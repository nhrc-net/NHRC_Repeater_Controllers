<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>NHRC-3 Repeater Controller Operation</title>
<meta name="description" content="Operating instructions for the NHRC-3, an inexpensive repeater controller with real stored speech">
<meta name="keywords" content="NHRC-3, repeater controller, NHRC, talking repeater controller">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><b>NHRC-3 Repeater Controller</b></FONT><br>
<font size=4><b>Operation Instructions</b></font><br>
<b>Firmware Version 43</b>
</div>
<hr>
These instructions will guide you in the operation of the
NHRC-3 repeater controller.<p>
<div align=center>
  <font size=6><b><i>Contents</i></b></font>
</div>
<p>
<ol>
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
    <li><a href="#The Tail Message">The Tail Message</a>
    <li><a href="#Tail Message Courtesy Tone">
      Using the Tail Message as the Courtesy Tone</a>
    </b></font>
  </ol>
</ol>
<font size=5><b>Index of Tables</b></font>
<blockquote>
  <ul>
    <li><a href="#Configuration Flag Bits">Configuration Flag Bits</a>
    <li><a href="#Message Commands">Message Commands</a>
    <li><a href="#Morse Code Character Encoding">Morse Code Character Encoding</a> 
    <li><a href="#Programming Memory Map">Programming Memory Map</a>
    <li><a href="#Timer Address and Resolution">Timer Address and Resolution</a>
  </ul>
