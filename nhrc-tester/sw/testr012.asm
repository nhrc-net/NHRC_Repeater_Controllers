;*******************************************************************************
; NHRC-Tester Repeater Controller Tester
; Copyright (C) 2002, 2003. 2004 Jeffrey B. Otterson and NHRC LLC.
; All Rights Reserved.
;*******************************************************************************
; This software contains proprietary and confidential trade secrets of NHRC LLC.
; It may not be distributed in any source or binary form without the express
; written permission of NHRC LLC.
;*******************************************************************************
VERSION EQU D'012'

; Set the DEBUG symbol to 1 to really speed up the software's internal clocks
; and timers for debugging in the simulator. Normally this is a 0.
DEBUG   EQU     0

        ;; SPSW is set to 0 for button, 1 for switch on half-duplex control.
SPSW    equ     1

        LIST P=16F628, F=INHX8M, R=HEX
        include "p16f628.inc"
	;; __FUSES _CP_ALL & _INTRC_OSC_NOCLKOUT & _WDT_ON & _LVP_OFF & _MCLRE_OFF & _PWRTE_ON
	__FUSES _CP_ALL & _INTRC_OSC_CLKOUT & _WDT_ON & _LVP_OFF & _PWRTE_ON
	ERRORLEVEL 0, -302	; suppress Argument out of range errors
;
; Real Time Interrupt info
; real time is counted by setting the TICK bit every 100 ms in the
; interrupt handler.
;
;     1 s
; -----------  = .00000025 sec per cycle
; 4,000,000 hz
;
; processor clock is 4 * above = .000001 sec (1 us) instruction cycle
; timer prescale of 4.
; count to 250 for 1 ms tick.

;PORTA
TP1	equ	0		; spare
PL_LED	equ	1		; PL enabled LED, output
COR_LED	equ	2		; COR enabled LED, output
S_CTCSS	equ	3		; PL detect to controller, output
S_COR	equ	4		; COR detect to controller, output

;PORTB
MICGATE	equ     0		; mic gate
PNKGATE equ     1		; pink noise gate
RPTGATE	equ	2		; speaker audio gate
TP2 	equ	3		; test point
MIC_PTT	equ	4		; mic ptt button, input
MICCHAN equ	5		; mic channel button, input
RPT_PTT equ	6		; repeater controller ptt, input
BUTTON	equ	7		; test set pushbutton, input

;flags
F_COR   equ     0		; COR selected on mic PTT.
F_CTCSS equ     1		; CTCSS selected on mic PTT.
F_CLEAR	equ     2		; keep this bit clear for incf hack to work
F_TXMUT equ     3		; TX mute control

		;; bits 4-7 are the debounced versions of the PORTB inputs.
	
;tFlags				; timer flags
TICK    equ     0		; 1 ms tick indicator flag
T1MS    equ     1		; 1 ms tick flag
T10MS   equ     2		; 10 ms tick flag
T100MS  equ     3		; 100 ms tick flag

	IF DEBUG == 1
TEN     equ     D'2'
	ELSE
TEN     equ     D'10'
	ENDIF

T0PRE	equ     D'13'		; 14 gave 1003 hz.

CDBBIT  equ     3		; debounce counts to 32, about 18.2 ms
CDBVAL	equ	8

PLPRE	equ	d'150'		; PL startup timer
CRSHPRE	equ	d'150'		; PL squelch crash timer

LEDPRE	equ	d'100'		; PL & COR LED delay timer, 10ms * 100 = 1000 ms.
	
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
	tFlags			; 23 Timer Flags
	flags			; 24 operating Flags
	onems			; 25 1 ms counter
	tenms			; 26 10 ms counter
	hundms			; 27 100 ms counter
	dbcButn			; 28 button debouncer timer.
	dbcMPtt			; 29 mic PTT button debouncer.
	dbcMChn			; 2a mic channel button debouncer.
	dbcCPtt			; 2b controller PTT debouncer.
	temp			; 2c temp value, use & abuse
        crshTmr                 ; 2d squelch crash timer (PL release delay)
        plTmr                   ; 2e PL timer (PL assert delay)
	ledTmr			; 2f PL & COR LED delay timer.
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
	movlw	T0PRE		; get timer 0 preset value
	movwf	TMR0		; preset timer 0
        bsf     tFlags,TICK     ; set tick indicator flag
	bcf     INTCON,T0IF     ; clear RTCC int mask

IntExit
	pop			; restore W and STATUS
	retfie

