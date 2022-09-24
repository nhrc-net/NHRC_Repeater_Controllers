	;; NHRC-5 Repeater Controller.
	;; Copyright 2000, 2001, 2009 NHRC LLC,
	;; as an unpublished proprietary work.
	;; All rights reserved.
	;; No part of this document may be used or reproduced by any means,
	;; for any purpose, without the expressed written consent of NHRC LLC.

	;; 5-104 05 February 2009 -- 6 years since the last change.
	;; 5-105 25 December 2009 -- make COR debounce much faster.

VER_INT	equ	d'1'
VER_HI	equ	d'0'
VER_LO	equ	d'5'

LOAD_EE=1

COLORBURST=1
;;DEBUG=1				; 
        ERRORLEVEL 0, -302,-306 ; suppress Argument out of range errors

        IFDEF __16F877
	include "p16f877.inc"
	ENDIF

	IFDEF COLORBURST
        __FUSES _PWRTE_ON & _XT_OSC & _LVP_OFF & _WRT_ENABLE_OFF & _CP_ALL
	ELSE
        __FUSES _PWRTE_ON & _HS_OSC & _LVP_OFF & _WRT_ENABLE_OFF & _CP_ALL
	ENDIF
	
        include "eeprom.inc"

;macro definitions for ROM paging.
	
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

	IFDEF DEBUG
TEN	equ	D'4'		; decade counter.
	ELSE
TEN	equ	D'10'		; decade counter.
	ENDIF
	
	;; constants for various ISD timers
ISD_DLY	equ	d'2'		; ISD start delay (200 ms).

; *************************
; ** IO Port Assignments **
; *************************

; PORTA
DTMFQ1	equ	0		; input, DTMF decoder Q1
DTMFQ2	equ	1		; input, DTMF decoder Q2
DTMFQ3	equ	2		; input, DTMF decoder Q3
DTMFQ4	equ	3		; input, DTMF decoder Q4
DTMF0DV	equ	4		; input, DTMF digit valid decoder 0 when high.
DTMF1DV	equ	5		; input, DTMF digit valid decoder 1 when high.

; PORTB
AUXCOR	equ	0		; AUX receiver COR\ input
ALARM	equ	1		; ALARM\ input
CT5SEL	equ	2		; CT5 SEL\ input
CT6SEL	equ	3		; CT6 SEL \ input
EXPAND4	equ	4		; digital output 1
EXPAND5	equ	5		; digital output 2
EXPAND6	equ	6		; digital output 3
EXPAND7	equ	7		; digital output 4

LED1	equ	4		; debug LED.
LED2	equ	5		; debug LED.
LED3	equ	6		; debug LED.
LED4	equ	7		; debug LED.

; PORTC
INIT	equ	0		; input, initialize jumper.
RX0AUD	equ	1		; output, audio mute, muted when low.
BEEP	equ	2		; PWM output, beep tone source.
ISDRUN	equ	3		; output, ISD play when low.
ISDREC	equ	4		; output, ISD record when low.
TX0PTT	equ	5		; output, PTT when high.
RX0COR	equ	6		; input, COR present when low.
RX0PL	equ	7		; input, CTCSS present when low.

; PORTD
FANCTL	equ	0		; output, fan control/digital output.
RX2AUD	equ	1		; output, mute aux audio when low.
TX1PTT	equ	2		; output, link tx when hi.
RX1AUD	equ	3		; output, mute link audio when low.
RX1COR	equ	4		; input, link COR present when low.
RX1PL	equ	5		; input, link CTCSS present when low.
DTMF0OE	equ	6		; output, DTMF 0 output enable.
DTMF1OE	equ	7		; output, DTMF 0 output enable.
	
; PORTE
ISDA0   equ     0               ; output, ISD message address line 0.
ISDA1   equ     1               ; output, ISD message address line 1.
ISDA2   equ     2               ; output, ISD message address line 2.
	
; *******************
; ** Control Flags **
; *******************
	
;tFlags				; timer flags        
TICK	equ	0		; TICK indicator
ONEMS	equ     1		; 1 ms tick flag
TENMS	equ     2		; 10 ms tick flag
HUNDMS	equ     3		; 100 ms tick flag
ONESEC	equ     4		; 1 second tick flag
TENSEC	equ	5		; 10 second flag...
; niy   equ     6               ; NIY
CWBEEP  equ     7               ; cw beep is on.
        
;flags
initID  equ     0		; need to ID now
needID  equ     1		; need to send ID
IDNOW	equ	2		; ID is running now.
TXONFLG	equ     3		; last TX state flag
CMD_NIB equ     4		; command interpreter nibble flag for copy
DEF_CT  equ	5		; deferred courtesy tone.
RBMUTE	equ     6               ; remote base muted
IDTOGL	equ     7		; ID toggle flag, selects alternately ID 1 & 2

;mscFlag 			; misc flags...
DT0ZERO	equ	0		; dtmf-0 last received 0
DT1ZERO	equ	1		; dtmf-1 last received 0
;; NIY	equ	2		; 
;; NIY	equ	3		; 
LASTDV0	equ	4		; last DTMF digit valid, dtmf-0
LASTDV1	equ	5		; last DTMF digit valid, dtmf-1
CTCSS0	equ	6		; last CTCSS on main receiver
CTCSS2	equ	7		; last CTCSS on link receiver

; txFlag
RX0OPEN equ     0               ; main receiver repeating
RX1OPEN	equ	1		; link receiver repeating
;;NIY	equ     2               ; 
TXHANG  equ     3               ; hang time
AUXIN	equ	4		; the Auxiliary input is turned on.
TALKING equ     5               ; ISD playing back
BEEPING equ     6               ; beep tone active
CWPLAY  equ     7               ; CW playing


CWTBDLY	equ	d'60'		; CW timebase delay for 20 WPM.

; isdFlag
ISDRUNF	equ	0		; isd running flag
ISDRECF	equ	1		; isd recording flag.
ISDRECR	equ	2		; isd record flag. record next keyup.
ISDTEST	equ	7		; audio test...
	
;; COR debounce time
COR1DEB equ     5               ; 5 ms.  COR off to on debounce time
COR0DEB equ     5               ; 5 ms.  COR on to off debounce time
DLY1DEB equ     d'100'          ; 100 ms. COR off->on debounce time, with DAD.
DLY0DEB equ     d'50'           ; 50 ms.  COR on->off debounce time, with DAD.
CHNKDEB	equ	d'250'		; 250 ms.
IDSOON  equ     D'6'		; ID soon, polite IDer threshold, 60 sec
MUTEDLY equ     D'20'		; DTMF muting timer = 2.0 sec.
DTMFDLY	equ	d'50'		; DTMF activity timer = 5.0 sec.
UNLKDLY	equ	d'120'		; unlocked mode timer.
	
; dtRFlag -- dtmf sequence received indicator
DT0RDY  equ     0               ; some sequence received on DTMF-0
DT1RDY  equ     1               ; some sequence received on DTMF-1
;NIY	equ     2               ; 
DTUL	equ	3		; command received from unlocked port.
DTSEVAL	equ	4		; dtmf command evaluation in progress.
DT0UNLK equ     5               ; unlocked indicator
DT1UNLK equ     6               ; unlocked indicator
;NIY	equ	7		; 
		;; 
;dtEFlag -- DTMF command evaluator control flag.
	;; low order 5 bits indicate next prefix number/user command to scan
DT0CMD	equ	5		; received this command from dtmf0
DT1CMD	equ	6		; received this command from dtmf1
;NIY	equ	7		;


; beepCtl -- beeper control flags...
B_ADR0  equ     0               ; beep or CW addressing mode indicator
B_ADR1  equ     1               ; beep or CW addressing mode indicator
				;   00 EEPROM
				;   01 lookup table index, built in messages.
				;   10 from RAM
				;   11 CW single letter mode
				; 
B_BEEP  equ     2               ; beep sequence in progress
B_CW    equ     3               ; CW transmission in progress
;	equ	4		;
;	equ	5		;
B_LAST  equ     6		; last segment of CT tones.
;	equ	7		;

; beepCtl preset masks
BEEP_CT equ     b'10000100'     ; CT from EEPROM
BEEP_CX equ     b'10000101'     ; CT from ROM table
CW_ROM  equ     b'10001001'     ; CW from ROM table
CW_EE   equ     b'10001000'     ; CW from EEPROM
CW_LETR	equ	b'10001011'	; CW ONE LETTER ONLY.

CTPAUSE equ     d'5'            ; 50 msec pause before CT.

MAGICCT	equ	d'99'		; magic CT length.  next digit is CW digit.
PULS_TM	equ	d'50'		; 50 x 10 ms = 500 ms.  pulse duration time.

	
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
CTSEL5	equ	5		; EXP3 controlled courtesy tone
CTSEL6	equ	6		; EXP4 controlled courtesy tone
CTUNLOK	equ	7		; unlocked courtesy tone

; Voice message numbers. 
VINITID	equ	0		; initial ID.
VID1   	equ	1		; normal ID 1.
VID2	equ	2		; normal ID 2.
VTIMOUT	equ	3		; timeout message.
VTAIL	equ	4		; tail message.
VCTONE	equ	4		; courtesy tone message.
VLINKOF equ	5		; link off message.
VLINKON	equ	6		; link transmit mode.
VTEST	equ	7		; audio test


; CW Message Addressing Scheme:
; These symbols represent the value of the CW characters in the ROM table.
;     1 - CW timeout message, "to"
;     2 - CW confirm message, "ok"
;     3 - CW bad message, "ng"
;     3 - CW link timeout "rb to"

CW_OK   equ     h'00'		; CW: OK
CW_NG   equ     h'03'		; CW: NG
CW_TO   equ     h'07'		; CW: TO
CWNHRC5	equ	h'0a'		; CW: NHRC 5 message.
CW_ON	equ	h'11'		; CW: ON
CW_OFF	equ	h'14'		; CW: OFF
BP_ALM	equ	h'18'		; beep:	alarm tone
	
;
; CW sender constants
;

CWDIT   equ     1               ; dit length in 100 ms
CWDAH   equ     CWDIT * 3       ; dah 
CWIESP  equ     CWDIT           ; inter-element space
CWILSP  equ     CWDAH           ; inter-letter space
CWIWSP  equ     CWDIT * 7       ; inter-word space

	IFDEF COLORBURST
T0PRE	equ	D'37'		; timer 0 preset for overflow in 224 counts.
	ELSE
T0PRE	equ     D'7'		; timer 0 preset for overflow in 250 counts.
	ENDIF

; Alarm timer values
ALM_DBC	equ	d'4'		; alarm debounce counts.
; chicken burst
CKNBRST	equ	d'20'		; 200 msec chicken burst.
	
; ***************
; ** VARIABLES **
; ***************
        cblock	h'20'           ; 1st block of RAM at 20h-7fh (96 bytes here)
        ;; interrupt pseudo-stack to save context during interrupt processing.
        s_copy                  ; saved STATUS
	p_copy			; saved PCLATH
	f_copy			; saved FSR
	i_temp			; temp for interrupt handler
        ;; internal timing generation
        tFlags                  ; Timer Flags
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
        rxFlag                  ; Receiver COS valid flags
	isdFlag			; ISD control flag.
        ;; beep generator control 
        beepTmr                 ; timer for generating various beeps
        beepAddr                ; address for various beepings, low byte.
        beepCtl                 ; beeping control flag
        ;; debounce timers
        rx0Dbc                  ; main receiver debounce timer
        rx1Dbc                  ; link receiver debounce timer
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
        dtATmr                  ; dtmf access timer
	fanTmr			; fan timer
	tailCtr			; tail message counter.
	unlkTmr			; unlocked mode timer.
	pulsTmr			; pulse timer.
        ;; timer presets
	hangDly			; hang timer preset, used often enough to keep around
        ;; CW generator data
        cwTmr                   ; CW element timer
        cwByte                  ; CW current byte (bitmap)
	cwTbTmr			; CW timebase timer
        cwTone                  ; CW tone 
        
	cTone			; courtesy tone to play

	eeAddr			; EEPROM address (low byte) to read/write
	eeCount			; number of bytes to read/write from EEPROM
        ;; control operator control flag groups
        group0                  ; group 0 flags
        group1                  ; group 1 flags
        group2                  ; group 2 flags
        group3                  ; group 3 flags
        group4                  ; group 4 flags
        group5                  ; group 5 flags
        group6                  ; group 6 flags
        group7                  ; group 7 flags
        group8                  ; group 8 flags
        group9                  ; group 9 flags
	;; ISD control variables
	isdDly			; isd command delay timer...
	isdMsg			; isd message number...
	isdRMsg			; isd RECORD message number...
	isdPTlo			; isd play timer low.
	isdPThi			; isd play timer high.
	isdRTlo			; isd record timer low.
	isdRThi			; isd record timer high.
	alrmTmr			; alarm beeper timer.
	alrmDbc			; alarm debounce timer.
	tx0CbTm			; transmitter 0 chicken burst timer
	tx1CbTm			; transmitter 1 chicken burst timer
	;; last var at 0x61 there are 14 left in this block...
	endc			; this block ends at 6f

	cblock	h'70'		; from 70 to 7f is common to all banks!
        w_copy                  ; 70  saved W register for interrupt handler
	dt0Ptr			; 71  DTMF-0 buffer pointer
	dt0Tmr			; 72  DTMF-0 buffer timer
	dt1Ptr			; 73  DTMF-1 buffer pointer
	dt1Tmr			; 74  DTMF-1 buffer timer
	scratch			; 75  scratchpad. (not currently used.)
        dtRFlag                 ; 76  DTMF receive flag...
	dtEFlag			; 77  DTMF command interpreter control flag
	eebPtr			; 78  eebuf write pointer.
	;; room here from 79 to 7f
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
	dt1buf0			; DTMF-1 receiver buffer (16 bytes) @ 130
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
	eebuf00			; eeprom write buffer (16 bytes) @ 140
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
	endc			; end of block @ 1bf


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
        org     0		; startup vector
	clrf	PCLATH		; stay in bank 0
        goto    Start

