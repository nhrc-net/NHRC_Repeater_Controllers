<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-4 Repeater Controller Operation</title>
<meta name="description" content="Operating instructions for NHRC-4 Repeater Controller, an inexpensive linking repeater controller">
<meta name="keywords" content="NHRC-4, repeater controller, NHRC, linking repeater controller">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-4 Repeater Controller</b></FONT><br>
<font size=4><b>Operation Instructions</b></font>
</div>
<hr>
These instructions will guide you in the operation of the
NHRC-4 Repeater Controller.  For installation instructions, see
the installation manual.<p>
<div align=center>
  <font size=6><b><i>Contents</i></b></font>
</div>
<p>
<ol>
  <font size=5><b><li><a href="#Introduction">Introduction</a></b></font><br>
  <font size=5><b><li><a href="#Initializing">Initializing</a></b></font><br>
  <font size=5><b><li><a href="#Programming">Programming the Controller</a></b></font>
  <ol>
    <font size=4><b><li><a href="#Programming the Timers">Programming the Timers</a></b></font>
    <font size=4><b><li><a href="#Programming the CW Messages">Programming the CW Messages</a></b></font>
    <font size=4><b><li><a href="#Programming the Flag Bits">Programming the Flag Bits</a></b></font>
    <font size=4><b><li><a href="#Programming the Courtesy Tones">Programming the Courtesy Tones</a></b></font>
    <font size=4><b><li><a href="#Previewing CW">Previewing Stored CW Messages</a></b></font>
  </ol>
  <p>
  <font size=5><b><li>Operating</b></font>
  <ol>
    <font size=4><b><li><a href="#Enabling">Enabling/Disabling the Repeater</a></b></font>
    <font size=4><b><li><a href="#Audio Delay">
      Using the NHRC-DAD Digital Audio Delay with the NHRC-4 Repeater Controller</a></b></font>
  </ol>
  <p>
  <font size=5><b><li>
    <a href="#Programming Example">Programming Example</a></b></font>
</ol>
<div align=center>
  <font size=6><b><i>Index of Tables</i></b></font>
</div>
<blockquote>
  <ul>
    <li><a href="#Configuration Flag Bits">Configuration Flag Bits</a>
    <li><a href="#Message Numbers">Message Numbers</a>
    <li><a href="#Morse Code Character Encoding">Morse Code Character Encoding</a>
    <li><a href="#Programming Memory Map">Programming Memory Map</a>
    <li><a href="#Timer Address and Resolution">Timer Address and Resolution</a>
    <li><a href="#DefaultCourtesyTones">Default Courtesy Tones Table</a>
    <li><a href="#HalfCourtesyTones">Half Courtesy Tones</a>
    <li><a href="#OperationalModes">Operational Modes</a>
  </ul>
</blockquote>
<hr>
<ol>
  <a name="Introduction">
  <font size=5><b><li>Introduction</b></font></a><br>

The NHRC-4 has 2 radio &quot;ports&quot;, which are connectors that the
radios connect to.  There is a &quot;primary&quot; and a &quot;secondary&quot;
radio port.<p>
The &quot;primary&quot; radio port is where the &quot;main&quot; repeater
connects.  All DTMF commands must come from here.  When the primary radio
is disabled, the secondary radio is also disabled.<p>
The &quot;secondary&quot; radio port is where the secondary radio connects.
The secondary radio can be a remote base, link radio, or a second repeater,
which when activated, is &quot;married&quot; to the primary repeater. The
secondary radio can be disabled without any effect on the primary radio.
No DTMF commands are accepted from this port.<p>

The secondary radio can be a &quot;Remote Base,&quot; which is a simplex radio
connected to the repeater system that allows the repeater users to remotely
operate on a different frequency/mode/band than the repeater.<p>
The secondary radio can be a link radio to interconnect the repeater on the
main port to a distant repeater.  The link radio can be simplex or full-duplex.
In the case of a full-duplex link, the main receiver and the link receiver
can be repeated over both transmitters simultaneously.  A simplex link will
always transmit when the main receiver is active, potentially blocking any
traffic that might be received over the link at that time.<p>
The secondary port can be connected to a repeater which will &quot;marry&quot;
or &quot;slave&quot; to the main repeater.  Anything received on either
repeater will be re-transmitted by both repeaters.  This allows repeaters on
two different bands to be easily and inexpensively linked.<p>
The secondary port has several different modes of operation that apply to some
or all of the applications described above.  The secondary port's modes can
only be selected by sending DTMF to the receiver connected to the primary
radio port.  These modes are:
<ul>
<li>disabled
<li>alert mode
<li>monitor mode
<li>transmit mode
</ul>
<p>
In disabled mode, the secondary radio port is ignored by the controller.<p>
Alert Mode is a mode in which a different courtesy tone will be played
if the receiver on the secondary port is unsquelched when the courtesy
tone is requested.  This is useful to indicate that traffic exists on
a remote base frequency without having to hear the remote base traffic
being repeated.<p>
In monitor mode, the secondary radio's receiver audio is retransmitted
over the primary repeater, but the secondary port is inhibited from
transmitting.  This mode is also useful for remote base operation and
monitoring linked repeaters.<p>
In transmit mode, the secondary radio's receiver audio is retransmitted
by the primary radio, and the primary radio's audio is transmitted over
the secondary radio.  This mode is useful for remote bases, linked
repeaters, and married repeaters.<p>
A married repeater requires that the controllers &quot;secondary port is a
duplex repeater&quot; option be set.  This option changes how the PTT line
to the secondary radio port operates.  Normally, the secondary radio
port's PTT line follows the primary radio port's CAS (receiver active)
line, that is the secondary port transmits when enabled and the primary
receiver is active.  When the &quot;secondary port is a duplex repeater&quot;
option is set, the secondary radio port's PTT line follows the primary
radio port's PTT line, so that the courtesy tone and tail are transmitted
on the married repeater.<p>

  The controller's programming is protected from unauthorized access
  by a 4-digit secret passcode.  The controller is programmed by
  8-digit DTMF commands that all begin with the 4-digit passcode.
  Throughout this manual, commands will be shown as <i>pppp</i>NNNN,
  where <i>pppp</i> represents the passcode, and NNNN is the actual
  command to the controller.<p>

