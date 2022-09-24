	;; NHRC-Squelch Advanced Repeater Controller.
	;; Copyright 1999 NHRC LLC, as an unpublished proprietary work.
	;; All Rights Reserved.
	;; No part of this document may be used or reproduced by any means,
	;; for any purpose, without the expressed written consent of NHRC LLC.

	;; sql-006 16 March 2000
	
        LIST P=12c671, R=HEX
        include "p12c671.inc"
        __FUSES _CP_ALL & _INTRC_OSC_NOCLKOUT & _PWRTE_ON & _WDT_ON & _MCLRE_OFF
;        ERRORLEVEL 0, -302      ;suppress argument out of range errors

; RUS delay constants for various noise modes.
DLY_1	equ	d'40'		; 400 ms   very   noisy delay.
DLY_2	equ	d'20'		; 200 ms somewhat noisy delay.
DLY_3	equ	d'10'		; 100 ms somewhat quiet delay.

; Noise Level counts (voltages) for various noise modes.
NOISE1	equ	d'128' 		; 2.50 volts
NOISE2	equ	d'26'		; 0.50 volt
NOISE3	equ	d'5'		; 0.10 volt
CAL_LVL	equ	d'229'		; 4.5 volts, calibration level.
	
; Noise level constants
ALLNOIS	equ	0		; all noise.
VRYNOIS	equ	1		; very noisy.
SOMNOIS	equ	2		; somewhat noisy.
SOMQUIE	equ	3		; somewhat quiet.
VRYQUIE	equ	4		; very quiet.

;tFlags				; timer flags    
TICK    equ     0		;   1 ms tick indicator.
ONEMS	equ     1		;   1 ms tick flag
TENMS	equ     2		;  10 ms tick flag
HUNDMS	equ     3		; 100 ms tick flag

;sqFlag				; squelch flag.
UNSQLCH	equ	0		; unsquelched.

;GPIO
;SQL	equ	0		; squelch pot on AN0/GP0.
;NOISE	equ	1		; noise level on AN1/GP1.
RUS	equ	2		; RUS output on GP2.
RUS_POL	equ	3		; RUS polarity invert on GP3.
CFG_JPR	equ	4		; config jumper.
DBG_LED	equ	5		; debug LED on GP5.

TEN	equ	d'10'		; ten. a decade.  useful for decade counters.
HUNDRED	equ	d'100'		; hundred. a century.
T0PRE	equ	8		; preset for TMR0, for 1 ms tick.
	
;variables
        cblock  20              ; RAM starts at 20h, contiguous to 7F.
				; (96 bytes here).
        w_copy                  ; saved W register for interrupt handler.
        s_copy                  ; saved status register for int handler.
        tFlags			; operating flags.
	sqFlag			; squelched flag.
	temp			; temporary storage.
	temp2			; temporary storage.
	tenMsC			; ten milliseconds down counter.
	hundMsC			; hundred millisecond down counter.
	squelch			; squelch pot level.
	wtNoise			; weighted noise level.
	ltNoise			; last noise level.
	sample0			; sample 0
	sample1			; sample 1
	sample2			; sample 2
	sample3			; sample 3 
	sample4			; sample 4
	sample5			; sample 5
	sample6			; sample 6
	sample7			; sample 7
	sampCtr			; sample counter.
	rusDly			; RUS on-->off transition delay.
	sqStat			; current squelch state.
        endc

;;;;;;;;;;;;;;;;;;
;; MAIN PROGRAM ;;
;;;;;;;;;;;;;;;;;;
        org     0
        goto    Start

;;;;;;;;;;;;;;;;;;;;;;; 
;; INTERRUPT HANDLER ;;
;;;;;;;;;;;;;;;;;;;;;;; 
        org     4
Intrupt				; interrupt handler.
        movwf   w_copy          ; save w reg in buffer.
        swapf   w_copy,f        ; swap it.
        swapf   STATUS,w        ; get status.
        movwf   s_copy          ; save it.

        btfsc   INTCON,T0IF	; is this a timer interrupt?
        goto    TimrInt		; yes.
        goto    IntExit		; no.

TimrInt
	movlw	T0PRE		; get timer offset
	movwf	TMR0		; preset timer.
        bsf     tFlags,TICK     ; set tick indicator flag

TimrDone                        
        bcf     INTCON,T0IF     ; clear RTCC int mask

IntExit
        swapf   s_copy,w        ; restore status
        movwf   STATUS          ;        /
        swapf   w_copy,w        ; restore W reg
        retfie

