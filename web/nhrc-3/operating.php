<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-3 Series Repeater Controllers Operation</title>
<meta name="description" content="Operating instructions for NHRC-3 repeater controllers, inexpensive repeater controllers with real stored speech">
<meta name="keywords" content="NHRC-3, repeater controller, NHRC, talking repeater controller">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-3 Series Repeater Controllers</b></FONT><br>
<font size=4><b>Operation Instructions</b></font><br>
<b>Firmware Version 5.0</b>
</div>
<hr>
These instructions will guide you in the operation of the
NHRC-3 Series repeater controllers.  For installion instructions, see
the appropriate installation manual.<p>
<div align=center>
  <font size=6><b><i>Contents</i></b></font>
</div>
<p>
<ol>
  <font size=5><b><li><a href="#Introduction">Introduction</a></b></font><br>
  <font size=5><b><li><a href="#Initializing">Initializing</a></b></font><br>
  <font size=5><b><li>Programming</b></font><br>
  <ol>
    <font size=4><b><li><a href="#Modes">Controller Modes</a></b></font>
    <font size=4><b><li><a href="#Programming">Programming the Controller</a></b></font>
    <blockquote>
      <a href="#Programming the Timers">Programming the Timers</a><br>
      <a href="#Programming the CW Messages">Programming the CW Messages</a><br>
      <a href="#Programming the Flag Bits">Programming the Flag Bits</a><br>
      <a href="#Recording the Voice Messages">Recording the Voice Messages</a><br>
    </blockquote>
    <font size=4><b><li><a href="#Enabling">Enabling/Disabling the Repeater</a></b></font>
  </ol>
  <p>
  <font size=5><b><li>Operating</b></font>
  <ol>
    <font size=4><b>
    <li><a href="#About the IDs">About the IDs</a>
    <li><a href="#Special ID Mode">About the Special ID Mode</a>
    <li><a href="#The Tail Message">The Tail Message</a>
    <li><a href="#Tail Message Courtesy Tone">
      Using the Tail Message as the Courtesy Tone</a>
    <li><a href="#Audio Delay">
      Using the NHRC-DAD Digital Audio Delay with the NHRC-3 series repeater controllers</a>
    </b></font>
  </ol>
    <p>
  <font size=5><b><li>
    <a href="#Programming Example">Programming Example</a></b></font>
</ol>
<font size=5><b>Index of Tables</b></font>
<blockquote>
  <ul>
    <li><a href="#Configuration Flag Bits">Configuration Flag Bits</a>
    <li><a href="#Message Commands">Message Commands</a>
    <li><a href="#Message Numbers">Message Numbers</a>
    <li><a href="#Morse Code Character Encoding">Morse Code Character Encoding</a> 
    <li><a href="#Programming Memory Map">Programming Memory Map</a>
    <li><a href="#Timer Address and Resolution">Timer Address and Resolution</a>
  </ul>
