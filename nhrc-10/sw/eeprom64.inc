; *************************************
; ** NHRC-10 EEPROM Constants        **
; ** Rev 1.07 May 14 2001            **
; ** Copyright 1999, 2001, NHRC LLC  **
; *************************************

; ******************************************
; ******************************************
; **  6 4 K   E E P R O M   2 5 L C 3 2 0 **
; **   E E P R O M   M E M O R Y   M A P  **
; **         0 0 0 0 - 1 F F F            **
; ******************************************
; ******************************************
;
EETMRB  equ     0000            ; 0000 Timer Preset values (1 byte each * 16)
EETHTL  equ     0000            ; hang timer long
EETHTS  equ     0001            ; hang timer short
EETID   equ     0002            ; ID timer
EETPAT  equ     0003            ; patch timer
EETAD   equ     0004            ; autodial timer
EETEAD  equ     0005            ; emergency autodial timer
EETDTA  equ     0006            ; DTMF access timer
EETTML  equ     0007            ; timeout timer long
EETTMS  equ     0008            ; timeout timer short
EETMUT  equ     0009            ; DTMF mute timer
EETFAN  equ     000a            ; fan timer
EETTAIL equ     000b            ; tail counter
EETRING equ     000c            ; ring counter
EERBTMR equ     000d            ; remote base timer
EEKCTMR equ     000e            ; kerchunker timer 1
;spare  equ     000f            ; spare
LASTTMR equ     h'0e'           ; timers 0-14, 15 timers.

        ;; 000e-000f are reserved for additional timers.
EECWID  equ     0010            ; 0010 CW ID
EECTB   equ     0020            ; 0020 Courtesy tone 0    Courtesy Tone 1
                                ; 0030 Courtesy tone 2    Courtesy Tone 3
                                ; 0040 Courtesy tone 4    Courtesy Tone 5
                                ; 0050 Courtesy tone 6    Courtesy Tone 7
EEPFB   equ     0060            ; 0060 control prefix 0   control prefix 1
                                ; 0070 control prefix 2   control prefix 3
                                ; 0080 control prefix 4   control prefix 5
                                ; 0090 control prefix 6   control prefix 7
                                ; 00A0 control prefix 8   control prefix 9
                                ; 00B0 control prefix 10  control prefix 11
                                ; 00C0 control prefix 12  control prefix 13
                                ; 00D0 control prefix 14  control prefix 15
EEPFC   equ     d'16'           ; 16 prefixes.
EEPFL   equ     08              ; of length 8.
                                ; 00E0 (RESERVED)
                                ; 00F0 (RESERVED)
EESSB   equ     0100            ; 0100 control op saved set 0
                                ; 0110 control op saved set 1
                                ; 0120 control op saved set 2
                                ; 0130 control op saved set 3
                                ; 0140 control op saved set 4
EESSC   equ     d'10'           ; save 10 groups
EESSCI  equ     d'11'           ; initialize 11 groups
EENSS   equ     d'4'            ; last saved set number
EEMBXF  equ     010a            ; mailbox flag. read from EE with group 0 only.
                                ; 0150 (RESERVED)
EEAAB   equ     0160            ; 0160 emergency autodial 0
                                ; 0170 emergency autodial 1
                                ; 0180 emergency autodial 2
                                ; 0190 emergency autodial 3
                                ; 01A0 emergency autodial 4
                                ; 01B0 emergency autodial 5
                                ; 01C0 emergency autodial 6
                                ; 01D0 emergency autodial 7
                                ; 01E0 emergency autodial 8
                                ; 01F0 emergency autodial 9

; ******************************************
; ******************************************
; **  6 4 K   E E P R O M   2 5 L C 6 4 0 **
; ******************************************
; ******************************************

; area code tables start at 0x0200, and are 0x80 long each.
; index byte  76543210
;                 ||||
;                 ///\
; eeaddress 76543210 76543210
;              hi       lo

EEACOFF equ     h'70'           ; area code offset
EEAFOFF equ     h'73'           ; area code flags offset
EELSTAC equ     d'15'           ; last area code number
EEACMSK	equ	b'11110000'	; invalid area code index mask.
EEACPFX equ     h'74'           ; area code dial prefix offset.
EEACPFL equ     d'10'           ; max length of area code dial prefix.
EEACSFL equ	09f3		; special flags for last area code.
EEACSPF	equ	09f4		; prefix shortcut for last area code.
EEAC00  equ     0200            ; 0200  Patch Restriction Area Code 0
                                ; 0210  "
EEAC02  equ     0220            ; 0220  "
                                ; 0230  "
EEAC04  equ     0240            ; 0240  "
                                ; 0250  "
