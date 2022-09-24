// Programmer.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "resource.h"
#include "Programmer.h"

#define COMM_TIMER 1

#define WORKSTRING_LENGTH 256

// Foward declarations of functions included in this code module:
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    AboutDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    AutodialsDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    AutopatchDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    ControlOpDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    CWIDDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    CWEditProc(HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK    DTMFEditProc(HWND, WORD, WPARAM, LPARAM);
LRESULT CALLBACK    EditExchangesDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    EmergencyAutodialsDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    GetDataTransferDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    PrefixesDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    SendDataTransferDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    TimersDialogBoxProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK    CourtesyTonesDialogBoxProc(HWND, UINT, WPARAM, LPARAM);

HANDLE OpenCommPort(HWND hwnd);
char bin2hex(BYTE b);
char bin2dtmf(BYTE b);
BYTE dtmf2bin(char c);
void CIVtoASCII(BYTE civMessage[], char messageBuffer[]);
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
void getAutodials(HWND hDlg);
void setAutodials(HWND hDlg);
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
char helpFileName[128];                             /* the path/file name of the help file */
BYTE eepromData[EEPROM_SIZE];

char filter[40];
const char * dtmfdigits = "0123456789ABCD*#";
const LPSTR timerNames[] = {"Hang Timer Long",
                            "Hang Timer Short",
                            "ID Timer",
                            "Patch Timer",
                            "Autodial Timer",
                            "Emergency Autodial Timer",
                            "DTMF Access Mode Timer",
                            "Timeout Timer Long",
                            "Timeout Timer Short",
                            "DTMF Muting Timer",
                            "Fan Timer",
                            "Tail Message Counter",
                            "Phone Rings Counter",
                            "Remote Base Auto-Shutoff Timer"};

const LPSTR courtesyToneNames[] = {"Main Receiver Courtesy Tone",
                                   "Main Receiver Courtesy Tone, Link Alert Mode, Link Receiver Active",
                                   "Main Receiver Courtesy Tone, Link Transmit Enabled",
                                   "Link Receiver Courtesy Tone, Link Transmit Disabled",
                                   "Link Receiver Courtesy Tone, Link Transmit Enabled",
                                   "Reserved",
                                   "CI-V Tune Mode Courtesy Tone",
                                   "Control Receiver Unlocked Courtesy Tone"};


const LPSTR controlGroupNames[] = {"Group 0 - Repeater Control",
                                   "Group 1 - Repeater Control II",
                                   "Group 2 - Voice and tail ID messages",
                                   "Group 3 - Miscellaneous Settings",
                                   "Group 4 - Autopatch Configuration",
                                   "Group 5 - Link Port Configuration",
                                   "Group 6 - Digital Output Configuration",
                                   "Group 7 - Digital Output Control",
                                   "Group 8 - Programming Write Protect",
                                   "Group 9 - Control Op Group Access"};

const LPSTR controlItemNames[] = { "Repeater Enable",                 // 0.0
                                   "Repeater CTCSS Required",         // 0.1
                                   "Key Up Delay (Kerchunk Filter)",  // 0.2
                                   "Hang Timer Enable",               // 0.3
                                   "Select Long Hang Timer",          // 0.4
                                   "DTMF Access Mode",                // 0.5
                                   "Enable Courtesy Tone",            // 0.6
                                   "Control Operator CTCSS required", // 0.7
                                   
                                   "Time Out Timer Enable",           // 1.0
                                   "Select Long Time Out Timer",      // 1.1
                                   "Enable Dual Squelch",             // 1.2
                                   "Enable DTMF Muting",              // 1.3
                                   "Drop Link to Mute DTMF",          // 1.4
                                   "Patch Requires CTCSS",            // 1.5
                                   "DTMF pad test enable",            // 1.6
                                   "Link Port to Control Receiver",   // 1.7

                                   "Enable Voice Initial ID",         // 2.0
                                   "Enable Normal ID #1",             // 2.1
                                   "Enable Normal ID #2",             // 2.2
                                   "Enable Normal ID #3",             // 2.3
                                   "Enable Tail Message #1",          // 2.4
                                   "Enable Tail Message #2",          // 2.5
                                   "Enable Tail Message #3",          // 2.6
                                   "Enable Mailbox Tail Message",     // 2.7
                                   
                                   "CI-V Tune sets Receive Mode",     // 3.0
                                   "Allow ID Stomp by Key Up",        // 3.1
                                   "Enable Voice Time Out Message",   // 3.2
                                   "Link Port Slaved Repeater Mode",  // 3.3
                                   "Digital Output is Fan Control",   // 3.4
                                   "Digital Output Control",          // 3.5
                                   "DAD installed on Main Port",      // 3.6
                                   "DAD installed on Link Port",      // 3.7
                                   
                                   "Enable Autopatch",                // 4.0
                                   "Enable Unrestricted Autopatch",   // 4.1
                                   "Autodial Enabled",                // 4.2
                                   "Emergency Autodial Enabled",      // 4.3
                                   "Disable Emergency Autodial Timer",// 4.4
                                   "Enable Reverse Patch",            // 4.5
                                   "Reverse Patch Ring On Air",       // 4.6
                                   "Enable Phone Auto-Answer",        // 4.7
                                   
                                   "Link Port Alert Mode",            // 5.0
                                   "Link Port Monitor Mode",          // 5.1
                                   "Link Port Transmit Mode",         // 5.2
                                   "Keep Link Enabled During Patch",  // 5.3
                                   "Link Prefix Enable",              // 5.4
                                   "Link Port Requires CTCSS",        // 5.5
                                   "Link Port Dual-Squelch Mode",     // 5.6
                                   "Enable Link Port Timeout Timer",  // 5.7
                                   
                                   "Digital Output 1 Pulsed Mode",    // 6.0
                                   "Digital Output 2 Pulsed Mode",    // 6.1
                                   "Digital Output 3 Pulsed Mode",    // 6.2
                                   "Digital Output 4 Pulsed Mode",    // 6.3
                                   "Digital Output 5-8 Pulsed Mode",  // 6.4
                                   "Digital Outputs One-Of Mode",     // 6.5
                                   "Drop Main PTT to Mute DTMF",      // 6.6
                                   "Suppress Autopatch Number Readback", // 6.7
                                   
                                   "Digital Output 1 Control",        // 7.0
                                   "Digital Output 2 Control",        // 7.1
                                   "Digital Output 3 Control",        // 7.2
                                   "Digital Output 4 Control",        // 7.3
                                   "Digital Output 5 Control",        // 7.4
                                   "Digital Output 6 Control",        // 7.5
                                   "Digital Output 7 Control",        // 7.6
                                   "Digital Output 8 Control",        // 7.7
                                   
                                   "Write Protect Control Groups",          // 8.0
                                   "WRite Protect Prefixes",                // 8.1
                                   "Write Protect Timers",                  // 8.2
                                   "Write Protect Patch Setup",             // 8.3
                                   "Write Protect Autodials",               // 8.4
                                   "(reserved - do not use)",               // 8.5
                                   "Write Protect CW and Courtesy Tones",   // 8.6
                                   "WRite Protect Pre-Recorded Vocabulary", // 8.7
                                   
                                   "Group 0 Access Enable",  // 9.0
                                   "Group 1 Access Enable",  // 9.0
                                   "Group 2 Access Enable",  // 9.0
                                   "Group 3 Access Enable",  // 9.0
                                   "Group 4 Access Enable",  // 9.0
                                   "Group 5 Access Enable",  // 9.0
                                   "Group 6 Access Enable",  // 9.0
                                   "Group 7 Access Enable"}; // 9.0

const LPSTR tones[] = {"DTMF 0",        // 00 
                       "DTMF 1",        // 01 
                       "DTMF 2",        // 02 
                       "DTMF 3",        // 03 
                       "DTMF 4",        // 04 
                       "DTMF 5",        // 05 
                       "DTMF 6",        // 06 
                       "DTMF 7",        // 07 
                       "DTMF 8",        // 08 
                       "DTMF 9",        // 09 
                       "DTMF A",        // 10 
                       "DTMF B",        // 11 
                       "DTMF C",        // 12 
                       "DTMF D",        // 13 
                       "DTMF *",        // 14 
                       "DTMF #",        // 15 
                       "D#5",           // 16 
                       "E5",            // 17 
                       "F5",            // 18 
                       "F#5",           // 19 
                       "G5",            // 20 
                       "G#5",           // 21 
                       "A5",            // 22 
                       "A#5",           // 23 
                       "B5",            // 24 
                       "C6",            // 25 
                       "C#6",           // 26 
                       "D6",            // 27 
                       "D#6",           // 28 
                       "E6",            // 29 
                       "F6",            // 30 
                       "F#6",           // 31 
                       "G6",            // 32 
                       "G#6",           // 33 
                       "A6",            // 34 
                       "A#6",           // 35 
                       "B6",            // 36 
                       "C7",            // 37 
                       "C#7",           // 38 
                       "D7",            // 39 
                       "D#7",           // 40 
                       "1300 Hz",       // 41 
                       "2100 Hz",       // 42 
                       "1200 Hz",       // 43 
                       "2200 Hz",       // 44 
                       "980 Hz",        // 45 
                       "1180 Hz",       // 46 
                       "1070 Hz",       // 47 
                       "1270 Hz",       // 48 
                       "1650 Hz",       // 49 
                       "1850 Hz",       // 50 
                       "2025 Hz",       // 51 
                       "2225 Hz",       // 52 
                       "DTMF row 1",    // 53 
                       "DTMF row 2",    // 54 
                       "DTMF row 3",    // 55 
                       "DTMF row 4",    // 56 
                       "DTMF column 1", // 57 
                       "DTMF column 2", // 58 
                       "DTMF column 3", // 59 
                       "DTMF column 4", // 60 
                       "None",          // 61 
                       "None",          // 62 
                       "None"};         // 63 

const BYTE toneTable[] = {0x10,	// DTMF 0 tone  -- 00
                          0x11,	// DTMF 1 tone  -- 01
                          0x12,	// DTMF 2 tone  -- 02
                          0x13,	// DTMF 3 tone  -- 03
                          0x14,	// DTMF 4 tone  -- 04
                          0x15,	// DTMF 5 tone  -- 05
                          0x16,	// DTMF 6 tone  -- 06
                          0x17,	// DTMF 7 tone  -- 07
                          0x18,	// DTMF 8 tone  -- 08
                          0x19,	// DTMF 9 tone  -- 09
                          0x1a,	// DTMF A tone  -- 10
                          0x1b,	// DTMF B tone  -- 11
                          0x1c,	// DTMF C tone  -- 12
                          0x1d,	// DTMF D tone  -- 13
                          0x1e,	// DTMF * tone  -- 14
                          0x1f,	// DTMF # tone  -- 15
                          0x30,	// note D#5     -- 16
                          0x31,	// note E5      -- 17
                          0x32,	// note F5      -- 18
                          0x33,	// note F#5     -- 19
                          0x34,	// note G5      -- 20
                          0x35,	// note G#5     -- 21
                          0x36,	// note A5      -- 22
                          0x37,	// note A#5     -- 23
                          0x38,	// note B5      -- 24
                          0x39,	// note C6      -- 25
                          0x3a,	// note C#6     -- 26
                          0x29,	// note D6      -- 27
                          0x3b,	// note D#6     -- 28
                          0x3c,	// note E6      -- 29
                          0x3d,	// note F6      -- 30
                          0x0e,	// note F#6     -- 31
                          0x3e,	// note G6      -- 32
                          0x2c,	// note G#6     -- 33
                          0x3f,	// note A6      -- 34
                          0x04,	// note A#6     -- 35
                          0x05,	// note B6      -- 36
                          0x25,	// note C7      -- 37
                          0x2f,	// note C#7     -- 38
                          0x06,	// note D7      -- 39
                          0x07,	// note D#7     -- 40
                          0x24,	// modem 1300   -- 41
                          0x25,	// modem 2100   -- 42
                          0x26,	// modem 1200   -- 43
                          0x27,	// modem 2200   -- 44
                          0x28,	// modem  980   -- 45
                          0x29,	// modem 1180   -- 46
                          0x2a,	// modem 1070   -- 47
                          0x2b,	// modem 1270   -- 48
                          0x2c,	// modem 1650   -- 49
                          0x2d,	// modem 1850   -- 50
                          0x2e,	// modem 2025   -- 51
                          0x2f,	// modem 2225   -- 52
                          0x08,	// dtmf row 1   -- 53
                          0x09,	// dtmf row 2   -- 54
                          0x0a,	// dtmf row 3   -- 55
                          0x0b,	// dtmf row 4   -- 56
                          0x0c,	// dtmf col 1   -- 57
                          0x0d,	// dtmf col 2   -- 58
                          0x0e,	// dtmf col 3   -- 59
                          0x0f,	// dtmf col 4   -- 60
                          0x00,	// no tone      -- 61
                          0x00,	// no tone      -- 62
                          0x00};// no tone      -- 63

// CW generation characters
const char cwIndex[] = " !#=/0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
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
                        0x13}; // z
