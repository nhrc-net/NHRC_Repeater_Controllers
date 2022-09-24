        ;; NHRC-17 Interoperability Controller.
        ;; Copyright 2011, 2012 NHRC LLC as an unpublished proprietary work.
        ;; All rights reserved.
        ;; No part of this document may be used or reproduced by any means,
        ;; for any purpose, without the expressed written consent of NHRC LLC.

        ;; v 0.01 10 December 2011 -- initial
        ;; v 0.02 02 January  2012 -- 3 ms CTSEL debounce for auto state change
        ;;                         -- command prefix max length now 8 (was 7)
        ;;                         -- DTMF eval can be disabled for each RX
        ;; v 0.03 08 January  2012 -- fix missing CT for RX2->TX1
        ;;                            fix *71 test courtesy tone works on RX
        ;;                            turned off CT for factor states 0,1
        ;; v 0.04 28 February 2012 -- now running on real hardware.
        ;; v 0.05 03 March    2012 -- fixed default IDs to be NHRC17
        ;; v 0.06 26 January  2016 -- fix obscure unmute bug on port 3
        
VER_INT equ     d'0'            ; remember to change CW version, too.
VER_HI  equ     d'0'            ; search for "VERSION DATA" in the source.
VER_LO  equ     d'6'

LOAD_EE=1
xxSIMULATOR=1
        
        ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

        IFDEF __16F887
        include "p16f887.inc"
        ENDIF
        
        IFDEF __DEBUG
        __CONFIG _CONFIG1, _HS_OSC & _LVP_OFF & _WDT_OFF & _IESO_OFF
        ELSE
        ;;  NOT a DEBUG build
        __CONFIG _CONFIG1, _PWRTE_ON & _HS_OSC & _LVP_OFF & _CP_ON
        ENDIF                   ; __DEBUG

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

        IFDEF SIMULATOR
TEN     equ     D'5'            ; faster than speeding decade counters.
        ELSE
TEN     equ     D'10'           ; decade counter.
        ENDIF

; *************************
; ** IO Port Assignments **
; *************************

; PORTA
DTMFQ1  equ     0               ; input, DTMF decoder Q1
DTMFQ2  equ     1               ; input, DTMF decoder Q2
DTMFQ3  equ     2               ; input, DTMF decoder Q3
DTMFQ4  equ     3               ; input, DTMF decoder Q4
INIT    equ     4               ; input, initialize jumper.
FANCTL  equ     5               ; output, fan control/digital output.

; PORTB
DTMF1OE equ     0               ; output, DTMF 1 output enable.
DTMF2OE equ     1               ; output, DTMF 2 output enable.
TX1PTT  equ     2               ; output, TX1 PTT when high.
TX2PTT  equ     3               ; output, TX2 PTT when high.
RX11AUD equ     4               ; output, audio 1->1 mute, muted when low.
RX21AUD equ     5               ; output, audio 2->1 mute, muted when low.
RX12AUD equ     6               ; output, audio 1->2 mute, muted when low.
RX22AUD equ     7               ; output, audio 2->2 mute, muted when low.
        
; PORTC
BEEP1   equ     0               ; PWM output, beep tone source.
BEEP2   equ     1               ; PWM output, beep tone source.
DTMF1DV equ     2               ; input, DTMF digit valid decoder 1 when high.
DTMF2DV equ     3               ; input, DTMF digit valid decoder 2 when high.
RX2PL   equ     4               ; input, RX2 CTCSS present when low.
RX2COR  equ     5               ; input, RX2 COR present when low.

; PORTD
EXP1    equ     0               ; expand 1 input
ALARM   equ     0               ; ALARM\ input
EXP2    equ     1               ; expand 2 input
CT4SEL  equ     1               ; CT4 SEL\ input
EXP3    equ     2               ; expand 3 input
CT5SEL  equ     2               ; CT5 SEL \ input
EXP4    equ     3               ; expand 4 input
CT6SEL  equ     3               ; CT6 SEL \ input
EXP5    equ     4               ; expand 5 output
TX1ENC  equ     4               ; TX1 Encoder output
EXP6    equ     5               ; expand 6 output
TX2ENC  equ     5               ; TX2 Encoder output
EXP7    equ     6               ; expand 7 output
EXP8    equ     7               ; expand 8 output

; PORTE
RX1COR  equ     0               ; input, RX1 COR present when low.
RX1PL   equ     1               ; input, RX1 CTCSS present when low.
RE2     equ     2               ; spare.
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
; niy   equ     7               ; NIY

; rx1flag, rx2flag, rx3flag
DTMF0   equ     0               ; DTMF decoder last received a zero
LASTDV  equ     1               ; last digit valid indicator
;CTCSS  equ     2               ; last CTCSS flag.
        
; tx1flag, tx2flag
RX1TX   equ     0               ; receiver 0 is being transmitted
RX2TX   equ     1               ; receiver 1 is being transmitted
HANG    equ     2               ; hang time
BEEPING equ     3               ; CT beep is active
CWPLAY  equ     4               ; CW playback active
CTDELAY equ     5               ; CT delay, leave tx on.
;NIY    equ     6               ; 
;NIY    equ     7               ; 

; tx1flg2, tx2flg2
NEEDID  equ     0               ; need to send ID
INITID  equ     1               ; need to send initial id.
TXONFLG equ     2               ; last TX state flag
DEF_CT  equ     3               ; deferred courtesy tone.
;; NIY  equ     4               ; 
CWBEEP  equ     5               ; cw beep is on.
;; NIY  equ     6               ; 
;; NIY  equ     7               ; 

;; COR debounce time
COR1DEB equ     5               ; 5 ms.  COR off to on debounce time
COR0DEB equ     5               ; 5 ms.  COR on to off debounce time
DLY1DEB equ     d'100'          ; 100 ms. COR off->on debounce time, with DAD.
DLY0DEB equ     d'50'           ; 50 ms.  COR on->off debounce time, with DAD.
CHNKDEB equ     d'250'          ; 250 ms.
        
IDSOON  equ     D'6'            ; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ     D'20'           ; DTMF muting timer = 2.0 sec.
DTMFDLY equ     d'20'           ; DTMF activity timer = 2.0 sec.
UNLKDLY equ     d'120'          ; unlocked mode timer.
        
; dtRFlag -- DTMF sequence received indicator
DT1RDY  equ     0               ; some sequence received on DTMF-1
DT2RDY  equ     1               ; some sequence received on DTMF-2
;niy    equ     2               ; 
DTUL    equ     3               ; command received from unlocked port.
DTSEVAL equ     4               ; DTMF command evaluation in progress.
DT1UNLK equ     5               ; unlocked indicator, port 1
DT2UNLK equ     6               ; unlocked indicator, port 2
;niy    equ     7               ;
                ;; 
;dtEFlag -- DTMF command evaluator control flag.
        ;; low order 5 bits indicate next prefix number/user command to scan
DT1CMD  equ     5               ; received this command from DTMF-1
DT2CMD  equ     6               ; received this command from DTMF-2
;niy     equ     7               ; 

; beep1ctl -- beeper control flags...
B_ADR0  equ     0               ; beep or CW addressing mode indicator
B_ADR1  equ     1               ; beep or CW addressing mode indicator
                                ;   00 EEPROM
                                ;   01 lookup table index, built in messages.
                                ;   10 from RAM
                                ;   11 CW single letter mode
                                ; 
B_BEEP  equ     2               ; beep sequence in progress
B_CW    equ     3               ; CW transmission in progress
;       equ     4               ;
;       equ     5               ;
B_LAST  equ     6               ; last segment of CT tones.

; beep1ctl preset masks
BEEP_CT equ     b'10000100'     ; CT from EEPROM
BEEP_CX equ     b'10000101'     ; CT from ROM table
CW_ROM  equ     b'10001001'     ; CW from ROM table
CW_EE   equ     b'10001000'     ; CW from EEPROM
CW_LETR equ     b'10001011'     ; CW ONE LETTER ONLY.

CTPAUSE equ     d'5'            ; 50 msec pause before CT.
MAGICCT equ     d'99'           ; magic CT length.  next digit is CW digit.
PULS_TM equ     d'50'           ; 50 x 10 ms = 500 ms.  pulse duration time.

; flags
RX1USQ  equ     0               ; receiver 1 unsquelched
RX1MUTD equ     1               ; receiver 1 muted
RX2USQ  equ     2               ; receiver 2 unsquelched
RX2MUTD equ     3               ; receiver 2 muted
;;      equ     4               ; not used
CMD_NIB equ     5               ; command interpreter nibble flag for copy
RX1NOCT equ     6               ; suppress CT on RX1
RX2NOCT equ     7               ; suppress CT on RX2

; serFlag -- serial IO control flags
SC_CMD  equ     5               ; have received command initiator
SC_ECHO equ     6               ; serial character ready to echo
SC_RDY  equ     7               ; serial command ready to process
        
; receiver states
RXSOFF  equ     0
RXSON   equ     1
RXSTMO  equ     2

; cTone Courtesy tone selections
CTNONE  equ     h'ff'           ; no courtesy tone.
CTRX11  equ     0               ; rx1 -> tx1 tone.
CTRX12  equ     1               ; rx1 -> tx2 tone.
CTRX21  equ     2               ; rx2 -> tx1 tone.
CTRX22  equ     3               ; rx2 -> tx2 tone.
CT4     equ     4               ; spare.
CT5     equ     5               ; spare.
CT6     equ     6               ; spare.
CTUNLOK equ     7               ; unlocked courtesy tone.

; CW Message Addressing Scheme:
; These symbols represent the value of the CW characters in the ROM table.
;     1 - CW timeout message, "to"
;     2 - CW confirm message, "ok"
;     3 - CW bad message, "ng"
;     3 - CW link timeout "rb to"

CW_OK   equ     h'00'           ; CW: OK
CW_NG   equ     h'03'           ; CW: NG
CW_TO1  equ     h'07'           ; CW: TO1
CW_TO2  equ     h'0b'           ; CW: TO2
CW_ON   equ     h'0f'           ; CW: ON
CW_OFF  equ     h'12'           ; CW: OFF
CW_N17  equ     h'16'           ; CW: NHRC 17 message.
BP_ALM  equ     h'24'           ; beep: alarm tone
        
;
; CW sender constants
;

CWDIT   equ     1               ; dit length in 100 ms
CWDAH   equ     CWDIT * 3       ; dah 
CWIESP  equ     CWDIT           ; inter-element space
CWILSP  equ     CWDAH           ; inter-letter space
CWIWSP  equ     CWDIT * 7       ; inter-word space

        IFDEF SIMULATOR
T0PRE   equ     D'127'          ; timer 0 preset for overflow in 127 counts, FAST.
        ELSE
T0PRE   equ     D'7'            ; timer 0 preset for overflow in 250 counts.
        ENDIF
        
; Alarm timer values
ALM_DBC equ     d'4'            ; alarm debounce counts.

CT_DBC  equ     d'3'            ; CT4/5/6 debounce counts. ms.
        
; chicken burst
CKNBRST equ     d'25'           ; 250 msec chicken burst.

;
; Serial control constants
;
SCATTN  equ     h'3a'           ; attention character, :
        
SCREAD  equ     h'52'           ; read command R
SCWRITE equ     h'57'           ; write command W
SCRESET equ     h'21'           ; reset command '!'
SCTERM  equ     h'0d'           ; command terminator <CR>
SCACK   equ     h'4b'           ; ACK message K
SCNAK   equ     h'4e'           ; NAK message N
SCCR    equ     h'0d'           ; CR
SCLF    equ     h'0a'           ; LF
        

; ***************
; ** VARIABLES **
; ***************
        cblock  h'20'           ; 1st block of RAM at 20h-7fh (96 bytes here)
        ;; port 1 receiver
        rx1flag                 ; 20 receiver 1 flags
        rx1stat                 ; 21 receiver 1 state
        rx1dbc                  ; 22 receiver 1 debounce timer
        rx1tout                 ; 23 receiver 1 timeout timer, in seconds
        mute1Tmr                ; 24 receiver 1 DTMF muting timer, in tenths.
        dt1atmr                 ; 25 receiver 1 DTMF access timer
        ;; port 1 transmitter
        tx1flag                 ; 26 Transmitter 1 control flag
        tx1flg2                 ; 27 Transmitter 1 control flag
        beep1tmr                ; 28 beeper 1 interval timer
        beep1ton                ; 29 beeper 1 tone
        beep1tnt                ; 2a beeper 1 tone timer
        beep1adr                ; 2b beeper 1 address for various beepings, low byte.
        beep1ctl                ; 2c beeper 1 control flag
        id1tmr                  ; 2d transmitter 1 id timer, in 10 seconds
        hang1tmr                ; 2e transmitter 1 hang timer, in tenths.
        tx1ctd                  ; 2f tx1 ct front porch delay
        cw1tmr                  ; 30 CW element timer
        cw1byte                 ; 31 CW current byte (bitmap)
        cw1tbtmr                ; 32 CW timebase timer
        cw1tone                 ; 33 CW tone 
        ct1tone                 ; 34 courtesy tone to play
        ulk1Tmr                 ; 35 unlocked mode timer.
        cb1Tmr                  ; 36 transmitter 1 chicken burst timer
        cw1spd                  ; 37 CW speed
        
        ;; port 2 receiver
        rx2flag                 ; 38 receiver 1 flags
        rx2stat                 ; 39 receiver 2 state
        rx2dbc                  ; 3a receiver 2 debounce timer
        rx2tout                 ; 3b receiver 2 timeout timer, in seconds
        mute2Tmr                ; 3c receiver 2 DTMF muting timer, in tenths.
        dt2atmr                 ; 3d receiver 2 DTMF access timer
        ;; port 2 transmitter
        tx2flag                 ; 3e transmitter 2 control flag
        tx2flg2                 ; 3f transmitter 2 control flag
        beep2tmr                ; 40 beeper 2 timer
        beep2ton                ; 41 beeper 2 tone 
        beep2tnt                ; 42 beeper 2 tone timer
        beep2adr                ; 43 beeper 2 address for various beepings, low byte.
        beep2ctl                ; 44 beeper 2 control flag
        id2tmr                  ; 45 transmitter 2 id timer, in 10 seconds
        hang2tmr                ; 46 transmitter 2 hang timer, in tenths.
        tx2ctd                  ; 47 tx2 ct front porch delay
        cw2tmr                  ; 48 CW element timer
        cw2byte                 ; 49 CW current byte (bitmap)
        cw2tbtmr                ; 4a CW timebase timer
        cw2tone                 ; 4b CW tone 
        ct2tone                 ; 4c courtesy tone to play
        ulk2Tmr                 ; 4d unlocked mode timer.
        cb2Tmr                  ; 4e transmitter 2 chicken burst timer
        cw2spd                  ; 4f CW speed
        endc

        cblock  h'50'           ; RAM block

        flags                   ; 50 receivers activity flag
        ;; internal timing generation
        oneMsC                  ; 51 one millisecond counter
        tenMsC                  ; 52 ten milliseconds counter
        hundMsC                 ; 53 hundred milliseconds counter
        thouMsC                 ; 54 thousand milliseconds counter (1 sec)
        temp                    ; 55 working storage. don't use in int handler.
        temp2                   ; 56 more working storage
        temp3                   ; 57 still more temporary storage
        temp4                   ; 58 yet still more temporary storage
        temp5                   ; 59 temporary storage...
        temp6                   ; 5a temporary storage...
        ;; operating flags
        fanTmr                  ; 5b fan timer
        pulsTmr                 ; 5c pulse timer.
        cmdSize                 ; 5d # digits received for current command
        eeAddr                  ; 5e EPROM address (low byte) to read/write
        eeCount                 ; 5f number of bytes to read/write from EEPROM
        endc                    ; this block ends at 5f
        
        cblock  h'60'           ; 60 to 6f is 16 control flag bytes.
                                ; but, since there are only 10, use 10! 
        ;; control operator control flag groups
        group0                  ; 60 group 0 flags
        group1                  ; 61 group 1 flags
        group2                  ; 62 group 2 flags
        group3                  ; 63 group 3 flags
        group4                  ; 64 group 4 flags
        group5                  ; 65 group 5 flags
        group6                  ; 66 group 6 flags
        group7                  ; 67 group 7 flags
        group8                  ; 68 group 8 flags
        group9                  ; 69 group 9 flags
        serFlag                 ; 6a serial interface control flags
        echoCh                  ; 6b character to echo.
        endc                    ; this block ends at 6f

        cblock  h'70'           ; from 70 to 7f is common to all banks!
        rICD70                  ; 70 reserved for ICD2
        dt1ptr                  ; 71  DTMF-1 buffer pointer
        dt1tmr                  ; 72  DTMF-1 buffer timer
        dt2ptr                  ; 73  DTMF-2 buffer pointer
        dt2tmr                  ; 74  DTMF-2 buffer timer
        txHead                  ; 75  serial transmitter buffer head pointer.
        txTail                  ; 76  serial transmitter buffer tail pointer.
        rxHead                  ; 77  serial receiver buffer head pointer.
        rxTail                  ; 78  serial receiver buffer head pointer.
        dtRFlag                 ; 79  DTMF receive flag...
        dtEFlag                 ; 7a  DTMF command interpreter control flag
        eebPtr                  ; 7b  eebuf write pointer.
        tFlags                  ; 7c  Timer Flags
        ;; interrupt pseudo-stack to save context during interrupt processing.
        s_copy                  ; 7d  saved STATUS
        p_copy                  ; 7e  saved PCLATH
        w_copy                  ; 7f  saved W register for interrupt handler
        endc                    ; 1st RAM block ends at 7f

        cblock  h'a0'           ; 2nd block of RAM at a0h-efh (80 bytes here)
        alrmTmr                 ; a0 alarm beeper timer.
        alrmDbc                 ; a1 alarm debounce timer.
        stateNo                 ; a2 the last state loaded.
        ct4dbc                  ; a3 ct4sel debounce timer
        ct5dbc                  ; a4 ct5sel debounce timer
        ct6dbc                  ; a5 ct6sel debounce timer
        endc
        
        cblock  h'b0'           ; from b0 to ef is use for serial buffers.

        txBuf00                 ; b0 serial transmit buffer (32 bytes)
        txBuf01                 ; b1 serial transmit buffer
        txBuf02                 ; b2 serial transmit buffer
        txBuf03                 ; b3 serial transmit buffer
        txBuf04                 ; b4 serial transmit buffer
        txBuf05                 ; b5 serial transmit buffer
        txBuf06                 ; b6 serial transmit buffer
        txBuf07                 ; b7 serial transmit buffer
        txBuf08                 ; b8 serial transmit buffer
        txBuf09                 ; b9 serial transmit buffer
        txBuf0a                 ; ba serial transmit buffer
        txBuf0b                 ; bb serial transmit buffer
        txBuf0c                 ; bc serial transmit buffer
        txBuf0d                 ; bd serial transmit buffer
        txBuf0e                 ; be serial transmit buffer
        txBuf0f                 ; bf serial transmit buffer
        txBuf10                 ; c0 serial transmit buffer
        txBuf11                 ; c1 serial transmit buffer
        txBuf12                 ; c2 serial transmit buffer
        txBuf13                 ; c3 serial transmit buffer
        txBuf14                 ; c4 serial transmit buffer
        txBuf15                 ; c5 serial transmit buffer
        txBuf16                 ; c6 serial transmit buffer
        txBuf17                 ; c7 serial transmit buffer
        txBuf18                 ; c8 serial transmit buffer
        txBuf19                 ; c9 serial transmit buffer
        txBuf1a                 ; ca serial transmit buffer
        txBuf1b                 ; cb serial transmit buffer
        txBuf1c                 ; cc serial transmit buffer
        txBuf1d                 ; cd serial transmit buffer
        txBuf1e                 ; ce serial transmit buffer
        txBuf1f                 ; cf serial transmit buffer

        rxBuf00                 ; d0 serial receive buffer (32 bytes)
        rxBuf01                 ; d1 serial receive buffer
        rxBuf02                 ; d2 serial receive buffer
        rxBuf03                 ; d3 serial receive buffer
        rxBuf04                 ; d4 serial receive buffer
        rxBuf05                 ; d5 serial receive buffer
        rxBuf06                 ; d6 serial receive buffer
        rxBuf07                 ; d7 serial receive buffer
        rxBuf08                 ; d8 serial receive buffer
        rxBuf09                 ; d9 serial receive buffer
        rxBuf0a                 ; da serial receive buffer
        rxBuf0b                 ; db serial receive buffer
        rxBuf0c                 ; dc serial receive buffer
        rxBuf0d                 ; dd serial receive buffer
        rxBuf0e                 ; de serial receive buffer
        rxBuf0f                 ; df serial receive buffer
        rxBuf10                 ; e0 serial receive buffer
        rxBuf11                 ; e1 serial receive buffer
        rxBuf12                 ; e2 serial receive buffer
        rxBuf13                 ; e3 serial receive buffer
        rxBuf14                 ; e4 serial receive buffer
        rxBuf15                 ; e5 serial receive buffer
        rxBuf16                 ; e6 serial receive buffer
        rxBuf17                 ; e7 serial receive buffer
        rxBuf18                 ; e8 serial receive buffer
        rxBuf19                 ; e9 serial receive buffer
        rxBuf1a                 ; ea serial receive buffer
        rxBuf1b                 ; eb serial receive buffer
        rxBuf1c                 ; ec serial receive buffer
        rxBuf1d                 ; ed serial receive buffer
        rxBuf1e                 ; ee serial receive buffer
        rxBuf1f                 ; ef serial receive buffer
        endc                    ; end block c0-ef
        


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

        ;; 16F87x ram blocks continue...
        cblock  h'110'          ; 16 bytes at 110h-11fh
        endc
        
        cblock  h'120'          ; 80 bytes 120h-16fh
        dt1buf0                 ; DTMF-1 receiver buffer (16 bytes) @ 120
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
        dt2buf0                 ; DTMF-2 receiver buffer (16 bytes) @ 130
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
        eebuf00                 ; eeprom write buffer (16 bytes) @ 140
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
        eebuf0f                 ; buffers end at 014f
        endc
        ;;
        ;;  there is room here from 0150 - 016f
        ;; 
        cblock  h'170'          ; 0170 this is common with 70-7f
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

        ;;
        ;;  there is room here from 01c0 to 01ef
        ;; 

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

        btfss   INTCON,T0IF     ; is it a timer interrupt?
        goto    INotTmr0        ; no

        ;;  process timer 0 interrupt.
        movlw   T0PRE           ; get timer 0 preset value
        movwf   TMR0            ; preset timer 0
        bsf     tFlags,TICK     ; set tick indicator flag
        bcf     INTCON,T0IF     ; clear RTCC int mask

INotTmr0                        ; no timer interrupt.
        btfss   PIR1,CCP1IF     ; is there a timer 1/compare interrupt?
        goto    INotTmr1

        ;; process timer 1 interrupt.
        clrf    TMR1L           ; clear timer 1
        clrf    TMR1H           ; clear timer 1
        bcf     PIR1,CCP1IF     ; clear compare match interrupt bit.
        btfss   PORTC,BEEP1     ; is beep1 hi?
        goto    ITmr11          ; no.
        bcf     PORTC,BEEP1     ; lower beep bit.
        goto    INotTmr1        ; done.
ITmr11                          ; beep bit was low.
        bsf     PORTC,BEEP1     ; raise beep bit.

INotTmr1                        ; end of timer 1 interrupt code.
        btfss   PIR1,TMR2IF     ; is there a timer 2 interrupt?
        goto    INotTmr2        ; no.

        ;; process timer 2 interrupt.
        ;; 101.6 us (.1016 ms)
        bcf     PIR1,TMR2IF     ; clear timer 2 interrupt bit.
        btfss   PORTC,BEEP2     ; is beep bit set?
        goto    ITmr21          ; no.
        bcf     PORTC,BEEP2     ; reset beep bit.
        goto    INotTmr2        ; done.
ITmr21                          ; set beep bit
        bsf     PORTC,BEEP2     ; set beep bit

INotTmr2                        ; end of timer 2 interrupt code.
        btfss   PIR1,RCIF       ; is it a USART Receive interrupt?
        goto    INotUSR         ; nope

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
        sublw   SCATTN          ; subtract serial attention character.
        btfss   STATUS,Z        ; skip if zero -- is cmd initiator
        goto    INotCmd         ; not the command initiator
        clrf    rxHead          ; preamble.  Reset to start of buffer.
        bsf     serFlag,SC_CMD  ; set the in-command no-echo flag
        
INotCmd
        btfsc   serFlag,SC_CMD  ; want to echo chars?
        goto    INoEcho         ; nope.
        movf    INDF,w          ; get received character back.
        movwf   echoCh          ; save this character for echo
        bsf     serFlag,SC_ECHO ; mark for echo

INoEcho
        movf    INDF,w          ; get received character back.
        sublw   SCTERM          ; subtract serial EOM character.
        btfsc   STATUS,Z        ; skip if non-zero.
        bsf     serFlag,SC_RDY  ; end of message received, ready to process.