</blockquote>
<hr>
<ol>
  <a name="Initializing">
  <font size=5><b><li>Initializing the Controller</b></font>
  </a><br>
  To initially program your secret code into the controller, you
  must apply power to the controller with the pins on the init jumper,
  (JP1) shorted, putting the controller into the initialize mode.
  Remove the jumper a few seconds after power is applied.  All
  of the values stored in the EEPROM will be reset to defaults,
  and the controller will be ready to accept the 4-digit secret
  access code.  This will reset the CW ID to the default value &quot;DE
  NHRC/2&quot; as well.  When the controller is in the initialize
  mode it will play the default ID message every time the received
  carrier drops.  Key up and enter your 4-digit access code.  The
  controller should respond with &quot;OK&quot;.  After that, the
  controller will not transmit except to acknowlege commands with
  a &quot;OK&quot; or &quot;NG&quot; message until it is enabled.
  The controller will appear to be dead except for responding to
  properly formed commands.  You may want to enter a configuration
  flag value before you enable the controller with the 0001 command.
  The secret access code is stored in non-volatile memory in the 16C84
  microcontroller.  You will use this code as the prefix for all
  commands you send to the controller.<p>

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
          </tr>
          <tr><td>Hang Timer</td><td>02</td><td>1/10</td><td>25.5</td></tr>
          <tr><td>Timeout Timer</td><td>03</td><td>1</td><td>255</td></tr>
          <tr><td>ID Timer</td><td>04</td><td>10</td><td>2550</td></tr>
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
      summing their hex weights.  For instance, to set up a link controller
      with no ISD2590, no courtesy tone, and suppress the DTMF muting, you
      would add 01, 10, and 20 to produce hex 31, which you would then
      program into address 01 in the controller as <i>pppp</i>0131.
      <p>
      <a name="Configuration Flag Bits">
      <div align=center>
        <table border>
          <caption><b>Configuration Flag Bits</b></caption>
          <tr><th>Bit</th><th>Hex Weight</th><th>Feature</th></tr>
          <tr><td>0</td><td>01</td><td>ISD Absent</td></tr>
          <tr><td>1</td><td>02</td><td>Simplex repeater mode</td></tr>
          <tr><td>2</td><td>04</td><td>ISD2560 device</td></tr>
          <tr><td>3</td><td>08</td><td>ISD2590 device</td></tr>
          <tr><td>4</td><td>10</td><td>suppress courtesy tone</td></tr>
          <tr><td>5</td><td>20</td><td>suppress DTMF muting</td></tr>
          <tr>
	    <td>6</td>
	    <td>40</td>
	    <td>use tail message for courtesy tone</td>
	  </tr>
          <tr><td>7</td><td>80</td><td>n/a</td></tr>
        </table>
      </div></a>
      <p>
      <a name="Recording the Voice Messages">
      <b><li>Recording the Voice Messages</b></a><br>
      Stored voice messages can be played and recorded, and CW messages can be 
      played by using the <a href="#Message Commands">message commands</a>.
      Command 40 is used to play stored voice or CW messages, and command 41
      is used to record stored voice messages.<p>
      To record stored voice messages, use command <i>pppp</i>410<i>x</i>,
      where <i>x</i> is the number of the message you want to record, found
      in the <a href="#Message Contents">message contents</a> table.  Unkey
      after the command sequence, then key up, speak your message, and unkey.
      The controller will remove about 100 ms from the end of your message to
      remove any squelch crash that might have been recorded.<p>
      To play stored voice messages, use command <i>pppp</i>401<i>x</i>, where 
      <i>x</i> is the number of the stored voice message you want to play.
      To play CW messages, use command <i>pppp</i>401<i>x</i>, where <i>x</i>
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
    <a name="The Tail Message">
    <font size=4><b><li>The Tail Message</b></font></a><br>
    The controller supports a "Tail Message" that plays the <i>n</i>th time
    the hang timer expires.  The number of times the hang timer must expire
    before the tail message plays (<i>n</i>) is the "tail message counter"
    at address 05. The tail message counter can be set from 1 to 255.  The
    tail message is disabled if the tail message counter is set to 0.
    Program the tail message counter value into address 05.<p>
    <a name="Tail Message Courtesy Tone">
    <font size=4><b><li>Using the Tail Message as the Courtesy Tone</b>
    </font></a><br>
    The tail message can be used as the courtesy tone if bit 6 is set in
    the configuration flags.  In this case, you will likely want to set
    the tail message counter value to 0 to keep the message from playing
    twice occasionally. The message could store the sound of a bell,
    a dog's bark, or the repeater trustee saying "what?"!
    </ol>
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
    <tr><td>410x</td><td>0 &lt;= x &lt;= 3, record voice message x</td></tr>
  </table>
  </a>
  <p>
  <a name="Message Contents">
  <table border>
    <caption><b>Message Contents</b></caption>
    <tr><th>Message Number</th><th>Stored Voice</th><th>CW</th></tr>
    <tr><td>0</td><td>Initial ID</td><td>ID message</td></tr>
    <tr>
      <td>1</td>
      <td>Normal ID message</td>
      <td>timeout message (&quot;TO&quot;)</td>
    </tr>
    <tr>
      <td>2</td>
      <td>Time-out Message</td>
      <td>confirm message (&quot;OK&quot;)</td>
    </tr>
    <tr>
      <td>3</td>
      <td>Tail Message</td>
      <td>invalid message (&quot;NG&quot;)</td>
    </tr>
  </table>
  </a>
  <p>
  <a name="Programming Memory Map">
  <table border>
    <caption><b>Programming Memory Map</b></caption>
    <tr><th>Address</th><th>Default Data</th><th>Comment</th></tr>
    <tr><td>00</td><td>01</td><td>enable flag</td></tr>
    <tr><td>01</td><td>00</td><td>configuration flags</td></tr>
    <tr><td>02</td><td>32</td><td>hang timer preset, in tenths</td></tr>
    <tr><td>03</td><td>1e</td><td>time-out timer preset, in seconds</td></tr>
    <tr><td>04</td><td>36</td><td>id timer preset, in 10 seconds</td></tr>
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
    <tr><td>19</td><td>ff</td><td>EOM</td></tr>
    <tr><td>1a</td><td>00</td><td>can fit 6 letter ID....</td></tr>
    <tr><td>1b-37</td><td></td><td>not used</td></tr>
    <tr><td>38</td><td>n/a</td><td>isd message 0 length, in tenths</td></tr>
    <tr><td>39</td><td>n/a</td><td>isd message 1 length, in tenths</td></tr>
    <tr><td>3a</td><td>n/a</td><td>isd message 2 length, in tenths</td></tr>
    <tr><td>3b</td><td>n/a</td><td>isd message 3 length, in tenths</td></tr>
    <tr><td>3c</td><td>n/a</td><td>passcode digit 1</td></tr>
    <tr><td>3d</td><td>n/a</td><td>passcode digit 2</td></tr>
    <tr><td>3e</td><td>n/a</td><td>passcode digit 3</td></tr>
    <tr><td>3f</td><td>n/a</td><td>passcode digit 4</td></tr>
  </table>
  </a>
  <p>
  <a name="Morse Code Character Encoding">
  <table border>
    <caption><b>Morse Code Character Encoding</b></caption>
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
  </a>
</div>
<hr>
<A HREF="/nhrc-3/">NHRC-3 Repeater Controller Home Page</a><br>
<A HREF="/nhrc-3m2/">NHRC-3/M2 Repeater Controller Home Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.11";
include '../barefooter.inc';
?>
