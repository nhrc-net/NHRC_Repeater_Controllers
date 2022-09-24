// Programmer.cpp : NHRC-3.1 Repeater Controller Programmer
// Copyright (C) 2012 NHRC LLC
//

#include "stdio.h"

#include "stdafx.h"
#include "resource.h"
#include "Programmer.h"

#define COMM_TIMER 1

#define WORKSTRING_LENGTH 256

// Foward declarations of functions included in this code module:
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    AboutDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    ControlOpDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    CWIDDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    CWEditProc(HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK    DTMFEditProc(HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK    GetDataTransferDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    PrefixesDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    SendDataTransferDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    TimersDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    CourtesyTonesDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    SelectComportDialogBoxProc(HWND, UINT, WPARAM, LPARAM);

HANDLE OpenCommPort(HWND hwnd);
char bin2hex(BYTE b);
BYTE hex2bin(char c);
char bin2dtmf(BYTE b);
BYTE dtmf2bin(char c);
void ReadData(HWND hwnd);
void SaveData(HWND hwnd);
void initializeData(void);
int isDTMF(char c);
int isValidCWChar(char c);
void SetWindowTitle(HWND hwnd, LPSTR name);
char cwByte2char(BYTE b);
BYTE char2cwByte(char c);
int cwctByte2index(BYTE b);
BYTE index2cwct(int i);
int toneByte2index(BYTE b);
BYTE index2toneByte(int i);
void getControlGroup(HWND hDlg);
void setControlGroup(HWND hDlg);
void getExchangeRestrictions(HWND hDlg);
void setExchangeRestrictions(HWND hDlg);
void getCourtesyToneDialogData(HWND hDlg);
void setCourtesyToneDialogData(HWND hDlg);
int isBitSet(BYTE byte, int bit);

// Global Variables:
HINSTANCE hInst;                                    // current instance
HWND hWndMain;
int xferAddress = 0;
BOOL unsaved;
BOOL dataLoaded;
char path[MAX_PATH];                                // the path of the program  directory 
char filename[MAX_PATH];
char helpFileName[MAX_PATH];                             /* the path/file name of the help file */
BYTE eepromData[EEPROM_SIZE];
#define TEXT_LENGTH 1024
#define FILTER_LENGTH 64
char filter[FILTER_LENGTH];
const char * dtmfdigits = "0123456789ABCD*#";
const LPSTR timerNames[] = {"Hang Timer Long",
                            "Hang Timer Short",
                            "ID Timer",
                            "DTMF Access Mode Timer",
                            "Timeout Timer Long",
                            "Timeout Timer Short",
							"Fan Timer",
							"Tail Message Counter",
							"Alarm Announcement Timer",
                            "CW Pitch",
                            "CW Speed"};

const LPSTR courtesyToneNames[] = {"Courtesy Tone 0",
                                   "Courtesy Tone 1",
                                   "Courtesy Tone 2",
                                   "Courtesy Tone 3",
                                   "Courtesy Tone 4",
                                   "Courtesy Tone 5",
                                   "Courtesy Tone 6",
                                   "Controller Unlocked Courtesy Tone"};

const LPSTR controlGroupNames[] = {"Group 0 - Repeater Access Control",
                                   "Group 1 - More Repeater Control",
                                   "Group 2 - Messages and Setup",
                                   "Group 3 - ID and Beacon",
                                   "Group 4 - Digital Outputs and Alarm",
                                   "Group 5 - Digital Outputs Pulse Mode",
                                   "Group 6 - Programming Write Protect",
                                   "Group 7 - Control Op Group Access"};

const LPSTR controlItemNames[] = { "Repeater Enable",                 // 0.0
                                   "COR and CTCSS",                   // 0.1
                                   "Key up delay",                    // 0.2
                                   "Hang Timer Enable",               // 0.3
                                   "Long Hang Timer Select",          // 0.4
                                   "DTMF Access Mode",                // 0.5
                                   "Courtesy Tone Enable",            // 0.6
                                   "Control Op CTCSS Required",       // 0.7
                                   
                                   "Time Out Timer Enable",           // 1.0
                                   "Long Time Out Timer Select",      // 1.1
                                   "Dual Squelch Enable",             // 1.2
                                   "DTMF Muting Enable",              // 1.3
                                   "Tail Message 1 Enable",           // 1.4
                                   "Tail Message 2 Enable",           // 1.5
                                   "Simplex Repeater Mode",           // 1.6
                                   "Simplex Voice ID Enable",         // 1.7

                                   "Enable Initial Voice ID",         // 2.0
                                   "Enable  Normal Voice ID 1",       // 2.1
                                   "Enable  Normal Voice ID 2",       // 2.2
                                   "Allow ID Stomp by key-up",        // 2.3
                                   "Enable Voice Time Out Message",   // 2.4
                                   "Fan Control Enable",              // 2.5
                                   "(Fan) Digital Output Control",    // 2.6
                                   "Audio Delay Installed",           // 2.7
                                   
                                   "European ID Mode",                // 3.0
                                   "European End ID Enable",          // 3.1
                                   "reserved",                        // 3.2
                                   "reserved",                        // 3.3
                                   "Reserved",                        // 3.4
                                   "ID Beacon Mode Enable",           // 3.5
                                   "NO CW ID Mode Enable",            // 3.6
                                   "NO ID mode",                      // 3.7
                                   
                                   "Digital Output 1 Pulse Mode",     // 4.0
                                   "Digital Output 2 Pulse Mode",     // 4.1
                                   "Reserved",                        // 4.2
                                   "Reserved",                        // 4.3
                                   "Reserved",                        // 4.4
                                   "Reserved",                        // 4.5
                                   "Alarm Input Enable",              // 4.6
                                   "Alarm Latch Mode",                // 4.7
                                   
                                   "Digital Output 1 Control",        // 5.0
                                   "Digital Output 2 Control",        // 5.1
                                   "Reserved",                        // 5.2
                                   "Reserved",                        // 5.3
                                   "Reserved",                        // 5.4
                                   "Reserved",                        // 5.5
                                   "Reserved",                        // 5.6
                                   "Reserved",                        // 5.7
                                                                 
                                   "Write Protect Control Groups",          // 6.0
                                   "Write Protect Prefixes",                // 6.1
                                   "Write Protect Timers",                  // 6.2
                                   "Reserved",                              // 6.3
                                   "Reserved",                              // 6.4
                                   "Reserved",                              // 6.5
                                   "Write Protect CW and Courtesy Tones",   // 6.6
                                   "WRite Protect Stored Voice Messages",   // 6.7
                                   
                                   "Group 0 Access Enable",  // 7.0
                                   "Group 1 Access Enable",  // 7.1
                                   "Group 2 Access Enable",  // 7.2
                                   "Group 3 Access Enable",  // 7.3
                                   "Group 4 Access Enable",  // 7.4
                                   "Group 5 Access Enable",  // 7.5
                                   "Reserved",               // 7.6
                                   "Reserved"};              // 7.0

const LPSTR tones[] = {"no tone",       // 00 
                       "F4",            // 01 
                       "F#4",           // 02 
                       "G4",            // 03 
                       "G#4",           // 04 
                       "A4",            // 05 
                       "A#4",           // 06 
                       "B4",            // 07 
                       "C5",            // 08 
                       "C#5",           // 09 
                       "D5",            // 10 
                       "D#5",           // 11 
                       "E5",            // 12 
                       "F5",            // 13 
                       "F#5",           // 14 
                       "G5",            // 15 
                       "G#5",           // 16 
                       "A5",            // 17 
                       "A#5",           // 18 
                       "B5",            // 19 
                       "C6",            // 20 
                       "C#6",           // 21 
                       "D6",            // 22 
                       "D#6",           // 23 
                       "E6",            // 24 
                       "F6",            // 25 
                       "F#6",           // 26 
                       "G6",            // 27 
                       "G#6",           // 28 
                       "A6",            // 29 
                       "A#6",           // 30 
                       "B6"};           // 31 

// CW generation characters
const char cwIndex[] = " !#=/0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.";
const BYTE cwMask[] = { 0x00,  // space
                        0x68,  // ! SK
                        0x2a,  // # AR
                        0x31,  // = BT
                        0x29,  // /
                        0x3f,  // 0
                        0x3e,  // 1
                        0x3c,  // 2
                        0x38,  // 3
                        0x30,  // 4
                        0x20,  // 5
                        0x21,  // 6
                        0x23,  // 7
                        0x27,  // 8
                        0x2f,  // 9
                        0x06,  // a
                        0x11,  // b
                        0x15,  // c
                        0x09,  // d
                        0x02,  // e
                        0x14,  // f
                        0x0b,  // g
                        0x10,  // h
                        0x04,  // i
                        0x1e,  // j
                        0x0d,  // k
                        0x12,  // l
                        0x07,  // m
                        0x05,  // n
                        0x0f,  // o
                        0x16,  // p
                        0x1b,  // q
                        0x0a,  // r
                        0x08,  // s
                        0x03,  // t
                        0x0c,  // u
                        0x18,  // v
                        0x0e,  // w
                        0x19,  // x
                        0x1d,  // y
                        0x13,  // z
						0x6a}; // .
const char ctcwmap[] = "0123456789~ /#=!~~~~~ABC~~~~~~~DEF~~~~~~~GHI~~~~~~~JKL~~~~~~~MNO~~~~~~QPRS~~~~~~~TUV~~~~~ZWXY~~~~~~~";

// used for bit set and clear operations
const BYTE bitValues[] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};

#define LAST_COMPORT 8
#define MAX_COMPORT_LENGTH 8

char comport[MAX_COMPORT_LENGTH] = "COM1:";

int APIENTRY WinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPSTR     lpCmdLine,
                     int       nCmdShow)
{
    WNDCLASSEX wcex;
    MSG msg;
    HACCEL hAccelTable;
    int i;

    initializeData();
    
    /* initialize file load/save template */
	strncpy_s(filter, FILTER_LENGTH, "NHRC-3.1 Controller Data (*.bin)|*.bin|", _TRUNCATE);

    for (i = 0; filter[i] != '\0'; i++)
    {
        if (filter[i] == '|')
            filter[i] = '\0';
    }
    unsaved = FALSE;
    dataLoaded = FALSE;
    
    if (!hPrevInstance)
    {
        wcex.cbSize         = sizeof(WNDCLASSEX); 
        wcex.style		    = CS_HREDRAW | CS_VREDRAW;
        wcex.lpfnWndProc	= (WNDPROC)WndProc;
        wcex.cbClsExtra		= 0;
        wcex.cbWndExtra		= 0;
        wcex.hInstance		= hInstance;
        wcex.hIcon			= LoadIcon(hInstance, (LPCTSTR)IDI_A_UPROGRAMMER);
        wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
        wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
        wcex.lpszMenuName	= (LPCSTR)IDC_UPROGRAMMER;
        wcex.lpszClassName	= "NHRC-3.1-PROGRAMMER";
        wcex.hIconSm		= LoadIcon(wcex.hInstance, (LPCTSTR)IDI_N);
        RegisterClassEx(&wcex);
    } // if !hPrevInstance
    
    // Perform application initialization:
    if (!InitInstance (hInstance, nCmdShow)) 
    {
        return FALSE;
    }

    hAccelTable = LoadAccelerators(hInstance, (LPCTSTR)IDC_UPROGRAMMER);

    // Main message loop:
    while (GetMessage(&msg, NULL, 0, 0)) 
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg)) 
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }
    return msg.wParam;
} // WinMain


