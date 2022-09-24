;*******************************************************************************
; PIC 16C84 Based Repeater Controller.
; Copyright (C) 1996, 1997 Jeffrey B. Otterson, N1KDO.  
; All Rights Reserved by the author.
;*******************************************************************************
; This software contains proprietary trade secrets of the Nasty Hacker's
; Repeater Consortium (NHRC).  It may not be distributed in any source or 
; binary form without the express written permission of the NHRC.
; 
; 17 October 1997
;*******************************************************************************
VERSION EQU D'045'

; Set the F84 symbol to 1 if you are going to assemble this code to run on 
; a 16F84.  Set it to 0 for 16C84
F84	EQU	0

; Set the NHRC3 symbol to 1 if you are targetting a NHRC-3 or NHRC-3/M2.
; Set it to 0 for NHRC-2
NHRC3	EQU	1
	
; Set the DEBUG symbol to 1 to really speed up the software's internal clocks
; and timers for debugging in the simulator. Normally this is a 0.
DEBUG   EQU     0

; Set the LOADEE symbol to 1 to preload the EEPROM cells with debugging data
; for debugging. Normally this is a 0.
LOADEE	EQU	1
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
;   Stored Audio:
;     0 - Initial ID, "Welcome to N1KDO repeater"
;     1 - Normal ID, "N1KDO repeater"
;     2 - Timeout message, "Repeater Timeout"
;     3 - Tail message, "Club meeting tonight"
;   CW messages:
;     0 - CW ID, "de n1kdo/r"
;     1 - CW timeout message, "to"
;     2 - CW confirm message, "ok"
;     3 - CW bad message, "ng"
;

CW_ID   equ     h'00'		; CW ID
CW_TO   equ     h'01'		; CW timeout
CW_OK   equ     h'02'		; CW OK
CW_NG   equ     h'03'		; CW NG
ISD_IID equ     h'10'		; ISD initial ID
ISD_ID  equ     h'11'		; ISD normal ID
ISD_TO  equ     h'12'		; ISD timeout message
ISD_TM  equ     h'13'		; ISD tail message
ISD_SM  equ     h'14'		; ISD simplex repeater message 

INOTID	equ	1		; indicates NOT isd ID message
ISDSIM  equ     2		; indicates simplex message
ISDMSG  equ     4		; indicates message is for ISD
MSGREC  equ     7		; set high bit to indicate record mode

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
; B.0 (in ) = DTMF digit valid
; B.1 (out) = PTT
; B.2 (out) = ISD playl\
; B.3 (out) = ISD A0
; B.4 (out) = ISD A1
; B.5 (out) = ISD record\
; B.6 (out) = beep tone output
; B.7 (in ) = COR
;
;PortB
dv      equ     0		; DTMF digit valid
ptt     equ     1		; PTT key
isdPlay equ     2		; ISD play   / chip enable
isdRec  equ     3		; ISD record / record (0)-play (1) select
isdA0   equ     4		; ISD message select bit 0 
isdA1   equ     5		; ISD message select bit 1
beepBit equ     6		; beep generator
cor     equ     7		; unsquelched (0) / squelched (1)

CTL0    equ     2		; output lead zero when no ISD
CTL1    equ     3		; output lead one  when no ISD

;TFlags				; timer flags
TICK    equ     0		; 100 ms tick flag
TENTH   equ     1		; tenth second decrementer flag
ONESEC  equ     2		; one second decrementer flag
TENSEC  equ     3		; ten second decrementer flag
CWTICK  equ     4		; cw clock bit
SAYOK	equ	6		; force OK message flag
TFLCOR  equ     7		; debounced cor
	
;flags
initID  equ     0		; need to ID now
needID  equ     1		; need to send ID
lastDV  equ     2		; last pass digit valid
init    equ     3		; initialize
lastCor equ     4		; last COR flag
isdRecF equ     5		; ISD record flag
cwOn    equ     6		; cw sender is active...
beepOn  equ     7		; beep tone on

;cfgFlag
NOISD   equ     0		; no ISD part
SIMPLEX equ     1		; simplex repeater mode
ISD2560 equ     2		; ISD2560 part mode
ISD2590 equ     3		; ISD2590 part mode
NOCTSY  equ     4		; suppress courtesy tone
NOMUTE  equ     5		; don't mute touch-tones
ISDCTSY equ     6		; play ISD message 3 for courtesy tone
ALTID   equ	7		; alternate ID control

ISD25XX equ	B'00001100'	; mask for ISD25xx bits

;state, bit 0 set indicates transmitter should be on...
SQUIET  equ     0
SRPT    equ     1
STIMOUT equ     2
SHANG   equ     3
SDISABL equ     4

ACTIVE	equ	0		; active BIT, if set don't turn off PTT

;debounce count complete Bit 
        IF DEBUG == 1
CDBBIT  equ     1               ; debounce counts to 2, about 1.143 ms?
CDBVAL	equ	2
        ELSE
CDBBIT  equ     5               ; debounce counts to 32, about 18.2 ms
CDBVAL	equ	32
        ENDIF

;
; EEPROM locations for data...
;
EEENAB  equ     h'00'
EECONF  equ     h'01'
EEHANG  equ     h'02'
EETOUT  equ     h'03'
EEID    equ     h'04'
EETMSG  equ     h'05'
EECWOK  equ     h'06'
EECWNG  equ     h'09'
EECWTO  equ     h'0c'
EECWID  equ     h'0f'
EEIEND  equ     h'1a'           ; last EEPROM to program with data at init time
EELAST  equ     h'37'           ; last EEPROM address to init

EEM0LEN equ     h'38'
EEM1LEN equ     h'39'
EEM2LEN equ     h'3a'
EEM3LEN equ     h'3b'
EETTPRE equ     h'3c'

;
;DTMF remote control constants
;
TONES   EQU     4               ; number of digits in touch tone command
MAXCMD  EQU     4               ; maximum number of digits in command

;
; CW sender constants
;
CWDIT   equ     1               ; dit = 100 ms
CWDAH   equ     CWDIT * 3       ; dah = 300 ms
CWIESP  equ     CWDIT           ; inter-element space = 100 ms
CWILSP  equ     CWDAH           ; inter-letter space = 300 ms
CWIWSP  equ     7               ; inter-word space = 700 ms

ISDBKOF EQU     D'3'            ; preset simplex ISD backoff time .3 sec

        IF DEBUG == 1
OFBASE  equ     D'2'            ; overflow counts fast!
TEN     equ     D'2'
        ELSE
OFBASE  equ     D'175'          ; overflow counts in 100.12 ms
TEN     equ     D'10'
        ENDIF

CWCNT   equ     D'105'          ; approximately 60 ms for 20 wpm

IDSOON  equ     D'6'            ; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ     D'20'           ; DTMF muting timer

;macro definitions
push    macro
        movwf   w_copy          ; save w reg in Buffer
        swapf   w_copy,f        ; swap it
        swapf   STATUS,w        ; get status
        movwf   s_copy          ; save it
        endm
;
pop     macro
        swapf   s_copy,w        ; restore status
        movwf   STATUS          ;       /
        swapf   w_copy,w        ; restore W reg
        endm

	IF NHRC3 == 0		; NHRC-3 target?
				; ISD Controls are inverted
	
ISDPON  macro			; turn on ISD PLAYL/CS\&PD\ (play)
	bsf	PORTB,isdPlay
	endm

ISDPOFF	macro			; turn off ISD PLAYL/CD\&PD\ (stop playing)
	bcf	PORTB,isdPlay
	endm

ISDRON	macro			; turn on ISD RECL/PR\ (start recording)
	bsf	PORTB,isdRec
	endm

ISDROFF	macro			; turn off ISD RECL/PR\ (stop recording)
	bcf	PORTB,isdRec
	endm

	ELSE
		
ISDPON  macro			; turn on ISD PLAYL/CS\&PD\ (play)
	bcf	PORTB,isdPlay
	endm

ISDPOFF	macro			; turn off ISD PLAYL/CD\&PD\ (stop playing)
	bsf	PORTB,isdPlay
	endm

