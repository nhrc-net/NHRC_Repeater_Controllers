	;; NHRC-Remote Plus Intelligent DTMF Remote Control
	;; Copyright 2011 NHRC LLC as an unpublished proprietary work.
	;; All rights reserved.
	;; No part of this document may be used or reproduced by any means,
	;; for any purpose, without the expressed written consent of NHRC LLC.

	;; 001 - start from NHRC-4 rev 3.0
	;; 300 - 8 digit pass codes.

VER_INT	equ	d'3'
VER_HI	equ	d'0'
VER_LO	equ	d'0'

LOAD_EE=1

;;DEBUG=1				;
	ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

	IFDEF __16F648A
	include "p16f648a.inc"
	IFDEF __MPLAB_DEBUGGER_ICD2
	;; for ICD don't use watchdog or code protect
	__FUSES _EXTCLK_OSC & _WDT_OFF & _LVP_OFF & _PWRTE_ON & _MCLRE_OFF
	ELSE
	__FUSES _CP_ON & _EXTCLK_OSC & _WDT_ON & _LVP_OFF & _PWRTE_ON & _MCLRE_OFF
	ENDIF			; __MPLAB_DEBUGGER_ICD2
	ELSE
	ERROR wrong processor selected!
	ENDIF			; __16F648A

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

INITBIT equ	4
BEEPBIT	equ	4		; beep and init share a.4
DV	equ	5		; STD/DV is now on RA5/MCLR\/VPP
PTT	equ	6		; PTT is now on RA6/OSC2/CLKOUT

;
; Port B has the following
; B.0 (in ) = control out 1
; B.1 (out) = control out 2
; B.2 (out) = control out 3
; B.3 (out) = control out 4
; B.4 (out) = control out 5
; B.5 (out) = control out 6
; B.6 (out) = control out 7
; B.7 (in ) = control out 8
;
;PortB
OUT1	equ	0		; control output 1
OUT2	equ	1		; control output 2
OUT3	equ	2		; control output 3
OUT4	equ	3		; control output 4
OUT5	equ	4		; control output 5
OUT6	equ	5		; control output 6
OUT7	equ	6		; control output 7
OUT8	equ	7		; control output 8

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
; niy	equ	5		;
; niy	equ	6		;
; niy	equ	7		;

;mscFlag			; misc flags...
;; niy	equ	0		;
;; niy	equ	1		;
;; NIY	equ	2		;
;; NIY	equ	3		;
LASTDV0	equ	4		; last DTMF digit valid, dtmf-0
;niy	equ	5		;
;niy	equ	6		;
;niy	equ	7		;

; txFlag
;;NIY	equ	0		;
;;NIY	equ	1		;
;;NIY	equ	2		;
;;NIY	equ	3		;
; niy	equ	4		;
; niy	equ	5		;
BEEPING equ	6		; beep tone active
CWPLAY	equ	7		; CW playing

CWTBDLY	equ	d'60'		; CW timebase delay for 20 WPM.

IDSOON	equ	D'6'		; ID soon, polite IDer threshold, 60 sec
DTMFDLY	equ	d'20'		; DTMF activity timer = 2.0 sec.

; dtRFlag -- dtmf sequence received indicator
DT0RDY	equ	0		; some sequence received on DTMF-0
;NIY	equ	1		;
;NIY	equ	2		;
;NIY	equ	3		;
DTSEVAL	equ	4		; dtmf command evaluation in progress.
;NIY	equ	5		;
;NIY	equ	6		;
;NIY	equ	7		;
		;;

;dtEFlag -- DTMF command evaluator control flag.
	;; low order 6 bits indicate next prefix number/user command to scan
DT0CMD	equ	6		; received this command from dtmf0
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

; CW Message Addressing Scheme:
; These symbols represent the value of the CW characters in the ROM table.
;	1 - CW timeout message, "to"
;	2 - CW confirm message, "ok"
;	3 - CW bad message, "ng"
;	3 - CW link timeout "rb to"

CW_OK	equ	h'00'		; CW: OK
CW_NG	equ	h'03'		; CW: NG
CW_TO	equ	h'07'		; CW: TO
CWHELLO	equ	h'0a'		; CW: NHRC RP
CW_ON	equ	h'12'		; CW: ON
CW_OFF	equ	h'15'		; CW: OFF
BPLOHI	equ	h'19'		; beep low then high
BPHILO	equ	h'1f'		; beep high then low

;
; CW sender constants
;

CWDIT	equ	1		; dit length in 100 ms
CWDAH	equ	CWDIT * 3	; dah
CWIESP	equ	CWDIT		; inter-element space
CWILSP	equ	CWDAH		; inter-letter space
CWIWSP	equ	CWDIT * 7	; inter-word space

MAGIC	equ	d'99'		; MAGIC value for programming ALL output prefixes.
OUTPUTS equ	d'8'		; number of outputs

T0PRE	equ	D'37'		; timer 0 preset for overflow in 224 counts.

; ***************
; ** VARIABLES **
; ***************
	cblock	h'20'		; 1st block of RAM at 20h-7fh (96 bytes here)
	;; interrupt pseudo-stack to save context during interrupt processing.
	s_copy			; 20 saved STATUS
	p_copy			; 21 saved PCLATH
	f_copy			; 22 saved FSR
	i_temp			; 23 temp for interrupt handler
	;; internal timing generation
	tFlags			; 24 Timer Flags
	oneMsC			; 25 one millisecond counter
	tenMsC			; 26 ten milliseconds counter
	hundMsC			; 27 hundred milliseconds counter
	thouMsC			; 28 thousand milliseconds counter (1 sec)

	temp			; 29 temporary storage. don't use in int handler.
	temp2			; 2a temporary storage.
	temp3			; 2b temporary storage.
	temp4			; 2c temporary storage.
	temp5			; 2d temporary storage.
	temp6			; 2e temporary storage.
	cmdSize			; 2f # digits received for current command
	;; operating flags
	flags			; 30 operating Flags
	mscFlag			; 31 misc. flags.
	txFlag			; 32 Transmitter control flag
	;; beep generator control
	beepTmr			; 33 timer for generating various beeps
	beepAddr		; 34 address for various beepings, low byte.
	beepCtl			; 35 beeping control flag
	;; timers
	idTmr			; 36 id timer, in 10 seconds
	pulsTim			; 37 pulse duration timer

	;; CW generator data
	cwTmr			; 38 CW element timer
	cwByte			; 39 CW current byte (bitmap)
	cwTbTmr			; 3a CW timebase timer
	cwTone			; 3b CW tone

	eeAddr			; 3c EEPROM address (low byte) to read/write
	eeCount			; 3d number of bytes to read/write from EEPROM
	pulsTmr			; 3e pulse timer

	;; control operator control flag groups
	group0			; group 0 flags
	group1			; group 1 flags
	group2			; group 2 flags
	;; last var at 0x?? there are ?? left in this block...
	endc			; this block ends at 6f

	cblock	h'70'		; from 70 to 7f is common to all banks!
	rICD70			; 70 reserved for ICD2
	w_copy			; 71 saved W register for interrupt handler
	dt0Ptr			; 72 DTMF-0 buffer pointer
	dt0Tmr			; 73 DTMF-0 buffer timer
	dtRFlag			; 74 DTMF receive flag...
	dtEFlag			; 75 DTMF command interpreter control flag
	eebPtr			; 76 eebuf write pointer.
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
	dt0buf1			; this should be enough to hold 31 digits,
	dt0buf2			; since the digits are stored as nibbles.
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
	btfss	PORTA,BEEPBIT	; is beep bit hi?
	goto	CompInL		; no.
	bcf	PORTA,BEEPBIT	; lower beep bit.
	goto	EEWrInt		; done.
CompInL				; beep bit was low.
	bsf	PORTA,BEEPBIT	; raise beep bit.

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
				; T0SE	n/a
				; PSA TMR0 gets the prescaler
				; PS2 \
				; PS1  > prescaler 4
				; PS0 /
	movwf	OPTION_REG	; set options

	movlw	b'00111111'	; low 6 bits are input
	movwf	TRISA		;
	movlw	b'00000000'	; port b all outputs
	movwf	TRISB

	clrf	PIE1		; turn off all peripheral interrupts.
	bsf	PIE1,CCP1IE	; enable on CCP1 interrupt.

	bcf	STATUS,RP0	; select bank 0

	;; PORT A does not need to be initialized, it is input-only.

	clrf	PORTA		; clear port a
	clrf	PORTB		; clear port b
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

	;; preset timer defaults
	clrf	cwTbTmr		; CW timebase counter.
	movlw	h'14'		; C6 tone
	movwf	cwTone		; CW tone.

	;; enable interrupts.
	movlw	b'11100000'	; enable global + peripheral + timer0
	movwf	INTCON

	btfsc	PORTA,INITBIT	; skip if init button pressed.
	goto	Start1		; no initialize request.