//
//   FUNCTION: InitInstance(HANDLE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
    HWND hWnd;
    hInst = hInstance; // Store instance handle in our global variable
    hWnd = CreateWindow("NHRC-3.1-PROGRAMMER", // class name
		                "NHRC-3.1 Programmer", // Window Title
						WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,  // style
                        CW_USEDEFAULT,        // x
						CW_USEDEFAULT,        // y
						400,                  // width
						220,                  // height
						NULL,                 // parent
						NULL,                 // menu
						hInstance,            // application instance
						NULL);                // window creation data

    if (!hWnd)
    {
        return FALSE;
    }

    ShowWindow(hWnd, nCmdShow);
    UpdateWindow(hWnd);

    return TRUE;
}

//
//  FUNCTION: WndProc(HWND, unsigned, WORD, LONG)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND	- process the application menu
//  WM_PAINT	- Paint the main window
//  WM_DESTROY	- post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    int wmId, wmEvent;
    PAINTSTRUCT ps;
    HDC hdc;
    int savedSet;
    char text[TEXT_LENGTH];
    DWORD dwError = 0;
    OPENFILENAME ofn;

    switch (message) 
    {
        case WM_COMMAND:
            wmId    = LOWORD(wParam); 
            wmEvent = HIWORD(wParam); 
            // Parse the menu selections:
            switch (wmId)
            {
                case IDM_ABOUT:
                    DialogBox(hInst, (LPCTSTR)IDD_ABOUTBOX, hWnd, (DLGPROC)AboutDialogBoxProc);
                    break;

                case IDM_EXIT:
                    DestroyWindow(hWnd);
                    break;

		case ID_FILE_SELECT_COMPORT:
                    if (DialogBox(hInst, (LPCTSTR)IDD_SELECT_COMPORT, hWnd, (DLGPROC)SelectComportDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;

                case ID_FILE_NEW:
                    if (unsaved)
                    {
                        if (MessageBox(hWnd,
                                       "Unsaved data exists.\nAre you sure?",
                                       "NHRC-3.1 Programmer",
                                       MB_ICONWARNING | MB_YESNO) == IDNO)
                            break;
                    } // if unsaved 
                    unsaved = FALSE;
                    initializeData();
                    SetWindowTitle(hWnd, "");
                    break;
                    
                case ID_FILE_OPEN:
                    memset(&ofn, '\0', sizeof(OPENFILENAME));
                    ofn.lStructSize = sizeof(OPENFILENAME);
                    ofn.hwndOwner = hWnd;
                    ofn.hInstance = hInst;
                    ofn.lpstrFilter = filter;
                    ofn.lpstrFile = filename;
                    ofn.nMaxFile = sizeof(filename);
                    ofn.lpstrInitialDir = path;
                    ofn.lpstrDefExt = "bin";
                    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST |
                        OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
                        
                    if (GetOpenFileName(&ofn) == 0)
                        return FALSE;
                    ReadData(hWnd);
                    break;

                case ID_FILE_SAVE:
                    if (strlen(filename) != 0)
                    {
                        SaveData(hWnd);
                        return FALSE;
                    } // if strlen(filename) != 0 
                    // deliberate fall through 
                    
                case ID_FILE_SAVE_AS:
                    memset(filename, '\0', sizeof(filename));
                    memset(&ofn, '\0', sizeof(OPENFILENAME));
                    ofn.lStructSize = sizeof(OPENFILENAME);
                    ofn.hwndOwner = hWnd;
                    ofn.hInstance = hInst;
                    ofn.lpstrFilter = filter;
                    ofn.lpstrFile = filename;
                    ofn.nMaxFile = sizeof(filename);
                    ofn.lpstrInitialDir = path;
                    ofn.lpstrDefExt = "bin";
                    ofn.Flags = OFN_CREATEPROMPT | OFN_PATHMUSTEXIST |
                        OFN_NOREADONLYRETURN | OFN_HIDEREADONLY;
                        
                    if (GetSaveFileName(&ofn) == 0)
                        return FALSE;
                    strncpy_s(filename, MAX_PATH, ofn.lpstrFile, _TRUNCATE);
                    SaveData(hWnd);
                    SetWindowTitle(hWnd, filename);
                    break;

                case ID_FILE_READ:
                    if (DialogBox(hInst, (LPCTSTR)IDD_TRANSFER, hWnd, (DLGPROC)GetDataTransferDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;
                    
                case ID_FILE_WRITE:
                    if (DialogBox(hInst, (LPCTSTR)IDD_TRANSFER, hWnd, (DLGPROC)SendDataTransferDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    break;

                case ID_EDIT_PREFIXES:
                    if (DialogBox(hInst, (LPCTSTR)IDD_PREFIXES, hWnd, (DLGPROC)PrefixesDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;

                case ID_EDIT_TIMERS:
                    if (DialogBox(hInst, (LPCTSTR)IDD_TIMERS, hWnd, (DLGPROC)TimersDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;

                case ID_CONTROLOPERATORSWITCHES_SET0:
                case ID_CONTROLOPERATORSWITCHES_SET1:
                case ID_CONTROLOPERATORSWITCHES_SET2:
                case ID_CONTROLOPERATORSWITCHES_SET3:
                case ID_CONTROLOPERATORSWITCHES_SET4:
                    savedSet = wmId - ID_CONTROLOPERATORSWITCHES_SET0;
                    if (DialogBoxParam(hInst,
                                       (LPCTSTR)IDD_CONTROLOP,
                                       hWnd,
                                       (DLGPROC) ControlOpDialogBoxProc,
                                       (LPARAM) savedSet) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;

                case ID_EDIT_CWID:
                    if (DialogBox(hInst, (LPCTSTR)IDD_CWID,
                                  hWnd, (DLGPROC)CWIDDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;
                    
                case ID_EDIT_COURTESYTONES:
                    if (DialogBox(hInst, (LPCTSTR)IDD_COURTESYTONES,
                                  hWnd, (DLGPROC)CourtesyTonesDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;

                default:
                    return DefWindowProc(hWnd, message, wParam, lParam);
            } // switch wmid
            break;
            
        case WM_PAINT:
            hdc = BeginPaint(hWnd, &ps);
            RECT rt;
            GetClientRect(hWnd, &rt);
			strncpy_s(text, TEXT_LENGTH,
				"1. Connect NHRC-3.1 to computer\n\n"
				"2. Select Com Port: (File->Select Com Port)\n\n"
				"3. Load data from controller: (File->Read From Controller)\n"
				"    or from file: (File->Open...).\n\n"
				"4. Edit Data using Edit menu items.\n\n"
				"5. Save data to controller: (File->Write to Controller)\n"
				"    and/or file: (File->Save...)", _TRUNCATE);
			DrawText(hdc, text, strlen(text), &rt, DT_LEFT);
            EndPaint(hWnd, &ps);
            break;
            
         case WM_DESTROY:
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
} // WndProc

// Mesage handler for about box.
LRESULT CALLBACK AboutDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_INITDIALOG:
            return TRUE;
            
        case WM_COMMAND:
            if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
            {
                EndDialog(hDlg, LOWORD(wParam));
                return TRUE;
            }
            break;
    }
    return FALSE;
} // AboutDialogBoxProc


LRESULT CALLBACK GetDataTransferDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    BYTE rxBuffer[SC_BUFFER_SIZE];
    BYTE txBuffer[SC_BUFFER_SIZE];
    int rxBufferCount = 0;
    DWORD txBufferCount = 0;
    HANDLE hCom;
    DWORD byteCount = 0;
    BOOL status;
    DWORD dwError;
    BYTE checksum;
    int bytesInPacket = 0;
    char text[1024];
    int i;
    int ok = TRUE;
    char addrLoNibble;
    char addrHiNibble;
    BYTE receivedChecksum;

    switch (message)
    {
        case WM_INITDIALOG:
            xferAddress = 0;
            hCom = OpenCommPort(hDlg);
            if (hCom == NULL)
                return FALSE;
            SetWindowLong(hDlg, GWL_USERDATA, (LONG) hCom);
            SendDlgItemMessage(hDlg, IDC_PROGRESSBAR, PBM_SETRANGE, 0, (LPARAM) MAKELPARAM(0, EEPROM_SIZE));
            unsaved = TRUE;
            return TRUE;

        case WM_ACTIVATE:
            SetTimer(hDlg, COMM_TIMER, 100, NULL);
            return FALSE;

        case WM_COMMAND:
            hCom = (HANDLE) GetWindowLong(hDlg, GWL_USERDATA);
            if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
            {
                KillTimer(hDlg, COMM_TIMER);
                EndDialog(hDlg, LOWORD(wParam));
                CloseHandle(hCom);
                return TRUE;
            }
            break;

        case WM_TIMER:
            hCom = (HANDLE) GetWindowLong(hDlg, GWL_USERDATA);
            if (!KillTimer(hDlg, COMM_TIMER))
            {
                dwError = GetLastError();
                wsprintf(text, "Could not kill timer, error #%d.", dwError);
                ok = FALSE;
            } // if !KillTimer()
            if (ok)
            {
                wsprintf(text, "%04X / %04X", xferAddress, EEPROM_SIZE);
                SendDlgItemMessage(hDlg, IDC_MESSAGE, WM_SETTEXT, 0, (LPARAM) text);
                SendDlgItemMessage(hDlg, IDC_PROGRESSBAR, PBM_SETPOS, (WPARAM) xferAddress, (LPARAM) 0);
                UpdateWindow(hDlg);
                txBufferCount = 0;
                memset(txBuffer, 0, sizeof txBuffer);
                txBuffer[txBufferCount++] = SC_ATTENTION_CHAR;
                txBuffer[txBufferCount++] = SC_READ_CMD_CHAR;
                checksum = 0;

                addrHiNibble = bin2hex((BYTE) (xferAddress >>  4 & 0x0f)); // address lo byte, hi nibble
                addrLoNibble = bin2hex((BYTE) (xferAddress       & 0x0f)); // address lo byte, lo nibble

                txBuffer[txBufferCount++] = addrHiNibble;
                txBuffer[txBufferCount++] = addrLoNibble;
                txBuffer[txBufferCount++] = SC_EOM_CHAR;

                status = WriteFile(hCom, txBuffer, txBufferCount, &byteCount, NULL);
                if (!status || !byteCount)
                {    
                    dwError = GetLastError();
                    wsprintf(text, "Could not write comm port(1), error #%d.", dwError);
                    ok = FALSE;
                } // if !status ...
            } // if ok

            if (ok)
            {
                // should now get controller's response...
                Sleep(250);
                memset(rxBuffer, 0, SC_BUFFER_SIZE);
                status = ReadFile(hCom, rxBuffer, SC_BUFFER_SIZE, &byteCount, NULL);
                if (!status || !byteCount)
                {
                    strncpy_s(text, TEXT_LENGTH, "No response from controller.\n  Check data cables.", _TRUNCATE);
                    ok = FALSE;
                } // if !status || !byteCount
            } // if ok
            if (ok)
            {
                if (byteCount != 24)
                {
                    wsprintf(text, "Bad data from controller.\n(%s, %d bytes)", rxBuffer, byteCount);
                    ok = FALSE;
                } // if byteCount != 30
            } // if ok
            if (ok)
            {
                if (rxBuffer[0] != SC_ATTENTION_CHAR ||
                    rxBuffer[1] != SC_WRITE_CMD_CHAR ||
                    rxBuffer[2] != addrHiNibble||
                    rxBuffer[3] != addrLoNibble ||
                    rxBuffer[22] != SC_EOM_CHAR)
                {
                    wsprintf(text, "Bad data from controller= %s, %d bytes", rxBuffer, byteCount);
                    ok = FALSE;
                } // if rxBuffer[0] != ...
            } // if ok
        
            if (ok)
            {
                rxBufferCount = 1;
                // now validate checksum
                checksum = 0;
                for (i=1; i < 20; i++)
                {
                    checksum = (BYTE) (checksum + rxBuffer[i]);
                } // for i

                receivedChecksum = 0;
                receivedChecksum = (BYTE) ((hex2bin(rxBuffer[20]) << 4) + hex2bin(rxBuffer[21]));

                if (checksum != receivedChecksum)
                {
                    wsprintf(text, "Checksum error. calculated=%02x, received=%02x", checksum, receivedChecksum);
                    ok = FALSE;
                } // if checksum != receivedChecksum
            } // if ok
            if (ok)
            {
                rxBufferCount = 4;

                // data is good, copy it.
                for (i=0; i < 8; i++)
                {
                    eepromData[xferAddress + i] = (BYTE) ((hex2bin(rxBuffer[rxBufferCount]) << 4) + hex2bin(rxBuffer[rxBufferCount+1]));
                    rxBufferCount += 2;
                } // for i
                xferAddress += SC_TRANSFER_SIZE;

                if (xferAddress < EEPROM_SIZE)
                    SetTimer(hDlg, COMM_TIMER, 2, NULL);
                else
                {
                    KillTimer(hDlg, COMM_TIMER);
                    dataLoaded = TRUE;
                    PostMessage(hDlg, WM_COMMAND, IDCANCEL, 0);
                }
                return TRUE;
            } // if ok
            if (!ok)
            {
                KillTimer(hDlg, COMM_TIMER);
                PostMessage(hDlg, WM_COMMAND, IDCANCEL, 0);
                MessageBox(hDlg, text, "Problem...", MB_ICONSTOP | MB_OK);
            } // if !ok
            break;
    } // switch
    return FALSE;
} // GetDataTransferDialogBoxProc


// Message handler for get data status box.

//-----------------------------------------------------------------------------------------
// Message handler for send data status box.
LRESULT CALLBACK SendDataTransferDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    BYTE rxBuffer[SC_BUFFER_SIZE];
    BYTE txBuffer[SC_BUFFER_SIZE];
    //int rxBufferCount = 0;
    int txBufferCount = 0;
    HANDLE hCom;
    DWORD byteCount = 0;
    BOOL status;
    DWORD dwError;
    BYTE checksum;
    BYTE eeByte;
    BYTE d;
    char text[1024];
    int i;
    int ok = TRUE;
    char addrLoNibble;
    char addrHiNibble;

    switch (message)
    {
        case WM_INITDIALOG:
            xferAddress = 0;
            hCom = OpenCommPort(hDlg);
            if (hCom == NULL)
                return FALSE;
            SetWindowLong(hDlg, GWL_USERDATA, (LONG) hCom);
            SendDlgItemMessage(hDlg, IDC_PROGRESSBAR, PBM_SETRANGE, 0, (LPARAM) MAKELPARAM(0, EEPROM_SIZE));
            return TRUE;

        case WM_ACTIVATE:
            SetTimer(hDlg, COMM_TIMER, 100, NULL);
            return FALSE;

        case WM_COMMAND:
            hCom = (HANDLE) GetWindowLong(hDlg, GWL_USERDATA);
            if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) 
            {
                KillTimer(hDlg, COMM_TIMER);
                EndDialog(hDlg, LOWORD(wParam));
                CloseHandle(hCom);
                return TRUE;
            }
            break;

        case WM_TIMER:
            // this is where the meat is...
            hCom = (HANDLE) GetWindowLong(hDlg, GWL_USERDATA);
            if (!KillTimer(hDlg, COMM_TIMER))
            {
                dwError = GetLastError();
                wsprintf(text, "Could not kill timer, error #%d.", dwError);
                ok = FALSE;
            } // if !KillTimer() 
            if (ok)
            {
                wsprintf(text, "%04X / %04X", xferAddress, EEPROM_SIZE);
                SendDlgItemMessage(hDlg, IDC_MESSAGE, WM_SETTEXT, 0, (LPARAM) text);
                SendDlgItemMessage(hDlg, IDC_PROGRESSBAR, PBM_SETPOS, (WPARAM) xferAddress, (LPARAM) 0);
                UpdateWindow(hDlg);
                txBufferCount = 0;

                txBuffer[txBufferCount++] = SC_ATTENTION_CHAR;
                txBuffer[txBufferCount++] = SC_WRITE_CMD_CHAR;
                checksum = SC_WRITE_CMD_CHAR;

                addrHiNibble = bin2hex((BYTE) (xferAddress >>  4 & 0x0f)); // address lo byte, hi nibble
                addrLoNibble = bin2hex((BYTE) (xferAddress       & 0x0f)); // address lo byte, lo nibble

                txBuffer[txBufferCount++] = addrHiNibble;
                checksum = (BYTE) (checksum + addrHiNibble);
                txBuffer[txBufferCount++] = addrLoNibble;
                checksum = (BYTE) (checksum + addrLoNibble);

                // add the eeprom data bytes to the message...
                for (i=0; i < SC_TRANSFER_SIZE; i++)
                {
                    eeByte = eepromData[xferAddress + i];
                    d = bin2hex((BYTE)((eeByte >> 4) & 0x0f));
                    txBuffer[txBufferCount++] = d;
                    checksum = (BYTE) (checksum + d);
                    d = bin2hex((BYTE) (eeByte & 0x0f));
                    txBuffer[txBufferCount++] = d;
                    checksum = (BYTE) (checksum + d);
                } // for i 

                txBuffer[txBufferCount++] = bin2hex((BYTE)((checksum >> 4) & 0x0f)); // checksum hi nibble
                txBuffer[txBufferCount++] = bin2hex((BYTE) (checksum       & 0x0f)); // checksum lo nibble
                txBuffer[txBufferCount++] = SC_EOM_CHAR;
                xferAddress += SC_TRANSFER_SIZE;

                status = WriteFile(hCom, txBuffer, txBufferCount, &byteCount, NULL);
                if (!status || !byteCount)
                {    
                    dwError = GetLastError();
                    wsprintf(text, "Could not write comm port(2), error #%d.", dwError);
                    ok = FALSE;
                } // if !status ... 
            } // if ok
            if (ok)
            {
                Sleep(250);
                // should now get controller's response...
                memset(rxBuffer, 0, sizeof rxBuffer);
                status = ReadFile(hCom, rxBuffer, SC_BUFFER_SIZE, &byteCount, NULL);
                if (!status || !byteCount)
                {
                    strncpy_s(text, TEXT_LENGTH, "No response from controller.\nCheck data cables.", _TRUNCATE);
                    ok = FALSE;
                } // if !status || !byteCount 
            } // if ok
            if (ok)
            {
                if (byteCount != 3) 
                {
                    wsprintf(text, "Bad data received from controller.\n(%s)", rxBuffer);
                    ok = FALSE;
                } // if byteCount != 3...
            } // if ok
            if (ok)
            {
                if (rxBuffer[0] != SC_ACK)
                { // invalid response message...
                        wsprintf(text, "Controller did not send ACK.");
                        ok = FALSE;
                } // if rxBuffer[0] == ...
            } // if ok
            if (ok)
            {
                if (xferAddress < EEPROM_SIZE)
                    SetTimer(hDlg, COMM_TIMER, 20, NULL);
                else
                {
                    KillTimer(hDlg, COMM_TIMER);
                    PostMessage(hDlg, WM_COMMAND, IDCANCEL, 0);
                }
                return TRUE;
            } // if ok
            if (!ok)
            {
                KillTimer(hDlg, COMM_TIMER);
                PostMessage(hDlg, WM_COMMAND, IDCANCEL, 0);
                MessageBox(hDlg, text, "Problem...", MB_ICONSTOP | MB_OK);
            } // if !ok
            break;
    } // switch
    return FALSE;
} // SendDataTransferDialogBoxProc
//-----------------------------------------------------------------------------------------

// Dialog box proc for CW ID dialog box.
LRESULT CALLBACK CWIDDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i;
    HWND hwndCtl;
    WNDPROC oldWindowProc;
    char tempString[CWID_LENGTH+1];
    
    switch (message)
    {
        case WM_INITDIALOG:
            hwndCtl = GetDlgItem(hDlg, IDC_CWIDTEXT);
            oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
            SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) oldWindowProc);
            SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) CWEditProc);
            SendMessage(hwndCtl, EM_LIMITTEXT, CWID_LENGTH, 0);
            memset(tempString, 0, CWID_LENGTH+1);
            for (i=0; i < CWID_LENGTH; i++)
            {
                tempString[i] = cwByte2char(eepromData[EEPROM_CWID_BASE + i]);
            } // for i 
            SetWindowText(hwndCtl, tempString);
            return TRUE;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDOK:
                    unsaved = TRUE;

                    // now get the data from the dialog...
                    hwndCtl = GetDlgItem(hDlg, IDC_CWIDTEXT);
                    memset(tempString, 0, CWID_LENGTH+1);
                    GetWindowText(hwndCtl, tempString, CWID_LENGTH);
                    for (i=0; i < CWID_LENGTH; i++)
                    {
                        eepromData[EEPROM_CWID_BASE + i] = char2cwByte(tempString[i]);
                    } // for i
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
                    
                case IDCANCEL:
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // CWIDDialogBoxProc

// Dialog box proc for Prefixes dialog box.
LRESULT CALLBACK PrefixesDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i,j;
    HWND hwndCtl;
    int address;
    WNDPROC oldWindowProc;
    char tempString[PREFIX_LENGTH+1];
    BYTE b;
    
    switch (message)
    {
        case WM_INITDIALOG:
            for (i = 0; i < MAX_PREFIX; i++)
            {
                hwndCtl = GetDlgItem(hDlg, IDC_PFX_EDIT_00 + i);
                address = EEPROM_PREFIX_BASE + i * PREFIX_LENGTH;
                oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
                SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) oldWindowProc);
                SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) DTMFEditProc);
                SendMessage(hwndCtl, EM_LIMITTEXT, PREFIX_LENGTH - 1, 0);
                memset(tempString, 0, PREFIX_LENGTH+1);
                for (j=0; j < PREFIX_LENGTH; j++)
                {
                    b = eepromData[address+j];
                    tempString[j] = (b == 0xff) ? '\0' : bin2dtmf(b);
                } // for j 
                SetWindowText(hwndCtl, tempString);
            } // for i
            return TRUE;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDOK:
                    unsaved = TRUE;

                    // now get the data from the dialog...
                    for (i = 0; i < MAX_PREFIX; i++)
                    {
                        hwndCtl = GetDlgItem(hDlg, IDC_PFX_EDIT_00 + i);
                        address = EEPROM_PREFIX_BASE + i * PREFIX_LENGTH;
                        memset(tempString, 0, PREFIX_LENGTH+1);
                        GetWindowText(hwndCtl, tempString, PREFIX_LENGTH);
                        for (j=0; j < PREFIX_LENGTH; j++)
                        {
                            eepromData[address+j] = dtmf2bin(tempString[j]);
                        } // for j 
                    } // for i
					// this is a hack for NHRC-3.1.  There is no command 6, cannot put FF in there.
					address = EEPROM_PREFIX_BASE + 6 * PREFIX_LENGTH;
					eepromData[address] = 0xee; 
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
                    
                case IDCANCEL:
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // PrefixesDialogBoxProc

// Dialog box proc for Select Comport dialog box.
LRESULT CALLBACK SelectComportDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i;
    HWND hwndCtl;
    char tempString[MAX_COMPORT_LENGTH];
    DWORD result = 0;
    LRESULT item;
    char data[32768];
    LPSTR dptr;

    switch (message)
    {
    case WM_INITDIALOG:
        hwndCtl = GetDlgItem(hDlg, IDC_COMPORT_COMBO);
        i = 0;
        //enumerate com ports in this machine
        result = QueryDosDevice(NULL, data, 32768);
        if (result) 
        {
            dptr = data;
            while (dptr < data + result)
            {
                if (!strncmp(dptr, "COM", 3)) 
                {
                    sprintf_s(tempString, MAX_COMPORT_LENGTH, "%s:", dptr);
                    SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) tempString);
                    if (!strncmp(comport, tempString, MAX_COMPORT_LENGTH))
                    {
                        SendMessage(hwndCtl, CB_SETCURSEL, i, 0);
                    } // if !strncmp
                    ++i;
                } // if ! strncmp
                dptr += strlen(dptr) + 1;
            } // while
        } // if result
        return TRUE;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDOK:
                    hwndCtl = GetDlgItem(hDlg, IDC_COMPORT_COMBO);
                    item = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
                    result = SendMessage(hwndCtl, CB_GETLBTEXT, (WORD) item, (LPARAM) tempString);
                    //strncpy(comport, tempString, MAX_COMPORT_LENGTH);
                    strncpy_s(comport, MAX_COMPORT_LENGTH, tempString, MAX_COMPORT_LENGTH);
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
                    
                case IDCANCEL:
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // SelectComportDialogBoxProc

//--------------------------------------------------
// Dialog box proc for Timers dialog box.
LRESULT CALLBACK TimersDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i;
    HWND hwndCtl;
    int address;
    char tempString[4];
    char messageText[256];
    BYTE b;
    int d;
    
    switch (message)
    {
        case WM_INITDIALOG:
            for (i = 0; i < MAX_TIMER; i++)
            {
                hwndCtl = GetDlgItem(hDlg, IDC_TIMER_EDIT_00 + i);
                address = EEPROM_TIMER_BASE + i;
                SendMessage(hwndCtl, EM_LIMITTEXT, 3, 0);
                wsprintf(tempString, "%d", eepromData[address]);
                SetWindowText(hwndCtl, tempString);
            } // for i
            return TRUE;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDOK:
                    unsaved = TRUE;
                    // now get the data from the dialog...
                    for (i = 0; i < MAX_TIMER; i++)
                    {
                        hwndCtl = GetDlgItem(hDlg, IDC_TIMER_EDIT_00 + i);
                        address = EEPROM_TIMER_BASE + i;
                        GetWindowText(hwndCtl, tempString, 4);
                        //sscanf(tempString, "%d", &d);
                        d = atoi(tempString);
                        if ((d < 0) || (d > 255))
                        {
                            wsprintf(messageText, "%s value out of range: %d.\nMust be 0-255.", timerNames[i], d); 
                            MessageBox(hDlg, messageText, "Error", MB_ICONHAND);
                            return FALSE;
                        } // if d < 0 ...
                        b = (BYTE) d;
                        eepromData[address] = b;
                    } // for i
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
                    
                case IDCANCEL:
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // TimersDialogBoxProc


//--------------------------------------------------
// Dialog box proc for Control Operator Settings dialog box.
LRESULT CALLBACK ControlOpDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int savedSetup = 0;
    int i;
    HWND hwndCtl;
    
    switch (message)
    {
        case WM_INITDIALOG:
            savedSetup = (int) lParam;

            SetWindowLong(hDlg, GWL_USERDATA, MAKELONG(0, (WORD) savedSetup));

            hwndCtl = GetDlgItem(hDlg, IDC_GROUP_COMBO);
            for (i = 0; i < MAX_CTL_GROUPS; i++)
            {
                SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) controlGroupNames[i]);
            } // for i 
            //SendMessage(hwndCtl, CB_SETMINVISIBLE, 10, 0);
            SendMessage(hwndCtl, CB_SETCURSEL, 0, 0);
            setControlGroup(hDlg);
            return TRUE;

        case WM_COMMAND:
            savedSetup = HIWORD(GetWindowLong(hDlg, GWL_USERDATA));
            switch (LOWORD(wParam))
            {
                case IDC_GROUP_COMBO:
                    
                    switch (HIWORD(wParam))
                    {
                        case CBN_SELCHANGE:
                            getControlGroup(hDlg);
                            setControlGroup(hDlg);
                            return TRUE;
                        default:
                            return FALSE;
                    } // switch HIWORD (wParam)

                case IDOK:
                    // now get the data from the dialog...
                    getControlGroup(hDlg);
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // ControlOpDialogBoxProc

void getControlGroup(HWND hDlg)
{
    HWND hwndCtl;
    int i;
    int group;
    int address;
    BYTE data;
    LRESULT lResult;
    int savedSetup;

    lResult = GetWindowLong(hDlg, GWL_USERDATA);
    group = LOWORD(lResult);
    savedSetup = HIWORD(lResult); // this is a horrible hack.

    address = EEPROM_CTLOP_BASE + savedSetup * NUM_CTL_GROUPS + group;
    data = 0;

    for (i=0; i<8; i++)
    {
        hwndCtl = GetDlgItem(hDlg, IDC_CTLOP_CB_0 + i);
        lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
        if (lResult == BST_CHECKED)
        {
            data |= bitValues[i];
        } // if lResult == BST_CHECKED
    } // for i 
    eepromData[address] = data;
} // setControlGroup()

void setControlGroup(HWND hDlg)
{
    HWND hwndCtl;
    int i;
    int group;
    int address;
    char message[128];
    BYTE data;
    LRESULT lResult;
    int savedSetup;

    lResult = GetWindowLong(hDlg, GWL_USERDATA);
    group = LOWORD(lResult);
    savedSetup = HIWORD(lResult); // this is a horrible hack.

    hwndCtl = GetDlgItem(hDlg, IDC_SAVEDSETUPMESSAGE);
    wsprintf(message, "Saved Setup # %d", savedSetup);
    SetWindowText(hwndCtl, message);

    hwndCtl = GetDlgItem(hDlg, IDC_GROUP_COMBO);
    group = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);

    SetWindowLong(hDlg, GWL_USERDATA, MAKELONG(group, savedSetup));
    address = EEPROM_CTLOP_BASE + savedSetup * NUM_CTL_GROUPS + group;
    data = eepromData[address];
    for (i=0; i<8; i++)
    {
        hwndCtl = GetDlgItem(hDlg, IDC_CTLOP_CB_0 + i);
        SetWindowText(hwndCtl, controlItemNames[group * 8 + i]);
        SendMessage(hwndCtl, BM_SETCHECK, isBitSet(data, i) ? BST_CHECKED : BST_UNCHECKED, 0);
    } // for i 
} // setControlGroup()
//--------------------------------------------------
// Dialog box proc for Courtesy Tones Dialog.
LRESULT CALLBACK CourtesyTonesDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i,j;
    HWND hwndCtl;
    char tempString[WORKSTRING_LENGTH];
    int isCWChar;

    switch (message)
    {
        case WM_INITDIALOG:
            SetWindowLong(hDlg, GWL_USERDATA, 0L);
            
            // set up courtesy tones dropdown menu
            hwndCtl = GetDlgItem(hDlg, IDC_TONE_SELECT_COMBO);
            for (i = 0; i<8; i++)
            { // loop through courtesy tone names
                SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) courtesyToneNames[i]);
            } // for i 
            SendMessage(hwndCtl, CB_SETCURSEL, 0, 0);

            // set up courtesy tone segment 1-4 pitch dropdown menu
            for (j=0; j<4; j++)
            {
                hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_PITCH_COMBO + j);
                for (i = 0; i<COURTESY_MAX_TONES; i++)
                { // loop through courtesy tone names
                    SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) tones[i]);
                } // for i 
                SendMessage(hwndCtl, CB_SETCURSEL, 0, 0);
            } // for j
            
            // set up courtesy tone segment 1-4 length max length
            for (j=0; j<4; j++)
            {
                hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_LENGTH_EDIT + j);
                SendMessage(hwndCtl, EM_LIMITTEXT, 2, 0);
            } // for j
            
            // set up courtesy tone CW letter dropdown menu
            hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_COMBO);
            for (i = 0; i < sizeof cwIndex - 1; i++)
            { // loop through courtesy tone names
                tempString[0] = cwIndex[i];
                tempString[1] = '\0';
                SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) tempString);
            } // for i 
            SendMessage(hwndCtl, CB_SETCURSEL, 0, 0);
            setCourtesyToneDialogData(hDlg);
            return TRUE;
        
        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDC_HUNDREDS_COMBO:
                    switch (HIWORD(wParam))
                    {
                        case CBN_SELCHANGE:
                            getCourtesyToneDialogData(hDlg);
                            setCourtesyToneDialogData(hDlg);
                            return TRUE;
                        default:
                            return FALSE;
                    } // switch HIWORD (wParam)

                case IDC_TONES_RADIO:
                case IDC_CWCHAR_RADIO:
                    switch (HIWORD(wParam))
                    {
                        case BN_CLICKED:
                            if (LOWORD(wParam) == IDC_CWCHAR_RADIO)
                                isCWChar = TRUE;
                            else
                                isCWChar = FALSE;

                            // set cw char radio button
                            hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_RADIO);
                            SendMessage(hwndCtl, BM_SETCHECK, isCWChar ? BST_CHECKED : BST_UNCHECKED, 0);
                            // set tones radio button
                            hwndCtl = GetDlgItem(hDlg, IDC_TONES_RADIO);
                            SendMessage(hwndCtl, BM_SETCHECK, isCWChar ? BST_UNCHECKED : BST_CHECKED, 0);
                            
                            for (i=0; i<4;i++)
                            { // set tones controls enabled/disabled
                                hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_LENGTH_EDIT + i);
                                EnableWindow(hwndCtl, !isCWChar);
                                hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_PITCH_COMBO + i);
                                EnableWindow(hwndCtl, !isCWChar);
                            } // for i
                            // set cw character combo enabled/disabled.
                            hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_COMBO);
                            EnableWindow(hwndCtl, isCWChar);
                            return TRUE;
                    } // switch HIWORD(wParam)

                case IDOK:
                    getCourtesyToneDialogData(hDlg);
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // CourtesyTonesDialogBoxProc

