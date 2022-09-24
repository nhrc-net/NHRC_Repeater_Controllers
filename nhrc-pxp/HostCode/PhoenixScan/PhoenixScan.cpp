/******************************************************************************/
/* Phoenix SX Scan Radio Programmer -- Copyright (C) 2001, 2004 NHRC LLC.     */
/******************************************************************************/

#define STRICT

#include "stdafx.h"
#include "PhoenixScan.h"
#include "PhoenixRadioData.h"

#define WINDOW_POSITION_TOP_LEFT      0
#define WINDOW_POSITION_TOP_CENTER    1
#define WINDOW_POSITION_TOP_RIGHT     2
#define WINDOW_POSITION_RIGHT_CENTER  3
#define WINDOW_POSITION_BOTTOM_RIGHT  4
#define WINDOW_POSITION_BOTTOM_CENTER 5
#define WINDOW_POSITION_BOTTOM_LEFT   6
#define WINDOW_POSITION_LEFT_CENTER   7
#define WINDOW_POSITION_CENTER        8

HINSTANCE hInstance;
HWND hwndMain;
HWND printDialog;
char helpFileName[128];                             /* the path/file name of the help file */
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
void SaveData(HWND hwnd);
void UpdateInterface (HWND hwnd);
void data2program(void);
void program2data(void);
int  lookupCGCode(int code);
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
char filter[256];

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
    char message[256];

#ifdef SCAN
    strcpy (filter, "Phoenix Scan Data Files (*.pxs)|*.pxs|Phoenix Data Files (*.pxd)|*.pxd|");
    fileHeader[0] = 0x01;
    fileHeader[1] = 0x01; /* program version, file format version */
#else
    strcpy(filter, "Phoenix Data Files (*.pxd)|*.pxd|Phoenix Scan Data Files (*.pxs)|*.pxs|");
    fileHeader[0] = 0x01;
    fileHeader[1] = 0x01; /* program version, file format version */
#endif
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
#ifdef SCAN
        wndclass.lpszClassName  = "PhoenixScan";
#else
        wndclass.lpszClassName  = "Phoenix";
#endif
        RegisterClass (&wndclass);
    } /* if !hPrevInstance */

    GetModuleFileName(hInstance, modulePath, MAX_PATH);
    i = strlen(modulePath);
    while ((i > 0) && (modulePath[i-1] != '\\'))
        i--;
    strncpy(path, modulePath, i);
    path[i] = '\0';

    strcpy(helpFileName, path);
    strcat(helpFileName, APPNAME);
    strcat(helpFileName, ".HLP");

    hwndMain = CreateDialog (hInstance, MAKEINTRESOURCE(DLG_MAIN), NULL, (DLGPROC) WndProc);
    if (hwndMain == NULL)
    {
        sprintf(message, "Could not create main window, error # %x", GetLastError());
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
    int i, item, temp;
    int ctlBase;
    HWND hwndCtl;
    ChannelDataStruct *thisChannel;
    LPDRAWITEMSTRUCT lpdis;    
    HDC hdc;
    HGDIOBJ oldObject;
    WORD controlID, notifyCode;
    OPENFILENAME ofn;
    char tempString[10];

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
	    } /* for i */

	    /* populate dropdowns */
	    /* initialize CCT dropdown */
	    hwndCtl = GetDlgItem(hwnd, CCT_COMBOBOX);
	    SendMessage(hwndCtl, CB_RESETCONTENT, 0, 0L);
	    for (i=0; i<NUM_CCT; i++)
	    {
		sprintf(tempString, "%3.1f", cctTimes[i]);
		SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) tempString);
	    } /* for i */
    
#ifdef SCAN
	    /* initialize scan mode dropdown */
	    hwndCtl = GetDlgItem(hwnd, SCAN_TYPE_COMBOBOX);
	    SendMessage(hwndCtl, CB_RESETCONTENT, 0, 0L);
	    for (i=0; i<NUM_SCAN_TYPES; i++)
	    {
		SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) scanTypeNames[i]);
	    } /* for i */
	    
	    /* initialize priority channel number */
	    hwndCtl = GetDlgItem(hwnd, PRIO_CHANNEL_COMBOBOX);
	    SendMessage(hwndCtl, CB_RESETCONTENT, 0, 0L);
	    for (i=0; i<NUM_CHANNELS; i++)
	    {
		sprintf(tempString, "%2d", i+1);
		SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) tempString);
	    } /* for i */
#endif

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
#ifdef SCAN
		    ofn.lpstrDefExt = "pxs";
#else
		    ofn.lpstrDefExt = "pxd";
#endif
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
#ifdef SCAN
		    ofn.lpstrDefExt = "pxs";
#else
		    ofn.lpstrDefExt = "pxd";
#endif
		    ofn.Flags = OFN_CREATEPROMPT | OFN_PATHMUSTEXIST |
			OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
			
		    if (GetSaveFileName(&ofn) == 0)
			return FALSE;
		    strcpy(filename, ofn.lpstrFile);
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
		    
