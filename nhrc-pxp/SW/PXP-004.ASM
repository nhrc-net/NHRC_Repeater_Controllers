	;; NHRC-PXP Phoenix X22C12 Programmer.
	;; Copyright 2000, 2001 NHRC LLC,
	;; as an unpublished proprietary work.
	;; All rights reserved.
	;; No part of this document may be used or reproduced by any means,
	;; for any purpose, without the expressed written consent of NHRC LLC.

	;; pxp-004 25 December 2000

        ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

	include "p16f876.inc"

	 __FUSES _PWRTE_ON & _HS_OSC & _LVP_OFF & _WRT_ENABLE_OFF & _CP_ALL
	
; *******************
; ** PAGING MACROS **
; *******************

PAGE0   macro			; select page 0
	bcf	PCLATH,3
	bcf	PCLATH,4
        endm

PAGE1   macro			; select page 1
	bsf	PCLATH,3
	bcf	PCLATH,4
        endm

PAGE2   macro			; select page 2
	bcf	PCLATH,3
	bsf	PCLATH,4
        endm

PAGE3   macro			; select page 3
	bsf	PCLATH,3
	bsf	PCLATH,4
        endm

; *************************
; ** IO Port Assignments **
; *************************

; PORTA
X22CS	equ	0		; output, X22C12 CS\
X22WE	equ	1		; output, X22C12 WE\
X22STR	equ	2		; output, X22C12 STORE\
X22RCL	equ	3		; output, X22C12 RECALL\
X22VCC	equ	4		; output, X22C12 POWER\
LED	equ	5		; output, status LED

; PORTB -- usually addressed as an entire byte.
X22A0	equ	0		; output, X22C12 A0
X22A1	equ	1		; output, X22C12 A1
X22A2	equ	2		; output, X22C12 A2
X22A3	equ	3		; output, X22C12 A3
X22A4	equ	4		; output, X22C12 A4
X22A5	equ	5		; output, X22C12 A5
X22A6	equ	6		; output, X22C12 A6
X22A7	equ	7		; output, X22C12 A7

; PORTC
X22IO1  equ     0               ; input/output, XC22C12 IO1
X22IO2  equ     1               ; input/output, XC22C12 IO2
X22IO3  equ     2               ; input/output, XC22C12 IO3
X22IO4  equ     3               ; input/output, XC22C12 IO4
PBWRITE	equ	4		; input, WRITE button.
PBREAD	equ	5		; input, READ button.
RS232TX	equ	6		; output, RS232 transmit.
RS232RX	equ	7		; input,  RS232 receive.

; *********************
; ** OTHER CONSTANTS **
; *********************

;tFlags				; timer flags	     
TICK	equ	0		; TICK indicator
ONEMS	equ	1		; 1 ms tick flag
TENMS	equ	2		; 10 ms tick flag
HUNDMS	equ	3		; 100 ms tick flag
ONESEC	equ	4		; 1 second tick flag
TENSEC	equ	5		; 10 second flag...
; niy	equ	6		; NIY
NEWCHAR	equ	7		; received a new char.

;bFlags				; buttonFlags
WLAST	equ	0		; write last
RLAST	equ	1		; read last
WNOW	equ	2		; write NOW.
RNOW	equ	3		; read NOW.

BDBC	equ	d'5'		; 50 ms button debounce.
RXTMOT	equ	d'50'		; 50 * 100 ms = 5.0 seconds, receive timeout.

; message numbers
M_NONE	equ	0		; no message
M_INIT	equ	1		; init message
M_MENU	equ	2		; menu message
M_BCKSM	equ	3		; bad checksum
M_TOERR	equ	4		; error
M_OK	equ	5		; ok
M_TXPR	equ	6		; transmit program
M_CKSM	equ	7		; checksum message

; receive state -- what to do with received characters

RXS_CMD	equ	0		; receive command state.
RXS_PGM	equ	1		; receive program data state.
RXS_CHK	equ	2		; receive checksum data state.
	
	IFDEF DEBUG
TEN	equ	D'4'		; decade counter.
	ELSE
TEN	equ	D'10'		; decade counter.
	ENDIF

T0PRE	equ	D'7'		; timer 0 preset for overflow in 250 counts.
	
; ***************
; ** VARIABLES **
; ***************
	cblock	h'20'		; 1st block of RAM at 20h-7fh (96 bytes here)
	;; interrupt pseudo-stack to save context during interrupt processing.
	s_copy			; saved STATUS
	p_copy			; saved PCLATH
	f_copy			; saved FSR
	;; internal timing generation.
	tFlags			; Timer Flags
	oneMsC			; one millisecond counter
	tenMsC			; ten milliseconds counter
	hundMsC			; hundred milliseconds counter
	thouMsC			; 1 second counter.
	bFlags			; buttons flag
	;; working storage, if you will.
	temp			; working storage. don't use in int handler.
	temp2			; more working storage
	temp3			; more working storage
	temp4			; more working storage
	txChar			; character to transmit.
	chksum			; checksum.
	rxTmo			; receive timeout.
	rxChar			; received char.
	rxState			; receive state.
	rxCsBc			; receive checksum byte counter.
	rxCksum			; receive checksum.
	dbRead			; read button debounce counter.
	dbWrite			; write button debounce counter.
	endc			; end of mem block.

	cblock	h'70'		; 16 bytes common in all banks
	pgmaddr			; 70 address of program data
	pgmdata			; 71 program data
	w_copy			; 72 saved W register for interrupt handler
	eeAddr			; 73 eeprom address
	msgNum			; 74 message number
	msgCnt			; 75 message counter
	endc

	cblock	h'120'		; 80 bytes 120h-16fh
	prgbuf1:64		; 120-15f 64 bytes of program data buffer
	endc

	cblock	h'1a0'		; 80 bytes 1a0h-1efh
	prgbuf2:64		; 1a0-1df 64 bytes of program data buffer
	endc

	
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
	btfsc	PIR1,RCIF	; is it a USART Receive interrupt?
	goto	URInt		; yes.
	btfsc	PIR1,TXIF	; is it a USART transmit interrupt?
	goto	UTInt		; yes.
	goto	IntExit		; no...