Start
        ERRORLEVEL 0, -302      ; suppress Argument out of range warnings.
        bsf     STATUS,RP0      ; select bank 1
	movlw	B'00011011'	; GP5 and GP2 are outputs.
        movwf   TRISIO          ; set GPIO port data direction
 
        movlw   b'00000001'     ; no pull up, timer 0 gets prescale 4
        movwf   OPTION_REG      ; set options

        movlw   b'00000100'     ; GPO and GP1 are analog inputs.
        movwf   ADCON1          ; write ADCON1

        bcf     STATUS,RP0      ; select page 0
	ERRORLEVEL 0		; don't suppress any warnings.
	
        clrf    GPIO            ; all off
        clrf    tFlags          ; clear timer flags.
	clrf	sqFlag		; clear squelch flag.

	movlw	b'01000001'	; set up A/D: 8 TOSC, AN0, noGO, ADON
	movwf	ADCON0		; set the A/D parameters...

	movlw	TEN		; get timebase presets
	movwf	tenMsC
	movlw	d'15'		; so hundred and ten don't fire at the same time.
	movwf	hundMsC
	clrf	sampCtr		; sample counter
	movlw	h'ff'		; set maximum noise by default.
	movwf	sample0		; sample 0
	movwf	sample1		; sample 1
	movwf	sample2		; sample 2
	movwf	sample3		; sample 3
	movwf	sample4		; sample 4
	movwf	sample5		; sample 5
	movwf	sample6		; sample 6
	movwf	sample7		; sample 7
	movwf	wtNoise		; weighted noise level
	movwf	ltNoise		; last noise level
	clrf 	squelch		; squelch threshold
	clrf	rusDly		; RUS on-->off transition delay.
	clrf	sqStat		; current squelch state.
	
        movlw   b'10100000'     ; enable interrupts, & Timer 0 overflow
        movwf   INTCON
	
	call	RUSoff		; start with RUS off.
	;; initialization complete...

; **********
; ** Loop **
; **********
Loop
	movlw	b'00000001'	; clear all old tFlags.
	andwf	tFlags,f	; clear all old tFlags.
	btfss	tFlags,TICK	; did a tick occur?
	goto	Loop1		; nope.
        clrwdt			; clear watchdog timer.
	bcf	tFlags,TICK	; clear tick indicator.
	bsf	tFlags,ONEMS	; set the 1 ms tick flag.
	decfsz	tenMsC,f	; decrement decade counter for 10 ms tick.
	goto	Check100	; did not get to zero.
	bsf	tFlags,TENMS	; set the 10 ms tick flag.
	movlw	TEN		; get preset.
	movwf	tenMsC		; reset decade counter.
Check100	
	decfsz	hundMsC,f	; decrement decade counter for 100 ms tick.
	goto	Loop1		; did not get to zero.
	bsf	tFlags,HUNDMS	; set the 100 ms tick flag.
	movlw	HUNDRED		; get preset.
	movwf	hundMsC		; reset decade counter.

Loop1
	
Ck100Ms				; check for 100 ms tick.
	;; LED BLINKER!!!
        btfss   tFlags,HUNDMS
        goto    LEDEnd
        btfss   GPIO,DBG_LED
        goto    LEDOff
	;; test the noise voltage here.
	movf	wtNoise,w	; get weighted noise level.
	sublw	CAL_LVL		; subtract calibrate level. w = CAL_LVL - w
	btfss	STATUS,C	; skip if result is positive.
	goto	LEDEnd		; result is negative. leave LED on.
	
        bcf     GPIO,DBG_LED
        goto    LEDEnd
LEDOff 
        bsf     GPIO,DBG_LED
LEDEnd
	
Ck10Ms				; check for 10 millisecond tick.
	btfss	tFlags,TENMS	; got a 10 ms tick?
	goto	Ck1Ms		; nope.
	;; check for running rusDly timer.
	movf	rusDly,f	; check for running RUS DELAY timer.
	btfsc	STATUS,Z	; is it zero?
	goto	RUSTDon		; yes.  ignore it.
	decfsz	rusDly,f	; decrement RUS DELAY timer.
	goto	RUSTDon		; not to zero yet.
	call	RUSoff		; turn off the RUS output.
RUSTDon
	
Ck1Ms				; check for 1 millisecond tick.
	btfss	tFlags,ONEMS	; got a 1 ms tick?
	goto	TmrDone		; no active timer ticks.
	
	movf	sampCtr,w	; get sample counter...
	andlw	b'00000011'	; mask to get operation type.
	movwf	temp		; save operation type.
	movlw	high SampTbl	; get high byte of address of SampTbl
	movwf	PCLATH		; set PCLATH.
	movf	temp,w		; get operation type.
	addwf	PCL,f		; computed goto.