EEAC06  equ     0260            ; 0260  "
EEAC0B  equ     0270            ; 0270  area code 0 code offset
EEAC0F  equ     0273            ; 0273  area code 0 flags
EEAC0P  equ     0274            ; 0274  area code 0 dial prefix.
                                ; 0275  " 
                                ; 0276  " 
                                ; 0277  " 
                                ; 0278  " 
                                ; 0279  " 
                                ; 027a  " 
                                ; 027b  " 
                                ; 027c  " 
                                ; 027d  "
        
EEAC10  equ     0280            ; 0280  Patch Restrictions Area Code 1
                                ; 0290  "
EEAC12  equ     02A0            ; 02A0  "
                                ; 02B0  "
EEAC14  equ     02C0            ; 02C0  "
                                ; 02D0  "
EEAC16  equ     02E0            ; 02E0  "
EEAC1B  equ     02F0            ; 02F0  area code 1 code offset
EEAC1F  equ     02F3            ; 02F3  area code 1 flags
EEAC1P  equ     02F4            ; 02F4  area code 1 dial prefix.
                                ; 02F5  " 
                                ; 02F6  " 
                                ; 02F7  " 
                                ; 02F8  " 
                                ; 02F9  " 
                                ; 02Fa  " 
                                ; 02Fb  " 
                                ; 02Fc  " 
                                ; 02Fd  "
        
EEAC20  equ     0300            ; 0300  Patch Restrictions Area Code 2
                                ; 0310  "
EEAC22  equ     0320            ; 0320  "
                                ; 0330  "
EEAC24  equ     0340            ; 0340  "
                                ; 0350  "
EEAC26  equ     0360            ; 0360  "
EEAC2B  equ     0370            ; 0370  area code 2 code offset
EEAC2F  equ     0373            ; 0373  area code 2 flags
EEAC2P  equ     0374            ; 0374  area code 2 dial prefix.
                                ; 0375  " 
                                ; 0376  " 
                                ; 0377  " 
                                ; 0378  " 
                                ; 0379  " 
                                ; 037A  " 
                                ; 037B  " 
                                ; 037C  " 
                                ; 037D  "
        
EEAC30  equ     0380            ; 0380  Patch Restrictions Area Code 3
                                ; 0390  "
EEAC32  equ     03A0            ; 03A0  "
                                ; 03B0  "
EEAC34  equ     03C0            ; 03C0  "
                                ; 03D0  "
EEAC36  equ     03E0            ; 03E0  "
EEAC3B  equ     03F0            ; 03F0  area code 3 code offset
EEAC3F  equ     03F3            ; 03F3  area code 3 flags
EEAC3P  equ     03F4            ; 03F4  area code 3 dial prefix.
                                ; 03F5  " 
                                ; 03F6  " 
                                ; 03F7  " 
                                ; 03F8  " 
                                ; 03F9  " 
                                ; 03FA  " 
                                ; 03FB  " 
                                ; 03FC  " 
                                ; 03FD  "

EEAC40  equ     0400            ; 0400  Patch Restrictions Area Code 4
                                ; 0410  "
EEAC42  equ     0420            ; 0420  "
                                ; 0430  "
EEAC44  equ     0440            ; 0440  "
                                ; 0450  "
EEAC46  equ     0460            ; 0460  "
EEAC4B  equ     0470            ; 0470  area code 2 code offset
EEAC4F  equ     0473            ; 0473  area code 2 flags
EEA42P  equ     0474            ; 0474  area code 2 dial prefix.
                                ; 0475  " 
                                ; 0476  " 
                                ; 0477  " 
                                ; 0478  " 
                                ; 0479  " 
                                ; 047A  " 
                                ; 047B  " 
                                ; 047C  " 
                                ; 047D  "
        
EEAC50  equ     0480            ; 0480  Patch Restrictions Area Code 5
                                ; 0490  "
EEAC52  equ     04A0            ; 04A0  "
                                ; 04B0  "
EEAC54  equ     04C0            ; 04C0  "
                                ; 04D0  "
EEAC56  equ     04E0            ; 04E0  "
EEAC5B  equ     04F0            ; 04F0  area code 3 code offset
EEAC5F  equ     04F3            ; 04F3  area code 3 flags
EEAC5P  equ     04F4            ; 04F4  area code 3 dial prefix.
                                ; 04F5  " 
                                ; 04F6  " 
                                ; 04F7  " 
                                ; 04F8  " 
                                ; 04F9  " 
                                ; 04FA  " 
                                ; 04FB  " 
                                ; 04FC  " 
                                ; 04FD  "

EEAC60  equ     0500            ; 0500  Patch Restrictions Area Code 6
                                ; 0510  "
