; PIC 16C84 Based Repeater Controller.
; Copyright (C) 1996, Jeffrey B. Otterson, N1KDO.  
; All Rights Reserved by the author.
;
; This software may be freely reproduced for use by amateur radio operators
; in their personally owned or club owned radio systems.  All other uses are
; strictly prohibited without the express written consent of the author.  
;
; The author maintains all commercial rights to this software.  Any sale of
; this software or derived works is strictly prohibited without the express
; written consent of the author.
; 
; 21 August 1996
;
        LIST P=16C84, F=INHX8M, R=HEX
        include "p16c84.inc"
        __FUSES _CP_OFF & _XT_OSC & _WDT_OFF
        ERRORLEVEL 0, -302      ;suppress Argument out of range errors
;
VERSION EQU D'027'
;
DEBUG   EQU     0
;
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

; this will generate a dit clock of 5 dits/sec, about 12 wpm.
; (to get 19.2 WPM (8 dits/sec), need a clock of 62.5 ms., or 105 overflows)

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

CW_ID   equ     h'00'
CW_TO   equ     h'01'
CW_OK   equ     h'02'
CW_NG   equ     h'03'
ISD_IID equ     h'10'
ISD_ID  equ     h'11'
ISD_TO  equ     h'12'
ISD_TM  equ     h'13'
ISD_SM  equ     h'14'   ;simplex repeater message 

ISDSIM  equ     2       ;indicates simplex message
ISDMSG  equ     4       ;indicates message is for ISD
MSGREC  equ     7       ;set high bit to indicate record mode

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
MUTE    equ     4       ;mute and init share A.4
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
dv      equ     0       ;DTMF digit valid
ptt     equ     1       ;PTT key
isdPlay equ     2       ;ISD run
isdRec  equ     3       ;ISD record (0) / play (1) select
isdA0   equ     4       ;ISD message select bit 0 
isdA1   equ     5       ;ISD message select bit 1
beepBit equ     6       ;beep generator
cor     equ     7       ;unsquelched (0) / squelched (1)

CTL0    equ     2       ;output lead zero when no ISD
CTL1    equ     3       ;output lead one  when no ISD

;TFlags                 ;timer flags        
TICK    equ     0       ;100 ms tick flag
TENTH   equ     1       ;tenth second decrementer flag
ONESEC  equ     2       ;one second decrementer flag
TENSEC  equ     3       ;ten second decrementer flag
CWTICK  equ     4       ;cw clock bit
TFLCOR  equ     7       ;debounced cor

;flags
initID  equ     0       ;need to ID now
sentID  equ     1       ;recently sent ID
lastDV  equ     2       ;last pass digit valid
init    equ     3       ;initialize
lastCor equ     4       ;last COR flag
isdRecF equ     5       ;ISD record flag
cwOn    equ     6       ;cw sender is active...
beepOn  equ     7       ;beep tone on

;cfgFlag
NOISD   equ     0       ;ISD 1420 is not present
SIMPLEX equ     1       ;simplex repeater mode
;NIY    equ     2       ;NIY
;NIY    equ     3       ;NIY
NOCTSY  equ     4       ;suppress courtesy tone
NOMUTE  equ     5       ;don't mute touch-tones
ISDCTSY equ     6       ;play ISD message 3 for courtesy tone
;NIY    equ     7       ;NIY


;state, bit 0 set indicates transmitter should be on...
SQUIET  equ     0
SRPT    equ     1
STIMOUT equ     2
SHANG   equ     3
SDISABL equ     4

SACTIVE equ     b'00000001'     ;active mask, don't turn off PTT when ISD done

;debounce count complete Bit 
        IF DEBUG == 1
CDBBIT  equ     1               ; debounce counts to 2, about 1.143 ms?
        ELSE
CDBBIT  equ     5               ; debounce counts to 32, about 18.2 ms
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
EEIEND  equ     h'1a'           ;last EEPROM to program with data at init time
EELAST  equ     h'37'           ;last EEPROM address to init

EEM0LEN equ     h'38'
EEM1LEN equ     h'39'
EEM2LEN equ     h'3a'
EEM3LEN equ     h'3b'
EETTPRE equ     h'3c'

;
;DTMF remote control constants
;
TONES   EQU     4               ;number of digits in received touch tone command
MAXCMD  EQU     4               ;maximum number of digits in command

;
; CW sender constants
;
CWDIT   equ     1               ;dit = 100 ms
CWDAH   equ     CWDIT * 3       ;dah = 300 ms
CWIESP  equ     CWDIT           ;inter-element space = 100 ms
CWILSP  equ     CWDAH           ;inter-letter space = 300 ms
CWIWSP  equ     7               ;inter-word space = 700 ms

ISDSMAX EQU     D'198'          ;preset max ISD record time 19.8 sec (simplex)
ISDMAX  EQU     D'48'           ;preset max ISD record time 4.8 sec
ISDBKOF EQU     D'3'            ;preset simplex ISD backoff time .3 sec

        IF DEBUG == 1
OFBASE  equ     D'2'            ;overflow counts fast!
TEN     equ     D'2'
        ELSE
OFBASE  equ     D'175'          ;overflow counts in 100.12 ms
TEN     equ     D'10'
        ENDIF

CWCNT   equ     D'105'          ;approximately 60 ms for 20 wpm

IDSOON  equ     D'6'            ;ID soon, polite IDer threshold, 60 sec
MUTEDLY equ     D'20'           ;DTMF muting timer

;macro definitions
push    macro
        movwf   w_copy          ;save w reg in Buffer
        swapf   w_copy,f        ;swap it
        swapf   STATUS,w        ;get status
        movwf   s_copy          ;save it
        endm
;
pop     macro
        swapf   s_copy,w        ;restore status
        movwf   STATUS          ;       /
        swapf   w_copy,w        ;restore W reg
        endm

