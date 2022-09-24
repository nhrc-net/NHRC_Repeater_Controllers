	;; NHRC-4 Repeater Controller.
	;; Copyright 2000-2005, NHRC LLC,
	;; as an unpublished proprietary work.
	;; All rights reserved.
	;; No part of this document may be used or reproduced by any means,
	;; for any purpose, without the expressed written consent of NHRC LLC.

	;; foo-004 22 October 2003
        ;; nhrc-4.asm 20 July 2005

	;; 001 - this is a conversion of the NHRC-5 to run in 4K.
	;; 002 - then the voice record/play , digital outputs, alarm, 
	;;	 courtesy tone select, aux receiver functionality was removed.
	;; 003 - removed 2nd DTMF decoder, etc.
	;; 004 - convert to NHRC-4

VER_INT	equ	d'3'
VER_HI	equ	d'0'
VER_LO	equ	d'0'

LOAD_EE=1

;;DEBUG=1				; 
	ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

	IFDEF __16F648A
	include "p16f648a.inc"
	IFDEF ICD
	;; for ICD don't use watchdog or code protect
	__FUSES _EXTCLK_OSC & _WDT_OFF & _LVP_OFF & _PWRTE_ON
	ELSE
	;; not ICD
	__FUSES _CP_ON & _EXTCLK_OSC & _WDT_ON & _LVP_OFF & _PWRTE_ON
	ENDIF			; ICD
	ELSE
	ERROR wrong processor selected!
	ENDIF
	
	include "eeprom.inc"

;macro definitions for ROM paging.
	
PAGE0	macro			; select page 0
	bcf	PCLATH,3
	endm

PAGE1	macro			; select page 1
	bsf	PCLATH,3
	endm

	IFDEF DEBUG
TEN	equ	D'4'		; decade counter.
	ELSE
TEN	equ	D'10'		; decade counter.
	ENDIF
	
; *************************
; ** IO Port Assignments **
; *************************

; Port A has the DTMF data, and one bit that is used for muting and init
; A.0 (in ) = DTMF bit 0
; A.1 (in ) = DTMF bit 1
; A.2 (in ) = DTMF bit 2
; A.3 (in ) = DTMF bit 3
; A.4 (in ) = init input at start up, mute output after
;
;Port A
TMASK	equ	0f
DTMFQ1	equ	0		; input, DTMF decoder Q1
DTMFQ2	equ	1		; input, DTMF decoder Q2
DTMFQ3	equ	2		; input, DTMF decoder Q3
DTMFQ4	equ	3		; input, DTMF decoder Q4
INIT	equ	4
MUTE	equ	4		; mute and init share A.4
DIAGLED	equ	6		; diagnostic LED on RA6
;
; Port B has the following
; B.0 (in ) = DTMF digit valid (in)
; B.1 (out) = PTT (out)
; B.2 (out) = remote base COR (in)
; B.3 (out) = remote base muting (out)
; B.4 (out) = remote base PTT (out)
; B.5 (out) = control output (out)
; B.6 (out) = beep tone output
; B.7 (in ) = COR
;
;PORTB
DV	equ	0		; DTMF digit valid
PTT	equ	1		; PTT key
RX1COR	equ	2		; remote base COR
RB_MUTE equ	3		; remote base muting
RB_PTT	equ	4		; remote base PTT
DOUT	equ	5		; digital out
FANCTL	equ	5		; digital out/Fan control
BEEPBIT equ	6		; beep generator
RX0COR	equ	7		; unsquelched (0) / squelched (1)
	
; *******************
; ** Control Flags **
; *******************
	
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
IDNOW	equ	2		; ID is running now.
TXONFLG	equ	3		; last TX state flag
CMD_NIB equ	4		; command interpreter nibble flag for copy
DEF_CT	equ	5		; deferred courtesy tone.
RBMUTE	equ	6		; remote base muted
IDTOGL	equ	7		; ID toggle flag, selects alternately ID 1 & 2

;mscFlag 			; misc flags...
DT0ZERO	equ	0		; dtmf-0 last received 0
;; niy 	equ	1		; 
;; NIY	equ	2		; 
;; NIY	equ	3		; 
LASTDV0	equ	4		; last DTMF digit valid, dtmf-0
;niy	equ	5		; 
;niy	equ	6		; 
;niy	equ	7		; 

; txFlag
RX0OPEN equ	0		; main receiver repeating
RX1OPEN	equ	1		; link receiver repeating
;;NIY	equ	2		; 
TXHANG	equ	3		; hang time
; niy	equ	4		; 
; niy	equ	5		; was ISD playing back
BEEPING equ	6		; beep tone active
CWPLAY	equ	7		; CW playing

CWTBDLY	equ	d'60'		; CW timebase delay for 20 WPM.
	
;; COR debounce time
COR1DEB equ	3		; 30 ms. COR off to on debounce time
COR0DEB equ	2		; 20 ms. COR on to off debounce time
DLY1DEB equ	d'25'		; 250 ms. COR off->on debounce time, with DAD.
DLY0DEB equ	d'20'		; 200 ms. COR on->off debounce time, with DAD.
CHNKDEB	equ	d'75'		; 750 ms.
IDSOON	equ	D'6'		; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ	D'20'		; DTMF muting timer = 2.0 sec.
DTMFDLY	equ	d'50'		; DTMF activity timer = 5.0 sec.
UNLKDLY	equ	d'120'		; unlocked mode timer.
	
; dtRFlag -- dtmf sequence received indicator
DT0RDY	equ	0		; some sequence received on DTMF-0
;NIY	equ	1		; 
;NIY	equ	2		; 
DTUL	equ	3		; command received from unlocked port.
DTSEVAL	equ	4		; dtmf command evaluation in progress.
DT0UNLK equ	5		; unlocked indicator
;NIY	equ	6		; 
;NIY	equ	7		; 
		;; 
;dtEFlag -- DTMF command evaluator control flag.
	;; low order 5 bits indicate next prefix number/user command to scan
DT0CMD	equ	5		; received this command from dtmf0
;NIY	equ	6		; received this command from dtmf1
;NIY	equ	7		;


; beepCtl -- beeper control flags...
B_ADR0	equ	0		; beep or CW addressing mode indicator
B_ADR1	equ	1		; beep or CW addressing mode indicator
				;	00 EEPROM
				;	01 lookup table index, built in messages.
				;	10 from RAM
				;	11 CW single letter mode
				; 
B_BEEP	equ	2		; beep sequence in progress
B_CW	equ	3		; CW transmission in progress
;	equ	4		;
;	equ	5		;
B_LAST	equ	6		; last segment of CT tones.
;	equ	7		;

; beepCtl preset masks
BEEP_CT equ	b'10000100'	; CT from EEPROM
BEEP_CX equ	b'10000101'	; CT from ROM table
CW_ROM	equ	b'10001001'	; CW from ROM table
CW_EE	equ	b'10001000'	; CW from EEPROM
CW_LETR	equ	b'10001011'	; CW ONE LETTER ONLY.

CTPAUSE equ	d'5'		; 50 msec pause before CT.

MAGICCT	equ	d'99'		; magic CT length.	next digit is CW digit.
PULS_TM	equ	d'50'		; 50 x 10 ms = 500 ms. pulse duration time.

	
; receiver states
RXSOFF	equ	0
RXSON	equ	1
RXSTMO	equ	2

; cTone Courtesy tone selections
CTNONE	equ	h'ff'		; no courtesy tone.
CTNORM	equ	0		; normal courtesy tone
CTALERT	equ	1		; alert mode alerted courtesy tone
CTRBTX 	equ	2		; courtesy tone when link tx enabled
CTRRBRX	equ	3		; courtesy tone link receiver link tx off
CTRRBTX	equ	4		; courtesy tone link receiver link tx on
CTSEL5	equ	5		; EXP3 controlled courtesy tone (boop)
CTSEL6	equ	6		; EXP4 controlled courtesy tone (beep)
CTUNLOK	equ	7		; unlocked courtesy tone

; CW Message Addressing Scheme:
; These symbols represent the value of the CW characters in the ROM table.
;	1 - CW timeout message, "to"
;	2 - CW confirm message, "ok"
;	3 - CW bad message, "ng"
;	3 - CW link timeout "rb to"

CW_OK	equ	h'00'		; CW: OK
CW_NG	equ	h'03'		; CW: NG
CW_TO	equ	h'07'		; CW: TO
CWNHRC4	equ	h'0a'		; CW: NHRC 4 message.
CW_ON	equ	h'11'		; CW: ON
CW_OFF	equ	h'14'		; CW: OFF
BP_ALM	equ	h'18'		; beep:	alarm tone
	
;
; CW sender constants
;

CWDIT	equ	1		; dit length in 100 ms
CWDAH	equ	CWDIT * 3	; dah 
CWIESP	equ	CWDIT		; inter-element space
CWILSP	equ	CWDAH		; inter-letter space
CWIWSP	equ	CWDIT * 7	; inter-word space

T0PRE	equ	D'37'		; timer 0 preset for overflow in 224 counts.

; ***************
; ** VARIABLES **
; ***************
	cblock	h'20'		; 1st block of RAM at 20h-7fh (96 bytes here)
	;; interrupt pseudo-stack to save context during interrupt processing.
	s_copy			; saved STATUS
	p_copy			; saved PCLATH
	f_copy			; saved FSR
	i_temp			; temp for interrupt handler
	;; internal timing generation
	tFlags			; Timer Flags
	oneMsC			; one millisecond counter
	tenMsC			; ten milliseconds counter
	hundMsC			; hundred milliseconds counter
	thouMsC			; thousand milliseconds counter (1 sec)

	temp			; working storage. don't use in int handler.
	temp2			; more working storage
	temp3			; still more temporary storage
	temp4			; yet still more temporary storage
	temp5			; temporary storage...
	temp6			; temporary storage...
	cmdSize			; # digits received for current command
	;; operating flags
	flags			; operating Flags
	mscFlag			; misc. flags.
	txFlag			; Transmitter control flag
	rxFlag			; Receiver COS valid flags
	;; beep generator control 
	beepTmr		 ; timer for generating various beeps
	beepAddr		; address for various beepings, low byte.
	beepCtl		 ; beeping control flag
	;; debounce timers
	rx0Dbc			; main receiver debounce timer
	rx1Dbc			; link receiver debounce timer
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
	dtATmr			; dtmf access timer
	fanTmr			; fan timer
	unlkTmr			; unlocked mode timer.
	;; timer presets
	hangDly			; hang timer preset, used often enough to keep around
	;; CW generator data
	cwTmr			; CW element timer
	cwByte			; CW current byte (bitmap)
	cwTbTmr			; CW timebase timer
	cwTone			; CW tone
        cwSpeed                 ; CW speed
	
	cTone			; courtesy tone to play

	eeAddr			; EEPROM address (low byte) to read/write
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
	;; last var at 0x?? there are ?? left in this block...
	endc			; this block ends at 6f

	cblock	h'70'		; from 70 to 7f is common to all banks!
	rICD70			; 70 reserved for ICD2
	w_copy			; 71 saved W register for interrupt handler
	dt0Ptr			; 72 DTMF-0 buffer pointer
	dt0Tmr			; 73 DTMF-0 buffer timer
	dt1Ptr			; 74 DTMF-1 buffer pointer
	dt1Tmr			; 75 DTMF-1 buffer timer
	scratch			; 76 scratchpad. (not currently used.)
	dtRFlag			; 77  DTMF receive flag...
	dtEFlag			; 78  DTMF command interpreter control flag
	eebPtr			; 79  eebuf write pointer.
	;; room here from 7a to 7f
	endc			; 1st RAM block ends at 7f

	cblock	h'a0'		; 2nd block of RAM at a0h-efh (80 bytes here)
	endc
	
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
	endc			; 2nd RAM block ends at ff

	;; 16c77 ram blocks continue...
	cblock	h'110'		; 16 bytes at 110h-11fh
	endc
	
	cblock	h'120'		; 80 bytes 120h-16fh
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
	endc			; end of 16 byte DTMF receiver buffer.

	cblock	h'130'		; eeprom write buffer (16 bytes) @ 130
	eebuf00			; eeprom write buffer (16 bytes) @ 130
	eebuf01
	eebuf02
	eebuf03
	eebuf04
	eebuf05
	eebuf06
	eebuf07
	eebuf08
	eebuf09
	eebuf0a
	eebuf0b
	eebuf0c
	eebuf0d
	eebuf0e
	eebuf0f
	endc			; end of 16 byte eeprom write buffer

	cblock	h'140'		; command buffer (32 bytes) at 140-15f
	cmdbf00			; command buffer  @140
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
	cmdbf0f			; command buffer  @14f (16 bytes)
	cmdbf10			; command buffer  @150
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
	cmdbf1f			; command buffer @15f (32 bytes)
	endc			; end of 32 byte command buffer
	
	cblock	h'165'		; reserved for ICD2
	rICD165			; reserved for ICD2
	rICD166			; reserved for ICD2
	rICD167			; reserved for ICD2
	rICD168			; reserved for ICD2
	rICD169			; reserved for ICD2
	rICD16a			; reserved for ICD2
	rICD16b			; reserved for ICD2
	rICD16c			; reserved for ICD2
	rICD16d			; reserved for ICD2
	rICD16e			; reserved for ICD2
	rICD16f			; reserved for ICD2
	endc
	
	cblock	h'170'		; this is common with 70-7f
	rICD170			; reserved for ICD2
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
	
	cblock	h'1f0'		; this is common with 70-7f
	rICD1f0			; reserved for ICD
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
	endc			; 4th RAM block ends at 1ff
	
; ********************
; ** STARTUP VECTOR **
; ********************
	org	h'0000'		; startup vector
	clrf	PCLATH		; stay in bank 0
	goto	Start

; ***********************
; ** INTERRUPT HANDLER **
; ***********************
IntHndlr
	org	h'0004'		; interrupt vector
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
	
	
TimrInt
	btfss	INTCON,T0IF	; Timer Interrupt?
	goto	CompInt		; no
	movlw	T0PRE		; get timer 0 preset value
	movwf	TMR0		; preset timer 0
	bsf	tFlags,TICK	; set tick indicator flag
	bcf	INTCON,T0IF	; clear RTCC int mask
	
CompInt				; timer 1 compare match interrupt.
	btfss	PIR1,CCP1IF	; CCP 1 interrupt?
	goto	EEWrInt		; no.
	clrf	TMR1L		; clear timer 1
	clrf	TMR1H		; clear timer 1
	bcf	PIR1,CCP1IF	; clear compare match interrupt bit.
	btfss	PORTB,BEEPBIT	; is beep bit hi?
	goto	CompInL		; no.
	bcf	PORTB,BEEPBIT	; lower beep bit.
	goto	EEWrInt		; done.
CompInL				; beep bit was low.
	bsf	PORTB,BEEPBIT	; raise beep bit.
	
EEWrInt				; EEPROM write complete interrrupt
	btfsc	PIR1,EEIF	; EE Write Complete interrupt?
	bcf	PIR1,EEIF	; yes, clear interrupt bit.

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
	
