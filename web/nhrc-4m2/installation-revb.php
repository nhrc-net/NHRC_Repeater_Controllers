<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-4/M2 MASTR II Integrated Repeater Controller Installation</title>
<meta name="description" content="Installation instructions for the NHRC-4/M2, an integrated repeater controller for the MASTR II">
<meta name="keywords" content="NHRC-4, NHRC-4/M2, repeater controller, NHRC, linking repeater controller, MASTR II">
</head>
<body bgcolor="white">
<div align=center>
<FONT SIZE=6><b>NHRC-4/M2 Repeater Controller</b></FONT><br>
<font size=4><b>Installation Instructions</b></font><br>
<font size=a>Rev. B Boards (shipped after January 1999)</b></font>
</div>
<hr>
These instructions will guide you in the installation and adjustment of the
NHRC-4/M2 repeater controller.<p>
<div align=center>
<font size=6><b><i>Contents</i></b></font></div><br>
<ol>
<h3><li><a href="#Preparation">MASTR II Preparation</a></h3>
<h3><li><a href="#RB">Secondary Radio Port Wiring</a></h3>
<h3><li><a href="#TS32">TS-32/TS-64 Hookup</a></h3>
<h3><li><a href="#Installing">Installing the NHRC-4/M2 in the MASTR II</a></h3>
<h3><li><a href="#LEDS">The LED status indicators</a></h3>
<h3><li><a href="#InstallingDelay">Installing the NHRC-DAD Audio Delay</a></h3>
<h3><li><a href="#Digital Output">Using the Digital Output</a></h3>
<h3><li><a href="#AdjustingAudio">Adjusting the Audio Levels</a></h3>
</ol>
<p>
<hr>
<div align=center>
<img src="4m2-scrn_revb.gif" width=600 height=216><br>
<b>Board Layout</b>
</div>
<ol>
  <a name="Preparation">
  <b><font size=5><li>MASTR II Preparation</font></b><br>
      </a>
      The NHRC-4/M2 operates using the MASTR II as the &quot;primary&quot;
      radio.  The primary radio must operate in full-duplex mode.  If your
      MASTR II is not already converted for full-duplex operation, consult
      the <a href="/mastr2/">NHRC MASTR II InfoSite</a> for duplexing information.<p>
      There are two options for interfacing the CAS and TX audio to the
      controller.  These signals do not normally appear on the the P908 plug
      on the system board of the MASTR II.<p>
      <b>Option 1: Use an interface cable</b><br>
      <blockquote>
      Transmit audio and CAS appear on the controller at J1, a 3-pin header.
      Wire an interface cable as shown in the table below:<p>
      <div align=center>
      <b>J1 Connections</b><br>
      <table border=1>
	<tr><th>J1<br>Pin #</th><th>MASTR II<br>Signal</th></tr>
	<tr><td>1</td><td>MIC HI<br>J902 #6</td></tr>
	<tr><td>2</td><td>CAS<br>J904 #9</td></tr>
	<tr><td>3</td><td>MIC LO<BR>J902 #5</td></tr>
      </table>
      </div><p>
      </blockquote>
      <b>Option 2: Modify the MASTR II System Board.</b><br>
      <blockquote>
      By cutting one trace and adding two wires to the MASTR II system
      board, the jumper described in option 1, above, can be avoided.<p>
      Add a wire that connects P908 pin 2 to J902 pin 6 (the exciter's MIC
      HI input). Cut the trace that leads to P908 pin 3 on the system board, 
      and add a wire that connects P908 pin 3 to J904 pin 9 (the CAS signal
      from the IFAS board).
      Install 0 ohm resistors (jumpers) R22 and R38 on the NHRC-4/M2 board,
      enabling the TX audio and CAS signals on the J908 connector.  Note
      that these jumpers may already be populated on your board.
      If you plan on using the local microphone on the MASTR II's control
      head, install a 1.5K resistor in location R38.
    </blockquote>

  <a name="RB">
  <b><font size=5><li>Secondary Radio Port Wiring</font></b><br>
  </a>
      The controller provides the secondary radio port on the F3 through F8
      frequency select leads, using the P909 connector.  These leads are
      routed to the front panel control cable connector on the systems board.
      In mobile MASTR II radios, these control lines are sometimes subject to
      the installation of diodes and jumpers and cutting of traces to share
      channel elements across more than one channel selection.  These diodes
      and jumpers must be removed, and the cut traces must be jumpered to
      for proper operation of the controller.  Consult the MASTR II service
      manual for information on these jumpers.<p>
      Dissecting an old control cable makes an easy job of attaching your
      secondary radio to the MASTR II.  In an E-chassis MASTR II, a bit of
      clever wiring in the systems board can allow a repeater on the
      &quot;top deck&quot; and the secondary, remote-base radio on the
      &quot;bottom deck&quot;.<p>
      In base stations and repeaters, the P909 connector is unused.
      Individual wires must be attached to P909 to break out the secondary
      radio port.<p>
      <div align=center>
      <b><font size=4>P909 Secondary Radio Port Connections</font></b><br>
      <table border=1>
	<tr><th>P909<br>Pin #</th><th>NHRC-4/M2<br>Use</th><th>Frequency<br>Select</th><th>J901 (control cable)<br>Pin #</th></tr>
	<tr><td align=center>1</td><td>Secondary port CAS</td><td align=center>F8</td><td align=center>15</td></tr>
	<tr><td align=center>2</td><td>Secondary port PTT</td><td align=center>F7</td><td align=center>14</td></tr>
	<tr><td align=center>3</td><td>Secondary port CTCSS detect</td><td align=center>F6</td><td align=center>13</td></tr>
	<tr><td align=center>4</td><td>Secondary port receiver audio</td><td align=center>F5</td><td align=center>12</td></tr>
	<tr><td align=center>5</td><td>Secondary port transmitter audio</td><td align=center>F4</td><td align=center>11</td></tr>
	<tr><td align=center>6</td><td>Digital output</td><td align=center>F3</td><td align=center>10</td></tr>
	<tr><td align=center>7</td><td>no connection</td><td align=center>F2</td><td align=center>9</td></tr>
	<tr><td align=center>8</td><td>Unused, grounded to select F1</td><td align=center>F1</td><td align=center>8</td></tr>
      </table>
      </div>
      <p>
      <B>It is extremely important that the radio attached to the secondary
      radio port be provided with a common ground from the MASTR II. </b>
      The &quot;A-&quot; lead (J901 pin 30) is a good spot.  If this common
      ground is not provided, erratic operation or distorted audio on the
      secondary radio will result.<p>

  <a name="TS32">
  <b><font size=5><li>TS-32/TS-64 hookup</font></b><br>
  </a>
    Connector JTS32 is a 7-pin header that allows the easy installation of
    an optional Communications Specialists TS-32 or TS-64 for CTCSS decode,
    encode, CTCSS audio filtering, and reverse-burst.  (Reverse burst is
    only available with the TS-64.)  Wire JTS32 to the TS-32/TS-64 as
    follows:<p>
    <div align=center>
      <b><font size=4>JTS32 Connections</font></b><br>
      <table border=1>
        <tr>
	  <th>JTS32<br>Pin #</th>
	  <th>TS-32<br>Signal</th>
	  <th>Description</th>
	</tr>
        <tr>
	  <td align=center>1</td>
	  <td>+V POWER</td>
	  <td>+10 volts to CTCSS board</td>
	</tr>
        <tr>
	  <td align=center>2</td>
	  <td>CTCSS DECODER INPUT</td>
	  <td>receiver audio to CTCSS decoder</td>
	</tr>
        <tr>
	  <td align=center>3</td>
	  <td>TO AUDIO FILTER INPUT</td>
	  <td>receiver audio to audio filter input<br>
	  (separate lead for TS-64)</td>
	</tr>
        <tr>
	  <td align=center>4</td>
	  <td>FROM AUDIO FILTER OUTPUT</td>
	  <td>filtered audio to controller</td>
	</tr>
        <tr>
	  <td align=center>5</td>
	  <td>CTCSS DETECT</td>
	  <td>decode signal from CTCSS decoder<br>
	  <font color=red>See important warning below!</font></td>
	</tr>
        <tr>
	  <td align=center>6</td>
	  <td>CTCSS ENCODER OUTPUT</td>
	  <td>CTCSS tone to transmitter</td>
	</tr>
        <tr>
	  <td align=center>7</td>
	  <td>- GROUND &amp; HANG-UP</td>
	  <td>Ground.</td>
	</tr>
      </table>
    </div>
    <p>
      <div align=center>
      <table border><tr><td align=center>
	<table>
	  <tr>
	    <th>
		<font size=5 color=red>WARNING:</font><br>
		DO NOT APPLY VOLTAGE TO THE CTCSS DETECT INPUT!<br>
	    </th>
	  </tr>
	  <tr>
	    <td>
    This input is pulled low by the CTCSS decoder when CTCSS is NOT PRESENT.<br>
    It will float high when CTCSS is detected.<br>
    Application of voltage to this input will destroy Q4 and render the controller inoperative.<br>
    Damage of this nature is not covered by the
    <a href="/warranty.php">NHRC Limited Warranty</a>.
      </td></tr></table>
      </td></tr></table>
      </div>
    <p>
    The TS-32 and the TS-64 both have a high-pass filter to remove the CTCSS
    tone from the repeated audio.  By removing jumper JP3, the controller's
    audio can be passed through the audio filter on the TS-32/TS-64.
    <p>
    Note: If the audio filter is not used, then jumper JP3 must be installed
    in order for audio to be passed through the controller.
    <p>
    The Communications Specialists CTCSS boards are not supplied by NHRC.
    Contact <a href="http://www.com-spec.com">Communications Specialists</a>
    at 800-854-0547 directly to order these boards.
    <p>
    <div align=center><b>TS-64 Notes</b></div><p>
    Consult the NHRC-4/M2 TS-64 Application note for detailed connection
    instructions.
    <p>
    The TS-64 has a reverse-burst/PTT delay feature that can be used with
    the NHRC-4/M2.  This feature is useful to eliminate the squelch crash
    received by the user's radio when the repeater transmitter drops.  Note
    that the user's radios must have CTCSS decoding enabled for this to
    work.  The NHRC-4/M2 provides support for the PTT delay through jumper
    JP4.  JP4 pin 1 is the controller's PTT signal, and JP4 pin 2 is PTT to
    the MASTR II.  If the reverse-burst/PTT delay feature is not used, then
    a jumper must be installed on JP4 so the controller can key the MASTR II.
    <p>
    Adjust the CTCSS deviation with R20 on the TS-64 board, with the
    &quot;CG LEVEL&quot; pot on the MASTR II exciter set to midrange.  The
    ideal deviation for the CTCSS tone is 750 Hz.
    <p>
    Consult the <font size=2>
    <a href="http://www.com-spec.com/insheet/ts64inst.pdf">
    TS-64 INSTRUCTION SHEET</a></font> for details on
    setting the CTCSS frequency and the reverse burst.<p>
    <p>
    <div align=center><b>TS-32 Notes</b></div><p>
    The TS-32 must have the JU-2 jumper cut.  Use the OUT-2 signal from the
    TS-32 into the CTCSS detect of the NHRC-4/M2.  If you want to be able to 
    disable the CTCSS requirement, install a switch on the HANGUP lead.  The
    TS-32 will supply CTCSS encode tone to the exciter through the NHRC-4/M2.
    <p>
    Adjust the CTCSS deviation with the R29 on the TS-32 board, with the
    &quot;CG LEVEL&quot; pot on the MASTR II exciter set to midrange.  The
    ideal deviation for the CTCSS tone is 750 Hz.
    <p>
    Consult the <font size=2>TS-32 INSTRUCTION SHEET</font> for details on
    setting the CTCSS frequency.<p>

  <a name="Installing">
  <b><font size=5><li>Installing the NHRC-4/M2 into the MASTR II</font></b><br>
  </a>
    The controller installs in the MASTR II where the MASTR II
    &quot;Channel Guard&quot; board normally belongs, plugged into the top
    of the systems board in the front of the radio.  If you have not already
    removed the Channel Guard board, do so now by pulling it straight up and
    out of the radio.  The NHRC-4/M2 installs with the component side of the
    board facing the control head cable connector.  Carefully line up the
    P908 (left side) and P909 (right side) connectors with the pins on the
    system board.  Push the board down firmly until the connectors are right
    against the system board.  The controller is now installed.<p>

  <a name="LEDS">
  <b><font size=5><li>The LED Status Indicators</font></b><br>
  </a>
    The NHRC-4 repeater controller is equipped with five status LEDS
    that aid in setup and troubleshooting.  There are green LEDs for each
    radio port that indicate that the controller has getting a valid CAS
    (carrier operated switch) and, if a CTCSS decoder is connected, a 
    a valid CTCSS decode signal.  The appropriate green LED should light
    when itsreceiver is active, and, if a CTCSS decoder is present, the
    correct CTCSS tone is present.  The yellow LED indicates that a DTMF
    signal is being decoded on the primary receiver.  This LED should
    light for the entire duration that the DTMF signal is present on the
    primary receiver. The red LEDs indicates transmit.  These LED will
    light when its respective transmitter is transmitting.<p>
    The LEDS can be disabled to reduce the power consumption of the
    controller.  Remove jumper JP2 to disable the LEDS.<p>

  <a name="InstallingDelay">
  <b><font size=5><li>Installing the NHRC-DAD with the NHRC-4/M2</font></b><br>
  </a>
      <div align=center>
      <a name="DAD Connector">
      J-2 Primary Radio DAD<br>
      J-3 Secondary Radio DAD
      </a>
      <table border>
	<tr><th>Pin</th><th>Use</th></tr>
	<tr><td>1</td><td>+13.8 Volts to delay board</td></tr>
	<tr><td>2</td><td>Audio <b>to</b> delay board</td></tr>
	<tr><td>3</td><td>Audio <b>from</b> delay board</td></tr>
	<tr><td>4</td><td>Ground/Audio Return</td></tr>
      </table>
      </div>
      <p>

    The audio delay for the primary radio simply plugs in to
    <a href="#DAD Connector">J2</a>.  The  audio delay for the secondary
    radio plugs in to  <a href="#DAD Connector">J3</a>.  If the audio delay
    is not installed, a jumper between pins 2 and 3 of the port's delay
    connector must be installed, or the controller will not pass audio.
    <p>
    It is strongly recommended that the CTCSS filter be used, as described
    above, if both CTCSS encode/decode and the audio delay are used.
    <p>
    See the Operation Instructions section on 
    <a href="/nhrc-4/operating.php#Programming the Flag Bits">
    programming the flag bits</a> to tell the controller the delay is present.
    <p>

  <a name="Digital Output">
  <b><font size=5><li>Using the Digital Output</font></b><br>
  </a>
      The NHRC-4 Repeater Controller has a digital output that can be used
      for various remote control applications or to control a fan on the
      repeater's transmitter.  The digital output is an open-drain into a
      power MOSFET, which is capable of sinking quite a bit of current, but
      we recommend a maximum load of about 500 mA.  Use a relay to drive
      larger loads.  The open-drain output can be used to gate the HOOKSWITCH
      signal to a TS-32 or other CTCSS decoder, to enable or disable CTCSS.
      Software allows the output to be enabled, disabled, or pulsed.
      In fan control mode, this output will be turned on when the transmitter
      is turned on, and turned off a programmable amount of time after the
      transmitter is turned off.<p>

  <a name="AdjustingAudio">
  <b><font size=5><li>Adjusting the Audio Levels</font></b><br>
  </a>
      <div align=center>
      <b>Audio Level Adjustments</b><br>
      <table border>
	<tr><th>Potentiometer</th><th>Use</th></tr>
        <tr><td>VR1</td><td>Primary Receiver Level</td></tr>
	<tr><td>VR2</td><td>Secondary Receiver Mix Level</td></tr>
        <tr><td>VR3</td><td>Primary Receiver Mix Level</td></tr>
        <tr><td>VR4</td><td>Beep Tone Mix Level</td></tr>
        <tr><td>VR5</td><td>Primary Transmitter Master Level</td></tr>
	<tr><td>VR6</td><td>Secondary Transmitter Master Level</td></tr>
      </table>
      </div><p>
      Preset all potentiometers to midrange. Key a radio on the primary input
      frequency, send some touch-tones, and adjust VR1 (the primary receiver
      level) until DTMF decoding is reliably indicated by yellow LED D5.
      <p>
      Note:  If VR1 is set too high, a crackling noise may be heard in the
      transmitted audio during the hang time.  Reduce the level set by VR1
      until this noise goes away.  Any repeated audio level reduction caused
      by adjusting VR1 can be compensated for by adjusting VR3 (primary
      receiver level) or VR5 (primary transmitter output level.)
      <p>
      The primary radio's transmit deviation is set with VR5 (the primary
      transmitter master level) on the controller board and the transmitter's
      deviation/modulation control.  The key to properly adjusting these
      controls is to remember that the limiter in the tranmitter is
      <i>after</i> VR5 but probably <i>before</i> the transmitter's
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
      Enable the secondary receiver, and adjust VR6 for reasonable deviation
      on the enabled transmitters when a signal is received on the secondary
      receiver.
      <p>
      Adjust VR4 (the beep level) to set the courtesy tone and CW tone
      level.
      <P>
      VR3 is used to set the primary receiver's audio mix level, and may
      not need to be adjusted from midpoint.<p>
</ol>
<hr>
Back to <A HREF="/nhrc-4m2/">NHRC-4/M2 Home Page</a>
<hr>
<?php
$copydate="1998-2005";
$version="1.11";
include '../barefooter.inc';
?>
