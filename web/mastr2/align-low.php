<?php
$title = "NHRC MASTR II InfoSite -- Low Band Alignment Instructions";
$category = "mastr2";
$item = "align-low";
$description="GE MASTR II mobile radio conversions: Low Band Alignment Instructions.";
$keywords="Low Band MASTR II Tune-Up Information";
$version="1.21";
$copydate="1997-2004";
include "../header.inc";
?>
<div align=center>
<font size=6><b>Low Band MASTR II Alignment Instructions</b></font>
</div>
<p>
These instructions describe alignment of the RF assembly of the Low Band MASTR
II receiver. The IF and Mixer alignment is not included; it rarely needs to be
performed.
<p>
Some older receivers will not have the two trimmer capacitors (C402 and C411)
on the Oscillator/Multiplier board, they will have three inductors with tunable
slugs instead. On these radios, put the meter on pin 3 of the metering jack and
peak the coil closest to the front of the radio, then dip the coil in the
middle.  Then put the meter on pin 4 of the metering jack and peak the middle
inductor and the one towards the back of the radio.  Then re-peak all three
inductors.  Proceed with the instructions at the second operation in step 2
(dip L404).
<p>
<div align=center>
<font size=4><b>Low Band MASTR II Receiver Alignment Controls Locations</b></font><br>
<img src="m2-rx-lo.gif" width=506 height=524>
</div>
<p>
<div align=center>
<table border>
  <tr><th colspan=4><font size=5>Low Band Receiver Alignment</font></th></tr>
  <tr><th>Step</th><th>Receiver<br>Metering<br>Jack Pin #</th><th>Test Set<br>Position</th><th>Instructions</th></tr>
  <tr>
    <td align=center>1</td>
    <td align=center>3</td>
    <td align=center>C</td>
    <td>Set slugs in L404, L502, and L503 to the top of the coil form.  Peak C402.</td>
  </tr>

  <tr>
    <td align=center>2</td>
    <td align=center>4</td>
    <td align=center>D</td>
    <td>Peak C411, then peak C402.  Dip L404, peak L502, then dip L503.  Do not readjust L404, L502 or L503.</td>
  </tr>

  <tr>
    <td align=center>3</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole for L4. Adjust the signal
	level for a slightly noisy signal.  Then, peak L4.  You may need to reduce the signal generator
	level one or more times to keep the received signal slightly noisy.  Alternately reduce the
	generator level and peak C305 to obtain the largest peak meter indication with the lowest
	signal generator level.</td>
  </tr>

  <tr>
    <td align=center>4</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole for  L2.  Adjust the signal
	level for a slightly noisy signal.  Then, peak L3 and peak L4. Use the same method as
	step 3 to obtain the largest peak meter indication with the lowest signal generator level.</td>
  </tr>
  
  <tr>
    <td align=center>5</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the antenna jack.  Adjust the generator
	level for a slightly noisy signal.  Peak L1, L2, L3, L4, C301, C302, and C502.  Continue
	to reduce the generator's level and peak these 7 controls for the best receiver sensivity.
	A signal-to-noise analyzer can be helpful here.  Continue to tweak these controls several
	times until no further improvement in sensitivity can be made.</td>
  </tr>
</table>
</div>
<p>
Mixer and IF alignment is almost never required.  Do not attempt to align the mixer or IF stages
of the receiver without at least a signal-to-noise analyzer.
<p>
The frequency of the receiver ICOM can be adjusted by turning the trimmer capacitor on the top
of the ICOM.  The frequency can be measured directly with a frequency counter connected to the
junction of C411 and L402 on the Oscillator/Multiplier board (frequency here should be 
receive frequency - IF frequency) or the ICOM's frequency can be adjusted by injecting a signal into
the receiver from a known reliable source (signal generator or service monitor) and tuning the
ICOM for best receive sensitivity.<p>
<div align=center>
<table border>
  <tr><TH colspan=2>Low Band IF Frequencies</th></tr>
  <tr><th>Split</th><th>IF<BR>Frequency</th></tr>
  <tr><td>25-30</td><td>11.2 MHz</td></tr>
  <tr><td>30-36</td><td>9.4 MHz</td></tr>
  <tr><td>36-42</td><td>11.2 MHz</td></tr>
  <tr><td>42-50</td><td>9.4 MHz</td></tr>
</table>
</div>
<p>
<hr>
All transmitter alignment measurements are performed with the transmitter keyed.  <B>Do not leave
the transmitter keyed for an extended period until the alignment is complete. </b> Make sure that a
wattmeter and dummy load are connected to the transmitter output.<p>
<div align=center>
<font size=4><b>Low Band MASTR II Transmitter Alignment Controls Locations</b></font><br>
<img src="m2-tx-lo.gif" width=245 height=493>
</div>
<p>
<div align=center>
<table border>
  <tr><th colspan=4><font size=5>Low Band Transmitter Alignment</font></th></tr>
  <tr><th>Step</th><th>Metering<br>Jack Pin #</th><th>Test Set<br>Position</th><th>Instructions</th></tr>
  <tr>
    <td align=center>1</td>
    <td align=center>2<br>(exciter)</td>
    <td align=center>A</td>
    <td>Peak L101.</td>
  </tr>
  
  <tr>
    <td align=center>2</td>
    <td align=center>1<br>(exciter)</td>
    <td align=center>B</td>
    <td>Peak L102 and L103.</td>
  </tr>
  
  <tr>
    <td align=center>3</td>
    <td align=center>3<br>(exciter)</td>
    <td align=center>C</td>
    <td>Dip T101.  Peak T102.</td>
  </tr>
  
  <tr>
    <td align=center>4</td>
    <td align=center>4<br>(exciter)</td>
    <td align=center>D</td>
    <td>Peak T103. Peak T102. Peak T101. Dip T104.</td>
  </tr>
  
  <tr>
    <td align=center>5</td>
    <td align=center>7<br>(exciter)</td>
    <td align=center>F</td>
    <td>Peak T105. Peak T104.  Dip T106. Peak T107.</td>
  </tr>
  
  <tr>
    <td align=center>6</td>
    <td align=center>6<br>(exciter)</td>
    <td align=center>G</td>
    <td>Peak T108.  Peak T107.  Peak T106.</td>
  </tr>

  <tr>
    <td align=center>7</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Meter is now on PA metering jack. Peak C134. Peak C156.</td>
  </tr>
  
  <tr>
    <td align=center>8</td>
    <td align=center>Wattmeter</td>
    <td align=center></td>
    <td>Adjust power control potentiometer on Power Amplifier for desired output power.</td>
  </tr>
  
</table>
</div>
<p>
Use a frequency counter or service monitor to adjust the transmitter ICOM.  The trimmer
capacitor on the top of the ICOM adjusts the ICOM's frequency, and therefor the transmitter's
output frequency.
<p>
Transmitter maximum deviation is set with the left hand potentiometer on the exciter.  Note
that this control adjusts the deviation level <i>after</i> the limiter.  This control should
be adjusted to ensure that maximum deviation does not exceed 5.0 KHz.  A service monitor or
deviation meter is required to make this adjustment.  If you do not have the required test
equipment, then don't adjust the deviation control, it's probably fine right where it is.
<p>
When setting power level, do not exceed rated output power.  If the radio will be used as a
repeater, or in any other similar high-duty-cycle application, then the maximum output power
should be derated to 1/2 to 2/3 of the specified rated output power.
<?php include '../footer.inc'; ?>