;
; Play the appropriate ID message, reset ID timers & flags
;
DoID
	btfss	flags,needID	; need to ID?
	return			; nope--id timer expired without tx since last
	;; play the ID here.
	bsf	flags,IDNOW	; set IDing now flag.
	PAGE1			; select code page 1.
 	movlw	EECWID		; address of CW ID message in EEPROM.
	movwf	eeAddr		; save CT base address
	call	PlayCWe		; kick of the CW playback.
	PAGE0			; select code page 0.
	
DoIDrst				; reset ID timer & logic.
	movlw	EETID		; get EEPROM address of ID timer preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	idTmr		; store to idTmr down-counter
	bcf	flags,initID	; clear initial ID flag
	movf	txFlag,w	; get tx flags
	andlw	h'03'		; w=w&(RX0OPEN|RX1OPEN), non zero if RX active.
	btfsc	STATUS,Z	; is it zero?
	bcf	flags,needID	; yes. reset needID flag.
	return

Rcv0Off				; turn off receiver 0
	movlw	RXSOFF		; get new state #
	movwf	rx0Stat		; set new receiver state
	bsf	PORTA,MUTE	; mute the receiver audio.
	bcf	txFlag,RX0OPEN	; clear main receiver on bit
	clrf	rx0TOut		; clear main receiver timeout timer
	goto	ChkMute		; check muting and TX status.
	
Rcv1Off				; turn off receiver 1
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bsf	PORTB,RB_MUTE	; mute RB.
	bcf	txFlag,RX1OPEN	; clear main receiver on bit
	clrf	rx1TOut		; clear main receiver timeout timer

ChkMute				; check to see if any transmitters were muted
	movf	muteTmr,f	; check mute timer
	btfsc	STATUS,Z	; is mute timer running?
	return			; no.
	btfss	flags,TXONFLG	; is the transmitter supposed to be on?
	return			; no.

	btfsc	group4,6	; drop TX to mute?
	bsf	PORTB,PTT	; turn TX back on.

	btfss	group3,7	; drop link TX to mute?
	return			; no.

	;is link a slaved repeater? turn link TX back on if it is.
	btfsc	group1,5	; slaved repeater mode?
	bsf	PORTB,RB_PTT	; yes.
	return			; done

SetHang				; start hang timer...
	btfss	group0,3	; is hang timer enabled?
	return			; nope.
	movlw	EETHTS		; get EEPROM address of hang timer short preset
	btfsc	group0,4	; is long hang timer selected?
	movlw	EETHTL		; get EEPROM address of hang timer long preset
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	hangDly		; save this in hangDly, used often.
	movwf	hangTmr		; preset hang timer
	btfss	STATUS,Z	; is hang timer zero.
	bsf	txFlag,TXHANG	; no, set hang time transmit flag
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
	PAGE1			; select ROM code page 1.
	call	WriteEE		; write into EEPROM.
	PAGE0			; select ROM code page 0.
	;; pause while EE operation completes.
	call	InitPos		; pause.
	movlw	d'32'		; get size.
	addwf	eeAddr,f	; add to address.
	movwf	eeCount		; reset number of bytes to write.
	decfsz	temp2,f		; decrement cycle count.
	goto	I256a		; next cycle.
	return			; done.
	
; *************
; ** InitPos **
; *************
InitPos				; short pause for EEPROM write cycle.
	movlw	d'20'		; 20 ms.
	call	InitDly		; delay.
	movlw	d'19'		; 19 ms.
	call	InitDly		; delay.
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
	
; *********************
; ** PROGRAM STARTUP **
; *********************
	org	h'0200'
Start
	;bsf	STATUS,IRP	; select FSR is in 100-1ff range
	bsf	STATUS,RP0	; select bank 1

	movlw	b'00000001'	; RBPU pull ups 
				; INTEDG INT on falling edge
				; T0CS	 TMR0 uses instruction clock
				; T0SE  n/a
				; PSA TMR0 gets the prescaler 
				; PS2 \
				; PS1  > prescaler 4
				; PS0 /
	movwf	OPTION_REG	; set options

	movlw	b'00011111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	movlw	b'10000101'	; RB0, RB2 & RB7 inputs
	movwf	TRISB

	clrf	PIE1		; turn off all peripheral interrupts.
	bsf	PIE1,CCP1IE	; enable on CCP1 interrupt.
	
  	bcf	STATUS,RP0	; select bank 0

	;; PORT A does not need to be initialized, it is input-only.

	movlw	b'00001000'	; preset port B (bit 3 is RB MUTE)
	movwf	PORTB		; preset port B values...

	clrf	PORTA		; clear port a
	movlw	h'07'		; turn off all comparators
	movwf	CMCON

	clrwdt			; give me more time to get up and running.

	;; set up timer 1
	movlw	b'00000000'	; set up timer 1.
	movwf	T1CON		; set up timer 1.
	movlw	b'00001010'	; timer 1 compare throws interrupt.
	movwf	CCP1CON		; set up compare mode.
	movlw	h'ff'		; init compare value.
	movwf	CCPR1L		; set up initial compare (invalid)
	movwf	CCPR1H		; set up initial compare (invalid)
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

	movlw	CTNONE		; no courtesy tone.
	movwf	cTone		; set courtesy tone selector.
	
	;; preset timer defaults
	clrf	cwTbTmr		; CW timebase counter.
        
	;; enable interrupts.
	movlw	b'11100000'	; enable global + peripheral + timer0
	movwf	INTCON

	btfsc	PORTA,INIT	; skip if init button pressed.
	goto	Start1		; no initialize request.
	
; *********************
; * INITIALIZE EEPROM *
; *********************
		
	clrf	temp2		; byte index
InitLp
	movf	temp2,w		; get last address.
	sublw	EELAST		; subtract last init address.
	btfss	STATUS,C	; c will be clear if result is negative.
	goto	Start1		; done initializing...
	movf	temp2,w		; get init address
	movwf	eeAddr		; set eeprom address
	movf	temp2,w		; get init address
	PAGE1			; select page 1.
	call	InitDat		; get init byte
	call	WriteEw		; write byte to EEPROM.
	PAGE0			; select page 0
	incf	temp2,f		; go to next byte
	goto	InitLp		; get the next block of 16 or be done.
	
; ********************************
; ** Ready to really start now. **
; ********************************
Start1
	bsf	STATUS,RP0	; select bank 1
	movlw	b'00001111'	; low 4 bits are input, RA4 is muting control
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select bank 0
	bsf	PORTA,MUTE	; mute the receiver audio.
	
	clrw			; select macro set 0.
	PAGE1			; select page 1.
	call	LoadCtl		; load control op settings.
	call	CWParms		; get the CW Parameters.
	;;
	;; say hello to all the nice people out there.
	;;
	movlw	CWNHRC4		; get controller name announcement.
	call	PlayCW		; start playback
	PAGE0			; select code page 0.
	
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
	bsf	tFlags,TENSEC	; set TENSEC indicator.

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
	;; Diagnostic LED blinker.
	btfss	tFlags,HUNDMS
	goto	LedEnd
	btfss	PORTA,DIAGLED
	goto	l3off
	bcf	PORTA,DIAGLED
	goto	LedEnd
l3off 
	bsf	PORTA,DIAGLED
LedEnd
	
; ********************************************
; ** RECEIVER DEBOUNCE AND INPUT VALIDATION **
; ********************************************
DebRx
	btfss	tFlags,TENMS	; is the ten ms tick active?
	goto	TenMsD		; nope
CkRx0				; check COR state receiver 1
	btfsc	PORTB,RX0COR	; check cor receiver 1
				; COR is not present.
	goto	Rx0Off		; high, COR is not present
Rx0On				; COR is present.
	btfsc	rxFlag,RX0OPEN	; already marked active?
	goto	Rx0NC		; yes.
	movf	rx0Dbc,f	; check for zero
	btfss	STATUS,Z	; is it zero?
	goto	Rx01Dbc		; nope...
	movlw	COR1DEB		; get COR debounce timer value.
	btfsc	group2,6	; is the delay present?
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
	btfsc	group2,6	; is the delay present?
	movlw	DLY0DEB		; get COR debounce with delay value.
	movwf	rx0Dbc		; set it
	goto	Rx0Done		 ; done.
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
	btfsc	PORTB,RX1COR	; check cor receiver 1
	goto	Rx1Off		; no COR receiver 1.
Rx1On				; COR is present for receiver 1
	btfsc	rxFlag,RX1OPEN	; already marked active?
	goto	Rx1NC		; yes.
	movf	rx1Dbc,f	; check for zero
	btfss	STATUS,Z	; is it zero?
	goto	Rx11Dbc		; nope...
	movlw	COR1DEB		; get COR debounce timer value
	btfsc	group2,7	; is the delay present?
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
	btfsc	group2,7	; is the delay present?
	movlw	DLY0DEB		; get COR debounce with delay value.
	movwf	rx1Dbc		; set it
	goto	Rx1Done		; done.
Rx10Dbc
	decfsz	rx1Dbc,f	; decrement the debounce counter
	goto	Rx1Done		; not zero yet
	bcf	rxFlag,RX1OPEN	; set receiver active flag
	btfss	group1,4	; is control rx & link port the same?
	goto	Rx1Done		; nope.
	movf	dt1Tmr,f	; test to see if touch-tones received...
	btfsc	STATUS,Z	; is it zero?
	goto	Rx1Done		; yes. don't need to accellerate execution.
	movlw	d'2'		; no
	movwf	dt1Tmr		; accelerate eval of DTMF command
	goto	Rx1Done		; done.
Rx1NC
	clrf	rx1Dbc		; clear debounce counter.
Rx1Done
	
	;; ******************
	;; ** check DTMF-0 ** 
	;; ******************
CkDTMF0	
	btfss	PORTB,DV	; is a DTMF digit being decoded?
	goto	CkDT0L		; no
	btfsc	mscFlag,LASTDV0	; was it there last time?
	goto	CkDTDone	; yes, do nothing.
	bsf	mscFlag,LASTDV0	; set last DV indicator.

RdDT0
	btfsc	group1,3	; is muting enabled?
	bsf	PORTA,MUTE	; mute the receiver audio.
	btfsc	group3,7	; drop link to mute enabled?
	bcf	PORTB,RB_PTT	; turn off link PTT.
	btfsc	group4,6	; drop main TX to mute enabled?
	bcf	PORTB,PTT	; turn off main PTT.
	movlw	MUTEDLY		; get mute timer delay
	movwf	muteTmr		; preset mute timer
RdDT0m
	movlw	DTMFDLY		; get DTMF activity timer preset.
	movwf	dt0Tmr		; set dtmf command timer
	
	movf	dt0Ptr,w	; get index
	movwf	FSR		; put it in FSR
	bcf	STATUS,C	; clear carry (just in case)
	rrf	FSR,f		; hey! divide by 2.
	movlw	LOW dt0buf0	; get address of buffer
	addwf	FSR,f		; add to index.

	movlw	b'00001111'	; mask bits.
	andwf	PORTA,w		; get masked bits of tone into W.
	call	MapDTMF		; remap tone into keystroke value..
	iorlw	h'0'		; OR with zero to set status bits.
	bcf	mscFlag,DT0ZERO	; clear last zero received.
	btfsc	STATUS,Z	; was a zero the last received digit?
	bsf	mscFlag,DT0ZERO	; yes...
	
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

	goto	CkDTDone	; done with DTMF checking.

CkDT0L				; check for end of LITZ...
	btfss	mscFlag,LASTDV0	; was it low last time?
	goto	CkDTDone	; yes.	Done.
	bcf	mscFlag,LASTDV0	; no, clear last DV indicator.

CkDTDone			; done with DTMF scanning.
TenMsD				; ten ms tasks done.
	
	goto	MainLp		; crosses 256 byte boundary (to 0400)

	org	h'0400'
	
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
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	dtATmr		; set DTMF access mode timer.
Main00				; receiver inactive --> active transition
	movlw	RXSON		; get new state #
	movwf	rx0Stat		; set new receiver state
	bsf	txFlag,RX0OPEN	; set main receiver on bit
	movlw	CTNONE		; no courtesy tone.
	movwf	cTone		; kill off any pending courtesy tone.
	movf	muteTmr,f	; check mute timer
	btfsc	STATUS,Z	; if it's non-zero, skip unmute
	bcf	PORTA,MUTE	; unmute the receiver audio.
MainUM
	;; link non-repeater PTT logic
	btfss	group3,2	; is link TX enabled?
	goto	Main01		; nope...
	btfsc	group1,5	; is link port a repeater?
	goto	Main01		; no.
	PAGE1			; select code page 1.
	call	PTT1On		; turn on TX1 PTT
	PAGE0			; select code page 0
	
Main01
        ;;  jeff -- this is the logic to mute the RB for main RX priority.
        btfss   group3,3        ; is mute RB on RX set?
        goto    Main01a         ; no.
        bsf     flags,RBMUTE    ; mark RB muted.

	btfss	txFlag,RX1OPEN	; is RB active?
        goto    Main01a         ; no.
	bsf	PORTB,RB_MUTE	; yes, mute RB.
        
Main01a
	btfss	group1,0	; is time out timer enabled?
	goto	ChkRb		; nope...
	movlw	EETTMS		; EEPROM address of timeout timer short preset.
	btfsc	group1,1	; is short timeout selected
	movlw	EETTML		; EEPROM address of timeout timer long preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rx0TOut		; set timeout counter
        goto    ChkRb
        
Main1				; receiver active state
	btfss	group0,0	; is repeater enabled?
	goto	Main1Off	; no.	turn receiver off
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
	bsf	PORTA,MUTE	; mute the receiver audio.
	clrf	rx0TOut		; clear main receiver timeout timer

        ;;  jeff -- this is the logic to unmute the RB when muted for priority.
        btfss   group3,3        ; is mute RB on RX set?
        goto    Main1TO         ; no.
        bcf     flags,RBMUTE    ; clear RB mute flag.
        btfsc   txFlag,RX1OPEN  ; is the RB still active?
	bcf	PORTB,RB_MUTE	; yes, unmute RB.

Main1TO	
	movlw	CW_TO		; time out message
	PAGE1			; select code page 1.
	call	PlayCW		; play the CW message.
	PAGE0			; select code page 0.
	goto	ChkRb		; done here...

Main1Off			; receiver was active, became inactive
	call	Rcv0Off		; turn off receiver
	;; link non-repeater-mode PTT logic
	btfss	group3,2	; is link port TX enabled?
	goto	Main10		; nope...
	btfsc	group1,5	; is link port a repeater?
	goto	Main10		; yes...
	PAGE1			; select code page 1
	call	PTT1Off
	PAGE0			; select code page 1
Main10
        ;;  jeff -- this is the logic to unmute the RB when muted for priority.
        btfss   group3,3        ; is mute RB on RX set?
        goto    Main10a         ; no.
        bcf     flags,RBMUTE    ; clear RB mute flag.
        btfsc   txFlag,RX1OPEN  ; is the RB still active?
	bcf	PORTB,RB_MUTE	; yes, unmute RB.
        
Main10a
	movlw	CTNORM		; get CT number
	btfss	group3,2	; is rb tx enabled?
	goto	Main10e		; nope.
	movlw	CTRBTX		; yes, get that courtesy tone
	goto	Main10h

