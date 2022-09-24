; ******************************************************
; ** NHRC-Remote Plus EEPROM Memory Map and Constants **
; ** Rev 3.00 03 May 2011                             **
; ** Copyright 2000, 2003, 2011 NHRC LLC              **
; ******************************************************

; ***********************
; ** EEPROM MEMORY MAP **
; ***********************

	;; 16F648A has 256 bytes EEPROM

        ;; 0000 - 000f are timer presets 
EETMRB	equ	h'00'		; 0000 Timer Preset values (1 byte each * 16)
EETID   equ	h'00'		; ID timer
EEPTID  equ     h'01'           ; pulse duration time
EELATCH equ     h'02'           ; the whole latch byte "timer" -- fake!
LASTTMR	equ	h'02'		; timers 0-2, 3 "timers".
	
	;; 0010-001f are the control op data, set 0
EE0B	equ	h'10'		; BASE OF SET 0
MAXGRP  equ     d'2'            ; max group index.
EESSC	equ	d'3'		; save 3 bytes of control op data
	;; set 0 ends at 1F

        ;; 0050 - 0005F are the CW ID
EECWID	equ	h'50'		; 0050 CW ID; 15 letters, max

        ;; 0060 - 00FF are the control operator prefix codes	
EEPFB	equ	h'60'		; 0060 control prefix 0   control prefix 1
				; 0070 control prefix 2   control prefix 3
				; 0080 control prefix 4   control prefix 5
				; 0090 control prefix 6   control prefix 7
                                ; 00a0 control prefix 8   control prefix 9
                                ; 00b0 control prefix 10  control prefix 11
                                ; 00c0 control prefix 12  control prefix 13
                                ; 00d0 control prefix 14  control prefix 15
                                ; 00e0 control prefix 16  control prefix 17
                                ; 00f0 control prefix 18  control prefix 19
	
EEPFC	equ	d'20'		; 20 prefixes.
EEPFL	equ	d'08'		; of length 8.
MAXPFX	equ	d'19'		; max prefix index.

EELAST	equ	h'ff'		; last EEPROM address to initialize.