; ***********************
; ** INTERRUPT HANDLER **
; ***********************
IntHndlr
        org     4		; interrupt vector
	; preserve registers...
        movwf   w_copy          ; save w register
        swapf   STATUS,w        ; get STATUS
	clrf	STATUS		; force bank 0
	movwf	s_copy		; save STATUS
	movf	PCLATH,w	; get PCLATH
	movwf	p_copy		; save PCLATH
	clrf	PCLATH		; force page 0
	bsf	STATUS,IRP	; select RAM bank 1
	movf	FSR,w		; get FSR
	movwf	f_copy		; save FSR
	
        btfsc   INTCON,T0IF	; is it a timer interrupt?
        goto    TimrInt		; yes...
	;; not any of the interrupts indicated in INTCON...
	;; look at PIR1 interrupts...
	btfsc	PIR1,CCP1IF	; is it a compare interrupt?
	goto	CompInt		; yes.
        goto    IntExit		; no...
	
TimrInt
	movlw	T0PRE		; get timer 0 preset value
	movwf	TMR0		; preset timer 0
        bsf     tFlags,TICK     ; set tick indicator flag

TimrDone                        
        bcf     INTCON,T0IF     ; clear RTCC int mask
	goto	IntExit		; done here.
	
CompInt				; timer 1 compare match interrupt.
	clrf	TMR1L		; clear timer 1
	clrf	TMR1H		; clear timer 1
	bcf	PIR1,CCP1IF	; clear compare match interrupt bit.
	btfss	PORTC,BEEP	; is beep bit hi?
	goto	CompInL		; no.
	bcf	PORTC,BEEP	; lower beep bit.
	goto	IntExit		; done.
CompInL				; beep bit was low.
	bsf	PORTC,BEEP	; raise beep bit.
	goto	IntExit		; done.

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
	btfss	flags,needID	; need to ID?
	return			; nope--id timer expired without tx since last
	;; play the ID here.
	bsf	flags,IDNOW	; set IDing now flag.
	movf	txFlag,w	; get tx flags
	andlw	h'03'		; w=w&(RX0OPEN|RX1OPEN), non zero if repeating
	btfss	STATUS,Z	; Z set is not repeating
	goto	DoIDCW		; actively repeating, play CW ID.
	;; not actively repeating (nobody talking), ok to play voice ID
	btfsc	flags,initID	; initial ID wanted?
	goto	DoIDInt		; yep.

	btfss	group2,1	; is the normal speech id enabled?
	goto	DoIDCW		; no. do CW ID.
	btfss	flags,IDTOGL	; will it be ID2 this time?
	goto	DoID1		; no. use ID 1
	bcf	flags,IDTOGL	; select ID1 next time.
	movlw	VID2		; get ID message 2.
	goto	DoIDSpc		; play ID message

DoID1
	bsf	flags,IDTOGL	; select ID2 next time.
	movlw	VID1		; get ID message 1.
	goto	DoIDSpc		; play ID message

DoIDInt				; play initial ID
	btfss	group2,0	; is initial speech ID enabled?
	goto	DoIDCW		; not enabled, play CW.
	movlw	VINITID		; get initial ID

DoIDSpc				; play speech ID
	PAGE3			; select code page 3.
	movwf	isdMsg		; save message number.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
	goto	DoIDrst

DoIDCW				; play CW id.
	PAGE3			; select code page 3.
 	movlw   EECWID		; address of CW ID message in EEPROM.
        movwf   eeAddr		; save CT base address
	call	PlayCWe		; kick of the CW playback.
	PAGE0			; select code page 0.
	
DoIDrst				; reset ID timer & logic.
	movlw	EETID		; get EEPROM address of ID timer preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf   idTmr		; store to idTmr down-counter
	bcf     flags,initID    ; clear initial ID flag
	movf	txFlag,w	; get tx flags
	andlw	h'03'		; w=w&(RX0OPEN|RX1OPEN), non zero if RX active.
	btfsc	STATUS,Z	; is it zero?
	bcf	flags,needID	; yes. reset needID flag.
	return

Rcv0Off                         ; turn off receiver 0
	movlw	RXSOFF		; get new state #
	movwf	rx0Stat		; set new receiver state
	bcf	PORTC,RX0AUD	; mute it...
	bcf	txFlag,RX0OPEN	; clear main receiver on bit
	clrf	rx0TOut		; clear main receiver timeout timer
	goto	ChkMute		; check muting and TX status.
        
Rcv1Off                         ; turn off receiver 1
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	PORTD,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear main receiver on bit
	clrf	rx1TOut		; clear main receiver timeout timer

ChkMute				; check to see if any transmitters were muted
	movf	muteTmr,f	; check mute timer
	btfsc	STATUS,Z	; is mute timer running?
	return			; no.
	btfss	flags,TXONFLG	; is the transmitter supposed to be on?
	return			; no.

	btfsc	group4,6	; drop TX to mute?
	bsf	PORTC,TX0PTT	; turn TX back on.

	btfss	group3,7	; drop link TX to mute?
	return			; no.

	;is link a slaved repeater? turn link TX back on if it is.
	btfsc	group1,5	; slaved repeater mode?
	bsf	PORTD,TX1PTT	; yes.
	return			; done

SetHang				; start hang timer...
	btfss	group0,3	; is hang timer enabled?
	return			; nope.
	movlw	EETHTS		; get EEPROM address of hang timer short preset
	btfsc	group0,4	; is long hang timer selected?
	movlw	EETHTL		; get EEPROM address of hang timer long preset
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	hangDly		; save this in hangDly, used often.
	movwf   hangTmr		; preset hang timer
	btfss	STATUS,Z	; is hang timer zero.
	bsf	txFlag,TXHANG	; no, set hang time transmit flag
	return			; done.

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

; ***************************************************
; ** DoTail -- Play Tail Message and Reset Counter **
; ***************************************************

DoTail
	movlw	VTAIL		; get tail message 1'
	movwf	isdMsg		; save message number.
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.

	;; now, reset tail message counter.
	movlw	EETTAIL		; get EEPROM address of tail message counter.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	tailCtr		; preset tail message counter.
	return			; done with tail message.
	
	;; **************************************************
	;; **************************************************
	;; **************************************************

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
	org	0200
Start
	;bsf	STATUS,IRP	; select FSR is in 100-1ff range
  	bsf     STATUS,RP0      ; select bank 1

        movlw   b'00000000'
        movwf   ADCON0
        movlw   b'00000111'
        movwf   ADCON1
        
	IFDEF COLORBURST
        movlw   b'00000001'     ; RBPU pull ups 
				; INTEDG INT on falling edge
				; T0CS	 TMR0 uses instruction clock
				; T0SE  n/a
				; PSA TMR0 gets the prescaler 
				; PS2 \
				; PS1  > prescaler 4
				; PS0 /
	ELSE
        movlw   b'00000011'     ; RBPU pull ups 
				; INTEDG INT on falling edge
				; T0CS	 TMR0 uses instruction clock
				; T0SE  n/a
				; PSA TMR0 gets the prescaler 
				; PS2 \
				; PS1  > prescaler 16
				; PS0 /
	ENDIF
        movwf   OPTION_REG      ; set options

        movlw   B'11111111'     ; na/na/in/in/in/in/in/in
        movwf   TRISA           ; set port A data direction

        movlw   B'00001111'     ; out/out/out/out/in/in/in/in
        movwf   TRISB           ; set port B data direction

        movlw   B'11000001'     ; in/in/out/out/out/out/out/in
        movwf   TRISC           ; set port C data direction

        movlw   B'00110000'     ; out/out/in/in/out/out/out/out
        movwf   TRISD           ; set port D data direction

        movlw   B'00000000'     ; na/na/na/na/na/out/out/out
        movwf   TRISE           ; set port C data direction

	movlw	b'00000100'	; enable on CCP1 interrupt.
	movwf	PIE1		; set up interrupt control.
	
  	bcf     STATUS,RP0      ; select bank 0

	;; PORT A does not need to be initialized, it is input-only.
        clrf    PORTB		; preset PORTB all off.
	movlw	b'00011000'	; ISD OFF, MAIN MUTED.
        movwf   PORTC		; preset PORTC.
        clrf	PORTD		; preset PORTD.
	clrf	PORTE		; preset PORTE.
	
	;btfss	STATUS,NOT_TO	; did WDT time out?
	;bsf	PORTB,LED2	; yes, light warning lamp.

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
        movlw   h'20'           ; first address of RAM.
        movwf   FSR             ; set pointer.
ClrMem
        clrf    INDF            ; clear ram byte.
        incf    FSR,f           ; increment FSR.
	btfss	FSR,7		; cheap test for address 80 and above.
        goto    ClrMem          ; loop some more.
	bsf	STATUS,IRP	; select FSR is in 100-1ff range
	
	movlw	TEN		; get timebase presets
	movwf	oneMsC
	movwf	tenMsC
	movwf	hundMsC
	movwf	thouMsC
        clrf    tFlags

	movlw	CTNONE		; no courtesy tone.
	movwf	cTone		; set courtesy tone selector.
	
	;; preset timer defaults
        clrf    cwTbTmr         ; CW timebase counter.
        movlw   h'14'           ; C6 tone
        movwf   cwTone          ; CW tone.
        
        ;; enable interrupts.
	movlw   b'11100000'     ; enable global + peripheral + timer0
        movwf   INTCON

	btfsc	PORTC,INIT	; skip if init button pressed.
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
	PAGE3			; select page 3
	call	InitDat		; get init byte
	call	WriteEw		; write byte to EEPROM.
	PAGE0			; select page 0
	incf	temp2,f		; go to next byte
	goto	InitLp		; get the next block of 16 or be done.
	
; ********************************
; ** Ready to really start now. **
; ********************************
Start1
	clrw			; select macro set 0.
	PAGE3			; select page 3.
	call	LoadCtl		; load control op settings.
	PAGE0			; select page 0
	;; get tail message counter.
	movlw	EETTAIL		; get EEPROM address of tail message counter.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select page 0.
	movwf	tailCtr		; preset tail message counter.
	;;
	;; say hello to all the nice people out there.
	;;
	PAGE3			; select code page 3.
	movlw	CWNHRC5		; get conterller name announcement.
	call	PlayCW		; start playback
	PAGE0			; select code page 0.

	btfss	group4,0	; is aux input turned on?
	goto	Loop0		; no.
	bsf	txFlag,AUXIN	; yes, turn on txFlag AUXIN indicator.
	bsf	PORTD,RX2AUD	; unmute AUX IN audio.
	
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
	;; LED BLINKER!!!  I'M ALIVE!!!  I'M ALIVE!!!  WOOHOO!!!
        ;btfss   tFlags,HUNDMS
        ;goto    LedEnd
        ;btfss   PORTB,LED1
        ;goto    l3off
        ;bcf     PORTB,LED1
        ;goto    LedEnd
l3off 
        ;bsf     PORTB,LED1
LedEnd
	
; ********************************************
; ** RECEIVER DEBOUNCE AND INPUT VALIDATION **
; ********************************************
DebRx
        btfss   tFlags,ONEMS    ; is the one ms tick active?
        goto    OneMsD		; nope
CkRx0				; check COR state receiver 1
	btfss   PORTC,RX0COR    ; check cor receiver 1
	goto    Rx0COR1   	; it's low, COR is present
				; COR is not present.
        btfss   group1,2        ; (NOT) OR PL?
        goto    Rx0Off		; nope...
        goto    Rx0CkPL         ; yes, OR PL mode
Rx0COR1
        btfss   group0,1        ; AND PL set?
        goto    Rx0On           ; no.
Rx0CkPL                         ; check PL...
        btfsc   PORTC,RX0PL     ; is the PL signal present?
        goto    Rx0Off		; no.
Rx0On                           ; the COR and PL requirements have been met
        btfsc   rxFlag,RX0OPEN  ; already marked active?
        goto    Rx0NC           ; yes.
        movf    rx0Dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx01Dbc         ; nope...
        movlw   COR1DEB         ; get COR debounce timer value.
	btfsc	group2,6	; is the delay present?
	movlw	DLY1DEB		; get COR debounce with delay value.
	movf	txFlag,f	; check for transmitter already on.
	btfss	STATUS,Z	; is the transmitter already on?
	goto	Rx0SDeb		; yep.
	btfsc	group0,2	; is the kerchunker delay set?
	movlw	CHNKDEB		; get kerchunker filter delay.
Rx0SDeb				; set debounce timer.
        movwf   rx0Dbc          ; set it
        goto    Rx0Done         ; done.
Rx01Dbc
        decfsz  rx0Dbc,f        ; decrement the debounce counter
        goto    Rx0Done         ; not zero yet
        bsf     rxFlag,RX0OPEN  ; set receiver active flag
        goto    Rx0Done         ; continue...
Rx0Off				; the COR and PL requirements have not been met
	btfss	rxFlag,RX0OPEN	; was the receiver off before?
	goto	Rx0NC		; yes.
        movf    rx0Dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx00Dbc         ; nope...
        movlw   COR0DEB         ; get COR debounce timer value.
	btfsc	group2,6	; is the delay present?
	movlw	DLY0DEB		; get COR debounce with delay value.
        movwf   rx0Dbc          ; set it
        goto    Rx0Done         ; done.