INotUSR                         ; end of USART receive interrupt code.

        btfss   PIR1,TXIF       ; is it a USART transmit interrupt?
        goto    INotUST         ; nope
        
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

INotUST                         ; end of USART transmit interrupt code.


IntExit
        ;; clean up and return from interrupt.
        movf    p_copy,w        ; get PCLATH preserved value
        movwf   PCLATH          ; restore PCLATH
        swapf   s_copy,w        ; get STATUS preserved value
        movwf   STATUS          ; restore STATUS
        swapf   w_copy,f        ; swap W
        swapf   w_copy,w        ; restore W
        retfie                  ; return from interrupt.

; ***********************************************
; ** This is the end of the interrupt handler. **
; ***********************************************

;;; these are page 0 subroutines.
                
;
; send the ID message, reset ID timers & flags
;
DoID1
        btfss   group4,3        ; is ID enabled for tx1?
        goto    NoID1           ; no.
        btfss   tx1flg2,NEEDID  ; need to ID?
        return                  ; nope--id timer expired without tx since last
        ;; play the ID here.
        movlw   EECWID1         ; address of CW ID message in EEPROM.
        btfsc   group4,4        ; is ID2 selected?
        movlw   EECWID2         ; yes.
        movwf   eeAddr          ; save CT base address
        PAGE3                   ; select code page 3.
        call    PlayCWe1        ; kick of the CW playback.
        PAGE0                   ; select code page 0.
        
        movlw   EETID1          ; get EEPROM address of ID timer preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   id1tmr          ; store to id1tmr down-counter
        bcf     tx1flg2,INITID  ; always reset initial ID flag
        movf    tx1flag,w       ; get tx flags
        andlw   b'00000011'     ; w=w&(RX1TX|RX2TX), non zero if RX active.
        btfsc   STATUS,Z        ; is it zero?
        bcf     tx1flg2,NEEDID  ; yes. reset NEEDID flag.
        return

NoID1
        clrf    id1tmr          ; clear id timer
        bcf     tx1flg2,INITID  ; clear INITID flag
        bcf     tx1flg2,NEEDID  ; clear NEEDID flag

;
; send the ID message, reset ID timers & flags
;
DoID2
        btfss   group5,3        ; is ID enabled for tx1?
        goto    NoID2           ; no.
        btfss   tx2flg2,NEEDID  ; need to ID?
        return                  ; nope--id timer expired without tx since last
        ;; play the ID here.
        movlw   EECWID1         ; address of CW ID message in EEPROM.
        btfsc   group5,4        ; is ID2 selected?
        movlw   EECWID2         ; yes.
        movwf   eeAddr          ; save CT base address
        PAGE3                   ; select code page 3.
        call    PlayCWe2        ; kick of the CW playback.
        PAGE0                   ; select code page 0.
        movlw   EETID2          ; get EEPROM address of ID timer preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   id2tmr          ; store to id2tmr down-counter
        bcf     tx2flg2,INITID  ; always reset initial ID flag
        movf    tx2flag,w       ; get tx flags
        andlw   b'00000011'     ; w=w&(RX1TX|RX2TX), non zero if RX active.
        btfss   STATUS,Z        ; is it zero?
        return                  ; no, not zero.
        bcf     tx2flg2,NEEDID  ; yes. reset NEEDID flag.
        return

NoID2
        clrf    id2tmr          ; clear id timer
        bcf     tx2flg2,INITID  ; clear INITID flag
        bcf     tx2flg2,NEEDID  ; clear NEEDID flag

Rcv1Off                         ; turn off receiver 0
        movlw   RXSOFF          ; get new state #
        movwf   rx1stat         ; set new receiver state
        bcf     PORTB,RX11AUD   ; mute rx1 into tx1 audio
        bcf     PORTB,RX12AUD   ; mute rx1 into tx2 audio
        bcf     tx1flag,RX1TX   ; clear rx1 into tx1 bit
        bcf     tx2flag,RX1TX   ; clear rx1 into tx2 bit
        clrf    mute1Tmr        ; clear muting timer
        clrf    rx1tout         ; clear main receiver timeout timer
        return                  ; done here.
        
Rcv2Off                         ; turn off receiver 2
        movlw   RXSOFF          ; get new state #
        movwf   rx2stat         ; set new receiver state
        bcf     PORTB,RX21AUD   ; mute rx1 into tx1 audio
        bcf     PORTB,RX22AUD   ; mute rx2 into tx2 audio
        bcf     tx1flag,RX2TX   ; clear rx1 into tx1 bit
        bcf     tx2flag,RX2TX   ; clear rx1 into tx2 bit
        clrf    mute2Tmr        ; clear muting timer
        clrf    rx2tout         ; clear main receiver timeout timer
        return                  ; done here.

SetHang1                        ; start hang timer for tx1...
        btfss   group4,1        ; is hang timer enabled?
        return                  ; nope.
        movlw   EETHTS          ; get EEPROM address of hang timer short preset
        btfsc   group4,2        ; is long hang timer selected?
        movlw   EETHTL          ; get EEPROM address of hang timer long preset
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   hang1tmr        ; preset hang timer
        btfss   STATUS,Z        ; is hang timer zero.
        bsf     tx1flag,HANG    ; no, set hang time transmit flag
        return                  ; done.

SetHang2                        ; start hang timer for tx1...
        btfss   group5,1        ; is hang timer enabled?
        return                  ; nope.
        movlw   EETHTS          ; get EEPROM address of hang timer short preset
        btfsc   group5,2        ; is long hang timer selected?
        movlw   EETHTL          ; get EEPROM address of hang timer long preset
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   hang2tmr        ; preset hang timer
        btfss   STATUS,Z        ; is hang timer zero.
        bsf     tx2flag,HANG    ; no, set hang time transmit flag
        return                  ; done.

SetCT1                          ; start CT timer, transmitter 1
        incf    ct1tone,w       ; check ct1tone for FF
        btfsc   STATUS,Z        ; is result 0?
        return                  ; yes, ct1tone was FF.
        movlw   EECT1BO         ; get EEPROM address of tx1 ct front porch.
        movwf   eeAddr          ; set EEPROM address.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   tx1ctd          ; preset tx1 ct front porch timer.
        btfss   STATUS,Z        ; is the front porch timer zero?
        bsf     tx1flag,CTDELAY ; set the tx flag indicator.
        return                  ; done here.

SetCT2                          ; start CT timer, transmitter 2
        incf    ct2tone,w       ; check ct2tone for FF
        btfsc   STATUS,Z        ; is result 0?
        return                  ; yes, ct1tone was FF.
        movlw   EECT2BO         ; get EEPROM address of tx1 ct front porch
        movwf   eeAddr          ; set EEPROM address.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   tx2ctd          ; preset tx1 ct front porch timer.
        btfss   STATUS,Z        ; is the front porch timer zero?
        bsf     tx2flag,CTDELAY ; set the tx flag indicator.
        return                  ; done here.

ChkID1                          ; call on receiver drop to see if want to ID
        btfsc   tx1flg2,INITID  ; check initial ID flag
        call    DoID1           ; play the ID
        btfss   tx1flg2,NEEDID  ; need to ID?
        return
        ;
        ;if (id1tmr <= idSoon) then goto StartID
        ;implemented as: if ((IDSOON-idTimer)>=0) then ID
        ;
        movf    id1tmr,w        ; get id1tmr into W
        sublw   IDSOON          ; IDSOON-w ->w
        btfsc   STATUS,C        ; C is clear if result is negative
        call    DoID1           ; ok to ID now, let's do it.
        return                  ; don't need to ID yet...

ChkID2                          ; call on receiver drop to see if want to ID
        btfsc   tx2flg2,INITID  ; check initial ID flag
        call    DoID2           ; play the ID
        btfss   tx2flg2,NEEDID  ; need to ID?
        return
        ;
        ;if (id1tmr <= idSoon) then goto StartID
        ;implemented as: if ((IDSOON-idTimer)>=0) then ID
        ;
        movf    id2tmr,w        ; get id1tmr into W
        sublw   IDSOON          ; IDSOON-w ->w
        btfsc   STATUS,C        ; C is clear if result is negative
        call    DoID2           ; ok to ID now, let's do it.
        return                  ; don't need to ID yet...

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
        bsf     STATUS,RP0      ; select bank 1

        movlw   b'00000000'
        movwf   ADCON0
        movlw   b'00000111'
        movwf   ADCON1
        
        movlw   b'10000011'     ; RBPU pull ups ON=0, breaks ICD3.
                                ; INTEDG INT on falling edge
                                ; T0CS   TMR0 uses instruction clock
                                ; T0SE  n/a
                                ; PSA TMR0 gets the prescaler 
                                ; PS2 \
                                ; PS1  > prescaler 16
                                ; PS0 /
        movwf   OPTION_REG      ; set options

        movlw   B'11011111'     ; na/na/out/in/in/in/in/in
        movwf   TRISA           ; set port A data direction

        movlw   B'00000000'     ; out/out/out/out/out/out/out/out
        movwf   TRISB           ; set port B data direction

        movlw   B'11111100'     ; in/in/in/in/in/in/out/out
        movwf   TRISC           ; set port C data direction

        movlw   B'00001111'     ; out/out/out/out/in/in/in/in
        movwf   TRISD           ; set port D data direction
        movlw   B'00000011'     ; out/out/out/out/out/out/in/in
        movwf   TRISE           ; set port E data direction
        
        IFDEF  __16F887
        bsf     STATUS,RP1      ; select register page 2/3
        clrf    ANSEL           ; clear analog select
        clrf    ANSELH          ; clear analog select
        bcf     STATUS,RP1      ; select register page 0/1
        ENDIF

        ; set up serial port, part 1

        movlw   b'11000000'     ; SMP=1 CKE=1
        movwf   SSPSTAT         ; input data on falling edge, output on rising
        movlw   d'103'          ; 9600 baud at 16.0 MHz clock.
        movwf   SPBRG           ; set baud rate generator.
        movlw   b'00100100'     ; transmit enabled, hi speed async.
        movwf   TXSTA           ; set transmit status and control register.
        movlw   b'00100110'     ; USART rx interrupt enabled.
                                ; interrupt on CCP1 or TMR2.
        movwf   PIE1            ; set peripheral interrupts enable register.

        bcf     STATUS,RP0      ; select bank 0

        movlw   b'10010000'     ; serial enabled, etc.
        movwf   RCSTA           ; set receive status and control register.

        ;; PORT A does not need to be initialized, it is input-only.
        clrf    PORTA           ; turn fan off
        clrf    PORTB           ; preset PORTB all off.
        clrf    PORTC           ; preset PORTC.
        clrf    PORTD
        clrf    PORTE
        
        clrwdt                  ; give me more time to get up and running.

        ;; set up timer 1
        movlw   b'00000000'     ; set up timer 1.
        movwf   T1CON           ; set up timer 1.
        movlw   b'00001010'     ; timer 1 compare throws interrupt.
        movwf   CCP1CON         ; set up compare mode.
        movlw   h'ff'           ; init compare value.
        movwf   CCPR1L          ; set up initial compare (invalid)
        movwf   CCPR1H          ; set up initial compare (invalid)
        
        ;; set up timer 2
        ;; timer 2 is shut off
        clrf    T2CON           ; set up timer 2.
        
        ;; enable interrupts.
        movlw   b'11100000'     ; enable global + peripheral + timer0
        movwf   INTCON

        btfsc   PORTA,INIT      ; skip if init button pressed.
        goto    Start1          ; no initialize request.
        
; *********************
; * INITIALIZE EEPROM *
; *********************
                
        clrf    temp2           ; byte index
InitLp
        movf    temp2,w         ; get init address
        movwf   eeAddr          ; set eeprom address
        movf    temp2,w         ; get init address
        PAGE3                   ; select page 3
        call    InitDat         ; get init byte
        call    WriteEw         ; write byte to EEPROM.
        PAGE0                   ; select page 0
        incfsz  temp2,f         ; skip to next byte till all 256 are done.
        goto    InitLp          ; get the next block of 16 or be done.
        
; ********************************
; ** Ready to really start now. **
; ********************************
Start1
        ;; 
        ;; clear memory
        ;; 
        bcf     STATUS,IRP      ; select FSR is in 00-ff range
        movlw   h'20'           ; first address of RAM.
        movwf   FSR             ; set pointer.
ClrMem                          ; clear memory.
        clrf    INDF            ; clear ram byte.
        incf    FSR,f           ; increment FSR.
        btfss   FSR,7           ; cheap test for address 80 and above.
        goto    ClrMem          ; loop some more.
        ; now clear from a0 to ff
        movlw   h'a0'           ; first address of RAM.
        movwf   FSR             ; set pointer.
ClrMem1                         ; clear more memory.
        clrf    INDF            ; clear ram byte.
        incfsz  FSR,f           ; increment FSR.
        goto    ClrMem1         ; loop some more.
        bsf     STATUS,IRP      ; select FSR is in 100-1ff range

        ;; 
        ;; preset stuff that needs to be non-zero
        ;; 
        movlw   TEN             ; get timebase presets
        movwf   oneMsC
        movwf   tenMsC
        movwf   hundMsC
        movwf   thouMsC
        clrf    tFlags

        movlw   CTNONE          ; no courtesy tone.
        movwf   ct1tone         ; set courtesy tone selector.
        movwf   ct2tone         ; set courtesy tone selector.

        ;; 
        ;; load eeprom data, saved state 0
        ;; 
        clrw                    ; select macro set 0.
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        call    CWParms         ; get the CW Parameters.
        PAGE0                   ; select page 0
        
        ;;
        ;; say hello to all the nice people out there.
        ;;
        PAGE3                   ; select code page 3.
        movlw   CW_N17          ; get controller name announcement.
        call    PlayCW1         ; start playback
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
        bsf     tFlags,TENSEC   ; set TENSEC indicator.

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
        CLRWDT

Loop1
        ;; LED BLINKER.
        ;btfss   tFlags,HUNDMS  ; DEBUG!!!
        ;goto    LedEnd
        ;btfss   PORTD,5
        ;goto    l3off
        ;bcf     PORTD,5
        ;goto    LedEnd
l3off 
        ;bsf     PORTD,5
LedEnd
        
; ********************************************
; ** RECEIVER DEBOUNCE AND INPUT VALIDATION **
; ********************************************
DebRx
        btfss   tFlags,ONEMS    ; is the one ms tick active?
        goto    OneMsD          ; nope
CkRx1                           ; check COR state receiver 1
        btfss   PORTE,RX1COR    ; check cor receiver 1
        goto    Rx1COR1         ; it's low, COR is present
                                ; COR is not present.
        btfss   group0,2        ; (NOT) OR PL? (dual squelch)
        goto    Rx1Off          ; nope...
        goto    Rx1CkPL         ; yes, OR PL mode
Rx1COR1
        btfss   group0,1        ; AND PL set? (CTCSS required)
        goto    Rx1On           ; no.
Rx1CkPL                         ; check PL...
        btfsc   PORTE,RX1PL     ; is the PL signal present?
        goto    Rx1Off          ; no.
Rx1On                           ; the COR and PL requirements have been met
        btfsc   flags,RX1USQ    ; already marked active?
        goto    Rx1NC           ; yes.
        movf    rx1dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx11Dbc         ; nope...
        movlw   COR1DEB         ; get COR debounce timer value.
        btfsc   group1,4        ; is the delay present?
        movlw   DLY1DEB         ; get COR debounce with delay value.

        btfss   group1,0        ; is the kerchunker delay set?
        goto    Rx1SDeb         ; no.
        btfss   group0,6        ; is rx1->tx1 enabled?
        goto    Rx1CC2          ; no, check rx1->tx2 then.
        movf    tx1flag,f       ; check for transmitter already on.
        btfss   STATUS,Z        ; is the transmitter already on?
        goto    Rx1SDeb         ; yep.
Rx1CC2
        btfss   group0,7        ; is rx1->tx2 enabled?
        goto    Rx1CCD          ; no, going to use the kerchunker delay.
        movf    tx2flag,f       ; check for transmitter already on.
        btfsc   STATUS,Z        ; is the transmitter already on?
Rx1CCD                          ; going to use the kerchunker delay.
        movlw   CHNKDEB         ; get kerchunker filter delay.
Rx1SDeb                         ; set debounce timer.
        movwf   rx1dbc          ; set it
        goto    Rx1Done         ; done.
Rx11Dbc
        decfsz  rx1dbc,f        ; decrement the debounce counter
        goto    Rx1Done         ; not zero yet
        bsf     flags,RX1USQ    ; set receiver active flag
        goto    Rx1Done         ; continue...
Rx1Off                          ; the COR and PL requirements have not been met
        btfss   flags,RX1USQ    ; was the receiver off before?
        goto    Rx1NC           ; yes.
        movf    rx1dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx10Dbc         ; nope...
        movlw   COR0DEB         ; get COR debounce timer value.
        btfsc   group1,4        ; is the delay present?
        movlw   DLY0DEB         ; get COR debounce with delay value.
        movwf   rx1dbc          ; set it
        goto    Rx1Done         ; done.
Rx10Dbc
        decfsz  rx1dbc,f        ; decrement the debounce counter
        goto    Rx1Done         ; not zero yet
        bcf     flags,RX1USQ    ; clear receiver active flag
        movf    dt1tmr,f        ; test to see if touch-tones received...
        btfsc   STATUS,Z        ; is it zero?
        goto    Rx1Done         ; yes. don't need to accellerate execution.
        movlw   d'2'            ; no
        movwf   dt1tmr          ; accelerate eval of DTMF command
        goto    Rx1Done         ; continue...
Rx1NC
        clrf    rx1dbc          ; clear debounce counter.
Rx1Done

CkRx2                           ; check COR state receiver 2
        btfss   PORTC,RX2COR    ; check cor receiver 2
        goto    Rx2COR1         ; it's low, COR is present
                                ; COR is not present.
        btfss   group2,2        ; (NOT) OR PL? (DUAL SQUELCH)
        goto    Rx2Off          ; nope...
        goto    Rx2CkPL         ; yes, OR PL mode
Rx2COR1
        btfss   group2,1        ; AND PL set?
        goto    Rx2On           ; no.
Rx2CkPL                         ; check PL...
        btfsc   PORTC,RX2PL     ; is the PL signal present?
        goto    Rx2Off          ; no.
Rx2On                           ; the COR and PL requirements have been met
        btfsc   flags,RX2USQ    ; already marked active?
        goto    Rx2NC           ; yes.
        movf    rx2dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx21Dbc         ; nope...
        movlw   COR1DEB         ; get COR debounce timer value
        btfsc   group3,4        ; is the delay present?
        movlw   DLY1DEB         ; get COR debounce with delay value.

        btfss   group3,0        ; is the kerchunker delay set?
        goto    Rx2SDeb         ; no.
        btfss   group2,6        ; is rx2->tx1 enabled?
        goto    Rx2CC2          ; no, check rx2->tx2 then.
        movf    tx1flag,f       ; check for transmitter already on.
        btfss   STATUS,Z        ; is the transmitter already on?
        goto    Rx2SDeb         ; yep.
Rx2CC2
        btfss   group2,7        ; is rx2->tx2 enabled?
        goto    Rx2CCD          ; no, going to use the kerchunker delay.
        movf    tx2flag,f       ; check for transmitter already on.
        btfsc   STATUS,Z        ; is the transmitter already on?
Rx2CCD                          ; going to use the kerchunker delay.
        movlw   CHNKDEB         ; get kerchunker filter delay.
Rx2SDeb                         ; set debounce timer.
        movwf   rx2dbc          ; set it
        goto    Rx2Done         ; done.
Rx21Dbc
        decfsz  rx2dbc,f        ; decrement the debounce counter
        goto    Rx2Done         ; not zero yet
        bsf     flags,RX2USQ    ; set receiver active flag
        goto    Rx2Done         ; continue...
Rx2Off                          ; the COR and PL requirements have not been met
        btfss   flags,RX2USQ    ; was the receiver off before?
        goto    Rx2NC           ; yes.
        movf    rx2dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx20Dbc         ; nope...
        movlw   COR0DEB         ; get COR debounce timer value.
        btfsc   group3,4        ; is the delay present?
        movlw   DLY0DEB         ; get COR debounce with delay value.
        movwf   rx2dbc          ; set it
        goto    Rx2Done         ; done.
Rx20Dbc
        decfsz  rx2dbc,f        ; decrement the debounce counter
        goto    Rx2Done         ; not zero yet
        bcf     flags,RX2USQ    ; set receiver active flag
        movf    dt2tmr,f        ; test to see if touch-tones received...
        btfsc   STATUS,Z        ; is it zero?
        goto    Rx2Done         ; yes. don't need to accellerate execution.
        movlw   d'2'            ; no
        movwf   dt2tmr          ; accelerate eval of DTMF command
        goto    Rx2Done         ; done.
Rx2NC
        clrf    rx2dbc          ; clear debounce counter.
Rx2Done

        ;; debounce CT4SEL, CT5SEL, and CT6SEL here
        btfss   group1,3        ; is CTSEL state change enabled?
        goto    NoCtSC          ; nope
        
CkCt4                           ; check CT4SEL state
        btfss   PORTD,CT4SEL    ; is CT select 4 input active (low)?
        goto    CT4DB0          ; is is low
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        clrf    ct4dbc          ; clear debounce counter.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    CkCt5           ; done here
        
CT4DB0                          ; CT4 is LOW.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    ct4dbc,w        ; get ct4 debounce timer
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   CT_DBC          ; subtract CT4/5/6 debounce time.
        btfss   STATUS,C        ; skip if CT_DBC - ctXDbc is positive.
        goto    SetS1           ; possibly set state 1
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        incf    ct4dbc,f        ; increment ct4 debounce timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    CkCt5           ; done here.

SetS1
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    stateNo,f       ; get current state.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   d'1'            ; compare to state 1
        btfsc   STATUS,Z        ; is it zero?
        goto    NoCtSC          ; no state change
        movlw   d'1'            ; select state 1
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        PAGE0                   ; select page 0
        goto    NoCtSC          ; done for now.
        
CkCt5                           ; check CT5SEL state
        btfss   PORTD,CT5SEL    ; is CT select 5 input active (low)?
        goto    CT5DB0          ; is is low
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        clrf    ct5dbc          ; clear debounce counter.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    CkCt6           ; done here
        
CT5DB0                          ; CT4 is LOW.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    ct5dbc,w        ; get ct5 debounce timer
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   CT_DBC          ; subtract CT4/5/6 debounce time.
        btfss   STATUS,C        ; skip if CT_DBC - ctXDbc is positive.
        goto    SetS2           ; possibly set state 1
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        incf    ct5dbc,f        ; increment ct4 debounce timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    CkCt6           ; done here.

SetS2
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    stateNo,f       ; get current state.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   d'2'            ; compare to state 2
        btfsc   STATUS,Z        ; is it zero?
        goto    NoCtSC          ; no state change
        movlw   d'2'            ; select state 2
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        PAGE0                   ; select page 0
        goto    NoCtSC          ; done for now.

CkCt6                           ; check CT6SEL state
        btfss   PORTD,CT6SEL    ; is CT select 6 input active (low)?
        goto    CT6DB0          ; is is low
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        clrf    ct6dbc          ; clear debounce counter.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    NoCtSC          ; done here
        
CT6DB0                          ; CT4 is LOW.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    ct6dbc,w        ; get ct6 debounce timer
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   CT_DBC          ; subtract CT4/5/6 debounce time.
        btfss   STATUS,C        ; skip if CT_DBC - ctXDbc is positive.
        goto    SetS3           ; possibly set state 1
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        incf    ct6dbc,f        ; increment ct6 debounce timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    NoCtSC          ; done here.

SetS3
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    stateNo,f       ; get current state.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   d'3'            ; compare to state 3
        btfsc   STATUS,Z        ; is it zero?
        goto    NoCtSC          ; no state change
        movlw   d'3'            ; select state 3
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        PAGE0                   ; select page 0
        goto    NoCtSC          ; done for now.
        
NoCtSC  
OneMsD                          ; one ms timer tic processing done
        
        btfss   tFlags,TENMS    ; is the ten ms tick active?
        goto    TenMsD          ; nope
        
        ;; ******************************
        ;; ** debounce the alarm input **
        ;; ******************************
        btfss   group6,3        ; is the alarm enabled?
        goto    CkAlDon         ; no.  ignore all this.
        btfss   PORTD,ALARM     ; is alarm bit off?
        goto    DebAlm          ; no.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        clrf    alrmDbc         ; clear debounce counter.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    CkAlDon         ; done here.
DebAlm                          ; debounce alarm input.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    alrmDbc,w       ; get alarm debounce timer
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        sublw   ALM_DBC         ; subtract alarm debounce time.
        btfss   STATUS,C        ; skip if ALM_DBC - alrmDbc is positive.
        goto    SetAlrm         ; it's positive.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        incf    alrmDbc,f       ; increment alarm debounce timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    CkAlDon         ; done here.
