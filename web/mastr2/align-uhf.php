<?php
$title = "NHRC MASTR II InfoSite -- UHF MASTR II Alignment Instructions";
$category = "mastr2";
$item = "align-uhf";
$description="GE MASTR II mobile radio conversions: UHF Alignment Instructions.">
$keywords="UHF MASTR II Tune-Up Information";
$version="1.21";
$copydate="1997-2004";
include "../header.inc";
?>
<div align=center>
<font size=6><b>UHF MASTR II Alignment Instructions</b></font>
</div>
<p>
These instructions describe alignment of the RF assembly of the UHF MASTR II
receiver.  The IF and Mixer alignment is not included; it rarely needs to be
performed.  You will need to consult the GE MASTR II Maintenance Manual for
these instructions.
<p>
Some older receivers will not have the three trimmer capacitors (C406, C411,
and C416) on the Oscillator/Multiplier board, they will have three inductors
(L401, L402, and L403, from front to rear) with tunable slugs instead.  Follow
the directions as shown, but adjust L401 instead of C406, L402 instead of C411,
and L403 instead of C411.
<p>
<div align=center>
<font size=4><b>UHF MASTR II Receiver Alignment Controls Locations</b></font><br>
<img src="m2-rx-uhf.gif" width=494 height=531>
</div>
<p>
<div align=center>
<table border>
  <tr><th colspan=4><font size=5>UHF Receiver Alignment</font></th></tr>
  <tr><th>Step</th><th>Receiver<br>Metering<br>Jack Pin #</th><th>Test Set<br>Position</th><th>Instructions</th></tr>
  <tr>
    <td align=center>1</td>
    <td align=center>3</td>
    <td align=center>C</td>
    <td>Peak C406.  Set C411 and C416 in a similar position. Set C306, C307, and
	C308 fully CCW.</td>
  </tr>

  <tr>
    <td align=center>2</td>
    <td align=center>4</td>
    <td align=center>D</td>
    <td>Peak C411, then peak C416.  Peak C406, C411, then C416. Adjust C306 for
	some kind of meter response, either a peak or a dip.</td>
  </tr>

  <tr>
    <td align=center>3</td>
    <td align=center>7</td>
    <td align=center>F</td>
    <td>Peak C307, then C306.  Peak C307 and C306 again.  Dip C308, then peak
	C306.  Do not readjust C307 or C308.</td>
  </tr>

  <tr>
    <td align=center>4</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to
	C304.  Adjust the signal level for a slightly noisy signal.  Then, peak
	C305, C304, and A303-C2.  You may need to reduce the signal generator
	level one or more times to keep the received signal slightly noisy.
	Alternately reduce the generator level and adjust these three controls
	to obtain the largest peak meter indication with the lowest signal
	generator level.</td>
  </tr>
  
  <tr>
    <td align=center>5</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to
	C303.  Adjust the signal level for a slightly noisy signal.  Then, peak
	C304 and C303.  Use the same method as step 5 to obtain the largest
	peak meter indication with the lowest signal generator level.</td>
  </tr>
  
  <tr>
    <td align=center>6</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to
	C302. Peak C302 and C303 as above.
  </tr>
  
  <tr>
    <td align=center>7</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the antenna jack. Peak
	C301, C302, C303, C304, C305, and A302-C2. If the UHS preamplifier is
	present, peak T2301 as well.  Keep reducing the signal generator level
	to keep the received signal slightly noisy.  Peak C303 as above.</tr>
  
  <tr>
    <td align=center>8</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Leave signal injected on receiver's frequency into antenna jack.
	Carefully tune C306, C307, and C308 for best quieting.  Do not adjust
	more than 1/4 turn.  Then, carefully tune C301, C302, C303, C304, C305,
	and A302-C2 for peak meter indication and best sensitivity.
	A signal-to-noise analyzer can be helpful here.  Continue to tweak
	these 6 controls several times until no further improvement in
	sensitivity can be made.
  </tr>
