<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<HTML>
<HEAD>
<title>A $60 Programmable Talking Repeater Controller</title>
<meta name="description" content="This is the original (unedited) text for the article that appeared in the February 1997 QST Magazine">
<meta name="keywords" content="repeater controller, stored speech, low cost, NHRC-2 documentation">
</HEAD>
<BODY bgcolor=white>
<P>
<CENTER><B><FONT SIZE=5>A $60 Programmable Talking Repeater Controller
</FONT></B></CENTER>
<CENTER><I><FONT SIZE=3>This inexpensive programmable controller
features stored voice, simplex or duplex repeater control, and
low power consumption.</FONT></I></CENTER>
<br>
<center><table border=0 width=100%><tr>
<td width=10%></td>
<td width=20%><FONT SIZE=2>
Jeff Otterson, N1KDO<BR>
3543 Tritt Springs Way<BR>
Marietta, GA  30062<BR>
otterson (at) nhrc.net
</font></td>
<td width=10%></td> 
<td width=20%><FONT SIZE=2>
Peter Gailunas, KA1OKQ<br>
444 Micol Road<BR>
Pembroke, NH  03275<BR>
gailunas (at) nhrc.net
</font>
</td>
<td width=10%></td>
<td width=20%><FONT SIZE=2>
Rich Cox, N1LTL<BR>
452 Brown Rd.<BR>
Candia, NH  03034<BR>
cox (at) nhrc.net
</font>
</td>
<td width=10%></td>
</tr></table></center>
<P>
Several recent repeater projects involving the construction
of portable repeaters for disaster site use and building a repeater
system with voted remote receivers indicated the need for a low-cost,
easy-to-build repeater controller.  The projects required a controller
that could be built for less than $60, with enough features to
be used as a duplex repeater controller, a link controller, or
a simplex repeater controller.  Other required features included
remote control and programming via DTMF, a hang timer, time-out
and ID timers, CW ID, and stored voice messages for all applications
except link control.  This article describes the product of our
work: the $60 Repeater Controller.<p>

<font size=4><b>Repeater Controller Mode</b></font><P>

The controller has an ID timer which can trigger 1 of 2 stored
voice IDs, or the CW ID.  The IDs are controlled by a user-programmable
ID timer, which can be set from 10 seconds to 2550 seconds.  Normally
this will be set to a value less than 600 seconds (the FCC-mandated
10 minute ID time.)  The controller will play the &quot;initial
ID&quot; if it has been quiet for one entire ID cycle (that is,
the time specified by the ID timer has elapsed since the repeater's
last transmission.)  The initial ID might contain a message such
as &quot;Welcome to N1KDO repeater.&quot;  The &quot;normal ID&quot;
will play after the ID timer expires.  The normal ID would typically
contain a short ID message like &quot;N1KDO repeater.&quot;  The
controller tries to be &quot;polite&quot; about when it IDs; if
a user unkeys and the ID timer has 60 seconds or less remaining
before playing an ID message, the controller will ID immediately
in an attempt to keep the ID from playing on top of another user.
 If a user keys up while a stored voice ID is playing, the controller
will cancel the stored voice ID and play the CW id. Also, if a
user keys the repeater, and the controller plays the initial ID,
the controller will not play the normal ID after the ID timer
expires unless the repeater is keyed again.  This prevents unnecessary
IDing by the repeater.<P>

The controller provides a hang timer and a courtesy tone.  The
hang timer keeps the repeater's transmitter on for a short time
after a user unkeys.  This reduces cycling of the repeater transmitter
and can eliminate some of the squelch crashes on the user's that
are caused by the repeater's transmitted signal dropping.  The
hang timer can be programmed for a delay from .1 second to 25.5
seconds.  The courtesy tone is a short beep that sounds after
a user's transmission has ended and the time-out timer has been
reset.  (Note that the time-out timer is reset before the courtesy
tone is heard.)<P>

The controller has a user-programmable time-out timer, which can
be set from 1 second to 255 seconds.  The time-out timer prevents
damage to the repeater's transmitter in the event of a user sitting
down on his microphone before starting a long ride, or the repeater's
receiver becoming unsquelched for some reason.  The time-out message
plays when the time-out timer expires and when the time-out condition
ends, so people listening to the repeater are aware of the time-out
condition as soon as it happens, and the offending operator knows
that he timed out the repeater when the time-out condition ends.<P>

