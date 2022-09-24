;*******************************************************************************
; NHRC-Remote Intelligent DTMF Remote Control.
; Copyright (C) 1998, 1999, 2001, 2002, 2003, NHRC LLC.
; All Rights Reserved.
;*******************************************************************************
; This software contains proprietary and confidential trade secrets of NHRC LLC.
; It may not be distributed in any source or binary form without the express
; written permission of NHRC LLC.
;
; 05 June 1998  1.0 Initial release.
; 15 November 2001 16F628 port
; 14 June 2002 v 1.1 bugfix release.
; 30 May 2003 v 1.2 bugfix release. 
;*******************************************************************************
VERSION EQU D'012'

; Set the DEBUG symbol to 1 to really speed up the software's internal clocks
; and timers for debugging in the simulator. Normally this is a 0.
DEBUG   EQU     0

; Set the LOADEE symbol to 1 to preload the EEPROM cells with data
; for debugging. Normally this is a 0.
LOADEE	EQU	0
;
        LIST P=16F628, F=INHX8M, R=HEX
        include "p16f628.inc"
	__FUSES _CP_ALL & _EXTCLK_OSC & _WDT_ON & _LVP_OFF & _MCLRE_OFF & _PWRTE_ON
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
;     1 - CW confirm message, "ok"
;     2 - CW bad message, "ng"
;

CW_ID   equ     h'00'		; CW ID
CW_OK   equ     h'01'		; CW OK
CW_NG   equ     h'02'		; CW NG
CW_HI   equ     h'03'		; CW HI
CW_LO   equ     h'04'		; CW LO
CW_PU   equ     h'05'		; CW PU

MAXPORT	equ	d'6'		; biggest acceptable port number

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
; A.4 (in ) = init input at start up, beep output after
;
;Port A
TMASK   equ     0f
INITBIT equ     4
BEEPBIT	equ	4		; beep and init share a.4
	
;
; Port B has the following
; B.0 (in ) = DTMF digit valid (in)
; B.1 (out) = PTT (out)
; B.2 (out) = control out 1
; B.3 (out) = control out 2
; B.4 (out) = control out 3
; B.5 (out) = control out 4
; B.6 (out) = control out 5
; B.7 (in ) = control out 6
;
;PortB
DV      equ     0		; DTMF digit valid
PTT     equ     1		; PTT 
OUT1	equ	2		; control output 1
OUT2	equ	3		; control output 1
OUT3	equ	4		; control output 1
OUT4	equ	5		; control output 1
OUT5	equ	6		; control output 1
OUT6	equ	7		; control output 1
	
;TFlags				; timer flags
TICK    equ     0		; 100 ms tick flag
TENTH   equ     1		; tenth second decrementer flag
ONESEC  equ     2		; one second decrementer flag
TENSEC  equ     3		; ten second decrementer flag
CWTICK  equ     4		; cw clock bit
CWPLAY  equ     5		; cw playing control bit
;NIY    equ     6		; NIY
LOWBEEP equ     7		; low beep tone divider bit

;flags                          ; operational flags
initID  equ     0		; need to ID now
needID  equ     1		; need to send ID
lastDV  equ     2		; last pass digit valid
init    equ     3		; initialize
NOSEC   equ     4		; no security mode.
;NIY    equ     5		; NIY
LOWTONE equ     6		; low beep selected
BEEPON  equ     7		; beep tone on

;
; EEPROM locations for data...
;
EEPCTRL equ     h'00'           ; port control
EEPMODE equ     h'01'           ; port mode, 0=on/off, 1=pulse
EEID    equ     h'02'           ; ID timer

EECWHI  equ     h'03'
EECWLO  equ     h'06'
EECWPU  equ     h'09'
EECWOK  equ     h'0c'
EECWNG  equ     h'0f'
EECWID  equ     h'12'
EEIEND  equ     h'3f'		; last EEPROM to program with data at init time
EELAST  equ     h'3b'		; last EEPROM address to init

EETTPR1 equ     h'3c'		; 1st passcode digit
EETTPR2 equ     h'3d'		; 2nd passcode digit
EETTPR3 equ     h'3e'		; 3rd passcode digit
EETTPR4 equ     h'3f'		; 4th passcode digit

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