SampTbl	
	goto	SmpNois		; sample counter is 0, take noise sample.
	goto	GetMin		; sample counter is 1, massage samples.
	goto	SampSql		; sample counter is 2, take squelch pot sample.
	goto	SetSqSt 	; sample counter is 3, choose signal state.
	
; *************
; ** SmpNois **
; *************
SmpNois				; get a noise sample.
	movlw	sample0		; get the address of sample1.
	movwf	FSR		; set the address for the result.
	movf	sampCtr,w	; get sample counter
	movwf	temp		; save...
	rrf	temp,f		; rotate, temp = temp/2 (sample counter/2)
	rrf	temp,w		; rotate, w    = temp/2 (sample counter/4)
	andlw	b'00000111'	; mask all except 3 lsbits.
	addwf	FSR,f		; add to address of sample.
	call	GetAD1		; get A/D 1.
	movwf	INDF		; save result.
	movwf	ltNoise		; save last noise result.
	goto	SampDon		; done sampling.

; ************
; ** GetMin **
; ************
GetMin				; get the smallest of the samples.
 	movlw	h'ff'		; maximum noise to start.
	movwf	wtNoise		; set starting point.
	movlw	d'08'		; set counter
	movwf	temp		; set counter.
	movlw	sample0		; get address of sample1.
	movwf	FSR		; set indirect address.
GetMinL				; loop start
	movf	INDF,w		; get sampleX value.
	subwf	wtNoise,w	; w = noise - w
	btfss	STATUS,C	; skip if result is positive.
	goto	GetMinE		; result was negative, sampleX > noise.
	movf	INDF,w		; get sampleX.
	movwf	wtNoise		; set noise value.
GetMinE				; done processing sampleX.
	incf	FSR,f		; increment FSR
	decfsz	temp,f		; decrement counter
	goto	GetMinL		; not done yet.
	goto	SampDon		; done getting minimum value.

; *************
; ** SetSqSt **
; *************
SetSqSt				; set the squelch state
	movf	wtNoise,w	; get noise value.
	subwf	squelch,w	; w = squelch - w.
	btfsc	STATUS,C	; skip if result is negative.
	goto	ChkSS		; NOT squelched.
	movlw	ALLNOIS		; all noise state.
	movwf	sqStat		; save squelch state.
	goto	SqDone		; done with this pass.

ChkSS				; check squelch settings, not squelched.
	movlw	VRYQUIE		; get very quiet squelch state.
	movwf	sqStat		; set very quiet squelch state.
	
	movf	wtNoise,w	; get noise value.
	sublw	NOISE3		; subtract NOISE3 level.
	btfsc	STATUS,C	; skip if result is negative.
	goto	SqDone		; result is positive, noise <= NOISE3.
	decf	sqStat,f	; move to next noisier level (3)

	movf	wtNoise,w	; get noise value.
	sublw	NOISE2		; subtract NOISE2 level.
	btfsc	STATUS,C	; skip if result is negative.
	goto	SqDone		; result is positive, noise <= NOISE2.
	decf	sqStat,f	; move to next noisier level (2)

	movf	wtNoise,w	; get noise value.
	sublw	NOISE1		; subtract NOISE1 level.
	btfsc	STATUS,C	; skip if result is negative.
	goto	SqDone		; result is positive, noise <= NOISE1.
	decf	sqStat,f	; move to next noisier level (1)
	
SqDone
	goto	SampDon		; done with this sample pass.
	
; *************
; ** SampSql **
; *************
SampSql
	call	GetAD0		; get A/D 0.
	movwf	squelch		; save squelch sample.

SampDon
	incf	sampCtr,f	; increment sample counter
	btfsc	sampCtr,5	; counted to 32 if bit 5 is set.
	clrf	sampCtr 	; reset sample counter.

NoSampl				; end of sample time check.
TmrDone				; end of timer processing.

; *****************************************************************************
; ** SqChk -- Check squelch state, set RUS output and timers accordingly. *****
; *****************************************************************************
SqChk				; check squelch state.
	movf	ltNoise,w	; get last noise value.
	subwf	squelch,w	; w = squelch - w.
	btfsc	STATUS,C	; skip if result is negative.
	goto	UnSq		; NOT squelched.

	btfss	sqFlag,UNSQLCH	; check to see if currently unsquelched.
	goto	SqCkEnd		; already squelched.
	
	movlw	high LSQtbl	; get high byte of address of LSQtbl
	movwf	PCLATH		; set PCLATH.
	movf	sqStat,w	; get sqStat.
	andlw	b'00000111'	; mask for sanity reasons.
	addwf	PCL,f		; computed goto.