Rx00Dbc
        decfsz  rx0Dbc,f        ; decrement the debounce counter
        goto    Rx0Done         ; not zero yet
        bcf     rxFlag,RX0OPEN  ; clear receiver active flag
	movf	dt0Tmr,f	; test to see if touch-tones received...
	btfsc	STATUS,Z	; is it zero?
	goto	Rx0Done		; yes. don't need to accellerate execution.
	movlw	d'2'		; no
	movwf	dt0Tmr		; accelerate eval of DTMF command
        goto    Rx0Done         ; continue...
Rx0NC
        clrf    rx0Dbc          ; clear debounce counter.
Rx0Done

CkRx1                           ; check COR state receiver 2
	btfss   PORTD,RX1COR    ; check cor receiver 1
	goto    Rx1COR1   	; it's low, COR is present
				; COR is not present.
        btfss   group3,4	; (NOT) OR PL?
        goto    Rx1Off  	; nope...
        goto    Rx1CkPL         ; yes, OR PL mode

Rx1COR1
        btfss   group3,3        ; AND PL set?
        goto    Rx1On           ; no.
Rx1CkPL                         ; check PL...
        btfsc   PORTD,RX1PL     ; is the PL signal present?
        goto    Rx1Off		; no.
Rx1On                           ; the COR and PL requirements have been met
        btfsc   rxFlag,RX1OPEN  ; already marked active?
        goto    Rx1NC           ; yes.
        movf    rx1Dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx11Dbc         ; nope...
        movlw   COR1DEB         ; get COR debounce timer value
	btfsc	group2,7	; is the delay present?
	movlw	DLY1DEB		; get COR debounce with delay value.
	movf	txFlag,f	; check for transmitter already on.
	btfss	STATUS,Z	; is the transmitter already on?
	goto	Rx1SDeb		; yep.
	btfsc	group0,2	; is the kerchunker delay set?
	movlw	CHNKDEB		; get kerchunker filter delay.
Rx1SDeb				; set debounce timer.
        movwf   rx1Dbc          ; set it
        goto    Rx1Done         ; done.
Rx11Dbc
        decfsz  rx1Dbc,f        ; decrement the debounce counter
        goto    Rx1Done         ; not zero yet
        bsf     rxFlag,RX1OPEN  ; set receiver active flag
        goto    Rx1Done         ; continue...
Rx1Off  			; the COR and PL requirements have not been met
	btfss	rxFlag,RX1OPEN	; was the receiver off before?
	goto	Rx1NC		; yes.
        movf    rx1Dbc,f        ; check for zero
        btfss   STATUS,Z        ; is it zero?
        goto    Rx10Dbc         ; nope...
        movlw   COR0DEB         ; get COR debounce timer value.
	btfsc	group2,7	; is the delay present?
	movlw	DLY0DEB		; get COR debounce with delay value.
        movwf   rx1Dbc          ; set it
        goto    Rx1Done         ; done.
Rx10Dbc
        decfsz  rx1Dbc,f        ; decrement the debounce counter
        goto    Rx1Done         ; not zero yet
        bcf     rxFlag,RX1OPEN  ; set receiver active flag
	btfss	group1,4	; is control rx & link port the same?
	goto	Rx1Done		; nope.
	movf	dt1Tmr,f	; test to see if touch-tones received...
	btfsc	STATUS,Z	; is it zero?
	goto	Rx1Done		; yes. don't need to accellerate execution.
	movlw	d'2'		; no
	movwf	dt1Tmr		; accelerate eval of DTMF command
        goto    Rx1Done         ; done.
Rx1NC
        clrf    rx1Dbc          ; clear debounce counter.
Rx1Done
	
OneMsD				; one millisecond tasks done.
        btfss   tFlags,TENMS    ; is the ten ms tick active?
        goto    TenMsD		; nope
	
	;; ******************************
	;; ** debounce the alarm input **
	;; ******************************
	btfss	group4,3	; is the alarm enabled?
	goto	CkAlDon		; no.  ignore all this.
	btfss	PORTB,ALARM	; is alarm bit off?
	goto	DebAlm		; no.
	clrf	alrmDbc		; clear debounce counter.
	goto	CkAlDon		; done here.
DebAlm				; debounce alarm input.
	movf	alrmDbc,w	; get alarm debounce timer
	sublw	ALM_DBC		; subtract alarm debounce time.
	btfss	STATUS,C	; skip if ALM_DBC - alrmDbc is positive.
	goto	SetAlrm		; it's positive.
	incf	alrmDbc,f	; increment alarm debounce timer.
	goto	CkAlDon		; done here.
SetAlrm				; set the alarm tone up, if not already set.
	movf	alrmTmr,f	; check alarm timer.
	btfss	STATUS,Z	; is it zero?
	goto	CkAlDon		; no.  Alarm timer is already set.
	movlw	d'1'		; immediately start alarm tone.
	movwf	alrmTmr		; save alarm timer.
CkAlDon				; checking alarm done.
	
	;; ******************
	;; ** check DTMF-0 ** 
	;; ******************
CkDTMF0	
	btfss	PORTA,DTMF0DV	; is a DTMF digit being decoded?
	goto	CkDT0L		; no
	btfsc	mscFlag,LASTDV0	; was it there last time?
	goto	CkDTMF1		; yes, do nothing.
	bsf	mscFlag,LASTDV0	; set last DV indicator.

RdDT0
	btfsc	group1,3	; is muting enabled?
	bcf	PORTC,RX0AUD	; mute receiver 0
	btfsc	group3,7	; drop link to mute enabled?
	bcf	PORTD,TX1PTT	; turn off link PTT.
	btfsc	group4,6	; drop main TX to mute enabled?
	bcf	PORTC,TX0PTT	; turn off main PTT.
	movlw   MUTEDLY		; get mute timer delay
	movwf   muteTmr		; preset mute timer
RdDT0m
	movlw	DTMFDLY		; get DTMF activity timer preset.
	movwf	dt0Tmr		; set dtmf command timer
	
	movf	dt0Ptr,w	; get index
	movwf	FSR		; put it in FSR
	bcf	STATUS,C	; clear carry (just in case)
	rrf	FSR,f		; hey! divide by 2.
	movlw	LOW dt0buf0	; get address of buffer
	addwf	FSR,f		; add to index.

	bsf	PORTD,DTMF0OE	; enable DTMF-0 output port.
	movlw	b'00001111'	; mask bits.
	andwf	PORTA,w		; get masked bits of tone into W.
	bcf	PORTD,DTMF0OE	; disable DTMF-0 output port.
	PAGE3			; select code page 3.
	call	MapDTMF		; remap tone into keystroke value..
	PAGE0			; select code page 0.
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

	goto	CkDTMF1		; done with DTMF checking.

CkDT0L				; check for end of of the DTMF tone
	btfss	mscFlag,LASTDV0	; was it low last time?
	goto	CkDTMF1		; yes.  Done.
	bcf	mscFlag,LASTDV0	; no, clear last DV indicator.

	bcf	mscFlag,CTCSS0	; clear LAST CTCSS flag.
        btfss   PORTC,RX0PL     ; is the PL signal present?
	bsf	mscFlag,CTCSS0	; set LAST CTCSS flag.

	;; ******************
	;; ** check DTMF-1 ** 
	;; ******************
CkDTMF1
	btfss	PORTA,DTMF1DV	; is a DTMF digit being decoded?
	goto	CkDT1L		; no
	btfsc	mscFlag,LASTDV1	; was it there last time?
	goto	CkDTDone	; yes, do nothing.
	bsf	mscFlag,LASTDV1	; set last DV indicator.

RdDT1
	btfss	group1,4	; is this from the link receiver?
	goto	RdDT1m		; no, it's from the control receiver.
	btfsc	group1,3	; is muting enabled?
	bcf	PORTD,RX1AUD	; mute receiver 1
	btfsc	group3,7	; drop link to mute enabled?
	bcf	PORTD,TX1PTT	; turn off link PTT.
	btfsc	group4,6	; drop main TX to mute enabled?
	bcf	PORTC,TX0PTT	; turn off main PTT.
	movlw   MUTEDLY		; get mute timer delay
	movwf   muteTmr		; preset mute timer
RdDT1m
	movlw	DTMFDLY		; get DTMF activity timer preset.
	movwf	dt1Tmr		; set dtmf command timer
	
	movf	dt1Ptr,w	; get index
	movwf	FSR		; put it in FSR
	bcf	STATUS,C	; clear carry (just in case)
	rrf	FSR,f		; hey! divide by 2.
	movlw	LOW dt1buf0	; get address of buffer
	addwf	FSR,f		; add to index.

	bsf	PORTD,DTMF1OE	; enable DTMF-1 output port.
	movlw	b'00001111'	; mask bits.
	andwf	PORTA,w		; get masked bits of tone into W.
	bcf	PORTD,DTMF1OE	; disable DTMF-1 output port.
	PAGE3			; select code page 3.
	call	MapDTMF		; remap tone into keystroke value..
	PAGE0			; select code page 0.
	iorlw	h'0'		; OR with zero to set status bits.
	bcf	mscFlag,DT1ZERO	; clear last zero received.
	btfsc	STATUS,Z	; was a zero the last received digit?
	bsf	mscFlag,DT1ZERO	; yes...
	
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

	goto	CkDTDone	; done with DTMF checking.

CkDT1L				; check for end of LITZ...
	btfss	mscFlag,LASTDV1	; was it low last time?
	goto	CkDTDone	; yes.  Done.
	bcf	mscFlag,LASTDV1	; clear last DV indicator.

	bcf	mscFlag,CTCSS2	; clear LAST CTCSS flag.
        btfss   PORTD,RX1PL     ; is the PL signal present?
	bsf	mscFlag,CTCSS2	; set LAST CTCSS flag.

CkDTDone			; done with DTMF scanning.


TenMsD				; ten ms tasks done.
	
	;; service isdDly timer here...
	btfss	tFlags,HUNDMS	; 100 Ms tick?
	goto	CkIDone		; no.

	movf	isdDly,f	; check ISD delay timer.
	btfsc	STATUS,Z	; is it zero?
	goto	CkIP		; yes.
	decfsz	isdDly,f	; no, decrement.
	goto	CkIP		; still not zero.
	;; isd delay timer counted to zero.  Start playback.
	bsf	isdFlag,ISDRUNF	; set running flag.
	bsf	PORTC,ISDREC	; clear record, if present, for sanity.
	bcf	PORTC,ISDRUN	; turn on ISD	playback.  
	goto	CkIDone		; done here...
	
CkIP				; check ISD run timer.
	btfsc	isdFlag,ISDRUNF	; is ISD running?
	goto	CkIPD		; yes.
	btfss	isdFlag,ISDRECF	; is ISD recording.
	goto	CkIRec		; no.

CkIPD	
	decfsz	isdPTlo,f	; decrement ISD play timer low.
	goto	CkIRec		; not zero yet.
	movf	isdPThi,f	; check ISD hi timer.
	btfsc	STATUS,Z	; is result zero.
	goto	CkIPDone	; ISD playback complete.
	decf	isdPThi,f	; decrement ISD play timer hi.
	goto	CkIRec		; done here.

CkIPDone			; ISD playback complete.
	bsf	PORTC,ISDRUN	; stop playback.
	bsf	PORTC,ISDREC	; stop record, if present.
	btfsc	isdFlag,ISDRECF	; was it recording?
	goto	CkIRDone	; yes.
	bcf	isdFlag,ISDRUNF	; clear running flag.
	bcf	txFlag,TALKING	; turn off talking bit.
	bcf	flags,IDNOW	; clear ID playing now flag.
	goto	CkIDone		; done here.
	
CkIRDone			; ISD record done.
	movf	isdRMsg,w	; get message number
	andlw	b'00000111'	; restrict message number to reasonable range.
	addlw	MSG0LEN		; add address of message 0.
	movwf	eeAddr		; set EEPROM address.
	movf	isdRTlo,w	; get record timer.
	PAGE3			; select ROM page 3.
	call	WriteEw		; save message length.
	PAGE0			; select ROM page 0.
	bcf	isdFlag,ISDRECF	; clear ISD recording bit.
	goto	CkIDone		; done here.
	
CkIRec				; deal with record timer, if active.
	btfss	isdFlag,ISDRECF	; in record mode?
	goto	CkIDone		; no.
	incfsz	isdRTlo,f	; increment ISD record low timer.
	goto	CkIDone		; don't need to carry.
	incf	isdRThi,f	; carry.
	
CkIDone
	btfss	group4,1	; is aux receiver in auto mode?
	goto	CkADone		; no.
	btfss	PORTB,AUXCOR   	; is cor active on remote receiver?
	goto	CkAOn		; yes.
	bcf	txFlag,AUXIN	; no, turn off txFlag AUXIN indicator.
	bcf	PORTD,RX2AUD	; mute AUX IN audio.
	goto	CkADone		; done.
CkAOn				; turn on AUX IN audio.
	;; check aux receiver auto mute here.
	btfss	group4,2	; auto mute aux input enabled?
	goto	CkAOn1		; nope.
	movlw	0x03		; receivers 0 and 1 mask
	andwf	txFlag,w	; and with active audio bits.
	btfss	STATUS,Z	; is result 0 (both receivers off)?
	goto	CkADone		; nope.
CkAOn1
	bsf	txFlag,AUXIN	; turn on txFlag AUXIN indicator.
	bsf	PORTD,RX2AUD	; unmute AUX IN audio.