Main10e
	btfss	group3,0	; is alert mode on?
	goto	Main10h		; nope.
	btfsc	rxFlag,RX1OPEN	; is rb squelch open?
	movlw	CTALERT		; yes, get that courtesy tone

Main10h
	movwf	cTone		; save the courtesy tone.
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now
Main10s				; Simplex mode; no hang, no courtesy tone.
	goto	ChkRb		; done here...

Main2				; receiver timedout state
	btfss	group0,0	; is repeater enabled?
	goto	Main2Off	; no.	turn receiver off
	btfsc	rxFlag,RX0OPEN	; is squelch still open?
	goto	ChkRb		; yes, still timed out
Main2Off			; end of timeout condition.
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rx0Stat		; set new receiver state
	btfsc	group2,3	; is voice timeout message enabled?
	goto	Main2TO		; yes...
	PAGE1			; select code page 1.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkRb		; done here...
Main2TO	
	movlw	CW_TO		; time out message
	PAGE1			; select code page 1.
	call	PlayCW		; play the message.
	PAGE0			; select code page 0.
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
	goto	ChkTmrs		; no.	don't allow link activity.
	movf	group3,w	; get group 3
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	ChkTmrs		; no...
	btfss	group0,5	; is DTMF access mode enabled?
	goto	RbRx01		; no.
	movf	dtATmr,f	; check DTMF access mode timer.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkTmrs		; yes.	Don't turn receiver on.
	;; timer is not zero, reset to initial value.
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	dtATmr		; set DTMF access mode timer.
	
RbRx01				; turn on remote base receiver.
	movlw	RXSON		; get new state #
	movwf	rx1Stat		; set new receiver state
	bsf	txFlag,RX1OPEN	; set link receiver on bit
	btfss	flags,RBMUTE	; is mute requested for some reason?
	bcf	PORTB,RB_MUTE	; no, unmute RB.
	btfss	group3,5	; is time out timer enabled?
	goto	RbRx01L		; nope...
	movlw	EETTMS		; EEPROM address of timeout timer long preset.
	btfsc	group1,1	; is short timeout selected
	movlw	EETTML		; EEPROM address of timeout timer short preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rx1TOut		; set timeout counter
RbRx01L
	btfss	group1,5	; are we in slaved repeater mode?
	goto	ChkTmrs		; no.
	PAGE1			; select code page 1.
	call	PTT1On		; turn on TX1 PTT.
	PAGE0			; select code page 0.
	goto	ChkTmrs		; done here...

RbRx1				; receiver active state
	btfss	group0,0	; is repeater enabled?
	goto	RbRx1Off	; no.	turn off link receiver.
	movf	group3,w	; get group 3
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
	bsf	PORTB,RB_MUTE	; mute RB.
	clrf	rx1TOut		; clear receiver 1 timeout timer
	btfsc	group2,3	; is voice timeout message enabled?
	goto	RbRx1TO		; yes...
	PAGE1			; select code page 1.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkTmrs		; done here...
RbRx1TO	
	movlw	CW_TO		; time out message
	PAGE1			; select code page 1.
	call	PlayCW		; play the message.
	PAGE0			; select code page 0.
	goto	ChkTmrs		; done here...

RbRx1Off			; receiver was active, became inactive
	call	Rcv1Off		; turn off link receiver
	;; if link tx is on, and link is not a repeater, then 
	;; suppress link ctsy tone.
	btfss	PORTB,RB_PTT	; is link tx on?
	goto	RbRx1o1		; nope.
	btfss	group1,5	; is link port in slave repeater mode?
	goto	RbRx1oh		; no, just hang, no ctsy tone.

RbRx1o1	
	;; receiver 2 courtesy tone
	movlw	CTRRBRX		; get eeprom address CT mask
	btfss	group3,2	; is rb tx enabled?
	goto	RbRx1oc		; no, set the tone & hang
	movlw	CTRRBTX		; yes, get that courtesy tone
	btfsc	group1,5	; is RB port a repeater?
	goto	RbRx1oc		; yes, set the tone & hang
	btfsc	txFlag,RX0OPEN	; is main receiver on bit set?
	goto	RbRx1oh		; yes, hang without a beep!

RbRx1oc
	movwf	cTone		; save the courtesy tone mask.

RbRx1oh
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now
	goto	ChkTmrs		; done here...

RbRx2				; receiver timedout state
	btfss	group0,0	; is repeater enabled?
	goto	RbRx2Off	; no.	turn off link receiver.
	movf	group3,w	; get group 3
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	RbRx2Off	; yes.	turn off link receiver.

	btfsc	rxFlag,RX1OPEN	; is squelch open?
	goto	ChkTmrs		; yes, still timed out
RbRx2Off	
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rx1Stat		; set new receiver state

	btfsc	group2,3	; is voice timeout message enabled?
	goto	RbRx2TO		; yes...
	PAGE1			; select code page 1.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkTmrs		; done here...

RbRx2TO
	movlw	CW_TO		; time out message
	PAGE1			; select code page 1.
	call	PlayCW		; play the message.
	PAGE0			; select code page 0.

ChkTmrs				; check timers here.

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
	
	;; select courtesy tone here.
HangCT
	incf	cTone,w		; check cTone for FF
	btfsc	STATUS,Z	; is result 0?
	goto	HangNob		; yes, cTone was FF.
	btfss 	group0,6	; is courtesy tone enabled?
	goto	HangNob		; courtesy tone disabled.

	movlw	CTUNLOK		; get unlocked mode courtesy tone.
	btfsc	dtRFlag,DT0UNLK	; is this port (main receiver) unlocked?
	movwf	cTone		; yep. set unlocked courtesy tone.

	PAGE1			; select code page 1.
	call	PlayCT		; play courtesy tone #w
	PAGE0			; select code page 0.

HangNob				; hanging without a beep
	decfsz	hangTmr,f	; decrement and check if now zero
	goto	NoHang		; not zero
	;; end of hang time.
	bcf	txFlag,TXHANG	; turn off hang time flag
NoHang				; done with hang timer...
	;; process DTMF muting timer...
	movf	muteTmr,f	; test mute timer
	btfsc	STATUS,Z	; Z is set if not DTMF muting
	goto	NoMutTm		; muteTmr is zero.
	decfsz	muteTmr,f	; decrement muteTmr
	goto	NoMutTm		; have not reached the end of the mute time
	btfsc	txFlag,RX0OPEN	; is receiver 0 unsquelched
	bcf	PORTA,MUTE	; unmute the receiver audio.

	btfss	txFlag,RX1OPEN	; is receiver 1 unsquelched
	goto	UnMutTx		; no.
	btfss	flags,RBMUTE	; is RB muted for some other reason?
	bcf	PORTB,RB_MUTE	; no, unmute RB.
UnMutTx
	btfss	flags,TXONFLG	; is the transmitter supposed to be on?
	goto    UMTx1		; no.
	btfsc	group4,6	; drop main receiver to mute enabled?
	bsf	PORTB,PTT	; turn on main receiver PTT!
UMTx1
	btfss	group3,7	; drop link to mute enabled?
	goto	NoMutTm		; no.
	btfss	group3,2	; link transmitter enabled?
	goto	NoMutTm		; nope.
	btfsc	txFlag,RX0OPEN	; is receiver 0 unsquelched
	bsf	PORTB,RB_PTT	; yes. turn on link PTT.
	
NoMutTm				; done with muting timer...
	btfss	flags,RBMUTE	; is the remote base muted for some reason?
	goto	NoRBMut		; nope.
	movf	txFlag,w	; get txFlag.
	andlw	b'11110001'	; any reason to keep muting?
	btfss	STATUS,Z	; skip if zero:	ok to unmute.
	goto	NoRBMut		; don't unmute yet.
	bcf	flags,RBMUTE	; clear the RBMUTE flag.
	btfsc	group3,1	; in receive mode?
	goto	RBUnMut		; yep.
	btfss	group3,2	; in transmit mode?
	goto	NoRBMut		; nope.
RBUnMut	
	btfsc	txFlag,RX1OPEN	; skip if the RB receiver is not active.
	bcf	PORTB,RB_MUTE	; unmute RB.
NoRBMut				; done with remote base muting checks.

Ck1S				; check 1-second flag bit.
	btfss	tFlags,ONESEC	; is one-second flag bit set?
	goto	Ck10S		; nope.
	;; 1-second tick active.
	movf	unlkTmr,f	; check unlkTmr
	btfsc	STATUS,Z	; is it zero?
	goto	NoULTmr		; yes, don't worry about it.
	decfsz	unlkTmr,f	; no, decrement it.
	goto	NoULTmr		; still not zero.
	;; unlkTmr counted down to zero, lock controller.
	movlw	b'00011111'	; mask:	 clear unlocked bits.
	andwf	dtRFlag,f	; and with dtRFlag: clear unlocked bits.

NoULTmr				; unlocked timer is zero.
	
Ck10S				; check 10-second tick flag bit.
	btfss	tFlags,TENSEC	; is ten-second flag bit set?
	goto	NoTimr		; nope.	no more timers to test.
	movf	idTmr,f
	btfsc	STATUS,Z	; is idTmr 0
	goto	NoIDTmr		; yes...
	decfsz	idTmr,f		; decrement ID timer
	goto	NoIDTmr		; not zero yet...
	call	DoID		; id timer decremented to zero, play the ID
NoIDTmr				; process more 10 second timers here...
	movf	fanTmr,f	; check fan timer
	btfsc	STATUS,Z	; is it zero?
	goto	NoFanTm		; yes.
	btfss	group2,4	; fan mode configured?
	goto	NoFanTm		; no
		decfsz	fanTmr,f	; decrement fan timer
	goto	NoFanTm		; not zero yet
	bcf	PORTB,FANCTL	; turn off fan
NoFanTm
	movf	dtATmr,f	; check DTMF access timer.
	btfsc	STATUS,Z	; is it zero?
	goto	NoDTATm		; yes
	decfsz	dtATmr,f	; decrement DTMF access timer
	goto	NoDTATm		; not zero yet.
	;; DTMF access mode timer has just timed out.
	movf	idTmr,f		; check for zero.
	btfsc	STATUS,Z	; is it zero?
	goto	NoDTATm		; yes.
	call	DoID		; send ID now.

NoDTATm
		
NoTimr				; no more timers to test.
	

ChkTx				; check if transmitter should be on
	movf	txFlag,f	; check txFlag
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkTx0		; it's zero, turn off transmitter
	;; txFlag is not zero

	btfsc	flags,TXONFLG	; skip if not already on
	goto	ChkTxE		; done here
	PAGE1			; select code page 1.
	call	PTT0On		; turn on transmitter (will set TXONFLG)
	PAGE0			; select code page 0.
	goto	ChkTxE		; now done here.
	
ChkTx0
	btfss	flags,TXONFLG	; skip if tx is on
	goto	ChkTxE		; was already off
	PAGE1			; select code page 1.
	call	PTT0Off		; turn off PTT
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

	movf	cwSpeed,w	; get cw timebase preset.
	movwf	cwTbTmr         ; preset CW timebase.

	decfsz	cwTmr,f		; decrement CW element timer
	goto	NoCW		; not zero

	btfss	tFlags,CWBEEP	; was "key" down? 
	goto	CWKeyUp		; nope
				; key was down
	bcf	tFlags,CWBEEP	; 
	; turn off beep here.
	clrw			; clear W.
	PAGE1			; select code page 1.
	call	SetTone		; set the beep tone up.
	PAGE0			; select code page 0.
	decf	cwByte,w	; test CW byte to see if 1
	btfsc	STATUS,Z	; was it 1 (Z set if cwByte == 1)
	goto	CWNext		; it was 1...
	movlw	CWIESP		; get cw inter-element space
	movwf	cwTmr		; preset cw timer
	goto	NoCW		; done with this pass...

CWNext				; get next character of message
	PAGE1			; select code page 1.
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
	movf	cwTone,w	; get CW tone
	;; turn on beep here.
	PAGE1			; select code page 1.
	call	SetTone		; set the beep tone up.
	PAGE0			; select code page 0.
	rrf	cwByte,f	; rotate cw bitmap
	bcf	cwByte,7	; clear the MSB
	goto	NoCW		; done with this pass...

CWDone				; done sending CW
	bcf	txFlag,CWPLAY	; turn off CW flag
CWDone1
	clrf	beepCtl	 ; clear beep control flags

NoCW
CasEnd
CkTone
	btfss	tFlags,HUNDMS	; check the DTMF timers every 100 msec.
	goto	TonDone	 ; not 100 MS tick.
CkDt0	
	movf	dt0Tmr,f	; check for zero...
	btfsc	STATUS,Z	; is it zero
	goto	TonDone		; yes
	decfsz	dt0Tmr,f	; decrement timer
	goto	TonDone		; not zero yet
	bsf	dtRFlag,DT0RDY	; ready to evaluate command.
TonDone
	;; manage beep timer 
	btfss	tFlags,TENMS	; is this a 10 ms tick?
	goto	NoTime		; nope.
	movf	beepTmr,f	; check beep timer
	btfsc	STATUS,Z	; is it zero?
	goto	NBeep		; yes.
	;goto	NoTime		; yes.
BeepTic			 ; a valid beep tick.
	decfsz	beepTmr,f	; decrement beepTmr
	goto	NoTime		; not zero yet.
	PAGE1			; select code page 1.
	call	GetBeep	 ; get the next beep tone...
	PAGE0			; select code page 0.
	goto	NoTime		; done here.
NBeep				; verify that beeping is really over. HACK.
	movf	cwTmr,f		; check cwTmr.
	btfss	STATUS,Z	; is it zero?
	goto	NoTime		; no.
	movf	beepCtl,f	; check this.
	btfsc	STATUS,Z	; is it zero?
	goto	NoTime		; yes.
	PAGE1			; select code page 1.
	call	GetBeep	 ; get the next beep tone...
	PAGE0			; select code page 0.

NoTime
	movf	tFlags,f	; evaluate tFlags
	btfss	STATUS,Z	; skip if ZERO
	goto	LoopEnd
	;; no timing flags were set...
	;; likely some excess, available CPU cycles here.
	;; evaluate DTMF buffers...
PfxDT0
	btfsc	dtRFlag,DTSEVAL	; is a command being interpreted now?
	goto	DTEval		; yes, don't try to evaluate another now.
	;; evaluate DTMF 0 buffer for command
	btfss	dtRFlag,DT0RDY	; is a command ready to evaluate?
	goto	XPfxDT		; no command waiting.
	;; copy command from dtmf rx buf to command interpreter input buffer.
	movlw	low dt0buf0	; get address of this dtmf receiver's buffer
	movwf	FSR		; store.
	movf	dt0Ptr,w	; get command size...
	movwf	cmdSize		; save it.
	call	CpyDTMF		; copy the command...
	movf	dt0Ptr,w	; get command size back, CpyDTMF clobbers.
	movwf	cmdSize		; save it.
	clrf	dt0Ptr		; make ready to receive again.
	clrf	dtEFlag		; start evaluating from first prefix.
	bsf	dtEFlag,DT0CMD	; command from DTMF-0.
	bsf	dtRFlag,DTSEVAL	; set evaluate DTMF bit.
	btfsc	dtRFlag,DT0UNLK	; port 0 unlocked?
	bsf	dtRFlag,DTUL	; this port is unlocked.
	bcf	dtRFlag,DT0RDY	; reset DTMF ready bit.
	goto	DTEval		; go and evaluate the command right now.

