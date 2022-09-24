/******************************************************************************/
/* Delta SX Radio Programmer -- Copyright (C) 2004 NHRC LLC.                  */
/******************************************************************************/

#define STRICT

#include "stdafx.h"
#include "DeltaSX.h"
#include "DeltaSXRadioData.h"

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
LRESULT CALLBACK BandDialogProc    (HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK CGDialogProc      (HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK PrintingDialogProc(HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK FreqEditProc      (HWND, WORD, WPARAM, LPARAM);
void ReadData(HWND hwnd);
void SaveData(HWND hwnd);
void UpdateInterface (HWND hwnd);
void data2program(void);
void program2data(void);
int  lookupRXCGCode(int code);
int  lookupRXCGInvertedCode(int code);
int  lookupTXCGCode(int code);
int  lookupTXCGInvertedCode(int code);
void freq2string(int f, char *s);
int  string2freq(char *s);
void initializeData(void);
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

ChannelDataStruct channels[NUM_CHANNELS];
RadioDataStruct radioData;
FreqEditDataStruct freqEditData[NUM_CHANNELS][2];

BOOL unsaved;
char filename[MAX_PATH];
char filter[MESSAGE_SIZE];

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

    strcpy_s (filter, MESSAGE_SIZE, "Delta SX Data Files (*.dsx)|*.dxs|");
    fileHeader[0] = 0x01;
    fileHeader[1] = 0x01; /* program version, file format version */
    char modulePath[MAX_PATH];
    int i;

    initializeData();
    
    /* initialize file load/save template */
    for (i = 0; filter[i] != '\0'; i++)
    {
        if (filter[i] == '|')
           filter[i] = '\0';
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
        wndclass.lpszClassName  = "DeltaSX";
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
    return msg.wParam;
} /* WinMain() */

LRESULT CALLBACK WndProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i, j, item, temp, temp2;
    int ctlBase;
    HWND hwndCtl;
    ChannelDataStruct *thisChannel;
    LPDRAWITEMSTRUCT lpdis;    
    HDC hdc;
    HGDIOBJ oldObject;
    WORD controlID, notifyCode;
    OPENFILENAME ofn;

    switch (message)
    {
        case WM_INITDIALOG:
	        for (i = 0; i < NUM_CHANNELS; i++)
	        {
		        ctlBase = CH_CTL_OFFSET + (1 + i) * 10;
		        thisChannel = &channels[i];
		        hwndCtl = GetDlgItem(hwnd, ctlBase + TX_CTL_OFFSET);
		        freqEditData[i][0].frequency = &thisChannel->nTxFrequency;
		        freqEditData[i][0].oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
		        SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) &freqEditData[i][0]);
		        SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) FreqEditProc);
		        hwndCtl = GetDlgItem(hwnd, ctlBase + RX_CTL_OFFSET);
		        freqEditData[i][1].frequency = &thisChannel->nRxFrequency;
		        freqEditData[i][1].oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
		        SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) &freqEditData[i][1]);
		        SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) FreqEditProc);
                hwndCtl = GetDlgItem(hwnd, ctlBase + CCT_CTL_OFFSET);
	            SendMessage(hwndCtl, CB_RESETCONTENT, 0, 0L);
	            for (j=0; j<NUM_CCT; j++)
	            {
	                SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) cctTimes[j]);
	            } /* for j */
	        } /* for i */

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

		        case FILE_NEW:
		            if (unsaved)
		            {
			            if (MessageBox(hwnd,
				                "Unsaved data exists.\nAre you sure?",
				                APPNAME,
				                MB_ICONWARNING | MB_YESNO) == IDNO)
			                break;
		            } /* if unsaved */
		            unsaved = FALSE;
		            initializeData();
                    radioData.nBandCode = DialogBox(hInstance, "BandDialog", hwndMain, (DLGPROC) BandDialogProc);
                    radioData.nIFFrequency = ifFrequencies[1];
                    if (radioData.nBandCode == BAND_VHF_45)
                        radioData.nIFFrequency = ifFrequencies[0];
		            SetWindowTitle(hwnd, "");
		            UpdateInterface(hwnd);
		            break;
    		    
		        case FILE_LOAD:
		            memset(&ofn, '\0', sizeof(OPENFILENAME));
		            ofn.lStructSize = sizeof(OPENFILENAME);
		            ofn.hwndOwner = hwnd;
		            ofn.hInstance = hInstance;
		            ofn.lpstrFilter = filter;
		            ofn.lpstrFile = filename;
		            ofn.nMaxFile = sizeof(filename);
		            ofn.lpstrInitialDir = path;
		            ofn.lpstrDefExt = "dsx";
		            ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
			        OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
        			
		            if (GetOpenFileName(&ofn) == 0)
			            return FALSE;
		            ReadData(hwnd);
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
		            ofn.lpstrFilter = filter;
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
		            data2program();
		            printDialog = CreateDialog(hInstance, "PrintingDialog", hwndMain, (DLGPROC) PrintingDialogProc);
                    break;

		        case POD_GET:
		            if (GetPod(hwnd))
		            {
                        radioData.nBandCode = DialogBox(hInstance, "BandDialog", hwndMain, (DLGPROC) BandDialogProc);
                        radioData.nIFFrequency = ifFrequencies[1];
                        if (radioData.nBandCode == BAND_VHF_45)
                            radioData.nIFFrequency = ifFrequencies[0];
			            program2data();
			            unsaved = TRUE;
			            UpdateInterface(hwnd);
		            } /* if GetPod(...) */
		            break;
    		    
		        case POD_PUT:
		            data2program();
		            PutPod(hwnd);
		            break;
        		    
		        case POD_READ:
		            PodCommand(hwnd, "r");
		            break;
        		    
		        case POD_WRITE:
		            PodCommand(hwnd, "w");
		            break;
    		    
                case HELP_ABOUT:
                    DialogBox (hInstance, "AboutDialog", hwnd, (DLGPROC) AboutDialogProc);
                    return(0);
		        default:
		            /* must be a channel control */
		            if ((controlID >= IDC_CH1_TX) &&
			            (controlID <= IDC_CH16_CCT))
		            {
			            i = (controlID - 1000) / 10 - 1;
			            if ((i >= 0) && (i < NUM_CHANNELS))
			            { /* valid channel range */
			                thisChannel = &channels[i];
			                item = controlID - 1000 - (i + 1) * 10;
			                switch (item)
			                {
				                case TX_TONE_CTL_OFFSET:
                                    temp2 = thisChannel->nTxCGCode;
                                    if (thisChannel->bUseInverseTxCode)
                                        temp2 += 1000;
				                    temp = DialogBoxParam(hInstance, "CGDialog", hwnd, (DLGPROC) CGDialogProc,
							                (LPARAM) temp2);
				                    if (temp >= 0)
				                    {
                                        if (temp >= 1000)
                                        {
                                            temp = temp - 1000;
                                            thisChannel->bUseInverseTxCode = TRUE;
                                        }
                                        else
                                        {
                                            thisChannel->bUseInverseTxCode = FALSE;
                                        }
					                    thisChannel->nTxCGCode = temp;
					                    SetDlgItemText(hwnd, wParam, cgNames[temp]);
					                    unsaved = TRUE;
				                    } /* if temp >= 0 */
				                    break;
				                case RX_TONE_CTL_OFFSET:
                                    temp2 = thisChannel->nRxCGCode;
                                    if (thisChannel->bUseInverseRxCode)
                                        temp2 += 1000;
				                    temp = DialogBoxParam(hInstance, "CGDialog", hwnd, (DLGPROC) CGDialogProc,
							                (LPARAM) temp2);
				                    if (temp >= 0)
				                    {
                                        if (temp >= 1000)
                                        {
                                            temp = temp - 1000;
                                            thisChannel->bUseInverseRxCode = TRUE;
                                        }
                                        else
                                        {
                                            thisChannel->bUseInverseRxCode = FALSE;
                                        }
					                    thisChannel->nRxCGCode = temp;
					                    SetDlgItemText(hwnd, wParam, cgNames[temp]);
					                    unsaved = TRUE;
				                    } /* if temp >= 0 */
				                    break;
				                case STE_CTL_OFFSET:
				                    thisChannel->bUseSTE = thisChannel->bUseSTE ? 0 : 1;
				                    SetWindowLong((HWND) lParam, GWL_USERDATA, thisChannel->bUseSTE);
				                    InvalidateRect((HWND) lParam, NULL, FALSE);
				                    unsaved = TRUE;
				                    break;
				                case CCT_CTL_OFFSET:
        		                    if (notifyCode == CBN_SELCHANGE)
		                            {
		            	                i = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
			                            if (i != CB_ERR)
			                            {
			                                thisChannel->nCCTCode = i;
			                                unsaved = TRUE;
			                            } /* if i != CB_ERR */
		                            } /* if nofifyCode == CBM_SELCHANGE */
				                    break;
			            } /* switch item */
			        } /* if i > 0 ... */ 
		        } /* if wParam > CHCTL_OFFSET ... */
		        return (0);
            } /* switch controlID */
            return(0);

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
            sprintf_s(tempString, MESSAGE_SIZE, "%s version %s\nNHRC Delta SX Programmer.\n\n%s\nBuilt %s",
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

LRESULT CALLBACK BandDialogProc (HWND hdlg, WORD msg, WPARAM wParam, LPARAM lParam)
{
    static int selectedBand = 0;
    WORD wID, wCode;
    switch (msg)
    {
        case WM_INITDIALOG:
            AdjustWindowPosition(hdlg, hwndMain, WINDOW_POSITION_CENTER);
            CheckDlgButton(hdlg, BAND_LOW_RB, BST_CHECKED);
            return(TRUE);

	    case WM_CTLCOLORDLG:
	        return (LRESULT) hbrBackground;
    	    
	    case WM_CTLCOLORSTATIC:
	        return (LRESULT) hbrBackground;

        case WM_COMMAND:
	        wID = LOWORD(wParam);
	        wCode = HIWORD(wParam);
	        if (wCode == BN_CLICKED)
	        {
		        if (wID == IDOK)
		        {
                    EndDialog (hdlg, selectedBand);
		            return(0);
		        }
		        if ((wID >= BAND_LOW_RB) && (wID <= BAND_UHF_RB))
		        {
		            if (IsDlgButtonChecked(hdlg, wID) == BST_CHECKED)
		            { /* this is a sanity check */
                        selectedBand = wID - BAND_LOW_RB;
			            //EndDialog (hdlg, selectedBand);
		            } /* if IsDlgButtonChecked... */
		            return(0);
		        } /* if wID >= CG_RB_0 && ... */
	        } /* if wCode == BN_CLICKED */
            break; /* End WM_COMMAND. */

        case WM_CLOSE:
            //EndDialog(hdlg, TRUE);
            return(TRUE);
    } /* switch */
    return(FALSE);
}/* BandDialogProc */

LRESULT CALLBACK CGDialogProc (HWND hdlg, WORD msg, WPARAM wParam, LPARAM lParam)
{
    static int cgCode = -1;
    WORD wID;
    WORD wCode;

    switch (msg)
    {
        case WM_INITDIALOG:
            AdjustWindowPosition(hdlg, hwndMain, WINDOW_POSITION_CENTER);
	        cgCode = (int) lParam;
            if (cgCode >= 1000)
            {
                cgCode -= 1000;
                CheckDlgButton(hdlg, CG_CB_INVERTED, BST_CHECKED);
            }
            else
            {
                CheckDlgButton(hdlg, CG_CB_INVERTED, BST_UNCHECKED);
            }
	        CheckDlgButton(hdlg, CG_RB_0 + cgCode, BST_CHECKED);
            return(TRUE);

	    case WM_CTLCOLORDLG:
	        return (LRESULT) hbrBackground;
	    
	    case WM_CTLCOLORSTATIC:
	        SetBkColor((HDC) wParam, GetSysColor(COLOR_WINDOW)); 
	        return (LRESULT) hbrBackground;

        case WM_COMMAND:
	        wID = LOWORD(wParam);
	        wCode = HIWORD(wParam);
	        if (wCode == BN_CLICKED)
	        {
		        if (wID == IDOK)
		        {
                    EndDialog (hdlg, cgCode + ((IsDlgButtonChecked(hdlg, CG_CB_INVERTED) ==  BST_CHECKED) ? 1000 : 0));
		            return(0);
		        }
		        if (wID == IDCANCEL)
		        {
		            EndDialog (hdlg, -1);
		            return(0);
		        }

		        if ((wID >= CG_RB_0) && (wID <= CG_RB_137))
		        {
		            if (IsDlgButtonChecked(hdlg, wID) == BST_CHECKED)
		            { /* this is a sanity check */
                        cgCode = wID - CG_RB_0 + ((IsDlgButtonChecked(hdlg, CG_CB_INVERTED) ==  BST_CHECKED) ? 1000 : 0);
			            EndDialog (hdlg, cgCode);
		            } /* if IsDlgButtonChecked... */
		            return(0);
		        } /* if wID >= CG_RB_0 && ... */

	        } /* if wCode == BN_CLICKED */
	        break;
	    
        case WM_CLOSE:
            EndDialog(hdlg, -1);
            return(TRUE);

    }/* switch */
    return(FALSE);
}/* CGDialogProc */

LRESULT CALLBACK PrintingDialogProc (HWND hwnd, WORD msg, WPARAM wParam, LPARAM lParam)
{
    char tempString[MESSAGE_SIZE];
    static HDC hDC;
    static int charHeight, charWidth, lineHeight, pageHeight, pageWidth;
    static int hMargin, vMargin, bodyHeight;
    static int pageNumber;
    static int yOffset = 0;
    static int xOffset = 0;
    int channelNumber;
    char txFreq[10];
    char rxFreq[10];
    ChannelDataStruct *thisChannel;
    int len;
    char szJobName[40];
    TEXTMETRIC tm;
    static FARPROC lpfnAbortProc;
    DOCINFO docInfo;
    LOGFONT printerLogFont;
    static HFONT oldHFont, printerHFont;
    DWORD dwError;
#ifdef DEBUGPRINT
    int i;
#endif    
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
	    channelNumber = lParam;
	    
            sprintf_s(tempString, MESSAGE_SIZE, "Printing channel %d of %d", channelNumber + 1, NUM_CHANNELS);
            SetWindowText(GetDlgItem(hwnd, PRINT_DIALOG_STATUS), tempString);
	    
	    /*                        "Ch   Transmit  Transmit Receive  Receive   STE   CCT" */
	    /*                        " #     Freq"     CG      Freq       CG              " */
	    /*                         xx   123.4567   ccccc   fff.ffff   ccccc   sss   sss */
	    thisChannel = &channels[channelNumber];
	    freq2string(thisChannel->nTxFrequency, txFreq);
	    freq2string(thisChannel->nRxFrequency, rxFreq);
	    len = sprintf_s(tempString, MESSAGE_SIZE, "%2d   %8s   %5s   %8s   %5s   %3s   %5s",
			  channelNumber + 1,
			  txFreq,
			  cgNames[thisChannel->nTxCGCode],
			  rxFreq,
			  cgNames[thisChannel->nRxCGCode],
			  (thisChannel->bUseSTE ? "YES" : "NO"),
			  cctTimes[thisChannel->nCCTCode]);
	    TextOut(hDC, 0, yOffset, tempString ,len);
	    yOffset += lineHeight;

	    channelNumber++;
        if (channelNumber < NUM_CHANNELS)
        { /* more questions to print */
            PostMessage(hwnd, MSG_PRINT_NEXT, 0, (LPARAM) channelNumber);
        } /* if (channelNumber < NUM_CHANNELS */
        else
        { /* no more channels to print */
#ifdef DEBUGPRINT		
		    yOffset += lineHeight;
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
#endif                
		    PostMessage(hwnd, MSG_PRINT_CLEANUP, 0, 0L);
        } /* if (channelNumber < NUM_CHANNELS */
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

HDC NewGetPrinterDC(HWND hwnd)
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
    len = sprintf_s(tempString, MESSAGE_SIZE, "NHRC Delta SX Programmer");
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
    x = 0;
#if 0
    if (radioData.nIFFrequency != 0)
    {
	    len = sprintf(tempString, "IF Frequency %4.1f MHz",
		      radioData.nIFFrequency / 1000000);
	    y += lineHeight;
	    TextOut(hDC, x, y, tempString ,len);
    } /* if radioData.nReferenceFrequencyCode != 0 */
#endif
    y += lineHeight;
    len = sprintf_s(tempString, MESSAGE_SIZE, "Ch   Transmit  Transmit Receive  Receive   STE   CCT");
    y += lineHeight + lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    len = sprintf_s(tempString, MESSAGE_SIZE, " #     Freq      CG      Freq       CG              ");
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    *yOffset = y + lineHeight + lineHeight;
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

/*****************************************************************************/
/* FreqEditProc -- the subclass code for the Frequency edit controls.        */
/* performs rudimentary input validation.  could be much more rigorous.      */
/*****************************************************************************/
LRESULT CALLBACK FreqEditProc(HWND hwnd, WORD message, WPARAM wParam, LPARAM lParam)
{
    char c;
    char tempString[BUFFER_SIZE];
    int freq;
    int i, l;
    BOOL valid;
    HANDLE clipHandle;
    LPSTR clipText;
    DWORD startPos, endPos;
    FreqEditDataStruct *freqEditData = (FreqEditDataStruct *) GetWindowLong(hwnd, GWL_USERDATA);
    
    switch (message)
    {
	    case WM_KEYDOWN:
	        if (wParam == VK_DELETE)
	        {
		        MessageBeep(MB_OK);
		        return FALSE;
	        } /* if wParam == VK_DELETE */
	        break;

        case WM_CHAR:
            c = (char) wParam;
	        SendMessage(hwnd, EM_GETSEL, (WPARAM) &startPos, (LPARAM) &endPos);
	        if (c == 8)
	        {
		        if (startPos > 0)
		        {
		            startPos--;
		            SendMessage(hwnd, EM_SETSEL, (WPARAM) startPos, (LPARAM) startPos);
		            return FALSE;
		        } /* if startPos > 0 */
		        else
		        {
		            MessageBeep(MB_OK);
		            return FALSE;
		        } /* if startPos > 0 */
	        } /* if c == 8 */
    	    if ((!isdigit(c)) && (c != '.'))
	        {
		        MessageBeep(MB_OK);
		        return FALSE;
	        } /* if !isdigit c */
	        SendMessage(hwnd, EM_GETSEL, (WPARAM) &startPos, (LPARAM) &endPos);
	        if (startPos == 3)
	        {
		        if (c != '.')
		        {
		            MessageBeep(MB_OK);
		            return FALSE;
		        } /* c != '.' */
    	    } /* if startPos == 3 */
	        else
	        {
		        if (!isdigit(c))
		        {
		            MessageBeep(MB_OK);
		            return FALSE;
		        } /* c != '.' */
	        } /* if !startPos == 3 */
	        if ((startPos == 0) && (c != '0') && (c != '1') && (c != '4'))
    	    {
    		    MessageBeep(MB_OK);
		        return FALSE;
	        } /* if startPos == 0 && c != 0 && c != 1 && c != 4 */
	    
	        if ((startPos == 1) && ((c == '0') || (c == '8') || (c == '9')))
	        {
		        MessageBeep(MB_OK);
		        return FALSE;
	        } /* if startPos == 0 && c != 0 && c != 1 && c != 4 */
    	    
	        if ((startPos < 0) || (startPos > 7))
	        {
		        MessageBeep(MB_OK);
		        return FALSE;
	        } /* if startPos < 0 ... */

	        freq2string(*freqEditData->frequency, tempString);
	        tempString[startPos] = c;
	        freq = string2freq(tempString);
	        *freqEditData->frequency = freq;
	        SetWindowText(hwnd, tempString);
	        startPos++;
	        SendMessage(hwnd, EM_SETSEL, (WPARAM) startPos, (LPARAM) startPos);
	        unsaved = TRUE;
	        return FALSE;

        case WM_KILLFOCUS:
	        freq2string(*freqEditData->frequency, tempString);
	        SetWindowText(hwnd, tempString);
            break;

	    case WM_PASTE:
	        if (OpenClipboard(hwnd))
	        {
		        clipHandle = GetClipboardData(CF_TEXT);
		        memset(tempString, 0, BUFFER_SIZE);
		        if (clipHandle != NULL)
		        {
		            clipText = (LPSTR) GlobalLock(clipHandle);
		            strncpy_s(tempString, BUFFER_SIZE, clipText, BUFFER_SIZE);
		            tempString[BUFFER_SIZE-1] = '\0';
		            GlobalUnlock(clipHandle);
		        } /* if clipHandle != NULL */
		        CloseClipboard();
		        l = lstrlen(tempString);
		        valid = TRUE;
		        if (l == 8)
		        {
		            for (i = 0; i < l; i++)
		            {
			        c = tempString[i];
			        switch (i)
			        {
			            case 0:
				        if ((c != '0') &&
				            (c != '1') &&
				            (c != '4'))
				            valid = FALSE;
				        break;
			            case 3:
				        if (c != '.')
				            valid = FALSE;
				        break;
			            default:
				        if (!isdigit(c))
				            valid = FALSE;
				        break;
			        } /* switch i */
		        } /* for i */
        		    
		        if (valid)
		        {
			        freq = string2freq(tempString);
			        *freqEditData->frequency = freq;
			        SetWindowText(hwnd, tempString);
			        startPos = endPos = 0;
			        SendMessage(hwnd, EM_SETSEL, (WPARAM) startPos, (LPARAM) endPos);
			        unsaved = TRUE;
			        return 0;
		        } /* if valid */
        		    
		        } /* if l == 8 */
	        } /* if OpenClipboard */
	        MessageBeep(MB_OK);
	        return 0;

    } /* switch */
   return(CallWindowProc(freqEditData->oldWindowProc, hwnd, message, wParam, lParam));
} /* FreqEditProc() */

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
    WriteFile(fileHandle, fileHeader, FILE_HEADER_SIZE, &bytesWritten, NULL); 
    WriteFile(fileHandle, (LPCVOID) &radioData, sizeof(RadioDataStruct), &bytesWritten, NULL);
    WriteFile(fileHandle, (LPCVOID) channels, sizeof(ChannelDataStruct) * NUM_CHANNELS, &bytesWritten, NULL);
    CloseHandle(fileHandle);
    unsaved = FALSE;
} /* SaveData() */

void ReadData(HWND hwnd)
{
    HANDLE fileHandle;
    DWORD bytesRead;
    BOOL success = TRUE;
    char versionData[2];

    fileHandle = CreateFile(filename, GENERIC_READ, 0, NULL, OPEN_EXISTING,
			    FILE_ATTRIBUTE_NORMAL, NULL);
    if (fileHandle == INVALID_HANDLE_VALUE)
    {
	    MessageBox(hwnd, "Invalid Handle", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    return;
    } /* if fileHandle == INVALID_HANDLE_VALUE */
    if (ReadFile(fileHandle, versionData, FILE_HEADER_SIZE, &bytesRead, NULL))
    {
	    if ((versionData[0] == fileHeader[0]) &&
	        (versionData[1] == fileHeader[1]))
	    {
	        ReadFile(fileHandle,
                        (LPVOID) &radioData,
                        sizeof(RadioDataStruct),
                        &bytesRead,
                        NULL);
	        ReadFile(fileHandle,
                        (LPVOID) channels,
                        sizeof(ChannelDataStruct) * NUM_CHANNELS,
                        &bytesRead,
                        NULL);
	    } /* if versionData... */
	    else
	    {
	        MessageBox(hwnd, "Invalid Data File", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	        success = FALSE;;
	    } /* if versionData... */
    } /* if ReadFile() */
    else
    {
	    MessageBox(hwnd, "IO Error", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
	    success = FALSE;;
    } /* if ReadFile() */
    CloseHandle(fileHandle);
    if (success)
    {
	    unsaved = FALSE;
	    UpdateInterface(hwnd);
	    SetWindowTitle(hwnd, filename);
    } /* if success */
} /* ReadData() */
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

void UpdateInterface (HWND hwnd)
{
    char tempString[10];
    int ctlBase;
    HWND hwndCtl;
    int i;
    ChannelDataStruct *thisChannel;
    
    for (i = 0; i < NUM_CHANNELS; i++)
    {
	    ctlBase = CH_CTL_OFFSET + (1 + i) * 10;
	    thisChannel = &channels[i];
	    freq2string(thisChannel->nTxFrequency, tempString);
	    hwndCtl = GetDlgItem(hwnd, ctlBase + TX_CTL_OFFSET);
	    SetWindowText(hwndCtl, tempString);
    	
	    SetDlgItemText(hwnd, ctlBase + TX_TONE_CTL_OFFSET, cgNames[thisChannel->nTxCGCode]);
	    freq2string(thisChannel->nRxFrequency, tempString);
	    hwndCtl = GetDlgItem(hwnd, ctlBase + RX_CTL_OFFSET);
	    SetWindowText(hwndCtl, tempString);
    	
	    SetDlgItemText(hwnd, ctlBase + RX_TONE_CTL_OFFSET, cgNames[thisChannel->nRxCGCode]);
	    CheckDlgButton(hwnd, ctlBase + STE_CTL_OFFSET, thisChannel->bUseSTE ? BST_CHECKED : BST_UNCHECKED);
	    hwndCtl = GetDlgItem(hwnd, ctlBase + STE_CTL_OFFSET);
	    SetWindowLong(hwndCtl, GWL_USERDATA, thisChannel->bUseSTE);
	    InvalidateRect(hwndCtl, NULL, FALSE);
	    hwndCtl = GetDlgItem(hwnd, ctlBase + CCT_CTL_OFFSET);
        SendMessage(hwndCtl, CB_SETCURSEL, (WPARAM) thisChannel->nCCTCode, 0);
    } /* for i */
} /* UpdateInterface() */

int lookupRXCGCode(int code)
{
    int i;
    for (i=0; i< NUM_CG; i++)
    {
	    if (rxCgCodes[i] == code)
	        return i;
    } /* for i */
    return -1;
} /* lookupRXCGCode() */

int lookupRXCGInvertedCode(int code)
{
    int i;
    for (i=0; i< NUM_CG; i++)
    {
	    if (rxCgCodesInverted[i] == code)
	        return i;
    } /* for i */
    return -1;
} /* lookupRXCGInvertedCode() */

int lookupTXCGCode(int code)
{
    int i;
    for (i=0; i< NUM_CG; i++)
    {
	    if (txCgCodes[i] == code)
	        return i;
    } /* for i */
    return -1;
} /* lookupTXCGCode() */

int lookupTXCGInvertedCode(int code)
{
    int i;
    for (i=0; i< NUM_CG; i++)
    {
	    if (txCgCodesInverted[i] == code)
	        return i;
    } /* for i */
    return -1;
} /* lookupTXCGInvertedCode() */

void freq2string(int f, char *s)
{
    char buffer[BUFFER_SIZE];
    sprintf_s(buffer, BUFFER_SIZE, "%09d", f);
    s[0] = buffer[0];
    s[1] = buffer[1];
    s[2] = buffer[2];
    s[3] = '.';
    s[4] = buffer[3];
    s[5] = buffer[4];
    s[6] = buffer[5];
    s[7] = buffer[6];
    s[8] = '\0';
} /* freq2string[] */

int string2freq(char *s)
{
   int i, freq, l, dp, m;
   char c;
   l = 0;
   dp = -1;
   while (c = s[l])
   {
       if (c == '.')
       {
           dp = l;
       } /* if c == '.' */
       l++;
   } /* while */
   /* now l is the string length, and dp contains the decimal position */
   if (dp < 0)
       return -1;
   /* get the factor for the first digit. */
   switch (dp)
   {
       case 0:
	   m = 100000;
	   break;
       case 1:
	   m = 1000000;
	   break;
       case 2:
	   m = 10000000;
	   break;
       case 3:
	   m = 100000000;
	   break;
       default:
	   m = 1;
	   break;
   } /* switch */

   freq = 0;
   for (i=0; i<l; i++)
   {
       if (i != dp)
       {
           freq += ((s[i]-48) * m);
           m = m / 10;
       } /* if i != dp */
   } /* for i */
   return freq;
} /* string2freq() */

void initializeData()
{
    int i;
    for (i=0; i < NUM_CHANNELS; i++)
    {
	    channels[i].nRxFrequency = 0;
	    channels[i].nTxFrequency = 0;
	    channels[i].nRxCGCode = 0;
	    channels[i].nTxCGCode = 0;
	    channels[i].bUseSTE = FALSE;
	    channels[i].nCCTCode = 0;
    } /* for i */
    radioData.nIFFrequency = 0;
    radioData.nBandCode = -1;
    filename[0] = '\0';
} /* intializeData() */

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



void data2program()
{
    int i, baseAddress;
    int factor;
    int csCode, ctcssCode;
    int freq, cs; /* in hertz! */
    ChannelDataStruct *thisChannel;
    int numChannels = -1;
    int isUHF;
    int syCode;

    /* initialize data */
    for (i=0; i<PROGRAM_DATA_SIZE; i++)
        programData[i]=0;

    isUHF = (radioData.nBandCode == BAND_UHF);

    /* iterate through channels, converting to radio program */
    for (i=0; i< NUM_CHANNELS; i++)
    {
        baseAddress = ((~(i + 1)) << 4) & 0x00f0; 
        thisChannel = &channels[i];
        if ((thisChannel->nRxFrequency == 0) && 
            (thisChannel->nTxFrequency == 0))
        { // this is an unprogrammed channel 
                programData[baseAddress     ] = (char) 0x00;
                programData[baseAddress +  1] = (char) 0x0f;
                programData[baseAddress +  2] = (char) 0x0f;
                programData[baseAddress +  3] = (char) 0x0f;
                programData[baseAddress +  4] = (char) 0x0f;
                programData[baseAddress +  5] = (char) 0x0b;
                programData[baseAddress +  6] = (char) 0x00;
                programData[baseAddress +  7] = (char) 0x00;
                programData[baseAddress +  8] = (char) 0x00;
                programData[baseAddress +  9] = (char) 0x0f;
                programData[baseAddress + 10] = (char) 0x0f;
                programData[baseAddress + 11] = (char) 0x0f;
                programData[baseAddress + 12] = (char) 0x0f;
                programData[baseAddress + 13] = (char) 0x0b;
                programData[baseAddress + 14] = (char) 0x00;
                programData[baseAddress + 15] = (char) 0x00;
        } // unprogrammed channel
        else
        { // programmed channel
            freq = thisChannel->nRxFrequency;
            if (freq == 0)
            { /* unprogrammed channel */
                programData[baseAddress    ] = (char) 0x00;
                programData[baseAddress + 1] = (char) 0x0f;
                programData[baseAddress + 2] = (char) 0x0f;
                programData[baseAddress + 3] = (char) 0x0f;
                programData[baseAddress + 4] = (char) 0x0f;
                programData[baseAddress + 5] = (char) 0x0b;
                programData[baseAddress + 6] = (char) 0x00;
                programData[baseAddress + 7] = (char) 0x00;
            } /* if freq == 0 */
            else
            { /* programmed channel */
                numChannels = i;


                if (!isUHF)
                { // try VHF channel spacing
                    freq = freq + radioData.nIFFrequency;
                    cs = 5000; // 5 KHz channel spacing
                    csCode = 2;
                    factor = (freq / cs) & 0xffff;
                    if (factor * cs != freq)
                    { // did not work out for 5 KHz
                        cs = 6250; // 6.25 KHz
                        csCode = 3;
                        factor = (freq / cs) & 0xffff;
                    } // did not work out for 5 KHz.

                    syCode = 0;
                    if ((thisChannel->nRxFrequency >= 135000000) && (thisChannel->nRxFrequency < 138000000))
                        syCode = 0;
                    if ((thisChannel->nRxFrequency >= 138000000) && (thisChannel->nRxFrequency < 142000000))
                        syCode = 1;
                    if ((thisChannel->nRxFrequency >= 142000000) && (thisChannel->nRxFrequency < 147000000))
                        syCode = 2;
                    if ((thisChannel->nRxFrequency >= 147000000) && (thisChannel->nRxFrequency < 153000000))
                        syCode = 3;
                    if ((thisChannel->nRxFrequency >= 159000000) && (thisChannel->nRxFrequency < 155000000))
                        syCode = 0;
                    if ((thisChannel->nRxFrequency >= 155000000) && (thisChannel->nRxFrequency < 159000000))
                        syCode = 1;
                    if ((thisChannel->nRxFrequency >= 159000000) && (thisChannel->nRxFrequency < 166000000))
                        syCode = 2;
                    if ((thisChannel->nRxFrequency >= 166000000) && (thisChannel->nRxFrequency < 174000000))
                        syCode = 3;
                } // is VHF
                else
                { // try UHF channel spacing...
                    freq = freq - radioData.nIFFrequency;
                    cs = 12500; // 2 * 6.25KHz channel spacing
                    csCode = 0;
                    factor = (freq / cs) & 0xffff;
                    syCode = 0;
                    if ((thisChannel->nRxFrequency >= 403000000) && (thisChannel->nRxFrequency < 408000000))
                        syCode = 0;
                    if ((thisChannel->nRxFrequency >= 408000000) && (thisChannel->nRxFrequency < 417000000))
                        syCode = 1;
                    if ((thisChannel->nRxFrequency >= 417000000) && (thisChannel->nRxFrequency < 426000000))
                        syCode = 2;
                    if ((thisChannel->nRxFrequency >= 426000000) && (thisChannel->nRxFrequency < 440000000))
                        syCode = 3;
                    if ((thisChannel->nRxFrequency >= 440000000) && (thisChannel->nRxFrequency < 446000000))
                        syCode = 0;
                    if ((thisChannel->nRxFrequency >= 446000000) && (thisChannel->nRxFrequency < 452000000))
                        syCode = 1;
                    if ((thisChannel->nRxFrequency >= 452000000) && (thisChannel->nRxFrequency < 460000000))
                        syCode = 2;
                    if ((thisChannel->nRxFrequency >= 460000000) && (thisChannel->nRxFrequency < 470000000))
                        syCode = 3;
                } // is UHF

                ctcssCode = thisChannel->bUseInverseRxCode ? rxCgCodesInverted[thisChannel->nRxCGCode]: rxCgCodes[thisChannel->nRxCGCode];

                programData[baseAddress]      = (char) (((ctcssCode & 0x1000) >> 9) | 
                                                        ((syCode & 0x0003) << 1) | 
                                                        ((ctcssCode & 0x0100) >> 8)); // RD, SY1, SY0, CCG5
                programData[baseAddress +  1] = (char) (((factor & 0x8000) >> 12) | // n9
                                                         (csCode & 0x07)); //n9, rp2..rp0
                programData[baseAddress +  2] = (char) ((factor & 0x0780) >> 7); // n4..n1
                programData[baseAddress +  3] = (char) ((factor & 0x7800) >> 11); // n8..n5
                programData[baseAddress +  4] = (char) (factor & 0x000f); // a3..a0
                programData[baseAddress +  5] = (char) (((factor & 0x0040) >> 3) | // n0
                                                        (thisChannel->bUseSTE ? 0: 4) | // ste
                                                        ((factor & 0x30) >> 4)); // n0, ste, a5, a4
                programData[baseAddress +  6] = (char) (ctcssCode & 0x000f); // fcg3..fcg0
                programData[baseAddress +  7] = (char) ((ctcssCode & 0x00f0) >> 4); // ccg3..ccg0
                // done with receiver part...
            } // no receive programmed for this channel

//  now do transmitter nibbles
            freq = thisChannel->nTxFrequency;
            if (freq == 0)
            { /* unprogrammed transmit channel */
                programData[baseAddress +  8] = (char) 0x00;
                programData[baseAddress +  9] = (char) 0x0f;
                programData[baseAddress + 10] = (char) 0x0f;
                programData[baseAddress + 11] = (char) 0x0f;
                programData[baseAddress + 12] = (char) 0x0f;
                programData[baseAddress + 13] = (char) 0x0b;
                programData[baseAddress + 14] = (char) 0x00;
                programData[baseAddress + 15] = (char) 0x00;
            } /* if freq == 0 */
            else
            { /* programmed channel */
                numChannels = i;

                if (!isUHF)
                { // try VHF channel spacing
                    cs = 5000; // 5 KHz channel spacing
                    csCode = 2;
                    factor = (freq / cs) & 0xffff;
                    if (factor * cs != freq)
                    { // did not work out for 5 KHz
                        cs = 6250; // 6.25 KHz
                        csCode = 3;
                        factor = (freq / cs) & 0xffff;
                    } // did not work out for 5 KHz.

                    syCode = 0;
                    if ((freq >= 135000000) && (freq < 138000000))
                        syCode = 0;
                    if ((freq >= 138000000) && (freq < 142000000))
                        syCode = 1;
                    if ((freq >= 142000000) && (freq < 147000000))
                        syCode = 2;
                    if ((freq >= 147000000) && (freq < 153000000))
                        syCode = 3;
                    if ((freq >= 159000000) && (freq < 155000000))
                        syCode = 0;
                    if ((freq >= 155000000) && (freq < 159000000))
                        syCode = 1;
                    if ((freq >= 159000000) && (freq < 166000000))
                        syCode = 2;
                    if ((freq >= 166000000) && (freq < 174000000))
                        syCode = 3;
                } // is VHF
                else
                { // try UHF channel spacing...
                    cs = 12500; // 3 * 4.16666667 KHz channel spacing
                    csCode = 0;
                    factor = (freq / cs) & 0xffff;
                    syCode = 0;
                    if ((freq >= 403000000) && (freq < 408000000))
                        syCode = 0;
                    if ((freq >= 408000000) && (freq < 417000000))
                        syCode = 1;
                    if ((freq >= 417000000) && (freq < 426000000))
                        syCode = 2;
                    if ((freq >= 426000000) && (freq < 440000000))
                        syCode = 3;
                    if ((freq >= 440000000) && (freq < 446000000))
                        syCode = 0;
                    if ((freq >= 446000000) && (freq < 452000000))
                        syCode = 1;
                    if ((freq >= 452000000) && (freq < 460000000))
                        syCode = 2;
                    if ((freq >= 460000000) && (freq < 470000000))
                        syCode = 3;
                } // is UHF

                ctcssCode = thisChannel->bUseInverseTxCode ? txCgCodesInverted[thisChannel->nTxCGCode]: txCgCodes[thisChannel->nTxCGCode];

                programData[baseAddress +  8] = (char) (((ctcssCode & 0x1000) >> 9) | 
                                                        ((syCode & 0x0003) << 1) | 
                                                        ((ctcssCode & 0x0100) >> 8)); // TD, SY1, SY0, CCG5
                programData[baseAddress +  9] = (char) (((factor & 0x8000) >> 12) | // n9
                                                         (thisChannel->nCCTCode & 0x07));
                programData[baseAddress + 10] = (char) ((factor & 0x0780) >> 7); // n4..n1
                programData[baseAddress + 11] = (char) ((factor & 0x7800) >> 11); // n8..n5
                programData[baseAddress + 12] = (char) (factor & 0x000f); // a3..a0
                programData[baseAddress + 13] = (char) (((factor & 0x0040) >> 3) | // n0
                                                        ((ctcssCode & 0x0200) >> 7) | // exfcg
                                                        ((factor & 0x0030) >> 4)); // n0, exfcg, a5, a4
                programData[baseAddress + 14] = (char) (ctcssCode & 0x000f); // fcg3..fcg0
                programData[baseAddress + 15] = (char) ((ctcssCode & 0x00f0) >> 4); // ccg3..ccg0
                // done with transmitter part...
            } // no transmit programmed for this channel
        } // programmed channel
    } /* for i */
    
} /* data2program() */

void program2data()
{
    int rp; // reference data
    int txSpacing, rxSpacing;
    int factor; 
    int isUHF = FALSE;
    int cgCode;
    int i, baseAddress;
    int ctcssCode;
    int freq;
    ChannelDataStruct *thisChannel;

    /* iterate through channels, converting radio program to radio data */
    for (i=0; i< NUM_CHANNELS; i++)
    {
        baseAddress = ((~(i + 1)) << 4) & 0x00f0; 
        thisChannel = &channels[i];

        rp = programData[baseAddress + 1] & 0x07;

	    if (rp == 7)
	    { /* unprogrammed channel */
	        thisChannel->nRxFrequency = 0;
            thisChannel->nTxFrequency = 0;
	        thisChannel->nRxCGCode = 0;
            thisChannel->nTxCGCode = 0;
            thisChannel->bUseInverseRxCode = FALSE;
            thisChannel->bUseInverseTxCode = FALSE;
	    } /* if programData[baseAddress + 5] == 0x0f */
	    else
	    { /* valid channel */
            switch (rp)
            {
                case 0: 
                    isUHF = true;
                    txSpacing = 12500; // 3 x 4166
                    rxSpacing = 6250;
                    break;
                case 1: // uhf narrow band
                    isUHF = true;
                    txSpacing = 12500; // 3 x 4166
                    rxSpacing = 6250;
                    break;
                case 2: // high band 
                    isUHF = false;
                    txSpacing = 5000;
                    rxSpacing = 5000;
                    break;
                case 3: // high band
                    isUHF = false;
                    txSpacing = 6250;
                    rxSpacing = 6250;
                    break;
                case 4: // do not use
                    isUHF = false;
                    txSpacing = 4167;
                    rxSpacing = 4167;
                    break;
                case 5: // do not use
                    isUHF = false;
                    txSpacing = 5000;
                    rxSpacing = 5000;
                    break;
                case 6: // do not use
                    isUHF = false;
                    txSpacing = 6250;
                    rxSpacing = 6250;
                    break;
                case 7: // blank channel
                    isUHF = true;
                    txSpacing = 0;
                    rxSpacing = 0;
                    break;
            } // switch 

            factor = (programData[baseAddress + 4] & 0x0f) + // a0..a3
                    ((programData[baseAddress + 5] & 0x03) << 4) + // a4,a5
                    ((programData[baseAddress + 5] & 0x08) << 3) +  // n0
                    ((programData[baseAddress + 2] & 0x0f) << 7) +  // n4..n1
                    ((programData[baseAddress + 3] & 0x0f) << 11) +  // n8..n5
                    ((programData[baseAddress + 1] & 0x08) << 12); //n9
            // get factor

            if ((factor == 0xffff) ||
                (factor == 0x0070)) // for broken NILES data...
            { // no RX on this channel
	            thisChannel->nRxFrequency = 0;
	            thisChannel->nRxCGCode = 0;
                thisChannel->bUseInverseRxCode = FALSE;
            }
            else
            { // rx is enabled on this channel
                switch (radioData.nBandCode)
                {
                    case BAND_VHF_45:
                    case BAND_VHF_575:
                        freq = (factor * rxSpacing) - radioData.nIFFrequency;
                        break;
                    case BAND_UHF:
                        freq = (factor * 2 * rxSpacing) + radioData.nIFFrequency;
                        break;
                    default:
                        freq = 0;
                } // switch 
                thisChannel->nRxFrequency = freq;

                ctcssCode = ((programData[baseAddress]     & 0x08) << 9) | // DCG indicator
                            ((programData[baseAddress]     & 0x01) << 8) | // high nibble of coarse
                            ((programData[baseAddress + 7] & 0x0f) << 4) | // low nibble of coarse
                             (programData[baseAddress + 6] & 0x0f);         // fine nibble 
                cgCode = lookupRXCGCode(ctcssCode);
                if (cgCode != -1)
                {
                    thisChannel->nRxCGCode = cgCode;
                    thisChannel->bUseInverseRxCode = FALSE;
                }
                else
                { // not found
                    cgCode = lookupRXCGInvertedCode(ctcssCode);
                    if (cgCode != -1)
                    {
                        thisChannel->nRxCGCode = cgCode;
                        thisChannel->bUseInverseRxCode = TRUE;
                    } // if cgCode != -1
                    else
                    {
                        thisChannel->nRxCGCode = 0;
                        thisChannel->bUseInverseRxCode = FALSE;
                    } // if cgCode != -1
                } // if cgCode != -1
               
                if ((programData[baseAddress + 5] & 0x04) != 0)
	            {
		            thisChannel->bUseSTE = FALSE;
	            } /* if programData[baseAddress + 5] ... */
	            else
	            {
		            thisChannel->bUseSTE = TRUE;
	            }  /* if programData[baseAddress + 5] ... */
            } // if factor != 0xffff (receive channel is programmed) 

            // now look at transmit settings for this channel...

            factor = (programData[baseAddress + 12] & 0x0f) +        // a0..a3
                    ((programData[baseAddress + 13] & 0x03) << 4) +  // a4,a5
                    ((programData[baseAddress + 13] & 0x08) << 3) +  // n0
                    ((programData[baseAddress + 10] & 0x0f) << 7) +  // n4..n1
                    ((programData[baseAddress + 11] & 0x0f) << 11) + // n8..n5
                    ((programData[baseAddress +  9] & 0x08) << 12);  //n9

            if ((factor == 0xffff) ||
                (factor == 0x0070)) // for broken NILES data
            { // no TX on this channel
	            thisChannel->nTxFrequency = 0;
	            thisChannel->nTxCGCode = 0;
                thisChannel->bUseInverseTxCode = FALSE;
            }
            else
            { // tx is enabled on this channel
                switch (radioData.nBandCode)
                {
                    case BAND_VHF_45:
                    case BAND_VHF_575:
                        freq = (factor * txSpacing);
                        break;
                    case BAND_UHF:
                        freq = (factor * txSpacing);
                        break;
                    default:
                        freq = 0;
                        break;
                } // switch

	            thisChannel->nTxFrequency = freq;

                ctcssCode = ((programData[baseAddress + 13] & 0x04) << 7) | // extra-fine bit
                            ((programData[baseAddress +  8] & 0x08) << 9) | // DCG indicator
                            ((programData[baseAddress +  8] & 0x01) << 8) | // high nibble of coarse
                            ((programData[baseAddress + 15] & 0x0f) << 4) | // low nibble of coarse
                             (programData[baseAddress + 14] & 0x0f);        // fine nibble 

                cgCode = lookupTXCGCode(ctcssCode);
                if (cgCode != -1)
                {
                    thisChannel->nTxCGCode = cgCode;
                    thisChannel->bUseInverseTxCode = FALSE;
                }
                else
                { // not found
                    cgCode = lookupTXCGInvertedCode(ctcssCode);
                    if (cgCode != -1)
                    {
                        thisChannel->nTxCGCode = cgCode;
                        thisChannel->bUseInverseTxCode = TRUE;
                    } // if cgCode != -1
                    else
                    {
                        thisChannel->nTxCGCode = 0;
                        thisChannel->bUseInverseTxCode = FALSE;
                    } // if cgCode != -1
                } // if cgCode != -1

                thisChannel->nCCTCode = programData[baseAddress + 9] & 0x07;
            } // if factor != 0xffff
	    } /* if rp != 7 */
    } /* for i */
} /* program2data() */