ISDRON	macro			; turn on ISD RECL/PR\ (start recording)
	bcf	PORTB,isdRec
	endm

ISDROFF	macro			; turn off ISD RECL/PR\ (stop recording)
	bsf	PORTB,isdRec
	endm

	ENDIF
	
;variables
        cblock  0c
        w_copy                  ; saved W register for interrupt handler
        s_copy                  ; saved status register for int handler
        cfgFlag                 ; Configuration Flags
        tFlags                  ; Timer Flags
        flags                   ; operating Flags
        ofCnt                   ; 100 ms timebase counter
        cwCntr                  ; cw timebase counter
        secCnt                  ; one second count
        tenCnt                  ; ten second count
        state                   ; CAS state
        hangDly                 ; hang timer preset, in tenths
        tOutDly                 ; timeout timer preset, in 1 seconds
        idDly                   ; id timer preset, in 10 seconds
        hangTmr                 ; hang timer, in tenths
        tOutTmr                 ; timeout timer, in 1 seconds
        idTmr                   ; id timer, in 10 seconds
        sISDTmr                 ; simplex ISD back-off timer
        muteTmr                 ; DTMF muting timer, in tenths
        cwTmr                   ; CW element timer
        msgNum                  ; message number to play
        tone                    ; touch tone digit received
        toneCnt                 ; digits received down counter
        cmdCnt                  ; command digists received
        tBuf1                   ; tones received buffer
        tBuf2                   ; tones received buffer
        tBuf3                   ; tones received buffer
        tBuf4                   ; tones received buffer
        cwBuff                  ; CW message buffer offset
        cwByte                  ; CW current byte (bitmap)                 
        tMsgCtr                 ; tail message counter
        dBounce                 ; cor debounce counter

        isdPlaL                 ; ISD1240 playback timer, tenths, low word
        isdPlaH                 ; ISD1240 playback timer, tenths, hi word
        isdRecL                 ; ISD1240 record timer, tenths (up-counter) lo
        isdRecH                 ; ISD1240 record timer, tenths (up-counter) hi

	endc

;last RAM address is at 2f

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
        push                    ; preserve W and STATUS

        btfsc   INTCON,T0IF
        goto    TimrInt
        goto    IntExit

TimrInt
        btfss   flags,beepOn    ; is beep turned on?
        goto    TimrTst         ; no, continue
        btfss   PORTB,beepBit   ; is beepBit set?
        goto    Beep0           ; no
        bcf     PORTB,beepBit   ; yes, turn it off
        goto    TimrTst         ; continue
Beep0
        bsf     PORTB,beepBit   ; beep bit is off, turn it on...

TimrTst
        decfsz  ofCnt,f         ; decrement the overflow counter
        goto    TimrDone        ; if not 0, then 
        bsf     tFlags,TICK     ; set tick indicator flag
        movlw   OFBASE          ; preset overflow counter
        movwf   ofCnt           

TimrDone                        
        decfsz  cwCntr,f        ; decrement the cw timebase counter
        goto    DeBounc
        bsf     tFlags,CWTICK   ; set tick indicator
        movlw   CWCNT           ; get preset value
        movwf   cwCntr          ; preset cw timebase counter

DeBounc                         ; COR debounce
        btfss   PORTB,cor       ; check cor
        goto    ICorOn          ; it's low...
                                ; squelch is closed; receiver is inactive
        movf    dBounce,f       ; check debounce counter for zero
        btfsc   STATUS,Z        ; is it zero?
        goto    TIntDone        ; yes
        decf    dBounce,f       ; no, decrement it
        btfss   STATUS,Z        ; is it zero?
        goto    TIntDone        ; no, continue
        bsf     tFlags,TFLCOR   ; yes, turn COR off
        goto    TIntDone        ; done with COR debouncing...        

ICorOn                          ; squelch is open; receiver is active
	btfsc	cfgFlag,SIMPLEX	; test for simplex mode
	goto	SCorOn		; use special simplex debouncer
        btfsc   dBounce,CDBBIT  ; check debounce counter
        goto    TIntDone        ; already maxed out
        incf    dBounce,f       ; increment 
        btfss   dBounce,CDBBIT  ; is it maxed now?
        goto    TIntDone        ; no
        bcf     tFlags,TFLCOR   ; yes, turn COR on
	goto	TIntDone	; done with debouncing...

SCorOn				; SIMPLEX debounce has extra hysteresis
	movlw	CDBVAL		; fetch debounce counter threshold
	subwf	dBounce,w	; subtract count from dBounce
	btfsc	STATUS,C	; is result negative
	bcf	tFlags,TFLCOR	; nope, turn on COR flag
	incfsz	dBounce,w	; increment & test dBounce
	incf	dBounce,f	; was not already at max, so increment

TIntDone
        bcf     INTCON,T0IF     ; clear RTCC int mask

IntExit
        pop                     ; restore W and STATUS
        retfie

Start
	IF NHRC3 == 0		; NHRC-3 Target?
				; ISD controls NOT inverted
	movlw   b'00000000'	; preset ISD controls low
	ELSE
	movlw	b'00001100'	; preset ISD controls high
	ENDIF
	movwf	PORTB		; preset port B values...
	
        bsf     STATUS,RP0      ; select bank 1
        movlw   b'00011111'     ; low 5 bits are input
        movwf   TRISA           ; set port a as outputs
        movlw   b'10000001'     ; RB0&RB7 inputs
        movwf   TRISB

        IF DEBUG == 1
        movlw   b'10001000'     ; DEBUG! no pull up, timer 0 gets no prescale
        ELSE
        movlw   b'10000000'     ; no pull up, timer 0 gets prescale 2
        ENDIF

        movwf   OPTION_REG      ; set options

        bcf     STATUS,RP0      ; select page 0
	clrf	flags		; reset all flags
        clrf    PORTA           ; make port a all low
        clrf    state           ; clear state (quiet)
        clrf    tFlags          ; clear timer flags
        bsf     tFlags,TFLCOR   ; set debounced cor off
        clrf    msgNum          ; clear message number
        movlw   OFBASE          ; preset overflow counter
        movwf   ofCnt           
        movlw   CWCNT           ; get preset value
        movwf   cwCntr          ; preset cw timebase counter

        movlw   TEN             ; preset decade counters
        movwf   secCnt          ; 1 second down counter
        movwf   tenCnt          ; 10 second down counter

	clrf	cfgFlag		; clear config flag
	clrf    hangTmr         ; clear hang timer
        clrf    tOutTmr         ; clear timeout timer
        clrf    idTmr           ; clear idTimer
        clrf    isdPlaL         ; clear lo byte isd play timer
        clrf    isdPlaH         ; clear hi byte isd play timer
        clrf    muteTmr         ; clear muting timer
        clrf    sISDTmr         ; clear ISD back off timer
        clrf    cmdCnt          ; clear command counter
        clrf    dBounce         ; clear debounce timer counter
        movlw   TONES
        movwf   toneCnt         ; preset tone counter

        btfsc   PORTA,INITBIT   ; check to see if init is pulled low
        goto    NoInit          ; init is not low, continue...

        bsf     flags,init      ; initialization in progress

        movlw   EELAST          ; get last address to initialize
        movwf   EEADR           ; set EEPROM address to program 
InitLp
        call    InitDat         ; get init data byte 
        movwf   EEDATA          ; put into EEPROM data register
        call    EEProg          ; program byte
        movf    EEADR,f         ; load status, set Z if zero (last byte done)
        btfsc   STATUS,Z        ; skip if Z is clear (not last byte)
        goto    InitISD         ; done initializing EEPROM data
        decf    EEADR,f         ; decrement EEADR
        goto    InitLp 

InitISD
        movlw   d'1'            ; 0.1 sec message length default
        movwf   EEDATA          ; put into EEPROM data register
        movlw   EEM0LEN         ; address of message 0 length
        movwf   EEADR           ; set EEPROM address to program 
        call    EEProg          ; program byte
        incf    EEADR,f         ; increment address of byte to init
        call    EEProg          ; program byte EEM1LEN
        incf    EEADR,f         ; increment address of byte to init
        call    EEProg          ; program byte EEM2LEN
        incf    EEADR,f         ; increment address of byte to init
        call    EEProg          ; program byte EEM3LEN

