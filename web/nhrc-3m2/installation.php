<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-3/M2 MASTR II Integrated Repeater Controller Installation</title>
<meta name="description" content="Installation instructions for the NHRC-3/M2, an integrated repeater controller for the MASTR II">
<meta name="keywords" content="NHRC-3, NHRC-3/M2, repeater controller, NHRC, talking repeater controller, MASTR II">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-3/M2 Repeater Controller</b></FONT><br>
<font size=4><b>Installation Instructions</b></font>
</div>
<hr>
These instructions will guide you in the installation and adjustment of the
NHRC-3/M2 repeater controller.<p>
<div align=center>
<font size=6><b><i>Contents</i></b></font></div><p>
<ol>
<h3><li><a href="#Preparation">MASTR II Preparation</a></h3>
<h3><li><a href="#TS32">TS-32 Hookup</a></h3>
<h3><li><a href="#Installing">Installing the NHRC-3/M2 in the MASTR II</a></h3>
<h3><li><a href="#LEDS">The LED status indicators</a></h3>
<h3><li><a href="#InstallingDelay">Installing the Audio Delay</a></h3>
<h3><li><a href="#AdjustingAudio">Adjusting the Audio Levels</a></h3>
</ol>
<p>
<hr>
<div align=center>
<img src="3m2-scrn.gif" width=600 height=186><br>
<b>Board Layout</b>
</div>
<ol>
  <a name="Preparation">
  <b><font size=5><li>MASTR II Preparation</font></b><br>
  </a>
    If you are planning to operate the MASTR II with the NHRC-3/M2 as a 
    full-duplex repeater, then you must have the duplex modification done
    before installing the NHRC-3/M2.  Consult the 
    <a href="/mastr2/">NHRC MASTR II infosite</a> for duplexing information.<p>
    There are two options for interfacing the CAS and TX audio to the
    controller.  These signals do not appear on the the CTCSS plugs on the
    system board of the MASTR II.<p>
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
    from the IFAS board).  Install 0 ohm resistors (jumpers) R34 and R35
    on the NHRC-3/M2 board5, enabling the TX audio and CAS signals on the
    J908 connector.  (Note: If you plan on using the local microphone on
    the MASTR II's control head, install a 1.5K resistor in location R34)
    </blockquote>

  <a name="TS32">
  <b><font size=5><li>TS-32 hookup</font></b><br>
  </a>
    Connector JTS32 is a 5-pin header that allows the easy installation of
    an optional Communications Specialists TS-32 for CTCSS decode and
    encode.  Wire JTS32 to the TS-32 as follows:<p>
    <div align=center>
      <b><font size=4>JTS32 Connections</font></b><br>
      <table border=1>
        <tr><th>JTS32<br>Pin #</th><th>TS-32<br>Signal</th></tr>
        <tr><td align=center>1</td><td>+V POWER</td></tr>
        <tr><td align=center>2</td><td>DECODER<br>INPUT</td></tr>
        <tr><td align=center>3</td><td>OUT-2</td></tr>
        <tr><td align=center>4</td><td>ENCODE<br>OUT</td></tr>
        <tr><td align=center>5</td><td>- GROUND &amp;<br>HANG-UP</td></tr>
      </table>
    </div>
    <p>
    The TS-32 must have the JU-2 jumper cut.  If you want to be able to 
    disable the CTCSS requirement, install a switch on the HANGUP lead.  The
    TS-32 will supply CTCSS encode tone to the exciter through the NHRC-3/M2.
    <p>
    Adjust the CTCSS deviation with the R29 on the TS-32 board, with the
    &quot;CG LEVEL&quot; pot on the MASTR II exciter set to midrange.  The
    ideal deviation for the CTCSS tone is 250-300 Hz.
    <p>
    Consult the <font size=2>TS-32 INSTRUCTION SHEET</font> for details on
    setting the CTCSS frequency.<p>
  <a name="Installing">
  <b><font size=5><li>Installing the NHRC-3/M3 into the MASTR II</font></b><br>
  </a>
    The controller installs in the MASTR II where the MASTR II
    &quot;Channel Guard&quot; board normally belongs, plugged into the top
    of the systems board in the front of the radio.  If you have not already
    removed the Channel Guard board, do so now by pulling it straight up and
    out of the radio.  The NHRC-3/M2 installs with the component side of the
    board facing the control head cable connector.  Carefully line up the
    P908 (left side) connector with the pins on the system board.  The P909
    connector may not cover all the pins on the right side; this is ok, since
    that connector is used for physical support of the controller only.
    Push the board down firmly until the connectors are right against the
    system board.  The controller is now installed.<p>
  <a name="LEDS">
  <b><font size=5><li>The LED Status Indicators</font></b><br>
  </a>
    The NHRC-3/M2 repeater controller is equipped with three status LEDS
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
  <b><font size=5><li>Installing the NHRC-DAD with the NHRC-3/M2</font></b><br>
  </a>
    Remove the jumper between pins 2 and 3 of J2, then plug the cable from
    the audio delay board onto the J2 header.  If the audio delay is not
    installed, then the jumper must be present between pins 2 and 3 of J2.<p>
    The NHRC-DAD is small enough to fit in either the exciter &quot;bay&quot;
    or the oscillator/multiplier &quot;bay&quot; of the MASTR II chassis.
    Carefully route the cable to either of these locations.  You may need to
    file a small notch into the plastic chassis to make room for the cable
    to pass through to the NHRC-DAD board.<p>
  <a name="AdjustingAudio">
  <b><font size=5><li>Adjusting the Audio Levels</font></b><br>
  </a>
    Preset all potentiometers to midrange. Key a radio on the input
    frequency, send some touch-tones, and adjust VR1 (the main receive
    level) until DTMF decoding is reliably indicated by yellow LED D4.
    <p>
    Deviation is set with VR2 (the master level) on the controller board
    and the &quot;MOD ADJUST&quot; control on the exciter.  The key to
    properly adjusting these controls is to remember that the limiter in
    the exciter is <i>after</i> VR2 but <i>before</i> the &quot;MOD
    ADJUST&quot; control.  The MOD ADJUST control will set the actual
    <i>peak</i> deviation, and VR2 will set the level into the limiter.
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
    audio.  VR5 sets  the ISD2590 playback level.  Adjust this control
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
Back to <A HREF="/nhrc-3m2/">NHRC-3/M2 Home Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.21";
include '../barefooter.inc';
?>
