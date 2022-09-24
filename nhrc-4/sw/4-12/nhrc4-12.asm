;******************************************************************************
; NHRC-4 Repeater Controller.
; Copyright (C) 1996, 1997, 1998, 1999, Jeffrey B. Otterson, N1KDO,
; and NHRC LLC.
; All Rights Reserved.
;******************************************************************************
; This software contains confidential information and proprietary trade 
; secrets of NHRC LLC (NHRC).  It may not be distributed in any source or
; binary form without the express written permission of NHRC LLC.
;
; 23 May 1999
;******************************************************************************
VERSION EQU D'012'

; Set the F84 symbol to 1 if you are going to assemble this code to run on
; a 16F84.  Set it to 0 for 16C84
F84	EQU	1

; Set the DEBUG symbol to 1 to really speed up the software's internal clocks
; and timers for debugging in the simulator. Normally this is a 0.
DEBUG   EQU     0

; Set the LOADEE symbol to 1 to preload the EEPROM cells with data
; for debugging. Normally this is a 0.
LOADEE	EQU	0
;
	IF F84 == 1
	LIST P=16F84, R=HEX
	include "p16f84.inc"
	ELSE
	LIST P=16C84, R=HEX
	include "p16c84.inc"
	ENDIF
	__FUSES _CP_ON & _XT_OSC & _WDT_ON
	ERRORLEVEL 0, -302	; suppress Argument out of range errors
;
; Real Time Interrupt info
; real time is counted by setting the TICK bit every 100 ms in the
; interrupt handler.
;
;     1 s
; -----------  = .000000279365115 sec per cycle
; 3579545 cps
;
; processor clock is 4 * above = .00000111746046 sec instruction cycle
; 256 of those is .000286069878 sec
; 2 x prescale results in .000572139755
; toggling a bit at that speed will result in a 873.9 hz square wave, which
; is used for the CW and courtesy tones.
; dividing that by 175 yields a period of .100124457 sec, the base timer tick.

;
; Message Addressing Scheme:
;   CW messages:
;     0 - CW ID, "de n1kdo/r"
;     1 - CW timeout message, "to"
;     2 - CW confirm message, "ok"
;     3 - CW bad message, "ng"
;     3 - CW remote base timeout "rb to"
;

CW_ID   equ     h'00'		; CW ID
CW_TO   equ     h'01'		; CW timeout
CW_OK   equ     h'02'		; CW OK
CW_NG   equ     h'03'		; CW NG
CW_RBTO	equ	h'04'		; CW RB timeout

;
; The main program spins in Loop as fast as it can.
; Timing is accomplished by the interrupt routine that sets 3 bits that
; are used inside the main loop: TENTH, ONESEC, and TENSEC.  When these
; bits are set, the corresponding timer(s) should be decremented.
;
; Port A has the DTMF data, and one bit that is used for muting and init
; A.0 (in ) = DTMF bit 0
; A.1 (in ) = DTMF bit 1
; A.2 (in ) = DTMF bit 2
; A.3 (in ) = DTMF bit 3
; A.4 (in ) = init input at start up, mute output after
;
;Port A
TMASK   equ     0f
INITBIT equ     4
MUTE    equ     4		; mute and init share A.4
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
;PortB
DV      equ     0		; DTMF digit valid
PTT     equ     1		; PTT key
RB_COR  equ     2		; remote base COR
RB_MUTE equ     3		; remote base muting
RB_PTT  equ     4		; remote base PTT
DOUT    equ     5		; digital out
BEEPBIT equ     6		; beep generator
cor     equ     7		; unsquelched (0) / squelched (1)

;enabFlg			; enable control
ENA_OFF	equ	0		; repeater is off
ENA_ON	equ	1		; repeater is on
ENA_ALT	equ	2		; remote base alert
ENA_RBR	equ	3		; remote base receive
ENA_RBT	equ	4		; remote base transmit

;TFlags				; timer flags
TICK    equ     0		; 100 ms tick flag
TENTH   equ     1		; tenth second decrementer flag
ONESEC  equ     2		; one second decrementer flag
TENSEC  equ     3		; ten second decrementer flag
CWTICK  equ     4		; cw clock bit
TRBCOR	equ	6		; RB debounced cor
TFLCOR  equ     7		; debounced cor

;flags
initID  equ     0		; need to ID now
needID  equ     1		; need to send ID
lastDV  equ     2		; last pass digit valid
init    equ     3		; initialize
lastCor equ     4		; last COR flag - for DTMF
lastTx	equ     5		; last TX state flag
LOWBEEP equ     6		; low beep tick bit
BEEPON  equ     7		; beep tone on

; txFlag -- transmit control flags
RXOPEN	equ	0		; main receiver repeating
RBOPEN	equ	1		;  rb  receiver repeating
TXHANG	equ	2		; hang time
; 3
; 4
; 5
; 6
CWPLAY	equ	7		; CW playing

; mscFlag -- Miscellaneous flag bits
RBRXENA equ     0		; rb rx enabled
RBTXENA	equ	1		; rb tx enabled
RBALERT	equ	2		; rb alert enabled
;NIY    equ     3		; NIY
OKRQST	equ	4		; request OK message when receiver drops
ERRRQST	equ	5		; request ERR message when receiver drops
;NIY    equ     6		; NIY
LOWTONE	equ	7		; set low beep tone

;cfgFlag -- Controller configuration flag bits
LINKRPT equ     0		; Link port is a duplex repeater
MDELAY  equ     1		; delay on main port
RDELAY  equ     2		; delay on link port
NOMUTE  equ     3		; don't mute touch-tones
DOUTFAN	equ	4		; digital output is transmitter fan
;NIY    equ     5		; NIY
;NIY    equ     6		; NIY
;NIY    equ     7		; NIY

; receiver states
RXSOFF	equ	0
RXSON	equ	1
RXSTMO	equ	2

;debounce count complete Bit
	IF DEBUG == 1
CDBBIT  equ     1		; debounce counts to 2, about 1.143 ms?
CDBVAL	equ	2
	ELSE
CDBBIT  equ     5		; debounce counts to 32, about 18.2 ms
CDBVAL	equ	32
	ENDIF

;
; EEPROM locations for data...
;
EEENAB  equ     h'00'
EECONF  equ     h'01'
EEDOUT	equ	h'02'
EEHANG  equ     h'03'
EERXTO	equ	h'04'
EERBTO  equ     h'05'
EEID    equ     h'06'
EEFAN	equ	h'07'
EECT1	equ	h'08'
EECT12	equ	h'09'
EECT1A	equ	h'0a'
EECT2	equ	h'0b'
EECT22	equ	h'0c'
EECWOK  equ     h'0e'
EECWNG  equ     h'14'
EECWTO  equ     h'1a'
EECWRTO equ     h'20'
EECWID  equ     h'26'
EEIEND  equ     h'3b'		; last EEPROM to program with data at init time
EELAST  equ     h'3b'		; last EEPROM address to init

EETTPRE equ     h'3c'

;
; ctSelFl			;courtesy tone selector flag
;
CT1FL	equ	0		; use CT1
CT12FL	equ	1		; use CT12
CT1AFL	equ	2		; use CT1A
; niy	equ	3		; NIY
CT2FL	equ	4		; use CT2
CT22FL	equ	5		; use CT22

CT1SEL	equ	h'01'		; select CT1
CT12SEL	equ	h'02'		; select CT12
CT1ASEL	equ	h'04'		; select CT12
CT1MASK	equ	h'07'		; mask out only CT1 tones

CT2SEL	equ	h'10'		; select CT2
CT22SEL	equ	h'20'		; select CT22
CT2MASK	equ	h'30'		; mask out only CT2 tones
	
;
;DTMF remote control constants
;
TONES   EQU     4	       ; number of digits in touch tone command
MAXCMD  EQU     4	       ; maximum number of digits in command

;
; CW sender constants
;
CWDIT   equ     1		; dit = 100 ms
CWDAH   equ     CWDIT * 3	; dah = 300 ms
CWIESP  equ     CWDIT		; inter-element space = 100 ms
CWILSP  equ     CWDAH		; inter-letter space = 300 ms
CWIWSP  equ     7		; inter-word space = 700 ms

	IF DEBUG == 1
OFBASE  equ     D'2'		; overflow counts fast!
TEN     equ     D'2'
CWCNT   equ     D'2'
	ELSE
OFBASE  equ     D'175'		; overflow counts in 100.12 ms
TEN     equ     D'10'
CWCNT   equ     D'105'		; approximately 60 ms for 20 wpm
	ENDIF

