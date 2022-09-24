; ********************************************
; ** NHRC-4 EEPROM Memory Map and Constants **
; ** Rev 3.00 22 October 2003               **
; ** Copyright 2000, 2003, 2005, NHRC LLC   **
; ********************************************

; ***********************
; ** EEPROM MEMORY MAP **
; ***********************

	;; 16F628 
EETMRB	equ	h'00'		; 0000 Timer Preset values (1 byte each * 16)
EETHTL	equ	h'00'		; long hang timer.
EETHTS	equ	h'01'		; hang timer
EETID	equ	h'02'		; ID timer
EETDTA	equ	h'03'		; DTMF access timer
EETTML	equ	h'04'		; long timeout timer
EETTMS	equ	h'05'		; timeout timer
EETFAN	equ	h'06'		; fan timer
EETCWP  equ     h'07'           ; CW pitch
EETCWS  equ     h'08'           ; CW speed
LASTTMR	equ	h'08'		; timers 0-8, 9 timers.
	
	;; 0010-001f are the control op data, set 0
EE0B	equ	h'10'		; BASE OF SET 0
	;; set 0 ends at 1F

	;; 0020-002f are the control op data, set 1
EE1B	equ	h'20'		; BASE OF SET 1
	;; set 1 ends at 2F

EECTB	equ	h'30'		; 0030 Courtesy tone 0    Courtesy Tone 1
				; 0040 Courtesy tone 2    Courtesy Tone 3
				; 0050 Courtesy tone 4    Courtesy Tone 5
				; 0060 Courtesy tone 6    Courtesy Tone 7

EECWID	equ	h'70'		; 0070 CW ID; 15 letters, max
	
EEPFB	equ	h'80'		; 0080 control prefix 0   control prefix 1
				; 0090 control prefix 2   control prefix 3
				; 00a0 control prefix 4   control prefix 5
				; 00b0 control prefix 6   control prefix 7
	
EEPFC	equ	d'06'		; 6 prefixes.
EEPFL	equ	d'08'		; of length 8.
	 
EESSC	equ	d'10'		; save 10 groups

EELAST	equ	h'cf'		; last address to initialize.
MAXPFX	equ	d'5'		; max prefix index.
