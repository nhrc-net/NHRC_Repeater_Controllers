; ********************************************
; ** NHRC-5 EEPROM Memory Map and Constants **
; ** Rev 0.03 25 October 2000               **
; ** Copyright 2000, NHRC LLC               **
; ********************************************

; ***********************
; ** EEPROM MEMORY MAP **
; ***********************

	;; 16F877 has 256 bytes EEPROM
EETMRB	equ	h'00'		; 0000 Timer Preset values (1 byte each * 16)
EETHTL	equ	h'00'		; long hang timer.
EETHTS	equ	h'01'		; hang timer
EETID	equ	h'02'		; ID timer
EETDTA	equ	h'03'		; DTMF access timer
EETTML	equ	h'04'		; long timeout timer
EETTMS	equ	h'05'		; timeout timer
EETFAN	equ	h'06'		; fan timer
EETALM	equ	h'07'		; alarm timer.
EETTAIL	equ	h'08'		; tail counter
LASTTMR	equ	h'08'		; timers 0-6, 7 timers.
	
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
	
EEPFC	equ	d'08'		; 8 prefixes.
EEPFL	equ	d'08'		; of length 8.
	
MSG0LEN equ	h'c0'		; 00c0 ISD message 0 length.
MSG1LEN equ	h'c1'		; 00c1 ISD message 1 length.
MSG2LEN equ	h'c2'		; 00c2 ISD message 2 length.
MSG3LEN	equ	h'c3'		; 00c3 ISD message 3 length.
MSG4LEN	equ	h'c4'		; 00c3 ISD message 4 length.
MSG5LEN	equ	h'c5'		; 00c3 ISD message 5 length.
MSG6LEN	equ	h'c6'		; 00c3 ISD message 6 length.
MSG7LEN	equ	h'c7'		; 00c3 ISD message 7 length.
	 
EESSC	equ	d'10'		; save 10 groups

EELAST	equ	h'cf'		; last address to initialize.
MAXPFX	equ	d'7'		; max prefix index.
MAXMSG	equ	d'7'		; max message number.