<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-4 Repeater Controller Installation</title>
<meta name="description" content="Installation instructions for the NHRC-4">
<meta name="keywords" content="NHRC-4, repeater controller, NHRC, linking repeater controller">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-4 Repeater Controller</b></FONT><br>
<font size=4><b>Installation Instructions</b></font>
</div>
<hr>
These instructions will guide you in the installation and adjustment of the
NHRC-4 repeater controller.<p>
<div align=center>
<font size=6><b><i>Contents</i></b></font></div><p>
<ol>
<h3><li><a href="#ElectricalConnections">Electrical Connections</a></h3>
<h3><li><a href="#LEDS">The LED status indicators</a></h3>
<h3><li><a href="#TS32">TS-32 Hookup</a></h3>
<h3><li><a href="#InstallingDelay">Installing the Audio Delay</a></h3>
<h3><li><a href="#Digital Output">The Digital Output</a></h3>
<h3><li><a href="#AdjustingAudio">Adjusting the Audio Levels</a></h3>
</ol>
<p>
<hr>
<div align=center>
<img src="m4scrn.gif" width=439 height=381><br>
<b>Board Layout</b>
</div>
<ol>
  <a name="ElectricalConnections">
  <b><font size=5><li>Electrical Connections</font></b><br>
  </a>
      The controller uses a 8 pin .100 header for all the primary radio's
      signals and DC power, a 6 pin .100 header for the secondary radio's
      signals, and a 6 pin .100 header for an external TS-32 CTCSS
      encoder/decoder for the promary radio.  In addition, it has two 4 pin
      .100 connectors to support optional NHRC-DAD digital audio delays for
      both radio ports.<p>

      Each radio port requires audio and a signal present indication (CAS)
      from it's receiver, and supplies transmit audio and PTT to it's
      transmitter.  The controller requires 13.8 volts DC for power, which is
      provided on the primary radio's connector..  Be very careful when
      wiring DC power to the controller, reverse polarity will severely
      damage the controller.  The connector pinouts
      are shown in the tables below.<p>
      <div align=center>
      <a name="Primary Radio Port Connector">
      <b>J-1 Primary Radio Port<br>(&quot;REPEATER&quot;)</b>
      </a>
      <table border>
	<tr><th>Pin</th><th>Use</th></tr>
	<tr><td>1</td><td>+13.8 Volts</td></tr>
	<tr><td>2</td><td>CAS (active high)</td></tr>
	<tr><td>3</td><td>PTT (active low)</td></tr>
	<tr><td>4</td><td>Receiver Audio</td></tr>
	<tr><td>5</td><td>Transmitter Audio</td></tr>
	<tr><td>6</td><td>Fan/Digital output (active low)</td></tr>
	<tr><td>7</td><td>Ground/Audio Return</td></tr>
	<tr><td>8</td><td>Ground/Audio Return</td></tr>
      </table>
      <p>
      <a name="Secondary Radio Port Connector">
      <b>J-2 Secondary Radio Port<br>(&quot;RB&quot;)</b>
      </a>
      <table border>
	<tr><th>Pin</th><th>Use</th></tr>
	<tr><td>1</td><td>CAS (active high)</td></tr>
	<tr><td>2</td><td>PTT (active low)</td></tr>
	<tr><td>3</td><td>CTCSS detect (active high)</td></tr>
	<tr><td>4</td><td>Receiver Audio</td></tr>
	<tr><td>5</td><td>Transmitter Audio</td></tr>
	<tr><td>6</td><td>Ground/Audio Return</td></tr>
      </table>
      <p>
      <a name="TS-32 Connector">
      <b>J-3 Primary Radio Port TS-32 Connector<br>(&quot;TS-32&quot;)</b></a>
      <table border>
	<tr><th>Pin</th><th>Use</th><th>TS-32 Signal</th></tr>
	<tr><td>1</td><td>+13.8 Volts to TS-32</td><td>+V POWER</td></tr>
	<tr><td>2</td><td>Receiver Audio</td><td>DECODER INPUT</td></tr>
	<tr><td>3</td><td>Receiver Audio</td><td>AUDIO FILTER INPUT</td></tr>
	<tr><td>4</td><td>Filtered Audio</td><td>AUDIO FILTER OUTPUT</td></tr>
	<tr><td>5</td><td>CTCSS Detect</td><td>OUT-2</td></tr>
	<tr><td>6</td><td>Ground/Audio Return</td><td>- GROUND &amp; HANGUP</td></tr>
      </table>
      <p>
      <b>
      <a name="DAD Connector">
      J-4 Primary Radio DAD<br>(&quot;MN DLY &quot;)<br>
      J-5 Secondary Radio DAD<br>(&quot;RB DLY &quot;)
      </a>
      </b>
      <table border>
	<tr><th>Pin</th><th>Use</th></tr>
	<tr><td>1</td><td>+13.8 Volts to delay board</td></tr>
	<tr><td>2</td><td>Audio <b>to</b> delay board</td></tr>
	<tr><td>3</td><td>Audio <b>from</b> delay board</td></tr>
	<tr><td>4</td><td>Ground/Audio Return</td></tr>
      </table>
      </div>
      <p>
      Receiver audio can typically be taken from the high side of the
      squelch control.  This audio must be de-emphasized with the controller's
      de-emphasis circuit, which provides a -6dB/octave slope. 
      Optionally, audio can be taken from later in the receiver's audio
      chain, where it is already de-emphasized.  Care must be taken
      that this source of audio is not subject to adjustment by the
      radio's volume control.  If the receiver audio has not been properly
      de-emphasized, either in the receiver itself or on the controller
      board, the repeater will have a very &quot;tinny&quot;, unnatural
      sound to it.  The NHRC-4 repeater controller is shipped without the
      de-emphasis circuit populated on the printed circuit board, for
      &quot;flat&quot; audio response.  To install the deemphasis filter,
      two 100K ohm resistors must be removed, and a 51K ohm, a 510K ohm,
      and a .0068 microfarad capacitor must be installed on the board.
      Consult the NHRC-4 Repeater Controller (Audio) schematic for
      modification instructions.<p>
      
      The receiver must provide a signal present indication (also called
      CAS, COR, RUS) to the controller.  The controller requires an
      &quot;active-high&quot; signal here.  If your radio only has
      &quot;active-low&quot; signalling available, a simple inverter can
      be constructed with a 2N3906 and a 4.7K resistor.  Connect the emitter
      of the transistor to a source of positive voltage, the collector to the
      controller's CAS terminal, and the base to the active-low signal through
      the 4.7K resistor.<p>
      
      Transmitter audio can be fed directly into the microphone input 
      of the transmitter.  VR5 is the master level control for the primary
      radio, used to set the audio level into the transmitter.  VR2 is the
      master level control for the secondary radio. The transmitter's deviation
      limiter (sometimes called IDC) should be set such that the transmitter
      cannot overdeviate, regardless of input signal level.  One way to 
      adjust transmitter deviation is to set the transmitter deviation 
      limiter wide open (unlimited), adjust the controller's master output
      until the transmitter is slightly overdeviating, then set the
      transmitter's deviation limiter to limit just below 5 KHz deviation.
      Then reduce the controller's master output until the transmitted audio
      does not sound compressed or clipped.  Transmitter deviation should be
      adjusted with a service monitor or deviation meter.<P>

      Transmitter keying is provided by a power MOSFET (Q2/Q6) configured
      in an open-drain circuit.  This can be used to key many transmitters
      directly.  The MOSFET essentially provides a closure to ground
      for PTT.  For other transmitters, the MOSFET can drive a small
      relay to key the radio.  Although this MOSFET can handle several
      amps, we recommend that no more than 500 mA of current be drawn
      through it.<p>
  <a name="LEDS">
  <b><font size=5><li>The LED Status Indicators</font></b><br>
  </a>
    The NHRC-4 repeater controller is equipped with five status LEDS
    that aid in setup and troubleshooting.  There are green LEDs for each
    radio port that indicate that the controller has getting a valid CAS
    (carrier operated switch) and, if a CTCSS decoder is connected, a 
    a valid CTCSS decode signal.  This LED should light when the repeater's
    receiver is active, and, if a CTCSS decoder is present, that the correct
    CTCSS tone is present.  The yellow LED indicates that a DTMF signal is
    being decoded on the primary receiver.  This LED should light for the
    entire duration that the DTMF signal is present on the primary receiver.
    The red LEDs indicates transmit.  These LED will light when the each
    transmitter is transmitting.<p>
    The LEDS can be disabled to reduce the power consumption of the
    controller.  Remove jumper JP2 to disable the LEDS.<p>
  <a name="TS32">
  <b><font size=5><li>TS-32 hookup</font></b><br>
  </a>
    <a href="#TS-32 Connector">Connector J3</a>
    is 6-pin header that allows the easy installation of
    an optional Communications Specialists TS-32 for CTCSS decode and
    possibly encode.  Consult table J-3 &quot;Primary Radio Port TS-32
    Connector (&quot;TS-32&quot;)&quot; for hookup information.<p>
      
    The TS-32 must have the JU-2 jumper cut.  If you want to be able to 
    disable the CTCSS requirement, install a switch on the HANGUP lead, or
    you could wire the HANGUP lead to the J1 Fan/Digital Output pin to allow
    remote enable/disable of the CTCSS requirement.  If you like, you can
    wire the TS-32's ENCODE OUT pin into your transmitter's CTCSS input to
    encode PL on the repeater's output.<p>

    The TS-32 is normally configured with it's high-pass filter in-circuit
    to remove received CTCSS tones.  Jumper JP1 on the controller board must
    be removed when the TS-32 high-pass filter is used.  If the TS-32 is not
    installed, then jumper JP1 must be installed in order for audio to pass
    through the controller.<p>
      
    Consult the <font size=2>TS-32 INSTRUCTION SHEET</font> for details on
    setting the CTCSS frequency.<p>

  <a name="InstallingDelay">
  <b><font size=5><li>Installing the Audio Delay</font></b><br>
  </a>
    The audio delay for the primary radio simply plugs in to
    <a href="#DAD Connector">J4</a>.  The  audio delay for the secondary
    radio plugs in to  <a href="#DAD Connector">J5</a>.  If the audio delay
    is not installed, a jumper between pins 2 and 3 of the port's delay
    connector must be installed, or the controller will not pass audio.<p>

  <a name="Digital Output">
  <b><font size=5><li>Using the Digital Output</font></b><br>
  </a>
      The NHRC-4 Repeater Controller has a digital output that can be used
      for various remote control applications or to control a fan on the
      repeater's transmitter.  The digital output is an open-drain into a
      power MOSFET, which is capable of sinking quite a bit of current, but
      we recommend a maximum load of about 500 mA.  Use a relay to drive
      larger loads.  The open-drain output can be used to gate the HOOKSWITCH
      signal to a TS-32 or other CTCSS decoder.  Software allows the output
      to be enabled, disabled, or pulsed.  In fan control mode, this output
      will be turned on when the transmitter is turned on, and turned off
      a programmable amount of time after the transmitter is turned off.<p>

  <a name="AdjustingAudio">
  <b><font size=5><li>Adjusting the Audio Levels</font></b><br>
  </a>
      <div align=center>
      <b>Audio Level Adjustments</b><br>
      <table border>
	<tr><th>Potentiometer</th><th>Use</th></tr>
	<tr><td>VR1</td><td>Secondary Receiver Mix Level</td></tr>
	<tr><td>VR2</td><td>Secondary Transmitter Master Level</td></tr>
        <tr><td>VR3</td><td>Primary Receiver Mix Level</td></tr>
        <tr><td>VR4</td><td>Primary Receiver Level</td></tr>
        <tr><td>VR5</td><td>Primary Transmitter Master Level</td></tr>
        <tr><td>VR6</td><td>Beep Tone Mix Level</td></tr>
      </table>
      </div><p>
      Preset all potentiometers to midrange. Key a radio on the primary input
      frequency, send some touch-tones, and adjust VR4 (the primary receiver
      level) until DTMF decoding is reliably indicated by yellow LED D5.
      <p>
      The primary radio's transmit deviation is set with VR5 (the primary
      transmitter master level) on the controller board and the transmitter's
      deviation/modulation control.  The key to properly adjusting these
      controls is to remember that the limiter in the tranmitter is
      <i>after</i> VR2 but probably <i>before</i> the transmitter's
      deviation/modulation control. The transmitter's deviation/modulation
      control will set the actual <i>peak</i> deviation, and VR5 will set
      the level into the transmitter.
      
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
      The secondary radio's transmit deviation is set with VR2 (the secondary
      transmitter master level).  Enable the secondary transmitter, and
      adjust VR2 for proper transmit deviation, similarly to VR5.
      <p>
      Enable the secondary receiver, and adjust VR1 for reasonable deviation
      on the enabled transmitters when a signal is received on the secondary
      receiver.
      <p>
      Adjust VR6 (the beep level) to set the courtesy tone and CW tone
      level.
      <P>
      VR3 is used to set the receiver audio mix level, and may not need to be
      adjusted from midpoint.<p>
</ol>
<hr>
Back to <A HREF="/nhrc-4/">NHRC-4 Home Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.02";
include '../barefooter.inc';
?>