;variables
        cblock  0c
        w_copy                  ;saved W register for interrupt handler
        s_copy                  ;saved status register for int handler
        cfgFlag                 ;Configuration Flags
        tFlags                  ;Timer Flags
        flags                   ;operating Flags
        ofCnt                   ;100 ms timebase counter
        cwCntr                  ;cw timebase counter
        secCnt                  ;one second count
        tenCnt                  ;ten second count
        state                   ;CAS state
        hangDly                 ;hang timer preset, in tenths
        tOutDly                 ;timeout timer preset, in 1 seconds
        idDly                   ;id timer preset, in 10 seconds
        hangTmr                 ;hang timer, in tenths
        tOutTmr                 ;timeout timer, in 1 seconds
        idTmr                   ;id timer, in 10 seconds
        isdTmr                  ;ISD1240 playback timer, in tenths
        isdRTmr                 ;ISD1240 record timer, in tenths (up-counter)
        sISDTmr                 ;simplex ISD back-off timer
        muteTmr                 ;DTMF muting timer, in tenths
        cwTmr                   ;CW element timer
        msgNum                  ;message number to play
        tone                    ;touch tone digit received
        toneCnt                 ;digits received down counter
        cmdCnt                  ;command digists received
        tBuf1                   ;tones received buffer
        tBuf2                   ;tones received buffer
        tBuf3                   ;tones received buffer
        tBuf4                   ;tones received buffer
        cwBuff                  ;CW message buffer offset
        cwByte                  ;CW current byte (bitmap)                 
        tMsgCtr                 ;tail message counter
        dBounce                 ;cor debounce counter
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
        push                    ;preserve W and STATUS

        btfsc   INTCON,T0IF
        goto    TimrInt
        goto    IntExit

TimrInt
        btfss   flags,beepOn    ;is beep turned on?
        goto    TimrTst         ;no, continue
        btfss   PORTB,beepBit   ;is beepBit set?
        goto    Beep0           ;no
        bcf     PORTB,beepBit   ;yes, turn it off
        goto    TimrTst         ;continue
Beep0
        bsf     PORTB,beepBit   ;beep bit is off, turn it on...

TimrTst
        decfsz  ofCnt,f         ;decrement the overflow counter
        goto    TimrDone        ;if not 0, then 
        bsf     tFlags,TICK     ;set tick indicator flag
        movlw   OFBASE          ;preset overflow counter
        movwf   ofCnt           

TimrDone                        
        decfsz  cwCntr,f        ;decrement the cw timebase counter
        goto    DBounce
        bsf     tFlags,CWTICK   ;set tick indicator
        movlw   CWCNT           ;get preset value
        movwf   cwCntr          ;preset cw timebase counter

DBounce                         ;COR debounce
        btfss   PORTB,cor       ;check cor
        goto    ICorOn          ;it's low...
                                ;squelch is closed; receiver is inactive
        movf    dBounce,f       ;check debounce counter for zero
        btfsc   STATUS,Z        ;is it zero?
        goto    TIntDone        ;yes
        decf    dBounce,f       ;no, decrement it
        btfss   STATUS,Z        ;is it zero?
        goto    TIntDone        ;no, continue
        bsf     tFlags,TFLCOR   ;yes, turn COR off
        goto    TIntDone        ;done with COR debouncing...        

ICorOn  
                                ;squelch is open; receiver is active
        btfsc   dBounce,CDBBIT  ;check debounce counter
        goto    TIntDone        ;already maxed out
        incf    dBounce,f       ;increment 
        btfss   dBounce,CDBBIT  ;is it maxed now?
        goto    TIntDone        ;no
        bcf     tFlags,TFLCOR   ;yes, turn COR on

TIntDone
        bcf     INTCON,T0IF     ;clear RTCC int mask

IntExit
        pop                     ;restore W and STATUS
        retfie

Start
        bsf     STATUS,RP0      ;select bank 1
        movlw   b'00011111'     ;low 5 bits are input
        movwf   TRISA           ;set port a as outputs
        movlw   b'10000001'     ;RB0&RB7 inputs
        movwf   TRISB

        IF DEBUG == 1
        movlw   b'10001000'     ;DEBUG! no pull up, timer 0 gets no prescale
        ELSE
        movlw   b'10000000'     ;no pull up, timer 0 gets prescale 2
        ENDIF

        movwf   OPTION_REG      ;

        bcf     STATUS,RP0      ;select page 0
        clrf    PORTB           ;init port B
        clrf    PORTA           ;make port a all low
        clrf    state           ;clear state (quiet)
        clrf    tFlags          ;clear timer flags
        bsf     tFlags,TFLCOR   ;set debouced cor off
        clrf    flags           ;clear status flags
        clrf    msgNum          ;clear message number
        movlw   OFBASE          ;preset overflow counter
        movwf   ofCnt           
        movlw   CWCNT           ;get preset value
        movwf   cwCntr          ;preset cw timebase counter

        movlw   TEN             ;preset decade counters
        movwf   secCnt          ;1 second down counter
        movwf   tenCnt          ;10 second down counter

        clrf    hangTmr         ;clear hang timer
        clrf    tOutTmr         ;clear timeout timer
        clrf    idTmr           ;clear idTimer
        clrf    isdTmr          ;clear isdTimer
        clrf    muteTmr         ;clear muting timer
        clrf    sISDTmr         ;clear ISD back off timer
        clrf    cmdCnt          ;clear command counter
        clrf    dBounce         ;clear debounce timer counter
        movlw   TONES
        movwf   toneCnt         ;preset tone counter

        btfsc   PORTA,INITBIT   ;check to see if init is pulled low
        goto    NoInit          ;init is not low, continue...

        bsf     flags,init      ;initialization in progress

        movlw   EELAST          ;get last address to initialize
        movwf   EEADR           ;set EEPROM address to program 
InitLp
        call    InitDat         ;get init data byte 
        movwf   EEDATA          ;put into EEPROM data register
        call    EEProg          ;program byte
        movf    EEADR,f         ;load status, set Z if zero (last byte done)
        btfsc   STATUS,Z        ;skip if Z is clear (not last byte)
        goto    InitISD         ;done initializing EEPROM data
        decf    EEADR,f         ;decrement EEADR
        goto    InitLp 

InitISD
        movlw   d'1'            ;0.1 sec message length default
        movwf   EEDATA          ;put into EEPROM data register
        movlw   EEM0LEN         ;address of message 0 length
        movwf   EEADR           ;set EEPROM address to program 
        call    EEProg          ;program byte
        incf    EEADR,f         ;increment address of byte to init
        call    EEProg          ;program byte EEM1LEN
        incf    EEADR,f         ;increment address of byte to init
        call    EEProg          ;program byte EEM2LEN
        incf    EEADR,f         ;increment address of byte to init
        call    EEProg          ;program byte EEM3LEN

NoInit
        bsf     STATUS,RP0      ;select bank 1
        movlw   b'00001111'     ;low 4 bits are input, RA4 is muting control
        movwf   TRISA           ;set port a as outputs
        bcf     STATUS,RP0      ;select bank 1

        call    GetData         ;read EEPROM data

        movlw   b'10100000'     ;enable interrupts, & Timer 0 overflow
        movwf   INTCON 