; *********************
; * INITIALIZE EEPROM *
; *********************

	clrf	temp2		; byte index
InitLp
	movf	temp2,w		; get init address
	movwf	eeAddr		; set eeprom address
	movf	temp2,w		; get init address
	call	InitDat		; get init byte
	PAGE1			; select page 1.
	call	WriteEw		; write byte to EEPROM.
	PAGE0			; select page 0

	movf	temp2,w		; get last address.
	sublw	EELAST		; subtract last init address.
	
	btfsc	STATUS,Z	; Z will be set if result is zero.
	goto	Start1		; done initializing...
	
	incf	temp2,f		; go to next byte
	goto	InitLp		; get the next block of 16 or be done.

; ********************************
; ** Ready to really start now. **
; ********************************
Start1
	bsf	STATUS,RP0	; select bank 1
	movlw	b'00101111'	; set INITBIT to BEEPBIT mode
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select bank 0

	clrw			; select macro set 0.
	PAGE1			; select page 1.
	call	LoadCtl		; load control op settings.
	;; push the last saved port status back to the port
	movf	group2,w	; get the group 2 register
	movwf	PORTB		; write it to the port

	;;
	;; say hello to all the nice people out there.
	;;
	movlw	CWHELLO		; get controller name announcement.
	call	PlayCW		; start playback

	;; read pulse timer default
	movlw	EEPTID		; get EEPROM address of Pulse duration preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE1			; select code page 1.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	pulsTim		; store to pulse duration preset

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
;	btfss	tFlags,HUNDMS
;	goto	LedEnd
;	btfss	PORTB,OUT8
;	goto	l3off
;	bcf	PORTB,OUT8
;	goto	LedEnd
l3off
;	bsf	PORTB,OUT8
LedEnd

	btfss	tFlags,TENMS	; is the ten ms tick active?
	goto	TenMsD		; nope

	;; ******************
	;; ** check DTMF-0 **
	;; ******************
CkDTMF0
	btfss	PORTA,DV	; is a DTMF digit being decoded?
	goto	CkDT0L		; no
	btfsc	mscFlag,LASTDV0	; was it there last time?
	goto	CkDTDone	; yes, do nothing.
	bsf	mscFlag,LASTDV0	; set last DV indicator.

RdDT0
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

CkDT0L				;
	btfss	mscFlag,LASTDV0	; was it low last time?
	goto	CkDTDone	; yes.	Done.
	bcf	mscFlag,LASTDV0	; no, clear last DV indicator.

CkDTDone			; done with DTMF scanning.

TenMsD				; ten ms tasks done.

	goto	MainLp		; crosses 256 byte boundary (to 0400)

	org	h'0400'

; *********************************
; * main loop for dtmf controller *
; *********************************

MainLp

ChkTmrs				; check timers here.

Ck10mS				; check 10 millisecond timers
	btfss	tFlags,TENMS	; is ten-millisecond bit set?
	goto	Ck100mS		; nope.
	;; ten millisecond tick active.
	movf	pulsTmr,f	; check for pulsed output
	btfsc	STATUS,Z	; is it zero?
	goto	PulsEnd		; yep.
	decfsz	pulsTmr,f	; decrement and check for zero.
	goto	PulsEnd		; not zero yet.

	;; pulse timer just counted down to zero.
	movf	group1,w	; get digout pulse control.
	andwf	group2,w	; check to see if any pulsed outputs are on
	btfsc	STATUS,Z	; any pulsed outputs on? (there should be!)
	goto	PulsEnd		; nope
	movf	group1,w	; get the pulse control.
	xorlw	h'ff'		; invert it
	andwf	group2,f	; turn off all pulsed outputs
	movf	group2,w	; get the expected latch output
	movwf	PORTB		; write it to the port

PulsEnd				; done with IO output pulse logic

Ck100mS				; check 100 millisecond tick.
	;btfss	tFlags,HUNDMS	; is 100 millisecond bit set?
	;goto	Ck1S		; nope.

Ck1S				; check 1-second flag bit.
	;btfss	tFlags,ONESEC	; is one-second flag bit set?
	;goto	Ck10S		; nope.
	;; 1-second tick active.
	;; not doing anything here right now.

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

	movlw	CWTBDLY		; get cw timebase preset.
	movwf	cwTbTmr	 ; preset CW timebase.

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
	clrf	beepCtl		; clear beep control flags

NoCW
CasEnd
CkTone
	btfss	tFlags,HUNDMS	; check the DTMF timers every 100 msec.
	goto	TonDone		; not 100 MS tick.
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
BeepTic				; a valid beep tick.
	decfsz	beepTmr,f	; decrement beepTmr
	goto	NoTime		; not zero yet.
	PAGE1			; select code page 1.
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
	PAGE1			; select code page 1.
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
	bcf	dtRFlag,DT0RDY	; reset DTMF ready bit.
	goto	DTEval		; go and evaluate the command right now.

XPfxDT
	goto	LoopEnd

DTEval				; evaluate DTMF command in command buffer

	;; evaluate the command in the buffer against the contents of eeprom.
	movlw	low cmdbf00	; get command buffer address
	movwf	FSR		; set pointer
	movf	dtEFlag,w	; get dtEFlag.
	andlw	b'00111111'	; mask out control bits.
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
	goto	DTEvalN		; them bytes were not equal. no match
	
	movf	temp2,w		; look at temp2
	sublw	d'1'		; is this the last byte
	btfsc	STATUS,Z	; is result zero?
	goto	DTEvalY		; yes, this was the last of 8, and it matched
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
	andlw	b'00111111'	; mask out control bits.
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

DTEdone				; done evaluating DTMF commands.
	clrf	dtEFlag		; yes.	reset evaluate DTMF flags.
	bcf	dtRFlag,DTSEVAL	; done evaluating.

LoopEnd
	;; JEFF always update the output latch here.
	;; maybe add logic later to only update it when different.

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

; ******************************
; ** ROM Table Fetches follow **
; ******************************
	org	h'0600'		; still in page 0
InitDat
	movwf	temp		; save addr.
	btfsc	temp,7		; hi bit set?
	goto	InitDaH		; top 128 bytes
	movlw	high InitTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	addwf	PCL,f		; add w to PCL