SetAlrm                         ; set the alarm tone up, if not already set.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    alrmTmr,f       ; check alarm timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        btfss   STATUS,Z        ; is it zero?
        goto    CkAlDon         ; no.  Alarm timer is already set.
        movlw   d'1'            ; immediately start alarm tone.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movwf   alrmTmr         ; save alarm timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
CkAlDon                         ; checking alarm done.
                
        ;; ******************
        ;; ** check DTMF-1 ** 
        ;; ******************
CkDTMF1 
        btfss   PORTC,DTMF1DV   ; is a DTMF digit being decoded?
        goto    CkDT1L          ; no
        btfsc   rx1flag,LASTDV  ; was it there last time?
        goto    CkDTMF2         ; yes, do nothing.
        bsf     rx1flag,LASTDV  ; set last DV indicator.

RdDT1
        btfsc   group1,6        ; muting rx1 -> tx1 enabled?
        bcf     PORTB,RX11AUD   ; mute rx1 -> tx1.
        btfsc   group1,7        ; muting rx1 -> tx2 enabled?
        bcf     PORTB,RX12AUD   ; mute rx1 -> tx2.
        movlw   MUTEDLY         ; get mute timer delay
        movwf   mute1Tmr        ; preset mute timer
RdDT1m
        movlw   DTMFDLY         ; get DTMF activity timer preset.
        movwf   dt1tmr          ; set DTMF command timer
        
        movf    dt1ptr,w        ; get index
        movwf   FSR             ; put it in FSR
        bcf     STATUS,C        ; clear carry (just in case)
        rrf     FSR,f           ; hey! divide by 2.
        movlw   LOW dt1buf0     ; get address of buffer
        addwf   FSR,f           ; add to index.

        bsf     PORTB,DTMF1OE   ; enable DTMF-0 output port.
        movlw   b'00001111'     ; mask bits.
        andwf   PORTA,w         ; get masked bits of tone into W.
        bcf     PORTB,DTMF1OE   ; disable DTMF-0 output port.
        PAGE3                   ; select code page 3.
        call    MapDTMF         ; remap tone into keystroke value..
        PAGE0                   ; select code page 0.
        iorlw   h'0'            ; OR with zero to set status bits.
        bcf     rx1flag,DTMF0   ; clear last zero received.
        btfsc   STATUS,Z        ; was a zero the last received digit?
        bsf     rx1flag,DTMF0   ; yes...
        
        btfsc   dt1ptr,0        ; is this an odd address?
        goto    DT1Odd          ; yes;
        clrf    INDF            ; zero both nibbles.
        movwf   INDF            ; save tone in indirect register.
        swapf   INDF,f          ; move the tone to the high nibble
        goto    DT1Done         ; done here
DT1Odd
        iorwf   INDF,F          ; save tone in low nibble
DT1Done 
        incf    dt1ptr,f        ; increment index
        movlw   h'1f'           ; mask
        andwf   dt1ptr,f        ; don't let index grow past 1f (31)

        goto    CkDTMF2         ; done with DTMF checking.

CkDT1L                          ; check for end of LITZ...
        btfss   rx1flag,LASTDV  ; was it low last time?
        goto    CkDTMF2         ; yes.  Done.
        bcf     rx1flag,LASTDV  ; no, clear last DV indicator.

        ;; ******************
        ;; ** check DTMF-2 ** 
        ;; ******************
CkDTMF2
        btfss   PORTC,DTMF2DV   ; is a DTMF digit being decoded?
        goto    CkDT2L          ; no
        btfsc   rx2flag,LASTDV  ; was it there last time?
        goto    CkDTDone        ; yes, do nothing.
        bsf     rx2flag,LASTDV  ; set last DV indicator.

RdDT2
        btfsc   group3,6        ; muting rx2 -> tx1 enabled?
        bcf     PORTB,RX21AUD   ; mute rx2 -> tx1.
        btfsc   group3,7        ; muting rx2 -> tx2 enabled?
        bcf     PORTB,RX22AUD   ; mute rx2 -> tx2.
        movlw   MUTEDLY         ; get mute timer delay
        movwf   mute2Tmr        ; preset mute timer
RdDT2m
        movlw   DTMFDLY         ; get DTMF activity timer preset.
        movwf   dt2tmr          ; set DTMF command timer
        
        movf    dt2ptr,w        ; get index
        movwf   FSR             ; put it in FSR
        bcf     STATUS,C        ; clear carry (just in case)
        rrf     FSR,f           ; hey! divide by 2.
        movlw   LOW dt2buf0     ; get address of buffer
        addwf   FSR,f           ; add to index.

        bsf     PORTB,DTMF2OE   ; enable DTMF-1 output port.
        movlw   b'00001111'     ; mask bits.
        andwf   PORTA,w         ; get masked bits of tone into W.
        bcf     PORTB,DTMF2OE   ; disable DTMF-1 output port.
        PAGE3                   ; select code page 3.
        call    MapDTMF         ; remap tone into keystroke value..
        PAGE0                   ; select code page 0.
        iorlw   h'0'            ; OR with zero to set status bits.
        bcf     rx2flag,DTMF0   ; clear last zero received.
        btfsc   STATUS,Z        ; was a zero the last received digit?
        bsf     rx2flag,DTMF0   ; yes...
        
        btfsc   dt2ptr,0        ; is this an odd address?
        goto    DT2Odd          ; yes;
        clrf    INDF            ; zero both nibbles.
        movwf   INDF            ; save tone in indirect register.
        swapf   INDF,f          ; move the tone to the high nibble
        goto    DT2Done         ; done here
DT2Odd
        iorwf   INDF,F          ; save tone in low nibble
DT2Done 
        incf    dt2ptr,f        ; increment index
        movlw   h'1f'           ; mask
        andwf   dt2ptr,f        ; don't let index grow past 1f (31)

        goto    CkDTDone        ; done with DTMF checking.

CkDT2L                          ; check for end of LITZ...
        btfss   rx2flag,LASTDV  ; was it low last time?
        goto    CkDTDone        ; yes.  Done.
        bcf     rx2flag,LASTDV  ; clear last DV indicator.
        
CkDTDone                        ; done with DTMF scanning.
TenMsD                          ; ten ms tasks done.

        goto    MainLp          ; crosses 256 byte boundary (to 0300)

; *************************************
; * main loop for repeater controller *
; *************************************
        
        org     0400
MainLp

; ***********************
; * Receiver processing *
; ***********************
        
DoRx1
        movlw   high Rx1Tbl     ; set high byte of address
        movwf   PCLATH          ; select page
        movf    rx1stat,w       ; get main receiver state
        addwf   PCL,f           ; add w to PCL:  computed GOTO
Rx1Tbl
        goto    Rx1Quiet        ; quiet
        goto    Rx1Rpt          ; repeat
        goto    Rx1Tmot         ; timeout

Rx1Quiet                        ; receiver quiet state
        btfss   flags,RX1USQ    ; is squelch open?
        goto    Rx1End          ; nope, don't turn receiver on
        ;; receiver is unsquelched; put it on the air
        ;; receiver inactive --> active transistion
        btfss   group0,0        ; is repeater enabled?
        goto    Rx1End          ; disabled, not gonna turn receiver on
        btfss   group0,3        ; is DTMF access mode enabled?
        goto    Rx1OffOn        ; no. start repeating.
        movf    dt1atmr,f       ; check DTMF access mode timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    Rx1End          ; yes.  Don't turn receiver on.
        ;; timer is not zero, reset to initial value.
        movlw   EETDTA          ; get EEPROM address of DTMF access timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   dt1atmr         ; set DTMF access mode timer.
Rx1OffOn                        ; receiver inactive --> active transition
        ;; check for priority
        movf    group0,w        ; get group 0 flags
        andwf   group2,w        ; and with group 2 flags
        andlw   b'11000000'     ; result is non-zero if linked.
        btfsc   STATUS,Z        ; are ports linked?
        goto    Rx101a          ; no.
        btfss   group3,5        ; does RX 2 have priority?
        goto    Rx101a          ; nope.
        movf    rx2stat,w       ; get RX 2 receiver state.
        sublw   RXSON           ; subtract ON state value.
        btfsc   STATUS,Z        ; is result zero?
        goto    Rx1End          ; yes.  RX 2 is ON. don't turn on RX1.
Rx101a
        movlw   RXSON           ; get new state #
        movwf   rx1stat         ; set new receiver state
        btfss   group0,6        ; is rx1 to tx1 enabled?
        goto    Rx101b          ; no.
        btfss   group4,5        ; is tx1 considered duplex?
        goto    Rx101b          ; no.
        bsf     tx1flag,RX1TX   ; set main receiver on bit
        movlw   CTNONE          ; no courtesy tone.
        movwf   ct1tone         ; kill off any pending courtesy tone.
        movf    mute1Tmr,f      ; check mute timer
        btfsc   STATUS,Z        ; if it's non-zero, skip unmute
        bsf     PORTB,RX11AUD   ; unmute rx1 into tx1
Rx101b                          ; check rx1 into tx2 now.
        btfss   group0,7        ; is rx1 to tx1 enabled?
        goto    Rx101c          ; no.
        bsf     tx2flag,RX1TX   ; set main receiver on bit
        movlw   CTNONE          ; no courtesy tone.
        movwf   ct2tone         ; kill off any pending courtesy tone.
        movf    mute1Tmr,f      ; check mute timer
        btfsc   STATUS,Z        ; if it's non-zero, skip unmute
        bsf     PORTB,RX12AUD   ; unmute rx1 into tx2
Rx101c  
        btfss   group1,1        ; is time out timer enabled?
        goto    Rx1End          ; nope...
        movlw   EETTMS          ; EEPROM address of timeout timer short preset.
        btfsc   group1,2        ; is short timeout selected
        movlw   EETTML          ; EEPROM address of timeout timer long preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   rx1tout         ; set timeout counter
        goto    Rx1End          ; done here...
Rx1Rpt                          ; receiver active state
        btfss   group0,0        ; is repeater enabled?
        goto    Rx1OnOff        ; no.  turn receiver off
        btfss   flags,RX1USQ    ; is squelch open?
        goto    Rx1OnOff        ; no, on->off transition
        ;; check for priority
        movf    group0,w        ; get group 0 flags
        andwf   group2,w        ; and with group 2 flags
        andlw   b'11000000'     ; result is non-zero if linked.
        btfsc   STATUS,Z        ; are ports linked?
        goto    Rx1Rpt1         ; no.
        btfss   group3,5        ; does RX 2 have priority?
        goto    Rx1Rpt1         ; nope. ignore RX2 priority.
        movf    rx2stat,w       ; get RX 2 receiver state.
        sublw   RXSON           ; subtract ON state value.
        btfss   STATUS,Z        ; is result zero?
        goto    Rx1Rpt1         ; no.
        bsf     flags,RX1NOCT   ; yes. RX2 is on.  Kill RX1 and its CT.
        goto    Rx1OnOff        ; 
Rx1Rpt1 
        btfss   tFlags,ONESEC   ; one second tick?
        goto    Rx1End          ; nope, continue
        movf    rx1tout,f       ; squelch still open, check timeout timer
        btfsc   STATUS,Z        ; skip if not zero
        goto    Rx1End          ; timeout timer is zero, don't decrement
        decfsz  rx1tout,f       ; decrement the timeout timer
        goto    Rx1End          ; have not timed out (yet), continue
        ;; receiver has timed out.
        movlw   RXSTMO          ; get new state, timed out
        movwf   rx1stat         ; set new receiver state
        clrf    rx1tout         ; clear rx2 timeout timer
        btfss   group0,6        ; is rx1 into tx1 on?
        goto    Rx1to2          ; no.
        bcf     tx1flag,RX1TX   ; clear rx1 on bit
        bcf     PORTB,RX11AUD   ; mute rx1 -> tx1
        PAGE3                   ; select code page 3.
        movlw   CW_TO1          ; get CW timeout message.
        call    PlayCW1         ; play CW message.
        PAGE0                   ; select code page 1.
Rx1to2                          ; check rx2 -> tx1.
        btfss   group0,7        ; is rx1 into tx2 on?
        goto    Rx1End          ; no.
        bcf     tx2flag,RX1TX   ; clear rx1 on bit
        bcf     PORTB,RX12AUD   ; mute rx1 -> tx2
        PAGE3                   ; select code page 3.
        movlw   CW_TO1          ; get CW timeout message.
        call    PlayCW2         ; play CW message.
        PAGE0                   ; select code page 1.
        goto    Rx1End          ; done here...

Rx1OnOff                        ; receiver was active, became inactive
        call    Rcv1Off         ; turn off rx1.
        btfss   group0,6        ; is rx1 into tx1 on?
        goto    Rx110a          ; no.
        movlw   CTRX11          ; get CT number
        btfss   group4,6        ; is rx1 -> tx1 courtesy tone enabled.
        movlw   CTNONE          ; no CT.
        btfsc   flags,RX1NOCT   ; is CT suppressed? (priority)
        movlw   CTNONE          ; no CT.
        movwf   ct1tone         ; save the courtesy tone.
        call    SetCT1          ; start tx1 ct front porch timer
        call    SetHang1        ; start/restart the hang timer
        call    ChkID1          ; test if need an ID now

Rx110a                          ; look at rx1 into tx2 here.
        btfss   group0,7        ; is rx1 into tx2 on?
        goto    Rx1End          ; nope, done here.
        movlw   CTRX12          ; get CT number
        btfss   group5,6        ; is rx1 -> tx2 courtesy tone enabled.
        movlw   CTNONE          ; no CT.
        btfsc   flags,RX1NOCT   ; is CT suppressed?  (priority)
        movlw   CTNONE          ; no CT.
        movwf   ct2tone         ; save the courtesy tone.
        call    SetCT2          ; start tx2 ct front porch timer
        call    SetHang2        ; start/restart the hang timer
        call    ChkID2          ; test if need an ID now
        goto    Rx1End          ; done here...

Rx1Tmot                         ; receiver timedout state
        btfss   group0,0        ; is repeater enabled?
        goto    Rx1TEnd         ; no.  turn receiver off
        btfsc   flags,RX1USQ    ; is squelch still open?
        goto    Rx1End          ; yes, still timed out
Rx1TEnd                         ; end of timeout condition.
        movlw   RXSOFF          ; timeout condition ended, get new state (off)
        movwf   rx1stat         ; set new receiver state

        btfss   group0,6        ; is rx1 into tx1 on?
        goto    Rx1Toe2         ; no.
        PAGE3                   ; select code page 3.
        movlw   CW_TO1          ; get CW timeout message.
        call    PlayCW1         ; play CW message.
        PAGE0                   ; select code page 1.
Rx1Toe2                         ; now look at rx2 -> tx2.
        btfss   group0,7        ; is rx1 into tx2 on?
        goto    Rx1End          ; no.
        PAGE3                   ; select code page 3.
        movlw   CW_TO1          ; get CW timeout message.
        call    PlayCW2         ; play CW message.
        PAGE0                   ; select code page 1.
        goto    Rx1End          ; done here...

Rx1End                          ; done with RX1 processing.
        bcf     flags,RX1NOCT   ; clear NO CT flag

DoRx2                           ; process RX2 here.
        movlw   high Rx2Tbl     ; set high byte of address
        movwf   PCLATH          ; select page
        movf    rx2stat,w       ; get main receiver state
        addwf   PCL,f           ; add w to PCL:  computed GOTO
Rx2Tbl
        goto    Rx2Quiet        ; quiet
        goto    Rx2Rpt          ; repeat
        goto    Rx2Tmot         ; timeout

Rx2Quiet                        ; receiver quiet state
        btfss   flags,RX2USQ    ; is squelch open?
        goto    Rx2End          ; nope, don't turn receiver on
        ;; receiver is unsquelched; put it on the air
        ;; receiver inactive --> active transistion
        btfss   group2,0        ; is receiver enabled?
        goto    Rx2End          ; disabled, not gonna turn receiver on
        btfss   group2,3        ; is DTMF access mode enabled?
        goto    Rx2OffOn        ; no. start repeating.
        movf    dt2atmr,f       ; check DTMF access mode timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    Rx2End          ; yes.  Don't turn receiver on.
        ;; timer is not zero, reset to initial value.
        movlw   EETDTA          ; get EEPROM address of DTMF access timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   dt2atmr         ; set DTMF access mode timer.
Rx2OffOn                        ; receiver inactive --> active transition
        ;; check for priority
        movf    group0,w        ; get group 0 flags
        andwf   group2,w        ; and with group 2 flags
        andlw   b'11000000'     ; result is non-zero if linked.
        btfsc   STATUS,Z        ; are ports linked?
        goto    Rx201a          ; no.
        btfss   group1,5        ; does RX 1 have priority?
        goto    Rx201a          ; nope.
        movf    rx1stat,w       ; get RX 1 receiver state.
        sublw   RXSON           ; subtract ON state value.
        btfsc   STATUS,Z        ; is result zero?
        goto    Rx2End          ; yes.  RX 1 is ON. don't turn on RX2.
Rx201a
        movlw   RXSON           ; get new state #
        movwf   rx2stat         ; set new receiver state
        btfss   group2,6        ; is rx2 to tx1 enabled?
        goto    Rx201b          ; no.
        bsf     tx1flag,RX2TX   ; set rx2->tx1 tx on bit
        movlw   CTNONE          ; no courtesy tone.
        movwf   ct2tone         ; kill off any pending courtesy tone.
        movf    mute2Tmr,f      ; check mute timer
        btfsc   STATUS,Z        ; if it's non-zero, skip unmute
        bsf     PORTB,RX21AUD   ; unmute rx2 into tx1
Rx201b                          ; check rx2 into tx2 now.
        btfss   group2,7        ; is rx2 to tx2 enabled?
        goto    Rx201c          ; no.
        btfss   group5,5        ; is tx2 considered duplex?
        goto    Rx201c          ; no.
        bsf     tx2flag,RX2TX   ; set rx2->tx2 tx on bit
        movlw   CTNONE          ; no courtesy tone.
        movwf   ct2tone         ; kill off any pending courtesy tone.
        movf    mute2Tmr,f      ; check mute timer
        btfsc   STATUS,Z        ; if it's non-zero, skip unmute
        bsf     PORTB,RX22AUD   ; unmute rx2 into tx2
Rx201c  
        btfss   group3,1        ; is time out timer enabled?
        goto    Rx2End          ; nope...
        movlw   EETTMS          ; EEPROM address of timeout timer short preset.
        btfsc   group3,2        ; is short timeout selected
        movlw   EETTML          ; EEPROM address of timeout timer long preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        movwf   rx2tout         ; set timeout counter
        goto    Rx2End          ; done here...
Rx2Rpt                          ; receiver active state
        btfss   group2,0        ; is receiver enabled?
        goto    Rx2OnOff        ; no.  turn receiver off
        btfss   flags,RX2USQ    ; is squelch open?
        goto    Rx2OnOff        ; no, on->off transition
        ;; check for priority
        movf    group0,w        ; get group 0 flags
        andwf   group2,w        ; and with group 2 flags
        andlw   b'11000000'     ; result is non-zero if linked.
        btfsc   STATUS,Z        ; are ports linked?
        goto    Rx2Rpt1         ; no.
        btfss   group1,5        ; does RX 1 have priority?
        goto    Rx2Rpt1         ; nope. ignore RX1 priority.
        movf    rx1stat,w       ; get RX 1 receiver state.
        sublw   RXSON           ; subtract ON state value.
        btfss   STATUS,Z        ; is result zero?
        goto    Rx2Rpt1         ; no.
        bsf     flags,RX2NOCT   ; yes. RX1 is on.  Kill RX2 and its CT.
        goto    Rx2OnOff        ; 
Rx2Rpt1
        btfss   tFlags,ONESEC   ; one second tick?
        goto    Rx2End          ; nope, continue
        movf    rx2tout,f       ; squelch still open, check timeout timer
        btfsc   STATUS,Z        ; skip if not zero
        goto    Rx2End          ; timeout timer is zero, don't decrement
        decfsz  rx2tout,f       ; decrement the timeout timer
        goto    Rx2End          ; have not timed out (yet), continue
        ;; receiver has timed out.
        movlw   RXSTMO          ; get new state, timed out
        movwf   rx2stat         ; set new receiver state
        clrf    rx2tout         ; clear rx2 timeout timer
        btfss   group2,6        ; is rx2 into tx1 on?
        goto    Rx2to2          ; no.
        bcf     tx1flag,RX2TX   ; clear rx2 on bit
        bcf     PORTB,RX21AUD   ; mute rx2 -> tx1
        PAGE3                   ; select code page 3.
        movlw   CW_TO2          ; get CW timeout message.
        call    PlayCW1         ; play CW message.
        PAGE0                   ; select code page 1.
Rx2to2                          ; check rx2 -> tx1.
        btfss   group2,7        ; is rx2 into tx2 on?
        goto    Rx2End          ; no.
        bcf     tx2flag,RX2TX   ; clear rx2 on bit
        bcf     PORTB,RX22AUD   ; mute rx2 -> tx2
        PAGE3                   ; select code page 3.
        movlw   CW_TO2          ; get CW timeout message.
        call    PlayCW2         ; play CW message.
        PAGE0                   ; select code page 1.
        goto    Rx2End          ; done here...

Rx2OnOff                        ; receiver was active, became inactive
        call    Rcv2Off         ; yes.  turn off rx2.
        btfss   group2,6        ; is rx2 into tx1 on?
        goto    Rx210a
        movlw   CTRX21          ; get CT number
        btfss   group4,7        ; is rx2 -> tx1 courtesy tone enabled.
        movlw   CTNONE          ; no CT.
        btfsc   flags,RX2NOCT   ; is CT suppressed? (priority)
        movlw   CTNONE          ; no CT.
        movwf   ct1tone         ; save the courtesy tone.
        call    SetCT1          ; start tx1 ct front porch timer
        call    SetHang1        ; start/restart the hang timer
        call    ChkID1          ; test if need an ID now

Rx210a                          ; look at rx2 into tx2 here.
        btfss   group2,7        ; is rx2 into tx2 on?
        goto    Rx2End          ; nope, done here.
        movlw   CTRX22          ; get CT number
        btfss   group5,7        ; is rx2 -> tx2 courtesy tone enabled.
        movlw   CTNONE          ; no CT.
        btfsc   flags,RX2NOCT   ; is CT suppressed? (priority)
        movlw   CTNONE          ; no CT.
        movwf   ct2tone         ; save the courtesy tone.
        call    SetCT2          ; start tx2 ct front porch timer
        call    SetHang2        ; start/restart the hang timer
        call    ChkID2          ; test if need an ID now
        goto    Rx2End          ; done here...

Rx2Tmot                         ; receiver timedout state
        btfss   group2,0        ; is receiver enabled?
        goto    Rx2TEnd         ; no.  turn receiver off
        btfsc   flags,RX2USQ    ; is squelch still open?
        goto    Rx2End          ; yes, still timed out
Rx2TEnd                         ; end of timeout condition.
        movlw   RXSOFF          ; timeout condition ended, get new state (off)
        movwf   rx2stat         ; set new receiver state

        btfss   group2,6        ; is rx2 into tx1 on?
        goto    Rx2Toe2         ; no.
        PAGE3                   ; select code page 3.
        movlw   CW_TO2          ; get CW timeout message.
        call    PlayCW1         ; play CW message.
        PAGE0                   ; select code page 1.
Rx2Toe2                         ; now look at rx2 -> tx2.
        btfss   group2,7        ; is rx2 into tx2 on?
        goto    Rx2End          ; no.
        PAGE3                   ; select code page 3.
        movlw   CW_TO2          ; get CW timeout message.
        call    PlayCW2         ; play CW message.
        PAGE0                   ; select code page 1.
        goto    Rx2End          ; done here...

Rx2End                          ; done with RX2 processing.
        bcf     flags,RX2NOCT   ; clear NO CT flag

; ********************
; * Timer processing *
; ********************
        
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
        ;; this is where the pulsed output gets turned off.
        swapf   group7,w        ; get group 7
        andwf   group7,w        ; and group 7
        xorlw   b'11111111'     ; invert result
        iorlw   b'11110000'     ; mask to protect bits 4-7
        andwf   group7,f        ; clear bits.
        swapf   group7,w        ; get group 7, swap nibbles.
        andlw   b'11110000'     ; clear unneeded bits.
        movwf   temp            ; save.
        movf    PORTD,w         ; get PORTD bits.
        andlw   b'00001111'     ; clear unneeded bits.
        iorwf   temp,w          ; set bits from group 7
        movwf   PORTD           ; put entire byte back to PORTD.

        btfss   group6,0        ; is digital output enabled?
        goto    PulsEnd         ; no
        btfss   group6,1        ; is digital output currently on?
        goto    PulsEnd         ; no
        btfss   group6,2        ; is pulsed mode selected?
        goto    PulsEnd         ; no
        bcf     group6,1        ; mark output off
        bcf     PORTA,FANCTL    ; turn off pulsed digital output.