EEAC62  equ     0520            ; 0520  "
                                ; 0530  "
EEAC64  equ     0540            ; 0540  "
                                ; 0550  "
EEAC66  equ     0560            ; 0560  "
EEAC6B  equ     0570            ; 0570  area code 2 code offset
EEAC6F  equ     0573            ; 0573  area code 2 flags
EEAC6P  equ     0574            ; 0574  area code 2 dial prefix.
                                ; 0575  " 
                                ; 0576  " 
                                ; 0577  " 
                                ; 0578  " 
                                ; 0579  " 
                                ; 057A  " 
                                ; 057B  " 
                                ; 057C  " 
                                ; 057D  "
        
EEAC70  equ     0580            ; 0580  Patch Restrictions Area Code 7
                                ; 0590  "
EEAC72  equ     05A0            ; 05A0  "
                                ; 05B0  "
EEAC74  equ     05C0            ; 05C0  "
                                ; 05D0  "
EEAC76  equ     05E0            ; 05E0  "
EEAC7B  equ     05F0            ; 05F0  area code 3 code offset
EEAC7F  equ     05F3            ; 05F3  area code 3 flags
EEAC7P  equ     05F4            ; 05F4  area code 3 dial prefix.
                                ; 05F5  " 
                                ; 05F6  " 
                                ; 05F7  " 
                                ; 05F8  " 
                                ; 05F9  " 
                                ; 05FA  " 
                                ; 05FB  " 
                                ; 05FC  " 
                                ; 05FD  "

EEAC80  equ     0600            ; 0600  Patch Restrictions Area Code 8
                                ; 0610  "
EEAC82  equ     0620            ; 0620  "
                                ; 0630  "
EEAC84  equ     0640            ; 0640  "
                                ; 0650  "
EEAC86  equ     0660            ; 0660  "
EEAC8B  equ     0670            ; 0670  area code 2 code offset
EEAC8F  equ     0673            ; 0673  area code 2 flags
EEAC8P  equ     0674            ; 0674  area code 2 dial prefix.
                                ; 0675  " 
                                ; 0676  " 
                                ; 0677  " 
                                ; 0678  " 
                                ; 0679  " 
                                ; 067A  " 
                                ; 067B  " 
                                ; 067C  " 
                                ; 067D  "
        
EEAC90  equ     0680            ; 0680  Patch Restrictions Area Code 9
                                ; 0690  "
EEAC92  equ     06A0            ; 06A0  "
                                ; 06B0  "
EEAC94  equ     06C0            ; 06C0  "
                                ; 06D0  "
EEAC96  equ     06E0            ; 06E0  "
EEAC9B  equ     06F0            ; 06F0  area code 3 code offset
EEAC9F  equ     06F3            ; 06F3  area code 3 flags
EEAC9P  equ     06F4            ; 06F4  area code 3 dial prefix.
                                ; 06F5  " 
                                ; 06F6  " 
                                ; 06F7  " 
                                ; 06F8  " 
                                ; 06F9  " 
                                ; 06FA  " 
                                ; 06FB  " 
                                ; 06FC  " 
                                ; 06FD  "

EEACA0  equ     0700            ; 0700  Patch Restrictions Area Code 10
                                ; 0710  "
EEACA2  equ     0720            ; 0720  "
                                ; 0730  "
EEACA4  equ     0740            ; 0740  "
                                ; 0750  "
EEACA6  equ     0760            ; 0760  "
EEACAB  equ     0770            ; 0770  area code 2 code offset
EEACAF  equ     0773            ; 0773  area code 2 flags
EEACAP  equ     0774            ; 0774  area code 2 dial prefix.
                                ; 0775  " 
                                ; 0776  " 
                                ; 0777  " 
                                ; 0778  " 
                                ; 0779  " 
                                ; 077A  " 
                                ; 077B  " 
                                ; 077C  " 
                                ; 077D  "
        
EEACB0  equ     0780            ; 0780  Patch Restrictions Area Code 11
                                ; 0790  "
EEACB2  equ     07A0            ; 07A0  "
                                ; 07B0  "
EEACB4  equ     07C0            ; 07C0  "
                                ; 07D0  "
EEACB6  equ     07E0            ; 07E0  "
EEACBB  equ     07F0            ; 07F0  area code 3 code offset
EEACBF  equ     07F3            ; 07F3  area code 3 flags
EEACBP  equ     07F4            ; 07F4  area code 3 dial prefix.
                                ; 07F5  " 
                                ; 07F6  " 
                                ; 07F7  " 
                                ; 07F8  " 
                                ; 07F9  " 
                                ; 07FA  " 
                                ; 07FB  " 
                                ; 07FC  " 
                                ; 07FD  "

