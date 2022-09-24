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
#define SC_RESET_CMD_CHAR  '!'
#define SC_EOM_CHAR        0x0d
#define SC_ACK             'K'
#define SC_NAK             'N'

// NHRC-17 EEPROM addresses and related constants
#define MAX_PREFIX              8        // number of prefixes
#define PREFIX_LENGTH           8        // length of prefixes
#define MAX_TIMER               15       // number of timer presets
#define MAX_CTL_GROUPS          10       // number of control operator groups
#define NUM_CTL_GROUPS          16       // size of saved setup
#define MAX_SAVEDSETS           5        // number of saved setups

#define EEPROM_TIMER_BASE       0x00     // base address of timers
#define EEPROM_CTLOP_BASE       0x10     // base address of saved control operator groups
#define EEPROM_COURTESY_BASE    0x60     // base address of courtesy tones
#define EEPROM_CWID1_BASE       0xA0     // base address of CW ID 1.
#define EEPROM_CWID2_BASE       0xB0     // base address of CW ID 1.
#define CWID_LENGTH             15       // max length of CW ID.
#define EEPROM_PREFIX_BASE      0xC0     // base address of prefixes

#define COURTESY_TONE_LENGTH    8        // courtesy tones are 8 bytes long
#define COURTESY_TONE_CW_CHAR   99       // magic value for CW character
#define COURTESY_MAX_TONES      32       // maximum number of courtesy tones

// programmer-specific data
const char * dtmfdigits = "0123456789ABCD*#";

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

// controller-specific text, etc.

const LPSTR timerNames[] = {"Hang Timer Long",
                            "Hang Timer Short",
                            "ID Timer Transmitter 1",
                            "ID Timer Transmitter 2",
                            "DTMF Access Mode Timer",
                            "Timeout Timer Long",
                            "Timeout Timer Short",
                            "Fan Timer",
                            "Alarm Interval Timer",
                            "Transmitter 1 Courtesy Tone Front Porch",
                            "Transmitter 2 Courtesy Tone Front Porch",
                            "Transmitter 1 CW Pitch",
                            "Transmitter 1 CW Speed",
                            "Transmitter 2 CW Pitch",
                            "Transmitter 2 CW Speed"};

const LPSTR courtesyToneNames[] = {"Courtesy Tone 0",
                                   "Courtesy Tone 1",
                                   "Courtesy Tone 2",
                                   "Courtesy Tone 3",
                                   "Courtesy Tone 4",
                                   "Courtesy Tone 5",
                                   "Courtesy Tone 6",
                                   "Controller Unlocked Courtesy Tone"};

const LPSTR controlGroupNames[] = {"Group 0 - Receiver 1 Access Control",
                                   "Group 1 - Receiver 1 Configuration",
                                   "Group 2 - Receiver 2 Access Control",
                                   "Group 3 - Receiver 2 Configuration",
                                   "Group 4 - Transmitter 1 Control",
                                   "Group 5 - Transmitter 2 Control",
                                   "Group 6 - Miscellaneous Settings",
                                   "Group 7 - Digital Output Control",
                                   "Group 8 - Control Write Protects",
                                   "Group 9 - Control Operator Security Configuration"};