InitTbl
	;; timer initial defaults
	retlw	d'54'		; 0000 ID timer 9.0 minutes
	retlw	d'100'		; 0001 pulse duration timer
	retlw	d'0'		; 0002 spare
	retlw	d'0'		; 0003 spare
	retlw	d'0'		; 0004 spare
	retlw	d'0'		; 0005 spare
	retlw	d'0'		; 0006 spare
	retlw	d'0'		; 0007 spare
	retlw	d'0'		; 0008 spare
	retlw	d'0'		; 0009 spare
	retlw	d'0'		; 000a spare
	retlw	d'0'		; 000b spare
	retlw	d'0'		; 000c spare
	retlw	d'0'		; 000d spare
	retlw	d'0'		; 000e spare
	retlw	d'0'		; 000f spare

	;; control operator switches, set 0
	retlw	b'00000000'	; 0010 control operator switches, group 0
	retlw	b'00000000'	; 0011 control operator switches, group 1
	retlw	b'00000000'	; 0012 control operator switches, group 2
	retlw	h'00'		; 0013 spare
	retlw	h'00'		; 0014 spare
	retlw	h'00'		; 0015 spare
	retlw	h'00'		; 0016 spare
	retlw	h'00'		; 0017 spare
	retlw	h'00'		; 0018 spare
	retlw	h'00'		; 0019 spare
	retlw	h'00'		; 001a spare
	retlw	h'00'		; 001b spare
	retlw	h'00'		; 001c spare
	retlw	h'00'		; 001d spare
	retlw	h'00'		; 001e spare
	retlw	h'00'		; 001f spare

	;; empty from 0x20 to 0x4f
	retlw	h'00'		; 0020 spare
	retlw	h'00'		; 0021 spare
	retlw	h'00'		; 0022 spare
	retlw	h'00'		; 0023 spare
	retlw	h'00'		; 0024 spare
	retlw	h'00'		; 0025 spare
	retlw	h'00'		; 0026 spare
	retlw	h'00'		; 0027 spare
	retlw	h'00'		; 0028 spare
	retlw	h'00'		; 0029 spare
	retlw	h'00'		; 002a spare
	retlw	h'00'		; 002b spare
	retlw	h'00'		; 002c spare
	retlw	h'00'		; 002d spare
	retlw	h'00'		; 002e spare
	retlw	h'00'		; 002f spare

	retlw	h'00'		; 0030 spare
	retlw	h'00'		; 0031 spare
	retlw	h'00'		; 0032 spare
	retlw	h'00'		; 0033 spare
	retlw	h'00'		; 0034 spare
	retlw	h'00'		; 0035 spare
	retlw	h'00'		; 0036 spare
	retlw	h'00'		; 0037 spare
	retlw	h'00'		; 0038 spare
	retlw	h'00'		; 0039 spare
	retlw	h'00'		; 003a spare
	retlw	h'00'		; 003b spare
	retlw	h'00'		; 003c spare
	retlw	h'00'		; 003d spare
	retlw	h'00'		; 003e spare
	retlw	h'00'		; 003f spare

	retlw	h'00'		; 0040 spare
	retlw	h'00'		; 0041 spare
	retlw	h'00'		; 0042 spare
	retlw	h'00'		; 0043 spare
	retlw	h'00'		; 0044 spare
	retlw	h'00'		; 0045 spare
	retlw	h'00'		; 0046 spare
	retlw	h'00'		; 0047 spare
	retlw	h'00'		; 0048 spare
	retlw	h'00'		; 0049 spare
	retlw	h'00'		; 004a spare
	retlw	h'00'		; 004b spare
	retlw	h'00'		; 004c spare
	retlw	h'00'		; 004d spare
	retlw	h'00'		; 004e spare
	retlw	h'00'		; 004f spare

	;; cw id initial defaults
	retlw	h'05'		; 0050 CW ID 01 'N'
	retlw	h'10'		; 0051 CW ID 02 'H'
	retlw	h'0a'		; 0052 CW ID 03 'R'
	retlw	h'15'		; 0053 CW ID 04 'C'
	retlw	h'00'		; 0054 CW ID 05 ' '
	retlw	h'0a'		; 0055 CW ID 06 'r'
	retlw	h'02'		; 0056 CW ID 07 'e'
	retlw	h'07'		; 0057 CW ID 08 'm'
	retlw	h'0f'		; 0058 CW ID 09 'o'
	retlw	h'03'		; 0059 CW ID 10 't'
	retlw	h'02'		; 005a CW ID 11 'e'
	retlw	h'16'		; 005b CW ID 12 'p'
	retlw	h'12'		; 005c CW ID 13 'l'
	retlw	h'0c'		; 005d CW ID 14 'u'
	retlw	h'08'		; 005e CW ID 15 's'
	retlw	h'ff'		; 005f CW ID 16 eom

	;; control prefixes
	retlw	h'0e'		; 0060 control prefix 00  00
	retlw	h'00'		; 0061 control prefix 00  01
	retlw	h'ff'		; 0062 control prefix 00  02
	retlw	h'ff'		; 0063 control prefix 00  03
	retlw	h'ff'		; 0064 control prefix 00  04
	retlw	h'ff'		; 0065 control prefix 00  05
	retlw	h'ff'		; 0066 control prefix 00  06
	retlw	h'ff'		; 0067 control prefix 00  07
	retlw	h'01'		; 0068 control prefix 01  00
	retlw	h'01'		; 0069 control prefix 01  01
	retlw	h'ff'		; 006a control prefix 01  02
	retlw	h'ff'		; 006b control prefix 01  03
	retlw	h'ff'		; 006c control prefix 01  04
	retlw	h'ff'		; 006d control prefix 01  05
	retlw	h'ff'		; 006e control prefix 01  06
	retlw	h'ff'		; 006f control prefix 01  07

	retlw	h'01'		; 0070 control prefix 02  00
	retlw	h'00'		; 0071 control prefix 02  01
	retlw	h'ff'		; 0072 control prefix 02  02
	retlw	h'ff'		; 0073 control prefix 02  03
	retlw	h'ff'		; 0074 control prefix 02  04
	retlw	h'ff'		; 0075 control prefix 02  05
	retlw	h'ff'		; 0076 control prefix 02  06
	retlw	h'ff'		; 0077 control prefix 02  07
	retlw	h'02'		; 0078 control prefix 03  00
	retlw	h'01'		; 0079 control prefix 03  01
	retlw	h'ff'		; 007a control prefix 03  02
	retlw	h'ff'		; 007b control prefix 03  03
	retlw	h'ff'		; 007c control prefix 03  04
	retlw	h'ff'		; 007d control prefix 03  05
	retlw	h'ff'		; 007e control prefix 03  06
	retlw	h'ff'		; 007f control prefix 03  07


	org	h'0700'		; still in page 0
InitDaH
	bcf	temp,7		; clear hi bit
	movlw	high InitTbH	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	addwf	PCL,f		; add w to PCL
