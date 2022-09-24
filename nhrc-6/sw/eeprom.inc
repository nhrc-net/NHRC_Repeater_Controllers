; ********************************************
; ** NHRC-6 EEPROM Memory Map and Constants **
; ** Rev 1.10 26 February 2004              **
; ** Copyright 2002, 2004, NHRC LLC         **
; ********************************************

; ***********************
; ** EEPROM MEMORY MAP **
; ***********************

	;; 16F876 has 256 bytes EEPROM
EETMRB	equ	h'00'		; 0000 Timer Preset values (1 byte each * 16)
EETHTL	equ	h'00'		; 00 long hang timer.
EETHTS	equ	h'01'		; 01 short hang timer
EETID1	equ	h'02'		; 02 ID timer, transmitter 1
EETID2	equ	h'03'		; 03 ID timer, transmitter 2
EETDTA	equ	h'04'		; 04 DTMF access timer
EETTML	equ	h'05'		; 05 long timeout timer
EETTMS	equ	h'06'		; 06 short timeout timer
EETFAN	equ	h'07'		; 07 fan timer

EECT1BO equ     h'08'           ; 08 TX1 courtesy tone backoff
EECT2BO equ     h'09'           ; 09 TX2 courtesy tone backoff
EETCWP1	equ	h'0A'		; CW pitch, tx1
EETCWS1	equ	h'0B'		; CW speed, tx1
EETCWP2	equ	h'0C'		; CW pitch, tx2
EETCWS2	equ	h'0D'		; CW speed, tx2
 
LASTTMR	equ	h'0D'		; timers 0-D, 14 timers.
	
	;; 0010-001f are the control op data, set 0
EE0B	equ	h'10'		; BASE OF SET 0
	;; set 0 ends at 1f

	;; 0020-002f are the control op data, set 1
EE1B	equ	h'20'		; BASE OF SET 1
	;; set 1 ends at 2f

	;; 0030-003f are the control op data, set 2
EE2B	equ	h'30'		; BASE OF SET 2
	;; set 2 ends at 3f

	;; 0040-004f are the control op data, set 3
EE3B	equ	h'40'		; BASE OF SET 3
	;; set 1 ends at 4f

	;; 0050-005f are the control op data, set 4
EE4B	equ	h'50'		; BASE OF SET 4
	;; set 1 ends at 5f

EECTB	equ	h'60'		; 0060 Courtesy tone 0    0068 Courtesy Tone 1
				; 0070 Courtesy tone 2    0078 Courtesy Tone 3
				; 0080 Courtesy tone 4    0088 Courtesy Tone 5
				; 0090 Courtesy tone 6    0098 Courtesy Tone 7

EECWID1	equ	h'a0'		; 00a0 CW ID; 15 letters, max
EECWID2	equ	h'b0'		; 00b0 CW ID; 15 letters, max
	
EEPFB	equ	h'c0'		; 00c0 control prefix 0   control prefix 1
				; 00d0 control prefix 2   control prefix 3
				; 00e0 control prefix 4   control prefix 5
				; 00f0 control prefix 6   control prefix 7
	
EEPFC	equ	d'08'		; 8 prefixes.
EEPFL	equ	d'08'		; of length 8.
	 
EESSC	equ	d'10'		; save 10 groups

EELAST	equ	h'ff'		; last address to initialize.
MAXPFX	equ	d'5'		; max prefix index.