IDSOON  equ     D'6'		; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ     D'20'		; DTMF muting timer

;macro definitions
push    macro
	movwf   w_copy		; save w reg in Buffer
	swapf   w_copy,f	; swap it
	swapf   STATUS,w	; get status
	movwf   s_copy		; save it
	endm
;
pop     macro
	swapf   s_copy,w	; restore status
	movwf   STATUS		;       /
	swapf   w_copy,w	; restore W reg
	endm

;variables
	cblock  0c
	w_copy			; saved W register for interrupt handler
	s_copy			; saved status register for int handler
	ofCnt			; 100 ms timebase counter
	cfgFlag			; Configuration Flags
	tFlags			; Timer Flags
	flags			; operating Flags
	txFlag			; Transmitter control flag
	mscFlag			; miscellaneous flag bits
	cwCntr			; cw timebase counter
	secCnt			; one second count
	tenCnt			; ten second count
	enabFlg			; enable flag
	rxState			; main receiver state
	rbState			; RB receiver state
	rxTout			; main receiver timeout timer, in whole seconds
	rbTout			; RB   receiver timeout timer, in whole seconds
	hangDly			; hang timer preset, kept around for speed
	hangTmr			; hang timer, in tenths
	idTmr			; id timer, in 10 seconds
	muteTmr			; DTMF muting timer, in tenths
	cwTmr			; CW element timer
	msgNum			; message number to play
	tone			; touch tone digit received
	toneCnt			; digits received down counter
	cmdCnt			; command digits received
	tBuf1			; tones received buffer
	tBuf2			; tones received buffer
	tBuf3			; tones received buffer
	tBuf4			; tones received buffer
	cwBuff			; CW message buffer offset
	cwByte			; CW current byte (bitmap)
	dBounce			; cor debounce counter
	rbDBnc			; remote base cor debounce counter
	temp			; temp value, use & abuse
	fanTmr			; fan run timer
	cTone			; courtesy tone
	ctSelFl			; courtesy tone selector flag
	endc

;last 16C84 rem address is at 2f
;last 16F84 ram address is at 4f ???
;;;;;;;;;;;;;;;;;;
;; MAIN PROGRAM ;;
;;;;;;;;;;;;;;;;;;

	org     0
	goto    Start
	dw      VERSION

	;
	; interrupt handler
	;
	org     4
	push			; preserve W and STATUS

	btfsc   INTCON,T0IF
	goto    TimrInt
	goto    IntExit

TimrInt
	btfss   flags,BEEPON    ; is beep turned on?
	goto    TimrTst		; no, continue
	btfss	mscFlag,LOWTONE	; is the low beep selected?
	goto	HiBeep		; nope...
	btfsc	flags,LOWBEEP	; is the low beep bit counter clear?
	goto	LowBp1		; nope;  it's set...
	bsf	flags,LOWBEEP	; wasn't set, set it
	goto	TimrTst		; and continue on...
LowBp1
	bcf	flags,LOWBEEP	; clear the low beep bit
				; now go on and toggle the beep bit
HiBeep
	btfss   PORTB,BEEPBIT   ; is BEEPBIT set?
	goto    Beep0		; no
	bcf     PORTB,BEEPBIT   ; yes, turn it off
	goto    TimrTst		; continue
Beep0
	bsf     PORTB,BEEPBIT   ; beep bit is off, turn it on...

TimrTst
	decfsz  ofCnt,f		; decrement the overflow counter
	goto    TimrDone	; if not 0, then
	bsf     tFlags,TICK     ; set tick indicator flag
	movlw   OFBASE		; preset overflow counter
	movwf   ofCnt

TimrDone
	decfsz  cwCntr,f	; decrement the cw timebase counter
	goto    DeBounc
	bsf     tFlags,CWTICK   ; set tick indicator
	movlw   CWCNT		; get preset value
	movwf   cwCntr		; preset cw timebase counter

DeBounc				; COR debounce
	btfss   PORTB,cor       ; check cor
	goto    ICorOn		; it's low...
				; squelch is closed; receiver is inactive
	movf    dBounce,f       ; check debounce counter for zero
	btfsc   STATUS,Z	; is it zero?
	goto    RBDbnce		; yes
	decf    dBounce,f       ; no, decrement it
	btfsc   STATUS,Z	; is it zero?
	goto	MCorOff		; yes, turn off main cor flag
	btfss	cfgFlag,MDELAY	; audio delay on main port?
	goto    RBDbnce		; no, continue
	decfsz	dBounce,f	; decrement & test
	goto	RBDbnce		; not zero yet.
	
MCorOff
	bsf     tFlags,TFLCOR   ; yes, turn COR off
	goto    RBDbnce		; done with COR debouncing...

ICorOn				; squelch is open; receiver is active
	btfss	cfgFlag,MDELAY	; audio delay on main port?
	goto	ICorOn1		; no
	incfsz	dBounce,w	; increment debounce & test for 256 (0)
	goto	ICorOn0		; not 256 yet
	goto	ICorS1		; it's now 256, set the COR flag

ICorOn0				; not 256 yet
	incf	dBounce,f	; increment dBounce
	goto	RBDbnce
	
ICorOn1				; no audio delay on this port
	btfsc   dBounce,CDBBIT  ; check debounce counter
	goto    RBDbnce		; already maxed out
	incf    dBounce,f       ; increment
	btfss   dBounce,CDBBIT  ; is it maxed now?
	goto    RBDbnce		; no
	
ICorS1				; set COR on
	bcf     tFlags,TFLCOR   ; yes, turn COR on

RBDbnce				; RB COR debounce
	btfss   PORTB,RB_COR	; check RB cor
	goto    RBCorOn		; it's low...
				; squelch is closed; receiver is inactive
	movf    rbDBnc,f	; check debounce counter for zero
	btfsc   STATUS,Z	; is it zero?
	goto    TIntDone	; yes
	decf    rbDBnc,f	; no, decrement it
	btfsc   STATUS,Z	; is it zero?
	goto	RCorOff		; yes, turn off RB cor
	btfss	cfgFlag,RDELAY	; audio delay on rb rcx?
	goto    TIntDone	; no, continue
	decfsz	rbDBnc,F	; decrement & test
	goto    TIntDone	; done with COR debouncing...

RCorOff
	bsf	tFlags,TRBCOR	; turn RB COR off
	goto	TIntDone	; done here...
	
RBCorOn				; squelch is open; receiver is active
	btfss	cfgFlag,RDELAY	; audio delay on rb rx
	goto	RCorOn1		; no
	incfsz	rbDBnc,w	; increment rx debounce
	goto	RCorOn0		; not 256 yet
	goto	RCorS1		; it's now 256, set the COR flag

RCorOn0				; not 256 yet
	incf	rbDBnc,f	; increment rb deboune
	goto	TIntDone	; done here

RCorOn1
	btfsc   rbDBnc,CDBBIT   ; check debounce counter
	goto    TIntDone	; already maxed out
	incf    rbDBnc,f	; increment
	btfss   rbDBnc,CDBBIT	; is it maxed now?
	goto    TIntDone	; no

RCorS1				; set the rb cor on
	bcf     tFlags,TRBCOR   ; yes, turn COR on

TIntDone
	bcf     INTCON,T0IF     ; clear RTCC int mask

IntExit
	pop			; restore W and STATUS
	retfie

Start
	movlw   b'00001000'	; preset port B (bit 3 is RB MUTE)
	movwf	PORTB		; preset port B values...

	bsf     STATUS,RP0      ; select bank 1
	movlw   b'00011111'     ; low 5 bits are input
	movwf   TRISA		; set port a as outputs
	movlw   b'10000101'     ; RB0, RB2 & RB7 inputs
	movwf   TRISB

	IF DEBUG == 1
	movlw   b'10001000'     ; DEBUG! no pull up, timer 0 gets no prescale
	ELSE
	movlw   b'10000000'     ; no pull up, timer 0 gets prescale 2
	ENDIF

	movwf   OPTION_REG      ; set options

	bcf     STATUS,RP0      ; select page 0
	clrf	flags		; reset all flags
	clrf    PORTA		; make port a all low
	movlw	b'11000000'	; initial value for tFlags
	movwf   tFlags		; clear timer flags
	bsf     tFlags,TFLCOR   ; set debounced cor off
	clrf    msgNum		; clear message number
	clrf	txFlag		; clear tx flag
	clrf	rxState		; reset receiver state
	clrf	rbState		; reset remote base receiver state
	clrf    rxTout		; clear timeout timer
	clrf    rbTout		; clear timeout timer
	clrf	mscFlag		; clear miscellaneous flags
	clrf	fanTmr		; clear fan timer
	movlw   OFBASE		; preset overflow counter
	movwf   ofCnt
	movlw   CWCNT		; get preset value
	movwf   cwCntr		; preset cw timebase counter

	movlw   TEN		; preset decade counters
	movwf   secCnt		; 1 second down counter
	movwf   tenCnt		; 10 second down counter

	clrf    hangTmr		; clear hang timer
	clrf    idTmr		; clear idTimer
	clrf    muteTmr		; clear muting timer
	clrf    cmdCnt		; clear command counter
	clrf    dBounce		; clear main rx debounce timer counter
	clrf    rbDBnc		; clear rb   rx debounce timer counter
	movlw   TONES
	movwf   toneCnt		; preset tone counter

	btfsc   PORTA,INITBIT	; check to see if init is pulled low
	goto    NoInit		; init is not low, continue...

	bsf     flags,init	; initialization in progress

	movlw   EELAST		; get last address to initialize
	movwf   EEADR		; set EEPROM address to program