InitTbH
	retlw	h'02'		; 0080 control prefix 04  00
	retlw	h'00'		; 0081 control prefix 04  01
	retlw	h'ff'		; 0082 control prefix 04  02
	retlw	h'ff'		; 0083 control prefix 04  03
	retlw	h'ff'		; 0084 control prefix 04  04
	retlw	h'ff'		; 0085 control prefix 04  05
	retlw	h'ff'		; 0086 control prefix 04  06
	retlw	h'ff'		; 0087 control prefix 04  07
	retlw	h'03'		; 0088 control prefix 05  00
	retlw	h'01'		; 0089 control prefix 05  01
	retlw	h'ff'		; 008a control prefix 05  02
	retlw	h'ff'		; 008b control prefix 05  03
	retlw	h'ff'		; 008c control prefix 05  04
	retlw	h'ff'		; 008d control prefix 05  05
	retlw	h'ff'		; 008e control prefix 05  06
	retlw	h'ff'		; 008f control prefix 05  07

	retlw	h'03'		; 0090 control prefix 06  00
	retlw	h'00'		; 0091 control prefix 06  01
	retlw	h'ff'		; 0092 control prefix 06  02
	retlw	h'ff'		; 0093 control prefix 06  03
	retlw	h'ff'		; 0094 control prefix 06  04
	retlw	h'ff'		; 0095 control prefix 06  05
	retlw	h'ff'		; 0096 control prefix 06  06
	retlw	h'ff'		; 0097 control prefix 06  07
	retlw	h'04'		; 0098 control prefix 07  00
	retlw	h'01'		; 0099 control prefix 07  01
	retlw	h'ff'		; 009a control prefix 07  02
	retlw	h'ff'		; 009b control prefix 07  03
	retlw	h'ff'		; 009c control prefix 07  04
	retlw	h'ff'		; 009d control prefix 07  05
	retlw	h'ff'		; 009e control prefix 07  06
	retlw	h'ff'		; 009f control prefix 07  07

	retlw	h'04'		; 00a0 control prefix 08  00
	retlw	h'00'		; 00a1 control prefix 08  01
	retlw	h'ff'		; 00a2 control prefix 08  02
	retlw	h'ff'		; 00a3 control prefix 08  03
	retlw	h'ff'		; 00a4 control prefix 08  04
	retlw	h'ff'		; 00a5 control prefix 08  05
	retlw	h'ff'		; 00a6 control prefix 08  06
	retlw	h'ff'		; 00a7 control prefix 08  07
	retlw	h'05'		; 00a8 control prefix 09  00
	retlw	h'01'		; 00a9 control prefix 09  01
	retlw	h'ff'		; 00aa control prefix 09  02
	retlw	h'ff'		; 00ab control prefix 09  03
	retlw	h'ff'		; 009c control prefix 09  04
	retlw	h'ff'		; 00ad control prefix 09  05
	retlw	h'ff'		; 00ae control prefix 09  06
	retlw	h'ff'		; 00af control prefix 09  07

	retlw	h'05'		; 00b0 control prefix 10  00
	retlw	h'00'		; 00b1 control prefix 10  01
	retlw	h'ff'		; 00b2 control prefix 10  02
	retlw	h'ff'		; 00b3 control prefix 10  03
	retlw	h'ff'		; 00b4 control prefix 10  04
	retlw	h'ff'		; 00b5 control prefix 10  05
	retlw	h'ff'		; 00b6 control prefix 10  06
	retlw	h'ff'		; 00b7 control prefix 10  07
	retlw	h'06'		; 00b8 control prefix 11  00
	retlw	h'01'		; 00b9 control prefix 11  01
	retlw	h'ff'		; 00ba control prefix 11  02
	retlw	h'ff'		; 00bb control prefix 11  03
	retlw	h'ff'		; 00bc control prefix 11  04
	retlw	h'ff'		; 00bd control prefix 11  05
	retlw	h'ff'		; 00be control prefix 11  06
	retlw	h'ff'		; 00bf control prefix 11  07

	retlw	h'06'		; 00c0 control prefix 12  00
	retlw	h'00'		; 00c1 control prefix 12  01
	retlw	h'ff'		; 00c2 control prefix 12  02
	retlw	h'ff'		; 00c3 control prefix 12  03
	retlw	h'ff'		; 00c4 control prefix 12  04
	retlw	h'ff'		; 00c5 control prefix 12  05
	retlw	h'ff'		; 00c6 control prefix 12  06
	retlw	h'ff'		; 00c7 control prefix 12  07
	retlw	h'07'		; 00c8 control prefix 13  00
	retlw	h'01'		; 00c9 control prefix 13  01
	retlw	h'ff'		; 00ca control prefix 13  02
	retlw	h'ff'		; 00cb control prefix 13  03
	retlw	h'ff'		; 00cc control prefix 13  04
	retlw	h'ff'		; 00cd control prefix 13  05
	retlw	h'ff'		; 00ce control prefix 13  06
	retlw	h'ff'		; 00df control prefix 13  07

	retlw	h'07'		; 00d0 control prefix 14  00
	retlw	h'00'		; 00d1 control prefix 14  01
	retlw	h'ff'		; 00d2 control prefix 14  02
	retlw	h'ff'		; 00d3 control prefix 14  03
	retlw	h'ff'		; 00d4 control prefix 14  04
	retlw	h'ff'		; 00d5 control prefix 14  05
	retlw	h'ff'		; 00d6 control prefix 14  06
	retlw	h'ff'		; 00d7 control prefix 14  07
	retlw	h'08'		; 00d8 control prefix 15  00
	retlw	h'01'		; 00d9 control prefix 15  01
	retlw	h'ff'		; 00da control prefix 15  02
	retlw	h'ff'		; 00db control prefix 15  03
	retlw	h'ff'		; 00dc control prefix 15  04
	retlw	h'ff'		; 00dd control prefix 15  05
	retlw	h'ff'		; 00de control prefix 15  06
	retlw	h'ff'		; 00df control prefix 15  07

	retlw	h'08'		; 00e0 control prefix 16  00
	retlw	h'00'		; 00e1 control prefix 16  01
	retlw	h'ff'		; 00e2 control prefix 16  02
	retlw	h'ff'		; 00e3 control prefix 16  03
	retlw	h'ff'		; 00e4 control prefix 16  04
	retlw	h'ff'		; 00e5 control prefix 16  05
	retlw	h'ff'		; 00e6 control prefix 16  06
	retlw	h'ff'		; 00e7 control prefix 16  07
	retlw	h'0e'		; 00e8 control prefix 17  00
	retlw	h'01'		; 00e9 control prefix 17  01
	retlw	h'ff'		; 00ea control prefix 17  02
	retlw	h'ff'		; 00eb control prefix 17  03
	retlw	h'ff'		; 00ec control prefix 17  04
	retlw	h'ff'		; 00ed control prefix 17  05
	retlw	h'ff'		; 00ee control prefix 17  06
	retlw	h'ff'		; 00ef control prefix 17  07

	retlw	h'0e'		; 00f0 control prefix 18  00
	retlw	h'02'		; 00f1 control prefix 18  01
	retlw	h'ff'		; 00f2 control prefix 18  02
	retlw	h'ff'		; 00f3 control prefix 18  03
	retlw	h'ff'		; 00f4 control prefix 18  04
	retlw	h'ff'		; 00f5 control prefix 18  05
	retlw	h'ff'		; 00f6 control prefix 18  06
	retlw	h'ff'		; 00f7 control prefix 18  07
	retlw	h'0e'		; 00f8 control prefix 19  00
	retlw	h'03'		; 00f9 control prefix 19  01
	retlw	h'ff'		; 00fa control prefix 19  02
	retlw	h'ff'		; 00fb control prefix 19  03
	retlw	h'ff'		; 00fc control prefix 19  04
	retlw	h'ff'		; 00fd control prefix 19  05
	retlw	h'ff'		; 00fe control prefix 19  06
	retlw	h'ff'		; 00ff control prefix 19  07


; ************************************************************************
; ****************************** ROM PAGE 1 ******************************
; ************************************************************************
	org	h'0800'		; page 1

LCmd
	movlw	high LTable	; set high byte of address
	movwf	PCLATH		; select page
	movf	temp,w		; get prefix index number.
	andlw	h'1f'		; restrict to reasonable range
	addwf	PCL,f		; add w to PCL