TONEDLY equ     D'15'           ; 1.5 sec to enter next digit or evaluate
PORTDLY	equ	D'5'		; 0.5 sec port pulse delay
	
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
	cblock  20		; 80 bytes from 20 to 6f
	w_copy			; 20 saved W register for interrupt handler
	s_copy			; 21 saved status register for int handler
	ofCnt			; 22 100 ms timebase counter
	tFlags			; 23 Timer Flags
	flags			; 24 operating Flags
	cwCntr			; 25 cw timebase counter
	secCnt			; 26 one second count
	tenCnt			; 27 ten second count
        pCtrl                   ; 28 port control flag
        pMode                   ; 29 port mode flag
	pDelay			; 2a port delay counter
	idTmr			; 2b id timer, in 10 seconds
	msgNum			; 2c message number to play
	cwTmr			; 2d CW element timer
	cwBuff			; 2e CW message buffer offset
	cwByte			; 2f CW current byte (bitmap)
	tone			; 30 touch tone digit received
	toneCnt			; 31 digits received down counter
        toneTmr                 ; 32 tone validation timer
	cmdCnt			; 33 command digits received
	tBuf1			; 34 tones received buffer
	tBuf2			; 35 tones received buffer
	tBuf3			; 36 tones received buffer
	tBuf4			; 37 tones received buffer
	temp			; 38 temp value, use & abuse
	endc

	cblock  70		; 16 bytes from 70 to 7f are shared 
				; across all RAM pages...
	epradr			; eeprom address in low memory
	eprdata			; eeprom data in low memory
	endc

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
	btfss	flags,LOWTONE	; is the low beep selected?
	goto	HiBeep		; nope...
	btfsc	tFlags,LOWBEEP	; is the low beep bit counter clear?
	goto	LowBp1		; nope;  it's set...
	bsf	tFlags,LOWBEEP	; wasn't set, set it
	goto	TimrTst		; and continue on...
LowBp1
	bcf	tFlags,LOWBEEP	; clear the low beep bit
				; now go on and toggle the beep bit
HiBeep
	btfss   PORTA,BEEPBIT   ; is BEEPBIT set?
	goto    Beep0		; no
	bcf     PORTA,BEEPBIT   ; yes, turn it off
	goto    TimrTst		; continue
Beep0
	bsf     PORTA,BEEPBIT   ; beep bit is off, turn it on...

TimrTst
	decfsz  ofCnt,f		; decrement the overflow counter
	goto    TimrDone	; if not 0, then
	bsf     tFlags,TICK     ; set tick indicator flag
	movlw   OFBASE		; preset overflow counter
	movwf   ofCnt

TimrDone
	decfsz  cwCntr,f	; decrement the cw timebase counter
	goto    TIntDone	; done here
	bsf     tFlags,CWTICK   ; set tick indicator
	movlw   CWCNT		; get preset value
	movwf   cwCntr		; preset cw timebase counter

TIntDone
	bcf     INTCON,T0IF     ; clear RTCC int mask

IntExit
	pop			; restore W and STATUS
	retfie

Start
        clrf    PORTB           ; turn off all outputs

	movlw	h'07'		; turn off all comparators
	movwf	CMCON

	bsf     STATUS,RP0      ; select bank 1
	movlw   b'00011111'     ; RA0..4 are inputs
	movwf   TRISA		; set port port directions
	movlw   b'00000001'     ; RB0 is input
	movwf   TRISB

	IF DEBUG == 1
	movlw   b'10001000'     ; DEBUG! no pull up, timer 0 gets no prescale
	ELSE
	movlw   b'10000000'     ; no pull up, timer 0 gets prescale 2
	ENDIF

	movwf   OPTION_REG      ; set options

	bcf     STATUS,RP0      ; select page 0
	
	clrf	flags		; reset all operational flags
        clrf    tFlags          ; reset all timing flags
	clrf    PORTA		; make port a all low
	clrf    msgNum		; clear message number
        clrf    toneTmr         ; clear tone validation timer
	clrf	pDelay		; clear port pulse delay timer
	movlw   OFBASE		; preset overflow counter
	movwf   ofCnt
	movlw   CWCNT		; get preset value
	movwf   cwCntr		; preset cw timebase counter

	movlw   TEN		; preset decade counters
	movwf   secCnt		; 1 second down counter
	movwf   tenCnt		; 10 second down counter

	clrf    idTmr		; clear idTimer
	clrf    cmdCnt		; clear command counter
	movlw   TONES
	movwf   toneCnt		; preset tone counter

	btfsc   PORTA,INITBIT	; check to see if init is pulled low
	goto    NoInit		; init is not low, continue...

	bsf     flags,init	; initialization in progress

	movlw   EEIEND		; get last address to initialize
	movwf   epradr		; set EEPROM address to program
InitLp
	call    InitDat		; get init data byte
	movwf   eprdata		; put into EEPROM data register
	call    EEProg		; program byte
	movf    epradr,f	; load status, set Z if zero (last byte done)
	btfsc   STATUS,Z	; skip if Z is clear (not last byte)
	goto    NoInit		; done initializing EEPROM data
	decf    epradr,f	; decrement epradr
	goto    InitLp