Start
	movlw	b'00011000'	; preset value
	movwf	PORTA		; preset port A
	movlw	b'00000010'	; preset value
	movwf	PORTB		; preset port B
	
	movlw	h'07'		; turn off all comparators
	movwf	CMCON

	bsf     STATUS,RP0      ; select bank 1
	movlw   b'00000000'     ; RA0..4 are outputs
	movwf   TRISA		; set port port directions
	movlw   b'11110000'     ; RB7..4 are inputs
	movwf   TRISB

	IF DEBUG == 1
	movlw   b'10001000'     ; DEBUG! no pull up, timer 0 gets no prescale
	ELSE
	movlw   b'10000001'     ; no pull up, timer 0 gets prescale 4
	ENDIF

	movwf   OPTION_REG      ; set options

	bcf     STATUS,RP0      ; select page 0
	
	clrf	flags		; reset all operational flags
        clrf    tFlags          ; reset all timing flags

	movlw   TEN		; preset decade counters
	movwf   onems 		; 1 ms down counter
	movwf   tenms		; 10 ms down counter
	movwf   hundms		; 100 ms down counter

	clrf	dbcButn		; init button debouncer timer.
	clrf	dbcMPtt		; init mic PTT button debouncer.
	clrf	dbcMChn		; init mic channel button debouncer.
	clrf	dbcCPtt		; init controller PTT debouncer.

	clrf	crshTmr		; clear PL deassert timer.
	clrf	plTmr		; clear PL assert timer.
	clrf	ledTmr		; clear PL & COR LED timer.

	bsf	flags,F_COR	; set initial mode for COR.
        bsf	PORTB,PNKGATE	; turn on white noise
	bsf	PORTA,S_COR	; turn off COR output (negative logic)
	bsf	PORTA,S_CTCSS	; turn off CTCSS output (negative logic)
	movlw   b'10100000'     ; enable interrupts, & Timer 0 overflow
	movwf   INTCON

Loop				; start of main loop
	clrwdt			; reset the watchdog timer
	movlw   b'11110001'     ; set timer flags mask
	andwf   tFlags,f	; clear timer flags
	btfss   tFlags,TICK     ; check to see if a tick has happened
	goto    Loop1		; nope...

	;
	; 1 ms tick has occurred...
	;
	bcf     tFlags,TICK     ; reset tick flag
	bsf     tFlags,T1MS     ; set 1ms flag
	decfsz  onems,f		; decrement 1 ms counter
	goto    Loop1		; not zero (not 10 ms interval)

	;
	; 10 ms tick has occurred...
	;
	movlw   TEN		; preset decade counter
	movwf   onems		; preset decade counter
	bsf     tFlags,T10MS	; set 10 ms flag
	decfsz  tenms,f		; decrement 10 ms counter
	goto    Loop1		; not zero (not 100 ms interval)

	;
	; 100 ms tick has occurred...
	;
	movlw   TEN		; preset decade counter
	movwf   tenms		; preset decade counter
	bsf     tFlags,T100MS   ; set 100 ms flag
	decfsz	hundms,f	; decrement 100 ms counter
	goto	Loop1		; not zero (not 1 sec interval)

	;
	; 1 s tick has occurred...
	;
	movlw   TEN		; preset decade counter
	movwf   hundms		; preset decade counter
	bsf     tFlags,T100MS   ; set 100 ms flag

; *****************************************************************************
; *****************************************************************************
; ***   MAIN LOOP STARTS HERE...                                            ***
; *****************************************************************************
; *****************************************************************************

Loop1
	;; LED BLINKER!!!  I'M ALIVE!!!  I'M ALIVE!!!
        btfss   tFlags,T100MS
        goto    LedEnd
        btfss   PORTA,TP1
        goto    l3off
	bcf	PORTA,TP1
        goto    LedEnd
l3off 
	bsf	PORTA,TP1
LedEnd

	btfss	tFlags,T1MS	; is 1ms flag set?
	goto	T1End  		; nope.
	;; 1 ms debouncer timer check...

ChkMPtt				; debounce mike PTT button.
	btfss	PORTB,MIC_PTT	; mic ptt button
	goto	NoMPtt		; no mic PTT
	btfsc	dbcMPtt,CDBBIT	; check for full...
	goto	ChkMChn		; already full.
	incf	dbcMPtt,f	; increment the debounce counter.
	btfss	dbcMPtt,CDBBIT	; check for full, now...
	goto	ChkMChn		; not full yet.
	btfsc	flags,MIC_PTT	; already set on?
	goto	ChkMChn		; yes.
	bsf	flags,MIC_PTT	; no, set mic ptt flag bit.
	;;  Mic PTT state transition, 0->1
	btfss	flags,F_COR	; is COR mode is enabled?
	goto	PNoCOR		; nope
	bcf	PORTA,S_COR	; set COR output. (negative logic)
	bsf	PORTA,COR_LED	; turn on COR LED.
PNoCOR
	btfss	flags,F_CTCSS	; is PL mode enabled?
	goto	MPtt11		; no.
	movlw	PLPRE		; get PL startup timer.
	movwf	plTmr		; set PL startup timer