#if 0
                case HELP_PROGRAM:
                    WinHelp(hwnd, helpFileName, HELP_CONTENTS, 0L);
                    break;
#endif
		    
                case HELP_ABOUT:
                    DialogBox (hInstance, "AboutDialog", hwnd, (DLGPROC) AboutDialogProc);
                    return(0);
		    
		case CCT_COMBOBOX:
		    if (notifyCode == CBN_SELCHANGE)
		    {
			i = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
			if (i != CB_ERR)
			{
			    radioData.nCCTTimeCode = i;
			    unsaved = TRUE;
			} /* if i != CB_ERR */
		    } /* if nofifyCode == CBM_SELCHANGE */
		    return (0);

#ifdef SCAN		    
		case SCAN_TYPE_COMBOBOX:
		    if (notifyCode == CBN_SELCHANGE)
		    {
			i = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
			if (i != CB_ERR)
			{
			    radioData.nScanTypeCode = i;
			    unsaved = TRUE;
			} /* if i != CB_ERR */
		    } /* if nofifyCode == CBM_SELCHANGE */
		    return (0);
		    
		case PRIO_CHANNEL_COMBOBOX:
		    if (notifyCode == CBN_SELCHANGE)
		    {
			i = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
			if (i != CB_ERR)
			{
			    radioData.nPriorityChannelNumber = i;
			    unsaved = TRUE;
			} /* if i != CB_ERR */
		    } /* if nofifyCode == CBM_SELCHANGE */
		    return (0);
