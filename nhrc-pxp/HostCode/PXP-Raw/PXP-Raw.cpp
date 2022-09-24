/******************************************************************************/
/* NHRC-PXP Raw Mode Programmer -- Copyright (C) 2004 NHRC LLC.               */
/******************************************************************************/

#define STRICT

#include "stdafx.h"
#include "PXP-Raw.h"

#define WINDOW_POSITION_TOP_LEFT      0
#define WINDOW_POSITION_TOP_CENTER    1
#define WINDOW_POSITION_TOP_RIGHT     2
#define WINDOW_POSITION_RIGHT_CENTER  3
#define WINDOW_POSITION_BOTTOM_RIGHT  4
#define WINDOW_POSITION_BOTTOM_CENTER 5
#define WINDOW_POSITION_BOTTOM_LEFT   6
#define WINDOW_POSITION_LEFT_CENTER   7
#define WINDOW_POSITION_CENTER        8

#define MESSAGE_SIZE 256
#define BUFFER_SIZE 32
#define FILE_BUFFER_SIZE 512

HINSTANCE hInstance;
HWND hwndMain;
HWND printDialog;
#define HELP_FILE_NAME_LENGTH 128
char helpFileName[HELP_FILE_NAME_LENGTH];           /* the path/file name of the help file */
char path[MAX_PATH];                                /* the path of the program  directory */
BOOL bUserAbort;
BOOL bSuccess;
HBRUSH hbrBackground = NULL;