CkADone				; done checking aux receiver mode.
	goto	MainLp		; crosses 256 byte boundary (to 0400)
	org 0400
	
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
	goto	ChkRb		; yes.  Don't turn receiver on.
	;; timer is not zero, reset to initial value.
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddr		; set EEPROM address low byte.
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
	movf	muteTmr,f	; check mute timer
	btfsc	STATUS,Z	; if it's non-zero, skip unmute
	bsf	PORTC,RX0AUD	; unmute receiver
	;; mute aux audio here, if requested...
	btfss	group4,2	; is aux audio auto-mute enabled?
	goto	Main00a		; nope.
	btfss	txFlag,AUXIN	; is the aux audio turned on?
	goto	Main00a		; nope.
	bcf	PORTD,RX2AUD	; mute the aux audio.
Main00a
	;; stomp playing voice messages here.
	btfss	isdFlag,ISDRUNF	; is ISD Running?
	goto	ChkRec		; no
	;; ISD is running.
	btfss	flags,IDNOW	; is an ID playing now?
	goto	Stomp		; nope.
	btfss	group2,2	; is stomp allowed?
	goto	MainUM		; nope.  bypass record check, too.
Stomp
	clrf	isdDly		; clear this so it can't fire, just in case.
	bcf	isdFlag,ISDRUNF	; clear ISD running flag.
	bsf	PORTC,ISDRUN	; stop ISD.
	bsf	PORTC,ISDREC	; sanity check--don't record.
	bcf	txFlag,TALKING	; clear TALKING flag

	btfss	flags,IDNOW	; is an ID playing now?
	;; hmmmm.  should this be allowed to set record mode now?
	goto	ChkRec		; no.

 	movlw   EECWID		; address of CW ID message in EEPROM.
        movwf   eeAddr		; save CT base address
	PAGE3			; select code page 1.
	call	PlayCWe		; kick off the CW playback.
	PAGE0			; select code page 0.
	bcf	flags,IDNOW	; clear IDing flag.
	
ChkRec
	btfsc	isdFlag,ISDRECR	; is record mode flag set?
	goto	NormRec		; record normal message.
	btfsc	group1,6	; in simplex mode?
	goto	SimRec		; yes.
        goto    MainUM          ; no continue...
	
NormRec				; normal, 11.1 second message.
	bcf	isdFlag,ISDRECR	; clear record mode flag.
	movlw	d'111'		; 11.1 seconds
	movwf	isdPTlo		; save message length.  
	clrf	isdPThi		; clear play timer hi. 
	goto	SRec		; start recording, up to 11.1 seconds.
	
SimRec
	btfsc	group1,7	; simplex voice ID mode?
	goto	SimRecS		; yes.
        movlw   H'03'           ; 768 ticks
        movwf   isdPThi         ; save hi byte isd max time
        movlw   H'82'           ; 130 more ticks = 89.8 seconds
        movwf   isdPTlo         ; save lo byte isd max time
	clrf	isdRMsg		; record message 0.
	goto	SRec		; start recording, up to 89.8 seconds.

SimRecS
        movlw   H'03'           ; 768 ticks
        movwf   isdPThi         ; save hi byte isd max time
        movlw   H'14'           ; 20 more ticks = 78.8 seconds
        movwf   isdPTlo         ; save lo byte isd max time
	movlw	d'1'		; start at message 1.
	movwf	isdRMsg		; record at message 1.
	
SRec				; start recording.
	clrf	isdRThi		; clear record timer hi.
	clrf	isdRTlo		; clear record timer lo.
	movf	isdRMsg,w	; get message number to record.
	movwf	PORTE		; set up ISD hardware address.
	bsf	isdFlag,ISDRECF	; set record flag.
	bcf	PORTC,ISDREC	; set record mode.
	bcf	PORTC,ISDRUN	; start ISD.
	goto	MainUM		; done here.
	
MainUM
	;; link non-repeater PTT logic
	btfss	group3,2	; is link TX enabled?
	goto	Main01		; nope...
	btfsc	group1,5	; is link port a repeater?
	goto	Main01		; no.
	PAGE3			; select code page 3
	call	PTT1On		; turn on TX1 PTT
	PAGE0			; select code page 0
	
Main01
	btfss	group1,0	; is time out timer enabled?
	goto	ChkRb		; nope...
	movlw	EETTMS		; EEPROM address of timeout timer short preset.
	btfsc	group1,1	; is short timeout selected
	movlw	EETTML		; EEPROM address of timeout timer long preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rx0TOut		; set timeout counter
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
	bcf     PORTC,RX0AUD	; mute
	clrf	rx0TOut		; clear main receiver timeout timer
	btfsc	group2,3	; is voice timeout message enabled?
	goto	Main1TO		; yes...
	PAGE3			; select code page 3.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkRb		; done here...
Main1TO	
	movlw   VTIMOUT		; time out message
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
	goto	ChkRb		; done here...

Main1Off			; receiver was active, became inactive
        call    Rcv0Off		; turn off receiver
	;; link non-repeater-mode PTT logic
	btfss	group3,2	; is link port TX enabled?
	goto	Main10		; nope...
	btfsc	group1,5	; is link port a repeater?
	goto	Main10		; yes...
	PAGE3			; select code page 3
	call	PTT1Off
	PAGE0			; select code page 1
Main10
	;; unmute aux input here, if requested.
	btfss	txFlag,AUXIN 	; should aux audio be on?
	goto	Main10z		; nope.
	btfss	group4,2	; aux auto mute auto-mute enabled.
	goto	Main10z		; nope.
	bsf	PORTD,RX2AUD	; unmute aux audio.
Main10z
	btfsc	group1,6	; in simplex mode?
	goto	Main10m		; yes.

	btfsc	isdFlag,ISDTEST	; test message mode?
	goto	Main10m		; yes.
	
	btfss	isdFlag,ISDRECF	; is the ISD recording
	goto	Main10a		; nope.
	bsf	PORTC,ISDRUN	; stop ISD.
	bsf	PORTC,ISDREC	; don't record anymore.
	bcf	isdFlag,ISDRECF	; clear recording flag.
	goto	RecEnd1		; 

Main10m				; receiver dropped, in simplex mode.
	btfss	isdFlag,ISDRECF	; is the ISD recording
	goto	Main10X		; nope.
	bsf	PORTC,ISDRUN	; stop ISD.
	bsf	PORTC,ISDREC	; don't record anymore.
	bcf	isdFlag,ISDRECF	; clear recording flag.

Main10X
	movf	isdRThi,f	; get record timer hi.
	btfss	STATUS,Z	; is it zero?
	goto	Main10Y		; no.
	movf	isdRTlo,f	; get record timer lo.
	btfsc	STATUS,Z	; is it zero?
	goto	Main10Q		; yes, no message recorded, don't play.
	decf	isdRTlo,f	; eat last .1 sec, squelch crash?
	btfss	STATUS,Z	; is it zero now?
	goto	Main10Z		; play the simplex message.
	
Main10Q				; zero length message recorded
	bcf	isdFlag,ISDTEST	; clear test message flag.
	goto	Main10s		; yes, no message recorded, don't play.
	
Main10Y
	movf	isdRTlo,f	; get record timer lo.
	btfsc	STATUS,Z	; is it zero?
	decf	isdRThi,f	; borrow 256 from hi byte.
	decf	isdRTlo,f	; eat last .1 sec, squelch crash?
Main10Z
	movf	isdRThi,w	; get record timer hi.
	movwf	isdPThi		; save play timer hi.
	movf	isdRTlo,w	; get record timer lo.
	movwf	isdPTlo		; save play timer lo.
	btfss	isdFlag,ISDTEST	; test message mode?
	goto	Main10v		; no.
	bcf	isdFlag,ISDTEST	; clear test message mode.
	movlw	VTEST		; get test message number
	goto	Main10w		; play it.
	
Main10v	
	movlw	d'0'		; normal simplex message.
	btfsc	group1,7	; simplex voice ID mode?
	movlw	d'1'		; special ID mode simplex message.
Main10w
	movwf	isdMsg		; save message number.
	PAGE3			; select code page 3.
	call	PlaySSp		; play simplex speech message.
	PAGE0			; select code page 0.
	goto	Main10s		; done here.

RecEnd1
	movf	isdRMsg,w	; get message number
	andlw	b'00000111'	; restrict message number to reasonable range.
	addlw	MSG0LEN		; add address of message 0.
	movwf	eeAddr		; set EEPROM address.
	decf	isdRTlo,w	; get record timer - 1.
	PAGE3			; select ROM page 3.
	call	WriteEw		; save message length.
	movlw	CW_OK		; get CW OK
	call	PlayCW		; start playback
	PAGE0			; select ROM page 0.
	
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
        movlw   CTALERT		; yes, get that courtesy tone

Main10h
	movwf	cTone		; save the courtesy tone.
	call	SetHang		; start/restart the hang timer
	call	ChkID		; test if need an ID now
Main10s				; Simplex mode; no hang, no courtesy tone.
	goto	ChkRb		; done here...

Main2				; receiver timedout state
	btfss	group0,0	; is repeater enabled?
	goto	Main2Off	; no.  turn receiver off
	btfsc	rxFlag,RX0OPEN	; is squelch still open?
	goto	ChkRb		; yes, still timed out
Main2Off			; end of timeout condition.
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rx0Stat		; set new receiver state
	btfsc	group2,3	; is voice timeout message enabled?
	goto	Main2TO		; yes...
	PAGE3			; select code page 3.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkRb		; done here...
Main2TO	
	movlw   VTIMOUT		; time out message
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
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
	goto	ChkTmrs		; no.  don't allow link activity.
	movf	group3,w	; get group 3
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	ChkTmrs		; no...
	btfss	group0,5	; is DTMF access mode enabled?
	goto	RbRx01		; no.
	movf	dtATmr,f	; check DTMF access mode timer.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkTmrs		; yes.  Don't turn receiver on.
	;; timer is not zero, reset to initial value.
	movlw	EETDTA		; get EEPROM address of DTMF access timer.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	dtATmr		; set DTMF access mode timer.
	
RbRx01				; turn on remote base receiver.
	movlw	RXSON		; get new state #
	movwf	rx1Stat		; set new receiver state
	bsf	txFlag,RX1OPEN	; set link receiver on bit
	btfss	flags,RBMUTE	; is mute requested for some reason?
	bsf	PORTD,RX1AUD	; no, unmute.
	btfss	group3,5	; is time out timer enabled?
	goto	RbRx01L		; nope...
	movlw	EETTMS		; EEPROM address of timeout timer long preset.
	btfsc	group1,1	; is short timeout selected
	movlw	EETTML		; EEPROM address of timeout timer short preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	rx1TOut		; set timeout counter
RbRx01L
	;; mute aux input if requested.
	;; mute aux audio here, if requested...
	btfss	group4,2	; is aux audio auto-mute enabled?
	goto	RbRx01a		; nope.
	btfss	txFlag,AUXIN	; is the aux audio turned on?
	goto	RbRx01a		; nope.
	bcf	PORTD,RX2AUD	; mute the aux audio.
	
RbRx01a
	btfss	group1,5	; are we in slaved repeater mode?
	goto	ChkTmrs		; no.
	PAGE3			; select code page 3.
	call	PTT1On		; turn on TX1 PTT.
	PAGE0			; select code page 0.
	goto	ChkTmrs		; done here...

RbRx1				; receiver active state
	btfss	group0,0	; is repeater enabled?
	goto	RbRx1Off	; no.  turn off link receiver.
	movf	group3,w	; get group 3
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	RbRx1Off	; yes.  turn off link receiver.
	
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
	bcf	PORTD,RX1AUD	; mute receiver 1
	clrf	rx1TOut		; clear receiver 1 timeout timer
	btfsc	group2,3	; is voice timeout message enabled?
	goto	RbRx1TO		; yes...
	PAGE3			; select code page 3.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkTmrs		; done here...
RbRx1TO	
	movlw   VTIMOUT		; time out message
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.
	goto	ChkTmrs		; done here...

RbRx1Off			; receiver was active, became inactive
        call    Rcv1Off		; turn off link receiver
	;; unmute aux input here, if requested.
	btfss	txFlag,AUXIN 	; should aux audio be on?
	goto	RbRx1o0		; nope.
	btfss	group4,2	; aux auto mute auto-mute enabled.
	goto	RbRx1o0		; nope.
	bsf	PORTD,RX2AUD	; unmute aux audio.
RbRx1o0
	;; if link tx is on, and link is not a repeater, then 
	;; suppress link ctsy tone.
	btfss	PORTD,TX1PTT	; is link tx on?
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
	goto	RbRx2Off	; no.  turn off link receiver.
	movf	group3,w	; get group 3
	andlw	b'00000110'	; and it with receive mode || transmit mode
	btfsc	STATUS,Z	; is result zero?
	goto	RbRx2Off	; yes.  turn off link receiver.

	btfsc	rxFlag,RX1OPEN	; is squelch open?
	goto	ChkTmrs		; yes, still timed out
RbRx2Off	
	movlw	RXSOFF		; timeout condition ended, get new state (off)
	movwf	rx1Stat		; set new receiver state

	btfsc	group2,3	; is voice timeout message enabled?
	goto	RbRx2TO		; yes...
	PAGE3			; select code page 3.
	movlw	CW_TO		; get CW timeout message.
	call	PlayCW		; play CW message.
	PAGE0			; select code page 1.
	goto	ChkTmrs		; done here...

RbRx2TO
	movlw   VTIMOUT		; time out message
	PAGE3			; select code page 3.
	call	PlaySpc		; play the speech message.
	PAGE0			; select code page 0.

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
	movf	pulsTmr,f	; check for pulsed output
	btfsc	STATUS,Z	; is it zero?
	goto	PulsEnd		; yep.
	decfsz	pulsTmr,f	; decrement and check for zero.
	goto	PulsEnd		; not zero yet.
	movf	group6,w	; get digout pulse control.

	andlw	h'0f'		; mask leaves low 4 bits.
	xorlw	h'ff'		; invert.
	andwf	group7,f	; update the port.
	
	swapf	group7,w	; get the port value back & swap nibbles.
	andlw	b'11110000'	; clear unneeded bits.
	movwf	temp		; save.
	movf	PORTB,w		; get PORTB bits.
	andlw	b'00001111'	; clear unneeded bits.
	iorwf	temp,w		; set bits from group5
	movwf	PORTB		; put entire byte back to PORTB.