const LPSTR controlItemNames[] = { "Receiver 1 Enable",                   // 0.0
                                   "Receiver 1 CTCSS Required",           // 0.1
                                   "Receiver 1 Dual Squelch",             // 0.2
                                   "Receiver 1 DTMF access mode",         // 0.3
                                   "Receiver 1 encode tone Tx 1",         // 0.4
                                   "Receiver 1 encode tone Tx 2",         // 0.5
                                   "Receiver 1 into Transmitter 1",       // 0.6
                                   "Receiver 1 into Transmitter 2",       // 0.7
                                   
                                   "Key Up Delay",                        // 1.0
                                   "Time Out Timer Enable",               // 1.1
                                   "Timeout Timer Long Select",           // 1.2
                                   "Load setup on CTSEL1/2/3 low",        // 1.3
                                   "Audio Delay Present",                 // 1.4
                                   "Receiver 1 has priority",             // 1.5
                                   "Mute DTMF into Transmitter 1",        // 1.6
                                   "Mute DTMF into Transmitter 2",        // 1.7

                                   "Receiver 2 Enable",                   // 2.0
                                   "Receiver 2 CTCSS Required",           // 2.1
                                   "Receiver 2 Dual Squelch",             // 2.2
                                   "Receiver 2 DTMF access mode",         // 2.3
                                   "Receiver 2 encode tone Tx 1",         // 2.4
                                   "Receiver 2 encode tone Tx 2",         // 2.5
                                   "Receiver 2 into Transmitter 1",       // 2.6
                                   "Receiver 2 into Transmitter 2",       // 2.7
                                   
                                   "Key Up Delay",                        // 3.0
                                   "Time Out Timer Enable",               // 3.1
                                   "Timeout Timer Long Select",           // 3.2
                                   "Saved Setup # is Courtesy Tone #",    // 3.3
                                   "Audio Delay Present",                 // 3.4
                                   "Receiver 1 has priority",             // 3.5
                                   "Mute DTMF into Transmitter 1",        // 3.6
                                   "Mute DTMF into Transmitter 2",        // 3.7

                                   "Transmitter 1 Transmit Enable",       // 4.0
                                   "Transmitter 1 Hang Time Enable",      // 4.1
                                   "Hang Timer Long Select",              // 4.2
                                   "Transmitter 1 ID Enable",             // 4.3
                                   "Transmitter 1 ID 2 Select",           // 4.4
                                   "Transmitter 1 Duplex Select",         // 4.5
                                   "Transmitter 1 Rx 1 CT Enable",        // 4.6
                                   "Transmitter 1 Rx 2 CT Enable",        // 4.7
                                   
                                   "Transmitter 2 Transmit Enable",       // 5.0
                                   "Transmitter 2 Hang Time Enable",      // 5.1
                                   "Hang Timer Long Select",              // 5.2
                                   "Transmitter 2 ID Enable",             // 5.3
                                   "Transmitter 2 ID 2 Select",           // 5.4
                                   "Transmitter 2 Duplex Select",         // 5.5
                                   "Transmitter 2 Rx 1 CT Enable",        // 5.6
                                   "Transmitter 2 Rx 2 CT Enable",        // 5.7
                                   
                                   "Fan Control is Digital Output",       // 6.0
                                   "Fan Digital Output Control",          // 6.1
                                   "Fan Digital Output Pulse Mode",       // 6.2
                                   "Alarm Input Enable",                  // 6.3
                                   "Reserved",                            // 6.4
                                   "Reserved",                            // 6.5
                                   "Transmitter 1 Chicken Burst Enable",  // 6.6
                                   "Transmitter 2 Chicken Burst Enable",  // 6.7
                                   
                                   "Digital Output 1 Port Control",       // 7.0
                                   "Digital Output 2 Port Control",       // 7.1
                                   "Digital Output 3 Port Control",       // 7.2
                                   "Digital Output 4 Port Control",       // 7.3
                                   "Digital Output 1 Pulsed Mode",        // 7.4
                                   "Digital Output 2 Pulsed Mode",        // 7.5
                                   "Digital Output 3 Pulsed Mode",        // 7.6
                                   "Digital Output 4 Pulsed Mode",        // 7.7
                                   
                                   "Write Protect Control Groups",        // 8.0
                                   "Write Protect Prefixes",              // 8.1
                                   "Write Protect Timers",                // 8.2
                                   "Ignore DTMF from Receiver 1",         // 8.3
                                   "Ignore DTMF from Receiver 2",         // 8.4
                                   "Reserved",                            // 8.5
                                   "Write Protect CW and Courtesy Tones", // 8.6
                                   "NHRC Test Mode - Do Not Use",         // 8.7
                                   
                                   "Group 0 Access Enable",               // 9.0
                                   "Group 1 Access Enable",               // 9.1
                                   "Group 2 Access Enable",               // 9.2
                                   "Group 3 Access Enable",               // 9.3
                                   "Group 4 Access Enable",               // 9.4
                                   "Group 5 Access Enable",               // 9.5
                                   "Group 6 Access Enable",               // 9.6
                                   "Group 7 Access Enable"};              // 9.7


const unsigned char default_data[] = {	0x64,0x32,0x36,0x36,0x3C,0xB4,0x1E,0x0C,
										0x06,0x32,0x32,0x14,0x14,0x14,0x14,0x00,
										0x81,0xC6,0x41,0xC6,0x09,0x09,0x00,0x00,
										0x00,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,
										0x81,0xC6,0x41,0xC6,0x09,0x09,0x00,0x00,
										0x00,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,
										0xC1,0xC6,0x41,0xC6,0xEB,0xC9,0x00,0x00,
										0x00,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,
										0x41,0xC6,0x81,0xC6,0xEB,0xEB,0x00,0x00,
										0x00,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,
										0xC1,0xC6,0xC1,0xC6,0xEB,0xEB,0x00,0x00,
										0x00,0xFF,0x00,0x00,0x00,0x00,0x00,0x00,
										0x05,0x8C,0x05,0x8F,0x05,0x93,0x05,0x16,
										0x05,0x8C,0x05,0x8F,0x05,0x93,0x05,0x16,
										0x05,0x96,0x05,0x93,0x05,0x8F,0x05,0x0C,
										0x05,0x96,0x05,0x93,0x05,0x8F,0x05,0x0C,
										0x63,0x01,0x00,0x00,0x00,0x00,0x00,0x00,
										0x63,0x02,0x00,0x00,0x00,0x00,0x00,0x00,
										0x63,0x03,0x00,0x00,0x00,0x00,0x00,0x00,
										0x0A,0x9F,0x0A,0x93,0x0A,0x9F,0x0A,0x13,
										0x05,0x10,0x0A,0x15,0x00,0x3E,0x23,0xFF,
										0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x05,0x10,0x0A,0x15,0x00,0x3E,0x23,0xFF,
										0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x01,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x02,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x03,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x04,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x05,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x06,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
										0x00,0x07,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF };

#endif // !defined(AFX_PROGRAMMER_H__E5A490FC_DA70_43F5_AF1C_47987A01CE3C__INCLUDED_)