Loop
        ;check CW bit
        btfss   tFlags,CWTICK   ;is the CWTICK set      
        goto    NoCW
        bcf     tFlags,CWTICK   ;reset the CWTICK flag bit

        ;
        ;CW sender
        ;
        btfss   flags,cwOn      ;sending CW?
        goto    NoCW            ;nope
        decfsz  cwTmr,f         ;decrement CW timer
        goto    NoCW            ;not zero
        
        btfss   flags,beepOn    ;was "key" down?
        goto    CWKeyUp         ;nope
                                ;key was down        
        bcf     flags,beepOn    ;key->up
        decf    cwByte,w        ;test CW byte to see if 1
        btfsc   STATUS,Z        ;was it 1 (Z set if cwByte == 1)
        goto    CWNext          ;it was 1...
        movlw   CWIESP          ;get cw inter-element space
        movwf   cwTmr           ;preset cw timer
        goto    NoCW            ;done with this pass...

CWNext                          ;get next character of message
        incf    cwBuff,f        ;increment offset
        movf    cwBuff,w        ;get offset
        call    ReadEE          ;get char from EEPROM
        movwf   cwByte          ;store character bitmap
        btfsc   STATUS,Z        ;is this a space (zero)
        goto    CWWord          ;yes, it is 00
        incf    cwByte,w        ;check to see if it is FF
        btfsc   STATUS,Z        ;if this bitmap was FF then Z will be set
        goto    CWWord          ;yes, it is FF
        movlw   CWILSP          ;no, not 00 or FF, inter letter space
        movwf   cwTmr           ;preset cw timer
        goto    NoCW            ;done wiht this pass...

CWWord                          ;word space
        movlw   CWIWSP          ;get word space
        movwf   cwTmr           ;preset cw timer
        goto    NoCW            ;done wiht this pass...

CWKeyUp                         ;key was up, key again...
        incf    cwByte,w        ;is cwByte == ff?
        btfsc   STATUS,Z        ;Z is set if cwByte == ff
        goto    CWDone          ;got EOM

        movf    cwByte,f        ;check for zero/word space
        btfss   STATUS,Z        ;is it zero
        goto    CWTest          ;no...
                                ;is 00, word space...
        incf    cwBuff,f        ;increment offset
        movf    cwBuff,w        ;get offset
        call    ReadEE          ;get char from EEPROM
        movwf   cwByte          ;store character bitmap
        btfsc   STATUS,Z        ;check for another word space
        goto    NoCW            ;if another space, done with this pass...
CWTest
        movlw   CWDIT           ;get dit length
        btfsc   cwByte,0        ;check low bit
        movlw   CWDAH           ;get DAH length
        movwf   cwTmr           ;preset cw timer
        bsf     flags,beepOn    ;turn key->down
        rrf     cwByte,f        ;rotate cw bitmap
        bcf     cwByte,7        ;clear the MSB
        goto    NoCW            ;done with this pass...

CWDone                          ;done sending CW
        bcf     flags,cwOn      ;turn off CW flag

NoCW
        movlw   b'11110001'     ;set timer flags mask
        andwf   tFlags,f        ;clear timer flags
        btfss   tFlags,TICK     ;check to see if a tick has happened
        goto    Loop1
        
        ;
        ; 100ms tick has occurred...
        ;
        bcf     tFlags,TICK     ;reset tick flag
        bsf     tFlags,TENTH    ;set tenth second flag
        decfsz  secCnt,f        ;decrement 1 second counter
        goto    Loop1           ;not zero (not 1 sec interval)

        ;
        ; 1s tick has occurred...
        ;
        movlw   TEN             ;preset decade counter
        movwf   secCnt          

        bsf     tFlags,ONESEC   ;set one second flag

        decfsz  tenCnt,f        ;decrement 10 second counter
        goto    Loop1           ;not zero (not 10 second interval)

        ;
        ; 10s tick has occurred...
        ;
        movlw   TEN             ;preset decade counter
        movwf   tenCnt
        bsf     tFlags,TENSEC   ;set ten second flag 

        ;
        ; main loop for repeater controller
        ;
Loop1
        ;computed GOTO used as a switch()
        movlw   h'00'
        movwf   PCLATH          ;ensure that computed goto will stay in range
        movf    state,w         ;get state into w
        addwf   PCL,f           ;add w to PCL
        goto    Quiet           ;0
        goto    Repeat          ;1
        goto    TimeOut         ;2
        goto    Hang            ;3
        goto    CasEnd          ;4

Quiet
        btfsc   tFlags,TFLCOR   ;is squelch open?
        goto    CasEnd          ;no

        btfss   cfgFlag,SIMPLEX ;simplex mode?
        goto    QKeyUp
                                ; *** SIMPLEX ***
        btfsc   flags,cwOn      ;is cw playing?
        goto    CasEnd          ;can't go into record if cw is playing

        movf    isdTmr,f        ;check ISD timer
        btfss   STATUS,Z        ;is it zero
        goto    CasEnd          ;no, ISD is playing, don't record

        movlw   SRPT            ;
        movwf   state           ;change state to repeat

        bcf     PORTB,isdRec    ;stop any recording message
        bcf     PORTB,isdPlay   ;stop any playing message
        bcf     PORTB,isdA0     ;reset message address bits
        bcf     PORTB,isdA1     
        bcf     PORTB,ptt       ;turn transmitter off
        bsf     flags,isdRecF   ;set record mode
        clrf    msgNum          ;set message number to zero
        bsf     msgNum,ISDMSG   ;set message to be for ISD
        movlw   ISDSMAX         ;get maximum simplex message length
        movwf   isdTmr          ;preset max duration counter
        clrf    isdRTmr         ;zero recorded duration timer
        bcf     PORTA,MUTE      ;unmute
        bsf     PORTB,isdRec    ;start recording

        movf    idTmr,f         ;check ID timer
        btfss   STATUS,Z        ;is it zero?
        goto    CasEnd          ;non zero
        movf    idDly,w         ;get ID timer delay into w
        movwf   idTmr           ;store to down-counter
        goto    CasEnd

QKeyUp
        bsf     PORTB,ptt       ;turn transmitter on

KeyUp   
        movf    isdTmr,f        ;check ISD timer
        btfsc   STATUS,Z        ;is it zero
        goto    Key0            ;yes, no message playing
        btfsc   msgNum,1        ;is it an ID message?
        goto    Key0            ;no, let it go
                                ;stomp on playing voice message
        clrf    isdTmr          ;clear ISD timer
        bcf     PORTB,isdPlay   ;turn off ISD1240 playback
        movlw   CW_ID           ;play CW Id
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message