NoInit
	bsf     STATUS,RP0      ; select bank 1
	movlw   b'00001111'     ; RA0..3 are inputs, RA4 is beep output now
	movwf   TRISA		; set port data direction
	bcf     STATUS,RP0      ; select bank 1

	movlw   EEPCTRL		; get address of port control byte
	movwf	epradr		; set EEPROM address
	call	EEEval		; get & evaluate data
	movlw   EEPMODE		; get address of port mode byte
	movwf	epradr		; set EEPROM address
	call	EEEval		; get & evaluate data

	call	ChkSec		; check to see if security is in effect.
	
	movlw   b'10100000'     ; enable interrupts, & Timer 0 overflow
	movwf   INTCON
	
Loop				; start of main loop
	clrwdt			; reset the watchdog timer
	;check CW bit
	btfss   tFlags,CWTICK   ; is the CWTICK set
	goto    NoCW
	bcf     tFlags,CWTICK   ; reset the CWTICK flag bit

	;
	;CW sender
	;
	btfss   tFlags,CWPLAY   ; sending CW?
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
	bcf     tFlags,CWPLAY   ; turn off CW flag
	bcf	PORTB,PTT	; turn off PTT

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

; ***************************************************************************\*****
; *********************************************************************************
; ***   MAIN LOOP STARTS HERE...                                                ***
; *********************************************************************************
; *********************************************************************************

Loop1

	btfss   tFlags,TENSEC   ; check to see if ten second tick
	goto    CkDela		; no timer tick... don't bother with timer

	movf    idTmr,f
	btfsc   STATUS,Z	; is idTmr 0
	goto    CkDela		; yes...

	decfsz  idTmr,f		; decrement ID timer
	goto    CkDela		; not zero yet...
				; id timer is zero! time to ID
	call	DoID		; play the ID

CkDela
	movf	pDelay,f	; check port pulse delay counter
	btfsc	STATUS,Z	; is it zero?
	goto	CkTone		; yep...
        btfss   tFlags,TENTH    ; tenth second tick?
        goto    CkTone          ; nope, don't bother decrementing
	decfsz	pDelay,f	; decrement port pulse delay
	goto	CkTone		; not zero yet...
	call	SetPort		; reset outputs to normal state....
	
CkTone
        movf    toneTmr,f       ; get tone timer
        btfsc   STATUS,Z        ; is it zero?
        goto    CkTone1         ; yes, don't bother decrementing
        btfss   tFlags,TENTH    ; tenth second tick?
        goto    CkTone1         ; nope, don't bother decrementing
        decfsz  toneTmr,f       ; decrement tone timer
        goto    CkTone1         ; not zero yet, continue

	movf    cmdCnt,f	; check to see if any stored tones
	btfsc   STATUS,Z	; is it zero?
	goto    CkTone1		; no stored tones

	movlw   MAXCMD		; get max # of command tones
	subwf   cmdCnt,w	; cmdCnt - MAXCMD -> w
	btfsc   STATUS,Z	; if Z is set then there are enough digits

	call	EvalTone	; evaluate tones!
        call    ClrTone         ; reset tone data

CkTone1        
	btfss   PORTB,DV	; check M8870 digit valid
	goto    NoTone		; not set
	btfsc   flags,lastDV    ; check to see if set on last pass
	goto	Loop		; it was already set, continue on
	bsf     flags,lastDV    ; set lastDV flag

MuteEnd
	movf    PORTA,w		; get DTMF digit
	andlw   TMASK		; mask off hi nibble
	movwf   tone		; save digit
	goto    Loop

NoTone
	btfss   flags,lastDV    ; is lastDV set
	goto	Loop		; nope, continue on...
	bcf     flags,lastDV    ; clear lastDV flag...

	btfsc   flags,init      ; in init mode?
	goto    WrTone		; yes, go write the tone

        movlw   TONEDLY         ; get tone timer
        movwf   toneTmr         ; save tone timer

	movf    toneCnt,w       ; test toneCnt
	btfss   STATUS,Z	; is it zero?
	goto    CkDigit		; no

	;password has been successfully entered, start storing tones

	;make sure that there is room for this digit
	movlw   MAXCMD		; get max # of command tones
	subwf   cmdCnt,w	; cmdCnt - MAXCMD -> w
	btfsc   STATUS,Z	; if Z is set then there is no more room
	goto    TooMany		; too many, start over...

	;there is room for this digit, calculate buffer address...
	movlw   tBuf1		; get address of first byte in buffer
	addwf   cmdCnt,w	; add offset
	movwf   FSR		; set indirection register
	movf    tone,w		; get tone
	call    MapDTMF		; convert to hex value
	movwf   INDF		; save into buffer location
	incf    cmdCnt,f	; increment cmdCnt
	goto    Wait

TooMany
	clrf	cmdCnt		; clear command count
	goto	Wait		; keep going