In order to save space in the microprocessor memory, the NHRC-4
repeater controller represents all numbers in &quot;hexadecimal&quot;
notation.  Hexadecimal, or &quot;hex&quot; for short, is a base-16
number format that allows a 8-bit number to be represented in two
digits.  Hex numbers are 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, and F.
Converting decimal (the normal base-10 numbers that 10-fingered
humans prefer) to hex is simple.  Divide the decimal number by 16
to get the 1st hex digit (10=A, 11=B, 12=C, 13=D, 14=E, 15=F), the
remainder is the 2nd hex digit.  For example,
60 decimal = 3 x 16 + 12 = 3C hex.  Any decimal number from 0 to 255
may be represented in only 2 hex digits.
<p>
Many scientific calculators can convert between these two number systems,
and the Windows 95 calculator can, too, if the &quot;scientific&quot;
view is selected. We provide a WWW page that can generate all the
programming data for the NHRC-4 controller quickly and easily, see
<A href="nhrc4prog.php">
http://www.nhrc.net/nhrc-4/nhrc4prog.php</a>.
<p>
A 16 key DTMF pad has keys 0-9 and A-D, which map directly to their
corresponding hex digits.  Use the <b>*</b> key for digit <b>E</b>
and the <b>#</b> key for digit <b>F</b>.  A 16-key DTMF pad is
required to program the controller.
<p>
<b>Note that all programming of the NHRC-4 must be transmitted to the
radio attached to the primary radio port.</b><p>
<a name="Initializing">
<font size=5><b><li>Initializing the Controller</b></font>
</a><br>
  The controller will need to be initialized to allow you to set your
  secret passcode.  Initializing the controller also resets all
  programmable settings to the factory defaults, including the CW ID
  message. It should not be nessecary to initialize the controller again,
  unless you want to change the passcode.  <B>The only way to change the
  passcode is to initialize the controller.</b><p>
  To initialize the controller, remove power and install the init
  jumper (JP3).  Apply power to the controller, and after a few seconds,
  remove the init jumper.  The controller is now in the initialize mode.
  If you &quot;kerchunk&quot; the primary port's receiver now, it will send
  the default CW ID of &quot;DE NHRC/4&quot;.  Now transmit (into the primary
  receiver) your 4-digit passcode.  The controller will respond by sending
  &quot;OK&quot; in CW <b>once</b>.  The controller will store the passcode
  and the main repeater will be enabled.<p>
  <a name="Programming">
  <font size=5><b><li>Programming the Controller</b></font>
  </a>
  <p>
    All programming is done by entering 8-digit DTMF sequences.  The first 4
    digits are the <i>passcode</i> chosen at initialization.  The next 2
    digits are an <i>address</i> or a <i>function code</i>.  The last 2 digits
    are the <i>data</i> for address or function.  To enter programming
    information, you must key your radio, enter the 8 digits, then unkey.  If
    the controller understands your sequence, it will respond with "OK" in CW.
    If there is an error in your sequence, but the passcode is good, the
    controller will respond with "NG".  If the controller does not understand
    your command at all, it will not respond with anything other than a
    courtesy beep, and then only if the courtesy beep is enabled.  If the
    controller is disabled, and an unrecognized command is entered,
    no response will be transmitted at all.
    <p>
    <center><table border>
    <caption><b>Responses to Commands</b></caption>
    <tr><th>Response</th><th>Meaning</th></tr>
    <tr><td>"OK"</td><td>Command accepted</td></tr>
    <tr><td>"NG"</td><td>Command address or data is bad</td></tr>
    <tr>
      <td>courtesy beep<br>or nothing</td>
      <td>Command/password not accepted</td>
    </tr>
    </table></center><br>
    If you enter an incorrect sequence, you can unkey before all 8 digits are
    entered, and the sequence will be ignored.  If you enter incorrect
    address or data values, just re-program the location affected with the
    correct data.
    <p>
    <ol>
      <a name="Programming the Timers">
      <font size=4><b><li>Programming the Timers</b></font></a><br>
      The NHRC-4 Repeater Controller provides several timers which
      control the operation of your repeater.  The <i>Hang Timer</i>
      controls how long the repeater will continue to transmit after a
      received signal drops.  This is often called the repeater's
      &quot;tail.&quot;  The tail is useful to eliminate annoying squelch
      crashes on users' radios.  As long as a reply is transmitted before the
      hang timer expires, the repeater will not drop, which would cause a
      squelch crash in the users' radios.<p>
      The <i>Timeout Timer</i> controls the maximum duration of the
      retransmission of a received signal.  It is more of a safety measure
      to protect the repeater from damage than a way to discourage long-winded
      users, even though it is often used that way.  The NHRC-4 has a separate
      timeout timer for each port.  The timeout timer(s) can be disabled by
      programming a 0 length.<p>
      The <i>ID Timer</i> sets the maximum duration between transmissions
      of the repeater's ID message(s).  (Note that the NHRC-4 may transmit
      an ID message before the timer expires in order to avoid transmitting
      the ID message while a user is transmitting.)<p>
      The timer values are stored as an 8-bit value which allows a range of 0
      to 255.  Some of the timers require high-resolution timing of short
      durations, and others require lower resolution timing of longer durations.
      Therefore, timers values are scaled by either 1/10, 1, or 10 seconds,
      depending on the application.<p>
      <a name="Timer Address and Resolution">
      <div align=center>
        <table border>
          <caption><b>Timer Address and Resolution</b></caption></a>
          <tr>
            <th>Timer</th>
            <th>Address</th>
            <th>Resolution<br>Seconds</th>
            <th>Max. Value<br>Seconds</th>
          </tr>
          <tr><td>Hang Timer</td><td>03</td><td>1/10</td><td>25.5</td></tr>
          <tr><td>Primary Receiver Timeout Timer</td><td>04</td><td>1</td><td>255</td></tr>
          <tr><td>Secondary Receiver Timeout Timer</td><td>05</td><td>1</td><td>255</td></tr>
          <tr><td>ID Timer</td><td>06</td><td>10</td><td>2550</td></tr>
          <tr><td>Fan Timer</td><td>07</td><td>10</td><td>2550</td></tr>
        </table>
      </div>
      <p>
      Enter the 4-digit passcode, the timer address, and the timer value,
      scaled appropriately.  For example, to program the Hang Timer for 10
      seconds, enter <i>pppp0364</i>, where <i>pppp</i> is your secret
      passcode, 03 is the hang timer address, and 64 is the hexadecimal value
      for 100, which would be 10.0 seconds.
      <p>
      <a name="Programming the CW Messages">
      <font size=4><b><li>Programming the CW Messages</b></font></a><br>
      CW messages are programmed by storing encoded CW characters into specific
      addresses in the controller.  Use the
      <a href="#Morse Code Character Encoding">Morse Code Character Encoding</a>
      table and the <a href="#Programming Memory Map">Programming Memory Map</a>
      to determine the data and address for the CW message characters.  For
      example, to program "DE N1KDO/R" for the CW ID, you would use the
      following commands:
      <p>
      <div align=center>
        <table border>
          <tr>
	    <th>DTMF Command</th>
	    <th>Address</th>
	    <th>Data</th>
	    <th>Description/Purpose</th>
	  </tr>
          <tr><td><i>pppp</i>2609</td><td>26</td><td>09</td><td>D</td></tr>
          <tr><td><i>pppp</i>2702</td><td>27</td><td>02</td><td>E</td></tr>
          <tr><td><i>pppp</i>2800</td><td>28</td><td>00</td><td>space</td></tr>
          <tr><td><i>pppp</i>2905</td><td>29</td><td>05</td><td>N</td></tr>
          <tr><td><i>pppp</i>2A3*</td><td>2A</td><td>3E</td><td>1</td></tr>
          <tr><td><i>pppp</i>2B0D</td><td>2B</td><td>0D</td><td>K</td></tr>
          <tr><td><i>pppp</i>2C09</td><td>2C</td><td>09</td><td>D</td></tr>
          <tr><td><i>pppp</i>2D0#</td><td>2D</td><td>0F</td><td>O</td></tr>
          <tr><td><i>pppp</i>2*29</td><td>2E</td><td>29</td><td>/</td></tr>
          <tr><td><i>pppp</i>2#0A</td><td>2F</td><td>0A</td><td>R</td></tr>
          <tr>
	    <td><i>pppp</i>30##</td>
	    <td>30</td><td>FF</td>
	    <td>End of message marker</td>
	  </tr>
        </table>
      </div><br>
      The CW ID can store a message of up to 20 characters.  Do not exceed 20
      characters.  Be sure to include the end-of-message character (FF) at the
      end of each message.
      <p>
      <a name="Programming the Flag Bits">
      <font size=4><b><li>Programming the Flag Bits</b></font></a><br>
      Controller features can be enabled with the use of the
      <a href="#Configuration Flag Bits">Configuration Flag Bits</a>.
      These bits are encoded in a single byte, which is programmed into
      the controller at address 01.  Multiple flag bits can be selected by
      adding their hex weights.<p>

      For example, to set up a controller with an audio delay on each port,
      and configure the digital output for fan control, you would add
      02, 04, and 10 to produce hex 16, which you would then program into
      address 01 in the controller with this command:<br>
	  <div align=center><tt>pppp0131</tt></div>
      <p>
      In addition to programming the flag bits as a group using address 01,
      the controller supports commands to set or clear these bits individually.
      Command 60 is used to clear (zero) a specified configuration bit, and
      command 61 is used to set (one) a specified configuration bit.  For
      example, to set (turn on) bit 3 (to suppress DTMF muting), enter
      the following command: <tt>pppp6103</tt>.  To clear bit 3 and enable
      the DTMF muting, enter this command:  <tt>pppp6003</tt>.  Note that
      the bit <i>number</i>, not it's hex weight is used for commands 60 and
      61.
      <p>
      <div align=center>
	<a name="Configuration Flag Bits">
