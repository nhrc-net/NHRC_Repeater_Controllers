	;; NHRC-10 Advanced Repeater Controller.
	;; Copyright 1998, 1999, 2000, 2001, 2002, 2003, NHRC LLC,
	;; as an unpublished proprietary work.
	;; All rights reserved.
	;; No part of this document may be used or reproduced by any means,
	;; for any purpose, without the expressed written consent of NHRC LLC.

	;; x-12x 27 July 2003 eXperimental version

VER_INT equ	d'1'
VER_HI	equ	d'2'
VER_LO	equ	d'0'

	ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

	include "p16f877.inc"
	__FUSES _PWRTE_ON & _HS_OSC & _LVP_OFF & _WRT_ENABLE_OFF & _CP_ALL
	
	include "eeprom64.asm"
	include "vocab.asm"

;macro definitions for ROM paging.
	
PAGE0	macro			; select page 0
	bcf	PCLATH,3
	bcf	PCLATH,4
	endm

PAGE1	macro			; select page 1
	bsf	PCLATH,3
	bcf	PCLATH,4
	endm

PAGE2	macro			; select page 2
	bcf	PCLATH,3
	bsf	PCLATH,4
	endm

PAGE3	macro			; select page 3
	bsf	PCLATH,3
	bsf	PCLATH,4
	endm

TEN	equ	D'10'		; decade counter.

; ******************************************
; ** 25C320 EEPROM COMMGNDS AND ADDRESSES ** 
; ******************************************

EEWREN	equ	b'00000110'	; set write enable latch
EEWRDI	equ	b'00000100'	; reset write enable latch
EERDSR	equ	b'00000101'	; read status register
EEWRSR	equ	b'00000001'	; write status register
EEREAD	equ	b'00000011'	; read array
EEWRITE equ	b'00000010'	; write array

; **********************
; ** ISD4004 COMMANDS **
; **********************

	;; note that only the 5 most significant bits of the command
	;; is used, the 3 least significant bits are used as part of
	;; message address.  Command word is stored in isdCmdC,
	;; address bytes in isdCmdH and isdCmdL

ISDCUE	equ	4		; ISD C0 bit - message cueing
ISDIAB	equ	3		; ISD C1 bit - ignore address bits
ISDPUP	equ	2		; ISD C2 bit - power up
ISDPLAY equ	1		; ISD C3 bit - Play / \record\
ISDRUN	equ	0		; ISD C4 bit - Run

	;; control flags for ISD operation.
	;; stored in isdFlag
ISDRUNF equ	0		; ISD is running
ISDRECF equ	1		; ISD is recording
ISDIABF equ	2		; ISD has had IAB set.
ISDRACF equ	3		; ISD wants RAC attention from service routine
ISDD4RC equ	4		; deferred record operation.
ISDTEST equ	5		; playback test message after recording.
ISDWRDF equ	6		; ISD wants another word.  Feed it.
ISDRECR equ	7		; ISD waiting to start recording on next keyup.


	;; constants for various ISD timers
ISD_DLY equ	d'100'		; ISD start delay (ms).
ISDDLYC equ	d'200'		; have to stop in record before the last
				; 31.25 ms marker passes us by. so last row
				; will only get ISDLREC ms. (200 of 250)
	
; *************************
; ** IO Port Assignments **
; *************************

; PORT A
LED1	equ	0		; debug LED output on A.0  watchdog timeout
LED2	equ	1		; debug LED output on A.1  Alive Blinker
EXPSEL	equ	2		; expansion port select on A.2
PHRING	equ	3		; phone ring detect input on A.3
RX0COR	equ	4		; COR input on A.4
RX0PL	equ	5		; CTCSS input on A.5

; PORT B
; B.0 is ISD interrupt input
DTMFSEL equ	1		; DTMF select output on B.1
TONESEL equ	2		; DTMF/TONE gen select output on B.2
ISDSEL	equ	3		; ISD SPI SS output on B.3
DTMF0DV equ	4		; DTMF decoder 0 DV input on B.4
DTMF1DV equ	5		; DTMF decoder 1 DV input on B.5
DTMF2DV equ	6		; DTMF decoder 2 DV input on B.6
ISDRAC	equ	7		; ISD row address clock input on B.7

; PORT C
OUTSEL	equ	0		; digital output select output on C.0 (outPort)
EEPSEL	equ	1		; EEPROM SPI SS output on C.1
DTMF2SE equ	2		; DTMF decoder 2 select on C.2
; C.3 is SPI clock
; C.4 is SPI MISO (mpu input)
; C.5 is SPI MOSI (mpu output)
; C.6 is SCI TXD
; C.7 is SCI RXD
	
; PORT D
; port D is all data I/O for DTMF 0 & 1, DTMF/Tone generator, digital out latch
	 
; PORT E
RX1COR	equ	0		; link COR input on E.0
RX1PL	equ	1		; link CTCSS input on E.1
INIT	equ	2		; init button input on E.2

; *******************
; ** Control Flags **
; *******************
	
; outPort
TX0PTT	equ	0		; main transmitter PTT
TX1PTT	equ	1		; link transmitter PTT
FONECTL equ	2		; phone off-hook
FANCTL	equ	3		; fan control
RX0AUD	equ	4		; main receiver audio gate
RX1AUD	equ	5		; link receiver audio gate
FONEAUD equ	6		; phone patch audio gate
BEEPAUD equ	7		; beep/voice audio gate
		
;tFlags				; timer flags	     
TICK	equ	0		; TICK indicator
ONEMS	equ	1		; 1 ms tick flag
TENMS	equ	2		; 10 ms tick flag
HUNDMS	equ	3		; 100 ms tick flag
ONESEC	equ	4		; 1 second tick flag
TENSEC	equ	5		; 10 second flag...
; niy	equ	6		; NIY
CWBEEP	equ	7		; cw beep is on.
	
;flags
initID	equ	0		; need to ID now
needID	equ	1		; need to send ID
TXONFLG equ	2		; last TX state flag
CMD_NIB equ	3		; command interpreter nibble flag for copy
DEF_CT	equ	4		; deferred courtesy tone.
DEFFONE equ	5		; deferred fone call.
RBMUTE	equ	6		; remote base muted flag.
; niy	equ	7		; NIY

;mscFlag			; misc flags...
DT0ZERO equ	0		; dtmf-0 last received 0
DT2ZERO equ	1		; dtmf-2 last received 0
LITZDT0 equ	2		; LiTZ on DTMF-0
LITZDT2 equ	3		; LiTZ on DTMF-2
NNXIE	equ	4		; NNX initialization in progress
CIV_RDY equ	5		; CI-V command received for interpretation.
CTCSS0	equ	6		; last CTCSS on main receiver
CTCSS2	equ	7		; last CTCSS on link receiver

; txFlag
RX0OPEN equ	0		; main receiver repeating
RX1OPEN equ	1		; link receiver repeating
TXHANG	equ	2		; hang time
PATCHON equ	3		; autopatch is on
DTMFING equ	4		; DTMF generation in progress
TALKING equ	5		; ISD playing back
BEEPING equ	6		; beep tone active
CWPLAY	equ	7		; CW playing

; idRFlag -- id & tail message rotate control flag
IDR0	equ	0		; ID rotate bit 0
IDR1	equ	1		; ID rotate bit 1
TAILR0	equ	2		; tail message rotate bit 0
TAILR1	equ	3		; tail message rotate bit 1
TAILRM	equ	4		; tail message rotate bit 2 (mbx)
; NIY	equ	5		; NIY
; NIY	equ	6		; NIY
IDNOW	equ	7		; id in progress now.

; beepCtl -- beeper control flags...
B_ADR0	equ	0		; beep or CW addressing mode indicator
B_ADR1	equ	1		; beep or CW addressing mode indicator
				;   00 from EEPROM, saved messages.
				;   01 from lookup table, built in messages.
				;   10 from RAM, generated messages.
				;   11 CW single letter mode.
				; 
B_BEEP	equ	2		; beep sequence in progress
B_CW	equ	3		; CW transmission in progress
B_DTMF	equ	4		; beeping out DTMF (autospace 5 counts)
B_PAUSE equ	5		; DTMF intra-digit pause.
B_LAST	equ	6		; last segment of CT tones.
B_MAIN	equ	7		; enable main port audio switch

CTPAUSE equ	d'5'		; 50 msec pause before CT.
DTMFLEN equ	d'10'		; 100 msec. digit/space length.
DTMFPRE equ	d'150'		; 1500 msec. predial delay.
DTMFPOZ equ	d'90'		; 900 msec. # pause.

;; beepCtl preset masks
BEEP_CT equ	b'10000100'	; CT from EEPROM
BEEP_CX equ	b'10000101'	; CT from ROM table
;BEEP_DT equ	 b'00111110'	 ; DTMF from RAM
BEEP_DT equ	b'00110110'	; DTMF from RAM
BEEPDTA equ	b'10110110'	; DTMF from RAM, over air.
BEEPADT equ	b'00110100'	; DTMF from EEPROM
CW_ROM	equ	b'10001001'	; CW from ROM table
CW_EE	equ	b'10001000'	; CW from EEPROM
CW_LETR	equ	b'10001011'	; CW, one letter only, from EE.

MAGICCT	equ	d'99'		; magic CT length, next digit is CW character.

CWTBDLY equ	d'60'		; CW timebase delay for 20 WPM.

;; mbxFlag -- voice mailbox control flag
;; low order 6 bits are used to indicate message presence

;; mbxCtl -- mailbox control flag for state machine
;;; need to indicate recording header or what else?
;; low order 4 bits indicate last message played.
MBXRHDR equ	5		; ready to record mailbox header.
MBXRMBX equ	6		; ready to record mailbox.
MBXLPLA equ	7		; last mailbox op was a play.

;; nnxInit -- call restrictions init control flag
NNXIA0	equ	0		; NNX init address indicator bit 0.
NNXIA1	equ	1		; NNX init address indicator bit 1.
NNXIA2	equ	2		; NNX init address indicator bit 2.
NNXCB	equ	3		; control bit--enable or disable NNXs.
NNXBI0	equ	4		; NNX init area code bank index bit 0.
NNXBI1	equ	5		; NNX init area code bank index bit 1.
NNXBI2	equ	6		; NNX init area code bank index bit 2.
NNXBI3	equ	7		; NNX init area code bank index bit 3.
	
;; COR debounce time
COR1DEB equ	3		; 30 ms.  COR off to on debounce time
COR0DEB equ	2		; 20 ms.  COR on to off debounce time
DLY1DEB equ	d'25'		; 250 ms. COR off->on debounce time, with DAD.
DLY0DEB equ	d'20'		; 200 ms. COR on->off debounce time, with DAD.
CHNKDEB equ	d'75'		; 750 ms.
IDSOON	equ	D'6'		; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ	D'20'		; DTMF muting timer = 2.0 sec.
DTMFDLY equ	d'50'		; DTMF activity timer = 5.0 sec.
LITZTIM equ	d'20'		; 5.0-3.0=2.0 time left on DTMF timer for LITZ
UNLKDLY equ	d'120'		; unlocked mode timer.
	
; dtRFlag -- dtmf sequence received indicator
DT0RDY	equ	0		; some sequence received on DTMF-0
DT1RDY	equ	1		; some sequence received on DTMF-1
DT2RDY	equ	2		; some sequence received on DTMF-2
DTUL	equ	3		; command received from unlocked port.
DTSEVAL equ	4		; dtmf command evaluation in progress.
DT0UNLK equ	5		; unlocked indicator
DT1UNLK equ	6		; unlocked indicator
DT2UNLK equ	7		; unlocked indicator
		;; 
;dtEFlag -- DTMF command evaluator control flag.
	;; low order 5 bits indicate next prefix number/user command to scan
DT0CMD	equ	5		; received this command from dtmf0
DT1CMD	equ	6		; received this command from dtmf1
DT2CMD	equ	7		; received this command from dtmf2

; tuneFlg -- CI-V tune mode control flag
SUPP_OK equ	0		; suppress OK message (for fine tune.
; niy	equ	1		; NIY
; niy	equ	2		; NIY
; niy	equ	3		; NIY
DTTUNE	equ	4		; tune mode command.
DT0TUNE equ	5		; dtmf-0 CI-V fine tune mode.
DT1TUNE equ	6		; dtmf-1 CI-V fine tune mode.
DT2TUNE equ	7		; dtmf-2 CI-V fine tune mode.
	
; group6 -- digital output control flags.
D1PUL	equ	0		; digital output 1 is pulsed
D2PUL	equ	1		; digital output 2 is pulsed
D3PUL	equ	2		; digital output 3 is pulsed
D4PUL	equ	3		; digital output 4 is pulsed
D58PUL	equ	4		; digital outputs 5-8 are pulsed
DONEOF	equ	5		; digital outputs are in one-of mode.
; NIY	eqy	6		; NIY
; NIY	eqy	7		; NIY

PULS_TM equ	d'50'		; 50 x 10 ms = 500 ms.	pulse duration time.

; CI-V commands.
; CI-V bus addresses
CIV_ME	equ	h'E0'		; my CI-V address.
CIV_PC	equ	h'E1'		; Programming PC's CI-V address.
CIV_706 equ	h'48'		; IC-706's CI-V address.

; responses (radio to controller)
CIV_OK	equ	h'FB'		; fine business.
CIV_BAD equ	h'FA'		; facked ap command.
CIV_EOM	equ	h'FD'		; CI-V end of message.
CIV_PRE	equ	h'FE'		; CI-V preamble byte (sent twice)
	
; commands and command responses
CIV_RDF equ	h'03'		; read out frequency.
CIV_RDM equ	h'04'		; read out mode & PB width.
CIV_PVT	equ	h'77'		; NHRC private CI-V command.
CIV_PRD	equ	h'00'		; EEPROM Read subcommand.
CIV_WRT	equ	h'01'		; EEPROM Write subcommand.

; commands (controller to radio)
CIV_FRQ equ	h'05'		; write frequency to radio.
CIV_MOD equ	h'06'		; write mode to radio.
CIV_VFO equ	h'07'		; select VFO
				;    00 VFO A
				;    01 VFO B
				;    A0 copy this VFO to other VFO
				;    B0 swap this VFO with other VFO
CIV_MEM equ	h'08'		; memory command.
CIV_SPL equ	h'0F'		; select split/duplex operation.
				;    00 split off
				;    01 split on
				;    10 duplex off
				;    11 - duplex
				;    12 + duplex

CIVSCTM equ	d'25'		; CIV scan time 25 x 10 ms = 250 ms
	
; Ring Detect values.
RNG_DUR equ	d'250'		; 2500 ms (2 sec) ring duration timer.
RNG_TMO equ	d'80'		; 8.0 seconds ring timeout.
RNG_TON equ	h'14'		; address of ring tone in lookup table.
RNG_PLS equ	d'20'		; min. number of ring low polls for valid ring.
	
; receiver states
RXSOFF	equ	0
RXSON	equ	1
RXSTMO	equ	2

; cTone Courtesy tone selections
CTNONE	equ	h'ff'		; no courtesy tone.
CTNORM	equ	0		; normal courtesy tone
CTALERT equ	1		; alert mode alerted courtesy tone
CTRBTX	equ	2		; courtesy tone when link tx enabled
CTRRBRX equ	3		; courtesy tone link receiver link tx off
CTRRBTX equ	4		; courtesy tone link receiver link tx on
CTSPAR1 equ	5		; unused courtesy tone
CTTUNE	equ	6		; tune mode courtesy tone
CTUNLOK equ	7		; unlocked courtesy tone

; CW Message Addressing Scheme:
; These symbols represent the value of the CW characters in the ROM table.
;     1 - CW timeout message, "to"
;     2 - CW confirm message, "ok"
;     3 - CW bad message, "ng"
;     3 - CW link timeout "rb to"

CW_OK	equ	h'00'		; CW OK
CW_NG	equ	h'03'		; CW NG
CW_TO	equ	h'07'		; CW timeout

PATCBIP equ	h'10'		; patch expiry bip.
SCANBIP equ	h'0c'		; scan mode 100 KHz beep.

;
; CW sender constants
;

CWDIT	equ	1		; dit length in 100 ms
CWDAH	equ	CWDIT * 3	; dah 
CWIESP	equ	CWDIT		; inter-element space
CWILSP	equ	CWDAH		; inter-letter space
CWIWSP	equ	CWDIT * 7	; inter-word space

;
; Patch Area code config bits
;
ACENAB		equ	0	; this area code is enabled.
AC1OK		equ	1	; a leading one is allowed.
AC1REQ		equ	2	; a leading one is required.
ACNONE		equ	3	; the area code itself is not required.
				; used for area code #3 only.
ACPFX		equ	4	; use prefix for dialing.
T0PRE	equ	D'7'		; timer 0 preset for overflow in 250 counts.

; ***************
; ** VARIABLES **
; ***************
	cblock	h'20'		; 1st block of RAM at 20h-7fh (96 bytes here)
	;; interrupt pseudo-stack to save context during interrupt processing.
	s_copy			; 20  saved STATUS
	p_copy			; 21  saved PCLATH
	f_copy			; 22  saved FSR
	;; interrupt on port B change registers
	b_now			; 23  port b this read
	b_last			; 24  port b last read
	i_temp			; 25  temp for interrupt handler
	;; internal timing generation
	tFlags			; 26  Timer Flags
	oneMsC			; 27  one millisecond counter
	tenMsC			; 28  ten milliseconds counter
	hundMsC			; 29  hundred milliseconds counter
	thouMsC			; 2a  thousand milliseconds counter (1 sec)

	temp			; 2b  working storage. don't use in int handler.
	temp2			; 2c  more working storage
	temp3			; 2d  still more temporary storage
	temp4			; 2e  yet still more temporary storage
	temp5			; 2f  temporary storage...
	temp6			; 30  temporary storage...
	cmdSize			; 31  # digits received for current command
	;; operating flags
	flags			; 32  operating Flags
	mscFlag			; 33  misc. flags.
	txFlag			; 34  Transmitter control flag
	rxFlag			; 35  Receiver COS valid flags
	idRFlag			; 36  id & tail message rotate control flag
	;; beep generator control 
	beepTmr			; 37  timer for generating various beeps
	beepAdrH		; 38  address for various beepings, hi byte.
	beepAdrL		; 39  address for various beepings, low byte.
	beepCtl			; 3a  beeping control flag
	;; debounce timers
	rx0Dbc			; 3b  main receiver debounce timer
	rx1Dbc			; 3c  link receiver debounce timer
	;; receiver states
	rx0Stat			; main receiver state
	rx1Stat			; link receiver state
	;; timers
	rx0TOut			; main receiver timeout timer, in seconds
	rx1TOut			; link receiver timeout timer, in seconds
	idTmr			; id timer, in 10 seconds
	hangTmr			; hang timer, in tenths.
	muteTmr			; DTMF muting timer, in tenths.
	lMutTmr			; link muting timer, in tenths.
	ptchTmr			; autopatch timer
	dtATmr			; dtmf access timer
	fanTmr			; fan timer
	tailCtr			; tail message counter.
	unlkTmr			; unlocked mode timer.
	pulsTmr			; pulse timer.
	;; timer presets
	hangDly			; hang timer preset, used enough to keep around
	;; message number
	msgNum			; message number to play
	;; CW generator data
	cwTmr			; CW element timer
	cwByte			; CW current byte (bitmap)
	cwTbTmr			; CW timebase timer
	
	rbTmr			; remote base inactivity timer.
	
	outPort			; output port data buffer
	cTone			; courtesy tone to play

	eeAddrL			; EEPROM address (low byte) to read/write
	eeAddrH			; EEPROM address (low byte) to read/write
	eeCount			; number of bytes to read/write from EEPROM
	;; control operator control flag groups
	group0			; group 0 flags
	group1			; group 1 flags
	group2			; group 2 flags
	group3			; group 3 flags
	group4			; group 4 flags
	group5			; group 5 flags
	group6			; group 6 flags
	group7			; group 7 flags
	group8			; group 8 flags
	group9			; group 9 flags
	mbxFlag			; mailbox flags. must be after last Cntl-op.
	mbxCtl			; mailbox control flags.
	;; ISD control variables
	isdFlag			; isd control flag
	isdRACc			; isd RAC counter.
	isdCmdH			; isd command	high  byte.
	isdCmdL			; isd command	low   byte.
	isdCmdC			; isd command command byte.
	isdDly			; isd command delay timer...
	isdMsg			; isd message number...
	isdRMsg			; isd RECORD message number...
	;; call restriction initialization control flag
	nnxInit			; call restriction initilization control flag.
	ringTmr			; ring timer.
	ringDur			; ring duration timer.
	ringCtr			; ring count.
	ringPul			; ring pulses counter.
	tuneFlg			; CI-V tune mode control flag.
	;; last var at 0x6f there are 0 left in this block...
	endc			; this block ends at 6f

	cblock	h'70'		; from 70 to 7f is common to all banks!
	w_copy			; 70  saved W register for interrupt handler
	dt0Ptr			; 71  DTMF-0 buffer pointer
	dt0Tmr			; 72  DTMF-0 buffer timer
	dt1Ptr			; 73  DTMF-1 buffer pointer
	dt1Tmr			; 74  DTMF-1 buffer timer
	dt2Ptr			; 75  DTMF-2 buffer pointer
	dt2Tmr			; 76  DTMF-2 buffer timer
	scratch			; 77  spare. unused.
	;; isdHead+1 is where words are added.
	;; isdTail+1 is where words are played.
	;; the tail follows the head.
	isdHead			; 78  ISD transmit buffer head pointer.
	isdTail			; 79  ISD transmit buffer tail pointer.
	dtRFlag			; 7a  DTMF receive flag...
	dtEFlag			; 7b  DTMF command interpreter control flag
	;; ci?Head+1 is where chars are added.
	;; ci?Tail+1 is where chars are consumed.
	;; the tail follows the head.
	ciTHead			; 7c  CI-V transmitter buffer head pointer.
	ciTTail			; 7d  CI-V transmitter buffer tail pointer.
	ciRHead			; 7e  CI-V receiver buffer head pointer.
	eebPtr			; 7f  eebuf write pointer.
	endc			; 1st RAM block ends at 7f

	cblock	h'a0'		; 2nd block of RAM at a0h-efh (80 bytes here)
	civfrq1			; a0  CI-V frequency cache.  byte 1 of 5.
	civfrq2			; a1  CI-V frequency cache.  byte 2 of 5.
	civfrq3			; a2  CI-V frequency cache.  byte 3 of 5.
	civfrq4			; a3  CI-V frequency cache.  byte 4 of 5.
	civfrq5			; a4  CI-V frequency cache.  byte 5 of 5.
	scanTmr			; a5  CI-V scan timer.
	scanMod			; a6  CI-V scan mode.
	;;  room from a7-af.
	endc

	;;
	;; 1.2x moved CI-V buffers to b0-cf and d0-ef and made 32 bytes long.
	;; this will allow transfer of 16 bytes of EEPROM data in a
	;; single CI-V message.
	;;
	
	cblock	h'b0'		; from b0 to ef is use for serial buffers.
	itbuf00			; b0 CI-V transmit buffer (32 bytes)
	itbuf01			; b1 CI-V transmit buffer
	itbuf02			; b2 CI-V transmit buffer
	itbuf03			; b3 CI-V transmit buffer
	itbuf04			; b4 CI-V transmit buffer
	itbuf05			; b5 CI-V transmit buffer
	itbuf06			; b6 CI-V transmit buffer
	itbuf07			; b7 CI-V transmit buffer
	itbuf08			; b8 CI-V transmit buffer
	itbuf09			; b9 CI-V transmit buffer
	itbuf0a			; ba CI-V transmit buffer
	itbuf0b			; bb CI-V transmit buffer
	itbuf0c			; bc CI-V transmit buffer
	itbuf0d			; bd CI-V transmit buffer
	itbuf0e			; be CI-V transmit buffer
	itbuf0f			; bf CI-V transmit buffer
	itbuf10			; c0 CI-V transmit buffer
	itbuf11			; c1 CI-V transmit buffer
	itbuf12			; c2 CI-V transmit buffer
	itbuf13			; c3 CI-V transmit buffer
	itbuf14			; c4 CI-V transmit buffer
	itbuf15			; c5 CI-V transmit buffer
	itbuf16			; c6 CI-V transmit buffer
	itbuf17			; c7 CI-V transmit buffer
	itbuf18			; c8 CI-V transmit buffer
	itbuf19			; c9 CI-V transmit buffer
	itbuf1a			; ca CI-V transmit buffer
	itbuf1b			; cb CI-V transmit buffer
	itbuf1c			; cc CI-V transmit buffer
	itbuf1d			; cd CI-V transmit buffer
	itbuf1e			; ce CI-V transmit buffer
	itbuf1f			; cf CI-V transmit buffer

	irbuf00			; d0 CI-V receive buffer (32 bytes)
	irbuf01			; d1 CI-V receive buffer
	irbuf02			; d2 CI-V receive buffer
	irbuf03			; d3 CI-V receive buffer
	irbuf04			; d4 CI-V receive buffer
	irbuf05			; d5 CI-V receive buffer
	irbuf06			; d6 CI-V receive buffer
	irbuf07			; d7 CI-V receive buffer
	irbuf08			; d8 CI-V receive buffer
	irbuf09			; d9 CI-V receive buffer
	irbuf0a			; da CI-V receive buffer
	irbuf0b			; db CI-V receive buffer
	irbuf0c			; dc CI-V receive buffer
	irbuf0d			; dd CI-V receive buffer
	irbuf0e			; de CI-V receive buffer
	irbuf0f			; df CI-V receive buffer
	irbuf10			; e0 CI-V receive buffer
	irbuf11			; e1 CI-V receive buffer
	irbuf12			; e2 CI-V receive buffer
	irbuf13			; e3 CI-V receive buffer
	irbuf14			; e4 CI-V receive buffer
	irbuf15			; e5 CI-V receive buffer
	irbuf16			; e6 CI-V receive buffer
	irbuf17			; e7 CI-V receive buffer
	irbuf18			; e8 CI-V receive buffer
	irbuf19			; e9 CI-V receive buffer
	irbuf1a			; ea CI-V receive buffer
	irbuf1b			; eb CI-V receive buffer
	irbuf1c			; ec CI-V receive buffer
	irbuf1d			; ed CI-V receive buffer
	irbuf1e			; ee CI-V receive buffer
	irbuf1f			; ef CI-V receive buffer
	endc			; end block c0-ef
	
	cblock	h'f0'		; this is really common with 70-7f
	rsvdf0			; f0  reserve these 16 bytes
	rsvdf1			; f1  reserve these 16 bytes
	rsvdf2			; f2  reserve these 16 bytes
	rsvdf3			; f3  reserve these 16 bytes
	rsvdf4			; f4  reserve these 16 bytes
	rsvdf5			; f5  reserve these 16 bytes
	rsvdf6			; f6  reserve these 16 bytes
	rsvdf7			; f7  reserve these 16 bytes
	rsvdf8			; f8  reserve these 16 bytes
	rsvdf9			; f9  reserve these 16 bytes
	rsvdfa			; fa  reserve these 16 bytes
	rsvdfb			; fb  reserve these 16 bytes
	rsvdfc			; fc  reserve these 16 bytes
	rsvdfd			; fd  reserve these 16 bytes
	rsvdfe			; fe  reserve these 16 bytes
	rsvdff			; ff  reserve these 16 bytes
	endc			; end block f0-ff

	;; 16c77 ram blocks continue...
	cblock	h'110'		; 16 bytes at 110h-11fh
	dt0buf0			; DTMF-0 receiver buffer (16 bytes) @ 120
	dt0buf1
	dt0buf2
	dt0buf3
	dt0buf4
	dt0buf5
	dt0buf6
	dt0buf7
	dt0buf8
	dt0buf9
	dt0bufa
	dt0bufb
	dt0bufc
	dt0bufd
	dt0bufe
	dt0buff
	endc
	
	cblock	h'120'		; 80 bytes 120h-16fh
	dt1buf0			; DTMF-1 receiver buffer (16 bytes) @ 120
	dt1buf1
	dt1buf2
	dt1buf3
	dt1buf4
	dt1buf5
	dt1buf6
	dt1buf7
	dt1buf8
	dt1buf9
	dt1bufa
	dt1bufb
	dt1bufc
	dt1bufd
	dt1bufe
	dt1buff

	dt2buf0			; DTMF-2 receiver buffer (16 bytes) @ 130
	dt2buf1
	dt2buf2
	dt2buf3
	dt2buf4
	dt2buf5
	dt2buf6
	dt2buf7
	dt2buf8
	dt2buf9
	dt2bufa
	dt2bufb
	dt2bufc
	dt2bufd
	dt2bufe
	dt2buff

	dtXbuf0			; dtmf TRANSMITTER buffer (32 bytes) @ 140
	dtXbuf1
	dtXbuf2
	dtXbuf3
	dtXbuf4
	dtXbuf5
	dtXbuf6
	dtXbuf7
	dtXbuf8
	dtXbuf9
	dtXbufa
	dtXbufb
	dtXbufc
	dtXbufd
	dtXbufe
	dtXbu10
	dtXbu11
	dtXbu12
	dtXbu13
	dtXbu14
	dtXbu15
	dtXbu16
	dtXbu17
	dtXbu18
	dtXbu19
	dtXbu1a
	dtXbu1b
	dtXbu1c
	dtXbu1d
	dtXbu1e
	dtXbu1f

	isdXB0			; ISD talker word buffer (16 bytes) @ 160
	isdXB1
	isdXB2
	isdXB3
	isdXB4
	isdXB5
	isdXB6
	isdXB7
	isdXB8
	isdXB9
	isdXBa
	isdXBb
	isdXBc
	isdXBd
	isdXBe
	isdXBf
	endc
	
	cblock	h'170'		; this is common with 70-7f
	rsvd170			; reserve these 16 bytes
	rsvd171			; reserve these 16 bytes
	rsvd172			; reserve these 16 bytes
	rsvd173			; reserve these 16 bytes
	rsvd174			; reserve these 16 bytes
	rsvd175			; reserve these 16 bytes
	rsvd176			; reserve these 16 bytes
	rsvd177			; reserve these 16 bytes
	rsvd178			; reserve these 16 bytes
	rsvd179			; reserve these 16 bytes
	rsvd17a			; reserve these 16 bytes
	rsvd17b			; reserve these 16 bytes
	rsvd17c			; reserve these 16 bytes
	rsvd17d			; reserve these 16 bytes
	rsvd17e			; reserve these 16 bytes
	rsvd17f			; reserve these 16 bytes
	endc			; 3nd RAM block ends at 17f
	
	;; cblock	h'190'	; 16 bytes at 190h-19fh
	;; endc
	cblock	h'1a0'		; 80 bytes 1a0h-1efh
	cmdbf00			; command buffer  @1a0
	cmdbf01			; command buffer
	cmdbf02			; command buffer
	cmdbf03			; command buffer
	cmdbf04			; command buffer
	cmdbf05			; command buffer
	cmdbf06			; command buffer
	cmdbf07			; command buffer
	cmdbf08			; command buffer
	cmdbf09			; command buffer
	cmdbf0a			; command buffer
	cmdbf0b			; command buffer
	cmdbf0c			; command buffer
	cmdbf0d			; command buffer
	cmdbf0e			; command buffer
	cmdbf0f			; command buffer  @1af (16 bytes)
	cmdbf10			; command buffer  @1b0
	cmdbf11			; command buffer
	cmdbf12			; command buffer
	cmdbf13			; command buffer
	cmdbf14			; command buffer
	cmdbf15			; command buffer
	cmdbf16			; command buffer
	cmdbf17			; command buffer
	cmdbf18			; command buffer
	cmdbf19			; command buffer
	cmdbf1a			; command buffer
	cmdbf1b			; command buffer
	cmdbf1c			; command buffer
	cmdbf1d			; command buffer
	cmdbf1e			; command buffer
	cmdbf1f			; command buffer @1bf (32 bytes)

	eebuf00			; eeprom buffer	 @1c0 (16 bytes)
	eebuf01			; eeprom buffer
	eebuf02			; eeprom buffer
	eebuf03			; eeprom buffer
	eebuf04			; eeprom buffer
	eebuf05			; eeprom buffer
	eebuf06			; eeprom buffer
	eebuf07			; eeprom buffer
	eebuf08			; eeprom buffer
	eebuf09			; eeprom buffer
	eebuf0a			; eeprom buffer
	eebuf0b			; eeprom buffer
	eebuf0c			; eeprom buffer
	eebuf0d			; eeprom buffer
	eebuf0e			; eeprom buffer
	eebuf0f			; eeprom buffer	 @1cf
	;; room from 1d0 to 1ef
	endc

	cblock	h'1f0'		; this is common with 70-7f
	rsvd1f0			; reserve these 16 bytes
	rsvd1f1			; reserve these 16 bytes
	rsvd1f2			; reserve these 16 bytes
	rsvd1f3			; reserve these 16 bytes
	rsvd1f4			; reserve these 16 bytes
	rsvd1f5			; reserve these 16 bytes
	rsvd1f6			; reserve these 16 bytes
	rsvd1f7			; reserve these 16 bytes
	rsvd1f8			; reserve these 16 bytes
	rsvd1f9			; reserve these 16 bytes
	rsvd1fa			; reserve these 16 bytes
	rsvd1fb			; reserve these 16 bytes
	rsvd1fc			; reserve these 16 bytes
	rsvd1fd			; reserve these 16 bytes
	rsvd1fe			; reserve these 16 bytes
	rsvd1ff			; reserve these 16 bytes
	endc			; 3nd RAM block ends at 1ff
	
; ********************
; ** STARTUP VECTOR **
; ********************
	org	0		; startup vector
	clrf	PCLATH		; stay in bank 0
	goto	Start

; ***********************
; ** INTERRUPT HANDLER **
; ***********************
IntHndlr
	org	4		; interrupt vector
	; preserve registers...
	movwf	w_copy		; save w register
	swapf	STATUS,w	; get STATUS
	clrf	STATUS		; force bank 0
	movwf	s_copy		; save STATUS
	movf	PCLATH,w	; get PCLATH
	movwf	p_copy		; save PCLATH
	clrf	PCLATH		; force page 0
	bsf	STATUS,IRP	; select RAM bank 1
	movf	FSR,w		; get FSR
	movwf	f_copy		; save FSR
	
	btfsc	INTCON,T0IF	; is it a timer interrupt?
	goto	TimrInt		; yes...
	btfsc	INTCON,RBIF	; is it a DTMF or ISDRAC interrupt?
	goto	RBInt		; yes...
	btfsc	INTCON,INTF	; is it an ISD general interrupt?
	goto	ISDInt		; yes
	;; not any of the interrupts indicated in INTCON...
	;; look at PIR1 interrupts...
	btfsc	PIR1,RCIF	; is it a USART Receive interrupt?
	goto	URInt		; yes.
	btfsc	PIR1,TXIF	; is it a USART transmit interrupt?
	goto	UTInt		; yes.
	goto	IntExit		; no...

ISDInt				; ISD 4004 interrupt handler
	;; can get an interrupt when recording if end of memory is reached.
	;; interrupt during playback for end-of-memory or end-of-message.
	;; must send command to ISD to clear IRQ.
	;; in any case, the first thing to do is to stop the ISD.
	bcf	INTCON,INTF	; clear interrupt request
	movlw	b'00000010'	; mask: clear all but ISDPLAY.
	andwf	isdCmdC,f	; clear bits.
	movlw	b'00001100'	; mask:	 set ISDIAB, ISDPUP.
	iorwf	isdCmdC,f	; set bits.
	movf	isdCmdC,w	; get the cmd  byte of the command.
	bcf	PORTB,ISDSEL	; select the ISD
	PAGE3			; select code page 3.
	call	SendSPI		; send & receive from the SPI
	PAGE0			; select code page 0.
	bsf	PORTB,ISDSEL	; deselect the ISD
	;; w now has the ISD status byte; but who cares?
	bcf	isdFlag,ISDRUNF ; clear ISD RUN indicator.
	btfss	isdFlag,ISDRECF ; was it recording?
	bsf	isdFlag,ISDWRDF ; nope, set IRQ attention bit.
	bcf	isdFlag,ISDRECF ; clear ISD RECORD indicator.
	bcf	isdFlag,ISDRACF ; clear RAC attention flag. don't need that now.
	clrf	isdDly		; clear ISD delay timer. don't need that now.
	clrf	isdRACc		; clear RAC counter.  don't need that 
	goto	IntExit

RBInt
	movf	PORTB,w		; read port b
	movwf	b_now		; save port b (only read once)
	xorwf	b_last,f	; b_last now is difference indicator
	btfss	b_last,DTMF0DV	; action on DTMF-0
	goto	CkDT1		; nope..
	btfss	rxFlag,RX0OPEN	; is receiver 1 marked active?
	goto	CkDT1		; no. ignore DTMF.
	btfss	b_now,DTMF0DV	; is DV high?
	goto	CkDT0L		; nope...
	
RdDT0
	btfsc	group1,3	; is muting enabled?
	bcf	outPort,RX0AUD	; mute receiver 0
	btfsc	group1,4	; drop link to mute enabled?
	bcf	outPort,TX1PTT	; turn off link PTT.
	btfsc	group6,6	; drop main TX to mute enabled?
	bcf	outPort,TX0PTT	; turn off main PTT.
	movlw	MUTEDLY		; get mute timer delay
	movwf	muteTmr		; preset mute timer
RdDT0m
	movlw	DTMFDLY		; get DTMF activity timer preset.
	movwf	dt0Tmr		; set dtmf command timer
	movlw	B'11111111'	; all inputs.
	bsf	STATUS,RP0	; select bank 1.
	movwf	TRISD		; set port D data direction.
	bcf	STATUS,RP0	; select bank 0.
	
	movf	dt0Ptr,w	; get index
	movwf	FSR		; put it in FSR
	bcf	STATUS,C	; clear carry (just in case)
	rrf	FSR,f		; hey! divide by 2.
	movlw	LOW dt0buf0	; get address of buffer
	addwf	FSR,f		; add to index.
	
	bsf	PORTB,DTMFSEL	; enable DTMF outputs.
	movlw	b'00001111'	; mask bits.
	andwf	PORTD,w		; get masked bits of tone into W.
	bcf	PORTB,DTMFSEL	; disable DTMF outputs.
	PAGE3			; select code page 3.
	call	MapDTMF		; remap tone into keystroke value..
	PAGE0			; select code page 0.
	iorlw	h'0'		; OR with zero to set status bits.
	bcf	mscFlag,DT0ZERO ; clear last zero received.
	btfsc	STATUS,Z	; was a zero the last received digit?
	bsf	mscFlag,DT0ZERO ; yes...
	
	btfsc	dt0Ptr,0	; is this an odd address?
	goto	DT0Odd		; yes;
	clrf	INDF		; zero both nibbles.
	movwf	INDF		; save tone in indirect register.
	swapf	INDF,f		; move the tone to the high nibble
	goto	DT0Done		; done here
DT0Odd
	iorwf	INDF,F		; save tone in low nibble
DT0Done 
	incf	dt0Ptr,f	; increment index
	movlw	h'1f'		; mask
	andwf	dt0Ptr,f	; don't let index grow past 1f (31)

	bsf	STATUS,RP0	; select page 1
	clrf	TRISD		; set port D all outputs.
	bcf	STATUS,RP0	; select bank 0.
	goto	CkDT1		; go look at DTMF-1

CkDT0L				; check for end of LITZ...
	btfss	mscFlag,DT0ZERO ; was zero the last received digit?
	goto	CkDT1		; no.
	movf	dt0Tmr,w	; get dtmf command timer
	btfsc	STATUS,Z	; is it already zero?
	goto	CkDT0LZ		; yes.
	sublw	LITZTIM		; subtract from litz time.
	btfss	STATUS,C	; is result positive?
	goto	CkDT1		; nope.

CkDT0LZ				; check for LITZ digits.
	bsf	mscFlag,LITZDT0 ; set LITZ on main receiver flag.
	clrf	dt0Ptr		; clear this, throw away received LITZ tone.
	clrf	dt0Tmr		; clear this, don't process tones normally.
		
CkDT1
	btfss	b_last,DTMF1DV	; action on DTMF-1
	goto	CkDT2		; nope..
	btfss	outPort,FONECTL ; is phone off-hook?
	goto	CkDT2		; nope.	 ignore tones from this source.
	btfss	b_now,DTMF1DV	; is DV high?
	goto	CkDT1L		; nope...

RdDT1
	btfsc	b_now,DTMF0DV	; is DV high on decoder 0?
	goto	CkDT2		; yes.	Ignore this digit.
	bcf	outPort,FONEAUD ; mute telephone audio
	;movlw	 MUTEDLY		; get mute timer delay
	;movwf	 muteTmr		; preset mute timer
	btfsc	txFlag,DTMFING	; is DTMF being sent right now?
	goto	CkDT2		; yes.	ignore digits received.
	movlw	DTMFDLY		; get DTMF activity timer preset
	movwf	dt1Tmr		; set dtmf command timer
	movlw	B'11111111'	; all inputs.
	bsf	STATUS,RP0	; select bank 1.
	movwf	TRISD		; set port D data direction.
	bcf	STATUS,RP0	; select bank 0.
	
	movf	dt1Ptr,w	; get index
	movwf	FSR		; put it in FSR
	bcf	STATUS,C	; clear carry (just in case)
	rrf	FSR,f		; hey! divide by 2.
	movlw	LOW dt1buf0	; get address of buffer
	addwf	FSR,f		; add to index.
	
	bsf	PORTB,DTMFSEL	; enable DTMF outputs.
	swapf	PORTD,w		; get decoder nibble & swap to low nibble
	andlw	b'00001111'	; mask bits.
	bcf	PORTB,DTMFSEL	; disable DTMF outputs.
	PAGE3			; select code page 3.
	call	MapDTMF		; remap tone into keystroke value..
	PAGE0			; select code page 0.
	btfsc	dt1Ptr,0	; is this an odd address?
	goto	DT1Odd		; yes;
	clrf	INDF		; zero both nibbles.
	movwf	INDF		; save tone in indirect register.
	swapf	INDF,f		; move the tone to the high nibble
	goto	DT1Done		; done here
DT1Odd
	iorwf	INDF,F		; save tone in low nibble
DT1Done 
	incf	dt1Ptr,f	; increment index
	movlw	h'1f'		; mask
	andwf	dt1Ptr,f	; don't let index grow past 1f (31)

	bsf	STATUS,RP0	; select page 1
	clrf	TRISD		; set port D all outputs.
	bcf	STATUS,RP0	; select bank 0.
	goto	CkDT2		; done here.

CkDT1L				; end of digit.
	btfsc	txFlag,PATCHON	; is patch on?
	bsf	outPort,FONEAUD ; yes, unmute telephone audio
	
CkDT2
	btfss	b_last,DTMF2DV	; action on DTMF-2
	goto	CkISDR
	btfss	b_now,DTMF2DV	; is DV high?
	goto	CkDT2L		; nope.	 Check for LiTZ.

RdDT2
	btfss	group1,7	; is control DTMF receiver set for link port?
	goto	RdDT2m		; no, it is the control receiver. dont mute.

	btfss	rxFlag,RX1OPEN	; is receiver 1 marked active?
	goto	CkISDR		; no. ignore DTMF.
	
	btfsc	group1,3	; is muting enabled?
	bcf	outPort,RX1AUD	; mute receiver 0
	btfsc	group1,4	; drop link to mute enabled?
	bcf	outPort,TX1PTT	; turn off link PTT.
	btfsc	group6,6	; drop main TX to mute enabled?
	bcf	outPort,TX0PTT	; turn off main PTT.
	movlw	MUTEDLY		; get mute timer delay
	movwf	muteTmr		; preset mute timer
RdDT2m
	btfsc	beepCtl,B_DTMF	; is controller SENDING DTMF?
	goto	CkISDR		; yes, do not receive these digits.
	movlw	DTMFDLY		; get DTMF activity timer preset
	movwf	dt2Tmr		; set dtmf command timer
	movlw	B'11111111'	; all inputs.
	bsf	STATUS,RP0	; select bank 1.
	movwf	TRISD		; set port D data direction.
	bcf	STATUS,RP0	; select bank 0.
	
	movf	dt2Ptr,w	; get index
	movwf	FSR		; put it in FSR
	bcf	STATUS,C	; clear carry (just in case)
	rrf	FSR,f		; hey! divide by 2.
	movlw	LOW dt2buf0	; get address of buffer
	addwf	FSR,f		; add to index.

	bsf	PORTC,DTMF2SE	; enable DTMF outputs.
	movlw	b'00001111'	; mask bits.
	andwf	PORTD,w		; get masked bits of tone into W.
	bcf	PORTC,DTMF2SE	; disable DTMF outputs.
	PAGE3			; select code page 3.
	call	MapDTMF		; remap tone into keystroke value..
	PAGE0			; select code page 0.
	iorlw	h'0'		; OR with zero to set status bits.
	bcf	mscFlag,DT2ZERO ; clear last zero received.
	btfsc	STATUS,Z	; was a zero the last received digit?
	bsf	mscFlag,DT2ZERO ; yes...
	btfsc	dt2Ptr,0	; is this an odd address?
	goto	DT2Odd		; yes;
	clrf	INDF		; zero both nibbles.
	movwf	INDF		; save tone in indirect register.
	swapf	INDF,f		; move the tone to the high nibble
	goto	DT2Done		; done here
DT2Odd
	iorwf	INDF,F		; save tone in low nibble
DT2Done 
	incf	dt2Ptr,f	; increment index
	movlw	h'1f'		; mask
	andwf	dt2Ptr,f	; don't let index grow past 1f (31)

	bsf	STATUS,RP0	; select page 1
	clrf	TRISD		; set port D all outputs.
	bcf	STATUS,RP0	; select bank 0.
	goto	CkISDR		; done here

CkDT2L				; check for end of LITZ...
	btfss	rxFlag,RX1OPEN	; is receiver 1 marked active?
	goto	CkISDR		; no. ignore DTMF.
	btfss	mscFlag,DT2ZERO ; was zero the last received digit?
	goto	CkISDR		; no.
	movf	dt2Tmr,w	; get dtmf command timer
	btfsc	STATUS,Z	; is it already zero?
	goto	CkDT2LZ		; yes.
	sublw	LITZTIM		; subtract from litz time.
	btfss	STATUS,C	; is result positive?
	goto	CkISDR		; nope.

CkDT2LZ				; check for LITZ digits.
	bsf	mscFlag,LITZDT2 ; set LITZ on main receiver flag.
	clrf	dt2Ptr		; clear this, throw away received LITZ tone.
	clrf	dt2Tmr		; clear this, don't process tones normally.
		
CkISDR
	btfss	b_last,ISDRAC	; action on ISDRAC
	goto	SaveB		; nope..

	btfsc	b_now,ISDRAC	; is ISDRAC low?
	goto	SaveB		; nope...
	bsf	isdFlag,ISDRACF ; set ISD RAC attention flag...
	
SaveB
	movf	b_now,w		; get port b (copy) byte
	movwf	b_last		; save last port b.
	bcf	INTCON,RBIF	; clear portb change f
	goto	IntExit		; done here.
	
TimrInt
	movlw	T0PRE		; get timer 0 preset value
	movwf	TMR0		; preset timer 0
	bsf	tFlags,TICK	; set tick indicator flag

TimrDone			
	bcf	INTCON,T0IF	; clear RTCC int mask
	goto	IntExit		; done here.

URInt				; USART receiver interrupt.
	movf	ciRHead,w	; save it...
	addlw	LOW irbuf00	; add to buffer base address.
	movwf	FSR		; set FSR as pointer
	movf	RCREG,w		; get received char.
	bcf	STATUS,IRP	; select 00-FF range for FSR/INDF
	movwf	INDF		; put char into buffer

	incf	ciRHead,w	; increment pointer.
	andlw	h'1f'		; mask so result stays in 0-31 range.
	movwf	ciRHead		; save pointer.

	movf	INDF,w		; get received character back.
	sublw	CIV_PRE		; subtract CI-V preamble character.
	btfsc	STATUS,Z	; skip if non-zero.
	clrf	ciRHead		; preamble.  Reset to start of buffer.

	movf	INDF,w		; get received character back.
	sublw	CIV_EOM		; subtract CI-V EOM character.
	btfsc	STATUS,Z	; skip if non-zero.
	bsf	mscFlag,CIV_RDY ; end of message received, ready to process.

	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	goto	IntExit		; done here.

UTInt				; USART transmitter interrupt.
	movf	ciTTail,w	; get tail pointer.
	subwf	ciTHead,w	; subtract from head pointer.
	btfsc	STATUS,Z	; result should be non-zero if buffer not empty
	goto	UTIntD		; buffer is empty.
	incf	ciTTail,w	; get pointer + 1.
	andlw	h'1f'		; mask so result stays in 0-31 range.
	movwf	ciTTail		; save it...
	addlw	LOW itbuf00	; add to buffer base address.
	movwf	FSR		; set FSR as pointer.
	bcf	STATUS,IRP	; select 00-FF range for FSR/INDF
	movf	INDF,w		; get char.
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	movwf	TXREG		; send char.
	goto	IntExit		; done here.
	
UTIntD				; no more chars to transmit.
	;; turn off the transmitter interrupt.
	bsf	STATUS,RP0	; select bank 1
	bcf	PIE1,TXIE	; turn off the transmitter interrupt.
	bcf	STATUS,RP0	; select bank 1
	;; goto IntExit		; done here.
	
IntExit
	movf	p_copy,w	; get PCLATH preserved value
	movwf	PCLATH		; restore PCLATH
	movf	f_copy,w	; get FSR preserved value
	movwf	FSR		; restore FSR
	swapf	s_copy,w	; get STATUS preserved value
	movwf	STATUS		; restore STATUS
	swapf	w_copy,f	; swap W
	swapf	w_copy,w	; restore W
	retfie

;
; Play the appropriate ID message, reset ID timers & flags
;
DoID
	movf	txFlag,w	; get txFlag
	andlw	b'00000011'	; mask out uninteresting bits.
	btfss	STATUS,Z	; are those receivers active?
	bsf	flags,needID	; yes.
	btfss	flags,needID	; need to ID?
	return			; nope--id timer expired without tx since last
	;; play the ID here.
	bsf	idRFlag,IDNOW	; set IDing now flag.
	movf	txFlag,w	; get tx flags
	andlw	h'03'		; w=w&(RX0OPEN|RX1OPEN), non zero if repeating
	btfss	STATUS,Z	; Z set is not repeating
	goto	DoIDCW		; actively repeating, play CW ID.
	;; not actively repeating (nobody talking), ok to play voice ID
	btfsc	flags,initID	; initial ID wanted?
	goto	DoIDInt		; yep.

	;; group2 bits 1, 2, & 3 enable the 3 normal IDs.
	movlw	b'00001110'	; bitmask for the 3 enabled IDs.
	andwf	group2,w	; check to see if the speech IDs are enabled.
	btfsc	STATUS,Z	; Z will be true if no speech IDs are enabled.
	goto	DoIDCW		; no speech IDs enabled.
	;; at least 1 speech normal ID is enabled
	btfsc	idRFlag,IDR0	; check to see if ID 2 is next.
	goto	DoIDck2		; ID 2 is next.
	btfsc	idRFlag,IDR1	; check to see if ID 3 is next.
	goto	DoIDck3		; ID 3 is next.

DoIDck1
	bsf	idRFlag,IDR0	; going to try ID 1 now, ID2 is next.
	bcf	idRFlag,IDR1	; make sure 2 is next.
	btfss	group2,1	; is Speech ID 1 enabled?
	goto	DoIDck2		; nope.
	movlw	VNID1		; get normal ID 1 message
	goto	DoIDSpc		; play ID message

DoIDck2
	bcf	idRFlag,IDR0	; going to try ID 2 now, ID 3 is next.
	bsf	idRFlag,IDR1	; make sure 3 is next.
	btfss	group2,2	; is Speech ID 2 enabled?
	goto	DoIDck3		; nope.
	movlw	VNID2		; get normal ID 2 message
	goto	DoIDSpc		; play ID message

DoIDck3
	bcf	idRFlag,IDR0	; going to try ID 3 now, ID 1 is next.
	bcf	idRFlag,IDR1	; make sure 1 is next.
	btfss	group2,3	; is Speech ID 3 enabled?
	goto	DoIDck1		; nope.
	movlw	VNID3		; get normal ID 2 message
	goto	DoIDSpc		; play ID message

DoIDInt				; play initial ID
	btfss	group2,0	; is initial speech ID enabled?
	goto	DoIDCW		; not enabled, play CW.
	movlw	VIID		; get initial ID

DoIDSpc				; play speech ID
	PAGE3			; select code page 3.
	call	PutWord		; add word in W to buffer.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PTTon		; turn on tx if not on already.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
	goto	DoIDrst

DoIDCW				; play CW id.
	PAGE3			; select code page 3.
	call	PTTon		; turn on tx if not on already.
	movlw	EECWID		; address of CW ID message in EEPROM.
	movwf	eeAddrL		; save CT base address
	clrf	eeAddrH		; save CT base address hi byte
	call	PlayCWe		; kick of the CW playback.
	PAGE0			; select code page 0.
	
DoIDrst				; reset ID timer & logic.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETID		; get EEPROM address of ID timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	idTmr		; store to idTmr down-counter
	bcf	flags,initID	; clear initial ID flag
	movf	txFlag,w	; get tx flags
	andlw	h'03'		; w=w&(RX0OPEN|RX1OPEN), non zero if RX active.
	btfsc	STATUS,Z	; is it zero?
	bcf	flags,needID	; yes. reset needID flag.
	return

PlayMsg				; play a speech message, message # in w.
	PAGE3			; select code page 3.
	call	PutWord		; add word in W to buffer.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PTTon		; turn on tx if not on already.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
	return			; done here.
	
Rcv0Off				; turn off receiver 0
	movlw	RXSOFF		; get new state #
	movwf	rx0Stat		; set new receiver state
	bcf	outPort,RX0AUD	; mute it...
	bcf	txFlag,RX0OPEN	; clear main receiver on bit
	clrf	rx0TOut		; clear main receiver timeout timer
	return
	
Rcv1Off				; turn off receiver 1
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	outPort,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	clrf	rx1TOut		; clear link receiver timeout timer
	return
	
SetHang				; start hang timer...
	btfss	group0,3	; is hang timer enabled?
	return			; nope.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETHTS		; get EEPROM address of hang timer short preset
	btfsc	group0,4	; is long hang timer selected?
	movlw	EETHTL		; get EEPROM address of hang timer long preset
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	hangDly		; save this in hangDly, used often.
	movwf	hangTmr		; preset hang timer
	btfsc	STATUS,Z	; check to see if the hang timer is zero.
	return			; it is.  can't hang...
	bsf	txFlag,TXHANG	; set hang time transmit flag
	return			; done.

ChkID				; call on receiver drop to see if want to ID
	btfsc	flags,initID	; check initial id flag
	call	DoID		; play the ID
	btfss	flags,needID	; need to ID?
	return
	;
	;if (idTmr <= idSoon) then goto StartID
	;implemented as: if ((IDSOON-idTimer)>=0) then ID
	;
	movf	idTmr,w		; get idTmr into W
	sublw	IDSOON		; IDSOON-w ->w
	btfsc	STATUS,C	; C is clear if result is negative
	call	DoID		; ok to ID now, let's do it.
	return			; don't need to ID yet...

; ***************************************************
; ** DoTail -- Play Tail Message and Reset Counter **
; ***************************************************

DoTail	
	;; group2 bits 4, 5, & 6 enable the normal tail messages.
	;; group2 biut 7 enabled the mailbox headers tail message.
	movlw	b'11110000'	; bitmask for the 4 tail messages.
	andwf	group2,w	; check if any tail messages are enabled.
	btfsc	STATUS,Z	; Z will be true if none are enabled.
	goto	DoTEnd		; no tail messages enabled.
	;; at least 1 tail message is enabled
	btfsc	idRFlag,TAILR0	; check to see if tail message 2 is next.
	goto	DoTck2		; tail message 2 is next.
	btfsc	idRFlag,TAILR1	; check to see if tail message 3 is next.
	goto	DoTck3		; tail message 3 is next.
	btfsc	idRFlag,TAILRM	; check to see if mbx tail message is next.
	goto	DoTckM		; mailbox tail message is next.
DoTck1
	bsf	idRFlag,TAILR0	; going to try TM 1 now, TM 2 is next.
	bcf	idRFlag,TAILR1	; make sure 2 is next.
	bcf	idRFlag,TAILRM	; make sure 2 is next.
	btfss	group2,4	; is TM 1 enabled?
	goto	DoTck2		; nope.
	movlw	VTAIL1		; get tail message 1
	goto	DoTSpc		; play tail message

DoTck2
	bcf	idRFlag,TAILR0	; going to try TM 2 now, TM 3 is next.
	bsf	idRFlag,TAILR1	; make sure 3 is next.
	bcf	idRFlag,TAILRM	; make sure 3 is next.
	btfss	group2,5	; is TM2 enabled?
	goto	DoTck3		; nope.
	movlw	VTAIL2		; get TM 2 message
	goto	DoTSpc		; play tail message

DoTck3
	bcf	idRFlag,TAILR0	; going to try TM 3 now, mbx tail is next.
	bcf	idRFlag,TAILR1	; make sure M is next.
	bsf	idRFlag,TAILRM	; make sure 3 is next.
	btfss	group2,6	; is Speech ID 3 enabled?
	goto	DoTckM		; nope.
	movlw	VTAIL3		; get TM 3 message
	goto	DoTSpc		; play tail message.

DoTckM
	bcf	idRFlag,TAILR0	; going to try mbx hdrs now, TM 1 is next.
	bcf	idRFlag,TAILR1	; make sure 1 is next.
	bcf	idRFlag,TAILRM	; make sure 1 is next.
	btfss	group2,7	; is mailbox header tail message enabled?
	goto	DoTck1		; nope.
	movf	mbxFlag,f	; check for messages in mailboxes.
	btfss	STATUS,Z	; skip if zero -- no messages
	goto	DoTckM1		; there are messages, play the headers.
	movlw	b'01110000'	; bitmask for the 3 normal tail messages.
	andwf	group2,w	; check if any tail messages are enabled.
	btfsc	STATUS,Z	; Z will be true if none are enabled.
	goto	DoTEnd		; no tail messages enabled.
	goto	DoTail		; try to play one of the other tail messages.

DoTckM1
	PAGE3			; select code page 3.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PTTon		; turn on tx if not on already.
	call	MbxHdrs		; play mailbox headers.
	PAGE0			; select code page 0.
	goto	DoTEnd		; done here.

DoTSpc				; play speech ID
	PAGE3			; select code page 3.
	call	PutWord		; add word in W to buffer.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PTTon		; turn on tx if not on already.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.

DoTEnd
	;; now, reset tail message counter.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETTAIL		; get EEPROM address of tail message counter.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	tailCtr		; preset tail message counter.
	return			; done with tail message.
	
	;; **************************************************
	;; **************************************************
	;; **************************************************

; *********************
; ** PROGRAM STARTUP **
; *********************
	org	0200
Start
	;bsf	STATUS,IRP	; select FSR is in 100-1ff range
	bsf	STATUS,RP0	; select bank 1

	movlw	b'00000000'
	movwf	ADCON0
	movlw	b'00000111'
	movwf	ADCON1
	
	movlw	B'11111000'	; na/na/in/in/in/out/out/out
	movwf	TRISA		; set port A data direction

	movlw	B'11110001'	; in/in/in/in/out/out/out/in
	movwf	TRISB		; set port B data direction

	movlw	B'10010000'	; SCI/SCI/SPI/SPI/SPI/out/out/out
				; in  out out in  out out out out
	movwf	TRISC		; set port C data direction

	movlw	B'00000000'	; all outputs normally.
	movwf	TRISD		; set port D data direction

	movlw	B'00000111'	; na/na/na/na/na/in/in/in
	movwf	TRISE		; set port E data direction
 
	movlw	b'10000011'	; RBPU\ no pull up, 
				; INTEDG INT on falling edge
				; T0CS	 TMR0 uses instruction clock
				; T0SE	n/a
				; PSA TMR0 gets the prescaler 
				; PS2 \
				; PS1  > prescaler 16
				; PS0 /
	movwf	OPTION_REG	; set options
	
	movlw	b'11000000'	; SMP=1 CKE=1
	movwf	SSPSTAT		; input data on falling edge, output on rising
	movlw	d'103'		; 9600 baud at 16.0 MHz clock.
	movwf	SPBRG		; set baud rate generator.
	movlw	b'00100100'	; transmit enabled, hi speed async.
	movwf	TXSTA		; set transmit status and control register.
	movlw	b'00100000'	; USART rx interrupt enabled.
	movwf	PIE1		; set peripheral interrupts enable register.
	bcf	STATUS,RP0	; select bank 0
	movlw	b'10010000'	; serial enabled, etc.
	movwf	RCSTA		; set receive status and control register.

	clrf	PORTA		; clear port outputs
	clrf	PORTB
	bsf	PORTB,ISDSEL	; isd ss\ should be hi.
	clrf	PORTC
	bsf	PORTC,EEPSEL	; eeprom ss\ should be hi.
	clrf	PORTD
	clrf	PORTE	

	movlw	b'00100001'	; set up spp: on, spi master, clk/16
	movwf	SSPCON		; set up SPP for SPI mode.
	
	btfss	STATUS,NOT_TO	; did WDT time out?
	bsf	PORTA,LED1	; yes, light warning lamp.

	clrwdt			; give me more time to get up and running.
	;bcf	STATUS,IRP	; select FSR is in 00-ff range
	movlw	h'20'		; first address of RAM.
	movwf	FSR		; set pointer.
ClrMem
	clrf	INDF		; clear ram byte.
	incf	FSR,f		; increment FSR.
	btfss	FSR,7		; cheap test for address 80 and above.
	goto	ClrMem		; loop some more.
	bsf	STATUS,IRP	; select FSR is in 100-1ff range
	
	movlw	TEN		; get timebase presets
	movwf	oneMsC
	movwf	tenMsC
	movwf	hundMsC
	movwf	thouMsC
	clrf	tFlags

	bsf	STATUS,RP0	; select register page 1.
	;; preset CI-V frequency in buffer to 28.4 MHz.
	clrf	civfrq1		; reset to 0 0.
	clrf	civfrq2		; reset to 0 0.
	movlw	h'40'		;   set to 4 0.
	movwf	civfrq3		;   set to 4 0.
	movlw	h'28'		;   set to 2 8.
	movwf	civfrq4		;   set to 2 8.
	clrf	civfrq5		; reset to 0 0.
	clrf	scanTmr		; clear scan timer.
	clrf	scanMod		; clear scan mode.
	bcf	STATUS,RP0	; select register page 0.
	
	movlw	CTNONE		; no courtesy tone.
	movwf	cTone		; set courtesy tone selector.
	
	;; preset timer defaults
	clrf	cwTbTmr		; CW timebase counter.
	
	movf	PORTB,w		; get port B value
	movwf	b_last		; save it...

	;; initialize the output port.
	clrf	PORTD		; clear port D
	bsf	PORTC,OUTSEL	; raise output port enable
	nop			; short delay
	bcf	PORTC,OUTSEL	; lower output port enable
	;; initialize the tone generator.
	bsf	PORTB,TONESEL	; set PDC3311 STROBE high
	nop			; short delay (PDC3311 requires 400 ns here)
	bcf	PORTB,TONESEL	; set PDC3311 STROBE low.
	;; clear the digital outputs.
	bsf	PORTA,EXPSEL	; raise digital output port enable
	nop			; very short delay
	bcf	PORTA,EXPSEL	; lower digital output port enable

	;; enable enough interrupts to run timer.
	movlw	b'10100000'	; enable global + timer interrupts
	movwf	INTCON

	;; now have a short pause before turning the ISD chip on.
	call	Delay20		; delay 20 ms.

	;; power up ISD chip!
InitISD
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	InitISD		; still enabled, retry disable.
	clrf	isdCmdC		; clear command.
	bsf	isdCmdC,ISDPUP	; power up only.
	PAGE3			; select code page 3.
	call	CmdISD8a	; send the power up command.
	PAGE0			; select code page 0.

	;; enable interrupts.
	movlw	b'11111000'	; enable global + int, peripheral, timer, portb
	movwf	INTCON

	btfsc	PORTE,INIT	; skip if init button pressed.
	goto	Start1		; no initialize request.
	PAGE2			; select code page 2.
	call	InitEE		; initialize the EEPROM contents.
	PAGE0			; select code page 0.
	goto	Start1		; no initialize request.
	
Delay20				; get a 20 ms delay.
	movlw	d'20'		; ms.
	PAGE2			; select code page 2
	call	InitDly		; delay
	PAGE0			; select code page 0
	return			; done.

; ********************************
; ** Ready to really start now. **
; ********************************
Start1
	clrw			; select macro set 0.
	PAGE3			; select page 3.
	call	LoadCtl		; load control op settings.
	;; get tail message counter.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETTAIL		; get EEPROM address of tail message counter.
	movwf	eeAddrL		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	tailCtr		; preset tail message counter.
	;; get phone ring counter.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETRING		; get EEPROM address of ring counter.
	movwf	eeAddrL		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select page 0.
	movwf	ringCtr		; preset ring counter.
	;;
	;; say hello to all the nice people out there.
	;; 
	PAGE3			; select code page 3.
	movlw	VNHRC		; get word "NHRC".
	call	PutWord		; add word to send buffer.
	movlw	V10		; get word "TEN".
	call	PutWord		; add word to send buffer.
	movlw	VREPEAT		; get word "REPEATER".
	call	PutWord		; add word to send buffer.
	movlw	VCNTRLR		; get word "CONTROLLER".
	call	PutWord		; add word to send buffer.
	movlw	VVERSN		; get word "VERSION".
	call	PutWord		; add word to send buffer.
	movlw	VER_INT		; get word for major version number.
	call	PutWord		; add word to send buffer.
	movlw	VPOINT		; get word "POINT".
	call	PutWord		; add word to send buffer.
	movlw	VER_HI		; get word for minor version number.
	call	PutWord		; add word for number to send buffer.
	movlw	VER_LO		; get word for even mode minor version number.
	addlw	h'00'		; add zero, will set Z if zero.
	btfss	STATUS,Z	; skip this word if it is zero.
	call	PutWord		; add word for number to send buffer.
	PAGE0			; select code page 0.
	bsf	flags,initID	; want initial ID right away.
	bsf	flags,needID	; want to ID right away.

	btfss	group2,0	; is initial speech ID enabled?
	goto	Hello1		; no.
	call	DoID		; so ID already...
	goto	Loop0		; get started.

Hello1
	bsf	group2,0	; enable initial speech ID for now.
	call	DoID		; so ID already...
	bcf	group2,0	; return initial speech ID to disabled.
	
; **************************************************************************
; ******************************* MAIN LOOP ********************************
; **************************************************************************
		
Loop0
	btfsc	tFlags,TENSEC	; is ten second flag set?
	bcf	tFlags,TENSEC	; reset it if it is...

Chek1000	
	btfss	tFlags,ONESEC	; is the 1000 mS flag set?
	goto	Check100	; nope...
	bcf	tFlags,ONESEC	; clear 1000 mS flag.
	decfsz	thouMsC,f	; decrement hundred millisecond counter.
	goto	Check100	; not zero.
	movlw	TEN		; get preset.
	movwf	thouMsC		; reset down counter.
	bsf	tFlags,TENSEC	; set ONESEC indicator.

Check100	
	btfss	tFlags,HUNDMS	; is the 100 mS flag set?
	goto	Check10		; nope...
	bcf	tFlags,HUNDMS	; clear 100 mS flag.
	decfsz	hundMsC,f	; decrement hundred millisecond counter.
	goto	Check10		; not zero.
	movlw	TEN		; get preset.
	movwf	hundMsC		; reset down counter.
	bsf	tFlags,ONESEC	; set ONESEC indicator.

Check10
	btfss	tFlags,TENMS	; is the 10 mS flag set?
	goto	Check1		; nope...
	bcf	tFlags,TENMS	; clear 10 mS flag.
	decfsz	tenMsC,f	; decrement ten millisecond counter.
	goto	Check1		; not zero.
	movlw	TEN		; get preset.
	movwf	tenMsC		; reset down counter.
	bsf	tFlags,HUNDMS	; set HUNDMS indicator.

Check1
	btfss	tFlags,ONEMS	; is the 1 mS flag set?
	goto	CheckTic	; nope...
	bcf	tFlags,ONEMS	; clear 1 mS flag.
	decfsz	oneMsC,f	; decrement one millisecond counter.
	goto	CheckTic	; not zero.
	movlw	TEN		; get preset.
	movwf	oneMsC		; reset down counter.
	bsf	tFlags,TENMS	; set TENMS indicator.

CheckTic
	
	btfss	tFlags,TICK	; did a tick occur?
	goto	Loop1		; nope.
	bcf	tFlags,TICK	; reset TICK indicator.
	bsf	tFlags,ONEMS	; set ONEMS indicator.
	CLRWDT

Loop1
	;; LED BLINKER!!!  I'M ALIVE!!!	 I'M ALIVE!!!  WOOHOO!!!
	btfss	tFlags,HUNDMS
	goto	LedEnd
	btfss	PORTA,LED2
	goto	l3off
	bcf	PORTA,LED2
	goto	LedEnd
l3off 
	bsf	PORTA,LED2
LedEnd
	
; ********************************************
; ** RECEIVER DEBOUNCE AND INPUT VALIDATION **
; ********************************************
DebRx
	btfss	tFlags,TENMS	; ten ms tick, check for receiver active
	goto	NoDeb		; nope
CkRx0				; check COR state receiver 1
	bcf	mscFlag,CTCSS0	; clear LAST CTCSS flag.
	btfss	PORTA,RX0PL	; is the PL signal present?
	bsf	mscFlag,CTCSS0	; set LAST CTCSS flag.
	btfss	PORTA,RX0COR	; check cor receiver 1
	goto	Rx0COR1		; it's low, COR is present
				; COR is not present.
	btfss	group1,2	; (NOT) OR PL?
	goto	Rx0Off		; nope...
	;; v 1.14 change here.
	btfsc	group0,1	; is PL required?
	goto	Rx0Off		; yes.
	;; end 1.14 change.
	goto	Rx0CkPL		; yes, OR PL mode
Rx0COR1
	btfss	group0,1	; AND PL set?
	goto	Rx0On		; no.
	;; v 1.14 new code.
	btfss	group1,2	; OR PL set?
	goto	Rx0CkPL		; no.
	;; AND and OR PL are both set, PL is required to bring up repeater,
	;; but not to access it during tail.
	movf	txFlag,w	; get txFlag.
	andlw	b'00000111'	; hang, rx1 or rx2 open.
	btfss	STATUS,Z	; Z will be set if repeater is idle.
	goto	Rx0On		; repeater is not idle.  Allow COR access.
	;; end v 1.14 new code.
Rx0CkPL				; check PL...
	btfsc	PORTA,RX0PL	; is the PL signal present?
	goto	Rx0Off		; no.
Rx0On				; the COR and PL requirements have been met
	btfsc	rxFlag,RX0OPEN	; already marked active?
	goto	Rx0NC		; yes.
	movf	rx0Dbc,f	; check for zero
	btfss	STATUS,Z	; is it zero?
	goto	Rx01Dbc		; nope...
	movlw	COR1DEB		; get COR debounce timer value.
	btfsc	group3,6	; is the delay present?
	movlw	DLY1DEB		; get COR debounce with delay value.
	movf	txFlag,f	; check for transmitter already on.
	btfss	STATUS,Z	; is the transmitter already on?
	goto	Rx0SDeb		; yep.
	btfsc	group0,2	; is the kerchunker delay set?
	movlw	CHNKDEB		; get kerchunker filter delay.
Rx0SDeb				; set debounce timer.
	movwf	rx0Dbc		; set it
	goto	Rx0Done		; done.
Rx01Dbc
	decfsz	rx0Dbc,f	; decrement the debounce counter
	goto	Rx0Done		; not zero yet
	bsf	rxFlag,RX0OPEN	; set receiver active flag
	goto	Rx0Done		; continue...
Rx0Off				; the COR and PL requirements have not been met
	btfss	rxFlag,RX0OPEN	; was the receiver off before?
	goto	Rx0NC		; yes.
	movf	rx0Dbc,f	; check for zero
	btfss	STATUS,Z	; is it zero?
	goto	Rx00Dbc		; nope...
	movlw	COR0DEB		; get COR debounce timer value.
	btfsc	group3,6	; is the delay present?
	movlw	DLY0DEB		; get COR debounce with delay value.
	movwf	rx0Dbc		; set it
	goto	Rx0Done		; done.
Rx00Dbc
	decfsz	rx0Dbc,f	; decrement the debounce counter
	goto	Rx0Done		; not zero yet
	bcf	rxFlag,RX0OPEN	; clear receiver active flag
	movf	dt0Tmr,f	; test to see if touch-tones received...
	btfsc	STATUS,Z	; is it zero?
	goto	Rx0Done		; yes. don't need to accellerate execution.
	movlw	d'2'		; no
	movwf	dt0Tmr		; accelerate eval of DTMF command
	goto	Rx0Done		; continue...
Rx0NC
	clrf	rx0Dbc		; clear debounce counter.
Rx0Done
		
CkRx1				; check COR state receiver 2
	bcf	mscFlag,CTCSS2	; clear LAST CTCSS flag.
	btfss	PORTE,RX1PL	; is the PL signal present?
	bsf	mscFlag,CTCSS2	; set LAST CTCSS flag.
	btfss	PORTE,RX1COR	; check cor receiver 1
	goto	Rx1COR1		; it's low, COR is present
				; COR is not present.
	btfss	group5,6	; (NOT) OR PL?
	goto	Rx1Off		; nope...
	;; v 1.14 new code
	btfsc	group5,5	; is PL required?
	goto	Rx1Off		; yes.
	;; end v 1.14 new code
	goto	Rx1CkPL		; yes, OR PL mode

Rx1COR1
	btfss	group5,5	; AND PL set?
	goto	Rx1On		; no.
	;; v 1.14 new code
	btfss	group5,6	; OR PL set?
	goto	Rx1CkPL		; no.
	;; AND and OR PL are both set, PL is required to bring up repeater,
	;; but not to access it during tail.
	movf	txFlag,w	; get txFlag.
	andlw	b'00000111'	; hang, rx1 or rx2 open.
	btfss	STATUS,Z	; Z will be set if repeater is idle.
	goto	Rx1On		; repeater is not idle.  Allow COR access.
	;; end v 1.14 new code.
Rx1CkPL				; check PL...
	btfsc	PORTE,RX1PL	; is the PL signal present?
	goto	Rx1Off		; no.
Rx1On				; the COR and PL requirements have been met
	btfsc	rxFlag,RX1OPEN	; already marked active?
	goto	Rx1NC		; yes.
	movf	rx1Dbc,f	; check for zero
	btfss	STATUS,Z	; is it zero?
	goto	Rx11Dbc		; nope...
	movlw	COR1DEB		; get COR debounce timer value
	btfsc	group3,7	; is the delay present?
	movlw	DLY1DEB		; get COR debounce with delay value.
	movf	txFlag,f	; check for transmitter already on.
	btfss	STATUS,Z	; is the transmitter already on?
	goto	Rx1SDeb		; yep.
	btfsc	group0,2	; is the kerchunker delay set?
	movlw	CHNKDEB		; get kerchunker filter delay.
Rx1SDeb				; set debounce timer.
	movwf	rx1Dbc		; set it
	goto	Rx1Done		; done.
Rx11Dbc
	decfsz	rx1Dbc,f	; decrement the debounce counter
	goto	Rx1Done		; not zero yet
	bsf	rxFlag,RX1OPEN	; set receiver active flag
	goto	Rx1Done		; continue...
Rx1Off				; the COR and PL requirements have not been met
	btfss	rxFlag,RX1OPEN	; was the receiver off before?
	goto	Rx1NC		; yes.
	movf	rx1Dbc,f	; check for zero
	btfss	STATUS,Z	; is it zero?
	goto	Rx10Dbc		; nope...
	movlw	COR0DEB		; get COR debounce timer value.
	btfsc	group3,7	; is the delay present?
	movlw	DLY0DEB		; get COR debounce with delay value.
	movwf	rx1Dbc		; set it
	goto	Rx1Done		; done.
Rx10Dbc
	decfsz	rx1Dbc,f	; decrement the debounce counter
	goto	Rx1Done		; not zero yet
	bcf	rxFlag,RX1OPEN	; set receiver active flag
	btfss	group1,7	; is control rx & link port the same?
	goto	Rx1Done		; nope.
	movf	dt2Tmr,f	; test to see if touch-tones received...
	btfsc	STATUS,Z	; is it zero?
	goto	Rx1Done		; yes. don't need to accellerate execution.
	movlw	d'2'		; no
	movwf	dt2Tmr		; accelerate eval of DTMF command
	goto	Rx1Done		; done.
Rx1NC
	clrf	rx1Dbc		; clear debounce counter.
Rx1Done
	
NoDeb
	;; service ISD RAC request here...
	btfss	isdFlag,ISDRACF ; is there a RAC waiting for service?
	goto	NoRAC		; nope.
	bcf	isdFlag,ISDRACF ; yes, clear the RAC flag.
	;; got a RAC indication from the ISD.
	btfsc	isdFlag,ISDIABF ; sent IAB command yet?
	goto	RACcChk		; yes...
	;; send the IAB command to the ISD and set the flag bit.
SendIAB
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	SendIAB		; still enabled, retry disable.
	PAGE3			; select code page 3.
	call	CmdISD8		; send 8-bit command to ISD.
	PAGE0			; select code page 0.
	bsf	isdFlag,ISDIABF ; sent the IAB command.
	bsf	INTCON,GIE	; re-enable interrupts

RACcChk				; check rac counter.
	movf	isdRACc,f	; test RAC counter, should be >0...
	btfss	STATUS,Z	; skip if isdRACc is zero.
	goto	RACCNZ		; it's non-zero, this is the expected conditn.
	;; something bad has happened.	got a RAC indication when not
	;; expecting any.  Simply stop the ISD.
	PAGE3			; select code page 3.
	call	ISDStop		; stop play or record.
	PAGE0			; select code page 0.
	bcf	txFlag,TALKING	; turn this off, too.
	goto	NoRAC		; continue on our merry way...

RACCNZ				; recording, RACCNT is non-zero
	decfsz	isdRACc,f	; decrement RAC counter
	goto	NoRAC		; not zero yet.
	;; isdRACc has counted to zero.
	;; very near the end of this message space; 
	btfss	isdFlag,ISDRECF ; is a record operation in progress?
	goto	RACPlay		; Playback in progress. deal with it.
	;; in record mode. only one row left. need to leave room for
	;; eom marker.	use timer to halt after ISDLREC delay (200 ms)
	movlw	ISDDLYC		; get stop delay
	movwf	isdDly		; set stop delay
	goto	NoRAC		; continue.

RACPlay				; got final RAC in playback mode.
	PAGE3			; select code page 3.
	call	ISDStop		; stop play or record.
	PAGE0			; select code page 0.
	bcf	txFlag,TALKING	; turn this off, too.
	bsf	isdFlag,ISDWRDF ; set get another word indicator.
	goto	NoRACD		; continue & get the next word.

NoRAC				; 
	;; service isdDly timer here...
	btfss	tFlags,ONEMS	; one MS flag set?
	goto	NoRACD		; nope...
	movf	isdDly,f	; test isdDly...
	btfsc	STATUS,Z	; is it zero?
	goto	NoRACD		; yes.	Do nothing here.
	decfsz	isdDly,f	; decrement isdDly
	goto	NoRACD		; not zero yet.
	btfsc	isdFlag,ISDRUN	; was the ISD running
	goto	NoRACR		; yes.
	btfss	isdFlag,ISDD4RC ; deferred record requested?
	goto	WordEnd		; no.  start speech.
	;; deferred record requested.
	bcf	isdFlag,ISDD4RC ; clear deferred record bit
	movf	isdRMsg,w	; get record message number.
	movwf	isdMsg		; set message number.
	movlw	h'ff'		; set invalid record message number.
	movwf	isdRMsg		; save it.
	PAGE3			; select code page 3.
	call	ISDRec		; start recording
	PAGE0			; select code page 0.
	goto	NoRACD

NoRACR
	;; isd timer timed out.
	PAGE3			; select code page 3.
	call	ISDStop		; stop the ISD.
	PAGE0			; select code page 0.

NoRACD
	;; check ISDWRDF bit; indicated playback of word complete.
	btfss	isdFlag,ISDWRDF ; was IRQ flag set?
	goto	NoISDInt	; nope.
	;; the ISD wants another word...  Feed it.
	bcf	isdFlag,ISDWRDF ; clear the indicator
WordEnd
	PAGE3			; select code page 3.
	call	NextWrd		; see if there is another word
	PAGE0			; select code page 0.
NoISDInt			; no action required on the ISD.
	
	;goto	MainLp		; crosses 256 byte boundary (to 0400)

	;; leave room to fill this in
		
	;org 0400

; *************************************
; * main loop for repeater controller *
; *************************************

MainLp
	movlw	high MlTbl	; set high byte of address
	movwf	PCLATH		; select page
	movf	rx0Stat,w	; get main receiver state
	addwf	PCL,f		; add w to PCL:	 computed GOTO
MlTbl
	goto	Main0		; quiet
	goto	Main1		; repeat
	goto	Main2		; timeout

Main0				; receiver quiet state
	btfss	rxFlag,RX0OPEN	; is squelch open?
	goto	ChkRb		; nope, don't turn receiver on
	;; receiver is unsquelched; put it on the air
	;; receiver inactive --> active transistion
	btfss	group0,0	; is repeater enabled?
	goto	ChkRb		; disabled, not gonna turn receiver on
	btfss	group0,5	; is DTMF access mode enabled?
	goto	Main00		; no.
	movf	dtATmr,f	; check DTMF access mode timer.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkRb		; yes.	Don't turn receiver on.
	;; timer is not zero, reset to initial value.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	dtATmr		; set DTMF access mode timer.
Main00				; receiver inactive --> active transition
	movlw	RXSON		; get new state #
	movwf	rx0Stat		; set new receiver state
	bsf	txFlag,RX0OPEN	; set main receiver on bit
	movlw	CTNONE		; no courtesy tone.
	movwf	cTone		; kill off any pending courtesy tone.
	bsf	STATUS,RP0	; select register page 1.
	clrf	scanTmr		; stop scanning.
	clrf	scanMod		; stop scanning.
	bcf	STATUS,RP0	; select register page 0.
	btfss	group5,1	; is RB in receive mode?
	goto	Main00a		; nope.
	bsf	flags,RBMUTE	; set the muted indicator.
	bcf	outPort,RX1AUD	; mute the remote base.
Main00a
	movf	group5,w	; get group 5
	andlw	b'00000110'	; is the link in transmit or receive mode?
	btfsc	STATUS,Z	; skip if either bit is set.
	goto	Main00b		; neither bit is set.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EERBTMR		; get EEPROM address of remote base timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rbTmr		; set remote base activity timer.
Main00b
	
	movf	muteTmr,f	; check mute timer
	btfsc	STATUS,Z	; if it's non-zero, skip unmute
	bsf	outPort,RX0AUD	; unmute receiver
	;; stomp playing voice messages here.
	btfss	isdFlag,ISDRUNF ; is ISD Running?
	goto	ChkRec		; no
	;; ISD is running.
	btfss	idRFlag,IDNOW	; is an ID playing now?
	goto	Stomp		; nope.
	btfss	group3,1	; is stomp allowed?
	goto	MainUM		; nope.	 bypass record check, too.
Stomp
	clrf	isdDly		; clear this so it can't fire, just in case.
	PAGE3			; select code page 3.
	call	ISDAbort	; abort ISD
	PAGE0			; select code page 0.

	btfss	idRFlag,IDNOW	; is an ID playing now?
	;; hmmmm.  should this be allowed to set record mode now?
	goto	ChkRec		; no.

	movlw	EECWID		; address of CW ID message in EEPROM.
	movwf	eeAddrL		; save CT base address
	clrf	eeAddrH		; save CT base address hi byte
	PAGE3			; select code page 1.
	call	PTTon		; turn on tx if not on already.
	call	PlayCWe		; kick off the CW playback.
	PAGE0			; select code page 0.
	bcf	idRFlag,IDNOW	; clear IDing flag.
	
ChkRec
	btfss	isdFlag,ISDRECR ; is record mode flag set?
	goto	MainUM		; no continue...
	bcf	isdFlag,ISDRECR ; clear record mode flag.
	incfsz	isdRMsg,w	; check for invalid number
	goto	ChkRec1		; valid number
	goto	MainUM		; invalid number
ChkRec1
	clrf	isdDly
	bsf	isdFlag,ISDD4RC ; set deferred record bit.
	movlw	ISD_DLY		; get ISD delay time
	movwf	isdDly		; set ISD timer for deferred record.
	
MainUM
	;; link non-repeater PTT logic
	btfss	group5,2	; is link TX enabled?
	goto	Main01		; nope...
	btfsc	group3,3	; is link port a repeater?
	goto	Main01		; yes ...
	btfsc	group5,3	; is link enabled during patch?
	goto	MainUML		; yes.
	btfsc	txFlag,PATCHON	; is the patch on?
	goto	Main01		; yes.

MainUML				; turn on the link transmitter.
	bsf	outPort,TX1PTT	; turn on link PTT

Main01
	btfss	group1,0	; is time out timer enabled?
	goto	ChkRb		; nope...
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETTMS		; EEPROM address of timeout timer short preset.
	btfsc	group1,1	; is short timeout selected
	movlw	EETTML		; EEPROM address of timeout timer long preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rx0TOut		; set timeout counter
	goto	ChkRb		; done here...

Main1				; receiver active state
	btfss	group0,0	; is repeater enabled?
	goto	Main1Off	; no.  turn receiver off
	btfss	rxFlag,RX0OPEN	; is squelch open?
	goto	Main1Off	; no, on->off transition
	btfss	tFlags,ONESEC	; one second tick?
	goto	ChkRb		; nope, continue
	movf	rx0TOut,f	; squelch still open, check timeout timer
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkRb		; timeout timer is zero, don't decrement
	decfsz	rx0TOut,f	; decrement the timeout timer
	goto	ChkRb		; have not timed out (yet), continue
	movlw	RXSTMO		; get new state, timed out
	movwf	rx0Stat		; set new receiver state
	bcf	txFlag,RX0OPEN	; clear main receiver on bit
	bcf	outPort,RX0AUD	; mute
	clrf	rx0TOut		; clear main receiver timeout timer
	btfsc	group3,2	; is voice timeout message enabled?
	goto	Main1TO		; yes...
	PAGE3			; select code page 3.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkRb		; done here...
Main1TO 
	movlw	VTOUT		; time out message
	call	PlayMsg		; play the message
	goto	ChkRb		; done here...

Main1Off			; receiver was active, became inactive
	call	Rcv0Off		; turn off receiver
	;; link non-repeater-mode PTT logic
	btfss	group5,2	; is link port TX enabled?
	goto	Main10		; nope...
	btfsc	group3,3	; is link port a repeater?
	goto	Main10		; yes...
	bcf	outPort,TX1PTT	; no, turn off link port tx
Main10
	;; version 1.14 changes
	;; bugfix for drop tx to mute dtmf not unmuting fast enough.
	movf	muteTmr,f	; test mute timer.
	btfsc	STATUS,Z	; z is set if NOT muting.
	goto	Main100		; muteTmr is zero.
	clrf	muteTmr		; make muting timer zero now.
	btfsc	group6,6	; drop tx to mute DTMF enabled, main.
	bsf	outPort,TX0PTT	; turn PTT back on.
	btfss	group1,4	; drop link to mute PTT enabled?
	goto	Main100		; no.
	btfss	group5,2	; link transmitter enabled?
	goto	Main100		; no.
	btfss	group3,3	; link port repeater mode enabled?
	goto	Main100		; no.
	bsf	outPort,TX1PTT	; turn link PTT back on.


Main100
	;; end version 1.14 changes
	btfss	isdFlag,ISDRECF ; is the ISD recording
	goto	Main10a		; nope.
	PAGE3			; select code page 3.
	call	ISDStop		; stop recording.
	PAGE0			; select code page 1.
	
Main10a
	btfss	isdFlag,ISDTEST ; was test message just recorded?
	goto	Main10b		; nope.
	bcf	isdFlag,ISDTEST ; clear test flag.
	movlw	VTESTM		; get test message track
	PAGE3			; select code page 3.
	call	PutWord		; put word into buffer
	bsf	outPort,BEEPAUD ; turn on beep audio
	call	SetPort		; set the output port
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
	
Main10b
	btfss	mbxCtl,MBXRHDR	; was mailbox header just recorded?
	goto	Main10c		; no.
	movlw	VRECORD		; get word "record".
	PAGE3			; select code page 3.
	call	PutWord		; put word into buffer
	movlw	VMBX		; get word "mailbox".
	call	PutWord		; put word into buffer
	movlw	VMESSAG		; get word "message".
	call	PutWord		; put word into buffer
	bsf	outPort,BEEPAUD ; turn on beep audio
	call	SetPort		; set the output port
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.

	movf	mbxCtl,w	; get message number
	andlw	h'0f'		; mask out high nibble
	addlw	VMB1		; add address of mailbox message slot.
	movwf	isdRMsg		; set record message number.
	bsf	isdFlag,ISDRECR ; set record mode flag
	bcf	mbxCtl,MBXRHDR	; clear record header control bit
	bsf	mbxCtl,MBXRMBX	; set record mailbox control bit.
	goto	Main10d

Main10c
	btfss	mbxCtl,MBXRMBX	; was mailbox just recorded?
	goto	Main10d		; no.
	bcf	mbxCtl,MBXRMBX	; clear record mailbox control bit.
	movlw	VOK		; get word "OK".
	PAGE3			; select code page 3.
	call	PutWord		; put word into buffer
	bsf	outPort,BEEPAUD ; turn on beep audio
	call	SetPort		; set the output port
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.

Main10d
	movlw	CTNORM		; get CT number
	btfss	group5,2	; is rb tx enabled?
	goto	Main10e		; nope.
	movlw	CTRBTX		; yes, get that courtesy tone
	goto	Main10h

Main10e
	btfss	group5,0	; is alert mode on?
	goto	Main10h		; nope.
	btfsc	rxFlag,RX1OPEN	; is rb squelch open?
	movlw	CTALERT		; yes, get that courtesy tone

Main10h
	movwf	cTone		; save the courtesy tone.
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now

	btfss	mscFlag,LITZDT0 ; is LITZ bit set?
	goto	ChkRb		; nope.
	bcf	mscFlag,LITZDT0 ; clear LITZ bit.
	movlw	VLITZ		; get LITZ message.
	call	PlayMsg		; play the LiTZ message.
	goto	ChkRb		; done here...

Main2				; receiver timedout state
	btfss	group0,0	; is repeater enabled?
	goto	Main2Off	; no.  turn receiver off
	btfsc	rxFlag,RX0OPEN	; is squelch still open?
	goto	ChkRb		; yes, still timed out
Main2Off			; end of timeout condition.
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rx0Stat		; set new receiver state
	btfsc	group3,2	; is voice timeout message enabled?
	goto	Main2TO		; yes...
	PAGE3			; select code page 3.
	call	PTTon		; turn on PTT
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkRb		; done here...
Main2TO 
	movlw	VTOUT		; time out message
	call	PlayMsg		; play the message
	goto	ChkRb		; seems redundant, but it ain't

ChkRb
	movlw	high RlTbl	; set high byte of address
	movwf	PCLATH		; select page
	movf	rx1Stat,w	; get link receiver state
	addwf	PCL,f		; add w to PCL:	 computed GOTO
RlTbl
	goto	RbRx0		; quiet
	goto	RbRx1		; repeat
	goto	RbRx2		; timeout

RbRx0				; receiver quiet state
	btfss	rxFlag,RX1OPEN	; is squelch open?
	goto	ChkTmrs		; nope, don't turn receiver on
	btfss	group0,0	; is repeater enabled?
	goto	ChkTmrs		; no.  don't allow link activity.
	movf	group5,w	; get group 6
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	ChkTmrs		; no...
	;; don't turn on link if patch is on and link disabled during patch.
	btfss	txFlag,PATCHON	; is patch on?
	goto	RbRx0a		; no.
	btfss	group5,3	; is link enabled during patch?
	goto	ChkTmrs		; no.

RbRx0a	
	btfss	group0,5	; is DTMF access mode enabled?
	goto	RbRx01		; no.
	movf	dtATmr,f	; check DTMF access mode timer.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkTmrs		; yes.	Don't turn receiver on.
	;; timer is not zero, reset to initial value.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	dtATmr		; set DTMF access mode timer.
	
RbRx01				; turn on remote base receiver.
	movlw	RXSON		; get new state #
	movwf	rx1Stat		; set new receiver state
	bsf	txFlag,RX1OPEN	; set link receiver on bit
	btfss	flags,RBMUTE	; is mute requested for some reason?
	bsf	outPort,RX1AUD	; no, unmute.
	btfss	group5,7	; is time out timer enabled?
	goto	ChkTmrs		; nope...
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETTMS		; EEPROM address of timeout timer long preset.
	btfsc	group1,1	; is short timeout selected
	movlw	EETTML		; EEPROM address of timeout timer short preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rx1TOut		; set timeout counter
	goto	ChkTmrs		; done here...

RbRx1				; receiver active state
	btfss	group0,0	; is repeater enabled?
	goto	RbRx1Off	; no.  turn off link receiver.
	movf	group5,w	; get group 5: link port configuration.
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	RbRx1Off	; yes.	turn off link receiver.
	
	btfss	rxFlag,RX1OPEN	; is squelch open?
	goto	RbRx1Off	; no, on->off transition
	btfss	tFlags,ONESEC	; one second tick?
	goto	ChkTmrs		; nope, continue
	movf	rx1TOut,f	; squelch still open, check timeout timer
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkTmrs		; timeout timer is zero, don't decrement
	decfsz	rx1TOut,f	; decrement the timeout timer
	goto	ChkTmrs		; have not timed out (yet), continue
	movlw	RXSTMO		; get new state, timed out
	movwf	rx1Stat		; set new receiver state
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	bcf	outPort,RX1AUD	; mute receiver 1
	clrf	rx1TOut		; clear receiver 1 timeout timer
	btfsc	group3,2	; is voice timeout message enabled?
	goto	RbRx1TO		; yes...
	PAGE3			; select code page 3.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkTmrs		; done here...
RbRx1TO 
	movlw	VTOUT		; time out message
	call	PlayMsg		; play the message
	goto	ChkTmrs		; done here...

RbRx1Off			; receiver was active, became inactive
	call	Rcv1Off		; turn off link receiver

	;; if link tx is on, and link is not a repeater, then 
	;; suppress link ctsy tone.
	btfss	outPort,TX1PTT	; is link tx on?
	goto	RbRx1o1		; nope.
	btfss	group3,3	; is link port in slave repeater mode?
	goto	RbRx1oh		; no, just hang, no ctsy tone.

RbRx1o1 
	;; receiver 2 courtesy tone
	movlw	CTRRBRX		; get eeprom address CT mask
	btfss	group5,2	; is rb tx enabled?
	goto	RbRx1oc		; no, set the tone & hang
	movlw	CTRRBTX		; yes, get that courtesy tone
	btfsc	group3,3	; is RB port a repeater?
	goto	RbRx1oc		; yes, set the tone & hang
	btfsc	txFlag,RX0OPEN	; is main receiver on bit set?
	goto	RbRx1oh		; yes, hang without a beep!

RbRx1oc
	movwf	cTone		; save the courtesy tone mask.

	btfss	mscFlag,LITZDT2 ; is LITZ bit set?
	goto	RbRx1oh		; nope.
	bcf	mscFlag,LITZDT2 ; clear LITZ bit.
	movlw	VLITZ		; get LITZ message.
	call	PlayMsg		; play the LiTZ message.
	
RbRx1oh
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now
	goto	ChkTmrs		; done here...

RbRx2				; receiver timedout state
	btfss	group0,0	; is repeater enabled?
	goto	RbRx2Off	; no.  turn off link receiver.
	movf	group5,w	; get group 6
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	RbRx2Off	; yes.	turn off link receiver.

	btfsc	rxFlag,RX1OPEN	; is squelch open?
	goto	ChkTmrs		; yes, still timed out
RbRx2Off	
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rx1Stat		; set new receiver state

	btfsc	group3,2	; is voice timeout message enabled?
	goto	RbRx2TO		; yes...
	PAGE3			; select code page 3.
	call	PTTon		; turn on PTT.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkTmrs		; done here...

RbRx2TO
	movlw	VTOUT		; time out message
	call	PlayMsg		; play the message


ChkTmrs				; check timers here.
	goto	Ck10mS		; skip one ms timer.
	;; start with one-millisecond timers
	btfss	tFlags,ONEMS	; is one-millisecond bit set?
	goto	Ck10mS		; nope.
	;; one-millisecond tick active.
	
Ck10mS				; check 10 millisecond timers
	btfss	tFlags,TENMS	; is ten-millisecond bit set?
	goto	Ck100mS		; nope.
	;; ten millisecond tick active.
	btfsc	PORTA,PHRING	; is the phone ringing?
	goto	NoRing		; no ring signal.
	;; there is a ring pulse detected.
	movf	ringDur,f	; check for zero...
	btfsc	STATUS,Z	; is it zero?
	goto	RingZer		; yes.
	movf	ringPul,f	; check ring pulse.
	btfsc	STATUS,Z	; skip if not zero.
	goto	NoRing		; it's zero.
	decfsz	ringPul,f	; decrement, skip if result is zero.
	goto	NoRing		; result is not zero.
	goto	GotRing		; result is zero.
	
RingZer				; ring just started.
	movlw	RNG_DUR		; get ring debounce duration.
	movwf	ringDur		; set ring debounce duration timer.
	movlw	RNG_PLS		; get ring pulse counter.
	movwf	ringPul		; set ring pulse counter.
	goto	RingEnd		; done here.

GotRing				; got a valid ring signal.
	movlw	RNG_TMO		; get ring timeout.
	movwf	ringTmr		; set ring timer.
	btfss	group4,7	; is phone auto-answer enabled?
	goto	RingAir		; nope.
	decfsz	ringCtr,f	; decrement ring counter.
	goto	RingAir		; not zero yet.
	;; going to pick up the phone now...
	;; reset ring counter for next time.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETRING		; get EEPROM address of ring counter.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select page 0.
	movwf	ringCtr		; preset ring counter.
	;; clear ring timeout timer.
	clrf	ringTmr		; clear ring counter timeout timer.
	;; now pick up the phone and say hello.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETPAT		; get EEPROM address of patch timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3
	call	ReadEEw		; read EEPROM.
	movwf	ptchTmr		; set autopatch timer.
	call	FoneUp		; pick up phone.
	movlw	VPHONE		; get word 'phone'.
	call	PutWord		; put word into buffer.
	movlw	VON		; get word 'on'.
	call	PutWord		; put word into buffer.
	call	PlaySpc		; send the words.
	PAGE0			; select code page 0.
	goto	RingEnd		; done.
	
RingAir
	btfss	group4,6	; ring out over air allowed?
	goto	RingEnd		; nope.
	PAGE3			; select code page 3.
	movlw	RNG_TON		; offset of ring tone in ROM table.
	call	PlayCTx		; play ct from table.
	PAGE0			; select code page 0.
	goto	RingEnd		; done here.

NoRing				; there is no ringing signal right now.
	movf	ringDur,f	; check for zero...
	btfsc	STATUS,Z	; skip if not zero.
	goto	RingEnd		; it's zero.
	decfsz	ringDur,f	; decrement it.	 skip if result is zero.
	goto	RingEnd		; result is not zero.
	clrf	ringPul		; clear ring pulse counter.
	
	;; done with ringer debounce for no ring sig detected.
RingEnd
	movf	pulsTmr,f	; check for pulsed output
	btfsc	STATUS,Z	; is it zero?
	goto	PulsEnd		; yep.
	decfsz	pulsTmr,f	; decrement and check for zero.
	goto	PulsEnd		; not zero yet.
	movf	group6,w	; get digout pulse control.
	andlw	h'0f'		; mask leaves low 4 bits.
	xorlw	h'ff'		; invert.
	btfsc	group6,D58PUL	; bits 5-8 also pulsed?
	andlw	h'0f'		; clear the high nibble
	andwf	group7,f	; update the port.
PulsEnd				; done with IO output pulse logic
	;; check for scan mode enabled.
	bsf	STATUS,RP0	; select register page 1.
	movf	scanTmr,f	; check this out.
	btfsc	STATUS,Z	; skip if non-zero.
	goto	NoScan		; it is zero.
	decfsz	scanTmr,f	; decrement.  skip if now zero.
	goto	NoScan		; it is not zero yet.
	movlw	CIVSCTM		; get new timer value.
	movwf	scanTmr		; preset the timer for next time.
	bcf	STATUS,RP0	; select register page 0.
	PAGE2			; select code page 2.
	call	ScanTun		; re-tune the radio.
	PAGE0			; select code page 0.
	goto	ScnTEnd		; done.
NoScan
	bcf	STATUS,RP0	; select register page 0.
ScnTEnd				; scan timer processing done.

Ck100mS				; check 100 millisecond tick.
	btfss	tFlags,HUNDMS	; is 100 millisecond bit set?
	goto	Ck1S		; nope.
	;; 100 millisecond tick active.
	;; check hang timer.
	movf	hangTmr,f	; check hang timer
	btfsc	STATUS,Z	; is it zero?
	goto	NoHang		; yes, not hang active, continue

	movf	hangTmr,w	; get hang timer
	subwf	hangDly,w	; w = hangDly - hangTmr(w) (amount hang used)
	sublw	d'05'		; subtract .5 seconds
	btfss	STATUS,Z	; skip if result is 0
	goto	HangNob		; not 0...don't beep.
	;; check to see if there is something already playing
	movf	txFlag,w	; get txFlag
	andlw	b'10110000'	; and txFlag with (CW or ISD or DTMF)
	btfsc	STATUS,Z	; is the result zero?
	goto	HangCT		; yes, ok to play CT.
	bsf	flags,DEF_CT	; set defer CT flag.
	goto	HangNob		; don't beep now.
	
	;;  bag the beep, CW, ISD or DTMF is playing.

	;; select courtesy tone here.
HangCT
	btfsc	txFlag,PATCHON	; is patch on?
	goto	HangNob		; patch is on, suppress CT
	incf	cTone,w		; check cTone for FF
	btfsc	STATUS,Z	; is result 0?
	goto	HangNob		; yes, cTone was FF.
	btfss	group0,6	; is courtesy tone enabled?
	goto	HangNob		; courtesy tone disabled.
	movlw	CTTUNE		; get tune mode courtesy tone.
	btfsc	tuneFlg,DT0TUNE ; is this port (main receiver) in tune mode?
	movwf	cTone		; yep. set tune mode courtesy tone.
	btfsc	tuneFlg,DT2TUNE ; is this port (link/control rx) in tune mode?
	movwf	cTone		; yep. set tune mode courtesy tone.
	movlw	CTUNLOK		; get unlocked mode courtesy tone.
	btfsc	dtRFlag,DT0UNLK ; is this port (main receiver) unlocked?
	movwf	cTone		; yep. set unlocked courtesy tone.
	btfsc	dtRFlag,DT2UNLK ; is this port (link/cntl rx) unlocked?
	movwf	cTone		; yep. set unlocked courtesy tone.

	PAGE3			; select code page 3.
	call	PlayCT		; play courtesy tone #w
	PAGE0			; select code page 0.

HangNob				; hanging without a beep
	decfsz	hangTmr,f	; decrement and check if now zero
	goto	NoHang		; not zero
	;; end of hang time.
	bcf	txFlag,TXHANG	; turn off hang time flag
	movf	txFlag,f	; check tXflag for zero.
	btfss	STATUS,Z	; is it zero?
	goto	NoHang		; no.  Don't touch hang timer.
	;; check tail message
	movf	tailCtr,f	; check.
	btfsc	STATUS,Z	; skip if tailCtr not zero.
	goto	NoHang		; tailCtr is zero.
	decfsz	tailCtr,f	; decrement tailCtr, skip if now zero.
	goto	NoHang		; not zero
	;; tail message time.
	call	DoTail		; play tail message.
	
NoHang				; done with hang timer...
	;; process DTMF muting timer...
	movf	muteTmr,f	; test mute timer
	btfsc	STATUS,Z	; Z is set if not DTMF muting
	goto	NoMutTm		; muteTmr is zero.
	decfsz	muteTmr,f	; decrement muteTmr
	goto	NoMutTm		; have not reached the end of the mute time
	btfsc	txFlag,RX0OPEN	; is receiver 0 unsquelched
	bsf	outPort,RX0AUD	; unmute it...

	btfss	txFlag,RX1OPEN	; is receiver 1 unsquelched
	goto	UnMutTx		; no.
	btfss	flags,RBMUTE	; is RB muted for some other reason?
	bsf	outPort,RX1AUD	; no, unmute it...
UnMutTx 
	btfsc	group6,6	; drop main receiver to mute enabled?
	bsf	outPort,TX0PTT	; turn on main receiver PTT!
	btfss	group1,4	; drop link to mute enabled?
	goto	NoMutTm		; no.
	btfss	group5,2	; link transmitter enabled?
	goto	NoMutTm		; nope.
	btfsc	txFlag,RX0OPEN	; is receiver 0 unsquelched
	bsf	outPort,TX1PTT	; yes. turn on link PTT.

NoMutTm				; done with muting timer...
	btfss	mscFlag,NNXIE	; is the NNX INIT bit set?
	goto	NoNNXi		; nope.
	;; set up base eeprom address.
	clrf	eeAddrL		; clear EEPROM address lo byte.
	swapf	nnxInit,w	; swap bytes of nnxInit into w
	andlw	b'00001111'	; mask out unused bits
	movwf	eeAddrH		; save EEPROM address hi byte base.
	rrf	eeAddrH,f	; rotate right
	btfsc	STATUS,C	; was the low bit set?
	bsf	eeAddrL,7	; yep.  add 0x80 to low byte of EEPROM addr.
	movlw	high EEAC00	; get high byte of EEPROM address.
	addwf	eeAddrH,f	; add to hi byte of EEPROM address.

	swapf	nnxInit,w	; swap nibbles in nnxInit into w.
	andlw	b'01110000'	; mask out all bits except address.
	addwf	eeAddrL,f	; add to eeprom address.
	movlw	d'16'		; count of bytes to write.
	movwf	temp		; save this.
	;; now check for 96-99.
	movf	nnxInit,w	; get nnxInit.
	andlw	b'00000111'	; mask out all but init address indicator bits.
	xorlw	b'00000110'	; check for 6
	btfss	STATUS,Z	; is it zero?
	goto	NNXi1		; nope.
	;; special for the last bank.
	movlw	d'4'		; count of bytes to write.
	movwf	temp		; save this.
	bcf	mscFlag,NNXIE	; will be done after this.
NNXi1
	movf	temp,w		; get number of bytes to write into eeprom.
	movwf	eeCount		; set number of bytes to write into eeprom.
	movlw	h'ff'		; initial value.
	btfss	nnxInit,NNXCB	; want ones?
	clrw			; nope.
	movwf	temp2		; save initial value.
	movlw	low eebuf00	; get base of buffer
	movwf	FSR		; set into FSR.
NNXiL
	movf	temp2,w		; get initial byte
	movwf	INDF		; save it into buffer.
	incf	FSR,f		; increment buffer pointer.
	decfsz	temp,f		; decrement number of bytes to write.
	goto	NNXiL		; not zero yet, go around again.
	movlw	low eebuf00	; get base of buffer
	movwf	FSR		; set into FSR.
	PAGE3			; select code page 3.
	call	WriteEE		; write EEPROM
	PAGE0			; select code page 0.
	incf	nnxInit,f	; move on to next page
	;; done for now.
NoNNXi
	movf	ringTmr,f	; test.
	btfsc	STATUS,Z	; is it zero?
	goto	NoRngTm		; yep.
	decfsz	ringTmr,f	; decrement.
	goto	NoRngTm		; not zero yet.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETRING		; get EEPROM address of ring counter.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select page 0.
	movwf	ringCtr		; preset ring counter.
NoRngTm
	;; check for deferred patch...
	btfss	flags,DEFFONE	; is the defered call wanted?
	goto	NoCall		; nope.
	movf	txFlag,w	; get txFlag.
	andlw	b'11110000'	; any reason to not dial?
	btfss	STATUS,Z	; skip if zero: no reason not to dial.
	goto	NoCall		; there is a reason not to dial.
	PAGE3			; select ROM page 3.
	call	DoPhone		; make the call.
	PAGE0			; select ROM page 0.
NoCall	
	btfss	flags,RBMUTE	; is the remote base muted for some reason?
	goto	NoRBMut		; nope.
	movf	txFlag,w	; get txFlag.
	andlw	b'11110001'	; any reason to keep muting?
	btfss	STATUS,Z	; skip if zero: ok to unmute.
	goto	NoRBMut		; don't unmute yet.
	bcf	flags,RBMUTE	; clear the RBMUTE flag.
	btfsc	group5,1	; in receive mode?
	goto	RBUnMut		; yep.
	btfss	group5,2	; in transmit mode?
	goto	NoRBMut		; nope.
RBUnMut 
	btfsc	txFlag,RX1OPEN	; skip if the RB receiver is not active.
	bsf	outPort,RX1AUD	; unmute the remote base.
NoRBMut				; done with remote base muting checks.
	
Ck1S				; check 1-second flag bit.
	btfss	tFlags,ONESEC	; is one-second flag bit set?
	goto	Ck10S		; nope.
	;; 1-second tick active.
	decfsz	ptchTmr,w	; quick-n-dirty test for 1.
	goto	NoP1Tmr		; was not 1.
	;; 10 or less seconds remain for patch.	 notify.
	PAGE3			; select code page 3.
	movlw	PATCBIP		; offset of patch bip in ROM table.
	call	PlayCTx		; play ct from table
	PAGE0			; select code page 0.
NoP1Tmr				; not 10 or less seconds less on patch.
	movf	unlkTmr,f	; check unlkTmr
	btfsc	STATUS,Z	; is it zero?
	goto	NoULTmr		; yes, don't worry about it.
	decfsz	unlkTmr,f	; no, decrement it.
	goto	NoULTmr		; still not zero.
	;; unlkTmr counted down to zero, lock controller.
	movlw	b'00011111'	; mask:	 clear unlocked bits.
	andwf	dtRFlag,f	; and with dtRFlag: clear unlocked bits.
	movlw	VCONTRL		; word "control"
	PAGE3			; select code page 3.
	call	PutWord		; put word into buffer
	movlw	VACCESS		; word "access"
	call	PutWord		; put word into buffer
	movlw	VDISABL		; word "disabled".
	call	PutWord		; put word into buffer.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PTTon		; turn on tx if not on already.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.

NoULTmr				; unlocked timer is zero.
	
Ck10S				; check 10-second tick flag bit.
	btfss	tFlags,TENSEC	; is ten-second flag bit set?
	goto	NoTimr		; nope.	 no more timers to test.
	movf	idTmr,f
	btfsc	STATUS,Z	; is idTmr 0
	goto	NoIDTmr		; yes...
	decfsz	idTmr,f		; decrement ID timer
	goto	NoIDTmr		; not zero yet...
	call	DoID		; id timer decremented to zero, play the ID
NoIDTmr				; process more 10 second timers here...
	movf	ptchTmr,f	; check patch timer.
	btfsc	STATUS,Z	; is it zero?
	goto	NoPtTmr		; yes
	decfsz	ptchTmr,f	; decrement patch timer
	goto	NoPtTmr		; not zero yet.
	PAGE3			; select code page 1.
	call	FoneOff		; turn off patch!
	movlw	VCALL		; word "call".
	call	PutWord		; put word into buffer
	movlw	VCOMPLT		; word "complete".
	call	PutWord		; put word into buffer
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set output port so message is heard
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
NoPtTmr 
	movf	fanTmr,f	; check fan timer
	btfsc	STATUS,Z	; is it zero?
	goto	NoFanTm		; yes.
	btfss	group3,4	; fan mode configured?
	goto	NoFanTm		; no
	decfsz	fanTmr,f	; decrement fan timer
	goto	NoFanTm		; not zero yet
	bcf	outPort,FANCTL	; turn off fan
NoFanTm
	movf	dtATmr,f	; check DTMF access timer.
	btfsc	STATUS,Z	; is it zero?
	goto	NoDTATm		; yes
	decfsz	dtATmr,f	; decrement DTMF access timer
	goto	NoDTATm		; not zero yet.
	;; dtmf access mode timer has counted down to 0.
	;; make sure remote base is diabled here.
	btfss	group0,5	; is DTMF access mode enabled?
	goto	NoDTATm		; DTMF access mode is not enabled.
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	outPort,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	clrf	rx1TOut		; clear link receiver timeout timer
	bcf	outPort,TX1PTT	; turn off link transmitter.
	;; v 1.14 change - turn off tune mode here
	clrf	tuneFlg		; turn off tune mode
	;; end v 1.14 change
		
	movlw	VREPEAT		; word "repeater".
	PAGE3			; select code page 3.
	call	PutWord		; put word into buffer
	movlw	VACCESS		; word "access".
	call	PutWord		; put word into buffer
	movlw	VDISABL		; word "disabled".
	call	PutWord		; put word into buffer
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set output port so message is heard
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
NoDTATm

	movf	rbTmr,f		; check remote-base activity timer.
	btfsc	STATUS,Z	; is it zero?
	goto	NoRBTmr		; yes
	decfsz	rbTmr,f		; decrement remote-base activity timer
	goto	NoRBTmr		; not zero yet.
	;; remote base auto-shutoff timer has timed out.
	PAGE1			; select code page 1.
	call	RBOff		; turn off remote base
	PAGE0			; select code page 0
NoRBTmr				; the remote base timer is not running.
		
NoTimr				; no more timers to test.
	

ChkTx				; check if transmitter should be on
	movf	txFlag,f	; check txFlag
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkTx0		; it's zero, turn off transmitter
	btfsc	flags,TXONFLG	; skip if not already on
	goto	ChkTxE		; done here
	PAGE3			; select code page 1.
	call	PTTon		; turn on transmitter (will set TXONFLG)
	PAGE0			; select code page 0.
	goto	ChkTxE		; OK, done here.
ChkTx0
	btfss	flags,TXONFLG	; skip if tx is on
	goto	ChkTxE		; was already off
	PAGE3			; select code page 1.
	call	PTToff		; turn off PTT
	PAGE0			; select code page 0.
ChkTxE				; end of ChkTx

; ***************
; ** CW SENDER ** 
; ***************
CWSendr
	btfss	txFlag,CWPLAY	; sending CW?
	goto	NoCW		; nope

	btfss	tFlags,ONEMS	; is this a one-ms tick?
	goto	NoCW		; nope.

	decfsz	cwTbTmr,f	; decrement CW timebase counter
	goto	NoCW		; not zero yet.

	movlw	CWTBDLY		; get cw timebase preset.
	movwf	cwTbTmr		; preset CW timebase.

	decfsz	cwTmr,f		; decrement CW element timer
	goto	NoCW		; not zero

	btfss	tFlags,CWBEEP	; was "key" down? 
	goto	CWKeyUp		; nope
				; key was down
	bcf	tFlags,CWBEEP	; key->up
	clrf	PORTD		; write quiet beep tone info to port
	bsf	PORTB,TONESEL	; set PDC3311 STROBE high
	nop			; short delay (PDC3311 requires 400 ns here)
	bcf	PORTB,TONESEL	; set PDC3311 STROBE low (should be 500 ns pulse)
	decf	cwByte,w	; test CW byte to see if 1
	btfsc	STATUS,Z	; was it 1 (Z set if cwByte == 1)
	goto	CWNext		; it was 1...
	movlw	CWIESP		; get cw inter-element space
	movwf	cwTmr		; preset cw timer
	goto	NoCW		; done with this pass...

CWNext				; get next character of message
	PAGE3			; select code page 1.
	call	GtBeep		; get the next cw character
	PAGE0			; select code page 0.
	movwf	cwByte		; store character bitmap
	btfsc	STATUS,Z	; is this a space (zero)
	goto	CWWord		; yes, it is 00
	incf	cwByte,w	; check to see if it is FF
	btfsc	STATUS,Z	; if this bitmap was FF then Z will be set
	goto	CWDone		; yes, it is FF
	movlw	CWILSP		; no, not 00 or FF, inter letter space
	movwf	cwTmr		; preset cw timer
	goto	NoCW		; done with this pass...

CWWord				; word space
	movlw	CWIWSP		; get word space
	movwf	cwTmr		; preset cw timer
	goto	NoCW		; done with this pass...

CWKeyUp				; key was up, key again...
	incf	cwByte,w	; is cwByte == ff?
	btfsc	STATUS,Z	; Z is set if cwByte == ff
	goto	CWDone		; got EOM

	movf	cwByte,f	; check for zero/word space
	btfss	STATUS,Z	; is it zero
	goto	CWTest		; no...
	goto	CWNext		; is 00, word space...

CWTest
	movlw	CWDIT		; get dit length
	btfsc	cwByte,0	; check low bit
	movlw	CWDAH		; get DAH length
	movwf	cwTmr		; preset cw timer
	bsf	tFlags,CWBEEP	; turn key->down
	movlw	h'39'		; C6 tone for CW.
	movwf	PORTD		; write beep tone info to port
	bsf	PORTB,TONESEL	; set PDC3311 STROBE high
	nop			; short delay (PDC3311 requires 400 ns here)
	bcf	PORTB,TONESEL	; set PDC3311 STROBE low (should be 500 ns pulse)
	rrf	cwByte,f	; rotate cw bitmap
	bcf	cwByte,7	; clear the MSB
	goto	NoCW		; done with this pass...

CWDone				; done sending CW
	bcf	txFlag,CWPLAY	; turn off CW flag
	btfss	beepCtl,B_MAIN	; did beep turn on audio gate?
	goto	CWDone1		; no.
	btfss	txFlag,TALKING	; don't turn off audio gate if talking.
	bcf	outPort,BEEPAUD ; turn off audio gate
CWDone1
	clrf	beepCtl		; clear beep control flags

NoCW
CasEnd
CkTone
	btfss	tFlags,HUNDMS	; check the DTMF timers every 100 msec.
	goto	TonDone		; not 100 MS tick.
CkDt0	
	movf	dt0Tmr,f	; check for zero...
	btfsc	STATUS,Z	; is it zero
	goto	CkDt1		; yes
	decfsz	dt0Tmr,f	; decrement timer
	goto	CkDt1		; not zero yet
	bsf	dtRFlag,DT0RDY	; ready to evaluate command.
CkDt1
	movf	dt1Tmr,f	; check for zero...
	btfsc	STATUS,Z	; is it zero
	goto	CkDt2		; yes
	decfsz	dt1Tmr,f	; decrement timer
	goto	CkDt2		; not zero yet
	bsf	dtRFlag,DT1RDY	; ready to evaluate command.
CkDt2
	movf	dt2Tmr,f	; check for zero...
	btfsc	STATUS,Z	; is it zero
	goto	TonDone		; yes
	decfsz	dt2Tmr,f	; decrement timer
	goto	TonDone		; not zero yet
	bsf	dtRFlag,DT2RDY	; ready to evaluate command.
TonDone
	;; manage beep timer 
	btfss	tFlags,TENMS	; is this a 10 ms tick?
	goto	NoTime		; nope.
	movf	beepTmr,f	; check beep timer
	btfsc	STATUS,Z	; is it zero?
	goto	NBeep		; yes.
BeepTic				; a valid beep tick.
	decfsz	beepTmr,f	; decrement beepTmr
	goto	NoTime		; not zero yet.
	PAGE3			; select code page 3.
	call	GetBeep		; get the next beep tone...
	PAGE0			; select code page 0.
	goto	NoTime		; done here.
NBeep				; verify that beeping is really over. HACK.
	movf	cwTmr,f		; check cwTmr.
	btfss	STATUS,Z	; is it zero?
	goto	NoTime		; no.
	movf	beepCtl,f	; check this.
	btfsc	STATUS,Z	; is it zero?
	goto	NoTime		; yes.
	PAGE3			; select code page 3.
	call	GetBeep		; get the next beep tone...
	PAGE0			; select code page 0.

NoTime
	movf	tFlags,f	; evaluate tFlags
	btfss	STATUS,Z	; skip if ZERO
	goto	LoopEnd
	;; no timing flags were set...
	;; likely some excess, available CPU cycles here.
	;; evaluate DTMF buffers...
PfxDT0
	;; evaluate DTMF 0 buffer for command
	btfsc	dtRFlag,DTSEVAL ; is a command being interpreted now?
	goto	DTEval		; yes, don't bother looking at the DTMF buffers right now
	btfss	dtRFlag,DT0RDY	; is a command ready to evaluate?
	goto	PfxDT1		; no command waiting.
	;; copy command from dtmf rx buf to command interpreter input buffer.
	movlw	low dt0buf0	; get address of this dtmf receiver's buffer
	movwf	FSR		; store.
	movf	dt0Ptr,w	; get command size...
	movwf	cmdSize		; save it.
	PAGE1			; select code page 1.
	call	CpyDTMF		; copy the command...
	PAGE0			; select code page 0.
	movf	dt0Ptr,w	; get command size back, CpyDTMF clobbers.
	movwf	cmdSize		; save it.
	clrf	dt0Ptr		; make ready to receive again.
	clrf	dtEFlag		; start evaluating from first prefix.
	bsf	dtEFlag,DT0CMD	; command from DTMF-0.
	bsf	dtRFlag,DTSEVAL ; set evaluate DTMF bit.
	btfsc	dtRFlag,DT0UNLK ; port 0 unlocked?
	bsf	dtRFlag,DTUL	; this port is unlocked.
	btfsc	tuneFlg,DT0TUNE ; is this port in tune mode?
	bsf	tuneFlg,DTTUNE	; set tune bit.
	bcf	dtRFlag,DT0RDY	; reset DTMF ready bit.
	bsf	outPort,BEEPAUD ; got cmd from main rx -- turn on audio gate
	goto	DTEval		; go and evaluate the command right now.

PfxDT1
	;; evaluate DTMF command from decoder 1 here.
	btfss	dtRFlag,DT1RDY	; is a command ready to evaluate?
	goto	PfxDT2		; no command waiting.
	;; copy command from dtmf rx buf to command interpreter input buffer.
	movlw	low dt1buf0	; get address of this dtmf receiver's buffer
	movwf	FSR		; store.
	movf	dt1Ptr,w	; get command size...
	movwf	cmdSize		; save it.
	PAGE1			; select code page 1.
	call	CpyDTMF		; copy the command...
	PAGE0			; select code page 0.
	movf	dt1Ptr,w	; get command size back, CpyDTMF clobbers.
	movwf	cmdSize		; save it.
	clrf	dt1Ptr		; make ready to receive again.
	clrf	dtEFlag		; start evaluating from first prefix.
	bsf	dtEFlag,DT1CMD	; command from DTMF-1.
	bsf	dtRFlag,DTSEVAL ; set evaluate DTMF bit.
	btfsc	dtRFlag,DT1UNLK ; port 1 unlocked?
	bsf	dtRFlag,DTUL	; this port is unlocked.
	btfsc	tuneFlg,DT1TUNE ; is this port in tune mode?
	bsf	tuneFlg,DTTUNE	; set tune bit.
	bcf	dtRFlag,DT1RDY	; reset DTMF ready bit.
	goto	DTEval		; go and evaluate the command right now.

PfxDT2
	;; evaluate DTMF command from decoder 1 here.
	btfss	dtRFlag,DT2RDY	; is a command ready to evaluate?
	goto	XPfxDT		; no command waiting.
	;; copy command from dtmf rx buf to command interpreter input buffer.
	movlw	low dt2buf0	; get address of this dtmf receiver's buffer
	movwf	FSR		; store.
	movf	dt2Ptr,w	; get command size...
	movwf	cmdSize		; save it.
	PAGE1			; select code page 1.
	call	CpyDTMF		; copy the command...
	PAGE0			; select code page 0.
	movf	dt2Ptr,w	; get command size back, CpyDTMF clobbers.
	movwf	cmdSize		; save it.
	clrf	dt2Ptr		; make ready to receive again.
	clrf	dtEFlag		; start evaluating from first prefix.
	bsf	dtEFlag,DT2CMD	; command from DTMF-2.
	bsf	dtRFlag,DTSEVAL ; set evaluate DTMF bit.
	btfsc	dtRFlag,DT2UNLK ; port 2 unlocked?
	bsf	dtRFlag,DTUL	; this port is unlocked.
	btfsc	tuneFlg,DT2TUNE ; is this port in tune mode?
	bsf	tuneFlg,DTTUNE	; set tune bit.
	bcf	dtRFlag,DT2RDY	; reset DTMF ready bit.
	bsf	outPort,BEEPAUD ; got cmd from ctl/link rx--turn on audio gate.
	goto	DTEval		; go and evaluate the command right now.

XPfxDT
	goto	LoopEnd
	
DTEval				; evaluate DTMF command in command buffer
	btfsc	tuneFlg,DTTUNE	; is this command from a port in tune mode?
	goto	DTEvalT		; yep.
	
	btfsc	dtRFlag,DTUL	; is this command from an unlocked port?
	goto	DTEvalU		; yep.

	;; evaluate the command in the buffer against the contents of eeprom.
	movlw	low cmdbf00	; get command buffer address
	movwf	FSR		; set pointer
	movf	dtEFlag,w	; get dtEFlag.
	andlw	b'00011111'	; mask out control bits.
	movwf	temp		; set prefix index.
	movlw	EEPFL		; max number of digits in prefix.
	movwf	temp2		; save max number of digits to look at.
	clrf	eeAddrH		; clear EEPROM address hi byte.
	movf	temp,w		; get prefix index.
	movwf	eeAddrL		; set EEPROM address low byte
	bcf	STATUS,C	; clear carry bit
	rlf	eeAddrL,f	; rotate (x2)
	rlf	eeAddrL,f	; rotate (x4 this time)
	rlf	eeAddrL,f	; rotate (x8 now)
	movlw	EEPFB		; get EEPROM base address for prefix 0
	addwf	eeAddrL,f	; add to offset.
	;; now have address of base of selected prefix.
DTEval1
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	temp3		; save retrieved byte
	sublw	h'ff'		; subtract FF.
	btfsc	STATUS,Z	; skip if temp3 was NOT FF.
	goto	DTEvalY		; value was FF, end of valid prefix. process.
	movf	temp3,w		; get back real value for retrieved byte.
	subwf	INDF,w		; subtract bytes.
	btfss	STATUS,Z	; skip if they were the same.
	goto	DTEvalN		; them bytes were not equal.
	decfsz	temp2,f		; decrease number of bytes to scan
	goto	DTEnext		; go evaluate next byte.
	goto	DTEvalN		; go on to next prefix.
DTEnext				; evaluate next byte.
	incf	eeAddrL,f	; move to the next EEPROM byte.
	incf	FSR,f		; move to the next cmdbuf byte.
	goto	DTEval1		; look at the next prefix
	
DTEvalN				; was not this prefix.
	incf	dtEFlag,f	; move to next prefix
	movf	dtEFlag,w	; get dtEFlag.
	andlw	b'00011111'	; mask out control bits.
	sublw	EEPFC		; subtract number of last prefix.
	btfsc	STATUS,Z	; is result 0? (all prefixes checked)
	goto	DTEdone		; it's zero, done evaluating.
	goto	LoopEnd		; continue.

DTEvalY				; HEY! it is this prefix!
	;; temp has the prefix number.
	;; EEPFL - temp2 is the index of the first byte after the prefix.
	movf	temp2,w		; get temp2 value.
	sublw	EEPFL		; w = EEPFL - w
	subwf	cmdSize,f	; get corrected cmdSize
	;; cmdSize has the number of bytes left in the command.
	PAGE1			; select code page 1.
	call	LCmd		; process the locked command
	PAGE0			; select code page 0.
	goto	DTEdone		; done evaluating.
	
DTEvalU				; evaluate unlocked DTMF command.
	PAGE2			; select code page 2.
	call	UlCmd		; evaluate the unlocked command.
	PAGE0			; select code page 0.
	goto	DTEdone		; done evaluating.

DTEvalT				; evaluate unlocked DTMF command.
	PAGE2			; select code page 2.
	call	TuneCmd		; evaluate the fine-tune command.
	movlw	CTTUNE		; get tune courtesy tone.
	movwf	cTone		; set courtesy tone.
	PAGE0			; select code page 0.

DTEdone				; done evaluating DTMF commands.
	clrf	dtEFlag		; yes.	reset evaluate DTMF flags.
	bcf	dtRFlag,DTSEVAL ; done evaluating.
	bcf	dtRFlag,DTUL	; so we don't care about unlocked anymore.
	bcf	tuneFlg,DTTUNE	; clear the tune mode flag.
	
LoopEnd
	;; always update the output latch here.
	;; maybe add logic later to only update it when different.

	btfss	mscFlag,CIV_RDY ; is there a CI-V message waiting?
	goto	FanCtl		; nope.
	PAGE3			; select ROM code page 2.
	call	ChkCIV		; yep.
	PAGE0			; select ROM code page 0.

FanCtl
	;; fan/control output control.
	btfsc	group3,4	; is fan control enabled?
	goto	LoopE1		; yes.
	btfsc	group3,5	; is digital output on?
	bsf	outPort,FANCTL	; yes, turn on control output.
	btfss	group3,5	; is digital output off?
	bcf	outPort,FANCTL	; yes, turn off control output.
LoopE1	
	;; end of loop here.
	;; always update the output latch here.
	movf	outPort,w	; get outport value
	movwf	PORTD		; copy to port
	bsf	PORTC,OUTSEL	; raise output port enable
	nop			; short delay
	bcf	PORTC,OUTSEL	; lower output port enable
	movf	group7,w	; get digital output value
	btfsc	group8,5	; is debug mode turned on?
	movf	txFlag,w	; yes. copy txFlag to output LEDs
	movwf	PORTD		; copy to port
	bsf	PORTA,EXPSEL	; raise digital output port enable
	nop			; short delay
	bcf	PORTA,EXPSEL	; lower digital output port enable
	goto	Loop0
		      
; ************************************************************************
; ****************************** ROM PAGE 1 ******************************
; ************************************************************************
	org	0800		; page 1

LCmd
	btfss	group0,5	; is DTMF access mode enabled?
	goto	LCmdS		; no,  process command.
	movf	temp,w		; get prefix index number.
	sublw	d'6'		; subtract DTMF access prefix.
	btfsc	STATUS,Z	; is it the DTMF access prefix?
	goto	LCmdS		; yes.  process command.
	movf	dtATmr,f	; get the DTMF access mode timer.
	btfsc	STATUS,Z	; is it zero?
	return			; yes. do nothing quietly.
	
LCmdS
	movlw	high LTable	; set high byte of address
	movwf	PCLATH		; select page
	movf	temp,w		; get prefix index number.
	andlw	h'0f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL

LTable				; jump table for locked commands.
	goto	LCmd0		; prefix 00 -- control operator
	goto	LCmd1		; prefix 01 -- autopatch
	goto	LCmd2		; prefix 02 -- unresricted autopatch
	goto	LCmd3		; prefix 03 -- autodial
	goto	LCmd4		; prefix 04 -- emergency autodial
	goto	LCmd5		; prefix 05 -- patch hang up code
	goto	LCmd6		; prefix 06 -- dtmf access
	goto	LCmd7		; prefix 07 -- pass dtmf
	goto	LCmd8		; prefix 08 -- dtmf test
	goto	LCmd9		; prefix 09 -- reverse patch
	goto	LCmdA		; prefix 10 -- audio check
	goto	LCmdB		; prefix 11 -- mailbox & audio check
	goto	LCmdC		; prefix 12 -- remote base
	goto	LCmdD		; prefix 13 -- (reserved)
	goto	LCmdE		; prefix 14 -- load saved state.
	goto	LCmdF		; prefix 15 -- unlock controller.

; ***********
; ** LCmd0 **
; ***********
LCmd0				; control operator switches
	btfss	group0,7	; CTCSS required?
	goto	LCmd0x		; no.
	btfss	dtEFlag,DT0CMD	; did the command come from the main receiver?
	goto	LCmd0c1		; no.
	btfss	mscFlag,CTCSS0	; was CTCSS on?
	return			; do nothing quietly.

LCmd0c1 
	btfss	dtEFlag,DT2CMD	; did the command come from the control RX?
	goto	LCmd0x		; no. must be the phone. process it.
	btfss	group1,7	; is the control receiver on the link port?
	goto	LCmd0x		; no, process it.
	btfss	mscFlag,CTCSS2	; was CTCSS on?
	return			; do nothing quietly.
LCmd0x				; actually do it.
	movlw	d'2'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 2)
	return			; not enough command digits. fail quietly.
	movf	cmdSize,w	; get command size
	sublw	d'3'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 3)
	return			; too many command digits. Fail quietly.

	movf	INDF,w		; get Group byte
	movwf	temp2		; save group byte.
	sublw	d'7'		; w = 7-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; bad, bad user tried to enter invalid group.
	;; check access to change that group.
	movf	temp2,w		; get group number 0-7.
	PAGE3
	call	GetMask		; get bitmask for that group.
	PAGE1
	;; now have bit representing group number in w.
	andwf	group9,w	; and with enabled groups mask.
	btfsc	STATUS,Z	; zero if group is disabled.
	return			; quietly do nothing.
	incf	FSR,f		; move to next byte (bit #)
	decf	cmdSize,f	; decrement command size.
	movf	INDF,w		; get Item byte (bit #)
	movwf	temp		; save it.
	incf	FSR,f		; move to next byte (state)
	decf	cmdSize,f	; decrement command size.

	sublw	d'7'		; w = 7-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; bad, bad user tried to enter invalid item.
	PAGE2			; select code page 2.
	goto	CtlOpC		; execute control op command

; ***********
; ** LCmd1 **
; ***********
LCmd1				; autopatch
	btfss	group4,0	; is autopatch enabled?
	return			; no.  quietly do nothing.
	btfss	group1,5	; CTCSS required?
	goto	LCmd1x		; no.
	btfss	dtEFlag,DT0CMD	; did the command come from the main receiver?
	goto	LCmd1c1		; no.
	btfss	mscFlag,CTCSS0	; was CTCSS on?
	return			; do nothing quietly.
LCmd1c1 
	btfss	dtEFlag,DT2CMD	; did the command come from the control RX?
	goto	LCmd1x		; no. must be the phone. process it.
	btfss	group1,7	; is the control receiver on the link port?
	goto	LCmd1x		; no, process it.
	btfss	mscFlag,CTCSS2	; was CTCSS on?
	return			; do nothing quietly.
LCmd1x
	movf	cmdSize,f	; get command size.
	btfss	STATUS,Z	; is it zero?
	goto	LCmd1z		; no.
	;; zero, extend patch timer.
	btfss	txFlag,PATCHON	; is patch active?
	return			; no.  quietly do nothing.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETPAT		; get EEPROM address of patch timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	movwf	ptchTmr		; set autopatch timer.
	return			; done.
	
LCmd1z	
	movf	FSR,w		; get pointer to digits to send.
	movwf	temp4		; save FSR for later.
	movf	cmdSize,w	; get command size...
	sublw	d'7'		; subtract from 7.
	btfsc	STATUS,Z	; is result 0?
	goto	LCmd17		; 7 digit dialing
	movf	cmdSize,w	; get command size...
	sublw	d'8'		; subtract from 8.
	btfsc	STATUS,Z	; is result 0?
	goto	LCmd18		; 8 digit dialing ("1" + 7 digits)
	movf	cmdSize,w	; get command size...
	sublw	d'10'		; subtract from 10.
	btfsc	STATUS,Z	; is result 0?
	goto	LCmd1A		; 10 digit dialing (area code + 7 digits)
	movf	cmdSize,w	; get command size...
	sublw	d'11'		; subtract from 11.
	btfsc	STATUS,Z	; is result 0?
	goto	LCmd1B		; 11 digit dialing (1 + area code + 7 digits)
	return			; not 7, 8, 10, or 11; quietly do nothing.

LCmd17				; 7 digit phone number entered.
	movlw	high EEACSFL	; get address of last AC flags.
	movwf	eeAddrH		; save EEPROM address hi byte base.
	movlw	low EEACSFL	; get address of last AC flags.
	movwf	eeAddrL		; save EEPROM address low byte base.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	movwf	temp6		; save configuration byte.
	btfss	temp6,ACENAB	; is this area code enabled?
	goto	LCmd1Bad	; nope.
	btfss	temp6,ACNONE	; is area code not specified?
	goto	LCmd1Bad	; nope.
	btfsc	temp6,AC1REQ	; is one NOT required?
	goto	LCmd1Bad	; nope.
	goto	LCmd18a		; yes.	continue.
	
LCmd18				; 8 digit phone number entered.
	movlw	high EEACSFL	; get address of last AC flags.
	movwf	eeAddrH		; save EEPROM address hi byte base.
	movlw	low EEACSFL	; get address of last AC flags.
	movwf	eeAddrL		; save EEPROM address low byte base.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	movwf	temp6		; save configuration byte.
	btfss	temp6,ACENAB	; is this area code enabled?
	goto	LCmd1Bad	; nope.
	btfss	temp6,ACNONE	; is area code not specified?
	goto	LCmd1Bad	; nope.
	btfss	temp6,AC1OK	; is one allowed?
	goto	LCmd1Bad	; nope.
	movf	INDF,w		; get 1st digit.
	sublw	d'1'		; subtract from 1.
	btfss	STATUS,Z	; was result 0?
	goto	LCmd1Bad	; nope.
	incf	FSR,f		; move past digit 1.
LCmd18a
	movlw	EELSTAC		; get last area code number
	movwf	temp		; ChkNNX wants the area code index in temp.
	PAGE3			; select code page 3.
	call	ChkNNX		; check NNX.
	PAGE1			; select code page 1.
	btfsc	STATUS,Z	; valid NNX?
	goto	LCmd1Bad	; nope.
	btfss	temp6,ACPFX	; is prefix required?
	goto	LCmd1NP		; make the call, no prefix...
	
	movlw	high EEACSPF	; get address of special area code prefix
	movwf	eeAddrH		; save EEPROM address hi byte base.
	movlw	low EEACSPF	; get address of special area code prefix
	movwf	eeAddrL		; save EEPROM address low byte base.
	goto	LCmd1DP		; dial with prefix.
	
LCmd1A				; 10 digit phone number entered.
	PAGE3			; select code page 3.
	call	GetAC		; get area code.
	PAGE1			; select code page 1.
	movwf	temp		; save index.  will be mashed by ChkNNX.
	movwf	temp5		; save index again.
	andlw	EEACMSK		; mask of invalid bits.
	btfss	STATUS,Z	; is result zero?
	goto	LCmd1Bad	; yes, invalid area code...
	movf	temp,w		; get back area code index.

	PAGE3			; select code page 3.
	call	ChkNNX		; check NNX.
	PAGE1			; select code page 1.
	btfsc	STATUS,Z	; valid NNX?
	goto	LCmd1Bad	; nope.
	
	clrf	eeAddrL		; clear EEPROM address lo byte.
	movf	temp5,w		; get temp5 (AC index)
	movwf	eeAddrH		; save EEPROM address hi byte base.
	rrf	eeAddrH,f	; rotate right
	btfsc	STATUS,C	; was the low bit set?
	bsf	eeAddrL,7	; yep.  add 0x80 to low byte of EEPROM addr.
	movlw	high EEAC00	; get high byte of EEPROM address.
	addwf	eeAddrH,f	; add to hi byte of EEPROM address.
	;; now have eeprom base address for area code of index temp5.
	;; get the flags to see if this area code is enabled.
	movlw	EEAFOFF		; get area code flags offset.
	addwf	eeAddrL,f	; add to eeprom address.
	PAGE3			; select code page 3.
	call	ReadEEw		; read the area code config bits.
	PAGE1			; select code page 1.
	movwf	temp6		; save area code config bits in temp.

	btfsc	temp6,AC1REQ	; is a leading 1 was required? (didn't get it.)
	goto	LCmd1Bad	; error.  did not get leading 1.
	
	btfss	temp6,ACPFX	; is prefix required?
	goto	LCmd1NP		; make the call, no prefix...
	incf	eeAddrL,f	; get address of prefix, it's after flags.
	goto	LCmd1DP		; make the call, with the prefix.

LCmd1B				; 11 digit phone number entered.
	movf	INDF,w		; get first digit...
	sublw	d'1'		; subtract from 1.
	btfss	STATUS,Z	; was result 0?
	goto	LCmd1Bad	; nope.
	incf	FSR,f		; move past digit 1.
	PAGE3			; select code page 3.
	call	GetAC		; get area code.
	PAGE1			; select code page 1.
	movwf	temp		; save index.  will be mashed by ChkNNX.
	movwf	temp5		; save index again.
	andlw	EEACMSK		; mask of invalid bits.
	btfss	STATUS,Z	; is result zero?
	goto	LCmd1Bad	; yes, invalid area code...
	movf	temp,w		; get back area code index.
	PAGE3			; select code page 3.
	call	ChkNNX		; check NNX.
	PAGE1			; select code page 1.
	btfsc	STATUS,Z	; valid NNX?
	goto	LCmd1Bad	; nope.
      
	clrf	eeAddrL		; clear EEPROM address lo byte.
	movf	temp5,w		; get temp5 (AC index)
	movwf	eeAddrH		; save EEPROM address hi byte base.
	rrf	eeAddrH,f	; rotate right
	btfsc	STATUS,C	; was the low bit set?
	bsf	eeAddrL,7	; yep.  add 0x80 to low byte of EEPROM addr.
	movlw	high EEAC00	; get high byte of EEPROM address.
	addwf	eeAddrH,f	; add to hi byte of EEPROM address.
	;; now have eeprom base address for area code of index temp2.
	;; get the flags to see if this area code is enabled.
	movlw	EEAFOFF		; get area code flags offset.
	addwf	eeAddrL,f	; add to eeprom address.
	PAGE3			; select code page 3.
	call	ReadEEw		; read the area code config bits.
	PAGE1			; select code page 1.
	movwf	temp6		; save area code config bits in temp.

	btfss	temp6,AC1OK	; is a leading 1 was allowed?  (got one)
	goto	LCmd1Bad	; error.  did not get leading 1.
	
	btfss	temp6,ACPFX	; is prefix required?
	goto	LCmd1NP		; make the call, no prefix...
	incf	eeAddrL,f	; get address of prefix, it's after flags.
	goto	LCmd1DP		; make the call, with the prefix.

LCmd1NP				; valid phone number. No Prefix required.
	movf	temp4,w		; get back base FSR (phone num address)
	movwf	FSR		; put back base FSR.
	PAGE3			; select ROM page 3
	call	CpyFone		; copy fone digits.
	PAGE1			; select ROM page 1
	goto	LCmd2Ca		; make the call.

LCmd1DP				; valid phone number. No Prefix required.
	movf	temp4,w		; get back base FSR (phone num address)
	movwf	FSR		; put back base FSR.
	PAGE3			; select ROM page 3
	call	CpyPref		; copy fone digits.
	PAGE1			; select ROM page 1
	goto	LCmd2Ca		; make the call.

LCmd1Bad			; bad phone number.
	PAGE3			; select code page 3.
	movlw	VBAD		; get word "BAD".
	call	PutWord		; put word into buffer
	movlw	VPHONE		; get word "PHONE".
	call	PutWord		; put word into buffer
	movlw	VNUMBER		; get word "NUMBER".
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmd2 **
; ***********
LCmd2				; unrestricted autopatch
	btfss	group4,1	; is unrestricted autopatch enabled?
	return			; no.  quietly do nothing.
	movf	cmdSize,f	; check cmdSize, no sense if zero length.
	btfss	STATUS,Z	; is it zero?
	goto	LCmd2C		; no.  continue with starting new call.
	btfss	txFlag,PATCHON	; is patch active?
	return			; no.  quietly do nothing.
	;; extend the patch timer.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETPAT		; get EEPROM address of patch timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	movwf	ptchTmr		; set autopatch timer.
	return			; done.
LCmd2C				; make the call.
	PAGE3			; select ROM page 3
	call	CpyFone		; copy fone digits.
	PAGE1			; select ROM page 1

LCmd2Ca				; make the call, alternate entry point.
	bsf	flags,DEFFONE	; set deferred fone call.
	
	;; this is where the announce could be suppressed with a return.
	
	PAGE3			; select code page 3.
	movlw	VAUTOP		; get word "AUTOPATCH".
	call	PutWord		; put word into buffer
	PAGE1			; select code page 1.
	btfsc	group6,7	; is the phone number readback suppressed?
	goto	LCmd2Lc		; yes, don't say the phone number.
LCmd2L				; say phone number loop.
	movf	INDF,w		; get digit.
	PAGE3			; select page 3
	call	HexWord		; get word for digit.
	call	PutWord		; put word for digit.
	PAGE1			; select page 1
	incf	FSR,f		; increment command digit pointer.
	decfsz	cmdSize,f	; decrease digits remaining.
	goto	LCmd2L		; go again and do another digit.
LCmd2Lc
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return			; done here,

; ***********
; ** LCmd3 **
; ***********
LCmd3				; autodial
	btfss	group4,2	; is autodial enabled?
	return			; no. quietly do nothing.

	movf	cmdSize,f	; check cmdSize, no sense if zero length.
	btfss	STATUS,Z	; is it zero?
	goto	LCmd3nz		; no.  continue with starting new call.
	btfss	txFlag,PATCHON	; is patch active?
	return			; no.  quietly do nothing.
	;; extend the patch timer.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETAD		; get EEPROM address of autodial timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	movwf	ptchTmr		; set autopatch timer.
	return			; done.
		
LCmd3nz				; not zero command length.
	PAGE3			; select page 3
	call	GetDNum		; get the decimal number that follows
	PAGE2			; select page 2
	movwf	temp2		; save number to dial.
	sublw	EEADNUM		; subtract max autodials
	btfss	STATUS,C	; skip if result is non-negative.
	return			; number too big.  quietly fail.
	;; number is in valid range.
	movlw	high EEADBS	; get hi byte of autodial base EEPROM address.
	movwf	eeAddrH		; set hi byte EEPROM address.
	movlw	low EEADBS	; get lo byte of autodial base EEPROM address.
	movwf	eeAddrL		; set lo byte EEPROM address.
	;; voodoo hack calculate autodial slot address.
	;; since all slots are 16 bytes, then...
	swapf	temp2,w		; multiply by 16.
	andlw	h'f0'		; low nibble of product.
	addwf	eeAddrL,f	; add to lo byte of eeprom address.	
	swapf	temp2,w		; multiply by 16.
	andlw	h'0f'		; get new high nibble of product.
	addwf	eeAddrH,f	; add to hi byte of eeprom address.
	PAGE3			; select code page 3.
	call	CpyAuto		; copy the autodial location.
	PAGE1			; select code page 1.
	movlw	low dtXbuf0	; get address of xmit buffer
	movwf	FSR		; put address of xmit buffer into FSR.
	movf	INDF,w		; get first digit of phone number.
	xorlw	h'ff'		; xor with FF, see if valid.
	btfsc	STATUS,Z	; result will be 0 in invalid.
	return			; quietly fail.

	;; set autodial timer.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETAD		; get address of autodial timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	movwf	ptchTmr		; set autopatch timer.
	bsf	flags,DEFFONE	; set deferred fone call.
	PAGE3			; select code page 3.
	movlw	VAUTOD		; get word "autodial".
	call	PutWord		; add word to buffer
	movf	temp2,w		; get slot number.
	call	PutNum		; add word for slot number.
	call	PlaySpc		; play message then make call.
	PAGE1			; select code page 1.
	return			; done here.

; ***********
; ** LCmd4 **
; ***********
LCmd4				; emergency autodial
	btfss	group4,3	; is emergency autodial enabled?
	return			; no.  quietly do nothing.
	decfsz	cmdSize,w	; check for 1 digit only.
	return			; too many digits.  Quietly fail.
	movf	INDF,w		; get emergency autodial digit.
	movwf	temp2		; save slot number for announcement.
	sublw	d'9'		; w = 9-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; invalid command digit.  Quietly fail.
	;; valid emergency autodial slot number.  Get EEPROM address.
	;; now get the address of the autodial slot.
	movlw	high EEAAB	; get hi byte of EEPROM address emerg autod.
	movwf	eeAddrH		; set hi byte EEPROM address.
	movlw	low EEAAB	; get lo byte of EEPROM address emerg autod.
	movwf	eeAddrL		; set lo byte EEPROM address.
	swapf	INDF,w		; multiply autodial number by 16.
	andlw	h'f0'		; mask all but high bits.
	addwf	eeAddrL,f	; add to eeprom address.
	PAGE3			; select code page 3.
	call	CpyAuto		; copy the autodial location.
	PAGE1			; select code page 1.
	
	movlw	low dtXbuf0	; get address of xmit buffer
	movwf	FSR		; put address of xmit buffer into FSR.
	movf	INDF,w		; get first digit of phone number.
	xorlw	h'ff'		; xor with FF, see if valid.
	btfsc	STATUS,Z	; result will be 0 in invalid.
	return			; quietly fail.

	;; set emergency autodial patch timer
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETEAD		; get address of emergency autodial timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE1			; select code page 1.
	btfss	group4,5	; is emergency autodial timer disabled?
	movwf	ptchTmr		; no.  set autopatch timer.
	bsf	flags,DEFFONE	; set deferred fone call.
	PAGE3			; select code page 3.
	movlw	VEMERG		; get word "emergency".
	call	PutWord		; add word to buffer
	movlw	VAUTOD		; get word "autodial".
	call	PutWord		; add word to buffer
	movf	temp2,w		; get slot number.
	call	PutNum		; add word for slot number.
	call	PlaySpc		; play message then make call.
	PAGE1			; select code page 1.
	return			; done here.

; ***********
; ** LCmd5 **
; ***********
LCmd5				; patch hang up code
	btfss	outPort,FONECTL ; is phone off hook?
	return			; nope.
	clrf	ptchTmr		; clear patch timer.
	PAGE3			; select code page 3.
	call	FoneOff		; turn off patch!
	movlw	VCALL		; word "call".
	call	PutWord		; put word into buffer
	movlw	VCOMPLT		; word "complete".
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmd6 **
; ***********
LCmd6				; DTMF access
	btfss	group0,5	; check to see if DTMF access mode is enabled.
	return			; it's not.
	decfsz	cmdSize,w	; check for one command digit.
	return			; not one command digit.
	movf	INDF,f		; get command digit.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmd60		; yes.
	decfsz	INDF,w		; check for one.
	return			; it's not one.

	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	movwf	dtATmr		; set DTMF access mode timer.
	
	movlw	VREPEAT		; word "repeater"
	call	PutWord		; put word into buffer
	movlw	VACCESS		; word "access"
	call	PutWord		; put word into buffer
	movlw	VENABLE		; word "enable"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

LCmd60				; turn off DTMF access mode.
	movf	dtATmr,f	; check for zero.
	btfsc	STATUS,Z	; is it zero.
	return			; it is zero, do nothing.
	clrf	dtATmr		; make it zero.
	
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	outPort,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	clrf	rx1TOut		; clear link receiver timeout timer
	bcf	outPort,TX1PTT	; turn off link transmitter.

	PAGE3			; select code page 3.
	movlw	VREPEAT		; word "repeater"
	call	PutWord		; put word into buffer
	movlw	VACCESS		; word "access"
	call	PutWord		; put word into buffer
	movlw	VDISABL		; word "disabled"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmd7 **
; ***********
LCmd7				; regenerate DTMF
	movf	cmdSize,f	; check cmdSize, no sense if zero length.
	btfsc	STATUS,Z	; is it zero?
	return			; yes. Don't make call.
	PAGE3			; select code page 3.
	movf	FSR,w		; get pointer to digits to send.
	call	PlayDTA		; play DTMF sequence over air.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmd8 **
; ***********
LCmd8				; DTMF pad test
	btfss	group1,6	; is DTMF pad test enabled?
	return			; no.  quietly do nothing.
	movf	cmdSize,w	; check command size
	sublw	d'15'		; w = 15 - w
	btfsc	STATUS,C	; skip if result is negative
	goto	DTTest		; result is not negative
	movlw	d'15'		; max bytes
	movwf	cmdSize		; set maximum value
DTTest
	movf	cmdSize,w	; get command size
	btfsc	STATUS,Z	; check for zero.
	return			; it's zero.  do nothing.
DTTLoop
	movf	INDF,w		; get digit.
	PAGE3			; select page 3
	call	HexWord		; get word for digit.
	call	PutWord		; put word for digit.
	PAGE1			; select page 1
	incf	FSR,f		; increment command digit pointer.
	decfsz	cmdSize,f	; decrease digits remaining.
	goto	DTTLoop		; go again and do another digit.
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmd9 **
; ***********
LCmd9				; reverse patch
	btfss	group4,5	; is reverse patch enabled?
	return			; no.  quietly do nothing.
	btfsc	outPort,FONECTL ; is the phone already up?
	goto	LCmd9up		; yes.	allow bring on air.
	movf	ringTmr,f	; get ring timeout timer.
	btfsc	STATUS,Z	; has the phone rang lately?
	return			; nope.	 don't allow user to pick up phone.
LCmd9up				; pick up the phone.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETPAT		; get EEPROM address of patch timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3
	call	ReadEEw		; read EEPROM.
	movwf	ptchTmr		; set autopatch timer.
	call	FoneOn		; pick up phone.
	movlw	VPHONE		; get word "phone".
	call	PutWord		; put word into buffer.
	movlw	VON		; get word "on".
	call	PutWord		; put word into buffer.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmdA **
; ***********
LCmdA				; audio check
	;PAGE3			; select code page 3.
	;movlw	VRECORD		; word "record"
	;call	PutWord		; put word into buffer
	;movlw	VTEST		; word "test"
	;call	PutWord		; put word into buffer
	;movlw	VMESSAG		; word "message"
	;call	PutWord		; put word into buffer
	;call	PlaySpc		; play the speech message.
	;PAGE1			; select code page 1.
	;movlw	VTESTM		; get test message track
	;movwf	isdRMsg		; set record message number.
	;bsf	isdFlag,ISDTEST ; play test message after recording.
	;bsf	isdFlag,ISDRECR ; set record mode flag
	;return

LCmdA1				; control digital output port
	;; this is new 1.13 code to change function 10
	;; from parrot to digital output control.
	movlw	d'1'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 2)
	return			; not enough command digits. fail quietly.
	movf	cmdSize,w	; get command size
	sublw	d'2'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 3)
	return			; too many command digits. Fail quietly.
	;; command is now either 1 or 2 digits.
	
	movf	INDF,w		; get output # byte (bit #)
	movwf	temp		; save it.
	incf	FSR,f		; move to next byte (state)
	decf	cmdSize,f	; decrement command size.

	sublw	d'7'		; w = 7-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; bad output number.

	movf	cmdSize,f	; test command size for zero (inquiry)
	btfsc	STATUS,Z	; skip if not 0.
	goto	LCmdA1a		; it's an inquiry.

	;; verify valid argument before starting message, if not inquiry.
	movf	INDF,w		; get state byte
	andlw	b'11111110'	; only 0 and 1 permitted.
	btfss	STATUS,Z	; should be zero of 0 or 1 entered
	return			; fail quietly.
	
LCmdA1a
	PAGE3			; select page 3
	movf	temp,w		; get item (bit) number.
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movlw	VIS		; get word "IS".
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movf	temp,w		; get Item byte
	call	GetMask		; get bit mask for selected item
	PAGE1			; select page 2
	movwf	temp		; save mask

	movf	cmdSize,f	; test command size for zero (inquiry)
	btfsc	STATUS,Z	; skip if not 0.
	goto	LCmdA1I		; it's an inquiry.
	
	movf	INDF,f		; get state byte
	btfss	STATUS,Z	; skip if state is zero
	goto	LCmdA11		; not zero

	;; turn off a digital output
	movf	temp,w		; get mask
	xorlw	h'ff'		; invert mask to clear selected bit
	andwf	group7,f	; apply inverted mask
	PAGE3			; select code page 3.
	movlw	VOFF		; get word "off".
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return			; done.

LCmdA11				; turn on a digital output.
	btfsc	group6,DONEOF	; one of mode set?
	clrf	group7		; yes, turn off outputs.
	movf	temp,w		; get mask
	iorwf	group7,f	; or byte with mask.
	movlw	VON		; get word "ON".
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buf. nukes temp3.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 2.
	movf	group6,w	; get group6.
	andlw	b'00011111'	; and pulsed outputs enabled?
	btfsc	STATUS,Z	; any enabled?
	return			; nope.
	movlw	PULS_TM		; get pulse timer initial value.
	movwf	pulsTmr		; set pulse timer.
	return			; done.
	
LCmdA1I				; inquiry mode.
	movf	temp,w		; get mask
	andwf	group7,w	; and the mask (in temp) with the field.
	movlw	VON		; get word "enabled".
	btfsc	STATUS,Z	; was result (from and) zero?
	movlw	VOFF		; yes. get word "disabled".
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 2.
	return			; done.
	
; ***********
; ** LCmdB **
; ***********
LCmdB				; mailbox
	movf	cmdSize,f	; check cmdSize
	btfsc	STATUS,Z	; skip if not zero
	goto	LCmdBP		; it's zero.  Play.
	;; there is at least one digit after the mailbox prefix.
	movlw	h'0e'		; asterisk
	xorwf	INDF,w		; is the digit a '*'?
	btfsc	STATUS,Z	; z will be true if digit is a '*'.
	goto	LCmdBS		; result is zero -- got a '*'.
	movf	INDF,w		; get mailbox number
	btfsc	STATUS,Z	; check for zero.
	goto	LCmdBNM		; zero is not valid mailbox number.
	sublw	d'6'		; subtract last mailbox number.
	btfss	STATUS,C	; C will be set if mbx # <= 6.
	goto	LCmdBNM		; no message.
	;; play numbered message here.
	movf	INDF,w		; get message number
	movwf	temp3		; save in temp 3
	clrf	temp2		; message counter
LCmdB1
	movf	temp2,w		; get message counter
	PAGE3			; select page 3
	call	GetMask		; get bitmask for message.
	PAGE1			; select page 1
	andwf	mbxFlag,w	; and with mailbox flag.
	btfsc	STATUS,Z	; zero if mailbox slot empty
	goto	LCmdB1a		; mailbox slot is empty.
	decfsz	temp3,f		; decrement temp3.
	goto	LCmdB1a		; not empty.
	;; found specified mailbox.  play it.
	movf	temp2,w		; get mailbox index.
	movwf	mbxCtl		; save it.
	bsf	mbxCtl,MBXLPLA	; set last played flag. OK to erase.
	movlw	VMB1H		; get mailbox 0 header address.
	addwf	temp2,w		; add offset
	PAGE3			; select code page 3.
	call	PutWord		; put word into buffer
	movlw	VMB1		; get mailbox 0 address.
	addwf	temp2,w		; add offset
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message
	PAGE1			; select code page 1.
	return			; done here
	
LCmdB1a
	incf	temp2,f		; move to next mailbox
	movf	temp2,w		; get mailbox number
	sublw	LASTMBX		; subtract w from last mlbx number, zero-based.
	btfsc	STATUS,C	; c will be set if >= 0.
	goto	LCmdB1		; try next slot

	;; that message was not present.
	PAGE3			; select code page 3.
	movlw	VNO		; get word "no".
	call	PutWord		; put word into buffer
	movlw	VMBX		; get word "mailbox".
	call	PutWord		; put word into buffer
	movf	INDF,w		; index
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	bcf	mbxCtl,MBXLPLA	; clear last played flag.
	return
LCmdBNM				; no message in this location.
	PAGE3			; select code page 3.
	movlw	VBAD		; get word "bad".
	call	PutWord		; put word into buffer.
	movlw	VMESSAG		; get word "message".
	call	PutWord		; put word into buffer.
	movlw	VNUMBER		; get word "number".
	call	PutWord		; put word into buffer.
	call	PlaySpc		; play the speech message
	PAGE1			; select code page 1.
	bcf	mbxCtl,MBXLPLA	; clear last played flag.
	return			; done here
	
LCmdBS				; evaluate & process asterisk commands.
	;; prefix and at least one asterisk here
	decf	cmdSize,f	; decrement remaining digits.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdBR		; no.  one asterisk. must be record mail.
	incf	FSR,f		; move to next digit.
	movlw	h'0e'		; asterisk
	xorwf	INDF,w		; is the digit a '*'?
	btfss	STATUS,Z	; z will be true if digit is a '*'.
	return			; do nothing if 2nd digit is not a '*'.
	decf	cmdSize,f	; decrement number of remaining digits.
	btfsc	STATUS,Z	; see if result is zero.
	goto	LCmdBE		; 2 asterisks only.  erase command.
	incf	FSR,f		; move to next digit.
	movlw	h'0e'		; asterisk
	xorwf	INDF,w		; is the digit a '*'?
	btfss	STATUS,Z	; z will be true if digit is a '*'.
	return			; do nothing if 2nd digit is not a '*'.
	;; got prefix *** -- this is the audio check.
	PAGE3			; select code page 3.
	movlw	VRECORD		; word "record"
	call	PutWord		; put word into buffer
	movlw	VTEST		; word "test"
	call	PutWord		; put word into buffer
	movlw	VMESSAG		; word "message"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	movlw	VTESTM		; get test message track
	movwf	isdRMsg		; set record message number.
	bsf	isdFlag,ISDTEST ; play test message after recording.
	bsf	isdFlag,ISDRECR ; set record mode flag
	bcf	mbxCtl,MBXLPLA	; clear last played flag.
	return

LCmdBE				; erase message
	btfss	mbxCtl,MBXLPLA	; was the last operation to play a message?
	goto	LCmdBEE		; no. error.
	movf	mbxCtl,w	; get mailbox control flag.
	andlw	b'00001111'	; mask out control bits.  mbx # remains.
	PAGE3			; select page 3
	call	GetMask		; get the bitmask.
	PAGE1			; select page 1
	xorlw	b'11111111'	; invert the bitmask.
	andwf	mbxFlag,f	; clear the bit from the mbxFlag.
	;; save mbxFlag to EEPROM
	movlw	high EEMBXF	; get high byte of EEPROM address.
	movwf	eeAddrH		; save high byte of EEPROM address.
	movlw	low EEMBXF	; get low byte of EEPROM address.
	movwf	eeAddrL		; save low byte of EEPROM address.
	movf	mbxFlag,w	; get mbxFlag back.
	PAGE3			; select code page 3.
	call	WriteEw		; write this byte to EEPROM.
	movlw	VOK		; get word "OK".
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	bcf	mbxCtl,MBXLPLA	; clear last played flag.
	return
	
LCmdBEE				; erase error.	last operation was not play.
	PAGE3			; select code page 3.
	movlw	VBAD		; get word "bad".
	call	PutWord		; put word into buffer
	movlw	VMBX		; get word "mailbox".
	call	PutWord		; put word into buffer
	movlw	VCOMMND		; get word "command".
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	bcf	mbxCtl,MBXLPLA	; clear last played flag.
	return

LCmdBR				; record message.
	clrf	temp2		; message counter
LCmdBR1
	movf	temp2,w		; get message counter
	PAGE3			; select page 3
	call	GetMask		; get bitmask for message.
	PAGE1			; select page 1
	movwf	temp3		; save mailbox mask bit.
	andwf	mbxFlag,w	; and with mailbox flag.
	btfsc	STATUS,Z	; zero if message slot empty
	goto	LCmdBRR		; now have valid slot number.
	incf	temp2,f		; move to next mailbox
	movf	temp2,w		; get mailbox number
	sublw	LASTMBX		; subtract w from last mlbx number, zero-based.
	btfsc	STATUS,C	; c will be set if >= 0.
	goto	LCmdBR1		; try next slot
	;; mailboxes are full.
	PAGE3			; select code page 3.
	movlw	VNO		; get word "no".
	call	PutWord		; put word into buffer
	movlw	VMBX		; get word "mailbox".
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return			; done here.

LCmdBRR				; ready to record into slot pointed at by temp2
	movf	temp2,w		; get message number
	andlw	h'0f'		; mask out high nibble
	movwf	mbxCtl		; set message number bits to this message.
	bsf	mbxCtl,MBXRHDR	; set record mailbox header flag.

	PAGE3			; select code page 3.
	movlw	VRECORD		; word "record"
	call	PutWord		; put word into buffer
	movlw	VMESSAG		; word "message"
	call	PutWord		; put word into buffer
	movlw	VHEADER		; word "header"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	movlw	VMB1H		; get mailbox header track number
	addwf	temp2,w		; add offset.
	movwf	isdRMsg		; set record message number.
	bsf	isdFlag,ISDRECR ; set record mode flag
	movf	temp3,w		; get mailbox mask bit.
	iorwf	mbxFlag,f	; set bit in mbxFlag.
	;; save mbxFlag to EEPROM
	movlw	high EEMBXF	; get high byte of EEPROM address.
	movwf	eeAddrH		; save high byte of EEPROM address.
	movlw	low EEMBXF	; get low byte of EEPROM address.
	movwf	eeAddrL		; save low byte of EEPROM address.
	movf	mbxFlag,w	; get mbxFlag back.
	PAGE3			; select code page 3.
	call	WriteEw		; write this byte to EEPROM.
	PAGE1			; select code page 1.
	return
	
LCmdBP				; play mailbox headers.
	PAGE3			; select code page 3.
	call	MbxHdrs		; play mailbox headers.
	PAGE1			; select code page 1.
	return			; done.
	
; ***********
; ** LCmdC **
; ***********
LCmdC				; remote base
	btfss	group5,4	; is link prefix enabled?
	return			; no.  do nothing quietly.
	movf	cmdSize,f	; check cmdSize
	btfsc	STATUS,Z	; skip if not zero
	return			; no more digits.  Ignore.
	movf	INDF,w		; get command digit.
	movwf	temp2		; save command digit.
	decf	cmdSize,f	; decrement cmdSize.
	incf	FSR,f		; move pointer.
	;; valid command digits:
	;;	    0 -- link off.
	;;	    1 -- link alert mode.
	;;	    2 -- link receive mode.
	;;	    3 -- link transmit mode.
	;;	    4 -- mode select.
	;;	    5 -- frequency select.
	;;	    6 -- VFO/Memory select.
	;;	    7 -- mem channel select.
	;;	    8 -- split on/off.
	;;	    9 -- tune mode.
	movf	temp2,f		; check.
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC0		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC1		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC2		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC3		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC4		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC5		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC6		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC7		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC8		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmdC9		; yes.
	return			; was greater than 3
LCmdC0				; link off
	bcf	group5,0	; clear alert bit
	bcf	group5,1	; clear receive bit
	bcf	group5,2	; clear transmit bit

	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	outPort,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	clrf	rx1TOut		; clear link receiver timeout timer
	bcf	outPort,TX1PTT	; turn off link transmitter.
	PAGE3			; select code page 3.
	movlw	VLINK		; word "link"
	call	PutWord		; put word into buffer
	movlw	VOFF		; word "off "
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

LCmdC1				; link alert mode.
	bsf	group5,0	; set alert bit
	bcf	group5,1	; clear receive bit
	bcf	group5,2	; clear transmit bit
	
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	outPort,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	clrf	rx1TOut		; clear link receiver timeout timer

	PAGE3			; select code page 3.
	movlw	VLINK		; word "link"
	call	PutWord		; put word into buffer
	movlw	VALERT		; word "ALERT"
	call	PutWord		; put word into buffer
	movlw	VON		; word "ON"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return
	
LCmdC2				; link receive mode.
	bcf	group5,0	; clear alert bit
	bsf	group5,1	; set receive bit
	bcf	group5,2	; clear transmit bit
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EERBTMR		; get EEPROM address of remote base timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	movwf	rbTmr		; set remote base activity timer.
	movlw	VLINK		; word "link"
	call	PutWord		; put word into buffer
	movlw	VRECEIV		; word "RECEIVE"
	call	PutWord		; put word into buffer
	movlw	VON		; word "ON"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return
	
LCmdC3				; link transmit mode
	bcf	group5,0	; clear alert bit
	bcf	group5,1	; clear receive bit
	bsf	group5,2	; set transmit bit
	btfsc	group3,3	; is port 2 a repeater?
	bsf	outPort,TX1PTT	; yes, turn on port 2 PTT.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EERBTMR		; get EEPROM address of remote base timer.
	movwf	eeAddrL		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	movwf	rbTmr		; set remote base activity timer.
	movlw	VLINK		; word "link"
	call	PutWord		; put word into buffer
	movlw	VTRANS		; word "TRANSMIT"
	call	PutWord		; put word into buffer
	movlw	VON		; word "ON"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

LCmdC4				; CI-V mode select.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC4R		; yes, send read command.
	movf	INDF,w		; get next digit.
	sublw	d'3'		; w = 3-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; invalid digit.
	btfss	STATUS,Z	; it was 3.
	goto	LCmdC4a		; not 3. leave alone.
	movlw	h'05'		; FM mode.
	movwf	INDF		; stuff it over the 3 that was there.
LCmdC4a				; ready to send digit.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_MOD		; select operating mode.
	call	SerOut		; send it.
	movf	INDF,w		; get operating mode argument from command.
	call	SerOut		; send it.
	movlw	h'01'		; select normal IF bandwidth.
	call	SerOut		; send it.
	movlw	h'fd'		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return

LCmdC4R				; read mode from radio.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_RDM		; read operating mode.
	call	SerOut		; send it.
	movlw	h'fd'		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return

LCmdC5				; CI-V tune.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC5R		; yes, send read command.
	;; first, find the '*'.
	movf	FSR,w		; get FSR to save it.
	movwf	temp		; cache FSR.
	movf	cmdSize,w	; get cmdSize.
	movwf	temp2		; temp copy.
LCmdC5a				; search for '*' loop.
	movf	INDF,w		; get next digit.
	xorlw	h'0e'		; is it the * key?
	btfsc	STATUS,Z	; skip if not the '*'.
	goto	LCmdC5b		; it was the '*'.
	;; check for bad digit here?
	incf	FSR,f		; move to next byte.
	decfsz	temp2,f		; decrement cmd size copy.  skip if zero.
	goto	LCmdC5a		; more digits...  loop.
	return			; '*' not found.
LCmdC5b				; "*" was found.
	btfss	group3,0	; is auto-receive mode selected?
	goto	LCmdC5c		; nope.
	;; set receive mode.
	bcf	group5,0	; clear alert bit
	bsf	group5,1	; set receive bit
	bcf	group5,2	; clear transmit bit
LCmdC5c 
	;; clear the CI-V frequency info.
	bsf	STATUS,RP0	; select register page 1.
	clrf	civfrq1		; reset to 0 0.
	clrf	civfrq2		; reset to 0 0.
	clrf	civfrq3		; reset to 0 0.
	clrf	civfrq4		; reset to 0 0.
	clrf	civfrq5		; reset to 0 0.
	bcf	STATUS,RP0	; select register page 0.
	movf	temp,w		; get old FSR back.
	movwf	FSR		; restore old FSR.
	
	movf	temp2,w		; get difference. (# digits left of *)
	subwf	cmdSize,w	; get command size.
	movwf	temp		; store the difference.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC5k		; process in the *.
	decf	temp,f		; decrement.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC5j		; process the 1 MHz digit.
	decf	temp,f		; decrement.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC5i		; process the 10 MHz digit.
	decf	temp,f		; decrement.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC5h		; process the 100 MHz digit.
	decf	temp,f		; decrement.
	btfss	STATUS,Z	; is it zero?
	return			; no.  bad value, do nothing.
	
LCmdC5g				; do 1 GHz digit.
	swapf	INDF,w		; get lo nibble of command char into hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq5,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

LCmdC5h				; do 100 MHz digit.
	movf	INDF,w		; get lo nibble of command char into lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq5,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

LCmdC5i				; do 10 MHz digit.
	swapf	INDF,w		; get lo nibble of command char into hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq4,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

LCmdC5j				; do 1 MHz digit.
	movf	INDF,w		; get lo nibble of command char into lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq4,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

LCmdC5k				; this better be the '*' digit.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.
	
				; do 100 KHz digit. 
	swapf	INDF,w		; get lo nibble of command char into hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq3,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

				; do 10 KHz digit. 
	movf	INDF,w		; get lo nibble of command char into lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq3,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

				; do 1 KHz digit. 
	swapf	INDF,w		; get lo nibble of command char into hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq2,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

				; do 100 Hz digit. 
	movf	INDF,w		; get lo nibble of command char into lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	iorwf	civfrq2,f	; and digit into frequency.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; get next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; any more digits?
	goto	LCmdC5S		; send the tune command.

LCmdC5S				; send the tune command.
	PAGE3			; select rom page 3
	call	CIVTune		; send tune message
	PAGE1			; select this page.
	return

LCmdC5R				; read mode from radio.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_RDF		; read operating mode.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return
		
LCmdC6				; VFO/Memory select.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	return			; yes. do nothing.
	movf	INDF,w		; get next digit.
	;; start evaluating.
	movwf	temp2		; save digit.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdC6a		; it's 0, send SELECT MEMORY command.
	decf	temp2,f		; decrement it.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdC6b		; it's was 1, send SELECT VFO command.
	movlw	h'00'		; VFO A command.
	movwf	temp		; save it.
	decf	temp2,f		; decrement it.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdC6c		; it's zero, ok to send it.
	movlw	h'01'		; VFO B command.
	movwf	temp		; save it.
	decf	temp2,f		; decrement it.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdC6c		; it's zero, ok to send it.
	movlw	h'A0'		; A=B command.
	movwf	temp		; save it.
	decf	temp2,f		; decrement it.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdC6c		; it's zero, ok to send it.
	movlw	h'B0'		; A/B command.
	movwf	temp		; save it.
	decf	temp2,f		; decrement it.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdC6c		; it's zero, ok to send it.
	return			; unknown command digit.
	
LCmdC6a				; ready to send select memory command.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_MEM		; select operating mode.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return

LCmdC6b				; ready to send select VFO command.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_VFO		; select operating mode.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return

LCmdC6c				; ready to send VFO command.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_VFO		; select operating mode.
	call	SerOut		; send it.
	movf	temp,w		; get VFO argument.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return

LCmdC7				; CI-V memory channel select.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	return			; yes. invalid command.	 do nothing.
	movf	INDF,w		; get command digit.
	andlw	h'0f'		; mask it.
	movwf	temp		; save digit.
	incf	FSR,F		; point at next digit.
	decf	cmdSize,f	; decrement command size.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmdC7a		; send command.
	movf	INDF,w		; get command digit.
	andlw	h'0f'		; mask it.
	swapf	temp,f		; swap bytes from temp into w.
	iorwf	temp,f		; add in nibble.
	decf	cmdSize,f	; should be no more digits.
	btfss	STATUS,Z	; is result zero?
	return			; no.  bad command.  do nothing.

LCmdC7a				; ready to send memory channel select command.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_MEM		; select memory channel.
	call	SerOut		; send it.
	movf	temp,w		; get channel number from command.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return

LCmdC8				; select split command.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	return			; yes. invalid command.	 do nothing.
	movf	INDF,w		; get command digit.
	btfsc	STATUS,Z	; skip if non-zero.
	goto	LCmdC8a		; send command.
	decf	INDF,w		; check to see if it was 1.
	btfsc	STATUS,Z	; skip if non-zero.
	goto	LCmdC8a		; send command.
	return			; invalid digit.  do nothing quietly.

LCmdC8a				; ready to send split select command.
	PAGE3			; select code page 3.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_SPL		; split command.
	call	SerOut		; send it.
	movf	INDF,w		; get channel number from command.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	PAGE1			; select code page 1.
	return			; done here.
	
LCmdC9				; select tune mode.
	btfss	group3,0	; is auto-receive mode selected?
	goto	LCmdC9a		; nope.
	;; set receive mode.
	bcf	group5,0	; clear alert bit
	bsf	group5,1	; set receive bit
	bcf	group5,2	; clear transmit bit
LCmdC9a 
	;; set the tune mode bit.
	movf	dtEFlag,w	; get eval flags
	andlw	b'11100000'	; mask all except command source indicators.
	iorwf	tuneFlg,f	; IOR with dtRFlag: set tune mode bit.
	;; tell someone who cares.
	PAGE3			; select code page 3.
	movlw	VFREQ		; word "frequency"
	call	PutWord		; put word into buffer
	movlw	VCONTRL		; word "control"
	call	PutWord		; put word into buffer
	movlw	VENABLE		; word "enabled"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	movlw	CTTUNE		; get tune mode courtesy tone.
	movwf	cTone		; set tune mode courtesy tone.
	return			; done. do nothing.
	
; ***********
; ** LCmdD **
; ***********
LCmdD				; LITZ command. default prefix 911.
	PAGE3			; select code page 3.
	movlw	VLITZ		; index
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return

; ***********
; ** LCmdE **
; ***********
LCmdE				; load saved state.
	decfsz	cmdSize,w	; is this 1?
	return			; nope.
	movf	INDF,w		; get command digit.
	sublw	d'4'		; subtract 4
	btfss	STATUS,C	; was result negative?
	return			; yes.
	movf	INDF,w		; get command digit.
	PAGE3			; select page 3.
	call	LoadCtl		; load control op settings.
	movlw	VOK		; word "OK"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return			; done.

; ***********
; ** LCmdF **
; ***********
LCmdF				; unlock this port
	movf	dtEFlag,w	; get eval flags
	andlw	b'11100000'	; mask all except command source indicators.
	iorwf	dtRFlag,f	; IOR with dtRFlag: set unlocked bit.
	movlw	UNLKDLY		; get unlocked mode timer.
	movwf	unlkTmr		; set unlocked mode timer.
	PAGE3			; select code page 3.
	movlw	VCONTRL		; word "control"
	call	PutWord		; put word into buffer
	movlw	VACCESS		; word "access"
	call	PutWord		; put word into buffer
	movlw	VENABLE		; word "enabled"
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	movlw	CTUNLOK		; get unlocked mode courtesy tone.
	movwf	cTone		; yep. set unlocked courtesy tone.
	return

; ***********
; ** RBOff **
; ***********
RBOff
	bcf	group5,0	; clear alert bit
	bcf	group5,1	; clear receive bit
	bcf	group5,2	; clear transmit bit
	;; v 1.14 change - turn off tune mode
	clrf	tuneFlg		; turn off tune mode
	;; end v 1.14 change
	bsf	STATUS,RP0	; select register page 1.
	clrf	scanTmr		; stop scanning.
	clrf	scanMod		; stop scanning.
	bcf	STATUS,RP0	; select register page 0.
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	outPort,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear link receiver on bit
	clrf	rx1TOut		; clear link receiver timeout timer
	bcf	outPort,TX1PTT	; turn off link transmitter.
	bsf	outPort,BEEPAUD ; turn on audio gate
	PAGE3			; select page 3.
	call	SetPort		; set the port.
	call	PTTon		; turn on PTT.
	movlw	VLINK		; word "link"
	call	PutWord		; put word into buffer
	movlw	VOFF		; word "off "
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 1.
	return
	
; *************
; ** CpyDTMF **
; *************
	;; copy a DTMF command from the DTMF receive buffer
	;; pointed at by FSR into the DTMF command interpreter buffer.
	;; terminate the DTMF command interpreter buffer with FF.
CpyDTMF				; copy DTMF from cmd buffer to xmit buffer
	bsf	flags,CMD_NIB	; start with high nibble of DTMF buffer.
	movf	FSR,w		; get FSR
	movwf	temp		; preserve this
	movlw	low cmdbf00	; get address of command buffer
	movwf	temp3		; set buffer pointer
CpyDtLp
	movf	temp,w		; get address of RX byte
	movwf	FSR		; set rx buffer pointer
	movf	INDF,w		; get byte
	movwf	temp2		; save byte
	movf	temp3,w		; get xmit buffer address pointer
	movwf	FSR		; set pointer
	btfss	flags,CMD_NIB	; is high nibble next victim
	goto	CpyDLow		; low nibble is victim
	swapf	temp2,w		; get high nibble
	bcf	flags,CMD_NIB	; select low nibble next
	goto	CpyDBth		; keep copying...
CpyDLow
	bsf	flags,CMD_NIB	; high nibble is next
	incf	temp,f		; increment DTMF rx address
	movf	temp2,w		; get low nibble
CpyDBth
	andlw	b'00001111'	; mask low nibble
	movwf	INDF		; save digit
	incf	temp3,f		; increment pointer (for next time)
	decfsz	cmdSize,f	; decrement cmdSize
	goto	CpyDtLp		; not zero yet...
	incf	FSR,f		; zero, write the FF at the end
	movlw	h'ff'		; end of DTMF message
	movwf	INDF		; mark end of DTMF
	return			; done.

; ************************************************************************
; ****************************** ROM PAGE 2 ******************************
; ************************************************************************
	org	1000		; page 2
	
; ***********
; ** UlCmd **
; ***********
UlCmd				; process an Unlocked Command!
	movlw	UNLKDLY		; get unlocked mode timeout time.
	movwf	unlkTmr		; set unlocked mode timer.
	movlw	CTUNLOK		; get the unlocked courtesy tone.
	movwf	cTone		; save the courtesy tone.
	movlw	low cmdbf00	; get command buffer address
	movwf	FSR		; set pointer
	movf	INDF,w		; get cmd byte
	sublw	h'0e'		; subtract e (* key)
	btfsc	STATUS,Z	; is result zero? (* is first tone)
	goto	UlStar		; yes.

	movf	INDF,w		; get cmd byte
	sublw	h'0f'		; subtract f (# key)
	btfss	STATUS,Z	; is result zero? (# is first tone)
	goto	UlCmdNG		; nope.
	;; lock command.
	movf	dtEFlag,w	; get eval flags
	andlw	b'11100000'	; mask all except command source indicators.
	xorlw	b'11111111'	; invert bitmask
	andwf	dtRFlag,f	; and with dtRFlag: clear unlocked bit.
	clrf	unlkTmr		; reset unlocked mode timer.
	PAGE3			; select code page 3.
	movlw	VCONTRL		; word "control"
	call	PutWord		; put word into buffer
	movlw	VACCESS		; word "access"
	call	PutWord		; put word into buffer
	movlw	VDISABL		; word "disabled".
	call	PutWord		; put word into buffer.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.
	
UlStar				; process '*' command.
	incf	FSR,f		; increment cmd pointer
	movf	INDF,w		; 2nd byte
	movwf	temp		; save it.
	incf	FSR,f		; increment cmd pointer
	decf	cmdSize,f	; decrement command size
	decf	cmdSize,f	; decrement command size again (-2) 
	movlw	high ULTable	; set high byte of address
	movwf	PCLATH		; select page
	movf	temp,w		; get command byte.
	andlw	h'0f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL
	;; jump table goes here...
ULTable
	goto	UlCmd0		; command *0 -- control op group
	goto	UlCmd1		; command *1 -- save setup
	goto	UlCmd2		; command *2 -- program prefixes
	goto	UlCmd3		; command *3 -- program timers
	goto	UlCmd4		; command *4 -- patch setup
	goto	UlCmd5		; command *5 -- autodial setup
	goto	UlCmd6		; command *6 -- user commands setup
	goto	UlCmd7		; command *7 -- program/play CW/Tones
	goto	UlCmd8		; command *8 -- play/record voice message
	goto	UlCmd9		; command *9 -- reserved (program ee byte)
	goto	UlCmdA		; command *a -- invalid command
	goto	UlCmdB		; command *b -- invalid command
	goto	UlCmdC		; command *c -- invalid command
	goto	UlCmdD		; command *d -- invalid command
	goto	UlCmdE		; command *e -- crash and burn
	goto	UlCmdF		; command *f -- invalid command

; ************
; ** UlCmd0 **
; ************
	;; set a control operator Group/Item to a specified state.
UlCmd0				; Control Op Group command
	movlw	d'2'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 2)
	goto	UlErr1		; not enough command digits.
	movf	cmdSize,w	; get command size
	sublw	d'3'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 3)
	goto	UlErr2		; too many command digits.

	movf	INDF,w		; get Group byte
	movwf	temp2		; save group byte.
	sublw	d'9'		; w = 9-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; bad, bad user tried to enter invalid group.
	incf	FSR,f		; move to next byte (bit #)
	decf	cmdSize,f	; decrement command size.
	movf	INDF,w		; get Item byte (bit #)
	movwf	temp		; save it.
	incf	FSR,f		; move to next byte (state)
	decf	cmdSize,f	; decrement command size.

	sublw	d'7'		; w = 7-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; bad, bad user tried to enter invalid item.

CtlOpC
	movf	cmdSize,f	; test this for zero (inquiry)
	btfsc	STATUS,Z	; skip if not 0.
	goto	CtlOpC1		; it's an inquiry.

	;; if not an inquiry, verify that state argument is valid before
	;; starting the confirmation message.
	movf	INDF,w		; get state byte
	andlw	b'11111110'	; only 0 and 1 permitted.
	btfss	STATUS,Z	; should be zero of 0 or 1 entered
	goto	UlErr3		; not zero, bad command.

CtlOpC1	
	PAGE3			; select page 3
	movlw	VCONTRL		; get "control" word.
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movf	temp2,w		; get group number.
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movlw	VPOINT		; get word "POINT".
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movf	temp,w		; get item (bit) number.
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movlw	VIS		; get word "IS".
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movf	temp,w		; get Item byte
	call	GetMask		; get bit mask for selected item
	PAGE2			; select page 2
	movwf	temp		; save mask

	movf	cmdSize,f	; test this for zero (inquiry)
	btfsc	STATUS,Z	; skip if not 0.
	goto	UlCmd0I		; it's an inquiry.
	
	movf	INDF,f		; get state byte
	btfss	STATUS,Z	; skip if state is zero
	goto	UlCmd01		; not zero
	movlw	low group0	; get address of 1st group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	xorlw	h'ff'		; invert mask to clear selected bit
	andwf	INDF,f		; apply inverted mask
	bsf	STATUS,IRP	; set indirect pointer into page 1
	PAGE3			; select code page 3.
	movlw	VDISABL		; get word "disabled".
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.

UlCmd01
	movlw	low group0	; get address of ist group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	
	bcf	STATUS,IRP	; set indirect back to page 0
	btfss	group6,DONEOF	; one of mode set?
	goto	UlCmd01a	; nope.
	movf	temp2,w		; get index.
	sublw	d'7'		; check for group7
	btfss	STATUS,Z	; is it group7?
	goto	UlCmd01a	; nope.
	clrf	INDF		; turn off all other outputs.
UlCmd01a
	movf	temp,w		; get mask
	iorwf	INDF,f		; or byte with mask.
	bsf	STATUS,IRP	; set indirect pointer into page 1
	movlw	VENABLE		; get word "enabled".
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buf. nukes temp3.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	movf	temp2,w		; get temp2.
	sublw	d'7'		; is it group 7?
	btfss	STATUS,Z	; is it?
	return			; no.
	movf	group6,w	; get group6.
	andlw	b'00011111'	; and pulsed outputs enabled?
	btfsc	STATUS,Z	; any enabled?
	return			; nope.
	movlw	PULS_TM		; get pulse timer initial value.
	movwf	pulsTmr		; set pulse timer.
	return			; done.
	
UlCmd0I				; inquiry mode.
	movlw	low group0	; get address of ist group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	andwf	INDF,w		; and the mask (in temp) with the field.
	bsf	STATUS,IRP	; set indirect pointer into page 1

	movlw	VENABLE		; get word "enabled".
	btfsc	STATUS,Z	; was result (from and) zero?
	movlw	VDISABL		; yes. get word "disabled".
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.
	
		
; ************
; ** UlCmd1 **
; ************
	;; save control operator Group/Item/States to a specified setup.
UlCmd1				; save setups
	btfsc	group8,0	; is control groups write protected?
	goto	UlErrWP		; yes.
	movf	cmdSize,w	; get command size
	sublw	d'1'		; subtract expected size
	btfss	STATUS,Z	; was it the expected size?
	goto	UlCmdNG		; nope.
	movf	INDF,w		; get setup number
	sublw	d'4'		; subtract largest expected
	btfss	STATUS,C	; is result not negative?
	goto	UlCmdNG		; nope.
	movlw	high EESSB	; get address of saved settings
	movwf	eeAddrH		; save high part of address
	movlw	low EESSB	; get low part of address
	movwf	eeAddrL		; save low part of address
	swapf	INDF,w		; magic! get command * 16
	addwf	eeAddrL,f	; now have ee address for saved state.
	movlw	EESSC		; get the number of bytes to save
	movwf	eeCount		; set the number of bytes to write.
	movlw	group0		; get address of first group
	movwf	FSR		; set pointer
	bcf	STATUS,IRP	; to page 0.
	PAGE3			; select code page 3.
	call	WriteEE		; save this stuff.
	PAGE2			; select code page 2.
	bsf	STATUS,IRP	; back to page 1.
	goto	UlCmdOK		; OK.
	
; ************
; ** UlCmd2 **
; ************
	;; set command prefixes...  
UlCmd2				; program prefixes
	btfsc	group8,1	; are prefixes write protected?
	goto	UlErrWP		; yes.
	movlw	d'3'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	UlErr1		; not enough command digits.
	movf	cmdSize,w	; get command size
	sublw	d'9'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 9)
	goto	UlErr2		; too many command digits.

	PAGE3			; select page 3
	call	GetTens		; get timer index tens digit.
	PAGE2			; select page 2
	movwf	temp		; save to prefix index in temp.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	INDF,w		; get timer index ones digit.
	addwf	temp,f		; add to prefix index in temp.
	movf	temp,w		; get prefix index
	sublw	d'15'		; w = 15 - pfxnum
	btfss	STATUS,C	; skip if result is non-negative (pfxnum <= 15)
	goto	UlErr3		; argument error
	decf	cmdSize,f	; less bytes to process
	incf	FSR,f		; point at next byte.

	movf	temp,w		; get index back.
	sublw	d'15'		; subtract index of unlock command.
	btfss	STATUS,Z	; is result zero?
	goto	UlCmd2P		; no.
	btfss	PORTE,INIT	; skip if init button not pressed.
	goto	UlCmd2P		; init is pressed.
	PAGE3			; select code page 3.
	movlw	VPROGR		; get word "program".
	call	PutWord		; add word to message buffer.
	movlw	VACCESS		; get word "access".
	call	PutWord		; add word to message buffer.
	movlw	VDISABL		; get word "disabled".
	call	PutWord		; add word to message buffer.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.
	
UlCmd2P				; program the new prefix.
	movf	cmdSize,w	; get command length
	movwf	eeCount		; save # bytes to write.
	incf	eeCount,f	; add 1 so FF at end of buffer gets copied.
	movlw	high EEPFB	; get high address of prefixes
	movwf	eeAddrH		; set eeprom address
	movlw	low EEPFB	; get low address of prefixes
	movwf	eeAddrL		; set eeprom address to base of prefixes
	bcf	STATUS,C	; clear carry
	rlf	temp,f		; multiply prefix by 2
	rlf	temp,f		; multiply prefix by 2 (x4 after)
	rlf	temp,f		; multiply prefix by 2 (x8 after)
	movf	temp,w		; get prefix offset
	addwf	eeAddrL,f	; add prefix to base
	PAGE3			; select code page 3.
	call	WriteEE		; write the prefix.
	PAGE2			; select code page 2.
	goto	UlCmdOK		; good command...
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  *3									      ;
;  Set Timers								      ;
;    *3<nn> inquire timer nn						     ;
;    *3<nn><time> set timer nn to time					     ;
;      00 <= nn <= 11  timer index					      ;
;      0 <= time <= 255 timer preset. 0=disable				      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UlCmd3				; program timers
	movlw	d'2'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	UlErr1		; not enough command digits.

	PAGE3			; select page 3
	call	GetTens		; get timer index tens digit.
	PAGE2			; select page 2
	movwf	temp2		; save
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrement count of remaining bytes.
	movf	INDF,w		; get timer index ones digit
	addwf	temp2,f		; add to timer index
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	temp2,w		; get timer index sum
	sublw	LASTTMR		; subtract last timer index
	btfss	STATUS,C	; skip if result is non-negative
	goto	UlErr3		; argument error
	clrf	eeAddrH		; clear hi byte of address
	movf	temp2,w		; get timer index
	movwf	eeAddrL		; set EEPROM address low byte
	movf	cmdSize,f	; check for no more digits.
	btfsc	STATUS,Z	; skip if not zero.
	goto	UlCmd3I		; zero more digits.
	;; ready to get value then set timer.
	btfsc	group8,2	; are timers write protected?
	goto	UlErrWP		; yes.
	PAGE3			; select page 3
	call	GetDNum		; get decimal number to w. nukes temp3,temp4
	movwf	temp4		; save decimal number to temp4.
	call	WriteEw		; write w into EEPROM.
	PAGE2			; select page 2
	movf	eeAddrL,w	; get low byte of address
	sublw	EETTAIL		; subtract tail counter address
	btfss	STATUS,Z	; skip if result is zero.
	goto	UlCmd3a		; result is non-zero.
	movlw	d'1'		; one.
	movwf	tailCtr		; get tail message on next tail drop.
UlCmd3a
	PAGE3			; select code page 3.
	movlw	VTIMER		; get "timer" word.
	call	PutWord		; add word "timer". nukes temp3.
	movf	temp2,w		; get timer number.
	call	PutNum		; put timer number. nukes temp, temp2, temp5.
	movlw	VIS		; get "is" word.
	call	PutWord		; add word "is". nukes temp3
	PAGE2			; select code page 2.
	movf	temp4,w		; get timer value back.
	goto	UlCmd3P		; go and add the number, play the message.
UlCmd3I				; inquire timer value.
	PAGE3			; select code page 3.
	movlw	VTIMER		; get "timer" word.
	call	PutWord		; add word "timer". nukes temp3.
	movf	temp2,w		; get timer number.
	call	PutNum		; put timer number. nukes temp, temp2,.
	movlw	VIS		; get "is" word.
	call	PutWord		; add word "is". nukes temp3
	call	ReadEEw		; get timer value. returns in w.
	PAGE2			; select code page 2.
UlCmd3P
	PAGE3			; select code page 3.
	call	PutNum		; timer value number. nukes temp, temp2, temp3.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   *40<nn><zzz> program area code #n with zzz.			      ;
;	zzz blank to query.						      ;
;   *41<nn><a><b> program area code #n options #a to b [0=disable, 1=enable]. ;
;       b=blank to query.						      ;
;   *42<nn><a> a=1 Enable all NNXs, a=0 Disable all NNXs, area code #n	      ;
;       a=blank--query not supported for all NNXs.			      ;
;   *43<nn><abc><d> Enable/disable particular NNX abc in area code #n.	      ;
;       d=0 disable, d=1 enable, d=blank=query.			      ;
;   *44<nn><zzz> program area code #n with PREFIX zzz.			      ;
;       zzz blank to query.						      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UlCmd4				; patch setup
	movlw	d'3'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	UlErr1		; not enough command digits.
	
	movf	INDF,w		; get operation code 0/1/2/3/4
	sublw	d'4'		; w = w - 4
	btfss	STATUS,C	; is result negative
	goto	UlErr3		; yes, invalid command digits.
	movf	INDF,w		; no, get operation code 0/1/2/3/4
	movwf	temp		; save operation code.
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.

	PAGE3			; select page 3
	call	GetTens		; get AC index tens digit.
	PAGE2			; select page 2
	movwf	temp2		; save
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrement count of remaining bytes.
	movf	INDF,w		; get AC index ones digit
	addwf	temp2,f		; add to AC index
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	temp2,w		; get timer index sum
	sublw	EELSTAC		; subtract last AC index
	btfss	STATUS,C	; skip if result is non-negative
	goto	UlErr3		; argument error

	;; have valid area code index here.
	;; set up NNX init bits.
	swapf	temp2,w		; get temp2 (AC index) swapped.
	andlw	b'11110000'	; mask to reasonable
	movwf	nnxInit		; save
		
	clrf	eeAddrL		; clear EEPROM address lo byte.
	rrf	temp2,w		; get temp2 (AC index)
	btfsc	STATUS,C	; was low bit set?
	bsf	eeAddrL,7	; yep, add 0x0080 to address.
	addlw	high EEAC00	; add high byte of EEPROM address
	movwf	eeAddrH		; save high byte.
	
	;; at this point, a valid command digit is stored in temp,
	;; a valid area code index in temp2, and
	;; the EEPROM address of the area code table loaded.

	movf	temp,f		; get back command index.
	btfsc	STATUS,Z	; is this zero?
	goto	UlCmd40		; yep.
	decf	temp,f		; decrement command index.
	btfsc	STATUS,Z	; is this zero?
	goto	UlCmd41		; yep.
	decf	temp,f		; decrement command index.
	btfsc	STATUS,Z	; is this zero?
	goto	UlCmd42		; yep.
	decf	temp,f		; decrement command index.
	btfsc	STATUS,Z	; is this zero?
	goto	UlCmd43		; yep.
	decf	temp,f		; decrement command index.
	btfsc	STATUS,Z	; is this zero?
	goto	UlCmd44		; yep.
	;; fallthrough to here should never occur.
	goto	UlCmdNG		; bad command...

UlCmd40				; program area code.
;    *40<n><zzz> program area code #n with zzz.				      ;
	movlw	EEACOFF		; get area code offset.
	addwf	eeAddrL,f	; add to eeprom address.
	movf	cmdSize,f	; get # cmd bytes left...
	btfsc	STATUS,Z	; are there no command bytes left?
	goto	UlCmd40Q	; yep, it's a query.
	btfsc	group8,3	; is patch setup write protected?
	goto	UlErrWP		; yes.
	movf	cmdSize,w	; get command size.
	sublw	d'3'		; subtract number of digits expected.
	btfss	STATUS,Z	; result should be zero
	goto	UlErr1		; not enough command digits.
	movlw	d'3'		; get number of bytes to write.
	movwf	eeCount		; save number of bytes to write to EEPROM.
	PAGE3			; select code page 3.
	call	WriteEE		; write the 3 area code digits to EEPROM.
	PAGE2			; select code page 2.
	goto	UlCmdOK		; say OK!
	
UlCmd40Q			; query area code.
	PAGE3			; select code page 3.
	call	ReadEEw		; get a byte from EEPROM.
	call	PutWord		; write message number to buffer
	incf	eeAddrL,f	; go to next address.
	call	ReadEEw		; get a byte from EEPROM.
	call	PutWord		; write message number to buffer
	incf	eeAddrL,f	; go to next address.
	call	ReadEEw		; get a byte from EEPROM.
	call	PutWord		; write message number to buffer
	call	PlaySpc		; start playback
	PAGE2			; select code page 2
	return			; don't play CW confirmation message, play ISD.
	
UlCmd41				; program area code configuration bits.
;    *41<n><a><b> program area code #n options #a to b [0=disable, 1=enable]. ;
	movlw	EEAFOFF		; get area code flags offset.
	addwf	eeAddrL,f	; add to eeprom address.
	movf	cmdSize,f	; get count of remaining bytes.
	btfsc	STATUS,Z	; are there no command bytes left?
	goto	UlErr1		; no. not enough command digits.
	movf	INDF,w		; get bit number.
	sublw	d'4'		; w = w - 4
	btfss	STATUS,C	; is result negative
	goto	UlErr3		; yes, invalid command digits.
	PAGE3			; select code page 3
	call	ReadEEw		; read the area code config bits.
	PAGE2			; select code page 2
	movwf	temp2		; save area code config bits in temp2.
	movf	INDF,w		; get bit number.
	movwf	temp		; save bit number in temp.
	PAGE3			; select page 3
	call	GetMask		; get bit mask for selected item
	PAGE2			; select page 2
	movwf	temp3		; save mask

	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrement count of remaining bytes.
	btfsc	STATUS,Z	; are there zero bytes left?
	goto	UlCmd41Q	; yes, it's a query.

	btfsc	group8,3	; is patch setup write protected?
	goto	UlErrWP		; yes.

	movf	INDF,w		; get state byte
	andlw	b'11111110'	; only 0 and 1 permitted.
	btfss	STATUS,Z	; should be zero of 0 or 1 entered
	goto	UlErr3		; not zero, bad command.
	movf	temp,w		; get bit number
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	PAGE2			; select code page 2.
	movf	INDF,f		; get state byte
	btfss	STATUS,Z	; skip if state is zero
	goto	UlCmd411	; not zero, it's a bit set.
	movlw	VDISABL		; get word "disabled".
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	PAGE2			; select code page 2.
	movf	temp3,w		; get mask.
	xorlw	h'ff'		; invert mask.
	andwf	temp2,w		; clear bit.
	goto	UlCmd41W	; now go and write it.

UlCmd411
	movlw	VENABLE		; get word "enabled".
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	PAGE2			; select code page 2.
	movf	temp3,w		; get mask
	iorwf	temp2,w		; set bit.

UlCmd41W			; write area code config bits.
	PAGE3			; select code page 3.
	call	WriteEw		; write w into EEPROM.
	PAGE3			; select code page 3.
	call	PlaySpc		; play message.
	PAGE2			; select code page 2.
	return			; done here.
	
UlCmd41Q			; query area code control flag bit.
	movf	temp,w		; get bit number
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	PAGE2			; select code page 2.
	movf	temp2,w		; get area code flag bits.
	andwf	temp3,w		; and with mask.
	movlw	VENABLE		; get word ENABLED.
	btfsc	STATUS,Z	; is result zero?
	movlw	VDISABL		; get word DISABLED
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	call	PlaySpc		; play message
	PAGE2			; select code page 2.
	return			; done here.

UlCmd42
;    *42<n><a> a=1 Enable all NNXs, a=0 Disable all NNXs, area code #n	      ;
	btfsc	group8,3	; is patch setup write protected?
	goto	UlErrWP		; yes.
	movf	cmdSize,f	; get count of remaining bytes.
	btfsc	STATUS,Z	; is there another digit?
	goto	UlErr1		; not enough command digits.
	;; FSR now pointing at <a>.
	movf	INDF,f		; check this...
	btfsc	STATUS,Z	; is it zero?
	goto	UlCmd420	; yep
	decfsz	INDF,w		; should decrement to zero
	goto	UlErr3		; it didn't, invalid command digit.
	bsf	nnxInit,NNXCB	; set the enable control bit.
UlCmd420
	bsf	mscFlag,NNXIE	; set the initialize bit.
	goto	UlCmdOK		; done, say OK.

UlCmd43
;    *43<n><abc><d> Enable/disable particular NNX abc in area code #n.	      ;
	movf	cmdSize,f	; get count of remaining bytes.
	;; FSR now pointing at <a>.
	movlw	d'3'		; minimum mumber of digits.
	subwf	cmdSize,w	; w = cmdSize - 3.
	;; w needs to be >= 0 (non-negative)
	btfss	STATUS,C	; c is set if non-negative.
	goto	UlErr1		; not enough command digits.
	;; start checking first digit.
	movlw	d'2'		; w=2; lowest digit for first NNX.
	subwf	INDF,w		; w = INDF - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	UlErr3		; invalid command digits.
	movf	INDF,w		; get first digit of NNX.
	sublw	d'9'		; w = 9 - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	UlErr3		; invalid command digits.
	movf	INDF,w		; get first digit of NNX.
	movwf	temp2		; save first digit of NNX.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrement count of remaining bytes.
	;; check 2nd digit of NNX.
	movf	INDF,w		; get 2nd digit of NNX.
	sublw	d'9'		; w = 9 - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	UlErr3		; invalid command digits.
	movf	INDF,w		; get 2nd digit of NNX.
	movwf	temp3		; save 2nd digit of NNX.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrement count of remaining bytes.
	;; check 3rd digit of NNX.
	movf	INDF,w		; get 3rd digit of NNX.
	sublw	d'9'		; w = 9 - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	UlErr3		; invalid command digits.
	movf	INDF,w		; get 3rd digit of NNX.
	movwf	temp4		; save 3rd digit of NNX.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrement count of remaining bytes.
	btfsc	STATUS,Z	; any digits left?
	goto	Cmd43b		; no; inquiry.
	btfsc	group8,3	; is patch setup write protected?
	goto	UlErrWP		; yes.
Cmd43b	
	;; all three digits of the NNX are good.
	PAGE3			; select code page 3.
	movf	temp2,w		; get 1st digit.
	call	PutWord		; add word to buffer.
	movf	temp3,w		; get 2nd digit.
	call	PutWord		; add word to buffer.
	movf	temp4,w		; get 3rd digit.
	call	PutWord		; add word to buffer.
	PAGE2			; select code page 2.
	;; multiply 2nd digit by 10.
	movf	temp3,w		; get 2nd digit.
	movwf	temp		; save it.
	addlw	h'0'		; clear carry.
	rlf	temp,f		; temp = temp * 2
	rlf	temp,f		; temp = temp * 4
	rlf	temp,w		; w = temp * 8
	addwf	temp3,w		; w = w + temp3
	addwf	temp3,w		; w = w + temp3 (really now temp3 * 10)
	addwf	temp4,w		; w = w + temp4 (really now temp3 * 10 + temp4)
	addwf	eeAddrL,f	; now have address of EEPROM byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; get eeprom byte.
	PAGE2			; select code page 2.
	movwf	temp3		; save eeprom byte.
	movlw	d'2'		; offset for first digit of NNX.
	subwf	temp2,w		; w now has bit number.
	PAGE3			; select page 3
	call	GetMask		; get bitmask for message.
	PAGE2			; select page 2
	movwf	temp		; save mask.
	;; at this point, temp has a mask with the selected bit set.
	;; temp2 has the bit number.
	;; temp3 has the bitmask for the 2nd & 3rd NNX digits.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	goto	UlCmd43x	; no more digits, must be inquiry.
	movf	INDF,f		; check INDF...
	btfss	STATUS,Z	; is it a SET or a CLEAR operation?
	goto	UlCmd43s	; it is a SET.
	movf	temp,w		; get mask.
	xorlw	h'ff'		; invert mask.
	andwf	temp3,w		; apply to eeprom mask.
	PAGE3			; select code page 3.
	call	WriteEw		; save it back to the EEPROM.
	PAGE2			; select code page 2.
	movlw	VDISABL		; get word "DISABLED".
	goto	UlCmd43w	; done.
	
UlCmd43s			; set bit
	movf	temp,w		; get mask.
	iorwf	temp3,w		; set bit.
	PAGE3			; select code page 3.
	call	WriteEw		; save it back to the EEPROM.
	PAGE2			; select code page 2.
	movlw	VENABLE		; get word "ENABLED".

UlCmd43w
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; don't play CW confirmation message, play ISD.

UlCmd43x			; inquiry
	movf	temp3,w		; get eeprom mask.
	andwf	temp,w		; and with selected NNX mask.
	movlw	VDISABL		; get word "DISABLED".
	btfss	STATUS,Z	; is result of andwf zero?
	movlw	VENABLE		; no, get word enable.
	PAGE3			; select code page 3.
	call	PutWord		; add word to buffer.
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; don't play CW confirmation message, play ISD.

UlCmd44				; program area code.
;    *44<n><zzz> program area code #n with PREFIX zzz.
	movlw	EEACPFX		; get area code prefix offset.
	addwf	eeAddrL,f	; add to eeprom address.
	movf	cmdSize,f	; get count of remaining bytes.
	btfsc	STATUS,Z	; are there no command bytes left?
	goto	UlCmd44Q	; yep, it's a query.
	btfsc	group8,3	; is patch setup write protected?
	goto	UlErrWP		; yes.
	
	movf	cmdSize,w	; get command size.
	sublw	EEACPFL		; subtract max number of digits allowed.
	btfss	STATUS,C	; result should be non-negative.
	goto	UlErr2		; too many command digits.
	movf	cmdSize,w	; get number of bytes left.
	movwf	eeCount		; save number of bytes to write to EEPROM.
	incf	eeCount,f	; increment eeCount so FF gets copied.
	PAGE3			; select code page 3.
	call	WriteEE		; write the 3 area code digits to EEPROM.
	PAGE2			; select code page 2.
	goto	UlCmdOK		; say OK!
	
UlCmd44Q			; query area code.
	PAGE3			; select code page 3.
	call	ReadEEw		; get eeprom byte.
	PAGE2			; select code page 2.
	movwf	temp		; save eeprom byte to temp.
	xorlw	h'ff'		; check to see if it equals FF
	btfsc	STATUS,Z	; now equal to zero?
	goto	UlCmd44P	; yes.	play words.
	movf	temp,w		; get saved byte back.
	PAGE3			; select code page 3.
	call	HexWord		; get word for digit.
	call	PutWord		; add word to speech buffer.
	PAGE2			; select code page 2.
	incf	eeAddrL,f	; move to next digit.
	goto	UlCmd44Q	; loop.

UlCmd44P			; play number.
	PAGE3			; select code page 3.
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; done here.
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; *5 Autodial Program							      ;
;									      ;
;   *50<n><number> program emergency autodial slot #n			      ;
;     0 <= n < = 9							      ;
;     number  phone number, 1-15 digits.				      ;
;     leave number blank to inquire.					      ;
;									      ;
;   *51<n> clear emergency autodial slot #n				      ;
;     0 <= n < = 9							      ;
;									      ;
;   *52<nn><number>							      ;
;     00 <= nn < = 99							      ;
;     number  phone number, 1-15 digits.				      ;
;     leave number blank to inquire.					      ;
;									      ;
;   *53<nn> clear autodial slot #nn					      ;
;     00 <= nn < = 99							      ;
;									      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
UlCmd5				; autodial setup
	movf	cmdSize,f	; check for zero..
	btfsc	STATUS,Z	; is it zero?
	goto	UlErr1		; not enough command digits.
	movf	INDF,w		; get command byte.
	movwf	temp		; save temp command byte.
	decf	cmdSize,f	; decrement command size.
	incf	FSR,f		; move to next command digit.
	movf	temp,w		; get temp command byte back.
	sublw	d'3'		; w = 3 - w
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; invalid command digit.
	btfsc	temp,1		; is it 2 or 3?
	goto	UlCmd52		; yep.
	
UlCmd50				; *50 or *51, program/clear emergency autodial.
	movf	INDF,w		; get emergency autodial number.
	sublw	d'9'		; w = 9-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; invalid command digit.
	movlw	high EEAAB	; get hi byte of EEPROM address emerg autod.
	movwf	eeAddrH		; set hi byte EEPROM address.
	movlw	low EEAAB	; get lo byte of EEPROM address emerg autod.
	movwf	eeAddrL		; set lo byte EEPROM address.
	swapf	INDF,w		; multiply autodial number by 16.
	andlw	h'f0'		; mask all but high bits.
	addwf	eeAddrL,f	; add to eeprom address.
	decf	cmdSize,f	; decrement command size.
	incf	FSR,f		; move to next command digit.
	btfsc	temp,0		; is it *51, clear emergency autodial slot?
	goto	UlCmd51		; yes.
	movf	cmdSize,f	; check command size for zero...
	btfss	STATUS,Z	; is it zero?
	goto	UlCmd50P	; no, some digits left, program autodial slot.
	;; play autodial slot.
UlCmd50a
	PAGE3			; select code page 3.
	call	ReadEEw		; get eeprom byte.
	PAGE2			; select code page 2.
	movwf	temp		; save eeprom byte to temp.
	xorlw	h'ff'		; check to see if it equals FF
	btfsc	STATUS,Z	; now equal to zero?
	goto	UlCmd50b	; yes.	play words.
	movf	temp,w		; get saved byte back.
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buffer.
	PAGE2			; select code page 2.
	incf	eeAddrL,f	; move to next digit.
	goto	UlCmd50a	; loop.
UlCmd50b			; play number.
	PAGE3			; select code page 3.
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; done here.
	
UlCmd50P			; program emergency/normal autodial.
	btfsc	group8,4	; are autodials write protected?
	goto	UlErrWP		; yes.

	movf	cmdSize,w	; get command size
	sublw	d'15'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 9)
	goto	UlErr2		; too many command digits.
	movf	cmdSize,w	; get command length
	movwf	eeCount		; save # bytes to write.
	incf	eeCount,f	; add 1 so FF at end of buffer gets copied.
	PAGE3			; select code page 3.
	call	WriteEE		; write the prefix.
	PAGE2			; select code page 2.
	goto	UlCmdOK		; good command...
	
UlCmd51				; clear emergency autodial
	movf	cmdSize,f	; no, it's not, check for zero more bytes.
	btfss	STATUS,Z	; zero bytes left?
	goto	UlErr2		; too many command digits.
	movlw	h'ff'		; set EOM marker.
	PAGE3			; select code page 3.
	call	WriteEw		; write W into the EEPROM at indicated address.
	PAGE2			; select code page 2.
	goto	UlCmdOK		; good command...
	
UlCmd52				; program normal autodial.
	movlw	d'3'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	UlErr1		; not enough command digits.
	movf	INDF,w		; get digit 1 of autodial slot number
	sublw	d'2'		; w = 2-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; invalid command digit. (not 0-2)
	clrw			; clear w
	btfsc	INDF,1		; is it a 2?
	movlw	d'200'		; yes
	btfsc	INDF,0		; is it a 1?
	movlw	d'100'		; yes
	movwf	temp2		; save hundreds place

	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	btfss	temp2,7		; check for >128
	goto	UlCmd52a	; no.
	
	movf	INDF,w		; get digit 2 of autodial slot number.
	sublw	d'4'		; w = 4-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; invalid command digit.
	goto	UlCmd52b	; valid digit.
	
UlCmd52a
	movf	INDF,w		; get digit 2 of autodial slot number.
	sublw	d'9'		; w = 9-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; invalid command digit.
UlCmd52b			; 
	PAGE3			; select page 3
	call	GetTens		; get value of tens.
	PAGE2			; select page 2
	addwf	temp2,f		; add to running total.
	
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	INDF,w		; get digit 3 of autodial slot number
	sublw	d'9'		; w = 9-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlErr3		; invalid command digit.
	movf	INDF,w		; get digit 3 of autodial slot number
	addwf	temp2,f		; add to timer index
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	;; valid 000-249 here.
	movlw	high EEADBS	; get hi byte of autodial base EEPROM address.
	movwf	eeAddrH		; set hi byte EEPROM address.
	movlw	low EEADBS	; get lo byte of autodial base EEPROM address.
	movwf	eeAddrL		; set lo byte EEPROM address.
	;; voodoo hack calculate autodial slot address.
	;; since all slots are 16 bytes, then...
	swapf	temp2,w		; multiply by 16.
	andlw	h'f0'		; low nibble of product.
	addwf	eeAddrL,f	; add to lo byte of eeprom address.	
	swapf	temp2,w		; swap nibbles of slot #
	andlw	h'0f'		; mask to leave low nibble.
	addwf	eeAddrH,f	; add to hi byte of eeprom address.
	btfsc	temp,0		; is it *53, clear autodial slot?
	goto	UlCmd51		; yes it is. UlCmd51 clears it.
	movf	cmdSize,f	; no, it's not, check for zero more bytes.
	btfss	STATUS,Z	; zero bytes left?
	goto	UlCmd50P	; go program the autodial.
	goto	UlCmd50a	; playback contents of autodial slot.
	
UlCmd6				; user commands setup
	goto	UlCmdNG		; bad command...

; *****************************************************************************
; **   *7								     **
; **   Record/Play CW and Courtesy Tones				     **
; **	*70 play CW ID							     **
; **	*70 <dd..dd..dd..> program cw message n with CW data in dd.dd.dd     **
; **			   see CW encoding table.			     **
; **									     **
; **	*71<n> play courtesy tone n, 0 <= n <= 7 (n is in range 0 to 7)	     **
; **	*71<n><ddtt,ddtt...> record courtesy tone n, 0 <= n <= 7	     **
; **	      dd is duration in 10 ms increments. 01 <= dd <=99		     **
; **	      tt is tone.  See tone table.  00 <= tt <= 63		     **
; *****************************************************************************
UlCmd7
	movf	cmdSize,f	; check command size.
	btfsc	STATUS,Z	; is it zero?
	goto	UlErr1		; not enough command digits.
	movf	INDF,f		; check command digit for zero.
	btfsc	STATUS,Z	; is it zero?
	goto	UlCmd70		; yes.
	decfsz	INDF,w		; decrement and test.
	goto	UlErr3		; was not 1 either.
UlCmd71				; Courtesy Tone Command.
	incf	FSR,f		; move to next byte.
	decf	cmdSize,f	; decrement commandSize.
	btfsc	STATUS,Z	; is result zero?
	goto	UlErr1		; yes. insufficient command digits.
	movf	INDF,w		; get command digit.
	movwf	temp2		; save index.
	sublw	d'7'		; subtract biggest argument.
	btfss	STATUS,C	; is result non-negative?
	goto	UlErr3		; nope. bad command digit.
	incf	FSR,f		; move to next byte.
	decf	cmdSize,f	; decrement commandSize.
	btfss	STATUS,Z	; is result zero?
	goto	UC71R		; record CT.
UC71P				; play courtesy tone.
	movf	temp2,w		; get index.
	movwf	cTone		; save CT index.
	PAGE3			; select code page 3.
	call	PlayCT		; play courtesy tone #w
	PAGE2			; select code page 2.
	return			; done.

UC71R				; record courtesy tone.
	clrf	eeAddrH		; clear EEPROM hi byte.
	movlw	low EECTB	; get EEPROM ctsy tone table base address
	movwf	eeAddrL		; move into EEPROM address low byte
	bcf	STATUS,C	; clear carry bit.
	rlf	temp2,f		; multiply msg # by 2
	rlf	temp2,f		; multiply msg # by 2 (x4 after)
	rlf	temp2,w		; multiply msg # by 2 (x8 after)
	addwf	eeAddrL,f	; add offset of ctsy tone to ctsy base addr.
	;; now have eeprom address of CT.
	movlw	b'00000011'	; mask:	 low 2 bits.
	andwf	cmdSize,w	; check for multiple of 4 only.
	btfss	STATUS,Z	; is result zero?
	goto	UlErr3		; bad command argument.
	movf	cmdSize,w	; get command size.
	sublw	d'16'		; 16 is 8 pairs or 4 tones.
	btfss	STATUS,C	; check for non-negative.
	goto	UlErr2		; too many command digits.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	eebPtr		; set eeprom buffer put pointer
	clrf	eeCount		; clear count.
UC71RL	
	PAGE3			; select page 3
	call	GetCTen		; get 2-digit argument.
	movwf	temp		; save this byte.
	call	PutEEB		; put into EEPROM write buffer.
	PAGE2			; select page 2
	movf	temp,w		; get back byte.
	xorlw	MAGICCT		; xor with magic CT number.
	btfss	STATUS,Z	; skip if result is zero (MAGIC number used)
	goto	UC71RLa		; not the magic number.
	decfsz	eeCount,w	; is eeCount == 1?
	goto	UC71RLa		; not 1.
	PAGE3			; select page 3
	call	GetCTen		; get 2-digit argument.
	call	PutEEB		; put into EEPROM write buffer.
	PAGE2			; select code page 2.
	goto	UC71RLb		; continue on.
UC71RLa	
	PAGE3			; select page 3
	call	GetCTen		; get 2-digit argument.
	call	GetTone		; get mapped tone.
	PAGE2			; select code page 2.
	movwf	temp		; save it.
	movf	cmdSize,f	; test command size.
	btfss	STATUS,Z	; any digits left?
	bsf	temp,7		; yes, set high bit of tone.
	movf	temp,w		; get temp back
	PAGE3			; select page 3
	call	PutEEB		; put into EEPROM write buffer.
	PAGE2			; select code page 2.
UC71RLb
	movf	cmdSize,f	; test command size.
	btfss	STATUS,Z	; any digits left?
	goto	UC71RL		; yes. loop around and get the next 4.
	;; now have whole segment in buffer.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	FSR		; set address to write into EEPROM.
	PAGE3			; select code page 3.
	call	WriteEE
	PAGE2			; back to code page 2.
	goto	UlCmdOK		; OK.

UlCmd70
	incf	FSR,f		; move to next byte.
	decfsz	cmdSize,f	; decrement commandSize.
	goto	UC70R		; record CW ID.
	movlw	EECWID		; address of CW ID message in EEPROM.
	movwf	eeAddrL		; save CT base address
	clrf	eeAddrH		; save CT base address hi byte
	PAGE3			; select code page 3.
	call	PTTon		; turn on tx if not on already.
	call	PlayCWe		; kick of the CW playback.
	PAGE2			; select code page 2.
	return
UC70R				; record CW ID.
	btfsc	cmdSize,0	; bit 0 should be clear for an even length.
	goto	UlErr3		; bad command argument.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	eebPtr		; set eeprom buffer put pointer
	clrf	eeCount		; clear count.
UC70RL	
	PAGE3			; select page 3
	call	GetCTen		; get 2-digit argument.
	call	GetCW		; get CW code.
	call	PutEEB		; put into EEPROM write buffer.
	PAGE2			; select code page 2.
	movf	cmdSize,f	; test cmdSize
	btfss	STATUS,Z	; skip if it's zero.
	goto	UC70RL		; loop around.
	
	movlw	h'ff'		; mark EOM.
	PAGE3			; select page 3
	call	PutEEB		; put into EEPROM write buffer.
	PAGE2			; select code page 2.
	clrf	eeAddrH		; clear hi byte of eeprom address.
	movlw	EECWID		; get CW ID address...
	movwf	eeAddrL		; set EEPROM address...
	movlw	low eebuf00	; get address of eebuffer.
	movwf	FSR		; set address to write into EEPROM.
	PAGE3			; select code page 3.
	call	WriteEE
	PAGE2			; back to code page 2.
	goto	UlCmdOK		; OK.
	
; ************
; ** UlCmd8 **
; ************
	;; play/record from ISD...  
UlCmd8				; play/record voice messages
	movf	INDF,w		; get 3rd byte..
	btfsc	STATUS,Z	; is it zero? (play cmd)
	goto	UlCmd8P		; play...
	movlw	h'01'		; get record command
	subwf	INDF,w		; subtract record command
	btfss	STATUS,Z	; is it zero?
	goto	UlErr3		; argument error
	;; 3rd digit was 1, record command
	incf	FSR,f		; increment command pointer; now at 4th digit
	decf	cmdSize,f	; decrease command size
	PAGE3			; select page 3
	call	GetDNum		; get the decimal number that follows
	PAGE2			; select page 2
	movwf	isdRMsg		; save message number.

	sublw	d'95'		; subtract highest protected number.
	btfss	STATUS,C	; skip if result is non-negative.
	goto	UlCmd8R		; result is negative
	;; message number is 95 or less.
	btfss	group8,7	; are ISD messages write protected?
	goto	UlCmd8R		; no.  record it.
	movlw	h'ff'		; set invalid record message number.
	movwf	isdRMsg		; save message number.
	goto	UlErrWP		; yes.

UlCmd8R 
	bsf	isdFlag,ISDRECR ; set record mode flag
	PAGE3			; select code page 3.
	movlw	VRECORD		; get word "RECORD"
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movlw	VMESSAG		; get word "MESSAGE"
	call	PutWord		; add word to speech buf. nukes temp5, temp6.
	movf	isdRMsg,w	; get message number
	call	PutNum		; put msg num. nukes temp, temp2, temp5, temp6.
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; done.
	
UlCmd8P				; 3rd digit was 0, playback command
	incf	FSR,f		; increment command pointer; now at 4th digit
	decf	cmdSize,f	; decrease command size
	PAGE3			; select page 3
	call	GetDNum		; get the decimal number that follows
	call	PutWord		; write message number to buffer
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; don't play CW confirmation message, play ISD.
	
UlCmd9				; reserved.
	goto	UlCmdNG		; bad command.

UlCmdA				; devel cmd *A
UlCmdB				; devel cmd *B
UlCmdC				; devel cmd *C
UlCmdD				; devel cmd *D
	goto	UlCmdNG		; bad command
	
UlCmdE				; devel cmd **, restart controller.
	goto	UlCmdE		; Loop forever, until restart via wdt timeout.

UlCmdF				; devel cmd *
	goto	UlCmdNG		; bad command
	
UlCmdOK				; "OK"
	movlw	VOK		; get word "OK".
	goto	UlErrX		; finish message.

UlCmdNG				; "BAD COMMAND"
	PAGE3			; select code page 3.
	movlw	VBAD		; get word "bad".
	call	PutWord		; add word to speech buf.
	PAGE2			; select code page 2.
	movlw	VCOMMND		; get word "command".
	goto	UlErrX		; finish the error message.
	
UlErrWP				; write protected error message..
	PAGE3			; select code page 3.
	movlw	VRECORD		; get word "record".
	call	PutWord		; add word to speech buf. nukes temp3.
	movlw	VACCESS		; get word "access".
	call	PutWord		; add word to speech buf. nukes temp3.
	PAGE2			; select code page 2.
	movlw	VDISABL		; get word "disabled"
	goto	UlErrX		; finish the error message

UlErr1				; error 1: not enough command digits
	movlw	V1		; get word "one".
	movwf	temp		; save for UlErr.
	goto	UlErr		; finish the error message

UlErr2				; error 2: too many command digits
	movlw	V2		; get word "two".
	movwf	temp		; save for UlErr.
	goto	UlErr		; finish the error message

UlErr3				; error 3: invalid command digits
	movlw	V3		; get word "three".
	movwf	temp		; save for UlErr.
	goto	UlErr		; finish the error message

UlErr				; play error X, x in temp.
	movlw	VERROR		; get word "error".
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buf. nukes temp3.
	PAGE2			; select code page 2.
	movf	temp,w		; get word for error number.

UlErrX
	PAGE3			; select code page 3.
	call	PutWord		; add word to speech buf. nukes temp3.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.

; *************
; ** ScanTun **
; *************
ScanTun
	bsf	STATUS,RP0	; select register page 1.
	movf	scanMod,w	; get scan mode.
	bcf	STATUS,RP0	; select register page 0.
	movwf	temp		; save it into temp.
	goto	TuneTmp		; tune!
	
; *************
; ** TuneCmd **
; *************
TuneCmd				; process a fine tune Command!
	movlw	low cmdbf00	; get command buffer address
	movwf	FSR		; set pointer
	movf	INDF,w		; get cmd byte
	movwf	temp		; save it.
	incf	FSR,f		; increment cmd pointer
	decf	cmdSize,f	; decrement command size
TuneTmp				; access tune command from temp.
	movlw	high TnTable	; set high byte of address
	movwf	PCLATH		; select page
	movf	temp,w		; get command byte.
	andlw	h'0f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL
	;; jump table goes here...
TnTable
	goto	TnMode		; command 0 -- mode select/inquire.
	goto	Inc100K		; command 1 -- increment 100 KHz digit.
	goto	Inc10K		; command 2 -- increment 10 KHz digit.
	goto	Inc1K		; command 3 -- increment 1 KHz digit.
	goto	Dec100K		; command 4 -- decrement 100 KHz digit.
	goto	Dec10K		; command 5 -- decrement 10 KHz digit.
	goto	Dec1K		; command 6 -- decrement 1 KHz digit.
	goto	SetScan		; command 7 -- start scan mode. 
	goto	Inc10		; command 8 -- increment 10 Hz digit.
	goto	Dec10		; command 9 -- decrement 10 Hz digit.
	goto	Inc100		; command a -- increment 100 Hz digit.
	goto	Dec100		; command b -- decrement 100 Hz digit.
	goto	TuneRx		; command c -- receive mode.
	goto	TuneTx		; command d -- transmit mode.
	goto	TnFreq		; command E/* -- frequency entry/inquire.
	goto	TnTerm		; command F/# -- terminate tune mode.
	
TnTerm				; tune command F/#: terminate Tune Mode.
	movf	dtEFlag,w	; get eval flags
	andlw	b'11100000'	; mask all except command source indicators.
	xorlw	b'11111111'	; invert bitmask
	andwf	tuneFlg,f	; and with tuneFlg: clear unlocked bit.
	PAGE3			; select code page 3.
	movlw	VFREQ		; word "frequency"
	call	PutWord		; put word into buffer
	movlw	VCONTRL		; word "control"
	call	PutWord		; put word into buffer
	movlw	VDISABL		; word "disabled".
	call	PutWord		; put word into buffer.
	call	PlaySpc		; play the speech message.
	PAGE2			; select code page 2.
	return			; done.

SetScan				; next digit sets scan mode.
	movf	cmdSize,f	; check for zero.
	btfsc	STATUS,Z	; is it zero?
	return			; yes, ignore it...
	movf	INDF,w		; get next digit.
	;; scan commands of 0, 7, c, d, */e #/f are not valid.
	movwf	temp		; save it.
	btfsc	STATUS,Z	; is it zero?
	return			; zero is not valid.
	movlw	b'00001100'	; mask for c,d,e,f.
	andwf	temp,w		; check for cdef.
	xorlw	b'00001100'	; mask for cdef.
	btfsc	STATUS,Z	; result will be zero if c, d, e or f.
	return			; was one of c, d, e, or f
	movf	temp,w		; get temp back.
	xorlw	h'07'		; check for 7.
	btfsc	STATUS,Z	; result will be zero if 7.
	return			; was 7.
	movf	temp,w		; get temp back.
	bsf	STATUS,RP0	; select register page 1.
	movwf	scanMod		; select scan mode.
	movlw	CIVSCTM		; get scan delay
	movwf	scanTmr		; set scan timer.
	bcf	STATUS,RP0	; select register page 0.
	return			; done.	 Scan mode has been selected.

TnMode				; tune command 0: mode select/inquire
	PAGE1			; select code page 1
	goto	LCmdC4		; access tune command.

TnFreq				; tune command E/*: frequency entry/inquire.
	PAGE1			; select code page 1
	goto	LCmdC5		; access tune command.

TuneRx				; select receive mode.
	PAGE1			; select code page 1
	goto	LCmdC2		; access select link receive command.

TuneTx				; select transmit mode.
	PAGE1			; select code page 1
	goto	LCmdC3		; access select link transmit command.

Inc10				; increment 10 Hz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq1,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncHi		; increment Hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq1		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc100				; increment 100 Hz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncLo		; increment lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq2		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc1K				; increment 1 KHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncHi		; increment hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq2		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc10K				; increment 10 KHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncLo		; increment lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq3		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.
	bsf	STATUS,RP0	; select register page 1.
	movf	scanMod,f	; check scan mode.
	btfsc	STATUS,Z	; is it zero?
	goto	Inc100K		; no.
	bcf	STATUS,RP0	; select register page 0.
	PAGE3			; select code page 3.
	movlw	SCANBIP		; offset of patch bip in ROM table.
	call	PlayCTx		; play ct from table
	PAGE2			; select code page 2.

Inc100K				; increment 100 KHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncHi		; increment hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq3		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc1M				; increment 1 MHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq4,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncLo		; increment lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq4		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc10M				; increment 10 MHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq4,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncHi		; increment hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq4		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc100M				; increment 100 MHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq5,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncLo		; increment lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq5		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Inc1G				; increment 1 GHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq5,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	IncHi		; increment hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq5		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	;btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.
	
Dec10				; decrement 10 Hz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq1,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecHi		; decrement hi nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq1		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec100				; decrement 100 Hz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecLo		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq2		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec1K				; decrement 1 KHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecHi		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq2		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec10K				; decrement 10 KHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecLo		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq3		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.
	bsf	STATUS,RP0	; select register page 1.
	movf	scanMod,f	; check scan mode.
	btfsc	STATUS,Z	; is it zero?
	goto	Dec100K		; no.
	bcf	STATUS,RP0	; select register page 0.
	PAGE3			; select code page 3.
	movlw	SCANBIP		; offset of patch bip in ROM table.
	call	PlayCTx		; play ct from table
	PAGE2			; select code page 2.

Dec100K				; decrement 100 KHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecHi		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq3		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec1M				; decrement 1 MHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq4,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecLo		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq4		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec10M				; decrement 10 MHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq4,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecHi		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq4		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec100M				; decrement 100 MHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq5,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecLo		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq5		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	btfss	temp,0		; carry required?
	goto	TnTune		; no, done, now tune the radio.

Dec1G				; decrement 1 GHz digit.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq5,w	; get frequency
	bcf	STATUS,RP0	; select register page 0.
	call	DecHi		; decrement lo nibble.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq5		; save frequency
	bcf	STATUS,RP0	; select register page 0.
	
TnTune				; send the tune command then return.
	bsf	tuneFlg,SUPP_OK ; suppress OK on this tune.
	PAGE3			; select ROM page 3.
	call	CIVTune		; send the tune message.
	PAGE2			; select ROM page 2.
	return			; done.

IncHi				; increment the hi nibble in w.
	movwf	temp2		; save byte.
	clrf	temp		; clear carry indicator.
	swapf	temp2,w		; switch nibbles.
	andlw	h'0f'		; mask lo nibble.
	addlw	d'1'		; add 1
	movwf	temp3		; save result.
	xorlw	d'10'		; is result 10?
	btfss	STATUS,Z	; result will be zero if 10.
	goto	IncHiNC		; no carry.
	bsf	temp,0		; set carry indicator.
	movlw	h'0f'		; mask.
	andwf	temp2,w		; set hi nibble to zero.
	return			; done.
IncHiNC				; no carry.
	movlw	h'0f'		; mask.
	andwf	temp2,f		; clear hi nibble to zero.
	swapf	temp3,w		; get new hi nibble.
	iorwf	temp2,w		; produce new result.
	return			; done.
	
IncLo				; increment the hi nibble in w.
	movwf	temp2		; save byte.
	clrf	temp		; clear carry indicator.
	andlw	h'0f'		; mask lo nibble.
	addlw	d'1'		; add 1
	movwf	temp3		; save result.
	xorlw	d'10'		; is result 10?
	btfss	STATUS,Z	; result will be zero if 10.
	goto	IncLoNC		; no carry.
	bsf	temp,0		; set carry indicator.
	movf	temp2,w		; get old byte
	andlw	h'f0'		; clear low nibble.
	return			; done.
IncLoNC				; no carry.
	movf	temp2,w		; get old byte
	andlw	h'f0'		; clear low nibble.
	iorwf	temp3,w		; OR in new low nibble.
	return			; done.
	
DecHi				; decrement the hi nibble in w.
	movwf	temp2		; save byte.
	clrf	temp		; clear carry indicator.
	swapf	temp2,w		; switch nibbles.
	andlw	h'0f'		; mask lo nibble.
	movwf	temp3		; save result.
	movlw	d'1'		; one.
	subwf	temp3,f		; subtract temp3 = temp3 - 1
	btfsc	STATUS,C	; was there a carry?
	goto	DecHiNC		; no carry.
	bsf	temp,0		; set carry indicator.
	movlw	h'0f'		; mask.
	andwf	temp2,w		; clear hi nibble.
	iorlw	h'90'		; set hi nibble to 9.
	return			; done.
	
DecHiNC				; no carry.
	movlw	h'0f'		; mask.
	andwf	temp2,f		; clear hi nibble to zero.
	swapf	temp3,w		; get new hi nibble.
	iorwf	temp2,w		; produce new result.
	return			; done.

DecLo				; decrement the lo nibble in w.
	movwf	temp2		; save byte.
	clrf	temp		; clear carry indicator.
	andlw	h'0f'		; mask lo nibble.
	movwf	temp3		; save result.
	movlw	d'1'		; one.
	subwf	temp3,f		; subtract temp3 = temp3 - 1
	btfsc	STATUS,C	; was there a carry?
	goto	DecLoNC		; no carry.
	bsf	temp,0		; set carry indicator.
	movlw	h'f0'		; mask.
	andwf	temp2,w		; clear lo nibble.
	iorlw	h'09'		; set lo nibble to 9.
	return			; done.
DecLoNC				; no carry.
	movf	temp2,w		; get old byte
	andlw	h'f0'		; clear low nibble.
	iorwf	temp3,w		; OR in new low nibble.
	return			; done.

	org	1700		; still in page 2

; *********************
; * INITIALIZE EEPROM *
; *********************
InitEE
	clrf	temp2		; byte index
	clrf	eeAddrH		; clear EEPROM address hi byte.
InitLp
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
	movf	temp2,w		; get last address.
	sublw	h'df'		; subtract last init address.
	btfss	STATUS,C	; c will be clear if result is negative.
	goto	InitCtl		; done initializing...
	movf	temp2,w		; get init address
	movwf	eeAddrL		; set eeprom address
InitLp1
	movf	temp2,w		; get init address
	PAGE3			; select page 3
	call	InitDat		; get init byte
	PAGE2			; select page 0
	movwf	INDF		; save init byte in buffer
	incf	FSR,F		; move pointer to next byte in buffer
	incf	temp2,f		; go to next byte
	movf	temp2,w		; get init address
	andlw	h'0f'		; result 0 if on a 16-byte boundary
	btfss	STATUS,Z	; skip if on 16-byte boundary.
	goto	InitLp1		; not on 16 byte boundary, get next byte.
	movlw	h'10'		; write 16 bytes
	movwf	eeCount		; number of bytes to write to eeprom
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
	PAGE3			; select code page 3.
	call	WriteEE		; get init byte
	PAGE2			; select code page 0.
	;; pause while EE operation completes.
	call	InitPos		; pause.
	goto	InitLp		; get the next block of 16 or be done.
	
	;; initialize saved control op sets.
InitCtl
	clrf	temp2		; clear saved state indicator/down counter
	movlw	high EESSB	; get hi part of saved cntl-op address
	movwf	eeAddrH		; save hi part of address.
InitCt1
	clrf	temp3		; location inside saved state
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
InitCt2
	movf	temp3,w		; get index into control op
	PAGE3			; select page 3
	call	ICtlTab		; get init byte
	PAGE2			; select page 0
	movwf	INDF		; save the byte into the buffer
	incf	FSR,f		; move pointer to next byte in buffer
	incf	temp3,f		; go to next byte
	movf	temp3,w		; get number of bytes copied so far
	sublw	EESSCI		; subtract count of bytes in saved set
	btfss	STATUS,Z	; skip if all bytes copied
	goto	InitCt2		; copy another byte.
	movlw	low EESSB	; get base of saved control op sets
	movwf	eeAddrL		; save into eeprom address
	swapf	temp2,w		; get saved state index * 16 (hackola)
	addwf	eeAddrL,f	; add to eeprom address
	movlw	EESSCI		; get number of bytes in saved control op set
	movwf	eeCount		; set number of bytes to write into eeprom
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
	PAGE3			; select code page 3.
	call	WriteEE		; get init byte
	PAGE2			; select code page 0.
	;; pause while EE operation completes.
	call	InitPos		; pause.
	incf	temp2,f		; increment set number
	movf	temp2,w		; get set number
	sublw	EENSS		; subtract number of sets
	btfss	STATUS,Z	; skip if zero
	goto	InitCt1		; get the next block of 16 or be done.

InitPR				; initialize patch restrictions.
	;; patch restrictions at EEAC00 to EEACLST
	;; first, prepare a buffer of 32 00s.
	movlw	d'32'		; count of bytes to copy to buffer.
	movwf	temp2		; store into temp.
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
InitPR1				; loop.
	clrf	INDF		; clear buffer.
	incf	FSR,f		; next buffer location.
	decfsz	temp2,f		; decrement remaining count.
	goto	InitPR1		; loop around.

	movlw	high EEAC00	; get high byte.
	movwf	eeAddrH		; save high byte.
InitPR2
	clrf	eeAddrL		; clear low nibble.
	call	Init256		; write 256 bytes.
	incf	eeAddrH,f	; increment eeAddrH
	movf	eeAddrH,w	; get eeAddrH
	sublw	high EEACLST	; w = (high) EEACLST - eeAddrH
	btfsc	STATUS,C	; skkip is result is negative
	goto	InitPR2		; not negative, do another 256
		
InitAD				; initialize Autodial slots.
	;; first, prepare a buffer of 32 FFs.
	movlw	d'32'		; count of bytes to copy to buffer.
	movwf	temp2		; store into temp.
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
	movlw	h'ff'		; init byte.
InitAD1				; loop.
	movwf	INDF		; store into buffer.
	incf	FSR,f		; next buffer location.
	decfsz	temp2,f		; decrement remaining count.
	goto	InitAD1		; loop around.
	
	movlw	high EEADBS	; get high byte of autodial base.
	movwf	eeAddrH		; save high byte.
InitAD2
	clrf	eeAddrL		; clear low nibble.
	call	Init256		; write 256 bytes.
	incf	eeAddrH,f	; increment eeAddrH
	movf	eeAddrH,w	; get eeAddrH
	sublw	high EEADLST	; w = (high) EEADLST - eeAddrH 
	btfsc	STATUS,C	; skkip is result is negative
	goto	InitAD2		; not negative, do another 256

InitPre
	clrf	temp		; clear counter.
InitPr0
	movlw	low EEAC0P	; address of bank 0 prefix.
	movwf	eeAddrL		; save address of bank 0 prefix.
	movf	temp,w		; get temp
	movwf	eeAddrH		; save temp.
	rrf	eeAddrH,f	; /2
	btfsc	STATUS,C	; was the low bit set before rotate?
	bsf	eeAddrL,7	; yep, set the high bit of the low nibble.
	movlw	high EEAC0P	; address of bank 0 prefix.
	addwf	eeAddrL,f	; save address of bank 0 prefix.
	movlw	h'ff'		; end of prefix indicator.
	PAGE3			; select code page 3.
	call	WriteEw		; write that location.
	PAGE2			; select code page 0.
	call	InitPos		; short delay for write cycle to complete.
	incf	temp,f		; increment counter.
	movlw	EELSTAC		; get highest allowed.
	subwf	temp,w		; w = EESTAC - temp.
	btfsc	STATUS,C	; is result negative?
	goto	InitPr0		; no.
	return			; done initializing EEPROM.
	
; *************
; ** Init256 **
; *************
Init256				; initialize 256 bytes from the 32 in cmdbuf00
	movlw	d'8'		; 8 * 32 = 256. 
	movwf	temp2		; store into temp.
	movlw	d'32'		; 32 bytes to write each cycle.
	movwf	eeCount		; save eeCount:	 number of bytes to write.
I256a				; loop through writes of 32 bytes.
	movlw	low cmdbf00	; get base of buffer
	movwf	FSR		; set into FSR.
	PAGE3			; select ROM code page 3.
	call	WriteEE		; write into EEPROM.
	PAGE2			; select ROM code page 0.
	;; pause while EE operation completes.
	call	InitPos		; pause.
	movlw	d'32'		; get size.
	addwf	eeAddrL,f	; add to address.
	movwf	eeCount		; reset number of bytes to write.
	decfsz	temp2,f		; decrement cycle count.
	goto	I256a		; next cycle.
	return			; done.
	
; *************
; ** InitPos **
; *************
InitPos				; short pause for EEPROM write cycle.
	bsf	PORTA,LED2	; lite led
	movlw	d'10'		; 10 ms.
	call	InitDly		; delay.
	bcf	PORTA,LED2	; unlite led
	return			; done with pause

; *************
; ** InitDly **
; *************
InitDly				; delay w ms for init code.
	movwf	temp6		; counter.
InitDl2
	btfss	tFlags,TICK	; looking for 1 ms TICK
	goto	InitDl2		; loop.
	bcf	tFlags,TICK	; clear TICK marker.
	clrwdt			; reset WDT every ms.
	decfsz	temp6,f		; decrement counter
	goto	InitDl2		; counter not zeroed yet.
	return
	
; ************************************************************************
; ****************************** ROM PAGE 3 ******************************
; ************************************************************************
	org	1800		; page 3

; ***********
; ** GetAC **
; ***********
	;; get area code index. Dial string area code pointed at by FSR/INDF.
	;; return with index in w.  index ff = invalid area code.
GetAC
	movf	FSR,w		; get FSR to save.
	movwf	temp3		; save FSR.
	clrf	temp2		; area code index.
TryAC
	movf	temp3,w		; get saved FSR.
	movwf	FSR		; restore FSR.
	;; get EEPROM base address for area code of index temp2.

	clrf	eeAddrL		; clear EEPROM address lo byte.
	rrf	temp2,w		; get temp2 (AC index)
	btfsc	STATUS,C	; was low bit set?
	bsf	eeAddrL,7	; yep, add 0x0080 to address.
	addlw	high EEAC00	; add high byte of EEPROM address
	movwf	eeAddrH		; save high byte.

	;; now have eeprom base address for area code of index temp2.
	;; get the flags to see if this area code is enabled.
	movlw	EEAFOFF		; get area code flags offset.
	addwf	eeAddrL,f	; add to eeprom address.
	call	ReadEEw		; read the area code config bits.
	movwf	temp		; save area code config bits in temp.
	btfss	temp,ACENAB	; is this area code enabled?
	goto	NextAC		; nope.
	btfsc	temp,ACNONE	; is this the local (7-digit) area code?
	goto	NextAC		; yep.
	movlw	d'3'		; offset from area code first digit.
	subwf	eeAddrL,f	; subtract offset, now have 1st digit address.
	movlw	d'3'		; number of digits to test.
	movwf	temp		; counter of number of digits to check.
ChkAC	
	call	ReadEEw		; read the area code digit.
	;; now have area code digit in W.
	xorwf	INDF,w		; compare call digit from eeprom digit.
	btfss	STATUS,Z	; result should be zero if matched.
	goto	NextAC		; did not match, try next area code.
	incf	eeAddrL,f	; move to next address.
	incf	FSR,f		; move to next
	decfsz	temp,f		; decrement digits to test.
	goto	ChkAC		; check another digit.
	;; checked 3 digits matched.  This is the correct area code.
	movf	temp2,w		; get area code index back.
	return			; return with area code index in W.

NextAC				; move on to the next area code.
	incf	temp2,f		; increment temp2.
	movf	temp2,w		; get temp2.
	sublw	EELSTAC		; subtract from highest valid AC index.
	btfsc	STATUS,C	; C is clear if result is negative.
	goto	TryAC		; not done looking at area codes, loop around.
	retlw	h'ff'		; failure.

; ************
; ** ChkNNX **
; ************
	;; check a NNX for valid.  1st digit of NNX pointed at by FSR/INDF.
	;; area code bank pointed at by temp.
	;; returns with STATUS.Z set for invalid, clear for valid.
ChkNNX
	;; get eeprom base address for this NNX.
	clrf	eeAddrL		; clear EEPROM address lo byte.
	rrf	temp,w		; get temp2 (AC index)
	btfsc	STATUS,C	; was low bit set?
	bsf	eeAddrL,7	; yep, add 0x0080 to address.
	addlw	high EEAC00	; add high byte of EEPROM address
	movwf	eeAddrH		; save high byte.
	;; now have eeprom base address for this nnx.
	movlw	d'2'		; w=2; lowest digit for first NNX.
	subwf	INDF,w		; w = INDF - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	BadNNX		; bad NNX.
	movf	INDF,w		; get first digit of NNX.
	sublw	d'9'		; w = 9 - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	BadNNX		; invalid command digits.
	movlw	d'2'		; base of valid first digits.
	subwf	INDF,w		; 1st digit - 2 -> w
	call	GetMask		; get bitmask for message.
	movwf	temp3		; save mask.
	incf	FSR,f		; move pointer to 2nd NNX digit.
	movf	INDF,w		; get 2nd digit of NNX.
	sublw	d'9'		; w = 9 - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	BadNNX		; invalid command digits.
	movf	INDF,w		; get 2nd digit of NNX.
	movwf	temp		; save it.
	addlw	h'0'		; clear carry.
	rlf	temp,f		; temp = temp * 2
	rlf	temp,f		; temp = temp * 4
	rlf	temp,w		; w = temp * 8
	addwf	INDF,w		; w = w + 2nd digit
	addwf	INDF,w		; w = w + 2nd digit (now 2nd digit * 10)
	movwf	temp2		; save 2nd digit * 10.
	
	incf	FSR,f		; move pointer to 3rd NNX digit.
	movf	INDF,w		; get 3rd digit of NNX.
	sublw	d'9'		; w = 9 - w.
	btfss	STATUS,C	; c is set if result is non-negative.
	goto	BadNNX		; invalid command digits.
	movf	INDF,w		; get 3rd digit of NNX.
	addwf	temp2,w		; add 3rd digit, sum to w.
	addwf	eeAddrL,f	; add to EEPROM base address.
	call	ReadEEw		; read the area code config bits.
	andwf	temp3,f		; AND the mask and the retrieved byte.
	return			; return success.  Z will be clear.
	
BadNNX				; return a failure.
	clrw
	addlw	h'0'		; set STATUS.Z
	return
	
; *************
; ** MbxHdrs **
; *************
MbxHdrs				; play mailbox headers
	movf	mbxCtl,w	; get mailbox control flags.
	andlw	b'01100000'	; check to see if function in progress
	btfss	STATUS,Z	; any record function in progress?
	return			; yes.	don't play headers.  will confuse user.
	movf	mbxFlag,f	; check mbxFlags.
	btfss	STATUS,Z	; Z set if no mailbox messages.
	goto	MbxHdr1		; play headers!
	movlw	VNO		; get word "no".
	call	PutWord		; put word into buffer
	movlw	VMBX		; get word "mailbox".
	call	PutWord		; put word into buffer
	movlw	VMESSAG		; get word "message".
	call	PutWord		; put word into buffer
	call	PlaySpc		; play the speech message.
	return			; done here.

MbxHdr1				; ok to play headers.
	clrf	temp2		; reset mailbox number.
	clrf	temp3		; reset mailbox message number.
	movlw	VMBX		; get word "mailbox".
	call	PutWord		; put word into buffer
MbxHdr2
	movf	temp2,w		; get message counter
	call	GetMask		; get bitmask for message.
	andwf	mbxFlag,w	; and with mailbox flag.
	btfsc	STATUS,Z	; zero if message slot empty
	goto	MbxHdr3		; empty slot.
	incf	temp3,f		; increase mailbox message number
	movf	temp3,w		; get mailbox message number
	call	PutWord		; put word into buffer
	movf	temp2,w		; get temp2
	addlw	VMB1H		; add index of mailbox 1 header
	call	PutWord		; put word into buffer
MbxHdr3				; increment mailbox number and test for done.
	incf	temp2,f		; move to next mailbox
	movf	temp2,w		; get mailbox number
	sublw	MAXMBX		; subtract w from last mbx number, zero-based.
	btfsc	STATUS,C	; c will be set if >= 0.
	goto	MbxHdr2		; try next slot
	call	PlaySpc		; play the speech message.
	return			; done with all slots.
	
; ************
; ** PlayCW **
; ************
	;; play CW from ROM table.  Address in W.
PlayCW
	movwf	temp		; save CW address.
	movf	beepCtl,w	; get beep control flag.
	btfss	STATUS,Z	; result will be zero if no.
	call	KillBeep	; kill off beep sequence in progress.
	movf	temp,w		; get back CW address.
	movlw	beepAdrL	; set CW address.
	clrf	beepAdrH	; clear hi byte of CW address.
	movlw	CW_ROM
	movwf	beepCtl		; set control flags.
	call	GtBeep		; get next character.
	goto	PlayCWx		; finish starting up CW.

; ************
; ** PlayCWe**
; ************
	;; play CW from EEPROM addresses named by eeAddrL & eeAddrH
PlayCWe
	movf	beepCtl,w	; get beep control flag.
	btfss	STATUS,Z	; result will be zero if no.
	call	KillBeep	; kill off beep sequence in progress.
	;andlw	b'00011100'	; is the beeper already busy?
	;btfss	STATUS,Z	; result will be zero if no.
	;call	KillBeep	; kill off beep sequence in progress.
	movf	eeAddrL,w	; get lo byte of address.
	movwf	beepAdrL	; set lo byte of address of beep.
	movf	eeAddrH,w	; get hi byte of address.
	movwf	beepAdrH	; set hi byte of address of beep.
	movlw	CW_EE		; select CW from EEPROM
	movwf	beepCtl		; set control flags.
	call	GtBeep		; get next character.
	goto	PlayCWx		; finish CW startup

; *************
; ** PlayCWL **
; *************
	;; play single CW letter, code in w.
PlayCWL
	movwf	temp		; save letter.
	movf	beepCtl,w	; get beep control flag.
	andlw	b'00011100'	; is the beeper already busy?
	btfss	STATUS,Z	; result will be zero if no.
	call	KillBeep	; kill off beep sequence in progress.
        movlw   CW_LETR		; select CW single letter mode.
        movwf   beepCtl         ; set control flags.
	movf	temp,w		; get letter back.
	call	GetCW		; get CW bitmap.

PlayCWx				; finish CW play startup.
	movwf	cwByte		; save byte in CW bitmap
	movlw	CWIWSP		; get startup delay
	movwf	cwTmr		; preset cw timer
	bcf	tFlags,CWBEEP	; make sure that beep is off
	bsf	txFlag,CWPLAY	; turn on CW sender
	call	PTTon		; turn on PTT...
	btfss	beepCtl,B_MAIN	; turn on main audio?
	return			; done.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	return

; *************
; ** PlayCTx **
; *************
	;; play a courtesy tone from the ROM table.
	;; courtesy tone offset in W.
PlayCTx				; play a courtesy tone
	movwf	temp		; save the courtesy tone offset.
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; result will be zero if no.
	return			; already beeping.
	movf	temp,w		; get back courtesy tone offset.
	movwf	beepAdrL	; set beep address lo byte.
	clrf	beepAdrH	; clear beep address hi byte.
	movlw	BEEP_CX		; CT beep. (from table)
	movwf	beepCtl		; set control flags.
	movlw	CTPAUSE		; initial delay.
	movwf	beepTmr		; set initial start
	bsf	txFlag,BEEPING	; beeping is enabled!
	btfss	beepCtl,B_MAIN	; turn on main audio?
	return			; done.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	return			; done.

; ************
; ** PlayCT **
; ************
	;; play courtesy tone # cTone from EEPROM.
PlayCT				; play a courtesy tone.
	btfsc	cTone,7		; sleazy easy check for no CT...
	return			; courtesy tone is suppressed.
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; result will be zero if no.
	return			; already beeping.
	movlw	CT_BASE		; get CT base.
	movwf	beepAdrL	; save CT base address.
	clrf	beepAdrH	; save CT base address hi byte.

	movf	cTone,w		; examine cTone.
	andlw	h'07'		; force into reasonable range.
	movwf	temp		; copy to temp.
	bcf	STATUS,C	; clear carry bit.
	rlf	temp,f		; multiply msg # by 2
	rlf	temp,f		; multiply msg # by 2 (x4 after)
	rlf	temp,w		; multiply msg # by 2 (x8 after)
	addwf	beepAdrL,f	; add offset of ctsy tone to beep base addr.
	;; now have EEPROM address of CT. reset courtesy tone indicator.
	movlw	CTNONE		; get no CT indicator.
	movwf	cTone		; save it.
	clrf	eeAddrH		; clear EEPROM hi address.
	movf	beepAdrL,w	; get low byte of EEPROM address.
	movwf	eeAddrL		; set low byte of EEPROM address.

	call    ReadEEw         ; read 1 byte from EEPROM.
	movwf	temp		; save eeprom data.
	btfsc	STATUS,Z	; is it zero?
	goto	PlayCTV		; yes.
	xorlw	MAGICCT		; xor with magic CT number.
	btfss	STATUS,Z	; skip if result is zero (MAGIC number used)
	goto	PlayCT1		; play normal CT segment.

	;; this is where the morse digit send goes.
	incf	eeAddrL,f	; move to next byte of CT.
	call    ReadEEw         ; read 1 byte from EEPROM.
	goto	PlayCWL		; play the CW letter
	
PlayCTV
	movlw	VCTONE		; get courtesy tone message.
	call	PutWord		; put word into buffer
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PlaySpc		; play the speech message.
	return			; done.

PlayCT1
	movlw	BEEP_CT		; CT beep.
	movwf	beepCtl		; set control flags.
	movlw	CTPAUSE		; initial delay.
	movwf	beepTmr		; set initial start
	bsf	txFlag,BEEPING	; beeping is enabled!
	btfss	beepCtl,B_MAIN	; turn on main audio?
	return			; done.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	return			; done.

PlayDTA
; **************
; ** PlayDTA **
; **************
	;; play DTMF sequence from RAM address indicated by W
	;; over the air.  for regenerate DTMF.
	movwf	temp		; save beep address.
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; skip if not beeping
	return			; don't try to start beeping then.
	movf	temp,w		; get back beep address.
	movwf	beepAdrL	; save beep address lo byte.
	clrf	beepAdrH	; clear beep address hi byte.
	movlw	BEEPDTA		; DTMF beep.
	goto	PlayDT1		; start beeping...
	
; *************
; ** PlayADT **
; *************
	;; play DTMF from EEPROM, starting from address in beepAdrL & beepAdrH
	;; for autodials
PlayADT
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; skip if not beeping
	return			; don't try to start beeping then.
	movf	eeAddrH,w	; get eeprom address hi byte.
	movwf	beepAdrH	; set beep address hi byte.
	movf	eeAddrL,w	; get eeprom address lo byte.
	movwf	beepAdrL	; set beep address lo byte.
	movlw	BEEPADT		; DTMF beep for autodial.
	goto	PlayDT1
	
; **************
; ** PlayDTMF **
; **************
	;; play DTMF sequence from RAM address indicated by beepAdrL.
	;; for dialing patch, etc.
PlayDTMF
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; skip if not beeping
	return			; don't try to start beeping then.
	movlw	low dtXbuf0	; get address of xmit buffer
	movwf	beepAdrL	; set beep address.
	clrf	beepAdrH	; clear hi byte of beep address.
	movlw	BEEP_DT		; DTMF beep.
PlayDT1
	movwf	beepCtl		; set control flags.
	movlw	DTMFPRE		; initial delay.
	movwf	beepTmr		; set initial start
	bsf	txFlag,DTMFING	; beeping is enabled!
	bcf	outPort,BEEPAUD ; turn beeps on main off
	btfsc	beepCtl,B_MAIN	; are beeps on main wanted?
	bsf	outPort,BEEPAUD ; yet, turn on audio gate
	call	SetPort		; set the port.
	return			; done.

; ************** 
; ** KillBeep **
; ************** 
	;; kill off whatever is beeping now.
KillBeep
	btfsc	beepCtl,B_MAIN	; did beep turn on audio gate?
	bcf	outPort,BEEPAUD ; yes turn off audio
	call	SetPort		; set the port.
	clrf	beepTmr		; clear beep timer
	clrf	beepCtl		; clear beep control flags
	;; clear beeping tx flags...
	movlw	b'00101111'	; mask to clear various beep bits.
	andwf	txFlag,f	; clear various beep bits.
	return
	
; *************
; ** GetBeep **
; *************
	;; get the next beep tone from whereever.
	;; select the tone, etc.
	;; uses temp.
GetBeep				; get the next beep character
	btfss	beepCtl,B_DTMF	; in DTMF mode?
	goto	BeepCT		; no.  Must be in courtesy tone mode.
	movlw	DTMFLEN		; DTMF length
	movwf	beepTmr		; set pause timing
	btfss	beepCtl,B_PAUSE ; inter-digit pause selected?
	goto	BpDtNp		; yep. set pause next.
	bcf	beepCtl,B_PAUSE ; was paused, clear pause indicator.
	call	GtBeep		; get next char
	movwf	temp2		; save tone byte
	incf	temp2,f		; add 1
	btfsc	STATUS,Z	; was result zero?
	goto	BDTD0		; yes.
	andlw	h'0f'		; mask to valid dtmf
	iorlw	h'10'		; force to DTMF tones range
	movwf	temp		; save tone byte.
	xorlw	h'1f'		; look for the #
	btfss	STATUS,Z	; is it zero (was # digit)?
	goto	SetBeep		; no, set the beep!
	movlw	DTMFPOZ		; get pause duration.
	movwf	beepTmr		; save pause length.
	clrf	temp		; select quiet tone.
	goto	SetBeep		; start playing the beep.

BDTD0				; done beeping DTMF.
	clrf	temp		; set quiet beep
	bcf	txFlag,DTMFING	; not DTMFing any more.
	btfsc	beepCtl,B_MAIN	; did beep turn on audio gate?
	bcf	outPort,BEEPAUD ; yes turn off audio
	call	SetPort		; set the port.
	clrf	beepTmr		; clear beep timer
	btfss	outPort,FONECTL ; is phone on?
	goto	BDTDone		; no.
	btfsc	beepCtl,B_MAIN	; was beep over air?
	goto	BDTDone		; yes.	done.
	call	FoneOn		; yes, turn on phone audio.
BDTDone	       
	clrf	beepCtl		; clear beep control flags
	return			; now done.
	
BpDtNp				; select pause...
	bsf	beepCtl,B_PAUSE ; set pause indicator
	clrf	temp		; select NO TONE
	goto	SetBeep		; set up the tone and return.

BeepCT				; beep courtesy tone.
	btfsc	beepCtl,B_LAST	; was the last segment just sent?
	goto	BeepDone	; yes.	stop beeping.
	call	GtBeep		; get length byte
	movwf	beepTmr		; save length
	call	GtBeep		; get tone byte
	;; do I want to convert it here?
	movwf	temp		; save tone byte
	btfss	temp,7		; is the continue bit set?
	bsf	beepCtl,B_LAST	; no. mark this segment last.
	movlw	b'00111111'	; mask
	andwf	temp,f		; mask out control bits.
	goto	SetBeep		; set the beep tone

BeepDone			; stop that confounded beeping...
	clrf	temp		; set quiet beep
	bcf	txFlag,BEEPING	; beeping is done...
	btfsc	txFlag,TALKING	; don't turn off audio gate if talking.
	goto	SetBeep		; talking, don't turn off audio gate.
	bcf	outPort,BEEPAUD ; turn off audio gate
	clrf	beepCtl		; clear beep control flags
	clrf	beepTmr		; clear beep timer
	call	SetPort		; set the port.

SetBeep
	movf	temp,w		; get beep tone 
	movwf	PORTD		; write beep tone info to port
	bsf	PORTB,TONESEL	; set PDC3311 STROBE high
	nop			; short delay (PDC3311 requires 400 ns here)
	bcf	PORTB,TONESEL	; set PDC3311 STROBE low (500 ns pulse)
	return

GtBeep				; get the next character for the beep message
	movf	beepCtl,w	; get control flag bits
	andlw	b'00000011'	; mask significant control flag bits.
	movwf	temp		; save w
	movlw	high GtBpTbl	; set page 
	movwf	PCLATH		; select page
	movf	temp,w		; get tone into w
	addwf	PCL,f		; add w to PCL
	
GtBpTbl
	goto	GtBEE		; get beep char from EEPROM
	goto	GtBROM		; get beep char from hardcoded ROM table
	goto	GtBRAM		; get beep char from RAM address
	goto	GtBLetr		; get beep for single CW letter.
	
GtBEE				; get beep char from EEPROM
	movf	beepAdrH,w	; get hi byte of EEPROM address
	movwf	eeAddrH		; store to EEPROM address hi byte
	movf	beepAdrL,w	; get lo byte of EEPROM address
	movwf	eeAddrL		; store to EEPROM address lo byte
	incf	beepAdrL,f	; increment pointer
	call	ReadEEw		; read 1 byte from EEPROM
	return			;
GtBROM				; get beep char from ROM table
	movf	beepAdrL,w	; get address low byte (hi is not used here)
	incf	beepAdrL,f	; increment pointer
	call	MesgTabl	; get char from table
	return			;
GtBRAM				; get beep char from RAM
	movf	beepAdrL,w	; get address low byte (hi is not used here)
	movwf	FSR		; set indirect register pointer
	incf	beepAdrL,f	; increment pointer
	movf	INDF,w		; get data byte from RAM
	return			; 

GtBLetr				; get single CW letter.
	retlw	h'ff'		; return ff.

; *************
; ** SetPort **
; *************
SetPort				; copy outport to latch
	movf	outPort,w	; get outport value
	movwf	PORTD		; copy to port
	bsf	PORTC,OUTSEL	; raise output port enable
	nop			; short delay
	bcf	PORTC,OUTSEL	; lower output port enable
	return			; done here.

; ***********
; ** PTTon **
; ***********
	;; turn on PTT & set up ID timer, etc., if needed.
PTTon				; key the transmitter
	btfsc	flags,TXONFLG	; is transmitter already on?
	return			; yep.
	;; transmitter was not already on. turn it on.
	bsf	outPort,TX0PTT	; apply PTT!
	;; set the remote base transmitter on if enabled and is a repeater.
	btfss	group5,2	; is port 2 tx enabled?
	goto	PTTOn1		; nope.
	btfss	group3,3	; is port 2 a repeater?
	goto	PTTOn1		; nope.
	bsf	outPort,TX1PTT	; turn on port 2 PTT.
PTTOn1				; 
	call	SetPort		; set the output pin
	bsf	flags,TXONFLG	; set last tx state flag
	movf	idTmr,f		; check ID timer
	btfsc	STATUS,Z	; is it zero?
	goto	PTTinit		; yes
	btfsc	flags,needID	; is needID set?
	goto	FanOn		; yes.
	goto	PTTset		; not set, set needID and reset idTmr
PTTinit
	bsf	flags,initID	; ID timer was zero, set initial ID flag
PTTset
	bsf	flags,needID	; need to play ID
	clrf	eeAddrH		; clear eeprom address hi byte
	movlw	EETID		; get address of ID timer
	movwf	eeAddrL		; set address of ID timer
	call	ReadEEw		; get byte from EEPROM
	movwf	idTmr		; store to down-counter
FanOn
	btfss	group3,4	; is fan control enabled?
	return			; no.
	clrf	fanTmr		; disable fan timer, fan stays on.
	bsf	outPort,FANCTL	; turn on fan
	return			; done here

; ************
; ** PTToff **
; ************
PTToff
	;; don't care if already off, turn off again. (can't hurt)
	bcf	outPort,TX0PTT	; turn off main PTT!
	bcf	outPort,TX1PTT	; turn off link PTT unequivocally
	bcf	flags,TXONFLG	; clear last tx state flag
	call	SetPort		; set the output pin
	btfss	group3,4	; is fan control enabled?
	return			; no.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETFAN		; get EEPROM address of ID timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	fanTmr		; set fan timer
	btfsc	STATUS,Z	; is fan timer zero?
	bcf	outPort,FANCTL	; yes, turn off fan now.
	return

; ************
; ** FoneUp **
; ************
	;; take phone off hook, but don't put on-air.
FoneUp
	bsf	outPort,FONECTL ; take phone off hook
	call	SetPort		; set the port.
	return			; done here.

; ************
; ** FoneOn **
; ************
	;; take phone off hook and put on-air.
FoneOn
	btfsc	group5,3	; is link enabled during patch?
	goto	FoneOn1		; yes.
	bcf	outPort,TX1PTT	; no.  turn off link PTT
	bcf	outPort,RX1AUD	; mute the link audio.
	;; turn off link input.
FoneOn1		
	bsf	txFlag,PATCHON	; turn on patch active transmitter on flag
	bsf	outPort,FONECTL ; take phone off hook
	bsf	outPort,FONEAUD ; turn on phone audio
	call	SetPort		; set the port.
	return			; done here.

; *************
; ** FoneOff **
; *************
	;; put phone on hook. (hang up).
FoneOff
	bcf	txFlag,PATCHON	; turn on patch active transmitter on flag
	bcf	outPort,FONECTL ; take phone off hook
	bcf	outPort,FONEAUD ; turn on phone audio
	btfsc	group5,3	; is link enabled during patch?
	goto	FoneOf1		; yes.
	btfsc	txFlag,RX1OPEN	; does the link want to be on?
	bsf	outPort,RX1AUD	; unmute the link receiver.
FoneOf1 
	call	SetPort		; set the port.
	return			; done here.

; ************
; ** ReadEE **
; ************
	;; read eeCount bytes from the EEPROM 
	;; starting at location in eeAdrH and eeAdrL into location
	;; starting at FSR.
ReadEE				; read EEPROM.
	movf	eeCount,f	; check this for zero
	btfsc	STATUS,Z	; is it zero?
	return			; yes, do nothing here!
ReadEEd 
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	ReadEEd		; no.  try again.
	bcf	PORTC,EEPSEL	; select the EEPROM
	movlw	EEREAD		; get EEPROM read instruction
	call	SendSPI		; send & receive
	movf	eeAddrH,w	; get hi byte of address...
	call	SendSPI		; send & receive
	movf	eeAddrL,w	; get lo byte of address
	call	SendSPI		; send & receive
RdEELp	      
	clrw			; clear W register (does this need to be here?)
	call	SendSPI		; send & receive
	movwf	INDF		; save into RAM address indicated by FSR
	incf	FSR,f		; increment RAM address in FSR
	decfsz	eeCount,f	; decrement count of bytes to read, test for 0
	goto	RdEELp		; not zero, keep reading
	bsf	PORTC,EEPSEL	; deselect the EEPROM
	bsf	INTCON,GIE	; enable interrupts
	return			; read the requested bytes, return

; *************
; ** ReadEEw **
; *************
	;; read 1 bytes from the EEPROM 
	;; from location in eeAddrH and eeAddrL into W
ReadEEw				; read EEPROM.
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	ReadEEw		; no,  try again.
	bcf	PORTC,EEPSEL	; select the EEPROM
	movlw	EEREAD		; get EEPROM read instruction
	call	SendSPI		; send & receive
	movf	eeAddrH,w	; get hi byte of address...
	call	SendSPI		; send & receive
	movf	eeAddrL,w	; get lo byte of address
	call	SendSPI		; send & receive
	call	SendSPI		; send & receive
	bsf	PORTC,EEPSEL	; deselect the EEPROM
	bsf	INTCON,GIE	; enable interrupts
	return			; read the requested bytes, return

; *************
; ** WriteEE **
; *************
	;; write eeCount bytes to the EEPROM 
	;; starting at location in eeAddrH and eeAddrL from location
	;; starting at FSR.
	;; cannot write more than 32 bytes.  cannot cross 32 byte paragraphs.
WriteEE				; write EEPROM.
	movf	eeCount,f	; check this for zero
	btfsc	STATUS,Z	; is it zero?
	return			; yes, do nothing here!
WriteEd 
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	WriteEd		; no.  try again.
	bcf	PORTC,EEPSEL	; select the EEPROM
	movlw	EEWREN		; set write enable latch
	call	SendSPI		; send it.
	bsf	PORTC,EEPSEL	; deselect the EEPROM
	nop			; insert short delay here
	bcf	PORTC,EEPSEL	; select the EEPROM
	movlw	EEWRITE		; get EEPROM write instruction
	call	SendSPI		; send & receive
	movf	eeAddrH,w	; get hi byte of address...
	call	SendSPI		; send & receive
	movf	eeAddrL,w	; get lo byte of address
	call	SendSPI		; send & receive
WrEELp	      
	movf	INDF,w		; get data byte to write
	call	SendSPI		; send & receive
	incf	FSR,f		; increment RAM address in FSR
	decfsz	eeCount,f	; decrement count of bytes to write, test for 0
	goto	WrEELp		; not zero, keep writing
	bsf	PORTC,EEPSEL	; deselect the EEPROM
	bsf	INTCON,GIE	; enable interrupts
	return			; wrote the requested bytes, done, so return

; *************
; ** WriteEw **
; *************
	;; write 1 byte from w into the EEPROM 
	;; at location in eeAdrH and eeAdrL
	;; stomps on temp3.
WriteEw				; write EEPROM.
	movwf	temp3		; save the value to write.
WritEd
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	WritEd		; no. try again.
	bcf	PORTC,EEPSEL	; select the EEPROM
	movlw	EEWREN		; set write enable latch
	call	SendSPI		; send it.
	bsf	PORTC,EEPSEL	; deselect the EEPROM
	nop			; insert short delay here
	bcf	PORTC,EEPSEL	; select the EEPROM
	movlw	EEWRITE		; get EEPROM write instruction
	call	SendSPI		; send & receive
	movf	eeAddrH,w	; get hi byte of address...
	call	SendSPI		; send & receive
	movf	eeAddrL,w	; get lo byte of address
	call	SendSPI		; send & receive
	movf	temp3,w		; get data byte to write
	call	SendSPI		; send & receive
	bsf	PORTC,EEPSEL	; deselect the EEPROM
	bsf	INTCON,GIE	; enable interrupts
	return			; wrote the requested bytes, done, so return

	
; ************
; ** ISDRec **
; ************
	;; prepare to record ISD message.
ISDRec
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	ISDRec		; still enabled, retry disable.
	call	ISDfixp		; set up address
	decf	isdRACc,f	; decrement RAC count.
	bcf	isdCmdC,ISDPLAY ; set record mode.
	call	CmdISD		; send 24-bit command to ISD.
	bsf	isdFlag,ISDRUNF ; ISD is now running.
	bsf	isdFlag,ISDRECF ; ISD is now recording.
	bcf	isdFlag,ISDIABF ; have not yet sent IAB message.
	bsf	INTCON,GIE	; re-enable interrupts
	return			; done...

; *************
; ** ISDStop **
; *************
	;; stop ISD message from playing or recording.
ISDStop
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	ISDStop		; still enabled, retry disable.
	bcf	isdCmdC,ISDRUN	; STOP the ISD. that's all.
	call	CmdISD8		; send 8-bit command to ISD
	movlw	b'11100000'	; bitmask: bits 7,6,5 set.
	andwf	isdFlag,f	; clear all but 2 hi bits.
	bsf	INTCON,GIE	; re-enable interrupts
	btfss	txFlag,TALKING	; is TALKING on?
	return			; nope.
	bcf	txFlag,TALKING	; clear txFlag TALKING indicator.
	btfss	txFlag,BEEPING	; don't turn off audio gate if beeping.
	bcf	outPort,BEEPAUD ; turn off audio gate, too.
	return			; done.

; **************
; ** ISDAbort **
; **************
	;; abort ISD speech playback
ISDAbort
	call	ISDStop		; stop the ISD.
	movf	isdHead,w	; get head pointer.
	movwf	isdTail		; set tail pointer equal to head pointer.
	return			; done here.
	
; ***********************
; ** ISD Message Fixup **
; ***********************
	;; this routine algoritmically finds the start address and RAC count
	;; for the message number contained in isdMsg.
	;; this code contains extreme nastiness! you have been warned.
	;; this code remaps internal message numbers into ISD 4004 addresses.
	;; the ISD is conveniently in upside-down bit order, which make this
	;; all a large pain in the ass.	 This code reverses the bit order and
	;; sets the nessecary bits in the isdCmdH and isdCmdL buffers.
ISDfixp
	movlw	b'00000111'	; mask: ISDPUP | ISDPLAY | ISDRUN
	movwf	isdCmdC		; set command byte.
	clrf	isdCmdL		; clear	  low	byte of ISD command.
	clrf	isdCmdH		; clear	 high	byte of ISD command.
	movf	isdMsg,w	; get message number
	movwf	temp		; save message number
	sublw	d'95'		; w = K - w
	btfss	STATUS,C	; c is clear if K < w, set if K >= w
	goto	IFixp01		; w > 95
	;; 14 instructions to set up the ISD address for messages 0-95
	;; 4 instructions longer than loop with rotate, but at least 2x faster.
	btfsc	temp,0		; hack!
	bsf	isdCmdH,5	; set HI bit 5
	btfsc	temp,1		; hack!
	bsf	isdCmdH,4	; set HI bit 4
	btfsc	temp,2		; hack!
	bsf	isdCmdH,3	; set HI bit 3
	btfsc	temp,3		; hack!
	bsf	isdCmdH,2	; set HI bit 2
	btfsc	temp,4		; hack!
	bsf	isdCmdH,1	; set HI bit 1
	btfsc	temp,5		; hack!
	bsf	isdCmdH,0	; set HI bit 0
	btfsc	temp,6		; hack!
	bsf	isdCmdL,7	; set LO bit 7
	;; no messages greater than 96, so this next bit can be ignored.
	;btfsc	temp,7		; hack!
	;bsf	isdCmdL,6	; set LO bit 6
	
	movlw	d'4'		; get # ISDRACs
	movwf	isdRACc		; save #ISDRACs
	return			; done with messages 00-95

IFixp01				; message number was >= 96!
	movf	temp,w		; get back temp
	sublw	d'110'		; w = K - w
	btfss	STATUS,C	; c is clear if K < w, set if K >= w
	goto	IFixp02		; w > 110
	;movf	temp,w		; get back old temp
	movlw	d'96'		; offset = 96
	subwf	temp,f		; w = temp - w : normalize to 0
	movlw	h'0c'		; offset with 0c
	addwf	temp,f		; add the offset.
	;; rude hack to set the appropriate ISD address bits.
	btfsc	temp,0		; get bit
	bsf	isdCmdH,2	; set bit
	btfsc	temp,1		; get bit
	bsf	isdCmdH,1	; set bit
	btfsc	temp,2		; get bit
	bsf	isdCmdH,0	; set bit
	btfsc	temp,3		; get bit
	bsf	isdCmdL,7	; set bit
	btfsc	temp,4		; get bit
	bsf	isdCmdL,6	; set bit
	;; end hack!
	movlw	d'32'		; get # ISDRACs
	movwf	isdRACc		; save #ISDRACs
	return			; done with messages 96-110

IFixp02				; message number was >= 111
	movf	temp,w		; get back old temp
	movlw	d'105'		; 111 (base msg #) - 6 (offset)
	subwf	temp,f		; w = temp - w : normalize to 0
	;; rude hack to set the appropriate ISD address bits.
	bsf	isdCmdH,2	; set bit
	bsf	isdCmdH,1	; set bit
	btfsc	temp,0		; get bit
	bsf	isdCmdH,0	; set bit
	btfsc	temp,1		; get bit
	bsf	isdCmdL,7	; set bit
	btfsc	temp,2		; get bit
	bsf	isdCmdL,6	; set bit
	btfsc	temp,3		; get bit
	bsf	isdCmdL,5	; set bit
	btfsc	temp,4		; get bit
	bsf	isdCmdL,4	; set bit
	;; end hack!
	movlw	d'128'		; get # ISDRACs
	movwf	isdRACc		; save #ISDRACs
	return

; *************
; ** CmdISD8 **
; *************
	;; send the command in isdCmdC to the ISD.
	;; return status from ISD in W.
CmdISD8				; command ISD.
	movlw	b'00000011'	; mask:	 clear all except ISDPLAY and ISDRUN.
	andwf	isdCmdC,f	; clear bits.
	movlw	b'00001100'	; mask:	 set ISDPUP and ISDIAB.
	iorwf	isdCmdC,f	; set bits.
CmdISD8a			; entry point for raw command access.
	bcf	PORTB,ISDSEL	; select the ISD
	movf	isdCmdC,w	; get the command byte of the command.
	call	SendSPI		; send & receive
	bsf	PORTB,ISDSEL	; deselect the ISD
	return			; read the requested bytes, return

; ************
; ** CmdISD **
; ************
	;; send the command in isdCmdH/isdCmdL/isdCmdC to the ISD.
	;; return status from ISD in W.
CmdISD				; command ISD.
	bcf	PORTB,ISDSEL	; select the ISD
	movf	isdCmdH,w	; get the high byte of the command.
	call	SendSPI		; send & receive
	movwf	temp		; save status
	movf	isdCmdL,w	; get the low  byte of the command.
	call	SendSPI		; send & receive
	movf	isdCmdC,w	; get the low  byte of the command.
	call	SendSPI		; send & receive
	bsf	PORTB,ISDSEL	; deselect the ISD
	movf	temp,w		; put ISD status byte into w.
	return			; read the requested bytes, return

; *************
; ** SendSPI **
; *************
	;; send the byte in W out the SPI.
	;; wait for the transmission to complete.
	;; return byte received from SPI in W.
SendSPI				; send a byte out the SPI
	movwf	SSPBUF		; output the byte in the W register
	bsf	STATUS,RP0	; select page 1
WaitSPI		 
	btfss	SSPSTAT,BF	; is byte transmission complete?
	goto	WaitSPI		; nope
	bcf	STATUS,RP0	; select page 0
	movf	SSPBUF,w	; save received byte in W
	return

; *************
; ** PlaySpc **
; *************
	;; Play Speech message from ISD buffer...
PlaySpc
	;; first, mute the remote base audio.
	bsf	flags,RBMUTE	; set the muted indicator.
	btfsc	txFlag,RX1OPEN	; is the remote base active?
	bcf	outPort,RX1AUD	; mute the remote base.
	
	movf	isdFlag,w	; get isdFlag
	andlw	b'01000001'	; and with ISDWRDF | ISDRUNF
	btfss	STATUS,Z	; skip if isd not already running...
	return			; cannot stomp current playback or record.
	movf	isdHead,w	; get head.
	subwf	isdTail,w	; subtract tail.
	btfsc	STATUS,Z	; check for zero.
	return			; no words to play.
	;; don't turn on TALKING unless audio gate is already on.
	btfsc	outPort,BEEPAUD ; turn on audio gate
	bsf	txFlag,TALKING	; ISD is playing.
	movlw	ISD_DLY		; get speech startup delay time.
	movwf	isdDly		; set speech startup delay timer.
	bcf	isdFlag,ISDD4RC ; clear deferred record bit, in case...
	return

; *************
; ** NextWrd **
; *************
	;; get the next word code from the speech buffer. return in W.
NextWrd
	movf	isdTail,w	; get tail pointer.
	subwf	isdHead,w	; subtract from head pointer.
	btfsc	STATUS,Z	; result should be non-zero if more words.
	goto	NoWords		; no more words.
	incf	isdTail,w	; get pointer + 1.
	andlw	h'0f'		; mask so result stays in 0-15 range.
	movwf	isdTail		; save it...
	addlw	LOW isdXB0	; add to buffer base address.
	movwf	FSR		; set FSR as pointer
	movf	INDF,w		; get word
	movwf	isdMsg		; set word index
	xorlw	h'ff'		; is it FF?
	btfss	STATUS,Z	; result will be zero if FF
	goto	PlayNxt		; there are more words to play.
NoWords
	btfss	txFlag,TALKING	; is TALKING on?
	return			; nope.
	bcf	txFlag,TALKING	; clear txFlag TALKING indicator.
	btfss	beepCtl,B_MAIN	; does beep have audio gate on?
	;btfss	txFlag,BEEPING	; don't turn off audio gate if beeping.
	bcf	outPort,BEEPAUD ; turn off audio gate, too.
	bcf	idRFlag,IDNOW	; turn off IDing flag
	btfss	flags,DEF_CT	; is there a deferred CT?
	return			; no deferred CT
	bcf	flags,DEF_CT	; clear deferred CT flag.
	call	PlayCT		; play deferred CT.
	return			; ok, done.
PlayNxt
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	PlayNxt		; still enabled, retry disable.
	call	ISDfixp		; set up address
	call	CmdISD		; send 24-bit command to ISD.
	bsf	isdFlag,ISDRUNF ; ISD is now running.
	bcf	isdFlag,ISDIABF ; have not yet sent IAB message.
	bsf	INTCON,GIE	; re-enable interrupts
	return
	
; *************
; ** PutWord **
; *************
	;; put a word in W into the speech buffer.
	;; clobbers value in temp5, temp6
PutWord
	movwf	temp5		; save word
	movf	FSR,w		; get old FSR
	movwf	temp6		; save old FSR
	incf	isdHead,w	; get pointer + 1.
	andlw	h'0f'		; mask so result stays in 0-15 range.
	movwf	isdHead		; save it...
	addlw	LOW isdXB0	; add to buffer base address.
	movwf	FSR		; set FSR as pointer
	movf	temp5,w		; get word back
	movwf	INDF		; save word into buffer
	movf	temp6,w		; get back old FSR
	movwf	FSR		; restore old FSR
	return	
	
; ************
; ** PutNum **
; ************
	;; put a number in W into the speech buffer.
	;; convert the number appropriately...
	;; clobbers values in temp, temp2
PutNum
	;; start with the 100s
	movwf	temp		; save W.
	clrf	temp2		; clear count of 100s.
	movf	temp,w		; get count back
	btfss	STATUS,Z	; check for zero.
	goto	PN100s		; not zero.
	call	PutWord		; add the "zero".
	return			; done here.
PN100s				; check 100s.
	movlw	d'100'		; 100.
	subwf	temp,w		; subtract.
	btfss	STATUS,C	; C clear if result negative.
	goto	PN100d		; result is negative.
	movwf	temp		; store result back to temp.
	incf	temp2,f		; increment 100s counter.
	goto	PN100s		; check for next 100s.
PN100d				; done with 100s.
	movf	temp2,w		; get 100s count.
	btfsc	STATUS,Z	; any?
	goto	PNteens		; no.
	call	PutWord		; put the 100s digit word.
	movlw	VHUND		; get "HUNDRED" word.
	call	PutWord		; put "HUNDRED".
PNteens				; check to see if in range 1-19.
	movf	temp,w		; get remaining count.
	btfsc	STATUS,Z	; is it zero?
	return			; yep.	exactly "one-hundred" or "two hundred".
	sublw	d'19'		; w = 19 - w.
	btfss	STATUS,C	; C clear if amount negative (w > 19)
	goto	PN10s		; W > 19.  No "teens" shortcut.
	movf	temp,w		; get count back.
	call	PutWord		; put word "one" -> "nineteen".
	return			; done.
PN10s				; deal with number of tens...
	clrf	temp2		; clear count of tens.
PN10l				; tens loop.
	movlw	d'10'		; 10.
	subwf	temp,w		; w = temp - 10.
	btfss	STATUS,C	; C clear if result is negative.
	goto	PN10d		; result is negative.
	movwf	temp		; store result back to temp.
	incf	temp2,f		; increment 10s counter.
	goto	PN10l		; check for next 10s.
PN10d				; done with 10s.
	movf	temp2,w		; get 10s count.
	btfsc	STATUS,Z	; any?
	goto	PN1s		; nope.	 go do the ones.
	addlw	V18		; offset into word list.
	call	PutWord		; add word.
PN1s				; add in the ones
	movf	temp,w		; get ones count
	btfss	STATUS,Z	; zero?
	call	PutWord		; no. add ones word. ("one" - "nine")...
	return
	
; ************************************************
; ** Load control operator settings from EEPROM **
; ************************************************
LoadCtl				; load the control operator saved groups
				; from "macro" set contained in w.
	movwf	temp		; save group number
	movlw	high EESSB	; get address of saved settings
	movwf	eeAddrH		; save high part of address
	movlw	low EESSB	; get low part of address
	movwf	eeAddrL		; save low part of address
	swapf	temp,w		; magic! get group number * 16
	addwf	eeAddrL,f	; now have ee address for saved state.
	movlw	EESSC		; get the number of bytes to read.
	movwf	eeCount		; set the number of bytes to read.
	movf	temp,f		; check temp
	btfsc	STATUS,Z	; is temp (settings #) zero?
	incf	eeCount,f	; yes. read one extra byte with group 0.
	movlw	group0		; get address of first group
	movwf	FSR		; set pointer
	bcf	STATUS,IRP	; to page 0.
	call	ReadEE		; read bytes from EEPROM.
	bsf	STATUS,IRP	; back to page 1.
	return			; done.
	
; *************
; ** GetDNum **
; *************
	;; get a decimal number from the bytes pointed at by fsr.
	;; there can be 1, 2, or 3 bytes.  The bytes will always be
	;; terminated by FF.  return result in w.
	;; this routine destroys the values in temp3 and temp4
GetDNum
	clrf	temp3		; clear temp resul.
	movf	cmdSize,w	; get command length
	movwf	temp4		; save it.
	btfsc	STATUS,Z	; no digits to parse?
	goto	GetDN99		; yes.
	decf	temp4,f		; decrement it
	btfsc	STATUS,Z	; was it 1?
	goto	GetDN1		; yep.
	decf	temp4,f		; decrement it
	btfsc	STATUS,Z	; was it 2?
	goto	GetDN2		; yep.
	decf	temp4,f		; decrement it
	btfss	STATUS,Z	; was it 3?
	goto	GetDN99		; no.
	;; get hundreds digit
	call	Get100s		; get hundreds
	addwf	temp3,f		; add it.
	incf	FSR,f		; move pointer to next command byte.
	decf	cmdSize,f	; decrement command size.
GetDN2	;; get tens digit
	call	GetTens		; get the value of the tens
	addwf	temp3,f		; add the tens to the running count
	incf	FSR,f		; move pointer to next command byte.
	decf	cmdSize,f	; decrement command size.
GetDN1	;; get ones digit
	movf	INDF,w		; get last digit...
	addwf	temp3,f		; add it.
	incf	FSR,f		; move pointer to next command byte.
	decf	cmdSize,f	; decrement command size.
GetDN99 ;; no digits left
	movf	temp3,w		; get temp result.
	return			; really done.

; ************
; ** CIVPre **
; ************
	;; send the CI-V preamble.
CIVPre
	movlw	CIV_PRE		; FE - preamble
	call	SerOut		; send it.
	movlw	CIV_PRE		; FE - preamble
	call	SerOut		; send it
	movlw	CIV_706		; 48 - address of radio.
	call	SerOut		; send it.
	movlw	CIV_ME		; E0 -- address of controller.
	call	SerOut		; send it.
	return			; done
	
; *************
; ** CIVPrPC **
; *************
	;; send the CI-V preamble for a message to a computer.
CIVPrPC
	movlw	CIV_PRE		; FE - preamble
	call	SerOut		; send it.
	movlw	CIV_PRE		; FE - preamble
	call	SerOut		; send it
	movlw	CIV_PC		; E1 - address of computer.
	call	SerOut		; send it.
	movlw	CIV_ME		; E0 -- address of controller.
	call	SerOut		; send it.
	return			; done

	
; ************
; ** SerOut **
; ************
SerOut				; send the character in w out the serial port.
	;; uses temp5, temp6
	;; first, disable interrupts.
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	SerOut		; still enabled, retry disable.
	;; next put the character into the buffer.
	movwf	temp5		; save character.
	movf	FSR,w		; get old FSR.
	movwf	temp6		; save old FSR.
	incf	ciTHead,w	; get pointer + 1.
	andlw	h'1f'		; mask so result stays in 0-31 range.
	movwf	ciTHead		; save it...
	addlw	LOW itbuf00	; add to buffer base address.
	movwf	FSR		; set FSR as pointer
	movf	temp5,w		; get word back
	bcf	STATUS,IRP	; select 00-FF range for FSR/INDF
	movwf	INDF		; save word into buffer
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	movf	temp6,w		; get back old FSR
	movwf	FSR		; restore old FSR
	;; then, turn on the serial port transmitter.
	bsf	STATUS,RP0	; select bank 1
	bsf	PIE1,TXIE	; turn off the transmitter interrupt.
	bcf	STATUS,RP0	; select bank 0
	;; last, turn interrupts back on so character gets sent.
	bsf	INTCON,GIE	; turn interrupts on.
	return	

GetCTen
	call	GetTens		; get tens digit.
	movwf	temp6		; save
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrement count of remaining bytes.
	movf	INDF,w		; get ones digit
	addwf	temp6,f		; add to timer index
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrement count of remaining bytes.
	movf	temp6,w		; get result.
	return			; done.

; ************
; ** PutEEB **
; ************
PutEEB				; put byte in w into EEPROM buffer.
	movwf	temp5		; save byte.
	movf	FSR,w		; get FSR.
	movwf	temp6		; save it.
	movf	eebPtr,w	; get address of eebuffer.
	movwf	FSR		; set FSR.
	movf	temp5,w		; get value.
	movwf	INDF		; write into eebuffer.
	incf	eebPtr,f	; increment eebuffer pointer.
	incf	eeCount,f	; increment count to write.
	movf	temp6,w		; get saved FSR.
	movwf	FSR		; restore FSR.
	return

; ************
; ** ChkCIV **
; ************

ChkCIV				; evaluate received CI-V message.
	;; the preamble (FE FE) has been stripped for convenience.
	bcf	mscFlag,CIV_RDY ; clear CI-V message waiting flag.
	movlw	low irbuf00	; get buffer base.
	movwf	FSR		; save buffer pointer.

	bcf	STATUS,IRP	; select 00-FF range for FSR/INDF

	movf	INDF,w		; get 1st byte.
	xorlw	CIV_ME		; my address.
	btfss	STATUS,Z	; result should be zero if this is my message.
	goto	ChkCIV0		; no. not my message.
	incf	FSR,f		; go to next byte.
	movf	INDF,w		; get 2nd byte.
	xorlw	CIV_706		; 706's address.
	btfsc	STATUS,Z	; result should be zero if from IC-706.
	goto	Msg706		; yes, 0, message from IC-706.
	;; jeff -- this is where to check for a computer message.
	movf	INDF,w		; get 2nd byte.
	xorlw	CIV_PC		; PC's address.
	btfss	STATUS,Z	; result should be zero if from IC-706.
	goto	ChkCIV0		; no. not from IC-706.
	;; message is from a computer.
	incf	FSR,f		; go to next byte
	movf	INDF,w		; get 3rd byte.
	xorlw	CIV_PVT		; NHRC private message.
	btfss	STATUS,Z	; result should be zero if NHRC PRIVATE message.
	goto	ChkCIV0		; not private message. just bail out.

	;; now evaluate the private subcommand byte...
	incf	FSR,f		; go to next byte.
	movf	INDF,w		; get 4th byte.
	xorlw	CIV_PRD		; NHRC PRIVATE READ command.
	btfsc	STATUS,Z	; result should be zero if OK message.
	goto	CIVRDDT		; computer read data message. IRP gets fixed there.

	movf	INDF,w		; get 4th byte.
	xorlw	CIV_WRT		; NHRC PRIVATE WRITE command.
	btfsc	STATUS,Z	; result should be zero if OK message.
	goto	CIVWRDT		; computer read data message. IRP gets fixed there.

	;; not an expected command... bail out.
	goto	ChkCIV0		; for now.

Msg706				; message is from IC-706.
	incf	FSR,f		; go to next byte.
	movf	INDF,w		; get 3rd byte.
	xorlw	CIV_OK		; OK result.
	btfsc	STATUS,Z	; result should be zero if OK message.
	goto	CIVOK		; OK message. IRP fixed there.

	movf	INDF,w		; get 3rd byte.
	xorlw	CIV_BAD		; BAD result.
	btfsc	STATUS,Z	; result should be zero if OK message.
	goto	CIVNG		; NG message. IRP fixed there.

	movf	INDF,w		; get 3rd byte.
	xorlw	CIV_RDF		; frequency message.
	btfsc	STATUS,Z	; result should be zero if OK message.
	goto	CIVRDF		; frequency message. IRP fixed there.

	movf	INDF,w		; get 3rd byte.
	xorlw	CIV_RDM		; mode message.
	btfsc	STATUS,Z	; result should be zero if OK message.
	goto	CIVRDM		; mode message. IRP fixed there.

ChkCIV0				; done processing uninteresting received message
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	return			; unexpected message...

CIVOK
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	btfss	tuneFlg,SUPP_OK ; is OK suppressed?
	goto	CIVOK1		; no.
	bcf	tuneFlg,SUPP_OK ; don't suppress OK next time.
	return			; done.
CIVOK1				; say OK.
	movlw	VOK		; get word "OK"
	call	PutWord		; add word in W to buffer.
	goto	CIVCend		; say it.
CIVNG		
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	movlw	VBAD		; get word "BAD"
	call	PutWord		; add word in W to buffer.
	movlw	VREMOTE		; get word "REMOTE"
	call	PutWord		; add word in W to buffer.
	movlw	VBASE		; get word "BASE"
	call	PutWord		; add word in W to buffer.
	movlw	VCOMMND		; get word "COMMAND"
	call	PutWord		; add word in W to buffer.
	;; exit scan mode.
	bsf	STATUS,RP0	; select register page 1.
	clrf	scanTmr		; stop scanning.
	clrf	scanMod		; stop scanning.
	bcf	STATUS,RP0	; select register page 0.
	;; poll the radio to get the current frequency back.

	call	CIVPre		; send CI-V preamble.
	movlw	CIV_RDF		; read operating mode.
	call	SerOut		; send it.
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
		
	goto	CIVCend		; say it.

CIVRDF				; read out frequency received on CI-V.
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq1		; save frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq2		; save frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq3		; save frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq4		; save frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte.
	bsf	STATUS,RP0	; select register page 1.
	movwf	civfrq5		; save frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF

	;; count number of digits to right of decimal to speak.
	movlw	d'6'		; say all 6 digits.
	movwf	temp3		; counter.
	
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq1,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask low nibble.
	btfss	STATUS,Z	; skip if result is zero.
	goto	CRdOut		; 1 hz digit was non-zero.
	decf	temp3,f		; 1 hz digit was zero.
	
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq1,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'f0'		; mask hi nibble.
	btfss	STATUS,Z	; skip if result is zero.
	goto	CRdOut		; 10 hz digit was non-zero.
	decf	temp3,f		; 10 hz digit was zero.
	
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask low nibble.
	btfss	STATUS,Z	; skip if result is zero.
	goto	CRdOut		; 100 hz digit was non-zero.
	decf	temp3,f		; 100 hz digit was zero.
	
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'f0'		; mask hi nibble.
	btfss	STATUS,Z	; skip if result is zero.
	goto	CRdOut		; 1 KHz digit was non-zero.
	decf	temp3,f		; 1 KHz digit was zero.

	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask low nibble.
	btfss	STATUS,Z	; skip if result is zero.
	goto	CRdOut		; 10 KHz digit was non-zero.
	decf	temp3,f		; 10 KHz digit was zero.
	;; always at least say the 100 KHz digit.
	
CRdOut				; read it out now.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq5,w	; get byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask out gigahertz digit.
	btfsc	STATUS,Z	; is there a 100 MHz digit?
	goto	CRd10M		; nope.
	call	PutWord		; add word to buffer.
	movlw	VHUND		; get word "hundred"
	call	PutWord		; add word to buffer.
CRd10M
	bsf	STATUS,RP0	; select register page 1.
	swapf	civfrq4,w	; get byte with nibbles reversed.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 10 MHz digit.
	call	Mult10		; multiply by 10.
	movwf	temp		; save number.
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq4,w	; get byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 1 MHz digit.
	addwf	temp,w		; add 10 MHz digit back in.
	btfss	STATUS,Z	; if even 100 MHz, don't say extra zero
	call	PutNum		; add number to buffer.
	movlw	VPOINT		; get word "point".
	call	PutWord		; add word to buffer.
CRd100K
	bsf	STATUS,RP0	; select register page 1.
	swapf	civfrq3,w	; get byte with nibbles reversed.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 100 kHz digit.
	call	PutWord		; add word to buffer.
	decf	temp3,f		; decrement counter
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	CRdNow		; read it back now.
CRd10K	
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 10 KHz digit.
	call	PutWord		; add word to buffer.
	decf	temp3,f		; decrement counter
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	CRdNow		; read it back now.
CRd1K		
	bsf	STATUS,RP0	; select register page 1.
	swapf	civfrq2,w	; get byte with nibbles reversed.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 1 kHz digit.
	call	PutWord		; add word to buffer.
	decf	temp3,f		; decrement counter
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	CRdNow		; read it back now.
CRd100
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 100 Hz digit.
	call	PutWord		; no, add word to buffer.
	decf	temp3,f		; decrement counter
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	CRdNow		; read it back now.
CRd10
	bsf	STATUS,RP0	; select register page 1.
	swapf	civfrq1,w	; get byte with nibbles reversed.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 10 Hz digit.
	call	PutWord		; add word to buffer.
	decf	temp3,f		; decrement counter
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	CRdNow		; read it back now.
CRd1
	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq1,w	; get byte.
	bcf	STATUS,RP0	; select register page 0.
	andlw	h'0f'		; mask to leave 1 Hz digit.
	call	PutWord		; no, add word to buffer.
CRdNow
	movlw	VMEGA		; get word "mega"
	call	PutWord		; add word to buffer.
	movlw	VHERTZ		; get word "hertz"
	call	PutWord		; add word to buffer.
	goto	CIVCend		; say it.

; ************
; ** Mult10 **
; ************
Mult10
	;; multiply w by 10, return in w
	movwf	temp5		; save it.
	movwf	temp6		; save it.
	addlw	h'0'		; clear carry.
	rlf	temp6,f		; temp6 = temp6 * 2
	rlf	temp6,f		; temp6 = temp6 * 4
	rlf	temp6,w		; w = temp * 8
	addwf	temp5,w		; w = w + temp5
	addwf	temp5,w		; w = w + temp5 (really now temp3 * 10)
	return			; returns with w*10 in w.

; ************
; ** CIVRDM **
; ************
				; make sure that computed goto is in range.
CIVRDM				; read mode.
	incf	FSR,f		; go to next byte.
	movlw	high CMTbl	; set page
	movwf	PCLATH		; select page
	movf	INDF,w		; get mode.
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
	andlw	h'07'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL

CMTbl				; CI-V Mode Table.
	goto	CIVRDLSB	; mode 0: LSB.
	goto	CIVRDUSB	; mode 1: USB.
	goto	CIVRDAM		; mode 2: AM.
	goto	CIVRDNG		; mode 3: CW. (not valid)
	goto	CIVRDNG		; mode 4: RTTY. (not valid)
	goto	CIVRDFM		; mode 5: FM.
	goto	CIVRDNG		; mode 6: wide fm. (not valid)
	goto	CIVRDNG		; mode 7: not valid.

CIVRDLSB			; LSB.
	movlw	VLOWER		; get word "lower"
	call	PutWord		; add word in W to buffer.
	movlw	VSIDEB		; get word "sideband"
	call	PutWord		; add word in W to buffer.
	goto	CIVCend		; say it.

CIVRDUSB			; USB.
	movlw	VUPPER		; get word "upper"
	call	PutWord		; add word in W to buffer.
	movlw	VSIDEB		; get word "sideband"
	call	PutWord		; add word in W to buffer.
	goto	CIVCend		; say it.

CIVRDAM				; AM.
	movlw	VAM		; get word "AM"
	call	PutWord		; add word in W to buffer.
	goto	CIVCend		; say it.

CIVRDFM				; FM.
	movlw	VFM		; get word "FM"
	call	PutWord		; add word in W to buffer.
	goto	CIVCend		; say it.

CIVRDNG				; invalid mode.
	movf	INDF,w		; get mode.
	call	PutNum		; add word in W to buffer.
	goto	CIVCend		; say it.

CIVCend
	bcf	tuneFlg,SUPP_OK ; don't suppress OK next time.
	bsf	outPort,BEEPAUD ; turn on audio gate
	call	SetPort		; set the port.
	call	PTTon		; turn on tx if not on already.
	call	PlaySpc		; play the speech message.
	return

; *************
; ** CIVTune **
; *************
CIVTune				; send CI-V Tune command.
	call	CIVPre		; send CI-V preamble.
	movlw	CIV_FRQ		; select operating mode.
	call	SerOut		; send it.

	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq1,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	call	SerOut		; send it.

	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq2,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	call	SerOut		; send it.

	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq3,w	; get frequency byte.
	bcf	STATUS,RP0	; select register pagsend CI-V Tune command.e 0.
	call	SerOut		; send it.

	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq4,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	call	SerOut		; send it.

	bsf	STATUS,RP0	; select register page 1.
	movf	civfrq5,w	; get frequency byte.
	bcf	STATUS,RP0	; select register page 0.
	call	SerOut		; send it.

	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	return			; done.

; *************
; ** CIVRDDT **
; *************
CIVRDDT				; Read data from EEPROM to computer.
	;; uses (temp,) temp2, temp3, temp4, (temp5, temp6)
        clrf    temp2           ; clear checksum.

        call    CIVGetB         ; get EEPROM address hi.
        movwf   eeAddrH         ; save EEPROM address hi.

        call    CIVGetB         ; get EEPROM address lo.
        movwf   eeAddrL         ; save EEPROM address lo.
        
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte. (number of bytes to transfer)
	movwf	temp3		; save number of bytes to transfer.
	addwf	temp2,f		; add to checksum

	incf	FSR,f		; move to next byte.
        movf    INDF,w          ; get checksum hi nibble.
        movwf   temp4           ; save checksum hi byte.
	swapf	temp4,f		; get byte. (checksum hi nibble)
        
	incf	FSR,f		; move to next byte.
        movf    INDF,w          ; get lo nibble of received checksum.
	iorwf	temp4,f		; or in checksum lo nibble.
                
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
        
        movf    temp4,w         ; get received checksum.
	subwf	temp2,w		; subtract calculated checksum from received.
	btfss	STATUS,Z	; is result zero?
	goto	CIVBad		; bad CIV message.
	
	call	CIVPrPC		; get preamble ready.
	
	movlw	CIV_PVT		; NHRC PRIVATE command.
	call	SerOut		; send it.

	movlw	CIV_WRT		; NHRC PRIVATE WRITE subcommand
	call	SerOut		; send it.

	clrf	temp2		; clear checksum counter.

	movf	eeAddrH,w	; get eeprom address hi byte.
	call	SendNib		; send as two nibbles.
	movf	eeAddrL,w	; get eeprom address lo byte.
	call	SendNib		; send as two nibbles.

	movf	temp3,w		; get number of bytes to transfer.
	addwf	temp2,f		; add to checksum.
	call	SerOut 		; send the number of bytes to transfer
	
CRDDTL				; loop for sending eeprom data.
	call	ReadEEw		; read a byte from the EEPROM.
	call	SendNib		; send as two nibbles.
	
	incf	eeAddrL,f	; add to address...
	btfsc	STATUS,C	; carry?
	incf	eeAddrH,f	; carry. increment eeprom address hi byte.
	decfsz	temp3,f		; decrement byte counter.
	goto	CRDDTL		; not zero yet, do the next byte.
	
	movf	temp2,w		; get checksum.
	call	SendNib		; send as two nibbles. temp2 now invalid.
	
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	return			; done here.
        
; *************
; ** CIVWRDT **
; *************
CIVWRDT				; write data from computer to EEPROM.
	;; jeff jeff jeff
	;; uses (temp,) temp2, temp3, temp4, (temp5, temp6)
        clrf    temp2           ; clear checksum.

        call    CIVGetB         ; get EEPROM address hi.
        movwf   eeAddrH         ; save EEPROM address hi.

        call    CIVGetB         ; get EEPROM address lo.
        movwf   eeAddrL         ; save EEPROM address lo.
        
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte. (number of bytes to transfer)
	movwf	temp3		; save number of bytes to transfer.
        movwf   eeCount         ; save number of bytes to write to EEPROM.
	addwf	temp2,f		; add to checksum

        movlw   LOW eebuf00     ; get address of EEPROM write buffer.
        movwf   temp5           ; save address of EEPROM write buffer.
        
CIVWrLp				; CIV write to EEPROM checksum check loop.
        call    CIVGetB         ; get tne next byte.
        call    CIVPutB         ; save the dang byte.
	decfsz	temp3,f		; decrement byte counter.
	goto	CIVWrLp		; not zero yet.
        
	incf	FSR,f		; move to next byte.
        movf    INDF,w          ; get checksum hi nibble.
        movwf   temp4           ; save checksum hi byte.
	swapf	temp4,f		; get byte. (checksum hi nibble)
        
	incf	FSR,f		; move to next byte.
        movf    INDF,w          ; get lo nibble of received checksum.
	iorwf	temp4,f		; or in checksum lo nibble.
                
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
        movf    temp4,w         ; get the received checksum.
	subwf	temp2,w		; subtract calculated checksum from received.
	btfss	STATUS,Z	; is result zero?
	goto	CIVBad		; no, bad checksum. send CIV NAK message.

CIVWOK
	movlw	low eebuf00	; get base of buffer
	movwf	FSR		; set into FSR.
        call    WriteEE         ; save the data into the EEPROM
	goto	CIVGood		; good command.
        
; *************
; ** CIVPutB **
; *************
CIVPutB                         ; save a byte in temp to the EEPROM write buffer.
        movf    FSR,w           ; get FSR for CI-V receive buffer.
        movwf   temp4           ; save CIV RX buffer FSR.
	bsf	STATUS,IRP	; select 100-1FF range for FSR/INDF
        movf    temp5,w         ; get FSR for EEPROM write buffer.
        movwf   FSR             ; set FSR.
        movf    temp,w          ; get data byte.
        movwf   INDF            ; save data byte to EEPROM write buffer.
        incf    temp5,f         ; increment EEPROM write buffer address.
        bcf	STATUS,IRP	; select 00-FF range for FSR/INDF
	movf	temp4,w		; get back old FSR
	movwf	FSR		; restore old FSR
        return                  ; done.
        
; *************
; ** CIVGetB **
; *************
CIVGetB                         ; get byte from 2 nibbles in CIV buffer.
	incf	FSR,f		; move to next byte.
        movf    INDF,w          ; get byte.
        addwf   temp2,f         ; add to checksum.
        movwf   temp            ; save hi nibble.
        swapf	temp,f          ; swap bytes.
	
	incf	FSR,f		; move to next byte.
	movf	INDF,w		; get byte.
	addwf	temp2,f		; add to checksum
	iorwf	temp,f          ; save lo nibble.
        movf    temp,w          ; put into w for convenience.
        return                  ; done.

; *************
; ** CIVBad  **
; *************
CIVBad				; send CIV NAK message.
	call	CIVPrPC		; get preamble ready.
	movlw	CIV_BAD		; CI-V NAK message.
	call	SerOut		; send it.
	goto	CIVEom		; send EOM

; *************
; ** CIVGood **
; *************
CIVGood				; send CIV OK message.
	call	CIVPrPC		; get preamble ready.
	movlw	CIV_OK		; CI-V OK message.
	call	SerOut		; send it.
CIVEom
	movlw	CIV_EOM		; EOM.
	call	SerOut		; send it.
	return			; done here.

; ******************************
; ** ROM Table Fetches follow **
; ******************************

	org	h'1d00'
; ***********
; ** GetCW **
; ***********
	;; get a cw bitmask from a phone pad letter number.
GetCW				; get tone byte from table
	movwf	temp		; save w
	movlw	high CWTbl	; set page 
	movwf	PCLATH		; select page
	bcf	temp,7		; force into 0-127 range for safety.
	movf	temp,w		; get tone into w
	addwf	PCL,f		; add w to PCL
CWTbl
	retlw	h'3f'		; 00 0
	retlw	h'3e'		; 01 1
	retlw	h'3c'		; 02 2
	retlw	h'38'		; 03 3
	retlw	h'30'		; 04 4
	retlw	h'20'		; 05 5
	retlw	h'21'		; 06 6
	retlw	h'23'		; 07 7
	retlw	h'27'		; 08 8
	retlw	h'2f'		; 09 9
	retlw	h'00'		; 10
	retlw	h'00'		; 11 space
	retlw	h'29'		; 12 /
	retlw	h'2a'		; 13 ar #
	retlw	h'31'		; 14 bt =
	retlw	h'58'		; 15 sk !
	retlw	h'00'		; 16
	retlw	h'00'		; 17
	retlw	h'00'		; 18
	retlw	h'00'		; 19
	retlw	h'00'		; 20
	retlw	h'06'		; 21 a
	retlw	h'11'		; 22 b 
	retlw	h'15'		; 23 c
	retlw	h'00'		; 24
	retlw	h'00'		; 25 
	retlw	h'00'		; 26
	retlw	h'00'		; 27
	retlw	h'00'		; 28
	retlw	h'00'		; 29
	retlw	h'00'		; 30
	retlw	h'09'		; 31 d
	retlw	h'02'		; 32 e
	retlw	h'14'		; 33 f
	retlw	h'00'		; 34
	retlw	h'00'		; 35
	retlw	h'00'		; 36
	retlw	h'00'		; 37
	retlw	h'00'		; 38
	retlw	h'00'		; 39
	retlw	h'00'		; 40
	retlw	h'0b'		; 41 g
	retlw	h'10'		; 42 h
	retlw	h'04'		; 43 i
	retlw	h'00'		; 44
	retlw	h'00'		; 45
	retlw	h'00'		; 46
	retlw	h'00'		; 47
	retlw	h'00'		; 48
	retlw	h'00'		; 49
	retlw	h'00'		; 50
	retlw	h'1e'		; 51 j
	retlw	h'0d'		; 52 k
	retlw	h'12'		; 53 l
	retlw	h'00'		; 54
	retlw	h'00'		; 55
	retlw	h'00'		; 56
	retlw	h'00'		; 57
	retlw	h'00'		; 58
	retlw	h'00'		; 59
	retlw	h'00'		; 60
	retlw	h'07'		; 61 m
	retlw	h'05'		; 62 n
	retlw	h'0f'		; 63 o
	retlw	h'00'		; 64
	retlw	h'00'		; 65
	retlw	h'00'		; 66
	retlw	h'00'		; 67
	retlw	h'00'		; 68
	retlw	h'00'		; 69
	retlw	h'1b'		; 70 q
	retlw	h'16'		; 71 p
	retlw	h'0a'		; 72 r
	retlw	h'08'		; 73 s
	retlw	h'00'		; 74
	retlw	h'00'		; 75
	retlw	h'00'		; 76
	retlw	h'00'		; 77
	retlw	h'00'		; 78
	retlw	h'00'		; 79
	retlw	h'00'		; 80
	retlw	h'03'		; 81 t
	retlw	h'0c'		; 82 u
	retlw	h'18'		; 83 v
	retlw	h'00'		; 84
	retlw	h'00'		; 85
	retlw	h'00'		; 86
	retlw	h'00'		; 87
	retlw	h'00'		; 88
	retlw	h'00'		; 89
	retlw	h'13'		; 90 z
	retlw	h'0e'		; 91 w
	retlw	h'19'		; 92 x
	retlw	h'1d'		; 93 y
	retlw	h'00'		; 94
	retlw	h'00'		; 95
	retlw	h'00'		; 96
	retlw	h'00'		; 97
	retlw	h'00'		; 98
	retlw	h'00'		; 99
	retlw	h'00'		; 100 -- all after 99 are a result of laziness.
	retlw	h'00'		; 101
	retlw	h'00'		; 102
	retlw	h'00'		; 103
	retlw	h'00'		; 104
	retlw	h'00'		; 105
	retlw	h'00'		; 106
	retlw	h'00'		; 107
	retlw	h'00'		; 108
	retlw	h'00'		; 109
	retlw	h'00'		; 110
	retlw	h'00'		; 111
	retlw	h'00'		; 112
	retlw	h'00'		; 113
	retlw	h'00'		; 114
	retlw	h'00'		; 115
	retlw	h'00'		; 116
	retlw	h'00'		; 117
	retlw	h'00'		; 118
	retlw	h'00'		; 119
	retlw	h'00'		; 120
	retlw	h'00'		; 121
	retlw	h'00'		; 122
	retlw	h'00'		; 123
	retlw	h'00'		; 124
	retlw	h'00'		; 125
	retlw	h'00'		; 126
	retlw	h'00'		; 127

; *************
; ** CpyPref **
; *************
CpyPref				; copy a phone dialing prefix.
	movf	FSR,w		; get FSR.
	movwf	temp5		; save copy of FSR.
	movlw	low dtXbuf0	; get address of xmit buffer
	movwf	FSR		; put address of xmit buffer into FSR.
CpyPre1
	call	ReadEEw		; get eeprom byte.
	movwf	temp		; save eeprom byte to temp.
	xorlw	h'ff'		; check to see if it equals FF
	btfsc	STATUS,Z	; now equal to zero?
	goto	CpyPre2		; yes.	done copying.
	movf	temp,w		; get saved byte back.
	movwf	INDF		; save the byte in the buffer.
	incf	FSR,f		; increment FSR.
	incf	eeAddrL,f	; increment eeprom address.
	goto	CpyPre1		; loop and copy more digits.
CpyPre2				; done copying digits.
	movf	FSR,w		; get current FSR.
	movwf	temp3		; save it.
	movf	temp5,w		; get back original pointer.
	movwf	FSR		; put back original pointer.
	movwf	temp2		; working copy of FSR.
	goto	CpyFnLp		; now go copy the phone number.

; *************
; ** CpyFone **
; *************
CpyFone				; copy a phone number.
	movf	FSR,w		; get FSR.
	movwf	temp5		; saved copy of FSR.
	movwf	temp2		; working copy of FSR.
	movlw	low dtXbuf0	; get address of xmit buffer
	movwf	temp3		; set buffer pointer
CpyFnLp				; start of loop.
	movf	INDF,w		; get digit.
	movwf	temp		; save digit.
	movf	temp3,w		; get xmit buffer pointer.
	movwf	FSR		; set the pointer.
	movf	temp,w		; get digit back.
	movwf	INDF		; put digit into buffer.
	xorlw	h'ff'		; is it FF?
	btfsc	STATUS,Z	; skip if not zero / not end of buffer?
	goto	CpyFnDn		; end of buffer.
	incf	temp2,f		; increment input buffer pointer.
	incf	temp3,f		; increment output buffer pointer.
	movf	temp2,w		; get input buffer pointer
	movwf	FSR		; set the pointer.
	goto	CpyFnLp		; loop around to copy more digits.
CpyFnDn				; done copying.
	movf	temp5,w		; get back original pointer.
	movwf	FSR		; put back original pointer.
	return			; done.


; *************
; ** SendNib **
; *************
SendNib				; send a byte in w as two nibbles
	;; uses temp, temp2
	movwf	temp		; save w.
	swapf	temp,w		; get hi nibble.
	andlw	h'0f'		; mask to nibble
	addwf	temp2,f		; add to checksum byte.
	call	SerOut		; send it.
	movf	temp,w		; get lo nibble.
	andlw	h'0f'		; mask to nibble
	addwf	temp2,f		; add to checksum byte.
	call	SerOut		; send it.
	return
	

; *************
; ** CpyAuto **
; *************
CpyAuto				; copy a autodial phone number.
	movf	FSR,w		; get FSR.
	movwf	temp5		; saved copy of FSR.
	movlw	low dtXbuf0	; get address of xmit buffer
	movwf	FSR		; put address of xmit buffer into FSR.
	movlw	EEADSZ		; autodial max size. copy all of em.
	movwf	eeCount		; number of bytes to copy.
	call	ReadEE		; read the autodial number from the EEPROM.
	movf	temp5,w		; get back original pointer.
	movwf	FSR		; put back original pointer.
	return			; done.

; *************
; ** DoPhone **
; *************
DoPhone				; dial a phone call from the DTMF xmit buffer.
	bcf	flags,DEFFONE	; clear deferred fone call.
	clrf	eeAddrH		; clear EEPROM high address byte.
	movlw	EETPAT		; get EEPROM address of patch timer preset.
	movwf	eeAddrL		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	ptchTmr		; set autopatch timer.
	call	FoneUp		; take phone off-hook.
	call	PlayDTMF	; play DTMF sequence.
	return



	
	org	h'1e00'
InitDat
	movwf	temp		; save addr.
	movlw	high InitTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	addwf	PCL,f		; add w to PCL
InitTbl
	;; timer initial defaults
	retlw	d'100'		; 0000 hang timer long
	retlw	d'50'		; 0001 hang timer short
	retlw	d'54'		; 0002 ID timer
	retlw	d'18'		; 0003 patch timer
	retlw	d'18'		; 0004 autodial timer
	retlw	d'30'		; 0005 emergency autodial timer
	retlw	d'60'		; 0006 DTMF access timer
	retlw	d'180'		; 0007 timeout timer long
	retlw	d'30'		; 0008 timeout timer short
	retlw	d'20'		; 0009 DTMF mute timer
	retlw	d'12'		; 000a fan timer
	retlw	d'0'		; 000b tail message counter
	retlw	d'0'		; 000c phone ring counter
	retlw	d'0'		; 000d spare
	retlw	d'0'		; 000e spare
	retlw	d'0'		; 000f spare
	;; cw id initial defaults
	retlw	h'05'		; 0010 CW ID  1 'n'
	retlw	h'10'		; 0011 CW ID  2 'h'
	retlw	h'0a'		; 0012 CW ID  3 'r'
	retlw	h'15'		; 0013 CW ID  4 'c'
	retlw	h'29'		; 0014 CW ID  5 '/'
	retlw	h'3e'		; 0015 CW ID  6 '1'
	retlw	h'3f'		; 0016 CW ID  7 '0'
	retlw	h'ff'		; 0017 CW ID  8 eom
	retlw	h'ff'		; 0018 CW ID  9 eom
	retlw	h'ff'		; 0019 CW ID 10 eom
	retlw	h'ff'		; 001a CW ID 11 eom
	retlw	h'ff'		; 001b CW ID 12 eom
	retlw	h'ff'		; 001c CW ID 13 eom
	retlw	h'ff'		; 001d CW ID 14 eom
	retlw	h'ff'		; 001e CW ID 15 eom
	retlw	h'ff'		; 001f CW ID 16 eom
	;; courtesy tone initial defaults
	;; Main Receiver Courtesy Tone
	retlw	h'05'		; 0020 Courtesy tone 0 00 length seg 1  50 ms
	retlw	h'b1'		; 0021 Courtesy tone 0 01 tone seg 1    e5
	retlw	h'05'		; 0022 Courtesy tone 0 02 length seg 2  50 ms
	retlw	h'b4'		; 0023 Courtesy tone 0 03 tone seg 2    g5
	retlw	h'05'		; 0024 Courtesy tone 0 04 length seg 3  50 ms
	retlw	h'b8'		; 0025 Courtesy tone 0 05 tone seg 3    b5
	retlw	h'05'		; 0026 Courtesy tone 0 06 length seg 4  50 ms
	retlw	h'29'		; 0027 Courtesy tone 0 07 tone seg 4    d6
	;; Main Receiver Courtesy Tone, Link RX active, alert mode.
	retlw	h'0a'		; 0028 Courtesy Tone 1 00 length seg 1 100 ms
	retlw	h'b1'		; 0029 Courtesy Tone 1 01 tone seg 1    e5
	retlw	h'0a'		; 002a Courtesy Tone 1 02 length seg 2 100 ms
	retlw	h'34'		; 002b Courtesy Tone 1 03 tone seg 2    g5
	retlw	h'00'		; 002c Courtesy Tone 1 04 length seg 3 
	retlw	h'00'		; 002d Courtesy Tone 1 05 tone seg 3
	retlw	h'00'		; 002e Courtesy Tone 1 06 length seg 4
	retlw	h'00'		; 002f Courtesy Tone 1 07 tone seg 4
	;; Main Receiver Courtesy Tone, Link TX on
	retlw	h'0a'		; 0030 Courtesy tone 2 00 length seg 1 100 ms
	retlw	h'b1'		; 0031 Courtesy tone 2 01 tone seg 1    e5
	retlw	h'0a'		; 0032 Courtesy tone 2 02 length seg 2 100 ms
	retlw	h'b4'		; 0033 Courtesy tone 2 03 tone seg 2    g5
	retlw	h'0a'		; 0034 Courtesy tone 2 04 length seg 3 100 ms
	retlw	h'38'		; 0035 Courtesy tone 2 05 tone seg 3    b5
	retlw	h'00'		; 0036 Courtesy tone 2 06 length seg 4
	retlw	h'00'		; 0037 Courtesy tone 2 07 tone seg 4
	;; Link Receiver Courtesy Tone
	retlw	h'05'		; 0038 Courtesy Tone 3 00 length seg 1  50 ms
	retlw	h'a9'		; 0039 Courtesy Tone 3 01 tone seg 1    d6
	retlw	h'05'		; 003a Courtesy Tone 3 02 length seg 2  50 ms
	retlw	h'b8'		; 003b Courtesy Tone 3 03 tone seg 2    b5
	retlw	h'05'		; 003c Courtesy Tone 3 04 length seg 3  50 ms
	retlw	h'b4'		; 003d Courtesy Tone 3 05 tone seg 3    g5
	retlw	h'05'		; 003e Courtesy Tone 3 06 length seg 4  50 ms
	retlw	h'31'		; 003f Courtesy Tone 3 07 tone seg 4    e5
	;; Link Receiver Courtesy Tone, Link TX on
	retlw	h'0a'		; 0040 Courtesy tone 4 00 length seg 1 100 ms
	retlw	h'a9'		; 0041 Courtesy tone 4 01 tone seg 1    d6
	retlw	h'0a'		; 0042 Courtesy tone 4 02 length seg 2 100 ms
	retlw	h'b8'		; 0043 Courtesy tone 4 03 tone seg 2    b5
	retlw	h'0a'		; 0044 Courtesy tone 4 04 length seg 3 100 ms
	retlw	h'34'		; 0045 Courtesy tone 4 05 tone seg 3    g5
	retlw	h'00'		; 0046 Courtesy tone 4 06 length seg 4
	retlw	h'00'		; 0047 Courtesy tone 4 07 tone seg 4
	;; Spare Courtesy Tone
	retlw	h'0a'		; 0048 Courtesy Tone 5 00 length seg 1 100 ms
	retlw	h'34'		; 0049 Courtesy Tone 5 01 tone seg 1    g4
	retlw	h'00'		; 004a Courtesy Tone 5 02 length seg 2
	retlw	h'00'		; 004b Courtesy Tone 5 03 tone seg 2
	retlw	h'00'		; 004c Courtesy Tone 5 04 length seg 3
	retlw	h'00'		; 004d Courtesy Tone 5 05 tone seg 3
	retlw	h'00'		; 004e Courtesy Tone 5 06 length seg 4
	retlw	h'00'		; 004f Courtesy Tone 5 07 tone seg 4
	;; Tune Mode Courtesy Tone
	retlw	h'0a'		; 0050 Courtesy tone 6 00 length seg 1 100 ms
	retlw	h'38'		; 0051 Courtesy tone 6 01 tone seg 1    b5
	retlw	h'00'		; 0052 Courtesy tone 6 02 length seg 2
	retlw	h'00'		; 0053 Courtesy tone 6 03 tone seg 2
	retlw	h'00'		; 0054 Courtesy tone 6 04 length seg 3
	retlw	h'00'		; 0055 Courtesy tone 6 05 tone seg 3
	retlw	h'00'		; 0056 Courtesy tone 6 06 length seg 4
	retlw	h'00'		; 0057 Courtesy tone 6 07 tone seg 4
	;; Unlocked Mode Courtesy Tone.
	retlw	h'0a'		; 0058 Courtesy Tone 7 00 length seg 1 100 ms
	retlw	h'a5'		; 0059 Courtesy Tone 7 01 tone seg 1    c7
	retlw	h'0a'		; 005a Courtesy Tone 7 02 length seg 2 100 ms
	retlw	h'b9'		; 005b Courtesy Tone 7 03 tone seg 2    c6
	retlw	h'0a'		; 005c Courtesy Tone 7 04 length seg 3 100 ms
	retlw	h'a5'		; 005d Courtesy Tone 7 05 tone seg 3    c7
	retlw	h'0a'		; 005e Courtesy Tone 7 06 length seg 4 100 ms
	retlw	h'39'		; 005f Courtesy Tone 7 07 tone seg 4    c6
	;; control prefixes
	retlw	h'00'		; 0060 control prefix 0	 00
	retlw	h'00'		; 0061 control prefix 0	 01
	retlw	h'ff'		; 0062 control prefix 0	 02
	retlw	h'ff'		; 0063 control prefix 0	 03
	retlw	h'ff'		; 0064 control prefix 0	 04
	retlw	h'ff'		; 0065 control prefix 0	 05
	retlw	h'ff'		; 0066 control prefix 0	 06
	retlw	h'ff'		; 0067 control prefix 0	 07
	retlw	h'00'		; 0068 control prefix 1	 00
	retlw	h'01'		; 0069 control prefix 1	 01
	retlw	h'ff'		; 006a control prefix 1	 02
	retlw	h'ff'		; 006b control prefix 1	 03
	retlw	h'ff'		; 006c control prefix 1	 04
	retlw	h'ff'		; 006d control prefix 1	 05
	retlw	h'ff'		; 006e control prefix 1	 06
	retlw	h'ff'		; 006f control prefix 1	 07
	retlw	h'00'		; 0070 control prefix 2	 00
	retlw	h'02'		; 0071 control prefix 2	 01
	retlw	h'ff'		; 0072 control prefix 2	 02
	retlw	h'ff'		; 0073 control prefix 2	 03
	retlw	h'ff'		; 0074 control prefix 2	 04
	retlw	h'ff'		; 0075 control prefix 2	 05
	retlw	h'ff'		; 0076 control prefix 2	 06
	retlw	h'ff'		; 0077 control prefix 2	 07
	retlw	h'00'		; 0078 control prefix 3	 00
	retlw	h'03'		; 0079 control prefix 3	 01
	retlw	h'ff'		; 007a control prefix 3	 02
	retlw	h'ff'		; 007b control prefix 3	 03
	retlw	h'ff'		; 007c control prefix 3	 04
	retlw	h'ff'		; 007d control prefix 3	 05
	retlw	h'ff'		; 007e control prefix 3	 06
	retlw	h'ff'		; 007f control prefix 3	 07
	retlw	h'00'		; 0080 control prefix 4	 00
	retlw	h'04'		; 0081 control prefix 4	 01
	retlw	h'ff'		; 0082 control prefix 4	 02
	retlw	h'ff'		; 0083 control prefix 4	 03
	retlw	h'ff'		; 0084 control prefix 4	 04
	retlw	h'ff'		; 0085 control prefix 4	 05
	retlw	h'ff'		; 0086 control prefix 4	 06
	retlw	h'ff'		; 0087 control prefix 4	 07
	retlw	h'0f'		; 0088 control prefix 5	 00
	retlw	h'ff'		; 0089 control prefix 5	 01
	retlw	h'ff'		; 008a control prefix 5	 02
	retlw	h'ff'		; 008b control prefix 5	 03
	retlw	h'ff'		; 008c control prefix 5	 04
	retlw	h'ff'		; 008d control prefix 5	 05
	retlw	h'ff'		; 008e control prefix 5	 06
	retlw	h'ff'		; 008f control prefix 5	 07
	retlw	h'00'		; 0090 control prefix 6	 00
	retlw	h'06'		; 0091 control prefix 6	 01
	retlw	h'ff'		; 0092 control prefix 6	 02
	retlw	h'ff'		; 0093 control prefix 6	 03
	retlw	h'ff'		; 0094 control prefix 6	 04
	retlw	h'ff'		; 0095 control prefix 6	 05
	retlw	h'ff'		; 0096 control prefix 6	 06
	retlw	h'ff'		; 0097 control prefix 6	 07
	retlw	h'00'		; 0098 control prefix 7	 00
	retlw	h'07'		; 0099 control prefix 7	 01
	retlw	h'ff'		; 009a control prefix 7	 02
	retlw	h'ff'		; 009b control prefix 7	 03
	retlw	h'ff'		; 009c control prefix 7	 04
	retlw	h'ff'		; 009d control prefix 7	 05
	retlw	h'ff'		; 009e control prefix 7	 06
	retlw	h'ff'		; 009f control prefix 7	 07
	retlw	h'00'		; 00a0 control prefix 8	 00
	retlw	h'08'		; 00a1 control prefix 8	 01
	retlw	h'ff'		; 00a2 control prefix 8	 02
	retlw	h'ff'		; 00a3 control prefix 8	 03
	retlw	h'ff'		; 00a4 control prefix 8	 04
	retlw	h'ff'		; 00a5 control prefix 8	 05
	retlw	h'ff'		; 00a6 control prefix 8	 06
	retlw	h'ff'		; 00a7 control prefix 8	 07
	retlw	h'00'		; 00a8 control prefix 9	 00
	retlw	h'09'		; 00a9 control prefix 9	 01
	retlw	h'ff'		; 00aa control prefix 9	 02
	retlw	h'ff'		; 00ab control prefix 9	 03
	retlw	h'ff'		; 00ac control prefix 9	 04
	retlw	h'ff'		; 00ad control prefix 9	 05
	retlw	h'ff'		; 00ae control prefix 9	 06
	retlw	h'ff'		; 00af control prefix 9	 07
	retlw	h'01'		; 00b0 control prefix 10 00
	retlw	h'00'		; 00b1 control prefix 10 01
	retlw	h'ff'		; 00b2 control prefix 10 02
	retlw	h'ff'		; 00b3 control prefix 10 03
	retlw	h'ff'		; 00b4 control prefix 10 04
	retlw	h'ff'		; 00b5 control prefix 10 05
	retlw	h'ff'		; 00b6 control prefix 10 06
	retlw	h'ff'		; 00b7 control prefix 10 07
	retlw	h'01'		; 00b8 control prefix 11 00
	retlw	h'01'		; 00b9 control prefix 11 01
	retlw	h'ff'		; 00ba control prefix 11 02
	retlw	h'ff'		; 00bb control prefix 11 03
	retlw	h'ff'		; 00bc control prefix 11 04
	retlw	h'ff'		; 00bd control prefix 11 05
	retlw	h'ff'		; 00be control prefix 11 06
	retlw	h'ff'		; 00bf control prefix 11 07
	retlw	h'01'		; 00c0 control prefix 12 00
	retlw	h'02'		; 00c1 control prefix 12 01
	retlw	h'ff'		; 00c2 control prefix 12 02
	retlw	h'ff'		; 00c3 control prefix 12 03
	retlw	h'ff'		; 00c4 control prefix 12 04
	retlw	h'ff'		; 00c5 control prefix 12 05
	retlw	h'ff'		; 00c6 control prefix 12 06
	retlw	h'ff'		; 00c7 control prefix 12 07
	retlw	h'09'		; 00c8 control prefix 13 00
	retlw	h'01'		; 00c9 control prefix 13 01
	retlw	h'01'		; 00ca control prefix 13 02
	retlw	h'ff'		; 00cb control prefix 13 03
	retlw	h'ff'		; 00cc control prefix 13 04
	retlw	h'ff'		; 00cd control prefix 13 05
	retlw	h'ff'		; 00ce control prefix 13 06
	retlw	h'ff'		; 00cf control prefix 13 07
	retlw	h'01'		; 00d0 control prefix 14 00
	retlw	h'04'		; 00d1 control prefix 14 01
	retlw	h'ff'		; 00d2 control prefix 14 02
	retlw	h'ff'		; 00d3 control prefix 14 03
	retlw	h'ff'		; 00d4 control prefix 14 04
	retlw	h'ff'		; 00d5 control prefix 14 05
	retlw	h'ff'		; 00d6 control prefix 14 06
	retlw	h'ff'		; 00d7 control prefix 14 07
	retlw	h'01'		; 00d8 control prefix 15 00
	retlw	h'05'		; 00d9 control prefix 15 01
	retlw	h'ff'		; 00da control prefix 15 02
	retlw	h'ff'		; 00db control prefix 15 03
	retlw	h'ff'		; 00dc control prefix 15 04
	retlw	h'ff'		; 00dd control prefix 15 05
	retlw	h'ff'		; 00de control prefix 15 06
	retlw	h'ff'		; 00df control prefix 15 07

ICtlTab				; initial control op defaults
	movwf	temp		; save addr.
	movlw	high CtlTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	andlw	h'0f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL
CtlTbl
	;; control operator group initial defaults
	retlw	b'01001001'	; group 0 (repeater control I)
	retlw	b'01001011'	; group 1 (repeater control II)
	retlw	b'00000001'	; group 2 (ID & tail message configuration)
	retlw	b'00000110'	; group 3 (misc. settings)
	retlw	b'11111111'	; group 4 (patch config)
	retlw	b'00010000'	; group 5 (link port config)
	retlw	b'00000000'	; group 6 (digital output configuration)
	retlw	b'00000000'	; group 7 (digital output control)
	retlw	b'10000000'	; group 8 (write protect switches)
	retlw	b'11111111'	; group 9 (cntl op group enable switches)
	retlw	b'00000000'	; group a (mailbox flags)
	retlw	b'00000000'	; group b (spare)  
	retlw	b'00000000'	; group c (spare) (future RB flags)
	retlw	b'00000000'	; group d (spare) (future RB frequency)
	retlw	b'00000000'	; group e (spare) (future RB frequency)
	retlw	b'00000000'	; group f (spare) (future RB frequency)
		
	org	1f00	    

; *************
; ** GetMask **
; *************
	;; get the bitmask of the selected numbered bit.
GetMask				; get mask of selected bit number.
	movwf	temp		; store 
	movlw	high BitTbl	; set page 
	movwf	PCLATH		; select page
	movf	temp,w		; get selected bit number into w
	andlw	h'07'		; force into valid range
	addwf	PCL,f		; add w to PCL
BitTbl
	retlw	b'00000001'	; 0 -- 0
	retlw	b'00000010'	; 1 -- 1
	retlw	b'00000100'	; 2 -- 2
	retlw	b'00001000'	; 3 -- 3
	retlw	b'00010000'	; 4 -- 4
	retlw	b'00100000'	; 5 -- 5
	retlw	b'01000000'	; 6 -- 6
	retlw	b'10000000'	; 7 -- 7
		
; *************
; ** Get100s **
; *************
	;; get the number of hundreds in INDF. return in w.
Get100s				; get tone byte from table
	movlw	high HundTbl	; set page 
	movwf	PCLATH		; select page
	movf	INDF,w		; get tone into w
	andlw	h'03'		; force into valid range
	addwf	PCL,f		; add w to PCL
HundTbl
	retlw	d'0'		; 0 -- 0
	retlw	d'100'		; 1 -- 1
	retlw	d'200'		; 2 -- 2
	retlw	d'0'		; 3 -- not valid
		
; *************
; ** GetTens **
; *************
	;; get the number of tens in INDF. return in w.
GetTens				; get tone byte from table
	movlw	high TenTbl	; set page 
	movwf	PCLATH		; select page
	movf	INDF,w		; get tone into w
	andlw	h'0f'		; force into valid range
	addwf	PCL,f		; add w to PCL
TenTbl
	retlw	d'00'		; 0 -- 0
	retlw	d'10'		; 1 -- 1
	retlw	d'20'		; 2 -- 2
	retlw	d'30'		; 3 -- 3
	retlw	d'40'		; 4 -- 4
	retlw	d'50'		; 5 -- 5
	retlw	d'60'		; 6 -- 6
	retlw	d'70'		; 7 -- 7
	retlw	d'80'		; 8 -- 8
	retlw	d'90'		; 9 -- 9
	retlw	d'00'		; A -- not valid
	retlw	d'00'		; B -- not valid
	retlw	d'00'		; C -- not valid
	retlw	d'00'		; D -- not valid
	retlw	d'00'		; * -- not valid
	retlw	d'00'		; # -- not valid
		
; *************
; ** GetTone **
; *************
	;; get a tone for the PDC3311C from the table.
	;; tone 3f is NO tone (off).
GetTone				; get tone byte from table
	movwf	temp		; save w
	movlw	high TnTbl	; set page 
	movwf	PCLATH		; select page
	movf	temp,w		; get tone into w
	andlw	h'3f'		; force into valid range
	addwf	PCL,f		; add w to PCL
TnTbl
	retlw	h'10'		; DTMF 0 tone  -- 00
	retlw	h'11'		; DTMF 1 tone  -- 01
	retlw	h'12'		; DTMF 2 tone  -- 02
	retlw	h'13'		; DTMF 3 tone  -- 03
	retlw	h'14'		; DTMF 4 tone  -- 04
	retlw	h'15'		; DTMF 5 tone  -- 05
	retlw	h'16'		; DTMF 6 tone  -- 06
	retlw	h'17'		; DTMF 7 tone  -- 07
	retlw	h'18'		; DTMF 8 tone  -- 08
	retlw	h'19'		; DTMF 9 tone  -- 09
	retlw	h'1a'		; DTMF A tone  -- 0a
	retlw	h'1b'		; DTMF B tone  -- 0b
	retlw	h'1c'		; DTMF C tone  -- 0c
	retlw	h'1d'		; DTMF D tone  -- 0d
	retlw	h'1e'		; DTMF * tone  -- 0e
	retlw	h'1f'		; DTMF # tone  -- 0f

	retlw	h'30'		; note D#5     -- 10
	retlw	h'31'		; note E5      -- 11
	retlw	h'32'		; note F5      -- 12
	retlw	h'33'		; note F#5     -- 13
	retlw	h'34'		; note G5      -- 14
	retlw	h'35'		; note G#5     -- 15
	retlw	h'36'		; note A5      -- 16
	retlw	h'37'		; note A#5     -- 17
	retlw	h'38'		; note B5      -- 18
	retlw	h'39'		; note C6      -- 19
	retlw	h'3a'		; note C#6     -- 1a
	retlw	h'29'		; note D6      -- 1b
	retlw	h'3b'		; note D#6     -- 1c
	retlw	h'3c'		; note E6      -- 1d
	retlw	h'3d'		; note F6      -- 1e
	retlw	h'0e'		; note F#6     -- 1f

	retlw	h'3e'		; note G6      -- 20
	retlw	h'2c'		; note G#6     -- 21
	retlw	h'3f'		; note A6      -- 22
	retlw	h'04'		; note A#6     -- 23
	retlw	h'05'		; note B6      -- 24
	retlw	h'25'		; note C7      -- 25
	retlw	h'2f'		; note C#7     -- 26
	retlw	h'06'		; note D7      -- 27
	retlw	h'07'		; note D#7     -- 28
	retlw	h'24'		; modem 1300   -- 29
	retlw	h'25'		; modem 2100   -- 2a
	retlw	h'26'		; modem 1200   -- 2b
	retlw	h'27'		; modem 2200   -- 2c
	retlw	h'28'		; modem	 980   -- 2d
	retlw	h'29'		; modem 1180   -- 2e
	retlw	h'2a'		; modem 1070   -- 2f

	retlw	h'2b'		; modem 1270   -- 30
	retlw	h'2c'		; modem 1650   -- 31
	retlw	h'2d'		; modem 1850   -- 32
	retlw	h'2e'		; modem 2025   -- 33
	retlw	h'2f'		; modem 2225   -- 34
	retlw	h'08'		; dtmf row 1   -- 35
	retlw	h'09'		; dtmf row 2   -- 36
	retlw	h'0a'		; dtmf row 3   -- 37
	retlw	h'0b'		; dtmf row 4   -- 38
	retlw	h'0c'		; dtmf col 1   -- 39
	retlw	h'0d'		; dtmf col 2   -- 3a
	retlw	h'0e'		; dtmf col 3   -- 3b
	retlw	h'0f'		; dtmf col 4   -- 3c
	retlw	h'00'		; no tone      -- 3d
	retlw	h'00'		; no tone      -- 3e
	retlw	h'00'		; no tone      -- 3f

; **************
; ** MesgTabl **
; **************
	;; play canned messages from ROM
	;; byte offset is index param in w.
	;; returns specified byte in w.
MesgTabl			; canned messages table (CW, beeps, DTMF, whatever)
	movwf	temp		; save addr.
	movlw	high MsgTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	andlw	h'3f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL
MsgTbl
	retlw	h'0f'		; 'O'	  -- 00
	retlw	h'0d'		; 'K'	  -- 01
	retlw	h'ff'		; EOM	  -- 02
	retlw	h'02'		; 'E'	  -- 03
	retlw	h'0a'		; 'R'	  -- 04
	retlw	h'0a'		; 'R'	  -- 05
	retlw	h'ff'		; EOM	  -- 06
	retlw	h'03'		; 'T'	  -- 07
	retlw	h'0f'		; '0'	  -- 08
	retlw	h'ff'		; EOM	  -- 09
	retlw	h'ff'		; EOM	  -- 0a
	retlw	h'ff'		; EOM	  -- 0b
	retlw	h'14'		; 0c SCANBIP -- scan mode beep
	retlw	h'25'		; 0d 
	retlw	h'00'		; oe
	retlw	h'00'		; 0f
	retlw	d'05'		; 10 bip! for patch timeout.
	retlw	h'31'		; 11
	retlw	d'00'		; 12
	retlw	h'00'		; 13
	retlw	d'05'		; 14 phone ring tone.
	retlw	h'b0'		; 15
	retlw	d'05'		; 16
	retlw	h'bb'		; 17
	retlw	d'05'		; 18
	retlw	h'b0'		; 19
	retlw	d'05'		; 1a
	retlw	h'bb'		; 1b
	retlw	d'05'		; 1c
	retlw	h'b0'		; 1d
	retlw	d'05'		; 1e
	retlw	h'bb'		; 1f
	retlw	d'05'		; 20
	retlw	h'b0'		; 21
	retlw	d'05'		; 22
	retlw	h'bb'		; 23
	retlw	d'05'		; 24
	retlw	h'b0'		; 25
	retlw	d'05'		; 26
	retlw	h'bb'		; 27
	retlw	d'05'		; 28
	retlw	h'b0'		; 29
	retlw	d'05'		; 2a
	retlw	h'bb'		; 2b
	retlw	d'05'		; 2c
	retlw	h'b0'		; 2d
	retlw	d'05'		; 2e
	retlw	h'3b'		; 2f
	
; ********************************************
; ** HexWord -- get word for hex digit in w **
; ********************************************
HexWord				; get word for hex digit.
	movwf	temp6		; save addr.
	movlw	high HexWTbl	; set page
	movwf	PCLATH		; select page
	movf	temp6,w		; get address back
	andlw	h'0f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL
HexWTbl
	;; word codes for hex digits
	retlw	V0		; 0
	retlw	V1		; 1
	retlw	V2		; 2
	retlw	V3		; 3
	retlw	V4		; 4
	retlw	V5		; 5
	retlw	V6		; 6
	retlw	V7		; 7
	retlw	V8		; 8
	retlw	V9		; 9
	retlw	VA		; a
	retlw	VB		; b
	retlw	VC		; c
	retlw	VD		; d
	retlw	VE		; e
	retlw	VF		; f

; ***********************
; * DTMF to HEX mapping *
; ***********************
;   ___ ___ ___ ___
;  |   |   |   |   |
;  | 1 | 2 | 3 | A |
;  |___|___|___|___|
;  |   |   |   |   |
;  | 4 | 5 | 6 | B |
;  |___|___|___|___|
;  |   |   |   |   |
;  | 7 | 8 | 9 | C |
;  |___|___|___|___|
;  |   |   |   |   |
;  |*/E| 0 |#/F| D |
;  |___|___|___|___|
;

MapDTMF
	movwf	temp6		; save tone.
	movlw	high DtTbl	; set page.
	movwf	PCLATH		; select page.
	movf	temp6,w		; get tone back.
	addwf	PCL,f		; add w to PCL
DtTbl
	retlw	0d		; 0 = D key
	retlw	01		; 1 = 1 key
	retlw	02		; 2 = 2 key
	retlw	03		; 3 = 3 key
	retlw	04		; 4 = 4 key
	retlw	05		; 5 = 5 key
	retlw	06		; 6 = 6 key
	retlw	07		; 7 = 7 key
	retlw	08		; 8 = 8 key
	retlw	09		; 9 = 9 key
	retlw	00		; A = 0 key
	retlw	0e		; B = * key (e)
	retlw	0f		; C = # key (f)
	retlw	0a		; D = A key
	retlw	0b		; E = B key
	retlw	0c		; F = C key

	
	end

	
; MORSE CODE encoding...
;
; morse characters are encoded in a single byte, bitwise, LSB to MSB.
; 0 = dit, 1 = dah.  the byte is shifted out to the right, until only 
; a 1 remains.	characters with more than 7 elements (error) cannot be sent.
;
; a .-	    00000110  06		 ; 0 -----   00111111  3f
; b -...    00010001  11		 ; 1 .----   00111110  3e
; c -.-.    00010101  15		 ; 2 ..---   00111100  3c
; d -..	    00001001  09		 ; 3 ...--   00111000  38
; e .	    00000010  02		 ; 4 ....-   00110000  30
; f ..-.    00010100  14		 ; 5 .....   00100000  20
; g --.	    00001011  0b		 ; 6 -....   00100001  21
; h ....    00010000  10		 ; 7 --...   00100011  23
; i ..	    00000100  04		 ; 8 ---..   00100111  27
; j .---    00011110  1e		 ; 9 ----.   00101111  2f
; k -.-	    00001101  0d					 
; l .-..    00010010  12		 ; sk ...-.- 01101000  58
; m --	    00000111  07		 ; ar .-.-.  00101010  2a
; n -.	    00000101  05		 ; bt -...-  00110001  31
; o ---	    00001111  0f		 ; / -..-.   00101001  29
; p .--.    00010110  16					 
; q --.-    00011011  1b		 ; space     00000000  00
; r .-.	    00001010  0a		 ; EOM	     11111111  ff
; s ...	    00001000  08
; t -	    00000011  03
; u ..-	    00001100  0c
; v ...-    00011000  18
; w .--	    00001110  0e
; x -..-    00011001  19
; y -.--    00011101  1d
; z --..    00010011  13
	
;; CW timebase:
;; WPM	setting
;;   5	  240
;;   6	  200
;;   7	  171
;;   8	  150
;;   9	  133
;;  10	  120
;;  11	  109
;;  12	  100
;;  13	   92
;;  14	   86
;;  15	   80
;;  16	   75
;;  17	   71
;;  18	   67
;;  19	   63
;;  20	   60
;;  21	   57
;;  22	   55
;;  23	   52
;;  24	   50
;;  25	   48
;;  26	   46
;;  27	   44
;;  28	   43
;;  29	   41
;;  30	   40