XPfxDT
	goto	LoopEnd
	
DTEval				; evaluate DTMF command in command buffer
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
	movf	temp,w		; get prefix index.
	movwf	eeAddr		; set EEPROM address low byte
	bcf	STATUS,C	; clear carry bit
	rlf	eeAddr,f	; rotate (x2)
	rlf	eeAddr,f	; rotate (x4 this time)
	rlf	eeAddr,f	; rotate (x8 now)
	movlw	EEPFB		; get EEPROM base address for prefix 0
	addwf	eeAddr,f	; add to offset.
	;; now have address of base of selected prefix.
DTEval1
	PAGE1			; select code page 1.
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
	incf	eeAddr,f	; move to the next EEPROM byte.
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
	PAGE1			; select code page 2.
	call	UlCmd		; evaluate the unlocked command.
	PAGE0			; select code page 0.
	goto	DTEdone		; done evaluating.

DTEdone				; done evaluating DTMF commands.
	clrf	dtEFlag		; yes.	reset evaluate DTMF flags.
	bcf	dtRFlag,DTSEVAL	; done evaluating.
	bcf	dtRFlag,DTUL	; so we don't care about unlocked anymore.
	
LoopEnd
	;; always update the output latch here.
	;; maybe add logic later to only update it when different.

FanCtl
	;; fan/control output control.
	btfsc	group2,4	; is fan control enabled?
	goto	LoopE1		; yes.
	btfsc	group2,5	; is digital output on?
	bsf	PORTB,FANCTL	; yes, turn on control output.
	btfss	group2,5	; is digital output off?
	bcf	PORTB,FANCTL	; yes, turn off control output.
LoopE1
	goto	Loop0

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
; ****************************** ROM PAGE 1 ******************************
; ************************************************************************
	org	h'0800'		; page 1

LCmd
	movlw	high LTable	; set high byte of address
	movwf	PCLATH		; select page
	movf	temp,w		; get prefix index number.
	andlw	h'07'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL

LTable				; jump table for locked commands.
	goto	LCmd0		; prefix 00 -- control operator
	goto	LCmd1		; prefix 01 -- DTMF access
	goto	LCmd2		; prefix 02 -- digital output control
	goto	LCmd3		; prefix 03 -- load saved setup
	goto	LCmd4		; prefix 04 -- remote base
	goto	LCmd5		; prefix 05 -- unlock controller
	goto	LCmd6		; prefix 06 -- not supported
	goto	LCmd7		; prefix 07 -- not supported

; ***********
; ** LCmd0 **
; ***********
LCmd0				; control operator switches
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
	call	GetMask		; get bitmask for that group.
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
	PAGE1			; select code page 2.
	goto	CtlOpC		; execute control op command

; ***********
; ** LCmd1 **
; ***********
LCmd1				; DTMF access mode
	btfss	group0,5	; check to see if DTMF access mode is enabled.
	return			; it's not.
	decfsz	cmdSize,w	; check for one command digit.
	return			; not one command digit.
	movf	INDF,f		; get command digit.
	btfsc	STATUS,Z	; is it zero?
	goto	LCmd10		; yes.
	decfsz	INDF,w		; check for one.
	return			; it's not one.

	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddr		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	dtATmr		; set DTMF access mode timer.
	goto	LCmdOK

LCmd10				; turn off DTMF access mode.
	movf	dtATmr,f	; check for zero.
	btfsc	STATUS,Z	; is it zero.
	return			; it is zero, do nothing.
	clrf	dtATmr		; make it zero.

	movf	idTmr,f		; check for zero.
	btfsc	STATUS,Z	; is it zero?
	return			; yes
	PAGE0			; select code page 0
	call	DoID		; send ID now.
	PAGE1			; select code page 1
	return

; ***********
; ** LCmd2 **
; ***********
LCmd2				; digital output control
	btfsc	group2,4	; is digital output enabled?
	goto	LCmdErr		; no. fan control is.  error.
	movlw	d'2'		; group 2.
	movwf	temp2		; save group byte.
	movlw	d'5'		; item 5.
	movwf	temp		; save item byte.
	goto	CtlOpC		; execute control op command

; ***********
; ** LCmd3 **
; ***********
LCmd3				; load saved state.
	decfsz	cmdSize,w	; is this 1?
	return			; nope.
	movf	INDF,w		; get command digit.
	sublw	d'1'		; subtract 1
	btfss	STATUS,C	; was result negative?
	return			; yes.
	movf	INDF,w		; get command digit.
	call	LoadCtl		; load control op settings.
	goto	LCmdOK
	
; ***********
; ** LCmd4 **
; ***********
LCmd4				; remote base control
	movf	cmdSize,f	; check cmdSize
	btfsc	STATUS,Z	; skip if not zero
	return			; no more digits.	Ignore.
	movf	INDF,w		; get command digit.
	movwf	temp2		; save command digit.
	decf	cmdSize,f	; decrement cmdSize.
	incf	FSR,f		; move pointer.
	;; valid command digits:
	;;		0 -- link off.
	;;		1 -- link alert mode.
	;;		2 -- link receive mode.
	;;		3 -- link transmit mode.
	movf	temp2,f		; check.
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmd40		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmd41		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmd42		; yes.
	decf	temp2,f		; decrement command digit
	btfsc	STATUS,Z	; is it zero now.
	goto	LCmd43		; yes.
	return			; was greater than 3
LCmd40				; link off
	bcf	group3,0	; clear alert bit
	bcf	group3,1	; clear receive bit
	bcf	group3,2	; clear transmit bit

	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bsf	PORTB,RB_MUTE	; mute RB.
	bcf	txFlag,RX1OPEN	; clear main receiver on bit
	clrf	rx1TOut		; clear main receiver timeout timer
	call	PTT1Off		; turn off TX1

	goto	LCmdOK

LCmd41				; link alert mode.
	bsf	group3,0	; set alert bit
	bcf	group3,1	; clear receive bit
	bcf	group3,2	; clear transmit bit
	
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bsf	PORTB,RB_MUTE	; mute RB.
	bcf	txFlag,RX1OPEN	; clear main receiver on bit
	clrf	rx1TOut		; clear main receiver timeout timer
	goto	LCmdOK
	
LCmd42				; link receive mode.
	bcf	group3,0	; clear alert bit
	bsf	group3,1	; set receive bit
	bcf	group3,2	; clear transmit bit
	goto	LCmdOK
	
LCmd43				; link transmit mode
	bcf	group3,0	; clear alert bit
	bcf	group3,1	; clear receive bit
	bsf	group3,2	; set transmit bit
	btfsc	group1,5	; is port 2 a repeater?
	call	PTT1On		; turn on TX1 PTT.
	goto	LCmdOK

; ***********
; ** LCmd5 **
; ***********
LCmd5				; unlock this port.
	movf	dtEFlag,w	; get eval flags
	andlw	b'11100000'	; mask all except command source indicators.
	iorwf	dtRFlag,f	; IOR with dtRFlag: set unlocked bit.
	movlw	UNLKDLY		; get unlocked mode timer.
	movwf	unlkTmr		; set unlocked mode timer.
	movlw	CTUNLOK		; get unlocked mode courtesy tone.
	movwf	cTone		; yep. set unlocked courtesy tone.
	goto	LCmdOK		; send OK.

; ***********
; ** LCmd6 **
; ***********
LCmd6				; not implemented
	goto	LCmdErr		; not there.

; ***********
; ** LCmd7 **
; ***********
LCmd7				; not implemented
	goto	LCmdErr		; not there.

; *************
; ** LCmdErr **
; *************
LCmdErr
	movlw	CW_NG 		; get CW OK
	call	PlayCW		; start playback
	return

; ************
; ** LCmdOK **
; ************
LCmdOK
	movlw	CW_OK		; get CW OK
	call	PlayCW		; start playback
	return

	org	h'0900'		; still in page 1
	
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
	movlw	CTNONE		; select no courtesy tone.
	movwf	cTone		; set courtesy tone.
	goto	UlCmdOK		; play OK message.
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
	goto	UlCmdD 		; command *d -- invalid command
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
	goto	UlCmdNG		; not enough command digits.
	movf	cmdSize,w	; get command size
	sublw	d'3'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 3)
	goto	UlCmdNG		; too many command digits.

	movf	INDF,w		; get Group byte
	movwf	temp2		; save group byte.
	sublw	d'9'		; w = 9-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlCmdNG		; bad, bad user tried to enter invalid group.
	incf	FSR,f		; move to next byte (bit #)
	decf	cmdSize,f	; decrement command size.
	movf	INDF,w		; get Item byte (bit #)
	movwf	temp		; save it.
	incf	FSR,f		; move to next byte (state)
	decf	cmdSize,f	; decrement command size.

	sublw	d'7'		; w = 7-w.
	btfss	STATUS,C	; skip if w is not negative
	goto	UlCmdNG		; bad, bad user tried to enter invalid item.

CtlOpC
	movf	temp,w		; get Item byte
	call	GetMask		; get bit mask for selected item
	movwf	temp		; save mask

	movf	cmdSize,f	; test this for zero (inquiry)
	btfsc	STATUS,Z	; skip if not 0.
	goto	UlCmd0I		; it's an inquiry.
	
	movf	INDF,w		; get state byte
	andlw	b'11111110'	; only 0 and 1 permitted.
	btfss	STATUS,Z	; should be zero of 0 or 1 entered
	goto	UlCmdNG		; not zero, bad command.
	movf	INDF,f		; get state byte
	btfss	STATUS,Z	; skip if state is zero
	goto	UlCmd01		; not zero, must be 1, go do the set.
	;; clear a bit.
	movlw	low group0	; get address of 1st group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	xorlw	h'ff'		; invert mask to clear selected bit
	andwf	INDF,f		; apply inverted mask
	bsf	STATUS,IRP	; set indirect pointer into page 1

	movlw	CW_OFF		; get CW OFF message
	call	PlayCW		; send the announcement.
	return			; done.

UlCmd01				; set a bit.
	movlw	low group0	; get address of ist group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	iorwf	INDF,f		; or byte with mask.
	bsf	STATUS,IRP	; set indirect pointer into page 1
			
	movlw	CW_ON		; get CW ON message.
	call	PlayCW		; send the announcement.
	return			; no.

UlCmd0I				; inquiry mode.
	movlw	low group0	; get address of ist group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	andwf	INDF,w		; and the mask (in temp) with the field.
	bsf	STATUS,IRP	; set indirect pointer into page 1

	movlw	CW_ON		; get CW ON message.
	btfsc	STATUS,Z	; was result (from and) zero?
	movlw	CW_OFF		; get CW OFF message.
	call	PlayCW		; send the announcement.
	return			; done.
	
		
; ************
; ** UlCmd1 **
; ************
	;; save control operator Group/Item/States to a specified setup.
UlCmd1				; save setups
	btfsc	group8,0	; are control groups write protected?
	goto	UlCmdNG		; yes.
	movf	cmdSize,w	; get command size
	sublw	d'1'		; subtract expected size
	btfss	STATUS,Z	; was it the expected size?
	goto	UlCmdNG		; nope.
	movf	INDF,w		; get setup number
	sublw	d'1'		; subtract largest expected
	btfss	STATUS,C	; is result not negative?
	goto	UlCmdNG		; nope.
	movlw	EE0B		; get low part of address
	movwf	eeAddr		; save low part of address
	swapf	INDF,w		; magic! get command * 16
	addwf	eeAddr,f	; now have ee address for saved state.
	movlw	EESSC		; get the number of bytes to save
	movwf	eeCount		; set the number of bytes to write.
	movlw	group0		; get address of first group
	movwf	FSR		; set pointer
	bcf	STATUS,IRP	; to page 0.
	call	WriteEE		; save this stuff.
	bsf	STATUS,IRP	; back to page 1.
	goto	UlCmdOK		; OK.
	
; ************
; ** UlCmd2 **
; ************
	;; set command prefixes...	
UlCmd2				; program prefixes
	btfsc	group8,1	; are prefixes write protected?
	goto	UlCmdNG		; yes.
	movlw	d'3'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	UlCmdNG		; not enough command digits.
	movf	cmdSize,w	; get command size
	sublw	d'9'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 9)
	goto	UlCmdNG		; too many command digits.

	call	GetTens		; get index tens digit.
	movwf	temp		; save to prefix index in temp.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	INDF,w		; get index ones digit.
	addwf	temp,f		; add to prefix index in temp.
	movf	temp,w		; get prefix index
	sublw	MAXPFX		; w = MAXPFX - pfxnum
	btfss	STATUS,C	; skip if result is non-negative (pfxnum <= MAXPFX)
	goto	UlCmdNG		; argument error
	decf	cmdSize,f	; less bytes to process
	incf	FSR,f		; point at next byte.

	movf	temp,w		; get index back.
	sublw	MAXPFX		; subtract index of unlock command.
	btfss	STATUS,Z	; is result zero?
	goto	UlCmd2P		; no.

	bsf	STATUS,RP0	; select register page 1
	movlw	b'00011111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select register page 0

	nop			; time to settle down.
	btfsc	PORTA,INIT	; skip if init button pressed.
	goto	UlCmd2B		; bad command.
	goto	UlCmd2C		; init pressed.
	
UlCmd2B				; 
	bsf	STATUS,RP0	; select register page 1
	movlw	b'00001111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select register page 0
	goto	UlCmdNG		; bad command.
		
UlCmd2C				; this is ugly. sorry.
	bsf	STATUS,RP0	; select register page 1
	movlw	b'00001111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select register page 0

UlCmd2P				; program the new prefix.
	movf	cmdSize,w	; get command length
	movwf	eeCount		; save # bytes to write.
	incf	eeCount,f	; add 1 so FF at end of buffer gets copied.
	movlw	low EEPFB	; get low address of prefixes
	movwf	eeAddr		; set eeprom address to base of prefixes
	bcf	STATUS,C	; clear carry
	rlf	temp,f		; multiply prefix by 2
	rlf	temp,f		; multiply prefix by 2 (x4 after)
	rlf	temp,f		; multiply prefix by 2 (x8 after)
	movf	temp,w		; get prefix offset
	addwf	eeAddr,f	; add prefix to base
	call	WriteEE		; write the prefix.
	goto	UlCmdOK		; good command...
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	*3								;
;	Set Timers							;
;	*3<nn> inquire timer nn						;
;	*3<nn><time> set timer nn to time				;
;	00 <= nn <= 11	timer index					;
;	0 <= time <= 255 timer preset. 0=disable			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UlCmd3				; program timers
	movlw	d'2'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 2)
	goto	UlCmdNG		; not enough command digits.

	call	GetTens		; get timer index tens digit.
	movwf	temp2		; save
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	INDF,w		; get timer index ones digit
	addwf	temp2,f		; add to timer index
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	temp2,w		; get timer index sum
	sublw	LASTTMR		; subtract last timer index
	btfss	STATUS,C	; skip if result is non-negative
	goto	UlCmdNG		; argument error
	movf	temp2,w		; get timer index
	movwf	eeAddr		; set EEPROM address low byte
	movf	cmdSize,f	; check for no more digits.
	btfsc	STATUS,Z	; skip if not zero.
	goto	UlCmdNG		; no more digits -- bad command.
	;; ready to get value then set timer.
	btfsc	group8,2	; are timers write protected?
	goto	UlCmdNG		; yes.
	call	GetDNum		; get decimal number to w. nukes temp3,temp4
	movwf	temp4		; save decimal number to temp4.
	call	WriteEw		; write w into EEPROM.
	call	CWParms		; set CW parameters.
