<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-3 Repeater Controller Installation</title>
<meta name="description" content="Installation instructions for the NHRC-3">
<meta name="keywords" content="NHRC-3, repeater controller, NHRC, talking repeater controller">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-3 Repeater Controller</b></FONT><br>
<font size=4><b>Installation Instructions</b></font>
</div>
<hr>
These instructions will guide you in the installation and adjustment of the
NHRC-3 repeater controller.<p>
<div align=center>
<font size=6><b><i>Contents</i></b></font></div><p>
<ol>
<h3><li><a href="#ElectricalConnections">Electrical Connections</a></h3>
<h3><li><a href="#LEDS">The LED status indicators</a></h3>
<h3><li><a href="#InstallingDelay">Installing the Audio Delay</a></h3>
<h3><li><a href="#AdjustingAudio">Adjusting the Audio Levels</a></h3>
</ol>
<p>
<hr>
<div align=center>
<img src="M3scrn.gif" width=373 height=398><br>
<b>Board Layout</b>
</div>
<ol>
  <a name="ElectricalConnections">
  <b><font size=5><li>Electrical Connections</font></b><br>
  </a>
      The controller uses a 10 pin .100 header for all signals.  It requires 
      receiver audio and a signal present indication (CAS) from the receiver, 
      supplies transmit audio and PTT to the transmitter, and requires 13.8
      volts DC for power.  Be very careful when wiring DC power to the 
      controller, reverse polarity will destroy the ICs.  The connector pinouts
      are shown in the table below.<p>
      <a name="ConnectorPinout">
      <div align=center>
      <table border>
	<caption><b>J-1 Controller Electrical Connections</b></caption>
	<tr><th>Pin</th><th>Use</th></tr>
	<tr><td>1</td><td>+13.8 Volts</td></tr>
	<tr><td>2</td><td>+13.8 Volts</td></tr>
	<tr><td>3</td><td>CAS +</td></tr>
	<tr><td>4</td><td>CAS -</td></tr>
	<tr><td>5</td><td>PTT (active low)</td></tr>
	<tr><td>6</td><td>Ground</td></tr>
	<tr><td>7</td><td>TX Audio (to transmitter)</td></tr>
	<tr><td>8</td><td>Ground/TX Audio Return</td></tr>
	<tr><td>9</td><td>RX Audio (from receiver)</td></tr>
	<tr><td>10</td><td>Ground/RX Audio Return</td></tr>
      </table>
      <p>
      <table border>
	<caption><b>J-2 Audio Delay Connections</b></caption>
	<tr><th>Pin</th><th>Use</th></tr>
	<tr><td>1</td><td>+13.8 Volts to delay board</td></tr>
	<tr><td>2</td><td>Audio to delay board</td></tr>
	<tr><td>3</td><td>Audio from delay board</td></tr>
	<tr><td>4</td><td>Ground/Audio Return</td></tr>
      </table>
      </div>
      </a>
      <p>

      Receiver audio can typically be taken from the high side of the
      squelch control.  This audio must be de-emphasized with the controller's
      optional de-emphasis circuit, which provides a -6dB/octave slope.
      Optionally, audio can be taken from later in the receiver's audio
      chain, where it is already de-emphasized.  Care must be taken
      that this source of audio is not subject to adjustment by the
      radio's volume control.  If the receiver audio has not been properly
      de-emphasized, either in the receiver itself or on the controller
      board, the repeater will have a very &quot;tinny&quot;, unnatural
      sound to it.<P>
      
      To de-emphasize the receiver audio on the controller board, install
      a .0068 F capacitor in position C1, change R2 to 51K, and change
      R1 to 510K.  These values should be considered a good starting
      point.  You may want to experiment with the values of C1 and R1
      to get better sounding audio.  We have had consistently good results
      with this de-emphasis network.<P>

      The receiver must provide a signal present indication (also called
      COR, RUS, CAS) to the controller.  Because of the varieties of
      polarity and state that this signal can take, we have chosen to
      implement the controller's signal present input with an opto-isolator
      (ISO1).  The anode and cathode of the LED in the opto-isolator
      are exposed through a current limiting resistor (R30).  This allows
      easy interfacing to active-high, active-low, and combinations
      of both to indicate the presence of a received signal to the controller.
      Clever wiring can allow the user to create CTCSS and COR, CTCSS
      or COR, etc. configurations.  Note that <b>both</b> the CAS+ and 
      CAS- terminals must be connected to something in order for the 
      controller to detect the signal present indication.<P>
      
      Transmitter audio can be fed directly into the microphone input 
      of the transmitter.  VR2 is the master level control, used to
      set the audio level into the transmitter.  The transmitter's deviation
      limiter (sometimes called IDC) should be set such that the transmitter
      cannot overdeviate, regardless of input signal level.  One way to 
      adjust transmitter deviation is to set the transmitter deviation 
      limiter wide open (unlimited), adjust the controller's master output
      until the transmitter is slightly overdeviating, then set the transmitter's
      deviation limiter to limit just below 5 KHz deviation.  Then reduce the
      controller's master output until the transmitted audio does not sound
      compressed or clipped.  Transmitter deviation should be adjusted with a 
      service monitor or deviation meter.<P>

      Transmitter keying is provided by a power MOSFET (Q6) configured
      in an open-drain circuit.  This can be used to key many transmitters
      directly.  The MOSFET essentially provides a closure to ground
      for PTT.  For other transmitters, the MOSFET can drive a small
      relay to key the radio.  Although this MOSFET can handle several
      amps, we recommend that no more than 500 mA of current be drawn
      through it.<p>
  <a name="LEDS">
  <b><font size=5><li>The LED Status Indicators</font></b><br>
  </a>
    The NHRC-3 repeater controller is equipped with three status LEDS
    that aid in setup and troubleshooting.  The green LED indicates that
    the controller is getting a valid CAS (carrier operated switch) and,
    if the TS-32 is connected, a valid CTCSS decode signal.  This LED should
    light when the repeater's receiver is active, and, when the TS-32 is
    properly installed, the correct CTCSS tone is present.  The yellow LED
    indicated that a DTMF signal is being decoded.  This LED should light
    for the entire duration that the DTMF signal is present on the receiver.
    The red LED indicates transmit.  This LED will light when the transmitter
    is transmitting.<p>
    The LEDS can be disabled to reduce the power consumption of the
    controller.  Remove jumper JP2 to disable the LEDS.<p>
  <a name="InstallingDelay">
  <b><font size=5><li>Installing the Audio Delay</font></b><br>
  </a>
    Remove the jumper between pins 2 and 3 of J2, then plug the cable from
    the audio delay board onto the J2 header.  If the audio delay is not
    installed, then the jumper must be present between pins 2 and 3 of J2.<p>

  <a name="AdjustingAudio">
  <b><font size=5><li>Adjusting the Audio Levels</font></b><br>
  </a>
    Preset all potentiometers to midrange. Key a radio on the input
    frequency, send some touch-tones, and adjust VR1 (the main receive
    level) until DTMF decoding is reliably indicated by yellow LED D4.
    <p>
    The repeater's deviation is set with VR2 (the master level) on the
    controller board and the transmitter's deviation/modulation control.
    The key to properly adjusting these controls is to remember that
    the limiter in the tranmitter is <i>after</i> VR2 but probably
    <i>before</i> the transmitter's deviation/modulation control.
    The transmitter's deviation/modulation control will set the actual
    <i>peak</i> deviation, and VR2 will set the level into the transmitter.
      
    You do not want excessive limiting on normal speech going through the
    repeater; it sounds bad and tends to &quot;pump-up&quot; background
    noise.  On the other hand, some limiting is desirable.  An oscilloscope
    connected to the audio output of a receiver tuned to the transmitter's
    frequency will show limiting as the audio gets &quot;flat-topped&quot;
    or clipped by the limiter.  Ideally, a 4.5KHz deviation signal input to
    the repeater should result in a 4.5 KHz deviation output, and 5.5 KHz
    of input deviation should result in just under 5.0 KHz of deviation
    out of the repeater.  A service monitor (or two), deviation meter,
    and/or a signal generator are necessary to do this job right.
    <p>
    Adjust VR6 (the beep level) to set the courtesy tone and CW tone
    level.
    <P>
    The easiest way to adjust the ISD2590 input and output levels
    is to select the simplex repeater mode and record and play messages
    until the audio sounds right.  VR3 adjusts the record audio level
    into the ISD2590.  Adjust this control for the best sounding record
    audio.  VR5 sets the ISD2590 playback level.  Adjust this control
    for best acceptable transmitter deviation.  Note that the ISD2590
    includes on-chip limiting/compression; this may fool you into
    thinking that you have the input level set just right when it is
    really too high.  Try recording a whisper, it should play back
    quietly, also try recording normal speech with large gaps between
    words in a somewhat noisy environment to listen for background noise
    pumping.  Properly adjusted, the ISD2590 recorded audio should be
    indistinguishable from normal audio repeated through the system.
    <p>
    VR4 is used to set the receiver audio level, and may not need to be
    adjusted from midpoint.<p>
</ol>
<hr>
Back to <A HREF="index.php">NHRC-3 Home Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.11";
include '../barefooter.inc';
?>

