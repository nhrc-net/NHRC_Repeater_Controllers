<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-Remote Errata</title>
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-Remote</b></FONT><br>
<FONT SIZE=5><b><i>Errata</i></b></font>
</div>
This document includes corrections or additions to the NHRC-Remote
printed manual, and the <i>QST</i> article &quot;An Intelligent DTMF
Remote Controller.&quot;<p>
<font size=5><B><i>Corrections to the Printed Manual</i></b></font><p>
<blockquote>
The schematics in the printed manual (schematic rev. B2, May 18, 1999)
show R13 as 300K
ohm.  We have changed this part to 470K ohm to reduce false DTMF decodes.
If you installed a 300K ohm resistor in R13, you can safely leave
it there, unless you observe excessive false DTMF decodes.  This part
is correctly listed on the parts list.<p>
The parts list in the printed manual (parts list rev. B, May 18, 1999)
show R12 to be 10K ohm.  This is
incorrect, and the schematic shows the correct value for this part,
which is 1K ohm.<p>
</blockquote>
<font size=5><B><i>Corrections to the </i>QST<i> Article</i></b></font><p>
<blockquote>
The schematic and parts list in the QST article show R13 as 300K ohm.
We have changed this part to 470K ohm to reduce false DTMF decodes.
If you installed a 300K ohm resistor in R13, you can safely
leave it there, unless you observe excessive false DTMF decodes.<P>
The schematic and parts list in the QST article show R12 as 10K ohm.
This is incorrect.  The correct value for R12 is 1K ohm.<P>
In Table 2 of the QST article, the Morse code value shown for the letter
G is incorrect.  The hex value shown for G is correct.<p>
</blockquote>
<hr>
Back to <A HREF="/nhrc-remote/">NHRC-Remote Page</a>
<hr>
<?php
$copydate="1999-2005";
$version="1.11";
include '../barefooter.inc';
?>

