        ;; NHRC-3.1 Repeater Controller.
        ;; Copyright 1996 - 2010 NHRC LLC,
        ;; as an unpublished proprietry work.
        ;; All rights reserved.
        ;; No part of this document may be used or reproduced by any means,
        ;; for any purpose, without the expressed written consent of NHRC LLC.

        ;; V 0.01 15 March 2009 Initial port from NHRC-3 Plus code
        ;; V 0.02 02 January 2010 ISD is working!
        ;; V 0.03 04 January 2010 simplex working, sort of, serial enabled.
        ;; V 0.11 28 September 2010 8 message expansion.
        ;; V 0.20 21 November 2010 two tail messages
        ;; V 0.90 24 November 2010 functionally complete (I think)
        ;; V 0.92 05 January 2011 5 saved setups, turn off failsafe clock
        ;; v 0.93 06 January 2011 simplex message works with timeout timer.
        ;;                        erase simplex msg on state change to simplex
        ;;                        CTCSS control op mode works right now.
        ;; v 0.94 07 January 2011 simplex message length fixed
        ;; v 0.95 08 January 2011 simplex message in slots 5-9, 90 sec max
        ;; v 0.96 09 January 2011 normal IDs toggle correctly
        ;; v 0.97 09 January 2011 euro ID mode end speech ID works now.
        ;; v 0.98 11 January 2011 reprogram unlock code.
        ;; v 0.99 11 January 2011 digital outputs port 5 bits 0 and 1
        ;; v 1.00 02 June 2011 bump version to 1.00
        ;; v 1.01 15 July 2011 version 1.01 NHRC-2.1 support
        ;; v 1.02 07 May 2011 Version 1.02 NHRC-2.1 fixes

        ;; NOTE: when updating the version, search this file for
        ;; CW version data
        
VERS1   equ     h'3e'           ; 1
VERS2   equ     h'3f'           ; 0
VERS3   equ     h'3c'           ; 2
                        
LOAD_EE=1
;NHRC3_1=1               ; set in NHRC-3.1 build Project->Build Options->Project->MPASM Macro Definitions

        ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

        IFDEF __16F886
        include "p16f886.inc"

        IFDEF __MPLAB_DEBUGGER_ICD2
        __CONFIG _CONFIG1, _PWRTE_ON & _FCMEN_OFF & _XT_OSC & _LVP_OFF & _CP_OFF & _WDT_OFF
        ELSE
        __CONFIG _CONFIG1, _PWRTE_ON & _FCMEN_OFF & _XT_OSC & _LVP_OFF & _CP_ON
        ENDIF                   ; __MPLAB_DEBUGGER_ICD2
        ELSE
        ERROR THIS PROCESSOR IS NOT SUPPORTED
        ENDIF                   ; __16F886
        
        include "eeprom.inc"

;macro definitions for ROM paging.
        
PAGE0   macro                   ; select page 0
        bcf     PCLATH,3
        bcf     PCLATH,4
        endm

PAGE1   macro                   ; select page 1
        bsf     PCLATH,3
        bcf     PCLATH,4
        endm

PAGE2   macro                   ; select page 2
        bcf     PCLATH,3
        bsf     PCLATH,4
        endm

PAGE3   macro                   ; select page 3
        bsf     PCLATH,3
        bsf     PCLATH,4
        endm

        IFDEF DEBUG
TEN     equ     D'4'            ; decade counter.
        ELSE
TEN     equ     D'10'           ; decade counter.
        ENDIF

        
        ;; ISD command queue commands
        ;; bit 7 6 5 4 3 2 1 0
        ;;     0 0 c c c c c c send command c:
        ;;     0 1 m m m m m m play message    m
        ;;     1 0 m m m m m m erase message   m
        ;;     1 1 m m m m m m record message  m
        ;;
        ;;  commands are:
        ;;     c = 0 0 0 0 0 0  = 0 invalid!
        ;;     c = 0 0 0 0 0 1  = 1 STOP
        ;;     c = 0 0 0 0 1 0  = 2 RESET
        ;;     c = 0 0 0 0 1 1  = 3 CLR_INT (will I need this from here?)
        ;;     c = 0 0 0 1 0 0  = 4 RD_STATUS
        ;;     c = 0 0 0 1 0 1  = 5 DEVID read
        ;;     c = 0 0 0 1 1 0  = 6 G_ERASE
        ;;     c = 0 0 0 1 1 1  = 7 WR_APC2 (set APC)
        ;;     c = 0 0 1 0 0 0  = 8 PU
        ;;     c = 1 d d d d d  = delay d (0-31) * 10 ms before next operation

IDLY50  equ     b'00100101'     ; delay 5  =  50 ms
IDLY60  equ     b'00100110'     ; delay 6  =  60 ms
IDLY100 equ     b'00101010'     ; delay 10 = 100 ms
IDLY200 equ     b'00110100'     ; delay 20 = 200 ms
IDLY250 equ     b'00111001'     ; delay 25 = 250 ms
ICMDPL  equ     b'01000000'     ; is mask, or in message number
ICMDREC equ     b'11000000'     ; is mask
ICMDDEL equ     b'10000000'     ; is mask
ICMDBAD equ     b'00000000'     ; invalid! bad!
ICMDST  equ     b'00000001'     ; stop
ICMDRST equ     b'00000010'     ; reset
ICMDCLI equ     b'00000011'     ; clear interrupt
ICMDRDS equ     b'00000100'     ; read status
ICMDDID equ     b'00000101'     ; read devid
ICMDGER equ     b'00000110'     ; G_erase
ICMDWAP equ     b'00000111'     ; write APC2 
ICMDPU  equ     b'00001000'     ; power up
        
        ;; ISD commands, reversed bit patterns
        ;; LED sets bit4, reversed is bit3
ISDPU   equ     b'10000000'     ; PU        - 0x01 - 2 byte command
ISDSTOP equ     b'01000000'     ; STOP      - 0x02 - 2 byte command -- int
ISDRST  equ     b'11000000'     ; RESET     - 0x03 - 2 byte command
ISDCINT equ     b'00100000'     ; CLR_INT   - 0x04 - 2 byte command
ISDSTS  equ     b'10100000'     ; RD_STATUS - 0x05 - 2 byte command
ISDPD   equ     b'11100000'     ; PD        - 0x07 - 2 byte command
ISDDID  equ     b'10010000'     ; DEVID     - 0x09 - 3 byte command
ISDGER  equ     b'11001010'     ; G_ERASE   - 0x43 - 2 byte command -- int
ISDWAPC equ     b'10100110'     ; WR_APC2   - 0x65 - 3 byte command
ISDPLAY equ     b'00001001'     ; SET PLAY  - 0x80 - 7 byte command -- int
ISDREC  equ     b'10001001'     ; SET REC   - 0x81 - 7 byte command -- int
ISDERAS equ     b'01001001'     ; SET ERASE - 0x82 - 7 byte command -- int

        ;; APC values configured for max volume
        ;; record from analog in
        ;; analog in always passed
        ;; analog output in AUX mode (voltage output)
        ;; pwm speaker disabled
        ;; analog output powered up
        ;; vAlert disabled
        ;; EOM stops playback
xPC07   equ     b'00010101'     ; APC register bits 0-7
APC07   equ     b'00011111'     ; APC register bits 0-7
        ;;        1xxxxxxx      ; D0 VOL0
        ;;        x1xxxxxx      ; D1 VOL1  -- max is 000
        ;;        xx1xxxxx      ; D2 VOL2 
        ;;        xxx1xxxx      ; D3 monitor during recording
        ;;        xxxx1xxx      ; D4 mix mic input 
        ;;        xxxxx1xx      ; D5 sound effects disable
        ;;        xxxxxx1x      ; D6 feed through disable
        ;;        xxxxxxx1      ; D7 analog outupt AUX mode
APC811  equ     b'10110000'     ; APC register bits 8-11 and 4 fill 0s
        ;;        1xxxxxxx      ; PWM Speaker power down
        ;;        x1xxxxxx      ; analog output power down
        ;;        xx1xxxxx      ; vAlert disable 
        ;;        xxx1xxxx      ; EOM stops playback enable

; *************************
; ** IO Port Assignments **
; *************************

; PORTA
DTMFQ1  equ     0               ; input, DTMF decoder Q1
DTMFQ2  equ     1               ; input, DTMF decoder Q2
DTMFQ3  equ     2               ; input, DTMF decoder Q3
DTMFQ4  equ     3               ; input, DTMF decoder Q4
RX0AUD  equ     4               ; output, audio mute, muted when high.
INIT    equ     4               ; output, audio mute, muted when high.
DTMF_DV equ     5               ; input, DTMF digit valid when high.

; PORTB
FANCTL  equ     0               ; output, fan control/digital output.
RX0COR  equ     1               ; input, COR
ISDSEL  equ     2               ; output, ISD Slave Select not.
ISDINT  equ     3               ; input, ISD interrupt.
CTSEL1  equ     4               ; input, courtesy tone selection.
CTSEL2  equ     5               ; input, courtesy tone selection.
ALARMIN equ     5               ; alarm input bit
OUT1    equ     6               ; digital output 1.
OUT2    equ     7               ; digital output 2.

; PORTC
TX0PTT  equ     0               ; output, PTT when high.
BEEP    equ     1               ; PWM output, beep tone source.
RX0PL   equ     2               ; input, CTCSS present when low.
;       equ     3               ; SPI clock
;       equ     4               ; MISO
;       equ     5               ; MOSI
;       equ     6               ; serial TX
;       equ     7               ; serial RX


; *******************
; ** Control Flags **
; *******************
        
;tFlags                         ; timer flags  
TICK    equ     0               ; TICK indicator
ONEMS   equ     1               ; 1 ms tick flag
TENMS   equ     2               ; 10 ms tick flag
HUNDMS  equ     3               ; 100 ms tick flag
ONESEC  equ     4               ; 1 second tick flag
TENSEC  equ     5               ; 10 second flag...
; niy   equ     6               ; NIY
CWBEEP  equ     7               ; cw beep is on.
        
;flags
initID  equ     0               ; need to ID now
needID  equ     1               ; need to send ID
IDNOW   equ     2               ; ID is running now.
TXONFLG equ     3               ; last TX state flag
CMD_NIB equ     4               ; command interpreter nibble flag for copy
DEF_CT  equ     5               ; deferred courtesy tone.
DEF_ID  equ     6               ; deferred ID message.
LAST_DV equ     7               ; last DTMF digit valid.

;mscFlag                        ; misc flags...
DT0ZERO equ     0               ; dtmf-0 last received 0
; NIY   equ     1               ; NIY
LITZDT0 equ     2               ; LiTZ on DTMF-0
IDTOGL  equ     3               ; ID2 flag.  used to alternate ID messages.
TAIL2F  equ     4               ; tail 2 flag1. used to alternate tail messages.
ALARMED equ     5               ; alarmed!
CTCSS0  equ     6               ; last CTCSS on main receiver
SC_RDY  equ     7               ; serial command is ready.

; txFlag
RX0OPEN equ     0               ; main receiver repeating
; NIY   equ     1               ; NIY
TXHANG  equ     2               ; hang time
; NIY   equ     3               ; NIY
; NIY   equ     4               ; NIY
TALKING equ     5               ; ISD playing back
BEEPING equ     6               ; beep tone active
CWPLAY  equ     7               ; CW playing


CWTBDLY equ     d'60'           ; CW timebase delay for 20 WPM.

; isdFlag
ISDRUNF equ     0               ; isd running flag
ISDRECF equ     1               ; isd recording flag.
ISDRECR equ     2               ; isd record flag. record next keyup.
ISDERS  equ     3               ; isd is erasing
ISDTEST equ     5               ; isd test mode
ISDZAPS equ     6               ; delete simplex message flag.
ISDRECE equ     7               ; isd record ERROR: message overflow

;; ismpcf -- ISD state machine processor control flag
ISMWAIT equ     0               ; wait for isdtmr countdown 
ISMWINT equ     1               ; wait for ISD interrupt
ISMERAS equ     7               ; erase cannot be interrupted!
        
;; COR debounce time
COR1DEB equ     5               ; 5 ms.  COR off to on debounce time
COR0DEB equ     5               ; 5 ms.  COR on to off debounce time
COR0DBS equ     50              ; 50 ms. COR on to off debounce time, simplex
DLY1DEB equ     d'100'          ; 100 ms. COR off->on debounce time, with DAD.
DLY0DEB equ     d'50'           ; 50 ms.  COR on->off debounce time, with DAD.
CHNKDEB equ     d'250'          ; 250 ms.

IDSOON  equ     D'6'            ; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ     D'20'           ; DTMF muting timer = 2.0 sec.
DTMFDLY equ     d'50'           ; DTMF activity timer = 5.0 sec.
LITZTIM equ     d'20'           ; 5.0-3.0=2.0 time left on DTMF timer for LITZ
UNLKDLY equ     d'120'          ; unlocked mode timer.
        
; dtRFlag -- dtmf sequence received indicator
DT0RDY  equ     0               ; some sequence received on DTMF-0
DT1RDY  equ     1               ; some sequence received on DTMF-1
DT2RDY  equ     2               ; some sequence received on DTMF-2
DTUL    equ     3               ; command received from unlocked port.
DTSEVAL equ     4               ; dtmf command evaluation in progress.
DT0UNLK equ     5               ; unlocked indicator
DT1UNLK equ     6               ; unlocked indicator
DT2UNLK equ     7               ; unlocked indicator
                ;; 
;dtEFlag -- DTMF command evaluator control flag.
        ;; low order 5 bits indicate next prefix number/user command to scan
DT0CMD  equ     5               ; received this command from dtmf0
DT1CMD  equ     6               ; received this command from dtmf1
DT2CMD  equ     7               ; received this command from dtmf2

; beepCtl -- beeper control flags...
B_ADR0  equ     0               ; beep or CW addressing mode indicator
B_ADR1  equ     1               ; beep or CW addressing mode indicator
                                ;   00 EEPROM
                                ;   01 lookup table index, built in messages.
                                ;   10 Raw RAM address
                                ;   11 Direct from DTMF buffer.
                                ; 
B_BEEP  equ     2               ; beep sequence in progress
B_CW    equ     3               ; CW transmission in progress
;NIY    equ     4               ; 
;NIY    equ     5               ; 
B_LAST  equ     6               ; last segment of CT tones.
;NIY    equ     7               ; 

; beepCtl preset masks
BEEP_CT equ     b'10000100'     ; CT from EEPROM
BEEP_CX equ     b'10000101'     ; CT from ROM table
CW_ROM  equ     b'10001001'     ; CW from ROM table
CW_EE   equ     b'10001000'     ; CW from EEPROM

CTPAUSE equ     d'5'            ; 50 msec pause before CT.

PULS_TM equ     d'50'           ; 50 x 10 ms = 500 ms.  pulse duration time.
        
; receiver states
RXSOFF  equ     0
RXSON   equ     1
RXSTMO  equ     2
RXSREC  equ     3               ; record with rptr disabled. new for 1.04
RXSOFON equ     4               ; receiver is active but repeater disabled,
                                ; new feature for 1.12
         
; cTone Courtesy tone selections
CTNONE  equ     h'ff'           ; no courtesy tone.
CT0     equ     0               ; normal courtesy tone
CT1     equ     1               ; 
CT2     equ     2               ; 
CT3     equ     3               ; 
CTSP1   equ     4               ; 
CTSP2   equ     5               ; unused courtesy tone
CTSP3   equ     6               ; unused courtesy tone
CTUNLOK equ     7               ; unlocked courtesy tone

; Voice message numbers.
	IFDEF NHRC3_1
VINITID equ     0               ; initial ID.
VNORMID equ     1               ; normal ID.
VNORMI2 equ     2               ; normal ID.
VTIMOUT equ     3               ; timeout message.
VTAIL   equ     4               ; tail message.
VCTONE  equ     4               ; courtesy tone message.
VTAIL2  equ     5               ; tail message.
VALARM  equ     6               ; alarm track
VTEST   equ     7               ; test track
VSIMPLX equ     5               ; simplex message is 5-7 (~90 sec)
VLAST   equ     7               ; last valid message number
	ELSE
VINITID equ     0               ; initial ID.
VNORMID equ     1               ; normal ID.
VTIMOUT equ     2               ; timeout message.
VTAIL   equ     3               ; tail message.
VCTONE  equ     3               ; courtesy tone message.
VSIMPLX equ     1               ; simplex message is 1-3 (~30 sec)
VLAST   equ     3               ; last valid message number
	ENDIF

; 
; CW Message indexes into table at MesgTabl
;
CW_OK   equ     h'00'           ; CW: OK
CW_ERR  equ     h'03'           ; CW: ERR
CW_TO   equ     h'07'           ; CW: TO
CW_ON   equ     h'0a'           ; CW: ON
CW_OFF  equ     h'0d'           ; CW: OFF
CWHELLO equ     h'11'           ; CW: powerup message.
        
;
; CW sender constants
;
CWDIT   equ     1               ; dit length in 100 ms
CWDAH   equ     CWDIT * 3       ; dah 
CWIESP  equ     CWDIT           ; inter-element space
CWILSP  equ     CWDAH           ; inter-letter space
CWIWSP  equ     CWDIT * 7       ; inter-word space

T0PRE   equ     D'37'           ; timer 0 preset for overflow in 224 counts.

;
; Serial control constants
;
SCATTN  equ     h'3a'           ; attention character, :
        
SCREAD  equ     h'52'           ; read command R
SCWRITE equ     h'57'           ; write command W
SCTERM  equ     h'0d'           ; command terminator <CR>
SCACK   equ     h'4b'           ; ACK message K
SCNAK   equ     h'4e'           ; NAK message N
SCCR    equ     h'0d'           ; CR
SCLF    equ     h'0a'           ; LF


; ***************
; ** VARIABLES **
; ***************
        cblock  h'20'           ; 1st block of RAM at 20h-7fh (96 bytes here)
        ;; interrupt pseudo-stack to save context during interrupt processing.
        s_copy                  ; 20 saved STATUS
        p_copy                  ; 21 saved PCLATH
        f_copy                  ; 22 saved FSR
        i_temp                  ; 23 temp for interrupt handler
        ;; internal timing generation
        tFlags                  ; 24 Timer Flags
        oneMsC                  ; 25 one millisecond counter
        tenMsC                  ; 26 ten milliseconds counter
        hundMsC                 ; 26 hundred milliseconds counter
        thouMsC                 ; 28 thousand milliseconds counter (1 sec)

        temp                    ; 29 working storage. don't use in int handler.
        temp2                   ; 2a more working storage
        temp3                   ; 2b still more temporary storage
        temp4                   ; 2c yet still more temporary storage
        temp5                   ; 2d temporary storage...
        temp6                   ; 2e temporary storage...
        cmdSize                 ; 2f # digits received for current command
        ;; operating flags
        flags                   ; 30 operating Flags
        mscFlag                 ; 31 misc. flags.
        txFlag                  ; 32 Transmitter control flag
        rxFlag                  ; 33 Receiver COS valid flags
        isdFlag                 ; 34 ISD control flag.
        ;; beep generator control 
        beepTmr                 ; 35 timer for generating various beeps
        beepAddr                ; 36 address for various beepings, low byte.
        beepCtl                 ; 37 beeping control flag
        ;; debounce timers
        rx0Dbc                  ; 38 main receiver debounce timer
        ;; receiver states
        rx0Stat                 ; 39 main receiver state
        ;; timers
        rx0TOut                 ; 3a main receiver timeout timer, in seconds
        idTmr                   ; 3b id timer, in 10 seconds
        hangTmr                 ; 3c hang timer, in tenths.
        muteTmr                 ; 3d DTMF muting timer, in tenths.
        lMutTmr                 ; 3e link muting timer, in tenths.
        dtATmr                  ; 3f dtmf access timer
        fanTmr                  ; 40 fan timer
        tailCtr                 ; 41 tail message counter.
        unlkTmr                 ; 42 unlocked mode timer.
        pulsTmr                 ; 43 pulse timer.
        ;; timer presets
        hangDly                 ; 44 hang timer preset, keep it handy.
        ;; CW generator data
        cwTmr                   ; 45 CW element timer
        cwByte                  ; 46 CW current byte (bitmap)
        cwTbTmr                 ; 47 CW timebase timer
        cwTone                  ; 48 CW tone
        cwSpeed                 ; 49 CW Speed
        
        cTone                   ; 4a courtesy tone to play

        eeAddr                  ; 4b EEPROM address (low byte) to read/write
        eeCount                 ; 4c number of bytes to read/write from EEPROM
        ;; control operator control flag groups
        group0                  ; 4d group 0 flags
        group1                  ; 4e group 1 flags
        group2                  ; 4f group 2 flags
        group3                  ; 50 group 3 flags
        group4                  ; 51 group 4 flags
        group5                  ; 52 group 5 flags
        group6                  ; 53 group 6 flags
        group7                  ; 54 group 7 flags
        ;; ISD control variables
        isdDly                  ; 55 isd command delay timer...
        isdMsg                  ; 56 isd message number...
        isdRMsg                 ; 57 isd RECORD message number...
        sr0lo                   ; 58 isd SR0 register lo byte
        sr0hi                   ; 59 isd SR0 register hi byte
        sr1lo                   ; 5a isd SR1 register lo byte
        isdDvId                 ; 5b isd device ID
        isdS1                   ; 5c isd start address first byte
        isdS2                   ; 5d isd start address 2nd byte
        isdE1                   ; 5e isd end address 1st byte
        isdE2                   ; 5f isd end address 2nd byte
        isdCmd                  ; 60 isd command byte
        ismpcf                  ; 61 isd state machine process control flags
        alrmTmr                 ; 62 alarm announce timer.

        ;; last var at 0x6f there are 14 left in this block...
        
        endc                    ; this block ends at 6f

        cblock  h'70'           ; from 70 to 7f is common to all banks!
        rICD70                  ; 70 reserved for ICD2
        w_copy                  ; 71 saved W register for interrupt handler
        dt0Ptr                  ; 72 DTMF-0 buffer pointer
        dt0Tmr                  ; 73 DTMF-0 buffer timer
        dtRFlag                 ; 74 DTMF receive flag...
        dtEFlag                 ; 75 DTMF command interpreter control flag
        eebPtr                  ; 76 eebuf write pointer.
        scratch                 ; 77 scratchpad. (not currently used.)
        txHead                  ; 78 serial transmitter buffer head.
        txTail                  ; 79 serial transmitter buffer tail.
        rxHead                  ; 7a serial receiver buffer head.
        rxTail                  ; 7b serial receiver buffer tail.
        isdcbh                  ; 7c isd command buffer head
        isdcbt                  ; 7c isd command buffer tail
        endc                    ; 1st RAM block ends at 7f

        cblock  h'a0'           ; 2nd block of RAM at a0h-efh (80 bytes here)
        ;; 32 bytes serial transmit buffer
        txBuf00                 ; a0
        txBuf01                 ; a1
        txBuf02                 ; a2
        txBuf03                 ; a3
        txBuf04                 ; a4
        txBuf05                 ; a5
        txBuf06                 ; a6
        txBuf07                 ; a7
        txBuf08                 ; a8
        txBuf09                 ; a9
        txBuf0a                 ; aa
        txBuf0b                 ; ab
        txBuf0c                 ; ac
        txBuf0d                 ; ad
        txBuf0e                 ; ae
        txBuf0f                 ; af
        txBuf10                 ; b0
        txBuf11                 ; b1
        txBuf12                 ; b2
        txBuf13                 ; b3
        txBuf14                 ; b4
        txBuf15                 ; b5
        txBuf16                 ; b6
        txBuf17                 ; b7
        txBuf18                 ; b8
        txBuf19                 ; b9
        txBuf1a                 ; ba
        txBuf1b                 ; bb
        txBuf1c                 ; bc
        txBuf1d                 ; bd
        txBuf1e                 ; be
        txBuf1f                 ; bf
        ;; 32 bytes serial receive buffer
        rxBuf00                 ; c0
        rxBuf01                 ; c1
        rxBuf02                 ; c2
        rxBuf03                 ; c3
        rxBuf04                 ; c4
        rxBuf05                 ; c5
        rxBuf06                 ; c6
        rxBuf07                 ; c7
        rxBuf08                 ; c8
        rxBuf09                 ; c9
        rxBuf0a                 ; ca
        rxBuf0b                 ; cb
        rxBuf0c                 ; cc
        rxBuf0d                 ; cd
        rxBuf0e                 ; ce
        rxBuf0f                 ; cf
        rxBuf10                 ; d0
        rxBuf11                 ; d1
        rxBuf12                 ; d2
        rxBuf13                 ; d3
        rxBuf14                 ; d4
        rxBuf15                 ; d5
        rxBuf16                 ; d6
        rxBuf17                 ; d7
        rxBuf18                 ; d8
        rxBuf19                 ; d9
        rxBuf1a                 ; da
        rxBuf1b                 ; db
        rxBuf1c                 ; dc
        rxBuf1d                 ; dd
        rxBuf1e                 ; de
        rxBuf1f                 ; df
        ;; 8 bytes isd commands queue
        isdcb00                 ; e0
        isdcb01                 ; e1
        isdcb02                 ; e2
        isdcb03                 ; e3
        isdcb04                 ; e4
        isdcb05                 ; e5
        isdcb06                 ; e6
        isdcb07                 ; e7
        endc
        
        cblock  h'f0'           ; this is really common with 70-7f
        rsvdf0                  ; f0  reserve these 16 bytes
        rsvdf1                  ; f1  reserve these 16 bytes
        rsvdf2                  ; f2  reserve these 16 bytes
        rsvdf3                  ; f3  reserve these 16 bytes
        rsvdf4                  ; f4  reserve these 16 bytes
        rsvdf5                  ; f5  reserve these 16 bytes
        rsvdf6                  ; f6  reserve these 16 bytes
        rsvdf7                  ; f7  reserve these 16 bytes
        rsvdf8                  ; f8  reserve these 16 bytes
        rsvdf9                  ; f9  reserve these 16 bytes
        rsvdfa                  ; fa  reserve these 16 bytes
        rsvdfb                  ; fb  reserve these 16 bytes
        rsvdfc                  ; fc  reserve these 16 bytes
        rsvdfd                  ; fd  reserve these 16 bytes
        rsvdfe                  ; fe  reserve these 16 bytes
        rsvdff                  ; ff  reserve these 16 bytes
        endc                    ; 2nd RAM block ends at ff

        ;; 16c77 ram blocks continue...
        cblock  h'110'          ; 16 bytes at 110h-11fh
        endc
        
        cblock  h'120'          ; 80 bytes 120h-16fh
        dt0buf0                 ; DTMF-0 receiver buffer (16 bytes) @ 120
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

        cblock  h'130'          ; eeprom write buffer (16 bytes) @ 130
        eebuf00                 ; eeprom write buffer (16 bytes) @ 130
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
        endc

        cblock  h'165'          ; reserved for ICD2
        rICD165                 ; reserved for ICD2
        rICD166                 ; reserved for ICD2
        rICD167                 ; reserved for ICD2
        rICD168                 ; reserved for ICD2
        rICD169                 ; reserved for ICD2
        rICD16a                 ; reserved for ICD2
        rICD16b                 ; reserved for ICD2
        rICD16c                 ; reserved for ICD2
        rICD16d                 ; reserved for ICD2
        rICD16e                 ; reserved for ICD2
        rICD16f                 ; reserved for ICD2
        endc
        
        cblock  h'170'          ; this is common with 70-7f
        rsvd170                 ; reserve these 16 bytes
        rsvd171                 ; reserve these 16 bytes
        rsvd172                 ; reserve these 16 bytes
        rsvd173                 ; reserve these 16 bytes
        rsvd174                 ; reserve these 16 bytes
        rsvd175                 ; reserve these 16 bytes
        rsvd176                 ; reserve these 16 bytes
        rsvd177                 ; reserve these 16 bytes
        rsvd178                 ; reserve these 16 bytes
        rsvd179                 ; reserve these 16 bytes
        rsvd17a                 ; reserve these 16 bytes
        rsvd17b                 ; reserve these 16 bytes
        rsvd17c                 ; reserve these 16 bytes
        rsvd17d                 ; reserve these 16 bytes
        rsvd17e                 ; reserve these 16 bytes
        rsvd17f                 ; reserve these 16 bytes
        endc                    ; 3nd RAM block ends at 17f
        
        ;; cblock       h'190'  ; 16 bytes at 190h-19fh
        ;; endc
        cblock  h'1a0'          ; 80 bytes 1a0h-1efh
        cmdbf00                 ; command buffer  @1a0
        cmdbf01                 ; command buffer
        cmdbf02                 ; command buffer
        cmdbf03                 ; command buffer
        cmdbf04                 ; command buffer
        cmdbf05                 ; command buffer
        cmdbf06                 ; command buffer
        cmdbf07                 ; command buffer
        cmdbf08                 ; command buffer
        cmdbf09                 ; command buffer
        cmdbf0a                 ; command buffer
        cmdbf0b                 ; command buffer
        cmdbf0c                 ; command buffer
        cmdbf0d                 ; command buffer
        cmdbf0e                 ; command buffer
        cmdbf0f                 ; command buffer  @1af (16 bytes)
        cmdbf10                 ; command buffer  @1b0
        cmdbf11                 ; command buffer
        cmdbf12                 ; command buffer
        cmdbf13                 ; command buffer
        cmdbf14                 ; command buffer
        cmdbf15                 ; command buffer
        cmdbf16                 ; command buffer
        cmdbf17                 ; command buffer
        cmdbf18                 ; command buffer
        cmdbf19                 ; command buffer
        cmdbf1a                 ; command buffer
        cmdbf1b                 ; command buffer
        cmdbf1c                 ; command buffer
        cmdbf1d                 ; command buffer
        cmdbf1e                 ; command buffer
        cmdbf1f                 ; command buffer @1bf (32 bytes)
        endc                    ; end of block @ 1bf


        cblock  h'1f0'          ; this is common with 70-7f
        rsvd1f0                 ; reserve these 16 bytes
        rsvd1f1                 ; reserve these 16 bytes
        rsvd1f2                 ; reserve these 16 bytes
        rsvd1f3                 ; reserve these 16 bytes
        rsvd1f4                 ; reserve these 16 bytes
        rsvd1f5                 ; reserve these 16 bytes
        rsvd1f6                 ; reserve these 16 bytes
        rsvd1f7                 ; reserve these 16 bytes
        rsvd1f8                 ; reserve these 16 bytes
        rsvd1f9                 ; reserve these 16 bytes
        rsvd1fa                 ; reserve these 16 bytes
        rsvd1fb                 ; reserve these 16 bytes
        rsvd1fc                 ; reserve these 16 bytes
        rsvd1fd                 ; reserve these 16 bytes
        rsvd1fe                 ; reserve these 16 bytes
        rsvd1ff                 ; reserve these 16 bytes
        endc                    ; 3nd RAM block ends at 1ff
        
