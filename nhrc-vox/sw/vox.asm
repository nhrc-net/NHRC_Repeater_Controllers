; pulsestretcher for 12f675 NHRC-SuperVox

	LIST P=12f675, R=HEX
	include "p12f675.inc"
	__FUSES _CP_ON & _INTRC_OSC_NOCLKOUT & _PWRTE_ON & _WDT_OFF & _MCLRE_OFF
	ERRORLEVEL 0, -302	; suppress Argument out of range errors

;tFlags				; timer flags	
TICK	equ	0		; 1 ms tick flag
	
;GPIO
TSET0	equ	0			; GPIO 0 is time set 0 - 250 ms
TSET1	equ	1			; GPIO 0 is time set 1 - 500 ms
TSET2	equ	2			; GPIO 0 is time set 2 - 1000 ms
POLARTY	equ	3			; GPIO 3 is output polarity
INPUT	equ	4			; GPIO 4 is the pulse stretcher input
OUTPUT	equ	5			; GPIO 5 is the pulse stretcher output

T0PRE	equ	D'12'		; overflow counts for base 1 KHz tick

	;; macro definitions
push	macro
	movwf	w_copy		; save w reg in Buffer
	swapf	w_copy,f	; swap it
	swapf	STATUS,w	; get status
	movwf	s_copy		; save it
	endm

pop	macro
	swapf	s_copy,w	; restore status
	movwf	STATUS		;
	swapf	w_copy,w	; restore W reg
	endm

	;; variables
	cblock	20		; RAM starts at 20h, contiguous to 7F (96 bytes here)
	w_copy			; saved W register for interrupt handler
	s_copy			; saved status register for int handler
	tFlags			; Timer Flags
	tenCnt			; decade counter to get 10 ms
	stretch			; stretch time counter
	endc

;;;;;;;;;;;;;;;;;;
;; MAIN PROGRAM ;;
;;;;;;;;;;;;;;;;;;

	org	0
	goto	Start

	;
	; interrupt handler
	;
	org	4
	push					; preserve W and STATUS

	btfss	INTCON,T0IF		; is this a Timer 0 interrupt?
	goto	IntExit			; no

	movlw	T0PRE			; get timer offset
	movwf	TMR0			; preset timer.
	bsf		tFlags,TICK		; set tick indicator flag

TimrDone			
	bcf		INTCON,T0IF		; clear RTCC int mask

IntExit
	pop						; restore W and STATUS
	retfie

Start
	bsf		STATUS,RP0		; select bank 1
	movlw	B'00011111'		; low 5 bits of port a are inputs (GP0-GP4)
	movwf	TRISIO			; set port a data direction
 
 	movlw	b'00000001'		; weak pull up, timer 0 gets prescale 4
	movwf	OPTION_REG		; set options
	
	call	3ffh			; get calibration constant
	movwf	OSCCAL			; set internal RC OSC calibration

	movlw	b'00000111'		; set weak pullups on GP2, GP1, GP0
	movwf	WPU				; set weak pullups
	
	clrf	ANSEL			; set all GPIO to be digital pins, not analog
	
	bcf		STATUS,RP0		; select page 0

	movlw	b'00000111'		; turn comparator off
	movwf	CMCON			; write CMCON
	
	movlw	b'00000000'		; turn A/D off
	movwf	ADCON0			; write ADCON0
	
	clrf	GPIO			; all off
	clrf	tFlags			; clear timer flags

	movlw	d'10'			; decade counter preset
	movwf	tenCnt			; preset decade counter
	
	movlw	b'10100000'		; enable interrupts, & Timer 0 overflow
	movwf	INTCON 

	call	SetOff			; turn output off

Loop
	btfss	tFlags,TICK		; is TICK set
	goto	Loop			; no
	bcf		tFlags,TICK		; reset TICK flag bit

	decfsz	tenCnt,f		; decrement decade counter
	goto	Loop			; not zero yet

	movlw	d'10'			; decade counter preset
	movwf	tenCnt			; preset decade counter

	btfsc	GPIO,INPUT		; is INPUT active (low?)
	goto	NoInput			; no
	
	call	SetOn			; turn on output
	
	movlw	d'25'			; mimimum is 250 ms
	btfss	GPIO,TSET0		; is TSET0 low?
	addlw	d'25'			; yes, add 250 ms
	btfss	GPIO,TSET1		; is TSET1 low?
	addlw	d'50'			; yes, add 500 ms
	btfss	GPIO,TSET2		; is TSET2 low?
	addlw	d'100'			; yes, add 1000 ms
	movwf	stretch			; save stretch time
	
NoInput
	decfsz	stretch,f		; decrement stretch time
	goto	Loop			; not zero yet
	call	SetOff			; turn output off
	goto	Loop			; not zero yet

SetOn
	btfss	GPIO,POLARTY	; is POLARTY bit set?
	bsf		GPIO,OUTPUT		; nope
	btfsc	GPIO,POLARTY	; is POLARTY bit clear?
	bcf		GPIO,OUTPUT		; nope
	return
	
SetOff
	btfss	GPIO,POLARTY	; is POLARTY bit set?
	bcf		GPIO,OUTPUT		; nope
	btfsc	GPIO,POLARTY	; is POLARTY bit clear?
	bsf		GPIO,OUTPUT		; nope
	return
	
	end