TimrInt
	movlw	T0PRE		; get timer 0 preset value
	movwf	TMR0		; preset timer 0
	bsf	tFlags,TICK	; set tick indicator flag

TimrDone			
	bcf	INTCON,T0IF	; clear RTCC int mask
	goto	IntExit		; done here.

URInt				; USART receiver interrupt.
	movf	RCREG,w		; get received char.
	movwf	rxChar		; save received char.
	bsf	tFlags,NEWCHAR	; got a new char.
	goto	IntExit		; done here.

UTInt				; USART transmitter interrupt.
	call	GetMsgC		; get a message character.
	movf	txChar,w	; get the character selected.
	btfsc	STATUS,Z	; is it zero?
	goto	UTIntD		; yes. buffer is empty.
	movwf	TXREG		; send char.
	goto	IntExit		; done here.
	
UTIntD				; no more chars to transmit.
	;; turn off the transmitter interrupt.
	bsf	STATUS,RP0	; select bank 1
	bcf	PIE1,TXIE	; turn off the transmitter interrupt.
	bcf	STATUS,RP0	; select bank 1
	clrf	msgCnt		; clear message count.
	bcf	PORTA,LED	; turn off busy LED
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

; *************
; ** GetMsgC **
; *************
	;; get a message character.
GetMsgC
	movlw	high MsgTbl	; set page 
	movwf	PCLATH		; select page
	movf	msgNum,w	; get message number
	andlw	h'07'		; there are only 8 valid states.
	addwf   PCL,f		; add w to PCL
MsgTbl
	goto	Msg0		; message 0 - no message
	goto	Msg1		; message 1 - init
	goto	Msg2		; message 2 - menu
	goto	Msg3		; message 3 - bad checksum
	goto	Msg4		; message 4 - error
	goto	Msg5		; message 5 - ok
	goto	Msg6		; message 6 - send program
	goto	Msg7		; message 7 - send checksum

Msg0				; no message here. sanity check.
	retlw	h'0'		; return 0, no message here, stop tx.
	
Msg1				; init message.
	PAGE3			; select code page 3
	call	InitMsg		; get a byte from the init message.
	PAGE0			; select code page 0
	goto	RetChar		; return the character
	
Msg2				; menu.
	PAGE3			; select code page 3
	call	MenuMsg		; get a byte from the init message.
	PAGE0			; select code page 0
	goto	RetChar		; return the character

Msg3				; checksum error message.
	PAGE3			; select code page 3
	call	BadCMsg		; get a byte from the init message.
	PAGE0			; select code page 0
	goto	RetChar		; return the character
	
Msg4 				; error message.
	PAGE3			; select code page 3
	call	ErrMsg		; get a byte from the init message.
	PAGE0			; select code page 0
	goto	RetChar		; return the character

Msg5				; ok message.
	PAGE3			; select code page 3
	call	OkMsg		; get a byte from the init message.
	PAGE0			; select code page 0
	goto	RetChar		; return the character

Msg6				; send program.
	movf	msgCnt,w	; get message count.
	movwf	pgmaddr		; save program address.
	PAGE2			; select code page 2.
	call	GetNib		; get the nibble from the RAM buffer
	PAGE0			; select code page 0.
	addwf	chksum,f	; add to checksum
	call	b2a		; convert binary nibble to hex digit.
	movwf	txChar		; save transmit character
	incfsz	msgCnt,f	; increment message counter
	return			; done here.
	movlw	M_CKSM		; get checksum message number
	movwf	msgNum		; save message number
	return			; done here.
	
Msg7				; send checksum.
	btfsc	msgCnt,0	; is this byte 1?
	goto	Msg7_1		; yes.
	swapf	chksum,w	; get checksum, swapped.
	andlw	h'0f'		; mask to get low nibble.
	call	b2a		; convert binary nibble to hex digit.
	movwf	txChar		; save transmit character
	incf	msgCnt,f	; increment message counter.
	return
Msg7_1				; send 2nd byte (low nibble)
	movf	chksum,w	; get checksum, swapped.
	andlw	h'0f'		; mask to get low nibble.
	call	b2a		; convert binary nibble to hex digit.
	movwf	txChar		; save transmit character
	clrf	msgCnt		; clear message count
	movlw	M_OK		; get OK message number
	movwf	msgNum		; save message number
	return			; done here.
	
RetChar				; return the character
	movwf	txChar		; save transmit character
	incf	msgCnt,f	; increment message counter
	return			; return the fetched char.

XmitMsg
	movwf	msgNum		; save message number
	clrf	msgCnt		; reset message counter
