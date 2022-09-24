<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title></title>
<SCRIPT LANGUAGE="Javascript">
<!--hide
var CONFIG_ADDR     = 0x01
var HANG_ADDR       = 0x02
var TIMEOUT_ADDR    = 0x03
var ID_TIMER_ADDR   = 0x04
var TAIL_COUNT_ADDR = 0x05
var OK_MSG_ADDR     = 0x06
var OK_MSG_LENGTH   = 3
var NG_MSG_ADDR     = 0x09
var NG_MSG_LENGTH   = 3
var TO_MSG_ADDR     = 0x0c
var TO_MSG_LENGTH   = 3
var ID_MSG_ADDR     = 0x0f
var ID_MSG_LENGTH   = 28

var LAST_EEPROM_ADDRESS = 0x37
    
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
				0x00,
				0x32,
				0x1e,
				0x36,
				0x00,
				0x0f,
				0x0d, 
				0xff, /* 08 */
				0x05,
				0x0b,
				0xff,
				0x03,
				0x0f,
				0xff,
				0x09, /* 0f */
				0x02, /* 10 */
				0x00,
				0x05, /* 12 =N */
				0x10, /* 13 =H */
				0x0a, /* 14 =R */
				0x15, /* 15 =C */
				0x29, /* 16 =/ */
				0x3c, /* 17 =2 */
				0xff, /* 18 */
				0x00, 
				0x00, /* 1a */
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, /* 1f */ 
				0x00, /* 20 */
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, /* 28 */
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, /* 2f */ 
				0x00, /* 30 */
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00, 
				0x00) /* 37 */

var eeprom = new Array(LAST_EEPROM_ADDRESS)

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
    win.document.writeln("<html><head><title>Customized NHRC-2 Programming Data</title></head>");
    win.document.writeln("<body bgcolor=white>")
    win.document.writeln("<div align=center>")
    win.document.writeln("<font size=5><b>Customized NHRC-2 Programming Data</b></font><br>")
    win.document.writeln("Values different from defaults are indicated in <font color=red>red<font color=black>.")

    /* set config flags */
    eeprom[CONFIG_ADDR]=0x00
    if (document.nhrc2params.cboISDAbsent.checked)
        eeprom[CONFIG_ADDR] |= 0x01
    if (document.nhrc2params.cboSimplexMode.checked)
        eeprom[CONFIG_ADDR] |= 0x02
    if (document.nhrc2params.cboNoCourtesyTone.checked)
        eeprom[CONFIG_ADDR] |= 0x10
    if (document.nhrc2params.cboNoDTMFMuting.checked)
        eeprom[CONFIG_ADDR] |= 0x20
    if (document.nhrc2params.cboTailMsgCT.checked)
        eeprom[CONFIG_ADDR] |= 0x40

    /* set hang time */
    eeprom[HANG_ADDR] = parseInt(document.nhrc2params.txtHangTimer.value)

    /* set timeout time */
    eeprom[TIMEOUT_ADDR] = parseInt(document.nhrc2params.txtTimeoutTimer.value)

    /* set id time */
    eeprom[ID_TIMER_ADDR] = parseInt(document.nhrc2params.txtIDTimer.value)

    /* set tail message counter */
    eeprom[TAIL_COUNT_ADDR] = parseInt(document.nhrc2params.txtTailMessageCounter.value)

    /* do messages */

    convertMessage(document.nhrc2params.txtOK.value, OK_MSG_ADDR, OK_MSG_LENGTH)
    convertMessage(document.nhrc2params.txtNG.value, NG_MSG_ADDR, NG_MSG_LENGTH)
    convertMessage(document.nhrc2params.txtTO.value, TO_MSG_ADDR, TO_MSG_LENGTH)
    convertMessage(document.nhrc2params.txtID.value, ID_MSG_ADDR, ID_MSG_LENGTH)

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
	    win.document.write("</font></b>")
	}
	else
	{
	    win.document.write("<font color=black>")
	    writeHex(win,eeprom[i])
	    win.document.write("</font>")
	}
	win.document.writeln("</td></tr>")
    }  
    win.document.writeln("</table></td><td align=right><table border>")
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
	    win.document.write("</font></b>")
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
      
function writeHex(win, h)
{
    var n = h >> 4;
    writeNibble(win,n)
    n = h & 0x0f
    writeNibble(win,n)
} /* writeHex() */

function writeNibble(win, n)
{
    switch (n)
    {
        case 10:
            win.document.write("A")
            break;
        case 11:
            win.document.write("B")
            break;
        case 12:
            win.document.write("C")
            break;
        case 13:
            win.document.write("D")
            break;
        case 14:
            win.document.write("E")
            break;
        case 15:
            win.document.write("F")
            break;
        default:
            win.document.write(n)
            break
    } /* switch */
}
//-->
</script>
</head>

<body onLoad=init() bgcolor=white>
<h1></h1>
<form name="nhrc2params">
<div align=center>
<table>
  <tr>
    <td align=right>Confirmation Message</td>
    <td><input type="TEXT" name="txtOK" value="OK" size=2 maxlength=2></td>
  </tr>
  <tr>
    <td align=right>Bad Command Message</td>
    <td><input type="TEXT" name="txtNG" value="NG" size=2 maxlength=2></td>
  </tr>
  <tr>
    <td align=right>Timeout Message</td>
    <td><input type="TEXT" name="txtTO" value="TO" size=2 maxlength=2></td>
  </tr>
  <tr>
    <td align=right>ID Message</td>
    <td><input type="TEXT" name="txtID" value="DE NHRC/2" size=12 maxlength=12></td>
  </tr>
  <tr>
    <td align=right>Hang timer in tenths</td>
    <td><input type="TEXT" name="txtHangTimer" value="50" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right>Timeout timer in seconds</td>
    <td><input type="TEXT" name="txtTimeoutTimer" value="30" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right>ID timer in tens</td>
    <td><input type="TEXT" name="txtIDTimer" value="54" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right>Tail Message Counter</td>
    <td><input type="TEXT" name="txtTailMessageCounter" value="0" size=3 maxlength=3></td>
  </tr>
  <tr>
    <td align=right>ISD 1420 Absent</td>
    <td><input type="CHECKBOX" name="cboISDAbsent"></td>
  </tr>
  <tr>
    <td align=right>Simplex Repeater Mode</td>
    <td><input type="CHECKBOX" name="cboSimplexMode"></td>
  </tr>
  <tr>
    <td align=right>Suppress Courtesy Tone</td>
    <td><input type="CHECKBOX" name="cboNoCourtesyTone"></td>
  </tr>
  <tr>
    <td align=right>Suppress DTMF Muting</td>
    <td><input type="CHECKBOX" name="cboNoDTMFMuting"></td>
  </tr>
  <tr>
    <td align=right>Use Tail Message for Courtesy Tone</td>
    <td><input type="CHECKBOX" name="cboTailMsgCT"></td>
  </tr>
  <tr>
    <td align=right><input type="RESET" value="Reset"></td>
    <td align=left><input type="BUTTON" value="Convert" onClick=convert()></td>
  </tr>
</table>
</div>
</form>
<hr>
Back to the <a href="index.php">NHRC-2 Repeater Controller</a> page.
<hr>
<?php
$copydate="1996-2005";
$version="1.11";
include '../barefooter.inc';
?>
