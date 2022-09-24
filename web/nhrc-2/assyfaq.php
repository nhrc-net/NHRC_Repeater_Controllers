<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>Frequently Asked Questions about Assembling a Partial Kit</title>
<meta name="description" content="Questions and answers about assembling a NHRC-2 Repeater Controller partial kit.">
<meta name="keywords" content="NHRC-2 assembly">
</head>
<body bgcolor=white>
<FONT SIZE=6><b><center>NHRC-2 Repeater Controller</center></b></FONT>
<font size=5><b><center>Frequently Asked Questions about Assembling a Partial Kit
</b></font></center><p>
<hr>
<table border=0 cellpadding=3>
<tr><td colspan=2><b>I can't find a IRL530.  Is there another part I can use for Q6?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
The closest subtitution is the IRL530N (Digi-Key P/N: IRL530N-ND). 
It's the next generation device, and just a bit more expensive.  ($1.66 each in 1-9 qty.) 
Digi-Key has stock on this item. Just about any N-channel TO-220 MOSFET will work here;
the pinouts are pretty much standard. We chose the IRL530 for it's low "Rds on" value 
(about 0.16 ohms) and because it is a "logic-level" device, meaning a 5 volt level on 
the gate will turn the device fully "on". Other good values would include the IRL510 &amp;
IRL520, IRF 510 and the new IRL520N &amp; IRL540N. Harris part RFD15N05L (available thru 
Newark) is also a good sub.  Radio Shack has the IRF510 in their catalog.
</td><td width=10%></td></tr>
<tr><td colspan=2><b>I have some ISD1020s lying around.  Can I use them in the NHRC2?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
Not easily.  The ISD1000 series parts use a slightly different interface for record/play, 
power down, and chip select.  To use a ISD1000 series part would require some changes to 
the PC board, and some software changes as well.   These changes are not impossible, in 
fact the original prototype controller used an ISD1020, but the ISD1420 is a less 
expensive, newer part.
</td><td width=10%></td></tr>
<tr><td colspan=2><b>In looking at the parts placement diagram in the back 
of the manual supplied with the kit, it looks like the pinout shown for Q2
does not match any 2N2222 made on this planet.  What gives?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
Ouch.  We goofed.  The correct pinout pinout for Q2 is EBC.  The orientation 
shown is correct, it's just the labels for E and C are reversed.  Install 
the transistor with the flat side facing the end of the board with the DB9 
connector.
</td><td width=10%></td></tr>

<tr><td colspan=2><b>How come my DB9 connector mounting holes do not line
up with the holes on the board?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
The NorComp part listed in the BOM indeed does have the wrong 
offset, and Digi-Key does not offer a correct sub. Newark Electronics
P/N: 89F1583 (SPC DE9S-FRS $2.96ea. 1-24pcs.) or Newark P/N: 87F2251 
(Amphenol 617-C009S-AJ120 $1.99ea. 1-24pcs.) both devices 
have the proper offset (0.318&quot;) and boardmount locks, however the 
Amphenol part does not come with jack screws, but are available 
separately using Newark P/N: 50F4689 (Keystone 7228 $0.16ea.)
Some kit builders have reported that the AMP Amplimite 754781-4
(Digikey A2100-ND), will fit in the board, but extreme care must be taken
if this part is used to make sure that none of the traces on the PC board
under the connector are shorted out.  Use some electrical tape or mylar
sheet to insulate the connector housing from the board.
The Amphenol 617-C009S is the preferred part.
</td><td width=10%></td></tr>

<tr><td colspan=2><b>I built my controller, and it doesn't work.  What can I do?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
Look at the <a href="troubles.php">Troubleshooting Information</a> page for some ideas to
get your controller running.
</td><td width=10%></td></tr>

<tr><td colspan=2><b>I want to build a controller without the ISD1420, for use
as a link controller.  What parts are not needed?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
You can leave the following parts off the board:
<blockquote><pre>
C5, C9, C12, C15, C18, C23, C24, C25
Q3, Q4
R9, R10, R13, R20, R21, R24, R25, R26, R27, R28
U2
VR3, VR5
</pre></blockquote>
Remember to set bit 0 of the configuration flag bits to indicate to the microprocessor that the ISD1420 is not present.
Consider setting bits 4 and 5 as well, depending on your linking requirements.
</td><td width=10%></td></tr>
<tr><td colspan=2><b>What's all this about deemphasis, and why should I care?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
Deemphasis is used to remove the preemphasis put on a FM signal by the transmitter.
    Together, they work to reduce the amount of hiss you hear in a received FM signal.
    The concept is similar to Dolby noise reduction:  the transmitted signal has the
    high-frequency component boosted before tranmission, then a corresponding reduction
    occurs in the receiver.  The receiver removing a significant part of the
    high-frequency component of the received signal actually removes a lot of hiss and
    noise with it.<p>
    If you use receiver audio that has not been deemphasized (like what is commonly
    found on the high side of the squelch control), then the repeated audio will sound
    very tinny and unnatural.  However, the high side of the squelch control is a good
    place to take audio from a receiver used in a repeater because the audio there is not
    subject to level changes caused by the volume control.  In many radios, the
    deemphasis filter is &quot;downstream&quot; of the volume control, which makes taking
    audio from there unattractive.<p>
    The NHRC-2 has the capability to perform deemphasis filtering on board.  To use the
    onboard filter, some parts substitutions must be performed.  It is probably easier
    to decide whether you want the filter or not <i>before</i> soldering part to the
    board.<p>
    <center><table border>
      <tr><th>Component</th><th>No Deemphasis</th><th>With Deemphasis</th></tr>
      <tr><td align=center>C3</td><td align=center>not present</td><td align=center>.0068uF</td></tr>
      <tr><td align=center>R3</td><td align=center>100K</td><td align=center>51K</td></tr>
      <tr><td align=center>R4</td><td align=center>100K</td><td align=center>510K</td></tr>
    </table></center>    
</td><td width=10%></td></tr>
<tr><td colspan=2><b>There seems to be some distortion in the repeated audio.  What
can I do?</b></td>
<td width="10%"></td></tr><tr><td width="10%"></td><td>
Try replacing U5 (the LM358) with a TL062, or install a 4.7K resistor from U5 pin 7 to
ground.  Do not use both modifications.
</td><td width=10%></td></tr>
</table>
<hr>
<center><b><i>This page will be updated as we discover more frequently asked questions.
You may want to check back often.</i></b></center>
<hr>
Back to the <a href="index.php">NHRC-2 Repeater Controller</a> page.
<hr>
<?php
$copydate="1996-2005";
$version="1.11";
include '../barefooter.inc';
?>