InitLp
	call    InitDat		; get init data byte
	movwf   EEDATA		; put into EEPROM data register
	call    EEProg		; program byte
	movf    EEADR,f		; load status, set Z if zero (last byte done)
	btfsc   STATUS,Z	; skip if Z is clear (not last byte)
	goto    NoInit		; done initializing EEPROM data
	decf    EEADR,f		; decrement EEADR
	goto    InitLp

NoInit
	bsf     STATUS,RP0      ; select bank 1
	movlw   b'00001111'     ; low 4 bits are input, RA4 is muting control
	movwf   TRISA		; set port a as outputs
	bcf     STATUS,RP0      ; select bank 1

	movlw   EEENAB		; get address of enable byte
	movwf	EEADR		; set EEPROM address
	call	EEEval		; get & evaluate data
	movlw   EECONF		; get address of configuration byte
	movwf	EEADR		; set EEPROM address
	call	EEEval		; get & evaluate data
        movlw   EEDOUT          ; address of digital output control byte
	movwf	EEADR		; set EEPROM address
	call	EEEval		; get & evaluate data
	movlw   EEHANG		; get address of hang timer preset value
	movwf	EEADR		; set EEPROM address
	call	EEEval		; get & evaluate data

	movlw   b'10100000'     ; enable interrupts, & Timer 0 overflow
	movwf   INTCON
	bsf	PORTA,MUTE	; mute the receiver audio.

Loop				; start of main loop
	clrwdt			; reset the watchdog timer
	;check CW bit
	btfss   tFlags,CWTICK   ; is the CWTICK set
	goto    NoCW
	bcf     tFlags,CWTICK   ; reset the CWTICK flag bit

	;
	;CW sender
	;
	btfss   txFlag,CWPLAY   ; sending CW?
	goto    NoCW		; nope
	decfsz  cwTmr,f		; decrement CW timer
	goto    NoCW		; not zero

	btfss   flags,BEEPON	; was "key" down?
	goto    CWKeyUp		; nope
				; key was down
	bcf     flags,BEEPON    ; key->up
	decf    cwByte,w	; test CW byte to see if 1
	btfsc   STATUS,Z	; was it 1 (Z set if cwByte == 1)
	goto    CWNext		; it was 1...
	movlw   CWIESP		; get cw inter-element space
	movwf   cwTmr		; preset cw timer
	goto    NoCW		; done with this pass...

CWNext				; get next character of message
	incf    cwBuff,f	; increment offset
	movf    cwBuff,w	; get offset
	call    ReadEE		; get char from EEPROM
	movwf   cwByte		; store character bitmap
	btfsc   STATUS,Z	; is this a space (zero)
	goto    CWWord		; yes, it is 00
	incf    cwByte,w	; check to see if it is FF
	btfsc   STATUS,Z	; if this bitmap was FF then Z will be set
	goto    CWDone		; yes, it is FF
	movlw   CWILSP		; no, not 00 or FF, inter letter space
	movwf   cwTmr		; preset cw timer
	goto    NoCW		; done with this pass...

CWWord				; word space
	movlw   CWIWSP		; get word space
	movwf   cwTmr		; preset cw timer
	goto    NoCW		; done with this pass...

CWKeyUp				; key was up, key again...
	incf    cwByte,w	; is cwByte == ff?
	btfsc   STATUS,Z	; Z is set if cwByte == ff
	goto    CWDone		; got EOM

	movf    cwByte,f	; check for zero/word space
	btfss   STATUS,Z	; is it zero
	goto    CWTest		; no...
	goto    CWNext		; is 00, word space...

CWTest
	movlw   CWDIT		; get dit length
	btfsc   cwByte,0	; check low bit
	movlw   CWDAH		; get DAH length
	movwf   cwTmr		; preset cw timer
	bsf     flags,BEEPON    ; turn key->down
	rrf     cwByte,f	; rotate cw bitmap
	bcf     cwByte,7	; clear the MSB
	goto    NoCW		; done with this pass...

CWDone				; done sending CW
	bcf     txFlag,CWPLAY   ; turn off CW flag

NoCW
	movlw   b'11110001'     ; set timer flags mask
	andwf   tFlags,f	; clear timer flags
	btfss   tFlags,TICK     ; check to see if a tick has happened
	goto    Loop1		; nope...

	;
	; 100ms tick has occurred...
	;
	bcf     tFlags,TICK     ; reset tick flag
	bsf     tFlags,TENTH    ; set tenth second flag
	decfsz  secCnt,f	; decrement 1 second counter
	goto    Loop1		; not zero (not 1 sec interval)

	;
	; 1s tick has occurred...
	;
	movlw   TEN		; preset decade counter
	movwf   secCnt
	bsf     tFlags,ONESEC	; set one second flag
	decfsz  tenCnt,f	; decrement 10 second counter
	goto    Loop1		; not zero (not 10 second interval)

	;
	; 10s tick has occurred...
	;
	movlw   TEN		; preset decade counter
	movwf   tenCnt
	bsf     tFlags,TENSEC   ; set ten second flag

	;
	; main loop for repeater controller
	;

Loop1
	movlw	h'00'		; in first 1/4 k
	movwf	PCLATH		; ensure computed goto stays in range
	movf	rxState,w	; get main receiver state
	addwf	PCL,f		; add w to PCL:	 computed GOTO
	goto	Main0		; quiet
	goto	Main1		; repeat
	goto	Main2		; timeout

Main0				; receiver quiet state
	btfsc	tFlags,TFLCOR	; is squelch open?
	goto	ChkRb		; nope, don't turn receiver on
	movf	enabFlg,f	; check enabFlg
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkRb		; disabled, not gonna turn receiver on
	movlw	RXSON		; get new state #
	movwf	rxState		; set new receiver state
	bsf	txFlag,RXOPEN	; set main receiver on bit
	bcf	ctSelFl,CT1FL	; clear CT1 flag
	bcf	ctSelFl,CT12FL	; clear CT12 flag
	bcf	ctSelFl,CT1AFL	; clear CT1A flag
	movf	muteTmr,f	; check mute timer
	btfsc	STATUS,Z	; if it's non-zero, skip unmute
	bcf     PORTA,MUTE      ; unmute
	;; remote base non-repeater PTT logic
	btfss	mscFlag,RBTXENA	; is rb tx enabled?
	goto	Main01		; nope...
	btfss	cfgFlag,LINKRPT	; is RB port a repeater?
	bsf	PORTB,RB_PTT	; turn on remote base PTT

Main01
	movlw	EERXTO		; get address of main rx timeout time
	call	ReadEE		; read EEPROM
	movwf	rxTout		; set main receiver timeout timer
	goto	ChkRb		; done here...

Main1				; receiver active state
	btfsc	tFlags,TFLCOR	; is squelch open?
	goto	Main1Off	; no, on->off transition
	btfss	tFlags,ONESEC	; one second tick?
	goto	ChkRb		; nope, continue
	movf	rxTout,f	; squelch still open, check timeout timer
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkRb		; timeout timer is zero, don't decrement
	decfsz	rxTout,f	; decrement the timeout timer
	goto	ChkRb		; have not timed out (yet), continue
	movlw	RXSTMO		; get new state, timed out
	movwf	rxState		; set new receiver state
	bcf	txFlag,RXOPEN	; clear main receiver on bit
	bsf     PORTA,MUTE      ; mute
	clrf	rxTout		; set main receiver timeout timer
	movlw   CW_TO		; time out message
	movwf   msgNum		; set message number
	call    PlayMsg		; play the message
	goto	ChkRb		; done here...