NoInit
        bsf     STATUS,RP0      ; select bank 1
        movlw   b'00001111'     ; low 4 bits are input, RA4 is muting control
        movwf   TRISA           ; set port a as outputs
        bcf     STATUS,RP0      ; select bank 0

        movlw   EEENAB		; get address of enable byte
	movwf	EEADR		; store EEPROM address
        call    EEEval		; get data and evalate
        movlw   EECONF          ; get address of configuration byte
	movwf	EEADR		; store EEPROM address
        call    EEEval		; get data and evalate
        movlw   EEHANG          ; get address of hang timer preset value
	movwf	EEADR		; store EEPROM address
        call    EEEval		; get data and evalate
        movlw   EETOUT          ; get address of timeout timer preset value
	movwf	EEADR		; store EEPROM address
        call    EEEval		; get data and evalate
        movlw   EEID            ; get address of ID timer preset value
	movwf	EEADR		; store EEPROM address
        call    EEEval		; get data and evalate
        movlw   EETMSG          ; get address of tail message counter preset
	movwf	EEADR		; store EEPROM address
        call    EEEval		; get data and evalate

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
        btfss   flags,cwOn      ; sending CW?
        goto    NoCW            ; nope
        decfsz  cwTmr,f         ; decrement CW timer
        goto    NoCW            ; not zero
        
        btfss   flags,beepOn	; was "key" down?
        goto    CWKeyUp         ; nope
                                ; key was down        
        bcf     flags,beepOn    ; key->up
        decf    cwByte,w        ; test CW byte to see if 1
        btfsc   STATUS,Z        ; was it 1 (Z set if cwByte == 1)
        goto    CWNext          ; it was 1...
        movlw   CWIESP          ; get cw inter-element space
        movwf   cwTmr           ; preset cw timer
        goto    NoCW            ; done with this pass...

CWNext                          ; get next character of message
        incf    cwBuff,f        ; increment offset
        movf    cwBuff,w        ; get offset
        call    ReadEE          ; get char from EEPROM
        movwf   cwByte          ; store character bitmap
        btfsc   STATUS,Z        ; is this a space (zero)
        goto    CWWord          ; yes, it is 00
        incf    cwByte,w        ; check to see if it is FF
        btfsc   STATUS,Z        ; if this bitmap was FF then Z will be set
        goto    CWDone          ; yes, it is FF
        movlw   CWILSP          ; no, not 00 or FF, inter letter space
        movwf   cwTmr           ; preset cw timer
        goto    NoCW            ; done with this pass...

CWWord                          ; word space
        movlw   CWIWSP          ; get word space
        movwf   cwTmr           ; preset cw timer
        goto    NoCW            ; done with this pass...

CWKeyUp                         ; key was up, key again...
        incf    cwByte,w        ; is cwByte == ff?
        btfsc   STATUS,Z        ; Z is set if cwByte == ff
        goto    CWDone          ; got EOM

        movf    cwByte,f        ; check for zero/word space
        btfss   STATUS,Z        ; is it zero
        goto    CWTest          ; no...
        goto    CWNext          ; is 00, word space...

CWTest
        movlw   CWDIT           ; get dit length
        btfsc   cwByte,0        ; check low bit
        movlw   CWDAH           ; get DAH length
        movwf   cwTmr           ; preset cw timer
        bsf     flags,beepOn    ; turn key->down
        rrf     cwByte,f        ; rotate cw bitmap
        bcf     cwByte,7        ; clear the MSB
        goto    NoCW            ; done with this pass...

CWDone                          ; done sending CW
        bcf     flags,cwOn      ; turn off CW flag
	call	CheckTx		; turn off transmitter if ok to
	
NoCW
        movlw   b'11110001'     ; set timer flags mask
        andwf   tFlags,f        ; clear timer flags
        btfss   tFlags,TICK     ; check to see if a tick has happened
        goto    Loop1		; nope...

	;
	; 100ms tick has occurred...
	;
        bcf     tFlags,TICK     ; reset tick flag
        bsf     tFlags,TENTH    ; set tenth second flag
	decfsz  secCnt,f        ; decrement 1 second counter
        goto    Loop1           ; not zero (not 1 sec interval)

	;
        ; 1s tick has occurred...
	;
        movlw   TEN             ; preset decade counter
        movwf   secCnt          
        bsf     tFlags,ONESEC   ; set one second flag
        decfsz  tenCnt,f        ; decrement 10 second counter
        goto    Loop1           ; not zero (not 10 second interval)

	;
        ; 10s tick has occurred...
	;
        movlw   TEN             ; preset decade counter
        movwf   tenCnt
        bsf     tFlags,TENSEC   ; set ten second flag 

        ;
        ; main loop for repeater controller
        ;
Loop1
        movlw   h'00'
        movwf   PCLATH          ; ensure that computed goto will stay in range
        movf    state,w         ; get state into w
        addwf   PCL,f           ; add w to PCL
        goto    Quiet           ; 0
        goto    Repeat          ; 1
        goto    TimeOut         ; 2
        goto    Hang            ; 3
        goto    CasEnd          ; 4

Quiet
        btfsc   tFlags,TFLCOR   ; is squelch open?
        goto    CasEnd          ; no

        btfss   cfgFlag,SIMPLEX ; simplex mode?
        goto    QKeyUp
                                ; *** SIMPLEX ***
        btfsc   flags,cwOn      ; is cw playing?
        goto    CasEnd          ; can't go into record if cw is playing

        movf    isdPlaL,w       ; fetch lo order byte of ISD play timer
        iorwf   isdPlaH,w	; or in hi order byte of ISD play timer
        btfss   STATUS,Z        ; is it zero
        goto    CasEnd          ; no, ISD is playing, don't record

        movlw   SRPT            ;
        movwf   state           ; change state to repeat 

	ISDPOFF			; stop any playing message
	ISDROFF			; stop any recording message
        bcf     PORTB,isdA0     ; reset message address bits
        bcf     PORTB,isdA1     
        bcf     PORTB,ptt       ; turn transmitter off
        clrf    msgNum          ; set message number to zero
        bsf     msgNum,ISDMSG   ; set message to be for ISD

        bcf     PORTA,MUTE      ; unmute
	call	Record		; start recording
        goto    CasEnd

QKeyUp
	call	PTTon		; turn transmitter on

KeyUp   
        movf    isdPlaL,w       ; fetch lo byte of ISD play timer
        iorwf   isdPlaH,w       ; or in hi byte of ISD play timer
        btfsc   STATUS,Z        ; is result zero (means both are zero)
        goto    Key0            ; yes, no message playing
        btfsc   msgNum,1        ; is it an ID message?
        goto    Key0            ; no, let it go
                                ; stomp on playing voice message
        clrf    isdPlaL         ; clear ISD timer
        clrf    isdPlaH         ; clear ISD timer
	ISDPOFF			; turn off ISD playback
        movlw   CW_ID           ; play CW Id
        movwf   msgNum          ; set message number
        call    PlayMsg         ; play the message

Key0
        bcf     PORTA,MUTE      ; unmute
        btfss   flags,cwOn      ; is cw playing?
        bcf     flags,beepOn    ; no, make sure that beep is off.

        movf    tOutDly,w       ; get timeout delay into w
        movwf   tOutTmr         ; preset timeout counter

        movlw   SRPT            
        movwf   state           ; change state to repeat

        btfss   msgNum,MSGREC   ; is record flag set?
        goto    CasEnd		; nope...
        bcf     msgNum,MSGREC   ; clear record flag
	call	Record		; start recording
        goto    CasEnd

Repeat
        btfss   tFlags,ONESEC   ; check to see if one second tick
        goto    Repeat1         ; nope...

	movf	tOutTmr,f	; get tOutTmr zero state
	btfss	STATUS,Z	; dont decrement if zero
        decfsz  tOutTmr,f       ; decrement timeout timer
        goto    Repeat1         ; not to zero yet...
        goto    TimedOut        ; timed out!

