<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-4 Programming Information Generator</title>
<meta name="description" content="NHRC-4 Repeater Controller Programming Information Generator">
<meta name="keywords" content="NHRC-4 programming">
<SCRIPT LANGUAGE="Javascript">
<!--hide
var HEX_DIGITS = "0123456789ABCDEF"

var CONFIG_ADDR      = 0x01
var DOUT_ADDR        = 0x02
var HANG_ADDR        = 0x03
var TIMEOUT_ADDR     = 0x04
var RB_TIMEOUT_ADDR  = 0x05
var ID_TIMER_ADDR    = 0x06
var FAN_TIMER_ADDR   = 0x07

var CT1_ADDR         = 0x08
var CT12_ADDR        = 0x09
var CT1A_ADDR        = 0x0a
var CT2_ADDR         = 0x0b
var CT22_ADDR        = 0x0c

var OK_MSG_ADDR      = 0x0e
var OK_MSG_LENGTH    = 6
var NG_MSG_ADDR      = 0x14
var NG_MSG_LENGTH    = 6
var TO_MSG_ADDR      = 0x1a
var TO_MSG_LENGTH    = 6
var RB_TO_MSG_ADDR   = 0x20
var RB_TO_MSG_LENGTH = 6
var ID_MSG_ADDR      = 0x26
var ID_MSG_LENGTH    = 20

var LAST_EEPROM_ADDRESS = 0x3b

var CWINDEXER = " !#=/0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
var  CWMASK = new Array (0x00, /* space */
                         0x68, /* ! SK */
		         0x2a, /* # AR */
			 0x31, /* = BT */
			 0x29, /* / */
			 0x3f, /* 0 */
			 0x3e, /* 1 */
			 0x3c, /* 2 */
			 0x38, /* 3 */
			 0x30, /* 4 */
			 0x20, /* 5 */
			 0x21, /* 6 */
			 0x23, /* 7 */
			 0x27, /* 8 */
			 0x2f, /* 9 */
			 0x06, /* a */
			 0x11, /* b */
			 0x15, /* c */
			 0x09, /* d */
			 0x02, /* e */
			 0x14, /* f */
			 0x0b, /* g */
			 0x10, /* h */
			 0x04, /* i */
			 0x1e, /* j */
			 0x0d, /* k */
			 0x12, /* l */
			 0x07, /* m */
			 0x05, /* n */
			 0x0f, /* o */
			 0x16, /* p */
			 0x1b, /* q */
			 0x0a, /* r */
			 0x08, /* s */
			 0x03, /* t */
			 0x0c, /* u */
			 0x18, /* v */
			 0x0e, /* w */
			 0x19, /* x */
			 0x1d, /* y */
			 0x13) /* z */
    
var eeprom_defaults = new Array(0x01, /* 00 */
				0x00, /* 01 */
				0x00, /* 02 */
                                0x32, /* 03 */
				0xb4, /* 04 */
				0xb4, /* 05 */
				0x36, /* 06 */
				0x0c, /* 07 */
				0x01, /* 08 */
				0x11, /* 09 */ 
				0x31, /* 0a */ 
				0x03, /* 0b */ 
				0x33, /* 0c */ 
				0x00, /* 0d */ 
				0x0f, /* 0e = O */
				0x0d, /* 0f = K */
				0xff, /* 10 = eom */
				0xff, /* 11 */
				0xff, /* 12 */
				0xff, /* 13 */
				0x05, /* 14 = N */
				0x0b, /* 15 = G */
				0xff, /* 16 = eom */
				0xff, /* 17 */
				0xff, /* 18 */
				0xff, /* 19 */
				0x03, /* 1a = T */
				0x0f, /* 1b = 0 */
				0xff, /* 1c = eom */
				0xff, /* 1d */
				0xff, /* 1e */
				0xff, /* 1f */
				0x0a, /* 20 = R */
				0x11, /* 21 = B */
				0x00, /* 22 = space */
				0x03, /* 23 = T */
				0x0f, /* 24 = O */
				0xff, /* 25 = eom */
				0x09, /* 26 = D */
				0x02, /* 27 = E */ 
				0x00, /* 28 = space */  
				0x05, /* 29 = N */  
				0x10, /* 2a = H */
				0x0a, /* 2b = R */ 
				0x15, /* 2c = C */ 
				0x29, /* 2d = / */ 
				0x30, /* 2e = 4 */ 
				0xff, /* 2f = eom */ 
				0xff, /* 30 */  
				0xff, /* 31 */ 
				0xff, /* 32 */
				0xff, /* 33 */
				0xff, /* 34 */
				0xff, /* 35 */
				0xff, /* 36 */
				0xff, /* 37 */
				0xff, /* 38 */
				0xff, /* 39 */
				0xff, /* 3a */
				0xff) /* 3b */