PulsEnd				; done with IO output pulse logic
	;; check chickenburst timer, tx0
	movf	tx0CbTm,f	; check tx0 chicken burst timer
	btfsc	STATUS,Z	; is it zero?
	goto	Chkn2		; yep.
	decfsz	tx0CbTm,f	; decrement the timer
	goto	Chkn2		; not zero yet.
	bcf	PORTC,TX0PTT	; turn off tx0 PTT!

Chkn2
	;; check chickenburst timer, tx1
	movf	tx1CbTm,f	; check tx1 chicken burst timer
	btfsc	STATUS,Z	; is it zero?
	goto	ChknEnd		; yep.
	decfsz	tx1CbTm,f	; decrement the timer
	goto	ChknEnd		; not zero yet.
	bcf	PORTD,TX1PTT	; turn off tx1 PTT!
ChknEnd

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

	movf	cTone,w		; get courtesy tone.
	btfss	PORTB,CT5SEL	; is CT5SEL low?
	movlw	CTSEL5		; yes, get CTSEL5 courtesy tone.
	btfss	PORTB,CT6SEL	; is CT6SEL low?
	movlw	CTSEL6		; yes, get CTSEL6 courtesy tone.
	
	btfsc	dtRFlag,DT0UNLK	; is this port (main receiver) unlocked?
	movlw	CTUNLOK		; get unlocked mode courtesy tone.
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
	movf    muteTmr,f       ; test mute timer
	btfsc   STATUS,Z	; Z is set if not DTMF muting
	goto    NoMutTm		; muteTmr is zero.
	decfsz  muteTmr,f       ; decrement muteTmr
	goto    NoMutTm		; have not reached the end of the mute time
	btfsc   txFlag,RX0OPEN	; is receiver 0 unsquelched
        bsf     PORTC,RX0AUD	; unmute it...

	btfss   txFlag,RX1OPEN	; is receiver 1 unsquelched
	goto	UnMutTx		; no.
	btfss	flags,RBMUTE	; is RB muted for some other reason?
        bsf     PORTD,RX1AUD	; no, unmute it...
UnMutTx
	btfsc	group4,6	; drop main receiver to mute enabled?
	bsf	PORTC,TX0PTT	; turn on main receiver PTT!
	btfss	group3,7	; drop link to mute enabled?
	goto	NoMutTm		; no.
	btfss	group3,2	; link transmitter enabled?
	goto	NoMutTm		; nope.
	btfsc   txFlag,RX0OPEN	; is receiver 0 unsquelched
	bsf	PORTD,TX1PTT	; yes. turn on link PTT.
	
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
	bsf	PORTD,RX1AUD	; unmute the remote base.
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
	goto	NoTimr		; nope.  no more timers to test.
	movf    idTmr,f
	btfsc   STATUS,Z	; is idTmr 0
	goto    NoIDTmr		; yes...
	decfsz  idTmr,f		; decrement ID timer
	goto    NoIDTmr		; not zero yet...
	call	DoID		; id timer decremented to zero, play the ID
NoIDTmr				; process more 10 second timers here...
	movf	fanTmr,f	; check fan timer
	btfsc	STATUS,Z	; is it zero?
	goto	NoFanTm		; yes.
	btfss	group2,4	; fan mode configured?
	goto	NoFanTm		; no
       	decfsz	fanTmr,f	; decrement fan timer
	goto	NoFanTm		; not zero yet
	bcf	PORTD,FANCTL	; turn off fan
NoFanTm
	movf	dtATmr,f	; check DTMF access timer.
	btfsc	STATUS,Z	; is it zero?
	goto	NoDTATm		; yes
	decfsz	dtATmr,f	; decrement DTMF access timer
	goto	NoDTATm		; not zero yet.

NoDTATm
	movf	alrmTmr,f	; check alarm timer.
	btfsc	STATUS,Z	; is it zero?
	goto	NoAlmTm		; yes
	decfsz	alrmTmr,f	; decrement alarm timer
	goto	NoAlmTm		; not zero yet.
	movlw	EETALM		; get EEPROM address of alarm timer preset.
	movwf	eeAddr		; set EEPROM address low byte.
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	PAGE0			; select code page 0.
	movwf	alrmTmr		; preset alarm timer.
	movlw	BP_ALM		; get alarm beep tone.
	PAGE3			; select code page 3.
	call	PlayCTx		; play courtesy tone #w
	PAGE0			; select code page 0.
NoAlmTm				; done with alarm timer.
		
NoTimr				; no more timers to test.
	

ChkTx				; check if transmitter should be on
	;; also handle the non-chickenburst CTCSS encoder control here.
	clrf	temp2		; clear temp2
	btfss	group5,0	; CTCSS control enabled TX0?
	goto	ChkTxC2		; no.
	btfsc	group5,1	; chickenburst mode TX0?
	goto	ChkTxC2		; yes

	movf	txFlag,w	; get txFlag
	andlw	b'00010011'	; active inputs mask.
	btfsc	STATUS,Z	; any active inputs?
	goto	ChkTxC1		; no active inputs.
	bsf	PORTB,4		; turn on tx0 CTCSS encoder.
	bsf	group7,0	; turn on in memory copy.
	goto	ChkTxC2
ChkTxC1
	bcf	PORTB,4		; turn off tx0 CTCSS encoder.
	bcf	group7,0	; turn off in memory copy.
	
ChkTxC2	
	btfss	group3,2	; is TX1 transmit-enabled?
	goto	ChkTxC4		; no
	btfss	group5,2	; CTCSS control enabled TX1?
	goto	ChkTxC4 	; no.
	btfsc	group5,3	; chickenburst mode TX1?
	goto	ChkTxC4		; yes

	movf	txFlag,w	; get txFlag
	andlw	b'00010011'	; active inputs mask.
	btfsc	STATUS,Z	; any active inputs?
	goto	ChkTxC3		; no active inputs.
	bsf	PORTB,5		; turn on tx1 CTCSS encoder.
	bcf	group7,1	; turn off in memory copy.
	goto	ChkTxC4		; finish.
	
ChkTxC3
	bcf	PORTB,5		; turn off tx1 CTCSS encoder.
	bcf	group7,1	; turn off in memory copy.
	
ChkTxC4	
	movf	txFlag,f	; check txFlag
	btfsc	STATUS,Z	; skip if not zero
	goto	ChkTx0		; it's zero, turn off transmitter
	;; txFlag is not zero

	btfsc	flags,TXONFLG	; skip if not already on
	goto	ChkTxE		; done here
	PAGE3			; select code page 1.
	call	PTT0On		; turn on transmitter (will set TXONFLG)
	PAGE0			; select code page 0.
	goto	ChkTxE		; now done here.
	
ChkTx0
	btfss	flags,TXONFLG	; skip if tx is on
	goto	ChkTxE		; was already off
	PAGE3			; select code page 1.
	call	PTT0Off		; turn off PTT
	PAGE0			; select code page 0.
ChkTxE				; end of ChkTx

; ***************
; ** CW SENDER ** 
; ***************
CWSendr
	btfss   txFlag,CWPLAY   ; sending CW?
	goto    NoCW		; nope

        btfss   tFlags,ONEMS    ; is this a one-ms tick?
        goto    NoCW            ; nope.

        decfsz  cwTbTmr,f       ; decrement CW timebase counter
        goto    NoCW            ; not zero yet.

	movlw	CWTBDLY		; get cw timebase preset.
        movwf   cwTbTmr         ; preset CW timebase.

	decfsz  cwTmr,f		; decrement CW element timer
	goto    NoCW		; not zero

	btfss   tFlags,CWBEEP	; was "key" down? 
	goto    CWKeyUp		; nope
				; key was down
	bcf     tFlags,CWBEEP	; 
	; turn off beep here.
	clrw			; clear W.
	PAGE3			; select code page 3.
	call	SetTone		; set the beep tone up.
	PAGE0			; select code page 0.
	decf    cwByte,w	; test CW byte to see if 1
	btfsc   STATUS,Z	; was it 1 (Z set if cwByte == 1)
	goto    CWNext		; it was 1...
	movlw   CWIESP		; get cw inter-element space
	movwf   cwTmr		; preset cw timer
	goto    NoCW		; done with this pass...

CWNext				; get next character of message
	PAGE3			; select code page 1.
        call    GtBeep          ; get the next cw character
	PAGE0			; select code page 0.
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
	bsf     tFlags,CWBEEP   ; turn key->down
        movf    cwTone,w        ; get CW tone
	;; turn on beep here.
	PAGE3			; select code page 3.
	call	SetTone		; set the beep tone up.
	PAGE0			; select code page 0.
	rrf     cwByte,f	; rotate cw bitmap
	bcf     cwByte,7	; clear the MSB
	goto    NoCW		; done with this pass...

CWDone				; done sending CW
	bcf     txFlag,CWPLAY   ; turn off CW flag
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
        goto    CkDt1		; yes
        decfsz  dt0Tmr,f        ; decrement timer
        goto    CkDt1		; not zero yet
	bsf	dtRFlag,DT0RDY	; ready to evaluate command.
CkDt1   
        movf    dt1Tmr,f        ; check for zero...
        btfsc   STATUS,Z        ; is it zero
        goto    TonDone         ; yes
        decfsz  dt1Tmr,f        ; decrement timer
        goto    TonDone		; not zero yet
	bsf	dtRFlag,DT1RDY	; ready to evaluate command.
TonDone
        ;; manage beep timer 
        btfss   tFlags,TENMS    ; is this a 10 ms tick?
        goto    NoTime          ; nope.
        movf    beepTmr,f       ; check beep timer
        btfsc   STATUS,Z        ; is it zero?
	goto	NBeep		; yes.
        ;goto    NoTime	        ; yes.
BeepTic                         ; a valid beep tick.
        decfsz  beepTmr,f       ; decrement beepTmr
        goto    NoTime          ; not zero yet.
	PAGE3			; select code page 3.
        call    GetBeep         ; get the next beep tone...
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
        call    GetBeep         ; get the next beep tone...
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
	goto	PfxDT1		; no command waiting.
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

PfxDT1
	;; evaluate DTMF 1 buffer for command
	btfss	dtRFlag,DT1RDY	; is a command ready to evaluate?
	goto	XPfxDT		; no command waiting.
	;; copy command from dtmf rx buf to command interpreter input buffer.
	movlw	low dt1buf0	; get address of this dtmf receiver's buffer
	movwf	FSR		; store.
	movf	dt1Ptr,w	; get command size...
	movwf	cmdSize		; save it.
	call	CpyDTMF		; copy the command...
	movf	dt1Ptr,w	; get command size back, CpyDTMF clobbers.
	movwf	cmdSize		; save it.
	clrf	dt1Ptr		; make ready to receive again.
	clrf	dtEFlag		; start evaluating from first prefix.
	bsf	dtEFlag,DT1CMD	; command from DTMF-0.
	bsf	dtRFlag,DTSEVAL	; set evaluate DTMF bit.
	btfsc	dtRFlag,DT1UNLK	; port 0 unlocked?
	bsf	dtRFlag,DTUL	; this port is unlocked.
	bcf	dtRFlag,DT1RDY	; reset DTMF ready bit.
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
	PAGE2			; select code page 2.
	call	UlCmd		; evaluate the unlocked command.
	PAGE0			; select code page 0.
	goto	DTEdone		; done evaluating.

DTEdone				; done evaluating DTMF commands.
	clrf	dtEFlag		; yes.  reset evaluate DTMF flags.
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
	bsf	PORTD,FANCTL	; yes, turn on control output.
	btfss	group2,5	; is digital output off?
	bcf	PORTD,FANCTL	; yes, turn off control output.
LoopE1
	btfsc	group4,7	; is NHRC test mode enabled?
	swapf	PORTB,f		; yep.
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
      	org	0800		; page 1

LCmd
	movlw	high LTable	; set high byte of address
	movwf	PCLATH		; select page
	movf	temp,w		; get prefix index number.
	andlw	h'07'		; restrict to reasonable range
	addwf   PCL,f		; add w to PCL

LTable				; jump table for locked commands.
	goto	LCmd0		; prefix 00 -- control operator
	goto	LCmd1		; prefix 01 -- DTMF access
	goto	LCmd2		; prefix 02 -- digital output control
	goto	LCmd3		; prefix 03 -- load saved setup
	goto	LCmd4		; prefix 04 -- remote base
	goto	LCmd5		; prefix 05 -- auxiliary input control.
	goto	LCmd6		; prefix 06 -- audio test
	goto	LCmd7		; prefix 07 -- unlock

; ***********
; ** LCmd0 **
; ***********
LCmd0				; control operator switches
	btfss	group0,7	; CTCSS required?
	goto	LCmd0x		; no.
	btfss	dtEFlag,DT0CMD	; did the command come from the main receiver?
	goto	LCmd0c1		; no.
	btfss	mscFlag,CTCSS0	; was CTCSS on?
	return			; no, do nothing quietly.
	goto	LCmd0c1		; yes.  evaluate the command.
	
LCmd0c1	
	btfss	dtEFlag,DT1CMD	; did the command come from the control RX?
	goto	LCmd0x		; no. must be the phone. process it.
	btfss	group1,4	; is the control receiver on the link port?
	goto	LCmd0x		; no, process it.
	btfss	mscFlag,CTCSS2	; was CTCSS on?
	return			; no, do nothing quietly.
	
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
	PAGE3			; select code page 3.
	call	ReadEEw		; read EEPROM.
	movwf	dtATmr		; set DTMF access mode timer.
	PAGE1			; select code page 1.
        return