UlCmd3a
	goto	UlCmdOK		; good command.
	
UlCmd4				; reserved
	goto	UlCmdNG		; bad command...
	
UlCmd5				; reserved
	goto	UlCmdNG		; bad command...

UlCmd6				; reserved
	goto	UlCmdNG		; bad command...

; ********************************************************************************
; **	*7									**
; **	Record/Play CW and Courtesy Tones					**
; **	*70 play CW ID								**
; **	*70 <dd..dd..dd..> program cw message n with CW data in dd.dd.dd	**
; **			see CW encoding table.					**
; **										**
; **	*71<n> play courtesy tone n, 0 <= n <= 7 (n is in range 0 to 7)		**
; **	*71<n><ddtt,ddtt...> record courtesy tone n, 0 <= n <= 7		**
; **		dd is duration in 10 ms increments. 01 <= dd <=99		**
; **		tt is tone.	See tone table.	00 <= tt <= 63			**
; ********************************************************************************
UlCmd7
	movf	cmdSize,f	; check command size.
	btfsc	STATUS,Z	; is it zero?
	goto	UlCmdNG		; not enough command digits.
	movf	INDF,f		; check command digit for zero.
	btfsc	STATUS,Z	; is it zero?
	goto	UlCmd70		; yes.
	decfsz	INDF,w		; decrement and test.
	goto	UlCmdNG		; was not 1 either.
UlCmd71				; Courtesy Tone Command.
	incf	FSR,f		; move to next byte.
	decf	cmdSize,f	; decrement commandSize.
	btfsc	STATUS,Z	; is result zero?
	goto	UlCmdNG		; yes. insufficient command digits.
	movf	INDF,w		; get command digit.
	movwf	temp2		; save index.
	sublw	d'7'		; subtract biggest argument.
	btfss	STATUS,C	; is result non-negative?
	goto	UlCmdNG		; nope. bad command digit.
	incf	FSR,f		; move to next byte.
	decf	cmdSize,f	; decrement commandSize.
	btfss	STATUS,Z	; is result zero?
	goto	UC71R		; record CT.
UC71P				; play courtesy tone.
	movf	temp2,w		; get index.
	movwf	cTone		; save CT index.
	call	PlayCT		; play courtesy tone #w
	return			; done.

UC71R				; record courtesy tone.
	btfsc	group8,6	; are courtesy tones write protected?
	goto	UlCmdNG		; yes.
	movlw	low EECTB	; get EEPROM ctsy tone table base address
	movwf	eeAddr		; move into EEPROM address low byte
	bcf	STATUS,C	; clear carry bit.
	rlf	temp2,f		; multiply msg # by 2
	rlf	temp2,f		; multiply msg # by 2 (x4 after)
	rlf	temp2,w		; multiply msg # by 2 (x8 after)
	addwf	eeAddr,f	; add offset of ctsy tone to ctsy base addr.
	;; now have eeprom address of CT.
	movlw	b'00000011'	; mask:	 low 2 bits.
	andwf	cmdSize,w	; check for multiple of 4 only.
	btfss	STATUS,Z	; is result zero?
	goto	UlCmdNG		; bad command argument.
	movf	cmdSize,w	; get command size.
	sublw	d'16'		; 16 is 8 pairs or 4 tones.
	btfss	STATUS,C	; check for non-negative.
	goto	UlCmdNG		; too many command digits.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	eebPtr		; set eeprom buffer put pointer
	clrf	eeCount		; clear count.
UC71RL	
	call	GetCTen		; get 2-digit argument.
	call	PutEEB		; put into EEPROM write buffer.
	call	GetCTen		; get 2-digit argument.
	movwf	temp		; save it.
	movf	cmdSize,f	; test command size.
	btfss	STATUS,Z	; any digits left?
	bsf	temp,7		; yes, set high bit of tone.
	movf	temp,w		; get temp back
	call	PutEEB		; put into EEPROM write buffer.
	movf	cmdSize,f	; test command size.
	btfss	STATUS,Z	; any digits left?
	goto	UC71RL		; yes. loop around and get the next 4.
	;; now have whole segment in buffer.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	FSR		; set address to write into EEPROM.
	call	WriteEE
	goto	UlCmdOK		; OK.

UlCmd70
	incf	FSR,f		; move to next byte.
	decfsz	cmdSize,f	; decrement commandSize.
	goto	UC70R		; record CW ID.
 	movlw	EECWID		; address of CW ID message in EEPROM.
	movwf	eeAddr		; save CT base address
	call	PlayCWe		; kick off the CW playback.
	return
UC70R				; record CW ID.
	btfsc	group8,6	; are CWID/courtesy tones write protected?
	goto	UlCmdNG		; yes.
	btfsc	cmdSize,0	; bit 0 should be clear for an even length.
	goto	UlCmdNG		; bad command argument.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	eebPtr		; set eeprom buffer put pointer
	clrf	eeCount		; clear count.
UC70RL	
	call	GetCTen		; get 2-digit argument.
	call	GetCW		; get CW code.
	call	PutEEB		; put into EEPROM write buffer.
	movf	cmdSize,f	; test cmdSize
	btfss	STATUS,Z	; skip if it's zero.
	goto	UC70RL		; loop around.
	
	movlw	h'ff'		; mark EOM.
	call	PutEEB		; put into EEPROM write buffer.
	movlw	EECWID		; get CW ID address...
	movwf	eeAddr		; set EEPROM address...
	movlw	low eebuf00	; get address of eebuffer.
	movwf	FSR		; set address to write into EEPROM.
	call	WriteEE
	goto	UlCmdOK		; OK.
	
UlCmd8				; not implemented.
UlCmd9				; reserved.
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
	movlw	CW_OK		; get CW OK message.
	goto	UlErr		; finish message.

UlCmdNG				; "BAD COMMAND"
	movlw	CW_NG		; get NG message.

UlErr
	call	PlayCW		; play CW
	return			; done with all this.

	org	h'0b00'		; still page 1
		
; ************
; ** PlayCW **
; ************
	;; play CW from ROM table.	Address in W.
PlayCW
	movwf	temp		; save CW address.
	;movf	beepCtl,w	; get beep control flag.
	;btfss	STATUS,Z	; result will be zero if no.
	;call	KillBeep	; kill off beep sequence in progress.
	movf	temp,w		; get back CW address.
	movwf	beepAddr	; set CW address.
	movlw	CW_ROM		; CW from the ROM table
	movwf	beepCtl		; set control flags.
	call	GtBeep		; get next character.
	movwf	cwByte		; save byte in CW bitmap
	movlw	CWIWSP		; get startup delay
	movwf	cwTmr		; preset cw timer
	bcf	tFlags,CWBEEP	; make sure that beep is off
	bsf	txFlag,CWPLAY	; turn on CW sender
	call	PTT0On		; turn on PTT...
	return

; ************
; ** PlayCWe**
; ************
	;; play CW from EEPROM addresses named by eeAddr
PlayCWe
	movf	beepCtl,w	; get beep control flag.
	andlw	b'00011100'	; is the beeper already busy?
	btfss	STATUS,Z	; result will be zero if no.
	call	KillBeep	; kill off beep sequence in progress.
	movf	eeAddr,w	; get lo byte of address.
	movwf	beepAddr	; set lo byte of address of beep.
	movlw	CW_EE		; select CW from EEPROM
	movwf	beepCtl		; set control flags.
	call	GtBeep		; get next character.
	movwf	cwByte		; save byte in CW bitmap
	movlw	CWIWSP		; get startup delay
	movwf	cwTmr		; preset cw timer
	bcf	tFlags,CWBEEP	; make sure that beep is off
	bsf	txFlag,CWPLAY	; turn on CW sender
	call	PTT0On		; turn on PTT...
	return

; ************
; ** PlayCWL**
; ************
	;; play single CW letter, code in w.
PlayCWL
	movwf	temp		; save letter.
	movf	beepCtl,w	; get beep control flag.
	andlw	b'00011100'	; is the beeper already busy?
	btfss	STATUS,Z	; result will be zero if no.
	call	KillBeep	; kill off beep sequence in progress.
	movf	eeAddr,w	; get lo byte of address.
	movwf	beepAddr	; set lo byte of address of beep.
	movlw	CW_LETR		; select CW single letter mode.
	movwf	beepCtl		; set control flags.
	movf	temp,w		; get letter back.
	call	GetCW		; get CW bitmap.
	movwf	cwByte		; save byte in CW bitmap
	movlw	CWIWSP		; get startup delay
	movwf	cwTmr		; preset cw timer
	bcf	tFlags,CWBEEP	; make sure that beep is off
	bsf	txFlag,CWPLAY	; turn on CW sender
	call	PTT0On		; turn on PTT...
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
	movwf	beepAddr	; set beep address lo byte.
	movlw	BEEP_CX		; CT beep. (from table)
	movwf	beepCtl		; set control flags.
	movlw	CTPAUSE		; initial delay.
	movwf	beepTmr		; set initial start
	bsf	txFlag,BEEPING	; beeping is enabled!
	call	PTT0On		; turn on PTT...
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
	movlw	EECTB		; get CT base.
	movwf	beepAddr	; save CT base address.

	movf	cTone,w		; examine cTone.
	andlw	h'07'		; force into reasonable range.
	movwf	temp		; copy to temp.
	bcf	STATUS,C	; clear carry bit.
	rlf	temp,f		; multiply msg # by 2
	rlf	temp,f		; multiply msg # by 2 (x4 after)
	rlf	temp,w		; multiply msg # by 2 (x8 after)
	addwf	beepAddr,f	; add offset of ctsy tone to beep base addr.
	;; now have EEPROM address of CT. reset courtesy tone indicator.
	movlw	CTNONE		; get no CT indicator.
	movwf	cTone		; save it.
	movf	beepAddr,w	; get low byte of EEPROM address.
	movwf	eeAddr		; set low byte of EEPROM address.

	call	ReadEEw		; read 1 byte from EEPROM.
	movwf	temp		; save eeprom data.
	xorlw	MAGICCT		; xor with magic CT number.
	btfss	STATUS,Z	; skip if result is zero (MAGIG number used)
	goto	PlayCT1		; play normal CT segment.

	;; this is where the morse digit send goes.
	incf	eeAddr,f	; move to next byte of CT.
	call	ReadEEw		; read 1 byte from EEPROM.
	goto	PlayCWL		; play the CW letter
	
PlayCT1
	movlw	BEEP_CT		; CT beep.
	movwf	beepCtl		; set control flags.
	movlw	CTPAUSE		; initial delay.
	movwf	beepTmr		; set initial start
	bsf	txFlag,BEEPING	; beeping is enabled!
	return			; done.

; ************** 
; ** KillBeep **
; ************** 
	;; kill off whatever is beeping now.
KillBeep
	clrf	beepTmr		; clear beep timer
	clrf	beepCtl		; clear beep control flags
	clrw			; select no tone.
	call	SetTone		; set the beep tone up.
	return
	
; *************
; ** GetBeep **
; *************
	;; get the next beep tone from whereever.
	;; select the tone, etc.
	;; uses temp.
GetBeep				; get the next beep character
	btfsc	beepCtl,B_LAST	; was the last segment just sent?
	goto	BeepDone	; yes.	stop beeping.
	call	GtBeep		; get length byte
	movwf	beepTmr		; save length
	call	GtBeep		; get tone byte
	movwf	temp		; save tone byte
	btfss	temp,7		; is the continue bit set?
	bsf	beepCtl,B_LAST	; no. mark this segment last.
	movlw	b'00111111'	; mask
	andwf	temp,f		; mask out control bits.
	goto	SetBeep		; set the beep tone

BeepDone			; stop that confounded beeping...
	clrf	temp		; set quiet beep
	bcf	txFlag,BEEPING	; beeping is done...
	clrf	beepCtl		; clear beep control flags
	clrf	beepTmr		; clear beep timer

SetBeep
	movf	temp,w		; get beep tone.
	call	SetTone		; set the beep tone up.
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
	goto	GtBLETR		; get beep for single CW letter.
	
GtBEE				; get beep char from EEPROM
	movf	beepAddr,w	; get lo byte of EEPROM address
	movwf	eeAddr		; store to EEPROM address lo byte
	incf	beepAddr,f	; increment pointer
	call	ReadEEw		; read 1 byte from EEPROM
	return			;
GtBROM				; get beep char from ROM table
	movf	beepAddr,w	; get address low byte (hi is not used here)
	incf	beepAddr,f	; increment pointer
	call	MesgTabl	; get char from table
	return			;
GtBRAM				; get beep char from RAM
	movf	beepAddr,w	; get address low byte (hi is not used here)
	movwf	FSR		; set indirect register pointer
	incf	beepAddr,f	; increment pointer
	movf	INDF,w		; get data byte from RAM
	return			; 

GtBLETR				; get single CW letter.
	retlw	h'ff'		; return ff.

; ************
; ** PTT0On **
; ************
	;; turn on PTT & set up ID timer, etc., if needed.
PTT0On				; key the transmitter
	btfsc	flags,TXONFLG	; is transmitter already on?
	return			; yep.

	;; transmitter was not already on. turn it on.
	bsf	PORTB,PTT	; apply PTT!
	;; set the remote base transmitter on if enabled and is a repeater.
	btfss	group3,2	; is port 2 tx enabled?
	goto	PTTOn1		; nope.
	btfss	group1,5	; is port 2 a repeater?
	goto	PTTOn1		; nope.
	call	PTT1On		; turn on TX1 PTT
PTTOn1				; 
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
	movlw	EETID		; get address of ID timer
	movwf	eeAddr		; set address of ID timer
	call	ReadEEw		; get byte from EEPROM
	movwf	idTmr		; store to down-counter
FanOn
	btfss	group2,4	; is fan control enabled?
	return			; no.
	clrf	fanTmr		; disable fan timer, fan stays on.
	bsf	PORTB,FANCTL	; turn on fan
	return			; done here

; *************
; ** PTT0Off **
; *************
PTT0Off
	bcf	PORTB,PTT	; turn off main PTT!
	bcf	flags,TXONFLG	; clear last tx state flag
	call	PTT1Off		; turn off TX1.
	btfss	group2,4	; is fan control enabled?
	return			; no.
	movlw	EETFAN		; get EEPROM address of ID timer preset.
	movwf	eeAddr		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	fanTmr		; set fan timer
	btfsc	STATUS,Z	; is fan timer zero?
	bcf	PORTB,FANCTL	; yes, turn off fan now.
	return