EEACC0  equ     0800            ; 0800  Patch Restrictions Area Code 12
                                ; 0810  "
EEACC2  equ     0820            ; 0820  "
                                ; 0830  "
EEACC4  equ     0840            ; 0840  "
                                ; 0850  "
EEACC6  equ     0860            ; 0860  "
EEACCB  equ     0870            ; 0870  area code 2 code offset
EEACCF  equ     0873            ; 0873  area code 2 flags
EEACCP  equ     0874            ; 0874  area code 2 dial prefix.
                                ; 0875  " 
                                ; 0876  " 
                                ; 0877  " 
                                ; 0878  " 
                                ; 0879  " 
                                ; 087A  " 
                                ; 087B  " 
                                ; 087C  " 
                                ; 087D  "
        
EEACD0  equ     0880            ; 0880  Patch Restrictions Area Code 13
                                ; 0890  "
EEACD2  equ     08A0            ; 08A0  "
                                ; 08B0  "
EEACD4  equ     08C0            ; 08C0  "
                                ; 08D0  "
EEACD6  equ     08E0            ; 08E0  "
EEACDB  equ     08F0            ; 08F0  area code 3 code offset
EEACDF  equ     08F3            ; 08F3  area code 3 flags
EEACDP  equ     08F4            ; 08F4  area code 3 dial prefix.
                                ; 08F5  " 
                                ; 08F6  " 
                                ; 08F7  " 
                                ; 08F8  " 
                                ; 08F9  " 
                                ; 08FA  " 
                                ; 08FB  " 
                                ; 08FC  " 
                                ; 08FD  "

EEACE0  equ     0900            ; 0900  Patch Restrictions Area Code 14
                                ; 0910  "
EEACE2  equ     0920            ; 0920  "
                                ; 0930  "
EEACE4  equ     0940            ; 0940  "
                                ; 0950  "
EEACE6  equ     0960            ; 0960  "
EEACEB  equ     0970            ; 0970  area code 2 code offset
EEACEF  equ     0973            ; 0973  area code 2 flags
EEACEP  equ     0974            ; 0974  area code 2 dial prefix.
                                ; 0975  " 
                                ; 0976  " 
                                ; 0977  " 
                                ; 0978  " 
                                ; 0979  " 
                                ; 097A  " 
                                ; 097B  " 
                                ; 097C  " 
                                ; 097D  "
        
EEACF0  equ     0980            ; 0980  Patch Restrictions Area Code 15
                                ; 0990  "
EEACF2  equ     09A0            ; 09A0  "
                                ; 09B0  "
EEACF4  equ     09C0            ; 09C0  "
                                ; 09D0  "
EEACF6  equ     09E0            ; 09E0  "
EEACFB  equ     09F0            ; 09F0  area code 3 code offset
EEACFF  equ     09F3            ; 09F3  area code 3 flags
EEACFP  equ     09F4            ; 09F4  area code 3 dial prefix.
                                ; 09F5  " 
                                ; 09F6  " 
                                ; 09F7  " 
                                ; 09F8  " 
                                ; 09F9  " 
                                ; 09FA  " 
                                ; 09FB  " 
                                ; 09FC  " 
                                ; 09FD  "

                                ; 09FF is last used address...
                                ; 09FF is last used address...
EEACLST	equ	09FF		; last address in area codes 

;; Autodial slots from 1000 - 1FFF (4K)
EEADBS  equ     1000            ; autodial base at 0400
EEADLST	equ	1FFF		; autodials end at 0FFF
EEADSZ  equ     0010            ; autodials get 16 bytes each.
        ;; room for 100H = 256 slots.
EEADNUM	equ	d'250'		; 250 autodials.

;; EEPROM Addresses
T_BASE  equ     h'00'           ; timers base address 
T_SIZE  equ     d'13'           ; number of bytes of timers
CW_BASE equ     h'10'           ; CW ID base addr
CW_SIZE equ     d'15'           ; max length
CT_BASE equ     h'20'           ; courtesy tone base
CT_SIZE equ     h'08'           ; size of CT
CT_MAX  equ     d'07'           ; last CT
PF_BASE equ     h'60'           ; base of prefixes
PF_SIZE equ     h'08'           ; size of prefix
PF_MAX  equ     d'15'           ; last prefix

        
CT_AD0  equ     h'20'
CT_AD1  equ     h'28'
CT_AD2  equ     h'30'
CT_AD3  equ     h'38'
CT_AD4  equ     h'40'
CT_AD5  equ     h'48'
CT_AD6  equ     h'50'
CT_AD7  equ     h'58'