CkDigit
	;check this digit against the code table
	sublw   TONES		; w = TONES - w; w now has digit number
	addlw   EETTPR1		; w = w + EETTPR1; the digit's EEPROM address
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
	addlw   EETTPR1		; w = w + EETTPR1; the digit's EEPROM address
	movwf   epradr		; epradr = w
	movf    tone,w		; get tone
	movwf   eprdata		; put into EEPROM data register...
	call    EEProg		; call EEPROM prog routine

	decfsz  toneCnt,f       ; decrement tone count
	goto    Wait		; not zero, still in init mode
	bcf     flags,init      ; zero, out of init mode
	call	ChkSec		; check to see if security is in effect.
	
BadTone
	movlw   TONES		; no... get number of command tones into w
	movwf   toneCnt		; preset number of command tones
	btfsc	flags,NOSEC	; is security disabled?
	clrf	toneCnt		; yes.  clear toneCnt.

Wait
	goto    Loop		; last COR is also off, do nothing here
	
EvalTone			; evaluate touch tones in buffer
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
	movwf   epradr
	movf    tBuf3,w		; get data byte
	movwf   eprdata
	call    EEProg		; program EE byte

	call	EEEval		; evaluate the changed byte

	movlw   CW_OK
	movwf   msgNum
	call    PlayMsg
	return			; done

MsgCmd				; 4x, 5x, 6x, 7x commands
	movf    tBuf1,w		; get command byte
	andlw   b'10001110'     ; check for invalid values
	btfss   STATUS,Z	;
	goto    BadCmd		; only 40, 41, 50, 51, 60, 61, 70, 71 valid

	movlw   high CmdTbl	; this value must equal address' high byte
	movwf   PCLATH		; ensure that computed goto will stay in range

	swapf   tBuf1,w		; swap command byte into w
	andlw   b'00000011'     ; mask bits that make up remainder of command
	addwf   PCL,f		; add w to PCL
CmdTbl
	goto    Cmd4x		; bits 2-7 has been stripped so 4 = 0
	goto    Cmd5x
	goto    Cmd6x
	goto    Cmd7x

Cmd4x
	movf    tBuf3,w		; get argument
	goto	CmdRes		; play message and done

Cmd5x
	goto    BadCmd

Cmd6x				; command 6x
	movf	tBuf1,w		; get cmd
	andlw	h'0e'		; mask extra bits
	btfss	STATUS,Z	; 60 or 61 permitted only
	goto	BadCmd		; not 60 or 61
	call	GetPBit		; get mask
	btfsc	tBuf1,0		; is low bit of addr/cmd set?
	goto	Cmd61		; yes
	comf	pCtrl,f  	; invert the config flags byte
	iorwf	pCtrl,f		; set the specified bit
	comf	pCtrl,f  	; invert the config flags byte again
	movlw   CW_LO		; "LO" message
	goto	Cmd6xW		; go write the change

Cmd61				; set output on
	movwf	temp		; save port number
	andwf	pMode,w		; and in the mode register
	btfss	STATUS,Z	; will be zero if port is not in pulse mode
	goto	Cmd61P		; it's in pulse mode...
	movf	temp,w		; get back port number
	iorwf	pCtrl,f  	; set the specified bit
	movlw	CW_HI		; "HI" message
	goto	Cmd6xW		; go write the change

Cmd61P				; pulse operation...
	movf	temp,w		; get back port number
	iorwf	PORTB,f		; set port bit
	movlw	PORTDLY		; get port pulse delay
	movwf	pDelay		; set the countdown timer
	movlw	CW_PU		; "PU" message
	call	PlayPMs		; play port control message
	return			; done here
	
Cmd6xW
	movwf	msgNum		; store message number
	movlw	EEPCTRL		; get the address for port control byte
	movwf	epradr		; store the eeprom address
	movf	pCtrl,w  	; get the config flag
        movwf   eprdata		; move it to the EEPROM data buffer
        call    EEProg          ; program EE byte
	call	EEEval		; evaluate the changed byte
	call	PlayPMs		; play port control message
	return			; done here
		
Cmd7x
	movf	tBuf1,w		; get cmd
	andlw	h'0e'		; mask extra bits
	btfss	STATUS,Z	; 70 or 71 permitted only
	goto	BadCmd		; not 70 or 71
	call	GetPBit		; get mask
	btfsc	tBuf1,0		; is low bit of addr/cmd set?
	goto	Cmd71		; yes
	comf	pMode,f  	; invert the config flags byte
	iorwf	pMode,f		; set the specified bit
	comf	pMode,f  	; invert the config flags byte again
	goto	Cmd7xW		; go write the change

Cmd71				; set config bit
	iorwf	pMode,f  	; set the specified bit
Cmd7xW
	movlw	EEPMODE		; get the address for port control byte
	movwf	epradr		; store the eeprom address
	movf	pMode,w  	; get the config flag
        movwf   eprdata		; move it to the EEPROM data buffer
        call    EEProg          ; program EE byte
	call	EEEval		; evaluate the changed byte
	goto	GoodCmd
	