PulsEnd                         ; done with digital output pulse logic

        ;; check chickenburst timer, tx0
        movf    cb1Tmr,f        ; check tx0 chicken burst timer
        btfsc   STATUS,Z        ; is it zero?
        goto    Chkn2           ; yep.
        decfsz  cb1Tmr,f        ; decrement the timer
        goto    Chkn2           ; not zero yet.
        bcf     PORTB,TX1PTT    ; turn off tx0 PTT!

Chkn2
        ;; check chickenburst timer, tx1
        movf    cb2Tmr,f        ; check tx1 chicken burst timer
        btfsc   STATUS,Z        ; is it zero?
        goto    ChknEnd         ; yep.
        decfsz  cb2Tmr,f        ; decrement the timer
        goto    ChknEnd         ; not zero yet.
        bcf     PORTB,TX2PTT    ; turn off tx1 PTT!
ChknEnd

        ;; now check tx1 ct front porch timer.
        movf    tx1ctd,f        ; check for tx1 ct front porch timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    T1CTDE          ; yes.
        decfsz  tx1ctd,f        ; decrement and check for zero.
        goto    T1CTDE          ; not zero yet.
        ;; time to play the courtesy tone
        bcf     tx1flag,CTDELAY ; clear tx indicator.
        movf    tx1flag,w       ; get tx1flag
        andlw   b'00010000'     ; and tx1flag with CW indicator
        btfsc   STATUS,Z        ; is the result zero?
        goto    DoCT1           ; yes, ok to play CT.
        bsf     tx1flg2,DEF_CT  ; set defer CT flag.
        goto    T1CTDE          ; don't beep now.

DoCT1
        incf    ct1tone,w       ; check ct1tone for FF
        btfsc   STATUS,Z        ; is result 0?
        goto    T1CTDE          ; yes, ct1tone was FF.
        btfss   group3,3        ; using state number for ct number?
        goto    DoCT1A          ; no
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    stateNo,w       ; get the last selected state number
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    DoCT1B
DoCT1A
        movf    ct1tone,w       ; get courtesy tone.
        btfss   PORTD,CT4SEL    ; is CT select 4 input active (low)?
        movlw   CT4             ; yes, select courtesy tone 4.
        btfss   PORTD,CT5SEL    ; is CT select 5 input active (low)?
        movlw   CT5             ; yes, select courtesy tone 5.
        btfss   PORTD,CT6SEL    ; is CT select 6 input active (low)?
        movlw   CT6             ; yes, select courtesy tone 6.
DoCT1B  
        btfsc   dtRFlag,DT1UNLK ; is this port (main receiver) unlocked?
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        movwf   ct1tone         ; yep. set unlocked courtesy tone.
        PAGE3                   ; select code page 3.
        call    PlayCT1         ; play courtesy tone #w
        PAGE0                   ; select code page 0.
        ;; end of tx1 ct processing...
T1CTDE                          ; done with tx1 ct front porch delay timer
        ;; now check tx2 ct front porch timer.
        movf    tx2ctd,f        ; check for tx1 ct front porch timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    T2CTDE          ; yes.
        decfsz  tx2ctd,f        ; decrement and check for zero.
        goto    T2CTDE          ; not zero yet.
        ;; time to play the courtesy tone
        bcf     tx2flag,CTDELAY ; clear tx indicator.
        movf    tx2flag,w       ; get tx2flag
        andlw   b'00010000'     ; and tx2flag with CW indicator
        btfsc   STATUS,Z        ; is the result zero?
        goto    DoCT2           ; yes, ok to play CT.
        bsf     tx2flg2,DEF_CT  ; set defer CT flag.
        goto    T2CTDE          ; don't beep now.

DoCT2
        incf    ct2tone,w       ; check ct1tone for FF
        btfsc   STATUS,Z        ; is result 0?
        goto    T2CTDE          ; yes, ct1tone was FF.
        btfss   group3,3        ; using state number for ct number?
        goto    DoCT2A          ; no
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    stateNo,w       ; get the last selected state number
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    DoCT2B
DoCT2A
        movf    ct2tone,w       ; get courtesy tone.
        btfss   PORTD,CT4SEL    ; is CT select 4 input active (low)?
        movlw   CT4             ; yes, select courtesy tone 4.
        btfss   PORTD,CT5SEL    ; is CT select 5 input active (low)?
        movlw   CT5             ; yes, select courtesy tone 5.
        btfss   PORTD,CT6SEL    ; is CT select 6 input active (low)?
        movlw   CT6             ; yes, select courtesy tone 6.
DoCT2B
        btfsc   dtRFlag,DT2UNLK ; is this port (main receiver) unlocked?
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        movwf   ct2tone         ; yep. set unlocked courtesy tone.
        PAGE3                   ; select code page 3.
        call    PlayCT2         ; play courtesy tone #w
        PAGE0                   ; select code page 0.
        ;; end of tx2 ct processing...
T2CTDE                          ; done with tx2 ct front porch delay timer
        
Ck100mS                         ; check 100 millisecond tick.
        btfss   tFlags,HUNDMS   ; is 100 millisecond bit set?
        goto    Ck1S            ; nope.
        ;; 100 millisecond tick active.

        ;; check hang timer1
        movf    hang1tmr,f      ; check hang timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NoHang1         ; yes, not hang active, continue
        decfsz  hang1tmr,f      ; decrement and check if now zero
        goto    NoHang1         ; not zero
        ;; end of hang time.
        bcf     tx1flag,HANG    ; turn off hang time flag
NoHang1

        ;; check hang timer2
        movf    hang2tmr,f      ; check hang timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NoHang2         ; yes, not hang active, continue
        decfsz  hang2tmr,f      ; decrement and check if now zero
        goto    NoHang2         ; not zero
        ;; end of hang time.
        bcf     tx2flag,HANG    ; turn off hang time flag
NoHang2                         ; done with hang timers..
        
        ;; process DTMF-1 muting timer...
        movf    mute1Tmr,f      ; test mute timer
        btfsc   STATUS,Z        ; Z is set if not DTMF muting
        goto    NoMutTm1        ; mute1Tmr is zero.
        decfsz  mute1Tmr,f      ; decrement mute1Tmr
        goto    NoMutTm1        ; have not reached the end of the mute time
        btfsc   tx1flag,RX1TX   ; is rx1 -> tx1 turned on?
        bsf     PORTB,RX11AUD   ; unmute rx1 -> tx1.
        btfsc   tx2flag,RX1TX   ; is rx1 -> tx2 turned on?
        bsf     PORTB,RX12AUD   ; unmute rx1 -> tx2.
NoMutTm1                        ; done with muting 1 timer...

        ;; process DTMF-2 muting timer...
        movf    mute2Tmr,f      ; test mute timer
        btfsc   STATUS,Z        ; Z is set if not DTMF muting
        goto    NoMutTm2        ; mute1Tmr is zero.
        decfsz  mute2Tmr,f      ; decrement mute1Tmr
        goto    NoMutTm2        ; have not reached the end of the mute time
        btfsc   tx1flag,RX2TX   ; is rx2 -> tx1 turned on?
        bsf     PORTB,RX21AUD   ; unmute rx1 -> tx1.
        btfsc   tx2flag,RX2TX   ; is rx2 -> tx2 turned on.
        bsf     PORTB,RX22AUD   ; unmute rx1 -> tx2.
NoMutTm2                        ; done with muting 1 timer...
        
Ck1S                            ; check 1-second flag bit.
        btfss   tFlags,ONESEC   ; is one-second flag bit set?
        goto    Ck10S           ; nope.
        ;; 1-second tick active.
        ;; check rx1 unlocked mode timer.
        movf    ulk1Tmr,f       ; check ulk1Tmr
        btfsc   STATUS,Z        ; is it zero?
        goto    NoUL1Tmr        ; yes, don't worry about it.
        decfsz  ulk1Tmr,f       ; no, decrement it.
        goto    NoUL1Tmr        ; still not zero.
        ;; ulk1Tmr counted down to zero, lock controller.
        bcf     dtRFlag,DT1UNLK ; lock port 1
NoUL1Tmr                        ; end of unlocked timer 1.
        
        ;; check rx2 unlocked mode timer.
        movf    ulk2Tmr,f       ; check ulk1Tmr
        btfsc   STATUS,Z        ; is it zero?
        goto    NoUL2Tmr        ; yes, don't worry about it.
        decfsz  ulk2Tmr,f       ; no, decrement it.
        goto    NoUL2Tmr        ; still not zero.
        ;; ulk1Tmr counted down to zero, lock controller.
        bcf     dtRFlag,DT2UNLK ; lock port 2
NoUL2Tmr                        ; end of unlocked timer 2.

Ck10S                           ; check 10-second tick flag bit.
        btfss   tFlags,TENSEC   ; is ten-second flag bit set?
        goto    NoTimr          ; nope.  no more timers to test.
        ;; check ID timer for tx1
        movf    id1tmr,f        ; check id1tmr
        btfsc   STATUS,Z        ; is id1tmr 0
        goto    NoID1Tmr        ; yes...
        decfsz  id1tmr,f        ; decrement ID timer
        goto    NoID1Tmr                ; not zero yet...
        call    DoID1           ; id timer decremented to zero, play the ID
NoID1Tmr                        ; process more 10 second timers here...
        ;; check ID timer for tx1
        movf    id2tmr,f        ; check id2tmr
        btfsc   STATUS,Z        ; is id2tmr 0
        goto    NoID2Tmr        ; yes...
        decfsz  id2tmr,f        ; decrement ID timer
        goto    NoID2Tmr        ; not zero yet...
        call    DoID2           ; id timer decremented to zero, play the ID
NoID2Tmr                        ; process more 10 second timers here...
        
        movf    fanTmr,f        ; check fan timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NoFanTm         ; yes.
        btfsc   group6,0        ; fan mode configured?
        goto    NoFanTm         ; no
        decfsz  fanTmr,f        ; decrement fan timer
        goto    NoFanTm         ; not zero yet
        bcf     PORTA,FANCTL    ; turn off fan
NoFanTm

        ;; check DTMF access mode timer for rx1
        movf    dt1atmr,f       ; check DTMF access timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    NoDTATm1        ; yes
        decfsz  dt1atmr,f       ; decrement DTMF access timer
        goto    NoDTATm1        ; not zero yet.
        ;; jeff, is something supposed to happen here?
        nop
NoDTATm1
        
        ;; check DTMF access mode timer for rx1
        movf    dt2atmr,f       ; check DTMF access timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    NoDTATm2        ; yes
        decfsz  dt2atmr,f       ; decrement DTMF access timer
        goto    NoDTATm2        ; not zero yet.
        ;; jeff, is something supposed to happen here?
        nop
NoDTATm2
        
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movf    alrmTmr,f       ; check alarm timer.
        btfsc   STATUS,Z        ; is it zero?
        goto    NoAlmTm         ; yes
        decfsz  alrmTmr,f       ; decrement alarm timer
        goto    NoAlmTm         ; not zero yet.
        bcf     STATUS,RP0      ; clear A7 for addresses 0-7f, 100-17f
        movlw   EETALM          ; get EEPROM address of alarm timer preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        PAGE0                   ; select code page 0.
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movwf   alrmTmr         ; preset alarm timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 0-7f, 100-17f
        btfss   group4,0        ; is transmitter 1 enabled?
        goto    NoAlTx1         ; no.
        movlw   BP_ALM          ; get alarm beep tone.
        PAGE3                   ; select code page 3.
        call    PlayCTx1        ; play courtesy tone #w, Tx1.
        PAGE0                   ; select code page 0.
NoAlTx1
        btfss   group5,0        ; is transmitter 2 enabled?
        goto    NoAlmTm         ; no.
        movlw   BP_ALM          ; get alarm beep tone.
        PAGE3                   ; select code page 3.
        call    PlayCTx2        ; play courtesy tone #w, Tx2.
        PAGE0                   ; select code page 0.
NoAlmTm                         ; done with alarm timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 0-7f, 100-17f
        
NoTimr                          ; no more timers to test.
        
ChkTx1                          ; check if transmitter 1 should be on
        btfsc   group6,6        ; chicken-burst mode TX1?
        goto    ChkTx1A         ; yes.  don't do encode control here.
        
        btfsc   group0,4        ; encode tone for RX1 -> TX1 ?
        goto    CkTx1aa         ; yes.
        btfss   group2,4        ; encode tone for RX2 -> TX1 ?
        goto    ChkTx1A         ; no.
CkTx1aa
        clrf    temp            ; encoder enable flag.
        btfss   group0,4        ; encode tone for RX1->TX1?
        goto    CkT1a           ; no.
        btfsc   tx1flag,RX1TX   ; is receiver 1 active?
        bsf     temp,0          ; yes, set flag to encode.
CkT1a
        btfss   group2,4        ; encode tone for RX2->TX1?
        goto    CkT1b           ; no.
        btfsc   tx1flag,RX2TX   ; is receiver 2 active?
        bsf     temp,0          ; yes, set flag to encode.
CkT1b   
        btfsc   temp,0          ; is flag set?
        bsf     PORTD,TX1ENC    ; yes, turn on encoder.
        btfss   temp,0          ; is flag clear?
        bcf     PORTD,TX1ENC    ; yes, turn off encoder.
ChkTx1A
        movf    tx1flag,f       ; check tx1flag
        btfsc   STATUS,Z        ; skip if not zero
        goto    ChkTx10         ; it's zero, turn off transmitter
        btfsc   tx1flg2,TXONFLG ; skip if not already on
        goto    ChkTx1E         ; done here
        PAGE3                   ; select code page 1.
        call    Tx1On           ; turn on transmitter (will set TXONFLG)
        PAGE0                   ; select code page 0.
        goto    ChkTx1E         ; now done here.
        
ChkTx10
        btfss   tx1flg2,TXONFLG ; skip if tx is on
        goto    ChkTx1E         ; was already off
        PAGE3                   ; select code page 1.
        call    Tx1Off          ; turn off PTT
        PAGE0                   ; select code page 0.
ChkTx1E                         ; end of ChkTx

ChkTx2                          ; check if transmitter 2 should be on
        btfsc   group6,7        ; chicken-burst mode TX2?
        goto    ChkTx2A         ; yes.  don't do encode control here.

        btfsc   group0,5        ; encode tone for RX1 -> TX2 ?
        goto    CkTx2aa         ; yes.
        btfss   group2,5        ; encode tone for RX2 -> TX2 ?
        goto    ChkTx2A         ; no.
CkTx2aa
        
        clrf    temp            ; encoder enable flag.
        btfss   group0,5        ; encode tone for RX1->TX2?
        goto    CkT2a           ; no.
        btfsc   tx2flag,RX1TX   ; is receiver 1 active?
        bsf     temp,0          ; yes, set flag to encode.
CkT2a
        btfss   group2,5        ; encode tone for RX2->TX2?
        goto    CkT2b           ; no.
        btfsc   tx2flag,RX2TX   ; is receiver 2 active?
        bsf     temp,0          ; yes, set flag to encode.
CkT2b   
        btfsc   temp,0          ; is flag set?
        bsf     PORTD,TX2ENC    ; yes, turn on encoder.
        btfss   temp,0          ; is flag clear?
        bcf     PORTD,TX2ENC    ; yes, turn off encoder.
ChkTx2A
        movf    tx2flag,f       ; check tx2flag
        btfsc   STATUS,Z        ; skip if not zero
        goto    ChkTx20         ; it's zero, turn off transmitter
        btfsc   tx2flg2,TXONFLG ; skip if not already on
        goto    ChkTx2E         ; done here
        PAGE3                   ; select code page 1.
        call    Tx2On           ; turn on transmitter (will set TXONFLG)
        PAGE0                   ; select code page 0.
        goto    ChkTx2E         ; now done here.
        
ChkTx20
        btfss   tx2flg2,TXONFLG ; skip if tx is on
        goto    ChkTx2E         ; was already off
        PAGE3                   ; select code page 1.
        call    Tx2Off          ; turn off PTT
        PAGE0                   ; select code page 0.
ChkTx2E                         ; end of ChkTx

; ******************************
; ** CW SENDER, transmitter 1 ** 
; ******************************
CWSendr1
        btfss   tx1flag,CWPLAY  ; sending CW?
        goto    NoCW1           ; nope

        btfss   tFlags,ONEMS    ; is this a one-ms tick?
        goto    NoCW1           ; nope.

        decfsz  cw1tbtmr,f      ; decrement CW timebase counter
        goto    NoCW1           ; not zero yet.

        movf    cw1spd,w        ; get cw timebase preset.
        movwf   cw1tbtmr        ; preset CW timebase.

        decfsz  cw1tmr,f        ; decrement CW element timer
        goto    NoCW1           ; not zero

        btfss   tx1flg2,CWBEEP  ; was "key" down? 
        goto    CWKeyUp1        ; nope
                                ; key was down
        bcf     tx1flg2,CWBEEP  ; 
        ; turn off beep here.
        clrw                    ; clear W.
        PAGE3                   ; select code page 3.
        call    SetTone1        ; set the beep tone up.
        PAGE0                   ; select code page 0.
        decf    cw1byte,w       ; test CW byte to see if 1
        btfsc   STATUS,Z        ; was it 1 (Z set if cw1byte == 1)
        goto    CWNext1         ; it was 1...
        movlw   CWIESP          ; get cw inter-element space
        movwf   cw1tmr          ; preset cw timer
        goto    NoCW1           ; done with this pass...

CWNext1                         ; get next character of message
        PAGE3                   ; select code page 1.
        call    GtBeep1         ; get the next cw character
        PAGE0                   ; select code page 0.
        movwf   cw1byte         ; store character bitmap
        btfsc   STATUS,Z        ; is this a space (zero)
        goto    CWWord1         ; yes, it is 00
        incf    cw1byte,w       ; check to see if it is FF
        btfsc   STATUS,Z        ; if this bitmap was FF then Z will be set
        goto    CWDone1         ; yes, it is FF
        movlw   CWILSP          ; no, not 00 or FF, inter letter space
        movwf   cw1tmr          ; preset cw timer
        goto    NoCW1           ; done with this pass...

CWWord1                         ; word space
        movlw   CWIWSP          ; get word space
        movwf   cw1tmr          ; preset cw timer
        goto    NoCW1           ; done with this pass...

CWKeyUp1                        ; key was up, key again...
        incf    cw1byte,w       ; is cw1byte == ff?
        btfsc   STATUS,Z        ; Z is set if cw1byte == ff
        goto    CWDone1         ; got EOM

        movf    cw1byte,f       ; check for zero/word space
        btfss   STATUS,Z        ; is it zero
        goto    CWTest1         ; no...
        goto    CWNext1         ; is 00, word space...

CWTest1
        movlw   CWDIT           ; get dit length
        btfsc   cw1byte,0       ; check low bit
        movlw   CWDAH           ; get DAH length
        movwf   cw1tmr          ; preset cw timer
        bsf     tx1flg2,CWBEEP  ; turn key->down
        movf    cw1tone,w       ; get CW tone
        ;; turn on beep here.
        PAGE3                   ; select code page 3.
        call    SetTone1        ; set the beep tone up.
        PAGE0                   ; select code page 0.
        rrf     cw1byte,f       ; rotate cw bitmap
        bcf     cw1byte,7       ; clear the MSB
        goto    NoCW1           ; done with this pass...

CWDone1                         ; done sending CW
        bcf     tx1flag,CWPLAY  ; turn off CW flag
        clrf    beep1ctl        ; clear beep control flags
        btfss   tx1flg2,DEF_CT  ; is the deferred CT set?
        goto    NoCW1           ; nope.
        bcf     tx1flg2,DEF_CT  ; clear deferred beep flag.
        incf    ct1tone,w       ; check ct1tone for FF
        btfsc   STATUS,Z        ; is result 0?
        goto    NoCW1           ; yes, ct1tone was FF.
        movf    ct1tone,w       ; get courtesy tone.
        btfsc   dtRFlag,DT1UNLK ; is this port (main receiver) unlocked?
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        movwf   ct1tone         ; yep. set unlocked courtesy tone.
        PAGE3                   ; select code page 3.
        call    PlayCT1         ; play courtesy tone #w
        PAGE0                   ; select code page 0.

NoCW1

; ******************************
; ** CW SENDER, transmitter 2 ** 
; ******************************
CWSendr2
        btfss   tx2flag,CWPLAY  ; sending CW?
        goto    NoCW2           ; nope

        btfss   tFlags,ONEMS    ; is this a one-ms tick?
        goto    NoCW2           ; nope.

        decfsz  cw2tbtmr,f      ; decrement CW timebase counter
        goto    NoCW2           ; not zero yet.

        movf    cw2spd,w        ; get cw timebase preset.
        movwf   cw2tbtmr        ; preset CW timebase.

        decfsz  cw2tmr,f        ; decrement CW element timer
        goto    NoCW2           ; not zero

        btfss   tx2flg2,CWBEEP  ; was "key" down? 
        goto    CWKeyUp2        ; nope
                                ; key was down
        bcf     tx2flg2,CWBEEP  ; 
        ; turn off beep here.
        clrw                    ; clear W.
        PAGE3                   ; select code page 3.
        call    SetTone2        ; set the beep tone up.
        PAGE0                   ; select code page 0.
        decf    cw2byte,w       ; test CW byte to see if 1
        btfsc   STATUS,Z        ; was it 1 (Z set if cw1byte == 1)
        goto    CWNext2         ; it was 1...
        movlw   CWIESP          ; get cw inter-element space
        movwf   cw2tmr          ; preset cw timer
        goto    NoCW2           ; done with this pass...

CWNext2                         ; get next character of message
        PAGE3                   ; select code page 1.
        call    GtBeep2         ; get the next cw character
        PAGE0                   ; select code page 0.
        movwf   cw2byte         ; store character bitmap
        btfsc   STATUS,Z        ; is this a space (zero)
        goto    CWWord2         ; yes, it is 00
        incf    cw2byte,w       ; check to see if it is FF
        btfsc   STATUS,Z        ; if this bitmap was FF then Z will be set
        goto    CWDone2         ; yes, it is FF
        movlw   CWILSP          ; no, not 00 or FF, inter letter space
        movwf   cw2tmr          ; preset cw timer
        goto    NoCW2           ; done with this pass...

CWWord2                         ; word space
        movlw   CWIWSP          ; get word space
        movwf   cw2tmr          ; preset cw timer
        goto    NoCW2           ; done with this pass...

CWKeyUp2                        ; key was up, key again...
        incf    cw2byte,w       ; is cw1byte == ff?
        btfsc   STATUS,Z        ; Z is set if cw1byte == ff
        goto    CWDone2         ; got EOM

        movf    cw2byte,f       ; check for zero/word space
        btfss   STATUS,Z        ; is it zero
        goto    CWTest2         ; no...
        goto    CWNext2         ; is 00, word space...

CWTest2
        movlw   CWDIT           ; get dit length
        btfsc   cw2byte,0       ; check low bit
        movlw   CWDAH           ; get DAH length
        movwf   cw2tmr          ; preset cw timer
        bsf     tx2flg2,CWBEEP  ; turn key->down
        movf    cw2tone,w       ; get CW tone
        ;; turn on beep here.
        PAGE3                   ; select code page 3.
        call    SetTone2        ; set the beep tone up.
        PAGE0                   ; select code page 0.
        rrf     cw2byte,f       ; rotate cw bitmap
        bcf     cw2byte,7       ; clear the MSB
        goto    NoCW2           ; done with this pass...

CWDone2                         ; done sending CW
        bcf     tx2flag,CWPLAY  ; turn off CW flag
        clrf    beep2ctl        ; clear beep control flags
        btfss   tx2flg2,DEF_CT  ; is the deferred CT set?
        goto    NoCW2           ; nope.
        bcf     tx2flg2,DEF_CT  ; clear deferred beep flag.
        incf    ct2tone,w       ; check ct1tone for FF
        btfsc   STATUS,Z        ; is result 0?
        goto    NoCW2           ; yes, ct1tone was FF.
        movf    ct2tone,w       ; get courtesy tone.
        btfsc   dtRFlag,DT2UNLK ; is this port (main receiver) unlocked?
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        movwf   ct2tone         ; yep. set unlocked courtesy tone.
        PAGE3                   ; select code page 3.
        call    PlayCT2         ; play courtesy tone #w
        PAGE0                   ; select code page 0.
NoCW2

CkTone
        btfss   tFlags,HUNDMS   ; check the DTMF timers every 100 msec.
        goto    TonDone         ; not 100 MS tick.
CkDt1   
        movf    dt1tmr,f        ; check for zero...
        btfsc   STATUS,Z        ; is it zero
        goto    CkDt2           ; yes
        decfsz  dt1tmr,f        ; decrement timer
        goto    CkDt2           ; not zero yet
        bsf     dtRFlag,DT1RDY  ; ready to evaluate command.
CkDt2   
        movf    dt2tmr,f        ; check for zero...
        btfsc   STATUS,Z        ; is it zero
        goto    TonDone         ; yes
        decfsz  dt2tmr,f        ; decrement timer
        goto    TonDone         ; not zero yet
        bsf     dtRFlag,DT2RDY  ; ready to evaluate command.