A tail message can be selected to play after a programmed number
of expirations of the hang timer.  This message can be used to
advertise a net or club meeting, to warn of inclement weather,
etc.<p>

<font size=4><b>Link Controller Mode</b></font><P>

The controller can be used to control link radios for remote receivers
or split-site repeaters.  In link controller mode, the controller
does not use any stored voice messages; it only will ID in CW.
This allows the controller to be built without the ISD1420 and
associated support circuitry, lowering the cost for link support.
In most link controller modes, the hang time would be set to zero.<p>

<font size=4><b>Simplex Repeater Controller Mode</b></font><P>

The controller can also be used to run a &quot;simplex repeater&quot;.
A simplex repeater records up to twenty seconds of audio from
the receiver, then plays the recorded audio back out the transmitter.
In this mode, the controller will ID in CW when the ID timer
expires.<p>

<font size=4><b>Power Consumption</b></font><P>

The controller is ideal for remote solar and battery powered applications.
In standby mode, less then 10 mA of current is drawn.  Worst
case current consumption occurs when messages are recorded into
the ISD1420 chip, and that is under 30 mA.  Normal repeater operation
requires less than 20 mA.<p>

<font size=4><b>Circuit Description</b></font><P>

The controller consists of a Microchip PIC 16C84 microcontroller
IC, a Teltone M8870 DTMF decoder IC, a ISD 1420 voice record/playback
IC, and a CMOS operational amplifier IC.<P>

The heart of the controller is the Microchip PIC 16C84 microcontroller
(U1).  The 16C84 features 13 I/O leads, 1024 word of program storage,
36 bytes of RAM, and 64 bytes of EEPROM (non-volatile memory)
in a 18-pin DIP.  It is a RISC-like (reduced instruction set computer)
Harvard architecture computer (it has separate program and data
stores), and is extremely fast.  In the repeater controller application,
the PIC 16C84 executes over 800,000 instructions per second (.8
MIP!).  The 16C84 provides all the timers, CW generation, DTMF
validation, and other digital I/O requirements of the controller.
The 16C84 uses the 3.58 MHz clock generated by the DTMF decoder.<P>

DTMF tones are decoded by the Teltone M8870 (U3).  The M8870
decodes DTMF by filtering the received audio signal into its high
and low components, and counting the frequency of each component.
 Because it uses this approach, it is much less likely to detect
voice as a DTMF digit and generate a false decode.  When a valid
digit is decoded, the M8870 raises the StD (delayed steering)
lead, which informs the 16C84 microcontroller that a valid touch
tone has been received.<P>

Speech messages are stored in the ISD 1420 (U2).  This device
stores speech by recording analog levels into flash EEPROM cells,
rather than storing digital values.  The ISD1420 can address up
to 160 different messages of 125 ms each, but in the controller
application, we chose to implement 4 messages of approximately
5 seconds each.  The device's address lines are configured to
allow messages to start at the 0-, 5-, 10-, and 15-second addresses.
Device address, playback and record are controlled by the PIC
16C84.<P>

Audio processing uses an optional de-emphasis circuit that provides
a -6dB/octave slope to de-emphasize receiver audio, which allows
the controller to be fed with the receiver's discriminator output,
rather than an already deemphasized source of audio, such as a
line or speaker output.  A FET(Q1) mutes the audio when the receiver
is squelched or DTMF tones are present.  A simple audio mixer
combines receiver audio, ISD 1420 audio, and beep tone audio into
the transmitter input.<p>

<font size=4><b>Software Description</b></font><P>

The controller's PIC 16C84 microcontroller chip would do absolutely
nothing without software.  The controller's software handles all
DTMF validation, beep generation, timing, CW sending and control
required by the ISD1420 and the repeater itself.  The source code
is nearly 1500 lines of assembler, and uses 85% of the available
program storage on the PIC.  The program uses 32 of 36 bytes of
RAM on the PIC, and more than half of the EEPROM.  The operation
of the software can be loosely described as a polled loop, with
interrupt-based timing.  The source code is heavily commented
for easy modification within the remaining space on the PIC.<P>