Key0
        bcf     PORTA,MUTE      ;unmute
        btfss   flags,cwOn      ;is cw playing?
        bcf     flags,beepOn    ;no, make sure that beep is off.

        movf    tOutDly,w       ;get timeout delay into w
        movwf   tOutTmr         ;preset timeout counter

        movlw   SRPT            
        movwf   state           ;change state to repeat

        btfss   msgNum,MSGREC   ;is record flag set?
        goto    Key1            ;nope...
        bcf     msgNum,MSGREC   ;clear record flag
        bsf     flags,isdRecF   ;set record mode
        movlw   ISDMAX          ;get maximum length...
        movwf   isdTmr          ;preset max duration
        clrf    isdRTmr         ;clear recorded duration timer
        bsf     PORTB,isdRec    ;turn on ISD record

Key1
        movf    idTmr,f         ;check ID timer
        btfss   STATUS,Z        ;is it zero?
        goto    Key2            ;non zero
        
        bsf     flags,initID    ;ID timer was zero, set initial ID flag
        goto    CasEnd
        
Key2
        btfss   flags,sentID    ;sent ID recently?     
        goto    CasEnd          ;no

        bcf     flags,sentID    ;clear recent ID flag
        
        movf    idDly,w         ;get ID timer delay into w
        movwf   idTmr           ;store to down-counter
        goto    CasEnd

Repeat
        btfss   tFlags,ONESEC   ;check to see if one second tick
        goto    Repeat1         ;nope...

        decfsz  tOutTmr,f       ;decrement timeout timer
        goto    Repeat1         ;not to zero yet...
        goto    TimedOut        ;timed out!

Repeat1
        btfss   tFlags,TFLCOR   ;is squelch open?
        goto    CasEnd          ;no, keep repeating
        bsf     PORTA,MUTE      ;mute the audio...
        clrf    muteTmr         ;cancel timed unmute from dtmf muting
        
        btfss   flags,isdRecF   ;is it in record mode?
        goto    CorOff          ;nope, skip next part
        bcf     PORTB,isdRec    ;recording, carrier dropped, stop recording
        bcf     flags,isdRecF   ;turn off record flag
        clrf    isdTmr          ;clear ISD timer
        btfss   cfgFlag,SIMPLEX ;in simplex mode?
        goto    RecEnd          ;no
                                ; *** SIMPLEX ***
SimPlay
        movlw   ISDBKOF         ;get the ISD back off delay
        movwf   sISDTmr         ;save the ISD back off delay
        bsf     PORTB,ptt       ;turn transmitter on
        movlw   SQUIET          
        movwf   state           ;change state to quiet
        goto    CasEnd
        
RecEnd
        movf    msgNum,w        ;get message number
        andlw   b'00000011'     ;mask out bit 2-7
        addlw   EEM0LEN         ;add address of message 0 length
        movwf   EEADR           ;set EEPROM address
        decf    isdRTmr,w       ;get timer - 1 (less 100 ms)
        movwf   EEDATA          ;put into EEPROM data register...
        call    EEProg          ;save message length

CorOff                          ;cor on->off transition
        btfsc   cfgFlag,SIMPLEX ;in simplex mode?
        goto    SimPlay         ;play (truncated) recorded message 

        clrf    muteTmr         ;reset the mute timer
        clrf    tOutTmr         ;clear time out timer
        movf    hangDly,w       ;get hang timer preset
        btfsc   STATUS,Z        ;is hang timer preset 0?
        goto    NoHang          ;no hang time
        movwf   hangTmr         ;preset hang timer
        movlw   SHANG            
        movwf   state           ;change state to hang
        goto    CorOff2

NoHang
        movlw   SQUIET          ;change state to quiet
        movwf   state           ;save state

CorOff2
        btfss   flags,initID    ;check initial id flag
        goto    CkId2           ;not set...
        movlw   ISD_IID         ;initial ID
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message
        goto    ResetID         ;reset timers, flags, & continue        

CkId2
        btfsc   flags,sentID    ;id sent lately?
        goto    CasEnd          ;yes, go on...

        ;
        ;if (idTmr <= idSoon) then goto StartID
        ;implemented as: if ((IDSOON-idTimer)>=0) then goto StartID
        ;
        movf    idTmr,w         ;get idTmr into W
        sublw   IDSOON          ;IDSOON-w ->w
        btfss   STATUS,C        ;C is clear if result is negative
        goto    CasEnd          ;don't need to ID yet...

        movlw   ISD_ID          ;regular ID
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message
        goto    ResetID         ;reset timers, flags, & continue        

TimedOut
        bsf     PORTA,MUTE      ;mute the audio...
        clrf    muteTmr         ;reset the mute timer
        movlw   STIMOUT
        movwf   state           ;change state to timed out
        movlw   ISD_TO          ;ISD time out message
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message
        goto    CasEnd
        
Hang    
        btfss   tFlags,TFLCOR   ;is squelch open?
        goto    KeyUp           ;yes!

        btfss   tFlags,TENTH    ;check to see if tenth second tick
        goto    CasEnd

        btfsc   flags,cwOn      ;is cw playing?
        goto    Hang2           ;yes, don't ctsy beep

        btfsc   cfgFlag,NOCTSY  ;check for suppressed courtesy tone
        goto    Hang2           ;suppressed...

        ;test to see if time for ctsy tone here
        movf    hangTmr,w       ;get hang timer
        addlw   5               ;add 500 ms
        subwf   hangDly,w       ;subtract hang delay
        btfss   STATUS,Z        ;zero if equal
        goto    Hang1
        movf    isdTmr,f        ;check isd timer
        btfss   STATUS,Z        ;is it zero?
        goto    Hang2           ;no; ISD is playing, don't beep
        btfsc   cfgFlag,ISDCTSY ;check for ISD stored courtesy tone
        goto    ISDCtsy
        bsf     flags,beepOn    ;turn on beep
        goto    Hang2

ISDCtsy                         ;want to play ISD message 3 for courtesy tone
        movlw   ISD_TM          ;ISD tail message plays as courtesy tone
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message
        goto    Hang2

Hang1
        btfsc   cfgFlag,ISDCTSY ;check for ISD stored courtesy tone
        goto    Hang2

        movf    hangTmr,w       ;get hang timer
        addlw   7               ;add 700 ms so beep is 200 ms long
        btfsc   flags,init      ;in init mode?
        addlw   3               ;add another 300 ms so beep is 500 ms long
        subwf   hangDly,w       ;subtract hang delay
        btfss   STATUS,Z        ;zero if equal
        goto    Hang2
        bcf     flags,beepOn    ;turn off beep

