; ************************************************
; ** NHRC-Micro EEPROM Memory Map and Constants **
; ** Rev 1.00 12 February 2004                  **
; ** Copyright 2004 NHRC LLC                    **
; ************************************************

; ***********************
; ** EEPROM MEMORY MAP **
; ***********************

	;; 16F648A has 256 bytes EEPROM
EETMRB	equ	h'00'		; 0000 Timer Preset values (1 byte each * 16)
EETHTL	equ	h'00'		; long hang timer.
EETHTS	equ	h'01'		; short hang timer.
EETID	equ	h'02'		; ID timer
EETDTA	equ	h'03'		; DTMF access timer
EETTML	equ	h'04'		; long timeout timer
EETTMS	equ	h'05'		; short timeout timer
EETCWP	equ	h'06'		; CW pitch
EETCWS	equ	h'07'		; CW speed
LASTTMR	equ	h'07'		; timers 0-7, 8 timers.
	
	;; 0010-001f are the control op data, set 0
EE0B	equ	h'10'		; BASE OF SET 0
	;; set 0 ends at 1F

	;; 0020-002f are the control op data, set 1
EE1B	equ	h'20'		; BASE OF SET 1
	;; set 1 ends at 2F

	;; 0030-003f are the control op data, set 2
EE2B	equ	h'30'		; BASE OF SET 2
	;; set 2 ends at 3F

	;; 0040-004f are the control op data, set 3
EE3B	equ	h'40'		; BASE OF SET 3
	;; set 3 ends at 4F

	;; 0050-005f are the control op data, set 4
EE4B	equ	h'50'		; BASE OF SET 4
	;; set 4 ends at 5F

EECTB	equ	h'60'		; 0060 Courtesy tone 0    Courtesy Tone 1
				; 0070 Courtesy tone 2    Courtesy Tone 3
				; 0080 Courtesy tone 4    Courtesy Tone 5
				; 0090 Courtesy tone 6    Courtesy Tone 7

EECWID	equ	h'a0'		; 00a0 CW ID; 15 letters, max
	
EEPFB	equ	h'b0'		; 00b0 control prefix 0   control prefix 1
				; 00c0 control prefix 2   control prefix 3
				; 00d0 control prefix 4   control prefix 5
				; 00e0 control prefix 6   control prefix 7
	
EEPFC	equ	d'04'		; 6 prefixes.
EEPFL	equ	d'08'		; of length 8.
	 
EESSC	equ	d'10'		; save 10 groups

EELAST	equ	h'ef'		; last address to initialize.
MAXPFX	equ	d'3'		; max prefix index.
