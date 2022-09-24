
#if !defined(AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_)
#define AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "resource.h"

#define EEPROM_SIZE 8192 /* 0x2000 */
#define CIV_BUFFER_SIZE 32
#define CIV_TRANSFER_SIZE 8

/* CI-V commands */
/* CI-V device addresses */
#define CIV_NHRC10_ADDRESS	0xe0
#define CIV_PC_ADDRESS		0xe1
#define CIV_IC706_ADDRESS	0x48

/* CI-V message data */
#define CIV_PREAMBLE		0xfe
#define	CIV_END_OF_MESSAGE	0xfd
#define CIV_JAM			0xfc
#define CIV_OK			0xfb
#define CIV_ERR			0xfa

/* CI-V command bytes */
#define CIV_NHRC_PRIVATE	0x77
#define CIV_NHRC_READ		0x00
#define	CIV_NHRC_WRITE		0x01
#define CIV_NHRC_RESET		0x7f

// NHRC10 EEPROM addresses and related constants
#define MAX_PREFIX              16       // number of prefixes
#define PREFIX_LENGTH           8        // length of prefixes
#define EEPROM_PREFIX_BASE      0x0060   // base address of prefixes
#define EEPROM_TIMER_BASE       0x0000   // base address of timers
#define MAX_TIMER               15       // 
#define MAX_EPATCH              10       // number of emergency autodial slots
#define EPATCH_LENGTH           16       // max length of emergency autodial number
#define EEPROM_EPATCH_BASE      0x0160   // base address of emergency autodial numbers
#define AUTODIAL_LENGTH         16       // maximum length of autodial number
#define MAX_AUTODIAL            250      // number of autodial slots
#define EEPROM_AUTODIAL_BASE    0x1000   // base address of autodial slots
#define MAX_CTL_GROUPS          10       // number of control operator groups
#define NUM_CTL_GROUPS          16       // size of saved setup
#define MAX_SAVEDSETS           5        // number of saved setups
#define EEPROM_CTLOP_BASE       0x0100   // base address of saved control operator groups
#define EEPROM_CWID_BASE        0x0010   // base address of CW ID.
#define CWID_LENGTH             15       // max length of CW ID.

#define EEPROM_AUTOPATCH_BASE   0x0200   // base address for patch configuration
#define EEPROM_AUTOPATCH_LENGTH 0x0080   // length of one area code configuration
#define EEPROM_AREACODE_OFFSET  0x0070   // offset for area code
#define AREACODE_LENGTH         3        // length of area code
#define EEPROM_AREACODE_CONFIG  0x0073   // offset of area code config byte
#define EEPROM_PREFIX_OFFSET    0x0074   // offset of dialing prefix
#define DIALING_PREFIX_LENGTH   10       // max length of autopatch dialing prefix
#define AUTOPATCH_LOCAL_AREA    15       // local area code
#define DIAL_RESTRICTION_LENGTH 100      // length of restrictions table

#define EEPROM_COURTESY_BASE    0x0020   // base address of courtesy tones
#define COURTESY_TONE_LENGTH    8        // courtesy tones are 8 bytes long
#define COURTESY_TONE_CW_CHAR   99       // magic value for CW character

#endif // !defined(AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_)