Hang2
        decfsz  hangTmr,f       ;decrement hang timer
        goto    CasEnd          ;not zero yet
        
        movlw   SQUIET          
        movwf   state           ;change state to quiet

        movf    tMsgCtr,f       ;check tail message counter
        btfsc   STATUS,Z        ;Z will be set if counter is zero, skip
        goto    CasEnd          ;tMsgCtr is zero
        decfsz  tMsgCtr,f       ;decrement the tail message counter
        goto    CasEnd          ;not zero yet
        movlw   EETMSG          ;get address of tail message counter preset
        call    ReadEE          ;read EEPROM
        movwf   tMsgCtr         ;restore w into tail message counter
        movlw   ISD_TM          ;get the tail message
        movwf   msgNum          ;save it as the message to play
        call    PlayMsg         ;play the message
        goto    CasEnd          ;done

TimeOut
        btfss   tFlags,TFLCOR   ;is squelch open?
        goto    CasEnd          ;no, stay timed out...
        
        movlw   SQUIET          
        movwf   state           ;change state to quiet

        movlw   ISD_TO          ;ISD time out message
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message

CasEnd
        movf    isdTmr,f        ;check isdTimer
        btfsc   STATUS,Z        ;is it zero?
        goto    ID1             ;yes, don't need to check it's timer...

        btfss   tFlags,TENTH    ;check to see if tenth second tick
        goto    ID1             ;nope

        btfsc   flags,isdRecF   ;is the ISD in record mode?
        incf    isdRTmr,f       ;yes. increment the record timer

        decfsz  isdTmr,f        ;decrement ISD1240 play timer
        goto    ID1             ;not zero yet...
        btfss   flags,isdRecF   ;is it in record mode
        goto    ISDpOff         ;no

        bcf     PORTB,isdRec    ;recording, time is up, truncate recording
        bcf     flags,isdRecF   ;turn off record flag
        btfsc   cfgFlag,SIMPLEX ;in simplex mode?
        goto    ID1             ;yes, don't store message length

                                ;store message length
        movf    msgNum,w        ;get message number
        andlw   b'00000011'     ;mask out bit 2-7
        addlw   EEM0LEN         ;add address of message 0 length
        movwf   EEADR           ;set EEPROM address

        decf    isdRTmr,w       ;get timer - 1
        movwf   EEDATA          ;put into EEPROM data register...
        call    EEProg          ;save message length
        goto    ID1             ;

ISDpOff
        bcf     PORTB,isdPlay   ;zero, turn off ISD1240 playback

ID1
        movf    idTmr,f         
        btfsc   STATUS,Z        ;is idTmr 0
        goto    CkBkOff         ;yes...

        btfss   tFlags,TENSEC   ;check to see if ten second tick
        goto    CkBkOff         ;nope...

        decfsz  idTmr,f         ;decrement ID timer
        goto    CkBkOff         ;not zero yet...
                                ;id timer is zero! time to ID
        btfsc   flags,sentID    ;check recent id flag
        goto    ID2             ;set...

StartID                         ;id timer timeout...
        movlw   ISD_ID          ;regular ID
        btfss   tFlags,TFLCOR   ;is squelch open?
        movlw   CW_ID           ;CW ID
        movwf   msgNum          ;set message number
        call    PlayMsg         ;play the message

ResetID
        movf    idDly,w         ;get ID timer delay into w
        movwf   idTmr           ;store to idTmr down-counter
        bcf     flags,initID    ;clear initial ID flag
        bsf     flags,sentID    ;set recent ID flag
        goto    CkBkOff          

ID2
        bcf     flags,sentID    ;clear recent ID flag

CkBkOff
        movf    sISDTmr,f       ;check ISD backoff timer
        btfsc   STATUS,Z        ;is it zero?
        goto    CkTone          ;yes
        btfss   tFlags,TENTH    ;check to see if tenth second tick
        goto    CkTone          ;nope
        decfsz  sISDTmr,f       ;decrement ISD1240 backoff timer
        goto    CkTone          ;not zero yet...
        movlw   ISD_SM          ;ISD simplex message
        movwf   msgNum          ;set message number
        call    ISDPlay         ;start the message playing

CkTone
        btfss   PORTB,dv        ;check M8870 digit valid
        goto    NoTone          ;not set
        btfsc   flags,lastDV    ;check to see if set on last pass
        goto    ToneDon         ;it was already set
        bsf     flags,lastDV    ;set lastDV flag

        btfsc   cfgFlag,NOMUTE  ;check for no muting flag
        goto    MuteEnd         ;no muting...
        
        movlw   MUTEDLY         ;get mute timer delay
        movwf   muteTmr         ;preset mute timer
        bsf     PORTA,MUTE      ;set muting

MuteEnd
        movf    PORTA,w         ;get DTMF digit
        andlw   TMASK           ;mask off hi nibble
        movwf   tone            ;save digit
        goto    ToneDon 

NoTone
        btfss   flags,lastDV    ;is lastDV set
        goto    ToneDon         ;nope...
        bcf     flags,lastDV    ;clear lastDV flag...

        btfsc   flags,init      ;in init mode?
        goto    WrTone          ;yes, go write the tone

        movf    toneCnt,w       ;test toneCnt
        btfss   STATUS,Z        ;is it zero?
        goto    CkDigit         ;no

        ;password has been successfully entered, start storing tones

        ;make sure that there is room for this digit
        movlw   MAXCMD          ;get max # of command tones
        subwf   cmdCnt,w        ;cmdCnt - MAXCMD -> w
        btfsc   STATUS,Z        ;if Z is set then there is no more room
        goto    Wait            ;no room, just ignore it...

        ;there is room for this digit, calculate buffer address...
        movlw   tBuf1           ;get address of first byte in buffer
        addwf   cmdCnt,w        ;add offset
        movwf   FSR             ;set indirection register
        movf    tone,w          ;get tone
        call    MapDTMF         ;convert to hex value
        movwf   INDF            ;save into buffer location
        incf    cmdCnt,f        ;increment cmdCnt
        goto    Wait

CkDigit
        ;check this digit against the code table
        sublw   TONES           ;w = TONES - w; w now has digit number
        addlw   EETTPRE         ;w = w + EETTPRE; the digit's EEPROM address
        call    ReadEE          ;read EEPROM
        subwf   tone,w          ;w = tone - w
        btfss   STATUS,Z        ;is w zero?
        goto    NotTone         ;no...
        decf    toneCnt,f       ;decrement toneCnt
        goto    ToneDon