TonDone

        btfss   tFlags,TENMS    ; is this a 10 ms tick?
        goto    NoTime          ; nope.
        
DoBeep1                         ; manage beep 1 timer
        movf    beep1tmr,f      ; check beep timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NBeep1          ; yes.
                                ; no, a valid beep tick.
        decfsz  beep1tmr,f      ; decrement beep1tmr
        goto    EndBeep1        ; not zero yet.
        PAGE3                   ; select code page 3.
        call    GetBeep1        ; get the next beep tone...
        PAGE0                   ; select code page 0.
        goto    EndBeep1        ; done here.
NBeep1                          ; verify that beeping is really over. HACK.
        movf    cw1tmr,f        ; check cw1tmr.
        btfss   STATUS,Z        ; is it zero?
        goto    EndBeep1        ; no.
        movf    beep1ctl,f      ; check this.
        btfsc   STATUS,Z        ; is it zero?
        goto    EndBeep1        ; yes.
        PAGE3                   ; select code page 3.
        call    GetBeep1        ; get the next beep tone...
        PAGE0                   ; select code page 0.
EndBeep1

DoBeep2                         ; manage beep 2 timer
        movf    beep2tmr,f      ; check beep timer
        btfsc   STATUS,Z        ; is it zero?
        goto    NBeep2          ; yes.
                                ; no, a valid beep tick.
        decfsz  beep2tmr,f      ; decrement beep2tmr
        goto    EndBeep2        ; not zero yet.
        PAGE3                   ; select code page 3.
        call    GetBeep2        ; get the next beep tone...
        PAGE0                   ; select code page 0.
        goto    EndBeep2        ; done here.
NBeep2                          ; verify that beeping is really over. HACK.
        movf    cw2tmr,f        ; check cw1tmr.
        btfss   STATUS,Z        ; is it zero?
        goto    EndBeep2        ; no.
        movf    beep2ctl,f      ; check this.
        btfsc   STATUS,Z        ; is it zero?
        goto    EndBeep2        ; yes.
        PAGE3                   ; select code page 3.
        call    GetBeep2        ; get the next beep tone...
        PAGE0                   ; select code page 0.
EndBeep2

NoTime
        movf    tFlags,f        ; evaluate tFlags
        btfss   STATUS,Z        ; skip if ZERO
        goto    LoopEnd
        ;; no timing flags were set...
        ;; likely some excess, available CPU cycles here.
        ;; evaluate DTMF buffers...
PfxDT1
        btfsc   dtRFlag,DTSEVAL ; is a command being interpreted now?
        goto    DTEval          ; yes, don't try to evaluate another now.
        ;; evaluate DTMF 1 buffer for command
        btfss   dtRFlag,DT1RDY  ; is a command ready to evaluate?
        goto    PfxDT2          ; no command waiting.
        btfsc   group8,3        ; ignore DTMF from receiver 1?
        goto    NoDT1           ; yes. ignore.
        ;; copy command from DTMF rx buf to command interpreter input buffer.
        movlw   low dt1buf0     ; get address of this DTMF receiver's buffer
        movwf   FSR             ; store.
        movf    dt1ptr,w        ; get command size...
        movwf   cmdSize         ; save it.
        PAGE1                   ; select code page 1
        call    CpyDTMF         ; copy the command...
        PAGE0                   ; select code page 0
        movf    dt1ptr,w        ; get command size back, CpyDTMF clobbers.
        movwf   cmdSize         ; save it.
        clrf    dt1ptr          ; make ready to receive again.
        clrf    dtEFlag         ; start evaluating from first prefix.
        bsf     dtEFlag,DT1CMD  ; command from DTMF-1.
        bsf     dtRFlag,DTSEVAL ; set evaluate DTMF bit.
        btfsc   dtRFlag,DT1UNLK ; port 1 unlocked?
        bsf     dtRFlag,DTUL    ; this port is unlocked.
        bcf     dtRFlag,DT1RDY  ; reset DTMF ready bit.
        goto    DTEval          ; go and evaluate the command right now.

NoDT1
        ;; not going to evaluate.  just clear and carry on
        clrf    dt1ptr

PfxDT2
        ;; evaluate DTMF 2 buffer for command
        btfss   dtRFlag,DT2RDY  ; is a command ready to evaluate?
        goto    XPfxDT          ; no command waiting.
        btfsc   group8,4        ; ignore DTMF from receiver 2?
        goto    NoDT2           ; yes. ignore.
        ;; copy command from DTMF rx buf to command interpreter input buffer.
        movlw   low dt2buf0     ; get address of this DTMF receiver's buffer
        movwf   FSR             ; store.
        movf    dt2ptr,w        ; get command size...
        movwf   cmdSize         ; save it.
        PAGE1                   ; select code page 1
        call    CpyDTMF         ; copy the command...
        PAGE0                   ; select code page 0
        movf    dt2ptr,w        ; get command size back, CpyDTMF clobbers.
        movwf   cmdSize         ; save it.
        clrf    dt2ptr          ; make ready to receive again.
        clrf    dtEFlag         ; start evaluating from first prefix.
        bsf     dtEFlag,DT2CMD  ; command from DTMF-2
        bsf     dtRFlag,DTSEVAL ; set evaluate DTMF bit.
        btfsc   dtRFlag,DT2UNLK ; port 2 unlocked?
        bsf     dtRFlag,DTUL    ; this port is unlocked.
        bcf     dtRFlag,DT2RDY  ; reset DTMF ready bit.
        goto    DTEval          ; go and evaluate the command right now.

NoDT2
        ;; not going to evaluate.  just clear and carry on
        clrf    dt2ptr
                
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
        goto    DTEvalN         ; them bytes were not equal. no match.

        movf    temp2,w         ; look at temp2
        sublw   d'1'            ; is this the last byte
        btfsc   STATUS,Z        ; is result zero?
        goto    DTEvalY         ; yes, this was the last of 8, and it matched
        
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
        btfss   serFlag,SC_ECHO ; ready to echo a character?
        goto    CkScRdy         ; no...
        ;; echo the character...
        movf    echoCh,w        ; get the character to be echoed.
        PAGE1                   ; select code page 1
        call    SerOut          ; transmit the character
        PAGE0                   ; select code page 0
        bcf     serFlag,SC_ECHO ; clear the echo flag
        movf    echoCh,w        ; get the character again
        sublw   SCCR            ; subtract serial CR character.
        btfss   STATUS,Z        ; skip if zero - skip if is CR.
        goto    CkScRdy         ; it was not CR
        movlw   SCLF            ; get LINE FEED
        PAGE1                   ; select code page 1
        call    SerOut          ; transmit the character
        PAGE0                   ; select code page 0
        
CkScRdy        
        btfss   serFlag,SC_RDY  ; is serial command ready?
        goto    FanCtl
        PAGE1
        call    SCProc
        PAGE0
        
FanCtl
        ;; fan/control output control.
        btfss   group6,0        ; is fan control enabled?
        goto    LoopE1          ; yes.
        btfsc   group6,1        ; is digital output on?
        bsf     PORTA,FANCTL    ; yes, turn on control output.
        btfss   group6,1        ; is digital output off?
        bcf     PORTA,FANCTL    ; yes, turn off control output.
LoopE1
        btfss   group8,7        ; in test mode?
        goto    NoTest          ; nope.
        swapf   PORTD,w         ; get PORTD, nibble-swapped.
        andlw   h'f0'           ; mask to restrict to output bits.
        movwf   PORTD           ; IN 1-4 to OUT 1-4, respectively. 
NoTest
        goto    Loop0           ; start the main loop again.

;;; 
;;;
;;;
;;;
        

        
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
        goto    LCmd4           ; prefix 04 -- link state control
        goto    LCmd5           ; prefix 05 -- digital output control
        goto    LCmd6           ; prefix 06 -- reset alarm
        goto    LCmd7           ; prefix 07 -- unlock controller

; ***********
; ** LCmd0 **
; ***********
LCmd0                           ; control operator switches
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
        sublw   d'7'            ; w = 7-w.
        btfss   STATUS,C        ; skip if w is not negative
        return                  ; bad, bad user tried to enter invalid group.
        ;; check access to change that group.
        movf    temp2,w         ; get group number 0-7.
        PAGE3
        call    GetMask         ; get bitmask for that group.
        PAGE1
        ;; now have bit representing group number in w.
        andwf   group9,w        ; and with enabled groups mask.
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
LCmd1p1
        btfss   dtEFlag,DT1CMD  ; command from DTMF-1?
        goto    LCmd1p2         ; no.
        btfss   group0,3        ; check to see if DTMF access mode is enabled.
        return                  ; it's not.
        decfsz  cmdSize,w       ; check for one command digit.
        return                  ; not one command digit.
        movf    INDF,f          ; get command digit.
        btfsc   STATUS,Z        ; is it zero?
        goto    LCmd10p1        ; yes.
        decfsz  INDF,w          ; check for one.
        return                  ; it's not one.

        movlw   EETDTA          ; get EEPROM address of DTMF access timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        movwf   dt1atmr         ; set DTMF access mode timer.
        PAGE1                   ; select code page 1.
        return

LCmd10p1                        ; turn off DTMF access mode.
        movf    dt1atmr,f       ; check for zero.
        btfsc   STATUS,Z        ; is it zero.
        return                  ; it is zero, do nothing.
        clrf    dt1atmr         ; make it zero.
        return

LCmd1p2
        btfss   dtEFlag,DT2CMD  ; command from DTMF-1?
        return                  ; no.
        btfss   group2,3        ; check to see if DTMF access mode is enabled.
        return                  ; it's not.
        decfsz  cmdSize,w       ; check for one command digit.
        return                  ; not one command digit.
        movf    INDF,f          ; get command digit.
        btfsc   STATUS,Z        ; is it zero?
        goto    LCmd10p2        ; yes.
        decfsz  INDF,w          ; check for one.
        return                  ; it's not one.

        movlw   EETDTA          ; get EEPROM address of DTMF access timer.
        movwf   eeAddr          ; set EEPROM address low byte.
        PAGE3                   ; select code page 3.
        call    ReadEEw         ; read EEPROM.
        movwf   dt2atmr         ; set DTMF access mode timer.
        PAGE1                   ; select code page 1.
        return

LCmd10p2                        ; turn off DTMF access mode.
        movf    dt2atmr,f       ; check for zero.
        btfsc   STATUS,Z        ; is it zero.
        return                  ; it is zero, do nothing.
        clrf    dt2atmr         ; make it zero.
        return

; ***********
; ** LCmd2 **
; ***********
LCmd2                           ; digital output control
        btfss   group6,0        ; is digital output control configured?
        goto    LCmdErr         ; no. send error message.
        movf    cmdSize,w       ; get command size
        btfsc   STATUS,Z        ; skip if not zero.
        goto    LCmd2Q          ; zero is a query.
        movf    INDF,w          ; get command digit.
        btfsc   STATUS,Z        ; skip if not zero.
        goto    LCmd2Off        ; zero is turn off command.
        sublw   d'1'            ; result will be zero if command was 1
        btfss   STATUS,Z        ; skip if zero.
        return                  ; not zero or one, do nothing.
LCmd2On                         ; one is turn on command.
        bsf     group6,1        ; set control op bit.
        bsf     PORTA,FANCTL    ; turn on digital output.
        btfss   group6,2        ; check for pulsed configuration.
        goto    LCmdOn          ; not pulsed.
        movlw   PULS_TM         ; get pulse time.
        movwf   pulsTmr         ; set pulse timer.
        goto    LCmdOn          ; send ON message.
LCmd2Off                        ; zero is turn off command
        bcf     group6,1        ; set control op bit.
        bcf     PORTA,FANCTL    ; turn on digital output.
        clrf    pulsTmr         ; clear pulse timer, just in case.
        goto    LCmdOff         ; send OFF message.
LCmd2Q                          ; no argument is query.
        btfss   group6,1        ; is it on or off?
        goto    LCmdOff         ; it's off.
        goto    LCmdOn          ; it's on.

; ***********
; ** LCmd3 **
; ***********
LCmd3                           ; load saved state.
        decfsz  cmdSize,w       ; is this 1?
        return                  ; nope.
        movf    INDF,w          ; get command digit.
        sublw   d'4'            ; subtract 1
        btfss   STATUS,C        ; was result negative?
        return                  ; yes.
        movf    INDF,w          ; get command digit.
        PAGE3                   ; select page 3.
        call    LoadCtl         ; load control op settings.
        call    ResetRX         ; reset receiver states.
        PAGE1                   ; select code page 1.
        goto    LCmdOK
        
; ***********
; ** LCmd4 **
; ***********
LCmd4                           ; remote base control
        movf    cmdSize,w       ; check cmdSize
        sublw   d'2'            ; compare with zero.
        btfss   STATUS,Z        ; skip if zero
        return                  ; not 2 digits. Ignore.
        movf    INDF,w          ; get command digit.
        movwf   temp2           ; save command digit.
        decf    cmdSize,f       ; decrement cmdSize.
        incf    FSR,f           ; move pointer.
        movf    INDF,w          ; get command digit.
        movwf   temp3           ; save command digit.
        decf    cmdSize,f       ; decrement cmdSize.
        incf    FSR,f           ; move pointer.

        movf    temp2,w         ; get first digit.
        sublw   d'3'            ; subtract max valid
        btfss   STATUS,C        ; is valid digit?
        goto    LCmdErr         ; no.

        movf    temp3,w         ; get second digit.
        sublw   d'3'            ; subtract max valid
        btfss   STATUS,C        ; is valid digit?
        goto    LCmdErr         ; no.
        
        ;; apply first digit.
        bcf     group0,6        ; clear bit
        bcf     group0,7        ; clear bit
        btfsc   temp2,0         ; is bit 0 set?
        bsf     group0,6        ; yes, set rx1->tx1
        btfsc   temp2,1         ; is bit 1 set?
        bsf     group0,7        ; yes, set rx1->tx2

        ;; apply second digit.
        bcf     group2,6        ; clear bit
        bcf     group2,7        ; clear bit
        btfsc   temp3,0         ; is bit 0 set?
        bsf     group2,6        ; yes, set rx2->tx1
        btfsc   temp3,1         ; is bit 1 set?
        bsf     group2,7        ; yes, set rx2->tx2

        PAGE3                   ; select page 3.
        call    ResetRX         ; reset receiver states.
        PAGE1                   ; select code page 1.
        ;; done here.  send OK message
        goto    LCmdOK          ; send OK message.