LRESULT CALLBACK AbortProc  (HDC hPrinterDC, short nCode);
LRESULT CALLBACK WndProc   (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK AboutDialogProc   (HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK CGDialogProc      (HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK PrintingDialogProc(HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK FreqEditProc      (HWND, WORD, WPARAM, LPARAM);
void ReadData(HWND hwnd);
void ReadAsciiData(HWND hwnd);
void SaveData(HWND hwnd);
int GetPod(HWND hwnd);
int PutPod(HWND hwnd);
int PodCommand(HWND hwnd, LPSTR command);
int CheckPod(HANDLE hCom, HWND hwnd);
char ascii2binary(char c);
char binary2ascii(char c);
HANDLE OpenCommPort(HWND hwnd);
void AdjustWindowPosition(HWND hwnd, HWND refwnd, int position);
void PrintFooter(HDC hDC, int pageWidth, int pageHeight, int charWidth, int lineHeight, int pageNumber, int hMargin);
void PrintHeader(HDC hDC, int pageWidth, int pageHeight, int charWidth, int lineHeight, int *xOffset, int *yOffset, int hMargin);
HDC NewGetPrinterDC(HWND);
HDC GetPrinterDC(HWND);
void SetWindowTitle(HWND hwnd, LPSTR name);
void UpdateInterface (HWND hwnd);

BOOL unsaved;
char filename[MAX_PATH];
char filterAscii[MESSAGE_SIZE];
char filterBinary[MESSAGE_SIZE];

#define FILE_HEADER_SIZE 2
#define PROGRAM_DATA_SIZE 256

/*************************/
/*** VERSION CONSTANTS ***/
/*************************/

#define POD_VERSION_STRING "\015\012\012NHRC-PXP V 0.0"
#define POD_VERSION_STRING_LENGTH 17
#define POD_OK_STRING "\015\012\012Ok\015"
#define POD_OK_STRING_LENGTH 6
#define POD_READ_BUFFER_SIZE PROGRAM_DATA_SIZE + 32

char programData[PROGRAM_DATA_SIZE];
char fileHeader[2];

int PASCAL WinMain (HINSTANCE hInst, HINSTANCE hPrevInstance, LPSTR lpszCmdLine, int nCmdShow)
{
    MSG         msg;
    WNDCLASS    wndclass;
    char message[MESSAGE_SIZE];

    strcpy_s (filterBinary, MESSAGE_SIZE, "Binary Data Files (*.bin)|*.bin|");
    strcpy_s (filterAscii,  MESSAGE_SIZE, "ASCII Hex Data (*.*)|*.*|");
    fileHeader[0] = 0x01;
    fileHeader[1] = 0x01; /* program version, file format version */
    char modulePath[MAX_PATH];
    int i;

    /* initialize file load/save template */
    for (i = 0; filterBinary[i] != '\0'; i++)
    {
        if (filterBinary[i] == '|')
           filterBinary[i] = '\0';
    }
    for (i = 0; filterAscii[i] != '\0'; i++)
    {
        if (filterAscii[i] == '|')
           filterAscii[i] = '\0';
    }
    unsaved = FALSE;
    hInstance = hInst;
    if (!hPrevInstance)
    {
	    hbrBackground = CreateSolidBrush(GetSysColor(COLOR_WINDOW));
        wndclass.style          = CS_HREDRAW | CS_VREDRAW;
        wndclass.lpfnWndProc    = WndProc;
        wndclass.cbClsExtra     = 0;
        wndclass.cbWndExtra     = DLGWINDOWEXTRA;
        wndclass.hInstance      = hInstance;
        wndclass.hIcon          = LoadIcon (hInstance, "Icon0");
        wndclass.hCursor        = LoadCursor(NULL, IDC_ARROW);
        wndclass.hbrBackground  = hbrBackground;
        wndclass.lpszMenuName   = NULL;
        wndclass.lpszClassName  = "PXP-Raw";
        RegisterClass (&wndclass);
    } /* if !hPrevInstance */

    GetModuleFileName(hInstance, modulePath, MAX_PATH);
    i = (int) strlen(modulePath);
    while ((i > 0) && (modulePath[i-1] != '\\'))
        i--;
    strncpy_s(path, MAX_PATH, modulePath, i);
    path[i] = '\0';

    strcpy_s(helpFileName, HELP_FILE_NAME_LENGTH, path);
    strcat_s(helpFileName, HELP_FILE_NAME_LENGTH, APPNAME);
    strcat_s(helpFileName, HELP_FILE_NAME_LENGTH, ".HLP");

    hwndMain = CreateDialog (hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, (DLGPROC) WndProc);
    if (hwndMain == NULL)
    {
        sprintf_s(message, MESSAGE_SIZE, "Could not create main window, error # %x", GetLastError());
        MessageBox(NULL, message, "Problem...", MB_ICONSTOP | MB_OK);
        return(0);
    } /* if hwndMain == NULL */

    ShowWindow (hwndMain, nCmdShow);

    while (GetMessage (&msg, NULL, 0, 0))
    {
	    if (!IsDialogMessage(hwndMain, &msg))
	    {
	        TranslateMessage (&msg);
	        DispatchMessage (&msg);
	    } /* if !IsDialogMessage... */
    } /* while */
    return (int) msg.wParam;
} /* WinMain() */

LRESULT CALLBACK WndProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HWND hwndCtl;
    LPDRAWITEMSTRUCT lpdis;    
    HDC hdc;
    HGDIOBJ oldObject;
    WORD controlID, notifyCode;
    OPENFILENAME ofn;

    switch (message)
    {
        case WM_INITDIALOG:
 	        UpdateInterface(hwnd);
            return(TRUE);

        case WM_COMMAND:
    	    controlID = LOWORD(wParam);
	        notifyCode = HIWORD(wParam);
	        hwndCtl = (HWND) lParam;
            switch (controlID)
            {
                case FILE_EXIT:
                    PostMessage(hwnd, WM_CLOSE, 0, 0L);
                    break;

		        case FILE_LOAD:
		            memset(&ofn, '\0', sizeof(OPENFILENAME));
		            ofn.lStructSize = sizeof(OPENFILENAME);
		            ofn.hwndOwner = hwnd;
		            ofn.hInstance = hInstance;
		            ofn.lpstrFilter = filterBinary;
		            ofn.lpstrFile = filename;
		            ofn.nMaxFile = sizeof(filename);
		            ofn.lpstrInitialDir = path;
		            ofn.lpstrDefExt = "dsx";
		            ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
			        OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
        			
		            if (GetOpenFileName(&ofn) == 0)
			            return FALSE;
		            ReadData(hwnd);
                    UpdateInterface(hwnd);
		            break;

		        case FILE_LOAD_ASCII:
		            memset(&ofn, '\0', sizeof(OPENFILENAME));
		            ofn.lStructSize = sizeof(OPENFILENAME);
		            ofn.hwndOwner = hwnd;
		            ofn.hInstance = hInstance;
		            ofn.lpstrFilter = filterAscii;
		            ofn.lpstrFile = filename;
		            ofn.nMaxFile = sizeof(filename);
		            ofn.lpstrInitialDir = path;
		            ofn.lpstrDefExt = "dsx";
		            ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
			        OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
        			
		            if (GetOpenFileName(&ofn) == 0)
			            return FALSE;
		            ReadAsciiData(hwnd);
                    UpdateInterface(hwnd);
		            break;

		        case FILE_SAVE:
		            if (strlen(filename) != 0)
		            {
			            SaveData(hwnd);
			            return FALSE;
		            } /* if strlen(filename) != 0 */
		            /* deliberate fall through */
    		    
		        case FILE_SAVE_AS:
		            memset(filename, '\0', sizeof(filename));
		            memset(&ofn, '\0', sizeof(OPENFILENAME));
		            ofn.lStructSize = sizeof(OPENFILENAME);
		            ofn.hwndOwner = hwnd;
		            ofn.hInstance = hInstance;
		            ofn.lpstrFilter = filterBinary;
		            ofn.lpstrFile = filename;
		            ofn.nMaxFile = sizeof(filename);
		            ofn.lpstrInitialDir = path;
		            ofn.lpstrDefExt = "dsx";
		            ofn.Flags = OFN_CREATEPROMPT | OFN_PATHMUSTEXIST |
			        OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
        			
		            if (GetSaveFileName(&ofn) == 0)
			            return FALSE;
		            strcpy_s(filename, MAX_PATH, ofn.lpstrFile);
		            SaveData(hwnd);
		            SetWindowTitle(hwnd, filename);
		            break;

		        case FILE_PRINT:
		            printDialog = CreateDialog(hInstance, "PrintingDialog", hwndMain, (DLGPROC) PrintingDialogProc);
                    break;

		        case POD_GET:
		            if (GetPod(hwnd))
		            {
			            unsaved = TRUE;
                        UpdateInterface(hwnd);
		            } /* if GetPod(...) */
		            break;
    		    
		        case POD_PUT:
		            PutPod(hwnd);
		            break;
        		    
		        case POD_READ:
		            PodCommand(hwnd, "r");
		            break;
        		    
		        case POD_WRITE:
		            PodCommand(hwnd, "w");
		            break;
    		    
#if 0
                    case HELP_PROGRAM:
                        WinHelp(hwnd, helpFileName, HELP_CONTENTS, 0L);
                        break;
#endif
    		    
                case HELP_ABOUT:
                    DialogBox (hInstance, "AboutDialog", hwnd, (DLGPROC) AboutDialogProc);
                    return(0);

            return(0);
        } //switch

	case WM_CTLCOLORSTATIC:
	    hdc = (HDC) wParam;
	    SetBkColor(hdc, GetSysColor(COLOR_WINDOW)); 
	    return (LRESULT) hbrBackground;

	case WM_DRAWITEM:
	    lpdis = (LPDRAWITEMSTRUCT) lParam;
	    if (lpdis->CtlType == ODT_BUTTON)
	    {
		    if (lpdis->itemState & ODS_FOCUS)
		    { /* checkbox has focus */
		        FrameRect(lpdis->hDC, &lpdis->rcItem, (HBRUSH) GetStockObject(BLACK_BRUSH));
		    } /* lpdis->itemState & ODS_FOCUS */
		    else
		    { /* checkbox does not have focus */
		        FrameRect(lpdis->hDC, &lpdis->rcItem, hbrBackground);
		    } /* lpdis->itemState & ODS_FOCUS */
		    /* fill in the inside of the checkbox */
		    oldObject = SelectObject(lpdis->hDC, hbrBackground);
		    Rectangle(lpdis->hDC, lpdis->rcItem.left+1, lpdis->rcItem.top+1, lpdis->rcItem.right-1, lpdis->rcItem.bottom-1);
		    SelectObject(lpdis->hDC, oldObject);
		    if (GetWindowLong(lpdis->hwndItem, GWL_USERDATA) != 0)
		    { /* checkbox is selected */
		        oldObject = SelectObject(lpdis->hDC, GetStockObject(BLACK_BRUSH));
		        MoveToEx(lpdis->hDC, lpdis->rcItem.left + 3, lpdis->rcItem.top + 3, NULL);
		        LineTo(lpdis->hDC, lpdis->rcItem.right - 3, lpdis->rcItem.bottom - 3);
		        MoveToEx(lpdis->hDC, lpdis->rcItem.left + 4, lpdis->rcItem.top + 3, NULL);
		        LineTo(lpdis->hDC, lpdis->rcItem.right - 3, lpdis->rcItem.bottom - 4);
		        MoveToEx(lpdis->hDC, lpdis->rcItem.left + 3, lpdis->rcItem.top + 4, NULL);
		        LineTo(lpdis->hDC, lpdis->rcItem.right - 4, lpdis->rcItem.bottom - 3);
    		    
		        MoveToEx(lpdis->hDC, lpdis->rcItem.right - 3, lpdis->rcItem.top + 3, NULL);
		        LineTo(lpdis->hDC, lpdis->rcItem.left + 3, lpdis->rcItem.bottom - 3);
		        MoveToEx(lpdis->hDC, lpdis->rcItem.right - 4, lpdis->rcItem.top + 3, NULL);
		        LineTo(lpdis->hDC, lpdis->rcItem.left + 3, lpdis->rcItem.bottom - 4);
		        MoveToEx(lpdis->hDC, lpdis->rcItem.right - 3, lpdis->rcItem.top + 4, NULL);
		        LineTo(lpdis->hDC, lpdis->rcItem.left + 4, lpdis->rcItem.bottom - 3);
		        SelectObject(lpdis->hDC, oldObject);
		    } /* lpdis->itemState & ODS_FOCUS */
		    return(TRUE);
	    } /* if lpdis->CtlType == ODT_BUTTON */
	    return (FALSE);
	    
        case WM_CLOSE:
	        if (unsaved)
	        {
		        if (MessageBox(hwnd,
			            "Unsaved data exists.\nAre you sure you want to exit?",
			            APPNAME,
			            MB_ICONWARNING | MB_YESNO) == IDNO)
		            return 0;
	        } /* if unsaved */
            WinHelp(hwnd, helpFileName, HELP_QUIT, 0L);
	        if (hbrBackground != NULL)
	        {
		        DeleteObject(hbrBackground);
		        hbrBackground = NULL;
	        } /* if hbrBackground != NULL */
            DestroyWindow(hwnd);
            return(0);

        case WM_DESTROY:
            PostQuitMessage(0);
            return(0);
    } /* switch message */
    return DefWindowProc (hwnd, message, wParam, lParam);
} /* WndProc */

LRESULT CALLBACK AboutDialogProc (HWND hdlg, WORD msg, WPARAM wParam, LPARAM lParam)
{
    char tempString[MESSAGE_SIZE];
    switch (msg)
    {
        case WM_INITDIALOG:
            AdjustWindowPosition(hdlg, hwndMain, WINDOW_POSITION_CENTER);
            sprintf_s(tempString, MESSAGE_SIZE, "%s version %s\nNHRC-PXP Raw Mode Programmer.\n\n%s\nBuilt %s",
		    APPTITLE, VERSION, COPYRIGHT, BUILDDATE);
            SetWindowText(GetDlgItem(hdlg, ABOUT_TEXT), tempString);
            return(TRUE);

	case WM_CTLCOLORDLG:
	    return (LRESULT) hbrBackground;
	    
	case WM_CTLCOLORSTATIC:
	    return (LRESULT) hbrBackground;

        case WM_COMMAND:
            if (wParam == IDOK)
            {
                EndDialog (hdlg, TRUE);
                return(TRUE);
            }
            break; /* End WM_COMMAND. */

        case WM_CLOSE:
            EndDialog(hdlg, TRUE);
            return(TRUE);
    } /* switch */
    return(FALSE);
}/* AboutDialogProc */

LRESULT CALLBACK PrintingDialogProc (HWND hwnd, WORD msg, WPARAM wParam, LPARAM lParam)
{
    char tempString[MESSAGE_SIZE];
    static HDC hDC;
    static int charHeight, charWidth, lineHeight, pageHeight, pageWidth;
    static int hMargin, vMargin, bodyHeight;
    static int pageNumber;
    static int yOffset = 0;
    static int xOffset = 0;
    int len;
    char szJobName[40];
    TEXTMETRIC tm;
    static FARPROC lpfnAbortProc;
    DOCINFO docInfo;
    LOGFONT printerLogFont;
    static HFONT oldHFont, printerHFont;
    DWORD dwError;
    int i;
    
    switch (msg)
    {
        case WM_INITDIALOG:
            AdjustWindowPosition(hwnd, hwndMain, WINDOW_POSITION_CENTER);
	    
            hDC = GetPrinterDC(hwnd);
            if (!hDC)
                return(-1);

            SetMapMode(hDC, MM_TEXT);

            printerLogFont.lfHeight = -MulDiv(12, GetDeviceCaps(hDC, LOGPIXELSY), 72);
            printerLogFont.lfWidth = 0;
            printerLogFont.lfEscapement = 0;
            printerLogFont.lfOrientation = 0;
            printerLogFont.lfItalic = 0;
            printerLogFont.lfUnderline = 0;
            printerLogFont.lfStrikeOut = 0;
            printerLogFont.lfWeight = FW_NORMAL;
            printerLogFont.lfCharSet = ANSI_CHARSET;
            printerLogFont.lfOutPrecision = OUT_DEVICE_PRECIS;
            printerLogFont.lfClipPrecision = CLIP_CHARACTER_PRECIS;
            printerLogFont.lfQuality = PROOF_QUALITY;
            printerLogFont.lfPitchAndFamily = FIXED_PITCH | FF_MODERN;
            lstrcpy(printerLogFont.lfFaceName,"Courier New");
            printerLogFont.lfWeight = FW_NORMAL;

            printerHFont = CreateFontIndirect(&printerLogFont);
            oldHFont = (HFONT) SelectObject(hDC, printerHFont);

            GetTextMetrics (hDC, &tm);

            charHeight = tm.tmHeight;
            lineHeight = tm.tmHeight + tm.tmExternalLeading;
            charWidth  = tm.tmAveCharWidth;
            hMargin = GetDeviceCaps(hDC, LOGPIXELSX) / 2; /* 1/2 inch */
            vMargin = GetDeviceCaps(hDC, LOGPIXELSY) / 2; /* 1/2 inch */
            pageWidth =  GetDeviceCaps(hDC, HORZRES) - hMargin;
            pageHeight = GetDeviceCaps(hDC, VERTRES);
            bodyHeight = pageHeight - 2 * lineHeight;
            lpfnAbortProc = MakeProcInstance ((FARPROC) AbortProc, hInstance);
            SetAbortProc(hDC, (ABORTPROC) lpfnAbortProc);
            GetWindowText (hwndMain, szJobName, sizeof (szJobName));

            bUserAbort = FALSE;

            docInfo.cbSize = sizeof(DOCINFO);
            docInfo.lpszDocName = szJobName;
            docInfo.lpszOutput = NULL;
            docInfo.lpszDatatype = NULL;
            docInfo.fwType = 0;
            bSuccess = FALSE;
            dwError = 0;
            if (StartDoc(hDC, &docInfo) > 0)
            {
            	if (StartPage(hDC) > 0)
		{
    	            PostMessage(hwnd, MSG_PRINT_HEADER, 0, 0L);
		    bSuccess = TRUE;
            	}
                else
                {
		    dwError = GetLastError();
                }
	    }
            else
            {
            	dwError = GetLastError();
            }
            if (bSuccess == FALSE)
            {
                PostMessage(hwnd, WM_CLOSE, 0, 0L);
            }
            if (dwError != 0)
            {
		PostMessage(hwnd, WM_CLOSE, 0, 0L);
	    }
            return(TRUE);
	    
        case WM_COMMAND:
            if (wParam == IDCANCEL)
            {
                bUserAbort = TRUE;
                AbortDoc(hDC);
                return(TRUE);
            }
            break; /* End WM_COMMAND. */
	    
        case MSG_PRINT_HEADER:
            SetWindowText(GetDlgItem(hwnd, PRINT_DIALOG_STATUS), "Printing Header");
            xOffset = hMargin;
            yOffset = 0;
            pageNumber = 1;
            PrintHeader(hDC, 
                        pageWidth, 
                        pageHeight, 
                        charWidth, 
                        lineHeight, 
                        &xOffset, 
                        &yOffset,
                        hMargin);
            PostMessage(hwnd, MSG_PRINT_NEXT, 0, 0L);
            break;
	    
        case MSG_PRINT_NEXT:
            if (bUserAbort && !bSuccess)
            {
                PostMessage(hwnd, MSG_PRINT_CLEANUP, 0, 0L);
                break;
            } /* if bUserAbort*/
		    len = sprintf_s(tempString, MESSAGE_SIZE, "--------- Programming Data ----------");
		    TextOut(hDC, 0, yOffset, tempString ,len);
		    yOffset += lineHeight;
		    len = sprintf_s(tempString, MESSAGE_SIZE, "Base  ------------ Offset -----------");
		    TextOut(hDC, 0, yOffset, tempString ,len);
		    yOffset += lineHeight;
		    len = sprintf_s(tempString, MESSAGE_SIZE, "Addr  0 1 2 3 4 5 6 7 8 9 a b c d e f");
		    TextOut(hDC, 0, yOffset, tempString ,len);
		    yOffset += lineHeight;
		    yOffset += lineHeight;
            for (i=0; i<256; i += 16)
            {
                len = sprintf_s(tempString, MESSAGE_SIZE, 
                                " %02x   %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x",
                                i,
                                programData[i+0],
                                programData[i+1],
                                programData[i+2],
                                programData[i+3],
                                programData[i+4],
                                programData[i+5],
                                programData[i+6],
                                programData[i+7],
                                programData[i+8],
                                programData[i+9],
                                programData[i+10],
                                programData[i+11],
                                programData[i+12],
                                programData[i+13],
                                programData[i+14],
                                programData[i+15]);
                TextOut(hDC, 0, yOffset, tempString ,len);
		        yOffset += lineHeight;
            } /* for i */
		    PostMessage(hwnd, MSG_PRINT_CLEANUP, 0, 0L);
            break;

        case MSG_PRINT_CLEANUP:
            SetWindowText(GetDlgItem(hwnd, PRINT_DIALOG_STATUS), "Cleaning up");
            PrintFooter(hDC, 
                        pageWidth, 
                        pageHeight, 
                        charWidth, 
                        lineHeight,
                        pageNumber++,
                        hMargin); 
            
            if (EndPage(hDC) <= 0)
            {
                bSuccess = FALSE;
                break;
            }
            if (bSuccess)
                EndDoc(hDC);            
            PostMessage(hwnd, WM_CLOSE, 0, 0L);
            break;

        case WM_CLOSE:
            //FreeProcInstance(lpfnAbortProc);
            SelectObject(hDC,oldHFont);
            DeleteObject(printerHFont);
            DeleteDC(hDC);
            DestroyWindow(hwnd);
            break;

    }/* switch */
    return(FALSE);
}/* PrintingDialogProc */

LRESULT CALLBACK AbortProc (HDC hPrinterDC, short nCode)
{
    MSG msg;

    while (!bUserAbort && PeekMessage (&msg, NULL, 0, 0, PM_REMOVE))
    {
        if (!printDialog || !IsDialogMessage (printDialog, &msg))
        {
            TranslateMessage (&msg);
            DispatchMessage (&msg);
        } /* if !printdialog... */
    } /* while !bUserAbort */
    return(!bUserAbort);
} /* AbortProc() */

HDC newGetPrinterDC(HWND hwnd)
{
    PRINTDLG pd;
    pd.lStructSize = sizeof(PRINTDLG); 
    pd.hDevMode = (HANDLE) NULL; 
    pd.hDevNames = (HANDLE) NULL; 
    pd.Flags = PD_RETURNDC; 
    pd.hwndOwner = hwnd; 
    pd.hDC = (HDC) NULL; 
    pd.nFromPage = 1; 
    pd.nToPage = 1; 
    pd.nMinPage = 0; 
    pd.nMaxPage = 0; 
    pd.nCopies = 1; 
    pd.hInstance = (HINSTANCE) NULL; 
    pd.lCustData = 0L; 
    pd.lpfnPrintHook = (LPPRINTHOOKPROC) NULL; 
    pd.lpfnSetupHook = (LPSETUPHOOKPROC) NULL; 
    pd.lpPrintTemplateName = (LPSTR) NULL; 
    pd.lpSetupTemplateName = (LPSTR)  NULL; 
    pd.hPrintTemplate = (HANDLE) NULL; 
    pd.hSetupTemplate = (HANDLE) NULL; 
    
    /* Display the PRINT dialog box. */ 
    if (PrintDlg(&pd))
	return(pd.hDC);
    else
	return(NULL);
} /* GetPrinterDC() */

HDC GetPrinterDC(HWND hwnd)
{
    static char szPrinter[80];
    char        *szDevice, *szDriver, *szOutput, *context;

    GetProfileString ("windows", "device", ",,,", szPrinter, 80);
    if (NULL != (szDevice = strtok_s (szPrinter, ",",  &context)) &&
        NULL != (szDriver = strtok_s (NULL,      ", ", &context)) &&
        NULL != (szOutput = strtok_s (NULL,      ", ", &context)))
        return(CreateDC (szDriver, szDevice, szOutput, NULL));
    return(0);
} /* GetPrinterDC() */

void PrintHeader(HDC hDC, int pageWidth, int pageHeight, int charWidth, int lineHeight, int *xOffset, int *yOffset, int hMargin)
{
    char tempString[MESSAGE_SIZE];
    int x, y, len, width;
    SIZE size;
    len = sprintf_s(tempString, MESSAGE_SIZE, "NHRC-PXP Raw Mode Programmer");
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = (pageWidth + hMargin - width) / 2;
    y = lineHeight;
    TextOut(hDC, x, y, tempString, len);
    len = sprintf_s(tempString, MESSAGE_SIZE, "%s",  filename);
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = (pageWidth + hMargin - width) / 2;
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    y += lineHeight;
    *yOffset = y + lineHeight;
} /* PrintHeader */

void PrintFooter(HDC hDC, int pageWidth, int pageHeight, int charWidth, int lineHeight, int pageNumber, int hMargin)
{
    char tempString[MESSAGE_SIZE];
    char *months[12] = {"January","February","March","April","May","June","July","August","September","October","November","December"};
    int x, y, len, width;
    SIZE size;
    struct tm *localTime;
    time_t t;

    y = pageHeight - lineHeight - lineHeight;

    t = time(NULL);
    localTime = localtime(&t);

    len = sprintf_s(tempString, MESSAGE_SIZE, "%d %s %d",
                  localTime->tm_mday,
                  months[localTime->tm_mon],
                  localTime->tm_year + 1900);
    TextOut(hDC, hMargin, y, tempString, len);

    len = sprintf_s(tempString, MESSAGE_SIZE, "%s version %s",  APPTITLE, VERSION);
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = (pageWidth + hMargin - width) / 2;
    TextOut(hDC, x, y, tempString, len);

    len = sprintf_s(tempString, MESSAGE_SIZE, "Page %d",  pageNumber);
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = pageWidth - width;
    TextOut(hDC, x, y, tempString, len);
} /* PrintFooter */

/*****************************************************************************/
/* AdjustWindowPosition() -- Move a window on the screen                     */
/*****************************************************************************/
void AdjustWindowPosition(HWND hwnd, HWND refWnd, int position)
{
    RECT rect;
    int x, y;
    int refX1, refX2, refY1, refY2;

    if (!refWnd)
        refWnd = GetDesktopWindow();
    GetWindowRect(refWnd, &rect);
    refX1 = rect.left;
    refX2 = rect.right;
    refY1 = rect.top;
    refY2 = rect.bottom;

    GetWindowRect(hwnd, &rect);
    switch (position)
    {
        case WINDOW_POSITION_TOP_LEFT:
            x = refX1;
            y = refY1;
            break;
        case WINDOW_POSITION_TOP_CENTER:
            x = refX1 + ((refX2 - refX1) / 2) - ((rect.right - rect.left) / 2);
            y = refY1;
            break;
        case WINDOW_POSITION_TOP_RIGHT:
            x = refX2 - (rect.right - rect.left);
            y = refY1;
            break;
        case WINDOW_POSITION_RIGHT_CENTER:
            x = refX2 - (rect.right - rect.left);
            y = refY1 + ((refY2 - refY1) / 2) - ((rect.bottom - rect.top) / 2);
            break;
        case WINDOW_POSITION_BOTTOM_RIGHT:
            x = refX2 - (rect.right - rect.left);
            y = refY2 - (rect.bottom - rect.top);
            break;
        case WINDOW_POSITION_BOTTOM_CENTER:
            x = refX1 + ((refX2 - refX1) / 2) - ((rect.right - rect.left) / 2);
            y = refY2 - (rect.bottom - rect.top);
            break;
        case WINDOW_POSITION_BOTTOM_LEFT:
            x = refX1;
            y = refY2 - (rect.bottom - rect.top);
            break;
        case WINDOW_POSITION_LEFT_CENTER:
            x = refX1;
            y = refY1 + ((refY2 - refY1) / 2) - ((rect.bottom - rect.top) / 2);
            break;
        case WINDOW_POSITION_CENTER:
            x = refX1 + ((refX2 - refX1) / 2) - ((rect.right - rect.left) / 2);
            y = refY1 + ((refY2 - refY1) / 2) - ((rect.bottom - rect.top) / 2);
            break;
        default:
            x = rect.left;
            y = rect.top;
            break;
    } /* switch position */
    SetWindowPos(hwnd, HWND_TOP, x, y, 0, 0, SWP_NOSIZE);
} /* AdjustWindowPosition() */

void SaveData(HWND hwnd)
{
    HANDLE fileHandle;
    DWORD bytesWritten;

    fileHandle = CreateFile(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (fileHandle == INVALID_HANDLE_VALUE)
    {
	    MessageBox(hwnd, "Invalid Handle", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    return;
    } /* if fileHandle == INVALID_HANDLE_VALUE */

    /* opened the file, write the header */
    WriteFile(fileHandle, (LPCVOID) &programData, sizeof(programData), &bytesWritten, NULL);
    CloseHandle(fileHandle);
    unsaved = FALSE;
} /* SaveData() */

void ReadData(HWND hwnd)
{
    HANDLE fileHandle;
    DWORD bytesRead;
    BOOL success = TRUE;
    fileHandle = CreateFile(filename, GENERIC_READ, 0, NULL, OPEN_EXISTING,
			    FILE_ATTRIBUTE_NORMAL, NULL);
    if (fileHandle == INVALID_HANDLE_VALUE)
    {
	    MessageBox(hwnd, "Invalid Handle", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    return;
    } /* if fileHandle == INVALID_HANDLE_VALUE */
    if (ReadFile(fileHandle,
                (LPVOID) &programData,
                sizeof(programData),
                &bytesRead,
                NULL))
    {
        success = true;
    } // if ReadFile
    else
    {
	    MessageBox(hwnd, "IO Error", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    success = FALSE;;
    } /* if ReadFile() */
    CloseHandle(fileHandle);
    if (success)
    {
	    unsaved = FALSE;
	    SetWindowTitle(hwnd, filename);
    } /* if success */
} /* ReadData() */

void ReadAsciiData(HWND hwnd)
{
    HANDLE fileHandle;
    DWORD bytesRead;
    char buffer[FILE_BUFFER_SIZE];
    BOOL success = TRUE;
    char b; //data byte
    int nibbleIndicator;
    int i;
    DWORD j;
    for (i=0; i<256; i++)
        programData[i] = 0;

    fileHandle = CreateFile(filename, GENERIC_READ, 0, NULL, OPEN_EXISTING,
			    FILE_ATTRIBUTE_NORMAL, NULL);
    if (fileHandle == INVALID_HANDLE_VALUE)
    {
	    MessageBox(hwnd, "Invalid Handle", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    return;
    } /* if fileHandle == INVALID_HANDLE_VALUE */
    if (ReadFile(fileHandle,
                (LPVOID) &buffer,
                FILE_BUFFER_SIZE,
                &bytesRead,
                NULL))
    {
        success = true;
    } /* if ReadFile() */
    else
    {
	    MessageBox(hwnd, "IO Error", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    success = FALSE;;
    } /* if ReadFile() */
    CloseHandle(fileHandle);
    i = 0;
    nibbleIndicator = 0;
    for (j = 0; j < bytesRead; j++)
    {
        b = buffer[j];
        switch (b)
        {
            case '0':
            case '1':    
            case '2':    
            case '3':    
            case '4':    
            case '5':    
            case '6':    
            case '7':    
            case '8':    
            case '9':
                programData[i] = (char) (b - 48);
                i++;
                break;
            case 'a':    
            case 'b':    
            case 'c':    
            case 'd':    
            case 'e':    
            case 'f':
                programData[i] = (char) (b - 87);
                i++;
                break;
            case 'A':    
            case 'B':    
            case 'C':    
            case 'D':    
            case 'E':    
            case 'F':   
                programData[i] = (char) (b - 55);
                i++;
                break;
        } // switch 
    } //for j

    if (i == 256)
    {
        success = true;
    }
    else
    {
	    MessageBox(hwnd, "File has an error", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    success = FALSE;
    } // if bytesRead >= 256
    if (success)
    {
	    unsaved = FALSE;
	    SetWindowTitle(hwnd, filename);
    } /* if success */
} /* ReadAsciiData() */

void SetWindowTitle(HWND hwnd, LPSTR name)
{
    char message[MESSAGE_SIZE];
    if (name[0] != 0 )
    {
    	sprintf_s(message, MESSAGE_SIZE, "%s - %s", APPNAME, name);
    } /* if (filename[0] != 0) */
    else
    {
	    sprintf_s(message, MESSAGE_SIZE, "%s", APPNAME);
    } /* if (filename[0] != 0) */
    SetWindowText(hwnd, message);
} /* SetWindowTitle() */

int PodCommand(HWND hwnd, LPSTR command)
{
    HANDLE hCom;
    DWORD byteCount;
    BOOL status;
    DWORD dwError;
    DWORD size;
    char buffer[POD_READ_BUFFER_SIZE + 1];
    char message[MESSAGE_SIZE];

    hCom = OpenCommPort(hwnd);
    if (hCom == NULL)
	return FALSE;
    
    if (!CheckPod(hCom, hwnd))
    {
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !CheckPod(...) */
    size = (DWORD) strlen(command);
    /* pod is there, and is the right version. read program EEPRM into pod. */
    status = WriteFile(hCom, command, size, &byteCount, NULL);
    if (!status || !byteCount)
    {
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not get Write comm port, error #d.", dwError);
	    MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !status ... */
    status = ReadFile(hCom, buffer, POD_READ_BUFFER_SIZE, &byteCount, NULL);
    CloseHandle(hCom);
    if (!status || !byteCount)
    {
	    MessageBox(hwnd, "No response from Pod.", "Problem...", MB_ICONSTOP | MB_OK);
	    return FALSE;
    } /* if !status || !byteCount */
    buffer[byteCount] = '\0';

    if (strncmp(buffer, POD_OK_STRING, POD_OK_STRING_LENGTH) != 0)
    {
	    MessageBox(hwnd, "Pod Communication Error.", "Problem...", MB_ICONSTOP | MB_OK);
	    return FALSE;
    } /* if strncmp */
    return TRUE;
} /* ReadPodCommand() */

int GetPod(HWND hwnd)
{
    HANDLE hCom;
    DWORD byteCount;
    BOOL status;
    DWORD dwError;
    char buffer[POD_READ_BUFFER_SIZE + 1];
    char message[MESSAGE_SIZE];
    int i;
    char checksum;
    char receivedChecksum;

    hCom = OpenCommPort(hwnd);
    if (hCom == NULL)
	return FALSE;
    
    if (!CheckPod(hCom, hwnd))
    {
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !CheckPod(...) */

    /* pod is there, and is the right version. upload from pod. */
    status = WriteFile(hCom, "u", 1, &byteCount, NULL);
    if (!status || !byteCount)
    {
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not get Write comm port, error #d.", dwError);
	    MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !status ... */
    status = ReadFile(hCom, buffer, POD_READ_BUFFER_SIZE, &byteCount, NULL);
    if (!status || !byteCount)
    {
	    MessageBox(hwnd, "No response from Pod.", "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !status || !byteCount */
    buffer[byteCount] = '\0';

    if (byteCount < (PROGRAM_DATA_SIZE + 2))
    {
	    MessageBox(hwnd, "Bad data received from pod.", "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return FALSE;
    } /* if byteCount < PROGRAM_DATA_SIZE + 2 */
    CloseHandle(hCom);
#ifdef DEBUG    
    sprintf_s(message, MESSAGE_SIZE, "status = %d, byteCount=%d\n%s", status, byteCount, buffer);
    MessageBox(hwnd, message, "Debug Info...", MB_OK);
#endif
    checksum = 0;
    for (i=0; i<PROGRAM_DATA_SIZE; i++)
    {
	    checksum = (char) (checksum + ascii2binary(buffer[i]));
    } /* for i */
    receivedChecksum = (char) (ascii2binary(buffer[256]) * 16 + ascii2binary(buffer[257]));
    if (checksum != receivedChecksum)
    {
	    sprintf_s(message, MESSAGE_SIZE, "Checksum error. %02x %02x", checksum, receivedChecksum);
	    MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    return FALSE;
    } /* if byteCount < PROGRAM_DATA_SIZE + 2 */
    /* data is good, copy it. */
    
    for (i=0; i<PROGRAM_DATA_SIZE; i++)
    {
	    programData[i] = ascii2binary(buffer[i]);
    } /* for i */
    
    return TRUE;
} /* GetPod() */

int PutPod(HWND hwnd)
{
    HANDLE hCom;
    DWORD byteCount;
    BOOL status;
    DWORD dwError;
    char buffer[POD_READ_BUFFER_SIZE + 1];
    char message[MESSAGE_SIZE];
    int i;
    char checksum;
    char c;

    hCom = OpenCommPort(hwnd);
    if (hCom == NULL)
	return FALSE;
	
    if (!CheckPod(hCom, hwnd))
    {
	    CloseHandle(hCom);
    	return FALSE;
    } /* if !CheckPod(...) */

    /* prepare outbound buffer */
    buffer[0] = 'd'; /* download to pod command */
    byteCount = 1;
    checksum = 0;
    for (i=0; i<PROGRAM_DATA_SIZE; i++)
    {
	    c = programData[i];
	    checksum = (char) (checksum + c);
	    buffer[byteCount++] = binary2ascii(c);
    } /* for i */
    buffer[byteCount++] = binary2ascii((char) ((checksum >> 4) & 0x0f));
    buffer[byteCount++] = binary2ascii((char) (checksum & 0x0f));
    buffer[byteCount] = '\0';
    
#ifdef DEBUG
    sprintf_s(message, MESSAGE_SIZE, "byteCount=%d\n%s", byteCount, buffer);
    MessageBox(hwnd, message, "Debug Info...", MB_OK);
#endif
    
    /* send outbound buffer */
    i = byteCount;
    status = WriteFile(hCom, buffer, i, &byteCount, NULL);
    if (!status || !byteCount)
    {
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not get Write comm port, error #d.", dwError);
	    MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !status ... */
    status = ReadFile(hCom, buffer, POD_READ_BUFFER_SIZE, &byteCount, NULL);
    CloseHandle(hCom);
    if (!status || !byteCount)
    {
	    MessageBox(hwnd, "No response from Pod.", "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return FALSE;
    } /* if !status || !byteCount */
    buffer[byteCount] = '\0';

    if (strncmp(buffer, POD_OK_STRING, POD_OK_STRING_LENGTH) != 0)
    {
	    sprintf_s(message, MESSAGE_SIZE, "byteCount=%d\n%s", byteCount, buffer);
	    MessageBox(hwnd, "Data Transfer Error.", "Problem...", MB_ICONSTOP | MB_OK);
	    return FALSE;
    } /* if strncmp */
    return TRUE;
} /* PutPod() */

int CheckPod(HANDLE hCom, HWND hwnd)
{
    DWORD byteCount;
    BOOL status;
    DWORD dwError;
    char buffer[32];
    char message[MESSAGE_SIZE];
    
    status = WriteFile(hCom, "v", 1, &byteCount, NULL);
    if (!status || !byteCount)
    {
	dwError = GetLastError();
	sprintf_s(message, MESSAGE_SIZE, "Could not get Write comm port, error #d.", dwError);
	MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	return FALSE;
    } /* if !status ... */
    status = ReadFile(hCom, buffer, 32, &byteCount, NULL);
    if (!status || !byteCount)
    {
	MessageBox(hwnd, "No response from Pod.", "Problem...", MB_ICONSTOP | MB_OK);
	return FALSE;
    } /* if !status || !byteCount */

    buffer[byteCount] = '\0';

    if (strncmp(buffer, POD_VERSION_STRING, POD_VERSION_STRING_LENGTH)!= 0)
    {
	    sprintf_s(message, MESSAGE_SIZE, "Unknown pod version or serial device:\n%s", buffer);
	    MessageBox(hwnd, message, "Problem...", MB_ICONEXCLAMATION | MB_OK);
	    return FALSE;
    } /* if strncmp */
    return TRUE;
} /* CheckPod() */

HANDLE OpenCommPort(HWND hwnd)
{
    DCB dcb;
    COMMTIMEOUTS commtimeouts;
    HANDLE hCom;
    DWORD dwError;
    BOOL fSuccess;
    char *comPort = "COM1";
    char message[MESSAGE_SIZE];
    hCom = CreateFile(comPort, GENERIC_READ | GENERIC_WRITE,
		      0,    /* comm devices must be opened w/exclusive-access */
		      NULL, /* no security attrs */
		      OPEN_EXISTING, /* comm devices must use OPEN_EXISTING */
		      0,    /* not overlapped I/O */
		      NULL  /* hTemplate must be NULL for comm devices */
		      );
    if (hCom == INVALID_HANDLE_VALUE)
    {
	    /* handle error */
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not open %s, error #d.", comPort, dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    return NULL;
    }
    /*
     * Omit the call to SetupComm to use the default queue sizes.
     * Get the current configuration.
     */
    
    fSuccess = GetCommState(hCom, &dcb);
    if (!fSuccess)
    {
	    /* Handle the error. */
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not get CommState, error #d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return NULL;
    } /* if ! fSuccess */
    /* Fill in the DCB: baud=9600, 8 data bits, no parity, 1 stop bit. */
    dcb.BaudRate = 9600;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;
    fSuccess = SetCommState(hCom, &dcb);
    if (!fSuccess)
    {
	    /* Handle the error. */
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not set CommState, error #d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return NULL;
    }  /* if !fSuccess */

    fSuccess = GetCommTimeouts(hCom, &commtimeouts);
    if (!fSuccess)
    {
	    /* Handle the error. */
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not get CommTimeouts, error #d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return NULL;
    } /* if ! fSuccess */
    commtimeouts.ReadIntervalTimeout = 50; // ms between characters.  9600 baud is about 1.1 ms
    commtimeouts.ReadTotalTimeoutMultiplier = 20; // ms per character for total timeout
    commtimeouts.ReadTotalTimeoutConstant = 500; // ms added to multiplier * numbytes to get total.
    commtimeouts.WriteTotalTimeoutMultiplier = 50; // ms MAX to transmit each character
    commtimeouts.WriteTotalTimeoutMultiplier = 1000; // ms added to multipler * numbytes to get total.

    fSuccess = SetCommTimeouts(hCom, &commtimeouts);
    if (!fSuccess)
    {
	    /* Handle the error. */
	    dwError = GetLastError();
	    sprintf_s(message, MESSAGE_SIZE, "Could not set CommTimeouts, error #d.", dwError);
            MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	    CloseHandle(hCom);
	    return NULL;
    } /* if ! fSuccess */
    return hCom;
} /* OpenCommPort() */
char ascii2binary(char c)
{
    if ((c > 47) && (c < 58))
	return  (char) (c - 48);

    if ((c > 64) && (c < 71))
	return (char) (c - 55);

    if ((c > 96) && (c < 103))
	return (char) (c - 87);
    return 0; /* bogus value */
} /* ascii2binary() */

char binary2ascii(char c)
{
    if (c < 10)
	return (char) (c + 48);
    if (c < 16)
	return (char) (c + 87);
    return '0';
} /* binary2ascii */
void UpdateInterface (HWND hwnd)
{
    char tempString[MESSAGE_SIZE];
    HWND hwndCtl;
    int i;
    for (i=0; i<256; i += 16)
    {
        sprintf_s(tempString, MESSAGE_SIZE, 
                        "  %02x  %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x %1x",
                        i,
                        programData[i+0],
                        programData[i+1],
                        programData[i+2],
                        programData[i+3],
                        programData[i+4],
                        programData[i+5],
                        programData[i+6],
                        programData[i+7],
                        programData[i+8],
                        programData[i+9],
                        programData[i+10],
                        programData[i+11],
                        programData[i+12],
                        programData[i+13],
                        programData[i+14],
                        programData[i+15]);

        hwndCtl = GetDlgItem(hwnd, HEX_DISP_BASE + (i >> 4));
        SetWindowText(hwndCtl, tempString);
    } // for i
} /* UpdateInterface() */