NotTone
        movlw   TONES
        subwf   toneCnt,w       
        btfsc   STATUS,Z        ;is this the first digit?
        goto    BadTone         ;yes
        movlw   TONES           ;reset to check to see if this digit
        movwf   toneCnt         ;is the first digit...
        goto    CkDigit

WrTone                          ;save tone in EEPROM to init password
        movf    toneCnt,w       ;test toneCnt
        sublw   TONES           ;w = TONES - w; w now has digit number
        addlw   EETTPRE         ;w = w + EETTPRE; the digit's EEPROM address
        movwf   EEADR           ;EEADR = w
        movf    tone,w          ;get tone
        movwf   EEDATA          ;put into EEPROM data register...
        call    EEProg          ;call EEPROM prog routine

        decfsz  toneCnt,f       ;decrement tone count        
        goto    ToneDon         ;not zero, still in init mode
        bcf     flags,init      ;zero, out of init mode

BadTone       
        movlw   TONES           ;no... get number of command tones into w
        movwf   toneCnt         ;preset number of command tones

ToneDon
        movlw   SACTIVE         ;get active mask
        andwf   state,w         ;check to see if active, zero is not active
        btfss   STATUS,Z        ;skip next if not active
        goto    Wait
        movf    isdTmr,f        ;check isdTmr for 0
        btfss   STATUS,Z        ;skip next if zero
        goto    Wait
        movf    sISDTmr,f       ;check ISD back off timer for 0
        btfss   STATUS,Z        ;skip next if zero
        goto    Wait
        btfsc   flags,cwOn      ;is cw sender going?
        goto    Wait            ;yes, keep going...
        bcf     PORTB,ptt       ;turn transmitter off

Wait
        btfss   tFlags,TENTH    ;check to see if one tenth second tick
        goto    Wait1           ;nope...

        movf    muteTmr,f       ;test mute timer
        btfsc   STATUS,Z        ;Z is set if not DTMF muting
        goto    Wait1           ;
        decfsz  muteTmr,f       ;decrement muteDly
        goto    Wait1           ;have not reached the end of the mute time
        bcf     PORTA,MUTE      ;unmute

Wait1
        btfsc   tFlags,TFLCOR   ;is squelch open?
        goto    CorOn           ;yes
        btfss   flags,lastCor   ;cor is off, is last COR off?
        goto    Loop            ;last COR is also off, do nothing here
        ;COR on->off transition (receiver has just unsquelched)
        bcf     flags,lastCor   ;clear last COR flag
        call    ClrTone         ;clear password tones & commands
        goto    Loop

CorOn
        btfsc   flags,lastCor   ;cor is ON, is last COR on?
        goto    Loop            ;last COR is also on, do nothing here
        ;COR off->on transition (receiver has just squelched)
        bsf     flags,lastCor   ;set last COR flag

        ;evaluate touch tones in buffer
        movf    cmdCnt,f        ;check to see if any stored tones
        btfsc   STATUS,Z        ;is it zero?
        goto    Loop            ;no stored tones

        movlw   MAXCMD          ;get max # of command tones
        subwf   cmdCnt,w        ;cmdCnt - MAXCMD -> w
        btfss   STATUS,Z        ;if Z is set then there are enough digits
        goto    CmdDone         ;not enough command digits...

        ;there are tones stored in the buffer...
        swapf   tBuf1,w         ;swap nibble of tBuf1 and store in w
        iorwf   tBuf2,w         ;or in low nibble (tBuf2)
        movwf   tBuf1           ;store resultant 8 bit value into tBuf1

        swapf   tBuf3,w         ;swap nibble of tBuf3 and store in w
        iorwf   tBuf4,w         ;or in low nibble (tBuf4)
        movwf   tBuf3           ;store resultant 8 bit value into tBuf3

        ;test the address...
        btfsc   tBuf1,7         ;bit 7 is not allowed         
        goto    BadCmd
        btfsc   tBuf1,6         ;bit 6 indicates command: 4xxx,5xxx,6xxx,7xxx
        goto    MsgCmd

        ;program the byte...
        movf    tBuf1,w         ;get address
        movwf   EEADR
        movf    tBuf3,w         ;get data byte
        movwf   EEDATA
        call    EEProg          ;program EE byte

        movlw   CW_OK
        movwf   msgNum
        call    PlayMsg

        ;test to see if any of the runtime variables need modification
TstEnab
        movf    tBuf1,w         ;get address
        btfss   STATUS,Z        
        goto    TstConf         
        movf    tBuf3,f
        btfss   STATUS,Z        ;is data 0?
        goto    TstEna1
        movlw   SDISABL
        movwf   state
        goto    TstDone
TstEna1
        movlw   SQUIET          ;enable repeater
        movwf   state
        bcf     flags,initID    ;
        bcf     flags,sentID    ;
        goto    TstDone

TstConf
        movf    tBuf1,w         ;get address
        sublw   EECONF          ;subtract CONFIG address
        btfss   STATUS,Z        
        goto    TstHang
        movf    tBuf3,w
        movwf   cfgFlag         ;store w into config flag

        clrf    hangTmr         ;clear hang timer
        clrf    tOutTmr         ;clear timeout timer
        clrf    isdTmr          ;clear isdTimer
        clrf    muteTmr         ;clear muting timer
        clrf    sISDTmr         ;clear ISD back off timer
        bcf     PORTB,isdRec    ;stop any recording message

        clrf    state           ;reset to quiet state
        goto    TstDone

TstHang
        movf    tBuf1,w         ;get address
        sublw   EEHANG          ;subtract HANG address
        btfss   STATUS,Z        
        goto    TstTOut
        movf    tBuf3,w
        movwf   hangDly         ;store w into hang time delay preset
        goto    TstDone
        
TstTOut
        movf    tBuf1,w         ;get address
        sublw   EETOUT          ;subtract TIMEOUT address
        btfss   STATUS,Z        
        goto    TstID
        movf    tBuf3,w
        movwf   tOutDly         ;store w into time out delay preset
        goto    TstDone

TstID
        movf    tBuf1,w         ;get address
        sublw   EEID            ;subtract ID address
        btfss   STATUS,Z        
        goto    TstTM
        movf    tBuf3,w
        movwf   idDly           ;store w into ID delay preset
        goto    TstDone