Main1Off			; receiver was active, became inactive
        call    RxOff           ; turn off receiver
	;; remote base non-repeater PTT logic
	btfss	mscFlag,RBTXENA	; is rb tx enabled?
	goto	Main10		; nope...
	btfss	cfgFlag,LINKRPT	; is RB port a repeater?
	bcf	PORTB,RB_PTT	; turn off remote base PTT

Main10
	movlw	CT1SEL		; get CT1 selection
	btfsc	mscFlag,RBTXENA	; is rb tx enabled?
	movlw	CT12SEL		; yes, get that courtesy tone
	btfss	mscFlag,RBALERT	; is rb alert enabled
	goto	Main10h		; no; continue
	btfss	tFlags,TRBCOR	; is rb squelch open? (negative logic)
        movlw   CT1ASEL		; yes, get that courtesy tone

Main10h
	movwf	ctSelFl		; sav CT selection flag
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now
	goto	ChkRb		; done here...

Main2				; receiver timedout state
	btfss	tFlags,TFLCOR	; is squelch open?
	goto	ChkRb		; yes, still timed out
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rxState		; set new receiver state
	movlw   CW_TO		; time out message
	movwf   msgNum		; set message number
	call    PlayMsg		; play the message
	goto	ChkRb		; seems redundant, but it ain't

ChkRb
	movlw	h'01'		; in second 1/4 k
	movwf	PCLATH		; ensure computed goto stays in range
	movf	rbState,w	; get  rb  receiver state
	addwf	PCL,f		; add w to PCL:	 computed GOTO
	goto	RbRx0		; quiet
	goto	RbRx1		; repeat
	goto	RbRx2		; timeout

RbRx0				; receiver quiet state
	btfsc	tFlags,TRBCOR	; is squelch open?
	goto	HangCnt		; nope, don't turn receiver on

	btfsc	mscFlag,RBRXENA	; is RB RX enabled?
	goto	RbRx01		; yes...

	btfss	mscFlag,RBTXENA	; is rb tx enabled?
	goto	HangCnt		; no...

RbRx01
	movlw	RXSON		; get new state #
	movwf	rbState		; set new receiver state
	bsf	txFlag,RBOPEN	; set  rb  receiver on bit	
	bcf	ctSelFl,CT2FL	; clear CT2 flag
	bcf	ctSelFl,CT22FL	; clear CT22 flag
	bcf     PORTB,RB_MUTE	; unmute
	movlw	EERBTO		; get address of  rb  rx timeout time
	call	ReadEE		; read EEPROM
	movwf	rbTout		; set  rb  receiver timeout timer
	goto	HangCnt		; done here...

RbRx1				; receiver active state
	btfsc	tFlags,TRBCOR	; is squelch open?
	goto	RbRx1Off	; no, on->off transition
	btfss	tFlags,ONESEC	; one second tick?
	goto	HangCnt		; nope, continue
	movf	rbTout,f	; squelch still open, check timeout timer
	btfsc	STATUS,Z	; skip if not zero
	goto	HangCnt		; timeout timer is zero, don't decrement
	decfsz	rbTout,f	; decrement the timeout timer
	goto	HangCnt		; have not timed out (yet), continue
	movlw	RXSTMO		; get new state, timed out
	movwf	rbState		; set new receiver state
	bcf	txFlag,RBOPEN	; clear  rb  receiver on bit
	bsf     PORTB,RB_MUTE	; mute
	clrf	rbTout		; set  rb  receiver timeout timer
	movlw   CW_RBTO		; time out message
	movwf   msgNum		; set message number
	call    PlayMsg		; play the message
	goto	HangCnt		; done here...

RbRx1Off			; receiver was active, became inactive
        call    RBRxOff         ; turn off RB receiver
	movlw	CT2SEL		; get CT selection
	btfss	mscFlag,RBTXENA	; is rb tx enabled?
	goto	RbRx1oc		; no, set the tone & hang
	movlw	CT22SEL		; yes, get that courtesy tone
	btfsc	cfgFlag,LINKRPT	; is RB port a repeater?
	goto	RbRx1oc		; yes, set the tone & hang
	btfsc	txFlag,RXOPEN	; is main receiver on bit set?
	goto	RbRx1oh		; yes, hang without a beep!

RbRx1oc
	movwf	ctSelFl		; save CT selection

RbRx1oh
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now
	goto	HangCnt		; done here...

RbRx2				; receiver timedout state
	btfss	tFlags,TRBCOR	; is squelch open?
	goto	HangCnt		; yes, still timed out
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rbState		; set new receiver state
	movlw   CW_RBTO		; time out message
	movwf   msgNum		; set message number
	call    PlayMsg		; play the message

HangCnt
	btfss	tFlags,TENTH	; tenth second tick?
	goto	ChkTx		; not a tenth second tick
	movf	hangTmr,f	; check hang timer
	btfsc	STATUS,Z	; is it zero?
	goto	ChkTx		; yes, continue
	;movf	cTone,f		; test cTone
	;btfsc	STATUS,Z	; is it zero?
	;goto	HangNob		; yes, no courtesy tones required

	btfss	txFlag,CWPLAY	; is cw playing?
        goto    CTBeep          ; no. play the beep.
	clrf	cTone		; cancel courtesy tone
	goto	HangNob		; bag the beep if cw is playing

CTBeep
       	movf	hangTmr,w	; get hang timer
	subwf	hangDly,w	; w = hangDly - hangTmr(w)
	movwf	temp		; save temporary value into temp
	movlw	d'5'		; .5 sec -- pre-beep delay
	subwf	temp,f		; temp = temp - 5
	btfss	STATUS,C	; skip if temp >= 0
	goto	HangNob		; temp < 5
	movf	temp,w		; get temp
	sublw	d'4'		; w = 4 - w
	btfss	STATUS,C	; skip if w <=4
	goto	HangNob
	;; at this point, the hang timer has been running for 0.5->1.0 sec

	movf	ctSelFl,f	; evaluate ctSelFl
	btfsc	STATUS,Z	; skip if it is NOT ZERO.
	goto	CTBeep2		; it is zero.

	movlw	EECT1		; default or fallthrough condition
	btfsc	ctSelFl,CT2FL	; CT2 selected?
	movlw	EECT2		; get EEPROM address of CT2.
	btfsc	ctSelFl,CT22FL	; CT22 selected?
	movlw	EECT22		; get EEPROM address of CT22.

	btfsc	ctSelFl,CT1FL	; CT1 selected?
	movlw	EECT1		; get EEPROM address of CT1.
	btfsc	ctSelFl,CT12FL	; CT12 selected?
	movlw	EECT12		; get EEPROM address of CT11.
	btfsc	ctSelFl,CT1AFL	; CT1A selected?
	movlw	EECT1A		; get EEPROM address of CT11.

	movwf	EEADR		; save EEPROM address
	call	ReadEE		; read EEPROM
	movwf	cTone		; save courtesy tone mask.
	clrf	ctSelFl		; reset ct to blank.
	
CTBeep2
	;; shit.
	bcf	mscFlag,LOWTONE
	bcf	flags,BEEPON
	btfsc	cTone,0		; check low bit
	bsf	flags,BEEPON
	rrf     cTone,f		; rotate cw bitmap
	bcf     cTone,7		; clear the MSB
	btfsc	cTone,0		; check low bit
	bsf	mscFlag,LOWTONE
	rrf     cTone,f		; rotate cw bitmap
	bcf     cTone,7		; clear the MSB
	goto	HangNob

HangNob				; hanging without a beep
	decfsz	hangTmr,f	; decrement and check if now zero
	goto	ChkTx		; not zero
	bcf	txFlag,TXHANG	; turn off hang time flag

ChkTx				; check if transmitter should be on
	movf	txFlag,f	; check txFlag
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkTx0		; it's zero, turn off transmitter
	btfsc	flags,lastTx	; skip if not already on
	goto	ChkFan		; done here
	call	PTTon		; turn on transmitter (will set lastTx)
	movf	enabFlg,w	; get enable flag
	sublw	ENA_RBT		; subtract from remote base transmit value
	btfss	STATUS,Z	; enable flag == ENA_RBT
	goto	ChkFan		; nope...
	btfsc	cfgFlag,LINKRPT	; is the link port configured as a repeater?
	bsf	PORTB,RB_PTT	; turn on remote base PTT
	goto	ChkFan		; continue

