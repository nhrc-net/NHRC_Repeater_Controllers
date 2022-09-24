/******************************************************************************/
/* NHRC-PXP Raw Mode Programmer -- Copyright (C) 2004, NHRC LLC.              */
/******************************************************************************/

#include <windows.h>
#include "Resource.h"

#define DLG_MAIN 200

#define APPTITLE "PXP-Raw"
#define APPNAME "PXP-Raw"
#define APPNAME_RAW PXP-Raw
#define ICON_NAME "nhrc.ico"

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