TstTM
        movf    tBuf1,w         ;get address
        sublw   EETMSG          ;subtract tail message counter address
        btfss   STATUS,Z        
        goto    TstDone
        movf    tBuf3,w
        movwf   tMsgCtr         ;store w into tail message counter
        goto    TstDone

TstDone
        call    ClrTone
        goto    Loop

MsgCmd                          ;4x, 5x, 6x, 7x commands
        movf    tBuf1,w         ;get command byte
        andlw   b'10111110'     ;check for invalid values
        btfss   STATUS,Z        ;
        goto    BadCmd          ;only 40, 41 are valid now

        ;right after movf
        ;jeff
        movlw   h'02'           ;this value must equal address' high byte
        movwf   PCLATH          ;ensure that computed goto will stay in range
        swapf   tBuf1,w         ;swap command byte into w
        andlw   b'00000011'     ;mask bits that make up remainder of command
        addwf   PCL,f           ;add w to PCL
        goto    Cmd4x           ;note that the 4 bit has been stripped so 4 = 0
        goto    Cmd5x
        goto    Cmd6x
        goto    Cmd7x

Cmd4x
        btfss   tBuf1,0         
        goto    MsgPlay         ;40nn command

        movf    tBuf3,w         ;get argument
        movwf   msgNum          ;save into message number
        call    ISDRec          ;get ready to record...
        goto    Loop

Cmd5x
        movf    tBuf2,f         ;check 2nd digit
        btfss   STATUS,Z        ;is it zero?
        goto    BadCmd          ;nope

        btfsc   tBuf3,0         ;lo bit clear?
        goto    Cmd50Odd        ;nope, 51, 53, etc.
        
        btfsc   tBuf4,0         ;lo bit clear?
        goto    Cmd50ES         ;nope, set (turn on)
        bcf     PORTB,CTL0      ;clear output (off/lo)
        goto    GoodCmd

Cmd50ES 
        bsf     PORTB,CTL0      ;set output (on/hi)
        goto    GoodCmd
        
Cmd50Odd
        
        btfsc   tBuf4,0         ;lo bit clear?
        goto    Cmd50OS         ;nope, set (turn on)
        bcf     PORTB,CTL1      ;clear output (off/lo)
        goto    GoodCmd

Cmd50OS 
        bsf     PORTB,CTL1      ;set output (on/hi)
        goto    GoodCmd

Cmd6x
Cmd7x
        goto    BadCmd
        
MsgPlay                         ;command 40
        movf    tBuf3,w         ;get argument
        movwf   msgNum          ;save into message number
        call    PlayMsg
        goto    Loop
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
        goto    Loop

;
;Read EEPROM variables
;
GetData
        movlw   EEENAB
        call    ReadEE          ;read EEPROM
        btfss   STATUS,Z        ;Z is set if disabled
        goto    GDEnab
        movlw   SDISABL         ;set state disabled
        movwf   state           ;save state
        goto    GDHang

GDEnab
        movlw   SQUIET          ;set state enabled
        movwf   state           ;save state
        bcf     flags,initID    ;
        bcf     flags,sentID    ;
GDHang
        movlw   EECONF          ;get address of configuration byte
        call    ReadEE          ;read EEPROM
        movwf   cfgFlag         ;store w into config flag copy

        movlw   EEHANG          ;get address of hang timer preset value
        call    ReadEE          ;read EEPROM
        movwf   hangDly         ;store w into hang time delay preset

        movlw   EETOUT          ;get address of timeout timer preset value
        call    ReadEE          ;read EEPROM
        movwf   tOutDly         ;store w into timeout delay preset

        movlw   EEID            ;get address of ID timer preset value
        call    ReadEE          ;read EEPROM
        movwf   idDly           ;store w into id timer delay preset

        movlw   EETMSG          ;get address of tail message counter preset
        call    ReadEE          ;read EEPROM
        movwf   tMsgCtr         ;store w into tail message counter
        return

PlayMsg
        btfss   msgNum,4        ;is bit 4 clear?
        goto    StartCW         ;yes, it's a CW message
        btfsc   cfgFlag,SIMPLEX ;in simplex mode?
        goto    MsgCWID         ;no recorded messages, only CWID
        btfss   cfgFlag,NOISD   ;is the ISD absent?
        goto    ISDPlay         ;no, play audio message
        bcf     msgNum,4        ;convert ISD message to CW message
        btfss   msgNum,1        ;is it not an ID
        goto    MsgCWID         ;it is an id message
        btfsc   msgNum,0        ;skip if timout message
        return                  ;don't even try to play tail message
        bsf     msgNum,0        ;set the bits to make Timeout Message
        bcf     msgNum,1        ;set the bits to make Timeout Message
        goto    StartCW         ;play the CW timeout message

MsgCWID 
        bcf     msgNum,0        ;make it message # 0
;
; Start sending a CW message
;
StartCW
        movlw   b'00000011'     ;mask out illegal values
        andwf   msgNum,f        ;mask it...
        call    GetCwMsg        ;lookup message
                                ;message offset is now in W
        movwf   cwBuff          ;save offset
        call    ReadEE          ;read byte from EEPROM
        movwf   cwByte          ;save byte in CW bitmap
        movlw   CWIWSP          ;get startup delay
        movwf   cwTmr           ;preset cw timer
        bcf     flags,beepOn    ;make sure that beep is off
        bsf     flags,cwOn      ;turn on CW sender
        bsf     PORTB,ptt       ;turn on PTT...
        return

;
;Play message from ISD1240; message address in msgNum
;
ISDPlay
        bcf     PORTB,isdA0     ;reset message address bits
        bcf     PORTB,isdA1     
        btfsc   msgNum,0        ;check bit 0
        bsf     PORTB,isdA0
        btfsc   msgNum,1        ;check bit 1
        bsf     PORTB,isdA1

        btfss   msgNum,ISDSIM   ;check bit 2
        goto    PNorm           ;not set
        movf    isdRTmr,f       ;check to see if this is 0
        btfsc   STATUS,Z        ;is it zero?
        return                  ;yes, bail out.

        incf    isdRTmr,w       ;check to see if it is 255
        btfsc   STATUS,Z        ;is it now zero?
        return                  ;yes, bail out.

        decf    isdRTmr,w       ;get message duration - 100 ms
        movwf   isdTmr          ;save into timer
        goto    PNow            ;play the message 