XmitM1				; 
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; test interrupts still enabled?
	goto	XmitM1		; still enabled, retry disable.
	bsf	STATUS,RP0	; select bank 1
	bsf	PIE1,TXIE	; turn on the transmitter interrupt.
	bcf	STATUS,RP0	; select bank 0
	;; last, turn interrupts back on so character gets sent.
	bsf	INTCON,GIE	; turn interrupts on.
	return	
			
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
	
	movlw	B'11000000'	; na/na/out/out/out/out/out/out
	movwf	TRISA		; set port A data direction

	movlw	B'00000000'	; out/out/out/out/out/out/out/out
	movwf	TRISB		; set port B data direction

	movlw	B'10111111'	; SCI/SCI/in/in/in/in/in/in
				; in  out in  in  in  in  in  in 
	movwf	TRISC		; set port C data direction

	movlw	b'10000011'	; RBPU\ no pull up, 
				; INTEDG INT on falling edge
				; T0CS	 TMR0 uses instruction clock
				; T0SE	n/a
				; PSA TMR0 gets the prescaler 
				; PS2 \
				; PS1  > prescaler 16
				; PS0 /
	movwf	OPTION_REG	; set options
	
	movlw	d'103'		; 9600 baud at 16.0 MHz clock.
	movwf	SPBRG		; set baud rate generator.
	movlw	b'00100100'	; transmit enabled, hi speed async.
	movwf	TXSTA		; set transmit status and control register.
	movlw	b'00100000'	; USART rx interrupt enabled.
	movwf	PIE1		; set peripheral interrupts enable register.
	bcf	STATUS,RP0	; select bank 0
	movlw	b'10010000'	; serial enabled, etc.
	movwf	RCSTA		; set receive status and control register.

	movlw	b'00011111'	; preset PORT 
	movwf	PORTA		; preset PORT A
	clrf	PORTB		; clear address.

	btfss	STATUS,NOT_TO	; did WDT time out?
	bsf	PORTA,LED	; yes, light warning lamp.

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
	clrf	tFlags
	
	;; enable interrupts.
	movlw	b'11100000'	; enable global + peripheral, timer
	movwf	INTCON

; ********************************
; ** Ready to really start now. **
; ********************************
	PAGE2			; select code page 2
	call	Load		; load RAM buffer from EEPROM
	PAGE0			; select code page 0
	;; say hello!
	movlw	M_INIT		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	
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
	;btfss	tFlags,HUNDMS
	;goto	LEDEnd
	;btfss	PORTA,LED
	;goto	LEDoff
	;bcf	PORTA,LED
	;goto	LedEnd
LEDoff 
	;bsf	PORTA,LED
LEDEnd
	btfss	tFlags,HUNDMS
	goto	Ck10Ms		; no 100 ms event checks.

	movf	rxTmo,f		; get receive timeout.
	btfsc	STATUS,Z	; check for zero.
	goto	Ck10Ms		; zero.
	decfsz	rxTmo,f		; decrement
	goto	Ck10Ms		; not zero.
	;; receive (upload to pod) timeout
	;; set receive command mode
	movlw	RXS_CMD		; get receive command state.
	movwf	rxState		; set receive state.
	;; send ERROR message.
	movlw	M_TOERR		; get message number for ERROR message.
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
		
Ck10Ms				; check Ten Millisecond timer events.
	btfss	tFlags,TENMS
	goto	CBDone		; no button press check.

CkWrite				; check and debounce the write button.
	btfsc	PORTC,PBWRITE	; is write button pressed. (LOW)
	goto	WR0		; no.
	;; write button is being pressed right now.
	btfss	bFlags,WLAST	; was write button pressed last time.
	goto	WR01		; no, off->on transition.
	movf	dbWrite,f	; check this for zero.
	btfsc	STATUS,Z	; skip if non-zero.
	goto	CkRead		; done with write button for now.
	decfsz	dbWrite,f	; decrement write button debounce counter.
	goto	CkRead		; done with write button for now.
	bsf	bFlags,WNOW	; set WRITE NOW flag.
	goto	CkRead		; done with write button for now.
WR01				; write button off->on transition.
	bsf	bFlags,WLAST	; set last state flag.
	movlw	BDBC		; get button debounce preset.
	movwf	dbWrite		; save write button debounce timer.
	goto	CkRead		; done with write button for now.

WR0				; write button is not pressed.
	clrf	dbWrite		; clear write button debounce timer
	bcf	bFlags,WLAST	; clear last state flag.

CkRead				; check and debounce the read button.
	btfsc	PORTC,PBREAD	; is read button pressed. (LOW)
	goto	RD0		; no.
	;; read button is being pressed right now.
	btfss	bFlags,RLAST	; was read button pressed last time.
	goto	RD01		; no, off->on transition.
	movf	dbRead,f	; check this for zero.
	btfsc	STATUS,Z	; skip if non-zero.
	goto	CBDone		; done with read button for now.
	decfsz	dbRead,f	; decrement read button debounce counter.
	goto	CBDone		; done with read button for now.
	bsf	bFlags,RNOW	; set READ NOW flag.
	goto	CBDone		; done with read button for now.
RD01				; read button off->on transition.
	bsf	bFlags,RLAST	; set last state flag.
	movlw	BDBC		; get button debounce preset.
	movwf	dbRead		; save read button debounce timer.
	goto	CBDone		; done with read button for now.

RD0				; read button is not pressed.
	clrf	dbRead		; clear read button debounce timer
	bcf	bFlags,RLAST	; clear last state flag.
	
CBDone				; done checking buttons
	