LCmd10				; turn off DTMF access mode.
	movf	dtATmr,f	; check for zero.
	btfsc	STATUS,Z	; is it zero.
	return			; it is zero, do nothing.
	clrf	dtATmr		; make it zero.
        return

; ***********
; ** LCmd2 **
; ***********
LCmd2				; digital output control
	movf	cmdSize,w	; get command size
	btfsc	STATUS,Z	; skip if not zero.
	return			; fail quietly.
	movf	INDF,w		; get command digit.
	btfsc	STATUS,Z	; skip if not zero.
	goto	LCmdErr		; zero is not allowed.
	movwf	temp		; save command digit.
	sublw	d'4'		; highest value.
	btfss	STATUS,C	; skip if result is non-negative.
	goto	LCmdErr		; was bigger than 4.
	decf	temp,f		; decrement, now in 0-3 range.
	movlw	d'7'		; ctl op group of digital outputs.
	movwf	temp2		; save group # in temp 2.
	incf	FSR,f		; move to next byte (bit #)
	PAGE2			; select code page 2.
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
	PAGE3			; select page 3.
	call	LoadCtl		; load control op settings.
	PAGE1			; select code page 1.
	goto	LCmdOK
	
; ***********
; ** LCmd4 **
; ***********
LCmd4				; remote base control
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
	bcf	PORTD,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear main receiver on bit
	clrf	rx1TOut		; clear main receiver timeout timer
	PAGE3			; select code page 3.
	call	PTT1Off		; turn off TX1
	PAGE1			; select code page 1.

	movlw	VLINKOF		; get link off message
	PAGE3			; select code page 3.
	movwf	isdMsg		; save message number.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 0.
	return

LCmd41				; link alert mode.
	bsf	group3,0	; set alert bit
	bcf	group3,1	; clear receive bit
	bcf	group3,2	; clear transmit bit
	
	movlw	RXSOFF		; get new state #
	movwf	rx1Stat		; set new receiver state
	bcf	PORTD,RX1AUD	; mute it...
	bcf	txFlag,RX1OPEN	; clear main receiver on bit
	clrf	rx1TOut		; clear main receiver timeout timer
	goto	LONMsg
	
LCmd42				; link receive mode.
	bcf	group3,0	; clear alert bit
	bsf	group3,1	; set receive bit
	bcf	group3,2	; clear transmit bit
	goto	LONMsg
	
LCmd43				; link transmit mode
	bcf	group3,0	; clear alert bit
	bcf	group3,1	; clear receive bit
	bsf	group3,2	; set transmit bit
	btfsc	group1,5	; is port 2 a repeater?
	PAGE3			; select code page 3.
	call	PTT1On		; turn on TX1 PTT.
	PAGE1			; select code page 1.
LONMsg
	movlw	VLINKON 	; get link receive message
	PAGE3			; select code page 3.
	movwf	isdMsg		; save message number.
	call	PlaySpc		; play the speech message.
	PAGE1			; select code page 0.
	bsf	flags,RBMUTE	; set the muted indicator.
	bcf	PORTD,RX1AUD	; mute the remote base.
	return

; ***********
; ** LCmd5 **
; ***********
LCmd5				; Auxiliary input control.
	decfsz	cmdSize,w	; is this 1?
	return			; nope.
	movf	INDF,w		; get command digit.
	movwf	temp2		; save digit.
	btfsc 	STATUS,Z	; is it zero?
	goto	LCmd50		; yes.
	decf	temp2,f		; decrement.
	btfsc	STATUS,Z	; is it zero now?
	goto	LCmd51		; yes.
	decf	temp2,f		; decrement.
	btfsc	STATUS,Z	; is it zero now?
	goto	LCmd52		; yes.
	decf	temp2,f		; decrement.
	btfsc	STATUS,Z	; is it zero now?
	goto	LCmd53		; yes.
	return			; no.

LCmd50				; turn off auxiliary input.
	bcf	group4,0	; clear manual control bit.
	bcf	group4,1	; clear automatic control bit.
	bcf	txFlag,AUXIN	; turn off txFlag AUXIN indicator.
	bcf	PORTD,RX2AUD	; mute AUX IN audio.
	goto	LCmdOK

LCmd51				; turn on auxiliary input.
	bsf	group4,0	; set manual control bit.
	bcf	group4,1	; clear automatic control bit.
	bsf	txFlag,AUXIN	; turn on txFlag AUXIN indicator.
	bsf	PORTD,RX2AUD	; unmute AUX IN audio.
	goto	LCmdOK

LCmd52				; auxiliary input automatic mode.
	bcf	group4,0	; clear manual control bit.
	bsf	group4,1	; set automatic control bit.
	goto	LCmdOK

LCmd53				; clear alarm.
	clrf	alrmTmr		; clear alarm timer
	goto	LCmdOK

; ***********
; ** LCmd6 **
; ***********
LCmd6				; audio test...
	;; only accept audio test from main port.
	btfss	dtEFlag,DT0CMD	; was the command from DTMF-0?
	goto	LCmdErr		; nope.  error.
	movlw	VTEST		; select audio test message
	movwf	isdRMsg		; save message number.
	bsf	isdFlag,ISDRECR	; set record mode flag
	bsf	isdFlag,ISDTEST	; set audio test flag.
	goto	LCmdOK		; send OK.

; ***********
; ** LCmd7 **
; ***********
LCmd7				; unlock this port
	movf	dtEFlag,w	; get eval flags
	andlw	b'11100000'	; mask all except command source indicators.
	iorwf	dtRFlag,f	; IOR with dtRFlag: set unlocked bit.
	movlw	UNLKDLY		; get unlocked mode timer.
	movwf	unlkTmr		; set unlocked mode timer.
	movlw	CTUNLOK		; get unlocked mode courtesy tone.
	movwf	cTone		; yep. set unlocked courtesy tone.
	goto	LCmdOK		; send OK.

; *************
; ** LCmdErr **
; *************
LCmdErr
	PAGE3			; select code page 3.
	movlw	CW_NG 		; get CW OK
	call	PlayCW		; start playback
	PAGE1			; select code page 1.
	return

; ************
; ** LCmdOK **
; ************
LCmdOK
	PAGE3			; select code page 3.
	movlw	CW_OK		; get CW OK
	call	PlayCW		; start playback
	PAGE1			; select code page 1.
	return

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
        movlw   CTUNLOK		; get the unlocked courtesy tone.
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
	addwf   PCL,f		; add w to PCL
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
	PAGE3			; select page 3
	movf	temp,w		; get Item byte
	call	GetMask		; get bit mask for selected item
	PAGE2			; select page 2
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

	movf	temp2,w		; get index.
	sublw	d'7'		; check for group7
	btfsc	STATUS,Z	; is it group7?
	call	SetDig		; set the digital outputs.
			
	movlw	CW_OFF		; get CW OFF message
	PAGE3			; select code page 3.
	call	PlayCW		; send the announcement.
	PAGE2			; select code page 2.
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

	movf	temp2,w		; get index.
	sublw	d'7'		; check for group7
	btfsc	STATUS,Z	; is it group5?
	call	SetDig		; set the digital outputs.
			
	movlw	CW_ON		; get CW ON message.
	PAGE3			; select code page 3.
	call	PlayCW		; send the announcement.
	PAGE2			; select code page 2.
	return			; no.

SetDig				; set digital output pins.
	swapf	group7,w	; get group 7, swap nibbles.
	andlw	b'11110000'	; clear unneeded bits.
	movwf	temp		; save.
	movf	PORTB,w		; get PORTB bits.
	andlw	b'00001111'	; clear unneeded bits.
	iorwf	temp,w		; set bits from group 7
	movwf	PORTB		; put entire byte back to PORTB.
	movf	group6,w	; get group6.
	andlw	b'00001111'	; and pulsed outputs enabled?
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

	movlw	CW_ON		; get CW ON message.
	btfsc	STATUS,Z	; was result (from and) zero?
	movlw	CW_OFF		; get CW OFF message.
	PAGE3			; select code page 3.
	call	PlayCW		; send the announcement.
	PAGE2			; select code page 2.
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
	goto	UlCmdNG		; yes.
	movlw	d'3'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 3)
	goto	UlCmdNG		; not enough command digits.
	movf	cmdSize,w	; get command size
	sublw	d'9'		; get max command length
	btfss	STATUS,C	; skip if result is non-negative (cmdSize <= 9)
	goto	UlCmdNG		; too many command digits.

	PAGE3			; select page 3
	call	GetTens		; get index tens digit.
	PAGE2			; select page 2
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
	btfsc	PORTC,INIT	; skip if init button pressed.
	goto	UlCmdNG		; bad command.
	
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
	PAGE3			; select code page 3.
	call	WriteEE		; write the prefix.
	PAGE2			; select code page 2.
	goto	UlCmdOK		; good command...
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  *3                                                                         ;
;  Set Timers                                                                 ;
;    *3<nn> inquire timer nn                                                 ;
;    *3<nn><time> set timer nn to time                                       ;
;      00 <= nn <= 11  timer index                                            ;
;      0 <= time <= 255 timer preset. 0=disable                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UlCmd3				; program timers
	movlw	d'2'		; minimum command length
	subwf	cmdSize,w	; w = cmdSize - w
	btfss	STATUS,C	; skip if result is non-negative (cmdsize >= 2)
	goto	UlCmdNG		; not enough command digits.

	PAGE3			; select page 3
	call	GetTens		; get timer index tens digit.
	PAGE2			; select page 2
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
	PAGE3			; select page 3
	call	GetDNum		; get decimal number to w. nukes temp3,temp4
	movwf	temp4		; save decimal number to temp4.
	call	WriteEw		; write w into EEPROM.
	PAGE2			; select page 2
	movf	eeAddr,w	; get low byte of address
	sublw	EETTAIL		; subtract tail counter address
	btfss	STATUS,Z	; skip if result is zero.
	goto	UlCmd3a		; result is non-zero.
	movlw	d'1'		; one.
	movwf	tailCtr		; get tail message on next tail drop.
UlCmd3a
	goto	UlCmdOK		; good command.
	
UlCmd4				; reserved
	goto	UlCmdNG		; bad command...
	
UlCmd5				; reserved
	goto	UlCmdNG		; bad command...

UlCmd6				; reserved
	goto	UlCmdNG		; bad command...

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
	PAGE3			; select code page 3.
	call	PlayCT		; play courtesy tone #w
	PAGE2			; select code page 2.
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
	PAGE3			; select page 3
	call	GetCTen		; get 2-digit argument.
	call	PutEEB		; put into EEPROM write buffer.
	call	GetCTen		; get 2-digit argument.
	PAGE2			; select code page 2.
	movwf	temp		; save it.
	movf	cmdSize,f	; test command size.
	btfss	STATUS,Z	; any digits left?
	bsf	temp,7		; yes, set high bit of tone.
	movf	temp,w		; get temp back
	PAGE3			; select page 3
	call	PutEEB		; put into EEPROM write buffer.
	PAGE2			; select code page 2.
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
 	movlw   EECWID		; address of CW ID message in EEPROM.
        movwf   eeAddr		; save CT base address
	PAGE3			; select code page 3.
	call	PlayCWe		; kick off the CW playback.
	PAGE2			; select code page 2.
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
	movlw	EECWID		; get CW ID address...
	movwf	eeAddr		; set EEPROM address...
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
	goto	UlCmdNG		; argument error
	btfsc	group8,7	; are voice messages write protected?
	goto	UlCmdNG		; yes.
	;; 3rd digit was 1, record command
	incf	FSR,f		; increment command pointer; now at 4th digit
	decf	cmdSize,f	; decrease command size
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	UlCmdNG		; bad command.
	movf	INDF,w		; get message number.
	sublw	MAXMSG		; subtract from max message number.
	btfss	STATUS,C	; skip if result is non-negative.
	goto	UlCmdNG		; bad command.
	movf	INDF,w		; get message number.
	movwf	isdRMsg		; save message number.
	bsf	isdFlag,ISDRECR	; set record mode flag
	goto	UlCmdOK		; send OK confirmation.
	
UlCmd8P				; 3rd digit was 0, playback command
	incf	FSR,f		; increment command pointer; now at 4th digit
	decf	cmdSize,f	; decrease command size
	btfsc	STATUS,Z	; skip if result is not zero.
	goto	UlCmdNG		; bad command.
	movf	INDF,w		; get message number.
	sublw	MAXMSG		; subtract from max message number.
	btfss	STATUS,C	; skip if result is non-negative.
	goto	UlCmdNG		; bad command.
	movf	INDF,w		; get message number.
	PAGE3			; select page 3
	call	PlaySpc		; start playback
	PAGE2			; select code page 2.
	return			; don't play CW confirmation message, play ISD.
	
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
	PAGE3			; select code page 3.
	call	PlayCW		; play CW
	PAGE2			; select code page 2.
	return			; done with all this.
	
; ************************************************************************
; ****************************** ROM PAGE 3 ******************************
; ************************************************************************
      	org	1800		; page 3

; *************
; ** PlaySpc **
; *************
PlaySpc				; play a speech message, message # in w.  
	andlw	b'00000111'	; restrict message number to reasonable range. 
	movwf	isdMsg		; save message number.
	addlw	MSG0LEN		; add address of message 0.
	movwf	eeAddr		; set EEPROM address.
	call	ReadEEw		; get message length.  
	movwf	isdPTlo		; save message length.  
	clrf	isdPThi		; clear play timer hi. 