const char ctcwmap[] = "0123456789~ /#=!~~~~~ABC~~~~~~~DEF~~~~~~~GHI~~~~~~~JKL~~~~~~~MNO~~~~~~QPRS~~~~~~~TUV~~~~~ZWXY~~~~~~~";

// used for bit set and clear operations
const BYTE bitValues[] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};

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
    strcpy(filter, "NHRC-10 Controller Data (*.bin)|*.bin|");

    for (i = 0; filter[i] != '\0'; i++)
    {
        if (filter[i] == '|')
            filter[i] = '\0';
    }
    unsaved = FALSE;
    dataLoaded = FALSE;
    
    if (!hPrevInstance)
    {
        wcex.cbSize = sizeof(WNDCLASSEX); 
        wcex.style			= CS_HREDRAW | CS_VREDRAW;
        wcex.lpfnWndProc	= (WNDPROC)WndProc;
        wcex.cbClsExtra		= 0;
        wcex.cbWndExtra		= 0;
        wcex.hInstance		= hInstance;
        wcex.hIcon			= LoadIcon(hInstance, (LPCTSTR)IDI_A_PROGRAMMER);
        wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
        wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
        wcex.lpszMenuName	= (LPCSTR)IDC_PROGRAMMER;
        wcex.lpszClassName	= "PROGRAMMER";
        wcex.hIconSm		= LoadIcon(wcex.hInstance, (LPCTSTR)IDI_N);
        RegisterClassEx(&wcex);
    } // if !hPrevInstance
    
    // Perform application initialization:
    if (!InitInstance (hInstance, nCmdShow)) 
    {
        return FALSE;
    }

    hAccelTable = LoadAccelerators(hInstance, (LPCTSTR)IDC_PROGRAMMER);

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
    hWnd = CreateWindow("PROGRAMMER",         // class name
		                "NHRC-10 Programmer", // Window Titlt
						WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,  // style
                        CW_USEDEFAULT,        // x
						CW_USEDEFAULT,        // y
						300,                  // width
						150,                  // height
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
    int areaCodeIndex;
    char text[1024];
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

                case ID_FILE_NEW:
                    if (unsaved)
                    {
                        if (MessageBox(hWnd,
                                       "Unsaved data exists.\nAre you sure?",
                                       "NHRC-10 Programmer",
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
                    strcpy(filename, ofn.lpstrFile);
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

                case ID_EDIT_AUTODIALS:
                    if (DialogBox(hInst, (LPCTSTR)IDD_AUTODIALS,
                                  hWnd, (DLGPROC) AutodialsDialogBoxProc) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(text, "Could not create dialog, error %u.", dwError);
                        MessageBox(hWnd, text, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    SetWindowTitle(hWnd, filename);
                    break;

                case ID_EDIT_EMERGENCYAUTODIALS:
                    if (DialogBox(hInst, (LPCTSTR)IDD_EMERGENCYAUTODIALS,
                                  hWnd, (DLGPROC)EmergencyAutodialsDialogBoxProc) == -1)
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

                case ID_AUTOPATCH_AREACODE00:
                case ID_AUTOPATCH_AREACODE01:
                case ID_AUTOPATCH_AREACODE02:
                case ID_AUTOPATCH_AREACODE03:
                case ID_AUTOPATCH_AREACODE04:
                case ID_AUTOPATCH_AREACODE05:
                case ID_AUTOPATCH_AREACODE06:
                case ID_AUTOPATCH_AREACODE07:
                case ID_AUTOPATCH_AREACODE09:
                case ID_AUTOPATCH_AREACODE10:
                case ID_AUTOPATCH_AREACODE11:
                case ID_AUTOPATCH_AREACODE12:
                case ID_AUTOPATCH_AREACODE13:
                case ID_AUTOPATCH_AREACODE14:
                case ID_AUTOPATCH_AREACODE15:
                    areaCodeIndex = wmId - ID_AUTOPATCH_AREACODE00;

                    if (DialogBoxParam(hInst,
                                       (LPCTSTR)IDD_AUTOPATCH,
                                       hWnd,
                                       (DLGPROC)AutopatchDialogBoxProc,
                                       (LPARAM) areaCodeIndex) == -1)
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
			strcpy(text, 
                "3 Easy Steps.\n\n"
				"1. Load data from controller or file.\n"
				"2. Edit Data.\n"
				"3. Save data to controller and/or file");
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


// Message handler for get data status box.
LRESULT CALLBACK GetDataTransferDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    BYTE rxBuffer[CIV_BUFFER_SIZE];
    BYTE txBuffer[CIV_BUFFER_SIZE];
    int rxBufferCount = 0;
    DWORD txBufferCount = 0;
    HANDLE hCom;
    DWORD byteCount = 0;
    BOOL status;
    DWORD dwError;
    BYTE checksum;
    BYTE d;
    BYTE receivedChecksum;
    int bytesInPacket = 0;
    char text[1024];
    char asciiMessage[CIV_BUFFER_SIZE*3 + 2];
    int i;
    int ok = TRUE;
    int receivedAddress;

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
                txBuffer[txBufferCount++] = CIV_PREAMBLE;
                txBuffer[txBufferCount++] = CIV_PREAMBLE;
                txBuffer[txBufferCount++] = CIV_NHRC10_ADDRESS;
                txBuffer[txBufferCount++] = CIV_PC_ADDRESS;
                txBuffer[txBufferCount++] = CIV_NHRC_PRIVATE;
                txBuffer[txBufferCount++] = CIV_NHRC_READ;
                checksum = 0;
                d = (BYTE) (xferAddress >> 12 & 0x0f); // address hi byte, hi nibble
                txBuffer[txBufferCount++] = d;
                checksum = d;
                d = (BYTE) (xferAddress >>  8 & 0x0f); // address hi byte, lo nibble
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                d = (BYTE) (xferAddress >>  4 & 0x0f); // address lo byte, hi nibble
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                d = (BYTE) (xferAddress       & 0x0f); // address lo byte, lo nibble
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                d = CIV_TRANSFER_SIZE; // transfer size
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                txBuffer[txBufferCount++] = (BYTE) ((checksum >> 4) & 0x0f); // checksum hi nibble
                txBuffer[txBufferCount++] = (BYTE) (checksum        & 0x0f); // checksum lo nibble
                txBuffer[txBufferCount++] = CIV_END_OF_MESSAGE;

                status = WriteFile(hCom, txBuffer, txBufferCount, &byteCount, NULL);
                if (!status || !byteCount)
                {    
                    dwError = GetLastError();
                    wsprintf(text, "Could not get Write comm port, error #%d.", dwError);
                    ok = FALSE;
                } // if !status ...
            } // if ok
            if (ok)
            {
                // should get back transmitted message...
                status = ReadFile(hCom, rxBuffer, txBufferCount, &byteCount, NULL);
                if ((status == 0) || (byteCount == 0))
                {
                    strcpy(text, "No echo from controller interface.\nCheck data cables.");
                    ok = FALSE;
                } // if !status || !byteCount
                if (ok && (byteCount != txBufferCount))
                {
                    wsprintf(text, "Bad echo from controller interface.\nCheck data cables.\n(sent %d, received %d)", txBufferCount, byteCount);
                    ok = FALSE;
                } // if !status || !byteCount 
            } // if ok
            if (ok)
            {
                // should now get controller's response...
                memset(rxBuffer, 0, CIV_BUFFER_SIZE);
                status = ReadFile(hCom, rxBuffer, CIV_BUFFER_SIZE, &byteCount, NULL);
                if (!status || !byteCount)
                {
                    strcpy(text, "No response from controller.\n  Check data cables.");
                    ok = FALSE;
                } // if !status || !byteCount
            } // if ok
            if (ok)
            {
                if (byteCount != 30)
                {
                    CIVtoASCII(rxBuffer, asciiMessage);
                    wsprintf(text, "Bad data from controller.\n(%s, %d bytes)", asciiMessage, byteCount);
                    ok = FALSE;
                } // if byteCount != 30
            } // if ok
            if (ok)
            {
                if (rxBuffer[0] != 0xfe ||
                    rxBuffer[1] != 0xfe ||
                    rxBuffer[2] != 0xe1 ||
                    rxBuffer[3] != 0xe0 ||
                    rxBuffer[4] != 0x77 ||
                    rxBuffer[5] != 0x01)
                {
                    CIVtoASCII(rxBuffer, asciiMessage);
                    wsprintf(text, "Bad data from controller= %s, %d bytes", asciiMessage, byteCount);
                    ok = FALSE;
                } // if rxBuffer[0] != ...
            } // if ok
        
            if (ok)
            {
                rxBufferCount = 6;
                // now validate checksum
                checksum = 0;
                checksum = (BYTE) (checksum + rxBuffer[rxBufferCount++]); // hi nibble of hi byte of address
                checksum = (BYTE) (checksum + rxBuffer[rxBufferCount++]); // lo nibble of hi byte of address
                checksum = (BYTE) (checksum + rxBuffer[rxBufferCount++]); // hi nibble of lo byte of address
                checksum = (BYTE) (checksum + rxBuffer[rxBufferCount++]); // lo nibble of lo byte of address
                bytesInPacket = rxBuffer[rxBufferCount]; // get number of bytes in transfer
                checksum = (BYTE) (checksum +  rxBuffer[rxBufferCount++]); // number of bytes in transfer
                for (i=0; i < bytesInPacket; i++)
                {
                    checksum = (BYTE) (checksum + rxBuffer[rxBufferCount++]); // hi nibble of data byte
                    checksum = (BYTE) (checksum + rxBuffer[rxBufferCount++]); // lo nibble of data byte
                } // for i
                receivedChecksum = 0;
                receivedChecksum = (BYTE) ((rxBuffer[rxBufferCount] << 4) + rxBuffer[rxBufferCount+1]);
                rxBufferCount += 2;
                if (checksum != receivedChecksum)
                {
                    wsprintf(text, "Checksum error. calculated=%02x, received=%02x", checksum, receivedChecksum);
                    ok = FALSE;
                } // if checksum != receivedChecksum
                if (rxBuffer[rxBufferCount] != 0xfd)
                {
                    CIVtoASCII(rxBuffer, asciiMessage);
                    wsprintf(text, "Bad data from controller= %s, %d bytes", asciiMessage, byteCount);
                    ok = FALSE;
                } // if rxBuffer[rxBufferCount] != 0xfd ...
            } // if ok
            if (ok)
            {
                rxBufferCount = 11;
                // now validate checksum
                receivedAddress = (rxBuffer[6] << 12) + (rxBuffer[7] << 8) + (rxBuffer[8] << 4) + rxBuffer[9];
                bytesInPacket = rxBuffer[10]; // get number of bytes in transfer

                // data is good, copy it.
                for (i=0; i < bytesInPacket; i++)
                {
                    eepromData[receivedAddress + i] = (BYTE) ((rxBuffer[rxBufferCount] << 4) + rxBuffer[rxBufferCount+1]);
                    rxBufferCount += 2;
                } // for i
                xferAddress += CIV_TRANSFER_SIZE;

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

//-----------------------------------------------------------------------------------------
// Message handler for send data status box.
LRESULT CALLBACK SendDataTransferDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    BYTE rxBuffer[CIV_BUFFER_SIZE];
    BYTE txBuffer[CIV_BUFFER_SIZE];
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
    char asciiMessage[CIV_BUFFER_SIZE*3 + 2];

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
                txBuffer[txBufferCount++] = CIV_PREAMBLE;
                txBuffer[txBufferCount++] = CIV_PREAMBLE;
                txBuffer[txBufferCount++] = CIV_NHRC10_ADDRESS;
                txBuffer[txBufferCount++] = CIV_PC_ADDRESS;
                txBuffer[txBufferCount++] = CIV_NHRC_PRIVATE;
                txBuffer[txBufferCount++] = CIV_NHRC_WRITE;

                checksum = 0;
                d = (BYTE) (xferAddress >> 12 & 0x0f); // address hi byte, hi nibble
                txBuffer[txBufferCount++] = d;
                checksum = d;
                d = (BYTE) (xferAddress >>  8 & 0x0f); // address hi byte, lo nibble
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                d = (BYTE) (xferAddress >>  4 & 0x0f); // address lo byte, hi nibble
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                d = (BYTE) (xferAddress       & 0x0f); // address lo byte, lo nibble
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                d = CIV_TRANSFER_SIZE; // transfer size
                txBuffer[txBufferCount++] = d;
                checksum = (BYTE) (checksum + d);
                
                // add the eeprom data bytes to the message...
                for (i=0; i < CIV_TRANSFER_SIZE; i++)
                {
                    eeByte = eepromData[xferAddress + i];
                    d = (BYTE) ((eeByte >> 4) & 0x0f);
                    txBuffer[txBufferCount++] = d;
                    checksum = (BYTE) (checksum + d);
                    d = (BYTE) (eeByte & 0x0f);
                    txBuffer[txBufferCount++] = d;
                    checksum = (BYTE) (checksum + d);
                } // for i 
                txBuffer[txBufferCount++] = (BYTE) ((checksum >> 4) & 0x0f); // checksum hi nibble
                txBuffer[txBufferCount++] = (BYTE) (checksum        & 0x0f); // checksum lo nibble
                txBuffer[txBufferCount++] = CIV_END_OF_MESSAGE;
                xferAddress += CIV_TRANSFER_SIZE;

                status = WriteFile(hCom, txBuffer, txBufferCount, &byteCount, NULL);
                if (!status || !byteCount)
                {    
                    dwError = GetLastError();
                    wsprintf(text, "Could not get Write comm port, error #%d.", dwError);
                    ok = FALSE;
                } // if !status ... 
            } // if ok
            if (ok)
            {
                // should get back transmitted message...
                status = ReadFile(hCom, rxBuffer, byteCount, &byteCount, NULL);
                if (!status || !byteCount)
                {
                    strcpy(text, "No echo from controller interface.\nCheck data cables.");
                    ok = FALSE;
                } // if !status || !byteCount 
            } // if ok
            if (ok)
            {
                Sleep(50);
                // should now get controller's response...
                status = ReadFile(hCom, rxBuffer, CIV_BUFFER_SIZE, &byteCount, NULL);
                if (!status || !byteCount)
                {
                    strcpy(text, "No response from controller.\nCheck data cables.");
                    ok = FALSE;
                } // if !status || !byteCount 
            } // if ok
            if (ok)
            {
                if (byteCount != 6)
                {
                    CIVtoASCII(rxBuffer, asciiMessage);
                    wsprintf(text, "Bad data received from controller.\n(%s)", asciiMessage);
                    ok = FALSE;
                } // if byteCount != 6
            } // if ok
            if (ok)
            {
                if (rxBuffer[0] == CIV_PREAMBLE &&
                    rxBuffer[1] == CIV_PREAMBLE &&
                    rxBuffer[2] == CIV_PC_ADDRESS &&
                    rxBuffer[3] == CIV_NHRC10_ADDRESS &&
                    rxBuffer[5] == CIV_END_OF_MESSAGE)
                { // valid response message...
                    if (rxBuffer[4] != CIV_OK)
                    {
                        wsprintf(text, "Controller did not send ACK.");
                        ok = FALSE;
                    } 
                } // if rxBuffer[0] == ...
                else
                {
                    CIVtoASCII(rxBuffer, asciiMessage);
                    wsprintf(text, "Controller sent invalid response: %s", asciiMessage);
                    ok = FALSE;
                } 
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
// Dialog box proc for Autodials dialog box.
LRESULT CALLBACK AutodialsDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i;
    HWND hwndCtl;
    char messageText[256];
    WNDPROC oldWindowProc;
    
    switch (message)
    {
        case WM_INITDIALOG:
            hwndCtl = GetDlgItem(hDlg, IDC_RANGE_COMBO);
            for (i = 0; i < MAX_AUTODIAL; i+=10)
            {
                wsprintf(messageText, "%d - %d", i, i+9);
                SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) messageText);
            } // for i 
            //SendMessage(hwndCtl, CB_SETMINVISIBLE, 10, 0);
            SendMessage(hwndCtl, CB_SETCURSEL, 0, 0);

            for (i = 0; i < 10; i++)
            {
                hwndCtl = GetDlgItem(hDlg, IDC_APATCH_EDIT_0 + i);
                oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
                SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) oldWindowProc);
                SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) DTMFEditProc);
                SendMessage(hwndCtl, EM_LIMITTEXT, AUTODIAL_LENGTH - 1, 0);
            } // for i
            setAutodials(hDlg);
            return TRUE;

        case WM_COMMAND:
            switch (LOWORD(wParam))
            {
                case IDC_RANGE_COMBO:
                    
                    switch (HIWORD(wParam))
                    {
                        case CBN_SELCHANGE:
                            getAutodials(hDlg);
                            setAutodials(hDlg);
                            return TRUE;
                        default:
                            return FALSE;
                    } // switch HIWORD (wParam)

                case IDOK:
                    // now get the data from the dialog...
                    getAutodials(hDlg);
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // AutodialsDialogBoxProc

void getAutodials(HWND hDlg)
{
    HWND hwndCtl;
    char tempString[AUTODIAL_LENGTH+1];
    int i,j;
    int base = 0;
    int address;

    base = GetWindowLong(hDlg, GWL_USERDATA);

    for(i=0; i<10; i++)
    {
        hwndCtl = GetDlgItem(hDlg, IDC_APATCH_EDIT_0 + i);
        memset(tempString, 0, AUTODIAL_LENGTH);
        GetWindowText(hwndCtl, tempString, AUTODIAL_LENGTH);
        address = EEPROM_AUTODIAL_BASE + (base + i) * AUTODIAL_LENGTH;
        for (j=0; j < EPATCH_LENGTH; j++)
        {
            eepromData[address+j] = dtmf2bin(tempString[j]);
        } // for j 
    } // for i
    unsaved = TRUE;
} // readAutodials()

void setAutodials(HWND hDlg)
{
    HWND hwndCtl;
    char tempString[AUTODIAL_LENGTH+1];
    char message[32];
    int i,j;
    int base = 0;
    LRESULT lResult;
    BYTE b;
    int address;

    hwndCtl = GetDlgItem(hDlg, IDC_RANGE_COMBO);
    lResult = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
    base = lResult * 10;
    SetWindowLong(hDlg, GWL_USERDATA, base);
    for(i=0; i<10; i++)
    {
        hwndCtl = GetDlgItem(hDlg, IDC_APATCH_LABEL_0 + i);
        wsprintf(message, "Autodial %3d", base + i);
        SetWindowText(hwndCtl, message);
        hwndCtl = GetDlgItem(hDlg, IDC_APATCH_EDIT_0 + i);
        memset(tempString, 0, AUTODIAL_LENGTH+1);
        address = EEPROM_AUTODIAL_BASE + (base + i) * AUTODIAL_LENGTH;
        for (j=0; j < AUTODIAL_LENGTH; j++)
        {
            b = eepromData[address+j];
            tempString[j] = (b == 0xff) ? '\0' : bin2dtmf(b);
        } // for j 
        SetWindowText(hwndCtl, tempString);
    } // for i
} // setAutodials() 


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
// Dialog box proc for EmergencyAutodials dialog box.
LRESULT CALLBACK EmergencyAutodialsDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int i,j;
    HWND hwndCtl;
    int address;
    char tempString[EPATCH_LENGTH];
    BYTE b;
    WNDPROC oldWindowProc;
    
    switch (message)
    {
        case WM_INITDIALOG:
            for (i = 0; i < MAX_EPATCH; i++)
            {
                hwndCtl = GetDlgItem(hDlg, IDC_EPATCH_EDIT_0 + i);
                address = EEPROM_EPATCH_BASE + i * EPATCH_LENGTH;
                oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
                SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) oldWindowProc);
                SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) DTMFEditProc);
                SendMessage(hwndCtl, EM_LIMITTEXT, EPATCH_LENGTH - 1, 0);
                memset(tempString, 0, EPATCH_LENGTH);
                for (j=0; j < EPATCH_LENGTH; j++)
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
                    for (i = 0; i < MAX_EPATCH; i++)
                    {
                        hwndCtl = GetDlgItem(hDlg, IDC_EPATCH_EDIT_0 + i);
                        address = EEPROM_EPATCH_BASE + i * EPATCH_LENGTH;
                        memset(tempString, 0, EPATCH_LENGTH);
                        GetWindowText(hwndCtl, tempString, EPATCH_LENGTH);
                        //memset(eepromData+address, 0, EPATCH_LENGTH);
                        for (j=0; j < EPATCH_LENGTH; j++)
                        {
                            eepromData[address+j] = dtmf2bin(tempString[j]);
                        } // for j 
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
} // EmergencyAutodialsDialogBoxProc