MPtt11
        bcf	PORTB,PNKGATE	; turn off white noise
	bsf	PORTB,MICGATE	; turn on mic audio
        clrf	crshTmr		; reset squelch crash timer.
	btfsc	flags,F_TXMUT	; is TX MUTE enabled?
	BCF	PORTB,RPTGATE	; yes, mute controller TX audio.
	goto	ChkMChn		; done with off->on transition. 

NoMPtt				; mic PTT NOT PRESSED.
	movf	dbcMPtt,f	; test.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkMChn		; yes.
	decfsz	dbcMPtt,f	; no, decrement it.
	goto	ChkMChn		; still not zero yet.
	btfss	flags,MIC_PTT	; already set on?
	goto	ChkMChn		; no.
	bcf	flags,MIC_PTT	; yes, clear mic ptt flag bit.
	;; mic PTT state transition, 1->0
	btfss	flags,F_COR	; is COR mode is enabled?
	goto	PoNoCOR		; no.
	bsf	PORTA,S_COR	; yes, clear COR output. (negative logic)
	bcf	PORTA,COR_LED	; turn off COR LED.
PoNoCOR
	btfss	flags,F_CTCSS	; is PL mode enabled?
	goto	MPtt01		; no.
	movlw	CRSHPRE		; get squelch crash timer.
	movwf	crshTmr		; set squelch crash timer.
MPtt01
	clrf	plTmr		; clear pl startup timer
        bsf	PORTB,PNKGATE	; turn on white noise
	bcf	PORTB,MICGATE	; turn off mic audio

	btfss	flags,F_TXMUT	; is TX mute flag set?
	goto	ChkMChn		; no.
	btfsc	flags,RPT_PTT	; controller PTT asserted?
	bsf	PORTB,RPTGATE	; turn on controller tx audio.
	
ChkMChn				; debounce mike channel button.
	btfss	PORTB,MICCHAN	; mic channel button
	goto	NoMChn		; no mic channel
	btfsc	dbcMChn,CDBBIT	; check for full...
	goto	ChkCPtt		; already full.
	incf	dbcMChn,f	; increment the debounce counter.
	btfss	dbcMChn,CDBBIT	; check for full, now...
	goto	ChkCPtt		; not full yet.
	btfsc	flags,MICCHAN	; already set on?
	goto	ChkCPtt		; yes.
	bsf	flags,MICCHAN	; no, set mic ptt flag bit.
	;; mike channel button state transition, 0->1
	;; mike channel button was pressed.
	;movf	ledTmr,f	; get ledTmr
	;btfsc	STATUS,Z	; is ledTmr zero?
	;goto	MChn0		; yes.
	bcf	flags,F_CLEAR	; keep this bit clear.
	incf	flags,f		; increment flags.
	bcf	flags,F_CLEAR	; keep this bit clear.
	;movlw	b'00000011'	; mask
	;andwf	flags,w		; and it
	;btfsc	STATUS,Z	; is it zero?
	;bsf	flags,F_COR	; yes. zero is not permitted.

MChn0
	movlw	LEDPRE		; get ledTmr preset
	movwf	ledTmr		; set ledTmr

	;; now show COR & PL status on LEDs.
	btfss	flags,F_COR	; is COR mode set?
	bcf	PORTA,COR_LED	; no. turn off COR led.

	btfsc	flags,F_COR	; is COR mode set?
	bsf	PORTA,COR_LED	; yes. turn on COR led.

	btfss	flags,F_CTCSS	; is CTCSS mode set?
	bcf	PORTA,PL_LED	; no. turn off CTCSS led.

	btfsc	flags,F_CTCSS	; is CTCSS mode set?
	bsf	PORTA,PL_LED	; yes. turn on CTCSS led.
	
	goto	ChkCPtt		; done with off->on transition. 

NoMChn				; mic channel NOT PRESSED.
	movf	dbcMChn,f	; test.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkCPtt		; yes.
	decfsz	dbcMChn,f	; no, decrement it.
	goto	ChkCPtt		; still not zero yet.
	btfss	flags,MICCHAN	; already set on?
	goto	ChkCPtt		; no.
	bcf	flags,MICCHAN	; yes, clear mic ptt flag bit.
	;; mike channel button state transition, 1->0