CkWNow				; check for debounced write button.
	btfss	bFlags,WNOW	; is there a valid write button press?
	goto	CkRNow		; no.
	bsf	PORTA,LED	; turn on busy LED
	PAGE2			; select code page 2
	call	WriteX		; write X22C12
	PAGE0			; select code page 0
	bcf	PORTA,LED	; turn off busy LED
	bcf	bFlags,WNOW	; clear debounced write button flag.

CkRNow				; check for debounced read button.
	btfss	bFlags,RNOW	; is there a valid read button press?
	goto	CkRChar		; no.
	bsf	PORTA,LED	; turn on busy LED
	PAGE2			; select code page 2
	call	ReadX		; read X22C12
	call	Save		; save data
	PAGE0			; select code page 0
	bcf	PORTA,LED	; turn off busy LED
	bcf	bFlags,RNOW	; clear debounced write button flag.

CkRChar				; check for received character.
	btfss	tFlags,NEWCHAR	; has a char been received?
	goto	Loop0		; no.
	bcf	tFlags,NEWCHAR	; clear new character flag.
	movlw	high rxsTbl	; set page 
	movwf	PCLATH		; select page
	movf	rxState,w	; get receive state
	andlw	h'03'		; restrict...
	addwf   PCL,f		; add w to PCL
rxsTbl
	goto	RxCmd		; received command
	goto	RxProg		; received program nibble
	goto	RxChk		; received checksum byte.
	goto	RxCmd		; fallthru!

RxCmd				; received command (valid: DURW)
	movf	rxChar,w	; get char
	xorlw	h'44'		; 'D'
	btfsc	STATUS,Z	; will be zero if D
	goto	RxCmdD		; it is D.
	
	movf	rxChar,w	; get char
	xorlw	h'64'		; 'd'
	btfsc	STATUS,Z	; will be zero if d
	goto	RxCmdD		; it is d.

	movf	rxChar,w	; get char
	xorlw	h'52'		; 'R'
	btfsc	STATUS,Z	; will be zero if R
	goto	RxCmdR		; it is R.
	
	movf	rxChar,w	; get char
	xorlw	h'72'		; 'r'
	btfsc	STATUS,Z	; will be zero if r
	goto	RxCmdR		; it is r.
	
	movf	rxChar,w	; get char
	xorlw	h'55'		; 'U'
	btfsc	STATUS,Z	; will be zero if U
	goto	RxCmdU		; it is U.
	
	movf	rxChar,w	; get char
	xorlw	h'75'		; 'u'
	btfsc	STATUS,Z	; will be zero if u
	goto	RxCmdU		; it is u.

	movf	rxChar,w	; get char
	xorlw	h'56'		; 'V'
	btfsc	STATUS,Z	; will be zero if V
	goto	RxCmdV		; it is V.
	
	movf	rxChar,w	; get char
	xorlw	h'76'		; 'v'
	btfsc	STATUS,Z	; will be zero if v
	goto	RxCmdV		; it is v.

	movf	rxChar,w	; get char
	xorlw	h'57'		; 'W'
	btfsc	STATUS,Z	; will be zero if W
	goto	RxCmdW		; it is W.
	
	movf	rxChar,w	; get char
	xorlw	h'77'		; 'w'
	btfsc	STATUS,Z	; will be zero if w
	goto	RxCmdW		; it is w.

	;; none of the above.
	bsf	PORTA,LED	; turn on busy LED
	movlw	M_MENU 		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	goto	Loop0

RxCmdD				; download to pod
	bsf	PORTA,LED	; turn on busy LED
	movlw	RXTMOT		; get timeout preset.
	movwf	rxTmo		; set timeout counter.
	clrf	chksum		; clear chksum
	clrf	pgmaddr		; reset program address.
	movlw	RXS_PGM		; get receive program state.
	movwf	rxState		; set receive state.
	goto	Loop0
	
RxCmdR				; read EEPROM to pod
	bsf	PORTA,LED	; turn on busy LED
	PAGE2			; select code page 2
	call	ReadX		; read X22C12
	call	Save		; save data
	PAGE0			; select code page 0
	movlw	M_OK 		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	goto	Loop0
	
RxCmdU				; upload from pod
	bsf	PORTA,LED	; turn on busy LED
	clrf	chksum		; clear chksum
	clrf	pgmaddr		; reset program address.
	movlw	M_TXPR		; send program message
	movwf	msgNum		; set message number
	clrf	msgCnt		; clear message counter
	call	XmitMsg		; start sending message.
	goto	Loop0		; done here.

RxCmdV				; show version.
	bsf	PORTA,LED	; turn on busy LED
	movlw	M_INIT		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	goto	Loop0
	
RxCmdW				; write EEPROM from pod
	bsf	PORTA,LED	; turn on busy LED
	PAGE2			; select code page 2
	call	WriteX		; write X22C12
	PAGE0			; select code page 0
	movlw	M_OK 		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	goto	Loop0

RxProg
	movf	rxChar,w	; get rxChar
	call	a2b		; convert char to hex digit
	addwf	chksum,f	; add to checksum
	movwf	pgmdata		; save to data temp reg.
	PAGE2			; select code page 2
	call	PutNib		; store nibble to ram buffer
	PAGE0			; select code page 0
	incfsz	pgmaddr,f	; increment prgram address
	goto	Loop0		; do more data bytes.
	movlw	RXS_CHK		; get receive checksum state.
	movwf	rxState		; set receive state.
	clrf	rxCsBc		; clear receive checksum byte count.
	clrf	rxCksum		; clear receive checksum.
	goto	Loop0
	