//--------------------------------------------------
// Dialog box proc for Autopatch Configuration Dialog.
LRESULT CALLBACK AutopatchDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int areaCodeIndex = 0;
    int i;
    HWND hwndCtl;
    int address;
    char tempString[WORKSTRING_LENGTH];
    BYTE b;
    LRESULT lResult;
    WNDPROC oldWindowProc;
    DWORD dwError;
        
    switch (message)
    {
        case WM_INITDIALOG:
            areaCodeIndex = (int) lParam;
            SetWindowLong(hDlg, GWL_USERDATA, MAKELONG(0, (WORD) areaCodeIndex));
            address = EEPROM_AUTOPATCH_BASE + areaCodeIndex * EEPROM_AUTOPATCH_LENGTH;

            // set heading
            hwndCtl = GetDlgItem(hDlg, IDC_HEADING);
            wsprintf(tempString, "Configure Settings for Area Code #%02d", areaCodeIndex);
            SetWindowText(hwndCtl, tempString);
            
            // set up area code edit field
            hwndCtl = GetDlgItem(hDlg, IDC_AREACODE);
            oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
            SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) oldWindowProc);
            SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) DTMFEditProc);
            SendMessage(hwndCtl, EM_LIMITTEXT, AREACODE_LENGTH, 0);
            memset(tempString, 0, WORKSTRING_LENGTH);
            for (i = 0; i < AREACODE_LENGTH; i++)
            {
                b = eepromData[address + EEPROM_AREACODE_OFFSET + i];
                tempString[i] = (b == 0xff) ? '\0' : bin2dtmf(b);
            } // for i 
            SetWindowText(hwndCtl, tempString);

            // set up dialing prefix edit field
            hwndCtl = GetDlgItem(hDlg, IDC_DIAL_PREFIX);
            oldWindowProc = (WNDPROC) GetWindowLong(hwndCtl, GWL_WNDPROC);
            SetWindowLong(hwndCtl, GWL_USERDATA, (LONG) oldWindowProc);
            SetWindowLong(hwndCtl, GWL_WNDPROC, (LONG) DTMFEditProc);
            SendMessage(hwndCtl, EM_LIMITTEXT, DIALING_PREFIX_LENGTH, 0);
            memset(tempString, 0, WORKSTRING_LENGTH);
            for (i = 0; i < DIALING_PREFIX_LENGTH; i++)
            {
                b = eepromData[address + EEPROM_PREFIX_OFFSET + i];
                tempString[i] = (b == 0xff) ? '\0' : bin2dtmf(b);
            } // for j 
            SetWindowText(hwndCtl, tempString);

            b = eepromData[address + EEPROM_AREACODE_CONFIG];

            // set area code enabled checkbox
            hwndCtl = GetDlgItem(hDlg, IDC_BANK_ENABLED);
            SendMessage(hwndCtl, BM_SETCHECK, isBitSet(b, 0) ? BST_CHECKED : BST_UNCHECKED, 0);

            // set leading 1 allowed
            hwndCtl = GetDlgItem(hDlg, IDC_LEADING_1_ALLOWED);
            SendMessage(hwndCtl, BM_SETCHECK, isBitSet(b, 1) ? BST_CHECKED : BST_UNCHECKED, 0);

            // set leading 1 required
            hwndCtl = GetDlgItem(hDlg, IDC_LEADING_1_REQUIRED);
            SendMessage(hwndCtl, BM_SETCHECK, isBitSet(b, 2) ? BST_CHECKED : BST_UNCHECKED, 0);

            // set local area code
            hwndCtl = GetDlgItem(hDlg, IDC_LOCAL_AREA_CODE);
            if (areaCodeIndex == AUTOPATCH_LOCAL_AREA)
            { // is local area code
                EnableWindow(hwndCtl, TRUE);
                SendMessage(hwndCtl, BM_SETCHECK, isBitSet(b, 3) ? BST_CHECKED : BST_UNCHECKED, 0);
            } // if areaCodeIndex == AUTOPATCH_LOCAL_AREA
            else
            { // is not local area code
                EnableWindow(hwndCtl, FALSE);
                SendMessage(hwndCtl, BM_SETCHECK, BST_UNCHECKED, 0);
            } // if areaCodeIndex == AUTOPATCH_LOCAL_AREA

            // set dial prefix enabled
            hwndCtl = GetDlgItem(hDlg, IDC_DIAL_PREFIX_ENABLED);
            SendMessage(hwndCtl, BM_SETCHECK, isBitSet(b, 4) ? BST_CHECKED : BST_UNCHECKED, 0);
            return TRUE;

        case WM_COMMAND:
            areaCodeIndex = HIWORD(GetWindowLong(hDlg, GWL_USERDATA));
            address = EEPROM_AUTOPATCH_BASE + areaCodeIndex * EEPROM_AUTOPATCH_LENGTH;
            
            switch (LOWORD(wParam))
            {
                case IDC_ENABLE_ALL_BUTTON:
                    if (MessageBox(hDlg,
                                   "Are you sure you want to enable all exchanges in this area code?",
                                   "Confirm Enable All", MB_OKCANCEL) == IDOK)
                    {
                        for (i=0; i < DIAL_RESTRICTION_LENGTH; i++)
                        {
                            eepromData[address + i] = 0xff;
                        } // for i
                    } // if MessageBox(...) == IDOK
                    return TRUE;
                    
                case IDC_DISABLE_ALL_BUTTON:
                    if (MessageBox(hDlg,
                                   "Are you sure you want to disable all exchanges in this area code?",
                                   "Confirm Disable All", MB_OKCANCEL) == IDOK)
                    {
                        for (i=0; i < DIAL_RESTRICTION_LENGTH; i++)
                        {
                            eepromData[address + i] = 0x00;
                        } // for i
                    } // if MessageBox(...) == IDOK
                    return TRUE;
                    
                case IDC_EDIT_BUTTON:
                    if (DialogBoxParam(hInst,
                                       (LPCTSTR) IDD_EDIT_EXCHANGES,
                                       hDlg,
                                       (DLGPROC) EditExchangesDialogBoxProc,
                                       areaCodeIndex) == -1)
                    {
                        dwError = GetLastError();
                        wsprintf(tempString, "Could not create dialog, error %u.", dwError);
                        MessageBox(hDlg, tempString, "Problem...", MB_ICONSTOP | MB_OK);
                        return FALSE;
                    }
                    return TRUE;
                    
                case IDOK:
                    unsaved = TRUE;
                    b = 0;
                    // get area code
                    hwndCtl = GetDlgItem(hDlg, IDC_AREACODE);
                    memset(tempString, 0, WORKSTRING_LENGTH);
                    GetWindowText(hwndCtl, tempString, WORKSTRING_LENGTH);
                    for (i=0; i < AREACODE_LENGTH; i++)
                    {
                        eepromData[address + EEPROM_AREACODE_OFFSET + i] = dtmf2bin(tempString[i]);
                    } // for i 
                    
                    // get dialing prefix
                    hwndCtl = GetDlgItem(hDlg, IDC_DIAL_PREFIX);
                    memset(tempString, 0, WORKSTRING_LENGTH);
                    GetWindowText(hwndCtl, tempString, WORKSTRING_LENGTH);
                    for (i=0; i < DIALING_PREFIX_LENGTH; i++)
                    {
                        eepromData[address + EEPROM_PREFIX_OFFSET + i] = dtmf2bin(tempString[i]);
                    } // for i
                        
                    // get area code enabled checkbox
                    hwndCtl = GetDlgItem(hDlg, IDC_BANK_ENABLED);
                    lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
                    if (lResult == BST_CHECKED)
                    {
                        b |= 0x01;
                    } // if lResult == BST_CHECKED
                    
                    // get leading 1 allowed
                    hwndCtl = GetDlgItem(hDlg, IDC_LEADING_1_ALLOWED);
                    SendMessage(hwndCtl, BM_SETCHECK, isBitSet(b, 1) ? BST_CHECKED : BST_UNCHECKED, 0);
                    lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
                    if (lResult == BST_CHECKED)
                    {
                        b |= 0x02;
                    } // if lResult == BST_CHECKED
                    
                    // get leading 1 required
                    hwndCtl = GetDlgItem(hDlg, IDC_LEADING_1_REQUIRED);
                    lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
                    if (lResult == BST_CHECKED)
                    {
                        b |= 0x04;
                    } // if lResult == BST_CHECKED
                    
                    // get local area code
                    if (areaCodeIndex == AUTOPATCH_LOCAL_AREA)
                    { // is local area code
                        hwndCtl = GetDlgItem(hDlg, IDC_LOCAL_AREA_CODE);
                        lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
                        if (lResult == BST_CHECKED)
                        {
                            b |= 0x08;
                        } // if lResult == BST_CHECKED
                    } // if areaCodeIndex == AUTOPATCH_LOCAL_AREA
                    
                    // set dial prefix enabled
                    hwndCtl = GetDlgItem(hDlg, IDC_DIAL_PREFIX_ENABLED);
                    lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
                    if (lResult == BST_CHECKED)
                    {
                        b |= 0x10;
                    } // if lResult == BST_CHECKED

                    // save result to EEPROB buffer
                    eepromData[address + EEPROM_AREACODE_CONFIG] = b;
                    
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
                    
                case IDCANCEL:
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // AutopatchDialogBoxProc

//--------------------------------------------------
// Dialog box proc for Edit Exchanges Dialog.
LRESULT CALLBACK EditExchangesDialogBoxProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    int areaCodeIndex = 0;
    int i;
    HWND hwndCtl;
    int address;
    char tempString[WORKSTRING_LENGTH];

    switch (message)
    {
        case WM_INITDIALOG:
            areaCodeIndex = (int) lParam;
            SetWindowLong(hDlg, GWL_USERDATA, MAKELONG(0, (WORD) areaCodeIndex));
            address = EEPROM_AUTOPATCH_BASE + areaCodeIndex * EEPROM_AUTOPATCH_LENGTH;
            
            // set heading
            hwndCtl = GetDlgItem(hDlg, IDC_HEADING);
            wsprintf(tempString, "Exchange Restrictions for Area Code #%02d", areaCodeIndex);
            SetWindowText(hwndCtl, tempString);

            // set up dropdown menu
            hwndCtl = GetDlgItem(hDlg, IDC_HUNDREDS_COMBO);
            for (i = 200; i < 1000; i += 100)
            {
                wsprintf(tempString, "%3d - %3d", i, i + 99);
                SendMessage(hwndCtl, CB_ADDSTRING, 0, (LPARAM) tempString);
            } // for i 
            SendMessage(hwndCtl, CB_SETCURSEL, 0, 0);
            
            setExchangeRestrictions(hDlg);
            return TRUE;
        
        case WM_COMMAND:
            areaCodeIndex = HIWORD(GetWindowLong(hDlg, GWL_USERDATA));
            switch (LOWORD(wParam))
            {
                case IDC_HUNDREDS_COMBO:
                    switch (HIWORD(wParam))
                    {
                        case CBN_SELCHANGE:
                            getExchangeRestrictions(hDlg);
                            setExchangeRestrictions(hDlg);
                            return TRUE;
                        default:
                            return FALSE;
                    } // switch HIWORD (wParam)

                case IDOK:
                    // now get the data from the dialog...
                    getExchangeRestrictions(hDlg);
                    EndDialog(hDlg, LOWORD(wParam));
                    return TRUE;
            } // switch 
            break;
    } // switch
    return FALSE;
} // EditExchangesDialogBoxProc