var eeprom = new Array(LAST_EEPROM_ADDRESS)
//var win

function init()
{
    var i;
    for (i=0; i <= LAST_EEPROM_ADDRESS; i++)
    {
        eeprom[i] = eeprom_defaults[i]
    } /* for */
} /* init() */

function convert()
{
    win = window.open("",'newWin',
       'toolbar=1,location=0,directories=0,status=1,menubar=1,scrollbars=1,resizable=1,width=500,height=500')
    win.document.writeln("<html><head><title>Customized NHRC-4 Programming Data</title></head>");
    win.document.writeln("<body bgcolor=white>")
    win.document.writeln("<div align=center>")
    win.document.writeln("<font size=5><b>Customized NHRC-4 Programming Data</b></font><br>")
    win.document.writeln("Values different from defaults are indicated in <font color=red><b>bold red</b><font color=black>.<p>")

    /* set config flags */
    eeprom[CONFIG_ADDR]=0x00
    if (document.nhrc4params.cboSecondaryDuplex.checked)
        eeprom[CONFIG_ADDR] |= 0x01
    if (document.nhrc4params.cboPrimaryDelay.checked)
        eeprom[CONFIG_ADDR] |= 0x02
    if (document.nhrc4params.cboSecondaryDelay.checked)
        eeprom[CONFIG_ADDR] |= 0x04
    if (document.nhrc4params.cboNoDTMFMuting.checked)
        eeprom[CONFIG_ADDR] |= 0x08
    if (document.nhrc4params.cboFanControl.checked)
        eeprom[CONFIG_ADDR] |= 0x10
    if (document.nhrc4params.cboMainPrio.checked)
        eeprom[CONFIG_ADDR] |= 0x20

    if (document.nhrc4params.cboMuteTxMain.checked)
        eeprom[CONFIG_ADDR] |= 0x40
    if (document.nhrc4params.cboMuteTxSecondary.checked)
        eeprom[CONFIG_ADDR] |= 0x80

    /* set hang time */
    eeprom[HANG_ADDR] = parseInt(document.nhrc4params.txtHangTimer.value)

    /* set primary timeout time */
    eeprom[TIMEOUT_ADDR] = parseInt(document.nhrc4params.txtPrimaryTimeoutTimer.value)

    /* set secondary timeout time */
    eeprom[RB_TIMEOUT_ADDR] = parseInt(document.nhrc4params.txtSecondaryTimeoutTimer.value)

    /* set id time */
    eeprom[ID_TIMER_ADDR] = parseInt(document.nhrc4params.txtIDTimer.value)

    /* do messages */

    convertMessage(document.nhrc4params.txtOK.value, OK_MSG_ADDR, OK_MSG_LENGTH)
    convertMessage(document.nhrc4params.txtNG.value, NG_MSG_ADDR, NG_MSG_LENGTH)
    convertMessage(document.nhrc4params.txtTO.value, TO_MSG_ADDR, TO_MSG_LENGTH)
    convertMessage(document.nhrc4params.txtRBTO.value, RB_TO_MSG_ADDR, RB_TO_MSG_LENGTH)
    convertMessage(document.nhrc4params.txtID.value, ID_MSG_ADDR, ID_MSG_LENGTH)

    convertCT(document.nhrc4params.cboCT1Seg1,
              document.nhrc4params.cboCT1Seg2,
              document.nhrc4params.cboCT1Seg3,
              document.nhrc4params.cboCT1Seg4,
              CT1_ADDR)

    convertCT(document.nhrc4params.cboCT12Seg1,
              document.nhrc4params.cboCT12Seg2,
              document.nhrc4params.cboCT12Seg3,
              document.nhrc4params.cboCT12Seg4,
              CT12_ADDR)

    convertCT(document.nhrc4params.cboCT1ASeg1,
              document.nhrc4params.cboCT1ASeg2,
              document.nhrc4params.cboCT1ASeg3,
              document.nhrc4params.cboCT1ASeg4,
              CT1A_ADDR)

    convertCT(document.nhrc4params.cboCT2Seg1,
              document.nhrc4params.cboCT2Seg2,
              document.nhrc4params.cboCT2Seg3,
              document.nhrc4params.cboCT2Seg4,
              CT2_ADDR)

    convertCT(document.nhrc4params.cboCT22Seg1,
              document.nhrc4params.cboCT22Seg2,
              document.nhrc4params.cboCT22Seg3,
              document.nhrc4params.cboCT22Seg4,
              CT22_ADDR)

    win.document.writeln("<table border=0 width=66%>")
    win.document.writeln("<tr><td align=left>")
    var i
    var j = LAST_EEPROM_ADDRESS / 2
    win.document.writeln("<table border>")
    win.document.writeln("<tr><th>Address</th><th>Data</th></tr>")
    for (i=0; i <= j;i++)
    {
        win.document.write("<tr><td>")
	writeHex(win, i)
	win.document.write("</td><td>")
	if (eeprom[i] != eeprom_defaults[i])
	{
	    win.document.write("<font color=red><b>")
	    writeHex(win,eeprom[i])
	    win.document.write("</b></font>")
	}
	else
	{
	    win.document.write("<font color=black>")
	    writeHex(win,eeprom[i])
	    win.document.write("</font>")
	}
	win.document.writeln("</td></tr>")
    }  
    win.document.writeln("</table>")
    win.document.writeln("</td><td align=right>")

    win.document.writeln("<table border>")
    win.document.writeln("<tr><th>Address</th><th>Data</th></tr>")
    for (; i <= LAST_EEPROM_ADDRESS;i++)
    {
        win.document.write("<tr><td>")
	writeHex(win, i)
	win.document.write("</td><td>")
	if (eeprom[i] != eeprom_defaults[i])
	{
	    win.document.write("<font color=red><b>")
	    writeHex(win,eeprom[i])
	    win.document.write("</b></font>")
	}
	else
	{
	    win.document.write("<font color=black>")
	    writeHex(win,eeprom[i])
	    win.document.write("</font>")
	}
	win.document.writeln("</td></tr>")
    }  
    win.document.writeln("</table>")
    win.document.writeln("</td></tr></table>")
    win.document.writeln("</div></body></html>")
    win.document.close()
} /* convert() */