; ********************
; ** STARTUP VECTOR **
; ********************
        org     0               ; startup vector
        clrf    PCLATH          ; stay in bank 0
        goto    Start

; ***********************
; ** INTERRUPT HANDLER **
; ***********************
IntHndlr
        org     4               ; interrupt vector
        ; preserve registers...
        movwf   w_copy          ; save w register
        swapf   STATUS,w        ; get STATUS
        clrf    STATUS          ; force bank 0
        movwf   s_copy          ; save STATUS
        movf    PCLATH,w        ; get PCLATH
        movwf   p_copy          ; save PCLATH
        clrf    PCLATH          ; force page 0
        bsf     STATUS,IRP      ; select RAM bank 1
        movf    FSR,w           ; get FSR
        movwf   f_copy          ; save FSR
        
TimrInt
        btfss   INTCON,T0IF     ; is it a timer interrupt?
        goto    CompInt         ; no
        movlw   T0PRE           ; get timer 0 preset value
        movwf   TMR0            ; preset timer 0
        bsf     tFlags,TICK     ; set tick indicator flag
        bcf     INTCON,T0IF     ; clear RTCC int mask

CompInt                         ; timer 1 compare match interrupt.
        btfss   PIR1,CCP1IF     ; is it a compare interrupt?
        goto    EEWrInt         ; no.
        clrf    TMR1L           ; clear timer 1
        clrf    TMR1H           ; clear timer 1
        bcf     PIR1,CCP1IF     ; clear compare match interrupt bit.
        btfss   PORTC,BEEP      ; is beep bit hi?
        goto    CompInL         ; no.
        bcf     PORTC,BEEP      ; lower beep bit.
        goto    EEWrInt         ; done.
CompInL                         ; beep bit was low.
        bsf     PORTC,BEEP      ; raise beep bit.

EEWrInt
        btfss   PIR1,EEIF       ; EE Write Complete interrupt?
        goto    SRcvInt         ; no.
        bcf     PIR1,EEIF       ; yes, clear interrupt bit.

SRcvInt                         ; Serial Receive Interrupt.
        btfss   PIR1,RCIF       ; serial receive interrupt?
        goto    SXmtInt         ; no.
        
        movf    rxHead,w        ; get head of buffer pointer.
        addlw   LOW rxBuf00     ; add to buffer base address.
        movwf   FSR             ; set FSR as pointer
        movf    RCREG,w         ; get received char.
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movwf   INDF            ; put char into buffer

        incf    rxHead,w        ; increment pointer.
        andlw   h'1f'           ; mask so result stays in 0-31 range.
        movwf   rxHead          ; save pointer.

        movf    INDF,w          ; get received character back.
        sublw   SCATTN          ; subtract CI-V preamble character.
        btfsc   STATUS,Z        ; skip if non-zero.
        clrf    rxHead          ; preamble.  Reset to start of buffer.

        movf    INDF,w          ; get received character back.
        sublw   SCTERM          ; subtract CI-V EOM character.
        btfsc   STATUS,Z        ; skip if non-zero.
        bsf     mscFlag,SC_RDY  ; end of message received, ready to process.

SXmtInt                         ; Serial Transmit Interrupt.
        btfss   PIR1,TXIF       ; serial transmit Interrupt?
        goto    IntExit         ; no.

        movf    txTail,w        ; get tail pointer.
        subwf   txHead,w        ; subtract from head pointer.
        btfsc   STATUS,Z        ; result should be non-zero if buffer no
        goto    UTIntD          ; buffer is empty.
        incf    txTail,w        ; get pointer + 1.
        andlw   h'1f'           ; mask so result stays in 0-31 range.
        movwf   txTail          ; save it...
        addlw   LOW txBuf00     ; add to buffer base address.
        movwf   FSR             ; set FSR as pointer.
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movf    INDF,w          ; get char.
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        movwf   TXREG           ; send char.
        goto    IntExit         ; done here.
        
UTIntD                          ; no more chars to transmit.
        ;; turn off the transmitter interrupt.
        bsf     STATUS,RP0      ; select bank 1
        bcf     PIE1,TXIE       ; turn off the transmitter interrupt.
        bcf     STATUS,RP0      ; select bank 1
        ;; goto IntExit         ; done here.
        
IntExit
        movf    p_copy,w        ; get PCLATH preserved value
        movwf   PCLATH          ; restore PCLATH
        movf    f_copy,w        ; get FSR preserved value
        movwf   FSR             ; restore FSR
        swapf   s_copy,w        ; get STATUS preserved value
        movwf   STATUS          ; restore STATUS
        swapf   w_copy,f        ; swap W
        swapf   w_copy,w        ; restore W
        retfie

;
; Play the appropriate ID message, reset ID timers & flags
;
DoID
        ;; euro ID mode change... ID forever, part 1
        btfsc   group3,0        ; euro ID mode?
        goto    DoIDEu          ; yep.
        btfsc   group3,5        ; ID Beacon Mode?
        goto    DoIDEu          ; yep.
        btfsc   flags,DEF_ID    ; deferred ID wanted?
        goto    DoIDEu          ; yes.
        btfss   flags,needID    ; need to ID?
        return                  ; nope--id timer expired without tx since last

        btfsc   group1,6        ; in simplex mode?
        goto    DoIDS           ; yes.
        
DoIDEu
        ;; check to see if ID is currently playing.
        btfsc   flags,IDNOW     ; is the ID playing already?
        return                  ; yes.  Don't start to ID again.
        
        ;; play the ID here.
        btfss   txFlag,RX0OPEN  ; is the receiver active?
        goto    DoIDQ           ; no, it is quiet.
        btfss   group3,6        ; is NO CW ID mode selected?
        goto    DoIDCW          ; no, and actively repeating, play CW ID.
        bsf     flags,DEF_ID    ; set deferred ID flag.
        return                  ; bail out for now.

DoIDQ
        ;; not actively repeating (nobody talking), ok to play voice ID
        btfsc   flags,DEF_ID    ; deferred ID wanted?
        goto    DoIDNor         ; yes.  Play NORMAL voice ID.

        btfsc   flags,initID    ; initial ID wanted?
        goto    DoIDInt         ; yep.
        
DoIDNor
        movf    group2,w        ; get group2 flags
        andlw   b'00000110'     ; mask, either normal ID
        btfss   STATUS,Z        ; is result zero?
        goto    DoIDNCW         ; 
        btfss   group3,6        ; is NO CW ID mode selected?
        goto    DoIDCW          ; yes. do CW ID.
DoIDNCW                         ; NOT doing CW ID
	IFDEF NHRC3_1
        xorlw   b'00000110'     ; are they both on?
        btfss   STATUS,Z        ; are they both on?
        goto    IdNoTog         ; no.
        ;; both ID messages are enabled.  alternate them.
        btfss   mscFlag,IDTOGL  ; toggle bit set?
        goto    IdNoAlt         ; nope
        bcf     mscFlag,IDTOGL  ; clear toggle bit
        movlw   VNORMI2         ; no.  get normal ID message2.
        ELSE
        btfss   group2,1        ; is normal ID 1 enabled?
        goto    DoIDCW          ; no.  send CW ID.
        movlw   VNORMID         ; NHRC-2.1 -- get normal ID message.
        ENDIF
        goto    DoIDSpc         ; play ID message

IdNoAlt
        bsf     mscFlag,IDTOGL  
        movlw   VNORMID         ; no.  get normal ID message.
        goto    DoIDSpc         ; play ID message

IdNoTog                         ; not alternating IDs.
        movlw   VNORMID         ; get normal ID the first
        IFDEF NHRC3_1
        btfsc   group2,2        ; normal ID 2 enabled?
        movlw   VNORMI2         ; get normal ID the second
        ENDIF
        goto    DoIDSpc         ; play it

DoIDS                           ; simplex mode ID message.
        btfss   group1,7        ; simplex mode voice ID requested?
        goto    DoIDCW          ; no.  Play CW ID.
        movlw   VINITID         ; get initial ID
        goto    DoIDSpc         ; play speech ID.
        
DoIDInt                         ; play initial ID
        btfsc   group3,6        ; is NO CW ID mode selected?
        goto    DoIDI1          ; yes.
        btfss   group2,0        ; is initial speech ID enabled?
        goto    DoIDCW          ; not enabled, play CW.
DoIDI1
        movlw   VINITID         ; get initial ID
        ;; 1.06 changes for improved Euro mode ID
        goto    DoIDSpc         ; play speech ID.

        
DoIDSpc                         ; play speech ID
        ;; 1.08 changes for suppressed ID...
        btfsc   group3,7        ; is NO ID mode set?
        goto    DoIDrst         ; yes.  NO ID mode is set.  Don't ID.
        ;; end 1.08 changes.
        ;; 1.06 changes for improved Euro mode ID
        btfsc   flags,IDNOW     ; is the ID playing already?
        return                  ; yes.  don't do it again
        bsf     flags,IDNOW     ; set IDing now flag.
        ;; end 1.06 changes
        call    NewPlay
        goto    DoIDrst

DoIDCW                          ; play CW id.
        ;; 1.08 changes for suppressed ID...
        btfsc   group3,7        ; is NO ID mode set?
        goto    DoIDrst         ; yes.  NO ID mode is set.  Don't ID.
        ;; end 1.08 changes.
        ;; 1.06 changes for improved Euro mode ID
        btfsc   flags,IDNOW     ; is the ID playing already?
        return                  ; yes.  don't do it again
        bsf     flags,IDNOW     ; set IDing now flag.
        ;; end 1.06 changes
        PAGE3                   ; select code page 3.
        movlw   EECWID          ; address of CW ID message in EEPROM.
        movwf   eeAddr          ; save CT base address
        call    PlayCWe         ; kick off the CW playback.
        PAGE0                   ; select code page 0.
        
DoIDrst                         ; reset ID timer & logic.
        movlw   EETID           ; get EEPROM address of ID timer preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   idTmr           ; store to idTmr down-counter
        bcf     flags,initID    ; clear initial ID flag
        
        movf    txFlag,w        ; get tx flags
        andlw   h'01'           ; w=w&RX0OPEN, non zero if RX active.
        btfsc   STATUS,Z        ; is it zero?
        bcf     flags,needID    ; yes. reset needID flag.
        return

Rcv0Off                         ; turn off receiver 0
        movlw   RXSOFF          ; get new state #
        movwf   rx0Stat         ; set new receiver state
        bsf     PORTA,RX0AUD    ; mute it...
        bcf     txFlag,RX0OPEN  ; clear main receiver on bit
        clrf    rx0TOut         ; clear main receiver timeout timer
        return
        
SetHang                         ; start hang timer...
        btfss   group0,3        ; is hang timer enabled?
        return                  ; nope.
        movlw   EETHTS          ; get EEPROM address of hang timer short preset
        btfsc   group0,4        ; is long hang timer selected?
        movlw   EETHTL          ; get EEPROM address of hang timer long preset
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   hangDly         ; save this in hangDly, used often.
        movwf   hangTmr         ; preset hang timer
        btfss   STATUS,Z        ; don't hang if hang timer is 0.
        bsf     txFlag,TXHANG   ; set hang time transmit flag
        return                  ; done.