void getExchangeRestrictions(HWND hDlg)
{
    HWND hwndCtl;
    int i;
    int areaCodeIndex;
    int hundredsIndex;
    int address;
    int bit;
    LRESULT lResult;

    lResult = GetWindowLong(hDlg, GWL_USERDATA);
    hundredsIndex = LOWORD(lResult);
    areaCodeIndex = HIWORD(lResult);
    address = EEPROM_AUTOPATCH_BASE + areaCodeIndex * EEPROM_AUTOPATCH_LENGTH;

    // set exchange enable checkboxes
    bit = hundredsIndex;
    if ((bit < 0) || (bit > 7))
    {
        MessageBox(hDlg, "bit value is invalid","error", MB_ICONSTOP);
        return;
    } // if bit invalid...
                     
    for (i=0; i<100; i++)
    { // loop through exchanges
        hwndCtl = GetDlgItem(hDlg, IDC_CHECK00 + i);
        lResult = SendMessage(hwndCtl, BM_GETCHECK, 0, 0);
        if (lResult == BST_CHECKED)
        { // box is checked
            eepromData[address+i] = eepromData[address+i] | bitValues[bit];
        } // if lResult == BST_CHECKED
        else
        { // box is not checked
            eepromData[address+i] = eepromData[address+i] & ~bitValues[bit];
        } // if lResult == BST_CHECKED
    } // for i
} // getExchangeRestrictions()