ChkTx0
	btfss	flags,lastTx	; skip if tx is on
	goto	ChkFan		; was already off
	call	PTToff		; turn off PTT
	goto	ChkFan		; continue

ChkFan
	movf	fanTmr,f	; check fan timer
	btfsc	STATUS,Z	; is it zero?
	goto	CasEnd		; no
	btfss	cfgFlag,DOUTFAN	; fan mode configured?
	goto	ChkFan0		; no
	btfss	tFlags,TENSEC	; ten second tick?
	goto	CasEnd		; no
        goto    ChkFan1
ChkFan0
        btfss   tFlags,TENTH    ; tenth second tick?
        goto    CasEnd          ; no
ChkFan1
       	decfsz	fanTmr,f	; decrement fan timer
	goto	CasEnd		; not zero yet
	bcf	PORTB,DOUT	; turn off fan

CasEnd
	movf    idTmr,f
	btfsc   STATUS,Z	; is idTmr 0
	goto    CkTone		; yes...

	btfss   tFlags,TENSEC   ; check to see if ten second tick
	goto    CkTone		; nope...

	decfsz  idTmr,f		; decrement ID timer
	goto    CkTone		; not zero yet...
				; id timer is zero! time to ID
	call	DoID		; play the ID

CkTone
	btfss   PORTB,DV	; check M8870 digit valid
	goto    NoTone		; not set
	btfsc   flags,lastDV    ; check to see if set on last pass
	goto	Wait		; it was already set
	bsf     flags,lastDV    ; set lastDV flag

	btfsc   cfgFlag,NOMUTE  ; check for no muting flag
	goto    MuteEnd		; no muting...

	movlw   MUTEDLY		; get mute timer delay
	movwf   muteTmr		; preset mute timer
	bsf     PORTA,MUTE      ; set muting

MuteEnd
	movf    PORTA,w		; get DTMF digit
	andlw   TMASK		; mask off hi nibble
	movwf   tone		; save digit
	goto    Wait

NoTone
	btfss   flags,lastDV    ; is lastDV set
	goto	Wait		; nope...
	bcf     flags,lastDV    ; clear lastDV flag...

	btfsc   flags,init      ; in init mode?
	goto    WrTone		; yes, go write the tone

	movf    toneCnt,w       ; test toneCnt
	btfss   STATUS,Z	; is it zero?
	goto    CkDigit		; no

	;password has been successfully entered, start storing tones

	;make sure that there is room for this digit
	movlw   MAXCMD		; get max # of command tones
	subwf   cmdCnt,w	; cmdCnt - MAXCMD -> w
	btfsc   STATUS,Z	; if Z is set then there is no more room
	goto    Wait		; no room, just ignore it...

	;there is room for this digit, calculate buffer address...
	movlw   tBuf1		; get address of first byte in buffer
	addwf   cmdCnt,w	; add offset
	movwf   FSR		; set indirection register
	movf    tone,w		; get tone
	call    MapDTMF		; convert to hex value
	movwf   INDF		; save into buffer location
	incf    cmdCnt,f	; increment cmdCnt
	goto    Wait

CkDigit
	;check this digit against the code table
	sublw   TONES		; w = TONES - w; w now has digit number
	addlw   EETTPRE		; w = w + EETTPRE; the digit's EEPROM address
	call    ReadEE		; read EEPROM
	subwf   tone,w		; w = tone - w
	btfss   STATUS,Z	; is w zero?
	goto    NotTone		; no...
	decf    toneCnt,f       ; decrement toneCnt
	goto	Wait

NotTone
	movlw   TONES
	subwf   toneCnt,w
	btfsc   STATUS,Z	; is this the first digit?
	goto    BadTone		; yes
	movlw   TONES		; reset to check to see if this digit
	movwf   toneCnt		; is the first digit...
	goto    CkDigit

WrTone				; save tone in EEPROM to init password
	movf    toneCnt,w	; test toneCnt
	sublw   TONES		; w = TONES - w; w now has digit number
	addlw   EETTPRE		; w = w + EETTPRE; the digit's EEPROM address
	movwf   EEADR		; EEADR = w
	movf    tone,w		; get tone
	movwf   EEDATA		; put into EEPROM data register...
	call    EEProg		; call EEPROM prog routine

	decfsz  toneCnt,f       ; decrement tone count
	goto    Wait		; not zero, still in init mode
	bcf     flags,init      ; zero, out of init mode
	bsf	mscFlag,OKRQST	; request OK message be sent

BadTone
	movlw   TONES		; no... get number of command tones into w
	movwf   toneCnt		; preset number of command tones

Wait
	btfss   tFlags,TENTH    ; check to see if one tenth second tick
	goto    Wait1		; nope...

	movf    muteTmr,f       ; test mute timer
	btfsc   STATUS,Z	; Z is set if not DTMF muting
	goto    Wait1		;
	decfsz  muteTmr,f       ; decrement muteDly
	goto    Wait1		; have not reached the end of the mute time
	btfsc	txFlag,RXOPEN	; is receiver still unsquelched
	bcf     PORTA,MUTE      ; yep, unmute

Wait1
	btfsc   tFlags,TFLCOR   ; is squelch open?
	goto    CorOn		; yes
	btfss   flags,lastCor   ; cor is off, is last COR off?
	goto    Loop		; last COR is also off, do nothing here
	;COR on->off transition (receiver has just unsquelched)
	bcf     flags,lastCor   ; clear last COR flag
	call    ClrTone		; clear password tones & commands
	goto    Loop

CorOn
	btfsc   flags,lastCor   ; cor is ON, is last COR on?
	goto    Loop		; last COR is also on, do nothing here
	;COR off->on transition (receiver has just squelched)
	bsf     flags,lastCor   ; set last COR flag

	;evaluate touch tones in buffer
	movf    cmdCnt,f	; check to see if any stored tones
	btfsc   STATUS,Z	; is it zero?
	goto    NoCmd		; no stored tones

	movlw   MAXCMD		; get max # of command tones
	subwf   cmdCnt,w	; cmdCnt - MAXCMD -> w
	btfss   STATUS,Z	; if Z is set then there are enough digits
	goto    NoCmd		; not enough command digits...

	;there are tones stored in the buffer...
	swapf   tBuf1,w		; swap nibble of tBuf1 and store in w
	iorwf   tBuf2,w		; or in low nibble (tBuf2)
	movwf   tBuf1		; store resultant 8 bit value into tBuf1

	swapf   tBuf3,w		; swap nibble of tBuf3 and store in w
	iorwf   tBuf4,w		; or in low nibble (tBuf4)
	movwf   tBuf3		; store resultant 8 bit value into tBuf3

	;test the address...
	btfsc   tBuf1,7		; bit 7 is not allowed
	goto    BadCmd
	btfsc   tBuf1,6		; bit 6 indicates command: 4xxx,5xxx,6xxx,7xxx
	goto    MsgCmd

	movf	tBuf1,w		; get the address to program
	sublw	EELAST		; subtract from EELAST, last valid prog addr
	btfss	STATUS,C	; skip if tBuf1 <= EELAST
	goto	BadCmd		; that address is not user programmable

	;program the byte...
	
	movf    tBuf1,w		; get address
	movwf   EEADR
	movf    tBuf3,w		; get data byte
	movwf   EEDATA
	call    EEProg		; program EE byte

	call	EEEval		; evaluate the changed byte

	movlw   CW_OK
	movwf   msgNum
	call    PlayMsg
	call    ClrTone         ; reset DTMF buffers & counters
	goto    Loop            ; back to top

MsgCmd				; 4x, 5x, 6x, 7x commands
	movf    tBuf1,w		; get command byte
	andlw   b'10001110'     ; check for invalid values
	btfss   STATUS,Z	;
	goto    BadCmd		; only 40, 41, 50, 51, 60, 61, 70, 71 valid

	movlw   h'02'		; this value must equal address' high byte
	movwf   PCLATH		; ensure that computed goto will stay in range

	swapf   tBuf1,w		; swap command byte into w
	andlw   b'00000011'     ; mask bits that make up remainder of command
	addwf   PCL,f		; add w to PCL
	goto    Cmd4x		; bits 2-7 has been stripped so 4 = 0
	goto    Cmd5x
	goto    Cmd6x
	goto    Cmd7x

Cmd4x
        goto    MsgPlay         ;40nn command

Cmd5x
	goto    BadCmd