Repeat1
        btfss   tFlags,TFLCOR   ; is squelch open?
        goto    CasEnd          ; no, keep repeating
        bsf     PORTA,MUTE      ; mute the audio...
        clrf    muteTmr         ; cancel timed unmute from dtmf muting
        
        btfss   flags,isdRecF   ; is it in record mode?
        goto    CorOff          ; nope, skip next part
				; recording, carrier dropped, stop recording
	call	RecStop		; stop recording
        clrf    isdPlaL         ; clear ISD timer
	clrf	isdPlaH
        btfss   cfgFlag,SIMPLEX ; in simplex mode?
        goto    RecEnd          ; no
                                ; *** SIMPLEX ***
SimPlay
        movlw   ISDBKOF         ; get the ISD back off delay
        movwf   sISDTmr         ; save the ISD back off delay
        call	PTTon		; turn transmitter on
	bcf	flags,initID	; clear initial ID flag, don't wan that here.
        movlw   SQUIET          
        movwf   state           ; change state to quiet
        goto    CasEnd
        
RecEnd
        movf    msgNum,w        ; get message number
        andlw   b'00000011'     ; mask out bit 2-7
        addlw   EEM0LEN         ; add address of message 0 length
        movwf   EEADR           ; set EEPROM address
        decf    isdRecL,w       ; get timer - 1 (less 100 ms)
        movwf   EEDATA          ; put into EEPROM data register...
        call    EEProg          ; save message length

CorOff                          ; cor on->off transition
        btfsc   cfgFlag,SIMPLEX ; in simplex mode?
        goto    SimPlay         ; play (truncated) recorded message 

        clrf    muteTmr         ; reset the mute timer
        clrf    tOutTmr         ; clear time out timer
        movf    hangDly,w       ; get hang timer preset
        btfsc   STATUS,Z        ; is hang timer preset 0?
        goto    NoHang          ; no hang time
        movwf   hangTmr         ; preset hang timer
        movlw   SHANG            
        movwf   state           ; change state to hang
        goto    CorOff2

NoHang
        movlw   SQUIET          ; change state to quiet
        movwf   state           ; save state

CorOff2
        btfsc   flags,initID    ; check initial id flag
	call	DoID		; play the ID
        btfss   flags,needID    ; need to ID?
        goto    CasEnd          ; no, go on...

        ;
        ;if (idTmr <= idSoon) then goto StartID
        ;implemented as: if ((IDSOON-idTimer)>=0) then ID
        ;
        movf    idTmr,w         ; get idTmr into W
        sublw   IDSOON          ; IDSOON-w ->w
        btfsc   STATUS,C        ; C is clear if result is negative
	call	DoID		; ok to ID now, let's do it.
        goto    CasEnd          ; don't need to ID yet... 

TimedOut
        bsf     PORTA,MUTE      ; mute the audio...
        clrf    muteTmr         ; reset the mute timer
        movlw   STIMOUT
        movwf   state           ; change state to timed out
        movlw   ISD_TO          ; ISD time out message
        movwf   msgNum          ; set message number
        call    PlayMsg         ; play the message
        goto    CasEnd
        
Hang    
        btfss   tFlags,TFLCOR   ; is squelch open?
        goto    KeyUp           ; yes!

        btfss   tFlags,TENTH    ; check to see if tenth second tick
        goto    CasEnd

        btfsc   flags,cwOn      ; is cw playing?
        goto    Hang2           ; yes, don't ctsy beep

        btfsc   cfgFlag,NOCTSY  ; check for suppressed courtesy tone
        goto    Hang2           ; suppressed...

        ;test to see if time for ctsy tone here
        movf    hangTmr,w       ; get hang timer
        addlw   5               ; add 500 ms
        subwf   hangDly,w       ; subtract hang delay
        btfss   STATUS,Z        ; zero if equal
        goto    Hang1
        movf    isdPlaL,w       ; fetch lo byte of isd play timer
	iorwf	isdPlaH,w	; or in hi byte of isd play timer
        btfss   STATUS,Z        ; is it zero?
        goto    Hang2           ; no; ISD is playing, don't beep
        btfsc   cfgFlag,ISDCTSY ; check for ISD stored courtesy tone
        goto    ISDCtsy
        bsf     flags,beepOn    ; turn on beep
        goto    Hang2

ISDCtsy                         ; want to play ISD message 3 for courtesy tone
        movlw   ISD_TM          ; ISD tail message plays as courtesy tone
        movwf   msgNum          ; set message number
        call    PlayMsg         ; play the message
        goto    Hang2

Hang1
        btfsc   cfgFlag,ISDCTSY ; check for ISD stored courtesy tone
        goto    Hang2

        movf    hangTmr,w       ; get hang timer
        addlw   7               ; add 700 ms so beep is 200 ms long
        subwf   hangDly,w       ; subtract hang delay
        btfss   STATUS,Z        ; zero if equal
        goto    Hang2
        bcf     flags,beepOn    ; turn off beep

Hang2
        decfsz  hangTmr,f       ; decrement hang timer
        goto    CasEnd          ; not zero yet
        
        movlw   SQUIET          
        movwf   state           ; change state to quiet

        movf    tMsgCtr,f       ; check tail message counter
        btfsc   STATUS,Z        ; Z will be set if counter is zero, skip
        goto    CasEnd          ; tMsgCtr is zero
        decfsz  tMsgCtr,f       ; decrement the tail message counter
        goto    CasEnd          ; not zero yet
        movlw   EETMSG          ; get address of tail message counter preset
        call    ReadEE          ; read EEPROM
        movwf   tMsgCtr         ; restore w into tail message counter
        movlw   ISD_TM          ; get the tail message
        movwf   msgNum          ; save it as the message to play
        call    PlayMsg         ; play the message
        goto    CasEnd          ; done

TimeOut
        btfss   tFlags,TFLCOR   ; is squelch open?
        goto    CasEnd          ; no, stay timed out...
        
        movlw   SQUIET          
        movwf   state           ; change state to quiet

        movlw   ISD_TO          ; ISD time out message
        movwf   msgNum          ; set message number
        call    PlayMsg         ; play the message

CasEnd
        btfss   tFlags,TENTH    ; check to see if tenth second tick
        goto    ID1             ; nope
                                ; yes, it is a tenth-tick
        movf    isdPlaL,w       ; fetch lo byte of isd play timer
	iorwf	isdPlaH,w	; or in hi byte of isd play timer
        btfsc   STATUS,Z        ; is it zero?
        goto    ID1             ; yes, hi and lo are zero, no msg playing

        btfss   flags,isdRecF   ; is the ISD in record mode?
        goto    CasE1           ; nope.
        incf    isdRecL,f       ; yes. increment the record timer
        btfsc   STATUS,Z        ; wrap around (carry)?
        incf    isdRecH,f       ; increment hi order counter...
        
CasE1
	movf	isdPlaH,f	; check hi byte of ISD play timer
	btfsc	STATUS,Z	; is it zero?
	goto	CasE1A		; yes, zero.
	movf	isdPlaL,f	; check lo byte of ISD play timer
	btfsc	STATUS,Z	; is it zero?
	decf	isdPlaH,f	; yes, borrow one from hi byte of ISD play timer
	decf	isdPlaL,f	; decrement lo byte of ISD play timer
	goto	ID1		; can't have counted to zero yet, continue.

CasE1A				; hi byte of ISD timer found to be zero
        decfsz  isdPlaL,f       ; decrement ISD1240 play timer
        goto    ID1             ; not zero yet...
				; ISD play timer counted down to zero.
        btfss   flags,isdRecF   ; is it in record mode
        goto    ISDpOff         ; no

	call	RecStop		; stop recording
        btfsc   cfgFlag,SIMPLEX ; in simplex mode?
        goto    ID1             ; yes, don't store message length

                                ; store message length
        movf    msgNum,w        ; get message number
        andlw   b'00000011'     ; mask out bit 2-7
        addlw   EEM0LEN         ; add address of message 0 length
        movwf   EEADR           ; set EEPROM address

        decf    isdRecL,w       ; get timer - 1
        movwf   EEDATA          ; put into EEPROM data register...
        call    EEProg          ; save message length
        goto    ID1