</table>
</div>
<p>
Mixer and IF alignment is almost never required.  Do not attempt to align the
mixer or IF stages of the receiver without at least a signal-to-noise analyzer.
<p>
The frequency of the receiver ICOM can be adjusted by turning the trimmer
capacitor on the top of the ICOM.  The frequency can be measured directly with
a frequency counter connected to the junction of C416 and L403 on the
Oscillator/Multiplier board (frequency here should be
(receive frequency - 11.2) / 3) or the ICOM's frequency can be adjusted by
injecting a signal into the receiver from a known reliable source (signal
generator or service monitor) and tuning the ICOM for best receive sensitivity.
<p>
<hr>
These alignment instructions are for a UHF exciter, and conventional UHF PA.
They will not work for a &quot;tripler-PA&quot; radio.  The conventional UHF
exicter has 8 transformers in cans and 5 variable capacitors.  The tripler-PA
exciter has 10 transformers in cans and no variable capacitors.  Don't bother
with the tripler-PA transmitter; they are not suitable for repeater work.
<p>
All transmitter alignment measurements are performed with the transmitter keyed.
<B>Do not leave the transmitter keyed for an extended period until the alignment
is complete. </b> Make sure that a wattmeter and dummy load are connected to the
transmitter output.
<p>
<div align=center>
<font size=4><b>UHF MASTR II Transmitter Alignment Controls Locations</b></font><br>
<img src="m2-tx-uhf.gif" width=206 height=503>
</div>
<p>
<div align=center>
<table border>
  <tr><th colspan=4><font size=5>UHF Transmitter Alignment</font></td></tr>
  <tr><th>Step</th><th>Metering<br>Jack Pin #</th><th>Test Set<br>Position</th><th>Instructions</th></tr>
  <tr>
    <td align=center>1</td>
    <td align=center>1<br>(exciter)</td>
    <td align=center>b</td>
    <td>Peak T101. Dip T102. Peak T103.</td>
  </tr>
  
  <tr>
    <td align=center>2</td>
    <td align=center>3<br>(exciter)</td>
    <td align=center>C</td>
    <td>Peak T104.  Dip T105.</td>
  </tr>
  
  <tr>
    <td align=center>3</td>
    <td align=center>4<br>(exciter)</td>
    <td align=center>D</td>
    <td>Peak T106.  Dip T107.</td>
  </tr>
  
  <tr>
    <td align=center>4</td>
    <td align=center>7<br>(exciter)</td>
    <td align=center>F</td>
    <td>Peak T108. Dip C155.</td>
  </tr>
  
  <tr>
    <td align=center>5</td>
    <td align=center>6<br>(exciter)</td>
    <td align=center>G</td>
    <td>Peak C157. Dip C167.</td>
  </tr>
  
  <tr>
    <td align=center>6</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Meter is now on PA metering jack.  Peak C171 and C175.  </td>
  </tr>
  
  <tr>
    <td align=center>7</td>
    <td align=center>1<br>(exciter)</td>
    <td align=center>B</td>
    <td>Meter is now on exciter metering jack.  Peak T101.</td>
  </tr>

  <tr>
    <td align=center>8</td>
    <td align=center>3<br>(exciter)</td>
    <td align=center>C</td>
    <td>Peak T102. Peak T103. Peak T104.</td>
  </tr>

  <tr>
    <td align=center>9</td>
    <td align=center>4<br>(exciter)</td>
    <td align=center>D</td>
    <td>Peak T105. Peak T106.</td>
  </tr>

  <tr>
    <td align=center>10</td>
    <td align=center>7<br>(exciter)</td>
    <td align=center>F</td>
    <td>Peak T107. Peak T108.</td>
  </tr>

  <tr>
    <td align=center>11</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Meter is now on PA metering jack.  Peak C155.  Peak C157.</td>
  </tr>
  
  <tr>
    <td align=center>12</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Peak C167. Peak C171. Peak C175.</td>
  </tr>

  <tr>
    <td align=center>13</td>
    <td align=center>1<br>(exciter)</td>
    <td align=center>B</td>
    <td>Meter is now on exciter metering jack.  Peak T101.</td>
  </tr>

  <tr>
    <td align=center>14</td>
    <td align=center>3<br>(exciter)</td>
    <td align=center>C</td>
    <td>Peak T102. Peak T103. Peak T104. Repeat to find highest peak.</td>
  </tr>

  <tr>
    <td align=center>15</td>
    <td align=center>4<br>(exciter)</td>
    <td align=center>D</td>
    <td>Peak T105. Peak T106. Repeat to find highest peak.</td>
  </tr>

  <tr>
    <td align=center>16</td>
    <td align=center>7<br>(exciter)</td>
    <td align=center>F</td>
    <td>Peak T107. Peak T108. Repeat to find highest peak.</td>
  </tr>

  <tr>
    <td align=center>17</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Meter is now on PA metering jack.  Peak C155.  Peak C157. Repeat to find
	highest peak.  Peform steps 13-17 again. </td>
  </tr>
  
  <tr>
    <td align=center>18</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Peak C167. Peak C171. Peak C175. Repeat to find hgihest peak.</td>
  </tr>
  
  <tr>
    <td align=center>19</td>
    <td align=center>Wattmeter</td>
    <td align=center></td>
    <td>Adjust power control potentiometer on Power Amplifier for desired output
	power.</td>
  </tr>
  
</table>
</div>
<p>
Use a frequency counter or service monitor to adjust the transmitter ICOM.  The
trimmer capacitor on the top of the ICOM adjusts the ICOM's frequency, and
therefore the transmitter's output frequency.
<p>
Transmitter maximum deviation is set with R104.  Note that this control adjusts
the deviation level <i>after</i> the limiter.  This control should be adjusted
to ensure that maximum deviation does not exceed 5.0 KHz.  A service monitor or
deviation meter is required to make this adjustment.  If you do not have the
required test equipment, then don't adjust the deviation control, it's probably
fine right where it is.
<p>
When setting power level, do not exceed rated output power.  If the radio will
be used as a repeater, or in any other similar high-duty-cycle application, then
the maximum output power should be derated to 1/2 to 2/3 of the specified rated
output power.
<?php include '../footer.inc'; ?>