; ************
; ** PTT1On **
; ************
PTT1On
	bsf	PORTB,RB_PTT	; turn on TX1 PTT.
	return
	
; *************
; ** PTT1Off **
; *************
PTT1Off
	bcf	PORTB,RB_PTT	; turn off TX1 PTT.
	return

; ************
; ** ReadEE **
; ************
	;; read eeCount bytes from the EEPROM 
	;; starting at location in eeAddr.
	;; starting at FSR.
ReadEE				; read EEPROM.
	movf	eeCount,f	; check this for zero
	btfsc	STATUS,Z	; is it zero?
	return			; yes, do nothing here!
ReadEEd
	call	ReadEEw		; read EEPROM.
	movwf	INDF		; save read byte.
	incf	eeAddr,f	; increment EEPROM address.
	incf	FSR,f		; increment memory address.
	decfsz	eeCount,f	; decrement count of bytes to read.
	goto	ReadEEd		; loop around and read another byte.
	return			; read the requested bytes, return

; *************
; ** ReadEEw **
; *************
	;; read 1 bytes from the EEPROM 
	;; from location in eeAddr into W
ReadEEw				; read EEPROM.
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	ReadEEw		; no,	try again.
	movf	eeAddr,w	; get eeprom address.
	bsf	STATUS,RP0	; select register page.
	movwf	EEADR		; write EEADR.
	bsf	EECON1,RD	; read EEPROM.
	movf	EEDATA,w	; get EEPROM data.
	bcf	STATUS,RP0	; select register page.
	bsf	INTCON,GIE	; enable interrupts
	return			; read the requested bytes, return

; *************
; ** WriteEE **
; *************
	;; write eeCount bytes to the EEPROM 
	;; starting at location in eeAddr from location
	;; starting at FSR.
	;; cannot write more than 32 bytes.	cannot cross 32 byte paragraphs.
WriteEE				; write EEPROM.
	movf	eeCount,f	; check this for zero
	btfsc	STATUS,Z	; is it zero?
	return			; yes, do nothing here!

WrEELp	
	movf	INDF,w		; get data byte to write.
	call	WriteEw		; write the byte.
	incf	FSR,f		; increment RAM address in FSR.
	incf	eeAddr,f	; increment EEPROM address.
	decfsz	eeCount,f	; decrement count of bytes to write, test for 0
	goto	WrEELp		; not zero, keep looping.
	return			; wrote the requested bytes, done, so return

; *************
; ** WriteEw **
; *************
	;; write 1 byte from w into the EEPROM 
	;; at location in eeAddr
	;; stomps on temp3.
WriteEw				; write EEPROM.
	bsf	STATUS,RP0	; select register page 1.
	movwf	EEDATA		; set address.
	bcf	STATUS,RP0	; select register page 0.
WritEd
	bcf	INTCON,T0IE	; disable timer 0 interrupts
	btfsc	INTCON,T0IE	; timer 0 interrupts successfully disabled?
	goto	WritEd		; nope.	Try again.
	bcf	PIR1,EEIF	; from ERRATA: clear EE write complete flag.
	movf	eeAddr,w	; get address.
	bsf	STATUS,RP0	; select register page.
	movwf	EEADR		; set address.
	bcf	PIE1,CCP1IE	; for ERRATA: disable on CCP1 interrupt.
	bsf	PIE1,EEIE	; from ERRATA: set EEIE bit.
	bsf	EECON1,WREN	; enable writes.
	movlw	h'55'		; magic value.
	movwf	EECON2		; write magic value.
	movlw	h'AA'		; magic value.
	movwf	EECON2		; write magic value.
	bsf	EECON1,WR	; start write cycle.
	sleep			; from ERRATA: sleep until EE write complete.
	clrwdt			; clear watchdog.
	bsf	EECON1,WREN	; disable writes.
	bsf	PIE1,CCP1IE	; for ERRATA: enable CCP1 interrupt.
	bcf	PIE1,EEIE	; from ERRATA: clear EEIE bit.
	bcf	STATUS,RP0	; select register page.
	bsf	INTCON,T0IE	; enable Timer 0 interrupts
	return			; wrote the requested bytes, done, so return

; ************************************************
; ** Load control operator settings from EEPROM **
; ************************************************
LoadCtl				; load the control operator saved groups
				; from "macro" set contained in w.
	movwf	temp		; save group number
	btfss	STATUS,Z	; is it zero?
	goto	LoadCtl1	; no
	movlw	EE0B		; yes, get address of set zero.
	movwf	eeAddr		; save address
	goto	LoadCtlX	; now load the control op data.
LoadCtl1			; load set 1
	movlw	EE1B		; yes, get address of set one.
	movwf	eeAddr		; save address
LoadCtlX			; now actually load the data to RAM.
	movlw	EESSC		; get the number of bytes to read.
	movwf	eeCount		; set the number of bytes to read.
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
	;; there can be 1, 2, or 3 bytes.	The bytes will always be
	;; terminated by FF.	return result in w.
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

GetCTen
	call	GetTens		; get tens digit.
	movwf	temp6 		; save
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

; **************
; ** GetToneL **
; **************
	;; get high byte for compare for tone.
	;; tone 1f is NO tone (off).
GetToneL			; get tone hi byte from table
	movlw	high TnTblL	; set page 
	movwf	PCLATH		; select page
	movf	temp,w		; get tone into w
	andlw	h'1f'		; force into valid range
	addwf	PCL,f		; add w to PCL
TnTblL
	retlw	h'ff'		; OFF -- 00
	retlw	h'01'		; F4  -- 01
	retlw	h'b9'		; F#4 -- 02
	retlw	h'75'		; G4  -- 03
	retlw	h'35'		; G#4 -- 04
	retlw	h'f8'		; A4  -- 05
	retlw	h'bf'		; A#4 -- 06
	retlw	h'89'		; B4  -- 07
	retlw	h'57'		; C5  -- 08
	retlw	h'27'		; C#5 -- 09
	retlw	h'f9'		; D5  -- 0a
	retlw	h'ce'		; D#5 -- 0b
	retlw	h'a6'		; E5  -- 0c
	retlw	h'80'		; F5  -- 0d
	retlw	h'5c'		; F#5 -- 0e
	retlw	h'3a'		; G5  -- 0f
	retlw	h'1a'		; G#5 -- 10
	retlw	h'fc'		; A5  -- 11
	retlw	h'df'		; A#  -- 12
	retlw	h'c4'		; B5  -- 13
	retlw	h'ab'		; C6  -- 14
	retlw	h'93'		; C#6 -- 15
	retlw	h'7c'		; D6  -- 16
	retlw	h'67'		; D#6 -- 17
	retlw	h'53'		; E6  -- 18
	retlw	h'40'		; F6  -- 19
	retlw	h'2e'		; F#6 -- 1a
	retlw	h'1d'		; G6  -- 1b
	retlw	h'0d'		; G#6 -- 1c
	retlw	h'fe'		; A6  -- 1d
	retlw	h'ef'		; A#6 -- 1e
	retlw	h'e2'		; B6  -- 1f

; **************
; ** GetToneH **
; **************
	;; get high byte for compare for tone.
	;; tone 1f is NO tone (off).
GetToneH			; get tone hi byte from table
	movlw	high TnTblH	; set page 
	movwf	PCLATH		; select page
	movf	temp,w		; get tone into w
	andlw	h'1f'		; force into valid range
	addwf	PCL,f		; add w to PCL
TnTblH
	retlw	h'ff'		; OFF -- 00
	retlw	h'05'		; F4  -- 01
	retlw	h'04'		; F#4 -- 02
	retlw	h'04'		; G4  -- 03
	retlw	h'04'		; G#4 -- 04
	retlw	h'03'		; A4  -- 05
	retlw	h'03'		; A#4 -- 06
	retlw	h'03'		; B4  -- 07
	retlw	h'03'		; C5  -- 08
	retlw	h'03'		; C#5 -- 09
	retlw	h'02'		; D5  -- 0a
	retlw	h'02'		; D#5 -- 0b
	retlw	h'02'		; E5  -- 0c
	retlw	h'02'		; F5  -- 0d
	retlw	h'02'		; F#5 -- 0e
	retlw	h'02'		; G5  -- 0f
	retlw	h'02'		; G#5 -- 10
	retlw	h'01'		; A5  -- 11
	retlw	h'01'		; A#  -- 12
	retlw	h'01'		; B5  -- 13
	retlw	h'01'		; C6  -- 14
	retlw	h'01'		; C#6 -- 15
	retlw	h'01'		; D6  -- 16
	retlw	h'01'		; D#6 -- 17
	retlw	h'01'		; E6  -- 18
	retlw	h'01'		; F6  -- 19
	retlw	h'01'		; F#6 -- 1a
	retlw	h'01'		; G6  -- 1b
	retlw	h'01'		; G#6 -- 1c
	retlw	h'00'		; A6  -- 1d
	retlw	h'00'		; A#6 -- 1e
	retlw	h'00'		; B6  -- 1f
        
; *************
; ** GetCWD  **
; *************
	;; get CW Delay 
GetCWD				; get cw delay from table
	movwf	temp		; save addr.
	movlw	high CWDTbl	; set page 
	movwf	PCLATH		; select page
	movf	temp,w		; get speed into w
	andlw	h'1f'		; force into valid range
	addwf	PCL,f		; add w to PCL
CWDTbl
	retlw	d'240'		;  0 -- use 5 WPM
	retlw	d'240'		;  1 -- use 5 WPM
	retlw	d'240'		;  2 -- use 5 WPM
	retlw	d'240'		;  3 -- use 5 WPM
	retlw	d'240'		;  4 -- use 5 WPM
	retlw	d'240'		;  5 WPM
	retlw	d'200'		;  6
	retlw	d'171'		;  7
	retlw	d'150'		;  8
	retlw	d'133'		;  9
	retlw	d'120'		; 10
	retlw	d'109'		; 11
	retlw	d'100'		; 12
	retlw	d'92'		; 13
	retlw	d'86'		; 14
	retlw	d'80'		; 15
	retlw	d'75'		; 16
	retlw	d'71'		; 17
	retlw	d'67'		; 18
	retlw	d'63'		; 19
	retlw	d'60'		; 20
	retlw	d'57'		; 21
	retlw	d'55'		; 22
	retlw	d'52'		; 23
	retlw	d'50'		; 24
	retlw	d'48'		; 25
	retlw	d'46'		; 26
	retlw	d'44'		; 27
	retlw	d'43'		; 28
	retlw	d'41'		; 29
	retlw	d'40'		; 30
	retlw	d'40'		; 31 - use 30 WPM

	org	h'0d00'		; still in page 1

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
	retlw	h'2a'		; 13 ar
	retlw	h'31'		; 14 bt
	retlw	h'58'		; 15 sk
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
	retlw	h'0f'		; 'O'	-- 00
	retlw	h'0d'		; 'K'	-- 01
	retlw	h'ff'		; EOM	-- 02
	retlw	h'02'		; 'E'	-- 03
	retlw	h'0a'		; 'R'	-- 04
	retlw	h'0a'		; 'R'	-- 05
	retlw	h'ff'		; EOM	-- 06
	retlw	h'03'		; 'T'	-- 07
	retlw	h'0f'		; '0'	-- 08
	retlw	h'ff'		; EOM	-- 09
	retlw	h'05'		; 'N'	-- 0a
	retlw	h'10'		; 'H'	-- 0b
	retlw	h'0a'		; 'R'	-- 0c
	retlw	h'15'		; 'C'	-- 0d
	retlw	h'00'		; ' '	-- 0e
	retlw	h'30'		; '4'	-- 0f
	retlw	h'ff'		; EOM	-- 10
	retlw	h'0f'		; 'O'	-- 11
	retlw	h'05'		; 'N'	-- 12
	retlw	h'ff'		; EOM	-- 13
	retlw	h'0f'		; 'O'	-- 14
	retlw	h'14'		; 'F'	-- 15
	retlw	h'14'		; 'F'	-- 16
	retlw	h'ff'		; EOM	-- 17
	retlw	d'05'		; 18 alarm tone
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

; *************
; ** Get100s **
; *************
	;; get the number of tens in INDF. return in w.
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
		
	;; jeff
; **************
; ** CWParms  **
; **************
CWParms				; set CW parameters from timers.
	movlw	EETCWP		; get EEPROM address of cw pitch preset.
	movwf	eeAddr		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	cwTone		; save CW tone.
	
	movlw	EETCWS		; get EEPROM address of cw speed preset.
	movwf	eeAddr		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	call	GetCWD		; get the CW delay for the indicated speed.
	movwf	cwSpeed		; save CW speed.

	return			; done here.

	org	h'0e00'		; still in page 1

; ******************************
; ** ROM Table Fetches follow **
; ******************************
InitDat
	movwf	temp		; save addr.
	movlw	high InitTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	addwf	PCL,f		; add w to PCL