ISDpOff
        ISDPOFF			; zero, turn off ISD1240 playback
	btfss	cfgFlag,SIMPLEX	; in simplex repeater mode?
	goto	ID1		; no.
	;; here! check to see if the ID timer is going to expire soon and play
	;; id now...
        movf    idTmr,w         ; get idTmr into W
        sublw   IDSOON          ; IDSOON-w ->w
        btfsc   STATUS,C        ; C is clear if result is negative
	call	DoID		; ok to ID now, let's do it.
	goto	CkBkOff		; continue

ID1
        movf    idTmr,f         
        btfsc   STATUS,Z        ; is idTmr 0
        goto    CkBkOff         ; yes...

        btfss   tFlags,TENSEC   ; check to see if ten second tick
        goto    CkBkOff         ; nope...
	
	;; this nasty logic defers the ID if in simplex repeater mode
	;; and recording.  It will put off the ID for up to the entire
	;; record time.
	btfss	cfgFlag,SIMPLEX	; in simplex repeater mode?
	goto	ID1A		; nope...
	decf	idTmr,w		; get ID timer -1
	btfss	STATUS,Z	; is it zero?
	goto	ID1A		; nope...
	btfsc	flags,isdRecF	; recording?
	goto	CkBkOff		; defer ID while recording

ID1A	
        decfsz  idTmr,f         ; decrement ID timer
        goto    CkBkOff         ; not zero yet...
                                ; id timer is zero! time to ID
	call	DoID		; play the ID

CkBkOff
        movf    sISDTmr,f       ; check ISD backoff timer
        btfsc   STATUS,Z        ; is it zero?
        goto    CkTone          ; yes
        btfss   tFlags,TENTH    ; check to see if tenth second tick
        goto    CkTone          ; nope
        decfsz  sISDTmr,f       ; decrement ISD1240 backoff timer
        goto    CkTone          ; not zero yet...
        movlw   ISD_SM          ; ISD simplex message
        movwf   msgNum          ; set message number
        call    ISDPlay         ; start the message playing

CkTone
        btfss   PORTB,dv        ; check M8870 digit valid
        goto    NoTone          ; not set
        btfsc   flags,lastDV    ; check to see if set on last pass
        goto    ToneDon         ; it was already set
        bsf     flags,lastDV    ; set lastDV flag

        btfsc   cfgFlag,NOMUTE  ; check for no muting flag
        goto    MuteEnd         ; no muting...
        
        movlw   MUTEDLY         ; get mute timer delay
        movwf   muteTmr         ; preset mute timer
        bsf     PORTA,MUTE      ; set muting

MuteEnd
        movf    PORTA,w         ; get DTMF digit
        andlw   TMASK           ; mask off hi nibble
        movwf   tone            ; save digit
        goto    ToneDon 

NoTone
        btfss   flags,lastDV    ; is lastDV set
        goto    ToneDon         ; nope...
        bcf     flags,lastDV    ; clear lastDV flag...

        btfsc   flags,init      ; in init mode?
        goto    WrTone          ; yes, go write the tone

        movf    toneCnt,w       ; test toneCnt
        btfss   STATUS,Z        ; is it zero?
        goto    CkDigit         ; no

        ;password has been successfully entered, start storing tones

        ;make sure that there is room for this digit
        movlw   MAXCMD          ; get max # of command tones
        subwf   cmdCnt,w        ; cmdCnt - MAXCMD -> w
        btfsc   STATUS,Z        ; if Z is set then there is no more room
        goto    Wait            ; no room, just ignore it...

        ;there is room for this digit, calculate buffer address...
        movlw   tBuf1           ; get address of first byte in buffer
        addwf   cmdCnt,w        ; add offset
        movwf   FSR             ; set indirection register
        movf    tone,w          ; get tone
        call    MapDTMF         ; convert to hex value
        movwf   INDF            ; save into buffer location
        incf    cmdCnt,f        ; increment cmdCnt
        goto    Wait

CkDigit
        ;check this digit against the code table
        sublw   TONES           ; w = TONES - w; w now has digit number
        addlw   EETTPRE         ; w = w + EETTPRE; the digit's EEPROM address
        call    ReadEE          ; read EEPROM
        subwf   tone,w          ; w = tone - w
        btfss   STATUS,Z        ; is w zero?
        goto    NotTone         ; no...
        decf    toneCnt,f       ; decrement toneCnt
        goto    ToneDon

NotTone
        movlw   TONES
        subwf   toneCnt,w       
        btfsc   STATUS,Z        ; is this the first digit?
        goto    BadTone         ; yes
        movlw   TONES           ; reset to check to see if this digit
        movwf   toneCnt         ; is the first digit...
        goto    CkDigit

WrTone                          ; save tone in EEPROM to init password
        movf    toneCnt,w       ; test toneCnt
        sublw   TONES           ; w = TONES - w; w now has digit number
        addlw   EETTPRE         ; w = w + EETTPRE; the digit's EEPROM address
        movwf   EEADR           ; EEADR = w
        movf    tone,w          ; get tone
        movwf   EEDATA          ; put into EEPROM data register...
        call    EEProg          ; call EEPROM prog routine

        decfsz  toneCnt,f       ; decrement tone count        
        goto    ToneDon         ; not zero, still in init mode
        bcf     flags,init      ; zero, out of init mode
	bsf	tFlags,SAYOK	; request OK message be sent
	
BadTone       
        movlw   TONES           ; no... get number of command tones into w
        movwf   toneCnt         ; preset number of command tones

ToneDon
	call	CheckTx		; turn off TX if OK

Wait
        btfss   tFlags,TENTH    ; check to see if one tenth second tick
        goto    Wait1           ; nope...

        movf    muteTmr,f       ; test mute timer
        btfsc   STATUS,Z        ; Z is set if not DTMF muting
        goto    Wait1           ;
        decfsz  muteTmr,f       ; decrement muteDly
        goto    Wait1           ; have not reached the end of the mute time
	movf	state,w		; get repeater state
	sublw	SRPT		; compare state to REPEAT state
	btfsc	STATUS,Z	; is result 0 (same)
        bcf     PORTA,MUTE      ; yep, unmute

Wait1
        btfsc   tFlags,TFLCOR   ; is squelch open?
        goto    CorOn           ; yes
        btfss   flags,lastCor   ; cor is off, is last COR off?
        goto    Loop            ; last COR is also off, do nothing here
        ;COR on->off transition (receiver has just unsquelched)
        bcf     flags,lastCor   ; clear last COR flag
        call    ClrTone         ; clear password tones & commands
        goto    Loop

CorOn
        btfsc   flags,lastCor   ; cor is ON, is last COR on?
        goto    Loop            ; last COR is also on, do nothing here
        ;COR off->on transition (receiver has just squelched)
        bsf     flags,lastCor   ; set last COR flag

        ;evaluate touch tones in buffer
        movf    cmdCnt,f        ; check to see if any stored tones
        btfsc   STATUS,Z        ; is it zero?
	goto    NoCmd           ; no stored tones

        movlw   MAXCMD          ; get max # of command tones
        subwf   cmdCnt,w        ; cmdCnt - MAXCMD -> w
        btfss   STATUS,Z        ; if Z is set then there are enough digits
        goto    NoCmd           ; not enough command digits...

        ;there are tones stored in the buffer...
        swapf   tBuf1,w         ; swap nibble of tBuf1 and store in w
        iorwf   tBuf2,w         ; or in low nibble (tBuf2)
        movwf   tBuf1           ; store resultant 8 bit value into tBuf1

        swapf   tBuf3,w         ; swap nibble of tBuf3 and store in w
        iorwf   tBuf4,w         ; or in low nibble (tBuf4)
        movwf   tBuf3           ; store resultant 8 bit value into tBuf3

        ;test the address...
        btfsc   tBuf1,7         ; bit 7 is not allowed
        goto    BadCmd
        btfsc   tBuf1,6         ; bit 6 indicates command: 4xxx,5xxx,6xxx,7xxx
        goto    MsgCmd

	movf	tBuf1,w		; get the address to program
	sublw	EELAST		; subtract from EELAST, last valid prog addr
	btfss	STATUS,C	; skip if tBuf1 <= EELAST
	goto	BadCmd		; that address is not user programmable

        ;program the byte...
        movf    tBuf1,w         ; get address
        movwf   EEADR
        movf    tBuf3,w         ; get data byte
        movwf   EEDATA
        call    EEProg          ; program EE byte

	call	EEEval		; evaluate the change

        movlw   CW_OK
        movwf   msgNum
        call    PlayMsg
        call    ClrTone
        goto    Loop
	
