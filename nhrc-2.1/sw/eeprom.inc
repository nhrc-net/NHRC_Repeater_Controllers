; ***********************************
; ** NHRC-3.1 EEPROM Constants     **
; ** Rev 0.99 11 January 2010      **
; ** Copyright 2011, NHRC LLC      **
; ***********************************

; ***********************
; ** EEPROM MEMORY MAP **
; ***********************

	;; 16F886 has 256 bytes EEPROM
EETMRB	equ	h'00'		; 0000 Timer Preset values (1 byte each * 16)
EETHTL	equ	h'00'		; 0000 long hang timer.
EETHTS	equ	h'01'		; 0001 hang timer
EETID	equ	h'02'		; 0002 ID timer
EETDTA	equ	h'03'		; 0003 DTMF access timer
EETTML	equ	h'04'		; 0004 long timeout timer
EETTMS	equ	h'05'		; 0005 timeout timer
EETFAN	equ	h'06'		; 0006 fan timer
EETTAIL	equ	h'07'		; 0007 tail counter
EEALARM equ     h'08'           ; 0008 alarm announce timer
EETCWP  equ     h'09'           ; 0009 CW pitch
EETCWS  equ     h'0a'           ; 000A CW speed
LASTTMR	equ	h'0A'		; timers 0-a, 10 timers.
	
EESETSZ	equ	h'08'		; size of both sets.
CTLOPS	equ	h'08'		; 8 bytes of control op data.

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
EEPFC	equ	d'08'		; 8 prefixes.
EEPFL	equ	d'08'		; of length 8.
				; next address is f0
	
EESSC	equ	d'8'		; save 8 groups
EENSS	equ	d'4'		; last saved set number

EELAST	equ	h'ef'		; last address to initialize.

MAXPFX	equ	d'7'		; max prefix index.
