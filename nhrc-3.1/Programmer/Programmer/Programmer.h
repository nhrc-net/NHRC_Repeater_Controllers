#if !defined(AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_)
#define AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "resource.h"

#define EEPROM_SIZE     256 
#define SC_BUFFER_SIZE   32
#define SC_TRANSFER_SIZE  8

/* Serial commands, etc. */
#define SC_ATTENTION_CHAR  ':'
#define SC_READ_CMD_CHAR   'R'
#define SC_WRITE_CMD_CHAR  'W'
#define SC_EOM_CHAR        0x0d
#define SC_ACK             'K'
#define SC_NAK             'N'

// NHRC-3.1 EEPROM addresses and related constants
#define MAX_PREFIX              8        // number of prefixes
#define PREFIX_LENGTH           8        // length of prefixes
#define MAX_TIMER               11       // number of timer presets
#define MAX_CTL_GROUPS          8        // number of control operator groups
#define NUM_CTL_GROUPS          16       // size of saved setup
#define MAX_SAVEDSETS           5        // number of saved setups

#define EEPROM_TIMER_BASE       0x00     // base address of timers
#define EEPROM_CTLOP_BASE       0x10     // base address of saved control operator groups
#define EEPROM_COURTESY_BASE    0x60     // base address of courtesy tones
#define EEPROM_CWID_BASE        0xA0     // base address of CW ID.
#define CWID_LENGTH             15       // max length of CW ID.
#define EEPROM_PREFIX_BASE      0xB0     // base address of prefixes

#define COURTESY_TONE_LENGTH    8        // courtesy tones are 8 bytes long
#define COURTESY_TONE_CW_CHAR   99       // magic value for CW character
#define COURTESY_MAX_TONES      32       // maximum number of courtesy tones

#endif // !defined(AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_)
