<?php
$title = "NHRC-10 Software Upgrade Information";
$category = "controllers";
$item = "nhrc10";
$version="1.21";
$copydate="2000-2004";
include "../header.inc";
?>
<font size=5><b>NHRC-10 Firmware Updates</b></font>
<p>
NHRC is pleased to announce NHRC-10 Firmware version 1.14.<p>
The following corrections or changes have been made since version 1.00.<p>
<div align="center">
<table border=1 cellpadding=2 width=90%>
  <tr>
    <td colspan=3 align=center>
    <font size=4><b>NHRC-10 Firmware Version History<b></font></td>
  </tr>
  <tr>
    <td><b>Version</b></td>
    <td><b>Release Date</b></td>
    <td><b>Description of Changes</b></td>
  </tr>

  <tr>
    <td>1.00</td>
    <td>05/07/2000</td>
    <td>Initial release of NHRC-10 firmware.</td>
  </tr>

  <tr>
    <td>1.01</td>
    <td>07/09/2000</td>
    <td>Added support for dialing prefix for autopatch area codes.</td>
  </tr>

  <tr>
    <td valign=top>1.02</td>
    <td valign=top>09/07/2000</td>
    <td>Fix for slaved repeater mode.<br>
        Fix for CI-V invalid frequency entry.</td>
  </tr>

  <tr>
    <td valign=top>1.03</td>
    <td valign=top>09/09/2000</td>
    <td>Fixes for area code readback, initialization bug for area codes, race condition in tone generation.</td>
  </tr>

  <tr>
    <td valign=top>1.04</td>
    <td valign=top>09/25/2000</td>
    <td>Fix for link port slaved repeater mode turn off.</td>
  </tr>

  <tr>
    <td valign=top>1.05</td>
    <td valign=top>11/17/2000</td>
    <td>Fix for zero hang time problem.</td>
  </tr>

  <tr>
    <td valign=top>1.06</td>
    <td valign=top>04/16/2001</td>
    <td>Fix for improper CI-V mode readback for &quot;FM&quot;</td>
  </tr>

  <tr>
    <td valign=top>1.07</td>
    <td valign=top>05/20/2001</td>
    <td>Support for 16 area codes with 25LC640.</td>
  </tr>

  <tr>
    <td valign=top>1.08</td>
    <td valign=top>08/21/2001</td>
    <td>Added support for CW letter courtesy tone.<br>
        Added support to optionally mute DTMF by dropping PTT, rather than muting audio.<br>
	Added remote base idle shutoff timer.<br>
	Added feature to allow phone patch dialed number feedback to be 
	optionally suppressed.</td>
  </tr>

  <tr>
    <td valign=top>1.10</td>
    <td valign=top>11/10/2001</td>
    <td>Mute remote base audio when controller is talking.<br>
        Fix for remote base muting during DTMF access mode.</td>
  </tr>

  <tr>
    <td valign=top>1.11</td>
    <td valign=top>12/17/2001</td>
    <td>Fix No ID problem when remote base is active but repeater is idle.<br>
        Fix bug that allowed commands to be accepted when controller is in 
	DTMF access mode.<br>
	Fix bug that would play disabled message after leaving DTMF access 
	mode.</td>
  </tr>

  <tr>
    <td valign=top>1.12</td>
    <td valign=top>12/04/2002</td>
    <td>Ignore DTMF on main and link inputs unless CAS/CTCSS inputs are valid.<BR>
        LiTZ now works on link port.</td>
  </tr>

  <tr>
    <td valign=top>1.13</td>
    <td valign=top>12/23/2002</td>
    <td>Changed command prefix 10 from audio test to digital output control.</td>
  </tr>

  <tr>
    <td valign=top>1.14</td>
    <td valign=top>06/09/2003</td>
    <td>Fix for drop ptt to mute DTMF not re-asserting PTT fast enough.<br> 
        Enable both CTCSS Required and Dual-Squelch modes to require CTCSS when 
        the repeater is idle, and use carrier squelch the rest of the time.
        (This allows a 1750 Hz decoder to be used on the CTCSS input.)<br> 
        Automatically disable CI-V tune mode when either remote base auto-shutoff
        timer ends or DTMF access mode timer times out.</td>
  </tr>

  <tr>
    <td valign=top>1.20</td>
    <td valign=top>11/01/2004</td>
    <td>Support for NHRC-10 Programming Software.</td>
  </tr>


</table>
</div>
<P>
To order upgraded firmware, please contact the factory.<P>
Back to <a href="/nhrc-10/">NHRC-10</a>
<?php include '../footer.inc'; ?>