InitTbl
	;; timer initial defaults
	retlw	d'100'		; 0000 hang timer long 10.0 sec
	retlw	d'50'		; 0001 hang timer short 5.0 sec
	retlw	d'54'		; 0002 ID timer 9.0 min
	retlw	d'60'		; 0003 DTMF access timer 600 sec
	retlw	d'180'		; 0004 timeout timer long 180 sec
	retlw	d'30'		; 0005 timeout timer short 30 sec
	retlw	d'12'		; 0006 fan timer 120 sec
	retlw	d'20'		; 0007 cw pitch
	retlw	d'20'		; 0008 cw speed
	retlw	d'0'		; 0009 spare
	retlw	d'0'		; 000a spare
	retlw	d'0'		; 000b spare
	retlw	d'0'		; 000c spare
	retlw	d'0'		; 000d spare
	retlw	d'0'		; 000e spare
	retlw	d'0'		; 000f spare

	;; control operator switches, set 0
	retlw	b'01001001'	; 0010 control operator switches, group 0
	retlw	b'00001011'	; 0011 control operator switches, group 1
	retlw	b'00001111'	; 0012 control operator switches, group 2
	retlw	b'00000000'	; 0013 control operator switches, group 3
	retlw	b'00000000'	; 0014 control operator switches, group 4
	retlw	b'00000000'	; 0015 control operator switches, group 5
	retlw	b'00000000'	; 0016 control operator switches, group 6
	retlw	b'00000000'	; 0017 control operator switches, group 7
	retlw	b'00000000'	; 0018 control operator switches, group 8
	retlw	b'11111111'	; 0019 control operator switches, group 9
	retlw	h'00'		; 001a spare
	retlw	h'00'		; 001b spare
	retlw	h'00'		; 001c spare
	retlw	h'00'		; 001d spare
	retlw	h'00'		; 001e spare
	retlw	h'00'		; 001f spare

	;; control operator switches, set 1
	retlw	b'01001001'	; 0020 control operator switches, group 0
	retlw	b'00001011'	; 0021 control operator switches, group 1
	retlw	b'00001111'	; 0022 control operator switches, group 2
	retlw	b'00000000'	; 0023 control operator switches, group 3
	retlw	b'00000000'	; 0024 control operator switches, group 4
	retlw	b'00000000'	; 0025 control operator switches, group 5
	retlw	b'00000000'	; 0026 control operator switches, group 6
	retlw	b'00000000'	; 0027 control operator switches, group 7
	retlw	b'00000000'	; 0028 control operator switches, group 8
	retlw	b'11111111'	; 0029 control operator switches, group 9
	retlw	h'00'		; 002a spare
	retlw	h'00'		; 002b spare
	retlw	h'00'		; 002c spare
	retlw	h'00'		; 002d spare
	retlw	h'00'		; 002e spare
	retlw	h'00'		; 002f spare

	;; courtesy tone initial defaults
	;; Main Receiver Courtesy Tone
	retlw	h'05'		; 0030 Courtesy tone 0 00 length seg 1
	retlw	h'8c'		; 0031 Courtesy tone 0 01 tone seg 1
	retlw	h'05'		; 0032 Courtesy tone 0 02 length seg 2
	retlw	h'8f'		; 0033 Courtesy tone 0 03 tone seg 2
	retlw	h'05'		; 0034 Courtesy tone 0 04 length seg 3
	retlw	h'93'		; 0035 Courtesy tone 0 05 tone seg 3
	retlw	h'05'		; 0036 Courtesy tone 0 06 length seg 4
	retlw	h'16'		; 0037 Courtesy tone 0 07 tone seg 4
	;; Main Receiver Courtesy Tone, Link RX active, alert mode.
	retlw	h'0a'		; 0038 Courtesy Tone 1 00 length seg 1
	retlw	h'8c'		; 0039 Courtesy Tone 1 01 tone seg 1
	retlw	h'0a'		; 003a Courtesy Tone 1 02 length seg 2
	retlw	h'0f'		; 003b Courtesy Tone 1 03 tone seg 2
	retlw	h'00'		; 003c Courtesy Tone 1 04 length seg 3
	retlw	h'00'		; 003d Courtesy Tone 1 05 tone seg 3
	retlw	h'00'		; 003e Courtesy Tone 1 06 length seg 4
	retlw	h'00'		; 003f Courtesy Tone 1 07 tone seg 4
	;; Main Receiver Courtesy Tone, Link TX on
	retlw	h'0a'		; 0040 Courtesy tone 2 00 length seg 1
	retlw	h'8c'		; 0041 Courtesy tone 2 01 tone seg 1
	retlw	h'0a'		; 0042 Courtesy tone 2 02 length seg 2
	retlw	h'8f'		; 0043 Courtesy tone 2 03 tone seg 2
	retlw	h'0a'		; 0044 Courtesy tone 2 04 length seg 3
	retlw	h'15'		; 0045 Courtesy tone 2 05 tone seg 3
	retlw	h'00'		; 0046 Courtesy tone 2 06 length seg 4
	retlw	h'00'		; 0047 Courtesy tone 2 07 tone seg 4
	;; Link Receiver Courtesy Tone
	retlw	h'05'		; 0048 Courtesy Tone 3 00 length seg 1
	retlw	h'96'		; 0049 Courtesy Tone 3 01 tone seg 1
	retlw	h'05'		; 004a Courtesy Tone 3 02 length seg 2
	retlw	h'93'		; 004b Courtesy Tone 3 03 tone seg 2
	retlw	h'05'		; 004c Courtesy Tone 3 04 length seg 3
	retlw	h'8f'		; 004d Courtesy Tone 3 05 tone seg 3
	retlw	h'05'		; 004e Courtesy Tone 3 06 length seg 4
	retlw	h'0b'		; 004f Courtesy Tone 3 07 tone seg 4
	;; Link Receiver Courtesy Tone, Link TX on
	retlw	h'0a'		; 0050 Courtesy tone 4 00 length seg 1
	retlw	h'96'		; 0051 Courtesy tone 4 01 tone seg 1
	retlw	h'0a'		; 0052 Courtesy tone 4 02 length seg 2
	retlw	h'93'		; 0053 Courtesy tone 4 03 tone seg 2
	retlw	h'0a'		; 0054 Courtesy tone 4 04 length seg 3
	retlw	h'10'		; 0055 Courtesy tone 4 05 tone seg 3
	retlw	h'00'		; 0056 Courtesy tone 4 06 length seg 4
	retlw	h'00'		; 0057 Courtesy tone 4 07 tone seg 4
	;; Spare Courtesy Tone
	retlw	h'0a'		; 0058 Courtesy Tone 5 00 length seg 1
	retlw	h'08'		; 0059 Courtesy Tone 5 01 tone seg 1
	retlw	h'00'		; 005a Courtesy Tone 5 02 length seg 2
	retlw	h'00'		; 005b Courtesy Tone 5 03 tone seg 2
	retlw	h'00'		; 005c Courtesy Tone 5 04 length seg 3
	retlw	h'00'		; 005d Courtesy Tone 5 05 tone seg 3
	retlw	h'00'		; 005e Courtesy Tone 5 06 length seg 4
	retlw	h'00'		; 005f Courtesy Tone 5 07 tone seg 4
	;; Tune Mode Courtesy Tone
	retlw	h'0a'		; 0060 Courtesy tone 6 00 length seg 1
	retlw	h'13'		; 0061 Courtesy tone 6 01 tone seg 1
	retlw	h'00'		; 0062 Courtesy tone 6 02 length seg 2
	retlw	h'00'		; 0063 Courtesy tone 6 03 tone seg 2
	retlw	h'00'		; 0064 Courtesy tone 6 04 length seg 3
	retlw	h'00'		; 0065 Courtesy tone 6 05 tone seg 3
	retlw	h'00'		; 0066 Courtesy tone 6 06 length seg 4
	retlw	h'00'		; 0067 Courtesy tone 6 07 tone seg 4
	;; Unlocked Mode Courtesy Tone.
	retlw	h'0a'		; 0068 Courtesy Tone 7 00 length seg 1
	retlw	h'9f'		; 0069 Courtesy Tone 7 01 tone seg 1
	retlw	h'0a'		; 006a Courtesy Tone 7 02 length seg 2
	retlw	h'93'		; 006b Courtesy Tone 7 03 tone seg 2
	retlw	h'0a'		; 006c Courtesy Tone 7 04 length seg 3
	retlw	h'9f'		; 006d Courtesy Tone 7 05 tone seg 3
	retlw	h'0a'		; 006e Courtesy Tone 7 06 length seg 4
	retlw	h'13'		; 006f Courtesy Tone 7 07 tone seg 4
	
 	;; cw id initial defaults
	retlw	h'05'		; 0070 CW ID	1 'N'
	retlw	h'10'		; 0071 CW ID	2 'H'
	retlw	h'0a'		; 0072 CW ID	3 'R'
	retlw	h'15'		; 0073 CW ID	4 'C'
	retlw	h'00'		; 0074 CW ID	5 ' '
	retlw	h'30'		; 0075 CW ID	6 '4'
	retlw	h'ff'		; 0076 CW ID	7 eom
	retlw	h'ff'		; 0077 CW ID	8 eom
	retlw	h'ff'		; 0078 CW ID	9 eom
	retlw	h'ff'		; 0079 CW ID 10 eom
	retlw	h'ff'		; 007a CW ID 11 eom
	retlw	h'ff'		; 007b CW ID 12 eom
	retlw	h'ff'		; 007c CW ID 13 eom
	retlw	h'ff'		; 007d CW ID 14 eom
	retlw	h'ff'		; 007e CW ID 15 eom
	retlw	h'ff'		; 007f CW ID 16 eom
	
	;; control prefixes
	retlw	h'00'		; 0080 control prefix 0	00
	retlw	h'00'		; 0081 control prefix 0	01
	retlw	h'ff'		; 0082 control prefix 0	02
	retlw	h'ff'		; 0083 control prefix 0	03
	retlw	h'ff'		; 0084 control prefix 0	04
	retlw	h'ff'		; 0085 control prefix 0	05
	retlw	h'ff'		; 0086 control prefix 0	06
	retlw	h'ff'		; 0087 control prefix 0	07
	retlw	h'00'		; 0088 control prefix 1	00
	retlw	h'01'		; 0089 control prefix 1	01
	retlw	h'ff'		; 008a control prefix 1	02
	retlw	h'ff'		; 008b control prefix 1	03
	retlw	h'ff'		; 008c control prefix 1	04
	retlw	h'ff'		; 008d control prefix 1	05
	retlw	h'ff'		; 008e control prefix 1	06
	retlw	h'ff'		; 008f control prefix 1	07
	retlw	h'00'		; 0090 control prefix 2	00
	retlw	h'02'		; 0091 control prefix 2	01
	retlw	h'ff'		; 0092 control prefix 2	02
	retlw	h'ff'		; 0093 control prefix 2	03
	retlw	h'ff'		; 0094 control prefix 2	04
	retlw	h'ff'		; 0095 control prefix 2	05
	retlw	h'ff'		; 0096 control prefix 2	06
	retlw	h'ff'		; 0097 control prefix 2	07
	retlw	h'00'		; 0098 control prefix 3	00
	retlw	h'03'		; 0099 control prefix 3	01
	retlw	h'ff'		; 009a control prefix 3	02
	retlw	h'ff'		; 009b control prefix 3	03
	retlw	h'ff'		; 009c control prefix 3	04
	retlw	h'ff'		; 009d control prefix 3	05
	retlw	h'ff'		; 009e control prefix 3	06
	retlw	h'ff'		; 009f control prefix 3	07
	retlw	h'00'		; 00a0 control prefix 4	00
	retlw	h'04'		; 00a1 control prefix 4	01
	retlw	h'ff'		; 00a2 control prefix 4	02
	retlw	h'ff'		; 00a3 control prefix 4	03
	retlw	h'ff'		; 00a4 control prefix 4	04
	retlw	h'ff'		; 00a5 control prefix 4	05
	retlw	h'ff'		; 00a6 control prefix 4	06
	retlw	h'ff'		; 00a7 control prefix 4	07
	retlw	h'00'		; 00a8 control prefix 5	00
	retlw	h'05'		; 00a9 control prefix 5	01
	retlw	h'ff'		; 00aa control prefix 5	02
	retlw	h'ff'		; 00ab control prefix 5	03
	retlw	h'ff'		; 00ac control prefix 5	04
	retlw	h'ff'		; 00ad control prefix 5	05
	retlw	h'ff'		; 00ae control prefix 5	06
	retlw	h'ff'		; 00af control prefix 5	07
	retlw	h'00'		; 00b0 control prefix 6	00
	retlw	h'06'		; 00b1 control prefix 6	01
	retlw	h'ff'		; 00b2 control prefix 6	02
	retlw	h'ff'		; 00b3 control prefix 6	03
	retlw	h'ff'		; 00b4 control prefix 6	04
	retlw	h'ff'		; 00b5 control prefix 6	05
	retlw	h'ff'		; 00b6 control prefix 6	06
	retlw	h'ff'		; 00b7 control prefix 6	07
	retlw	h'00'		; 00b8 control prefix 7	00
	retlw	h'07'		; 00b9 control prefix 7	01
	retlw	h'ff'		; 00ba control prefix 7	02
	retlw	h'ff'		; 00bb control prefix 7	03
	retlw	h'ff'		; 00bc control prefix 7	04
	retlw	h'ff'		; 00bd control prefix 7	05
	retlw	h'ff'		; 00be control prefix 7	06
	retlw	h'ff'		; 00bf control prefix 7	07
	retlw	h'01'		; 00c0 spare
	retlw	h'01'		; 00c1 spare
	retlw	h'01'		; 00c2 spare
	retlw	h'01'		; 00c3 spare
	retlw	h'01'		; 00c4 spare
	retlw	h'01'		; 00c5 spare
	retlw	h'01'		; 00c6 spare
	retlw	h'01'		; 00c7 spare
	retlw	h'00'		; 00c8 spare
	retlw	h'00'		; 00c9 spare
	retlw	h'00'		; 00ca spare
	retlw	h'00'		; 00cb spare
	retlw	h'00'		; 00cc spare
	retlw	h'00'		; 00cd spare
	retlw	h'00'		; 00ce spare
	retlw	h'00'		; 00cf spare

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
; ** SetTone **
; *************
	;; get a tone 1/2 interval from the table.
	;; tone 00 is NO tone (off).
	;; start sending the tone.
SetTone				; get tone bytes from table
	movwf	temp		; save w
	btfsc	STATUS,Z	; is result zero?
	goto	StopTone	; yes. Stop that infernal beeping.
	call	GetToneH	; get hi byte.
	movwf	CCPR1H		; save hi byte.
	call	GetToneL	; get lo byte.
	movwf	CCPR1L		; save lo byte.
	clrf	TMR1L		; clear lo byte of timer.
	clrf	TMR1H		; clear hi byte of timer.
	bsf	T1CON, TMR1ON	; turn on timer 1.	Start beeping.
	return			; done.