EEEval
	movf	EEADR,w		; get the EEPROM address
	sublw	EETMSG		; subtract last config data address
	btfss	STATUS,C	; skip if EEADR <= EETMSG (result non-negative)
	return			; not a config data address (ID or other)
        movlw   h'02'
        movwf   PCLATH          ; ensure that computed goto will stay in range
	movf	EEADR,w		; get the EEPROM address
	addwf	PCL,f		; computed goto
	goto	TstEnab
	goto	TstConf
	goto	TstHang
	goto	TstTOut
	goto	TstID
	goto	TstTM
	
TstEnab
	call	ReadEE		; get the data
        btfss   STATUS,Z        ; is data 0?
        goto    TstEna1		; nope
        movlw   SDISABL		; get disabled state value
        movwf   state		; save disabled state value
	btfss	cfgFlag,SIMPLEX	; in simplex mode?
	return			; nope...
	ISDPOFF			; stop playing ISD
	ISDROFF			; stop recording
	clrf	sISDTmr		; clear simplex backoff timer
	clrf	isdRecL		; set recorded message length to 0
	clrf	isdRecH		; set recorded message length to 0
	clrf	isdPlaL		; clear playback timer low byte
	clrf	isdPlaH		; clear playback timer hi byte
        return

TstEna1
        movlw   SQUIET          ; enable repeater
        movwf   state		; save quiet state
        bcf     flags,initID    ; clear initial id flag
        bcf     flags,needID    ; clear needId flag
        return

TstConf
	call	ReadEE		; get the data
        movwf   cfgFlag         ; store w into config flag

	movf	state,w		; get state value
	sublw	SDISABL		; subtract disabled state value
	btfsc	STATUS,Z	; skip if result is not zero (!=)
	return			; no need to mess with the rest...

        clrf    hangTmr         ; clear hang timer
        clrf    tOutTmr         ; clear timeout timer
        clrf    isdPlaL         ; clear lo byte of isd play timer
        clrf    isdPlaH         ; clear hi byte of isd play timer
        clrf    muteTmr         ; clear muting timer
        clrf    sISDTmr         ; clear ISD back off timer

	call	RecStop		; stop recording (just in case)
        clrf    state           ; reset to quiet state
	return

TstHang
	call	ReadEE		; get the data
        movwf   hangDly         ; store w into hang time delay preset
	return
        
TstTOut
	call	ReadEE		; get the data
        movwf   tOutDly         ; store w into time out delay preset
	return

TstID
	call	ReadEE		; get the data
        movwf   idDly           ; store w into ID delay preset
	return

TstTM
	call	ReadEE		; get the data
        movwf   tMsgCtr         ; store w into tail message counter
	return

MsgCmd                          ; 4x, 5x, 6x, 7x commands
        movf    tBuf1,w         ; get command byte
        andlw   b'10001110'     ; check for invalid values
        btfss   STATUS,Z        ;
        goto    BadCmd          ; only 40, 41, 50, 51, 60, 61, 70, 71 valid 

        movlw   h'02'           ; this value must equal address' high byte
        movwf   PCLATH          ; ensure that computed goto will stay in range

        swapf   tBuf1,w         ; swap command byte into w
        andlw   b'00000011'     ; mask bits that make up remainder of command
        addwf   PCL,f           ; add w to PCL
        goto    Cmd4x           ; bits 2-7 has been stripped so 4 = 0
        goto    Cmd5x
        goto    Cmd6x
        goto    Cmd7x

Cmd4x
        btfss   tBuf1,0         
        goto    MsgPlay         ; 40nn command

        movf    tBuf3,w         ; get argument
        movwf   msgNum          ; save into message number
	call	SelMsg		; select message
        bsf     msgNum,MSGREC   ; set message record bit        
        goto    Loop

Cmd5x
	btfss	cfgFlag,NOISD	; check to see if ISD is not present
	goto	BadCmd		; the ISD is there, port commands invalid
	movf    tBuf1,w         ; get command byte
        andlw   b'00001111'     ; mask off high nibble
        btfss   STATUS,Z        ; is result (low nibble) zero?
        goto    BadCmd          ; nope

        btfsc   tBuf3,4         ; lo bit of hi nibble clear?
        goto    Cmd50Odd        ; nope, 51, 53, etc.
        
        btfsc   tBuf3,0         ; lo bit clear?
        goto    Cmd50ES         ; nope, set (turn on)
        bcf     PORTB,CTL0      ; clear output (off/lo)
        goto    GoodCmd

Cmd50ES 
        bsf     PORTB,CTL0      ; set output (on/hi)
        goto    GoodCmd
        
Cmd50Odd
        btfsc   tBuf3,0         ; lo bit clear?
        goto    Cmd50OS         ; nope, set (turn on)
        bcf     PORTB,CTL1      ; clear output (off/lo)
        goto    GoodCmd

Cmd50OS 
        bsf     PORTB,CTL1      ; set output (on/hi)
        goto    GoodCmd

Cmd6x
Cmd7x
        goto    BadCmd
        
MsgPlay                         ; command 40
        movf    tBuf3,w         ; get argument
        movwf   msgNum          ; save into message number
        call    PlayMsg
        goto    Loop

NoCmd				; no command was received
	btfss	flags,init	; in init mode?
	goto    CkSayOk		; nope
	movlw	CW_ID		; select CW ID message
	goto	CmdRes		; play ID since in init mode

CkSayOk
	btfss	tFlags,SAYOK	; is the say ok flag set?
	goto	CmdDone		; nope
	bcf	tFlags,SAYOK	; reset the flag
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


Record
        clrf    isdRecL         ; zero record time
        clrf    isdRecH         ; zero record time
        clrf    isdPlaH         ; zero play hi word; useful for 4/6 cases below
        movlw   h'02'           ; this subroutine is in the $200 addresses
        movwf   PCLATH          ; ensure that computed goto will stay in range
        rrf     cfgFlag,w       ; rotate config flags right 1 into w
        andlw   B'0000111'      ; mask off useless bits
        addwf   PCL,f           ; add w to PCL
        goto    I1420N          ; xxxx000x ISD1420 normal
        goto    I1420S          ; xxxx001x ISD1420 simplex
        goto    I2560N          ; xxxx010x ISD2560 normal
        goto    I2560S          ; xxxx011x ISD2560 simplex
        goto    I2590N          ; xxxx100x ISD2590 normal
        goto    I2590S          ; xxxx101x ISD2590 simplex
        goto    I1420N          ; xxxx110x ISD1020 normal
        goto    I1420S          ; xxxx111x ISD1020 simplex

I1420N                          ; ISD1420 normal
        movlw   D'48'           ; 4.8 seconds
        movwf   isdPlaL         ; save low byte isd max time
	goto	Rec1	
	
I1420S                          ; ISD1420 simplex
        movlw   D'198'          ; 19.8 seconds
        movwf   isdPlaL         ; save low byte isd max time
	goto	Rec1	
        return

I2560N                          ; ISD2560 normal
        movlw   D'148'          ; 14.8 seconds
        movwf   isdPlaL         ; save low byte isd max time
	goto	Rec1	

I2560S                          ; ISD2560 simplex
        movlw   H'02'           ; 512 ticks
        movwf   isdPlaH         ; save hi byte isd max time
        movlw   H'56'           ; 86 more ticks = 59.8 seconds
        movwf   isdPlaL         ; save lo byte isd max time
	goto	Rec1	