<table border>
<caption><b>Configuration Flag Bits</b></caption>
<tr>
  <th>Bit</th>
  <th>Hex<br>Weight</th>
  <th>Binary<br>Value</th>
  <th>Feature</th>
</tr>
<tr>
  <td align=center>0</td>
  <td align=center>01</td>
  <td>00000001</td>
  <td>secondary port is duplex repeater</td>
</tr>
<tr>
  <td align=center>1</td>
  <td align=center>02</td>
  <td>00000010</td>
  <td>audio delay on primary receiver</td>
</tr>
<tr>
  <td align=center>2</td>
  <td align=center>04</td>
  <td>00000100</td>
  <td>audio delay on secondary receiver</td>
</tr>
<tr>
  <td align=center>3</td>
  <td align=center>08</td>
  <td>00001000</td>
  <td>disable DTMF muting</td>
</tr>
<tr>
  <td align=center>4</td>
  <td align=center>10</td>
  <td>00010000</td>
  <td>digital output is fan control</td>
</tr>
<tr>
  <td align=center>5</td>
  <td align=center>20</td>
  <td>00100000</td>
  <td>main receiver has priority over link receiver<font color=red>*</font></td>
</tr>
<tr>
  <td align=center>6</td>
  <td align=center>40</td>
  <td>01000000</td>
  <td>drop main transmitter to mute DTMF<font color=red>**</font></td>