ChkID                           ; call on receiver drop to see if want to ID
        btfsc   flags,initID    ; is the initial ID wanted?
        goto    ChkID1          ; yes, play the ID
        btfsc   flags,DEF_ID    ; is the deferred ID wanted?
        goto    ChkID1          ; yes, play the ID.
        btfss   flags,needID    ; need to ID sometime?
        return                  ; nope.
        ;
        ;if (idTmr <= IDSOON then goto StartID
        ;implemented as: if ((IDSOON-idTimer)>=0) then ID
        ;
        movf    idTmr,w         ; get idTmr into W
        sublw   IDSOON          ; IDSOON-w ->w
        btfsc   STATUS,C        ; C is clear if result is negative
ChkID1
        call    DoID            ; ok to ID now, let's do it.
        return                  ; don't need to ID yet...

; ***************************************************
; ** DoTail -- Play Tail Message and Reset Counter **
; ***************************************************

DoTail
        IFDEF NHRC3_1
        movf    group1,w        ; get group1 flags
        andlw   b'00110000'     ; mask, either normal ID
        btfsc   STATUS,Z        ; is result zero? (none enabled)
        goto    ResetTC         ; reset the counter
        xorlw   b'00110000'     ; are they both on?
        btfss   STATUS,Z        ; are they both on?
        goto    TailNTg         ; no.
        ;; both ID messages are enabled.  alternate them.
        btfss   mscFlag,TAIL2F  ; toggle bit set?
        goto    TlNoAlt         ; nope
        bcf     mscFlag,TAIL2F  ; clear toggle bit
        movlw   VTAIL2          ; use tail message 2.
        goto    PlayTl          ; play ID message

TlNoAlt
        bsf     mscFlag,TAIL2F  
        movlw   VTAIL           ; use tail message 1.
        goto    PlayTl          ; play ID message

TailNTg                         ; not toggling tail messages
        movlw   VTAIL           ; get tail message 1
        btfsc   group1,4        ; is tail 1 enabled?
        goto    PlayTl          ; yes it is.  use it.
        movlw   VTAIL2          ; get tail message 2
        btfss   group1,5        ; is tail 2 enabled?
        goto    ResetTC         ; no.  should never get here.  handle anyway.
        ELSE
        btfss   group1,4        ; is tail 1 enabled?
        goto    ResetTC         ; it is not.  Don't play a tail message.
        movlw   VTAIL           ; get tail message 1
        ENDIF
        
PlayTl  
        call    NewPlay         ; play ISD Message

ResetTC 
        ;; now, reset tail message counter.
        movlw   EETTAIL         ; get EEPROM address of tail message counter.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   tailCtr         ; preset tail message counter.
        return                  ; done with tail message.
        
        ;; **************************************************
        ;; **************************************************
        ;; **************************************************

; *************
; ** Init256 **
; *************
Init256                         ; initialize 256 bytes from the 32 in cmdbuf00
        movlw   d'8'            ; 8 * 32 = 256. 
        movwf   temp2           ; store into temp.
        movlw   d'32'           ; 32 bytes to write each cycle.
        movwf   eeCount         ; save eeCount:  number of bytes to write.
I256a                           ; loop through writes of 32 bytes.
        movlw   low cmdbf00     ; get base of buffer
        movwf   FSR             ; set into FSR.
        PAGE3                   ; select ROM code page 3.
        call    WriteEE         ; write into EEPROM.
        PAGE0                   ; select ROM code page 0.
        ;; pause while EE operation completes.
        call    InitPos         ; pause.
        movlw   d'32'           ; get size.
        addwf   eeAddr,f        ; add to address.
        movwf   eeCount         ; reset number of bytes to write.
        decfsz  temp2,f         ; decrement cycle count.
        goto    I256a           ; next cycle.
        return                  ; done.
        
; *************
; ** InitPos **
; *************
InitPos                         ; short pause for EEPROM write cycle.
        movlw   d'20'           ; 20 ms.
        call    InitDly         ; delay.
        movlw   d'19'           ; 19 ms.
        call    InitDly         ; delay.
        return                  ; done with pause

; *************
; ** InitDly **
; *************
InitDly                         ; delay w ms for init code.
        movwf   temp6           ; counter.
InitDl2
        btfss   tFlags,TICK     ; looking for 1 ms TICK
        goto    InitDl2         ; loop.
        bcf     tFlags,TICK     ; clear TICK marker.
        clrwdt                  ; reset WDT every ms.
        decfsz  temp6,f         ; decrement counter
        goto    InitDl2         ; counter not zeroed yet.
        return
        
; *********************
; ** PROGRAM STARTUP **
; *********************
        org     0200
Start
        bsf     STATUS,RP0      ; select bank 1

        movlw   b'00000000'     ; turn off A/D
        movwf   ADCON0
        movlw   b'00000111'
        movwf   ADCON1

        movlw   b'01111000'     ;
        movwf   OSCCON          ; set for external clock
        movlw   b'00000001'     ; RBPU pull ups 
                                ; INTEDG INT on falling edge
                                ; T0CS   TMR0 uses instruction clock
                                ; T0SE  n/a
                                ; PSA TMR0 gets the prescaler 
                                ; PS2 \
                                ; PS1  > prescaler 4
                                ; PS0 /
        movwf   OPTION_REG      ; set options

        ;; SPI setup
        movlw   b'11000000'     ; SMP=1 CKE=1
        movwf   SSPSTAT         ; input data on falling edge, output on rising

        ;; Serial port setup
        movlw   d'46'           ; 1200 (1190)  baud at 3.579545 MHz clock.
        movwf   SPBRG           ; set baud rate generator.
        movlw   b'00100000'     ; transmit enabled, low speed async.
        movwf   TXSTA           ; set transmit status and control register.
        movlw   b'00100100'     ; RCIE | CCP1IE interrupts enabled.
        movwf   PIE1            ; set peripheral interrupts enable register.
        
        movlw   B'11101111'     ; na/na/in/out/in/in/in/in
        movwf   TRISA           ; set port A data direction

        movlw   B'00111010'     ; out/out/in/in/in/out/in/out
        movwf   TRISB           ; set port B data direction

        movlw   B'00110000'     ; CTSEL1 & CTSEL2
        movwf   WPUB            ; set port weak pullups

        movlw   B'11010100'     ; na/na/SDO(out)/SDI(in)/SCK(out)/in/out/out
        movwf   TRISC           ; set port C data direction

        movlw   b'00000100'     ; enable on CCP1 interrupt.
        movwf   PIE1            ; set up interrupt control.

        bsf     STATUS,RP1      ; select register page 2/3
        clrf    ANSEL           ; clear analog select
        clrf    ANSELH          ; clear analog select

        bcf     STATUS,RP1      ; select register page 0/1

        bcf     STATUS,RP0      ; select register page 0/2

        ;; SPI setup
        movlw   b'00100001'     ; set up spp: on, spi master, clk/16
        movwf   SSPCON          ; set up SPP for SPI mode.
        
        ;; enable serial port
        movlw   b'10010000'     ; serial enabled, etc.
        movwf   RCSTA           ; set receive status and control register.

        movlw   b'00010000'     ; port a preset muted.
        movwf   PORTA           ; preset PORTA
        clrf    PORTB           ; preset PORTB
        bsf     PORTB,ISDSEL    ; set SPI select high
        movlw   b'00011000'     ; presets for PORTC so ISD does not start
        movwf   PORTC           ; preset PORTC

        clrwdt                  ; give me more time to get up and running.

        ;; set up timer 1
        movlw   b'00000000'     ; set up timer 1.
        movwf   T1CON           ; set up timer 1.
        movlw   b'00001010'     ; timer 1 compare throws interrupt.
        movwf   CCP1CON         ; set up compare mode.
        movlw   h'ff'           ; init compare value.
        movwf   CCPR1L          ; set up initial compare (invalid)
        movwf   CCPR1H          ; set up initial compare (invalid)
        movlw   h'20'           ; first address of RAM.
        movwf   FSR             ; set pointer.

ClrMem
        clrf    INDF            ; clear ram byte.
        incf    FSR,f           ; increment FSR.
        btfss   FSR,7           ; cheap test for address 80 and above.
        goto    ClrMem          ; loop some more.
        bsf     STATUS,IRP      ; select FSR is in 100-1ff range
        
        movlw   TEN             ; get timebase presets
        movwf   oneMsC
        movwf   tenMsC
        movwf   hundMsC
        movwf   thouMsC
        clrf    tFlags

        movlw   CTNONE          ; no courtesy tone.
        movwf   cTone           ; set courtesy tone selector.

        ;; preset timer defaults
        clrf    cwTbTmr         ; CW timebase counter.
        
        ;; enable interrupts.
        movlw   b'11100000'     ; enable global + peripheral + timer0
        movwf   INTCON

        ;;  power up the ISD
        movlw   ICMDPU          ; get power up command constant
        call    QISDCmd         ; enqueue the PU command.

        ;;  50 ms T_PU_D power up delay.
        movlw   IDLY60          ; 60 ms delay
        call    QISDCmd         ; enqueue the delay command
                
        ;; set the MUTE pin to an input to look for init
        bsf     STATUS,RP0      ; select bank 1
        movlw   B'11111111'     ; na/na/in/*in*/in/in/in/in
        movwf   TRISA           ; set port A data direction
        bcf     STATUS,RP0      ; select bank 0

        btfsc   PORTA,INIT      ; skip if init button pressed.
        goto    Start1          ; no initialize request.
        
; *********************
; * INITIALIZE EEPROM *
; *********************
                
        clrf    temp2           ; byte index
InitLp
        movf    temp2,w         ; get last address.
        sublw   EELAST          ; subtract last init address.
        btfss   STATUS,C        ; c will be clear if result is negative.
        goto    InitDun         ; done initializing...
        movf    temp2,w         ; get init address
        movwf   eeAddr          ; set eeprom address
        movf    temp2,w         ; get init address
        PAGE3                   ; select page 3
        call    InitDat         ; get init byte
        call    WriteEw         ; write byte to EEPROM.
        PAGE0                   ; select page 0
        incf    temp2,f         ; go to next byte
        goto    InitLp          ; get the next block of 16 or be done.
        
InitDun                         ; done with init loop
        movlw   ICMDGER         ; get global erase command
        call    QISDCmd         ; enqueue the GER command.
        clrwdt                  ; get more time to start up.
        
; ********************************
; ** Ready to really start now. **
; ********************************
Start1
        ;; reset the state of the MUTE pin to an output
        bsf     STATUS,RP0      ; select bank 1
        movlw   B'11101111'     ; na/na/in/out/in/in/in/in
        movwf   TRISA           ; set port A data direction
        bcf     STATUS,RP0      ; select bank 0

        movlw   ICMDWAP         ; get the WAPC2 command
        call    QISDCmd         ; enqueue the WAPC2 command.

        movlw   ICMDDID         ; get the DID command
        call    QISDCmd         ; enqueue the DID command.
        
        
Start2  
        clrw                    ; select macro set 0.
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        call    CWParms         ; get the CW parameters for pitch and speed.
        PAGE0                   ; select page 0
        movlw   1               ; 1 = 10 seconds for ID timer in euro mode.
        btfsc   group3,0        ; in euro mode?
        movwf   idTmr           ; preload ID timer in euro mode.
        btfsc   group3,5        ; in ID Beacon mode?
        movwf   idTmr           ; preload ID timer in euro mode.
                
        ;; get tail message counter.
        movlw   EETTAIL         ; get EEPROM address of tail message counter.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select page 0.
        movwf   tailCtr         ; preset tail message counter.
        ;;
        ;; say hello to all the nice people out there.
        ;;
        btfsc   group3,7        ; NO ID set?
        goto    Loop0           ; yes.  NO ID.
        PAGE3                   ; select code page 3.
        movlw   CWHELLO         ; get HELLO announcement.
        call    PlayCW          ; start playback
        PAGE0                   ; select code page 0.
        
; **************************************************************************
; ******************************* MAIN LOOP ********************************
; **************************************************************************
                
Loop0
        btfsc   tFlags,TENSEC   ; is ten second flag set?
        bcf     tFlags,TENSEC   ; reset it if it is...

Chek1000        
        btfss   tFlags,ONESEC   ; is the 1000 mS flag set?
        goto    Check100        ; nope...
        bcf     tFlags,ONESEC   ; clear 1000 mS flag.
        decfsz  thouMsC,f       ; decrement hundred millisecond counter.
        goto    Check100        ; not zero.
        movlw   TEN             ; get preset.
        movwf   thouMsC         ; reset down counter.
        bsf     tFlags,TENSEC   ; set ONESEC indicator.

Check100        
        btfss   tFlags,HUNDMS   ; is the 100 mS flag set?
        goto    Check10         ; nope...
        bcf     tFlags,HUNDMS   ; clear 100 mS flag.
        decfsz  hundMsC,f       ; decrement hundred millisecond counter.
        goto    Check10         ; not zero.
        movlw   TEN             ; get preset.
        movwf   hundMsC         ; reset down counter.
        bsf     tFlags,ONESEC   ; set ONESEC indicator.

Check10
        btfss   tFlags,TENMS    ; is the 10 mS flag set?
        goto    Check1          ; nope...
        bcf     tFlags,TENMS    ; clear 10 mS flag.
        decfsz  tenMsC,f        ; decrement ten millisecond counter.
        goto    Check1          ; not zero.
        movlw   TEN             ; get preset.
        movwf   tenMsC          ; reset down counter.
        bsf     tFlags,HUNDMS   ; set HUNDMS indicator.

Check1
        btfss   tFlags,ONEMS    ; is the 1 mS flag set?
        goto    CheckTic        ; nope...
        bcf     tFlags,ONEMS    ; clear 1 mS flag.
        decfsz  oneMsC,f        ; decrement one millisecond counter.
        goto    CheckTic        ; not zero.
        movlw   TEN             ; get preset.
        movwf   oneMsC          ; reset down counter.
        bsf     tFlags,TENMS    ; set TENMS indicator.

CheckTic
        
        btfss   tFlags,TICK     ; did a tick occur?
        goto    Loop1           ; nope.
        bcf     tFlags,TICK     ; reset TICK indicator.
        bsf     tFlags,ONEMS    ; set ONEMS indicator.
        clrwdt

Loop1
; ********************************************
; ** RECEIVER DEBOUNCE AND INPUT VALIDATION **
; ********************************************
DebRx
        btfss   tFlags,ONEMS    ; one ms tick, check for receiver active
        goto    NoDeb           ; nope
CkRx0                           ; check COR state receiver 1
        btfss   PORTB,RX0COR    ; check cor receiver 1
        goto    Rx0COR1         ; it's low, COR is present
                                ; COR is not present.
        btfss   group1,2        ; (NOT) OR PL?
        goto    Rx0Off          ; nope...
        ;; v01.2 change here.
        btfsc   group0,1        ; is PL required?
        goto    Rx0Off          ; yes.
        ;; end v01.2 change.
        goto    Rx0CkPL         ; yes, OR PL mode
Rx0COR1
        btfss   group0,1        ; AND PL set?
        goto    Rx0On           ; no.
        ;; v01.2  new code.
        btfss   group1,2        ; OR PL set?
        goto    Rx0CkPL         ; no.
        ;; AND and OR PL are both set, PL is required to bring up repeater,
        ;; but not to access it during tail.
        movf    txFlag,w        ; get txFlag.
        andlw   b'00000101'     ; hang time or rx0 is open.
        btfss   STATUS,Z        ; Z will be set if not hang or rx0.
        goto    Rx0On           ; repeater is not idle.  Allow COR access.
        ;; end v 01.2 new code.
        ;; 1.06 change.  fix for 1750 mode in timeout...
        btfsc   rxFlag,RX0OPEN  ; already marked active?
        goto    Rx0On           ; stay set on.
        ;; end of 1.06 change...

Rx0CkPL                         ; check PL...
        btfsc   PORTC,RX0PL     ; is the PL signal present?
        goto    Rx0Off          ; no.
        
Rx0On                           ; the COR and PL requirements have been met
        btfsc   rxFlag,RX0OPEN  ; already marked active?
        goto    Rx0NC           ; yes.
        movf    rx0Dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx01Dbc         ; nope...
        movlw   COR1DEB         ; get COR debounce timer value.
        btfsc   group2,7        ; is the delay present?
        movlw   DLY1DEB         ; get COR debounce with delay value.
        movf    txFlag,f        ; check for transmitter already on.
        btfss   STATUS,Z        ; is the transmitter already on?
        goto    Rx0SDeb         ; yep.
        btfsc   group0,2        ; is the kerchunker delay set?
        movlw   CHNKDEB         ; get kerchunker filter delay.
Rx0SDeb                         ; set debounce timer.
        movwf   rx0Dbc          ; set it
        goto    Rx0Done         ; done.
Rx01Dbc
        decfsz  rx0Dbc,f        ; decrement the debounce counter
        goto    Rx0Done         ; not zero yet
        bsf     rxFlag,RX0OPEN  ; set receiver active flag
        goto    Rx0Done         ; continue...
Rx0Off                          ; the COR and PL requirements have not been met
        btfss   rxFlag,RX0OPEN  ; was the receiver off before?
        goto    Rx0NC           ; yes.
        movf    rx0Dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx00Dbc         ; nope...
        movlw   COR0DEB         ; get COR debounce timer value.
        btfsc   group2,7        ; is the delay present?
        movlw   DLY0DEB         ; get COR debounce with delay value.
        ;; 1.06 change; use long debounce in simplex mode
        btfsc   group1,6        ; in simplex mode?
        movlw   COR0DBS         ; get COR simplex debounce time.
        ;; end 1.06 change...
        movwf   rx0Dbc          ; set it
        goto    Rx0Done         ; done.
Rx00Dbc
        decfsz  rx0Dbc,f        ; decrement the debounce counter
        goto    Rx0Done         ; not zero yet
        bcf     rxFlag,RX0OPEN  ; clear receiver active flag
        movf    dt0Tmr,f        ; test to see if touch-tones received...
        btfsc   STATUS,Z        ; is it zero?
        goto    Rx0Done         ; yes. don't need to accellerate execution.
        movlw   d'2'            ; no
        movwf   dt0Tmr          ; accelerate eval of DTMF command
        goto    Rx0Done         ; continue...
Rx0NC
        clrf    rx0Dbc          ; clear debounce counter.
Rx0Done

        ;; check alarm input status
        btfss   group4,6        ; is the alarm enabled?
        goto    AlmOff          ; alarm is not turned on.
        btfsc   PORTB,ALARMIN   ; is alarm input low?
        goto    NoAlm           ; no
        btfsc   mscFlag,ALARMED ; was the alarm mode already set?
        goto    AlmDone         ; yes.  no need to do more.
        bsf     mscFlag,ALARMED ; set alarmed flag
        movlw   d'1'            ; play alarm message soon.
        movwf   alrmTmr         ; set alarm timer 10 seconds hence.
        goto    NoDeb

NoAlm
        btfsc   group4,7        ; latch mode selected?
        goto    AlmDone         ; yes.
        bcf     mscFlag,ALARMED ; reset alarmed flag
        clrf    alrmTmr         ; clear alarm announcement timer
        goto    AlmDone
        
AlmOff                          ; alarm is not enabled.
        bcf     mscFlag,ALARMED ; so make sure the indicator is off.
        clrf    alrmTmr         ; and timer is zero

AlmDone          
NoDeb
        btfss   tFlags,TENMS    ; ten MS flag set?
        goto    CkDTDone        ; no.

        btfss   PORTA,DTMF_DV   ; is a DTMF digit being decoded?
        goto    CkDT0L          ; no
        btfsc   flags,LAST_DV   ; was it there last time?
        goto    CkDTDone        ; yes, do nothing.
        bsf     flags,LAST_DV   ; set last DV indicator.
        bcf     mscFlag,CTCSS0  ; clear LAST CTCSS flag.
        btfss   PORTC,RX0PL     ; is the PL signal present?
        bsf     mscFlag,CTCSS0  ; set LAST CTCSS flag.

RdDT0
        btfss   group1,3        ; is muting enabled?
        goto    RdDT0m          ; nope.
        bsf     PORTA,RX0AUD    ; mute receiver 0
        movlw   MUTEDLY         ; get mute timer delay
        movwf   muteTmr         ; preset mute timer
RdDT0m
        movlw   DTMFDLY         ; get DTMF activity timer preset.
        movwf   dt0Tmr          ; set dtmf command timer
        
        movf    dt0Ptr,w        ; get index
        movwf   FSR             ; put it in FSR
        bcf     STATUS,C        ; clear carry (just in case)
        rrf     FSR,f           ; hey! divide by 2.
        movlw   LOW dt0buf0     ; get address of buffer
        addwf   FSR,f           ; add to index.
        
        movlw   b'00001111'     ; mask bits.
        andwf   PORTA,w         ; get masked bits of tone into W.
        PAGE3                   ; select code page 3.
        call    MapDTMF         ; remap tone into keystroke value..
        PAGE0                   ; select code page 0.
        iorlw   h'0'            ; OR with zero to set status bits.
        bcf     mscFlag,DT0ZERO ; clear last zero received.
        btfsc   STATUS,Z        ; was a zero the last received digit?
        bsf     mscFlag,DT0ZERO ; yes...
        
        btfsc   dt0Ptr,0        ; is this an odd address?
        goto    DT0Odd          ; yes;
        clrf    INDF            ; zero both nibbles.
        movwf   INDF            ; save tone in indirect register.
        swapf   INDF,f          ; move the tone to the high nibble
        goto    DT0Done         ; done here
DT0Odd
        iorwf   INDF,F          ; save tone in low nibble
DT0Done 
        incf    dt0Ptr,f        ; increment index
        movlw   h'1f'           ; mask
        andwf   dt0Ptr,f        ; don't let index grow past 1f (31)

        goto    CkDTDone        ; done with DTMF checking.

CkDT0L                          ; check for end of LITZ...
        btfss   flags,LAST_DV   ; was it low last time?
        goto    CkDTDone        ; yes.  Done.
        bcf     flags,LAST_DV   ; clear last DV indicator.
        btfss   mscFlag,DT0ZERO ; was zero the last received digit?
        goto    CkDTDone        ; no.
        movf    dt0Tmr,w        ; get dtmf command timer
        btfsc   STATUS,Z        ; is it already zero?
        goto    CkDT0LZ         ; yes.
        sublw   LITZTIM         ; subtract from litz time.
        btfss   STATUS,C        ; is result positive?
        goto    CkDTDone        ; nope.

CkDT0LZ                         ; check for LITZ digits.
        bsf     mscFlag,LITZDT0 ; set LITZ on main receiver flag.
        clrf    dt0Ptr          ; clear this, throw away received LITZ tone.
        clrf    dt0Tmr          ; clear this, don't process tones normally.

CkDTDone                        ; done with DTMF scanning.

;;;     ISD State machine.

        ;; check for "interrupt" from ISD here.
        btfsc   PORTB,ISDINT    ; is ISD interrupt low?
        goto    IIDone          ; no interrupt has occurred
        ;; the interrupt bit is low; have interrupt
        bcf     txFlag,TALKING  ; clear TALKING flag, no matter what

        btfss   group1,6        ; in simplex mode?
        goto    CkI2            ; no
        btfsc   isdFlag,ISDRECF ; was it recording?
        bsf     isdFlag,ISDRECE ; yes, set message overflow flag
        btfsc   isdFlag,ISDRUNF ; was it in playback mode?
        bsf     isdFlag,ISDZAPS ; yes, erase simplex message

CkI2
        bcf     isdFlag,ISDRUNF ; not running any more
        bcf     isdFlag,ISDRECF ; not recording any more
        btfsc   flags,IDNOW     ; was that an ID that was playing?
        bcf     flags,needID    ; don't need to ID again
        bcf     flags,IDNOW     ; if this was an ID, clear it
        PAGE3                   ; select code page 3.
        movlw   ISDCINT         ; ISD clear interrupt command.
        call    ISDCmd2         ; clear interrupt.
        PAGE0                   ; select code page 0.
        bcf     ismpcf,ISMWINT  ; turn off wait for interrupt flag
        bcf     ismpcf,ISMERAS  ; turn off erase cannot be interrupted flag

CkI3
        btfss   isdFlag,ISDZAPS ; zap simplex message?
        goto    IIDone          ; nope.
        bcf     isdFlag,ISDZAPS ; reset zap simplex message flag
        
        ;; erase simplex message after playback
        btfss   group1,6        ; in simplex mode?
        goto    IIDone          ; no
        movlw   VSIMPLX         ; get simplex message
        iorlw   ICMDDEL         ; make into erase command
        call    QISDCmd         ; enqueue the delay command.
        
IIDone  
        ;; check the state if the ISD Timer
        movf    isdDly,f        ; check for isdDly
        btfsc   STATUS,Z        ; is it zero?
        goto    NIsdTmr         ; isdDly is zero
        decfsz  isdDly,f        ; decrement isdDly
        goto    NIsdTmr         ; still not zero.
        bcf     ismpcf,ISMWAIT  ; turn off timer flag
        
NIsdTmr
        ;; now process the ISD state machine.
        movf    ismpcf,f        ; check state machine process control flags
        btfss   STATUS,Z        ; skip if ismpcf is zero
        goto    IQDone          ; not ready for another command
        movf    isdcbt,w        ; get tail pointer.
        subwf   isdcbh,w        ; subtract from head pointer.
        btfsc   STATUS,Z        ; result should be non-zero if buffer no
        goto    IQDone          ; buffer is empty.
        ;; there is a command in the queue, dequeue it
        incf    isdcbt,w        ; get tail pointer + 1.
        andlw   h'07'           ; mask so result stays in 0-7 range.
        movwf   isdcbt          ; save it...
        addlw   LOW isdcb00     ; add to buffer base address.
        movwf   FSR             ; set FSR as pointer.
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movf    INDF,w          ; get char.
        clrf    INDF            ; mark as invalid.  aids debugging. 
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        ;;  now have dequeued isd command in w
        movwf   temp5           ; save it
        btfsc   temp5,7         ; is command?
        goto    ICP7            ; hi bit is set! erase or record
        btfsc   temp5,6         ; is it playback?
        goto    ICPplay         ; it is playback.
        btfsc   temp5,5         ; is it a delay command?
        goto    ICPdelay
        
        ;; has to be a command
ICPcmd
        movlw   b'00001111'     ; command number mask
        andwf   temp5,f         ; mask 0-7

        movlw   high ICPtbl     ; set high byte of address
        movwf   PCLATH          ; select page
        movf    temp5,w         ; get command number
        addwf   PCL,f           ; add w to PCL:  computed GOTO
ICPtbl  ;; computed goto
        goto    ICPcmd0         ; invalid command
        goto    ICPcmd1         ; stop
        goto    ICPcmd2         ; reset
        goto    ICPcmd3         ; clear interrupt
        goto    ICPcmd4         ; read status
        goto    ICPcmd5         ; resd devid
        goto    ICPcmd6         ; global erase
        goto    ICPcmd7         ; write APC2
        goto    ICPcmd8         ; PU
        goto    ICPcmd0         ; 9 invalid command
        goto    ICPcmd0         ; A invalid command
        goto    ICPcmd0         ; B invalid command
        goto    ICPcmd0         ; C invalid command
        goto    ICPcmd0         ; D invalid command
        goto    ICPcmd0         ; E invalid command
        goto    ICPcmd0         ; F invalid command

ICPcmd0                         ; invalid command.
        goto    IQDone  

ICPcmd1                         ; stop
        clrf    isdS1           ; clear isd payload byte 1
        clrf    isdS2           ; clear isd payload byte 2
        movlw   ISDSTS          ;
        PAGE3                   ; select code page 3.
        call    ISDCmd3         ; send the STATUS  command
        PAGE0                   ; select code page 0.
        movf    sr1lo,w         ; get status 1 byte
        andlw   b'00110000'     ; mask out all except REC and PLAY flags
        btfsc   STATUS,Z        ; is it zero?
        goto    ICP2B           ; it is zero, not gonna send STOP.
        bsf     ismpcf,ISMWINT  ; need to wait for ISD int after this cmd.
        movlw   ISDSTOP         ; get the STOP command
        goto    ICP2B           ; send 2 byte command

ICPcmd2                         ; reset
        movlw   ISDRST          ; get the RESET command
        goto    ICP2B           ; send 2 byte command

ICPcmd3                         ; clear interrupt
        movlw   ISDCINT         ; ISD clear interrupt command.
        goto    IQDone          

ICPcmd4                         ; read status
        clrf    isdS1           ; clear isd payload byte 1
        clrf    isdS2           ; clear isd payload byte 2
        movlw   ISDSTS          ;
        PAGE3                   ; select code page 3.
        call    ISDCmd3         ; send the STATUS  command
        PAGE0                   ; select code page 0.
        goto    IQDone          
        
ICPcmd5                         ; read devid
        clrf    isdS1           ; clear isd payload byte 1
        clrf    isdS2           ; clear isd payload byte 2
        movlw   ISDDID          ; read devid commadn
        PAGE3                   ; select code page 3.
        call    ISDCmd3         ; send the DEVID command
        PAGE0                   ; select code page 0.
        movf    sr1lo,w         ; get 3rd response byte
        movwf   isdDvId         ; save ISD device ID.
        goto    IQDone          

ICPcmd6                         ; G_erase
        bsf     ismpcf,ISMWINT  ; need to wait for interrupt after this cmd.
        bcf     ismpcf,ISMERAS  ; erase cannot be interrupted.
        movlw   ISDGER          ; ISD global erase command
        goto    ICP2B           ; send 2 byte command

ICPcmd7                         ; write apc2
        movlw   APC07           ; 1st byte of APC register
        movwf   isdS1           ; save it
        movlw   APC811          ; 2nd byte of APC register
        movwf   isdS2           ; save it
        movlw   ISDWAPC         ; ISD WR_APC2 command
        PAGE3                   ; select code page 3
        call    ISDCmd3         ; send 3 byte command to ISD
        PAGE0                   ; select code page 0
        goto    IQDone  
        
ICPcmd8                         ; PU
        movlw   ISDPU           ; ISD PU command
        goto    ICP2B           ; send 2 byte command
        
ICP2B                           ; send 2 byte command from here
        PAGE3                   ; select code page 3.
        call    ISDCmd2         ; send the command
        PAGE0                   ; select code page 0.
        goto    IQDone          
        
ICPdelay
        movf    temp5,w         ; get command back
        andlw   b'00011111'     ; mask to delay
        ;; this uses 7 instructions to make isdDly = 10 * w
        movwf   isdDly          ; save it  (=A)
        movwf   temp5           ; save it  (=A)
        rlf     temp5,f         ; temp5 = temp5 x 2
        rlf     temp5,f         ; temp5 = temp5 x 2
        rlf     temp5,w         ; w = temp5 * 2
        addwf   isdDly,w        ; w = w + isdDly
        addwf   isdDly,f        ; idsDly = w + isdDly
        bsf     ismpcf,ISMWAIT  ; set ISMWAIT condition, wait for timer
        goto    IQDone
        
ICPplay
        movlw   ISDPLAY         ; ISD SET_PLAY command
        movwf   isdCmd          ; save command byte
        
        bsf     txFlag,TALKING  ; set TALKING flag.
                
        movf    temp5,w         ; get command byte back
        andlw   b'00111111'     ; mask to only reasonable message numbers
        PAGE3                   ; select code page 3.
        call    MsgNum          ; set up ISD start/stop address
        call    ISDCmd7         ; send 7 byte command to ISD
        call    PTTon           ; turn on tx if not on already.
        PAGE0                   ; select code page 0

        bsf     isdFlag,ISDRUNF ; set ISD running flag
        goto    ICPWINT
        
ICP7
        btfss   temp5,6
        goto    ICPerase
        
ICPrec
        movlw   ISDREC
        movwf   isdCmd          ; save command byte

        movf    temp5,w         ; get command byte back
        andlw   b'00111111'     ; mask to only reasonable message numbers
        PAGE3                   ; select code page 3
        call    MsgNum          ; set up ISD start/stop address
        call    ISDCmd7         ; send 7 byte command to ISD
        PAGE0                   ; select code page 0
        
        bsf     isdFlag,ISDRECF ; set recording flag
        bcf     isdFlag,ISDRECE ; clear overflow flag
        goto    ICPWINT

ICPerase
        movlw   ISDERAS         ; ISD SET_ERASE command
        movwf   isdCmd          ; save command byte

        movf    temp5,w         ; get command byte back
        andlw   b'00111111'     ; mask to only reasonable message numbers
        PAGE3                   ; select code page 3
        call    MsgNum          ; set up ISD start/stop address
        call    ISDCmd7         ; send 7 byte command to ISD
        PAGE0                   ; select code page 0
        
        bsf     ismpcf,ISMERAS  ; erase cannot be interrupted.
        btfsc   group1,6        ; in simplex mode?
        bsf     txFlag,TALKING  ; set TALKING flag.
        
ICPWINT                         ; set wait for interrupt and continue
        bsf     ismpcf,ISMWINT  ; wait for interrupt
        
        goto    IQDone

IQDone  

        goto    MainLp          ; crosses 256 byte boundary (to 0400)
        org 0400
        
; *************************************
; * main loop for repeater controller *
; *************************************

MainLp
        movlw   high MlTbl      ; set high byte of address
        movwf   PCLATH          ; select page
        movf    rx0Stat,w       ; get main receiver state
        addwf   PCL,f           ; add w to PCL:  computed GOTO
MlTbl
        goto    Main0           ; quiet
        goto    Main1           ; repeat
        goto    Main2           ; timeout
        ;; new state for 1.04 
        goto    Main3           ; RXSREC record with rptr disabled.
        ;; new state for 1.12
        goto    Main4           ; receiver active while repeater is off
        
Main0                           ; receiver quiet state
        btfss   rxFlag,RX0OPEN  ; is squelch open?
        goto    ChkTmrs         ; nope, don't turn receiver on
        ;; receiver is unsquelched; put it on the air
        ;; receiver inactive --> active transition
        ;; v 1.04 changes to allow record when repeater disabled...
        btfsc   group0,0        ; is repeater enabled?
        goto    Main0on         ; yes.
        
        ;; repeater is not enabled.
        btfsc   isdFlag,ISDRECR ; is record mode flag set?
        goto    Main0R
        btfss   group3,5        ; ID beacon mode?
        goto    ChkTmrs         ; nope.
        btfss   group3,6        ; NO CW ID mode?
        goto    ChkTmrs         ; nope.
        ;; now in BEACON mode and NO CW ID mode.
        movlw   RXSOFON         ; get new state #
        movwf   rx0Stat         ; set new receiver state

        ;; stomp playing voice messages here.
        btfss   isdFlag,ISDRUNF ; is ISD Running?
        goto    ChkTmrs         ; no
        ;; ISD is running.
        btfss   flags,IDNOW     ; is an ID playing now?
        goto    ChkTmrs         ; no.
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.
        bcf     txFlag,TALKING  ; clear TALKING flag
        bsf     flags,DEF_ID    ; set deferred ID flag.
        bcf     flags,IDNOW     ; clear IDing flag.
        goto    ChkTmrs         ; rptr is disabled, no record.
        
Main0R
        ;; repeater is disabled, but record is set.
        ;; set state to record...
        movlw   RXSREC          ; get new state #.
        movwf   rx0Stat         ; set new receiver state record with rptr off.
        bcf     PORTA,RX0AUD    ; unmute receiver
        
        btfss   isdFlag,ISDRUNF ; is ISD Running?
        goto    M0ORec          ; no
        ;; ISD is running.
        clrf    isdDly          ; clear this so it can't fire, just in case.
        bcf     isdFlag,ISDRUNF ; clear ISD running flag.
        bcf     txFlag,TALKING  ; clear TALKING flag
M0ORec
        ;; now set up to start recording...
        bcf     isdFlag,ISDRECR ; clear record mode flag.
        ;; stop the ISD to make sure it is in a known state.
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.
        ;; send the record command
        movf    isdRMsg,w       ; get message number
        iorlw   ICMDREC         ; make into record command
        call    QISDCmd         ; enqueue the command
        goto    ChkTmrs         ; done here.  continue on.
                
Main0on
        btfss   group0,5        ; is DTMF access mode enabled?
        goto    Main00          ; no.
        movf    dtATmr,f        ; check DTMF access mode timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    ChkTmrs         ; yes.  Don't turn receiver on.
        ;; timer is not zero, reset to initial value.
        movlw   EETDTA          ; get EEPROM address of DTMF access timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   dtATmr          ; set DTMF access mode timer.
Main00                          ; receiver inactive --> active transition
        movlw   RXSON           ; get new state #
        movwf   rx0Stat         ; set new receiver state

        btfss   group3,0        ; euro ID mode?
        goto    Main00e         ; not in euro mode.
        movf    txFlag,w        ; get txFlag.
        andlw   b'00000100'     ; mask for HANG 
        btfsc   STATUS,Z        ; is result zero?
        bsf     flags,initID    ; yes, set init ID mode
        
Main00e                         ;
        bsf     flags,needID    ; make sure ID still plays if tail never drops
        ;; 1.05 change here, fixes extra ID in euro ID mode
        bcf     txFlag,TXHANG   ; clear hang flag
        clrf    hangTmr         ; clear hang timer
        ;; end of 1.05 change
        btfss   group1,6        ; dont turn on TX if in simplex mode.
        bsf     txFlag,RX0OPEN  ; set main receiver on bit
        movlw   CTNONE          ; no courtesy tone.
        movwf   cTone           ; kill off any pending courtesy tone.
Main00a 
        movf    muteTmr,f       ; check mute timer
        btfsc   STATUS,Z        ; if it's non-zero, skip unmute
        bcf     PORTA,RX0AUD    ; unmute receiver
        ;; stomp playing voice messages here.
        btfss   isdFlag,ISDRUNF ; is ISD Running?
        goto    ChkRec          ; no
        ;; ISD is running.
        btfss   flags,IDNOW     ; is an ID playing now?
        goto    Stomp           ; nope.
        btfss   group2,3        ; is stomp allowed?
        goto    MainUM          ; nope.  bypass record check, too.
Stomp
        clrf    isdDly          ; clear this so it can't fire, just in case.
        bcf     txFlag,TALKING  ; clear TALKING flag
        ;; stop the ISD
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.

        btfss   group1,6        ; in simplex repeat mode?
        goto    StompNS         ; nope.
        ;; erase simplex message after playback
        movlw   VSIMPLX         ; get simplex message
        iorlw   ICMDDEL         ; make into erase command
        call    QISDCmd         ; enqueue the erase command.

StompNS 
        btfss   flags,IDNOW     ; is an ID playing now?
        ;; hmmmm.  should this be allowed to set record mode now?
        goto    ChkRec          ; no.

        btfss   group3,6        ; is NO CW ID mode selected?
        goto    Stomp1          ; no, it is not.
        bsf     flags,DEF_ID    ; set deferred ID flag.
        bcf     flags,IDNOW     ; clear IDing flag.
        goto    ChkRec          ; continue...
        
Stomp1
        movlw   EECWID          ; address of CW ID message in EEPROM.
        movwf   eeAddr          ; save CT base address
        PAGE3                   ; select code page 1.
        call    PlayCWe         ; kick off the CW playback.
        PAGE0                   ; select code page 0.
        bcf     flags,IDNOW     ; clear IDing flag.
        
ChkRec
        btfsc   isdFlag,ISDRECR ; is record mode flag set?
        goto    NormRec         ; record normal message.
        btfsc   group1,6        ; in simplex mode?
        goto    SimRec          ; yes.
        goto    MainUM          ; no continue...

NormRec                         ; normal, 22.3 second message.
        bcf     isdFlag,ISDRECR ; clear record mode flag.
        movf    isdRMsg,w       ; get record message slot
        iorlw   ICMDREC         ; make into record command
        call    QISDCmd         ; enqueue the command
        goto    MainUM          ; continue
        
SimRec
        movlw   VSIMPLX         ; get simplex message
        iorlw   ICMDREC         ; make into record command
        call    QISDCmd         ; enqueue the command
        goto    MainUM          ; done here.
        
MainUM
Main01
        btfss   group1,0        ; is time out timer enabled?
        goto    ChkTmrs         ; nope...
        movlw   EETTMS          ; EEPROM address of timeout timer short preset.
        btfsc   group1,1        ; is short timeout selected
        movlw   EETTML          ; EEPROM address of timeout timer long preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   rx0TOut         ; set timeout counter
        goto    ChkTmrs         ; done here...

Main1                           ; receiver active state
        btfss   group0,0        ; is repeater enabled?
        goto    Main1Off        ; no.  turn receiver off
        btfss   rxFlag,RX0OPEN  ; is squelch open?
        goto    Main1Off        ; no, on->off transition
        btfss   tFlags,ONESEC   ; one second tick?
        goto    ChkTmrs         ; nope, continue
        movf    rx0TOut,f       ; squelch still open, check timeout timer
        btfsc   STATUS,Z        ; skip if not zero
        goto    ChkTmrs         ; timeout timer is zero, don't decrement
        decfsz  rx0TOut,f       ; decrement the timeout timer
        goto    ChkTmrs         ; have not timed out (yet), continue
        ;; have just timed out!
        movlw   RXSTMO          ; get new state, timed out
        movwf   rx0Stat         ; set new receiver state
        bcf     txFlag,RX0OPEN  ; clear main receiver on bit
        bsf     PORTA,RX0AUD    ; mute
        btfss   group1,6        ; in simplex mode?
        goto    Main1X          ; yes.
        btfss   isdFlag,ISDRECF ; is the ISD recording
        goto    ChkTmrs         ; no, it has already stopped
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.
        goto    ChkTmrs         ; done here
Main1X  
        clrf    rx0TOut         ; clear main receiver timeout timer
        btfsc   group2,4        ; is voice timeout message enabled?
        goto    Main1TO         ; yes...
        PAGE3                   ; select code page 3.
        movlw   CW_TO           ; get CW timeout message.
        call    PlayCW          ; play CW message.
        PAGE0                   ; select code page 1.
        goto    ChkTmrs         ; done here...
Main1TO 
        movlw   VTIMOUT         ; time out message
        call    NewPlay
        goto    ChkTmrs         ; done here...

Main1Off                        ; receiver was active, became inactive
        call    Rcv0Off         ; turn off receiver
Main10
        btfsc   group1,6        ; in simplex mode?
        goto    Main10m         ; yes.

        btfsc   isdFlag,ISDTEST ; test mode?
        goto    Main10m         ; yes

        btfss   isdFlag,ISDRECF ; is the ISD recording
        goto    Main10a         ; nope.
        ;; the ISD is recording, send the stop command
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.
        goto    RecEnd1         ; not in simplex mode.

Main10m                         ; receiver dropped, in simplex mode.
        btfss   isdFlag,ISDRECF ; is the ISD recording
        goto    Main10X         ; nope.
        ;; the ISD is recording, send the stop command
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.

Main10X
        movlw   VSIMPLX         ; normal simplex message.
        IFDEF NHRC3_1
        btfsc   isdFlag,ISDTEST ; test message?
        movlw   VTEST           ; get the test message address
        ENDIF
        call    NewPlay         ; play it
        bcf     isdFlag,ISDTEST ; clear this bit regardless of set or not
        goto    Main10s         ; done here.

RecEnd1
        ;;  play CW OK message to indicate the record is complete
        movlw   CW_OK           ; get CW OK
        btfsc   isdFlag,ISDRECE ; overflow error?
        movlw   CW_ERR          ; yes!
        bcf     isdFlag,ISDRECE ; clear overflow message bit
        PAGE3                   ; select code page 3.
        call    PlayCW          ; start playback
        PAGE0                   ; select ROM page 0.
        
Main10a
        ;;  set the courtesy tone
        clrf    cTone           ; start with zero
        btfss   PORTB,CTSEL1    ; is CTSEL1 high?
        bsf     cTone,0         ; no. set cTone 1s bit.
        btfsc   PORTB,CTSEL2    ; is CTSEL2 high?
        goto    Main10h         ; yes.
        btfss   group4,6        ; is alarm mode set?
        bsf     cTone,1         ; no.  set cTone 2s bit.

Main10h
        call    SetHang         ; start/restart the hang timer
        call    ChkID           ; test if need an ID now
Main10s                         ; Simplex mode; no hang, no courtesy tone.
        goto    ChkTmrs         ; done here...

Main2                           ; receiver timedout state
        btfss   group0,0        ; is repeater enabled?
        goto    Main2Off        ; no.  turn receiver off
        btfsc   rxFlag,RX0OPEN  ; is squelch still open?
        goto    ChkTmrs         ; yes, still timed out
Main2Off                        ; end of timeout condition.
        movlw   RXSOFF          ; timeout condition ended, get new state (off)
        movwf   rx0Stat         ; set new receiver state
        btfsc   group1,6        ; simplex mode?
        goto    Main2Sx         ; yes
        btfsc   group2,4        ; is voice timeout message enabled?
        goto    Main2TO         ; yes...
        PAGE3                   ; select code page 3.
        movlw   CW_TO           ; get CW timeout message.
        call    PlayCW          ; play CW message.
        PAGE0                   ; select code page 1.
        goto    ChkTmrs         ; done here...
Main2Sx
        movlw   VSIMPLX         ; get simplex message
        goto    Main2Py         ; play it
Main2TO 
        movlw   VTIMOUT         ; time out message
Main2Py 
        call    NewPlay         ; play message
        goto    ChkTmrs         ; seems redundant, but it ain't

Main3                           ; record with rptr disabled state.
        btfss   rxFlag,RX0OPEN  ; is squelch open?
        goto    Main3Off        ; no, on->off transition
        goto    ChkTmrs         ; 

Main3Off                        ; receiver was active, became inactive
        bsf     PORTA,RX0AUD    ; mute it...
        movlw   RXSOFF          ; get new state (off)
        movwf   rx0Stat         ; set new receiver state

        btfss   isdFlag,ISDRECF ; is the ISD recording?
        goto    Main3OK         ; nope. must have timed out.
        ;; the ISD is recording, send the STOP command
        movlw   ICMDST          ; get STOP command
        call    QISDCmd         ; enqueue the STOP command.
        
Main3OK
        ;; done recording -- Play the OK message.
        PAGE3                   ; select ROM page 3.
        movlw   CW_OK           ; get CW OK
        call    PlayCW          ; start playback
        PAGE0                   ; select ROM page 0.
        goto    ChkTmrs         ; seems redundant, but it ain't

Main4
        ;; receiver active with repeater disabled,
        ;; ID BEACON MODE enabled.
        ;; NO CW ID MODE enabled.
        ;; 1.12

        btfsc   rxFlag,RX0OPEN  ; is squelch open?
        goto    ChkTmrs         ; yes, still open.
        ;; COR has gone away.
        movlw   RXSOFF          ; COR on to off transition, get new state (off)
        movwf   rx0Stat         ; set new receiver state
        call    ChkID           ; test if need an ID now
        goto    ChkTmrs         ; done here.
        
ChkTmrs                         ; check timers here.
        goto    Ck10mS          ; skip one ms timer.
        ;; start with one-millisecond timers
        btfss   tFlags,ONEMS    ; is one-millisecond bit set?
        goto    Ck10mS          ; nope.
        ;; one-millisecond tick active.
        
Ck10mS                          ; check 10 millisecond timers
        btfss   tFlags,TENMS    ; is ten-millisecond bit set?
        goto    Ck100mS         ; nope.
        ;; ten millisecond tick active.
        movf    pulsTmr,f       ; check for pulsed output
        btfsc   STATUS,Z        ; is it zero?
        goto    PulsEnd         ; yep.
        decfsz  pulsTmr,f       ; decrement and check for zero.
        goto    PulsEnd         ; not zero yet.
        
        movf    group4,w        ; get digout pulse control.
        andlw   b'00000011'     ; mask leaves 2 digital output control bits.
        xorlw   h'ff'           ; invert.
        andwf   group5,f        ; update the port.
        PAGE2                   ; select page 2
        call    SetDig          ; set the digital outputs themselves
        PAGE0                   ; select code page 0.
PulsEnd                         ; done with IO output pulse logic

Ck100mS                         ; check 100 millisecond tick.
        btfss   tFlags,HUNDMS   ; is 100 millisecond bit set?
        goto    Ck1S            ; nope.
        ;; 100 millisecond tick active.
        ;; check hang timer.
        movf    hangTmr,f       ; check hang timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NoHang          ; yes, not hang active, continue

        ;; 1.03 change here.
        ;; don't decrement hang timer if ID is running.
        movf    txFlag,w        ; get txFlag.
        andlw   b'10100000'     ; mask CWPLAY TALKING
        btfss   STATUS,Z        ; is result zero?
        goto    NoHang          ; no.  One of the sources is active.
        ;; end of 1.03 change

        movf    hangTmr,w       ; get hang timer
        subwf   hangDly,w       ; w = hangDly - hangTmr(w) (amount hang used)
        sublw   d'05'           ; subtract .5 seconds
        btfss   STATUS,Z        ; skip if result is 0
        goto    HangNob         ; not 0...don't beep.
        ;; check to see if there is something already playing
        movf    txFlag,w        ; get txFlag
        andlw   b'10110000'     ; and txFlag with (CW or ISD or DTMF)
        btfsc   STATUS,Z        ; is the result zero?
        goto    HangCT          ; yes, ok to play CT.
        bsf     flags,DEF_CT    ; set defer CT flag.
        goto    HangNob         ; don't beep now.
        
        ;;  bag the beep, CW, ISD or DTMF is playing.

        ;; select courtesy tone here.
HangCT
        incf    cTone,w         ; check cTone for FF
        btfsc   STATUS,Z        ; is result 0?
        goto    HangNob         ; yes, cTone was FF.
        btfss   group0,6        ; is courtesy tone enabled?
        goto    HangNob         ; courtesy tone disabled.
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        btfsc   dtRFlag,DT0UNLK ; is this port (main receiver) unlocked?
        movwf   cTone           ; yep. set unlocked courtesy tone.

        PAGE3                   ; select code page 3.
        call    PlayCT          ; play courtesy tone #w
        PAGE0                   ; select code page 0.

HangNob                         ; hanging without a beep
        decfsz  hangTmr,f       ; decrement and check if now zero
        goto    NoHang          ; not zero
        ;; end of hang time. hang timer timed out.
        bcf     txFlag,TXHANG   ; turn off hang time flag
        ;; euro mode check
        btfss   group3,0        ; in European mode?
        goto    USMode          ; nope.
        ;; euro mode ID playing
        ;; 1.06 euro ID mode test...
        btfss   group3,1        ; Euro Mode Tail Drop Normal Speech ID set?
        call    DoIDCW          ; no.  Play CW ID.
        btfsc   group3,1        ; Euro Mode Tail Drop Normal Speech ID set?
        call    DoIDNor         ; yep.  Play speech ID.
        ;; end of 1.06 change
        goto    NoHang          ; end of euro mode change

USMode
        movf    txFlag,f        ; check tXflag for zero.
        btfss   STATUS,Z        ; is it zero?
        goto    NoHang          ; no.  txFlag is not zero

        ;; check tail message
        movf    tailCtr,f       ; check.
        btfsc   STATUS,Z        ; skip if tailCtr not zero.
        goto    NoHang          ; tailCtr is zero.
        decfsz  tailCtr,f       ; decrement tailCtr, skip if now zero.
        goto    NoHang          ; not zero
        ;; tail message time.
        call    DoTail          ; play tail message.
        
NoHang                          ; done with hang timer...
        ;; process DTMF muting timer...
        movf    muteTmr,f       ; test mute timer
        btfsc   STATUS,Z        ; Z is set if not DTMF muting
        goto    NoMutTm         ; muteTmr is zero.
        decfsz  muteTmr,f       ; decrement muteTmr
        goto    NoMutTm         ; have not reached the end of the mute time
        btfsc   txFlag,RX0OPEN  ; is receiver 0 unsquelched
        bcf     PORTA,RX0AUD    ; unmute it...

NoMutTm                         ; done with muting timer...
Ck1S                            ; check 1-second flag bit.
        btfss   tFlags,ONESEC   ; is one-second flag bit set?
        goto    Ck10S           ; nope.
        ;; 1-second tick active.
        movf    unlkTmr,f       ; check unlkTmr
        btfsc   STATUS,Z        ; is it zero?
        goto    NoULTmr         ; yes, don't worry about it.
        decfsz  unlkTmr,f       ; no, decrement it.
        goto    NoULTmr         ; still not zero.
        ;; unlkTmr counted down to zero, lock controller.
        movlw   b'00011111'     ; mask:  clear unlocked bits.
        andwf   dtRFlag,f       ; and with dtRFlag: clear unlocked bits.

NoULTmr                         ; unlocked timer is zero.
        
Ck10S                           ; check 10-second tick flag bit.
        btfss   tFlags,TENSEC   ; is ten-second flag bit set?
        goto    NoTimr          ; nope.  no more timers to test.
        movf    idTmr,f
        btfsc   STATUS,Z        ; is idTmr 0
        goto    NoIDTmr         ; yes...
        decfsz  idTmr,f         ; decrement ID timer
        goto    NoIDTmr         ; not zero yet...
        call    DoID            ; id timer decremented to zero, play the ID
NoIDTmr                         ; process more 10 second timers here...
        movf    fanTmr,f        ; check fan timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NoFanTm         ; yes.
        btfss   group2,5        ; fan mode configured?
        goto    NoFanTm         ; no
        decfsz  fanTmr,f        ; decrement fan timer
        goto    NoFanTm         ; not zero yet
        bcf     PORTB,FANCTL    ; turn off fan
NoFanTm
        ;; 
        movf    dtATmr,f        ; check DTMF access timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    NoDTATm         ; yes
        decfsz  dtATmr,f        ; decrement DTMF access timer
        goto    NoDTATm         ; not zero yet.
        ;;  
        
NoDTATm
		IFDEF NHRC3_1
        movf    alrmTmr,f       ; check alarm announce timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NoAlTmr         ; yes.
        decfsz  alrmTmr,f       ; decrement the alarm announce timer.
        goto    NoAlTmr         ; still not zero
        movlw   VALARM          ; get alarm announce message.
        call    NewPlay         ; play the alarm message.

        ;; now, reset alarm announce timer
        movlw   EEALARM         ; get EEPROM address of alarm timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   alrmTmr         ; preset tail message counter.
		ENDIF
NoAlTmr 
        
NoTimr                          ; no more timers to test.
        

ChkTx                           ; check if transmitter should be on
        movf    txFlag,f        ; check txFlag
        btfsc   STATUS,Z        ; skip if not zero
        goto    ChkTx0          ; it's zero, turn off transmitter
        btfsc   flags,TXONFLG   ; skip if not already on
        goto    ChkTxE          ; done here
        PAGE3                   ; select code page 1.
        call    PTTon           ; turn on transmitter (will set TXONFLG)
        PAGE0                   ; select code page 0.
        goto    ChkTxE          ; now done here.
        
ChkTx0
        btfss   flags,TXONFLG   ; skip if tx is on
        goto    ChkTxE          ; was already off
        PAGE3                   ; select code page 1.
        call    PTToff          ; turn off PTT
        PAGE0                   ; select code page 0.
ChkTxE                          ; end of ChkTx

; ***************
; ** CW SENDER ** 
; ***************
CWSendr
        btfss   txFlag,CWPLAY   ; sending CW?
        goto    NoCW            ; nope

        btfss   tFlags,ONEMS    ; is this a one-ms tick?
        goto    NoCW            ; nope.

        decfsz  cwTbTmr,f       ; decrement CW timebase counter
        goto    NoCW            ; not zero yet.

        movf    cwSpeed,w       ; get CW timebase preset.
        movwf   cwTbTmr         ; preset CW timebase.

        decfsz  cwTmr,f         ; decrement CW element timer
        goto    NoCW            ; not zero

        btfss   tFlags,CWBEEP   ; was "key" down? 
        goto    CWKeyUp         ; nope
                                ; key was down
        bcf     tFlags,CWBEEP   ; 
        ; turn off beep here.
        clrw                    ; clear W.
        PAGE3                   ; select code page 3.
        call    SetTone         ; set the beep tone up.
        PAGE0                   ; select code page 0.
        decf    cwByte,w        ; test CW byte to see if 1
        btfsc   STATUS,Z        ; was it 1 (Z set if cwByte == 1)
        goto    CWNext          ; it was 1...
        movlw   CWIESP          ; get cw inter-element space
        movwf   cwTmr           ; preset cw timer
        goto    NoCW            ; done with this pass...

CWNext                          ; get next character of message
        PAGE3                   ; select code page 1.
        call    GtBeep          ; get the next cw character
        PAGE0                   ; select code page 0.
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
        bsf     tFlags,CWBEEP   ; turn key->down
        movf    cwTone,w        ; get CW tone
        ;; turn on beep here.
        PAGE3                   ; select code page 3.
        call    SetTone         ; set the beep tone up.
        PAGE0                   ; select code page 0.
        rrf     cwByte,f        ; rotate cw bitmap
        bcf     cwByte,7        ; clear the MSB
        goto    NoCW            ; done with this pass...

CWDone                          ; done sending CW
        bcf     txFlag,CWPLAY   ; turn off CW flag
        btfss   flags,IDNOW     ; was this an ID message?
        goto    CWDone1         ; no
        bcf     flags,needID    ; don't need to ID now.
        bcf     flags,IDNOW     ; not sending ID any more, either.
        bcf     flags,DEF_ID    ; clear deferred ID flag
        
CWDone1
        clrf    beepCtl         ; clear beep control flags

NoCW
CasEnd
CkTone
        btfss   tFlags,HUNDMS   ; check the DTMF timers every 100 msec.
        goto    TonDone         ; not 100 MS tick.
CkDt0   
        movf    dt0Tmr,f        ; check for zero...
        btfsc   STATUS,Z        ; is it zero
        goto    TonDone         ; yes
        decfsz  dt0Tmr,f        ; decrement timer
        goto    TonDone         ; not zero yet
        bsf     dtRFlag,DT0RDY  ; ready to evaluate command.
TonDone
        ;; manage beep timer 
        btfss   tFlags,TENMS    ; is this a 10 ms tick?
        goto    NoTime          ; nope.
        movf    beepTmr,f       ; check beep timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NBeep           ; yes.
        ;goto    NoTime         ; yes.
BeepTic                         ; a valid beep tick.
        decfsz  beepTmr,f       ; decrement beepTmr
        goto    NoTime          ; not zero yet.
        PAGE3                   ; select code page 3.
        call    GetBeep         ; get the next beep tone...
        PAGE0                   ; select code page 0.
        goto    NoTime          ; done here.
NBeep                           ; verify that beeping is really over. HACK.
        movf    cwTmr,f         ; check cwTmr.
        btfss   STATUS,Z        ; is it zero?
        goto    NoTime          ; no.
        movf    beepCtl,f       ; check this.
        btfsc   STATUS,Z        ; is it zero?
        goto    NoTime          ; yes.
        PAGE3                   ; select code page 3.
        call    GetBeep         ; get the next beep tone...
        PAGE0                   ; select code page 0.

NoTime
        movf    tFlags,f        ; evaluate tFlags
        btfss   STATUS,Z        ; skip if ZERO
        goto    LoopEnd
        ;; no timing flags were set...
        ;; likely some excess, available CPU cycles here.
        ;; evaluate DTMF buffers...
PfxDT0
        ;; evaluate DTMF 0 buffer for command
        btfsc   dtRFlag,DTSEVAL ; is a command being interpreted now?
        goto    DTEval          ; yes, don't look at the DTMF buffers right now
        btfss   dtRFlag,DT0RDY  ; is a command ready to evaluate?
        goto    XPfxDT          ; no command waiting.
        ;; copy command from dtmf rx buf to command interpreter input buffer.
        movlw   low dt0buf0     ; get address of this dtmf receiver's buffer
        movwf   FSR             ; store.
        movf    dt0Ptr,w        ; get command size...
        movwf   cmdSize         ; save it.
        call    CpyDTMF         ; copy the command...
        movf    dt0Ptr,w        ; get command size back, CpyDTMF clobbers.
        movwf   cmdSize         ; save it.
        clrf    dt0Ptr          ; make ready to receive again.
        clrf    dtEFlag         ; start evaluating from first prefix.
        bsf     dtEFlag,DT0CMD  ; command from DTMF-0.
        bsf     dtRFlag,DTSEVAL ; set evaluate DTMF bit.
        btfsc   dtRFlag,DT0UNLK ; port 0 unlocked?
        bsf     dtRFlag,DTUL    ; this port is unlocked.
        bcf     dtRFlag,DT0RDY  ; reset DTMF ready bit.
        goto    DTEval          ; go and evaluate the command right now.

XPfxDT
        goto    LoopEnd
        
DTEval                          ; evaluate DTMF command in command buffer
        btfsc   dtRFlag,DTUL    ; is this command from an unlocked port?
        goto    DTEvalU         ; yep.

        ;; evaluate the command in the buffer against the contents of eeprom.
        movlw   low cmdbf00     ; get command buffer address
        movwf   FSR             ; set pointer
        movf    dtEFlag,w       ; get dtEFlag.
        andlw   b'00011111'     ; mask out control bits.
        movwf   temp            ; set prefix index.
        movlw   EEPFL           ; max number of digits in prefix.
        movwf   temp2           ; save max number of digits to look at.
        movf    temp,w          ; get prefix index.
        movwf   eeAddr          ; set EEPROM address low byte
        bcf     STATUS,C        ; clear carry bit
        rlf     eeAddr,f        ; rotate (x2)
        rlf     eeAddr,f        ; rotate (x4 this time)
        rlf     eeAddr,f        ; rotate (x8 now)
        movlw   EEPFB           ; get EEPROM base address for prefix 0
        addwf   eeAddr,f        ; add to offset.
        ;; now have address of base of selected prefix.
DTEval1
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   temp3           ; save retrieved byte
        sublw   h'ff'           ; subtract FF.
        btfsc   STATUS,Z        ; skip if temp3 was NOT FF.
        goto    DTEvalY         ; value was FF, end of valid prefix. process.
        movf    temp3,w         ; get back real value for retrieved byte.
        subwf   INDF,w          ; subtract bytes.
        btfss   STATUS,Z        ; skip if they were the same.
        goto    DTEvalN         ; them bytes were not equal.
        decfsz  temp2,f         ; decrease number of bytes to scan
        goto    DTEnext         ; go evaluate next byte.
        goto    DTEvalN         ; go on to next prefix.
DTEnext                         ; evaluate next byte.
        incf    eeAddr,f        ; move to the next EEPROM byte.
        incf    FSR,f           ; move to the next cmdbuf byte.
        goto    DTEval1         ; look at the next prefix
        
DTEvalN                         ; was not this prefix.
        incf    dtEFlag,f       ; move to next prefix
        movf    dtEFlag,w       ; get dtEFlag.
        andlw   b'00011111'     ; mask out control bits.
        sublw   EEPFC           ; subtract number of last prefix.
        btfsc   STATUS,Z        ; is result 0? (all prefixes checked)
        goto    DTEdone         ; it's zero, done evaluating.
        goto    LoopEnd         ; continue.

DTEvalY                         ; HEY! it is this prefix!
        ;; temp has the prefix number.
        ;; EEPFL - temp2 is the index of the first byte after the prefix.
        movf    temp2,w         ; get temp2 value.
        sublw   EEPFL           ; w = EEPFL - w
        subwf   cmdSize,f       ; get corrected cmdSize
        ;; cmdSize has the number of bytes left in the command.
        PAGE1                   ; select code page 1.
        call    LCmd            ; process the locked command
        PAGE0                   ; select code page 0.
        goto    DTEdone         ; done evaluating.
        
DTEvalU                         ; evaluate unlocked DTMF command.
        PAGE2                   ; select code page 2.
        call    UlCmd           ; evaluate the unlocked command.
        PAGE0                   ; select code page 0.
        goto    DTEdone         ; done evaluating.

DTEdone                         ; done evaluating DTMF commands.
        clrf    dtEFlag         ; yes.  reset evaluate DTMF flags.
        bcf     dtRFlag,DTSEVAL ; done evaluating.
        bcf     dtRFlag,DTUL    ; so we don't care about unlocked anymore.
        
LoopEnd
        btfsc   mscFlag,SC_RDY  ; is serial command ready?
        call    SCProc          ; yes. Process Serial Command.

FanCtl
        ;; fan/control output control.
        btfsc   group2,5        ; is fan control enabled?
        goto    LoopE1          ; yes.
        btfsc   group2,6        ; is digital output on?
        bsf     PORTB,FANCTL    ; yes, turn on control output.
        btfss   group2,6        ; is digital output off?
        bcf     PORTB,FANCTL    ; yes, turn off control output.
LoopE1
        goto    Loop0

; *************
; ** CpyDTMF **
; *************
        ;; copy a DTMF command from the DTMF receive buffer
        ;; pointed at by FSR into the DTMF command interpreter buffer.
        ;; terminate the DTMF command interpreter buffer with FF.
CpyDTMF                         ; copy DTMF from cmd buffer to xmit buffer
        bsf     flags,CMD_NIB   ; start with high nibble of DTMF buffer.
        movf    FSR,w           ; get FSR
        movwf   temp            ; preserve this
        movlw   low cmdbf00     ; get address of command buffer
        movwf   temp3           ; set buffer pointer
CpyDtLp
        movf    temp,w          ; get address of RX byte
        movwf   FSR             ; set rx buffer pointer
        movf    INDF,w          ; get byte
        movwf   temp2           ; save byte
        movf    temp3,w         ; get xmit buffer address pointer
        movwf   FSR             ; set pointer
        btfss   flags,CMD_NIB   ; is high nibble next victim
        goto    CpyDLow         ; low nibble is victim
        swapf   temp2,w         ; get high nibble
        bcf     flags,CMD_NIB   ; select low nibble next
        goto    CpyDBth         ; keep copying...
CpyDLow
        bsf     flags,CMD_NIB   ; high nibble is next
        incf    temp,f          ; increment DTMF rx address
        movf    temp2,w         ; get low nibble
CpyDBth
        andlw   b'00001111'     ; mask low nibble
        movwf   INDF            ; save digit
        incf    temp3,f         ; increment pointer (for next time)
        decfsz  cmdSize,f       ; decrement cmdSize
        goto    CpyDtLp         ; not zero yet...
        incf    FSR,f           ; zero, write the FF at the end
        movlw   h'ff'           ; end of DTMF message
        movwf   INDF            ; mark end of DTMF
        return                  ;


        
; ************
; ** SCProc **
; ************
        ;; process a serial command.
SCProc                          ; process serial command
        clrf    temp2           ; clear checksum.
        movlw   rxBuf00         ; get address of receive buffer.
        movwf   FSR             ; set pointer.
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movf    INDF,w          ; get byte from buffer
        addwf   temp2,f         ; add to checksum.
        xorlw   SCREAD          ; compare to read character.
        btfsc   STATUS,Z        ; is result zero?
        goto    SCRead          ; yes.
        movf    INDF,w          ; get byte from buffer
        xorlw   SCWRITE         ; compare to read character.
        btfss   STATUS,Z        ; is result zero?
        goto    SCEnd           ; no.

SCWrite                         ; write data into EEPROM
        call    CIVGetB         ; get a byte value from 2 chars in buffer
        movwf   eeAddr          ; save the address.

        movlw   h'8'            ; transfer size
        movwf   eeCount         ; save number of bytes to write.
        movwf   temp6           ; save to counter.

        movlw   low eebuf00     ; get address of eeprom write buffer.
        movwf   temp5           ; save it.

SCWLoop
        call    CIVGetB         ; get byte from CI-V.
        call    CIVPutB         ; save the byte.
        decfsz  temp6,f         ; decrement byte counter.
        goto    SCWLoop         ; loop some more.
        movf    temp2,w         ; get checksum.
        movwf   temp4           ; save in temp4...

        call    CIVGetB         ; get checksum byte.
        subwf   temp4,w         ; compare checksum byte to calculated.
        btfss   STATUS,Z        ; is the checksum good?
        goto    SCSNAK          ; nope.

        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF

        movlw   low eebuf00     ; get base of buffer.
        movwf   FSR             ; set into FSR.
        PAGE3                   ; select code page 3.
        call    WriteEE         ; save the data into the EEPROM.
        PAGE0                   ; select code page 0.

        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movlw   SCACK           ; ACK message
        call    SerOut          ; send it.
        movlw   SCCR            ; <CR>
        call    SerOut          ; send it.
        movlw   SCLF            ; <LF>
        call    SerOut          ; send it.
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        bcf     mscFlag,SC_RDY  ; clear serial data ready flag.
        return                  ; done.
        
SCSNAK                          ; send NAK message.
        movlw   SCNAK           ; NAK message
        call    SerOut          ; send it.
        movlw   SCCR            ; <CR>
        call    SerOut          ; send it.
        movlw   SCLF            ; <LF>
        call    SerOut          ; send it.
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        bcf     mscFlag,SC_RDY  ; clear serial data ready flag.
        return                  ; done.
                
SCRead                          ; read EEPROM data...
        call    CIVGetB         ; read the address.
        movwf   eeAddr          ; save the address.
        incf    FSR,F           ; move pointer.
        movf    INDF,w          ; get next byte
        xorlw   SCTERM          ; compare to command terminator
        btfss   STATUS,Z        ; is it a zero?
        goto    SCEnd           ; nope.  not a valid command.
        movf    temp,w          ; get address back.
        andlw   h'03'           ; low 3 bits should all be zero.
        btfss   STATUS,Z        ; is result zero?
        goto    SCEnd           ; no.
        
        movlw   d'8'            ; number of bytes to transfer.
        movwf   temp3           ; save counter.
        clrf    temp2           ; clear checksum counter.

        movlw   SCATTN          ; get attention character.
        call    SerOut          ; send it.
        movlw   SCWRITE         ; get WRITE command character.
        addwf   temp2,f         ; add to checksum.
        call    SerOut          ; send it.

        movf    temp,w          ; get address back.
        call    SndByte         ; send the address byte.

SCReadL
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.

        call    SndByte         ; send it.
        incf    eeAddr,f        ; move to next eeprom address.
        decfsz  temp3,f         ; decrement counter.
        goto    SCReadL         ; loop around.

        movf    temp2,w         ; get checksum.
        call    SndByte         ; send checksum.

        movlw   h'0d'           ; <CR>
        call    SerOut          ; send it
        movlw   h'0a'           ; <LF>
        call    SerOut          ; send it
        ;; fall through to SCEnd.

SCEnd                           ; done looking at serial command.
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        bcf     mscFlag,SC_RDY  ; clear serial data ready flag.
        return

; *************
; ** CIVGetB **
; *************
CIVGetB                         ; get byte from 2 nibbles in CIV buffer.
        ;; modifies checksum in temp2
        ;; uses temp.  returns with result in temp and in W.
        incf    FSR,f           ; move to next byte.
        movf    INDF,w          ; get byte.
        addwf   temp2,f         ; add to checksum.
        call    DeHex           ; convert from printable.
        movwf   temp            ; save hi nibble.
        swapf   temp,f          ; swap bytes.
        
        incf    FSR,f           ; move to next byte.
        movf    INDF,w          ; get byte.
        addwf   temp2,f         ; add to checksum
        call    DeHex           ; convert from printable
        iorwf   temp,f          ; save lo nibble.
        movf    temp,w          ; put into w for convenience.
        return                  ; done.

; ***********
; ** DeHex **
; ***********
DeHex                           ; convert from printable to actual
        andlw   h'7f'           ; make semi-reasonable.
        movwf   temp3           ; save.
        btfsc   temp3,6         ; is it a letter?
        goto    DeHexL          ; yes.
        andlw   h'0f'           ; not a letter.
        return                  ; done
DeHexL                          ; it is a letter.
        andlw   h'07'           ; mask.
        addlw   h'09'           ; add.
        andlw   h'0f'           ; mask to valid.
        return

; *************
; ** SndByte **
; *************
SndByte                         ; send byte in w as 2 hex digits.
        movwf   temp            ; save it.
        swapf   temp,w          ; swap nibbles.
        andlw   h'0f'           ; mask.
        call    GetHex          ; get hex digit.
        addwf   temp2,f         ; add to checksum.
        call    SerOut          ; send it.
        movf    temp,w          ; get back byte.
        andlw   h'0f'           ; mask.
        call    GetHex          ; get hex digit. 
        addwf   temp2,f         ; add to checksum.
        call    SerOut          ; send it.
        return                  ; done.

; ************
; ** GetHex **
; ************
GetHex                          ; get a hex digit for a number in w.
        movwf   temp4           ; save it.
        sublw   d'9'            ; w = 9 - w.
        btfss   STATUS,C        ; is result negative?
        goto    GetHex1         ; yes
        movf    temp4,w         ; get number back.
        addlw   h'30'           ; make into printable digit.
        return                  ; done.
GetHex1
        movf    temp4,w         ; get number back.
        addlw   d'55'           ; make into printable digit.
        return                  ; done.

                
; *************
; ** CIVPutB **
; *************
CIVPutB                         ; put byte in temp into the EEPROM write buffer.
        movf    FSR,w           ; get FSR for CI-V receive buffer.
        movwf   temp4           ; save CIV RX buffer FSR.
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        movf    temp5,w         ; get FSR for EEPROM write buffer.
        movwf   FSR             ; set FSR.
        movf    temp,w          ; get data byte.
        movwf   INDF            ; save data byte to EEPROM write buffer.
        incf    temp5,f         ; increment EEPROM write buffer address.
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movf    temp4,w         ; get back old FSR
        movwf   FSR             ; restore old FSR
        return                  ; done.

; ************
; ** SerOut **
; ************
SerOut                          ; send the character in w out the serial port.
        ;; uses temp5, temp6
        ;; first, disable interrupts.
        bcf     INTCON,GIE      ; disable interrupts
        btfsc   INTCON,GIE      ; test interrupts still enabled?
        goto    SerOut          ; still enabled, retry disable.
        ;; next put the character into the buffer.
        movwf   temp5           ; save character.
        movf    FSR,w           ; get old FSR.
        movwf   temp6           ; save old FSR.
        incf    txHead,w        ; get pointer + 1.
        andlw   h'1f'           ; mask so result stays in 0-31 range.
        movwf   txHead          ; save it...
        addlw   LOW txBuf00     ; add to buffer base address.
        movwf   FSR             ; set FSR as pointer
        movf    temp5,w         ; get word back
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movwf   INDF            ; save byte into buffer
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        movf    temp6,w         ; get back old FSR
        movwf   FSR             ; restore old FSR
        ;; then, turn on the serial port transmitter.
        bsf     STATUS,RP0      ; select bank 1
        bsf     PIE1,TXIE       ; turn off the transmitter interrupt.
        bcf     STATUS,RP0      ; select bank 0
        ;; last, turn interrupts back on so character gets sent.
        bsf     INTCON,GIE      ; turn interrupts on.
        return
        
; ************
; ** NewPlay **
; ************
NewPlay 
        iorlw   ICMDPL          ; or in play command.
        movwf   temp4           ; save this
        movlw   IDLY50          ; 50 ms delay
        call    QISDCmd         ; enqueue the delay command.
        movf    temp4,w         ; get temp back
        call    QISDCmd         ; enqueue the play command.
        bsf     txFlag,TALKING  ; set talking state
        return

; *************
; ** QISDCmd **
; *************
QISDCmd                         ; enqueue isd command from W
        movwf   temp5           ; save character.
        xorlw   ICMDST          ; compare with STOP command
        btfss   STATUS,Z        ; it result zero?
        goto    QISDC2          ; no.
        ;; this is a special case for the STOP command.
        ;; never mind waiting for an interrupt or time delay. just stop.
        clrf    isdDly          ; clear the delay timer
        bcf     ismpcf,ISMWINT  ; turn off wait for interrupt flag
        bcf     ismpcf,ISMWAIT  ; turn off wait for delay timer flag
        ;; empty the queue by resetting the head and tail indices
        clrf    isdcbh          ; reset tail to zero
        clrf    isdcbt          ; reset head to zero
QISDC2
        movf    FSR,w           ; get old FSR.
        movwf   temp6           ; save old FSR.
        incf    isdcbh,w        ; get head pointer + 1.
        andlw   h'07'           ; mask so result stays in 0-7 range.
        movwf   isdcbh          ; save it...
        addlw   LOW isdcb00     ; add to buffer base address.
        movwf   FSR             ; set FSR as pointer
        movf    temp5,w         ; get word back
        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movwf   INDF            ; save byte into buffer
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        movf    temp6,w         ; get back old FSR
        movwf   FSR             ; restore old FSR
        return

        
; ************************************************************************
; ****************************** ROM PAGE 1 ******************************
; ************************************************************************
        org     0800            ; page 1

LCmd
        movlw   high LTable     ; set high byte of address
        movwf   PCLATH          ; select page
        movf    temp,w          ; get prefix index number.
        andlw   h'07'           ; restrict to reasonable range
        addwf   PCL,f           ; add w to PCL

LTable                          ; jump table for locked commands.
        goto    LCmd0           ; prefix 00 -- control operator
        goto    LCmd1           ; prefix 01 -- DTMF access
        goto    LCmd2           ; prefix 02 -- digital output control
        goto    LCmd3           ; prefix 03 -- load saved setup
        goto    LCmd4           ; prefix 04 -- audio test -- NHRC-3.1 only
        goto    LCmd5           ; prefix 05 -- reset alarm -- NHRC-3.1 only
        goto    LCmd6           ; prefix 06 -- reserved
        goto    LCmd7           ; prefix 07 -- unlock

; ***********
; ** LCmd0 **
; ***********
LCmd0                           ; control operator switches
        btfss   group0,7        ; CTCSS required?
        goto    LCmd0x          ; no.
        btfss   mscFlag,CTCSS0  ; was CTCSS on?
        return                  ; do nothing quietly.

LCmd0x                          ; actually do it.
        movlw   d'2'            ; minimum command length
        subwf   cmdSize,w       ; w = cmdSize - w
        btfss   STATUS,C        ; skip if result is non-negative (cmdsize >= 2)
        return                  ; not enough command digits. fail quietly.
        movf    cmdSize,w       ; get command size
        sublw   d'3'            ; get max command length
        btfss   STATUS,C        ; skip if result is non-negative (cmdSize <= 3)
        return                  ; too many command digits. Fail quietly.

        movf    INDF,w          ; get Group byte
        movwf   temp2           ; save group byte.
        sublw   d'5'            ; w = 7-w.
        btfss   STATUS,C        ; skip if w is not negative
        return                  ; bad, bad user tried to enter invalid group.
        ;; check access to change that group.
        movf    temp2,w         ; get group number 0-7.
        PAGE3
        call    GetMask         ; get bitmask for that group.
        PAGE1
        ;; now have bit representing group number in w.
        andwf   group7,w        ; and with enabled groups mask.
        btfsc   STATUS,Z        ; zero if group is disabled.
        return                  ; quietly do nothing.
        incf    FSR,f           ; move to next byte (bit #)
        decf    cmdSize,f       ; decrement command size.
        movf    INDF,w          ; get Item byte (bit #)
        movwf   temp            ; save it.
        incf    FSR,f           ; move to next byte (state)
        decf    cmdSize,f       ; decrement command size.

        sublw   d'7'            ; w = 7-w.
        btfss   STATUS,C        ; skip if w is not negative
        return                  ; bad, bad user tried to enter invalid item.
        PAGE2                   ; select code page 2.
        goto    CtlOpC          ; execute control op command

; ***********
; ** LCmd1 **
; ***********
LCmd1                           ; DTMF access mode
        btfss   group0,5        ; check to see if DTMF access mode is enabled.
        return                  ; it's not.
        decfsz  cmdSize,w       ; check for one command digit.
        return                  ; not one command digit.
        movf    INDF,f          ; get command digit.
        btfsc   STATUS,Z        ; is it zero?
        goto    LCmd10          ; yes.
        decfsz  INDF,w          ; check for one.
        return                  ; it's not one.

        movlw   EETDTA          ; get EEPROM address of DTMF access timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        movwf   dtATmr          ; set DTMF access mode timer.
        PAGE1                   ; select code page 1.
        return

LCmd10                          ; turn off DTMF access mode.
        movf    dtATmr,f        ; check for zero.
        btfsc   STATUS,Z        ; is it zero.
        return                  ; it is zero, do nothing.
        clrf    dtATmr          ; make it zero.
        return

; ***********
; ** LCmd2 **
; ***********
LCmd2
        movf    cmdSize,w       ; get command size
        btfsc   STATUS,Z        ; skip if not zero.
        return                  ; fail quietly.
        movf    INDF,w          ; get command digit.
        incf    FSR,f           ; move to next byte (bit #)
        movwf   temp2           ; save command digit.
        btfsc   STATUS,Z        ; skip if not zero.
        goto    LCmdErr         ; zero is not allowed.
        sublw   d'4'            ; highest value.
        btfss   STATUS,C        ; skip if result is non-negative.
        goto    LCmdErr         ; was bigger than 4.
        movf    temp2,w         ; get value back.
        ;addlw  d'3'            ; get bit number.
        movwf   temp            ; temp now has actual bit number.
        movlw   d'5'            ; ctl op group of digital outputs.
        movwf   temp2           ; save group # in temp 2.
        PAGE2                   ; select code page 2.
        goto    CtlOpC          ; execute control op command
                        
; ***********
; ** LCmd3 **
; ***********
LCmd3                           ; load saved state.
        decfsz  cmdSize,w       ; is this 1?
        return                  ; nope.
        movf    INDF,w          ; get command digit.
        sublw   EENSS           ; subtract 4
        btfss   STATUS,C        ; was result negative?
        return                  ; yes.
        movf    INDF,w          ; get command digit.
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        PAGE1                   ; select code page 1.
        goto    LCmdOK

; ***********
; ** LCmd4 **
; ***********
LCmd4                           ; audio test
        IFDEF NHRC3_1
        bsf     isdFlag,ISDTEST ; set the ISDTEST bit
        movlw   VTEST           ; get test message number.
        movwf   isdRMsg         ; save message number.

        PAGE0                   ; select code page 3
        iorlw   ICMDDEL         ; make into erase command
        call    QISDCmd         ; enqueue the erase command.
        PAGE1                   ; select code page 2
        
        bsf     isdFlag,ISDRECR ; set record mode flag
        goto    LCmdOK          ; send the OK message
        ELSE
        return                  ; do nothing
        ENDIF

; ***********
; ** LCmd5 **
; ***********
LCmd5                           ; reset alarm -- NHRC-3.1 only
        IFDEF NHRC3_1
        bcf     mscFlag,ALARMED ; reset alarmed flag
        clrf    alrmTmr         ; clear alarm announcement timer
        goto    LCmdOK
        ELSE
        return                  ; do nothing
        ENDIF

; ***********
; ** LCmd6 **
; ***********
LCmd6                           ; Not Implemented
        return                  ; do nothing.

; ***********
; ** LCmd7 **
; ***********
LCmd7                           ; unlock
        movf    dtEFlag,w       ; get eval flags
        andlw   b'11100000'     ; mask all except command source indicators.
        iorwf   dtRFlag,f       ; IOR with dtRFlag: set unlocked bit.
        movlw   UNLKDLY         ; get unlocked mode timer.
        movwf   unlkTmr         ; set unlocked mode timer.
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        movwf   cTone           ; yep. set unlocked courtesy tone.
        goto    LCmdOK          ; send OK.
        return                  ; do nothing.

; *************
; ** LCmdErr **
; *************
LCmdErr
        PAGE3                   ; select code page 3.
        movlw   CW_ERR          ; get CW ERR
        call    PlayCW          ; start playback
        PAGE1                   ; select code page 1.
        return

; ************
; ** LCmdOK **
; ************
LCmdOK
        PAGE3                   ; select code page 3.
        movlw   CW_OK           ; get CW OK
        call    PlayCW          ; start playback
        PAGE1                   ; select code page 1.
        return

; ************************************************************************
; ****************************** ROM PAGE 2 ******************************
; ************************************************************************
        org     1000            ; page 2
        
; ***********
; ** UlCmd **
; ***********
UlCmd                           ; process an Unlocked Command!
        movlw   UNLKDLY         ; get unlocked mode timeout time.
        movwf   unlkTmr         ; set unlocked mode timer.
        movlw   CTUNLOK         ; get the unlocked courtesy tone.
        movwf   cTone           ; save the courtesy tone.
        movlw   low cmdbf00     ; get command buffer address
        movwf   FSR             ; set pointer
        movf    INDF,w          ; get cmd byte
        sublw   h'0e'           ; subtract e (* key)
        btfsc   STATUS,Z        ; is result zero? (* is first tone)
        goto    UlStar          ; yes.

        movf    INDF,w          ; get cmd byte
        sublw   h'0f'           ; subtract f (# key)
        btfss   STATUS,Z        ; is result zero? (# is first tone)
        goto    UlCmdNG         ; nope.
        ;; lock command.
        movf    dtEFlag,w       ; get eval flags
        andlw   b'11100000'     ; mask all except command source indicators.
        xorlw   b'11111111'     ; invert bitmask
        andwf   dtRFlag,f       ; and with dtRFlag: clear unlocked bit.
        clrf    unlkTmr         ; reset unlocked mode timer.
        movlw   CTNONE          ; select no courtesy tone.
        movwf   cTone           ; set courtesy tone.
        goto    UlCmdOK         ; play OK message.
        return                  ; done.
        
UlStar                          ; process '*' command.
        incf    FSR,f           ; increment cmd pointer
        movf    INDF,w          ; 2nd byte
        movwf   temp            ; save it.
        incf    FSR,f           ; increment cmd pointer
        decf    cmdSize,f       ; decrement command size
        decf    cmdSize,f       ; decrement command size again (-2) 
        movlw   high ULTable    ; set high byte of address
        movwf   PCLATH          ; select page
        movf    temp,w          ; get command byte.
        andlw   h'0f'           ; restrict to reasonable range
        addwf   PCL,f           ; add w to PCL
        ;; jump table goes here...
ULTable
        goto    UlCmd0          ; command *0 -- control op group
        goto    UlCmd1          ; command *1 -- save setup
        goto    UlCmd2          ; command *2 -- program prefixes
        goto    UlCmd3          ; command *3 -- program timers
        goto    UlCmd4          ; command *4 -- patch setup
        goto    UlCmd5          ; command *5 -- autodial setup
        goto    UlCmd6          ; command *6 -- user commands setup
        goto    UlCmd7          ; command *7 -- program/play CW/Tones
        goto    UlCmd8          ; command *8 -- play/record voice message
        goto    UlCmd9          ; command *9 -- reserved (program ee byte)
        goto    UlCmdA          ; command *a -- invalid command
        goto    UlCmdB          ; command *b -- invalid command
        goto    UlCmdC          ; command *c -- invalid command
        goto    UlCmdD          ; command *d -- invalid command
        goto    UlCmdE          ; command *e -- crash and burn
        goto    UlCmdF          ; command *f -- invalid command

; ************
; ** UlCmd0 **
; ************
        ;; set a control operator Group/Item to a specified state.
UlCmd0                          ; Control Op Group command
        movlw   d'2'            ; minimum command length
        subwf   cmdSize,w       ; w = cmdSize - w
        btfss   STATUS,C        ; skip if result is non-negative (cmdsize >= 2)
        goto    UlCmdNG         ; not enough command digits.
        movf    cmdSize,w       ; get command size
        sublw   d'3'            ; get max command length
        btfss   STATUS,C        ; skip if result is non-negative (cmdSize <= 3)
        goto    UlCmdNG         ; too many command digits.

        movf    INDF,w          ; get Group byte
        movwf   temp2           ; save group byte.
        sublw   d'9'            ; w = 9-w.
        btfss   STATUS,C        ; skip if w is not negative
        goto    UlCmdNG         ; bad, bad user tried to enter invalid group.
        incf    FSR,f           ; move to next byte (bit #)
        decf    cmdSize,f       ; decrement command size.
        movf    INDF,w          ; get Item byte (bit #)
        movwf   temp            ; save it.
        incf    FSR,f           ; move to next byte (state)
        decf    cmdSize,f       ; decrement command size.

        sublw   d'7'            ; w = 7-w.
        btfss   STATUS,C        ; skip if w is not negative
        goto    UlCmdNG         ; bad, bad user tried to enter invalid item.

CtlOpC
        PAGE3                   ; select page 3
        movf    temp,w          ; get Item byte
        call    GetMask         ; get bit mask for selected item
        PAGE2                   ; select page 2
        movwf   temp            ; save mask

        movf    cmdSize,f       ; test this for zero (inquiry)
        btfsc   STATUS,Z        ; skip if not 0.
        goto    UlCmd0I         ; it's an inquiry.
        
        movf    INDF,w          ; get state byte
        andlw   b'11111110'     ; only 0 and 1 permitted.
        btfss   STATUS,Z        ; should be zero of 0 or 1 entered
        goto    UlCmdNG         ; not zero, bad command.
        movf    INDF,f          ; get state byte
        btfss   STATUS,Z        ; skip if state is zero
        goto    UlCmd01         ; not zero, must be 1, go do the set.
        ;; clear a bit.
        movlw   low group0      ; get address of 1st group.
        movwf   FSR             ; set FSR to point there.
        movf    temp2,w         ; get group number
        addwf   FSR,f           ; add to address.
        bcf     STATUS,IRP      ; set indirect back to page 0
        movf    temp,w          ; get mask
        xorlw   h'ff'           ; invert mask to clear selected bit
        andwf   INDF,f          ; apply inverted mask
        bsf     STATUS,IRP      ; set indirect pointer into page 1

        movf    temp2,w         ; get index.
        sublw   d'5'            ; check for group5
        btfsc   STATUS,Z        ; is it group5?
        call    SetDig          ; set the digital outputs.
                        
        movlw   CW_OFF          ; get CW OFF message
        PAGE3                   ; select code page 3.
        call    PlayCW          ; send the announcement.
        PAGE2                   ; select code page 2.
        return                  ; done.

UlCmd01                         ; set a bit.
        movlw   low group0      ; get address of ist group.
        movwf   FSR             ; set FSR to point there.
        movf    temp2,w         ; get group number
        addwf   FSR,f           ; add to address.
        bcf     STATUS,IRP      ; set indirect back to page 0
        movf    temp,w          ; get mask
        iorwf   INDF,f          ; or byte with mask.
        bsf     STATUS,IRP      ; set indirect pointer into page 1

        movf    temp2,w         ; get index.
        sublw   d'5'            ; check for group5
        btfss   STATUS,Z        ; is it group5?
        goto    UlCm0ND         ; no.
        call    SetDig          ; set the digital outputs.
        movf    group5,w        ; get group 5.
        andwf   group4,w        ; and with pulsed flags.
        andlw   b'00000011'     ; mask only valid outputs.
        btfsc   STATUS,Z        ; is result non-zero?
        goto    UlCm011         ; no.
        movlw   PULS_TM         ; get pulsed output timer.
        movwf   pulsTmr         ; start pulsed output timer.

UlCm0ND
        call    FixSMsg         ; clear simplex message if there
        
UlCm011                 
        movlw   CW_ON           ; get CW ON message.
        PAGE3                   ; select code page 3.
        call    PlayCW          ; send the announcement.
        PAGE2                   ; select code page 2.
        return                  ; no.

FixSMsg
        btfss   group1,6        ; in simplex mode?
        return
        ;; erase simplex message location.
        PAGE0                   ; select code page 3
        movlw   VSIMPLX         ; get simplex message
        iorlw   ICMDDEL         ; make into erase command
        call    QISDCmd         ; enqueue the erase command.
        PAGE2                   ; select code page 2
        return
SetDig                          ; set digital output pins.
        btfss   group5,0        ; is OUT1 supposed to be on?
        bcf     PORTB,OUT1      ; no
        btfsc   group5,0        ; is OUT1 supposed to be off?
        bsf     PORTB,OUT1      ; no
        btfss   group5,1        ; is OUT2 supposed to be on?
        bcf     PORTB,OUT2      ; no
        btfsc   group5,1        ; is OUT2 supposed to be off?
        bsf     PORTB,OUT2      ; no
        return                  ; done
        
UlCmd0I                         ; inquiry mode.
        movlw   low group0      ; get address of ist group.
        movwf   FSR             ; set FSR to point there.
        movf    temp2,w         ; get group number
        addwf   FSR,f           ; add to address.
        bcf     STATUS,IRP      ; set indirect back to page 0
        movf    temp,w          ; get mask
        andwf   INDF,w          ; and the mask (in temp) with the field.
        bsf     STATUS,IRP      ; set indirect pointer into page 1

        movlw   CW_ON           ; get CW ON message.
        btfsc   STATUS,Z        ; was result (from and) zero?
        movlw   CW_OFF          ; get CW OFF message.
        PAGE3                   ; select code page 3.
        call    PlayCW          ; send the announcement.
        PAGE2                   ; select code page 2.
        return                  ; done.
                
; ************
; ** UlCmd1 **
; ************
        ;; save control operator Group/Item/States to a specified setup.
UlCmd1                          ; save setups
        btfsc   group6,0        ; is control groups write protected?
        goto    UlCmdNG         ; yes.
        movf    cmdSize,w       ; get command size
        sublw   d'1'            ; subtract expected size
        btfss   STATUS,Z        ; was it the expected size?
        goto    UlCmdNG         ; nope.
        movf    INDF,w          ; get setup number
        sublw   EENSS           ; subtract largest expected
        btfss   STATUS,C        ; is result not negative?
        goto    UlCmdNG         ; nope.
        movlw   EE0B            ; get low part of address
        movwf   eeAddr          ; save low part of address
        swapf   INDF,w          ; magic! get command * 16
        addwf   eeAddr,f        ; now have ee address for saved state.
        movlw   EESSC           ; get the number of bytes to save
        movwf   eeCount         ; set the number of bytes to write.
        movlw   group0          ; get address of first group
        movwf   FSR             ; set pointer
        bcf     STATUS,IRP      ; to page 0.
        PAGE3                   ; select code page 3.
        call    WriteEE         ; save this stuff.
        PAGE2                   ; select code page 2.
        bsf     STATUS,IRP      ; back to page 1.
        goto    UlCmdOK         ; OK.
        
; ************
; ** UlCmd2 **
; ************
        ;; set command prefixes...  
UlCmd2                          ; program prefixes
        btfsc   group6,1        ; are prefixes write protected?
        goto    UlCmdNG         ; yes.
        movlw   d'3'            ; minimum command length
        subwf   cmdSize,w       ; w = cmdSize - w
        btfss   STATUS,C        ; skip if result is non-negative (cmdsize >= 3)
        goto    UlCmdNG         ; not enough command digits.
        movf    cmdSize,w       ; get command size
        sublw   d'9'            ; get max command length
        btfss   STATUS,C        ; skip if result is non-negative (cmdSize <= 9)
        goto    UlCmdNG         ; too many command digits.

        PAGE3                   ; select page 3
        call    GetTens         ; get index tens digit.
        PAGE2                   ; select page 2
        movwf   temp            ; save to prefix index in temp.
        incf    FSR,f           ; move pointer to next address.
        decf    cmdSize,f       ; decrment count of remaining bytes.
        movf    INDF,w          ; get index ones digit.
        addwf   temp,f          ; add to prefix index in temp.
        movf    temp,w          ; get prefix index
        sublw   MAXPFX          ; w = MAXPFX - pfxnum
        btfss   STATUS,C        ; skip if result is non-negative
        goto    UlCmdNG         ; argument error
        decf    cmdSize,f       ; less bytes to process
        incf    FSR,f           ; point at next byte.

        movf    temp,w          ; get index back.
        sublw   MAXPFX          ; subtract index of unlock command.
        btfss   STATUS,Z        ; is result zero?
        goto    UlCmd2P         ; no.

        ;; set the MUTE pin to an input...
        movlw   B'11111111'     ; na/na/in/out/in/in/in/in
        movwf   TRISA           ; set port A data direction

        btfsc   PORTA,INIT      ; skip if init button pressed.
        goto    UlCmdNGx        ; bad command.

        ;; reset the state of the MUTE pin to an output
        movlw   B'11101111'     ; na/na/in/out/in/in/in/in
        movwf   TRISA           ; set port A data direction
        
UlCmd2P                         ; program the new prefix.
        movf    cmdSize,w       ; get command length
        movwf   eeCount         ; save # bytes to write.
        incf    eeCount,f       ; add 1 so FF at end of buffer gets copied.
        movlw   low EEPFB       ; get low address of prefixes
        movwf   eeAddr          ; set eeprom address to base of prefixes
        bcf     STATUS,C        ; clear carry
        rlf     temp,f          ; multiply prefix by 2
        rlf     temp,f          ; multiply prefix by 2 (x4 after)
        rlf     temp,f          ; multiply prefix by 2 (x8 after)
        movf    temp,w          ; get prefix offset
        addwf   eeAddr,f        ; add prefix to base
        PAGE3                   ; select code page 3.
        call    WriteEE         ; write the prefix.
        PAGE2                   ; select code page 2.
        goto    UlCmdOK         ; good command...
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  *3                                                                         ;
;  Set Timers                                                                 ;
;    *3<nn> inquire timer nn                                                  ;
;    *3<nn><time> set timer nn to time                                        ;
;      00 <= nn <= 11  timer index                                            ;
;      0 <= time <= 255 timer preset. 0=disable                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UlCmd3                          ; program timers
        movlw   d'2'            ; minimum command length
        subwf   cmdSize,w       ; w = cmdSize - w
        btfss   STATUS,C        ; skip if result is non-negative (cmdsize >= 2)
        goto    UlCmdNG         ; not enough command digits.

        PAGE3                   ; select page 3
        call    GetTens         ; get timer index tens digit.
        PAGE2                   ; select page 2
        movwf   temp2           ; save
        incf    FSR,f           ; move pointer to next address
        decf    cmdSize,f       ; decrment count of remaining bytes.
        movf    INDF,w          ; get timer index ones digit
        addwf   temp2,f         ; add to timer index
        incf    FSR,f           ; move pointer to next address
        decf    cmdSize,f       ; decrment count of remaining bytes.
        movf    temp2,w         ; get timer index sum
        sublw   LASTTMR         ; subtract last timer index
        btfss   STATUS,C        ; skip if result is non-negative
        goto    UlCmdNG         ; argument error
        movf    temp2,w         ; get timer index
        movwf   eeAddr          ; set EEPROM address low byte
        movf    cmdSize,f       ; check for no more digits.
        btfsc   STATUS,Z        ; skip if not zero.
        goto    UlCmdNG         ; no more digits -- bad command.
        ;; ready to get value then set timer.
        btfsc   group6,2        ; are timers write protected?
        goto    UlCmdNG         ; yes.
        PAGE3                   ; select page 3
        call    GetDNum         ; get decimal number to w. nukes temp3,temp4
        movwf   temp4           ; save decimal number to temp4.
        call    WriteEw         ; write w into EEPROM.
        PAGE2                   ; select page 2
        movf    eeAddr,w        ; get low byte of address
        sublw   EETTAIL         ; subtract tail counter address
        btfss   STATUS,Z        ; skip if result is zero.
        goto    UlCmd3a         ; result is non-zero.
        movlw   d'1'            ; one.
        movwf   tailCtr         ; get tail message on next tail drop.
        goto    UlCmdOK         ; good command
UlCmd3a
        PAGE3                   ; select code page 3
        call    CWParms         ; get CW parameters.
        PAGE2                   ; select code page 2
        goto    UlCmdOK         ; good command.
        
UlCmd4                          ; reserved
        goto    UlCmdNG         ; bad command...
        
UlCmd5                          ; reserved
        goto    UlCmdNG         ; bad command...

UlCmd6                          ; reserved
        goto    UlCmdNG         ; bad command...

; *****************************************************************************
; **   *7                                                                    **
; **   Record/Play CW and Courtesy Tones                                     **
; **    *70 play CW ID                                                       **
; **    *70 <dd..dd..dd..> program cw message n with CW data in dd.dd.dd     **
; **                       see CW encoding table.                            **
; **                                                                         **
; **    *71<n> play courtesy tone n, 0 <= n <= 7 (n is in range 0 to 7)      **
; **    *71<n><ddtt,ddtt...> record courtesy tone n, 0 <= n <= 7             **
; **          dd is duration in 10 ms increments. 01 <= dd <=99              **
; **          tt is tone.  See tone table.  00 <= tt <= 63                   **
; *****************************************************************************
UlCmd7
        movf    cmdSize,f       ; check command size.
        btfsc   STATUS,Z        ; is it zero?
        goto    UlCmdNG         ; not enough command digits.
        movf    INDF,f          ; check command digit for zero.
        btfsc   STATUS,Z        ; is it zero?
        goto    UlCmd70         ; yes.
        decfsz  INDF,w          ; decrement and test.
        goto    UlCmdNG         ; was not 1 either.
UlCmd71                         ; Courtesy Tone Command.
        incf    FSR,f           ; move to next byte.
        decf    cmdSize,f       ; decrement commandSize.
        btfsc   STATUS,Z        ; is result zero?
        goto    UlCmdNG         ; yes. insufficient command digits.
        movf    INDF,w          ; get command digit.
        movwf   temp2           ; save index.
        sublw   d'7'            ; subtract biggest argument.
        btfss   STATUS,C        ; is result non-negative?
        goto    UlCmdNG         ; nope. bad command digit.
        incf    FSR,f           ; move to next byte.
        decf    cmdSize,f       ; decrement commandSize.
        btfss   STATUS,Z        ; is result zero?
        goto    UC71R           ; record CT.
UC71P                           ; play courtesy tone.
        movf    temp2,w         ; get index.
        movwf   cTone           ; save CT index.
        PAGE3                   ; select code page 3.
        call    PlayCT          ; play courtesy tone #w
        PAGE2                   ; select code page 2.
        return                  ; done.

UC71R                           ; record courtesy tone.
        btfsc   group6,6        ; are courtesy tones write protected?
        goto    UlCmdNG         ; yes.
        movlw   low EECTB       ; get EEPROM ctsy tone table base address
        movwf   eeAddr          ; move into EEPROM address low byte
        bcf     STATUS,C        ; clear carry bit.
        rlf     temp2,f         ; multiply msg # by 2
        rlf     temp2,f         ; multiply msg # by 2 (x4 after)
        rlf     temp2,w         ; multiply msg # by 2 (x8 after)
        addwf   eeAddr,f        ; add offset of ctsy tone to ctsy base addr.
        ;; now have eeprom address of CT.
        movlw   b'00000011'     ; mask:  low 2 bits.
        andwf   cmdSize,w       ; check for multiple of 4 only.
        btfss   STATUS,Z        ; is result zero?
        goto    UlCmdNG         ; bad command argument.
        movf    cmdSize,w       ; get command size.
        sublw   d'16'           ; 16 is 8 pairs or 4 tones.
        btfss   STATUS,C        ; check for non-negative.
        goto    UlCmdNG         ; too many command digits.
        movlw   low eebuf00     ; get address of eebuffer.
        movwf   eebPtr          ; set eeprom buffer put pointer
        clrf    eeCount         ; clear count.
UC71RL  
        PAGE3                   ; select page 3
        call    GetCTen         ; get 2-digit argument.
        call    PutEEB          ; put into EEPROM write buffer.
        call    GetCTen         ; get 2-digit argument.
        PAGE2                   ; select code page 2.
        movwf   temp            ; save it.
        movf    cmdSize,f       ; test command size.
        btfss   STATUS,Z        ; any digits left?
        bsf     temp,7          ; yes, set high bit of tone.
        movf    temp,w          ; get temp back
        PAGE3                   ; select page 3
        call    PutEEB          ; put into EEPROM write buffer.
        PAGE2                   ; select code page 2.
        movf    cmdSize,f       ; test command size.
        btfss   STATUS,Z        ; any digits left?
        goto    UC71RL          ; yes. loop around and get the next 4.
        ;; now have whole segment in buffer.
        movlw   low eebuf00     ; get address of eebuffer.
        movwf   FSR             ; set address to write into EEPROM.
        PAGE3                   ; select code page 3.
        call    WriteEE
        PAGE2                   ; back to code page 2.
        goto    UlCmdOK         ; OK.

UlCmd70
        incf    FSR,f           ; move to next byte.
        decfsz  cmdSize,f       ; decrement commandSize.
        goto    UC70R           ; record CW ID.
        movlw   EECWID          ; address of CW ID message in EEPROM.
        movwf   eeAddr          ; save CT base address
        PAGE3                   ; select code page 3.
        call    PlayCWe         ; kick off the CW playback.
        PAGE2                   ; select code page 2.
        return
UC70R                           ; record CW ID.
        btfsc   group6,6        ; are courtesy tones write protected?
        goto    UlCmdNG         ; yes.
        btfsc   cmdSize,0       ; bit 0 should be clear for an even length.
        goto    UlCmdNG         ; bad command argument.
        movlw   low eebuf00     ; get address of eebuffer.
        movwf   eebPtr          ; set eeprom buffer put pointer
        clrf    eeCount         ; clear count.
UC70RL  
        PAGE3                   ; select page 3
        call    GetCTen         ; get 2-digit argument.
        call    GetCW           ; get CW code.
        call    PutEEB          ; put into EEPROM write buffer.
        PAGE2                   ; select code page 2.
        movf    cmdSize,f       ; test cmdSize
        btfss   STATUS,Z        ; skip if it's zero.
        goto    UC70RL          ; loop around.
        
        movlw   h'ff'           ; mark EOM.
        PAGE3                   ; select page 3
        call    PutEEB          ; put into EEPROM write buffer.
        PAGE2                   ; select code page 2.
        movlw   EECWID          ; get CW ID address...
        movwf   eeAddr          ; set EEPROM address...
        movlw   low eebuf00     ; get address of eebuffer.
        movwf   FSR             ; set address to write into EEPROM.
        PAGE3                   ; select code page 3.
        call    WriteEE
        PAGE2                   ; back to code page 2.
        goto    UlCmdOK         ; OK.
        
; ************
; ** UlCmd8 **
; ************
        ;; play/record from ISD...  
UlCmd8                          ; play/record voice messages
        movf    INDF,w          ; get 3rd byte..
        btfsc   STATUS,Z        ; is it zero? (play cmd)
        goto    UlCmd8P         ; play...
        movlw   h'01'           ; get record command
        subwf   INDF,w          ; subtract record command
        btfss   STATUS,Z        ; is it zero?
        goto    UlCmdNG         ; argument error
        ;; 3rd digit was 1, record command
        incf    FSR,f           ; increment command pointer; now at 4th digit
        decf    cmdSize,f       ; decrease command size
        btfsc   STATUS,Z        ; skip if result is not zero.
        goto    UlCmdNG         ; bad command.
        movf    INDF,w          ; get message number.
        sublw   VLAST           ; subtract from max message number.
        btfss   STATUS,C        ; skip if result is non-negative.
        goto    UlCmdNG         ; bad command.
        btfsc   group6,7        ; are voice messages write protected?
        goto    UlCmdNG         ; yes.
        movf    INDF,w          ; get message number.
        movwf   isdRMsg         ; save message number.

        PAGE0                   ; select code page 3
        iorlw   ICMDDEL         ; make into erase command
        call    QISDCmd         ; enqueue the erase command.
        PAGE2                   ; select code page 2
        
        bsf     isdFlag,ISDRECR ; set record mode flag
        goto    UlCmdOK         ; send OK confirmation.
        
UlCmd8P                         ; 3rd digit was 0, playback command
        incf    FSR,f           ; increment command pointer; now at 4th digit
        decf    cmdSize,f       ; decrease command size
        btfsc   STATUS,Z        ; skip if result is not zero.
        goto    UlCmdNG         ; bad command.
        movf    INDF,w          ; get message number.
        sublw   VLAST           ; subtract from max message number.
        btfss   STATUS,C        ; skip if result is non-negative.
        goto    UlCmdNG         ; bad command.
        movf    INDF,w          ; get message number.
        PAGE0                   ; select page 3
        call    NewPlay         ; start playback
        PAGE2                   ; select code page 2.
        return                  ; don't play CW confirmation message, play ISD.
        
UlCmd9                          ; reserved.
UlCmdA                          ; devel cmd *A
UlCmdB                          ; devel cmd *B
UlCmdC                          ; devel cmd *C
UlCmdD                          ; devel cmd *D
        goto    UlCmdNG         ; bad command
        
UlCmdE                          ; devel cmd **, restart controller.
        goto    UlCmdE          ; Loop forever, until restart via wdt timeout.

UlCmdF                          ; devel cmd *
        goto    UlCmdNG         ; bad command
        
UlCmdOK                         ; "OK"
        movlw   CW_OK           ; get CW OK message.
        goto    UlErr           ; finish message.

UlCmdNGx
        ;; reset the state of the MUTE pin to an output
        movlw   B'11101111'     ; na/na/in/out/in/in/in/in
        movwf   TRISA           ; set port A data direction

UlCmdNG                         ; "BAD COMMAND"
        movlw   CW_ERR          ; get ERR message.

UlErr
        PAGE3                   ; select code page 3.
        call    PlayCW          ; play CW
        PAGE2                   ; select code page 2.
        return                  ; done with all this.
        
; ************************************************************************
; ****************************** ROM PAGE 3 ******************************
; ************************************************************************
        org     1800            ; page 3

; ************
; ** PlayCW **
; ************
        ;; play CW from ROM table.  Address in W.
PlayCW
        movwf   temp            ; save CW address.
        ;movf   beepCtl,w       ; get beep control flag.
        ;btfss  STATUS,Z        ; result will be zero if no.
        ;call   KillBeep        ; kill off beep sequence in progress.
        movf    temp,w          ; get back CW address.
        movwf   beepAddr        ; set CW address.
        movlw   CW_ROM          ; CW from the ROM table
        movwf   beepCtl         ; set control flags.
        call    GtBeep          ; get next character.
        movwf   cwByte          ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cwTmr           ; preset cw timer
        bcf     tFlags,CWBEEP   ; make sure that beep is off
        bsf     txFlag,CWPLAY   ; turn on CW sender
        call    PTTon           ; turn on PTT...
        return

; ************
; ** PlayCWe**
; ************
        ;; play CW from EEPROM addresses named by eeAddr
PlayCWe
        movf    beepCtl,w       ; get beep control flag.
        andlw   b'00011100'     ; is the beeper already busy?
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBeep        ; kill off beep sequence in progress.
        movf    eeAddr,w        ; get lo byte of address.
        movwf   beepAddr        ; set lo byte of address of beep.
        movlw   CW_EE           ; select CW from EEPROM
        movwf   beepCtl         ; set control flags.
        call    GtBeep          ; get next character.
        movwf   cwByte          ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cwTmr           ; preset cw timer
        bcf     tFlags,CWBEEP   ; make sure that beep is off
        bsf     txFlag,CWPLAY   ; turn on CW sender
        call    PTTon           ; turn on PTT...
        return

; *************
; ** PlayCTx **
; *************
        ;; play a courtesy tone from the ROM table.
        ;; courtesy tone offset in W.
PlayCTx                         ; play a courtesy tone
        movwf   temp            ; save the courtesy tone offset.
        movf    beepCtl,f       ; already beeping?
        btfss   STATUS,Z        ; result will be zero if no.
        return                  ; already beeping.
        movf    temp,w          ; get back courtesy tone offset.
        movwf   beepAddr        ; set beep address lo byte.
        movlw   BEEP_CX         ; CT beep. (from table)
        movwf   beepCtl         ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beepTmr         ; set initial start
        bsf     txFlag,BEEPING  ; beeping is enabled!
        return                  ; done.

; ************
; ** PlayCT **
; ************
        ;; play courtesy tone # cTone from EEPROM.
PlayCT                          ; play a courtesy tone.
        btfsc   cTone,7         ; sleazy easy check for no CT...
        return                  ; courtesy tone is suppressed.
        movf    beepCtl,f       ; already beeping?
        btfss   STATUS,Z        ; result will be zero if no.
        return                  ; already beeping.
        movlw   EECTB           ; get CT base.
        movwf   beepAddr        ; save CT base address.

        movf    cTone,w         ; examine cTone.
        andlw   h'07'           ; force into reasonable range.
        movwf   temp            ; copy to temp.
        bcf     STATUS,C        ; clear carry bit.
        rlf     temp,f          ; multiply msg # by 2
        rlf     temp,f          ; multiply msg # by 2 (x4 after)
        rlf     temp,w          ; multiply msg # by 2 (x8 after)
        addwf   beepAddr,f      ; add offset of ctsy tone to beep base addr.
        ;; now have EEPROM address of CT. reset courtesy tone indicator.
        movlw   CTNONE          ; get no CT indicator.
        movwf   cTone           ; save it.
        movf    beepAddr,w      ; get low byte of EEPROM address.
        movwf   eeAddr          ; set low byte of EEPROM address.

        call    ReadEEw         ; read 1 byte from EEPROM.
        movwf   temp            ; save eeprom data.
        btfss   STATUS,Z        ; is it zero?
        goto    PlayCT1         ; nope.
        movlw   VCTONE          ; get courtesy tone message.
        PAGE0
        call    NewPlay
        PAGE3
        return                  ; done.
PlayCT1
        movlw   BEEP_CT         ; CT beep.
        movwf   beepCtl         ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beepTmr         ; set initial start
        bsf     txFlag,BEEPING  ; beeping is enabled!
        return                  ; done.

; ************** 
; ** KillBeep **
; ************** 
        ;; kill off whatever is beeping now.
KillBeep
        clrf    beepTmr         ; clear beep timer
        clrf    beepCtl         ; clear beep control flags
        clrw                    ; select no tone.
        call    SetTone         ; set the beep tone up.
        return
        
; *************
; ** GetBeep **
; *************
        ;; get the next beep tone from whereever.
        ;; select the tone, etc.
        ;; uses temp.
GetBeep                         ; get the next beep character
        btfsc   beepCtl,B_LAST  ; was the last segment just sent?
        goto    BeepDone        ; yes.  stop beeping.
        call    GtBeep          ; get length byte
        movwf   beepTmr         ; save length
        call    GtBeep          ; get tone byte
        movwf   temp            ; save tone byte
        btfss   temp,7          ; is the continue bit set?
        bsf     beepCtl,B_LAST  ; no. mark this segment last.
        movlw   b'00111111'     ; mask
        andwf   temp,f          ; mask out control bits.
        goto    SetBeep         ; set the beep tone

BeepDone                        ; stop that confounded beeping...
        clrf    temp            ; set quiet beep
        bcf     txFlag,BEEPING  ; beeping is done...
        btfsc   txFlag,TALKING  ; don't turn off audio gate if talking.
        goto    SetBeep         ; talking, don't turn off audio gate.
        clrf    beepCtl         ; clear beep control flags
        clrf    beepTmr         ; clear beep timer

SetBeep
        movf    temp,w          ; get beep tone.
        call    SetTone         ; set the beep tone up.
        return

GtBeep                          ; get the next character for the beep message
        movf    beepCtl,w       ; get control flag bits
        andlw   b'00000011'     ; mask significant control flag bits.
        movwf   temp            ; save w
        movlw   high GtBpTbl    ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        addwf   PCL,f           ; add w to PCL
        
GtBpTbl
        goto    GtBEE           ; get beep char from EEPROM
        goto    GtBROM          ; get beep char from hardcoded ROM table
        goto    GtBRAM          ; get beep char from RAM address
        goto    GtBDT           ; get beep from address in DTMF receive buffer
        
GtBEE                           ; get beep char from EEPROM
        movf    beepAddr,w      ; get lo byte of EEPROM address
        movwf   eeAddr          ; store to EEPROM address lo byte
        incf    beepAddr,f      ; increment pointer
        call    ReadEEw         ; read 1 byte from EEPROM
        return                  ;
GtBROM                          ; get beep char from ROM table
        movf    beepAddr,w      ; get address low byte (hi is not used here)
        incf    beepAddr,f      ; increment pointer
        call    MesgTabl        ; get char from table
        return                  ;
GtBRAM                          ; get beep char from RAM
        movf    beepAddr,w      ; get address low byte (hi is not used here)
        movwf   FSR             ; set indirect register pointer
        incf    beepAddr,f      ; increment pointer
        movf    INDF,w          ; get data byte from RAM
        return                  ; 

GtBDT                           ; get beep char from DTMF rx buffer address
        ;; currently not implemented.
        movlw   h'ff'           ; immediate end of message!
        return

; ***********
; ** PTTon **
; ***********
        ;; turn on PTT & set up ID timer, etc., if needed.
PTTon                           ; key the transmitter
        btfsc   flags,TXONFLG   ; is transmitter already on?
        return                  ; yep.
        bsf     PORTC,TX0PTT    ; tx was not on, turn it on
        bsf     flags,TXONFLG   ; set last tx state flag
        movf    idTmr,f         ; check ID timer
        btfsc   STATUS,Z        ; is it zero?
        goto    PTTinit         ; yes.  use initial ID.
        btfsc   flags,needID    ; is needID already set?
        goto    PTTfan          ; yes...
        goto    PTTset          ; no, set ID timer and needID
PTTinit                         ;
        ;; this would be a good spot to defeat the initial ID logic
        bsf     flags,initID    ; ID timer was zero, set initial ID flag
PTTset  
        bsf     flags,needID    ; need to ID...
        movlw   EETID           ; get address of ID timer
        movwf   eeAddr          ; set address of ID timer
        call    ReadEEw         ; get byte from EEPROM
        movwf   idTmr           ; store to down-counter
PTTfan  
        btfss   group2,5        ; is fan control enabled?
        return                  ; no.
        clrf    fanTmr          ; disable fan timer, fan stays on.
        bsf     PORTB,FANCTL    ; turn on fan
        return                  ; done here

; ************
; ** PTToff **
; ************
PTToff
        ;; don't care if already off, turn off again. (can't hurt)
        bcf     PORTC,TX0PTT    ; turn off main PTT!
        bcf     flags,TXONFLG   ; clear last tx state flag
        btfss   group2,5        ; is fan control enabled?
        return                  ; no.
        movlw   EETFAN          ; get EEPROM address of ID timer preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        movwf   fanTmr          ; set fan timer
        btfsc   STATUS,Z        ; is fan timer zero?
        bcf     PORTB,FANCTL    ; yes, turn off fan now.
        return

; ************
; ** ReadEE **
; ************
        ;; read eeCount bytes from the EEPROM 
        ;; starting at location in eeAddr.
        ;; starting at FSR.
ReadEE                          ; read EEPROM.
        movf    eeCount,f       ; check this for zero
        btfsc   STATUS,Z        ; is it zero?
        return                  ; yes, do nothing here!
ReadEEd
        call    ReadEEw         ; read EEPROM.
        movwf   INDF            ; save read byte.
        incf    eeAddr,f        ; increment EEPROM address.
        incf    FSR,f           ; increment memory address.
        decfsz  eeCount,f       ; decrement count of bytes to read.
        goto    ReadEEd         ; loop around and read another byte.
        return                  ; read the requested bytes, return

; *************
; ** ReadEEw **
; *************
        ;; read 1 bytes from the EEPROM 
        ;; from location in eeAddr into W
ReadEEw                         ; read EEPROM.
        bcf     INTCON,GIE      ; disable interrupts
        btfsc   INTCON,GIE      ; interrupts successfully disabled?
        goto    ReadEEw         ; no,  try again.
        movf    eeAddr,w        ; get eeprom address.
        bsf     STATUS,RP1      ; select register page.
        bcf     STATUS,RP0      ; select register page.
        movwf   EEADR           ; write EEADR.
        bsf     STATUS,RP0      ; select register page.
        bcf     EECON1,EEPGD    ; select DATA memory.
        bsf     EECON1,RD       ; read EEPROM.
        bcf     STATUS,RP0      ; select register page.
        movf    EEDATA,w        ; get EEPROM data.
        bcf     STATUS,RP1      ; select register page.
        bsf     INTCON,GIE      ; enable interrupts
        return                  ; read the requested bytes, return

; *************
; ** WriteEE **
; *************
        ;; write eeCount bytes to the EEPROM 
        ;; starting at location in eeAddr from location
        ;; starting at FSR.
        ;; cannot write more than 32 bytes.  cannot cross 32 byte paragraphs.
WriteEE                         ; write EEPROM.
        movf    eeCount,f       ; check this for zero
        btfsc   STATUS,Z        ; is it zero?
        return                  ; yes, do nothing here!

WrEELp
        movf    INDF,w          ; get data byte to write.
        call    WriteEw         ; write the byte.
        incf    FSR,f           ; increment RAM address in FSR.
        incf    eeAddr,f        ; increment EEPROM address.
        decfsz  eeCount,f       ; decrement count of bytes to write, test for 0
        goto    WrEELp          ; not zero, keep looping.
        return                  ; wrote the requested bytes, done, so return

; *************
; ** WriteEw **
; *************
        ;; write 1 byte from w into the EEPROM 
        ;; at location in eeAddr
        ;; stomps on temp3.
WriteEw                         ; write EEPROM.
        movwf   temp3           ; save the value to write.
WritEd
        bcf     INTCON,GIE      ; disable interrupts
        btfsc   INTCON,GIE      ; interrupts successfully disabled?
        goto    WritEd          ; nope.  Try again.
        movf    eeAddr,w        ; get address.
        bsf     STATUS,RP1      ; select register page.
        bcf     STATUS,RP0      ; select register page.
        movwf   EEADR           ; set address.
        bcf     STATUS,RP1      ; select register page.
        movf    temp3,w         ; get data.
        bsf     STATUS,RP1      ; select register page.
        movwf   EEDATA          ; set data.
        bsf     STATUS,RP0      ; select register page.
        bcf     EECON1,EEPGD    ; select data EEPROM.
        bsf     EECON1,WREN     ; enable writes.
        movlw   h'55'           ; magic value.
        movwf   EECON2          ; write magic value.
        movlw   h'AA'           ; magic value.
        movwf   EECON2          ; write magic value.
        bsf     EECON1,WR       ; start write cycle.
        clrwdt                  ; clear watchdog.
        bsf     EECON1,WREN     ; disable writes.
WriteEl                         ; loop until EEPROM written.
        btfsc   EECON1,WR       ; done writing?
        goto    WriteEl         ; nope. keep waiting.
        bcf     STATUS,RP0      ; select register page.
        bcf     STATUS,RP1      ; select register page.
        bsf     INTCON,GIE      ; enable interrupts
        return                  ; wrote the requested bytes, done, so return

        
; ************************************************
; ** Load control operator settings from EEPROM **
; ************************************************
LoadCtl                         ; load the control operator saved groups
                                ; from "macro" set contained in w.
        movwf   temp            ; save group number
        movlw   EE0B            ; yes, get address of set zero.
        movwf   eeAddr          ; save address.
        swapf   temp,w          ; magic multiply by 16!
        addwf   eeAddr,f        ; add computed offset to eeAddr.
        movlw   EESSC           ; get the number of bytes to read.
        movwf   eeCount         ; set the number of bytes to read.
        movlw   group0          ; get address of first group
        movwf   FSR             ; set pointer
        bcf     STATUS,IRP      ; to page 0.
        call    ReadEE          ; read bytes from EEPROM.
        bsf     STATUS,IRP      ; back to page 1.
        PAGE2                   ; select page 2
        call    SetDig          ; set the digital outputs themselves
        call    FixSMsg         ; clear the simplex message, if need be.
        PAGE3                   ; select code page 0.
        return                  ; done.
        
; *************
; ** GetDNum **
; *************
        ;; get a decimal number from the bytes pointed at by fsr.
        ;; there can be 1, 2, or 3 bytes.  The bytes will always be
        ;; terminated by FF.  return result in w.
        ;; this routine destroys the values in temp3 and temp4
GetDNum
        clrf    temp3           ; clear temp resul.
        movf    cmdSize,w       ; get command length
        movwf   temp4           ; save it.
        btfsc   STATUS,Z        ; no digits to parse?
        goto    GetDN99         ; yes.
        decf    temp4,f         ; decrement it
        btfsc   STATUS,Z        ; was it 1?
        goto    GetDN1          ; yep.
        decf    temp4,f         ; decrement it
        btfsc   STATUS,Z        ; was it 2?
        goto    GetDN2          ; yep.
        decf    temp4,f         ; decrement it
        btfss   STATUS,Z        ; was it 3?
        goto    GetDN99         ; no.
        ;; get hundreds digit
        call    Get100s         ; get hundreds
        addwf   temp3,f         ; add it.
        incf    FSR,f           ; move pointer to next command byte.
        decf    cmdSize,f       ; decrement command size.
GetDN2  ;; get tens digit
        call    GetTens         ; get the value of the tens
        addwf   temp3,f         ; add the tens to the running count
        incf    FSR,f           ; move pointer to next command byte.
        decf    cmdSize,f       ; decrement command size.
GetDN1  ;; get ones digit
        movf    INDF,w          ; get last digit...
        addwf   temp3,f         ; add it.
        incf    FSR,f           ; move pointer to next command byte.
        decf    cmdSize,f       ; decrement command size.
GetDN99 ;; no digits left
        movf    temp3,w         ; get temp result.
        return                  ; really done.


GetCTen
        call    GetTens         ; get tens digit.
        movwf   temp6           ; save
        incf    FSR,f           ; move pointer to next address
        decf    cmdSize,f       ; decrement count of remaining bytes.
        movf    INDF,w          ; get ones digit
        addwf   temp6,f         ; add to timer index
        incf    FSR,f           ; move pointer to next address
        decf    cmdSize,f       ; decrement count of remaining bytes.
        movf    temp6,w         ; get result.
        return                  ; done.

; ************
; ** PutEEB **
; ************
PutEEB                          ; put byte in w into EEPROM buffer.
        movwf   temp5           ; save byte.
        movf    FSR,w           ; get FSR.
        movwf   temp6           ; save it.
        movf    eebPtr,w        ; get address of eebuffer.
        movwf   FSR             ; set FSR.
        movf    temp5,w         ; get value.
        movwf   INDF            ; write into eebuffer.
        incf    eebPtr,f        ; increment eebuffer pointer.
        incf    eeCount,f       ; increment count to write.
        movf    temp6,w         ; get saved FSR.
        movwf   FSR             ; restore FSR.
        return


; ************
; ** Mult10 **
; ************
Mult10
        ;; multiply w by 10, return in w
        movwf   temp5           ; save it.
        movwf   temp6           ; save it.
        addlw   h'0'            ; clear carry.
        rlf     temp6,f         ; temp6 = temp6 * 2
        rlf     temp6,f         ; temp6 = temp6 * 4
        rlf     temp6,w         ; w = temp * 8
        addwf   temp5,w         ; w = w + temp5
        addwf   temp5,w         ; w = w + temp5 (really now temp3 * 10)
        return                  ; returns with w*10 in w.

; ************
; ** MsgNum **
; ************
MsgNum                          ; set up message addresses
        IFDEF NHRC3_1
        andlw   b'00000111'     ; mask to only 0-7 valid
        ELSE
        andlw   b'00000011'     ; mask to only 0-3 valid
        ENDIF
        movwf   isdMsg          ; save message number.
        call    GetIS1          ; get ISD message start address byte 1
        movwf   isdS1           ; save it
        call    GetIS2          ; get ISD message start address byte 2
        movwf   isdS2           ; save it

        btfss   group1,6        ; in simplex mode?
        goto    MsgNumN         ; no.
        movlw   VLAST           ; use last message slot for simplex end
        movwf   isdMsg          ; use this as the last slot number

MsgNumN
        call    GetIE1          ; get ISD message  end  address byte 1
        movwf   isdE1           ; save it
        call    GetIE2          ; get ISD message  end  address byte 2
        movwf   isdE2           ; save it
        return
                
; *************
; ** ISDCmd2 **
; *************
        ;;  send 2 byte command to ISD.
        ;; 1st byte is in W
        ;; 2nd byte is always zero
ISDCmd2 
        bcf     PORTB,ISDSEL    ; select the ISD
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0lo           ; save ISD status register 0
        movlw   H'00'           ; 2nd byte of ISD command
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0hi           ; save ISD status register 0
        bsf     PORTB,ISDSEL    ; deselect the ISD
        return                  ; done.

; *************
; ** ISDCmd3 **
; *************
        ;; send 3 byte command to ISD.
        ;; used only for WR_APC2 command
        ;; 1st byte is in W
        ;; 2nd byte is in isdS1
        ;; 3rd byte is in isdS2
ISDCmd3
        bcf     PORTB,ISDSEL    ; select the ISD
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0lo           ; save ISD status register 0
        movf    isdS1,w         ; 1st byte of APC payload
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0hi           ; save ISD status register 0
        movf    isdS2,w         ; 2nd byte of APC payload
        call    SendSPI         ; send & receive from the SPI
        movwf   sr1lo           ; save ISD status register 0
        bsf     PORTB,ISDSEL    ; deselect the ISD
        return                  ; done.

; *************
; ** ISDCmd7 **
; *************
        ;; send 7 byte command to ISD.
        ;; used for SET_PLAY and SET_REC commands.
        ;; 1st byte is in isdCmd
        ;; 2nd byte is always zero
        ;; 3rd byte is in isdS1
        ;; 4th byte is in isdS2
        ;; 5th byte is in isdE1
        ;; 6th byte is in isdE2
        ;; 7th byte is always zero
ISDCmd7
        ;; select ISD
        bcf     PORTB,ISDSEL    ; select the ISD
        ;; byte 1
        movf    isdCmd,w        ; get byte 1, the command byte
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0lo           ; save ISD status register 0 lo byte
        ;; byte 2
        clrw                    ; byte 2 is zero
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0hi           ; save ISD status register 0 hi byte
        ;; byte 3
        movf    isdS1,w         ; get byte 3, 1st start address byte
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0lo           ; save ISD status register 0 lo byte
        ;; byte 4
        movf    isdS2,w         ; get byte 4, 2nd start address byte
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0hi           ; save ISD status register 0 hi byte
        ;; byte 5
        movf    isdE1,w         ; get byte 3, 1st  end  address byte
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0lo           ; save ISD status register 0 lo byte
        ;; byte 6
        movf    isdE2,w         ; get byte 4, 2nd  end  address byte
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0hi           ; save ISD status register 0 hi byte
        ;; byte 7
        clrw                    ; byte 7 is always zero
        call    SendSPI         ; send & receive from the SPI
        movwf   sr0lo           ; save ISD status register 0
        ;; deselect ISD
        bsf     PORTB,ISDSEL    ; deselect the ISD
        return                  ; done.

; *************
; ** SendSPI **
; *************
        ;; send the byte in W out the SPI.
        ;; wait for the transmission to complete.
        ;; return byte received from SPI in W.
SendSPI                         ; send a byte out the SPI
        movwf   SSPBUF          ; output the byte in the W register
        bsf     STATUS,RP0      ; select page 1
WaitSPI          
        btfss   SSPSTAT,BF      ; is byte transmission complete?
        goto    WaitSPI         ; nope
        bcf     STATUS,RP0      ; select page 0
        movf    SSPBUF,w        ; save received byte in W
        return

; ******************************
; ** ROM Table Fetches follow **
; ******************************

        org     h'1c00'
; ***********
; ** GetCW **
; ***********
        ;; get a cw bitmask from a phone pad letter number.
GetCW                           ; get tone byte from table
        movwf   temp            ; save w
        movlw   high CWTbl      ; set page 
        movwf   PCLATH          ; select page
        bcf     temp,7          ; force into 0-127 range for safety.
        movf    temp,w          ; get tone into w
        addwf   PCL,f           ; add w to PCL
CWTbl
        retlw   h'3f'           ; 00 0
        retlw   h'3e'           ; 01 1
        retlw   h'3c'           ; 02 2
        retlw   h'38'           ; 03 3
        retlw   h'30'           ; 04 4
        retlw   h'20'           ; 05 5
        retlw   h'21'           ; 06 6
        retlw   h'23'           ; 07 7
        retlw   h'27'           ; 08 8
        retlw   h'2f'           ; 09 9
        retlw   h'00'           ; 10
        retlw   h'00'           ; 11 space
        retlw   h'29'           ; 12 /
        retlw   h'2a'           ; 13 ar
        retlw   h'31'           ; 14 bt
        retlw   h'58'           ; 15 sk
        retlw   h'00'           ; 16
        retlw   h'00'           ; 17
        retlw   h'00'           ; 18
        retlw   h'00'           ; 19
        retlw   h'00'           ; 20
        retlw   h'06'           ; 21 a
        retlw   h'11'           ; 22 b 
        retlw   h'15'           ; 23 c
        retlw   h'00'           ; 24
        retlw   h'00'           ; 25 
        retlw   h'00'           ; 26
        retlw   h'00'           ; 27
        retlw   h'00'           ; 28
        retlw   h'00'           ; 29
        retlw   h'00'           ; 30
        retlw   h'09'           ; 31 d
        retlw   h'02'           ; 32 e
        retlw   h'14'           ; 33 f
        retlw   h'00'           ; 34
        retlw   h'00'           ; 35
        retlw   h'00'           ; 36
        retlw   h'00'           ; 37
        retlw   h'00'           ; 38
        retlw   h'00'           ; 39
        retlw   h'00'           ; 40
        retlw   h'0b'           ; 41 g
        retlw   h'10'           ; 42 h
        retlw   h'04'           ; 43 i
        retlw   h'00'           ; 44
        retlw   h'00'           ; 45
        retlw   h'00'           ; 46
        retlw   h'00'           ; 47
        retlw   h'00'           ; 48
        retlw   h'00'           ; 49
        retlw   h'00'           ; 50
        retlw   h'1e'           ; 51 j
        retlw   h'0d'           ; 52 k
        retlw   h'12'           ; 53 l
        retlw   h'00'           ; 54
        retlw   h'00'           ; 55
        retlw   h'00'           ; 56
        retlw   h'00'           ; 57
        retlw   h'00'           ; 58
        retlw   h'00'           ; 59
        retlw   h'00'           ; 60
        retlw   h'07'           ; 61 m
        retlw   h'05'           ; 62 n
        retlw   h'0f'           ; 63 o
        retlw   h'00'           ; 64
        retlw   h'00'           ; 65
        retlw   h'00'           ; 66
        retlw   h'00'           ; 67
        retlw   h'00'           ; 68
        retlw   h'00'           ; 69
        retlw   h'1b'           ; 70 q
        retlw   h'16'           ; 71 p
        retlw   h'0a'           ; 72 r
        retlw   h'08'           ; 73 s
        retlw   h'00'           ; 74
        retlw   h'00'           ; 75
        retlw   h'00'           ; 76
        retlw   h'00'           ; 77
        retlw   h'00'           ; 78
        retlw   h'00'           ; 79
        retlw   h'00'           ; 80
        retlw   h'03'           ; 81 t
        retlw   h'0c'           ; 82 u
        retlw   h'18'           ; 83 v
        retlw   h'00'           ; 84
        retlw   h'00'           ; 85
        retlw   h'00'           ; 86
        retlw   h'00'           ; 87
        retlw   h'00'           ; 88
        retlw   h'00'           ; 89
        retlw   h'13'           ; 90 z
        retlw   h'0e'           ; 91 w
        retlw   h'19'           ; 92 x
        retlw   h'1d'           ; 93 y
        retlw   h'00'           ; 94
        retlw   h'00'           ; 95
        retlw   h'00'           ; 96
        retlw   h'00'           ; 97
        retlw   h'00'           ; 98
        retlw   h'00'           ; 99
        retlw   h'00'           ; 100 -- all after 99 are a result of laziness.
        retlw   h'00'           ; 101
        retlw   h'00'           ; 102
        retlw   h'00'           ; 103
        retlw   h'00'           ; 104
        retlw   h'00'           ; 105
        retlw   h'00'           ; 106
        retlw   h'00'           ; 107
        retlw   h'00'           ; 108
        retlw   h'00'           ; 109
        retlw   h'00'           ; 110
        retlw   h'00'           ; 111
        retlw   h'00'           ; 112
        retlw   h'00'           ; 113
        retlw   h'00'           ; 114
        retlw   h'00'           ; 115
        retlw   h'00'           ; 116
        retlw   h'00'           ; 117
        retlw   h'00'           ; 118
        retlw   h'00'           ; 119
        retlw   h'00'           ; 120
        retlw   h'00'           ; 121
        retlw   h'00'           ; 122
        retlw   h'00'           ; 123
        retlw   h'00'           ; 124
        retlw   h'00'           ; 125
        retlw   h'00'           ; 126
        retlw   h'00'           ; 127

; *************
; ** GetCWD  **
; *************
        ;; get CW Delay 
GetCWD                          ; get cw delay from table
        movwf   temp            ; save addr.
        movlw   high CWDTbl     ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get speed into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
CWDTbl
        retlw   d'240'          ;  0 -- use 5 WPM
        retlw   d'240'          ;  1 -- use 5 WPM
        retlw   d'240'          ;  2 -- use 5 WPM
        retlw   d'240'          ;  3 -- use 5 WPM
        retlw   d'240'          ;  4 -- use 5 WPM
        retlw   d'240'          ;  5 WPM
        retlw   d'200'          ;  6
        retlw   d'171'          ;  7
        retlw   d'150'          ;  8
        retlw   d'133'          ;  9
        retlw   d'120'          ; 10
        retlw   d'109'          ; 11
        retlw   d'100'          ; 12
        retlw   d'92'           ; 13
        retlw   d'86'           ; 14
        retlw   d'80'           ; 15
        retlw   d'75'           ; 16
        retlw   d'71'           ; 17
        retlw   d'67'           ; 18
        retlw   d'63'           ; 19
        retlw   d'60'           ; 20
        retlw   d'57'           ; 21
        retlw   d'55'           ; 22
        retlw   d'52'           ; 23
        retlw   d'50'           ; 24
        retlw   d'48'           ; 25
        retlw   d'46'           ; 26
        retlw   d'44'           ; 27
        retlw   d'43'           ; 28
        retlw   d'41'           ; 29
        retlw   d'40'           ; 30
        retlw   d'40'           ; 31 - use 30 WPM

        IFDEF NHRC3_1

; *************************************************
; ** GetIS1 -- get 1st byte of ISD start address **
; *************************************************
GetIS1
        movlw   high GetIS1t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000111'     ; mask to only 0-7 valid
        addwf   PCL,f           ; add w to PCL
GetIS1t
        retlw   h'08'
        retlw   h'00'
        retlw   h'0f'
        retlw   h'07'
        retlw   h'0b'
        retlw   h'03'
        retlw   h'0d'
        retlw   h'05'

; *************************************************
; ** GetIS2 -- get 2nd byte of ISD start address **
; *************************************************
GetIS2
        movlw   high GetIS2t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000111'     ; mask to only 0-7 valid
        addwf   PCL,f           ; add w to PCL
GetIS2t
        retlw   h'00'
        retlw   h'80'
        retlw   h'80'
        retlw   h'40'
        retlw   h'c0'
        retlw   h'20'
        retlw   h'a0'
        retlw   h'60'

; *************************************************
; ** GetIE1 -- get 1st byte of ISD  end  address **
; *************************************************
GetIE1
        movlw   high GetIE1t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000111'     ; mask to only 0-7 valid
        addwf   PCL,f           ; add w to PCL
GetIE1t
        retlw   h'ff'
        retlw   h'f7'
        retlw   h'fb'
        retlw   h'f3'
        retlw   h'fd'
        retlw   h'f5'
        retlw   h'f9'
        retlw   h'f1'

; *************************************************
; ** GetIE2 -- get 2nd byte of ISD  end  address **
; *************************************************
GetIE2
        movlw   high GetIE2t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000111'     ; mask to only 0-7 valid
        addwf   PCL,f           ; add w to PCL
GetIE2t
        retlw   h'00'
        retlw   h'80'
        retlw   h'40'
        retlw   h'c0'
        retlw   h'20'
        retlw   h'a0'
        retlw   h'60'
        retlw   h'e0'

        ELSE

; *************************************************
; ** GetIS1 -- get 1st byte of ISD start address **
; *************************************************
GetIS1
        movlw   high GetIS1t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000011'     ; mask to only 0-3 valid
        addwf   PCL,f           ; add w to PCL
GetIS1t
        retlw   h'08'
        retlw   h'0a'
        retlw   h'09'
        retlw   h'0b'

; *************************************************
; ** GetIS2 -- get 2nd byte of ISD start address **
; *************************************************
GetIS2
        movlw   high GetIS2t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000011'     ; mask to only 0-3 valid
        addwf   PCL,f           ; add w to PCL
GetIS2t
        retlw   h'00'
        retlw   h'00'
        retlw   h'00'
        retlw   h'00'

; *************************************************
; ** GetIE1 -- get 1st byte of ISD  end  address **
; *************************************************
GetIE1
        movlw   high GetIE1t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000011'     ; mask to only 0-3 valid
        addwf   PCL,f           ; add w to PCL
GetIE1t
        retlw   h'f2'
        retlw   h'f1'
        retlw   h'f3'
        retlw   h'f0'

; *************************************************
; ** GetIE2 -- get 2nd byte of ISD  end  address **
; *************************************************
GetIE2
        movlw   high GetIE2t    ; set page 
        movwf   PCLATH          ; select page
        movf    isdMsg,w        ; get ISD message number
        andlw   b'00000011'     ; mask to only 0-3 valid
        addwf   PCL,f           ; add w to PCL
GetIE2t
        retlw   h'00'
        retlw   h'00'
        retlw   h'00'
        retlw   h'80'

        ENDIF

        org     h'1d00'
InitDat
        movwf   temp            ; save addr.
        movlw   high InitTbl    ; set page
        movwf   PCLATH          ; select page
        movf    temp,w          ; get address back
        addwf   PCL,f           ; add w to PCL
InitTbl
        ;; timer initial defaults
        retlw   d'100'          ; 0000 hang timer long 10.0 sec
        retlw   d'50'           ; 0001 hang timer short 5.0 sec
        retlw   d'54'           ; 0002 ID timer 9.0 min
        retlw   d'60'           ; 0003 DTMF access timer 60 sec
        retlw   d'180'          ; 0004 timeout timer long 180 sec
        retlw   d'30'           ; 0005 timeout timer short 30 sec
        retlw   d'12'           ; 0006 fan timer 120 sec
        retlw   d'0'            ; 0007 tail message counter - units
        retlw   d'12'           ; 0008 alarm announce timer - tens
        retlw   d'20'           ; 0009 cw pitch
        retlw   d'20'           ; 000a cw speed
        retlw   d'0'            ; 000b spare
        retlw   d'0'            ; 000c spare
        retlw   d'0'            ; 000d spare
        retlw   d'0'            ; 000e spare
        retlw   d'0'            ; 000f spare

        ;; control operator switches, set 0
        retlw   b'01001000'     ; 0010 control operator switches, group 0
        retlw   b'00001011'     ; 0011 control operator switches, group 1
        retlw   b'00011111'     ; 0012 control operator switches, group 2
        retlw   b'00000000'     ; 0013 control operator switches, group 3
        retlw   b'00000000'     ; 0014 control operator switches, group 4
        retlw   b'00000000'     ; 0015 control operator switches, group 5
        retlw   b'00000000'     ; 0016 control operator switches, group 6
        retlw   b'01111111'     ; 0017 control operator switches, group 7
        retlw   h'00'           ; 0018 spare
        retlw   h'00'           ; 0019 spare
        retlw   h'00'           ; 001a spare
        retlw   h'00'           ; 001b spare
        retlw   h'00'           ; 001c spare
        retlw   h'00'           ; 001d spare
        retlw   h'00'           ; 001e spare
        retlw   h'00'           ; 001f spare

        ;; control operator switches, set 1
        ;; changed at 1.06 so set 1 will default to Euro operation.
        retlw   b'01001011'     ; 0020 control operator switches, group 0
        retlw   b'00001111'     ; 0021 control operator switches, group 1
        retlw   b'00001101'     ; 0022 control operator switches, group 2
        retlw   b'00000001'     ; 0023 control operator switches, group 3
        retlw   b'00000000'     ; 0024 control operator switches, group 4
        retlw   b'00000000'     ; 0025 control operator switches, group 5
        retlw   b'00000000'     ; 0026 control operator switches, group 6
        retlw   b'00111111'     ; 0027 control operator switches, group 7
        retlw   h'00'           ; 0028 spare
        retlw   h'00'           ; 0029 spare
        retlw   h'00'           ; 002a spare
        retlw   h'00'           ; 002b spare
        retlw   h'00'           ; 002c spare
        retlw   h'00'           ; 002d spare
        retlw   h'00'           ; 002e spare
        retlw   h'00'           ; 002f spare

        ;; control operator switches, set 2
        retlw   b'01001000'     ; 0030 control operator switches, group 0
        retlw   b'00001011'     ; 0031 control operator switches, group 1
        retlw   b'00011111'     ; 0032 control operator switches, group 2
        retlw   b'00000000'     ; 0033 control operator switches, group 3
        retlw   b'00000000'     ; 0034 control operator switches, group 4
        retlw   b'00000000'     ; 0035 control operator switches, group 5
        retlw   b'00000000'     ; 0036 control operator switches, group 6
        retlw   b'01111111'     ; 0037 control operator switches, group 7
        retlw   h'00'           ; 0038 spare
        retlw   h'00'           ; 0039 spare
        retlw   h'00'           ; 003a spare
        retlw   h'00'           ; 003b spare
        retlw   h'00'           ; 003c spare
        retlw   h'00'           ; 003d spare
        retlw   h'00'           ; 003e spare
        retlw   h'00'           ; 003f spare

        ;; control operator switches, set 3
        retlw   b'01001000'     ; 0040 control operator switches, group 0
        retlw   b'00001011'     ; 0041 control operator switches, group 1
        retlw   b'00011111'     ; 0042 control operator switches, group 2
        retlw   b'00000000'     ; 0043 control operator switches, group 3
        retlw   b'00000000'     ; 0044 control operator switches, group 4
        retlw   b'00000000'     ; 0045 control operator switches, group 5
        retlw   b'00000000'     ; 0046 control operator switches, group 6
        retlw   b'01111111'     ; 0047 control operator switches, group 7
        retlw   h'00'           ; 0048 spare
        retlw   h'00'           ; 0049 spare
        retlw   h'00'           ; 004a spare
        retlw   h'00'           ; 004b spare
        retlw   h'00'           ; 004c spare
        retlw   h'00'           ; 004d spare
        retlw   h'00'           ; 004e spare
        retlw   h'00'           ; 004f spare

        ;; control operator switches, set 4
        retlw   b'01001000'     ; 0050 control operator switches, group 0
        retlw   b'00001011'     ; 0051 control operator switches, group 1
        retlw   b'00011111'     ; 0052 control operator switches, group 2
        retlw   b'00000000'     ; 0053 control operator switches, group 3
        retlw   b'00000000'     ; 0054 control operator switches, group 4
        retlw   b'00000000'     ; 0055 control operator switches, group 5
        retlw   b'00000000'     ; 0056 control operator switches, group 6
        retlw   b'01111111'     ; 0057 control operator switches, group 7
        retlw   h'00'           ; 0058 spare
        retlw   h'00'           ; 0059 spare
        retlw   h'00'           ; 005a spare
        retlw   h'00'           ; 005b spare
        retlw   h'00'           ; 005c spare
        retlw   h'00'           ; 005d spare
        retlw   h'00'           ; 005e spare
        retlw   h'00'           ; 005f spare
        
        ;; courtesy tone initial defaults
        ;; Main Receiver Courtesy Tone
        retlw   h'05'           ; 0060 Courtesy tone 0 00 length seg 1
        retlw   h'8c'           ; 0061 Courtesy tone 0 01 tone seg 1
        retlw   h'05'           ; 0062 Courtesy tone 0 02 length seg 2
        retlw   h'8f'           ; 0063 Courtesy tone 0 03 tone seg 2
        retlw   h'05'           ; 0064 Courtesy tone 0 04 length seg 3
        retlw   h'93'           ; 0065 Courtesy tone 0 05 tone seg 3
        retlw   h'05'           ; 0066 Courtesy tone 0 06 length seg 4
        retlw   h'16'           ; 0067 Courtesy tone 0 07 tone seg 4
        ;; Main Receiver Courtesy Tone, Link RX active, alert mode.
        retlw   h'0a'           ; 0068 Courtesy Tone 1 00 length seg 1
        retlw   h'8c'           ; 0069 Courtesy Tone 1 01 tone seg 1
        retlw   h'0a'           ; 006a Courtesy Tone 1 02 length seg 2
        retlw   h'0f'           ; 006b Courtesy Tone 1 03 tone seg 2
        retlw   h'00'           ; 006c Courtesy Tone 1 04 length seg 3
        retlw   h'00'           ; 006d Courtesy Tone 1 05 tone seg 3
        retlw   h'00'           ; 006e Courtesy Tone 1 06 length seg 4
        retlw   h'00'           ; 006f Courtesy Tone 1 07 tone seg 4
        ;; Main Receiver Courtesy Tone, Link TX on
        retlw   h'0a'           ; 0070 Courtesy tone 2 00 length seg 1
        retlw   h'8c'           ; 0071 Courtesy tone 2 01 tone seg 1
        retlw   h'0a'           ; 0072 Courtesy tone 2 02 length seg 2
        retlw   h'8f'           ; 0073 Courtesy tone 2 03 tone seg 2
        retlw   h'0a'           ; 0074 Courtesy tone 2 04 length seg 3
        retlw   h'15'           ; 0075 Courtesy tone 2 05 tone seg 3
        retlw   h'00'           ; 0076 Courtesy tone 2 06 length seg 4
        retlw   h'00'           ; 0077 Courtesy tone 2 07 tone seg 4
        ;; Link Receiver Courtesy Tone
        retlw   h'05'           ; 0078 Courtesy Tone 3 00 length seg 1
        retlw   h'96'           ; 0079 Courtesy Tone 3 01 tone seg 1
        retlw   h'05'           ; 007a Courtesy Tone 3 02 length seg 2
        retlw   h'93'           ; 007b Courtesy Tone 3 03 tone seg 2
        retlw   h'05'           ; 007c Courtesy Tone 3 04 length seg 3
        retlw   h'8f'           ; 007d Courtesy Tone 3 05 tone seg 3
        retlw   h'05'           ; 007e Courtesy Tone 3 06 length seg 4
        retlw   h'0b'           ; 007f Courtesy Tone 3 07 tone seg 4
        ;; Link Receiver Courtesy Tone, Link TX on
        retlw   h'0a'           ; 0080 Courtesy tone 4 00 length seg 1
        retlw   h'96'           ; 0081 Courtesy tone 4 01 tone seg 1
        retlw   h'0a'           ; 0082 Courtesy tone 4 02 length seg 2
        retlw   h'93'           ; 0083 Courtesy tone 4 03 tone seg 2
        retlw   h'0a'           ; 0084 Courtesy tone 4 04 length seg 3
        retlw   h'10'           ; 0085 Courtesy tone 4 05 tone seg 3
        retlw   h'00'           ; 0086 Courtesy tone 4 06 length seg 4
        retlw   h'00'           ; 0087 Courtesy tone 4 07 tone seg 4
        ;; Spare Courtesy Tone
        retlw   h'0a'           ; 0088 Courtesy Tone 5 00 length seg 1
        retlw   h'08'           ; 0089 Courtesy Tone 5 01 tone seg 1
        retlw   h'00'           ; 008a Courtesy Tone 5 02 length seg 2
        retlw   h'00'           ; 008b Courtesy Tone 5 03 tone seg 2
        retlw   h'00'           ; 008c Courtesy Tone 5 04 length seg 3
        retlw   h'00'           ; 008d Courtesy Tone 5 05 tone seg 3
        retlw   h'00'           ; 008e Courtesy Tone 5 06 length seg 4
        retlw   h'00'           ; 008f Courtesy Tone 5 07 tone seg 4
        ;; Tune Mode Courtesy Tone
        retlw   h'0a'           ; 0090 Courtesy tone 6 00 length seg 1
        retlw   h'13'           ; 0091 Courtesy tone 6 01 tone seg 1
        retlw   h'00'           ; 0092 Courtesy tone 6 02 length seg 2
        retlw   h'00'           ; 0093 Courtesy tone 6 03 tone seg 2
        retlw   h'00'           ; 0094 Courtesy tone 6 04 length seg 3
        retlw   h'00'           ; 0095 Courtesy tone 6 05 tone seg 3
        retlw   h'00'           ; 0096 Courtesy tone 6 06 length seg 4
        retlw   h'00'           ; 0097 Courtesy tone 6 07 tone seg 4
        ;; Unlocked Mode Courtesy Tone.
        retlw   h'0a'           ; 0098 Courtesy Tone 7 00 length seg 1
        retlw   h'9f'           ; 0099 Courtesy Tone 7 01 tone seg 1
        retlw   h'0a'           ; 009a Courtesy Tone 7 02 length seg 2
        retlw   h'93'           ; 009b Courtesy Tone 7 03 tone seg 2
        retlw   h'0a'           ; 009c Courtesy Tone 7 04 length seg 3
        retlw   h'9f'           ; 009d Courtesy Tone 7 05 tone seg 3
        retlw   h'0a'           ; 009e Courtesy Tone 7 06 length seg 4
        retlw   h'13'           ; 009f Courtesy Tone 7 07 tone seg 4
        
        ;; cw id initial defaults
        retlw   h'05'           ; 00a0 CW ID  1 'N'  CW ID
        retlw   h'10'           ; 00a1 CW ID  2 'H'
        retlw   h'0a'           ; 00a2 CW ID  3 'R'
        retlw   h'15'           ; 00a3 CW ID  4 'C'
        retlw   h'00'           ; 00a4 CW ID  5 ' '
        retlw   h'38'           ; 00a5 CW ID  6 '3'
        retlw   h'6a'           ; 00a6 CW ID  7 '.'
        retlw   h'3e'           ; 00a7 CW ID  8 '1'
        retlw   h'00'           ; 00a8 CW ID  9 ' '
        retlw   h'18'           ; 00a9 CW ID 10 'V'  VERSION DATA
        retlw   VERS1           ; 00aa CW ID 11 -- defined at file head
        retlw   h'6a'           ; 00ab CW ID 12 '.'
        retlw   VERS2           ; 00ac CW ID 13 -- defined at file head
        retlw   VERS3           ; 00ad CW ID 14 -- defined at file head
        retlw   h'ff'           ; 00ae CW ID 15 eom
        retlw   h'ff'           ; 00af CW ID 16 eom
        
        ;; control prefixes
        retlw   h'00'           ; 00b0 control prefix 0  00
        retlw   h'00'           ; 00b1 control prefix 0  01
        retlw   h'ff'           ; 00b2 control prefix 0  02
        retlw   h'ff'           ; 00b3 control prefix 0  03
        retlw   h'ff'           ; 00b4 control prefix 0  04
        retlw   h'ff'           ; 00b5 control prefix 0  05
        retlw   h'ff'           ; 00b6 control prefix 0  06
        retlw   h'ff'           ; 00b7 control prefix 0  07
        retlw   h'00'           ; 00b8 control prefix 1  00
        retlw   h'01'           ; 00b9 control prefix 1  01
        retlw   h'ff'           ; 00ba control prefix 1  02
        retlw   h'ff'           ; 00bb control prefix 1  03
        retlw   h'ff'           ; 00bc control prefix 1  04
        retlw   h'ff'           ; 00bd control prefix 1  05
        retlw   h'ff'           ; 00be control prefix 1  06
        retlw   h'ff'           ; 00bf control prefix 1  07
        retlw   h'00'           ; 00c0 control prefix 2  00
        retlw   h'02'           ; 00c1 control prefix 2  01
        retlw   h'ff'           ; 00c2 control prefix 2  02
        retlw   h'ff'           ; 00c3 control prefix 2  03
        retlw   h'ff'           ; 00c4 control prefix 2  04
        retlw   h'ff'           ; 00c5 control prefix 2  05
        retlw   h'ff'           ; 00c6 control prefix 2  06
        retlw   h'ff'           ; 00c7 control prefix 2  07
        retlw   h'00'           ; 00c8 control prefix 3  00
        retlw   h'03'           ; 00c9 control prefix 3  01
        retlw   h'ff'           ; 00ca control prefix 3  02
        retlw   h'ff'           ; 00cb control prefix 3  03
        retlw   h'ff'           ; 00cc control prefix 3  04
        retlw   h'ff'           ; 00cd control prefix 3  05
        retlw   h'ff'           ; 00ce control prefix 3  06
        retlw   h'ff'           ; 00cf control prefix 3  07
        retlw   h'00'           ; 00d0 control prefix 4  00
        retlw   h'04'           ; 00d1 control prefix 4  01
        retlw   h'ff'           ; 00d2 control prefix 4  02
        retlw   h'ff'           ; 00d3 control prefix 4  03
        retlw   h'ff'           ; 00d4 control prefix 4  04
        retlw   h'ff'           ; 00d5 control prefix 4  05
        retlw   h'ff'           ; 00d6 control prefix 4  06
        retlw   h'ff'           ; 00d7 control prefix 4  07
        retlw   h'00'           ; 00d8 control prefix 5  00
        retlw   h'05'           ; 00d9 control prefix 5  01
        retlw   h'ff'           ; 00da control prefix 5  02
        retlw   h'ff'           ; 00db control prefix 5  03
        retlw   h'ff'           ; 00dc control prefix 5  04
        retlw   h'ff'           ; 00dd control prefix 5  05
        retlw   h'ff'           ; 00de control prefix 5  06
        retlw   h'ff'           ; 00df control prefix 5  07
        retlw   h'00'           ; 00e0 control prefix 6  00
        retlw   h'06'           ; 00e1 control prefix 6  01
        retlw   h'ff'           ; 00e2 control prefix 6  02
        retlw   h'ff'           ; 00e3 control prefix 6  03
        retlw   h'ff'           ; 00e4 control prefix 6  04
        retlw   h'ff'           ; 00e5 control prefix 6  05
        retlw   h'ff'           ; 00e6 control prefix 6  06
        retlw   h'ff'           ; 00e7 control prefix 6  07
        retlw   h'00'           ; 00e8 control prefix 7  00
        retlw   h'07'           ; 00e9 control prefix 7  01
        retlw   h'ff'           ; 00ea control prefix 7  02
        retlw   h'ff'           ; 00eb control prefix 7  03
        retlw   h'ff'           ; 00ec control prefix 7  04
        retlw   h'ff'           ; 00ee control prefix 7  05
        retlw   h'ff'           ; 00ee control prefix 7  06
        retlw   h'ff'           ; 00ef control prefix 7  07

        org     1e00

; *************
; ** GetMask **
; *************
        ;; get the bitmask of the selected numbered bit.
GetMask                         ; get mask of selected bit number.
        movwf   temp            ; store 
        movlw   high BitTbl     ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get selected bit number into w
        andlw   h'07'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
BitTbl
        retlw   b'00000001'     ; 0 -- 0
        retlw   b'00000010'     ; 1 -- 1
        retlw   b'00000100'     ; 2 -- 2
        retlw   b'00001000'     ; 3 -- 3
        retlw   b'00010000'     ; 4 -- 4
        retlw   b'00100000'     ; 5 -- 5
        retlw   b'01000000'     ; 6 -- 6
        retlw   b'10000000'     ; 7 -- 7
                
; *************
; ** Get100s **
; *************
        ;; get the number of tens in INDF. return in w.
Get100s                         ; get tone byte from table
        movlw   high HundTbl    ; set page 
        movwf   PCLATH          ; select page
        movf    INDF,w          ; get tone into w
        andlw   h'03'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
HundTbl
        retlw   d'0'            ; 0 -- 0
        retlw   d'100'          ; 1 -- 1
        retlw   d'200'          ; 2 -- 2
        retlw   d'0'            ; 3 -- not valid
                
; *************
; ** GetTens **
; *************
        ;; get the number of tens in INDF. return in w.
GetTens                         ; get tone byte from table
        movlw   high TenTbl     ; set page 
        movwf   PCLATH          ; select page
        movf    INDF,w          ; get tone into w
        andlw   h'0f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TenTbl
        retlw   d'00'           ; 0 -- 0
        retlw   d'10'           ; 1 -- 1
        retlw   d'20'           ; 2 -- 2
        retlw   d'30'           ; 3 -- 3
        retlw   d'40'           ; 4 -- 4
        retlw   d'50'           ; 5 -- 5
        retlw   d'60'           ; 6 -- 6
        retlw   d'70'           ; 7 -- 7
        retlw   d'80'           ; 8 -- 8
        retlw   d'90'           ; 9 -- 9
        retlw   d'00'           ; A -- not valid
        retlw   d'00'           ; B -- not valid
        retlw   d'00'           ; C -- not valid
        retlw   d'00'           ; D -- not valid
        retlw   d'00'           ; * -- not valid
        retlw   d'00'           ; # -- not valid
                
; *************
; ** SetTone **
; *************
        ;; get a tone 1/2 interval from the table.
        ;; tone 00 is NO tone (off).
        ;; start sending the tone.
SetTone                         ; get tone bytes from table
        movwf   temp            ; save w
        btfsc   STATUS,Z        ; is result zero?
        goto    StopTone        ; yes. Stop that infernal beeping.
        call    GetToneH        ; get hi byte.
        movwf   CCPR1H          ; save hi byte.
        call    GetToneL        ; get lo byte.
        movwf   CCPR1L          ; save lo byte.
        clrf    TMR1L           ; clear lo byte of timer.
        clrf    TMR1H           ; clear hi byte of timer.
        bsf     T1CON, TMR1ON   ; turn on timer 1.  Start beeping.
        return                  ; done.

StopTone                        ; stop the racket!
        bcf     T1CON, TMR1ON   ; turn off timer 1.
        return
        
; **************
; ** GetToneL **
; **************
        ;; get high byte for compare for tone.
        ;; tone 1f is NO tone (off).
GetToneL                        ; get tone hi byte from table
        movlw   high TnTblL     ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TnTblL
        retlw   h'ff'           ; OFF -- 00
        retlw   h'01'           ; F4  -- 01
        retlw   h'b9'           ; F#4 -- 02
        retlw   h'75'           ; G4  -- 03
        retlw   h'35'           ; G#4 -- 04
        retlw   h'f8'           ; A4  -- 05
        retlw   h'bf'           ; A#4 -- 06
        retlw   h'89'           ; B4  -- 07
        retlw   h'57'           ; C5  -- 08
        retlw   h'27'           ; C#5 -- 09
        retlw   h'f9'           ; D5  -- 0a
        retlw   h'ce'           ; D#5 -- 0b
        retlw   h'a6'           ; E5  -- 0c
        retlw   h'80'           ; F5  -- 0d
        retlw   h'5c'           ; F#5 -- 0e
        retlw   h'3a'           ; G5  -- 0f
        retlw   h'1a'           ; G#5 -- 10
        retlw   h'fc'           ; A5  -- 11
        retlw   h'df'           ; A#  -- 12
        retlw   h'c4'           ; B5  -- 13
        retlw   h'ab'           ; C6  -- 14
        retlw   h'93'           ; C#6 -- 15
        retlw   h'7c'           ; D6  -- 16
        retlw   h'67'           ; D#6 -- 17
        retlw   h'53'           ; E6  -- 18
        retlw   h'40'           ; F6  -- 19
        retlw   h'2e'           ; F#6 -- 1a
        retlw   h'1d'           ; G6  -- 1b
        retlw   h'0d'           ; G#6 -- 1c
        retlw   h'fe'           ; A6  -- 1d
        retlw   h'ef'           ; A#6 -- 1e
        retlw   h'e2'           ; B6  -- 1f

; **************
; ** GetToneH **
; **************
        ;; get high byte for compare for tone.
        ;; tone 1f is NO tone (off).
GetToneH                        ; get tone hi byte from table
        movlw   high TnTblH     ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TnTblH
        retlw   h'ff'           ; OFF -- 00
        retlw   h'05'           ; F4  -- 01
        retlw   h'04'           ; F#4 -- 02
        retlw   h'04'           ; G4  -- 03
        retlw   h'04'           ; G#4 -- 04
        retlw   h'03'           ; A4  -- 05
        retlw   h'03'           ; A#4 -- 06
        retlw   h'03'           ; B4  -- 07
        retlw   h'03'           ; C5  -- 08
        retlw   h'03'           ; C#5 -- 09
        retlw   h'02'           ; D5  -- 0a
        retlw   h'02'           ; D#5 -- 0b
        retlw   h'02'           ; E5  -- 0c
        retlw   h'02'           ; F5  -- 0d
        retlw   h'02'           ; F#5 -- 0e
        retlw   h'02'           ; G5  -- 0f
        retlw   h'02'           ; G#5 -- 10
        retlw   h'01'           ; A5  -- 11
        retlw   h'01'           ; A#  -- 12
        retlw   h'01'           ; B5  -- 13
        retlw   h'01'           ; C6  -- 14
        retlw   h'01'           ; C#6 -- 15
        retlw   h'01'           ; D6  -- 16
        retlw   h'01'           ; D#6 -- 17
        retlw   h'01'           ; E6  -- 18
        retlw   h'01'           ; F6  -- 19
        retlw   h'01'           ; F#6 -- 1a
        retlw   h'01'           ; G6  -- 1b
        retlw   h'01'           ; G#6 -- 1c
        retlw   h'00'           ; A6  -- 1d
        retlw   h'00'           ; A#6 -- 1e
        retlw   h'00'           ; B6  -- 1f

; **************
; ** MesgTabl **
; **************
        ;; play canned messages from ROM
        ;; byte offset is index param in w.
        ;; returns specified byte in w.
MesgTabl                        ; canned messages table (CW, beeps, DTMF, whatever)
        movwf   temp            ; save addr.
        movlw   high MsgTbl     ; set page
        movwf   PCLATH          ; select page
        movf    temp,w          ; get address back
        andlw   h'3f'           ; restrict to reasonable range
        addwf   PCL,f           ; add w to PCL
MsgTbl
        retlw   h'0f'           ; 'O'     -- 00 CW_OK
        retlw   h'0d'           ; 'K'     -- 01
        retlw   h'ff'           ; EOM     -- 02
        retlw   h'02'           ; 'E'     -- 03 CW_ERR
        retlw   h'0a'           ; 'R'     -- 04
        retlw   h'0a'           ; 'R'     -- 05
        retlw   h'ff'           ; EOM     -- 06
        retlw   h'03'           ; 'T'     -- 07 CW_TO
        retlw   h'0f'           ; '0'     -- 08
        retlw   h'ff'           ; EOM     -- 09
        retlw   h'0f'           ; 'O'     -- 0a CW_ON
        retlw   h'05'           ; 'N'     -- 0b
        retlw   h'ff'           ; EOM     -- 0c
        retlw   h'0f'           ; 'O'     -- 0d CW_OFF
        retlw   h'14'           ; 'F'     -- 0e
        retlw   h'14'           ; 'F'     -- 0f
        retlw   h'ff'           ; EOM     -- 10
        retlw   h'05'           ; 'N'     -- 11 CWHELLO
        retlw   h'10'           ; 'H'     -- 12
        retlw   h'0a'           ; 'R'     -- 13
        retlw   h'15'           ; 'C'     -- 14
        retlw   h'00'           ; ' '     -- 15
        IFDEF NHRC3_1
        retlw   h'38'           ; '3'     -- 16
        ELSE
        retlw   h'3c'           ; '2'     -- 16
        ENDIF
        retlw   h'6a'           ; '.'     -- 17
        retlw   h'3e'           ; '1'     -- 18
        retlw   h'00'           ; ' '     -- 19
        retlw   h'18'           ; 'V'     -- 1a
        retlw   VERS1           ; '%'     -- 1b 
        retlw   h'6a'           ; '.'     -- 1c
        retlw   VERS2           ; '%'     -- 1d
        retlw   VERS3           ; '%'     -- 1e
        retlw   h'ff'           ; EOM     -- 1f

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
        movwf   temp6           ; save tone.
        movlw   high DtTbl      ; set page.
        movwf   PCLATH          ; select page.
        movf    temp6,w         ; get tone back.
        addwf   PCL,f           ; add w to PCL
DtTbl
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
        
; **************
; ** CWParms  **
; **************
CWParms                         ; set CW parameters from timers.
        movlw   EETCWP          ; get EEPROM address of cw pitch preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        movwf   cwTone          ; save CW tone.
        
        movlw   EETCWS          ; get EEPROM address of cw speed preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        call    GetCWD          ; get the CW delay for the indicated speed.
        movwf   cwSpeed         ; save CW speed.

        return                  ; done here.

        org     1f00

        FILL 0x3ff,0x0100       ; reserve this block for the ICD.
        
        IF LOAD_EE == 1 
        org     2100h
        de      d'100'          ; 0000 hang timer long 10.0 sec
        de      d'50'           ; 0001 hang timer short 5.0 sec
        de      d'57'           ; 0002 ID timer 120 sec for debug
        de      d'60'           ; 0003 DTMF access timer 60 sec
        de      d'180'          ; 0004 timeout timer long 180 sec
        de      d'15'           ; 0005 timeout timer short 30 sec
        de      d'6'            ; 0006 fan timer 6 sec
        de      d'0'            ; 0007 tail message counter - units
        de      d'12'           ; 0008 alarm announce timer -- tens
        de      d'20'           ; 0009 cw pitch
        de      d'20'           ; 000a cw speed
        de      d'0'            ; 000b spare
        de      d'0'            ; 000c spare
        de      d'0'            ; 000d spare
        de      d'0'            ; 000e spare
        de      d'0'            ; 000f spare

        ;; control operator switches, set 0
        de      b'01001001'     ; 0010 control operator switches, group 0
        de      b'00001011'     ; 0011 control operator switches, group 1
        de      b'00001111'     ; 0012 control operator switches, group 2
        de      b'00000000'     ; 0013 control operator switches, group 3
        de      b'00000000'     ; 0014 control operator switches, group 4
        de      b'00000000'     ; 0015 control operator switches, group 5
        de      b'00000000'     ; 0016 control operator switches, group 6
        de      b'00111111'     ; 0017 control operator switches, group 7
        de      h'00'           ; 0018 spare
        de      h'00'           ; 0019 spare
        de      h'00'           ; 001a spare
        de      h'00'           ; 001b spare
        de      h'00'           ; 001c spare
        de      h'00'           ; 001d spare
        de      h'00'           ; 001e spare
        de      h'00'           ; 001f spare

        ;; control operator switches, set 1

        de      b'01011011'     ; 0020 control operator switches, group 0
        de      b'00001111'     ; 0021 control operator switches, group 1
        de      b'00011111'     ; 0022 control operator switches, group 2
        de      b'00000001'     ; 0023 control operator switches, group 3
        de      b'00000000'     ; 0024 control operator switches, group 4
        de      b'00000000'     ; 0025 control operator switches, group 5
        de      b'00000000'     ; 0026 control operator switches, group 6
        de      b'00111111'     ; 0027 control operator switches, group 7
        de      h'00'           ; 0028 spare
        de      h'00'           ; 0029 spare
        de      h'00'           ; 002a spare
        de      h'00'           ; 002b spare
        de      h'00'           ; 002c spare
        de      h'00'           ; 002d spare
        de      h'00'           ; 002e spare
        de      h'00'           ; 002f spare


        ;; control operator switches, set 2

        de      b'01001001'     ; 0030 control operator switches, group 0
        de      b'00001011'     ; 0031 control operator switches, group 1
        de      b'00001111'     ; 0032 control operator switches, group 2
        de      b'00000000'     ; 0033 control operator switches, group 3
        de      b'00000000'     ; 0034 control operator switches, group 4
        de      b'00000000'     ; 0035 control operator switches, group 5
        de      b'00000000'     ; 0036 control operator switches, group 6
        de      b'00111111'     ; 0037 control operator switches, group 7
        de      h'00'           ; 0038 spare
        de      h'00'           ; 0039 spare
        de      h'00'           ; 003a spare
        de      h'00'           ; 003b spare
        de      h'00'           ; 003c spare
        de      h'00'           ; 003d spare
        de      h'00'           ; 003e spare
        de      h'00'           ; 003f spare

        ;; control operator switches, set 3

        de      b'01001001'     ; 0040 control operator switches, group 0
        de      b'00001011'     ; 0041 control operator switches, group 1
        de      b'00001111'     ; 0042 control operator switches, group 2
        de      b'00000000'     ; 0043 control operator switches, group 3
        de      b'00000000'     ; 0044 control operator switches, group 4
        de      b'00000000'     ; 0045 control operator switches, group 5
        de      b'00000000'     ; 0046 control operator switches, group 6
        de      b'00111111'     ; 0047 control operator switches, group 7
        de      h'00'           ; 0048 spare
        de      h'00'           ; 0049 spare
        de      h'00'           ; 004a spare
        de      h'00'           ; 004b spare
        de      h'00'           ; 004c spare
        de      h'00'           ; 004d spare
        de      h'00'           ; 004e spare
        de      h'00'           ; 004f spare

        ;; control operator switches, set 4

        de      b'01001001'     ; 0050 control operator switches, group 0
        de      b'01001001'     ; 0051 control operator switches, group 1
        de      b'00001111'     ; 0052 control operator switches, group 2
        de      b'00000000'     ; 0053 control operator switches, group 3
        de      b'00000000'     ; 0054 control operator switches, group 4
        de      b'00000000'     ; 0055 control operator switches, group 5
        de      b'00000000'     ; 0056 control operator switches, group 6
        de      b'00111111'     ; 0057 control operator switches, group 7
        de      h'00'           ; 0058 spare
        de      h'00'           ; 0059 spare
        de      h'00'           ; 005a spare
        de      h'00'           ; 005b spare
        de      h'00'           ; 005c spare
        de      h'00'           ; 005d spare
        de      h'00'           ; 005e spare
        de      h'00'           ; 005f spare
        
        ;; courtesy tone initial defaults
        ;; Main Receiver Courtesy Tone
        de      h'05'           ; 0060 Courtesy tone 0 00 length seg 1
        de      h'8c'           ; 0061 Courtesy tone 0 01 tone seg 1
        de      h'05'           ; 0062 Courtesy tone 0 02 length seg 2
        de      h'8f'           ; 0063 Courtesy tone 0 03 tone seg 2
        de      h'05'           ; 0064 Courtesy tone 0 04 length seg 3
        de      h'93'           ; 0065 Courtesy tone 0 05 tone seg 3
        de      h'05'           ; 0066 Courtesy tone 0 06 length seg 4
        de      h'16'           ; 0067 Courtesy tone 0 07 tone seg 4
        ;; Main Receiver Courtesy Tone, Link RX active, alert mode.
        de      h'0a'           ; 0068 Courtesy Tone 1 00 length seg 1
        de      h'8c'           ; 0069 Courtesy Tone 1 01 tone seg 1
        de      h'0a'           ; 006a Courtesy Tone 1 02 length seg 2
        de      h'0f'           ; 006b Courtesy Tone 1 03 tone seg 2
        de      h'00'           ; 006c Courtesy Tone 1 04 length seg 3
        de      h'00'           ; 006d Courtesy Tone 1 05 tone seg 3
        de      h'00'           ; 006e Courtesy Tone 1 06 length seg 4
        de      h'00'           ; 006f Courtesy Tone 1 07 tone seg 4
        ;; Main Receiver Courtesy Tone, Link TX on
        de      h'0a'           ; 0070 Courtesy tone 2 00 length seg 1
        de      h'8c'           ; 0071 Courtesy tone 2 01 tone seg 1
        de      h'0a'           ; 0072 Courtesy tone 2 02 length seg 2
        de      h'8f'           ; 0073 Courtesy tone 2 03 tone seg 2
        de      h'0a'           ; 0074 Courtesy tone 2 04 length seg 3
        de      h'15'           ; 0075 Courtesy tone 2 05 tone seg 3
        de      h'00'           ; 0076 Courtesy tone 2 06 length seg 4
        de      h'00'           ; 0077 Courtesy tone 2 07 tone seg 4
        ;; Link Receiver Courtesy Tone
        de      h'05'           ; 0078 Courtesy Tone 3 00 length seg 1
        de      h'96'           ; 0079 Courtesy Tone 3 01 tone seg 1
        de      h'05'           ; 007a Courtesy Tone 3 02 length seg 2
        de      h'93'           ; 007b Courtesy Tone 3 03 tone seg 2
        de      h'05'           ; 007c Courtesy Tone 3 04 length seg 3
        de      h'8f'           ; 007d Courtesy Tone 3 05 tone seg 3
        de      h'05'           ; 007e Courtesy Tone 3 06 length seg 4
        de      h'0b'           ; 007f Courtesy Tone 3 07 tone seg 4
        ;; Link Receiver Courtesy Tone, Link TX on
        de      h'0a'           ; 0080 Courtesy tone 4 00 length seg 1
        de      h'96'           ; 0081 Courtesy tone 4 01 tone seg 1
        de      h'0a'           ; 0082 Courtesy tone 4 02 length seg 2
        de      h'93'           ; 0083 Courtesy tone 4 03 tone seg 2
        de      h'0a'           ; 0084 Courtesy tone 4 04 length seg 3
        de      h'10'           ; 0085 Courtesy tone 4 05 tone seg 3
        de      h'00'           ; 0086 Courtesy tone 4 06 length seg 4
        de      h'00'           ; 0087 Courtesy tone 4 07 tone seg 4
        ;; Spare Courtesy Tone
        de      h'0a'           ; 0088 Courtesy Tone 5 00 length seg 1
        de      h'08'           ; 0089 Courtesy Tone 5 01 tone seg 1
        de      h'00'           ; 008a Courtesy Tone 5 02 length seg 2
        de      h'00'           ; 008b Courtesy Tone 5 03 tone seg 2
        de      h'00'           ; 008c Courtesy Tone 5 04 length seg 3
        de      h'00'           ; 008d Courtesy Tone 5 05 tone seg 3
        de      h'00'           ; 008e Courtesy Tone 5 06 length seg 4
        de      h'00'           ; 008f Courtesy Tone 5 07 tone seg 4
        ;; Tune Mode Courtesy Tone
        de      h'0a'           ; 0090 Courtesy tone 6 00 length seg 1
        de      h'13'           ; 0091 Courtesy tone 6 01 tone seg 1
        de      h'00'           ; 0092 Courtesy tone 6 02 length seg 2
        de      h'00'           ; 0093 Courtesy tone 6 03 tone seg 2
        de      h'00'           ; 0094 Courtesy tone 6 04 length seg 3
        de      h'00'           ; 0095 Courtesy tone 6 05 tone seg 3
        de      h'00'           ; 0096 Courtesy tone 6 06 length seg 4
        de      h'00'           ; 0097 Courtesy tone 6 07 tone seg 4
        ;; Unlocked Mode Courtesy Tone.
        de      h'0a'           ; 0098 Courtesy Tone 7 00 length seg 1
        de      h'9f'           ; 0099 Courtesy Tone 7 01 tone seg 1
        de      h'0a'           ; 009a Courtesy Tone 7 02 length seg 2
        de      h'93'           ; 009b Courtesy Tone 7 03 tone seg 2
        de      h'0a'           ; 009c Courtesy Tone 7 04 length seg 3
        de      h'9f'           ; 009d Courtesy Tone 7 05 tone seg 3
        de      h'0a'           ; 009e Courtesy Tone 7 06 length seg 4
        de      h'13'           ; 009f Courtesy Tone 7 07 tone seg 4
        
        ;; cw id initial defaults
        de      h'05'           ; 00a0 CW ID  1 'n'   CW ID
        de      h'10'           ; 00a1 CW ID  2 'h'
        de      h'0a'           ; 00a2 CW ID  3 'r'
        de      h'15'           ; 00a3 CW ID  4 'c'
        de      h'00'           ; 00a4 CW ID  5 ' '
        de      h'38'           ; 00a5 CW ID  6 '3'
        de      h'6a'           ; 00a6 CW ID  7 '.'
        de      h'3e'           ; 00a7 CW ID  8 '1'
        de      h'00'           ; 00a8 CW ID  9 ' '
        de      h'18'           ; 00a9 CW ID 10 'V'  VERSION DATA
        de      VERS1           ; 00aa CW ID 11 -- defined at file head
        de      h'6a'           ; 00ab CW ID 12 '.'
        de      VERS2           ; 00ac CW ID 13 -- defined at file head
        de      VERS3           ; 00ad CW ID 14 -- defined at file head
        de      h'ff'           ; 00ae CW ID 15 eom
        de      h'ff'           ; 00af CW ID 16 eom
        
        ;; control prefixes
        de      h'00'           ; 00b0 control prefix 0  00
        de      h'00'           ; 00b1 control prefix 0  01
        de      h'ff'           ; 00b2 control prefix 0  02
        de      h'ff'           ; 00b3 control prefix 0  03
        de      h'ff'           ; 00b4 control prefix 0  04
        de      h'ff'           ; 00b5 control prefix 0  05
        de      h'ff'           ; 00b6 control prefix 0  06
        de      h'ff'           ; 00b7 control prefix 0  07
        de      h'00'           ; 00b8 control prefix 1  00
        de      h'01'           ; 00b9 control prefix 1  01
        de      h'ff'           ; 00ba control prefix 1  02
        de      h'ff'           ; 00bb control prefix 1  03
        de      h'ff'           ; 00bc control prefix 1  04
        de      h'ff'           ; 00bd control prefix 1  05
        de      h'ff'           ; 00be control prefix 1  06
        de      h'ff'           ; 00bf control prefix 1  07
        de      h'00'           ; 00c0 control prefix 2  00
        de      h'02'           ; 00c1 control prefix 2  01
        de      h'ff'           ; 00c2 control prefix 2  02
        de      h'ff'           ; 00c3 control prefix 2  03
        de      h'ff'           ; 00c4 control prefix 2  04
        de      h'ff'           ; 00c5 control prefix 2  05
        de      h'ff'           ; 00c6 control prefix 2  06
        de      h'ff'           ; 00c7 control prefix 2  07
        de      h'00'           ; 00c8 control prefix 3  00
        de      h'03'           ; 00c9 control prefix 3  01
        de      h'ff'           ; 00ca control prefix 3  02
        de      h'ff'           ; 00cb control prefix 3  03
        de      h'ff'           ; 00cc control prefix 3  04
        de      h'ff'           ; 00cd control prefix 3  05
        de      h'ff'           ; 00ce control prefix 3  06
        de      h'ff'           ; 00cf control prefix 3  07
        de      h'00'           ; 00d0 control prefix 4  00
        de      h'04'           ; 00d1 control prefix 4  01
        de      h'ff'           ; 00d2 control prefix 4  02
        de      h'ff'           ; 00d3 control prefix 4  03
        de      h'ff'           ; 00d4 control prefix 4  04
        de      h'ff'           ; 00d5 control prefix 4  05
        de      h'ff'           ; 00d6 control prefix 4  06
        de      h'ff'           ; 00d7 control prefix 4  07
        de      h'00'           ; 00d8 control prefix 5  00
        de      h'05'           ; 00d9 control prefix 5  01
        de      h'ff'           ; 00da control prefix 5  02
        de      h'ff'           ; 00db control prefix 5  03
        de      h'ff'           ; 00dc control prefix 5  04
        de      h'ff'           ; 00dd control prefix 5  05
        de      h'ff'           ; 00de control prefix 5  06
        de      h'ff'           ; 00df control prefix 5  07
        de      h'00'           ; 00e0 control prefix 6  00
        de      h'06'           ; 00e1 control prefix 6  01
        de      h'ff'           ; 00e2 control prefix 6  02
        de      h'ff'           ; 00e3 control prefix 6  03
        de      h'ff'           ; 00e4 control prefix 6  04
        de      h'ff'           ; 00e5 control prefix 6  05
        de      h'ff'           ; 00e6 control prefix 6  06
        de      h'ff'           ; 00e7 control prefix 6  07
        de      h'00'           ; 00e8 control prefix 7  00
        de      h'07'           ; 00e9 control prefix 7  01
        de      h'ff'           ; 00ea control prefix 7  02
        de      h'ff'           ; 00eb control prefix 7  03
        de      h'ff'           ; 00ec control prefix 7  04
        de      h'ff'           ; 00ed control prefix 7  05
        de      h'ff'           ; 00ee control prefix 7  06
        de      h'ff'           ; 00ef control prefix 7  07
        de      h'01'           ; 00f0 spare
        de      h'01'           ; 00f1 spare
        de      h'01'           ; 00f2 spare
        de      h'01'           ; 00f3 spare
        de      h'00'           ; 00f4 spare
        de      h'00'           ; 00f5 spare
        de      h'00'           ; 00f6 spare
        de      h'00'           ; 00f7 spare
        de      h'00'           ; 00f8 spare
        de      h'00'           ; 00f9 spare
        de      h'00'           ; 00fa spare
        de      h'00'           ; 00fb spare
        de      h'00'           ; 00fc spare
        de      h'00'           ; 00fd spare
        de      h'00'           ; 00fe spare
        de      h'00'           ; 00ff spare

        ENDIF   
        
        end

        
; MORSE CODE encoding...
;
; morse characters are encoded in a single byte, bitwise, LSB to MSB.
; 0 = dit, 1 = dah.  the byte is shifted out to the right, until only 
; a 1 remains.  characters with more than 7 elements (error) cannot be sent.
;
; a .-      00000110  06                 ; 0 -----   00111111  3f
; b -...    00010001  11                 ; 1 .----   00111110  3e
; c -.-.    00010101  15                 ; 2 ..---   00111100  3c
; d -..     00001001  09                 ; 3 ...--   00111000  38
; e .       00000010  02                 ; 4 ....-   00110000  30
; f ..-.    00010100  14                 ; 5 .....   00100000  20
; g --.     00001011  0b                 ; 6 -....   00100001  21
; h ....    00010000  10                 ; 7 --...   00100011  23
; i ..      00000100  04                 ; 8 ---..   00100111  27
; j .---    00011110  1e                 ; 9 ----.   00101111  2f
; k -.-     00001101  0d                                         
; l .-..    00010010  12                 ; sk ...-.- 01101000  58
; m --      00000111  07                 ; ar .-.-.  00101010  2a + 
; n -.      00000101  05                 ; bt -...-  00110001  31
; o ---     00001111  0f                 ; / -..-.   00101001  29
; p .--.    00010110  16                 ;'.' .-.-.- 01101010  6a        
; q --.-    00011011  1b                 ; space     00000000  00
; r .-.     00001010  0a                 ; EOM       11111111  ff
; s ...     00001000  08
; t -       00000011  03
; u ..-     00001100  0c
; v ...-    00011000  18
; w .--     00001110  0e
; x -..-    00011001  19
; y -.--    00011101  1d
; z --..    00010011  13
        
;; CW timebase:
;; WPM  setting
;;   5    240
;;   6    200
;;   7    171
;;   8    150
;;   9    133
;;  10    120
;;  11    109
;;  12    100
;;  13     92
;;  14     86
;;  15     80
;;  16     75
;;  17     71
;;  18     67
;;  19     63
;;  20     60
;;  21     57
;;  22     55
;;  23     52
;;  24     50
;;  25     48
;;  26     46
;;  27     44
;;  28     43
;;  29     41
;;  30     40
           