Cmd6x				; command 6x
	movf	tBuf1,w		; get cmd
	andlw	h'0e'		; mask extra bits
	btfss	STATUS,Z	; 60 or 61 permitted only
	goto	BadCmd		; not 60 or 61
	call	GetBit		; get mask
	btfsc	tBuf1,0		; is low bit of addr/cmd set?
	goto	Cmd61		; yes
	comf	cfgFlag,f	; invert the config flags byte
	iorwf	cfgFlag,f	; set the specified bit
	comf	cfgFlag,f	; invert the config flags byte again
	goto	Cmd6xW		; go write the change

Cmd61				; set config bit
	iorwf	cfgFlag,f	; set the specified bit
Cmd6xW
	movlw	EECONF		; get the address for the config byte
	movwf	EEADR		; store the eeprom address
	movf	cfgFlag,w	; get the config flag
        movwf   EEDATA		; move it to the EEPROM data buffer
        call    EEProg          ; program EE byte
	call	EEEval		; evaluate the changed byte
	goto	GoodCmd
	
Cmd7x
	goto    BadCmd

GetBit				; return mask in w with bit w set
        movlw   h'02'		; in range 200-2ff
        movwf   PCLATH          ; ensure that computed goto will stay in range
	movf	tBuf3,w		; get the selected bit
	andlw	h'07'		; must be in 0-7 range
	addwf	PCL,f		; computed goto
	retlw	b'00000001'	; bit 0
	retlw	b'00000010'	; bit 1
	retlw	b'00000100'	; bit 2
	retlw	b'00001000'	; bit 3
	retlw	b'00010000'	; bit 4
	retlw	b'00100000'	; bit 5
	retlw	b'01000000'	; bit 6
	retlw	b'10000000'	; bit 7

MsgPlay				; command 40
	movf    tBuf3,w		; get argument
	movwf   msgNum		; save into message number
	call    PlayMsg
	goto    Loop

NoCmd				; no command was received
	btfss	flags,init	; in init mode?
	goto    CkSayOk		; nope
	movlw	CW_ID		; select CW ID message
	goto	CmdRes		; play ID since in init mode

CkSayOk
	btfss	mscFlag,OKRQST	; is the say ok flag set?
	goto	CmdDone		; nope
	bcf	mscFlag,OKRQST	; reset the flag
	movlw	CW_OK		; select CW OK message
	goto	CmdRes		; play it and continue

BadCmd
	movlw   CW_NG
	goto    CmdRes
GoodCmd
	movlw   CW_OK
CmdRes
	movwf   msgNum
	call    PlayMsg
CmdDone
	call    ClrTone
	goto	Loop

SetHang
	btfss	txFlag,CWPLAY	; is cw playing?
	bcf	flags,BEEPON	; bag the beep if cw is not playing
	movf	hangDly,w	; get hang timer preset
	movwf   hangTmr		; preset hang timer
	bsf	txFlag,TXHANG	; set hang time transmit flag
	return			; done.

EEEval
	movf	EEADR,w		; get the address
	sublw	EEHANG		; subtract EEHANG address
	btfss	STATUS,C	; skip if EEADR <= EEHANG
	return			; out of config range, ignore
	movlw	h'02'		; in 2nd 1/4 k
	movwf	PCLATH		; ensure computed goto stays in range
	movf	EEADR,w		; get the address
	addwf	PCL,f		; computed goto
	goto	TstEnab
	goto	TstConf
	goto	TstDOUT
	goto	TstHang

TstEnab
	call	ReadEE		; get eeprom data
	movwf	enabFlg		; store enable flag
	bcf	mscFlag,RBRXENA	; clear this; will set soon if needed
	bcf	mscFlag,RBTXENA	; clear this; will set soon if needed
	bcf	mscFlag,RBALERT	; clear this; will set soon if needed
	movf	enabFlg,w	; get enable flag
	btfss	STATUS,Z        ; is it zero?
        goto    TstEnNZ         ; nope
        call    RxOff           ; turn off main receiver
        call    RBRxOff         ; turn off  rb  receiver
        bcf     PORTB,RB_PTT    ; turn off RB tx
        return                  ; done here...

TstEnNZ
	sublw	ENA_RBT		; subtract remote base transmit value
	btfss	STATUS,Z	; enable flag == ENA_RBT ?
	goto	TstEna0		; nope
	bsf	mscFlag,RBRXENA	; set remote base RX enable flag
	bsf	mscFlag,RBTXENA	; set remote base TX enable flag
        return                  ; done here

TstEna0				; turn off RB tx
	bcf	PORTB,RB_PTT	; turn off remote base PTT

	movf	enabFlg,w	; get enable flag
	sublw	ENA_RBR		; subtract remote base receive value
	btfsc	STATUS,Z	; enable flag == ENA_ALT ?
	goto	TstEnRE		; yes...
        call    RBRxOff
	goto	TstEnaA
TstEnRE
	bsf	mscFlag,RBRXENA	; set remote base RX enable  flag
        return                  ; done here...

TstEnaA
	movf	enabFlg,w	; get enable flag
	sublw	ENA_ALT		; subtract remote base alert value
	btfsc	STATUS,Z	; enable flag == ENA_ALT ?
	bsf	mscFlag,RBALERT	; set remote base alert flag
	return

TstConf
	call	ReadEE		; get eeprom data
	movwf   cfgFlag		; store w into config flag
        clrf    rxState         ; reset main receiver state
        clrf    rbState         ; reset  rb  receiver state
        movlw   b'11111100'     ; mask, all except receiver bit
        andwf   txFlag,f        ; clear 2 low bits of txFlag
        btfsc   cfgFlag,DOUTFAN ; is fan mode selected?
        return			; yes, ignore the rest
        movlw   EEDOUT          ; address of DOUT saved state
        call    ReadEE          ; read EEPROM
        movwf   temp            ; store in temp
        bcf     PORTB,DOUT      ; turn off control lead
        btfsc   temp,0          ; is low bit set? (DOUT on)
        bsf     PORTB,DOUT      ; turn on control lead
	return

TstDOUT
	call	ReadEE		; get eeprom data
	movwf	temp		; save data into temp
        btfsc   cfgFlag,DOUTFAN ; is DOUT in fan control mode?
        return                  ; yes.  can't change it.
        btfss   temp,1		; is bit 1 set?
        goto    Dout1
        bsf     PORTB,DOUT      ; turn DOUT on...
        movlw   d'5'            ; 1/2 sec
        movwf   fanTmr          ; set the timer to turn it off in 1/2 sec
	clrf	EEDATA		; reset to 0
	call	EEProg		; program to 0, don't want pulse on init
        return                  ; done here...

Dout1
        btfss   temp,0		; is low bit set?
        goto    Dout0           ; no
        bsf     PORTB,DOUT      ; yes, turn on DOUT
        return                  ; done here...

Dout0
        bcf     PORTB,DOUT      ; turn DOUT off
	return

TstHang
	call	ReadEE		; get eeprom data
	movwf	hangDly
	return

MsgCWID
	movlw	CW_ID		; force CW ID
	movwf	msgNum		; set message number
;
; Start sending a CW message
;
PlayMsg
StartCW
	bcf	mscFlag,LOWTONE	; set the low tone here
	call    GetCwMsg	; lookup message, put message offset in W
	movwf   cwBuff		; save offset
	call    ReadEE		; read byte from EEPROM
	movwf   cwByte		; save byte in CW bitmap
	movlw   CWIWSP		; get startup delay
	movwf   cwTmr		; preset cw timer
	bcf     flags,BEEPON    ; make sure that beep is off
	bsf     txFlag,CWPLAY   ; turn on CW sender
	call	PTTon		; turn on PTT...
	return
RxOff                           ; turn off main receiver
	movlw	RXSOFF		; get new state #
	movwf	rxState		; set new receiver state
	bcf	txFlag,RXOPEN	; clear main receiver on bit
	bsf     PORTA,MUTE      ; mute
	clrf	rxTout		; clear main receiver timeout timer
        return
        
RBRxOff                         ; turn off remote base receiver
       	movlw	RXSOFF		; no... get new state #
	movwf	rbState		; set new receiver state
	bcf	txFlag,RBOPEN	; clear  rb  receiver on bit
	bsf     PORTB,RB_MUTE	; mute
	clrf	rbTout		; clear  rb  receiver timeout timer
        return

;
; Read EEPROM byte
; address is supplied in W on call, data is returned in w
;
ReadEE
	movwf   EEADR		; EEADR = w
	bsf     STATUS,RP0      ; select bank 1
	bsf     EECON1,RD       ; read EEPROM
	bcf     STATUS,RP0      ; select bank 0
	movf    EEDATA,w	; get EEDATA into w
	return