void getCourtesyToneDialogData(HWND hDlg)
{
    HWND hwndCtl;
    int i;
    int index;
    int length;
    int tone;
    int courtesyToneIndex;
    int address;
    int isCWChar;
    LRESULT lResult;
    char tempString[WORKSTRING_LENGTH];

    courtesyToneIndex = GetWindowLong(hDlg, GWL_USERDATA);
    address = EEPROM_COURTESY_BASE + courtesyToneIndex * COURTESY_TONE_LENGTH;
    hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_RADIO);
    lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
    isCWChar = (lResult == BST_CHECKED);

    if (isCWChar)
    { // cw character courtesy tone selected
        hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_COMBO);
        index = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
        eepromData[address] = COURTESY_TONE_CW_CHAR;
        eepromData[address + 1] = index2cwct(index);
        for (i=2; i < COURTESY_TONE_LENGTH; i++)
            eepromData[address + i] = 0x00;
    } // if is CWChar
    else
    { // tone sequence courtesy tone selected
        // validate lengths
        for (i=0; i<4; i++)
        {
            hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_LENGTH_EDIT + i);
            GetWindowText(hwndCtl, tempString, WORKSTRING_LENGTH);
            length = atoi(tempString);
            if ((length < 0) || (length > 98))
            {
                wsprintf(tempString, "Length of segment %d is out of range.\nValid range is 0-98", i+1);
                MessageBox(hDlg, tempString, "Error", MB_ICONSTOP);
                return;
            } // if length < 0 ...
        } // for i

        for (i=0; i<4; i++)
        {
            hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_LENGTH_EDIT + i);
            GetWindowText(hwndCtl, tempString, WORKSTRING_LENGTH);
            length = atoi(tempString);

            hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_PITCH_COMBO + i);
            index = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
            tone = index2toneByte(index);
            eepromData[address + 2 * i] = length;
            eepromData[address + 1 + 2 * i] = tone;
            if ((i != 0) && (length != 0))
            { // mark more tones flag.
                eepromData[address + 1 + 2 * (i-1)] |= 0x80;
            } // if ((i != 0) && (length != 0))
        } // for i 
    } // if is CWChar
} // getCourtesyToneDialogData()