#endif
		    
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
				    temp = DialogBoxParam(hInstance, "CGDialog", hwnd, (DLGPROC) CGDialogProc,
							  (LPARAM) thisChannel->nTxCGCode);
				    if (temp >= 0)
				    {
					thisChannel->nTxCGCode = temp;
					SetDlgItemText(hwnd, wParam, cgNames[temp]);
					unsaved = TRUE;
				    } /* if temp >= 0 */
				    break;
				case RX_TONE_CTL_OFFSET:
				    temp = DialogBoxParam(hInstance, "CGDialog", hwnd, (DLGPROC) CGDialogProc,
							  (LPARAM) thisChannel->nRxCGCode);
				    if (temp >= 0)
				    {
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
				    thisChannel->bUseCCT = thisChannel->bUseCCT ? 0 : 1;
				    SetWindowLong((HWND) lParam, GWL_USERDATA, thisChannel->bUseCCT);
				    InvalidateRect((HWND) lParam, NULL, FALSE);
				    unsaved = TRUE;
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
		{ /* checkbox has is selected */
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
    char tempString[256];
    switch (msg)
    {
        case WM_INITDIALOG:
            AdjustWindowPosition(hdlg, hwndMain, WINDOW_POSITION_CENTER);
#ifdef SCAN
            sprintf(tempString, "%s version %s\nNHRC Phoenix SX Scan Programmer.\n\n%s\nBuilt %s",
		    APPTITLE, VERSION, COPYRIGHT, BUILDDATE);
#else
            sprintf(tempString, "%s version %s\nNHRC Phoenix SX Programmer.\n\n%s\nBuilt %s",
		    APPTITLE, VERSION, COPYRIGHT, BUILDDATE);
#endif
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
		    EndDialog (hdlg, cgCode);
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
			cgCode = wID - CG_RB_0;
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
    char tempString[128];
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
#ifdef DEBUG    
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
	    
            wsprintf(tempString, "Printing channel %d of %d", channelNumber + 1, NUM_CHANNELS);
            SetWindowText(GetDlgItem(hwnd, PRINT_DIALOG_STATUS), tempString);
	    
	    /*                        "Ch   Transmit  Transmit Receive  Receive   STE   CCT" */
	    /*                        " #     Freq"     CG      Freq       CG              " */
	    /*                         xx   123.4567   ccccc   fff.ffff   ccccc   sss   sss */
	    thisChannel = &channels[channelNumber];
	    freq2string(thisChannel->nTxFrequency, txFreq);
	    freq2string(thisChannel->nRxFrequency, rxFreq);
#ifdef SCAN	    
	    len = sprintf(tempString, "%2d   %8s   %5s   %8s   %5s   %3s   %3s",
			  channelNumber + 1,
			  txFreq,
			  cgNames[thisChannel->nTxCGCode],
			  rxFreq,
			  cgNames[thisChannel->nRxCGCode],
			  (thisChannel->bUseSTE ? "YES" : "NO"),
			  (thisChannel->bUseCCT ? "YES" : "NO"));
#else
	    len = sprintf(tempString, "%2X   %8s   %5s   %8s   %5s   %3s   %3s",
			  channelNumber % 8 + 1 + ((channelNumber < 8) ? 0xa0 : 0xb0),
			  txFreq,
			  cgNames[thisChannel->nTxCGCode],
			  rxFreq,
			  cgNames[thisChannel->nRxCGCode],
			  (thisChannel->bUseSTE ? "YES" : "NO"),
			  (thisChannel->bUseCCT ? "YES" : "NO"));
#endif
	    TextOut(hDC, 0, yOffset, tempString ,len);
	    yOffset += lineHeight;

	    channelNumber++;
            if (channelNumber < NUM_CHANNELS)
            { /* more questions to print */
                PostMessage(hwnd, MSG_PRINT_NEXT, 0, (LPARAM) channelNumber);
            } /* if (channelNumber < NUM_CHANNELS */
            else
            { /* no more channels to print */
#ifdef DEBUG		
		yOffset += lineHeight;
		len = sprintf(tempString, "--------- Programming Data ----------");
		TextOut(hDC, 0, yOffset, tempString ,len);
		yOffset += lineHeight;
		len = sprintf(tempString, "Base  ------------ Offset -----------");
		TextOut(hDC, 0, yOffset, tempString ,len);
		yOffset += lineHeight;
		len = sprintf(tempString, "Addr  0 1 2 3 4 5 6 7 8 9 a b c d e f");
		TextOut(hDC, 0, yOffset, tempString ,len);
		yOffset += lineHeight;
		yOffset += lineHeight;
                for (i=0; i<256; i += 16)
                {
                    len = sprintf(tempString,
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
    char        *szDevice, *szDriver, *szOutput ;

    GetProfileString ("windows", "device", ",,,", szPrinter, 80) ;
    if (NULL != (szDevice = strtok (szPrinter, "," )) &&
        NULL != (szDriver = strtok (NULL,      ", ")) &&
        NULL != (szOutput = strtok (NULL,      ", ")))
        return(CreateDC (szDriver, szDevice, szOutput, NULL));
    return(0);
} /* GetPrinterDC() */

void PrintHeader(HDC hDC, 
                 int pageWidth, 
                 int pageHeight,
                 int charWidth, 
                 int lineHeight,
                 int *xOffset, 
                 int *yOffset,
                 int hMargin)
{
    char tempString[128];
    int x, y, len, width;
    SIZE size;
    len = sprintf(tempString, "NHRC Phoenix SX Scan Programmer");
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = (pageWidth + hMargin - width) / 2;
    y = lineHeight;
    TextOut(hDC, x, y, tempString, len);
    len = sprintf(tempString, "%s",  filename);
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = (pageWidth + hMargin - width) / 2;
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    y += lineHeight;
    x = 0;
    if (radioData.nReferenceFrequencyCode != 0)
    {
	len = sprintf(tempString, "Reference Oscillator %4.1f MHz",
		      referenceFrequencies[radioData.nReferenceFrequencyCode]);
	y += lineHeight;
	TextOut(hDC, x, y, tempString ,len);
    } /* if radioData.nReferenceFrequencyCode != 0 */
#ifdef SCAN    
    len = sprintf(tempString, "Scan Mode is %s", scanTypeNames[radioData.nScanTypeCode]);
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    len = sprintf(tempString, "Priority Channel is %d", radioData.nPriorityChannelNumber + 1);
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
#endif    
    len = sprintf(tempString, "Carrier Control Timer is %3.1f minutes.", cctTimes[radioData.nCCTTimeCode]);
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    len = sprintf(tempString, "Ch   Transmit  Transmit Receive  Receive   STE   CCT");
    y += lineHeight + lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    len = sprintf(tempString, " #     Freq      CG      Freq       CG              ");
    y += lineHeight;
    TextOut(hDC, x, y, tempString ,len);
    *yOffset = y + lineHeight + lineHeight;
} /* PrintHeader */

void PrintFooter(HDC hDC, 
                 int pageWidth, 
                 int pageHeight,
                 int charWidth, 
                 int lineHeight,
                 int pageNumber,
                 int hMargin)
{
    char tempString[128];
    char *months[12] = {"January","February","March","April","May","June","July","August","September","October","November","December"};
    int x, y, len, width;
    SIZE size;
    struct tm *localTime;
    time_t t;

    y = pageHeight - lineHeight - lineHeight;

    t = time(NULL);
    localTime = localtime(&t);

    len = sprintf(tempString, "%d %s %d", 
                  localTime->tm_mday,
                  months[localTime->tm_mon],
                  localTime->tm_year + 1900);
    TextOut(hDC, hMargin, y, tempString, len);

    len = sprintf(tempString, "%s version %s",  APPTITLE, VERSION);
    GetTextExtentPoint32(hDC, tempString, len, &size);
    width = size.cx;
    x = (pageWidth + hMargin - width) / 2;
    TextOut(hDC, x, y, tempString, len);

    len = sprintf(tempString, "Page %d",  pageNumber);
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
    char tempString[10];
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
		memset(tempString, 0, 10);
		if (clipHandle != NULL)
		{
		    clipText = (LPSTR) GlobalLock(clipHandle);
		    strncpy(tempString, clipText, 10);
		    tempString[9] = '\0';
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

    fileHandle = CreateFile(filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
			    FILE_ATTRIBUTE_NORMAL, NULL);
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
    char message[256];
    if (name[0] != 0 )
    {
	sprintf(message, "%s - %s", APPNAME, name);
    } /* if (filename[0] != 0) */
    else
    {
	sprintf(message, "%s", APPNAME);
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
	CheckDlgButton(hwnd, ctlBase + CCT_CTL_OFFSET, thisChannel->bUseCCT ? BST_CHECKED : BST_UNCHECKED);
	hwndCtl = GetDlgItem(hwnd, ctlBase + CCT_CTL_OFFSET);
	SetWindowLong(hwndCtl, GWL_USERDATA, thisChannel->bUseCCT);
	InvalidateRect(hwndCtl, NULL, FALSE);
    } /* for i */
    
    /* initialize CCT dropdown */
    hwndCtl = GetDlgItem(hwnd, CCT_COMBOBOX);
    SendMessage(hwndCtl, CB_SETCURSEL, (WPARAM) radioData.nCCTTimeCode, 0);
    
#ifdef SCAN
    /* initialize scan mode dropdown */
    hwndCtl = GetDlgItem(hwnd, SCAN_TYPE_COMBOBOX);
    SendMessage(hwndCtl, CB_SETCURSEL, (WPARAM) radioData.nScanTypeCode, 0);
    
    /* initialize priority channel number */
    hwndCtl = GetDlgItem(hwnd, PRIO_CHANNEL_COMBOBOX);
    SendMessage(hwndCtl, CB_SETCURSEL, (WPARAM) radioData.nPriorityChannelNumber, 0);
#endif
} /* UpdateInterface() */

int lookupCGCode(int code)
{
    int i;
    for (i=0; i< NUM_CG; i++)
    {
	if (cgCodesInverted[i] == code)
	    return i;
    } /* for i */
    return 0;
} /* lookupCGCode() */

void freq2string(int f, char *s)
{
    char buffer[10];
    sprintf(buffer, "%09d", f);
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
	channels[i].bUseCCT = FALSE;
    } /* for i */
    radioData.nCCTTimeCode = 0;
    radioData.nChannelSpacingCode = 0;
    radioData.nReferenceFrequencyCode = 0;
    radioData.nScanTypeCode = 0;
    radioData.nPriorityChannelNumber = 0;
    filename[0] = '\0';
} /* intializeData() */

int PodCommand(HWND hwnd, LPSTR command)
{
    HANDLE hCom;
    DWORD byteCount;
    BOOL status;
    DWORD dwError;
    char buffer[POD_READ_BUFFER_SIZE + 1];
    char message[400];

    hCom = OpenCommPort(hwnd);
    if (hCom == NULL)
	return FALSE;
    
    if (!CheckPod(hCom, hwnd))
    {
	CloseHandle(hCom);
	return FALSE;
    } /* if !CheckPod(...) */

    /* pod is there, and is the right version. read program EEPRM into pod. */
    status = WriteFile(hCom, command, strlen(command), &byteCount, NULL);
    if (!status || !byteCount)
    {
	dwError = GetLastError();
	sprintf(message, "Could not get Write comm port, error #d.", dwError);
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
    char message[400];
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
	sprintf(message, "Could not get Write comm port, error #d.", dwError);
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
    sprintf(message, "status = %d, byteCount=%d\n%s", status, byteCount, buffer);
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
	sprintf(message, "Checksum error. %02x %02x", checksum, receivedChecksum);
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
    char message[400];
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
    sprintf(message, "byteCount=%d\n%s", byteCount, buffer);
    MessageBox(hwnd, message, "Debug Info...", MB_OK);
#endif
    
    /* send outbound buffer */
    i = byteCount;
    status = WriteFile(hCom, buffer, i, &byteCount, NULL);
    if (!status || !byteCount)
    {
	dwError = GetLastError();
	sprintf(message, "Could not get Write comm port, error #d.", dwError);
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
	sprintf(message, "byteCount=%d\n%s", byteCount, buffer);
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
    char message[100];
    
    status = WriteFile(hCom, "v", 1, &byteCount, NULL);
    if (!status || !byteCount)
    {
	dwError = GetLastError();
	sprintf(message, "Could not get Write comm port, error #d.", dwError);
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
	sprintf(message, "Unknown pod version or serial device:\n%s", buffer);
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
    char message[128];
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
	sprintf(message, "Could not open %s, error #d.", comPort, dwError);
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
	sprintf(message, "Could not get CommState, error #d.", dwError);
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
	sprintf(message, "Could not set CommState, error #d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
	CloseHandle(hCom);
	return NULL;
    }  /* if !fSuccess */

    fSuccess = GetCommTimeouts(hCom, &commtimeouts);
    if (!fSuccess)
    {
	/* Handle the error. */
	dwError = GetLastError();
	sprintf(message, "Could not get CommTimeouts, error #d.", dwError);
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
	sprintf(message, "Could not set CommTimeouts, error #d.", dwError);
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

#ifdef SCAN

/*******************/
/*******************/
/*** SCAN RADIOS ***/
/*******************/
/*******************/

/* make this program's data into radio eeprom program data */
void data2program()
{
    int i, baseAddress, x, csCode, ctcssCode;
    int freq, cs; /* in hertz! */
    ChannelDataStruct *thisChannel;
    int numChannels = -1;
    int isUHF;

    /* initialize data */
    for (i=0; i<PROGRAM_DATA_SIZE; i++)
        programData[i]=0;

    /* iterate through channels, converting to radio program */
    for (i=0; i< NUM_CHANNELS; i++)
    {
        baseAddress = (i + 1) * 16 % 256;
        thisChannel = &channels[i];

        freq = thisChannel->nRxFrequency;
        if (freq == 0)
        { /* unprogrammed channel */
            programData[baseAddress + 5] = 0x0f;
        } /* if freq == 0 */
        else
        { /* programmed channel */
	    if (freq > 400000000)
		isUHF = TRUE;
	    else
		isUHF = FALSE;
            numChannels = i;
            freq = freq + IF_FREQUENCY_HZ;
	    cs = 5000;
	    csCode = 2;
	    x = (freq / cs) & 0xffff;
	    if (x * cs != freq)
	    {
		if (isUHF)
		{
		    cs = 12500;
		} /* if isUHF */
		else
		{
		    cs = 4166;
		} /* if isUHF */
		csCode = 1;
		x = (freq / cs) & 0xffff;
		if (x * cs != freq)
		{
		    cs = 6250;
		    csCode = 3;
		    x = (freq / cs) & 0xffff;
		} /* if x * cs != freq */
	    } /* if x * cs != freq */
	    
            if (radioData.nReferenceFrequencyCode == 1)
            { /* 13.8 ref osc */
                csCode += 4;
            } /* if radioData.nReferenceFrequencyCode == 1 */
            ctcssCode = cgCodesInverted[thisChannel->nRxCGCode];
            if (thisChannel->bUseSTE)
                ctcssCode += 0x08;
            programData[baseAddress + 0] = 0;
            programData[baseAddress + 1] = (char) (((x >> 12) & 0x08) + csCode);
            programData[baseAddress + 2] = (char) ((x >> 7) & 0x0f);
            programData[baseAddress + 3] = (char) ((x >> 11) & 0x0f);
            programData[baseAddress + 4] = (char) (x & 0x0f);
            programData[baseAddress + 5] = (char) (((x >> 3) & 0x08) + ((x >> 4) & 0x03));
            programData[baseAddress + 6] = (char) ((ctcssCode >> 4) & 0x0f);
            programData[baseAddress + 7] = (char) (ctcssCode & 0x0f);
        } /* if f == 0 */

        freq = thisChannel->nTxFrequency;
        if (freq == 0)
        { /* unprogrammed channel */
            programData[baseAddress + 13] = 0x0f;
        } /* if f == 0 */
        else
        { /* programmed channel */
            numChannels = i;
            x = freq / cs;
            ctcssCode = cgCodesInverted[thisChannel->nTxCGCode];
            if (thisChannel->bUseSTE)
                ctcssCode += 0x08;
            programData[baseAddress +  8] = (char) 0;
            programData[baseAddress +  9] = (char) (((x >> 12) & 0x08) +
                                                    (thisChannel->bUseCCT ? 4 : 0));
            programData[baseAddress + 10] = (char) ((x >> 7) & 0x0f);
            programData[baseAddress + 11] = (char) ((x >> 11) & 0x0f);
            programData[baseAddress + 12] = (char) (x & 0x0f);
            programData[baseAddress + 13] = (char) (((x >> 3) & 0x08) + ((x >> 4) & 0x03));
            programData[baseAddress + 14] = (char) ((ctcssCode >> 4) & 0x0f);
            programData[baseAddress + 15] = (char) (ctcssCode & 0x0f);
        } /* if f == 0 */
    } /* for i */
    
    /* set radio settings */
    programData[0x00] = (char) scanTypeCodes[radioData.nScanTypeCode]; // scan option code, f for front programmable.
    if (radioData.nScanTypeCode == FIXED_PRIORITY)
	programData[0x40] = (char) radioData.nPriorityChannelNumber; // priority channel number for fixed priority.
    else
	programData[0x40] = 0; // priority channel number for NOT fixed priority.
    programData[0x80] = (char) numChannels; // number of channels in radio.
    programData[0xe0] = (char) 0x00; // priority channel code, must be zero.
    programData[0xf8] = (char) radioData.nCCTTimeCode; // CCT Time code.
} /* data2program() */

/* make this radio eeprom program data into this program's data */
void program2data()
{
    int i, baseAddress, x, r, ctcssCode, freq, cs;
    ChannelDataStruct *thisChannel;

    /* iterate through channels, converting radio program to radio data */
    for (i=0; i< NUM_CHANNELS; i++)
    {
        baseAddress = (i + 1) * 16 % 256;
        thisChannel = &channels[i];

	if (programData[baseAddress + 5] == 0x0f)
	{ /* unprogrammed channel */
	    thisChannel->nRxFrequency = 0;
	    thisChannel->nRxCGCode = 0;	    
	} /* if programData[baseAddress + 5] == 0x0f */
	else
	{ /* valid channel */
	    /* get R */
	    r = programData[baseAddress + 1] & 0x07;
	    /* get X */
	    x =	((programData[baseAddress + 1] & 0x08) << 12) |  // x15
		((programData[baseAddress + 3] & 0x0f) << 11) |  // x14..x11
		((programData[baseAddress + 2] & 0x0f) << 7)  |  // x10..x7
		((programData[baseAddress + 5] & 0x08) << 3)  |  // x6
		((programData[baseAddress + 5] & 0x03) << 4)  |  // x5..x4
		(programData[baseAddress + 4] & 0x0f);           // x3..x0
		if (r & 0x04)
	    { /* ref osc 13.8 */
		radioData.nReferenceFrequencyCode = 1;
	    } /* if r & 0x04 */
	    else
	    { /* ref osc 13.2 */
		radioData.nReferenceFrequencyCode = 0;
	    } /* if r & 0x04 */
	    r = r & 0x03;

	    switch (r)
	    {
		case 2:  /* most common channel spacing */
		    cs = 5000;
		    freq = cs * x;
		    break;

		case 3: 
		    cs = 6250;
		    freq = cs * x;
		    break;
		default: // either .004166 or .0125.
		    cs = 12500;
		    freq = cs * x;
		    if ((freq < 215000000) || (freq > 515000000))
		    { /* not a valid range for UHF, assume VHF channel spacing */
			cs = 4166;
			freq = cs * x;
		    } /* if freq < 215000000 || freq > 515000000 */
		    break;
	    } /* switch */
	    
	    thisChannel->nRxFrequency = (freq - IF_FREQUENCY_HZ);

            ctcssCode = (programData[baseAddress + 6] << 4) | programData[baseAddress + 7];
	    if (ctcssCode & 0x08)
	    {
		thisChannel->bUseSTE = TRUE;
		ctcssCode = ctcssCode & 0xf7;
	    } /* if ctcssCode & 0x08 */
	    else
	    {
		thisChannel->bUseSTE = FALSE;
	    } /* if ctcssCode & 0x08 */
	    thisChannel->nRxCGCode = lookupCGCode(ctcssCode);
	} /* if programData[baseAddress + 5] == 0x0f */

	if (programData[baseAddress + 13] == 0x0f)
	{ /* unprogrammed channel */
	    thisChannel->nTxFrequency = 0;
	    thisChannel->nTxCGCode = 0;
	    thisChannel->bUseCCT = FALSE;
	    thisChannel->bUseSTE = FALSE;
	} /* if programData[baseAddress + 5] == 0x0f */
	else
	{ /* valid channel */
	    if (programData[baseAddress + 9] & 0x04)
	    {
		thisChannel->bUseCCT = TRUE;
	    } /* if programData[baseAddress + 9] & 0x04 */
	    else
	    {
		thisChannel->bUseCCT = FALSE;
	    } /* if programData[baseAddress + 9] & 0x04 */
	    /* get X */
	    x =	((programData[baseAddress + 9] & 0x08) << 12) |  // x15
		((programData[baseAddress + 11] & 0x0f) << 11) |  // x14..x11
		((programData[baseAddress + 10] & 0x0f) << 7)  |  // x10..x7
		((programData[baseAddress + 13] & 0x08) << 3)  |  // x6
		((programData[baseAddress + 13] & 0x03) << 4)  |  // x5..x4
		 (programData[baseAddress + 12] & 0x0f);          // x3..x0
	    freq = cs * x;
	    thisChannel->nTxFrequency = freq;
	    
            ctcssCode = (programData[baseAddress + 14] << 4) | programData[baseAddress + 15];
	    if (ctcssCode & 0x08)
	    {
		thisChannel->bUseSTE = TRUE;
		ctcssCode = ctcssCode & 0xf7;
	    } /* if ctcssCode & 0x08 */
	    else
	    {
		thisChannel->bUseSTE = FALSE;
	    } /* if ctcssCode & 0x08 */
	    thisChannel->nTxCGCode = lookupCGCode(ctcssCode);
	} /* if programData[baseAddress + 5] == 0x0f */
    } /* for i */
    radioData.nPriorityChannelNumber = 0;	
    switch (programData[0x00])
    {
	case 0x01:
	    radioData.nScanTypeCode = SELECTED_CHANNEL_PRIORITY;
	    break;
	case 0x0f:
	    radioData.nScanTypeCode = FRONT_PANEL_PRIORITY;
	    break;
	default:
	    radioData.nScanTypeCode = FIXED_PRIORITY;
	    radioData.nPriorityChannelNumber = programData[0x40] & 0x0f;	
	    break;
    } /* switch */
    radioData.nCCTTimeCode = programData[0xf8] & 0x0f;
} /* program2data() */

#else /* ifdef SCAN */

/***********************/
/***********************/
/*** NON-SCAN RADIOS ***/
/***********************/
/***********************/

/* make this program's data into radio eeprom program data */
void data2program()
{
    int mode, i, baseAddress, x, csCode, ctcssCode, cgType;
    int freq, cs; /* in hertz! */
    ChannelDataStruct *thisChannel;
    int numChannels;
    int isUHF;

    /* initialize data */
    for (i=0; i<PROGRAM_DATA_SIZE; i++)
        programData[i]=0;

    /* iterate through modes & channels, converting to radio program */
    for (mode = 0; mode < NUM_MODES; mode++)
    {
	numChannels = 0;
	for (i=0; i < NUM_CHANNELS_MODE; i++)
	{
	    baseAddress = (i + 1) * 0x20 % 0x100;
	    if (mode == 1)
		baseAddress += 0x08; /* for mode B, address is +8h */
	    
	    thisChannel = &channels[mode * 8 + i];
	    freq = thisChannel->nRxFrequency;
	    if (freq == 0)
	    { /* unprogrammed channel */
		programData[baseAddress + 0x5] = 0x0f;
	    } /* if freq == 0 */
	    else
	    { /* programmed channel */
		if (freq > 400000000)
		    isUHF = TRUE;
		else
		    isUHF = FALSE;
		numChannels = i;
		freq = freq + IF_FREQUENCY_HZ;
		cs = 5000;
		csCode = 2;
		x = (freq / cs) & 0xffff;
		if (x * cs != freq)
		{
		    if (isUHF)
		    {
			cs = 12500;
		    } /* if isUHF */
		    else
		    {
			cs = 4166;
		    } /* if isUHF */
		    csCode = 1;
		    x = (freq / cs) & 0xffff;
		    if (x * cs != freq)
		    {
			cs = 6250;
			csCode = 3;
			x = (freq / cs) & 0xffff;
		    } /* if x * cs != freq */
		} /* if x * cs != freq */
		
		if (radioData.nReferenceFrequencyCode == 1)
		{ /* 13.8 ref osc */
		    csCode += 4;
		} /* if radioData.nReferenceFrequencyCode == 1 */
		ctcssCode = cgCodesInverted[thisChannel->nRxCGCode];
		cgType = 0;
		if (thisChannel->nRxCGCode >= FIRST_DCG)
		    cgType += 0x08;
		if (thisChannel->nTxCGCode >= FIRST_DCG)
		    cgType += 0x04;
		if ((cgType != 0x0c) && (thisChannel->bUseSTE))
		    cgType += 0x02;
		programData[baseAddress + 0x0] = (char) cgType;
		programData[baseAddress + 0x1] = (char) (((x >> 12) & 0x08) + csCode);
		programData[baseAddress + 0x2] = (char) ((x >> 7) & 0x0f);
		programData[baseAddress + 0x3] = (char) ((x >> 11) & 0x0f);
		programData[baseAddress + 0x4] = (char) (x & 0x0f);
		programData[baseAddress + 0x5] = (char) (((x >> 3) & 0x08) + ((x >> 4) & 0x03));
		programData[baseAddress + 0x6] = (char) ((ctcssCode >> 4) & 0x0f);
		programData[baseAddress + 0x7] = (char) (ctcssCode & 0x0f);
	    } /* if f == 0 */
	    
	    freq = thisChannel->nTxFrequency;
	    if (freq == 0)
	    { /* unprogrammed channel */
		programData[baseAddress + 0x15] = 0x0f;
	    } /* if f == 0 */
	    else
	    { /* programmed channel */
		numChannels = i;
		x = freq / cs;
		ctcssCode = cgCodesInverted[thisChannel->nTxCGCode];
		programData[baseAddress + 0x10] = (char) (thisChannel->bUseCCT ? 0x8 : 0x0);
		programData[baseAddress + 0x11] = (char) ((x >> 12) & 0x08);
		programData[baseAddress + 0x12] = (char) ((x >> 7) & 0x0f);
		programData[baseAddress + 0x13] = (char) ((x >> 11) & 0x0f);
		programData[baseAddress + 0x14] = (char) (x & 0x0f);
		programData[baseAddress + 0x15] = (char) (((x >> 3) & 0x08) + ((x >> 4) & 0x03));
		programData[baseAddress + 0x16] = (char) ((ctcssCode >> 4) & 0x0f);
		programData[baseAddress + 0x17] = (char) (ctcssCode & 0x0f);
	    } /* if f == 0 */
	} /* for i */
	if (mode == 0)
	    programData[0xf1] = (char) (programData[0xf1] | numChannels);
	else
	    programData[0x19] = (char) (programData[0x19] | numChannels);
    } /* for mode */
    /* set radio settings */
    programData[0x11] = (char) (programData[0x11] | radioData.nCCTTimeCode); // CCT Time code.
} /* data2program() */

/* make this radio eeprom program data into this program's data */
void program2data()
{
    int mode, i, baseAddress, x, r, ctcssCode, freq, cs, cgType;
    ChannelDataStruct *thisChannel;

    /* iterate through modes & channels, converting to radio program */
    for (mode = 0; mode < NUM_MODES; mode++)
    {
	for (i=0; i< NUM_CHANNELS_MODE; i++)
	{
	    baseAddress = (i + 1) * 0x20 % 0x100;
	    if (mode == 1)
		baseAddress += 0x08; /* for mode B, address is +8h */
	    
	    thisChannel = &channels[mode * 8 + i];

	    if (programData[baseAddress + 0x05] == 0x0f)
	    { /* unprogrammed channel */
		thisChannel->nRxFrequency = 0;
		thisChannel->nRxCGCode = 0;	    
	    } /* if programData[baseAddress + 5] == 0x0f */
	    else
	    { /* valid channel */
		/* get R */
		r = programData[baseAddress + 1] & 0x07;
		/* get X */
		x = ((programData[baseAddress + 0x01] & 0x08) << 12) |  // x15
		    ((programData[baseAddress + 0x03] & 0x0f) << 11) |  // x14..x11
		    ((programData[baseAddress + 0x02] & 0x0f) << 7)  |  // x10..x7
		    ((programData[baseAddress + 0x05] & 0x08) << 3)  |  // x6
		    ((programData[baseAddress + 0x05] & 0x03) << 4)  |  // x5..x4
		     (programData[baseAddress + 0x04] & 0x0f);          // x3..x0
		if (r & 0x04)
		{ /* ref osc 13.8 */
		    radioData.nReferenceFrequencyCode = 1;
		} /* if r & 0x04 */
		else
		{ /* ref osc 13.2 */
		    radioData.nReferenceFrequencyCode = 0;
		} /* if r & 0x04 */
		r = r & 0x03;
		
		switch (r)
		{
		    case 2:  /* most common channel spacing */
			cs = 5000;
			freq = cs * x;
			break;
		    case 3: 
			cs = 6250;
			freq = cs * x;
			break;
		    default: // either .004166 or .0125.
			cs = 12500;
			freq = cs * x;
			if ((freq < 215000000) || (freq > 515000000))
			{ /* not a valid range for UHF, assume VHF channel spacing */
			    cs = 4166;
			    freq = cs * x;
			} /* if freq < 215000000 || freq > 515000000 */
			break;
		} /* switch */
		
		thisChannel->nRxFrequency = (freq - IF_FREQUENCY_HZ);
		
		ctcssCode = (programData[baseAddress + 0x06] << 4) | programData[baseAddress + 0x07];

		cgType = programData[baseAddress + 0x00];
		thisChannel->bUseSTE = (cgType & 0x02) ? TRUE : FALSE;

		thisChannel->nRxCGCode = lookupCGCode(ctcssCode);
	    } /* if programData[baseAddress + 5] == 0x0f */
	    
	    if (programData[baseAddress + 0x15] == 0x0f)
	    { /* unprogrammed channel */
		thisChannel->nTxFrequency = 0;
		thisChannel->nTxCGCode = 0;
		thisChannel->bUseCCT = FALSE;
		thisChannel->bUseSTE = FALSE;
	    } /* if programData[baseAddress + 0x15] == 0x0f */
	    else
	    { /* valid channel */
		if (programData[baseAddress + 0x10] & 0x08)
		{
		    thisChannel->bUseCCT = TRUE;
		} /* if programData[baseAddress + 9] & 0x04 */
		else
		{
		    thisChannel->bUseCCT = FALSE;
		} /* if programData[baseAddress + 9] & 0x04 */
		/* get X */
		x = ((programData[baseAddress + 0x11] & 0x08) << 12) |  // x15
		    ((programData[baseAddress + 0x13] & 0x0f) << 11) |  // x14..x11
		    ((programData[baseAddress + 0x12] & 0x0f) << 7)  |  // x10..x7
		    ((programData[baseAddress + 0x15] & 0x08) << 3)  |  // x6
		    ((programData[baseAddress + 0x15] & 0x03) << 4)  |  // x5..x4
		     (programData[baseAddress + 0x14] & 0x0f);          // x3..x0
		freq = cs * x;
		thisChannel->nTxFrequency = freq;
		
		ctcssCode = (programData[baseAddress + 0x16] << 4) | programData[baseAddress + 0x17];
		thisChannel->nTxCGCode = lookupCGCode(ctcssCode);
	    } /* if programData[baseAddress + 5] == 0x0f */
	} /* for i */
    } /* for mode */
    radioData.nCCTTimeCode = programData[0x11] & 0x07;
} /* program2data() */

#endif /* ifdef SCAN */