LTable				; jump table for locked commands.
	goto	LCmd0		; prefix 00 -- set/reset config bits
	goto	LCmd1		; prefix 01 -- Port 1 on
	goto	LCmd2		; prefix 02 -- Port 1 off
	goto	LCmd3		; prefix 03 -- Port 2 on
	goto	LCmd4		; prefix 04 -- Port 2 off
	goto	LCmd5		; prefix 05 -- Port 3 on
	goto	LCmd6		; prefix 06 -- Port 3 off
	goto	LCmd7		; prefix 07 -- Port 4 on
	goto	LCmd8		; prefix 08 -- Port 4 off
	goto	LCmd9		; prefix 09 -- Port 5 on
	goto	LCmd10		; prefix 10 -- Port 5 off
	goto	LCmd11		; prefix 11 -- Port 6 on
	goto	LCmd12		; prefix 12 -- Port 6 off
	goto	LCmd13		; prefix 13 -- Port 7 on
	goto	LCmd14		; prefix 14 -- Port 7 off
	goto	LCmd15		; prefix 15 -- Port 8 on
	goto	LCmd16		; prefix 16 -- Port 8 off
	goto	LCmd17		; prefix 17 -- program/play CW ID
	goto	LCmd18		; prefix 18 -- set timers
	goto	LCmd19		; prefix 19 -- program command prefixes
	;; the rest are hear because the computed goto allows 31 valid values and
	;; we don't want to jump ramdomly into the code below.
	goto	LCmdErr		; prefix 20 -- invalid.
	goto	LCmdErr		; prefix 21 -- invalid.
	goto	LCmdErr		; prefix 22 -- invalid.
	goto	LCmdErr		; prefix 23 -- invalid.
	goto	LCmdErr		; prefix 24 -- invalid.
	goto	LCmdErr		; prefix 25 -- invalid.
	goto	LCmdErr		; prefix 26 -- invalid.
	goto	LCmdErr		; prefix 27 -- invalid.
	goto	LCmdErr		; prefix 28 -- invalid.
	goto	LCmdErr		; prefix 29 -- invalid.
	goto	LCmdErr		; prefix 30 -- invalid.
	goto	LCmdErr		; prefix 31 -- invalid.

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
	sublw	MAXGRP		; w = MAXGRP-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; bad, bad user tried to enter invalid group.
	;; check access to change that group.
	movf	temp2,w		; get group number 0-7.
	call	GetMask		; get bitmask for that group.
	;; now have bit representing group number in w.
	incf	FSR,f		; move to next byte (bit #)
	decf	cmdSize,f	; decrement command size.
	movf	INDF,w		; get Item byte (bit #)
	movwf	temp		; save it.
	incf	FSR,f		; move to next byte (state)
	decf	cmdSize,f	; decrement command size.

	sublw	d'7'		; w = 7-w.
	btfss	STATUS,C	; skip if w is not negative
	return			; bad, bad user tried to enter invalid item.

	movf	temp,w		; get Item byte
	call	GetMask		; get bit mask for selected item
	movwf	temp		; save mask

	movf	cmdSize,f	; test this for zero (inquiry)
	btfsc	STATUS,Z	; skip if not 0.
	goto	CtlOpQ		; it's an inquiry.

	movf	INDF,w		; get state byte
	andlw	b'11111110'	; only 0 and 1 permitted.
	btfss	STATUS,Z	; should be zero of 0 or 1 entered
	goto	LCmdErr		; not zero, bad command.
	movf	INDF,f		; get state byte
	btfss	STATUS,Z	; skip if state is zero
	goto	CtlOp1		; not zero, must be 1, go do the set.
	;; clear a bit.
	movlw	low group0	; get address of 1st group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	xorlw	h'ff'		; invert mask to clear selected bit
	andwf	INDF,f		; apply inverted mask
	movf	INDF,w		; get new value
	movwf	temp3		; save it
	bsf	STATUS,IRP	; set indirect pointer into page 1

	;; save to eeprom
	movlw	EE0B		; base of control op settings
	addwf	temp2,w		; group number
	movwf	eeAddr
	movf	temp3,w
	call	WriteEw		; write byte to EEPROM.

	movlw	CW_OFF		; get CW OFF message
	call	PlayCW		; send the announcement.
	return			; done.

CtlOp1				; set a bit.
	movlw	low group0	; get address of ist group.
	movwf	FSR		; set FSR to point there.
	movf	temp2,w		; get group number
	addwf	FSR,f		; add to address.
	bcf	STATUS,IRP	; set indirect back to page 0
	movf	temp,w		; get mask
	iorwf	INDF,f		; or byte with mask.
	movf	INDF,w		; get new value
	movwf	temp3		; save it
	bsf	STATUS,IRP	; set indirect pointer into page 1

	;; save to eeprom
	movlw	EE0B		; base of control op settings
	addwf	temp2,w		; group number
	movwf	eeAddr
	movf	temp3,w
	call	WriteEw		; write byte to EEPROM.

	movlw	CW_ON		; get CW ON message.
	call	PlayCW		; send the announcement.
	return			; no.

CtlOpQ				; inquiry mode.
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


; ***********
; ** LCmd1 **
; ***********
LCmd1				; Port 1 on
	bsf	group2,0	; set bit 0 high
	goto	LCmdOn		; send ON message

; ***********
; ** LCmd2 **
; ***********
LCmd2				; Port 1 off
	bcf	group2,0	; set bit 0 low
	goto	LCmdOff		; send OFF message

; ***********
; ** LCmd3 **
; ***********
LCmd3				; Port 2 on
	bsf	group2,1	; set bit 1 high
	goto	LCmdOn		; send ON message

; ***********
; ** LCmd4 **
; ***********
LCmd4				; Port 2 off
	bcf	group2,1	; set bit 1 low
	goto	LCmdOff		; send OFF message

; ***********
; ** LCmd5 **
; ***********
LCmd5				; Port 3 on
	bsf	group2,2	; set bit 2 high
	goto	LCmdOn		; send ON message

; ***********
; ** LCmd6 **
; ***********
LCmd6				; Port 3 off
	bcf	group2,2	; set bit 2 low
	goto	LCmdOff		; send OFF message

; ***********
; ** LCmd7 **
; ***********
LCmd7				; Port 4 on
	bsf	group2,3	; set bit 3 high
	goto	LCmdOn		; send ON message

; ***********
; ** LCmd8 **
; ***********
LCmd8				; Port 4 off
	bcf	group2,3	; set bit 3 low
	goto	LCmdOff		; send OFF message

; ***********
; ** LCmd9 **
; ***********
LCmd9				; Port 5 on
	bsf	group2,4	; set bit 4 high
	goto	LCmdOn		; send ON message

; ************
; ** LCmd10 **
; ************
LCmd10				; Port 5 off
	bcf	group2,4	; set bit 4 low
	goto	LCmdOff		; send OFF message

; ************
; ** LCmd11 **
; ************
LCmd11				; Port 6 on
	bsf	group2,5	; set bit 5 high
	goto	LCmdOn		; send ON message

; ************
; ** LCmd12 **
; ************
LCmd12				; Port 6 off
	bcf	group2,5	; set bit 5 low
	goto	LCmdOff		; send OFF message

; ************
; ** LCmd13 **
; ************
LCmd13				; Port 7 on
	bsf	group2,6	; set bit 6 high
	goto	LCmdOn		; send ON message

; ************
; ** LCmd14 **
; ************
LCmd14				; Port 7 off
	bcf	group2,6	; set bit 6 low
	goto	LCmdOff		; send OFF message

; ************
; ** LCmd15 **
; ************
LCmd15				; Port 8 on
	bsf	group2,7	; set bit 7 high
	goto	LCmdOn		; send ON message

; ************
; ** LCmd16 **
; ************
LCmd16				; Port 8 off
	bcf	group2,7	; set bit 7 low
	goto	LCmdOff		; send OFF message

; ************
; ** LCmd17 **
; ************
LCmd17				; play/program CW ID
	movf	cmdSize,f	; check command size
	btfsc	STATUS,Z	; is it zero?
	goto	LCmd17P		; yes.	Play CW ID.
	;; record CW ID
	btfsc	cmdSize,0	; bit 0 should be clear for an even length.
	goto	LCmdErr		; not even number of digits

	movlw	low eebuf00	; get address of eebuffer.
	movwf	eebPtr		; set eeprom buffer put pointer
	clrf	eeCount		; clear count.
LC17RL
	call	GetCTen		; get 2-digit argument.
	call	GetCW		; get CW code.
	call	PutEEB		; put into EEPROM write buffer.
	movf	cmdSize,f	; test cmdSize
	btfss	STATUS,Z	; skip if it's zero.
	goto	LC17RL		; loop around.

	movlw	h'ff'		; mark EOM.
	call	PutEEB		; put into EEPROM write buffer.
	movlw	EECWID		; get CW ID address...
	movwf	eeAddr		; set EEPROM address...
	movlw	low eebuf00	; get address of eebuffer.
	movwf	FSR		; set address to write into EEPROM.
	call	WriteEE
	goto	LCmdOK		; done.	 send OK message.

LCmd17P				; play CW ID
	movlw	EECWID		; address of CW ID message in EEPROM.
	movwf	eeAddr		; save CT base address
	call	PlayCWe		; kick off the CW playback.
	return

; ************
; ** LCmd18 **
; ************
LCmd18				; set timer / other value
	movlw	d'2'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 2)
	goto	LCmdErr		; not enough command digits.

	movf	INDF,w		; get timer index ones digit (there are less then 10!)
	movwf	temp2		; save timer index
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrement count of remaining bytes.

	movf	temp2,w		; get timer index
	sublw	LASTTMR		; subtract last timer index
	btfss	STATUS,C	; skip if result is non-negative
	goto	LCmdErr		; argument error
	movf	temp2,w		; get timer index
	sublw	EELATCH		; subtract the latch index
	btfss	STATUS,Z	; is this the latch index?
	goto	LCmd18A		; nope.
	movlw	EE0B		; base of set 0
	addlw	d'2'		; offset of group2
	movwf	eeAddr		; set EEPROM address low byte
	call	GetDNum		; get decimal number to w. nukes temp3,temp4
	movwf	temp4		; save decimal number to temp4.
	movwf	PORTB		; save to the latch
	movwf	group2		; save it to the internal copy
	call	WriteEw		; write w into EEPROM.
	goto	LCmdOK		; good command.

LCmd18A
	movf	temp2,w		; get timer index
	movwf	eeAddr		; set EEPROM address low byte
	movf	cmdSize,f	; check for no more digits.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdErr		; no more digits -- bad command.
	;; ready to get value then set timer.
	call	GetDNum		; get decimal number to w. nukes temp3,temp4
	movwf	temp4		; save decimal number to temp4.
	call	WriteEw		; write w into EEPROM.
	movf	temp2,w		; get timer index
	sublw	EEPTID		; compare with ID timer offset
	btfss	STATUS,Z	; is result zero?
	goto	LCmdOK		; yes
	movf	temp4,w		; get timer value.
	movwf	pulsTim		; save the pulse timer.
	goto	LCmdOK		; good command.

; ************
; ** LCmd19 **
; ************
LCmd19				; program command prefix
	movlw	d'3'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	LCmdErr		; not enough command digits.
	movf	cmdSize,w	; get command size
	sublw	d'10'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 10)
	goto	LCmdErr		; too many command digits.

	call	GetTens		; get index tens digit.
	movwf	temp		; save to prefix index in temp.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	INDF,w		; get index ones digit.
	addwf	temp,f		; add to prefix index in temp.
	incf	FSR,f		; move pointer to next address.
	decf	cmdSize,f	; decrment count of remaining bytes.
	movf	temp,w		; get prefix index
	sublw	MAGIC		; w = MAGIC - pfxnum - test for MAGIC
	btfsc	STATUS,Z	; is the result zero?
	goto	PfxMagc		; yes, magic happens
	movf	temp,w		; no, get prefix index
	sublw	MAXPFX		; w = MAXPFX - pfxnum
	btfss	STATUS,C	; skip if result is non-negative (pfxnum <= MAXPFX)
	goto	LCmdErr		; argument error

	movf	temp,w		; get index back.
	sublw	MAXPFX		; subtract index of unlock command.
	btfss	STATUS,Z	; is result zero?
	goto	PfxProg		; no.

	bsf	STATUS,RP0	; select register page 1
	movlw	b'00011111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select register page 0

	nop			; time to settle down.
	btfsc	PORTA,INITBIT	; skip if init button pressed.
	goto	PfxSec		; bad command.
	goto	PfxSec1		; init pressed.