RxChk				; get checksum bytes
	btfsc	rxCsBc,0	; is receive checksum byte count 1?
	goto	RxChk1		; yes
	movf	rxChar,w	; get rxChar
	call	a2b		; convert char to hex digit
	movwf	rxCksum		; save into receive checksum.
	swapf	rxCksum,f	; move it to the high nibble
	incf	rxCsBc,f	; increment byte counter.
	goto	Loop0		; wait for next char.
	
RxChk1				; get 2nd checksum byte.
	movf	rxChar,w	; get rxChar
	call	a2b		; convert char to hex digit
	addwf	rxCksum,f	; add to other nibble.
	;; set receive command mode
	movlw	RXS_CMD		; get receive command state.
	movwf	rxState		; set receive state.
	;; now have checksum.  do something with it.
	movf	chksum,w	; get checksum.
	subwf	rxCksum,w	; subtract received checksum.
	btfss	STATUS,Z	; skip if result is 0, checksum matches.
	goto	RxChkNG		; bad checksum
	;; save to EEPROM.
	PAGE2			; select code page 2
	call	Save		; save data
	PAGE0			; select code page 0
	;; send the OK message.
	clrf	rxTmo		; clear timeout counter.
	movlw	M_OK 		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	goto	Loop0
RxChkNG				; bad checksum
	;; send the bad checksum message.
	clrf	rxTmo		; clear timeout counter.
	movlw	M_BCKSM		; get message number
	movwf	msgNum		; save message number
	call	XmitMsg		; send message
	goto	Loop0

; *********
; ** b2a **
; *********
	;; convert binary to ascii.
	;; only works on low nibble.
	;; receives input and returns output in w.
b2a
	andlw	h'0f'		; mask to reasonable.
	movwf	temp3		; save data
	sublw	d'9'		; w = 9 - w
	btfss	STATUS,C	; is result non-negative.
	goto	b2aLet		; no.
	movf	temp3,w		; get data back.
	addlw	d'48'		; add value of character 0.
	return			; done.
b2aLet				; result is A-F.
	movf	temp3,w		; get data back.
	addlw	d'55'		; add value of character 'A' - 10.
	return			; done.
	
; *********
; ** a2b **
; *********
	;; convert ascii hex digit to binary representation.
	;; only works for 0-F
	;; receives input and returns output in w.
a2b
	movwf	temp3		; save data.
	btfsc	temp3,7		; this bit must be clear.
	goto	a2bJunk		; bad data.
	btfsc	temp3,6		; is it a letter?
	goto	a2bLet		; yes.
	btfss	temp3,5		; this bit must be set for number
	goto	a2bJunk		; bad data.
	btfss	temp3,4		; this bit must be set for number
	goto	a2bJunk		; bad data.
	movlw	h'0f'		; mask.
	andwf	temp3,w		; get number.
	return			; 0-9 
a2bLet				; it could be a letter...
	btfsc	temp3,3		; this bit must be clear for valid letter.
	goto	a2bJunk		; bad data.
	movlw	h'07'		; mask.
	andwf	temp3,w		; get number.
	addlw	h'09'		; move to valid.
	andlw	h'0f'		; force 16 to 0.
	return			; a-f
a2bJunk
	retlw	h'00'		; return with 0 in W
		
; ************************************************************************
; ****************************** ROM PAGE 1 ******************************
; ************************************************************************
	org	0800		; page 1

	
; ************************************************************************
; ****************************** ROM PAGE 2 ******************************
; ************************************************************************
	org	1000		; page 2
	
; ***********
; ** ReadX **
; ***********
	;; read X22C12 into RAM buffer.
ReadX
	;; put the X22C12 into a known state.
	clrf	pgmaddr		; reset X22C12 address.
	clrf	PORTB		; reset address lines.
	bsf	PORTA,X22CS	; deselect X22C12 CS\.
	bsf	PORTA,X22WE	; deselect X22C12 WE\.
	bsf	PORTA,X22STR	; deselect X22C12 STR\.
	bsf	PORTA,X22RCL	; deselect X22C12 RCL\.
	
	;; set up the IO direction.
	bsf	STATUS,RP0	; select bank 1.
	movlw	B'10111111'	; SCI/SCI/in/in/in/in/in/in
				; in  out in  in  in  in  in  in 
	movwf	TRISC		; set port C data direction
	bcf	STATUS,RP0	; select bank 0.
	call	Dly150		; delay 150 ns to allow X22C12 to stabilize.

	;; read the data out of the device.
	bcf	PORTA,X22VCC	; power up the X22C12.
	call	Dly150		; delay 150 ns to allow X22C12 to power up.
RXLoop				; read X22C12 loop
	clrwdt			; clear watchdog.
	movf	pgmaddr,w	; get address.
	movwf	PORTB		; set X22C12 address lines.
	bcf	PORTA,X22CS	; select X22C12 CS\
	call	Dly150		; delay 150 ns.
	movf	PORTC,w		; get data nibble from X22C12
	andlw	h'0f'		; mask out invalid bits.
	movwf	pgmdata		; save program data.
	bsf	PORTA,X22CS	; deselect X22C12 CS\.
	call	PutNib		; save nibble to RAM buffer.
	incfsz	pgmaddr,f	; increment program address
	goto	RXLoop		; read another nibble.
	;; read all the data.  power down the device.
	clrf	PORTB		; reset all addresses to 0.
	bsf	PORTA,X22VCC	; power down the X22C12.

	call	Dly150		; wait a bit for the X22C12 to stabilize.
	;; turn off all the other pins to the programmer socket
	bcf	PORTA,X22CS	; select X22C12 CS\.
	bcf	PORTA,X22WE	; select X22C12 WE\.
	bcf	PORTA,X22STR	; select X22C12 STR\.
	bcf	PORTA,X22RCL	; select X22C12 RCL\.
	return