NoCmd				; no command was received
	btfss	flags,init	; in init mode?
	goto    GoodCmd		; nope
	movlw	CW_ID		; select CW ID message
	goto	CmdRes		; play ID since in init mode

BadCmd
	movlw   CW_NG
	goto    CmdRes
GoodCmd
	movlw   CW_OK
CmdRes
	movwf   msgNum
	call    PlayMsg
CmdDone
	return

SetPort
	btfss	pCtrl,2		; check bit 2
	goto	P2lo
	bsf	PORTB,2		; set bit 2
	goto	CkP3
P2lo
	bcf	PORTB,2		; clear bit 2

CkP3
	btfss	pCtrl,3		; check bit 3
	goto	P3lo
	bsf	PORTB,3		; set bit 3
	goto	CkP4
P3lo
	bcf	PORTB,3		; clear bit 3

CkP4
	btfss	pCtrl,4		; check bit 4
	goto	P4lo
	bsf	PORTB,4		; set bit 4
	goto	CkP5
P4lo
	bcf	PORTB,4		; clear bit 4

CkP5
	btfss	pCtrl,5		; check bit 5
	goto	P5lo
	bsf	PORTB,5		; set bit 5
	goto	CkP6
P5lo
	bcf	PORTB,5		; clear bit 5

CkP6
	btfss	pCtrl,6		; check bit 6
	goto	P6lo
	bsf	PORTB,6		; set bit 6
	goto	CkP7
P6lo
	bcf	PORTB,6		; clear bit 6

CkP7
	btfss	pCtrl,7		; check bit 7
	goto	P7lo
	bsf	PORTB,7		; set bit 7
	return
P7lo
	bcf	PORTB,7		; clear bit 7
	return

	
GetBit				; return mask in w with bit w set
        movlw   high GBTbl	; in range 100-1ff
        movwf   PCLATH          ; ensure that computed goto will stay in range
	movf	tBuf3,w		; get the selected bit
	andlw	h'07'		; must be in 0-7 range
	addwf	PCL,f		; computed goto
GBTbl
	retlw	b'00000001'	; bit 0
	retlw	b'00000010'	; bit 1
	retlw	b'00000100'	; bit 2
	retlw	b'00001000'	; bit 3
	retlw	b'00010000'	; bit 4
	retlw	b'00100000'	; bit 5
	retlw	b'01000000'	; bit 6
	retlw	b'10000000'	; bit 7

GetPBit				; get port bit...
        movlw   high GPBTbl	; in range 100-1ff
        movwf   PCLATH          ; ensure that computed goto will stay in range
	movf	tBuf3,w		; get the selected bit
	andlw	h'07'		; must be in 0-7 range
	addwf	PCL,f		; computed goto
GPBTbl
	retlw	b'00000000'	; port 0 -- not valid
	retlw	b'00000100'	; port 1 -- bit 2 -- output #1
	retlw	b'00001000'	; port 2 -- bit 3 -- output #2
	retlw	b'00010000'	; port 3 -- bit 4 -- output #3
	retlw	b'00100000'	; port 4 -- bit 5 -- output #4
	retlw	b'01000000'	; port 5 -- bit 6 -- output #5
	retlw	b'10000000'	; port 6 -- bit 7 -- output #6
	retlw	b'00000000'	; port 7 -- not valid 
	
GetPCW 				; get port number CW character
        movlw   high PCWTbl	; in range 100-1ff
        movwf   PCLATH          ; ensure that computed goto will stay in range
	movf	tBuf3,w		; get the selected bit
	andlw	h'07'		; must be in 0-7 range
	addwf	PCL,f		; computed goto
PCWTbl
	retlw	h'02'      	; port 0 -- not valid -'E'
	retlw	h'3e'      	; port 1 -- bit 2 -- output #1 - '1'
	retlw	h'3c'      	; port 2 -- bit 3 -- output #2 - '2'
	retlw	h'38'      	; port 3 -- bit 4 -- output #3 - '3'
	retlw	h'30'      	; port 4 -- bit 5 -- output #4 - '4'
	retlw	h'20'       	; port 5 -- bit 6 -- output #5 - '5'
	retlw	h'21'      	; port 6 -- bit 7 -- output #6 - '6' 
	retlw	h'02'      	; port 7 -- not valid - 'E'
	
EEEval
	movf	epradr,w	; get the address
        sublw   EEPMODE         ; subtract hi eval address
        btfss   STATUS,C        ; is result negative?
        return                  ; nope
	movlw	high EEETbl	; in 1st 1/4 k
	movwf	PCLATH		; ensure computed goto stays in range
	movf	epradr,w	; get the address
	addwf	PCL,f		; computed goto