PfxSec				;
	bsf	STATUS,RP0	; select register page 1
	movlw	b'00001111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select register page 0
	goto	LCmdErr		; bad command.

PfxSec1				; this is ugly. sorry.
	bsf	STATUS,RP0	; select register page 1
	movlw	b'00001111'	; low 5 bits are input
	movwf	TRISA		; set port a as outputs
	bcf	STATUS,RP0	; select register page 0

PfxProg				; program the new prefix.
	movf	cmdSize,w	; get command length
	movwf	eeCount		; save # bytes to write.
	sublw	d'8'		; check for length of 8
	btfss	STATUS,Z	; is it zero?
	incf	eeCount,f	; No.  add 1 so FF at end of buffer gets copied.
	movlw	low EEPFB	; get low address of prefixes
	movwf	eeAddr		; set eeprom address to base of prefixes
	bcf	STATUS,C	; clear carry
	rlf	temp,f		; multiply prefix by 2
	rlf	temp,f		; multiply prefix by 2 (x4 after)
	rlf	temp,f		; multiply prefix by 2 (x8 after)
	movf	temp,w		; get prefix offset
	addwf	eeAddr,f	; add prefix to base
	call	WriteEE		; write the prefix.
	goto	LCmdOK		; good command...

PfxMagc				; process magic set prefix command.
	movf	cmdSize,w	; get command size
	sublw	d'6'		; get max magic prefix length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 6)
	goto	LCmdErr		; too many command digits.
	movf	cmdSize,w	; get command size
	movwf	temp3		; save it.

	;; now set the univeral prefix into the write buffer.
	movlw	low eebuf00	; get address of eebuffer.
	movwf	eebPtr		; set eeprom buffer put pointer
	clrf	eeCount		; clear count.
PfxMc1
	movf	INDF,w		; get command digit
	call	PutEEB		; put into the EEPROM buffer
	incf	FSR,f		; move pointer to next address
	decf	cmdSize,f	; decrement count of remaining bytes.
	movf	cmdSize,f	; test cmdSize
	btfss	STATUS,Z	; skip if it's zero.
	goto	PfxMc1		; loop around.
	;; now have the prefix set up
	movlw	d'1'		; first prefix to write
	movwf	temp4		; prefix number
	movwf	temp2		; port number
PfxMLp				;
	movlw	low eebuf00	; get address of eebuffer.
	addwf	temp3,w		; add size of prefix
	movwf	eebPtr		; set eeprom buffer put pointer
	movf	temp3,w		; get length
	movwf	eeCount		; set length
	movf	temp2,w		; get port number
	call	PutEEB		; put into the EEPROM buffer
	movlw	d'1'		; on command
	call	PutEEB		; put into the EEPROM buffer
	call	PgmPfx		; program that prefix.

	incf	temp4,f		; increment prefix number
	movlw	low eebuf00	; get address of eebuffer.
	addwf	temp3,w		; add size of prefix
	movwf	eebPtr		; set eeprom buffer put pointer
	movf	temp3,w		; get length
	movwf	eeCount		; set length
	movf	temp2,w		; get port number
	call	PutEEB		; put into the EEPROM buffer
	movlw	d'0'		; off command
	call	PutEEB		; put into the EEPROM buffer
	call	PgmPfx		; program that prefix.
	incf	temp4,f		; increment prefix number

	incf	temp2,f		; increment the port number
	movlw	d'9'		; highest port number + 1
	subwf	temp2,w		; last port number
	btfss	STATUS,C	; is it negative?
	goto	PfxMLp		; nope.	 do the next one.

	goto	LCmdOK		; good command...

PgmPfx
	movlw	low EEPFB	; get low address of prefixes
	movwf	eeAddr		; set eeprom address to base of prefixes
	bcf	STATUS,C	; clear carry
	movf	temp4,w		; get prefix number
	movwf	temp		; save prefix number
	rlf	temp,f		; multiply prefix by 2
	rlf	temp,f		; multiply prefix by 2 (x4 after)
	rlf	temp,f		; multiply prefix by 2 (x8 after)
	movf	temp,w		; get prefix offset
	addwf	eeAddr,f	; add prefix to base	
	movlw	low eebuf00	; get address of eebuffer.
	movwf	FSR		; set address to write into EEPROM.
	call	WriteEE		; write the prefix.
	return

; *************
; ** LCmdErr **
; *************
LCmdErr
	movlw	CW_NG		; get CW OK
	call	PlayCW		; start playback
	return

; ************
; ** LCmdOK **
; ************
LCmdOK
	movlw	CW_OK		; get CW OK
	call	PlayCW		; start playback
	return

; ************
; ** LCmdOn **
; ************
LCmdOn
	movf	group2,w	; get the group 2 register
	movwf	PORTB		; write it to the port
	btfss	group0,7	; check for tone telemetry mode
	goto	LCOn1A		; nope
	movlw	BPLOHI		; get low-high beep
	call	PlayCTx		; play courtesy tone #w
	goto	LCOn1B

LCOn1A
	movlw	CW_ON		; get CW ON
	call	PlayCW		; start playback

LCOn1B
	movf	group2,w	; get group 2
	andwf	group1,w	; and with pulse control
	btfsc	STATUS,Z	; are any outputs set for pulsed mode?
	goto	SaveIt		; nope
	movf	pulsTim,w	; get pulse duration time value.
	movwf	pulsTmr		; set pulse timer.
	return

; *************
; ** LCmdOff **
; *************
LCmdOff
	movf	group2,w	; get the group 2 register
	movwf	PORTB		; write it to the port

	btfss	group0,7	; check for tone telemetry mode
	goto	LCOff1A		; nope
	movlw	BPHILO		; get high-low beep
	call	PlayCTx		; play courtesy tone #w
	goto	LCOff1B

LCOff1A
	movlw	CW_OFF		; get CW OFF
	call	PlayCW		; start playback

LCOff1B

SaveIt
	movlw	EE0B		; base of control op settings
	addlw	d'2'		; group 2
	movwf	eeAddr
	movf	group2,w
	call	WriteEw		; write byte to EEPROM.
	return

	org	h'0a00'		; still in page 1

; ************
; ** CtlOpC **
; ************
CtlOpC
; ************
; ** PlayCW **
; ************
	;; play CW from ROM table.	Address in W.
PlayCW
	movwf	temp		; save CW address.
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
	bsf	PORTA,PTT	; apply PTT!
	bsf	flags,TXONFLG	; set last tx state flag
	movf	idTmr,f		; check ID timer
	btfsc	STATUS,Z	; is it zero?
	goto	PTTinit		; yes
	btfss	flags,needID	; is needID set?
	goto	PTTset		; not set, set needID and reset idTmr
PTTinit
	bsf	flags,initID	; ID timer was zero, set initial ID flag
PTTset
	bsf	flags,needID	; need to play ID
	movlw	EETID		; get address of ID timer
	movwf	eeAddr		; set address of ID timer
	call	ReadEEw		; get byte from EEPROM
	movwf	idTmr		; store to down-counter
	return			; done here