; ************
; ** WriteX **
; ************
	;; Write X22C12 from RAM buffer.
WriteX
	;; put the X22C12 into a known state.
	clrf	pgmaddr		; reset X22C12 address.
	clrf	PORTB		; reset address lines.
	bsf	PORTA,X22CS	; deselect X22C12 CS\.
	bsf	PORTA,X22WE	; deselect X22C12 WE\.
	bsf	PORTA,X22STR	; deselect X22C12 STR\.
	bsf	PORTA,X22RCL	; deselect X22C12 RCL\.
	call	Dly150		; delay 150 ns to allow X22C12 to stabilize.
	
	;; set up the IO direction.
	bsf	STATUS,RP0	; select bank 1.
	movlw	B'10110000'	; SCI/SCI/in/in/out/out/out/out
				; in  out in  in  out out out out
	movwf	TRISC		; set port C data direction
	bcf	STATUS,RP0	; select bank 0.

	;; write the data into the device.
	bcf	PORTA,X22VCC	; power up the X22C12.
	call	Dly5ms		; delay 5 ms so device will power up ready.
WXLoop				; write X22C12 loop
	clrwdt			; clear watchdog.
	movf	pgmaddr,w	; get address.
	movwf	PORTB		; set X22C12 address lines.
	movlw	h'f0'		; mask.
	andwf	PORTC,f		; clear low nibble (data bits) on portc
	call	GetNib		; get the nibble.
	iorwf	PORTC,f		; set program bits 
	bcf	PORTA,X22WE	; select X22C12 WE\
	bcf	PORTA,X22CS	; select X22C12 CS\
	call	Dly150		; delay 150 ns.
	bsf	PORTA,X22CS	; deselect X22C12 CS\
	bsf	PORTA,X22WE	; deselect X22C12 WE\
	incfsz	pgmaddr,f	; increment program address
	goto	WXLoop		; read another nibble.
	;; wrote all the data. 
	clrf	PORTB		; reset all addresses to 0.
	bcf	PORTA,X22STR	; select X22C12 STORE\
	call	Dly150		; delay 150 ns.
	bsf	PORTA,X22STR	; deselect X22C12 STORE\
	;; wait for device to save it's program...
	call	Dly5ms		; wait 5 ms so X22C12 can complete the store.
	;; power down the device.
	bsf	PORTA,X22VCC	; power down the X22C12.
	;; reset the IO direction.
	bsf	STATUS,RP0	; select bank 1.
	movlw	B'10111111'	; SCI/SCI/in/in/in/in/in/in
				; in  out in  in  in  in  in  in 
	movwf	TRISC		; set port C data direction
	bcf	STATUS,RP0	; select bank 0.

	call	Dly150		; wait a bit for the X22C12 to stabilize.
	;; turn off all the other pins to the programmer socket
	bcf	PORTA,X22CS	; select X22C12 CS\.
	bcf	PORTA,X22WE	; select X22C12 WE\.
	bcf	PORTA,X22STR	; select X22C12 STR\.
	bcf	PORTA,X22RCL	; select X22C12 RCL\.
	return

; **********
; ** Save **
; **********
	;; save RAM buffer to EEPROM.
Save
	clrf	eeAddr		; reset EEPROM address
SLoop
	call	GetByte		; get data buffer byte.
	call	WriteEE		; save to EEPROM
	incf	eeAddr,f	; increment address.
	btfss	eeAddr,7	; this bit will get set at address 128
	goto	SLoop		; save another byte.
	return			; done.
	
; **********
; ** Load **
; **********
	;; load RAM buffer from EEPROM.
Load
	clrf	eeAddr		; reset EEPROM address.
LLoop				; load loop
	call	ReadEE		; read EEPROM
	call	PutByte		; save byte into RAM buffer.
	incf	eeAddr,f	; increment address.
	btfss	eeAddr,7	; this bit will get set at address 128
	goto	LLoop		; load another byte.
	return			; done.
	
; ************
; ** ReadEE **
; ************
        ;; read 1 bytes from the EEPROM 
        ;; from location in eeAddr into W
ReadEE                          ; read EEPROM.
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	ReadEE  	; no,  try again.
	movf	eeAddr,w	; get eeprom address.
	bsf	STATUS,RP1	; select register page.
	bcf	STATUS,RP0	; select register page.
	movwf	EEADR		; write EEADR.
	bsf	STATUS,RP0	; select register page.
	bcf	EECON1,EEPGD	; select DATA memory.
	bsf	EECON1,RD	; read EEPROM.
	bcf	STATUS,RP0	; select register page.
	movf	EEDATA,w	; get EEPROM data.
	bcf	STATUS,RP1	; select register page.
	bsf	INTCON,GIE	; enable interrupts
        return                  ; read the requested bytes, return

; *************
; ** WriteEE **
; *************
        ;; write 1 byte from w into the EEPROM 
        ;; at location in eeAddr
	;; stomps on temp3.
WriteEE                         ; write EEPROM.
	movwf	temp3		; save the value to write.