function convertMessage(m, addr, len)
{
    l = m.length;
    l = Math.min(l, len-1)
    m = m.toUpperCase()
    for (i=0;i<l;i++)
    {
        c = m.charAt(i)
        j = CWINDEXER.indexOf(c)
        if (j == -1)
            j = 0
        eeprom[addr++] = CWMASK[j]
    } /* for i */
    eeprom[addr++] = 0xff
} /* convertMessage() */

function convertCT(s1, s2, s3, s4, addr)
{
    eeprom[addr] = 0;
    if (s1[1].checked)
        eeprom[addr] |= 0x01;
    if (s1[2].checked)
        eeprom[addr] |= 0x03;
    if (s2[1].checked)
        eeprom[addr] |= 0x04;
    if (s2[2].checked)
        eeprom[addr] |= 0x0c;
    if (s3[1].checked)
        eeprom[addr] |= 0x10;
    if (s3[2].checked)
        eeprom[addr] |= 0x30;
    if (s4[1].checked)
        eeprom[addr] |= 0x40;
    if (s4[2].checked)
        eeprom[addr] |= 0xc0;
} /* convertCT() */
    
function writeHex(win, h)
{
    var n = h >> 4;
    win.document.write(HEX_DIGITS.charAt(n))
    n = h & 0x0f
    win.document.write(HEX_DIGITS.charAt(n))
} /* writeHex() */

