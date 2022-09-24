/******************************************************************************/
/* Delta SX Radio Programmer -- Copyright (C) 2001, NHRC LLC.                 */
/******************************************************************************/

#include <windows.h>
#include "Resource.h"

#define DLG_MAIN 200

#define APPTITLE "Delta SX"
#define APPNAME "DeltaSX"
#define APPNAME_RAW DeltaSX
#define ICON_NAME "DeltaSX.ico"

#define VERSION   "1.00"
#define RVERSION   1, 0, 0, 32
#define COPYRIGHT "Copyright \251 2004, 2006 NHRC LLC."
#define BUILDDATE "30 May 2006"

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#define MSG_PRINT_HEADER WM_USER + 100
#define MSG_PRINT_NEXT MSG_PRINT_HEADER + 1
#define MSG_PRINT_CLEANUP MSG_PRINT_NEXT + 1

typedef struct {
    int nRxFrequency;       /* receive frequency */
    int nTxFrequency;       /* transmit frequency */
    int nRxCGCode;          /* receive channel guard code */
    int bUseInverseRxCode;  /* use inverse DCG code for RX */
    int nTxCGCode;          /* transmit channel guard code */
    int bUseInverseTxCode;  /* use inverse DCG Code for TX */
    int bUseSTE;            /* use Squelch Tail Elimination */
    int nCCTCode;           /* Carrier Control Timer value */
} ChannelDataStruct;

typedef struct {
    int nBandCode;          /* Band Code */
    int nIFFrequency;       /* IF Frequency */
    int filler2;            /* filler */
    int filler3;            /* filler */
} RadioDataStruct;

typedef struct {
    int *frequency;
    WNDPROC oldWindowProc;
} FreqEditDataStruct;