PlaySSp				; entry point for simplex playback.
	movf	isdMsg,w	; get message number.
	movwf	PORTE		; set up the ISD hardware message address.
	bsf	txFlag,TALKING	; set TALKING flag.
	call	PTT0On		; turn on tx if not on already.
	movlw	ISD_DLY		; get ISD startup delay.
	movwf	isdDly		; save ISD startup delay.
	return			; done here.
	
; ************
; ** PlayCW **
; ************
	;; play CW from ROM table.  Address in W.
PlayCW
	movwf	temp		; save CW address.
	;movf	beepCtl,w	; get beep control flag.
	;btfss	STATUS,Z	; result will be zero if no.
	;call	KillBeep	; kill off beep sequence in progress.
	movf	temp,w		; get back CW address.
	movwf	beepAddr	; set CW address.
        movlw   CW_ROM		; CW from the ROM table
        movwf   beepCtl         ; set control flags.
        call    GtBeep          ; get next character.
	movwf   cwByte		; save byte in CW bitmap
	movlw   CWIWSP		; get startup delay
	movwf   cwTmr		; preset cw timer
	bcf     tFlags,CWBEEP   ; make sure that beep is off
	bsf     txFlag,CWPLAY   ; turn on CW sender
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
        movlw   CW_EE		; select CW from EEPROM
        movwf   beepCtl         ; set control flags.
        call    GtBeep          ; get next character.
	movwf   cwByte		; save byte in CW bitmap
	movlw   CWIWSP		; get startup delay
	movwf   cwTmr		; preset cw timer
	bcf     tFlags,CWBEEP   ; make sure that beep is off
	bsf     txFlag,CWPLAY   ; turn on CW sender
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
        movlw   CW_LETR		; select CW single letter mode.
        movwf   beepCtl         ; set control flags.
	movf	temp,w		; get letter back.
	call	GetCW		; get CW bitmap.
	movwf   cwByte		; save byte in CW bitmap
	movlw   CWIWSP		; get startup delay
	movwf   cwTmr		; preset cw timer
	bcf     tFlags,CWBEEP   ; make sure that beep is off
	bsf     txFlag,CWPLAY   ; turn on CW sender
	call	PTT0On		; turn on PTT...
	return

; *************
; ** PlayCTx **
; *************
	;; play a courtesy tone from the ROM table.
	;; courtesy tone offset in W.
PlayCTx                         ; play a courtesy tone
	movwf	temp		; save the courtesy tone offset.
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; result will be zero if no.
	return			; already beeping.
	movf	temp,w		; get back courtesy tone offset.
	movwf	beepAddr	; set beep address lo byte.
        movlw   BEEP_CX         ; CT beep. (from table)
        movwf   beepCtl         ; set control flags.
        movlw   CTPAUSE         ; initial delay.
        movwf   beepTmr         ; set initial start
        bsf     txFlag,BEEPING  ; beeping is enabled!
	call	PTT0On		; turn on PTT...
        return                  ; done.

; ************
; ** PlayCT **
; ************
        ;; play courtesy tone # cTone from EEPROM.
PlayCT                          ; play a courtesy tone.
	btfsc	cTone,7		; sleazy easy check for no CT...
	return			; courtesy tone is suppressed.
	movf	beepCtl,f	; already beeping?
	btfss	STATUS,Z	; result will be zero if no.
	return			; already beeping.
        movlw   EECTB		; get CT base.
        movwf   beepAddr        ; save CT base address.

        movf    cTone,w		; examine cTone.
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

	call    ReadEEw         ; read 1 byte from EEPROM.
	movwf	temp		; save eeprom data.
	btfsc	STATUS,Z	; is it zero?
	goto	PlayCTV		; yes.
	xorlw	MAGICCT		; xor with magic CT number.
	btfss	STATUS,Z	; skip if result is zero (MAGIG number used)
	goto	PlayCT1		; play normal CT segment.

	;; this is where the morse digit send goes.
	incf	eeAddr,f	; move to next byte of CT.
	call    ReadEEw         ; read 1 byte from EEPROM.
	goto	PlayCWL		; play the CW letter
	
PlayCTV
	movlw	VCTONE		; get courtesy tone message.
	call	PlaySpc		; play the speech message.
	return			; done.
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
	clrw			; select no tone.
	call	SetTone		; set the beep tone up.
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
	btfsc	txFlag,TALKING	; don't turn off audio gate if talking.
	goto	SetBeep		; talking, don't turn off audio gate.
        clrf    beepCtl         ; clear beep control flags
        clrf    beepTmr         ; clear beep timer

SetBeep
        movf    temp,w          ; get beep tone.
	call	SetTone		; set the beep tone up.
        return

GtBeep                          ; get the next character for the beep message
	movf	beepCtl,w	; get control flag bits
	andlw	b'00000011'	; mask significant control flag bits.
	movwf	temp		; save w
	movlw	high GtBpTbl	; set page 
	movwf	PCLATH		; select page
	movf    temp,w		; get tone into w
	addwf   PCL,f		; add w to PCL
	
GtBpTbl
	goto	GtBEE		; get beep char from EEPROM
	goto	GtBROM		; get beep char from hardcoded ROM table
	goto	GtBRAM		; get beep char from RAM address
	goto	GtBLETR		; get beep for single CW letter.
	
GtBEE				; get beep char from EEPROM
        movf    beepAddr,w      ; get lo byte of EEPROM address
        movwf   eeAddr		; store to EEPROM address lo byte
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

GtBLETR				; get single CW letter.
	retlw	h'ff'		; return ff.

; ************
; ** PTT0On **
; ************
	;; turn on PTT & set up ID timer, etc., if needed.
PTT0On				; key the transmitter
	clrf	tx0CbTm		; clear chicken burst timer, tx0
	btfsc	flags,TXONFLG	; is transmitter already on?
	return			; yep.

	btfss	group5,0	; tx0 CTCSS encoder enabled?
	goto	P01NoCB		; no.
	btfss	group5,1	; tx0 chicken burst enabled?
	goto	P01NoCB		; no.
	bsf	PORTB,4		; turn on tx1 CTCSS encoder.

P01NoCB	
	;; transmitter was not already on. turn it on.
	bsf	PORTC,TX0PTT	; apply PTT!
	;; set the remote base transmitter on if enabled and is a repeater.
	btfss	group3,2	; is port 2 tx enabled?
	goto	PTTOn1		; nope.
	btfss	group1,5	; is port 2 a repeater?
	goto	PTTOn1		; nope.
	call	PTT1On		; turn on TX1 PTT
PTTOn1				; 
	bsf	flags,TXONFLG	; set last tx state flag
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
	movlw	EETID		; get address of ID timer
	movwf	eeAddr		; set address of ID timer
	call	ReadEEw		; get byte from EEPROM
	movwf   idTmr		; store to down-counter
FanOn
	btfss	group2,4	; is fan control enabled?
	return			; no.
	clrf	fanTmr		; disable fan timer, fan stays on.
	bsf	PORTD,FANCTL	; turn on fan
	return			; done here

; *************
; ** PTT0Off **
; *************
PTT0Off
	btfss	group5,0	; tx0 CTCSS encoder enabled?
	goto	P00NoCB		; no.
	btfss	group5,1	; tx0 chicken burst enabled?
	goto	P00NoCB		; no.
	movlw	CKNBRST		; get chickenburst delay.
	movwf	tx0CbTm		; set chicken burst timer, tx0.
	bcf	PORTB,4		; turn CTCSS encoder off, tx0.
	goto	P00Off1
P00NoCB
	bcf	PORTC,TX0PTT	; turn off main PTT!
P00Off1
	bcf	flags,TXONFLG	; clear last tx state flag
	call	PTT1Off		; turn off TX1.
	btfss	group2,4	; is fan control enabled?
	return			; no.
	movlw	EETFAN		; get EEPROM address of ID timer preset.
	movwf	eeAddr		; set EEPROM address low byte.
	call	ReadEEw		; read EEPROM.
	movwf	fanTmr		; set fan timer
	btfsc	STATUS,Z	; is fan timer zero?
	bcf	PORTD,FANCTL	; yes, turn off fan now.
	return

; ************
; ** PTT1On **
; ************
PTT1On
	bsf	PORTD,TX1PTT	; turn on TX1 PTT.
	clrf	tx1CbTm		; clear chicken burst timer, tx1
	btfss	group5,2	; tx1 CTCSS encoder enabled?
	return			; no.
	btfss	group5,3	; tx1 chicken burst enabled?
	return			; no.
	bsf	PORTB,5		; turn on tx1 CTCSS encoder.
	return
	
; *************
; ** PTT1Off **
; *************
PTT1Off
	btfss	group5,2	; tx1 CTCSS encoder enabled?
	goto	P10NoCB		; no.
	btfss	group5,3	; tx1 chicken burst enabled?
	goto	P10NoCB		; no.
	movlw	CKNBRST		; get chickenburst delay.
	movwf	tx1CbTm		; set chicken burst timer, tx0.
	bcf	PORTB,5		; turn CTCSS encoder off, tx0.
	goto	P10Off1
P10NoCB
	bcf	PORTD,TX1PTT	; turn off TX1 PTT.
P10Off1
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
	call	ReadEEw		; read EEPROM.
	movwf	INDF		; save read byte.
	incf	eeAddr,f	; increment EEPROM address.
	incf	FSR,f		; increment memory address.
	decfsz	eeCount,f	; decrement count of bytes to read.
	goto	ReadEEd		; loop around and read another byte.
        return                  ; read the requested bytes, return

; *************
; ** ReadEEw **
; *************
        ;; read 1 bytes from the EEPROM 
        ;; from location in eeAddr into W
ReadEEw                         ; read EEPROM.
	bcf	INTCON,GIE	; disable interrupts
	btfsc	INTCON,GIE	; interrupts successfully disabled?
	goto	ReadEEw		; no,  try again.
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
	call	WriteEw		; write the byte.
        incf    FSR,f           ; increment RAM address in FSR.
	incf	eeAddr,f	; increment EEPROM address.
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
	PAGE2			; select code page 2.
	call	SetDig		; set digital I/O up.
	PAGE3			; select code page 3.
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
GetDN1  ;; get ones digit
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


; ******************************
; ** ROM Table Fetches follow **
; ******************************

	org	h'1c00'
; ***********
; ** GetCW **
; ***********
        ;; get a cw bitmask from a phone pad letter number.
GetCW				; get tone byte from table
	movwf	temp		; save w
	movlw	high CWTbl	; set page 
	movwf	PCLATH		; select page
	bcf	temp,7		; force into 0-127 range for safety.
	movf    temp,w		; get tone into w
	addwf   PCL,f		; add w to PCL
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

	
	org	h'1d00'
InitDat
	movwf	temp		; save addr.
	movlw	high InitTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	addwf   PCL,f		; add w to PCL
