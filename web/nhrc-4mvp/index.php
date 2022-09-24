<?php
$title = "NHRC-4/MVP Repeater Controller";
$category = "retired";
$item = "nhrc4mvp";
$description="The NHRC-4/MVP Repeater Controller, an integrated repeater controller for the GE Custom MVP.";
$keywords="NHRC-4/MVP, repeater controller, NHRC, MVP, linking repeater controller";
$version="1.6";
$copydate="2000-2017";
include "../header.inc";
?>
<div class="pageHeadCentered">NHRC-4/MVP Repeater Controller</div>
<div class="pageHeadCentered">An Integrated <i>Linking</i> Repeater Controller<br>
for General Electric Custom MVP Radios</div>
<p>
<table border=0 width="100%">
  <tr>
    <td>
The NHRC-4/MVP is a specialized version of our <a href="/nhrc-4/">
NHRC-4</a> linking repeater controller, designed for installation inside a 
General Electric Custom MVP transceiver.  The controller installs in place
of of the GE channel-guard board.<p>
The controller
has a &quot;primary&quot; and a &quot;secondary&quot; radio port.  The 
primary port is used for the controlling repeater, and the secondary port
can be used for a remote base, link radio, or &quot;slaved&quot; repeater.
Unique courtesy tones provide feedback of the input source and link state.
<p>
The controller is programmable by sending DTMF sequences.  The CW ID, hang
time, ID timer, timeout timer and tail message counter can all be 
programmed by the user.  All programming is password-protected, and is
stored in non-volatile EEPROM memory.
</td>
    <td align=center valign=top>
<a href="nhrc-4mvp-image.php"><img src="nhrc-4mvp-small.jpg" width=300 height=274 alt="[Picture of NHRC-4/MVP Controller]" border=0></a><br>
Click image to view a bigger picture,<br>
and an image of the controller<br>
installed in a Custom MVP.
    </td>	
  </tr>
</table>
<div class="productFeatures">Features:</div>
<ul>
  <li>Easily installs into a Custom MVP, producing a complete, compact repeater.
  <li>Secondary port can be remote base, link radio or slaved duplex repeater.
  <li>&quot;Intelligent&quot; ID algorithm.
  <li>Distinctive Courtesy Tones can indicate channel activity:
  <ul>
    <li>primary receiver courtesy tone.
    <li>primary receiver courtesy tone, secondary port transmit enabled.
    <li>secondary receiver courtesy tone.
    <li>secondary receiver courtesy tone, secondary port transmit enabled.
    <li>primary receiver courtesy tone, secondary receiver active, alert mode selected.
  </ul>
  <li>1 Digital output:
  <ul>
    <li>Fan control (runs when transmitter on and n minutes after).
    <li>On/Off/Pulse commands.
    <li>Open-collector output.
  </ul>
  <li>Touch-Tone remote control and programming.
  <li>Hang timer, ID timer, Timeout timers, Fan Timer, and CW messages stored in non-volatile memory.
  <li>Individual audio gating on each port allows use of non-squelched receiver audio.
  <li>LED <img src="../resources/green-ball.gif" width=12 height=12>CAS,
      <img src="../resources/red-ball.gif" width=12 height=12>PTT,
      and <img src="../resources/yellow-ball.gif" width=12 height=12>DTMF indicators
      for primary port.<br>
      <img src="../resources/green-ball.gif" width=12 height=12>CAS and
      <img src="../resources/red-ball.gif" width=12 height=12>PTT indicators for secondary port.
  <li>Extremely low power consumption.
</ul>
<div class="productFeatures">Documentation:</div>
<blockquote>
<b>Version 3.0 Manuals</b><p>
<ul>
  <li><a href="NHRC-4_Operating_Manual.pdf">NHRC-4 Operating Manual</a>
      <img src="/resources/pdficonsmall.gif" width=22 height=24 border=0 alt="PDF icon"> (~150KB)
  <li><a href="NHRC-4MVP_Installation_and_Setup_Guide.pdf">NHRC-4/MVP Installation and Setup Guide</a>
      <img src="/resources/pdficonsmall.gif" width=22 height=24 border=0 alt="PDF icon"> (~956KB)
  </ul>
<b>Prior Versions Manuals</b><p>
<ul>
  <li><a href="/nhrc-4/nhrc4prog.php">NHRC-4 Series Programming Information Generator</a>
  <li><a href="/nhrc-4/nhrc4ref.php">NHRC-4 Series Quick Reference</a>
  <li><a href="/nhrc-4/operating.php">Operating the NHRC-4 Series Repeater Controllers</a>
  <li><a href="nhrc-4mvp-manual.pdf">NHRC-4/MVP User Guide</a>
      <img src="/resources/pdficonsmall.gif" width=22 height=24 border=0 alt="PDF icon"> (1500K)
</ul>
</blockquote>
<div class="productFeatures">Accessories:</div>
<ul>
    <li><a href="/nhrc-dad-2/index.php">NHRC-DAD-2</a> Digital Audio Delay
</ul>
<div class="productFeatures">Pricing:</div>
<blockquote>
  <table border=0 cellspacing=2>
    <tr>
      <td bgcolor=#00ccff valign=top>NHRC-4/MVP</td>
      <td bgcolor=#00ccff>Integrated Linking Repeater Controller<br>
                          for GE Custom MVP</td>
      <td bgcolor=#00ccff align=right valign=top>Retired Producrt<br>
Special Order Only<br>
Contact Factory</td>
    </tr>
    <tr>
      <td bgcolor=#00ffcc valign=top><a href="/nhrc-4/version-3-features.php">NHRC-4 Version 3.0 Upgrade</a></td>
      <td bgcolor=#00ffcc>Includes new microcontroller IC and printed documentation</td>
      <td bgcolor=#00ffcc align=right valign=top>$29.00</td>
    </tr>
    <tr>
      <td bgcolor=#00ccff valign=top>Shipping &amp; Handling</td>
      <td bgcolor=#00ccff>&nbsp;</td>
      <td bgcolor=#00ccff>See <a href="/shipping.php">Shipping Info</a></td>
    </tr>
  </table>
</blockquote>
<?php include '../footer.inc'; ?>
