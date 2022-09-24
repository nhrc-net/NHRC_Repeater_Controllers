<?php
$title = "NHRC MASTR II InfoSite -- VHF MASTR II Alignment Instructions";
$category = "mastr2";
$item = "align-vhf";
$description="GE MASTR II mobile radio conversions: VHF Alignment Instructions.";
$keywords="VHF MASTR II Tune-Up Information";
$version="1.31";
$copydate="1997-2004";
include "../header.inc";
?>
<div align=center>
<font size=6><b>VHF MASTR II Alignment Instructions</b></font>
</div>
<p>
These instructions describe alignment of the RF assembly of the VHF MASTR II
receiver.  The IF and Mixer alignment is not included; it rarely needs to be
performed.
<p>
Some older receivers will not have the three trimmer capacitors (C406, C411,
and C416) on the Oscillator/Multiplier board, they will have three inductors
(L401, L402, and L403, from front to rear) with tunable slugs instead.  Follow
the directions as shown, but adjust L401 instead of C406, L402 instead of C411,
and L403 instead of C411.
<p>
<div align=center>
<font size=4><b>VHF MASTR II Receiver Alignment Controls Locations</b></font><br>
<img src="m2-rx-vhf.gif" width=494 height=531>
</div>
<p>
<div align=center>
<table border>
  <tr><th colspan=4><font size=5>VHF Receiver Alignment</font></th></tr>
  <tr><th>Step</th><th>Receiver<br>Metering<br>Jack Pin #</th><th>Test Set<br>Position</th><th>Instructions</th></tr>
  <tr>
    <td align=center>1</td>
    <td align=center>3</td>
    <td align=center>C</td>
    <td>Peak C406.  Set C411 and C416 in a similar position. Set C306 and C307 fully CCW.</td>
  </tr>

  <tr>
    <td align=center>2</td>
    <td align=center>4</td>
    <td align=center>D</td>
    <td>Peak C411, then peak C416.  Peak C406, C411, then C416. Dip C306 and then peak C307.</td>
  </tr>

  <tr>
    <td align=center>3</td>
    <td align=center>2</td>
    <td align=center>A</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to
	C305.  Adjust the signal level for a meter reading of approximately
	0.38 volts.</td>
  </tr>

  <tr>
    <td align=center>4</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Leaving signal injected at same level as step 3, peak C502.</td>
  </tr>

  <tr>
    <td align=center>5</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to C304.  Adjust the signal
	level for a slightly noisy signal.  Then, peak C305.  You may need to reduce the signal generator
	level one or more times to keep the received signal slightly noisy.  Alternately reduce the
	generator level and peak C305 to obtain the largest peak meter indication with the lowest
	signal generator level.</td>
  </tr>
  
  <tr>
    <td align=center>6</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to C303.  Adjust the signal
	level for a slightly noisy signal.  Then, peak C304.  Use the same method as step 5 to obtain
	the largest peak meter indication with the lowest signal generator level.</td>
  </tr>
  
  <tr>
    <td align=center>7</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to C302. Peak C303 as above.
  </tr>
  
  <tr>
    <td align=center>8</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into the hole adjacent to C302. Peak C303 as above.
  </tr>
  
  <tr>
    <td align=center>9</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Inject a signal on the receiver's frequency into antenna jack.  Peak C301 and C302 as above.
	If the UHS preamplifier is present, peak transformer on that.
  </tr>
  
  <tr>
    <td align=center>10</td>
    <td align=center>1</td>
    <td align=center>B</td>
    <td>Leave signal injected on receiver's frequency into antenna jack.  Carefully tune C502, C301,
	C302, C303, C304, and C305 for peak indication and best sensitivity.  A signal-to-noise
	analyzer can be helpful here.  Continue to tweak these controls several times until no
	further improvement in sensitivity can be made.
  </tr>
</table>
</div>
<p>
Mixer and IF alignment is almost never required.  Do not attempt to align the
mixer or IF stages of the receiver without at least a signal-to-noise analyzer.
<p>
The frequency of the receiver ICOM can be adjusted by turning the trimmer
capacitor on the top of the ICOM.  The frequency can be measured directly with
a frequency counter connected to the junction of C418 and C419 on the
Oscillator/Multiplier board (frequency here should be receive frequency - 11.2
MHz) or the ICOM's frequency can be adjusted by injecting a signal into the
receiver from a known reliable source (signal generator or service monitor) and
tuning the ICOM for best receive sensitivity.
<p>
<hr>
All transmitter alignment measurements are performed with the transmitter keyed.
<B>Do not leave the transmitter keyed for an extended period until the alignment
is complete. </b> Make sure that a wattmeter and dummy load are connected to the
transmitter output.
<p>
<div align=center>
<font size=4><b>VHF MASTR II Transmitter Alignment Controls Locations</b></font><br>
<img src="m2-tx-vhf.gif" width=247 height=512>
</div>
<p>
<div align=center>
<table border>
  <tr><th colspan=4><font size=5>VHF Transmitter Alignment</font></td></tr>
  <tr><th>Step</th><th>Metering<br>Jack Pin #</th><th>Test Set<br>Position</th><th>Instructions</th></tr>
  <tr>
    <td align=center>1</td>
    <td align=center>2<br>(exciter)</td>
    <td align=center>A</td>
    <td>Peak T101.</td>
  </tr>
  
  <tr>
    <td align=center>2</td>
    <td align=center>1<br>(exciter)</td>
    <td align=center>B</td>
    <td>Peak T102 and T103.</td>
  </tr>
  
  <tr>
    <td align=center>3</td>
    <td align=center>3<br>(exciter)</td>
    <td align=center>C</td>
    <td>Dip T104.</td>
  </tr>
  
  <tr>
    <td align=center>4</td>
    <td align=center>4<br>(exciter)</td>
    <td align=center>D</td>
    <td>Peak T105. Peak T104. Dip T106.</td>
  </tr>
  
  <tr>
    <td align=center>5</td>
    <td align=center>7<br>(exciter)</td>
    <td align=center>F</td>
    <td>Peak T107. Peak T106.  Dip T108. Peak T109.</td>
  </tr>
  
  <tr>
    <td align=center>6</td>
    <td align=center>5 -<br>6 +<br>(exciter)</td>
    <td align=center><font color="red">G</font></td>
    <td><b><font color="red">Note:</b>Move multimeter to 5/- and 6/+</font></b><br>
    Peak T110.  Peak T108.  Peak T109.</td>
  </tr>

  <tr>
    <td align=center>7</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Meter is now on PA metering jack.  Peak T111 and T112.  </td>
  </tr>
  
  <tr>
    <td align=center>8</td>
    <td align=center>5<br>(exciter)</td>
    <td align=center><font color="red">G</font></td>
    <td>Meter is now on exciter metering jack.  <br>
    <b><font color="red">Note:</b>Move multimeter to 5/- and 6/+</font></b><br>
    Peak T108. Peak T109. Peak T110.</td>
  </tr>

  <tr>
    <td align=center>9</td>
    <td align=center>4<br>(PA)</td>
    <td align=center>D</td>
    <td>Meter is now on PA metering jack.  Peak T111 and T112.  </td>
  </tr>
  
  <tr>
    <td align=center>10</td>
    <td align=center>Wattmeter</td>
    <td align=center></td>
    <td>Adjust power control potentiometer on Power Amplifier for desired output power.</td>
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
be used as a repeater, or in any other similar high-duty-cycle application,
then the maximum output power should be derated to 1/2 to 2/3 of the specified
rated output power.
<?php include '../footer.inc'; ?>
