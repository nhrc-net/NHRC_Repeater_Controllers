; **********************************
; ** NHRC-10 Vocabulary Constants **
; ** Rev 0.70 July 20, 1999       **
; ** Copyright 1999, NHRC LLC     **
; **********************************

; ***************************************************************************
; ***************************************************************************
; ** This file contains proprietary information which is the confidential  **
; ** property of NHRC LLC.  It shall not be copied, reproduced, disclosed, **
; ** published in whole or in part without the express written permission  ** 
; ** of NHRC LLC.                                                          **
; ***************************************************************************
; ***************************************************************************

	;; 96 1-second messages
V0	equ	h'00'			; 000  zero
V1	equ	h'01'			; 001  one
V2	equ	h'02'			; 002  two
V3	equ	h'03'			; 003  three
V4	equ	h'04'			; 004  four
V5	equ	h'05'			; 005  five
V6	equ	h'06'			; 006  six
V7	equ	h'07'			; 007  seven
V8	equ	h'08'			; 008  eight
V9	equ	h'09'			; 009  nine
V10	equ	h'0a'			; 010  ten
V11	equ	h'0b'			; 011  eleven
V12	equ	h'0c'			; 012  twelve
V13	equ	h'0d'			; 013  thirteen
V14	equ	h'0e'			; 014  fourteen
V15	equ	h'0f'			; 015  fifteen
V16	equ	h'10'			; 016  sixteen
V17	equ	h'11'			; 017  seventeen
V18	equ	h'12'			; 018  eighteen
V19	equ	h'13'			; 019  nineteen
V20	equ	h'14'			; 020  twenty
V30	equ	h'15'			; 021  thirty
V40	equ	h'16'			; 022  forty
V50	equ	h'17'			; 023  fifty
V60	equ	h'18'			; 024  sixty
V70	equ	h'19'			; 025  seventy
V80	equ	h'1a'			; 026  eighty
V90	equ	h'1b'			; 027  ninety
VHUND	equ	h'1c'			; 028  hundred
VTHOU	equ	h'1d'			; 029  thousand
VACCESS	equ	h'1e'			; 030  access
VAUTOP	equ	h'1f'			; 031  autopatch 
VBAD	equ	h'20'			; 032  bad
VBASE	equ	h'21'			; 033  base
VCALL	equ	h'22'			; 034  call
VCOMPLT	equ	h'23'			; 035  complete
VCONTRL equ	h'24'			; 036  control
VCOMMND equ	h'25'			; 037  command
VDISABL	equ	h'26'			; 038  disabled
VDENIED	equ	h'27'			; 039  denied
VENABLE	equ	h'28'			; 040  enabled
VERROR	equ	h'29'			; 041  error
VFREQ	equ	h'2a'			; 042  frequency
VIS	equ	h'2b'			; 043  is
VHERTZ	equ	h'2c'			; 044  hertz
VKILO	equ	h'2d'			; 045  kilo
VLINK	equ	h'2e'			; 046  link
VMEGA	equ	h'2f'			; 047  mega
VMESSAG	equ	h'30'			; 048  message
VMINUS	equ	h'31'			; 049  minus
VMINUTE	equ	h'32'			; 050  minutes
VOFF	equ	h'33'			; 051  off
VON	equ	h'34'			; 052  on
VOPERAT	equ	h'35'			; 053  operator
VPHONE	equ	h'36'			; 054  phone
VPL	equ	h'37'			; 055  PL
VPOINT	equ	h'38'			; 056  point
VPROGR	equ	h'39'			; 057  program
VRECEIV	equ	h'3a'			; 058  receive
VRECORD	equ	h'3b'			; 059  record
VNO    	equ	h'3c'			; 060  no
VREMOTE	equ	h'3d'			; 061  remote
VREPEAT	equ	h'3e'			; 062  repeater
VRING	equ	h'3f'			; 063  ring
VSECOND	equ	h'40'			; 064  seconds
VSQUELC	equ	h'41'			; 065  squelch
VTIMER	equ	h'42'			; 066  timer
VTRANS	equ	h'43'			; 067  transmit
VTEST	equ	h'44'			; 068  test
VNHRC	equ	h'45'			; 069  NHRC
VMBX	equ	h'46'			; 070  mailbox
VCNTRLR	equ	h'47'			; 071  controller
VVERSN	equ	h'48'			; 072  version
VEMERG	equ	h'49'			; 073  emergency
VAUTOD	equ	h'4a'			; 074  autodial
VOK	equ	h'4b'			; 075  OK
VSIDEB	equ	h'4c'			; 076  sideband
VAM	equ	h'4d'			; 077  AM
VPM	equ	h'4e'			; 078  PM
VUPPER	equ	h'4f'			; 079  upper
VLOWER	equ	h'50'			; 080  lower
VFM	equ	h'51'			; 081  FM
VA	equ	h'52'			; 082  A
VB	equ	h'53'			; 083  B
VC	equ	h'54'			; 084  C
VD	equ	h'55'			; 085  D
VE	equ	h'56'			; 086  E
VF	equ	h'57'			; 087  F
VMETERS	equ	h'58'			; 088  meters
VCENTI	equ	h'59'			; 089  centi
VALERT	equ	h'5a'			; 090  alert
VUP	equ	h'5b'			; 091  up
VDOWN	equ	h'5c'			; 092  down
VPLUS	equ	h'5d'			; 093  plus
VNUMBER	equ	h'5e'			; 094  number
VHEADER	equ	h'5f'			; 095  header
	;; 15 8-second messages
VNID1	equ	h'60'			; 096  normal ID 1
VNID2	equ	h'61'			; 097  normal ID 2
VNID3	equ	h'62'			; 098  normal ID 3
VTOUT	equ	h'63'			; 099  timeout message
VANN1	equ	h'64'			; 100  announcement 1
VANN2	equ	h'65'			; 101  announcement 2
VANN3	equ	h'66'			; 102  announcement 3
VTESTM	equ	h'67'			; 103  test track
VCTONE	equ	h'68'			; 104  courtesy tone message.
VMB1H	equ	h'69'			; 105  mbox 1 header
VMB2H	equ	h'6a'			; 106  mbox 2 header
VMB3H	equ	h'6b'			; 107  mbox 3 header
VMB4H	equ	h'6c'			; 108  mbox 4 header
VMB5H	equ	h'6d'			; 109  mbox 5 header
VMB6H	equ	h'6e'			; 110  mbox 6 header
	;; 12 32-second messages
VIID	equ	h'6f'			; 111  initial ID message
VTAIL1	equ	h'70'			; 112  tail message 1
VTAIL2	equ	h'71'			; 113  tail message 2
VTAIL3	equ	h'72'			; 114  tail message 3
VLITZ	equ	h'73'			; 115  litz message   
VSPECL	equ	h'74'			; 116  special message
VMB1	equ	h'75'			; 117  mbox 1 contents
VMB2	equ	h'76'			; 118  mbox 2 contents
VMB3	equ	h'77'			; 119  mbox 3 contents
VMB4	equ	h'78'			; 120  mbox 4 contents
VMB5	equ	h'79'			; 121  mbox 5 contents
VMB6	equ	h'7a'			; 122  mbox 6 contents
MAXMBX	equ	d'6'			; max mailbox #
LASTMBX	equ	d'5'			; max mailbox #, zero based.