;
; clear tone buffer and reset good digit counters
;
ClrTone
	movlw   TONES		; no... get number of command tones into w
	movwf   toneCnt		; preset number of command tones
	clrf    cmdCnt		; clear number of command bytes...
	clrf    tBuf1		; clear command buffer bytes
	clrf    tBuf2
	clrf    tBuf3
	return

;
; Play the appropriate ID message, reset ID timers & flags
;
DoID
	btfss	flags,needID	; need to ID?
	return			; nope...
	movlw   CW_ID		; CW ID
	movwf   msgNum		; set message number
	movlw   EEID		; get address of ID timer preset value
	call    ReadEE		; read EEPROM
	movwf   idTmr		; store to idTmr down-counter
	btfss	STATUS,Z	; is the idTmr zero?
	call    PlayMsg		; id timer is not zero, play the ID message
	bcf     flags,initID    ; clear initial ID flag
	movf	txFlag,w	; get tx flags
	andlw	h'03'		; w=w&(RXOPEN|RBOPEN), non zero if CT wanted
	btfsc	STATUS,Z	; is it zero?
	bcf	flags,needID	; yes. reset needID flag.
	return

;
; turn on PTT & set up ID timer, etc., if needed.
;
PTTon				; key the transmitter
	bsf	PORTB,PTT	; apply PTT!
	bsf	flags,lastTx	; set last tx state flag
	movf    idTmr,f		; check ID timer
	btfsc   STATUS,Z	; is it zero?
	goto    PTTinit		; yes
	btfsc	flags,needID	; is needID set?
	goto	FanOn		; yes.
	goto	PTTset		; not set, set needID and reset idTmr
PTTinit
	bsf     flags,initID    ; ID timer was zero, set initial ID flag
PTTset
	bsf	flags,needID	; need to play ID
	movlw   EEID		; get address of ID timer preset value
	call    ReadEE		; read EEPROM
	movwf   idTmr		; store to down-counter
	btfss	STATUS,Z	; is id timer zero?
	goto	FanOn		; nope.
	bcf     flags,initID    ; yes. don't ID.
	bcf	flags,needID	; id timer is zero, don't ID.
	
FanOn
	btfss	cfgFlag,DOUTFAN	; is fan control enabled?
	return			; no.
	clrf	fanTmr		; disable fan timer
	bsf	PORTB,DOUT	; turn on fan
	return

PTToff
	bcf	PORTB,PTT	; turn transmitter off
	bcf	flags,lastTx	; clear last tx state flag
	bcf	PORTB,RB_PTT	; turn off remote base PTT unequivocally
	btfss	cfgFlag,DOUTFAN	; is fan control enabled?
	return			; no.
	movlw	EEFAN		; get address of fan delay timer
	call	ReadEE		; read EEPROM
	movwf	fanTmr		; set fan timer
	return

ChkID				; call on receiver drop to see if want to ID
	btfsc   flags,initID    ; check initial id flag
	call	DoID		; play the ID
	btfss   flags,needID    ; need to ID?
	return
	;
	;if (idTmr <= idSoon) then goto StartID
	;implemented as: if ((IDSOON-idTimer)>=0) then ID
	;
	movf    idTmr,w		; get idTmr into W
	sublw   IDSOON		; IDSOON-w ->w
	btfsc   STATUS,C	; C is clear if result is negative
	call	DoID		; ok to ID now, let's do it.
	return			; don't need to ID yet...

;
; Program EEPROM byte
;
EEProg
	clrwdt			; this can take 10 ms, so clear WDT first
	bsf     STATUS,RP0      ; select bank 1
	bcf     INTCON,GIE      ; disable interrupts
	bsf     EECON1,WREN     ; enable EEPROM write
	movlw   h'55'
	movwf   EECON2		; write 55
	movlw   h'AA'
	movwf   EECON2		; write AA
	bsf     EECON1,WR       ; start write
	bcf     EECON1,WREN     ; disable write
EEPLoop
	nop
	btfsc   EECON1,WR       ; is write cycle complete?
	goto    EEPLoop		; wait for write to finish

	bsf     INTCON,GIE      ; enable interrupts
	bcf     STATUS,RP0      ; select bank 0
	return

	dw      'C'
	dw      'O'
	dw      'P'
	dw      'Y'
	dw      'R'
	dw      'I'
	dw      'G'
	dw      'H'
	dw      'T'
	dw      ' '
	dw      '('
	dw      'C'
	dw      ')'
	dw      ' '
	dw      '1'
	dw      '9'
	dw      '9'
	dw      '7'
	dw      ','
	dw      ' '
	dw      'J'
	dw      'E'
	dw      'F'
	dw      'F'
	dw      'R'
	dw      'E'
	dw      'Y'
	dw      ' '
	dw      'O'
	dw      'T'
	dw      'T'
	dw      'E'
	dw      'R'
	dw      'S'
	dw      'O'
	dw      'N'
	dw      '.'
	dw      ' '
	dw      ' '

	dw      'A'
	dw      'L'
	dw      'L'
	dw      ' '
	dw      'R'
	dw      'I'
	dw      'G'
	dw      'H'
	dw      'T'
	dw      'S'
	dw      ' '
	dw      'R'
	dw      'E'
	dw      'S'
	dw      'E'
	dw      'R'
	dw      'V'
	dw      'E'
	dw      'D'
	dw      '.'

	org     039fh
;
; EEPROM Memory Map (@ 2100h)
;   00 enable/disable flag
;   01 configuration flag
;   02 digital output control
;   03 hang timer preset
;   04 timeout timer preset
;   05 RB timeout timer preset
;   06 id timer preset
;   07 fan timer preset
;   08 NIY
;   09 NIY
;   0a-10 CW OK ( 7 bytes)
;   11-17 CW NG ( 7 bytes)
;   18-1e CW TO ( 7 bytes)
;   1f-25 CW RB TO ( 7 bytes)
;   26-3a CW id (21 bytes)
;   3b forced EOM
;   3c-3f Password (4 bytes)

;
; Lookup values to load EEPROM addresses with at initialize time...
;
InitDat
	movlw   h'03'		; this subroutine is in the top 256 bytes
	movwf   PCLATH		; ensure that computed goto will stay in range
	movf    EEADR,w		; get EEPROM address into w
	addwf   PCL,f		; add w to PCL
	retlw   h'01'		; 00 -- enable flag, initially enabled!
	retlw   h'00'		; 01 -- configuration flag
	retlw	h'00'		; 02 -- digital output control flag
	retlw   h'32'		; 03 -- hang timer preset, in tenths (5.0)
	retlw   h'b4'		; 04 -- timeout timer preset, in 1 seconds(180)
	retlw   h'b4'		; 05 -- RB timeout timer preset, in 1 seconds(180)
	retlw   h'36'		; 06 -- id timer preset, in 10 seconds (540)
	retlw   h'0c'		; 07 -- fan timer preset, in 10 seconds (120)
	retlw	h'01'		; 08 -- ct mask for pri rx
	retlw	h'11'		; 09 -- ct mask for pri rx, sec tx on
	retlw	h'13'		; 0a -- ct mask for pri rx, sec rx alert
	retlw	h'03'		; 0b -- ct mask for sec rx
	retlw	h'33'		; 0c -- ct mask for sec rx, sec tx on
	retlw	h'00'		; 0d -- NIY
	retlw   h'0f'		; 0e -- 'O'      1
	retlw   h'0d'		; 0f -- 'K'      2
	retlw   h'ff'		; 10 -- EOM      3
	retlw   h'ff'		; 11 -- EOM      4
	retlw   h'ff'		; 12 -- EOM      5
	retlw   h'ff'		; 13 -- EOM      6
	retlw   h'05'		; 14 -- 'N'      1
	retlw   h'0b'		; 15 -- 'G'      2
	retlw   h'ff'		; 16 -- EOM      3
	retlw   h'ff'		; 17 -- EOM      4
	retlw   h'ff'		; 18 -- EOM      5
	retlw   h'ff'		; 19 -- EOM      6
	retlw   h'03'		; 1a -- 'T'      1
	retlw   h'0f'		; 1b -- 'O'      2
	retlw   h'ff'		; 1c -- EOM      3
	retlw   h'ff'		; 1d -- EOM      4
	retlw   h'ff'		; 1e -- EOM      5
	retlw   h'ff'		; 1f -- EOM      7
	retlw   h'0a'		; 20 -- 'R'      1
	retlw   h'11'		; 21 -- 'B'      2
	retlw   h'00'		; 22 -- ' '      3
	retlw   h'03'		; 23 -- 'T'      4
	retlw   h'0f'		; 24 -- 'O'      5
	retlw   h'ff'		; 25 -- EOM      7
	retlw   h'09'		; 26 -- 'D'      1
	retlw   h'02'		; 27 -- 'E'      2
	retlw   h'00'		; 28 -- space    3
	retlw   h'05'		; 29 -- 'N'      4
	retlw   h'10'		; 2a -- 'H'      5
	retlw   h'0a'		; 2b -- 'R'      6
	retlw   h'15'		; 2c -- 'C'      7
	retlw   h'29'		; 2d -- '/'      8
	retlw   h'30'		; 2e -- '4'      9
	retlw   h'ff'		; 2f -- EOM     10
	retlw   h'ff'		; 30 -- EOM     11
	retlw   h'ff'		; 31 -- EOM     12  can fit 6 letter id....
	retlw   h'ff'		; 32 -- EOM     13
	retlw   h'ff'		; 33 -- EOM     14
	retlw   h'ff'		; 34 -- EOM     15
	retlw   h'ff'		; 35 -- EOM     16
	retlw   h'ff'		; 36 -- EOM     17
	retlw   h'ff'		; 37 -- EOM     18
	retlw   h'ff'		; 38 -- EOM     19
	retlw   h'ff'		; 39 -- EOM     20
	retlw   h'ff'		; 3a -- EOM     21
	retlw   h'ff'		; 3b -- EOM     22 /* last init address */

	page