void setCourtesyToneDialogData(HWND hDlg)
{
    HWND hwndCtl;
    int i;
    int address;
    char tempString[WORKSTRING_LENGTH];
    int courtesyToneIndex;
    int isCWChar;
    int ended;
    int index;

    // get courtesy tone  index from dropdown
    hwndCtl = GetDlgItem(hDlg, IDC_TONE_SELECT_COMBO);
    courtesyToneIndex = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
    // stash courtesy tone index
    SetWindowLong(hDlg, GWL_USERDATA, (LONG) courtesyToneIndex);
    // set courtesy tone base address...
    address = EEPROM_COURTESY_BASE + courtesyToneIndex * COURTESY_TONE_LENGTH;

    isCWChar = (eepromData[address] == COURTESY_TONE_CW_CHAR) ? TRUE : FALSE;

    // set cw char radio button
    hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_RADIO);
    SendMessage(hwndCtl, BM_SETCHECK, isCWChar ? BST_CHECKED : BST_UNCHECKED, 0);
    // set tones radio button
    hwndCtl = GetDlgItem(hDlg, IDC_TONES_RADIO);
    SendMessage(hwndCtl, BM_SETCHECK, isCWChar ? BST_UNCHECKED : BST_CHECKED, 0);
    
    for (i=0; i<4;i++)
    { // set tones controls enabled/disabled
        hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_LENGTH_EDIT + i);
        EnableWindow(hwndCtl, !isCWChar);
        hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_PITCH_COMBO + i);
        EnableWindow(hwndCtl, !isCWChar);
    } // for i
    // set cw character combo enabled/disabled.
    hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_COMBO);
    EnableWindow(hwndCtl, isCWChar);

    if (isCWChar)
    { // this tone is configured as a CW character
        hwndCtl = GetDlgItem(hDlg, IDC_CWCHAR_COMBO);
        index = cwctByte2index(eepromData[address + 1]);
        SendMessage(hwndCtl, CB_SETCURSEL, index, 0);
    } // if isCWChar
    else
    { // this courtesy tone is configured as a tone sequence
        ended = FALSE;
        for (i=0; i<4; i++)
        {
            hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_LENGTH_EDIT + i);
            wsprintf(tempString, "%02d", eepromData[address + i * 2]);
            SetWindowText(hwndCtl, ended ? "" : tempString);
            hwndCtl = GetDlgItem(hDlg, IDC_SEG_1_PITCH_COMBO + i);
            index = toneByte2index(eepromData[address + 1 + i * 2]);
            SendMessage(hwndCtl, CB_SETCURSEL, ended ? -1 : index, 0);
            if ((eepromData[address + 1 + i * 2] & 0x80) == 0)
                ended = TRUE;
        } // for i
    } // if isCWChar
} // setCourtesyToneDialogData()