EEETbl
	goto	TstCtrl
	goto	TstMode

TstCtrl                         ; evaluate port control byte
	call	ReadEE		; get eeprom data
        movwf   pCtrl           ; set control outputs temp storage
	call	SetPort		; set up output port...
        return                  ; done here...

TstMode
	call	ReadEE		; get eeprom data
        movwf   pMode           ; set control output mode temp storage
	return

ChkSec				; check to see if in secured mode
	movlw	EETTPR1		; get address of first passcode location
	call	ReadEE		; get data
	xorlw	h'0a'		; is it the zero key?
	btfss	STATUS,Z	; skip if result is zero.
	goto	SecOn		; not zero, security is on
	movlw	EETTPR2		; get address of first passcode location
	call	ReadEE		; get data
	xorlw	h'0a'		; is it the zero key?
	btfss	STATUS,Z	; skip if result is zero.
	goto	SecOn		; not zero, security is on
	movlw	EETTPR3		; get address of first passcode location
	call	ReadEE		; get data
	xorlw	h'0a'		; is it the zero key?
	btfss	STATUS,Z	; skip if result is zero.
	goto	SecOn		; not zero, security is on
	movlw	EETTPR4		; get address of first passcode location
	call	ReadEE		; get data
	xorlw	h'0a'		; is it the zero key?
	btfss	STATUS,Z	; skip if result is zero.
	goto	SecOn		; not zero, security is on
	
	bsf	flags,NOSEC	; security is not in effect.
	clrf	toneCnt		; clear tone counter.
	return

SecOn	 			; security is ON.
	bcf	flags,NOSEC	; security is ON.
	movlw   TONES		; get password tones count.
	movwf   toneCnt		; preset tone counter
	return			; done
	
MsgCWID
	movlw	CW_ID		; force CW ID
	movwf	msgNum		; set message number
;
; Start sending a CW message
;
PlayMsg
	bcf     flags,BEEPON    ; make sure that beep is off
	bcf	flags,LOWTONE	; set the high tone here
	call    GetCwMsg	; lookup message, put message offset in W
	movwf   cwBuff		; save offset
	call    ReadEE		; read byte from EEPROM
	movwf   cwByte		; save byte in CW bitmap
	movlw   CWIWSP		; get startup delay
	movwf   cwTmr		; preset cw timer
	bsf     tFlags,CWPLAY   ; turn on CW sender
	call	PTTon		; turn on PTT...
	return

PlayPMs
	bcf     flags,BEEPON    ; make sure that beep is off
	bcf	flags,LOWTONE	; set the high tone here
	call    GetCwMsg	; lookup message, put message offset in W
	movwf   cwBuff		; save offset
	decf	cwBuff,f	; backup one to fake continued message
	call	GetPCW		; get port # CW char...
	movwf   cwByte		; save byte in CW bitmap
	movlw   CWIWSP		; get startup delay
	movwf   cwTmr		; preset cw timer
	bsf     tFlags,CWPLAY   ; turn on CW sender
	call	PTTon		; turn on PTT...
	return

;
; Read EEPROM byte
; address is supplied in W on call, data is returned in w
;
ReadEE
	bsf     STATUS,RP0      ; select bank 1
	movwf   EEADR		; EEADR = w
	bsf     EECON1,RD       ; read EEPROM
	movf    EEDATA,w	; get EEDATA into w
	bcf     STATUS,RP0      ; select bank 0
	return

;
; Program EEPROM byte
;
EEProg
        bcf     INTCON,GIE      ; disable interrupts
	btfsc	INTCON,GIE	; is it really off?
	goto	EEProg		; no, try to turn interrupts off again.
	clrwdt			; this can take 10 ms, so clear WDT first
	bcf     INTCON,GIE      ; disable interrupts
	bsf     STATUS,RP0      ; select bank 1
	movf	epradr,w	; get address
	movwf	EEADR		; set eeprom address
	movf	eprdata,w	; get data
	movwf	EEDATA		; set data int EPROM data register.
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

	bcf     STATUS,RP0      ; select bank 0
	bsf     INTCON,GIE      ; enable interrupts
	return

;
; clear tone buffer and reset good digit counters
;
ClrTone
	movlw   TONES		; no... get number of command tones into w
	movwf   toneCnt		; preset number of command tones
	btfsc	flags,NOSEC	; is security disabled?
	clrf	toneCnt		; yes.
	clrf    cmdCnt		; clear number of command bytes...
	clrf    tBuf1		; clear command buffer bytes
	clrf    tBuf2
	clrf    tBuf3
	clrf    tBuf4
	return