LSQtbl	
	goto	LSQ0		;   full   noise state.
	goto	LSQ1		;   very   noisy state.
	goto	LSQ2		; somewhat noisy state.
	goto	LSQ3		; somewhat quiet state.
	goto	LSQ4		;   very   quiet state.
	goto	LSQ0		; invalid state.  consider to be full noise.
	goto	LSQ0		; invalid state.  consider to be full noise.
	goto	LSQ0		; invalid state.  consider to be full noise.

LSQ0				; last squelch state was 0.
	goto	SqCkEnd		; safe to ignore.
	
LSQ1				; last squelch state was 1.
	movlw	DLY_1		; get very noisy delay
	movwf	rusDly		; save delay.
	btfss	GPIO,CFG_JPR	; is long delay selected?
	addwf	rusDly,f	; yes.
	goto	SqCkEnd		; done here.

LSQ2				; last squelch state was 2.
	movlw	DLY_2		; get somewhat noisy delay
	movwf	rusDly		; save delay.
	btfss	GPIO,CFG_JPR	; is long delay selected?
	addwf	rusDly,f	; yes.
	goto	SqCkEnd		; done here.

LSQ3				; last squelch state was 3.
	movlw	DLY_3		; get somewhat quiet delay
	movwf	rusDly		; save delay.
	btfss	GPIO,CFG_JPR	; is long delay selected?
	addwf	rusDly,f	; yes.
	goto	SqCkEnd		; done here.

LSQ4				; last squelch state was 4.
	clrf	rusDly		; clear any outstanding delay.
	call	RUSoff		; turn off RUS.
	goto	SqCkEnd		; done here.

UnSq				; in some unsquelched mode.
	btfsc	sqFlag,UNSQLCH	; check to see if currently squelched.
	goto	SqCkEnd		; already unsquelched.
	clrf	rusDly		; reset RUS DELAY.
	call	RUSon		; turn on RUS.
	
SqCkEnd
	goto	Loop		; done here.
	
; *****************************************************************************
; ** RUSon -- turn on RUS output **********************************************
; *****************************************************************************
RUSon				; activate the RUS signal.
	bsf	sqFlag,UNSQLCH	; set unsquelched bit.
	btfsc	GPIO,RUS_POL	; is RUS polarity inverted?
	goto	RUS1		; no.
	goto	RUS0		; yes.

; *****************************************************************************
; ** RUSoff -- turn off RUS output ********************************************
; *****************************************************************************
RUSoff				; inactivate the RUS signal.
	bcf	sqFlag,UNSQLCH	; clear unsquelched bit.
	btfsc	GPIO,RUS_POL	; is RUS polarity inverted?
	goto	RUS0		; no.
	;; next line commented out for deliberate fall-thru to RUS1.
	;goto	RUS1		; yes.

RUS1				; set the RUS line HI.
	bsf	GPIO,RUS	; set the RUS line HI.
	return			; done.

RUS0				; set the RUS line LO.
	bcf	GPIO,RUS	; set the RUS line LO.
	return
	
; *****************************************************************************
; ** GetAD0 -- get value from AD0. ********************************************
; *****************************************************************************
GetAD0				; get the A/D value for AN0.
	movlw	b'01000001'	; set up A/D: 8 TOSC, AN0, notGO, ADON
	movwf	ADCON0		; set the A/D parameters...
	goto	GetAD		; continue...

; *****************************************************************************
; ** GetAD1 -- get value from AD1. ********************************************
; *****************************************************************************
GetAD1				; get the A/D value for AN0.
	movlw	b'01001001'	; set up A/D: 8 TOSC, AN1, notGO, ADON
	movwf	ADCON0		; set the A/D parameters...
GetAD	
	;; need 12 uSec for A/D to stabilize.
	;; wait 15.
	nop			;  1
	nop			;  2 
	nop			;  3 
	nop			;  4 
	nop			;  5 
	nop			;  6 
	nop			;  7 
	nop			;  8 
	nop			;  9 
	nop			; 10
	nop			; 11
	nop			; 12 
	nop			; 13 
	nop			; 14 
	nop			; 15 
	bsf	ADCON0,GO	; start conversion...
	;; the conversion should take about another 20 uSec.
ADWait
	btfsc	ADCON0,GO	; conversion done yet?
	goto	ADWait		; nope...
	movf	ADRES,W		; get result, return it in W.
	return

	END