//-->
</script>
</head>

<body bgcolor=white onLoad=init()>
<div align=center>
<FONT SIZE=6><B>NHRC-4 Repeater Controller</B></FONT><br>
<FONT SIZE=5><B>Programming Information Generator</B></FONT>
</div>
    <p>
Use this page to quickly and easily generate programming information for the
NHRC-4 repeater controller.<p>
 Enter or select your settings below, then click
the <i>Generate</i> button to generate the programming information.  A new
window will open that contains the programming information.  Print and/or save
this window.  The data that is different than the default data provided when
the controller is initialized is displayed in <b><font color=red>bold red</font></b>.<br>
<HR>
<form name="nhrc4params">
<div align=center>
<table border=0 cellspacing=0 cellpadding=2>
  <tr>
    <th colspan=2 bgcolor=#ffff33><font size=4 color=black>M E S S A G E S</font></th>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Confirmation Message</td>
    <td bgcolor=#33cc99><input type="TEXT" name="txtOK" value="OK" size=5 maxlength=5></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Bad Command Message</td>
    <td bgcolor=#99ccff><input type="TEXT" name="txtNG" value="NG" size=5 maxlength=5></td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Primary Receiver Timeout Message</td>
    <td bgcolor=#33cc99><input type="TEXT" name="txtTO" value="TO" size=5 maxlength=5></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Secondary Receiver Timeout Message</td>
    <td bgcolor=#99ccff><input type="TEXT" name="txtRBTO" value="RB TO" size=5 maxlength=5</td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>ID Message</td>
    <td bgcolor=#33cc99><input type="TEXT" name="txtID" value="DE NHRC/4" size=20 maxlength=20></td>
  </tr>
  <tr>
    <th colspan=2 bgcolor=#ffff33><font size=4 color=black>T I M E R S</font></th>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Hang timer (tenths)</td>
    <td bgcolor=#33cc99><input type="TEXT" name="txtHangTimer" value="50" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Primary Receiver Timeout Timer (seconds)</td>
    <td bgcolor=#99ccff><input type="TEXT" name="txtPrimaryTimeoutTimer" value="180" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Secondary Receiver Timeout Timer (seconds)</td>
    <td bgcolor=#33cc99><input type="TEXT" name="txtSecondaryTimeoutTimer" value="180" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>ID timer (tens of seconds)</td>
    <td bgcolor=#99ccff><input type="TEXT" name="txtIDTimer" value="54" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Fan Timer delay (tens of seconds)</td>
    <td bgcolor=#33cc99><input type="TEXT" name="txtFanTimer" value="12" size=3 maxlength=3></td>
  </tr>
  <tr>
    <th colspan=2 bgcolor=#ffff33><font size=4 color=black>C O U R T E S Y&nbsp;&nbsp;&nbsp;T O N E S</font></th>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Primary Receiver Courtesy Tone</td>
    <td bgcolor=#33cc99>
	<table border>
	  <tr>
	    <th>Segment 1</th><th>Segment 2</th><th>Segment 3</th><th>Segment 4</th>
	  </tr>
	  <tr>
	    <td>
		<input type=radio name="cboCT1Seg1" value="none">None<br>
		<input type=radio name="cboCT1Seg1" value="beep" checked>Beep<br>
		<input type=radio name="cboCT1Seg1" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT1Seg2" value="none" checked>None<br>
		<input type=radio name="cboCT1Seg2" value="beep">Beep<br>
		<input type=radio name="cboCT1Seg2" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT1Seg3" value="none" checked>None<br>
		<input type=radio name="cboCT1Seg3" value="beep">Beep<br>
		<input type=radio name="cboCT1Seg3" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT1Seg4" value="none" checked>None<br>
		<input type=radio name="cboCT1Seg4" value="beep">Beep<br>
		<input type=radio name="cboCT1Seg4" value="boop">Boop
	    </td>
	  </tr>
       </table>
    </td>
  </tr>

  <tr>
    <td align=right bgcolor=#99ccff>Primary Receiver Courtesy Tone<br>
    Seondary Receiver Alert Mode</td>
    <td bgcolor=#99ccff>
	<table border>
	  <tr>
	    <th>Segment 1</th><th>Segment 2</th><th>Segment 3</th><th>Segment 4</th>
	  </tr>
	  <tr>
	    <td>
		<input type=radio name="cboCT1ASeg1" value="none">None<br>
		<input type=radio name="cboCT1ASeg1" value="beep" checked>Beep<br>
		<input type=radio name="cboCT1ASeg1" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT1ASeg2" value="none" checked>None<br>
		<input type=radio name="cboCT1ASeg2" value="beep">Beep<br>
		<input type=radio name="cboCT1ASeg2" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT1ASeg3" value="none">None<br>
		<input type=radio name="cboCT1ASeg3" value="beep">Beep<br>
		<input type=radio name="cboCT1ASeg3" value="boop" checked>Boop
	    </td>
	    <td>
		<input type=radio name="cboCT1ASeg4" value="none" checked>None<br>
		<input type=radio name="cboCT1ASeg4" value="beep">Beep<br>
		<input type=radio name="cboCT1ASeg4" value="boop">Boop
	    </td>
	  </tr>
       </table>
    </td>
  </tr>

  <tr>
    <td align=right bgcolor=#33cc99>Primary Receiver Courtesy Tone<br>
    Secondary Transmitter Enabled</td>
    <td bgcolor=#33cc99>
	<table border>
	  <tr>
	    <th>Segment 1</th><th>Segment 2</th><th>Segment 3</th><th>Segment 4</th>
	  </tr>
	  <tr>
	    <td>
		<input type=radio name="cboCT12Seg1" value="none">None<br>
		<input type=radio name="cboCT12Seg1" value="beep" checked>Beep<br>
		<input type=radio name="cboCT12Seg1" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT12Seg2" value="none" checked>None<br>
		<input type=radio name="cboCT12Seg2" value="beep">Beep<br>
		<input type=radio name="cboCT12Seg2" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT12Seg3" value="none">None<br>
		<input type=radio name="cboCT12Seg3" value="beep" checked>Beep<br>
		<input type=radio name="cboCT12Seg3" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT12Seg4" value="none" checked>None<br>
		<input type=radio name="cboCT12Seg4" value="beep">Beep<br>
		<input type=radio name="cboCT12Seg4" value="boop">Boop
	    </td>
	  </tr>
       </table>
    </td>
  </tr>

  <tr>
    <td align=right bgcolor=#99ccff>Secondary Receiver Courtesy Tone</td>
    <td bgcolor=#99ccff>
	<table border>
	  <tr>
	    <th>Segment 1</th><th>Segment 2</th><th>Segment 3</th><th>Segment 4</th>
	  </tr>
	  <tr>
	    <td>
		<input type=radio name="cboCT2Seg1" value="none">None<br>
		<input type=radio name="cboCT2Seg1" value="beep">Beep<br>
		<input type=radio name="cboCT2Seg1" value="boop" checked>Boop
	    </td>
	    <td>
		<input type=radio name="cboCT2Seg2" value="none" checked>None<br>
		<input type=radio name="cboCT2Seg2" value="beep">Beep<br>
		<input type=radio name="cboCT2Seg2" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT2Seg3" value="none" checked>None<br>
		<input type=radio name="cboCT2Seg3" value="beep">Beep<br>
		<input type=radio name="cboCT2Seg3" value="boop">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT2Seg4" value="none" checked>None<br>
		<input type=radio name="cboCT2Seg4" value="beep">Beep<br>
		<input type=radio name="cboCT2Seg4" value="boop">Boop
	    </td>
	  </tr>
       </table>
    </td>
  </tr>

  <tr>
    <td align=right bgcolor=#33cc99>Secondary Receiver Courtesy Tone<br>
    Secondary Transmitter Enabled</td>
    <td bgcolor=#33cc99>
	<table border>
	  <tr>
	    <th>Segment 1</th><th>Segment 2</th><th>Segment 3</th><th>Segment 4</th>
	  </tr>
	  <tr>
	    <td>
		<input type=radio name="cboCT22Seg1" value="none">None<br>
		<input type=radio name="cboCT22Seg1" value="beep">Beep<br>
		<input type=radio name="cboCT22Seg1" value="beep" checked>Boop
	    </td>
	    <td>
		<input type=radio name="cboCT22Seg2" value="none" checked>None<br>
		<input type=radio name="cboCT22Seg2" value="beep">Beep<br>
		<input type=radio name="cboCT22Seg2" value="beep">Boop
	    </td>
	    <td>
		<input type=radio name="cboCT22Seg3" value="none">None<br>
		<input type=radio name="cboCT22Seg3" value="beep">Beep<br>
		<input type=radio name="cboCT22Seg3" value="beep" checked>Boop
	    </td>
	    <td>
		<input type=radio name="cboCT22Seg4" value="none" checked>None<br>
		<input type=radio name="cboCT22Seg4" value="beep">Beep<br>
		<input type=radio name="cboCT22Seg4" value="beep">Boop
	    </td>
	  </tr>
       </table>
    </td>
  </tr>

  <tr>
    <th colspan=2 bgcolor=#ffff33><font size=4 color=black>C O N T R O L&nbsp;&nbsp;&nbsp;F L A G S</font></th>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Secondary Port is Duplex Repeater</td>
    <td bgcolor=#33cc99><input type="CHECKBOX" name="cboSecondaryDuplex"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Audio Delay on Primary Port</td>
    <td bgcolor=#99ccff><input type="CHECKBOX" name="cboPrimaryDelay"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Audio Delay on Secondary Port</td>
    <td bgcolor=#33cc99><input type="CHECKBOX" name="cboSecondaryDelay"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Suppress DTMF Muting</td>
    <td bgcolor=#99ccff><input type="CHECKBOX" name="cboNoDTMFMuting"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Use Digital Output for Fan Control</td>
    <td bgcolor=#33cc99><input type="CHECKBOX" name="cboFanControl"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Main Receiver Has Priority Over Link Receiver<font color=red>*</font></td>
    <td bgcolor=#99ccff><input type="CHECKBOX" name="cboMainPrio"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#33cc99>Drop Main Transmitter to Mute DTMF<font color=red>**</font></td>
    <td bgcolor=#33cc99><input type="CHECKBOX" name="cboMuteTxMain"></td>
  </tr>
  <tr>
    <td align=right bgcolor=#99ccff>Drop Secondary Transmitter to Mute DTMF<font color=red>**</font></td>
    <td bgcolor=#99ccff><input type="CHECKBOX" name="cboMuteTxSecondary"></td>
  </tr>
</table>
<font color=red>*</font>Software version &gt;= 1.4 only.<br>
<font color=red>**</font>Software version &gt;= 2.2 only.
<p>
<input type="RESET" value="Reset">
<input type="BUTTON" value="Generate" onClick=convert()>
</div>
</form>
<hr>
<a href="/nhrc-4/">NHRC-4 Repeater Controller Page</a><br>
<a href="/nhrc-4m2/">NHRC-4/M2 Repeater Controller Page</a><br>
<a href="/nhrc-4mvp/">NHRC-4/MVP Repeater Controller Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.31";
include '../barefooter.inc';
?>