</tr>
<tr>
  <td align=center>7</td>
  <td align=center>80</td>
  <td>10000000</td>
  <td>drop secondary transmitter to mute DTMF<font color=red>**</font></td>
</tr>
</table>
<font color=red>*</font>Software version &gt;= 1.4 only.<br>
<font color=red>*</font>Software version &gt;= 2.2 only.
</a>
<p>
<table border>
	  <caption><b>Example Configurations</b></caption>
	  <tr><th>Flag Bits<br>Value</th><th>Features Selected</th></tr>
	  <tr><td align=center>00</td><td>none</td></tr>
	  <tr><td align=center>01</td><td>duplex repeater on secondary port</td></tr>
	  <tr><td align=center>08</td><td>no DTMF muting</td></tr>
	  <tr><td align=center>10</td><td>digital output is fan control</td></tr>
	  <tr><td align=center>11</td><td>duplex repeater on secondary port<br>
	                     digital output is fan control</td></tr>
	  <tr><td align=center>17</td><td>duplex repeater on secondary port<br>
	                     NHRC-DAD on primary port<br>
	                     NHRC-DAD on secondary port<br>
	                     digital output is fan control</td></tr>
	  <tr><td align=center>36</td><td>NHRC-DAD on primary port<br>
	      NHRC-DAD on secondary port<br>
	      digital output is fan control<br>
	      main receiver has priority over link receiver<font color=red>*</font></td></tr>
	  <tr><td align=center>1F</td><td>duplex repeater on secondary port<br>
	                     NHRC-DAD on primary port<br>
	                     NHRC-DAD on secondary port<br>
	                     no DTMF muting<br>
	                     digital output is fan control</td></tr>
        </table>
	<font color=red>*</font>Software version &gt;= 1.4 only.
      </div>
      <p>
    <a name="Programming the Courtesy Tones">
    <font size=4><b><li>Programming the Courtesy Tones</b></font></a><br>
    The NHRC-4 uses up to five different courtesy tones to indicate various
    events:
	<ul>
	  <li>primary receiver
	  <li>primary receiver, the secondary transmitter enabled
	  <li>primary receiver, alert mode
	  <li>secondary receiver
	  <li>secondary receiver, secondary transmitter enabled
        </ul><p>
    Each tone is individually programmable, and can be unique
    for that event, programmed to be the same as other events, or programmed
    empty to be silent.<p>
    The NHRC-4 will play the appropriate courtesy tones 500 milliseconds
    (1/2 second) after a receiver drops.  The courtesy tones all consist of
    four 100 millisecond (1/10 second) segments.  Each segment can be no tone,
    low tone (a &quot;boop&quot;, about 440 hertz), or high tone (a
    &quot;beep&quot;, about 880 hertz).  If all the segments are programmed
    as no tone, the courtesy tone will be disabled. The default courtesy
    tones are shown in the
    <a href="#DefaultCourtesyTones">Default Courtesy Tones Table</a>.
    <div align=center>
    <a name="DefaultCourtesyTones">
    <table border>
    <caption><b>Default Courtesy Tones</b></caption>
    <tr>
      <th>Event</th>
      <th>Default Tones</th>
      <th>Binary<br>Encoding</th>
      <th>Hex<br>Encoding</th>
    </tr>
    <tr>
      <td>Primary Receiver</td>
      <td>beep none none none</td>
      <td align=center>00 00 00 01</td>
      <td align=center>01</td>
    </tr>
    <tr>
      <td>Primary Receiver<br>Secondary Transmitter Enabled</td>
      <td>beep none beep none</td>
      <td align=center>00 01 00 01</td>
      <td align=center>11</td>
    </tr>
    <tr>
      <td>Primary Receiver<br>Secondard Receiver Alert Mode</td>
      <td>beep none boop none</td>
      <td align=center>00 11 00 01</td>
      <td align=center>31</td>
    </tr>
    <tr>
      <td>Secondary Receiver</td>
      <td>boop none none none</td>
      <td align=center>00 00 00 11</td>
      <td align=center>03</td>
    </tr>
    <tr>
      <td>Secondary Receiver<br>Secondary Transmitter Enabled</td>
      <td>boop none boop none</td>
      <td align=center>00 11 00 11</td>
      <td align=center>33</td>
    </tr>
    </table>
    </a>
    </div>
    <p>
    The courtesy tones are encoded as four pairs of bits, with the first segment
    encoded as the two least significant bits, and the fourth segment encoded as
    the 2 most significant bits.  Each pair of bits is allowed three possible
    values to indicate no tone, beep, or boop.  The
    <a href="#HalfCourtesyTones">Half Courtesy Tones</a> table shows tones
    generated for valid 4-bit values and their hex representation.  To use
    this table, first determine the tones for each of the four segments,
    then find the hex digit that represents the first and second pair of
    tones.  The second pair's digit becomes the first hex digit, and the
    first pair's digit becomes the second hex digit.  For example, to encode
    a courtesy tone of boop-beep-boop-none, you would find the first pair
    (boop-beep) in the table as the hex digit D and the second pair
    (boop-none) in the table as the hex digit 3, so your courtesy tone
    would be encoded as 3D.<p>
    <div align=center>
    <a name="HalfCourtesyTones">
    <table border>
    <caption><b>Half Courtesy Tones</b></caption>
    <tr>
      <th>Tones</th>
      <th>Binary<br>Encoding</th>
      <th>Hex<br>Encoding</th>
    </tr>
    <tr>
      <td>none none</td>
      <td align=center>00 00</td>
      <td align=center>0</td>
    </tr>
    <tr>
      <td>none beep</td>
      <td align=center>01 00</td>
      <td align=center>4</td>
    </tr>
    <tr>
      <td>none boop</td>
      <td align=center>11 00</td>
      <td align=center>C</td>
    </tr>
    <tr>
      <td>beep none</td>
      <td align=center>00 01</td>
      <td align=center>1</td>
    </tr>
    <tr>
      <td>beep beep</td>
      <td align=center>01 01</td>
      <td align=center>5</td>
    </tr>
    <tr>
      <td>beep boop</td>
      <td align=center>01 11</td>
      <td align=center>7</td>
    </tr>
    <tr>
      <td>boop none</td>
      <td align=center>00 11</td>
      <td align=center>3</td>
    </tr>
    <tr>
      <td>boop beep</td>
      <td align=center>11 01</td>
      <td align=center>D</td>
    </tr>
    <tr>
      <td>boop boop</td>
      <td align=center>11 11</td>
      <td align=center>F</td>
    </tr>
    </table>
    </a>
    </div>
    <p>
    <a name="Previewing CW">
    <font size=4><b><li>Previewing Stored CW Messages</b></font></a><br>
    Stored CW messages can be previewed with the command <i>40</i> followed
    with the message number you want to preview.  The message numbers can be
    found in the <a href="#Message Numbers">Message Numbers</a> table.  For
    example, to preview the secondary receiver timeout message, send command:<br>
	<div align=center><tt>pppp4004</tt></div><p>
  </ol>
  <font size=5><b><li>Operating</b></font><br>
  <ol>
    <a name="Enabling">
    <font size=4><b><li>Enabling/Disabling the Repeater</b></font></a><br>
    The radio ports can be disabled or enabled by remote control by setting
    the code for the operational mode in location 00.  See the
    <a href="#OperationalModes">Operational Modes Table</a> for the codes that
    indicate the mode you want.<p>
    <div align=center>
    <a name="OperationalModes">
    <table border>
    <caption><b>Operational Modes</b></caption>
    <tr>
      <th>Code</th>
      <th>Operational Mode</th>
    </tr>
    <tr>
      <td align=center>00</td>
      <td>Primary &amp; Secondary off</td>
    </tr>
    <tr>
      <td align=center>01</td>
      <td>Primary enabled</td>
    </tr>
    <tr>
      <td align=center>02</td>
      <td>Primary enabled, secondary alert mode</td>
    </tr>
    <tr>
      <td align=center>03</td>
      <td>Primary enabled, secondary monitor mode</td>
    </tr>
    <tr>
      <td align=center>04</td>
      <td>Primary enabled, secondary transmit mode</td>
    </tr>
    </table>
    </a>
    </div>
    <p>
    For instance, to disable the repeater, send command:<br>
    <div align=center><tt>pppp0000</tt></div><br>
    To enable the repeater on the primary port, send command:<br>
    <div align=center><tt>pppp0001</tt></div><br>
    To enable the repeater on the primary port, and select monitor
    mode for the secondary port, send command:<br>
    <div align=center><tt>pppp0003</tt></div><p>

    <a name="Audio Delay">
    <font size=4><b><li>
    Using the NHRC-DAD Digital Audio Delay with the NHRC-4 Repeater Controller.
    </b></font></a><br>
    The NHRC-4 Repeater Controller supports the optional NHRC-DAD
    digital audio delay board.  The NHRC-DAD allows complete muting of
    received DTMF tones (no leading beep before muting), and suppression
    of squelch crashes when the received signal drops.  The NHRC-DAD has
    a 128 ms delay on all received audio.  The NHRC-4 Repeater Controller
    supports a NHRC-DAD on both radio ports with a software switch and a
    dedicated DAD connector for each port.
    If the DAD is not present, then a jumper must be installed between
    pins 2 and 3 of the DAD connector (see installation manual).  If the
    DAD is present, then the appropriate configuration flag bit must be
    set.<p>
  </ol>
  <a name="Programming Example">
  <font size=5><b><li>Programming Example</b></font></a><br>
    Programming the NHRC-4 Repeater Controller can seem quite
    complicated at first.  This section of the manual is intended as a
    tutorial to help you learn how to program your controller.<p>
    Let's assume we want to program a NHRC-4 Repeater Controller
    with the following parameters:<p>
    <blockquote>
      CW ID: DE N1LTL/R FN42<br>
      Hang Time 7.5 seconds<br>
      Timeout timer 120 seconds<br>
    </blockquote><p>
    First, we will initialize the controller.  Install JP3 and apply power
    to the controller to initialize.  After a few seconds, remove JP3.
    Send DTMF <tt>2381</tt> to set access code to 2381.  The controller
    will send &quot;OK&quot; in CW to indicate the passcode was accepted.
    Now the controller is initialized, and disabled.<p>
    Now we will enable the controller.  Send DTMF <tt>23810001</tt>
    (passcode=2381, address=00, data=01).  The controller will send
    &quot;OK&quot; in CW to indicate the command was successful.<p>
    We will now program the CW ID.  Looking at the &quot;Programming Memory
    Map&quot;, we can see that the first location for the CW ID is 26.  The
    first letter of the ID is 'D', which we look up in the &quot;Morse Code
    Character Encoding&quot; table and discover that the encoding for 'D'
    is 09.  Location 26 gets programmed with 09.<p>
    Send DTMF <tt>23812609</tt> to program the letter 'D' as the first
    character of the CW ID.  The controller will send &quot;OK&quot; in CW
    if the command is accepted.  If you entered the command correctly, but
    you don't get the &quot;OK&quot;, your DTMF digits may not all be
    decoding.  See the Installation Guide for your controller to readjust
    the audio level for the DTMF decoder.<p>
    The next character is the letter 'E', which is
    encoded as 02, and will be programmed into the next address, 27.
    Send DTMF <tt>23812702</tt>.<p>
    The next character is the space character, and it will be programmed
    into address 29.  Send DTMF 23812800.  Here are the rest of the
    sequences to program the rest of the ID message:<br>
    <blockquote>
      <tt>23812905</tt> (N in address 29)<br>
      <tt>23812A3*</tt> (1 in address 2A)<br>
      <tt>23812B12</tt> (L in address 2B)<br>
      <tt>23812C03</tt> (T in address 2C)<br>
      <tt>23812D12</tt> (L in address 2D)<br>
      <tt>23812*29</tt> (/ in address 2E)<br>
      <tt>23812#0A</tt> (R in address 2F)<br>
      <tt>23813000</tt> (space in address 30)<br>
      <tt>23813114</tt> (F in address 31)<br>
      <tt>23813205</tt> (N in address 32)<br>
      <tt>23813330</tt> (4 in address 33)<br>
      <tt>2381343C</tt> (2 in address 34)<br>
      <tt>238135FF</tt> (EOM in address 35)<br>
    </blockquote>
    After the last character of the CW ID is programmed, the End-of-Message
    character must be programmed.  In this case, the last character of the
    ID message was programmed into address 34, so the EOM character, which
    is encoded as FF, goes into address 35:<br>
    <tt>238135##</tt> (EOM into address 35.)<p>
    To program the hang timer, we must first determine the address of the
    hang timer by consulting the Programming Memory Map.  The Hang Timer
    preset is stored in location 03.  Next, we need to convert the 7.5
    seconds into tenths, which would be 75 tenths of a second.  Then the
    75 gets converted to hex:<br>
    <blockquote>
      75 / 16 = 4 with a remainder of 11, so 75 decimal equals 4B hex.
    </blockquote>
    Now program the hang timer preset by sending <tt>2381034B</tt>.<p>
    To program the primary receiver's timer with 120 seconds, we get the
    address of the primary receiver's timeout timer preset, which is 04,
    and then convert 120 seconds to hex:<br>
    <blockquote>
      120 / 16 = 7 with a remainder of 8, so 120 decimal equals 78 hex.
    </blockquote>
    So we will program location 04 with 78: <tt>23810478</tt><p>
    Any CW message can be played back at any time by "programming" location
    40 with the message code you want to play.  To play the CW ID, send
    <tt>23814000</tt>.<p>
  </ol>