// ---------------------------------------------------------------------------
// open the comm port
HANDLE OpenCommPort(HWND hwnd)
{
    DCB dcb;
    COMMTIMEOUTS commtimeouts;
    HANDLE hCom;
    DWORD dwError;
    BOOL fSuccess;
    char message[128];
    hCom = CreateFile(comport, GENERIC_READ | GENERIC_WRITE,
                      0,    // comm devices must be opened w/exclusive-access 
                      NULL, // no security attrs 
                      OPEN_EXISTING, // comm devices must use OPEN_EXISTING 
                      0,    // not overlapped I/O 
                      NULL  // hTemplate must be NULL for comm devices 
                      );
    if (hCom == INVALID_HANDLE_VALUE)
    {
        // handle error 
        dwError = GetLastError();
        wsprintf(message, "Could not open %s, error %d.", comport, dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
        return NULL;
    }
    //
    fSuccess = GetCommState(hCom, &dcb);
    if (!fSuccess)
    {
        // Handle the error. 
        dwError = GetLastError();
        wsprintf(message, "Could not get CommState, error %d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
        CloseHandle(hCom);
        return NULL;
    } // if !fSuccess
    // Fill in the DCB: baud=1200, 8 data bits, no parity, 1 stop bit. 
    dcb.BaudRate = 1200;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;
	dcb.fOutxCtsFlow = FALSE;
	dcb.fOutxDsrFlow = FALSE;
    fSuccess = SetCommState(hCom, &dcb);
    if (!fSuccess)
    {
        // Handle the error. 
        dwError = GetLastError();
        wsprintf(message, "Could not set CommState, error %d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
        CloseHandle(hCom);
        return NULL;
    }  // if !fSuccess

    fSuccess = GetCommTimeouts(hCom, &commtimeouts);
    if (!fSuccess)
    {
        // Handle the error. 
        dwError = GetLastError();
        wsprintf(message, "Could not get CommTimeouts, error %d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
        CloseHandle(hCom);
        return NULL;
    } // if ! fSuccess 
    commtimeouts.ReadIntervalTimeout = 50; // ms between characters.  9600 baud is about 1.1 ms
    commtimeouts.ReadTotalTimeoutMultiplier = 20; // ms per character for total timeout
    commtimeouts.ReadTotalTimeoutConstant = 500; // ms added to multiplier * numbytes to get total.
    commtimeouts.WriteTotalTimeoutMultiplier = 50; // ms MAX to transmit each character
    commtimeouts.WriteTotalTimeoutMultiplier = 1000; // ms added to multipler * numbytes to get total.

    fSuccess = SetCommTimeouts(hCom, &commtimeouts);
    if (!fSuccess)
    {
        // Handle the error. 
        dwError = GetLastError();
        wsprintf(message, "Could not set CommTimeouts, error %d.", dwError);
        MessageBox(hwnd, message, "Problem...", MB_ICONSTOP | MB_OK);
        CloseHandle(hCom);
        return NULL;
    } // if !fSuccess
    return hCom;
} // OpenCommPort()

// get a ascii hex digit for a value.
char bin2hex(BYTE b)
{
    if (b < 10)
        return (char) (b + 48);
    if (b < 16)
        return (char) (b + 55);
    return '0';
} // bin2hex()

// get a binary value for a hex digit.
BYTE hex2bin(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    if (c >= 'a' && c <= 'f')
        return c = 'a' + 10;
    return 0;
}

// get a ascii dtmf digit for a value.
char bin2dtmf(BYTE b)
{
    if (b > 15)
        return 0;
    return dtmfdigits[b];
} // bin2dtmf()

BYTE dtmf2bin(char c)
{
    if (c >= '0' && c <= '9')
        return (BYTE) (c - '0');
    if (c >= 'A' && c <= 'D')
        return (BYTE) c - 55;
    if (c >= 'a' && c <= 'd')
        return (BYTE) c - 87;
    if (c == '*')
        return (BYTE) 0x0e;
    if (c == '#')
        return (BYTE) 0x0f;
    return (BYTE) 0xff;
} // dtmf2bin

char cwByte2char(BYTE b)
{
    int i;
    for (i=0; i < sizeof cwIndex; i++)
    {
        if (b == cwMask[i])
            return cwIndex[i];
    } // for
    if (b == 0xff)
        return '\0';
    return ' ';
} // cwByte2char()

int cwctByte2index(BYTE b)
{
    int i;
    char c;
    c = ctcwmap[b];
    for (i=0; i < sizeof(cwIndex); i++)
    {
        if (c == cwIndex[i])
            return i;
    } // for
    return -1;
} // cwctByte2index()

BYTE index2cwct(int i)
{
    char c;
    int j;
    c = cwIndex[i];
    for (j=0; j < sizeof(ctcwmap); j++)
    {
        if (c == ctcwmap[j])
            return (BYTE) j;
    } // for
    return (BYTE) 0;
} // index2cwct()

BYTE char2cwByte(char c)
{
    int i;
    if (isalpha(c))
        c = toupper(c);
    for (i=0; i < sizeof cwIndex; i++)
    {
        if (c == cwIndex[i])
            return cwMask[i];
    } // for
    return (BYTE) 0xff;
} // char2cwByte

int toneByte2index(BYTE b)
{
    return (b & 0x007f);
} // toneByte2index

BYTE index2toneByte(int i)
{
    return (BYTE) i & 0x001f;
} // index2toneByte

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
    } // if fileHandle == INVALID_HANDLE_VALUE 

    // opened the file, write the header 
    WriteFile(fileHandle, (LPCVOID) eepromData, EEPROM_SIZE, &bytesWritten, NULL); 
    CloseHandle(fileHandle);
    unsaved = FALSE;
} // SaveData() 

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
    } // if fileHandle == INVALID_HANDLE_VALUE 
    if (!ReadFile(fileHandle, eepromData, EEPROM_SIZE, &bytesRead, NULL))
    {
        MessageBox(hwnd, "IO Error", "Error", MB_OK | MB_ICONERROR | MB_APPLMODAL);
        success = FALSE;
    } // if ReadFile() 
    CloseHandle(fileHandle);
    if (success)
    {
        unsaved = FALSE;
        dataLoaded = TRUE;
        SetWindowTitle(hwnd, filename);
    } // if success 
} // ReadData() 