PNorm
        movf    msgNum,w        ;get message number
        andlw   b'00000011'     ;mask out bits 2-7
        addlw   EEM0LEN         ;add the base of the message lengths
        movwf   EEADR           ;save address
        call    ReadEE          ;read EEPROM, w will have message length after
        movwf   isdTmr          ;preset message timer
        btfsc   STATUS,Z        ;is the length 0
        return                  ;yes, don't play.
        bsf     PORTB,ptt       ;turn transmitter on
        
PNow
        bsf     PORTB,isdPlay   ;start ISD1240 playback
        return

;
;Record Message into ISD1240; message address in msgNum
;
ISDRec
        bcf     PORTB,isdA0     ;reset message address bits
        bcf     PORTB,isdA1     
        btfsc   msgNum,0        ;check bit 0
        bsf     PORTB,isdA0
        btfsc   msgNum,1        ;check bit 1
        bsf     PORTB,isdA1
        bsf     msgNum,MSGREC   ;set message record bit        
        return

;
; Read EEPROM byte
; address is supplied in W on call, data is returned in w
;
ReadEE
        movwf   EEADR           ;EEADR = w
        bsf     STATUS,RP0      ;select bank 1
        bsf     EECON1,RD       ;read EEPROM
        bcf     STATUS,RP0      ;select bank 0
        movf    EEDATA,w        ;get EEDATA into w
        return

;
; clear tone buffer and reset good digit counters
;

ClrTone
        movlw   TONES           ;no... get number of command tones into w
        movwf   toneCnt         ;preset number of command tones
        clrf    cmdCnt          ;clear number of command bytes...
        clrf    tBuf1           ;clear command buffer bytes
        clrf    tBuf2
        clrf    tBuf3
        return

;
; Program EEPROM byte
;
EEProg
        bsf     STATUS,RP0      ;select bank 1
        bcf     INTCON,GIE      ;disable interrupts
        bsf     EECON1,WREN     ;enable EEPROM write
        movlw   h'55'
        movwf   EECON2          ;write 55
        movlw   h'AA'
        movwf   EECON2          ;write AA
        bsf     EECON1,WR       ;start write
        bcf     EECON1,WREN     ;disable write
EEPLoop
        nop
        btfsc   EECON1,WR       ;is write cycle complete?
        goto    EEPLoop         ;wait for write to finish

        bsf     INTCON,GIE      ;enable interrupts
        bcf     STATUS,RP0      ;select bank 0
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
        dw      'B'
        dw      '.'
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
        dw      'C'
        dw      'O'
        dw      'M'
        dw      'M'
        dw      'E'
        dw      'R'
        dw      'C'
        dw      'I'
        dw      'A'
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
        dw      ' '
        dw      'B'
        dw      'Y'
        dw      ' '
        dw      'T'
        dw      'H'
        dw      'E'
        dw      ' '
        dw      'A'
        dw      'U'
        dw      'T'
        dw      'H'
        dw      'O'
        dw      'R'
        dw      '.'

        org     0380h
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

;
; Lookup values to load EEPROM addresses with at initialize time 
; if EEADR > EEIEND, return 0.
;
InitDat

        movf    EEADR,w         ;get current address
        sublw   EEIEND          ;EEIEND - EEADR -> w
        btfss   STATUS,C        ;C is clear if result is negative
        retlw   0               ;zero this location       

        movlw   h'03'           ;this subroutine is in the top 256 bytes
        movwf   PCLATH          ;ensure that computed goto will stay in range
        movf    EEADR,w         ;get EEPROM address into w
        addwf   PCL,f           ;add w to PCL
        retlw   h'01'           ;00 -- enable flag
        retlw   h'00'           ;01 -- configuration flag
        retlw   h'32'           ;02 -- hang timer preset, in tenths
        retlw   h'1e'           ;03 -- timeout timer preset, in 1 seconds
        retlw   h'36'           ;04 -- id timer preset, in 10 seconds
        retlw   h'00'           ;05 -- tail message count
        retlw   h'0f'           ;06 -- 'O'      1
        retlw   h'0d'           ;07 -- 'K'      2
        retlw   h'ff'           ;08 -- EOM      3
        retlw   h'05'           ;09 -- 'N'      1
        retlw   h'0b'           ;0a -- 'G'      2
        retlw   h'ff'           ;0b -- EOM      3
        retlw   h'03'           ;0c -- 'T'      1
        retlw   h'0f'           ;0d -- 'O'      2
        retlw   h'ff'           ;0e -- EOM      3
        retlw   h'09'           ;0f -- 'D'      1
        retlw   h'02'           ;10 -- 'E'      2
        retlw   h'00'           ;11 -- space    3
        retlw   h'05'           ;12 -- 'N'      4
        retlw   h'10'           ;13 -- 'H'      5
        retlw   h'0a'           ;14 -- 'R'      6
        retlw   h'15'           ;15 -- 'C'      7
        retlw   h'29'           ;16 -- '/'      8
        retlw   h'3c'           ;17 -- '2'      9
        retlw   h'ff'           ;18 -- EOM     10
        retlw   h'ff'           ;19 -- EOM     11
        retlw   h'ff'           ;1a -- EOM     12  can fit 6 letter id....
        
        page
        org     03E4h           ;set this subroutine in last bit of memory

;
; Lookup EEPROM address of CW message based on index of message
;
GetCwMsg
        movlw   h'03'           ;this subroutine is in the top 256 bytes
        movwf   PCLATH          ;ensure that computed goto will stay in range
        movf    msgNum,w        ;get msgNum into w
        addwf   PCL,f           ;add w to PCL
        retlw   EECWID          ;0 = ID message
        retlw   EECWTO          ;1 = 1 timeout message
        retlw   EECWOK          ;2 = 2 ok message
        retlw   EECWNG          ;3 = 3 ng message

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
        movlw   h'03'           ;this subroutine is in the top 256 bytes
        movwf   PCLATH          ;ensure that computed goto will stay in range
        movf    tone,w          ;get tone into w
        addwf   PCL,f           ;add w to PCL
        retlw   0d              ;0 = D key 
        retlw   01              ;1 = 1 key
        retlw   02              ;2 = 2 key
        retlw   03              ;3 = 3 key
        retlw   04              ;4 = 4 key
        retlw   05              ;5 = 5 key
        retlw   06              ;6 = 6 key
        retlw   07              ;7 = 7 key
        retlw   08              ;8 = 8 key
        retlw   09              ;9 = 9 key
        retlw   00              ;A = 0 key
        retlw   0e              ;B = * key (e)
        retlw   0f              ;C = # key (f)
        retlw   0a              ;D = A key
        retlw   0b              ;E = B key
        retlw   0c              ;F = C key

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