I2590N				; ISD2590 normal
        movlw   D'223'          ; 22.3 seconds
        movwf   isdPlaL         ; save lo byte isd max time
	goto	Rec1	

I2590S				; ISD2590 simplex
        movlw   H'03'           ; 768 ticks
        movwf   isdPlaH         ; save hi byte isd max time
        movlw   H'82'           ; 130 more ticks = 89.8 seconds
        movwf   isdPlaL         ; save lo byte isd max time
	goto	Rec1	

Rec1				; start recording on the ISD
        clrf    isdRecL         ; clear recorded duration timer low byte
        clrf    isdRecH         ; clear recorded duration timer hi  byte
        bsf     flags,isdRecF   ; set record mode
        ISDRON			; start recording
	btfsc	cfgFlag,ISD2560 ; check to see if the ISD part is a 2560
	ISDPON                  ; it is, set the chip select
	btfsc	cfgFlag,ISD2590 ; check to see if the ISD part is a 2590
	ISDPON			; it is, set the chip select
	return			; nope
	
RecStop				; stop recording
	btfsc	cfgFlag,ISD2560 ; is it a ISD2560 part
	ISDPOFF			; yes, turn off chip select
	btfsc	cfgFlag,ISD2590 ; is it a ISD2590 part
	ISDPOFF			; yes, turn off chip select
        ISDROFF			; stop recording
	bcf     flags,isdRecF   ; turn off record flag
	return
		
PlayMsg
        btfss   msgNum,ISDMSG	; is it an ISD message?
        goto    StartCW         ; nope, it's a CW message
				; ISD message request 
	btfsc	msgNum,ISDSIM	; is this the simplex message?
	goto	ISDPlay		; yes, play it now 
        btfsc   cfgFlag,SIMPLEX ; in simplex mode?
        goto    MsgCWID         ; no recorded messages, only CWID
        btfss   cfgFlag,NOISD   ; is the ISD absent?
        goto    ISDPlay         ; no, play audio message
        bcf     msgNum,ISDMSG	; convert ISD message to CW message
        btfss   msgNum,INOTID	; is it not an ID
        goto    MsgCWID         ; it is an id message
        btfsc   msgNum,0        ; skip if timeout message
        return                  ; don't even try to play tail message
	movlw	CW_TO		; select CW timeout message
	movwf	msgNum		; set message number
        goto    StartCW         ; play the CW timeout message

MsgCWID 
        movlw	CW_ID		; force CW ID
	movwf	msgNum		; set message number
;
; Start sending a CW message
;
StartCW
        call    GetCwMsg        ; lookup message, put message offset in W
        movwf   cwBuff          ; save offset
        call    ReadEE          ; read byte from EEPROM
        movwf   cwByte          ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cwTmr           ; preset cw timer
        bcf     flags,beepOn    ; make sure that beep is off
        bsf     flags,cwOn      ; turn on CW sender
        call	PTTon		; turn on PTT...
        return

;
;Play message from ISD1240; message address in msgNum
;
ISDPlay
	call	SelMsg		; select ISD message msgNum
        btfss   msgNum,ISDSIM   ; check bit 2; set indicates simplex
        goto    PNorm           ; not set
        movf    isdRecL,w       ; check lo byte of ISD record timer
	iorwf	isdRecH,w	; or in hi byte of ISD record timer
	btfsc   STATUS,Z        ; is it zero? (no message recorded)
        goto	SimBail	        ; yes, bail out.

	; shave 100 ms from message length to try to kill squelch crash
	movf	isdRecL,f	; check for borrow
	btfsc	STATUS,Z	; is it zero? (need to borrow?)
	decf	isdRecH,f	; borrow...
        decf    isdRecL,w       ; shave off 100mS
        movwf   isdPlaL         ; save into timer
	movf	isdRecH,w	; get hi order byte of recorded message dur.
	movwf	isdPlaH		; save into timer hi byte.
	clrf	isdRecL		; clear record length timer lo byte
	clrf	isdRecH		; clear record length timer hi byte

	movf    isdPlaL,w       ; check lo byte of ISD record timer
	iorwf	isdPlaH,w	; or in hi byte of ISD record timer
	btfsc   STATUS,Z        ; is it zero? (no message recorded)
        goto	SimBail	        ; yes, bail out.
        goto    PNow            ; play the message 

SimBail				; don't play simplex message 
	bcf	PORTB,ptt	; turn off ptt
	return			; bail
	
PNorm
	clrf	isdPlaH		; clear hi order byte of ISD play timer
        movf    msgNum,w        ; get message number
        andlw   b'00000011'     ; mask out bits 2-7
        addlw   EEM0LEN         ; add the base of the message lengths
        movwf   EEADR           ; save address
        call    ReadEE          ; read EEPROM, w will have message length after
        movwf   isdPlaL         ; set lo order byte of ISD play timer
        btfsc   STATUS,Z        ; is the length 0
        return                  ; yes, don't play.
        call	PTTon		; turn transmitter on

PNow
        ISDPON			; start ISD1240 playback
        return

;
;Set ISD message address lines from msgNum
;
SelMsg
        bcf     PORTB,isdA0     ; reset message address bits
        bcf     PORTB,isdA1     
        btfsc   msgNum,0        ; check bit 0
        bsf     PORTB,isdA0
        btfsc   msgNum,1        ; check bit 1
        bsf     PORTB,isdA1
        return

;
; Read EEPROM byte
; address is supplied in W on call, data is returned in w
;
ReadEE
        movwf   EEADR           ; EEADR = w
        bsf     STATUS,RP0      ; select bank 1
        bsf     EECON1,RD       ; read EEPROM
        bcf     STATUS,RP0      ; select bank 0
        movf    EEDATA,w        ; get EEDATA into w
        return

;
; clear tone buffer and reset good digit counters
;
ClrTone
        movlw   TONES           ; no... get number of command tones into w
        movwf   toneCnt         ; preset number of command tones
        clrf    cmdCnt          ; clear number of command bytes...
        clrf    tBuf1           ; clear command buffer bytes
        clrf    tBuf2
        clrf    tBuf3
        return

; 
; Play the appropriate ID message, reset ID timers & flags 
;
DoID
	btfss	flags,needID	; need to ID?
	return			; nope...
	btfsc	cfgFlag,NOISD	; is the ISD absent?
	goto	DoIDCW		; yes. use CW ID.
	btfsc	cfgFlag,SIMPLEX	; are we in simplex mode?
	goto	DoIDCW		; yes. use CW ID.
        btfss   tFlags,TFLCOR   ; is squelch open?
	goto	DoIDCW		; yes, use CW ID.
        movlw   ISD_IID		; select initial ID
	btfsc	flags,initID	; is it the initial ID?
	goto	DoIDany		; yes... play it
	btfsc	cfgFlag,ALTID	; alternate ID mode selected?
	goto	DoIDCW		; yes, play CW ID instead of normal ID
        movlw   ISD_ID          ; regular ID
	goto	DoIDany		; play it
	
DoIDCW
        movlw   CW_ID           ; CW ID
DoIDany
        movwf   msgNum          ; set message number
        call    PlayMsg         ; play the message
        movf    idDly,w         ; get ID timer delay into w
        movwf   idTmr           ; store to idTmr down-counter
        bcf     flags,initID    ; clear initial ID flag
	movf	state,w		; get the repeater state
	sublw	SRPT		; compare to REPEAT state
        btfss   STATUS,Z	; in REPEAT state?
	bcf	flags,needID	; no. reset needID flag.
	return
	
; 
; turn on PTT & set up ID timer, etc., if needed. 
; 
PTTon				; key the transmitter
	bsf	PORTB,ptt	; apply PTT!
        movf    idTmr,f         ; check ID timer
        btfsc   STATUS,Z        ; is it zero?
        goto    PTTinit         ; yes
	btfsc	flags,needID	; is needID set?
	return			; yes. done.
	goto	PTTset		; not set, set needID and reset idTmr
PTTinit
        bsf     flags,initID    ; ID timer was zero, set initial ID flag