ChkCPtt				; debounce Controller PTT
	btfss	PORTB,RPT_PTT	; mic ptt button
	goto	NoCPtt		; no mic PTT
	btfsc	dbcCPtt,CDBBIT	; check for full...
	goto	ChkButn		; already full.
	incf	dbcCPtt,f	; increment the debounce counter.
	btfss	dbcCPtt,CDBBIT	; check for full, now...
	goto	ChkButn		; not full yet.
	btfsc	flags,RPT_PTT	; already set on?
	goto	ChkButn		; yes.
	bsf	flags,RPT_PTT	; no, set mic ptt flag bit.
	;; controller PTT state transition, 0->1
	;; deal with simplex emulation (TX MUTE)
	btfss	flags,F_TXMUT	; is TX Mute flag set?
	goto	CPtt1		; no
	btfss	flags,MIC_PTT	; is Mike PTT pressed?
	goto	CPtt1		; no.
	goto	ChkButn		; TX mute is set.  don't send audio.
	
CPtt1
	bsf	PORTB,RPTGATE	; turn on speaker audio gate
	goto	ChkButn		; done with off->on transition. 

NoCPtt				; controller PTT not asserted.
	movf	dbcCPtt,f	; test.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkButn		; yes.
	decfsz	dbcCPtt,f	; no, decrement it.
	goto	ChkButn		; still not zero yet.
	btfss	flags,RPT_PTT	; already set on?
	goto	ChkButn		; no.
	bcf	flags,RPT_PTT	; yes, clear mic ptt flag bit.
	;; controller PTT state transition, 1->0
	bcf	PORTB,RPTGATE	; turn off speaker audio gate

ChkButn				; check control button.
	btfsc	PORTB,BUTTON	; tester button
	goto	NoButn		; button not pressed.
        IF SPSW == 0            ; button, not switch
	btfsc	dbcButn,CDBBIT	; check for full...
	goto	ChkDone		; already full.
	incf	dbcButn,f	; increment the debounce counter.
	btfss	dbcButn,CDBBIT	; check for full, now...
	goto	ChkDone		; not full yet.
	btfsc	flags,BUTTON	; already set on?
	goto	ChkDone		; yes.
	bsf	flags,BUTTON 	; no, set button pressed flag bit.
	;; tester control button state transition, 0->1
	btfss	flags,F_TXMUT	; is TX mute flag set?
	goto	TXM0		; no.
	bcf	flags,F_TXMUT	; clear it.
	goto	ChkDone		; done
TXM0				; TX mute bit is not set
        ENDIF
	bsf	flags,F_TXMUT	; turn on half-duplex mode.
	goto	ChkDone		; done.

NoButn				; tester button not pressed.
        IF SPSW == 0            ; button, not switch
	movf	dbcButn,f	; test.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkDone		; yes.
	decfsz	dbcButn,f	; no, decrement it.
	goto	ChkDone		; still not zero yet.
	btfss	flags,BUTTON	; already set on?
	goto	ChkDone		; no.
	bcf	flags,BUTTON 	; yes, clear button pressed bit.
	;; tester control button state transition, 1->0
        ELSE
	bcf	flags,F_TXMUT	; turn off half-duplex mode.
        ENDIF
	
ChkDone				; done checking/debouncing inputs.

	movf	crshTmr,f	; check squelch crash timer.
	btfsc	STATUS,Z	; is it zero?
	goto	ChkPlT		; yes.
	decfsz	crshTmr,f	; decrement timer.
	goto	ChkPlT		; not zero yet.
	bsf	PORTA,S_CTCSS	; turn off CTCSS output. (negative logic)
	bcf	PORTA,PL_LED	; turn off status LED led.

ChkPlT
	movf	plTmr,f		; check pl startup timer.
	btfsc	STATUS,Z	; is it zero?
	goto	TTDone		; yes.
	decfsz	plTmr,f		; decrement timer.
	goto	TTDone		; not zero yet.
	bcf	PORTA,S_CTCSS	; turn on CTCSS output. (negative logic)
	bsf	PORTA,PL_LED	; turn on status LED led.

TTDone	

T1End				; end of 1 mS tasks.
	btfss   tFlags,T10MS	; 10 ms tick?
	goto	T10End		; no

	movf	ledTmr,f	; get ledTmr
	btfsc	STATUS,Z	; is ledTmr zero?
	goto	LtEnd		; yes
	decfsz	ledTmr,f	; decrement ledTmr
	goto	LtEnd		; not zero yet.

	btfsc	PORTA,S_COR	; is COR set?
	bcf	PORTA,COR_LED	; no. turn off COR led.

	btfss	PORTA,S_COR	; is COR mode set?
	bsf	PORTA,COR_LED	; yes. turn on COR led.

	btfsc	PORTA,S_CTCSS	; is CTCSS mode set?
	bcf	PORTA,PL_LED	; no. turn off CTCSS led.

	btfss	PORTA,S_CTCSS	; is CTCSS mode set?
	bsf	PORTA,PL_LED	; yes. turn on CTCSS led.

LtEnd
T10End				; end of 10 mS tasks.
	
	goto	Loop		; back to the top.
	end			; "end of line".







