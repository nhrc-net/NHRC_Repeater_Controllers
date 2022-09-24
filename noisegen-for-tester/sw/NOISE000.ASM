	;;  noise generator for 12c508.  Generates pseudo-random bit sequence.
	;; implemented as a 23-bit shift register.  bit 0 (lowest) sets output
	;; pin.  bit 0 and bit 5 are xor-ed, and the result is placed in bit
	;; 22.
	;; care must be taken to make sure that the same cycle time is enforced
	;; for all branch states.
	
	; simple CW sender for 12c508
; uses hardcoded cw message.

        LIST P=12c508, R=HEX
        include "p12c508.inc"
        __FUSES _CP_OFF & _IntRC_OSC & _WDT_OFF & _MCLRE_OFF
        ERRORLEVEL 0, -302      ;suppress Argument out of range errors

;GPIO
NOIZ	equ	0		; GPIO 0 is the noise output

;variables
        cblock  07              ;RAM starts at 07h, contiguous to 1F (25 bytes here)
	shift3			; highest byte of shift register
	shift2			; middle  byte of shift register
	shift1			; lowest  byte of shift register
        endc
;last RAM address is at 1f

;;;;;;;;;;;;;;;;;;
;; MAIN PROGRAM ;;
;;;;;;;;;;;;;;;;;;

        org     0
Start
        movlw   b'10000001'     ; no pull up, timer 0 gets prescale 4.
	option			; set option register.
	
	movlw	B'00111110'	; GP0 is output.
	tris	GPIO

	bcf	GPIO,NOIZ	; turn off only output.

	clrf	shift3		; clear register
	clrf	shift2		; clear register
	clrf	shift1		; clear register
	bsf	shift1,0	; set bit
	bsf	shift2,0	; set bit
	bsf	shift3,0	; set bit

Loop
	rrf	shift3,f	; rotate shift 3, LSB->C
	rrf	shift2,f	; rotate shift 2, LSB->C
	rrf	shift1,f	; rotate shift 1, LSB->C
	btfss	STATUS,C	; was LSB of shift1 set?
	goto	NoisOff		; no.
	bsf	GPIO,NOIZ	; turn on noiz output.
	goto	FeedBck		; do feedback...
NoisOff
	bcf	GPIO,NOIZ	; turn on noiz output.
	nop			; time waster, makes set & clear same # cycles
FeedBck
	bcf	shift3,7	; clear high bit
	bcf	shift3,6	; clear 23rd bit (where feedback goes...)
	btfss	shift1,0	; is bit 0 set?
	goto	B0Clear		; no.
	btfss	shift1,5	; is bit 5 set?
	goto	X01  		; no.  bit 5 clear, bit 0 set.
	goto	X11		; yes. bit 5 set,   bit 0 set.
	
B0Clear
	btfss	shift1,5	; is bit 5 set?
	goto	X00  		; no.  bit 5 clear, bit 0 clear.
	;goto	X10		; yes. bit 5 set,   bit 0 clear.
X10
X01
	bsf	shift3,6	; set 23rd bit (where feedback goes...)
X00
X11
	;; loop length is about 16 cycles to here...
	goto	Loop		; go again...

        end