<hr>
<div align=center>
  <font size=6><b>Tables</b></font>
  <a name="Message Numbers">
  <table border>
    <caption><b>Message Contents</b></caption>
    <tr><th>Message Number</th><th>Contents</th><th>Default</th></tr>
    <tr><td>0</td><td>ID message</td><td>DE NHRC/4</td></tr>
    <tr><td>1</td><td>primary receiver timeout message</td><td>TO</td></tr>
    <tr><td>2</td><td>valid command confirm message</td><td>OK</td></tr>
    <tr><td>3</td><td>invalid command message</td><td>NG</td></tr>
    <tr><td>4</td><td>secondary receiver timeout message</td><td>RB TO</td></tr>
  </table>
  </a>
  <p>
  <a name="Programming Memory Map">
<table border>
<caption><b>Programming Memory Map</b></caption>
<tr><th>Address</th><th>Default Data</th><th>Comment</th></tr>
<tr><td valign=top>00</td><td valign=top>01</td><td>enable flag<br>
                              00 Primary &amp; Secondary off<br>
                              01 Primary repeater enabled<br>
                              02 Primary enabled, secondary alert mode<br>
                              03 Primary enabled, secondary monitor mode<br>
                              04 Primary enabled, secondary transmit mode<br>
</td></tr>
<tr><td>01</td><td>10</td><td>Configuration Flags (see table)</td></tr>
<tr><td valign=top>02</td><td valign=top>00</td><td>Digital output control<br>
                              00 off<br>
                              01 on<br>
                              02 1/2 sec on pulse</td></tr>