</blockquote>
<hr>
<ol>
  <a name="Introduction">
  <font size=5><b><li>Introduction</b></font></a><br>
  The controller's programming is protected from unauthorized access
  by a 4-digit secret passcode.  The controller is programmed by
  8-digit DTMF commands that all begin with the 4 digit passcode.
  Throughout this manual, commands will be shown as <i>pppp</i>NNNN,
  where <i>pppp</i> represents the passcode, and NNNN is the actual
  command to the controller.<p>
  In order to save space in the microprocessor memory, the NHRC-3
  repeater controllers represent all numbers in &quot;hexadecimal&quot;
  notation.  Hexadecimal, or hex for short, is a base-16 number format
  that allows a 8-bit number to be represented in two digits.  Hex
  numbers are 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, and F.
  Converting decimal (the normal base-10 numbers that 10 fingered
  humans prefer) to hex is simple: divide the decimal number by 16
  to get the 1st hex digit (10=A, 11=B, 12=C, 13=D, 14=E, 15=F), the
  remainder is the 2nd hex digit.  Many scientific calculators can
  convert between these two number systems, and the Windows 95
  calculator can, too, if the &quot;scientific&quot; view is selected.
  We provide a WWW page that can generate all the programming data
  for the NHRC-3 controllers quickly and easily, see
  <A href="nhrc3prog.php">
  http://www.nhrc.net/nhrc3/nhrc3prog.php</a>.<p>
      
  <a name="Initializing">
  <font size=5><b><li>Initializing the Controller</b></font>
  </a><br>
  The controller will need to be initialized to allow you to set your
  secret passcode.  Initializing the controller also resets all
  programmable settings to the factory defaults, including the CW ID
  message, and sets all the stored voice messages to blank.  It should
  not be nessecary to initialize the controller again, unless you want
  to change the passcode.  <B>The only way to change the passcode is
  to initialize the controller.</b><p>
  To initialize the controller, remove power and install the init
  jumper (JP1).  Apply power to the controller, and after a few seconds,
  remove the init jumper.  The controller is now in the initialize mode.
  If you &quot;kerchunk&quot; the controller now, it will send the
  default CW ID of &quot;DE NHRC/3&quot;.  Now transmit your 4-digit
  passcode.  The controller will respond by sending &quot;OK&quot; in
  CW <b>once</b>.  The controller will store the passcode and enter
  the disabled condition.<p>
  <font size=4><B><i>At this time, the controller will seem
  to be &quot;dead&quot;, it will not respond to keyups, kerchunks, etc.
  </b></i></font><p>
  In fact, the controller will now only respond to correctly
  formatted 8-digit command messages.  The controller initializes into
  the disabled condition specifically to allow programming and
  configuration of simplex repeaters; if it came up into a duplex
  operating condition, simplex repeaters <i>could not be programmed!</i><p>
  To select simplex mode (before enabling the repeater), send the
  following DTMF sequence:<br>
      <div align=center><tt>pppp0102</tt></div><br>
  <b>Do not enable a simplex repeater without first selecting simplex
  mode, or else you will not be able to program the controller until you
  initialize it again!</b><p>
  If the controller is connected to a full-duplex repeater or link
  radio, you may wish to enable it at this time.  To put the repeater
  into the enabled condition, send the following DTMF sequence: <br>
      <div align=center><tt>pppp0001</tt></div><br>
  This command will &quot;turn on &quot; the repeater.<p>
  <font size=5><b><li>Programming</b></font>
  <a name="Modes">
  <ol>
    <font size=4><b><li>Controller Modes</b></font><br>
    </a>
    The controller can operate in 3 different modes:
    <ul>
      <li>Repeater Controller Mode<br>
      The controller operates a full-duplex repeater, with a courtesy tone and 
      stored voice messages.<p>
      <li>Link Controller Mode<br>
      This is a variation of Repeater Controller Mode where the ISD2590 voice
      storage chip is deleted to lower the cost of the controller.  This mode
      is intended to control remote receivers that are essentially crossband
      repeaters.  Normally, when using link controller mode, the hang time is
      set to 0 seconds, and the controller is programmed to suppress DTMF
      muting, so the user's DTMF commands will appear on the input of a
      "downstream" controller.  The controller adds remote control, a timeout
      timer and CW ID capability to remote or link receivers.<p>
      <li>Simplex Repeater Controller Mode<br>
      This mode allows simplex (as opposed to duplex) radios to be used as 
      repeaters.  Up to 90 seconds of received audio is stored in the ISD2590
      voice storage chip, and is "parroted" back when the user unkeys.  The ID
      message is played in CW.
    </ul>
    <p>
    <a name="Programming">
    <font size=4><b><li>Programming the Controller</b></font></a><br>
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
    <tr><td>"OK"</td><td>Command Accepted</td></tr>
    <tr><td>"NG"</td><td>Command address or data is bad</td></tr>
    <tr>
      <td>courtesy beep<br>or nothing</td>
      <td>Command/password not accepted</td>
    </tr>
    </table></center><br>
    If you enter an incorrect sequence, you can unkey before all 8 digits are 
    entered, and the sequence will be ignored.  If you enter an incorrect
    address or incorrect data, just re-program the location affected with the
    correct data.
    <p>
    In order to save space, reduce keystrokes, and eliminate some software 
    complexity, all programming addresses and data are entered as hexadecimal 
    numbers.  Hexadecimal (or hex, for short) is a base-16 notation that is 
    particularly convenient for use in digital computer systems because each
    hex digit represents 4 bits of a value.  The controller uses pairs of hex
    digits to represent 8-bit values for the address and data of programming
    information.   Any decimal number from 0 to 255 may be represented by two
    hex digits.  Hex digits are 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E,
    F, where A through F represent values from 10 to 15.  To convert a decimal
    number from 0 to 255 to hex, divide the decimal number by 16.  The
    quotient (number of whole 16s) forms the left (high) digit, and the
    remainder forms the right (low) digit.  Thus, 60 decimal = 3 x 16 + 12 = 3C
    hex.<p>
    The DTMF keys 0-9 and A-D map directly to their corresponding digits.  Use 
    the <b>*</b> key for digit <b>E</b> and the <b>#</b> key for digit <b>F</b>.
    A 16-key DTMF generator is required to program the controller.
    <p>
    <ol>
      <a name="Programming the Timers">
      <b><li>Programming the Timers</b></a><br>
      The NHRC-3 series repeater controllers provide several timers which
      control the operation of your repeater.  The <i>Hang Timer</i>
      controls how long the repeater will continue to transmit after a
      received signal drops.  This is often called the repeater's
      &quot;tail&quot;.  The tail is useful to eliminate annoying squelch
      crashes on users' radios; as long as a reply is transmitted before the
      hang timer expires, the repeater will not drop, which would cause a
      squelch crash in the users' radios.<p>
      The <i>Timeout Timer</i> controls the maximum duration of the
      retransmission of a received signal.  It is more of a safety measure
      to protect the repeater from damage than a way to discourage long-winded
      users, even though it is often used that way.<p>
      The <i>ID Timer</i> sets the maximum duration between transmissions
      of the repeater's ID message(s).  Note that the NHRC-3 may transmit
      an ID message before the timer expires in order to avoid transmitting
      the ID message while a user is transmitting.<p>
      The timer values are stored as an 8-bit value, which allows a range of 0
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
            <th>Default Value<br>Seconds</th>
          </tr>
          <tr>
	    <td>Hang Timer</td>
	    <td align=center>02</td>
	    <td align=center>1/10</td>
	    <td align=center>25.5</td>
	    <td align=center>5.0</td>
	  </tr>
          <tr>
	    <td>Timeout Timer</td>
	    <td align=center>03</td>
	    <td align=center>1</td>
	    <td align=center>255</td>
	    <td align=center>30</td>
	  </tr>
          <tr>
	    <td>ID Timer</td>
	    <td align=center>04</td>
	    <td align=center>10</td>
	    <td align=center>2550</td>
	    <td align=center>540</td>
	  </tr>
        </table>
      </div>
      <p>
      Enter the 4 digit passcode, the timer address, and the timer value,
      scaled appropriately.  For example, to program the Hang Timer for 10
      seconds, enter <i>pppp0264</i>, where <i>pppp</i> is your secret
      passcode, 02 is the hang timer address, and 64 is the hexadecimal value
      for 100, which would be 10.0 seconds.
      <p>
      <a name="Programming the CW Messages">
      <b><li>Programming the CW Messages</b></a><br>
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
          <tr><td><i>pppp</i>0#09</td><td>0F</td><td>09</td><td>D</td></tr>
          <tr><td><i>pppp</i>1002</td><td>10</td><td>02</td><td>E</td></tr>
          <tr><td><i>pppp</i>1100</td><td>11</td><td>00</td><td>space</td></tr>
          <tr><td><i>pppp</i>1205</td><td>12</td><td>05</td><td>N</td></tr>
          <tr><td><i>pppp</i>133*</td><td>13</td><td>3E</td><td>1</td></tr>
          <tr><td><i>pppp</i>140D</td><td>14</td><td>0D</td><td>K</td></tr>
          <tr><td><i>pppp</i>1509</td><td>15</td><td>09</td><td>D</td></tr>
          <tr><td><i>pppp</i>160#</td><td>16</td><td>0F</td><td>O</td></tr>
          <tr><td><i>pppp</i>1729</td><td>17</td><td>29</td><td>/</td></tr>
          <tr><td><i>pppp</i>180A</td><td>18</td><td>0A</td><td>R</td></tr>
          <tr>
	    <td><i>pppp</i>19##</td>
	    <td>19</td><td>FF</td>
	    <td>End of message marker</td>
	  </tr>
        </table>
      </div><br>
      The CW ID can store a message of up to 40 characters.  Do not exceed 40
      characters.
      <p>
      <a name="Programming the Flag Bits">
      <b><li>Programming the Flag Bits</b></a><br>
      Controller features can be enabled of disabled with the use of the 
      <a href="#Configuration Flag Bits">Configuration Flag Bits</a>.
      These bits are encoded into a single byte, which is programmed into
      the controller at address 01.  Multiple flag bits can be selected by
      adding their hex weights.  For example, to set up a link controller
      with no ISD chip, no courtesy tone, and suppress the DTMF muting, you
      would add 01, 10, and 20 to produce hex 31, which you would then
      program into address 01 in the controller as <tt>pppp0131</tt>.
      <p>
      In addition to programming the flag bits as a group using address 01,
      the controller supports commands to set or clear these bits individually.
      Command 60 is used to clear (zero) a specified configuration bit, and
      command 61 is used to set (one) a specified configuration bit.  For
      example, to set (turn on) bit 4 (to suppress the courtesy tone), enter
      the following command: <tt>pppp6104</tt>.  To clear bit 4 and enable
      the courtesy tone, enter this command:  <tt>pppp6004</tt>.  Note that
      the bit <i>number</i>, not it's hex weight is used for commands 60 and
      61.
      <p>
      <div align=center>
        <a name="Configuration Flag Bits">
        <table border>
          <caption><b>Configuration Flag Bits</b></caption>
          <tr>
	    <th>Bit<br>Number</th>
	    <th>Bit Mask</th>
	    <th>Hex<br>Weight</th>
	    <th>Feature</th>
	  </tr>
          <tr>
	    <td align=center>0</td>
	    <td align=center>00000001</td>
	    <td align=center>01</td>
	    <td>ISD Absent</td>
	  </tr>
          <tr>
	    <td align=center>1</td>
	    <td align=center>00000010</td>
	    <td align=center>02</td>
	    <td>Simplex repeater mode</td>
	  </tr>
          <tr>
	    <td align=center>2</td>
	    <td align=center>00000100</td>
	    <td align=center>04</td>
	    <td>Audio Delay Installed</td>
	  </tr>
          <tr>
	    <td align=center>3</td>
	    <td align=center>00001000</td>
	    <td align=center>08</td>
	    <td>(reserved)</td>
	  </tr>
          <tr>
	    <td align=center>4</td>
	    <td align=center>00010000</td>
	    <td align=center>10</td>
	    <td>suppress courtesy tone</td>
	  </tr>
          <tr>
	    <td align=center>5</td>
	    <td align=center>00100000</td>
	    <td align=center>20</td>
	    <td>suppress DTMF muting</td>
	  </tr>
          <tr>
	    <td align=center>6</td>
	    <td align=center>01000000</td>
	    <td align=center>40</td>
	    <td>use tail message for courtesy tone</td>
	  </tr>
          <tr>
	    <td align=center>7</td>
	    <td align=center>10000000</td>
	    <td align=center>80</td>
	    <td>special ID mode</td>
	  </tr>
        </table>
        </a><p>
	<table border>
	  <caption><b>Example Configurations</b></caption>
	  <tr>
	    <th>Bits<br>Selected</th>
	    <th>Configuration<br>Bits</th>
	    <th>Hex Value of<br>Flag Bits</th>
	    <th>Features Selected</th>
	  </tr>
	  <tr>
	    <td align=center>(none)</td>
	    <td align=center>00000000</td>
	    <td align=center>00</td>
	    <td>Duplex Repeater Mode</td>
	  </tr>
	  <tr>
	    <td align=center>1</td>
	    <td align=center>00000010</td>
	    <td align=center>02</td>
	    <td>Simplex Repeater Mode</td>
	  </tr>
	  <tr>
	    <td align=center>2</td>
	    <td align=center>00000100</td>
	    <td align=center>04</td>
	    <td>Duplex Repeater Mode<br>
		audio delay installed</td>
	  </tr>
	  <tr>
	    <td align=center>0,4,5</td>
	    <td align=center>00110001</td>
	    <td align=center>31</td>
	    <td>Link Controller Mode:<br>
	                     no ISD chip<br>
	                     no courtesy tone<br>
	                     no DTMF muting</td>
	  </tr>
	  <tr>
	    <td align=center>6</td>
	    <td align=center>01000000</td>
	    <td align=center>40</td>
	    <td>Duplex Repeater Mode<br>
		tail message is courtesy tone</td>
	  </tr>
	  <tr>
	    <td align=center>7</td>
	    <td align=center>10000000</td>
	    <td align=center>80</td>
	    <td>Duplex Repeater Mode<br>
		special ID mode</td>
	  </tr>
	  <tr>
	    <td align=center>7,6</td>
	    <td align=center>11000000</td>
	    <td align=center>C0</td>
	    <td>Duplex Repeater Mode<br>
		tail message is courtesy tone<br>
		special ID mode</td>
	  </tr>
	  <tr>
	    <td align=center>7,6,2</td>
	    <td align=center>11000100</td>
	    <td align=center>C4</td>
	    <td>Duplex Repeater Mode<br>
		Audio Delay Installed<br>
		tail message is courtesy tone<br>
		special ID mode</td>
	  </tr>
        </table>
      </div>
	
      <p>
      <a name="Recording the Voice Messages">
      <b><li>Recording the Voice Messages</b></a><br>
      Stored voice messages can be played and recorded, and CW messages can be 
      played by using the <a href="#Message Commands">message commands</a>.
      Command 40 is used to play stored voice or CW messages, and command 41
      is used to record stored voice messages.<p>
      To record stored voice messages, use command <i>pppp</i>411<i>x</i>,
      where <i>x</i> is the number of the message you want to record, found
      in the <a href="#Message Numbers">message numbers</a> table.  Unkey
      after the command sequence, then key up, speak your message, and unkey.
      The controller will remove about 100 ms from the end of your message to
      remove any squelch crash that might have been recorded.<p>
      To play stored voice messages, use command <i>pppp</i>401<i>x</i>, where 
      <i>x</i> is the number of the stored voice message you want to play.
      To play CW messages, use command <i>pppp</i>400<i>x</i>, where <i>x</i>
      is the number of the CW message you want to play.<p>
      You may wish to have a family member or member of the opposite sex record
      your ID messages.  The recorded audio sounds natural enough that people
      have actually tried to call the amateur whose callsign is recorded in the
      controller after the ID message plays!<p>
    </ol>
    <a name="Enabling">
    <font size=4><b><li>Enabling/Disabling the Repeater</b></font></a><br>
    The repeater can be disabled or enabled by remote control by setting the 
    value in location 00.  Set this location to zero to disable, or non-zero to
    enable.  For instance, to disable the repeater, send command <i>pppp</i>0000.
    To enable the repeater, send command <i>pppp</i>0001.<p>
    </ol>
  <font size=5><b><li>Operating</b></font><br>
  <ol>
    <a name="About the IDs">
    <font size=4><b><li>About the IDs</b></font></a><br>
    When the repeater is first keyed  the controller will play the "initial
    ID". If the repeater is keyed again before the ID timer expires, the
    controller will play the "normal ID" when the ID timer expires.  If the
    repeater is not keyed again, and the ID timer expires, the controller
    will reset and play the "initial ID" the next time the repeater is keyed.
    If the repeater is keyed while the controller is playing a stored voice
    message ID, the controller will cancel the stored voice message ID and
    play the CW ID.<p>
    The idea behind this IDing logic is to prevent unnecessary IDing.  For 
    instance, if a repeater user keys the machine and announces "This is N1KDO,
    monitoring", the controller will play the initial ID, and no further IDing
    will occur unless the repeater is keyed again.  If users commence with a QSO,
    keying the repeater at least once more, the controller will play the normal
    ID and reset the ID timer when the ID timer expires.  If the repeater becomes
    idle for one ID timer period after the last ID, then the next time it is 
    keyed it will play the initial ID.  The intent is that the repeater users 
    only hear the initial ID the first time that they key the repeater.<p>
    <a name="Special ID Mode">
    <font size=4><b><li>About the Special ID Mode</b></font></a><br>
    The &quot;Special ID Mode&quot; operates differently in &quot;normal&quot;
    repeater mode than in simplex repeater mode.  In normal repeater mode,
    enabling special ID mode will cause a CW ID to be sent instead of the
    &quot;normal&quot; ID message.  In Simplex Repeater Mode, enabling
    special ID mode will cause the controller to play the &quot;initial&quot;
    voice ID (stored as voice message #0) insted of playing a CW ID.
    In simplex mode, the maximum repeated message duration is reduced by
    1/4 to accomodate this voice ID.  (About 67 seconds instead of 90).
    In summary, the special ID mode will cause a CW ID to play instead of
    the normal voice ID in normal repeater mode, or will allow a voice ID
    to be played instead of a CW ID in simplex repeater mode.<p>
    <a name="The Tail Message">
    <font size=4><b><li>The Tail Message</b></font></a><br>
    The controller supports a "Tail Message" that plays the <i>n</i>th time
    the hang timer expires.  The number of times the hang timer must expire
    before the tail message plays (<i>n</i>) is the "tail message counter"
    at address 05. The tail message counter can be set from 1 to 255.  The
    tail message is disabled if the tail message counter is set to 0.
    Program the tail message counter value into address 05.<p>
    For example, to have the tail message play after the 4th tail drop,
    program <i>pppp</i>0504.  <i>Try it.</i><p>
    <a name="Tail Message Courtesy Tone">
    <font size=4><b><li>Using the Tail Message as the Courtesy Tone</b>
    </font></a><br>
    The tail message can be used as the courtesy tone if bit 6 is set in
    the configuration flags.  In this case, you will likely want to set
    the tail message counter value to 0 to keep the message from playing
    twice occasionally. The message could store the sound of a bell,
    a dog's bark, or the repeater trustee saying "what?"!<p>
    <a name="Audio Delay">
    <font size=4><b><li>
    Using the NHRC-DAD Digital Audio Delay with the NHRC-3 series repeater
    controllers
    </b></font></a><br>
    The NHRC-3 series repeater controllers support the optional NHRC-DAD
    digital audio delay board.  The NHRC-DAD allows complete muting of
    received DTMF tones (no leading beep before muting), and suppression
    of squelch crashes when the received signal drops.  The NHRC-DAD has
    a 128 ms delay on all received audio.  NHRC-3 repeater controllers
    support the DAD with a software switch, settable by a configuration
    flag bit, and a dedicated connector on the controller for the DAD.
    If the DAD is not present, then a jumper must be installed between
    pins 2 and 3 of the DAD connector (see installation manual.)  If the
    DAD is present, then the appropriate configuration flag bit must be
    set (in the case of the NHRC-3 series controller, set bit 2, hex
    weight 04.)<p>
    </ol>
  <a name="Programming Example">
  <font size=5><b><li>Programming Example</b></font></a><br>
    Programming the NHRC-3 series repeater controllers can seem quite
    complicated at first.  This section of the manual is intended as a
    tutorial to help you learn how to program your controller.<p>
    Let's assume we want to program a NHRC-3 Series Repeater Controller
    with the following parameters:<p>
    <blockquote>
      CW ID: DE N1LTL/R FN42<br>
      Hang Time 7.5 seconds<br>
      Timeout timer 120 seconds<br>
      Play tail message every 6 tail drops.
    </blockquote><p>
    First, we will initialize the controller.  Install JP1 and apply power
    to the controller to initialize.  After a few seconds, remove JP1.
    Send DTMF <tt>2381</tt> to set access code to 2381.  The controller
    will send &quot;OK&quot; in CW to indicate the passcode was accepted.
    Now the controller is initialized, and disabled.<p>
    If we were programming a simplex repeater, we would now set the
    configuration flags for simplex mode, so we could turn the controller
    on and still be able to program it.  For duplex repeaters, this step
    should not be performed.  Send DTMF <tt>23810102</tt> to set the
    simplex repeater mode flag bit.<p>
    Now we will enable the controller.  Send DTMF <tt>23810001</tt>
    (passcode=2381, address=00, data=01).  The controller will send
    &quot;OK&quot; in CW to indicate the command was successful.<p> 
    We will now program the CW ID.  Looking at the &quot;Programming Memory
    Map&quot;, we can see that the first location for the CW ID is 0F.  The
    first letter of the ID is 'D', which we look up in the &quot;Morse Code
    Character Encoding&quot; table and discover that the encoding for 'D'
    is 09.  So location 0F gets programmed with 09.  Since the F digit is
    represented by the DTMF digit '#', the '#' is used to send the 'F'.<p>
    Send DTMF <tt>23810#09</tt> to program the letter 'D' as the first
    character of the CW ID.  The controller will send &quot;OK&quot; in CW
    if the command is accepted.  If you entered the command correctly, but
    you don't get the &quot;OK&quot;, your DTMF digits may not all be
    decoding.  See the Installation guide for your controller to readjust
    the audio level for the DTMF decoder.<p>
    The next character is the letter 'E', which is
    encoded as 02, and will be programmed into the next address, which is
    10.  Send DTMF <tt>23811002</tt>.<p>
    The next character is the space character, and it will be programmed
    into address 11.  Send DTMF 23810B00.  Here are the rest of the 
    sequences to program the rest of the ID message:<br>
    <blockquote>
      <tt>23811205</tt> (N in address 12)<br>
      <tt>2381133*</tt> (1 in address 13)<br>
      <tt>23811412</tt> (L in address 14)<br>
      <tt>23811503</tt> (T in address 15)<br>
      <tt>23811612</tt> (L in address 16)<br>
      <tt>23811729</tt> (/ in address 17)<br>
      <tt>2381180A</tt> (R in address 18)<br>
      <tt>23811900</tt> (space in address 19)<br>
      <tt>23811A14</tt> (F in address 1A)<br>
      <tt>23811B05</tt> (N in address 1B)<br>
      <tt>23811C30</tt> (4 in address 1C)<br>
      <tt>23811D3C</tt> (2 in address 1D)<br>
    </blockquote>
    After the last character of the CW ID is programmed, the End-of-Message
    character must be programmed.  In this case, the last character of the 
    ID message was programmed into address 1D, so the EOM character, which 
    is encoded as FF, goes into address 1E:<br>
    <tt>23811*##</tt> (EOM into address 1E.)<p>
    To program the hang timer, we must first determine the address of the
    hang timer by consulting the Programming Memory Map.  The Hang Timer
    preset is stored in location 02.  Next, we need to convert the 7.5
    seconds into tenths, which would be 75 tenths of a second.  Then the
    75 gets converted to hex:<br>
    <blockquote>
      75 / 16 = 4 with a remainder of 11, so 75 decimal equals 4B hex.
    </blockquote>
    Now program the hang timer preset by sending <tt>2381024B</tt>.<p>
    To program the timeout timer with 120 seconds, we get the address of
    the timeout timer preset, which is 03, and then convert 120 seconds
    to hex:<br>
    <blockquote>
      120 / 16 = 7 with a remainder of 8, so 120 decimal equals 78 hex.
    </blockquote>
    So we will program location 03 with 78: <tt>23810378</tt><p>
    To program the tail message counter, we determine the address of the 
    counter (05) and since 6 is less than 16, the hex conversion is easy:
    <blockquote>
      6 / 16 = 0 remainder 6, so 6 decimal equals 06 hex.
    </blockquote>
    We will program location 05 with 06: <tt>23810506</tt><p>
    If we were programming a simplex repeater, we would stop here.  Except
    in the case of the &quot;special ID mode&quot; no voice messages need
    to be stored for simplex repeater mode.<p>
    Now we can record the 4 voice messages.  The voice messages are 
    recorded by "programming" address 41 with the message number, then
    recording the message.  We will program the initial ID message
    (message number 10, see the "Message Numbers" table) first:<p>
    Send <tt>23814110</tt>, then key up again and clearly speak the message to
    be recorded "This is N1LTL repeater in Candia New Hampshire, an open
    repeater available to all licensed amateur radio operators."  Unkey
    after you are done speaking.<p>
    The "normal ID" (11), timeout message (12), and tail message(13) 
    can be recorded the same way:<br>
    <blockquote>
      Send <tt>23814111</tt>, speak "N1LTL repeater".<br>
      Send <tt>23814112</tt>, speak "A longwinded blatherskite has timed out the repeater."<br>
      Send <tt>23814113</tt>, speak "Free Beer Tonight at N1LTL's! (Swiller Lite, too)."
    </blockquote>
    Any message can be played back at any time by "programming" location
    40 with the message code you want to play.  To play the CW ID, send
    <tt>23814000</tt>.  To play the tail message, send <tt>23814013</tt>.<p>
    This tutorial did not discuss programming the Timeout timer, but the 
    concepts described here apply to that timer as well.<p>
  </ol>
<hr>
<div align=center>
  <font size=6><b>Tables</b></font>
  <a name="Message Commands">
  <table border>
    <caption><b>Message Commands</b></caption>
    <tr><th>Command</th><th>Description</th></tr>
    <tr><td>400x</td><td>0 &lt;= x &lt;= 3, play CW message x</td></tr>
    <tr><td>401x</td><td>0 &lt;= x &lt;= 3, play voice message x</td></tr>
    <tr><td>411x</td><td>0 &lt;= x &lt;= 3, record voice message x</td></tr>
  </table>
  </a>
  <p>
  <a name="Message Numbers">
  <table border>
    <caption><b>Message Numbers</b></caption>
    <tr><th>Message Number</th><th>Contents</th></tr>
    <tr><td>00</td><td>CW ID</td></tr>
    <tr><td>01</td><td>CW Timeout Message &quot;TO&quot;</td></tr>
    <tr><td>02</td><td>CW Confirmation Message &quot;OK&quot;</td></tr>
    <tr><td>03</td><td>CW Invalid Command Message &quot;NG&quot;</td></tr>
    <tr><td>10</td><td>Voice Initial ID Message</td></tr>
    <tr><td>11</td><td>Voice Normal ID Message</td></tr>
    <tr><td>12</td><td>Voice Timeout Message</td></tr>
    <tr><td>13</td><td>Voice Tail Message</td></tr>
  </table>
  </a>
  <p>
  <a name="Programming Memory Map">
  <table width=80%>
  <caption><b>Programming Memory Map</b></caption>
  <tr><td align=left>
  <table border>
    <tr><th>Address</th><th>Default<br>Data</th><th>Comment</th></tr>
    <tr><td>00</td><td>01</td><td>enable flag</td></tr>
    <tr><td>01</td><td>00</td><td>configuration flags</td></tr>
    <tr><td>02</td><td>32</td><td>hang timer, in tenths</td></tr>
    <tr><td>03</td><td>1e</td><td>time-out timer, in seconds</td></tr>
    <tr><td>04</td><td>36</td><td>ID timer, in 10 seconds</td></tr>
    <tr><td>05</td><td>00</td><td>tail message counter</td></tr>
    <tr><td>06</td><td>0f</td><td>'O' OK Message</td></tr>
    <tr><td>07</td><td>0d</td><td>'K'</td></tr>
    <tr><td>08</td><td>ff</td><td>EOM</td></tr>
    <tr><td>09</td><td>05</td><td>'N' NG Message</td></tr>
    <tr><td>0a</td><td>0b</td><td>'G'</td></tr>
    <tr><td>0b</td><td>ff</td><td>EOM</td></tr>
    <tr><td>0c</td><td>03</td><td>'T' TO Message</td></tr>
    <tr><td>0d</td><td>0f</td><td>'O'</td></tr>
    <tr><td>0e</td><td>ff</td><td>EOM</td></tr>
    <tr><td>0f</td><td>09</td><td>'D' CW ID starts here</td></tr>
    <tr><td>10</td><td>02</td><td>'E' </td></tr>
    <tr><td>11</td><td>00</td><td>space</td></tr>
    <tr><td>12</td><td>05</td><td>'N'</td></tr>
    <tr><td>13</td><td>3e</td><td>'1'</td></tr>
    <tr><td>14</td><td>0d</td><td>'K'</td></tr>
    <tr><td>15</td><td>09</td><td>'D'</td></tr>
    <tr><td>16</td><td>0f</td><td>'O'</td></tr>
    <tr><td>17</td><td>29</td><td>'/'</td></tr>
    <tr><td>18</td><td>0a</td><td>'R'</td></tr>
    <tr><td>19</td><td>ff</td><td>(end of message mark)</td></tr>
    <tr><td>1a</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>1b</td><td>ff</td><td>(empty)</td></tr>
  </table>
  </td><td align=right>
  <table border>
    <tr><th>Address</th><th>Default<br>Data</th><th>Comment</th></tr>
    <tr><td>1c</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>1d</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>1e</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>1f</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>20</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>21</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>22</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>23</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>24</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>25</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>26</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>27</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>28</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>29</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>2a</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>2b</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>2c</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>2d</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>2e</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>2f</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>30</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>31</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>32</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>33</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>34</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>35</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>36</td><td>ff</td><td>(empty)</td></tr>
    <tr><td>37</td><td>ff</td><td>(empty)</td></tr>
  </table>
  </table>
  </a>
  Note that the entire range of 0F-37 is available for your CW ID message.<br>
  <i>Do not forget to terminate the message with the FF (end-of-message)
  character.</i>
  <p>
  <a name="Morse Code Character Encoding">
  <table border=0 width=90%>
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
  </td><td align=right>
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
    <tr><td>space</td><td>   </td><td>00000000</td><td>00</td></tr>
    <tr><td>EOM</td><td></td><td>11111111</td><td>ff</td></tr>
  </table>
  </table>
  </a>
</div>
<hr>
<A HREF="/nhrc-3/">NHRC-3 Repeater Controller Home Page</a><br>
<A HREF="/nhrc-3m2/">NHRC-3/M2 Repeater Controller Home Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.21";
include '../barefooter.inc';
?>