WritEd
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	WritEd		; nope.  Try again.
	movf	eeAddr,w	; get address.
	bsf	STATUS,RP1	; select register page.
	bcf	STATUS,RP0	; select register page.
	movwf	EEADR		; set address.
	bcf	STATUS,RP1	; select register page.
	movf	temp3,w		; get data.
	bsf	STATUS,RP1	; select register page.
	movwf	EEDATA		; set data.
	bsf	STATUS,RP0	; select register page.
	bcf	EECON1,EEPGD	; select data EEPROM.
	bsf	EECON1,WREN	; enable writes.
	movlw	h'55'		; magic value.
	movwf	EECON2		; write magic value.
	movlw	h'AA'		; magic value.
	movwf	EECON2		; write magic value.
	bsf	EECON1,WR	; start write cycle.
	clrwdt			; clear watchdog.
	bsf	EECON1,WREN	; disable writes.
WriteEl				; loop until EEPROM written.
	btfsc	EECON1,WR	; done writing?
	goto	WriteEl		; nope. keep waiting.
	bcf	STATUS,RP0	; select register page.
	bcf	STATUS,RP1	; select register page.
	bsf	INTCON,GIE	; enable interrupts
        return                  ; wrote the requested bytes, done, so return

; ************
; ** GetNib **
; ************
	;; get a NIBBLE of the program data specified by address pgmaddr
	;; from the RAM bufferin pgmaddr.  return the nibble in pgmdata and in W.
GetNib	
	bsf	STATUS,IRP	; all the program data is in 100-1ff
	movf	pgmaddr,w	; get pgmaddr
	movwf	temp2		; save to temp 2.
	rrf	temp2,f		; divide by 2.
	bcf	temp2,7		; make sure bit 7 is clear.
	bcf	temp2,6		; also clear bit 6.
	movlw	low prgbuf1	; get the address of the program buffer
	addwf	temp2,f		; add the offset of the program buffer
	btfsc	pgmaddr,7	; is this address in 80-ff?
	bsf	temp2,7		; select the upper half of the buffer.
	movf	temp2,w		; get the address back.
	movwf	FSR		; set indirect address.
	movf	INDF,w		; get byte at that address.
	btfss	pgmaddr,0	; is this the high nibble?
	goto	GetNibL		; no, it's the low nibble.
GetNibH				; return the high nibble
	swapf	INDF,w		; swap the nibbles into W.
GetNibL				; mask and return the low nibble.
	andlw	h'0f'		; mask.
	movwf	pgmdata		; save data
	bcf	STATUS,IRP	; set indirect to 00-ff range.
	return			; return with the result in w.
	
; ************
; ** PutNib **
; ************
	;; save the NIBBLE pgmdata at address pgmaddr into the RAM buffer.
PutNib
	bsf	STATUS,IRP	; all the program data is in 100-1ff
	movf	pgmaddr,w	; get pgmaddr
	movwf	temp2		; save to temp 2.
	rrf	temp2,f		; divide by 2.
	bcf	temp2,7		; make sure bit 7 is clear.
	bcf	temp2,6		; also clear bit 6.
	movlw	low prgbuf1	; get the address of the program buffer
	addwf	temp2,f		; add the offset of the program buffer
	btfsc	pgmaddr,7	; is this address in 80-ff?
	bsf	temp2,7		; select the upper half of the buffer.
	movf	temp2,w		; get the address back.
	movwf	FSR		; set indirect address.
	movf	pgmdata,w	; get the program data.
	movwf	temp3		; save it.
	btfss	pgmaddr,0	; is this the high nibble?
	goto	PutNibL		; no, it's the low nibble.
PutNibH				; save the high nibble into the RAM buffer.
	movlw	h'0f'		; mask to preserve the low nibble.
	andwf	INDF,f		; clear the high nibble in the RAM buffer.
	swapf	pgmdata,w	; swap the data to the high nibble.
	andlw	h'f0'		; sanity mask so only high nibble remains.
	iorwf	INDF,f		; IOR the high nibble into the RAM buffer.
	bcf	STATUS,IRP	; set indirect to 00-ff range.
	return			; done.
PutNibL				; save the low nibble into the RAM buffer.
	movlw	h'f0'		; mask to preserve the high nibble.
	andwf	INDF,f		; clear the low nibble in the RAM buffer.
	movf	pgmdata,w	; get the program data.
	andlw	h'0f'		; sanity mask so only low nibble remains.
	iorwf	INDF,f		; IOR the high nibble into the RAM buffer.
	bcf	STATUS,IRP	; set indirect to 00-ff range.
	return			; done.

; *************
; ** GetByte **
; *************
	;; get a BYTE of the program data specified by address eeAddr
	;; from the RAM buffer.  return the BYTE in W
GetByte
	bsf	STATUS,IRP	; all the program data is in 100-1ff
	movf	eeAddr,w	; get eeAddr
	movwf	temp2		; save to temp 2.
	bcf	temp2,7		; make sure bit 7 is clear.
	bcf	temp2,6		; make sure bit 6 is clear.
	movlw	low prgbuf1	; get the address of the program buffer
	addwf	temp2,f		; add the offset of the program buffer
	btfsc	eeAddr,6	; is this address in 40-7f?
	bsf	temp2,7		; select the upper half of the buffer.
	movf	temp2,w		; get the address back.
	movwf	FSR		; set indirect address.
	movf	INDF,w		; get byte at that address.
	bcf	STATUS,IRP	; set indirect to 00-ff range.
	return			; return with the result in w.
	
; *************
; ** PutByte **
; *************
	;; save the BYTE in W at byte address eeAddr into the RAM buffer.