<tr><td>03</td><td>32</td><td>Hang timer preset, in tenths</td></tr>
<tr><td>04</td><td>1e</td><td>Primary receiver timout timer, in seconds</td></tr>
<tr><td>05</td><td>1e</td><td>Secondary receiver timout timer, in seconds</td></tr>
<tr><td>06</td><td>36</td><td>id timer preset, in 10 seconds</td></tr>
<tr><td>07</td><td>00</td><td>fan timer, in 10 seconds</td></tr>
<tr><td>08</td><td>01</td><td>primary receiver courtesy tone</td></tr>
<tr><td>09</td><td>11</td><td>primary receiver courtesy tone<br>
                              secondary transmitter enabled</td></tr>
<tr><td>0a</td><td>31</td><td>primary receiver courtesy tone<br>
                              secondary receiver alert mode</td></tr>
<tr><td>0b</td><td>03</td><td>secondary receiver courtesy tone</td></tr>
<tr><td>0c</td><td>33</td><td>secondary receiver courtesy tone<br>
                              secondary transmitter enabled</td></tr>
<tr><td>0d</td><td>00</td><td>reserved</td></tr>
<tr><td>0e</td><td>0f</td><td>'O'    OK Message</td></tr>
<tr><td>0f</td><td>0d</td><td>'K' </td></tr>
<tr><td>10</td><td>ff</td><td>EOM </td></tr>
<tr><td>11</td><td>ff</td><td>EOM </td></tr>
<tr><td>12</td><td>ff</td><td>EOM </td></tr>
<tr><td>13</td><td>ff</td><td>EOM </td></tr>
<tr><td>14</td><td>05</td><td>'N'    NG Message</td></tr>
<tr><td>15</td><td>0b</td><td>'G' </td></tr>
<tr><td>16</td><td>ff</td><td>EOM </td></tr>
<tr><td>17</td><td>ff</td><td>EOM </td></tr>
<tr><td>18</td><td>ff</td><td>EOM </td></tr>
<tr><td>19</td><td>ff</td><td>EOM </td></tr>
<tr><td>1a</td><td>03</td><td>'T'    TO Message</td></tr>
<tr><td>1b</td><td>0f</td><td>'O' </td></tr>
<tr><td>1c</td><td>ff</td><td>EOM </td></tr>
<tr><td>1d</td><td>ff</td><td>EOM </td></tr>
<tr><td>1e</td><td>ff</td><td>EOM </td></tr>
<tr><td>1f</td><td>ff</td><td>EOM </td></tr>
<tr><td>20</td><td>0a</td><td>'R'    TO Message</td></tr>
<tr><td>21</td><td>22</td><td>'B' </td></tr>
<tr><td>22</td><td>00</td><td>' ' </td></tr>
<tr><td>23</td><td>03</td><td>'T' </td></tr>
<tr><td>24</td><td>0f</td><td>'O' </td></tr>
<tr><td>25</td><td>ff</td><td>EOM </td></tr>
<tr><td>26</td><td>09</td><td>'D'    CW ID starts here</td></tr>
<tr><td>27</td><td>02</td><td>'E'    </td></tr>
<tr><td>28</td><td>00</td><td>space  </td></tr>
<tr><td>29</td><td>05</td><td>'N'    </td></tr>
<tr><td>2a</td><td>10</td><td>'H'    </td></tr>
<tr><td>2b</td><td>0a</td><td>'R'    </td></tr>
<tr><td>2c</td><td>15</td><td>'C'    </td></tr>
<tr><td>2d</td><td>29</td><td>'/'    </td></tr>
<tr><td>2e</td><td>30</td><td>'4'    </td></tr>
<tr><td>2f</td><td>ff</td><td>EOM    </td></tr>
<tr><td>30</td><td>ff</td><td>EOM    </td></tr>
<tr><td>31</td><td>ff</td><td>EOM    </td></tr>
<tr><td>32</td><td>ff</td><td>EOM    </td></tr>
<tr><td>33</td><td>ff</td><td>EOM    </td></tr>
<tr><td>34</td><td>ff</td><td>EOM    </td></tr>
<tr><td>35</td><td>ff</td><td>EOM    </td></tr>
<tr><td>36</td><td>ff</td><td>EOM    </td></tr>
<tr><td>37</td><td>ff</td><td>EOM    </td></tr>
<tr><td>38</td><td>ff</td><td>EOM    </td></tr>
<tr><td>39</td><td>ff</td><td>EOM    </td></tr>
<tr><td>3a</td><td>ff</td><td>EOM  can fit 20 letter id</td></tr>
<tr><td>3b</td><td>ff</td><td>EOM  (safety)</td></tr>
<tr><td>3c</td><td>n/a</td><td>passcode digit 1</td></tr>
<tr><td>3d</td><td>n/a</td><td>passcode digit 2</td></tr>
<tr><td>3e</td><td>n/a</td><td>passcode digit 3</td></tr>
<tr><td>3f</td><td>n/a</td><td>passcode digit 4</td></tr>
</table>
  </a>
  <p>
  Note that the entire range of 26-3B is available for your CW ID message.<br>
  <b>Do not forget to terminate the message with the FF (end-of-message)
  character.</b>
  <p>
  <a name="Morse Code Character Encoding">

  <table border=0>
  <caption><b>Morse Code Character Encoding</b></caption>
  <tr><td align=left>
  <table border>
    <tr>
      <th>Character</th>
      <th>Morse<br>Code</th>
      <th>Binary<br>Encoding</th>
      <th>Hex<br>Encoding</th>
    </tr>
    <tr><td>sk</td><td>...-.-</td><td>01101000</td><td>68</td></tr>
    <tr><td>ar</td><td>.-.-. </td><td>00101010</td><td>2a</td></tr>
    <tr><td>bt</td><td>-...- </td><td>00110001</td><td>31</td></tr>
    <tr><td>/ </td><td>-..-. </td><td>00101001</td><td>29</td></tr>
    <tr><td>0 </td><td>----- </td><td>00111111</td><td>3f</td></tr>
    <tr><td>1 </td><td>.---- </td><td>00111110</td><td>3e</td></tr>
    <tr><td>2 </td><td>..--- </td><td>00111100</td><td>3c</td></tr>
    <tr><td>3 </td><td>...-- </td><td>00111000</td><td>38</td></tr>
    <tr><td>4 </td><td>....- </td><td>00110000</td><td>30</td></tr>
    <tr><td>5 </td><td>..... </td><td>00100000</td><td>20</td></tr>
    <tr><td>6 </td><td>-.... </td><td>00100001</td><td>21</td></tr>
    <tr><td>7 </td><td>--... </td><td>00100011</td><td>23</td></tr>
    <tr><td>8 </td><td>---.. </td><td>00100111</td><td>27</td></tr>
    <tr><td>9 </td><td>----. </td><td>00101111</td><td>2f</td></tr>
    <tr><td>a </td><td>.-    </td><td>00000110</td><td>06</td></tr>
    <tr><td>b </td><td>-...  </td><td>00010001</td><td>11</td></tr>
    <tr><td>c </td><td>-.-.  </td><td>00010101</td><td>15</td></tr>
    <tr><td>d </td><td>-..   </td><td>00001001</td><td>09</td></tr>
    <tr><td>e </td><td>.     </td><td>00000010</td><td>02</td></tr>
    <tr><td>f </td><td>..-.  </td><td>00010100</td><td>14</td></tr>
    <tr><td>g </td><td>--.   </td><td>00001011</td><td>0b</td></tr>
  </table>
  </td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td>
  <table border>
    <tr>
      <th>Character</th>
      <th>Morse<br>Code</th>
      <th>Binary<br>Encoding</th>
      <th>Hex<br>Encoding</th>
    </tr>
    <tr><td>h </td><td>....  </td><td>00010000</td><td>10</td></tr>
    <tr><td>i </td><td>..    </td><td>00000100</td><td>04</td></tr>
    <tr><td>j </td><td>.---  </td><td>00011110</td><td>1e</td></tr>
    <tr><td>k </td><td>-.-   </td><td>00001101</td><td>0d</td></tr>
    <tr><td>l </td><td>.-..  </td><td>00010010</td><td>12</td></tr>
    <tr><td>m </td><td>--    </td><td>00000111</td><td>07</td></tr>
    <tr><td>n </td><td>-.    </td><td>00000101</td><td>05</td></tr>
    <tr><td>o </td><td>---   </td><td>00001111</td><td>0f</td></tr>
    <tr><td>p </td><td>.--.  </td><td>00010110</td><td>16</td></tr>
    <tr><td>q </td><td>--.-  </td><td>00011011</td><td>1b</td></tr>
    <tr><td>r </td><td>.-.   </td><td>00001010</td><td>0a</td></tr>
    <tr><td>s </td><td>...   </td><td>00001000</td><td>08</td></tr>
    <tr><td>t </td><td>-     </td><td>00000011</td><td>03</td></tr>
    <tr><td>u </td><td>..-   </td><td>00001100</td><td>0c</td></tr>
    <tr><td>v </td><td>...-  </td><td>00011000</td><td>18</td></tr>
    <tr><td>w </td><td>.--   </td><td>00001110</td><td>0e</td></tr>
    <tr><td>x </td><td>-..-  </td><td>00011001</td><td>19</td></tr>
    <tr><td>y </td><td>-.--  </td><td>00011101</td><td>1d</td></tr>
    <tr><td>z </td><td>--..  </td><td>00010011</td><td>13</td></tr>
    <tr><td>space</td><td>&nbsp;</td><td>00000000</td><td>00</td></tr>
    <tr><td>EOM</td><td>&nbsp;</td><td>11111111</td><td>ff</td></tr>
  </table>
  </table>
  </a>
</div>
<hr>
<a href="/nhrc-4/">NHRC-4 Repeater Controller Page</a><br>
<a href="/nhrc-4m2/">NHRC-4/M2 Repeater Controller Page</a><br>
<a href="/nhrc-4mvp/">NHRC-4/MVP Repeater Controller Page</a>
<hr>
<?php
$copydate="1997-2010";
$version="1.22";
include '../barefooter.inc';
?>