; *************
; ** PTT0Off **
; *************
PTT0Off
	bcf	PORTA,PTT	; turn off main PTT!
	bcf	flags,TXONFLG	; clear last tx state flag
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
	movlw	EE0B		; yes, get address of set zero.
	movwf	eeAddr		; save address
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

	org	h'0c00'		; still in page 1

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
	retlw	h'ff'		; OFF	-- 00
	retlw	h'01'		; F4	-- 01
	retlw	h'b9'		; F#4	-- 02
	retlw	h'75'		; G4	-- 03
	retlw	h'35'		; G#4	-- 04
	retlw	h'f8'		; A4	-- 05
	retlw	h'bf'		; A#4	-- 06
	retlw	h'89'		; B4	-- 07
	retlw	h'57'		; C5	-- 08
	retlw	h'27'		; C#5	-- 09
	retlw	h'f9'		; D5	-- 0a
	retlw	h'ce'		; D#5	-- 0b
	retlw	h'a6'		; E5	-- 0c
	retlw	h'80'		; F5	-- 0d
	retlw	h'5c'		; F#5	-- 0e
	retlw	h'3a'		; G5	-- 0f
	retlw	h'1a'		; G#5	-- 10
	retlw	h'fc'		; A5	-- 11
	retlw	h'df'		; A#	-- 12
	retlw	h'c4'		; B5	-- 13
	retlw	h'ab'		; C6	-- 14
	retlw	h'93'		; C#6	-- 15
	retlw	h'7c'		; D6	-- 16
	retlw	h'67'		; D#6	-- 17
	retlw	h'53'		; E6	-- 18
	retlw	h'40'		; F6	-- 19
	retlw	h'2e'		; F#6	-- 1a
	retlw	h'1d'		; G6	-- 1b
	retlw	h'0d'		; G#6	-- 1c
	retlw	h'fe'		; A6	-- 1d
	retlw	h'ef'		; A#6	-- 1e
	retlw	h'e2'		; B6	-- 1f

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
	retlw	h'05'		; F4	-- 01
	retlw	h'04'		; F#4 -- 02
	retlw	h'04'		; G4	-- 03
	retlw	h'04'		; G#4 -- 04
	retlw	h'03'		; A4	-- 05
	retlw	h'03'		; A#4 -- 06
	retlw	h'03'		; B4	-- 07
	retlw	h'03'		; C5	-- 08
	retlw	h'03'		; C#5 -- 09
	retlw	h'02'		; D5	-- 0a
	retlw	h'02'		; D#5 -- 0b
	retlw	h'02'		; E5	-- 0c
	retlw	h'02'		; F5	-- 0d
	retlw	h'02'		; F#5 -- 0e
	retlw	h'02'		; G5	-- 0f
	retlw	h'02'		; G#5 -- 10
	retlw	h'01'		; A5	-- 11
	retlw	h'01'		; A#	-- 12
	retlw	h'01'		; B5	-- 13
	retlw	h'01'		; C6	-- 14
	retlw	h'01'		; C#6 -- 15
	retlw	h'01'		; D6	-- 16
	retlw	h'01'		; D#6 -- 17
	retlw	h'01'		; E6	-- 18
	retlw	h'01'		; F6	-- 19
	retlw	h'01'		; F#6 -- 1a
	retlw	h'01'		; G6	-- 1b
	retlw	h'01'		; G#6 -- 1c
	retlw	h'00'		; A6	-- 1d
	retlw	h'00'		; A#6 -- 1e
	retlw	h'00'		; B6	-- 1f


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
	retlw	h'0a'		; 'R'	-- 0f
	retlw	h'11'		; 'B'	-- 10
	retlw	h'ff'		; EOM	-- 11
	retlw	h'0f'		; 'O'	-- 12
	retlw	h'05'		; 'N'	-- 13
	retlw	h'ff'		; EOM	-- 14
	retlw	h'0f'		; 'O'	-- 15
	retlw	h'14'		; 'F'	-- 16
	retlw	h'14'		; 'F'	-- 17
	retlw	h'ff'		; EOM	-- 18
	;; beep low high
	retlw	d'25'		; 19 250 ms
	retlw	h'81'		; 1a F4
	retlw	d'25'		; 1b 250 ms
	retlw	h'80'		; 1c silence
	retlw	d'25'		; 1d 250 ms
	retlw	h'19'		; 1e F5
	;; beep high low
	retlw	d'25'		; 1f 250 ms
	retlw	h'99'		; 20 F6
	retlw	d'25'		; 21 250 ms
	retlw	h'80'		; 22 silence
	retlw	d'25'		; 23 250 ms
	retlw	h'01'		; 24 F4
	retlw	d'100'		; 25
	retlw	h'1f'		; 26
	retlw	d'00'		; 27
	retlw	h'00'		; 28
	retlw	d'00'		; 29
	retlw	h'00'		; 2a
	retlw	d'00'		; 2b
	retlw	h'00'		; 2c
	retlw	d'00'		; 2d
	retlw	h'00'		; 2e
	retlw	h'00'		; 2f

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
	andlw	h'3f'		; mask
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

	;; jeff

	org	h'0f00'		; reserved for ICD

	IF LOAD_EE == 1
	org	h'2100'
	de	d'54'		; 0000 ID timer 9.0 min
	de	d'100'		; 0001 pulse duration timer
	de	d'0'		; 0002 spare
	de	d'0'		; 0003 spare
	de	d'0'		; 0004 spare
	de	d'0'		; 0005 spare
	de	d'0'		; 0006 spare
	de	d'0'		; 0007 spare
	de	d'0'		; 0008 spare
	de	d'0'		; 0009 spare
	de	d'0'		; 000a spare
	de	d'0'		; 000b spare
	de	d'0'		; 000c spare
	de	d'0'		; 000d spare
	de	d'0'		; 000e spare
	de	d'0'		; 000f spare

	;; control operator switches, set 0
	de	b'00000000'	; 0010 control operator switches, group 0
	de	b'00000000'	; 0011 control operator switches, group 1
	de	b'00000000'	; 0012 control operator switches, group 2
	de	h'00'		; 0013 spare
	de	h'00'		; 0014 spare
	de	h'00'		; 0015 spare
	de	h'00'		; 0016 spare
	de	h'00'		; 0017 spare
	de	h'00'		; 0018 spare
	de	h'00'		; 0019 spare
	de	h'00'		; 001a spare
	de	h'00'		; 001b spare
	de	h'00'		; 001c spare
	de	h'00'		; 001d spare
	de	h'00'		; 001e spare
	de	h'00'		; 001f spare

	;;  empty from 0x20 to 0x4f
	de	h'00'		; 0020 spare
	de	h'00'		; 0021 spare
	de	h'00'		; 0022 spare
	de	h'00'		; 0023 spare
	de	h'00'		; 0024 spare
	de	h'00'		; 0025 spare
	de	h'00'		; 0026 spare
	de	h'00'		; 0027 spare
	de	h'00'		; 0028 spare
	de	h'00'		; 0029 spare
	de	h'00'		; 002a spare
	de	h'00'		; 002b spare
	de	h'00'		; 002c spare
	de	h'00'		; 002d spare
	de	h'00'		; 002e spare
	de	h'00'		; 002f spare

	de	h'00'		; 0030 spare
	de	h'00'		; 0031 spare
	de	h'00'		; 0032 spare
	de	h'00'		; 0033 spare
	de	h'00'		; 0034 spare
	de	h'00'		; 0035 spare
	de	h'00'		; 0036 spare
	de	h'00'		; 0037 spare
	de	h'00'		; 0038 spare
	de	h'00'		; 0039 spare
	de	h'00'		; 003a spare
	de	h'00'		; 003b spare
	de	h'00'		; 003c spare
	de	h'00'		; 003d spare
	de	h'00'		; 003e spare
	de	h'00'		; 003f spare

	de	h'00'		; 0040 spare
	de	h'00'		; 0041 spare
	de	h'00'		; 0042 spare
	de	h'00'		; 0043 spare
	de	h'00'		; 0044 spare
	de	h'00'		; 0045 spare
	de	h'00'		; 0046 spare
	de	h'00'		; 0047 spare
	de	h'00'		; 0048 spare
	de	h'00'		; 0049 spare
	de	h'00'		; 004a spare
	de	h'00'		; 004b spare
	de	h'00'		; 004c spare
	de	h'00'		; 004d spare
	de	h'00'		; 004e spare
	de	h'00'		; 004f spare

	;; cw id initial defaults
	de	h'05'		; 0050 CW ID	1 'n'
	de	h'10'		; 0051 CW ID	2 'h'
	de	h'0a'		; 0052 CW ID	3 'r'
	de	h'15'		; 0053 CW ID	4 'c'
	de	h'00'		; 0054 CW ID	5 ' '
	de	h'0a'		; 0055 CW ID	6 'r'
	de	h'02'		; 0056 CW ID	7 'e'
	de	h'07'		; 0057 CW ID	8 'm'
	de	h'0f'		; 0058 CW ID	9 'o'
	de	h'03'		; 0059 CW ID   10 't'
	de	h'02'		; 005a CW ID   11 'e'
	de	h'16'		; 005b CW ID   12 'p'
	de	h'12'		; 005c CW ID   13 'l'
	de	h'0c'		; 005d CW ID   14 'u'
	de	h'08'		; 005e CW ID   15 's'
	de	h'ff'		; 005f CW ID   16 eom

	;; control prefixes
	de	h'0e'		; 0060 control prefix 00  00
	de	h'00'		; 0061 control prefix 00  01
	de	h'ff'		; 0062 control prefix 00  02
	de	h'ff'		; 0063 control prefix 00  03
	de	h'ff'		; 0064 control prefix 00  04
	de	h'ff'		; 0065 control prefix 00  05
	de	h'ff'		; 0066 control prefix 00  06
	de	h'ff'		; 0067 control prefix 00  07
	de	h'01'		; 0068 control prefix 01  00
	de	h'01'		; 0069 control prefix 01  01
	de	h'ff'		; 006a control prefix 01  02
	de	h'ff'		; 006b control prefix 01  03
	de	h'ff'		; 006c control prefix 01  04
	de	h'ff'		; 006d control prefix 01  05
	de	h'ff'		; 006e control prefix 01  06
	de	h'ff'		; 006f control prefix 01  07

	de	h'01'		; 0070 control prefix 02  00
	de	h'00'		; 0071 control prefix 02  01
	de	h'ff'		; 0072 control prefix 02  02
	de	h'ff'		; 0073 control prefix 02  03
	de	h'ff'		; 0074 control prefix 02  04
	de	h'ff'		; 0075 control prefix 02  05
	de	h'ff'		; 0076 control prefix 02  06
	de	h'ff'		; 0077 control prefix 02  07
	de	h'02'		; 0078 control prefix 03  00
	de	h'01'		; 0079 control prefix 03  01
	de	h'ff'		; 007a control prefix 03  02
	de	h'ff'		; 007b control prefix 03  03
	de	h'ff'		; 007c control prefix 03  04
	de	h'ff'		; 007d control prefix 03  05
	de	h'ff'		; 007e control prefix 03  06
	de	h'ff'		; 007f control prefix 03  07

	de	h'02'		; 0080 control prefix 04  00
	de	h'00'		; 0081 control prefix 04  01
	de	h'ff'		; 0082 control prefix 04  02
	de	h'ff'		; 0083 control prefix 04  03
	de	h'ff'		; 0084 control prefix 04  04
	de	h'ff'		; 0085 control prefix 04  05
	de	h'ff'		; 0086 control prefix 04  06
	de	h'ff'		; 0087 control prefix 04  07
	de	h'03'		; 0088 control prefix 05  00
	de	h'01'		; 0089 control prefix 05  01
	de	h'ff'		; 008a control prefix 05  02
	de	h'ff'		; 008b control prefix 05  03
	de	h'ff'		; 008c control prefix 05  04
	de	h'ff'		; 008d control prefix 05  05
	de	h'ff'		; 008e control prefix 05  06
	de	h'ff'		; 008f control prefix 05  07

	de	h'03'		; 0090 control prefix 06  00
	de	h'00'		; 0091 control prefix 06  01
	de	h'ff'		; 0092 control prefix 06  02
	de	h'ff'		; 0093 control prefix 06  03
	de	h'ff'		; 0094 control prefix 06  04
	de	h'ff'		; 0095 control prefix 06  05
	de	h'ff'		; 0096 control prefix 06  06
	de	h'ff'		; 0097 control prefix 06  07
	de	h'04'		; 0098 control prefix 07  00
	de	h'01'		; 0099 control prefix 07  01
	de	h'ff'		; 009a control prefix 07  02
	de	h'ff'		; 009b control prefix 07  03
	de	h'ff'		; 009c control prefix 07  04
	de	h'ff'		; 009d control prefix 07  05
	de	h'ff'		; 009e control prefix 07  06
	de	h'ff'		; 009f control prefix 07  07

	de	h'04'		; 00a0 control prefix 08  00
	de	h'00'		; 00a1 control prefix 08  01
	de	h'ff'		; 00a2 control prefix 08  02
	de	h'ff'		; 00a3 control prefix 08  03
	de	h'ff'		; 00a4 control prefix 08  04
	de	h'ff'		; 00a5 control prefix 08  05
	de	h'ff'		; 00a6 control prefix 08  06
	de	h'ff'		; 00a7 control prefix 08  07
	de	h'05'		; 00a8 control prefix 09  00
	de	h'01'		; 00a9 control prefix 09  01
	de	h'ff'		; 00aa control prefix 09  02
	de	h'ff'		; 00ab control prefix 09  03
	de	h'ff'		; 00ac control prefix 09  04
	de	h'ff'		; 00ad control prefix 09  05
	de	h'ff'		; 00ae control prefix 09  06
	de	h'ff'		; 00af control prefix 09  07

	de	h'05'		; 00b0 control prefix 10  00
	de	h'00'		; 00b1 control prefix 10  01
	de	h'ff'		; 00b2 control prefix 10  02
	de	h'ff'		; 00b3 control prefix 10  03
	de	h'ff'		; 00b4 control prefix 10  04
	de	h'ff'		; 00b5 control prefix 10  05
	de	h'ff'		; 00b6 control prefix 10  06
	de	h'ff'		; 00b7 control prefix 10  07
	de	h'06'		; 00b8 control prefix 11  00
	de	h'01'		; 00b9 control prefix 11  01
	de	h'ff'		; 00ba control prefix 11  02
	de	h'ff'		; 00bb control prefix 11  03
	de	h'ff'		; 00bc control prefix 11  04
	de	h'ff'		; 00bd control prefix 11  05
	de	h'ff'		; 00be control prefix 11  06
	de	h'ff'		; 00bf control prefix 11  07

	de	h'06'		; 00c0 control prefix 12  00
	de	h'00'		; 00c1 control prefix 12  01
	de	h'ff'		; 00c2 control prefix 12  02
	de	h'ff'		; 00c3 control prefix 12  03
	de	h'ff'		; 00c4 control prefix 12  04
	de	h'ff'		; 00c5 control prefix 12  05
	de	h'ff'		; 00c6 control prefix 12  06
	de	h'ff'		; 00c7 control prefix 12  07
	de	h'07'		; 00c8 control prefix 13  00
	de	h'01'		; 00c9 control prefix 13  01
	de	h'ff'		; 00ca control prefix 13  02
	de	h'ff'		; 00cb control prefix 13  03
	de	h'ff'		; 00cc control prefix 13  04
	de	h'ff'		; 00cd control prefix 13  05
	de	h'ff'		; 00ce control prefix 13  06
	de	h'ff'		; 00cf control prefix 13  07

	de	h'07'		; 00d0 control prefix 14  00
	de	h'00'		; 00d1 control prefix 14  01
	de	h'ff'		; 00d2 control prefix 14  02
	de	h'ff'		; 00d3 control prefix 14  03
	de	h'ff'		; 00d4 control prefix 14  04
	de	h'ff'		; 00d5 control prefix 14  05
	de	h'ff'		; 00d6 control prefix 14  06
	de	h'ff'		; 00d7 control prefix 14  07
	de	h'08'		; 00d8 control prefix 15  00
	de	h'01'		; 00d9 control prefix 15  01
	de	h'ff'		; 00da control prefix 15  02
	de	h'ff'		; 00db control prefix 15  03
	de	h'ff'		; 00dc control prefix 15  04
	de	h'ff'		; 00dd control prefix 15  05
	de	h'ff'		; 00de control prefix 15  06
	de	h'ff'		; 00df control prefix 15  07

	de	h'08'		; 00e0 control prefix 16  00
	de	h'00'		; 00e1 control prefix 16  01
	de	h'ff'		; 00e2 control prefix 16  02
	de	h'ff'		; 00e3 control prefix 16  03
	de	h'ff'		; 00e4 control prefix 16  04
	de	h'ff'		; 00e5 control prefix 16  05
	de	h'ff'		; 00e6 control prefix 16  06
	de	h'ff'		; 00e7 control prefix 16  07
	de	h'0e'		; 00e8 control prefix 17  00
	de	h'01'		; 00e9 control prefix 17  01
	de	h'ff'		; 00ea control prefix 17  02
	de	h'ff'		; 00eb control prefix 17  03
	de	h'ff'		; 00ec control prefix 17  04
	de	h'ff'		; 00ed control prefix 17  05
	de	h'ff'		; 00ee control prefix 17  06
	de	h'ff'		; 00ef control prefix 17  07

	de	h'0e'		; 00f0 control prefix 18  00
	de	h'02'		; 00f1 control prefix 18  01
	de	h'ff'		; 00f2 control prefix 18  02
	de	h'ff'		; 00f3 control prefix 18  03
	de	h'ff'		; 00f4 control prefix 18  04
	de	h'ff'		; 00f5 control prefix 18  05
	de	h'ff'		; 00f6 control prefix 18  06
	de	h'ff'		; 00f7 control prefix 18  07
	de	h'0e'		; 00f8 control prefix 19  00
	de	h'03'		; 00f9 control prefix 19  01
	de	h'ff'		; 00fa control prefix 19  02
	de	h'ff'		; 00fb control prefix 19  03
	de	h'ff'		; 00fc control prefix 19  04
	de	h'ff'		; 00fd control prefix 19  05
	de	h'ff'		; 00fe control prefix 19  06
	de	h'ff'		; 00ff control prefix 19  07

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