; Lookup EEPROM address of CW message based on index of message
;
GetCwMsg
	movlw   h'03'		; this subroutine is in the top 256 bytes
	movwf   PCLATH		; ensure that computed goto will stay in range
	movf    msgNum,w	; get msgNum into w
	andlw	b'00000111'	; force it into range...
	addwf   PCL,f		; add w to PCL
	retlw   EECWID		; 0 = ID message
	retlw   EECWTO		; 1 = timeout message
	retlw   EECWOK		; 2 = ok message
	retlw   EECWNG		; 3 = ng message
	retlw   EECWRTO		; 4 = timeout message
	retlw	EECWNG		; 5 = NIY
	retlw	EECWNG		; 6 = NIY
	retlw	EECWNG		; 7 = NIY

; DTMF to HEX mapping
;
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
	movlw   h'03'		; this subroutine is in the top 256 bytes
	movwf   PCLATH		; ensure that computed goto will stay in range
	movf    tone,w		; get tone into w
	addwf   PCL,f		; add w to PCL
	retlw   0d		; 0 = D key
	retlw   01		; 1 = 1 key
	retlw   02		; 2 = 2 key
	retlw   03		; 3 = 3 key
	retlw   04		; 4 = 4 key
	retlw   05		; 5 = 5 key
	retlw   06		; 6 = 6 key
	retlw   07		; 7 = 7 key
	retlw   08		; 8 = 8 key
	retlw   09		; 9 = 9 key
	retlw   00		; A = 0 key
	retlw   0e		; B = * key (e)
	retlw   0f		; C = # key (f)

	retlw   0a		; D = A key
	retlw   0b		; E = B key
	retlw   0c		; F = C key


	IF LOADEE == 1
	org	2100h
	de	h'01'		; 00 -- enable flag
	de	h'10'		; 01 -- configuration flag
	de	h'00'		; 02 -- digital output control
	de	h'32'		; 03 -- hang timer preset, in tenths (5.0)
	de	h'b4'		; 04 -- timeout timer preset, in 1 seconds (180)
	de	h'b4'		; 05 -- RB timeout timer preset, in 1 seconds (180)
	de	h'36'		; 06 -- id timer preset, in 10 seconds (540)
	de	h'0c'		; 07 -- fan timer preset, in 10 seconds (120)
	de	h'01'		; 08 -- ct mask for pri rx
	de	h'11'		; 09 -- ct mask for pri rx, sec tx on
	de	h'31'		; 0a -- ct mask for pri rx, sec rx alert
	de	h'03'		; 0b -- ct mask for sec rx
	de	h'33'		; 0c -- ct mask for sec rx, sec rx alert
	de	h'00'		; 0d -- NIY
	de	h'0f'		; 0e -- 'O'      1
	de	h'0d'		; 0f -- 'K'      2
	de	h'ff'		; 10 -- EOM      4
	de	h'ff'		; 11 -- EOM      5
	de	h'ff'		; 12 -- EOM      6
	de	h'ff'		; 13 -- EOM      7
	de	h'05'		; 14 -- 'N'      1
	de	h'0b'		; 15 -- 'G'      2
	de	h'ff'		; 16 -- EOM      3
	de	h'ff'		; 17 -- EOM      4
	de	h'ff'		; 18 -- EOM      5
	de	h'ff'		; 19 -- EOM      6
	de	h'03'		; 1a -- 'T'      1
	de	h'0f'		; 1b -- 'O'      2
	de	h'ff'		; 1c -- EOM      3
	de	h'ff'		; 1d -- EOM      4
	de	h'ff'		; 1e -- EOM      5
	de	h'ff'		; 1f -- EOM      6
	de	h'0a'		; 20 -- 'R'      1
	de	h'11'		; 21 -- 'B'      2
	de	h'00'		; 22 -- space    3
	de	h'03'		; 23 -- 'T'      4
	de	h'0f'		; 24 -- 'O'      5
	de	h'ff'		; 25 -- EOM      6
	de	h'09'		; 26 -- 'D'      1
	IF DEBUG == 1
	de	h'ff'		; 27 -- EOM      2  debug, make ID real short.
	ELSE
	de	h'02'		; 27 -- 'E'      2
	endif
	de	h'00'		; 28 -- space    3
	de	h'05'		; 29 -- 'N'      4
	de	h'38'		; 2a -- '1'      5
	de	h'0d'		; 2b -- 'K'      6
	de	h'09'		; 2c -- 'D'      7
	de	h'0f'		; 2d -- 'O'      8
	de	h'29'		; 2e -- '/'      9
	de	h'0a'		; 2f -- 'R'     10
	de	h'ff'		; 30 -- EOM     11
	de	h'ff'		; 31 -- EOM     12  can fit 6 letter id....
	de	h'ff'		; 32 -- EOM     13
	de	h'ff'		; 33 -- EOM     14
	de	h'ff'		; 34 -- EOM     15
	de	h'ff'		; 35 -- EOM     16
	de	h'ff'		; 36 -- EOM     17
	de	h'ff'		; 37 -- EOM     18
	de	h'ff'		; 38 -- EOM     19
	de	h'ff'		; 39 -- EOM     20
	de	h'ff'		; 3a -- EOM     21
	de	h'ff'		; 3b -- EOM     ! don't write here !
	de	h'01'		; 3c -- password nibble 1
	de	h'02'		; 3d -- password nibble 2
	de	h'03'		; 3e -- password nibble 3
	de	h'04'		; 3f -- password nibble 4
	ENDIF
	end

; MORSE CODE encoding...
;
; morse characters are encoded in a single byte, bitwise, LSB to MSB.
; 0 = dit, 1 = dah.  the byte is shifted out to the right, until only
; a 1 remains.  characters with more than 7 elements (error) cannot be sent.
;
; sk ...-.- 01101000  58
; ar .-.-.  00101010  2a
; bt -...-  00110001  31
; / -..-.   00101001  29
; 0 -----   00111111  3f
; 1 .----   00111110  3e
; 2 ..---   00111100  3c
; 3 ...--   00111000  38
; 4 ....-   00110000  30
; 5 .....   00100000  20
; 6 -....   00100001  21
; 7 --...   00100011  23
; 8 ---..   00100111  27
; 9 ----.   00101111  2f
; a .-      00000110  06
; b -...    00010001  11
; c -.-.    00010101  15
; d -..     00001001  09
; e .       00000010  02
; f ..-.    00010100  14
; g --.     00001011  0b
; h ....    00010000  10
; i ..      00000100  04
; j .---    00011110  1e
; k -.-     00001101  0d
; l .-..    00010010  12
; m --      00000111  07
; n -.      00000101  05
; o ---     00001111  0f
; p .--.    00010110  16
; q --.-    00011011  1b
; r .-.     00001010  0a
; s ...     00001000  08
; t -       00000011  03
; u ..-     00001100  0c
; v ...-    00011000  18
; w .--     00001110  0e
; x -..-    00011001  19
; y -.--    00011101  1d
; z --..    00010011  13
; space     00000000  00 space (special exception)
; EOM       11111111  ff end of message (special exception)