; ***********
; ** LCmd5 **
; ***********
LCmd5                           ; digital output controls
        movf    cmdSize,w       ; get command size
        btfsc   STATUS,Z        ; skip if not zero.
        return                  ; fail quietly.
        movf    INDF,w          ; get command digit.
        btfsc   STATUS,Z        ; skip if not zero.
        goto    LCmdErr         ; zero is not allowed.
        movwf   temp            ; save command digit.
        sublw   d'4'            ; highest value.
        btfss   STATUS,C        ; skip if result is non-negative.
        goto    LCmdErr         ; was bigger than 4.
        decf    temp,f          ; decrement, now in 0-3 range.
        movlw   d'7'            ; ctl op group of digital outputs.
        movwf   temp2           ; save group # in temp 2.
        incf    FSR,f           ; move to next byte (bit #)
        decf    cmdSize,f       ; decrement command size
        PAGE2                   ; select code page 2.
        goto    CtlOpC          ; execute control op command

; ***********
; ** LCmd6 **
; ***********
LCmd6                           ; reset alarm
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        clrf    alrmTmr         ; clear alarm timer.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        goto    LCmdOK          ; send OK message.
        
; ***********
; ** LCmd7 **
; ***********
LCmd7                           ; unlock this port.
        movf    dtEFlag,w       ; get eval flags
        andlw   b'11100000'     ; mask all except command source indicators.
        iorwf   dtRFlag,f       ; IOR with dtRFlag: set unlocked bit.
        movlw   UNLKDLY         ; get unlocked mode timer.
        movwf   ulk1Tmr         ; set unlocked mode timer.
        movlw   CTUNLOK         ; get unlocked mode courtesy tone.
        movwf   ct1tone         ; yep. set unlocked courtesy tone.
        goto    LCmdOK          ; send OK.

; ************
; ** LCmdOn **
; ************
LCmdOn
        movlw   CW_ON           ; get CW ON
        goto    LCmdMsg         ; play response message.
 
; *************
; ** LCmdOff **
; *************
LCmdOff
        movlw   CW_OFF          ; get CW OFF
        goto    LCmdMsg         ; play response message.
 
; *************
; ** LCmdErr **
; *************
LCmdErr
        movlw   CW_NG           ; get CW OK
        goto    LCmdMsg         ; play response message.

; ************
; ** LCmdOK **
; ************
LCmdOK
        movlw   CW_OK           ; get CW OK
        goto    LCmdMsg         ; play response message.
 
; *************
; ** LCmdMsg **
; *************
LCmdMsg
        btfss   dtEFlag,DT1CMD  ; was command from DTMF-1?
        goto    LCmdMsg2        ; no.
        PAGE3                   ; select code page 3.
        call    PlayCW1         ; start playback
        PAGE1                   ; select code page 1.
        return

LCmdMsg2
        btfss   dtEFlag,DT2CMD  ; was command from DTMF-2?
        return
        PAGE3                   ; select code page 3.
        call    PlayCW2         ; start playback
        PAGE1                   ; select code page 1.
        return

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
        return                  ; done.

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
        xorlw   SCWRITE         ; compare to write character.
        btfsc   STATUS,Z        ; is result zero?
        goto    SCWrite         ; yes.
        movf    INDF,w          ; get byte from buffer
        xorlw   SCRESET         ; compare to reset character.
        btfsc   STATUS,Z        ; is result zero?
        goto    SCReset         ; yes.
        goto    SCSNAK          ; bad command.

SCWrite                         ; write data into EEPROM
        call    CIVGetB         ; get a byte value from 2 chars in buffer
        movwf   eeAddr          ; save the address.

        movlw   h'8'            ; transfer size
        movwf   eeCount         ; save number of bytes to write.
        movwf   temp6           ; save to counter.

        movlw   low eebuf00     ; get address of eeprom write buffer.
        movwf   temp5           ; save it.

SCWLoop
        call    CIVGetB         ; get byte from serial.
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
        PAGE1                   ; select code page 1.

        bcf     STATUS,IRP      ; select 00-FF range for FSR/INDF
        movlw   SCACK           ; ACK message
        call    SerOut          ; send it.
        movlw   SCCR            ; <CR>
        call    SerOut          ; send it.
        movlw   SCLF            ; <LF>
        call    SerOut          ; send it.
        goto    SCEnd           ; clean up and return.
        
SCRead                          ; read EEPROM data...
        call    CIVGetB         ; read the address.
        movwf   eeAddr          ; save the address.
        incf    FSR,F           ; move pointer.
        movf    INDF,w          ; get next byte
        xorlw   SCTERM          ; compare to command terminator
        btfss   STATUS,Z        ; is it a zero?
        goto    SCSNAK          ; nope.  not a valid command.
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
        PAGE1                   ; select code page 1.

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
        goto    SCEnd           ; clean up and return

SCReset
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        bcf     serFlag,SC_RDY  ; clear serial data ready flag.
        PAGE0
        goto    Start1          ; reset.

SCSNAK                          ; send NAK message.
        movlw   SCNAK           ; NAK message
        call    SerOut          ; send it.
        movlw   SCCR            ; <CR>
        call    SerOut          ; send it.
        movlw   SCLF            ; <LF>
        call    SerOut          ; send it.
        goto    SCEnd           ; clean up and return.
                
SCEnd                           ; done looking at serial command.
        bsf     STATUS,IRP      ; select 100-1FF range for FSR/INDF
        clrf    rxHead          ; reset receive buffer pointer.
        bcf     serFlag,SC_RDY  ; clear serial data ready flag.
        bcf     serFlag,SC_CMD  ; reset no-echo flag.
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
        movf    FSR,w           ; get FSR for serial receive buffer.
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
                
; ************************************************************************
; ****************************** ROM PAGE 2 ******************************
; ************************************************************************
        org     1000            ; page 2
        
; ***********
; ** UlCmd **
; ***********
UlCmd                           ; process an Unlocked Command!
        movlw   UNLKDLY         ; get unlocked mode timeout time.
        movwf   ulk1Tmr         ; set unlocked mode timer.
        movlw   CTUNLOK         ; get the unlocked courtesy tone.
        movwf   ct1tone         ; save the courtesy tone.
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
        clrf    ulk1Tmr         ; reset unlocked mode timer.
        movlw   CTNONE          ; select no courtesy tone.
        movwf   ct1tone         ; set courtesy tone.
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
        goto    UlCmd4          ; command *4 -- invalid command
        goto    UlCmd5          ; command *5 -- invalid command
        goto    UlCmd6          ; command *6 -- incaliv command
        goto    UlCmd7          ; command *7 -- program/play CW/Tones
        goto    UlCmd8          ; command *8 -- invalid command
        goto    UlCmd9          ; command *9 -- invalid command
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
        sublw   d'6'            ; check for group6
        btfsc   STATUS,Z        ; is it group6?
        call    SetDig          ; set the digital outputs.
        
        movf    temp2,w         ; get index.
        sublw   d'7'            ; check for group6
        btfsc   STATUS,Z        ; is it group6?
        call    SetDig7         ; set the digital outputs.
        
        PAGE3                   ; select page 3.
        call    ResetRX         ; reset receiver states.
        PAGE2                   ; select code page 2.
        
        movlw   CW_OFF          ; get CW OFF message
        goto    UlMsg           ; play message to correct port.

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
        sublw   d'6'            ; check for group6
        btfsc   STATUS,Z        ; is it group6?
        call    SetDig          ; set the digital outputs.

        movf    temp2,w         ; get index.
        sublw   d'7'            ; check for group7
        btfsc   STATUS,Z        ; is it group7?
        call    SetDig7         ; set the digital outputs.
                                
        PAGE3                   ; select page 3.
        call    ResetRX         ; reset receiver states.
        PAGE2                   ; select code page 2.
        
        movlw   CW_ON           ; get CW ON message.
        goto    UlMsg

SetDig                          ; set digital output pins.
        btfss   group6,0        ; digital output configured?
        return                  ; no.
        btfss   group6,1        ; is digital output supposed to be on?
        goto    SetDig0         ; no, it's off.
        bsf     PORTA,FANCTL    ; turn on digital output.
        btfss   group6,2        ; check for pulsed configuration.
        return                  ; not pulsed
        movlw   PULS_TM         ; get pulse time.
        movwf   pulsTmr         ; set pulse timer.
        return                  ; done here.
SetDig0
        bcf     PORTA,FANCTL    ; turn on digital output.
        clrf    pulsTmr         ; clear pulse timer, just in case.
        return                  ; done here.

SetDig7                         ; set digital output pins.
        swapf   group7,w        ; get group 7, swap nibbles.
        andlw   b'11110000'     ; clear unneeded bits.
        movwf   temp            ; save.
        movf    PORTD,w         ; get PORTD bits.
        andlw   b'00001111'     ; clear unneeded bits.
        iorwf   temp,w          ; set bits from group 7
        movwf   PORTD           ; put entire byte back to PORTD.
        swapf   group7,w        ; get group7 bytes swapped
        andwf   group7,w        ; and group7
        ;; gnarly logic says that if the result is non-zero, then
        ;; one pulsed output is turned on.
        btfsc   STATUS,Z        ; any pulsed outputs enabled?
        return                  ; nope.
        movlw   PULS_TM         ; get pulse timer initial value.
        movwf   pulsTmr         ; set pulse timer.
        return                  ; done.
        
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
        goto    UlMsg
        
                
; ************
; ** UlCmd1 **
; ************
        ;; save control operator Group/Item/States to a specified setup.
UlCmd1                          ; save setups
        btfsc   group8,0        ; are control groups write protected?
        goto    UlCmdNG         ; yes.
        movf    cmdSize,w       ; get command size
        sublw   d'1'            ; subtract expected size
        btfss   STATUS,Z        ; was it the expected size?
        goto    UlCmdNG         ; nope.
        movf    INDF,w          ; get setup number
        sublw   d'4'            ; subtract largest expected
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
        ;; program command prefix
UlCmd2                          ; program prefixes
        btfsc   group8,1        ; are prefixes write protected?
        goto    UlCmdNG         ; yes.
        movlw   d'3'            ; minimum command length
        subwf   cmdSize,w       ; w = cmdSize - w
        btfss   STATUS,C        ; skip if result is non-negative (cmdsize >= 3)
        goto    UlCmdNG         ; not enough command digits.
        movf    cmdSize,w       ; get command size
        sublw   d'10'           ; get max command length
        btfss   STATUS,C        ; skip if result is non-negative (cmdSize <= 10)
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
        btfss   STATUS,C        ; skip if result is non-negative (pfxnum <= MAXPFX)
        goto    UlCmdNG         ; argument error
        decf    cmdSize,f       ; less bytes to process
        incf    FSR,f           ; point at next byte.

        movf    temp,w          ; get index back.
        sublw   MAXPFX          ; subtract index of unlock command.
        btfss   STATUS,Z        ; is result zero?
        goto    UlCmd2P         ; no.
        btfsc   PORTA,INIT      ; skip if init button pressed.
        goto    UlCmdNG         ; bad command.
        
UlCmd2P                         ; program the new prefix.
        movf    cmdSize,w       ; get command length
        movwf   eeCount         ; save # bytes to write.
        sublw   d'8'            ; check for length of 8
        btfss   STATUS,Z        ; is it zero?
        incf    eeCount,f       ; No.  add 1 so FF at end of buffer gets copied.
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
;    *3<nn> inquire timer nn                                                 ;
;    *3<nn><time> set timer nn to time                                       ;
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
        btfsc   group8,2        ; are timers write protected?
        goto    UlCmdNG         ; yes.
        PAGE3                   ; select page 3
        call    GetDNum         ; get decimal number to w. nukes temp3,temp4
        movwf   temp4           ; save decimal number to temp4.
        call    WriteEw         ; write w into EEPROM.
        call    CWParms         ; set CW parameters.
        PAGE2                   ; select page 2
UlCmd3a
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
        movwf   ct1tone         ; save CT index.
        movwf   ct2tone         ; save CT index.
        PAGE3                   ; select code page 3.
        btfsc   dtEFlag,DT1CMD  ; is the command from DTMF-1?
        call    PlayCT1         ; play courtesy tone #w
        btfsc   dtEFlag,DT2CMD  ; is the command from DTMF-2?
        call    PlayCT2         ; play courtesy tone #w
        PAGE2                   ; select code page 2.
        return                  ; done

UC71R                           ; record courtesy tone.
        btfsc   group8,6        ; are courtesy tones write protected?
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
        goto    UlCmd70a        ; more digits...
        goto    UlCmdNG         ; not enough command digits.

UlCmd70a                        ; 
        movf    INDF,w          ; get next command digit.
        movwf   temp2           ; save the ID number.

        incf    FSR,f           ; move to next byte.
        decfsz  cmdSize,f       ; decrement commandSize.
                
        goto    UC70R           ; there are more digits, record CW ID.
        
        movlw   EECWID1         ; address of CW ID 1 message in EEPROM.
        movf    temp2,f         ; set status bits
        btfss   STATUS,Z        ; is temp zero?
        movlw   EECWID2         ; no, use address of CW ID 2 message in EEPROM.
        
        movwf   eeAddr          ; save CT base address
        PAGE3                   ; select code page 3.
        btfsc   dtEFlag,DT1CMD  ; is the command from rx1?
        call    PlayCWe1        ; yes, start CW playback.
        btfsc   dtEFlag,DT2CMD  ; is the command from rx2?
        call    PlayCWe2        ; yes, start CW playback.
        PAGE2                   ; select code page 2.

        return                  ; no
        
UC70R                           ; record CW ID.
        btfsc   group8,6        ; are CWID/courtesy tones write protected?
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
        movlw   EECWID1         ; address of CW ID 1 message in EEPROM.
        movf    temp2,f         ; set status bits
        btfss   STATUS,Z        ; is temp zero?
        movlw   EECWID2         ; no, use address of CW ID 2 message in EEPROM.
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
UlCmd8                          ; not implemented.
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

UlCmdNG                         ; "BAD COMMAND"
        movlw   CW_NG           ; get NG message.

UlErr
UlMsg                           ; play unlocked confirmation message out the correct port.
        btfss   dtEFlag,DT1CMD  ; was command from DTMF-1?
        goto    UlMsg2          ; no.
        PAGE3                   ; select code page 3.
        call    PlayCW1         ; start playback
        PAGE2                   ; select code page 1.
        return

UlMsg2
        btfss   dtEFlag,DT2CMD  ; was command from DTMF-2?
        return                  ; no.

; ************************************************************************
; ****************************** ROM PAGE 3 ******************************
; ************************************************************************
        org     1800            ; page 3

; *************
; ** PlayCW1 **
; *************
        ;; play CW from ROM table.  Address in W.
PlayCW1
        movwf   temp            ; save CW address.
        movf    beep1ctl,w      ; get beep control flag.
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBp1         ; kill off beep sequence in progress.
        movf    temp,w          ; get back CW address.
        movwf   beep1adr        ; set CW address.
        movlw   CW_ROM          ; CW from the ROM table
        movwf   beep1ctl        ; set control flags.
        call    GtBeep1         ; get next character.
        movwf   cw1byte         ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cw1tmr          ; preset cw timer
        bcf     tx1flg2,CWBEEP  ; make sure that beep is off
        bsf     tx1flag,CWPLAY  ; turn on CW sender
        call    Tx1On           ; turn on tx1 transmitter.
        return

; *************
; ** PlayCW2 **
; *************
        ;; play CW from ROM table.  Address in W.
PlayCW2
        movwf   temp            ; save CW address.
        movf    beep2ctl,w      ; get beep control flag.
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBp2         ; kill off beep sequence in progress.
        movf    temp,w          ; get back CW address.
        movwf   beep2adr        ; set CW address.
        movlw   CW_ROM          ; CW from the ROM table
        movwf   beep2ctl        ; set control flags.
        call    GtBeep2         ; get next character.
        movwf   cw2byte         ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cw2tmr          ; preset cw timer
        bcf     tx2flg2,CWBEEP  ; make sure that beep is off
        bsf     tx2flag,CWPLAY  ; turn on CW sender
        call    Tx2On           ; turn on tx2 transmitter.
        return

; **************
; ** PlayCWe1 **
; **************
        ;; play CW from EEPROM addresses named by eeAddr
PlayCWe1
        movf    beep1ctl,w      ; get beep control flag.
        andlw   b'00011100'     ; is the beeper already busy?
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBp1         ; kill off beep sequence in progress.
        movf    eeAddr,w        ; get lo byte of address.
        movwf   beep1adr        ; set lo byte of address of beep.
        movlw   CW_EE           ; select CW from EEPROM
        movwf   beep1ctl        ; set control flags.
        call    GtBeep1         ; get next character.
        movwf   cw1byte         ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cw1tmr          ; preset cw timer
        bcf     tx1flg2,CWBEEP  ; make sure that beep is off
        bsf     tx1flag,CWPLAY  ; turn on CW sender
        call    Tx1On           ; turn on tx1 transmitter.
        return

; **************
; ** PlayCWe2 **
; **************
        ;; play CW from EEPROM addresses named by eeAddr
PlayCWe2
        movf    beep2ctl,w      ; get beep control flag.
        andlw   b'00011100'     ; is the beeper already busy?
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBp2         ; kill off beep sequence in progress.
        movf    eeAddr,w        ; get lo byte of address.
        movwf   beep2adr        ; set lo byte of address of beep.
        movlw   CW_EE           ; select CW from EEPROM
        movwf   beep2ctl        ; set control flags.
        call    GtBeep2         ; get next character.
        movwf   cw2byte         ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cw2tmr          ; preset cw timer
        bcf     tx2flg2,CWBEEP  ; make sure that beep is off
        bsf     tx2flag,CWPLAY  ; turn on CW sender
        call    Tx2On           ; turn on tx2 transmitter.
        return

; **************
; ** PlayCWL1 **
; **************
        ;; play single CW letter, code in w.
PlayCWL1
        movwf   temp            ; save letter.
        movf    beep1ctl,w      ; get beep control flag.
        andlw   b'00011100'     ; is the beeper already busy?
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBp1         ; kill off beep sequence in progress.
        movf    eeAddr,w        ; get lo byte of address.
        movwf   beep1adr        ; set lo byte of address of beep.
        movlw   CW_LETR         ; select CW single letter mode.
        movwf   beep1ctl        ; set control flags.
        movf    temp,w          ; get letter back.
        call    GetCW           ; get CW bitmap.
        movwf   cw1byte         ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cw1tmr          ; preset cw timer
        bcf     tx1flg2,CWBEEP  ; make sure that beep is off
        bsf     tx1flag,CWPLAY  ; turn on CW sender
        return

; **************
; ** PlayCWL2 **
; **************
        ;; play single CW letter, code in w.
PlayCWL2
        movwf   temp            ; save letter.
        movf    beep2ctl,w      ; get beep control flag.
        andlw   b'00011100'     ; is the beeper already busy?
        btfss   STATUS,Z        ; result will be zero if no.
        call    KillBp2         ; kill off beep sequence in progress.
        movf    eeAddr,w        ; get lo byte of address.
        movwf   beep2adr        ; set lo byte of address of beep.
        movlw   CW_LETR         ; select CW single letter mode.
        movwf   beep2ctl        ; set control flags.
        movf    temp,w          ; get letter back.
        call    GetCW           ; get CW bitmap.
        movwf   cw2byte         ; save byte in CW bitmap
        movlw   CWIWSP          ; get startup delay
        movwf   cw2tmr          ; preset cw timer
        bcf     tx2flg2,CWBEEP  ; make sure that beep is off
        bsf     tx2flag,CWPLAY  ; turn on CW sender
        return

; **************
; ** PlayCTx1 **
; **************
        ;; play a courtesy tone from the ROM table.
        ;; courtesy tone offset in W.
PlayCTx1                        ; play a courtesy tone
        movwf   temp            ; save the courtesy tone offset.
        movf    beep1ctl,f      ; already beeping?
        btfss   STATUS,Z        ; result will be zero if no.
        return                  ; already beeping.
        movf    temp,w          ; get back courtesy tone offset.
        movwf   beep1adr        ; set beep address lo byte.
        movlw   BEEP_CX         ; CT beep. (from table)
        movwf   beep1ctl        ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beep1tmr        ; set initial start
        bsf     tx1flag,BEEPING ; beeping is enabled!
        return                  ; done.

; **************
; ** PlayCTx2 **
; **************
        ;; play a courtesy tone from the ROM table.
        ;; courtesy tone offset in W.
PlayCTx2                        ; play a courtesy tone
        movwf   temp            ; save the courtesy tone offset.
        movf    beep2ctl,f      ; already beeping?
        btfss   STATUS,Z        ; result will be zero if no.
        return                  ; already beeping.
        movf    temp,w          ; get back courtesy tone offset.
        movwf   beep2adr        ; set beep address lo byte.
        movlw   BEEP_CX         ; CT beep. (from table)
        movwf   beep2ctl        ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beep2tmr        ; set initial start
        bsf     tx2flag,BEEPING ; beeping is enabled!
        return                  ; done.

; *************
; ** PlayCT1 **
; *************
        ;; play courtesy tone # ct1tone from EEPROM.
PlayCT1                         ; play a courtesy tone.
        btfsc   ct1tone,7       ; sleazy easy check for no CT...
        return                  ; courtesy tone is suppressed.
        movf    beep1ctl,f      ; already beeping?
        btfss   STATUS,Z        ; result will be zero if no.
        return                  ; already beeping.
        movlw   EECTB           ; get CT base.
        movwf   beep1adr        ; save CT base address.

        movf    ct1tone,w       ; examine ct1tone.
        andlw   h'07'           ; force into reasonable range.
        movwf   temp            ; copy to temp.
        bcf     STATUS,C        ; clear carry bit.
        rlf     temp,f          ; multiply msg # by 2
        rlf     temp,f          ; multiply msg # by 2 (x4 after)
        rlf     temp,w          ; multiply msg # by 2 (x8 after)
        addwf   beep1adr,f      ; add offset of ctsy tone to beep base addr.
        ;; now have EEPROM address of CT. reset courtesy tone indicator.
        movlw   CTNONE          ; get no CT indicator.
        movwf   ct1tone         ; save it.
        movf    beep1adr,w      ; get low byte of EEPROM address.
        movwf   eeAddr          ; set low byte of EEPROM address.

        call    ReadEEw         ; read 1 byte from EEPROM.
        movwf   temp            ; save eeprom data.
        xorlw   MAGICCT         ; xor with magic CT number.
        btfss   STATUS,Z        ; skip if result is zero (MAGIC number used)
        goto    PlayCT1a        ; play normal CT segment.

        ;; this is where the morse digit send goes.
        incf    eeAddr,f        ; move to next byte of CT.
        call    ReadEEw         ; read 1 byte from EEPROM.
        goto    PlayCWL1        ; play the CW letter
        
PlayCT1a
        movlw   BEEP_CT         ; CT beep.
        movwf   beep1ctl        ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beep1tmr        ; set initial start
        bsf     tx1flag,BEEPING ; beeping is enabled!
        return                  ; done.

; *************
; ** PlayCT2 **
; *************
        ;; play courtesy tone # ct2tone from EEPROM.
PlayCT2                         ; play a courtesy tone.
        btfsc   ct2tone,7       ; sleazy easy check for no CT...
        return                  ; courtesy tone is suppressed.
        movf    beep2ctl,f      ; already beeping?
        btfss   STATUS,Z        ; result will be zero if no.
        return                  ; already beeping.
        movlw   EECTB           ; get CT base.
        movwf   beep2adr        ; save CT base address.

        movf    ct2tone,w       ; examine ct2tone.
        andlw   h'07'           ; force into reasonable range.
        movwf   temp            ; copy to temp.
        bcf     STATUS,C        ; clear carry bit.
        rlf     temp,f          ; multiply msg # by 2
        rlf     temp,f          ; multiply msg # by 2 (x4 after)
        rlf     temp,w          ; multiply msg # by 2 (x8 after)
        addwf   beep2adr,f      ; add offset of ctsy tone to beep base addr.
        ;; now have EEPROM address of CT. reset courtesy tone indicator.
        movlw   CTNONE          ; get no CT indicator.
        movwf   ct2tone         ; save it.
        movf    beep2adr,w      ; get low byte of EEPROM address.
        movwf   eeAddr          ; set low byte of EEPROM address.

        call    ReadEEw         ; read 1 byte from EEPROM.
        movwf   temp            ; save eeprom data.
        xorlw   MAGICCT         ; xor with magic CT number.
        btfss   STATUS,Z        ; skip if result is zero (MAGIC number used)
        goto    PlayCT2a        ; play normal CT segment.

        ;; this is where the morse digit send goes.
        incf    eeAddr,f        ; move to next byte of CT.
        call    ReadEEw         ; read 1 byte from EEPROM.
        goto    PlayCWL2        ; play the CW letter
        
PlayCT2a
        movlw   BEEP_CT         ; CT beep.
        movwf   beep2ctl        ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beep2tmr        ; set initial start
        bsf     tx2flag,BEEPING ; beeping is enabled!
        return                  ; done.

; ************* 
; ** KillBp1 **
; ************* 
        ;; kill off whatever is beeping now.
KillBp1
        clrf    beep1tmr        ; clear beep timer
        clrf    beep1ctl        ; clear beep control flags
        bcf     tx1flag,BEEPING ; reset the transmitter flag
        clrw                    ; select no tone.
        call    SetTone1        ; set the beep tone up.
        return
        
; ************* 
; ** KillBp2 **
; ************* 
        ;; kill off whatever is beeping now.
KillBp2
        clrf    beep2tmr        ; clear beep timer
        clrf    beep2ctl        ; clear beep control flags
        bcf     tx2flag,BEEPING ; reset the transmitter flag
        clrw                    ; select no tone.
        call    SetTone2        ; set the beep tone up.
        return
        
; **************
; ** GetBeep1 **
; **************
        ;; get the next beep tone from whereever.
        ;; select the tone, etc.
        ;; uses temp.
GetBeep1                        ; get the next beep character
        btfsc   beep1ctl,B_LAST ; was the last segment just sent?
        goto    Beep1Don        ; yes.  stop beeping.
        call    GtBeep1         ; get length byte
        movwf   beep1tmr        ; save length
        call    GtBeep1         ; get tone byte
        movwf   temp            ; save tone byte
        btfss   temp,7          ; is the continue bit set?
        bsf     beep1ctl,B_LAST ; no. mark this segment last.
        movlw   b'00111111'     ; mask
        andwf   temp,f          ; mask out control bits.
        goto    SetBeep1        ; set the beep tone

Beep1Don                        ; stop that confounded beeping...
        clrf    temp            ; set quiet beep
        bcf     tx1flag,BEEPING ; beeping is done...
        clrf    beep1ctl        ; clear beep control flags
        clrf    beep1tmr        ; clear beep timer

SetBeep1
        movf    temp,w          ; get beep tone.
        call    SetTone1        ; set the beep tone up.
        return

GtBeep1                         ; get the next character for the beep message
        movf    beep1ctl,w      ; get control flag bits
        andlw   b'00000011'     ; mask significant control flag bits.
        movwf   temp            ; save w
        movlw   high GtBpTbl1   ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        addwf   PCL,f           ; add w to PCL
        
GtBpTbl1
        goto    GtBEE1          ; get beep char from EEPROM
        goto    GtBROM1         ; get beep char from hardcoded ROM table
        goto    GtBRAM1         ; get beep char from RAM address
        goto    GtBLETR1        ; get beep for single CW letter.
        
GtBEE1                          ; get beep char from EEPROM
        movf    beep1adr,w      ; get lo byte of EEPROM address
        movwf   eeAddr          ; store to EEPROM address lo byte
        incf    beep1adr,f      ; increment pointer
        call    ReadEEw         ; read 1 byte from EEPROM
        return                  ;
GtBROM1                         ; get beep char from ROM table
        movf    beep1adr,w      ; get address low byte (hi is not used here)
        incf    beep1adr,f      ; increment pointer
        call    MesgTabl        ; get char from table
        return                  ;
GtBRAM1                         ; get beep char from RAM
        movf    beep1adr,w      ; get address low byte (hi is not used here)
        movwf   FSR             ; set indirect register pointer
        incf    beep1adr,f      ; increment pointer
        movf    INDF,w          ; get data byte from RAM
        return                  ; 

GtBLETR1                        ; get single CW letter.
        retlw   h'ff'           ; return ff.

; **************
; ** GetBeep2 **
; **************
        ;; get the next beep tone from whereever.
        ;; select the tone, etc.
        ;; uses temp.
GetBeep2                        ; get the next beep character
        btfsc   beep2ctl,B_LAST ; was the last segment just sent?
        goto    Beep2Don        ; yes.  stop beeping.
        call    GtBeep2         ; get length byte
        movwf   beep2tmr        ; save length
        call    GtBeep2         ; get tone byte
        movwf   temp            ; save tone byte
        btfss   temp,7          ; is the continue bit set?
        bsf     beep2ctl,B_LAST ; no. mark this segment last.
        movlw   b'00111111'     ; mask
        andwf   temp,f          ; mask out control bits.
        goto    SetBeep2        ; set the beep tone

Beep2Don                        ; stop that confounded beeping...
        clrf    temp            ; set quiet beep
        bcf     tx2flag,BEEPING ; beeping is done...
        clrf    beep2ctl        ; clear beep control flags
        clrf    beep2tmr        ; clear beep timer

SetBeep2
        movf    temp,w          ; get beep tone.
        call    SetTone2        ; set the beep tone up.
        return

GtBeep2                         ; get the next character for the beep message
        movf    beep2ctl,w      ; get control flag bits
        andlw   b'00000011'     ; mask significant control flag bits.
        movwf   temp            ; save w
        movlw   high GtBpTbl2   ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        addwf   PCL,f           ; add w to PCL
        
GtBpTbl2
        goto    GtBEE2          ; get beep char from EEPROM
        goto    GtBROM2         ; get beep char from hardcoded ROM table
        goto    GtBRAM2         ; get beep char from RAM address
        goto    GtBLETR2        ; get beep for single CW letter.
        
GtBEE2                          ; get beep char from EEPROM
        movf    beep2adr,w      ; get lo byte of EEPROM address
        movwf   eeAddr          ; store to EEPROM address lo byte
        incf    beep2adr,f      ; increment pointer
        call    ReadEEw         ; read 1 byte from EEPROM
        return                  ;
GtBROM2                         ; get beep char from ROM table
        movf    beep2adr,w      ; get address low byte (hi is not used here)
        incf    beep2adr,f      ; increment pointer
        call    MesgTabl        ; get char from table
        return                  ;
GtBRAM2                         ; get beep char from RAM
        movf    beep2adr,w      ; get address low byte (hi is not used here)
        movwf   FSR             ; set indirect register pointer
        incf    beep2adr,f      ; increment pointer
        movf    INDF,w          ; get data byte from RAM
        return                  ; 

GtBLETR2                        ; get single CW letter.
        retlw   h'ff'           ; return ff.
        
; ***********
; ** Tx1On **
; ***********
        ;; turn on PTT & set up ID timer, etc., if needed.
Tx1On                           ; key the transmitter
        btfss   group4,0        ; is TX1 enabled?
        return                  ; no.
        clrf    cb1Tmr          ; clear chicken-burst timer.
        btfsc   tx1flg2,TXONFLG ; is transmitter already on?
        return                  ; yep.
        ;; transmitter was not already on. turn it on.
        btfsc   group6,6        ; is chicken burst enabled?
        bsf     PORTD,TX1ENC    ; yes, turn on chicken burst.
        bsf     PORTB,TX1PTT    ; apply PTT!
        ;; set the remote base transmitter on if enabled and is a repeater.
        bsf     tx1flg2,TXONFLG ; set last tx state flag
        movf    id1tmr,f        ; check ID timer
        btfsc   STATUS,Z        ; is it zero?
        goto    PTT1init        ; yes
        btfsc   tx1flg2,NEEDID  ; is NEEDID set?
        goto    TxOnFan         ; yes.
        goto    PTT1set         ; not set, set NEEDID and reset id1tmr
PTT1init
        bsf     tx1flg2,INITID  ; ID timer was zero, set initial ID flag
PTT1set
        bsf     tx1flg2,NEEDID  ; need to play ID
        movlw   EETID1          ; get address of ID timer
        movwf   eeAddr          ; set address of ID timer
        call    ReadEEw         ; get byte from EEPROM
        movwf   id1tmr          ; store to down-counter
        goto    TxOnFan         ; deal with tx fan.
        
; ***********
; ** Tx2On **
; ***********
        ;; turn on PTT & set up ID timer, etc., if needed.
Tx2On                           ; key the transmitter
        btfss   group5,0        ; is TX2 enabled?
        return                  ; no.
        clrf    cb2Tmr          ; clear chicken-burst timer.
        btfsc   tx2flg2,TXONFLG ; is transmitter already on?
        return                  ; yep.
        ;; transmitter was not already on. turn it on.
        btfsc   group6,7        ; is chicken burst enabled?
        bsf     PORTD,TX2ENC    ; yes, turn on chicken burst.
        bsf     PORTB,TX2PTT    ; apply PTT!
        ;; set the remote base transmitter on if enabled and is a repeater.
        bsf     tx2flg2,TXONFLG ; set last tx state flag
        movf    id2tmr,f        ; check ID timer
        btfsc   STATUS,Z        ; is it zero?
        goto    PTT2init        ; yes
        btfsc   tx1flg2,NEEDID  ; is NEEDID set?
        goto    TxOnFan         ; yes.
        goto    PTT2set         ; not set, set NEEDID and reset id1tmr
PTT2init
        bsf     tx2flg2,INITID  ; ID timer was zero, set initial ID flag
PTT2set
        bsf     tx2flg2,NEEDID  ; need to play ID
        movlw   EETID2          ; get address of ID timer
        movwf   eeAddr          ; set address of ID timer
        call    ReadEEw         ; get byte from EEPROM
        movwf   id2tmr          ; store to down-counter

TxOnFan
        btfsc   group6,0        ; is fan control enabled?
        return                  ; no.
        clrf    fanTmr          ; disable fan timer, fan stays on.
        bsf     PORTA,FANCTL    ; turn on fan
        return                  ; done here

; ************
; ** Tx1Off **
; ************
Tx1Off
        btfsc   group6,6        ; is chicken-burst turned on?
        goto    Tx1OCB          ; yes
        ;; don't care if already off, turn off again. (can't hurt)
        bcf     PORTB,TX1PTT    ; turn off main PTT!
        bcf     tx1flg2,TXONFLG ; clear last tx state flag
        goto    TxOffFan        ; check fan...

Tx1OCB
        movlw   CKNBRST         ; get chickenburst delay.
        movwf   cb1Tmr          ; set chicken burst timer, tx1.
        bcf     PORTD,TX1ENC    ; turn CTCSS encoder off, tx1.
        bcf     tx1flg2,TXONFLG ; clear last tx state flag
        goto    TxOffFan        ; check fan...

; ************
; ** Tx2Off **
; ************
Tx2Off
        btfsc   group6,7        ; is chicken-burst turned on?
        goto    Tx2OCB          ; yes
        ;; don't care if already off, turn off again. (can't hurt)
        bcf     PORTB,TX2PTT    ; turn off tx2 PTT!
        bcf     tx2flg2,TXONFLG ; clear last tx state flag
        goto    TxOffFan        ; check fan...

Tx2OCB
        movlw   CKNBRST         ; get chickenburst delay.
        movwf   cb2Tmr          ; set chicken burst timer, tx2.
        bcf     PORTD,TX2ENC    ; turn CTCSS encoder off, tx2.
        bcf     tx2flg2,TXONFLG ; clear last tx state flag
        goto    TxOffFan        ; check fan...