;
; Play the appropriate ID message, reset ID timers & flags
;
DoID
	btfss	flags,needID	; need to ID?
	return			; nope...
	movlw   CW_ID		; CW ID
	movwf   msgNum		; set message number
	call    PlayMsg		; play the message
	movlw   EEID		; get address of ID timer preset value
	call    ReadEE		; read EEPROM
	movwf   idTmr		; store to idTmr down-counter
	bcf	flags,needID	; yes. reset needID flag.
	return

;
; turn on PTT & set up ID timer, etc., if needed.
;
PTTon				; key the transmitter
	bsf	PORTB,PTT	; apply PTT!
	movf    idTmr,f		; check ID timer
	btfsc   STATUS,Z	; is it zero?
	goto    PTTinit		; yes
	btfsc	flags,needID	; is needID set?
	goto	PTTset		; not set, set needID and reset idTmr
PTTinit
	bsf     flags,initID    ; ID timer was zero, set initial ID flag
PTTset
	bsf	flags,needID	; need to play ID
	movlw   EEID		; get address of ID timer preset value
	call    ReadEE		; read EEPROM
	movwf   idTmr		; store to down-counter

PTToff
	return

ChkID				; call on receiver drop to see if want to ID
	btfsc   flags,initID    ; check initial id flag
	call	DoID		; play the ID
	btfss   flags,needID    ; need to ID?
	return

;
; Lookup values to load EEPROM addresses with at initialize time...
;
InitDat
	movlw   high InitTbl	; this subroutine is in the top 256 bytes
	movwf   PCLATH		; ensure that computed goto will stay in range
	movf    epradr,w	; get EEPROM address into w
	addwf   PCL,f		; add w to PCL
InitTbl
	retlw   h'00'		; 00 -- port control, initally all off
	retlw   h'00'		; 01 -- port mode, initially all on/off (not pulse)
	retlw	h'32'		; 02 -- ID timer
	retlw   h'10'		; 03 -- 'H'      1
	retlw   h'04'		; 04 -- 'I'      2
	retlw   h'ff'		; 05 -- EOM      3
	retlw   h'12'		; 06 -- 'L'      1
	retlw   h'0f'		; 07 -- 'O'      2
	retlw	h'ff'		; 08 -- EOM      3
	retlw	h'16'		; 09 -- 'P'      1
	retlw	h'0c'		; 0a -- 'U'      2
	retlw	h'ff'		; 0b -- EOM      3
	retlw   h'0f'		; 0c -- 'O'      1
	retlw   h'0d'		; 0d -- 'K'      2
	retlw   h'ff'		; 0e -- EOM      3
	retlw   h'05'		; 0f -- 'N'      1
	retlw   h'0b'		; 10 -- 'G'      2
	retlw   h'ff'		; 11 -- EOM      7
	retlw   h'09'		; 12 -- 'D'      1
	retlw   h'02'		; 13 -- 'E'      2
	retlw   h'00'		; 14 -- space    3
	retlw   h'05'		; 15 -- 'N'      4
	retlw   h'10'		; 16 -- 'H'      5
	retlw   h'0a'		; 17 -- 'R'      6
	retlw   h'15'		; 18 -- 'C'      7
	retlw   h'29'		; 19 -- '/'      8
	retlw   h'0a'		; 1a -- 'R'      9
	retlw   h'02'		; 1b -- 'E'     10
	retlw   h'07'		; 1c -- 'M'     11
	retlw   h'0f'		; 1d -- 'O'     12
	retlw   h'03'		; 1e -- 'T'     13
	retlw   h'02'		; 1f -- 'E'     14
	retlw   h'ff'		; 20 -- EOM     15
	retlw   h'ff'		; 21 -- EOM     16
	retlw   h'ff'		; 22 -- EOM     17
	retlw   h'ff'		; 23 -- EOM     18
	retlw   h'ff'		; 24 -- EOM     19
	retlw   h'ff'		; 25 -- EOM     20
	retlw   h'ff'		; 26 -- EOM     21
	retlw   h'ff'		; 27 -- EOM     21
	retlw   h'ff'		; 28 -- EOM     21
	retlw   h'ff'		; 29 -- EOM     21
	retlw   h'ff'		; 2a -- EOM     21
	retlw   h'ff'		; 2b -- EOM     21
	retlw   h'ff'		; 2c -- EOM     21
	retlw   h'ff'		; 2d -- EOM     21
	retlw   h'ff'		; 2e -- EOM     21
	retlw   h'ff'		; 2f -- EOM     21
	retlw   h'ff'		; 30 -- EOM     21
	retlw   h'ff'		; 31 -- EOM     21
	retlw   h'ff'		; 32 -- EOM     21
	retlw   h'ff'		; 33 -- EOM     21
	retlw   h'ff'		; 34 -- EOM     21
	retlw   h'ff'		; 35 -- EOM     21
	retlw   h'ff'		; 36 -- EOM     21
	retlw   h'ff'		; 37 -- EOM     21
	retlw   h'ff'		; 38 -- EOM     21
	retlw   h'ff'		; 39 -- EOM     21
	retlw   h'ff'		; 3a -- EOM     21
	retlw   h'ff'		; 3b -- EOM     22 /* last init address */
	retlw	h'ff'		; 3c -- 0a
	retlw	h'ff'		; 3d -- 0a
	retlw	h'ff'		; 3e -- 0a
	retlw	h'ff'		; 3f -- 0a

	page