PTTset
	bsf	flags,needID	; need to play ID
        movf    idDly,w         ; get ID timer delay into w
        movwf   idTmr           ; store to down-counter
	return

;
; check to see if there is any reason to leave the transmitter on
;
CheckTx
	btfsc	state,ACTIVE	; in an active state?
        return			; it's active; don't shut off

        movf    isdPlaL,w       ; fetch lo byte of isd play timer
	iorwf	isdPlaH,w	; or in hi byte of isd play timer
        btfss   STATUS,Z        ; skip next if zero
        return			; ISD message is playing, don't shut off

        movf    sISDTmr,f       ; check ISD back off timer for 0
        btfss   STATUS,Z        ; skip next if zero
        return			; waiting on back off timer, don't shut off
        btfsc   flags,cwOn      ; is cw sender going?
        return			; cw is playing, don't shut off
        bcf     PORTB,ptt       ; turn transmitter off
	return
	
;
; Program EEPROM byte
;
EEProg
	clrwdt			; this can take 10 ms, so clear WDT first
        bsf     STATUS,RP0      ; select bank 1
        bcf     INTCON,GIE      ; disable interrupts
        bsf     EECON1,WREN     ; enable EEPROM write
        movlw   h'55'
        movwf   EECON2          ; write 55
        movlw   h'AA'
        movwf   EECON2          ; write AA
        bsf     EECON1,WR       ; start write
        bcf     EECON1,WREN     ; disable write
EEPLoop
        nop
        btfsc   EECON1,WR       ; is write cycle complete?
        goto    EEPLoop         ; wait for write to finish

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
        dw      '6'
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

;
; EEPROM Memory Map (@ 2100h)
;   00 enable/disable flag
;   01 configuration flag
;   02 hang timer preset
;   03 timeout timer preset
;   04 id timer preset
;   05 tail message count
;   06-08 CW OK ( 3 bytes)
;   09-0b CW NG ( 3 bytes)
;   0c-0e CW TO ( 3 bytes)
;   0f-1a CW id (12 bytes)
;   1b-37 empty (29 bytes)
;   38 isd message 0 length
;   39 isd message 1 length
;   3a isd message 2 length
;   3b isd message 3 length
;   3c-3f Password (4 bytes)

;
; Lookup values to load EEPROM addresses with at initialize time 
; if EEADR > EEIEND, return 0.
;
InitDat

        movf    EEADR,w         ; get current address
        sublw   EEIEND          ; EEIEND - EEADR -> w
        btfss   STATUS,C        ; C is clear if result is negative
        retlw   0               ; zero this location       

        movlw   h'03'           ; this subroutine is in the top 256 bytes
        movwf   PCLATH          ; ensure that computed goto will stay in range
        movf    EEADR,w         ; get EEPROM address into w
        addwf   PCL,f           ; add w to PCL
        retlw   h'00'           ; 00 -- enable flag, initially disabled!
	if NHRC3 == 0
        retlw   h'00'           ; 01 -- configuration flag
	ELSE
        retlw   h'08'           ; 01 -- configuration flag
	ENDIF
        retlw   h'32'           ; 02 -- hang timer preset, in tenths
        retlw   h'1e'           ; 03 -- timeout timer preset, in 1 seconds
        retlw   h'36'           ; 04 -- id timer preset, in 10 seconds
        retlw   h'00'           ; 05 -- tail message count
        retlw   h'0f'           ; 06 -- 'O'      1
        retlw   h'0d'           ; 07 -- 'K'      2
        retlw   h'ff'           ; 08 -- EOM      3
        retlw   h'05'           ; 09 -- 'N'      1
        retlw   h'0b'           ; 0a -- 'G'      2
        retlw   h'ff'           ; 0b -- EOM      3
        retlw   h'03'           ; 0c -- 'T'      1
        retlw   h'0f'           ; 0d -- 'O'      2
        retlw   h'ff'           ; 0e -- EOM      3
        retlw   h'09'           ; 0f -- 'D'      1
        retlw   h'02'           ; 10 -- 'E'      2
        retlw   h'00'           ; 11 -- space    3
        retlw   h'05'           ; 12 -- 'N'      4
        retlw   h'10'           ; 13 -- 'H'      5
        retlw   h'0a'           ; 14 -- 'R'      6
        retlw   h'15'           ; 15 -- 'C'      7
        retlw   h'29'           ; 16 -- '/'      8
	IF NHRC3 == 0
        retlw   h'3c'           ; 17 -- '2'      9
	ELSE
        retlw   h'38'           ; 17 -- '3'      9
	ENDIF
        retlw   h'ff'           ; 18 -- EOM     10
        retlw   h'ff'           ; 19 -- EOM     11
        retlw   h'ff'           ; 1a -- EOM     12  can fit 6 letter id....
        
        page

; Lookup EEPROM address of CW message based on index of message
;
GetCwMsg
        movlw   h'03'           ; this subroutine is in the top 256 bytes
        movwf   PCLATH          ; ensure that computed goto will stay in range
        movf    msgNum,w        ; get msgNum into w
	andlw	b'00000011'	; force it into range...
        addwf   PCL,f           ; add w to PCL
        retlw   EECWID          ; 0 = ID message
        retlw   EECWTO          ; 1 = 1 timeout message
        retlw   EECWOK          ; 2 = 2 ok message
        retlw   EECWNG          ; 3 = 3 ng message

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
        movlw   h'03'           ; this subroutine is in the top 256 bytes
        movwf   PCLATH          ; ensure that computed goto will stay in range
        movf    tone,w          ; get tone into w
        addwf   PCL,f           ; add w to PCL
        retlw   0d              ; 0 = D key 
        retlw   01              ; 1 = 1 key
        retlw   02              ; 2 = 2 key
        retlw   03              ; 3 = 3 key
        retlw   04              ; 4 = 4 key
        retlw   05              ; 5 = 5 key
        retlw   06              ; 6 = 6 key
        retlw   07              ; 7 = 7 key
        retlw   08              ; 8 = 8 key
        retlw   09              ; 9 = 9 key
        retlw   00              ; A = 0 key
        retlw   0e              ; B = * key (e)
        retlw   0f              ; C = # key (f)
        retlw   0a              ; D = A key
        retlw   0b              ; E = B key
        retlw   0c              ; F = C key


	IF LOADEE == 1	
	org	2100h
        de	h'01'           ; 00 -- enable flag, initially disabled!
        de	h'08'           ; 01 -- configuration flag
        de	h'32'           ; 02 -- hang timer preset, in tenths
        de	h'3c'           ; 03 -- timeout timer preset, in 1 seconds
        de	h'36'           ; 04 -- id timer preset, in 10 seconds
        de	h'00'           ; 05 -- tail message count
        de	h'0f'           ; 06 -- 'O'      1
        de	h'0d'           ; 07 -- 'K'      2
        de	h'ff'           ; 08 -- EOM      3
        de	h'05'           ; 09 -- 'N'      1
        de	h'0b'           ; 0a -- 'G'      2
        de	h'ff'           ; 0b -- EOM      3
        de	h'03'           ; 0c -- 'T'      1
        de	h'0f'           ; 0d -- 'O'      2
        de	h'ff'           ; 0e -- EOM      3
        de	h'09'           ; 0f -- 'D'      1
        de	h'02'           ; 10 -- 'E'      2
        de	h'00'           ; 11 -- space    3
        de	h'05'           ; 12 -- 'N'      4
        de	h'3e'           ; 13 -- '1'      5
        de	h'0d'           ; 14 -- 'k'      6
        de	h'09'           ; 15 -- 'd'      7
        de	h'0f'           ; 16 -- 'o'      8
        de	h'29'           ; 17 -- '/'      9
        de	h'ff'           ; 18 -- 'r'     10
        de	h'0a'           ; 19 -- EOM     11
        de	h'ff'           ; 1a -- EOM     12  can fit 6 letter id....
	org	2138h
	de	h'00'		; 38 -- length of message 0
	de	h'00'		; 39 -- length of message 1
	de	h'00'		; 3a -- length of message 2
	de	h'00'		; 3b -- length of message 3
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