TxOffFan
        btfsc   group6,0        ; is fan control enabled?
        return                  ; no.
        movlw   EETFAN          ; get EEPROM address of ID timer preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        movwf   fanTmr          ; set fan timer
        btfsc   STATUS,Z        ; is fan timer zero?
        bcf     PORTA,FANCTL    ; yes, turn off fan now.
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
        bsf     STATUS,RP0      ; set A7 for addresses 80-ff, 180-1ff
        movwf   stateNo         ; save state number.
        bcf     STATUS,RP0      ; clear A7 for addresses 00-7f, 100-17f
        movlw   EE0B            ; yes, get address of set zero.
        movwf   eeAddr          ; save address
        swapf   temp,w          ; magic! get group number * 16
        addwf   eeAddr,f        ; now have ee address for saved state.
        movlw   EESSC           ; get the number of bytes to read.
        movwf   eeCount         ; set the number of bytes to read.
        movlw   group0          ; get address of first group
        movwf   FSR             ; set pointer
        bcf     STATUS,IRP      ; to page 0.
        call    ReadEE          ; read bytes from EEPROM.
        bsf     STATUS,IRP      ; back to page 1.
        PAGE2                   ; select code page 2.
        call    SetDig          ; set digital I/O up.
        call    SetDig7         ; set digital outputs 1-4 up.
        PAGE3                   ; select code page 3.
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


; *************
; ** ResetRX **
; *************
ResetRX
        ;; reset both receivers after a mode change.
        clrf    rx1dbc          ; clear receiver 1 debouncer counter
        bcf     flags,RX1USQ    ; mark receiver 1 idle
        clrf    rx2dbc          ; clear receiver 2 debouncer counter
        bcf     flags,RX2USQ    ; mark receiver 2 idle
        return                  ; done here

        
; ******************************
; ** ROM Table Fetches follow **
; ******************************

        org     h'1a00'
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
CWTbl                           ; MORSE CODE / CW CHARACTER TABLE
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
        retlw   h'6a'           ; 16 /aaa/ .
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


        org     h'1b00'
InitDat
        movwf   temp            ; save addr.
        btfsc   temp,7          ; look for top 128
        goto    InitD2          ; go to other lookup
        movlw   high InitTbl    ; set page
        movwf   PCLATH          ; select page
        movf    temp,w          ; get address back
        addwf   PCL,f           ; add w to PCL
InitTbl
        ;; timer initial defaults
        retlw   d'100'          ; 0000 hang timer long 10.0 sec
        retlw   d'50'           ; 0001 hang timer short 5.0 sec
        retlw   d'54'           ; 0002 tx1 ID timer 9.0 min
        retlw   d'54'           ; 0003 tx2 ID timer 9.0 min
        retlw   d'60'           ; 0004 DTMF access timer 60 sec
        retlw   d'180'          ; 0005 timeout timer long 180 sec
        retlw   d'30'           ; 0006 timeout timer short 30 sec
        retlw   d'12'           ; 0007 fan timer 120 sec
        retlw   d'6'            ; 0008 alarm timer, 60 sec
        retlw   d'50'           ; 0009 tx1 ct front porch delay
        retlw   d'50'           ; 000a tx2 ct front porch delay
        retlw   d'20'           ; 000b cw pitch tx1
        retlw   d'20'           ; 000c cw speed tx1
        retlw   d'20'           ; 000d cw pitch tx2
        retlw   d'20'           ; 000e cw speed tx2
        retlw   d'0'            ; 000f spare

        ;; control operator switches, set 0. A->B, B->A. both simplex, no CT
        retlw   b'10000001'     ; 0010 control operator switches, group 0
        retlw   b'11000110'     ; 0011 control operator switches, group 1
        retlw   b'01000001'     ; 0012 control operator switches, group 2
        retlw   b'11000110'     ; 0013 control operator switches, group 3
        retlw   b'00001001'     ; 0014 control operator switches, group 4
        retlw   b'00001001'     ; 0015 control operator switches, group 5
        retlw   b'00000000'     ; 0016 control operator switches, group 6
        retlw   b'00000000'     ; 0017 control operator switches, group 7
        retlw   b'00000000'     ; 0018 control operator switches, group 8
        retlw   b'11111111'     ; 0019 control operator switches, group 9
        retlw   h'00'           ; 001a spare
        retlw   h'00'           ; 001b spare
        retlw   h'00'           ; 001c spare
        retlw   h'00'           ; 001d spare
        retlw   h'00'           ; 001e spare
        retlw   h'00'           ; 001f spare

        ;; control operator switches, set 1. A->B, B->A. both simplex, no CT
        retlw   b'10000001'     ; 0020 control operator switches, group 0
        retlw   b'11000110'     ; 0021 control operator switches, group 1
        retlw   b'01000001'     ; 0022 control operator switches, group 2
        retlw   b'11000110'     ; 0023 control operator switches, group 3
        retlw   b'00001001'     ; 0024 control operator switches, group 4
        retlw   b'00001001'     ; 0025 control operator switches, group 5
        retlw   b'00000000'     ; 0026 control operator switches, group 6
        retlw   b'00000000'     ; 0027 control operator switches, group 7
        retlw   b'00000000'     ; 0028 control operator switches, group 8
        retlw   b'11111111'     ; 0029 control operator switches, group 9
        retlw   h'00'           ; 002a spare
        retlw   h'00'           ; 002b spare
        retlw   h'00'           ; 002c spare
        retlw   h'00'           ; 002d spare
        retlw   h'00'           ; 002e spare
        retlw   h'00'           ; 002f spare

        ;; control operator switches, set 2. A->A,B, B->A. A repeat, B remote
        retlw   b'11000001'     ; 0030 control operator switches, group 0
        retlw   b'11000110'     ; 0031 control operator switches, group 1
        retlw   b'01000001'     ; 0032 control operator switches, group 2
        retlw   b'11000110'     ; 0033 control operator switches, group 3
        retlw   b'11101011'     ; 0034 control operator switches, group 4
        retlw   b'11001001'     ; 0035 control operator switches, group 5
        retlw   b'00000000'     ; 0036 control operator switches, group 6
        retlw   b'00000000'     ; 0037 control operator switches, group 7
        retlw   b'00000000'     ; 0038 control operator switches, group 8
        retlw   b'11111111'     ; 0039 control operator switches, group 9
        retlw   h'00'           ; 003a spare
        retlw   h'00'           ; 003b spare
        retlw   h'00'           ; 003c spare
        retlw   h'00'           ; 003d spare
        retlw   h'00'           ; 003e spare
        retlw   h'00'           ; 003f spare

        ;; control operator switches, set 3. A->A, B-B. both repeat.
        retlw   b'01000001'     ; 0040 control operator switches, group 0
        retlw   b'11000110'     ; 0041 control operator switches, group 1
        retlw   b'10000001'     ; 0042 control operator switches, group 2
        retlw   b'11000110'     ; 0043 control operator switches, group 3
        retlw   b'11101011'     ; 0044 control operator switches, group 4
        retlw   b'11101011'     ; 0045 control operator switches, group 5
        retlw   b'00000000'     ; 0046 control operator switches, group 6
        retlw   b'00000000'     ; 0047 control operator switches, group 7
        retlw   b'00000000'     ; 0048 control operator switches, group 8
        retlw   b'11111111'     ; 0049 control operator switches, group 9
        retlw   h'00'           ; 004a spare
        retlw   h'00'           ; 004b spare
        retlw   h'00'           ; 004c spare
        retlw   h'00'           ; 004d spare
        retlw   h'00'           ; 004e spare
        retlw   h'00'           ; 004f spare

        ;; control operator switches, set 4. A->A,B, B->A,B. both repeat.
        retlw   b'11000001'     ; 0050 control operator switches, group 0
        retlw   b'11000110'     ; 0051 control operator switches, group 1
        retlw   b'11000001'     ; 0052 control operator switches, group 2
        retlw   b'11000110'     ; 0053 control operator switches, group 3
        retlw   b'11101011'     ; 0054 control operator switches, group 4
        retlw   b'11101011'     ; 0055 control operator switches, group 5
        retlw   b'00000000'     ; 0056 control operator switches, group 6
        retlw   b'00000000'     ; 0057 control operator switches, group 7
        retlw   b'00000000'     ; 0058 control operator switches, group 8
        retlw   b'11111111'     ; 0059 control operator switches, group 9
        retlw   h'00'           ; 005a spare
        retlw   h'00'           ; 005b spare
        retlw   h'00'           ; 005c spare
        retlw   h'00'           ; 005d spare
        retlw   h'00'           ; 005e spare
        retlw   h'00'           ; 005f spare

        ;; courtesy tone initial defaults
        ;;  rx1 -> tx1 courtesy tone.
        retlw   h'05'           ; 0060 Courtesy tone 0 00 length seg 1
        retlw   h'8c'           ; 0061 Courtesy tone 0 01 tone seg 1
        retlw   h'05'           ; 0062 Courtesy tone 0 02 length seg 2
        retlw   h'8f'           ; 0063 Courtesy tone 0 03 tone seg 2
        retlw   h'05'           ; 0064 Courtesy tone 0 04 length seg 3
        retlw   h'93'           ; 0065 Courtesy tone 0 05 tone seg 3
        retlw   h'05'           ; 0066 Courtesy tone 0 06 length seg 4
        retlw   h'16'           ; 0067 Courtesy tone 0 07 tone seg 4
        ;; rx1 -> tx2 courtesy tone.
        retlw   h'05'           ; 0068 Courtesy Tone 1 00 length seg 1
        retlw   h'8c'           ; 0069 Courtesy Tone 1 01 tone seg 1
        retlw   h'05'           ; 006a Courtesy Tone 1 02 length seg 2
        retlw   h'8f'           ; 006b Courtesy Tone 1 03 tone seg 2
        retlw   h'05'           ; 006c Courtesy Tone 1 04 length seg 3
        retlw   h'93'           ; 006d Courtesy Tone 1 05 tone seg 3
        retlw   h'05'           ; 006e Courtesy Tone 1 06 length seg 4
        retlw   h'16'           ; 006f Courtesy Tone 1 07 tone seg 4
        ;;  rx2 -> tx1 courtesy tone.
        retlw   h'05'           ; 0070 Courtesy tone 2 00 length seg 1
        retlw   h'96'           ; 0071 Courtesy tone 2 01 tone seg 1
        retlw   h'05'           ; 0072 Courtesy tone 2 02 length seg 2
        retlw   h'93'           ; 0073 Courtesy tone 2 03 tone seg 2
        retlw   h'05'           ; 0074 Courtesy tone 2 04 length seg 3
        retlw   h'8f'           ; 0075 Courtesy tone 2 05 tone seg 3
        retlw   h'05'           ; 0076 Courtesy tone 2 06 length seg 4
        retlw   h'0c'           ; 0077 Courtesy tone 2 07 tone seg 4
        ;;  rx2 -> tx2 courtesy tone.
        retlw   h'05'           ; 0078 Courtesy Tone 3 00 length seg 1
        retlw   h'96'           ; 0079 Courtesy Tone 3 01 tone seg 1
        retlw   h'05'           ; 007a Courtesy Tone 3 02 length seg 2
        retlw   h'93'           ; 007b Courtesy Tone 3 03 tone seg 2
        retlw   h'05'           ; 007c Courtesy Tone 3 04 length seg 3
        retlw   h'8f'           ; 007d Courtesy Tone 3 05 tone seg 3
        retlw   h'05'           ; 007e Courtesy Tone 3 06 length seg 4
        retlw   h'0c'           ; 007f Courtesy Tone 3 07 tone seg 4

        org     1c00            ; keeps the computed gotos reasonable.
; **************
; ** SetTone1 **
; **************
        ;; get a tone 1/2 interval from the table.
        ;; tone 00 is NO tone (off).
        ;; start sending the tone.
SetTone1                        ; get tone bytes from table
        movwf   temp            ; save w
        btfsc   STATUS,Z        ; is result zero?
        goto    StopTon1        ; yes. Stop that infernal beeping.
        call    GetTon1H        ; get hi byte.
        movwf   CCPR1H          ; save hi byte.
        call    GetTon1L        ; get lo byte.
        movwf   CCPR1L          ; save lo byte.
        clrf    TMR1L           ; clear lo byte of timer.
        clrf    TMR1H           ; clear hi byte of timer.
        bsf     T1CON,  TMR1ON  ; turn on timer 1.  Start beeping.
        return                  ; done.

StopTon1                        ; stop the racket!
        bcf     T1CON, TMR1ON   ; turn off timer 1.
        return
        
; **************
; ** GetTon1L **
; **************
        ;; get high byte for compare for tone.
        ;; tone 00 is NO tone (off).
GetTon1L                        ; get tone hi byte from table
        movlw   high TnTbl1L    ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TnTbl1L
        retlw   h'ff'           ; OFF -- 00
        retlw   h'5e'           ; F4  -- 01
        retlw   h'1d'           ; F#4 -- 02
        retlw   h'ee'           ; G4  -- 03
        retlw   h'cf'           ; G#4 -- 04
        retlw   h'c1'           ; A4  -- 05
        retlw   h'c2'           ; A#4 -- 06
        retlw   h'd1'           ; B4  -- 07
        retlw   h'ee'           ; C5  -- 08
        retlw   h'17'           ; C#5 -- 09
        retlw   h'4d'           ; D5  -- 0a
        retlw   h'8d'           ; D#5 -- 0b
        retlw   h'd9'           ; E5  -- 0c
        retlw   h'2f'           ; F5  -- 0d
        retlw   h'8e'           ; F#5 -- 0e
        retlw   h'f7'           ; G5  -- 0f
        retlw   h'67'           ; G#5 -- 10
        retlw   h'e0'           ; A5  -- 11
        retlw   h'61'           ; A#  -- 12
        retlw   h'e8'           ; B5  -- 13
        retlw   h'77'           ; C6  -- 14
        retlw   h'0b'           ; C#6 -- 15
        retlw   h'a6'           ; D6  -- 16
        retlw   h'47'           ; D#6 -- 17
        retlw   h'ec'           ; E6  -- 18
        retlw   h'97'           ; F6  -- 19
        retlw   h'47'           ; F#6 -- 1a
        retlw   h'fb'           ; G6  -- 1b
        retlw   h'b3'           ; G#6 -- 1c
        retlw   h'70'           ; A6  -- 1d
        retlw   h'30'           ; A#6 -- 1e
        retlw   h'f4'           ; B6  -- 1f

; **************
; ** GetTon1H **
; **************
        ;; get high byte for compare for tone.
        ;; tone 00 is NO tone (off).
GetTon1H                        ; get tone hi byte from table
        movlw   high TnTbl1H    ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TnTbl1H
        retlw   h'ff'           ; OFF -- 00
        retlw   h'16'           ; F4  -- 01
        retlw   h'15'           ; F#4 -- 02
        retlw   h'13'           ; G4  -- 03
        retlw   h'12'           ; G#4 -- 04
        retlw   h'11'           ; A4  -- 05
        retlw   h'10'           ; A#4 -- 06
        retlw   h'0f'           ; B4  -- 07
        retlw   h'0e'           ; C5  -- 08
        retlw   h'0e'           ; C#5 -- 09
        retlw   h'0d'           ; D5  -- 0a
        retlw   h'0c'           ; D#5 -- 0b
        retlw   h'0b'           ; E5  -- 0c
        retlw   h'0b'           ; F5  -- 0d
        retlw   h'0a'           ; F#5 -- 0e
        retlw   h'09'           ; G5  -- 0f
        retlw   h'09'           ; G#5 -- 10
        retlw   h'08'           ; A5  -- 11
        retlw   h'08'           ; A#  -- 12
        retlw   h'07'           ; B5  -- 13
        retlw   h'07'           ; C6  -- 14
        retlw   h'07'           ; C#6 -- 15
        retlw   h'06'           ; D6  -- 16
        retlw   h'06'           ; D#6 -- 17
        retlw   h'05'           ; E6  -- 18
        retlw   h'05'           ; F6  -- 19
        retlw   h'05'           ; F#6 -- 1a
        retlw   h'04'           ; G6  -- 1b
        retlw   h'04'           ; G#6 -- 1c
        retlw   h'04'           ; A6  -- 1d
        retlw   h'04'           ; A#6 -- 1e
        retlw   h'03'           ; B6  -- 1f

; **************
; ** SetTone2 **
; **************
        ;; get a tone 1/2 interval from the table.
        ;; tone 00 is NO tone (off).
        ;; start sending the tone.
SetTone2                        ; get tone bytes from table
        movwf   temp            ; save w
        btfsc   STATUS,Z        ; is result zero?
        goto    StopTon2        ; yes. Stop that infernal beeping.
        call    GetTon2H        ; get hi byte.
        movwf   T2CON           ; save hi byte into timer 2 control
        call    GetTon2L        ; get lo byte.
        bsf     STATUS,RP0      ; select bank 1
        movwf   PR2             ; save lo byte.
        bcf     STATUS,RP0      ; select bank 0
        bsf     T2CON, TMR2ON   ; turn on timer 2.  Start beeping.
        return                  ; done.

StopTon2                        ; stop the racket!
        bcf     T2CON, TMR2ON   ; turn off timer 2.
        return
        
; **************
; ** GetTon2L **
; **************
        ;; get high byte for compare for tone.
        ;; tone 00 is NO tone (off).
GetTon2L                        ; get tone hi byte from table
        movlw   high TnTbl2L    ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TnTbl2L
        retlw   h'00'           ; OFF -- 00
        retlw   h'6e'           ; F4  -- 01
        retlw   h'5a'           ; F#4 -- 02
        retlw   h'5b'           ; G4  -- 03
        retlw   h'56'           ; G#4 -- 04
        retlw   h'51'           ; A4  -- 05
        retlw   h'43'           ; A#4 -- 06
        retlw   h'fd'           ; B4  -- 07
        retlw   h'fe'           ; C5  -- 08
        retlw   h'f0'           ; C#5 -- 09
        retlw   h'e3'           ; D5  -- 0a
        retlw   h'f7'           ; D#5 -- 0b
        retlw   h'e9'           ; E5  -- 0c
        retlw   h'dc'           ; F5  -- 0d
        retlw   h'c1'           ; F#5 -- 0e
        retlw   h'aa'           ; G5  -- 0f
        retlw   h'ac'           ; G#5 -- 10
        retlw   h'8e'           ; A5  -- 11
        retlw   h'86'           ; A#  -- 12
        retlw   h'fd'           ; B5  -- 13
        retlw   h'bf'           ; C6  -- 14
        retlw   h'78'           ; C#6 -- 15
        retlw   h'f3'           ; D6  -- 16
        retlw   h'c9'           ; D#6 -- 17
        retlw   h'65'           ; E6  -- 18
        retlw   h'8f'           ; F6  -- 19
        retlw   h'87'           ; F#6 -- 1a
        retlw   h'55'           ; G6  -- 1b
        retlw   h'4b'           ; G#6 -- 1c
        retlw   h'47'           ; A6  -- 1d
        retlw   h'86'           ; A#6 -- 1e
        retlw   h'fd'           ; B6  -- 1f

; **************
; ** GetTon2H **
; **************
        ;; get high byte for compare for tone.
        ;; tone 00 is NO tone (off).
        ;; note that this is a cooked value, already rotated to go into T2CON
GetTon2H                        ; get tone hi byte from table
        movlw   high TnTbl2H    ; set page 
        movwf   PCLATH          ; select page
        movf    temp,w          ; get tone into w
        andlw   h'1f'           ; force into valid range
        addwf   PCL,f           ; add w to PCL
TnTbl2H
        retlw   h'00'           ; OFF -- 00
        retlw   h'61'           ; F4  -- 01
        retlw   h'71'           ; F#4 -- 02
        retlw   h'69'           ; G4  -- 03
        retlw   h'69'           ; G#4 -- 04
        retlw   h'69'           ; A4  -- 05
        retlw   h'79'           ; A#4 -- 06
        retlw   h'78'           ; B4  -- 07
        retlw   h'70'           ; C5  -- 08
        retlw   h'70'           ; C#5 -- 09
        retlw   h'70'           ; D5  -- 0a
        retlw   h'60'           ; D#5 -- 0b
        retlw   h'60'           ; E5  -- 0c
        retlw   h'60'           ; F5  -- 0d
        retlw   h'68'           ; F#5 -- 0e
        retlw   h'70'           ; G5  -- 0f
        retlw   h'68'           ; G#5 -- 10
        retlw   h'78'           ; A5  -- 11
        retlw   h'78'           ; A#  -- 12
        retlw   h'38'           ; B5  -- 13
        retlw   h'48'           ; C6  -- 14
        retlw   h'70'           ; C#6 -- 15
        retlw   h'30'           ; D6  -- 16
        retlw   h'38'           ; D#6 -- 17
        retlw   h'70'           ; E6  -- 18
        retlw   h'48'           ; F6  -- 19
        retlw   h'48'           ; F#6 -- 1a
        retlw   h'70'           ; G6  -- 1b
        retlw   h'78'           ; G#6 -- 1c
        retlw   h'78'           ; A6  -- 1d
        retlw   h'38'           ; A#6 -- 1e
        retlw   h'18'           ; B6  -- 1f

        ;; jammed some small routines in here to use this space.

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

        org     1d00        
InitD2
        movwf   temp            ; save addr.
        bcf     temp,7          ; subtract 128
        movlw   high InitTb2    ; set page
        movwf   PCLATH          ; select page
        movf    temp,w          ; get address back
        addwf   PCL,f           ; add w to PCL