void setExchangeRestrictions(HWND hDlg)
{
    HWND hwndCtl;
    int i;
    int hundredsIndex;
    int areaCodeIndex;
    int address;
    char tempString[WORKSTRING_LENGTH];
    int bit;
    LRESULT lResult;

    lResult = GetWindowLong(hDlg, GWL_USERDATA);
    //hundredsIndex = LOWORD(lResult);
    areaCodeIndex = HIWORD(lResult);

    // get hundreds index from dropdown
    hwndCtl = GetDlgItem(hDlg, IDC_HUNDREDS_COMBO);
    hundredsIndex = SendMessage(hwndCtl, CB_GETCURSEL, 0, 0);
    // stash current hundreds index
    SetWindowLong(hDlg, GWL_USERDATA, MAKELONG(hundredsIndex, areaCodeIndex));
    
    address = EEPROM_AUTOPATCH_BASE + areaCodeIndex * EEPROM_AUTOPATCH_LENGTH;

    // set row headers...
    for (i = 0; i < 10; i++)
    {
        hwndCtl = GetDlgItem(hDlg, IDC_LABEL_0 + i);
        wsprintf(tempString, "%02dx", (hundredsIndex + 2) * 10 + i);
        SetWindowText(hwndCtl, tempString);
    } // for i

    // set exchange enable checkboxes
    bit = hundredsIndex;
    if ((bit < 0) || (bit > 7))
    {
        MessageBox(hDlg, "bit value is invalid","error", MB_ICONSTOP);
        return;
    } // if bit invalid...
                     
    for (i=0; i<100; i++)
    { // loop through exchanges
        hwndCtl = GetDlgItem(hDlg, IDC_CHECK00 + i);
        SendMessage(hwndCtl, BM_SETCHECK, isBitSet(eepromData[address+i], bit) ? BST_CHECKED : BST_UNCHECKED, 0);
    } // for i
} // setExchangeRestrictions()

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
                for (i = 0; i<64; i++)
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
    char *comPort = "COM1";
    char message[128];
    hCom = CreateFile(comPort, GENERIC_READ | GENERIC_WRITE,
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
        wsprintf(message, "Could not open %s, error %d.", comPort, dwError);
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
    // Fill in the DCB: baud=9600, 8 data bits, no parity, 1 stop bit. 
    dcb.BaudRate = 9600;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;
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
    for (i=0; i < sizeof cwIndex; i++)
    {
        if (b == cwIndex[i])
            return i;
    } // for
    return -1;
} // cwctByte2index()