void SetWindowTitle(HWND hwnd, LPSTR name)
{
    char message[256];
    char rawFileName[MAX_PATH];
    unsigned int i;
    int pos = 0;

    for (i=0; i<strlen(name); i++)
        if (name[i] == '\\')
            pos = i;

    strncpy_s(rawFileName, MAX_PATH, name+pos+1, _TRUNCATE);
    
    if (name[0] != 0 )
    {
        wsprintf(message, "NHRC-3.1 Programmer - %s %s", rawFileName, unsaved ? "(unsaved)" : "");
    } // if (filename[0] != 0) 
    else
    {
        wsprintf(message, "NHRC-3.1 Programmer %s", unsaved ? "(unsaved)" : "");
    } // if (filename[0] != 0) 
    SetWindowText(hwnd, message);
} // SetWindowTitle() 

void initializeData()
{
    memset(eepromData, 0xff, EEPROM_SIZE);
    filename[0] = '\0';
    unsaved = FALSE;
} // intializeData() 

int isDTMF(char c)
{
    if (c >= '0' && c <= '9')
        return TRUE;
    if (c >= 'A' && c <= 'D')
        return TRUE;
    if (c >= 'a' && c <= 'd')
        return TRUE;
    if (c == '*')
        return TRUE;
    if (c == '#')
        return TRUE;
    return FALSE;
} // isDTMF()