PutByte
	movwf	temp3		; save data.
	bsf	STATUS,IRP	; all the program data is in 100-1ff
	movf	eeAddr,w	; get eeAddr
	movwf	temp2		; save to temp 2.
	bcf	temp2,7		; make sure bit 7 is clear.
	bcf	temp2,6		; make sure bit 6 is clear.
	movlw	low prgbuf1	; get the address of the program buffer
	addwf	temp2,f		; add the offset of the program buffer
	btfsc	eeAddr,6	; is this address in 40-7f?
	bsf	temp2,7		; select the upper half of the buffer.
	movf	temp2,w		; get the address back.
	movwf	FSR		; set indirect address.
	movf	temp3,w		; get the saved data byte back.
	movwf	INDF		; save the byte in the RAM buffer.
	bcf	STATUS,IRP	; set indirect to 00-ff range.
	return			; done.

; ************
; ** Dly5ms **
; ************
Dly5ms				; delay 5 milliseconds.
	movlw	d'20'		; 20 loops using 250 ns delay.
	movwf	temp4		; loop counter, 1 instruction cycle
D5L				; loop start
	call	Dly250		; 250 ns delay.
	decfsz	temp4,f		; decrement temp4
	goto	D5L		; loop some more.
	return			; done here.

	
; ***********
; ** Dly50 **
; ***********
	;; delay 50 ns.
Dly50
	;; use 50 loops.  each loop iteration takes 1 nanosecond.
	;; the rest of the routine uses another 1 nanosecond.
	;; the net result is that this will take about 51 nanoseconds.
	clrwdt			; clear watchdog.
	movlw	d'50'		; 50 loops, 1 instruction cycle
	movwf	temp3		; loop counter, 1 instruction cycle
	goto	DLoop		; start delay.
	
; ************
; ** Dly150 **
; ************
	;; delay 150 ns.
Dly150
	;; use 150 loops.  each loop iteration takes 1 nanosecond.
	;; the rest of the routine uses another 1 nanosecond.
	;; the net result is that this will take about 151 nanoseconds.
	clrwdt			; clear watchdog.
	movlw	d'150'		; 150 loops, 1 instruction cycle
	movwf	temp3		; loop counter, 1 instruction cycle
	goto	DLoop		; start delay.

; ************
; ** Dly250 **
; ************
	;; delay 250 ns.
Dly250
	;; use 250 loops.  each loop iteration takes 1 nanosecond.
	;; the rest of the routine uses another 1 nanosecond.
	;; the net result is that this will take about 251 nanoseconds.
	clrwdt			; clear watchdog.
	movlw	d'250'		; 250 loops, 1 instruction cycle
	movwf	temp3		; loop counter, 1 instruction cycle
	goto	DLoop		; start delay.

DLoop				; each pass thru the loop takes 1 nanosecond.
	nop			; waste time, 1 instruction cycle
	decfsz	temp3,f		; decrement temp3, 1 cycle
	goto	DLoop		; keep going, 2 instruction cycles.
	;; the skip causes the decfsz to use a 2nd instruction cycle.
	return			; done. 2 instruction cycles
		
; ************************************************************************
; ****************************** ROM PAGE 3 ******************************
; ************************************************************************
	org	1800		; page 3

; *************
; ** InitMsg **
; *************
        ;; get the init message.
InitMsg				; get message from table
	movlw	high InitTbl	; set page 
	movwf	PCLATH		; select page
	movf	msgCnt,w	; get message counter
	addwf   PCL,f		; add w to PCL
InitTbl
	dt	0d,0a,0a,"NHRC-PXP V 0.04",0d,0a,">",00
	
; *************
; ** MenuMsg **
; *************
        ;; get the menu message.
MenuMsg				; get message from table
	movlw	high MenuTbl	; set page 
	movwf	PCLATH		; select page
	movf	msgCnt,w	; get message counter
	addwf   PCL,f		; add w to PCL
MenuTbl
	dt	0d,0a,0a
	dt	"V - Show Version Number.",0d,0a
	dt	"D - Download program TO pod.",0d,0a
	dt	"U - Upload program FROM pod.",0d,0a
	dt	"R - READ program EEPROM INTO POD.",0d,0a
	dt	"W - WRITE program from pod TO EEPROM.",0d,0a,0a,">",00
	
; **************************
; ** Bad Checksum Message **
; **************************
        ;; get the bad checksum message.
BadCMsg				; get message from table
	movlw	high bcksTbl	; set page 
	movwf	PCLATH		; select page
	movf	msgCnt,w	; get message counter
	addwf   PCL,f		; add w to PCL
bcksTbl
	dt	0d,0a,0a,"Bad Checksum",0d,0a,">",00
	
; **************************************
; ** Download Timed Out Error Message **
; **************************************
        ;; get the timeout error message.
ErrMsg				; get message from table
	movlw	high errmTbl	; set page 
	movwf	PCLATH		; select page
	movf	msgCnt,w	; get message counter
	addwf   PCL,f		; add w to PCL
errmTbl
	dt	0d,0a,0a,"Download Timed Out",0d,0a,">",00

	org	1900		; page 3; break so computed goto stays in range
		
; ****************
; ** OK Message **
; ****************
        ;; get the ok message.
OkMsg				; get message from table
	movlw	high okmTbl	; set page 
	movwf	PCLATH		; select page
	movf	msgCnt,w	; get message counter
	addwf   PCL,f		; add w to PCL
okmTbl
	dt	0d,0a,0a,"Ok",0d,0a,">",00
	
	end