StopTone			; stop the racket!
	bcf	T1CON, TMR1ON	; turn off timer 1.
	return
	
	org	h'0f00'		; reserved for ICD

	IF LOAD_EE == 1	
	org	h'2100'
	de	d'100'		; 0000 hang timer long 10.0 sec
	de	d'50'		; 0001 hang timer short 5.0 sec
	de	d'54'		; 0002 ID timer 9.0 min
	de	d'60'		; 0003 DTMF access timer 600 sec
	de	d'180'		; 0004 timeout timer long 180 sec
	de	d'30'		; 0005 timeout timer short 30 sec
	de	d'12'		; 0006 fan timer 120 sec
	de	d'20'		; 0007 cw pitch
	de	d'20'		; 0008 cw speed
	de	d'0'		; 0009 spare
	de	d'0'		; 000a spare
	de	d'0'		; 000b spare
	de	d'0'		; 000c spare
	de	d'0'		; 000d spare
	de	d'0'		; 000e spare
	de	d'0'		; 000f spare

	;; control operator switches, set 0
	de	b'01001001'	; 0010 control operator switches, group 0
	de	b'00001011'	; 0011 control operator switches, group 1
	de	b'00001111'	; 0012 control operator switches, group 2
	de	b'00000000'	; 0013 control operator switches, group 3
	de	b'00000000'	; 0014 control operator switches, group 4
	de	b'00000000'	; 0015 control operator switches, group 5
	de	b'00000000'	; 0016 control operator switches, group 6
	de	b'00000000'	; 0017 control operator switches, group 7
	de	b'00000000'	; 0018 control operator switches, group 8
	de	b'11111111'	; 0019 control operator switches, group 9
	de	h'00'		; 001a spare
	de	h'00'		; 001b spare
	de	h'00'		; 001c spare
	de	h'00'		; 001d spare
	de	h'00'		; 001e spare
	de	h'00'		; 001f spare

	;; control operator switches, set 1
	de	b'01001001'	; 0020 control operator switches, group 0
	de	b'00001011'	; 0021 control operator switches, group 1
	de	b'00001111'	; 0022 control operator switches, group 2
	de	b'00000000'	; 0023 control operator switches, group 3
	de	b'00000000'	; 0024 control operator switches, group 4
	de	b'00000000'	; 0025 control operator switches, group 5
	de	b'00000000'	; 0026 control operator switches, group 6
	de	b'00000000'	; 0027 control operator switches, group 7
	de	b'00000000'	; 0028 control operator switches, group 8
	de	b'11111111'	; 0029 control operator switches, group 9
	de	h'00'		; 002a spare
	de	h'00'		; 002b spare
	de	h'00'		; 002c spare
	de	h'00'		; 002d spare
	de	h'00'		; 002e spare
	de	h'00'		; 002f spare

	;; courtesy tone initial defaults
	;; Main Receiver Courtesy Tone
	de	h'05'		; 0030 Courtesy tone 0 00 length seg 1
	de	h'8c'		; 0031 Courtesy tone 0 01 tone seg 1
	de	h'05'		; 0032 Courtesy tone 0 02 length seg 2
	de	h'8f'		; 0033 Courtesy tone 0 03 tone seg 2
	de	h'05'		; 0034 Courtesy tone 0 04 length seg 3
	de	h'93'		; 0035 Courtesy tone 0 05 tone seg 3
	de	h'05'		; 0036 Courtesy tone 0 06 length seg 4
	de	h'16'		; 0037 Courtesy tone 0 07 tone seg 4
	;; Main Receiver Courtesy Tone, Link RX active, alert mode.
	de	h'0a'		; 0038 Courtesy Tone 1 00 length seg 1
	de	h'8c'		; 0039 Courtesy Tone 1 01 tone seg 1
	de	h'0a'		; 003a Courtesy Tone 1 02 length seg 2
	de	h'0f'		; 003b Courtesy Tone 1 03 tone seg 2
	de	h'00'		; 003c Courtesy Tone 1 04 length seg 3
	de	h'00'		; 003d Courtesy Tone 1 05 tone seg 3
	de	h'00'		; 003e Courtesy Tone 1 06 length seg 4
	de	h'00'		; 003f Courtesy Tone 1 07 tone seg 4
	;; Main Receiver Courtesy Tone, Link TX on
	de	h'0a'		; 0040 Courtesy tone 2 00 length seg 1
	de	h'8c'		; 0041 Courtesy tone 2 01 tone seg 1
	de	h'0a'		; 0042 Courtesy tone 2 02 length seg 2
	de	h'8f'		; 0043 Courtesy tone 2 03 tone seg 2
	de	h'0a'		; 0044 Courtesy tone 2 04 length seg 3
	de	h'15'		; 0045 Courtesy tone 2 05 tone seg 3
	de	h'00'		; 0046 Courtesy tone 2 06 length seg 4
	de	h'00'		; 0047 Courtesy tone 2 07 tone seg 4
	;; Link Receiver Courtesy Tone
	de	h'05'		; 0048 Courtesy Tone 3 00 length seg 1
	de	h'96'		; 0049 Courtesy Tone 3 01 tone seg 1
	de	h'05'		; 004a Courtesy Tone 3 02 length seg 2
	de	h'93'		; 004b Courtesy Tone 3 03 tone seg 2
	de	h'05'		; 004c Courtesy Tone 3 04 length seg 3
	de	h'8f'		; 004d Courtesy Tone 3 05 tone seg 3
	de	h'05'		; 004e Courtesy Tone 3 06 length seg 4
	de	h'0b'		; 004f Courtesy Tone 3 07 tone seg 4
	;; Link Receiver Courtesy Tone, Link TX on
	de	h'0a'		; 0050 Courtesy tone 4 00 length seg 1
	de	h'96'		; 0051 Courtesy tone 4 01 tone seg 1
	de	h'0a'		; 0052 Courtesy tone 4 02 length seg 2
	de	h'93'		; 0053 Courtesy tone 4 03 tone seg 2
	de	h'0a'		; 0054 Courtesy tone 4 04 length seg 3
	de	h'10'		; 0055 Courtesy tone 4 05 tone seg 3
	de	h'00'		; 0056 Courtesy tone 4 06 length seg 4
	de	h'00'		; 0057 Courtesy tone 4 07 tone seg 4
	;; Spare Courtesy Tone
	de	h'0a'		; 0058 Courtesy Tone 5 00 length seg 1
	de	h'08'		; 0059 Courtesy Tone 5 01 tone seg 1
	de	h'00'		; 005a Courtesy Tone 5 02 length seg 2
	de	h'00'		; 005b Courtesy Tone 5 03 tone seg 2
	de	h'00'		; 005c Courtesy Tone 5 04 length seg 3
	de	h'00'		; 005d Courtesy Tone 5 05 tone seg 3
	de	h'00'		; 005e Courtesy Tone 5 06 length seg 4
	de	h'00'		; 005f Courtesy Tone 5 07 tone seg 4
	;; Tune Mode Courtesy Tone
	de	h'0a'		; 0060 Courtesy tone 6 00 length seg 1
	de	h'13'		; 0061 Courtesy tone 6 01 tone seg 1
	de	h'00'		; 0062 Courtesy tone 6 02 length seg 2
	de	h'00'		; 0063 Courtesy tone 6 03 tone seg 2
	de	h'00'		; 0064 Courtesy tone 6 04 length seg 3
	de	h'00'		; 0065 Courtesy tone 6 05 tone seg 3
	de	h'00'		; 0066 Courtesy tone 6 06 length seg 4
	de	h'00'		; 0067 Courtesy tone 6 07 tone seg 4
	;; Unlocked Mode Courtesy Tone.
	de	h'0a'		; 0068 Courtesy Tone 7 00 length seg 1
	de	h'9f'		; 0069 Courtesy Tone 7 01 tone seg 1
	de	h'0a'		; 006a Courtesy Tone 7 02 length seg 2
	de	h'93'		; 006b Courtesy Tone 7 03 tone seg 2
	de	h'0a'		; 006c Courtesy Tone 7 04 length seg 3
	de	h'9f'		; 006d Courtesy Tone 7 05 tone seg 3
	de	h'0a'		; 006e Courtesy Tone 7 06 length seg 4
	de	h'13'		; 006f Courtesy Tone 7 07 tone seg 4
	
 	;; cw id initial defaults
	de	h'05'		; 0070 CW ID	1 'n'
	de	h'10'		; 0071 CW ID	2 'h'
	de	h'0a'		; 0072 CW ID	3 'r'
	de	h'15'		; 0073 CW ID	4 'c'
	de	h'00'		; 0074 CW ID	5 ' '
	de	h'30'		; 0075 CW ID	6 '4'
	de	h'ff'		; 0076 CW ID	7 eom
	de	h'ff'		; 0077 CW ID	8 eom
	de	h'ff'		; 0078 CW ID	9 eom
	de	h'ff'		; 0079 CW ID 10 eom
	de	h'ff'		; 007a CW ID 11 eom
	de	h'ff'		; 007b CW ID 12 eom
	de	h'ff'		; 007c CW ID 13 eom
	de	h'ff'		; 007d CW ID 14 eom
	de	h'ff'		; 007e CW ID 15 eom
	de	h'ff'		; 007f CW ID 16 eom
	
	;; control prefixes
	de	h'00'		; 0080 control prefix 0	00
	de	h'00'		; 0081 control prefix 0	01
	de	h'ff'		; 0082 control prefix 0	02
	de	h'ff'		; 0083 control prefix 0	03
	de	h'ff'		; 0084 control prefix 0	04
	de	h'ff'		; 0085 control prefix 0	05
	de	h'ff'		; 0086 control prefix 0	06
	de	h'ff'		; 0087 control prefix 0	07
	de	h'00'		; 0088 control prefix 1	00
	de	h'01'		; 0089 control prefix 1	01
	de	h'ff'		; 008a control prefix 1	02
	de	h'ff'		; 008b control prefix 1	03
	de	h'ff'		; 008c control prefix 1	04
	de	h'ff'		; 008d control prefix 1	05
	de	h'ff'		; 008e control prefix 1	06
	de	h'ff'		; 008f control prefix 1	07
	de	h'00'		; 0090 control prefix 2	00
	de	h'02'		; 0091 control prefix 2	01
	de	h'ff'		; 0092 control prefix 2	02
	de	h'ff'		; 0093 control prefix 2	03
	de	h'ff'		; 0094 control prefix 2	04
	de	h'ff'		; 0095 control prefix 2	05
	de	h'ff'		; 0096 control prefix 2	06
	de	h'ff'		; 0097 control prefix 2	07
	de	h'00'		; 0098 control prefix 3	00
	de	h'03'		; 0099 control prefix 3	01
	de	h'ff'		; 009a control prefix 3	02
	de	h'ff'		; 009b control prefix 3	03
	de	h'ff'		; 009c control prefix 3	04
	de	h'ff'		; 009d control prefix 3	05
	de	h'ff'		; 009e control prefix 3	06
	de	h'ff'		; 009f control prefix 3	07
	de	h'00'		; 00a0 control prefix 4	00
	de	h'04'		; 00a1 control prefix 4	01
	de	h'ff'		; 00a2 control prefix 4	02
	de	h'ff'		; 00a3 control prefix 4	03
	de	h'ff'		; 00a4 control prefix 4	04
	de	h'ff'		; 00a5 control prefix 4	05
	de	h'ff'		; 00a6 control prefix 4	06
	de	h'ff'		; 00a7 control prefix 4	07
	de	h'00'		; 00a8 control prefix 5	00
	de	h'05'		; 00a9 control prefix 5	01
	de	h'ff'		; 00aa control prefix 5	02
	de	h'ff'		; 00ab control prefix 5	03
	de	h'ff'		; 00ac control prefix 5	04
	de	h'ff'		; 00ad control prefix 5	05
	de	h'ff'		; 00ae control prefix 5	06
	de	h'ff'		; 00af control prefix 5	07
	de	h'00'		; 00b0 control prefix 6	00
	de	h'06'		; 00b1 control prefix 6	01
	de	h'ff'		; 00b2 control prefix 6	02
	de	h'ff'		; 00b3 control prefix 6	03
	de	h'ff'		; 00b4 control prefix 6	04
	de	h'ff'		; 00b5 control prefix 6	05
	de	h'ff'		; 00b6 control prefix 6	06
	de	h'ff'		; 00b7 control prefix 6	07
	de	h'00'		; 00b8 control prefix 7	00
	de	h'07'		; 00b9 control prefix 7	01
	de	h'ff'		; 00ba control prefix 7	02
	de	h'ff'		; 00bb control prefix 7	03
	de	h'ff'		; 00bc control prefix 7	04
	de	h'ff'		; 00bd control prefix 7	05
	de	h'ff'		; 00be control prefix 7	06
	de	h'ff'		; 00bf control prefix 7	07
	
	de	d'50'		; 00c0 spare
	de	d'50'		; 00c1 spare
	de	d'50'		; 00c2 spare
	de	d'50'		; 00c3 spare
	de	d'50'		; 00c4 spare
	de	d'50'		; 00c5 spare
	de	d'50'		; 00c6 spare
	de	d'50'		; 00c7 spare
	de	h'00'		; 00c8 spare
	de	h'00'		; 00c9 spare
	de	h'00'		; 00ca spare
	de	h'00'		; 00cb spare
	de	h'00'		; 00cc spare
	de	h'00'		; 00cd spare
	de	h'00'		; 00ce spare
	de	h'00'		; 00cf spare

	de	h'00'		; 00d0 spare
	de	h'00'		; 00d1 spare
	de	h'00'		; 00d2 spare
	de	h'00'		; 00d3 spare
	de	h'00'		; 00d4 spare
	de	h'00'		; 00d5 spare
	de	h'00'		; 00d6 spare
	de	h'00'		; 00d7 spare
	de	h'00'		; 00d8 spare
	de	h'00'		; 00d9 spare
	de	h'00'		; 00da spare
	de	h'00'		; 00db spare
	de	h'00'		; 00dc spare
	de	h'00'		; 00dd spare
	de	h'00'		; 00de spare
	de	h'00'		; 00df spare
	
	de	h'00'		; 00e0 spare
	de	h'00'		; 00e1 spare
	de	h'00'		; 00e2 spare
	de	h'00'		; 00e3 spare
	de	h'00'		; 00e4 spare
	de	h'00'		; 00e5 spare
	de	h'00'		; 00e6 spare
	de	h'00'		; 00e7 spare
	de	h'00'		; 00e8 spare
	de	h'00'		; 00e9 spare
	de	h'00'		; 00ea spare
	de	h'00'		; 00eb spare
	de	h'00'		; 00ec spare
	de	h'00'		; 00ed spare
	de	h'00'		; 00ee spare
	de	h'00'		; 00ef spare
	
	de	h'00'		; 00f0 spare
	de	h'00'		; 00f1 spare
	de	h'00'		; 00f2 spare
	de	h'00'		; 00f3 spare
	de	h'00'		; 00f4 spare
	de	h'00'		; 00f5 spare
	de	h'00'		; 00f6 spare
	de	h'00'		; 00f7 spare
	de	h'00'		; 00f8 spare
	de	h'00'		; 00f9 spare
	de	h'00'		; 00fa spare
	de	h'00'		; 00fb spare
	de	h'00'		; 00fc spare
	de	h'00'		; 00fd spare
	de	h'00'		; 00fe spare
	de	h'00'		; 00ff spare

	ENDIF	
	
	end

	
; MORSE CODE encoding...
;
; morse characters are encoded in a single byte, bitwise, LSB to MSB.
; 0 = dit, 1 = dah.	the byte is shifted out to the right, until only 
; a 1 remains.	characters with more than 7 elements (error) cannot be sent.
;
; a .-		00000110	06	; 0 -----	00111111	3f
; b -...	00010001	11	; 1 .----	00111110	3e
; c -.-.	00010101	15	; 2 ..---	00111100	3c
; d -..		00001001	09	; 3 ...--	00111000	38
; e .		00000010	02	; 4 ....-	00110000	30
; f ..-.	00010100	14	; 5 .....	00100000	20
; g --.		00001011	0b	; 6 -....	00100001	21
; h ....	00010000	10	; 7 --...	00100011	23
; i ..		00000100	04	; 8 ---..	00100111	27
; j .---	00011110	1e	; 9 ----.	00101111	2f
; k -.-		00001101	0d			 
; l .-..	00010010	12	; sk ...-.-	01101000	58
; m --		00000111	07	; ar .-.-.	00101010	2a
; n -.		00000101	05	; bt -...-	00110001	31
; o ---		00001111	0f	; / -..-.	00101001	29
; p .--.	00010110	16			 
; q --.-	00011011	1b	; space		00000000	00
; r .-.		00001010	0a	; EOM		11111111	ff
; s ...		00001000	08
; t -		00000011	03
; u ..-		00001100	0c
; v ...-	00011000	18
; w .--		00001110	0e
; x -..-	00011001	19
; y -.--	00011101	1d
; z --..	00010011	13
	
;; CW timebase:
;; WPM	setting
;;	5	240
;;	6	200
;;	7	171
;;	8	150
;;	9	133
;;	10	120
;;	11	109
;;	12	100
;;	13	92
;;	14	86
;;	15	80
;;	16	75
;;	17	71
;;	18	67
;;	19	63
;;	20	60
;;	21	57
;;	22	55
;;	23	52
;;	24	50
;;	25	48
;;	26	46
;;	27	44
;;	28	43
;;	29	41
;;	30	40
	