; Lookup EEPROM address of CW message based on index of message
;
GetCwMsg
	movlw   high CWMTbl	; this subroutine is in the top 256 bytes
	movwf   PCLATH		; ensure that computed goto will stay in range
	movf    msgNum,w	; get msgNum into w
	andlw	b'00000111'	; force it into range 0-7
	addwf   PCL,f		; add w to PCL
CWMTbl
	retlw   EECWID		; 0 = ID message
	retlw   EECWOK		; 1 = OK message
	retlw   EECWNG		; 2 = NG message
	retlw   EECWHI		; 3 = HI message
	retlw   EECWLO		; 4 = LO message
	retlw   EECWPU		; 5 = PU message
	retlw   EECWNG		; 6 = NG message, fallthru
	retlw   EECWNG		; 7 = NG message, fallthru


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
	movlw   high DTMFTbl	; this subroutine is in the top 256 bytes
	movwf   PCLATH		; ensure that computed goto will stay in range
	movf    tone,w		; get tone into w
	addwf   PCL,f		; add w to PCL
DTMFTbl
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
	de	h'00'		; 00 -- port control flag
	de	h'00'		; 01 -- port mode flag
	de	h'36'		; 02 -- ID timer preset, in 10 seconds (540)
	de	h'10'		; 03 -- 'H'      1
	de	h'04'		; 04 -- 'I'      2
	de	h'ff'		; 05 -- EOM      3
	de	h'12'		; 06 -- 'L'      1
	de	h'0f'		; 07 -- 'O'      2
	de	h'ff'		; 08 -- EOM      3
	de	h'16'		; 09 -- 'P'      1
	de	h'0c'		; 0a -- 'U'      2
	de	h'ff'		; 0b -- EOM      3
	de	h'0f'		; 0c -- 'O'      1
	de	h'0d'		; 0d -- 'K'      2
	de	h'ff'		; 0e -- EOM      4
	de	h'05'		; 0f -- 'N'      1
	de	h'0b'		; 10 -- 'G'      2
	de	h'ff'		; 11 -- EOM      3
	de	h'09'		; 12 -- 'D'      1
	IF DEBUG == 1
	de	h'ff'		; 13 -- EOM      2  debug, make ID real short.
	ELSE
	de	h'02'		; 13 -- 'E'      2
	endif
	de	h'00'		; 14 -- space    3
	de	h'05'		; 15 -- 'N'      4
        de	h'38'		; 16 -- '1'      5
	de	h'0d'		; 17 -- 'K'      6
	de	h'09'		; 18 -- 'D'      7
	de	h'0f'		; 19 -- 'O'      8
	de	h'29'		; 1a -- '/'      9
	de	h'0a'		; 1b -- 'R'     10
	de	h'ff'		; 1c -- EOM     11
	de	h'ff'		; 1d -- EOM     12  can fit 6 letter id....
	de	h'ff'		; 1e -- EOM     13
	de	h'ff'		; 1f -- EOM     14
	de	h'ff'		; 20 -- EOM     15
	de	h'ff'		; 21 -- EOM     16
	de	h'ff'		; 22 -- EOM     17
	de	h'ff'		; 23 -- EOM     18
	de	h'ff'		; 24 -- EOM     19
	de	h'ff'		; 25 -- EOM     20
	de	h'ff'		; 26 -- EOM     21
	de	h'ff'		; 27 -- EOM     22
	de	h'ff'		; 28 -- EOM     23
	de	h'ff'		; 29 -- EOM     24
	de	h'ff'		; 2a -- EOM     25
	de	h'ff'		; 2b -- EOM     26
	de	h'ff'		; 2c -- EOM     27
	de	h'ff'		; 2d -- EOM     28
	de	h'ff'		; 2e -- EOM     29
	de	h'ff'		; 2f -- EOM     30
	de	h'ff'		; 30 -- EOM     31
	de	h'ff'		; 31 -- EOM     32
	de	h'ff'		; 32 -- EOM     33
	de	h'ff'		; 33 -- EOM     34
	de	h'ff'		; 34 -- EOM     35
	de	h'ff'		; 35 -- EOM     36
	de	h'ff'		; 36 -- EOM     37
	de	h'ff'		; 37 -- EOM     38
	de	h'ff'		; 38 -- EOM     39
	de	h'ff'		; 39 -- EOM     40
	de	h'ff'		; 3a -- EOM     41
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