The controller's software was assembled with Microchip's MPASM.
The source and object code are available for unlimited non-commercial
use by amateurs worldwide, and can be downloaded from the Internet.
Development tools for the PIC microcontroller (MPASM and MPSIM)
are also available on the Internet.  Several sources exist on
the Internet that describe the construction of a programmer for
the PIC 16C84.  (See &quot;Sources&quot;, below.)<p>

<font size=4><b>Radio Interfacing</b></font><P>

The controller uses a female DB9 connector for all signals.  It
requires receiver audio and a signal present indication (CAS)
from the receiver, Transmit audio and PTT for the transmitter,
and 13.8 volts DC for power.  Be very careful when wiring DC power
to the controller, reverse polarity will destroy the ICs.<p>

<TABLE BORDER>
<caption align=bottom><b>Table 1:<br>DB9 Connector Pinout</b></caption>
<TR><TH>Pin</th><TH>Signal</th></TR>
<TR><TD>1</td><TD>Ground</td></TR>
<TR><TD>2</td><TD>13.8 Volts</td></TR>
<TR><TD>3</td><TD>PTT (active low)</td></TR>
<TR><TD>4</td><TD>TX Audio</td></TR>
<TR><TD>5</td><TD>RX Audio</td></TR>
<TR><TD>6</td><TD>CAS +</td></TR>
<TR><TD>7</td><TD>CAS -</td></TR>
<TR><TD>8</td><TD>Ground/TX Audio Return</td></TR>
<TR><TD>9</td><TD>Ground/RX Audio Return</td></TR>
</TABLE><P>

Receiver audio can typically be taken from the high side of the
squelch control.  This audio must be de-emphasized with the controller's
optional de-emphasis circuit, which provides a -6dB/octave slope.
Optionally, audio can be taken from later in the receiver's audio
chain, where it is already de-emphasized.  Care must be taken
that this source of audio is not subject to adjustment by the
radio's volume control.  If the receiver audio has not been properly
de-emphasized, either in the receiver itself, or on the controller
board, the repeater will have a very &quot;tinny&quot;, unnatural
sound to it.<P>

To de-emphasize the receiver audio on the controller board, install
a .0068 F capacitor in position C3, change R3 to 51K, and change
R4 to 510K.  These values should be considered a good starting
point;  you may want to experiment with the values of C3 and R4
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
or COR, etc. configurations.<P>

Transmitter audio can be fed directly into the microphone input
of the transmitter.  VR2 is the master level control, used to
set the audio level into the transmitter.  Transmit audio should
be adjusted with a service monitor or deviation meter.<P>

Transmitter keying is provided by a power MOSFET (Q6) configured
in an open-drain circuit.  This can be used to key many transmitters
directly.  The MOSFET essentially provides a closure to ground
for PTT.  For other transmitters, the MOSFET can drive a small
relay to key the radio.  Although this MOSFET can handle several
amps, we recommend that no more than 100 mA of current be drawn
through it, since the trace on the PC board is rather thin.<p>

<font size=4><b>Adjusting the Audio Levels</b></font><P>