InitTb2
        ;; more initial defaults
        ;; Spare Courtesy Tone
        retlw   MAGICCT         ; 0080 Courtesy tone 4 00 length seg 1
        retlw   h'01'           ; 0081 Courtesy tone 4 01 tone seg 1
        retlw   h'00'           ; 0082 Courtesy tone 4 02 length seg 2
        retlw   h'00'           ; 0083 Courtesy tone 4 03 tone seg 2
        retlw   h'00'           ; 0084 Courtesy tone 4 04 length seg 3
        retlw   h'00'           ; 0085 Courtesy tone 4 05 tone seg 3
        retlw   h'00'           ; 0086 Courtesy tone 4 06 length seg 4
        retlw   h'00'           ; 0087 Courtesy tone 4 07 tone seg 4
        ;; Spare Courtesy Tone
        retlw   MAGICCT         ; 0088 Courtesy Tone 5 00 length seg 1
        retlw   h'02'           ; 0089 Courtesy Tone 5 01 tone seg 1
        retlw   h'00'           ; 008a Courtesy Tone 5 02 length seg 2
        retlw   h'00'           ; 008b Courtesy Tone 5 03 tone seg 2
        retlw   h'00'           ; 008c Courtesy Tone 5 04 length seg 3
        retlw   h'00'           ; 008d Courtesy Tone 5 05 tone seg 3
        retlw   h'00'           ; 008e Courtesy Tone 5 06 length seg 4
        retlw   h'00'           ; 008f Courtesy Tone 5 07 tone seg 4
        ;; spare Courtesy Tone
        retlw   MAGICCT         ; 0090 Courtesy tone 6 00 length seg 1
        retlw   h'03'           ; 0091 Courtesy tone 6 01 tone seg 1
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
        
        ;; cw id 1 initial defaults
        retlw   h'05'           ; 00a0 CW ID  1 'N'
        retlw   h'10'           ; 00a1 CW ID  2 'H'
        retlw   h'0a'           ; 00a2 CW ID  3 'R'
        retlw   h'15'           ; 00a3 CW ID  4 'C'
        retlw   h'00'           ; 00a4 CW ID  5 ' '
        retlw   h'3e'           ; 00a5 CW ID  6 '1'
        retlw   h'23'           ; 00a5 CW ID  7 '7'
        retlw   h'ff'           ; 00a7 CW ID  8 eom
        retlw   h'ff'           ; 00a8 CW ID  9 eom
        retlw   h'ff'           ; 00a9 CW ID 10 eom
        retlw   h'ff'           ; 00aa CW ID 11 eom
        retlw   h'ff'           ; 00ab CW ID 12 eom
        retlw   h'ff'           ; 00ac CW ID 13 eom
        retlw   h'ff'           ; 00ad CW ID 14 eom
        retlw   h'ff'           ; 00ae CW ID 15 eom
        retlw   h'ff'           ; 00af CW ID 16 eom
        
        ;; cw id 21 initial defaults
        retlw   h'05'           ; 00b0 CW ID  1 'N'
        retlw   h'10'           ; 00b1 CW ID  2 'H'
        retlw   h'0a'           ; 00b2 CW ID  3 'R'
        retlw   h'15'           ; 00b3 CW ID  4 'C'
        retlw   h'00'           ; 00b4 CW ID  5 ' '
        retlw   h'3e'           ; 00b5 CW ID  6 '1'
        retlw   h'23'           ; 00b5 CW ID  7 '7'
        retlw   h'ff'           ; 00b7 CW ID  8 eom
        retlw   h'ff'           ; 00b8 CW ID  9 eom
        retlw   h'ff'           ; 00b9 CW ID 10 eom
        retlw   h'ff'           ; 00ba CW ID 11 eom
        retlw   h'ff'           ; 00bb CW ID 12 eom
        retlw   h'ff'           ; 00bc CW ID 13 eom
        retlw   h'ff'           ; 00bd CW ID 14 eom
        retlw   h'ff'           ; 00be CW ID 15 eom
        retlw   h'ff'           ; 00bf CW ID 16 eom
        
        ;; control prefixes
        retlw   h'00'           ; 00c0 control prefix 0  00
        retlw   h'00'           ; 00c1 control prefix 0  01
        retlw   h'ff'           ; 00c2 control prefix 0  02
        retlw   h'ff'           ; 00c3 control prefix 0  03
        retlw   h'ff'           ; 00c4 control prefix 0  04
        retlw   h'ff'           ; 00c5 control prefix 0  05
        retlw   h'ff'           ; 00c6 control prefix 0  06
        retlw   h'ff'           ; 00c7 control prefix 0  07
        retlw   h'00'           ; 00c8 control prefix 1  00
        retlw   h'01'           ; 00c9 control prefix 1  01
        retlw   h'ff'           ; 00ca control prefix 1  02
        retlw   h'ff'           ; 00cb control prefix 1  03
        retlw   h'ff'           ; 00cc control prefix 1  04
        retlw   h'ff'           ; 00cd control prefix 1  05
        retlw   h'ff'           ; 00ce control prefix 1  06
        retlw   h'ff'           ; 00cf control prefix 1  07
        retlw   h'00'           ; 00d0 control prefix 2  00
        retlw   h'02'           ; 00d1 control prefix 2  01
        retlw   h'ff'           ; 00d2 control prefix 2  02
        retlw   h'ff'           ; 00d3 control prefix 2  03
        retlw   h'ff'           ; 00d4 control prefix 2  04
        retlw   h'ff'           ; 00d5 control prefix 2  05
        retlw   h'ff'           ; 00d6 control prefix 2  06
        retlw   h'ff'           ; 00d7 control prefix 2  07
        retlw   h'00'           ; 00d8 control prefix 3  00
        retlw   h'03'           ; 00d9 control prefix 3  01
        retlw   h'ff'           ; 00da control prefix 3  02
        retlw   h'ff'           ; 00db control prefix 3  03
        retlw   h'ff'           ; 00dc control prefix 3  04
        retlw   h'ff'           ; 00dd control prefix 3  05
        retlw   h'ff'           ; 00de control prefix 3  06
        retlw   h'ff'           ; 00df control prefix 3  07
        retlw   h'00'           ; 00e0 control prefix 4  00
        retlw   h'04'           ; 00e1 control prefix 4  01
        retlw   h'ff'           ; 00e2 control prefix 4  02
        retlw   h'ff'           ; 00e3 control prefix 4  03
        retlw   h'ff'           ; 00e4 control prefix 4  04
        retlw   h'ff'           ; 00e5 control prefix 4  05
        retlw   h'ff'           ; 00e6 control prefix 4  06
        retlw   h'ff'           ; 00e7 control prefix 4  07
        retlw   h'00'           ; 00e8 control prefix 5  00
        retlw   h'05'           ; 00e9 control prefix 5  01
        retlw   h'ff'           ; 00ea control prefix 5  02
        retlw   h'ff'           ; 00eb control prefix 5  03
        retlw   h'ff'           ; 00ec control prefix 5  04
        retlw   h'ff'           ; 00ed control prefix 5  05
        retlw   h'ff'           ; 00ee control prefix 5  06
        retlw   h'ff'           ; 00ef control prefix 5  07
        retlw   h'00'           ; 00f0 control prefix 6  00
        retlw   h'06'           ; 00f1 control prefix 6  01
        retlw   h'ff'           ; 00f2 control prefix 6  02
        retlw   h'ff'           ; 00f3 control prefix 6  03
        retlw   h'ff'           ; 00f4 control prefix 6  04
        retlw   h'ff'           ; 00f5 control prefix 6  05
        retlw   h'ff'           ; 00f6 control prefix 6  06
        retlw   h'ff'           ; 00f7 control prefix 6  07
        retlw   h'00'           ; 00f8 control prefix 7  00
        retlw   h'07'           ; 00f9 control prefix 7  01
        retlw   h'ff'           ; 00fa control prefix 7  02
        retlw   h'ff'           ; 00fb control prefix 7  03
        retlw   h'ff'           ; 00fc control prefix 7  04
        retlw   h'ff'           ; 00fd control prefix 7  05
        retlw   h'ff'           ; 00fe control prefix 7  06
        retlw   h'ff'           ; 00ff control prefix 7  07

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

; **************
; ** CWParms  **
; **************
CWParms                         ; set CW parameters from timers.
        movlw   EETCWP1         ; get EEPROM address of cw pitch preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        movwf   cw1tone         ; save CW tone.
        
        movlw   EETCWS1         ; get EEPROM address of cw speed preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        call    GetCWD          ; get the CW delay for the indicated speed.
        movwf   cw1spd          ; save CW speed.

        movlw   EETCWP2         ; get EEPROM address of cw pitch preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        movwf   cw2tone         ; save CW tone.
        
        movlw   EETCWS2         ; get EEPROM address of cw speed preset.
        movwf   eeAddr          ; set EEPROM address low byte.
        call    ReadEEw         ; read EEPROM.
        call    GetCWD          ; get the CW delay for the indicated speed.
        movwf   cw2spd          ; save CW speed.
        
        return                  ; done here.

        org     1e00        

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
        retlw   h'0f'           ; 'O'     -- 00
        retlw   h'0d'           ; 'K'     -- 01
        retlw   h'ff'           ; EOM     -- 02
        retlw   h'02'           ; 'E'     -- 03
        retlw   h'0a'           ; 'R'     -- 04
        retlw   h'0a'           ; 'R'     -- 05
        retlw   h'ff'           ; EOM     -- 06
        retlw   h'03'           ; 'T'     -- 07
        retlw   h'0f'           ; '0'     -- 08
        retlw   h'3e'           ; '1'     -- 09
        retlw   h'ff'           ; EOM     -- 0a
        retlw   h'03'           ; 'T'     -- 0b
        retlw   h'0f'           ; '0'     -- 0c
        retlw   h'3c'           ; '2'     -- 0d 
        retlw   h'ff'           ; EOM     -- 0e
        retlw   h'0f'           ; 'O'     -- 0f
        retlw   h'05'           ; 'N'     -- 10
        retlw   h'ff'           ; EOM     -- 11
        retlw   h'0f'           ; 'O'     -- 12
        retlw   h'14'           ; 'F'     -- 13
        retlw   h'14'           ; 'F'     -- 14
        retlw   h'ff'           ; EOM     -- 15
        retlw   h'05'           ; 'N'     -- 16
        retlw   h'10'           ; 'H'     -- 17
        retlw   h'0a'           ; 'R'     -- 18
        retlw   h'15'           ; 'C'     -- 19
        retlw   h'00'           ; ' '     -- 1a
        retlw   h'3e'           ; '1'     -- 1b
        retlw   h'23'           ; '7'     -- 1c 
        retlw   h'00'           ; ' '     -- 1d  search for MORSE to find codes
        retlw   h'18'           ; 'v'     -- 1e  VERSION DATA
        retlw   h'3f'           ; '0'     -- 1f  VERSION DATA
        retlw   h'6a'           ; '.'     -- 20  VERSION DATA
        retlw   h'3f'           ; '0'     -- 21  VERSION DATA
        retlw   h'20'           ; '5'     -- 22  VERSION DATA
        retlw   h'ff'           ; EOM     -- 23
        retlw   d'05'           ; 24 alarm tone
        retlw   h'b0'           ; 25
        retlw   d'05'           ; 26
        retlw   h'bb'           ; 27
        retlw   d'05'           ; 28
        retlw   h'b0'           ; 29
        retlw   d'05'           ; 2a
        retlw   h'bb'           ; 2b
        retlw   d'05'           ; 2c
        retlw   h'b0'           ; 2d
        retlw   d'05'           ; 2e
        retlw   h'bb'           ; 2f
        retlw   d'05'           ; 30
        retlw   h'b0'           ; 31
        retlw   d'05'           ; 32
        retlw   h'bb'           ; 33
        retlw   d'05'           ; 34
        retlw   h'b0'           ; 35
        retlw   d'05'           ; 36
        retlw   h'bb'           ; 37
        retlw   d'05'           ; 38
        retlw   h'b0'           ; 39
        retlw   d'05'           ; 3a
        retlw   h'3b'           ; 3b
        retlw   h'00'           ; 3c reserved
        retlw   h'00'           ; 3d reserved
        retlw   h'00'           ; 3e reserved
        retlw   h'00'           ; 3f reserved

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

        org     1f00        

        FILL 0x3ff,0x0100       ; reserve this block for the ICD.
        
        IF LOAD_EE == 1 
        org     2100h

        de      d'100'          ; 0000 long hang timer.
        de      d'50'           ; 0001 short hang timer
        de      d'54'           ; 0002 ID timer, transmitter 1
        de      d'54'           ; 0003 ID timer, transmitter 2
        de      d'60'           ; 0004 DTMF access timer
        de      d'180'          ; 0005 long timeout timer
        de      d'30'           ; 0006 short timeout timer
        de      d'12'           ; 0007 fan timer
        de      d'6'            ; 0008 alarm timer
        de      d'50'           ; 0009 tx1 ct front porch delay
        de      d'50'           ; 000a tx2 ct front porch delay
        de      d'20'           ; 000b cw pitch tx1
        de      d'20'           ; 000c cw speed tx1
        de      d'20'           ; 000d cw pitch tx2
        de      d'20'           ; 000e cw speed tx2
        de      d'0'            ; 000f spare

        ;; control operator switches, set 0. A->B, B->A. both simplex.
        de      b'10000001'     ; 0010 control operator switches, group 0
        de      b'11000110'     ; 0011 control operator switches, group 1
        de      b'01000001'     ; 0012 control operator switches, group 2
        de      b'11000110'     ; 0013 control operator switches, group 3
        de      b'00001001'     ; 0014 control operator switches, group 4
        de      b'00001001'     ; 0015 control operator switches, group 5
        de      b'00000000'     ; 0016 control operator switches, group 6
        de      b'00000000'     ; 0017 control operator switches, group 7
        de      b'00000000'     ; 0018 control operator switches, group 8
        de      b'11111111'     ; 0019 control operator switches, group 9
        de      h'00'           ; 001a spare
        de      h'00'           ; 001b spare
        de      h'00'           ; 001c spare
        de      h'00'           ; 001d spare
        de      h'00'           ; 001e spare
        de      h'00'           ; 001f spare

        ;; control operator switches, set 1. A->B, B->A. both simplex
        de      b'10000001'     ; 0020 control operator switches, group 0
        de      b'11000110'     ; 0021 control operator switches, group 1
        de      b'01000001'     ; 0022 control operator switches, group 2
        de      b'11000110'     ; 0023 control operator switches, group 3
        de      b'00001001'     ; 0024 control operator switches, group 4
        de      b'00001001'     ; 0025 control operator switches, group 5
        de      b'00000000'     ; 0026 control operator switches, group 6
        de      b'00000000'     ; 0027 control operator switches, group 7
        de      b'00000000'     ; 0028 control operator switches, group 8
        de      b'11111111'     ; 0029 control operator switches, group 9
        de      h'00'           ; 002a spare
        de      h'00'           ; 002b spare
        de      h'00'           ; 002c spare
        de      h'00'           ; 002d spare
        de      h'00'           ; 002e spare
        de      h'00'           ; 002f spare

        ;; control operator switches, set 2. A->A,B, B->A. A repeat, B remote
        de      b'11000001'     ; 0030 control operator switches, group 0
        de      b'11000110'     ; 0031 control operator switches, group 1
        de      b'01000001'     ; 0032 control operator switches, group 2
        de      b'11000110'     ; 0033 control operator switches, group 3
        de      b'11101011'     ; 0034 control operator switches, group 4
        de      b'11001001'     ; 0035 control operator switches, group 5
        de      b'00000000'     ; 0036 control operator switches, group 6
        de      b'00000000'     ; 0037 control operator switches, group 7
        de      b'00000000'     ; 0038 control operator switches, group 8
        de      b'11111111'     ; 0039 control operator switches, group 9
        de      h'00'           ; 003a spare
        de      h'00'           ; 003b spare
        de      h'00'           ; 003c spare
        de      h'00'           ; 003d spare
        de      h'00'           ; 003e spare
        de      h'00'           ; 003f spare

        ;; control operator switches, set 3. A->A, B->B. both repeat.
        de      b'01000001'     ; 0040 control operator switches, group 0
        de      b'11000110'     ; 0041 control operator switches, group 1
        de      b'10000001'     ; 0042 control operator switches, group 2
        de      b'11000110'     ; 0043 control operator switches, group 3
        de      b'11101011'     ; 0044 control operator switches, group 4
        de      b'11101011'     ; 0045 control operator switches, group 5
        de      b'00000000'     ; 0046 control operator switches, group 6
        de      b'00000000'     ; 0047 control operator switches, group 7
        de      b'00000000'     ; 0048 control operator switches, group 8
        de      b'11111111'     ; 0049 control operator switches, group 9
        de      h'00'           ; 004a spare
        de      h'00'           ; 004b spare
        de      h'00'           ; 004c spare
        de      h'00'           ; 004d spare
        de      h'00'           ; 004e spare
        de      h'00'           ; 004f spare

        ;; control operator switches, set 4. A->A,B, B->A,B.  Both Repeat
        de      b'11000001'     ; 0050 control operator switches, group 0
        de      b'11000110'     ; 0051 control operator switches, group 1
        de      b'11000001'     ; 0052 control operator switches, group 2
        de      b'11000110'     ; 0053 control operator switches, group 3
        de      b'11101011'     ; 0054 control operator switches, group 4
        de      b'11101011'     ; 0055 control operator switches, group 5
        de      b'00000000'     ; 0056 control operator switches, group 6
        de      b'00000000'     ; 0057 control operator switches, group 7
        de      b'00000000'     ; 0058 control operator switches, group 8
        de      b'11111111'     ; 0059 control operator switches, group 9
        de      h'00'           ; 005a spare
        de      h'00'           ; 005b spare
        de      h'00'           ; 005c spare
        de      h'00'           ; 005d spare
        de      h'00'           ; 005e spare
        de      h'00'           ; 005f spare

        ;; courtesy tone initial defaults
        ;;  rx1 -> tx1 courtesy tone.
        de      h'05'           ; 0060 Courtesy tone 0 00 length seg 1
        de      h'8c'           ; 0061 Courtesy tone 0 01 tone seg 1
        de      h'05'           ; 0062 Courtesy tone 0 02 length seg 2
        de      h'8f'           ; 0063 Courtesy tone 0 03 tone seg 2
        de      h'05'           ; 0064 Courtesy tone 0 04 length seg 3
        de      h'93'           ; 0065 Courtesy tone 0 05 tone seg 3
        de      h'05'           ; 0066 Courtesy tone 0 06 length seg 4
        de      h'16'           ; 0067 Courtesy tone 0 07 tone seg 4
        ;;  rx1 -> tx2 courtesy tone.
        de      h'05'           ; 0068 Courtesy Tone 1 00 length seg 1
        de      h'8c'           ; 0069 Courtesy Tone 1 01 tone seg 1
        de      h'05'           ; 006a Courtesy Tone 1 02 length seg 2
        de      h'8f'           ; 006b Courtesy Tone 1 03 tone seg 2
        de      h'05'           ; 006c Courtesy Tone 1 04 length seg 3
        de      h'93'           ; 006d Courtesy Tone 1 05 tone seg 3
        de      h'05'           ; 006e Courtesy Tone 1 06 length seg 4
        de      h'16'           ; 006f Courtesy Tone 1 07 tone seg 4
        ;;  rx2 -> tx1 courtesy tone.
        de      h'05'           ; 0070 Courtesy tone 2 00 length seg 1
        de      h'96'           ; 0071 Courtesy tone 2 01 tone seg 1
        de      h'05'           ; 0072 Courtesy tone 2 02 length seg 2
        de      h'93'           ; 0073 Courtesy tone 2 03 tone seg 2
        de      h'05'           ; 0074 Courtesy tone 2 04 length seg 3
        de      h'8f'           ; 0075 Courtesy tone 2 05 tone seg 3
        de      h'05'           ; 0076 Courtesy tone 2 06 length seg 4
        de      h'0c'           ; 0077 Courtesy tone 2 07 tone seg 4
        ;;  rx2 -> tx2 courtesy tone.
        de      h'05'           ; 0078 Courtesy Tone 3 00 length seg 1
        de      h'96'           ; 0079 Courtesy Tone 3 01 tone seg 1
        de      h'05'           ; 007a Courtesy Tone 3 02 length seg 2
        de      h'93'           ; 007b Courtesy Tone 3 03 tone seg 2
        de      h'05'           ; 007c Courtesy Tone 3 04 length seg 3
        de      h'8f'           ; 007d Courtesy Tone 3 05 tone seg 3
        de      h'05'           ; 007e Courtesy Tone 3 06 length seg 4
        de      h'0c'           ; 007f Courtesy Tone 3 07 tone seg 4
        ;; Courtesy Tone 4
        de      MAGICCT         ; 0080 Courtesy tone 4 00 length seg 1
        de      h'01'           ; 0081 Courtesy tone 4 01 tone seg 1
        de      h'00'           ; 0082 Courtesy tone 4 02 length seg 2
        de      h'00'           ; 0083 Courtesy tone 4 03 tone seg 2
        de      h'00'           ; 0084 Courtesy tone 4 04 length seg 3
        de      h'00'           ; 0085 Courtesy tone 4 05 tone seg 3
        de      h'00'           ; 0086 Courtesy tone 4 06 length seg 4
        de      h'00'           ; 0087 Courtesy tone 4 07 tone seg 4
        ;; Courtesy Tone 5
        de      MAGICCT         ; 0088 Courtesy Tone 5 00 length seg 1
        de      h'02'           ; 0089 Courtesy Tone 5 01 tone seg 1
        de      h'00'           ; 008a Courtesy Tone 5 02 length seg 2
        de      h'00'           ; 008b Courtesy Tone 5 03 tone seg 2
        de      h'00'           ; 008c Courtesy Tone 5 04 length seg 3
        de      h'00'           ; 008d Courtesy Tone 5 05 tone seg 3
        de      h'00'           ; 008e Courtesy Tone 5 06 length seg 4
        de      h'00'           ; 008f Courtesy Tone 5 07 tone seg 4
        ;; Courtesy Tone 6
        de      MAGICCT         ; 0090 Courtesy tone 6 00 length seg 1
        de      h'03'           ; 0091 Courtesy tone 6 01 tone seg 1
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
        
        ;; cw id 1 initial defaults
        de      h'05'           ; 00a0 CW ID  1 'N'
        de      h'10'           ; 00a1 CW ID  2 'H'
        de      h'0a'           ; 00a2 CW ID  3 'R'
        de      h'15'           ; 00a3 CW ID  4 'C'
        de      h'00'           ; 00a4 CW ID  5 ' '
        de      h'3e'           ; 00a5 CW ID  6 '1'
        de      h'23'           ; 00a6 CW ID  7 '7'
        de      h'ff'           ; 00a7 CW ID  8 eom
        de      h'ff'           ; 00a8 CW ID  9 eom
        de      h'ff'           ; 00a9 CW ID 10 eom
        de      h'ff'           ; 00aa CW ID 11 eom
        de      h'ff'           ; 00ab CW ID 12 eom
        de      h'ff'           ; 00ac CW ID 13 eom
        de      h'ff'           ; 00ad CW ID 14 eom
        de      h'ff'           ; 00ae CW ID 15 eom
        de      h'ff'           ; 00af CW ID 16 eom
        
        ;; cw id 2 initial defaults
        de      h'05'           ; 00b0 CW ID  1 'N'
        de      h'10'           ; 00b1 CW ID  2 'H'
        de      h'0a'           ; 00b2 CW ID  3 'R'
        de      h'15'           ; 00b3 CW ID  4 'C'
        de      h'00'           ; 00b4 CW ID  5 ' '
        de      h'3e'           ; 00b4 CW ID  6 '1'
        de      h'23'           ; 00b5 CW ID  7 '7'
        de      h'ff'           ; 00b6 CW ID  8 eom
        de      h'ff'           ; 00b8 CW ID  9 eom
        de      h'ff'           ; 00b9 CW ID 10 eom
        de      h'ff'           ; 00ba CW ID 11 eom
        de      h'ff'           ; 00bb CW ID 12 eom
        de      h'ff'           ; 00bc CW ID 13 eom
        de      h'ff'           ; 00bd CW ID 14 eom
        de      h'ff'           ; 00be CW ID 15 eom
        de      h'ff'           ; 00bf CW ID 16 eom
        
        ;; control prefixes
        de      h'00'           ; 00c0 control prefix 0  00
        de      h'00'           ; 00c1 control prefix 0  01
        de      h'ff'           ; 00c2 control prefix 0  02
        de      h'ff'           ; 00c3 control prefix 0  03
        de      h'ff'           ; 00c4 control prefix 0  04
        de      h'ff'           ; 00c5 control prefix 0  05
        de      h'ff'           ; 00c6 control prefix 0  06
        de      h'ff'           ; 00c7 control prefix 0  07
        de      h'00'           ; 00c8 control prefix 1  00
        de      h'01'           ; 00c9 control prefix 1  01
        de      h'ff'           ; 00ca control prefix 1  02
        de      h'ff'           ; 00cb control prefix 1  03
        de      h'ff'           ; 00cc control prefix 1  04
        de      h'ff'           ; 00cd control prefix 1  05
        de      h'ff'           ; 00ce control prefix 1  06
        de      h'ff'           ; 00cf control prefix 1  07
        de      h'00'           ; 00d0 control prefix 2  00
        de      h'02'           ; 00d1 control prefix 2  01
        de      h'ff'           ; 00d2 control prefix 2  02
        de      h'ff'           ; 00d3 control prefix 2  03
        de      h'ff'           ; 00d4 control prefix 2  04
        de      h'ff'           ; 00d5 control prefix 2  05
        de      h'ff'           ; 00d6 control prefix 2  06
        de      h'ff'           ; 00d7 control prefix 2  07
        de      h'00'           ; 00d8 control prefix 3  00
        de      h'03'           ; 00d9 control prefix 3  01
        de      h'ff'           ; 00da control prefix 3  02
        de      h'ff'           ; 00db control prefix 3  03
        de      h'ff'           ; 00dc control prefix 3  04
        de      h'ff'           ; 00dd control prefix 3  05
        de      h'ff'           ; 00de control prefix 3  06
        de      h'ff'           ; 00df control prefix 3  07
        de      h'00'           ; 00e0 control prefix 4  00
        de      h'04'           ; 00e1 control prefix 4  01
        de      h'ff'           ; 00e2 control prefix 4  02
        de      h'ff'           ; 00e3 control prefix 4  03
        de      h'ff'           ; 00e4 control prefix 4  04
        de      h'ff'           ; 00e5 control prefix 4  05
        de      h'ff'           ; 00e6 control prefix 4  06
        de      h'ff'           ; 00e7 control prefix 4  07
        de      h'00'           ; 00e8 control prefix 5  00
        de      h'05'           ; 00e9 control prefix 5  01
        de      h'ff'           ; 00ea control prefix 5  02
        de      h'ff'           ; 00eb control prefix 5  03
        de      h'ff'           ; 00ec control prefix 5  04
        de      h'ff'           ; 00ed control prefix 5  05
        de      h'ff'           ; 00ee control prefix 5  06
        de      h'ff'           ; 00ef control prefix 5  07
        de      h'00'           ; 00f0 control prefix 6  00
        de      h'06'           ; 00f1 control prefix 6  01
        de      h'ff'           ; 00f2 control prefix 6  02
        de      h'ff'           ; 00f3 control prefix 6  03
        de      h'ff'           ; 00f4 control prefix 6  04
        de      h'ff'           ; 00f5 control prefix 6  05
        de      h'ff'           ; 00f6 control prefix 6  06
        de      h'ff'           ; 00f7 control prefix 6  07
        de      h'00'           ; 00f8 control prefix 7  00
        de      h'07'           ; 00f9 control prefix 7  01
        de      h'ff'           ; 00fa control prefix 7  02
        de      h'ff'           ; 00fb control prefix 7  03
        de      h'ff'           ; 00fc control prefix 7  04
        de      h'ff'           ; 00fd control prefix 7  05
        de      h'ff'           ; 00fe control prefix 7  06
        de      h'ff'           ; 00ff control prefix 7  07
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
; m --      00000111  07                 ; ar .-.-.  00101010  2a
; n -.      00000101  05                 ; bt -...-  00110001  31
; o ---     00001111  0f                 ; / -..-.   00101001  29
; p .--.    00010110  16                                         
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