int isValidCWChar(char c)
{
    if (c >= '0' && c <= '9')
        return TRUE;
    if (c >= 'A' && c <= 'Z')
        return TRUE;
    if (c >= 'a' && c <= 'z')
        return TRUE;
    if (c == ' ')
        return TRUE;
    if (c == '!')
        return TRUE;
    if (c == '#')
        return TRUE;
    if (c == '/')
        return TRUE;
    return FALSE;
} // isValidCWChar()

/*****************************************************************************/
/* DTMFEditProc -- the subclass code for the DTMF edit controls.             */
/* performs rudimentary input validation.  allows only 0123456789AaBbCcDd*#  */
/*****************************************************************************/
LRESULT CALLBACK DTMFEditProc(HWND hwnd, WORD message, WPARAM wParam, LPARAM lParam)
{
    WNDPROC oldWindowProc = (WNDPROC) GetWindowLong(hwnd, GWL_USERDATA);
    char c;
    switch (message)
    {
        case WM_CHAR:
            c = (char) wParam;
            if (isDTMF(c))
                return(CallWindowProc(oldWindowProc, hwnd, message, wParam, lParam));
            if (c == 8) // backspace...
                return(CallWindowProc(oldWindowProc, hwnd, message, wParam, lParam));
            MessageBeep(MB_OK);
            return FALSE;

    } /* switch */
    return(CallWindowProc(oldWindowProc, hwnd, message, wParam, lParam));
} /* DTMFEditProc() */

/*****************************************************************************/
/* CWEditProc -- the subclass code for the DTMF edit controls.               */
/* performs rudimentary input validation.  allows only valid CW characters.  */
/*****************************************************************************/
LRESULT CALLBACK CWEditProc(HWND hwnd, WORD message, WPARAM wParam, LPARAM lParam)
{
    WNDPROC oldWindowProc = (WNDPROC) GetWindowLong(hwnd, GWL_USERDATA);
    char c;
    switch (message)
    {
        case WM_CHAR:
            c = (char) wParam;
            if (isValidCWChar(c))
                return(CallWindowProc(oldWindowProc, hwnd, message, wParam, lParam));
            if (c == 8) // backspace...
                return(CallWindowProc(oldWindowProc, hwnd, message, wParam, lParam));
            MessageBeep(MB_OK);
            return FALSE;

    } /* switch */
    return(CallWindowProc(oldWindowProc, hwnd, message, wParam, lParam));
} /* CWEditProc() */

int isBitSet(BYTE byte, int bit)
{
    return ((byte & bitValues[bit]) != 0);
} // isBitSet()