Preset all potentiometers to midrange. Connect an oscilloscope
probe or DVM to pin 15 of U3.  (Use the power supply ground for
the 'scope's ground or the DVM's return.)  Key a radio on the
input frequency, send some touch-tones,  and adjust VR1 (the main 
receive level) until DTMF decoding is reliably indicated by a 5 
volt level on U3 pin 15.  Disconnect the oscilloscope or DVM.  
Adjust VR2 (the master level) to adjust transmitter deviation, 
ideally measured with a deviation meter or service monitor.  
Adjust VR6 (the beep level) to set the courtesy tone and CW tone 
level.<P>

The easiest way to adjust the ISD1420 input and output levels
is to select the simplex repeater mode and record messages until
the audio sounds right.  VR3 adjusts the record audio level into
the ISD1420.  Adjust this control for the best sounding record
audio.  VR5 sets  the ISD1420 playback level.  Adjust this control
for best acceptable transmitter deviation.  VR4 is used to set
the receiver audio level, and may not need to be adjusted from
midpoint.<p>

<font size=4><b>Initializing the Controller</b></font><P>

To initially program your secret code into the controller, you
must apply power to the controller with the pins on the init jumper,
(SW1) shorted, putting the controller into the initialize mode.
Remove the jumper a few seconds after power is applied.  All
of the values stored in the EEPROM will be reset to defaults,
and the controller will be ready to accept the 4-digit secret
access code.  This will reset the CW ID to the default value &quot;DE
NHRC/2&quot; as well.  When the controller is in the initialize
mode the courtesy tone is 1/2 second long, instead of the usual
1/5 second.  Key up and enter your 4-digit access code.  The controller
should respond with the normal (1/5 second) courtesy beep.  The
secret access code is stored in non-volatile memory in the 16C84
microcontroller.  You will use this code as the prefix for all
commands you send to the controller.<p>

<font size=4><b>About Hexadecimal</b></font><P>

To save space and reduce software complexity, the controller is
programmed using hexadecimal, or hex for short.  Hex is a base-16
notation that is particularly convenient for use in digital computer
systems because each hex digit represents 4 bits of a value. 
The controller uses pairs of hex digits to represent 8-bit values
for the address and data of programming information.  Any decimal
number from 0 to 255 may be represented by two hex digits.  Hex
digits are 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F, where
A through F represent values from 10 to 15.  To convert a decimal
number from 0 to 255 to hex, divide the decimal number by 16.
The quotient (number of whole 16s) forms the left (high) digit,
and the remainder forms the right (low) digit.  Thus, 60 decimal
=  3 x 16 + 12 = 3C hex.<p>

<font size=4><b>Programming the Controller</b></font><P>

All programming data is entered into the controller as DTMF strings
of 4 hex digits immediately after the access code is entered.
 The * tone is translated to hex &quot;E&quot;, and the # code
is translated to hex &quot;F&quot;.  The first two hex digits
represent a memory location, and the second two digits represent
a value to store in that location.  This probably sounds more
complicated than it is.  For example, to program the hang timer
(address 04) with 5 seconds (50 decimal = 32 hex), assuming your
secret code is 1234, you would key your radio, enter 1, 2, 3,
4, 0, 4, 3, 2, then unkey.  If the OK message had been programmed,
the controller will respond with the CW message &quot;OK&quot;.
The if the NG message has been programmed, and the address entered
was not valid, the controller will respond with the CW message
&quot;NG&quot;.  The range of valid addresses is 00-3F.  The controller
uses 40 and 41 for message play and record commands as described
in Table 2:<p>

<TABLE BORDER>
<caption align=bottom><b>Table 2:  Message Play/Record Commands</b></caption>
<TR><th>Command</Th><Th>Description</Th></TR>
<TR><td>400x</TD><td>0 &lt;= x &lt;= 3, play CW message x</TD></TR>
<TR><td>401x</TD><td>0 &lt;= x &lt;= 3, play voice message x</TD></TR>
<TR><td>410x</TD><td>0 &lt;= x &lt;= 3, record voice message x</TD></TR>
</TABLE><P>

Timers in the controller are of three different resolutions, depending
on the application.  All timers are stored in 8-bit values, and
can hold any value from 0 to 255.  The hang timer is in one-tenth
second increments.  To program a hang time of 5 seconds, the value
50 decimal must be stored in the hang timer preset location. 
To store the value, it must first be converted to hexadecimal.
50 decimal translates to 32 hex.  Therefore, the command sent
to then controller would be &quot;cccc0232&quot; to set the hang
time to 5.0 seconds, where &quot;cccc&quot; is your secret access
code.  The hang time can be adjusted from 0 to 25.5 seconds.<P>

The time-out timer is in whole second increments.  60 seconds
would be stored as 60 decimal (3c hex).  The time-out timer can
be adjusted from 0 to 255 seconds.<P>

The ID timer is in ten-second increments.  To store 570 seconds
(9.5 minutes) you would store 57 decimal (39 hex).  The ID timer
can be set from 0 to 2550 seconds!<p>

<font size=4><b>Messages</b></font><P>

Stored voice messages up to 4.8 seconds each can be recorded.
The controller will not play the last 100 ms of stored messages
to avoid playing squelch crashes that may have been recorded at
the end of the messages.  CW messages play at 12 WPM.  There are
4 messages for voice, and 4 messages for CW, as shown in Table
3:<p>

<TABLE BORDER>
<caption align=bottom><B>Table 3: Message Numbers</b></caption>
<TR><Th>Message<BR>Number</Th><Th>Stored Voice</Th><Th>CW</Th></TR>
<TR><TD>0</TD><TD>Initial ID</TD><TD>ID message</TD></TR>
<tr><td>1</td><td>Normal ID message</td><td>timeout message (&quot;TO&quot;)</td></tr>
<tr><td>2</td><td>Time-out Message</td><td>confirm message (&quot;OK&quot;)</td></tr>
<tr><td>3</td><td>Tail Message</td><td>invalid message (&quot;NG&quot;)</td></tr>
</TABLE><P>

<font size=4><b>Recording the Voice Messages</b></font><P>

To record the voice message, enter your secret code, then 410x,
where X is the number of the voice message you wish to program.
Unkey after the command sequence, then key up, speak your message,
and unkey.  The controller will remove about 100 ms from the end
of your message to remove any squelch crash that might have been
recorded.  You can play your message by using command 401x, where
x is the number of the voice message you want to play.  The tail
message is recorded like any other message,  but it will not play
until you program the tail message counter (address 05) to a non-zero
value N.  Programming the tail message counter to 0 will disable
the tail message.<P>

You may wish to have a family member or member of the opposite
sex record your ID messages.  The recorded audio sounds natural
enough that people have actually tried to call the amateur who's
callsign is recorded in the controller after the ID message plays!<p>

<font size=4><b>Programming CW Messages</b></font><P>

CW messages are stored in the controller's non-volatile memory,
and programmed in the same manner as the timers.  Each message
has a fixed base address, and maximum number of characters.  Refer
to Table 4, the programming memory map to determine where each
symbol in a message belongs.  CW symbols are stored in a binary-encoded
form, from right to left, with a 1 representing a dah, and a 0
representing a dit.  The leftmost 1 indicates the width of the
symbol.  Table 5 has been provided as a quick lookup of the CW
symbols to their encoded hexadecimal form.  To program the first
letter of the ID message (&quot;D&quot;), you would enter your
secret code, then the address (0E), then the encoded form of the
letter D (09): &quot;cccc0909&quot; (where cccc represents your
secret access code).  To program the second letter (&quot;E&quot;)
enter &quot;cccc0F02&quot;.  The ID message can be up to 39 characters
long, and must end with the End-Of-Message character, hex FF.<p>

<font size=4><b>About the IDs</b></font><P>

The controller will normally play the initial ID when the repeater
is first accessed after one ID period of inactivity.  If no further
activity occurs after the initial ID plays, then no ID will be
sent after the ID timer expires.  If any activity occurs after
the initial ID is sent, the first occurrence will set the ID timer.
 If a user unkeys within 60 seconds of the expiration of the ID
timer, the repeater will play the normal ID message immediately,
hopefully to prevent it from playing during another user's transmission.
 If a user keys up the repeater when a voice ID is playing, the
controller will cancel the playing voice ID and start to play
the CW ID.  The CW ID cannot be canceled.<p>

<font size=4><b>Selecting Controller Modes</b></font><P>

The controller mode is selected by programming values into the
configuration flags (address 01).  Multiple modes can be simultaneously
selected by adding their values together to set multiple bits
in the configuration byte.  To select &quot;normal&quot; (full-duplex)
controller mode, program the configuration flags with 00.  To
select link controller mode (no ISD1420, only CW messages), program
the configuration flags byte with 01, and optionally program the
hang timer (address 02) to 00.  When in link controller mode,
you may wish to have the controller pass DTMF tones to a &quot;downstream&quot;
controller.  Program the configuration flags byte with 21 in this
case.  To select the simplex repeater controller mode, program
the configuration flags byte with 02.  In normal or link control
mode, the courtesy tone can be suppressed by adding hex 10 to
the configuration flags.  For instance, to use link controller
mode with no courtesy tone, program the configuration flags with
11.  Note that in either normal or link control mode, setting
the hang time to 0 will also suppress the courtesy tone.  The
tail message stored in position 3 can be used instead of the courtesy
beep by adding hex 40 to the controller mode byte.  See Table
6 for a description of the various bits in the configuration flags
byte.<p>

<TABLE BORDER>
<caption><b>Table 6: Configuration Flag Bits</b></caption>
<TR><TH>Bit</TH><TH>Hex<BR>Weight</TH><TH>Feature</TH></TR>
<TR><TD>0 (LSB)</TD><TD>01</TD><TD>ISD Absent</TD></TR>
<TR><TD>1</TD><TD>02</TD><TD>Simplex repeater mode</TD></TR>
<TR><TD>2</TD><TD>04</TD><TD>N/A</TD></TR>
<TR><TD>3</TD><TD>08</TD><TD>N/A</TD></TR>
<TR><TD>4</TD><TD>10</TD><TD>suppress courtesy tone</TD></TR>
<TR><TD>5</TD><TD>20</TD><TD>suppress DTMF muting</TD></TR>
<TR><TD>6</TD><TD>40</TD><TD>use Tail Message for courtesy tone</TD></TR>
<TR><TD>7 (MSB</TD><TD>80</TD><TD>N/A</TD></TR>
</TABLE><P>

<font size=4><b>RFI</b></font><P>

Radio Frequency Interference (RFI) is everywhere, but is particularly
troublesome at a repeater site.  This controller, like any microprocessor-based
device, can generate a significant amount of RFI.  It is important
to install the controller into a grounded RF-tight box.<p>

<font size=4><b>Conclusion</b></font><P>

We found that the low cost, variety of features, and low power
consumption of this controller made it a winner for several of
our repeater projects.  We wanted to share our results with the
amateur community at large, and hope that many of you will find
this controller useful and functional in your own repeater projects.<p>

<TABLE BORDER>
<caption align=bottom><b>Table 4: Programming Memory Map</b></caption>
<TR><Th>Address</Th><Th>Default<BR>Data</Th><Th>Comment</Th></TR>
<TR><TD>00</TD><TD>01</TD><TD>enable flag</TD></TR>
<TR><TD>01</TD><TD>00</TD><TD>configuration flags</TD></TR>
<TR><TD>02</TD><TD>32</TD><TD>hang timer preset, in tenths</TD></TR>
<TR><TD>03</TD><TD>1e</TD><TD>time-out timer preset, in seconds</TD></TR>
<TR><TD>04</TD><TD>36</TD><TD>id timer preset, in 10 seconds</TD></TR>
<TR><TD>05</TD><TD>00</TD><TD>tail message counter</TD></TR>
<TR><TD>06</TD><TD>0f</TD><TD>'O'    OK Message</TD></TR>
<TR><TD>07</TD><TD>0d</TD><TD>'K' </TD></TR>
<TR><TD>08</TD><TD>ff</TD><TD>EOM </TD></TR>
<TR><TD>09</TD><TD>05</TD><TD>'N'    NG Message</TD></TR>
<TR><TD>0a</TD><TD>0b</TD><TD>'G' </TD></TR>
<TR><TD>0b</TD><TD>ff</TD><TD>EOM </TD></TR>
<TR><TD>0c</TD><TD>03</TD><TD>'T'    TO Message</TD></TR>
<TR><TD>0d</TD><TD>0f</TD><TD>'O' </TD></TR>
<TR><TD>0e</TD><TD>ff</TD><TD>EOM </TD></TR>
<TR><TD>0f</TD><TD>09</TD><TD>'D'    CW ID starts here</TD></TR>
<TR><TD>10</TD><TD>02</TD><TD>'E'</TD></TR>
<TR><TD>11</TD><TD>00</TD><TD>space</TD></TR>
<TR><TD>12</TD><TD>05</TD><TD>'N'</TD></TR>
<TR><TD>13</TD><TD>10</TD><TD>'H'</TD></TR>
<TR><TD>14</TD><TD>0a</TD><TD>'R'</TD></TR>
<TR><TD>15</TD><TD>15</TD><TD>'C'</TD></TR>
<TR><TD>16</TD><TD>29</TD><TD>'/'</TD></TR>
<TR><TD>17</TD><TD>3c</TD><TD>'2'</TD></TR>
<TR><TD>18</TD><TD>ff</TD><TD>EOM</TD></TR>
<TR><TD>19</TD><TD>ff</TD><TD>EOM</TD></TR>
<TR><TD>1a</TD><TD>ff</TD><TD>EOM</TD></TR>
<TR><TD>1b-37</TD><TD></TD><TD>not used, room for long CW ID</TD></TR>
<TR><TD>38</TD><TD>n/a</TD><TD>isd message 0 length, in tenths</TD></TR>
<TR><TD>39</TD><TD>n/a</TD><TD>isd message 1 length, in tenths</TD></TR>
<TR><TD>3a</TD><TD>n/a</TD><TD>isd message 2 length, in tenths</TD></TR>
<TR><TD>3b</TD><TD>n/a</TD><TD>isd message 3 length, in tenths</TD></TR>
<TR><TD>3c</TD><TD>n/a</TD><TD>passcode digit 1</TD></TR>
<TR><TD>3d</TD><TD>n/a</TD><TD>passcode digit 2</TD></TR>
<TR><TD>3e</TD><TD>n/a</TD><TD>passcode digit 3</TD></TR>
<TR><TD>3f</TD><TD>n/a</TD><TD>passcode digit 4</TD></TR>
</TABLE><P>

<font size=4><b>Morse Code Encoding.</b></font><P>

Morse code characters are encoded in a single byte, bit-wise,
LSB to MSB.  A 0 represents a dit and a 1 represents a dah.  The
byte is shifted out to the right, until only a 1 remains.  Characters
with more than 7 elements (like error) cannot be sent.  Special
cases are made for space (hex 00) and end-of-message (hex ff).<p>

<TABLE BORDER>
<caption><B>Table 5: Morse Code Character Encoding</B></caption>
<TR><Th>Character</Th><Th>Morse<BR>Code</Th><Th>Binary<BR>Encoding</Th><Th>Hex<BR>Encoding</Th></TR>
<TR><TD>SK</TD><TD>...-.-</TD><TD>01101000</TD><TD>68</TD></TR>
<TR><TD>AR</TD><TD>.-.-.</TD><TD>00101010</TD><TD>2a</TD></TR>
<TR><TD>BT</TD><TD>-...-</TD><TD>00110001</TD><TD>31</TD></TR>
<TR><TD>/</TD><TD>-..-.</TD><TD>00101001</TD><TD>29</TD></TR>
<TR><TD>0</TD><TD>-----</TD><TD>00111111</TD><TD>3f</TD></TR>
<TR><TD>1</TD><TD>.----</TD><TD>00111110</TD><TD>3e</TD></TR>
<TR><TD>2</TD><TD>..---</TD><TD>00111100</TD><TD>3c</TD></TR>
<TR><TD>3</TD><TD>...--</TD><TD>00111000</TD><TD>38</TD></TR>
<TR><TD>4</TD><TD>....-</TD><TD>00110000</TD><TD>30</TD></TR>
<TR><TD>5</TD><TD>.....</TD><TD>00100000</TD><TD>20</TD></TR>
<TR><TD>6</TD><TD>-....</TD><TD>00100001</TD><TD>21</TD></TR>
<TR><TD>7</TD><TD>--...</TD><TD>00100011</TD><TD>23</TD></TR>
<TR><TD>8</TD><TD>---..</TD><TD>00100111</TD><TD>27</TD></TR>
<TR><TD>9</TD><TD>----.</TD><TD>00101111</TD><TD>2f</TD></TR>
<TR><TD>a</TD><TD>.-</TD><TD>00000110</TD><TD>06</TD></TR>
<TR><TD>b</TD><TD>-...</TD><TD>00010001</TD><TD>11</TD></TR>
<TR><TD>c</TD><TD>-.-.</TD><TD>00010101</TD><TD>15</TD></TR>
<TR><TD>d</TD><TD>-..</TD><TD>00001001</TD><TD>09</TD></TR>
<TR><TD>e</TD><TD>.</TD><TD>00000010</TD><TD>02</TD></TR>
<TR><TD>f</TD><TD>..-.</TD><TD>00010100</TD><TD>14</TD></TR>
<TR><TD>g</TD><TD>--.</TD><TD>00001011</TD><TD>0b</TD></TR>
<TR><TD>h</TD><TD>....</TD><TD>00010000</TD><TD>10</TD></TR>
<TR><TD>i</TD><TD>..</TD><TD>00000100</TD><TD>04</TD></TR>
<TR><TD>j</TD><TD>.---</TD><TD>00011110</TD><TD>1e</TD></TR>
<TR><TD>k</TD><TD>-.-</TD><TD>00001101</TD><TD>0d</TD></TR>
<TR><TD>l</TD><TD>.-..</TD><TD>00010010</TD><TD>12</TD></TR>
<TR><TD>m</TD><TD>--</TD><TD>00000111</TD><TD>07</TD></TR>
<TR><TD>n</TD><TD>-.</TD><TD>00000101</TD><TD>05</TD></TR>
<TR><TD>o</TD><TD>---</TD><TD>00001111</TD><TD>0f</TD></TR>
<TR><TD>p</TD><TD>.--.</TD><TD>00010110</TD><TD>16</TD></TR>
<TR><TD>q</TD><TD>--.-</TD><TD>00011011</TD><TD>1b</TD></TR>
<TR><TD>r</TD><TD>.-.</TD><TD>00001010</TD><TD>0a</TD></TR>
<TR><TD>s</TD><TD>...</TD><TD>00001000</TD><TD>08</TD></TR>
<TR><TD>t</TD><TD>-</TD><TD>00000011</TD><TD>03</TD></TR>
<TR><TD>u</TD><TD>..-</TD><TD>00001100</TD><TD>0c</TD></TR>
<TR><TD>v</TD><TD>...-</TD><TD>00011000</TD><TD>18</TD></TR>
<TR><TD>w</TD><TD>.--</TD><TD>00001110</TD><TD>0e</TD></TR>
<TR><TD>x</TD><TD>-..-</TD><TD>00011001</TD><TD>19</TD></TR>
<TR><TD>y</TD><TD>-.--</TD><TD>00011101</TD><TD>1d</TD></TR>
<TR><TD>z</TD><TD>--..</TD><TD>00010011</TD><TD>13</TD></TR>
<TR><TD>space</TD><TD></TD><TD>00000000</TD><TD>00</TD></TR>
<TR><TD>EOM</TD><TD></TD><TD>11111111</TD><TD>ff</TD></TR>
</TABLE><P>

<font size=4><b>References</b></font><p>
<UL>
<LI>PIC 16/17 Microcontroller Data Book.  Microchip
Corporation, Chandler AZ.  (<I><a href="http://www.microchip.com">
http://www.microchip.com</a></I>)
<LI>ISD Data Book, Voice Record and Playback ICs,
1995.  Information Storage Devices, San Jose, CA. (<I>http://www.isd.com</I>)
<LI>Telecom Design Solutions, Component Data Book.
 Teltone Corporation, Bothell, WA (or see <I>
<a href="http://products.zarlink.com/product_profiles/MT8870D.htm">
http://products.zarlink.com/product_profiles/MT8870D.htm
</a></I>)
<LI>Application Note MSAN-108, &quot;Applications
of the MT8870 Integrated DTMF Receiver&quot;.  Mitel Semiconductor,
Kanata, Ontario, Canada (<I>
<a href="http://www.semicon.mitel.com">http://www.semicon.mitel.com</a></I>)
<LI>Linear Circuits Data Book 1992, Volume 1, Operational
Amplifiers. Texas Instruments,  Dallas, TX. (or see <I>
<a href="http://www.st.com">http://www.st.com</a></I>)
</UL><P>

<FONT SIZE=4><b>Sources</b></FONT>
<UL>
<LI>The source code for the repeater controller is
available on the Internet from the following location:  <I>
<a href="http://www.nhrc.net/nhrc-2/">
http://www.nhrc.net/nhrc-2/</a>
</I>.
The source code is also available from N1KDO, send a blank diskette
and a stamped, self-addressed diskette mailer.
<LI>A partial parts kit, containing a programmed
PIC16C84, M8870, the PC board, and complete documentation (the parts that are
not available from Digikey) is available for $30, plus shipping, from NHRC.
<LI>PIC 16C84 device programmer information is available
on the Internet at the following locations: <ul>
<li><I>
http://digiserve.com/takdesign/pic-faq/hardware.html
</i><li><i>
http://www.paranoia.com/~filipg/HTML/LINK/ELE/F_PIC_faq.html
</i><li><i>
http://hertz.njit.edu/~rxy5310/picb
</i></ul></UL><P>
<FONT SIZE=4><b>Acknowledgments</b></FONT><p>
The authors want to thank Mike Martin at Prototype
America in Manchester, NH for his extra-speedy work in the rapid
turnaround of our prototype boards.
<hr>
<a href="index.php">NHRC-2 Controller Home Page</a>
<hr>
<?php
$copydate="1996-2005";
$version="1.21";
include '../barefooter.inc';
?>