BYTE index2cwct(int i)
{
    char c;
    int j;
    c = cwIndex[i];
    for (j=0; j < sizeof(cwIndex); j++)
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
    int i;
    b = (BYTE) (b & 0x7f); // mask out high bit 
    for (i=0; i < sizeof toneTable; i++)
    {
        if (b == toneTable[i])
            return i;
    } // for
    return -1;
} // toneByte2index

BYTE index2toneByte(int i)
{
    return toneTable[i];
} // index2toneByte

// convert a binary CI-V message into human readable form.
void CIVtoASCII(BYTE civMessage[], char messageBuffer[])
{
    int civPtr = 0;
    int messagePtr = 0;
    BYTE civByte;
    do
    {
        civByte = civMessage[civPtr++];
        messageBuffer[messagePtr++] = bin2hex(civByte >> 4 & 0x0f);
        messageBuffer[messagePtr++] = bin2hex(civByte & 0x0f);
        messageBuffer[messagePtr++] = ' ';
    } while ((civByte != CIV_END_OF_MESSAGE) && (civPtr < CIV_BUFFER_SIZE));
    messageBuffer[messagePtr++] = '\0';
}
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

    strcpy(rawFileName, name+pos+1);
    
    if (name[0] != 0 )
    {
        wsprintf(message, "NHRC-10 Programmer - %s %s", rawFileName, unsaved ? "(unsaved)" : "");
    } // if (filename[0] != 0) 
    else
    {
        wsprintf(message, "NHRC-10 Programmer %s", unsaved ? "(unsaved)" : "");
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