InitTbl
	;; timer initial defaults
	retlw   d'100'		; 0000 hang timer long 10.0 sec
	retlw	d'50'		; 0001 hang timer short 5.0 sec
	retlw	d'54'		; 0002 ID timer 9.0 min
	retlw	d'60'		; 0003 DTMF access timer 60 sec
	retlw	d'180'		; 0004 timeout timer long 180 sec
	retlw	d'30'		; 0005 timeout timer short 30 sec
	retlw	d'12'		; 0006 fan timer 120 sec
	retlw	d'6'		; 0007 alarm interval timer 60 sec
	retlw	d'0'		; 0008 tail message counter - units
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
	retlw	h'05'		; 0070 CW ID  1 'N'
	retlw	h'10'		; 0071 CW ID  2 'H'
	retlw	h'0a'		; 0072 CW ID  3 'R'
	retlw	h'15'		; 0073 CW ID  4 'C'
	retlw	h'00'		; 0074 CW ID  5 ' '
	retlw	h'20'		; 0075 CW ID  6 '5'
	retlw	h'ff'		; 0076 CW ID  7 eom
	retlw	h'ff'		; 0077 CW ID  8 eom
	retlw	h'ff'		; 0078 CW ID  9 eom
	retlw	h'ff'		; 0079 CW ID 10 eom
	retlw	h'ff'		; 007a CW ID 11 eom
	retlw	h'ff'		; 007b CW ID 12 eom
	retlw	h'ff'		; 007c CW ID 13 eom
	retlw	h'ff'		; 007d CW ID 14 eom
	retlw	h'ff'		; 007e CW ID 15 eom
	retlw	h'ff'		; 007f CW ID 16 eom
	
	;; control prefixes
	retlw	h'00'		; 0080 control prefix 0  00
	retlw	h'00'		; 0081 control prefix 0  01
	retlw	h'ff'		; 0082 control prefix 0  02
	retlw	h'ff'		; 0083 control prefix 0  03
	retlw	h'ff'		; 0084 control prefix 0  04
	retlw	h'ff'		; 0085 control prefix 0  05
	retlw	h'ff'		; 0086 control prefix 0  06
	retlw	h'ff'		; 0087 control prefix 0  07
	retlw	h'00'		; 0088 control prefix 1  00
	retlw	h'01'		; 0089 control prefix 1  01
	retlw	h'ff'		; 008a control prefix 1  02
	retlw	h'ff'		; 008b control prefix 1  03
	retlw	h'ff'		; 008c control prefix 1  04
	retlw	h'ff'		; 008d control prefix 1  05
	retlw	h'ff'		; 008e control prefix 1  06
	retlw	h'ff'		; 008f control prefix 1  07
	retlw	h'00'		; 0090 control prefix 2  00
	retlw	h'02'		; 0091 control prefix 2  01
	retlw	h'ff'		; 0092 control prefix 2  02
	retlw	h'ff'		; 0093 control prefix 2  03
	retlw	h'ff'		; 0094 control prefix 2  04
	retlw	h'ff'		; 0095 control prefix 2  05
	retlw	h'ff'		; 0096 control prefix 2  06
	retlw	h'ff'		; 0097 control prefix 2  07
	retlw	h'00'		; 0098 control prefix 3  00
	retlw	h'03'		; 0099 control prefix 3  01
	retlw	h'ff'		; 009a control prefix 3  02
	retlw	h'ff'		; 009b control prefix 3  03
	retlw	h'ff'		; 009c control prefix 3  04
	retlw	h'ff'		; 009d control prefix 3  05
	retlw	h'ff'		; 009e control prefix 3  06
	retlw	h'ff'		; 009f control prefix 3  07
	retlw	h'00'		; 00a0 control prefix 4  00
	retlw	h'04'		; 00a1 control prefix 4  01
	retlw	h'ff'		; 00a2 control prefix 4  02
	retlw	h'ff'		; 00a3 control prefix 4  03
	retlw	h'ff'		; 00a4 control prefix 4  04
	retlw	h'ff'		; 00a5 control prefix 4  05
	retlw	h'ff'		; 00a6 control prefix 4  06
	retlw	h'ff'		; 00a7 control prefix 4  07
	retlw	h'00'		; 00a8 control prefix 5  00
	retlw	h'05'		; 00a9 control prefix 5  01
	retlw	h'ff'		; 00aa control prefix 5  02
	retlw	h'ff'		; 00ab control prefix 5  03
	retlw	h'ff'		; 00ac control prefix 5  04
	retlw	h'ff'		; 00ad control prefix 5  05
	retlw	h'ff'		; 00ae control prefix 5  06
	retlw	h'ff'		; 00af control prefix 5  07
	retlw	h'00'		; 00b0 control prefix 6  00
	retlw	h'06'		; 00b1 control prefix 6  01
	retlw	h'ff'		; 00b2 control prefix 6  02
	retlw	h'ff'		; 00b3 control prefix 6  03
	retlw	h'ff'		; 00b4 control prefix 6  04
	retlw	h'ff'		; 00b5 control prefix 6  05
	retlw	h'ff'		; 00b6 control prefix 6  06
	retlw	h'ff'		; 00b7 control prefix 6  07
	retlw	h'00'		; 00b8 control prefix 7  00
	retlw	h'07'		; 00b9 control prefix 7  01
	retlw	h'ff'		; 00ba control prefix 7  02
	retlw	h'ff'		; 00bb control prefix 7  03
	retlw	h'ff'		; 00bc control prefix 7  04
	retlw	h'ff'		; 00bd control prefix 7  05
	retlw	h'ff'		; 00be control prefix 7  06
	retlw	h'ff'		; 00bf control prefix 7  07
	retlw	h'01'		; 00c0 ISD message 0 length, tenths.
	retlw	h'01'		; 00c1 ISD message 1 length, tenths.
	retlw	h'01'		; 00c2 ISD message 2 length, tenths.
	retlw	h'01'		; 00c3 ISD message 3 length, tenths.
	retlw	h'01'		; 00c4 ISD message 4 length, tenths.
	retlw	h'01'		; 00c5 ISD message 5 length, tenths.
	retlw	h'01'		; 00c6 ISD message 6 length, tenths.
	retlw	h'01'		; 00c7 ISD message 7 length, tenths.
	retlw	h'00'		; 00c8 spare
	retlw	h'00'		; 00c9 spare
	retlw	h'00'		; 00ca spare
	retlw	h'00'		; 00cb spare
	retlw	h'00'		; 00cc spare
	retlw	h'00'		; 00cd spare
	retlw	h'00'		; 00ce spare
	retlw	h'00'		; 00cf spare

        org     1e00        

; *************
; ** GetMask **
; *************
        ;; get the bitmask of the selected numbered bit.
GetMask				; get mask of selected bit number.
	movwf	temp		; store 
	movlw	high BitTbl	; set page 
	movwf	PCLATH		; select page
	movf    temp,w		; get selected bit number into w
	andlw	h'07'		; force into valid range
	addwf   PCL,f		; add w to PCL
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
        ;; get the number of tens in INDF. return in w.
Get100s				; get tone byte from table
	movlw	high HundTbl	; set page 
	movwf	PCLATH		; select page
	movf    INDF,w		; get tone into w
	andlw	h'03'		; force into valid range
	addwf   PCL,f		; add w to PCL
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
	movf    INDF,w		; get tone into w
	andlw	h'0f'		; force into valid range
	addwf   PCL,f		; add w to PCL
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
	bsf	T1CON, TMR1ON	; turn on timer 1.  Start beeping.
	return			; done.

StopTone			; stop the racket!
	bcf	T1CON, TMR1ON	; turn off timer 1.
	return
	
; **************
; ** GetToneL **
; **************
        ;; get high byte for compare for tone.
        ;; tone 1f is NO tone (off).
GetToneL			; get tone hi byte from table
	movlw	high TnTblL	; set page 
	movwf	PCLATH		; select page
	movf    temp,w		; get tone into w
	andlw	h'1f'		; force into valid range
	addwf   PCL,f		; add w to PCL
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
	movf    temp,w		; get tone into w
	andlw	h'1f'		; force into valid range
	addwf   PCL,f		; add w to PCL
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

; **************
; ** MesgTabl **
; **************
	;; play canned messages from ROM
	;; byte offset is index param in w.
	;; returns specified byte in w.
MesgTabl                        ; canned messages table (CW, beeps, DTMF, whatever)
	movwf	temp		; save addr.
	movlw	high MsgTbl	; set page
	movwf	PCLATH		; select page
	movf	temp,w		; get address back
	andlw	h'3f'		; restrict to reasonable range
	addwf   PCL,f		; add w to PCL
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
        retlw   h'ff'           ; EOM     -- 09
	retlw	h'05'		; 'N'     -- 0a
	retlw	h'10'		; 'H'     -- 0b
	retlw	h'0a'		; 'R'     -- 0c
	retlw	h'15'		; 'C'     -- 0d
	retlw	h'00'		; ' '     -- 0e
	retlw	h'20'		; '5'     -- 0f
	retlw	h'ff'		; EOM     -- 10
        retlw	h'0f'           ; 'O'     -- 11
	retlw	h'05'           ; 'N'     -- 12
        retlw   h'ff'           ; EOM     -- 13
        retlw   h'0f'           ; 'O'     -- 14
        retlw   h'14'           ; 'F'     -- 15
        retlw   h'14'           ; 'F'     -- 16
	retlw	h'ff'		; EOM     -- 17
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
	addwf   PCL,f		; add w to PCL
DtTbl
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
	
        org     1f00        

	FILL 0x3ff,0x0100	; reserve this block for the ICD.
	
	IF LOAD_EE == 1	
	org	2100h
	de	d'100'		; 0000 hang timer long 10.0 sec
	de	d'50'		; 0001 hang timer short 5.0 sec
	de	d'54'		; 0002 ID timer 9.0 min
	de	d'60'		; 0003 DTMF access timer 60 sec
	de	d'180'		; 0004 timeout timer long 180 sec
	de	d'30'		; 0005 timeout timer short 30 sec
	de	d'12'		; 0006 fan timer 120 sec
	de	d'6'		; 0007 alarm interval timer 60 sec.
	de	d'0'		; 0008 tail message counter - units
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
	de	h'05'		; 0070 CW ID  1 'n'
	de	h'10'		; 0071 CW ID  2 'h'
	de	h'0a'		; 0072 CW ID  3 'r'
	de	h'15'		; 0073 CW ID  4 'c'
	de	h'00'		; 0074 CW ID  5 ' '
	de	h'20'		; 0075 CW ID  6 '5'
	de	h'ff'		; 0076 CW ID  7 eom
	de	h'ff'		; 0077 CW ID  8 eom
	de	h'ff'		; 0078 CW ID  9 eom
	de	h'ff'		; 0079 CW ID 10 eom
	de	h'ff'		; 007a CW ID 11 eom
	de	h'ff'		; 007b CW ID 12 eom
	de	h'ff'		; 007c CW ID 13 eom
	de	h'ff'		; 007d CW ID 14 eom
	de	h'ff'		; 007e CW ID 15 eom
	de	h'ff'		; 007f CW ID 16 eom
	
	;; control prefixes
	de	h'00'		; 0080 control prefix 0  00
	de	h'00'		; 0081 control prefix 0  01
	de	h'ff'		; 0082 control prefix 0  02
	de	h'ff'		; 0083 control prefix 0  03
	de	h'ff'		; 0084 control prefix 0  04
	de	h'ff'		; 0085 control prefix 0  05
	de	h'ff'		; 0086 control prefix 0  06
	de	h'ff'		; 0087 control prefix 0  07
	de	h'00'		; 0088 control prefix 1  00
	de	h'01'		; 0089 control prefix 1  01
	de	h'ff'		; 008a control prefix 1  02
	de	h'ff'		; 008b control prefix 1  03
	de	h'ff'		; 008c control prefix 1  04
	de	h'ff'		; 008d control prefix 1  05
	de	h'ff'		; 008e control prefix 1  06
	de	h'ff'		; 008f control prefix 1  07
	de	h'00'		; 0090 control prefix 2  00
	de	h'02'		; 0091 control prefix 2  01
	de	h'ff'		; 0092 control prefix 2  02
	de	h'ff'		; 0093 control prefix 2  03
	de	h'ff'		; 0094 control prefix 2  04
	de	h'ff'		; 0095 control prefix 2  05
	de	h'ff'		; 0096 control prefix 2  06
	de	h'ff'		; 0097 control prefix 2  07
	de	h'00'		; 0098 control prefix 3  00
	de	h'03'		; 0099 control prefix 3  01
	de	h'ff'		; 009a control prefix 3  02
	de	h'ff'		; 009b control prefix 3  03
	de	h'ff'		; 009c control prefix 3  04
	de	h'ff'		; 009d control prefix 3  05
	de	h'ff'		; 009e control prefix 3  06
	de	h'ff'		; 009f control prefix 3  07
	de	h'00'		; 00a0 control prefix 4  00
	de	h'04'		; 00a1 control prefix 4  01
	de	h'ff'		; 00a2 control prefix 4  02
	de	h'ff'		; 00a3 control prefix 4  03
	de	h'ff'		; 00a4 control prefix 4  04
	de	h'ff'		; 00a5 control prefix 4  05
	de	h'ff'		; 00a6 control prefix 4  06
	de	h'ff'		; 00a7 control prefix 4  07
	de	h'00'		; 00a8 control prefix 5  00
	de	h'05'		; 00a9 control prefix 5  01
	de	h'ff'		; 00aa control prefix 5  02
	de	h'ff'		; 00ab control prefix 5  03
	de	h'ff'		; 00ac control prefix 5  04
	de	h'ff'		; 00ad control prefix 5  05
	de	h'ff'		; 00ae control prefix 5  06
	de	h'ff'		; 00af control prefix 5  07
	de	h'00'		; 00b0 control prefix 6  00
	de	h'06'		; 00b1 control prefix 6  01
	de	h'ff'		; 00b2 control prefix 6  02
	de	h'ff'		; 00b3 control prefix 6  03
	de	h'ff'		; 00b4 control prefix 6  04
	de	h'ff'		; 00b5 control prefix 6  05
	de	h'ff'		; 00b6 control prefix 6  06
	de	h'ff'		; 00b7 control prefix 6  07
	de	h'00'		; 00b8 control prefix 7  00
	de	h'07'		; 00b9 control prefix 7  01
	de	h'ff'		; 00ba control prefix 7  02
	de	h'ff'		; 00bb control prefix 7  03
	de	h'ff'		; 00bc control prefix 7  04
	de	h'ff'		; 00bd control prefix 7  05
	de	h'ff'		; 00be control prefix 7  06
	de	h'ff'		; 00bf control prefix 7  07
	de	d'50'		; 00c0 ISD message 0 length, tenths.
	de	d'50'		; 00c1 ISD message 1 length, tenths.
	de	d'50'		; 00c2 ISD message 2 length, tenths.
	de	d'50'		; 00c3 ISD message 3 length, tenths.
	de	d'50'		; 00c4 ISD message 4 length, tenths.
	de	d'50'		; 00c5 ISD message 5 length, tenths.
	de	d'50'		; 00c6 ISD message 6 length, tenths.
	de	d'50'		; 00c7 ISD message 7 length, tenths.
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
; 0 = dit, 1 = dah.  the byte is shifted out to the right, until only 
; a 1 remains.  characters with more than 7 elements (error) cannot be sent.
;
; a .-      00000110  06                 ; 0 -----   00111111  3f
; b -...    00010001  11		 ; 1 .----   00111110  3e
; c -.-.    00010101  15		 ; 2 ..---   00111100  3c
; d -..     00001001  09		 ; 3 ...--   00111000  38
; e .       00000010  02		 ; 4 ....-   00110000  30
; f ..-.    00010100  14		 ; 5 .....   00100000  20
; g --.     00001011  0b		 ; 6 -....   00100001  21
; h ....    00010000  10		 ; 7 --...   00100011  23
; i ..      00000100  04		 ; 8 ---..   00100111  27
; j .---    00011110  1e		 ; 9 ----.   00101111  2f
; k -.-     00001101  0d		                         
; l .-..    00010010  12		 ; sk ...-.- 01101000  58
; m --      00000111  07		 ; ar .-.-.  00101010  2a
; n -.      00000101  05		 ; bt -...-  00110001  31
; o ---     00001111  0f		 ; / -..-.   00101001  29
; p .--.    00010110  16		                         
; q --.-    00011011  1b		 ; space     00000000  00
; r .-.     00001010  0a		 ; EOM       11111111  ff
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
	
