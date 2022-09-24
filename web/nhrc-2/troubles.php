<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head><title>NHRC-2 Troubleshooting Guide</title>
<META NAME="keywords" CONTENT="NHRC-2 Troubleshooting">
<META NAME="description" CONTENT="A guide to troubleshooting the NHRC-2 Repeater Controller">
</head>
<body bgcolor=white>
<FONT SIZE=6><b><center>NHRC-2 Repeater Controller</center></b></FONT>
<font size=5><b><center>Troubleshooting Guide</center></b></font>
<hr align=center width="90%">
<br>
<center>
<font size=5><b>Table of Contents</b></font><p>
<table border=0><tr><td>
<font size=4><b>
<a href="#power">Power-related problems</a><br>
<a href="#cas">CAS signal problems</a><br>
<a href="#ptt">PTT signal problems</a><br>
<a href="#dead">Completely dead controller</a><br>
<a href="#audio">Audio problems</a><br>
<a href="#dtmf">DTMF decoding problems</a><br>
<a href="#voice">Voice messages are distorted or noisy</a><br>
<a href="#lastresort">The last resort</a><br>
</b></font>
</td></tr></table></center><p>
<hr align=center width="90%">
<p>
<table border=0 cellpadding=10>
<tr><td colspan=3>
<font size=4><b><a name="power">Power-related problems</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
Check all of your solder joints carefully.  A poorly soldered or an
unsoldered joint can cause all sorts of problems. Solder joints should
appear bright and shiny, and the solder should taper from the end of the
pin to the pad on the board; there should not be a &quot;blob&quot; of
solder on the pin.  Make sure that there are no solder &quot;bridges&quot;
between pads or traces.  It is very easy to create solder bridges between
the IC pins, these pins are only 1/10 of an inch apart.
<p>
Apply power with all the chips removed from their sockets and an ammeter
in series with the +13.8 (pin 2 on the controller).  There should be an
extremely small amount of current flowing into the board with the ICs 
removed, typically less than 5 mA.  If there is more current, check
component placement, and ensure that there are no solder bridges on the
board.  Remove the ammeter, and re-apply power.  With all of the chips 
still removed, check for 5 volts at pin 3 of U4, pin 14 of U1, pin 28
of U2, and pin 18 of U3.  If any of the power supply voltages are not
right <b>do not insert the chips</b> until this problem is found and
corrected.
<p>
Make sure the PIC 16C84 is in the middle socket on the board.  The M8870
sits in the socket next to  the crystal.  Make sure the chips are plugged
in correctly, with pin 1 toward the DB-9 connector.  Improper installation
of the chips can destroy them!  If you had the chips in backward they may
be nuked. 
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="cas">CAS Signal problems</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
The easiest way to verify correct operation of the CAS signal is to remove
ISO1 (4N39) from its socket, and plug a LED in instead.  The LED's 
anode(?) (the + leg, usually longer) goes into pin 1, and the cathode(?)
(the - leg, usually shorter) goes to pin 2 of the socket.  If you are 
unsure of which leg of the LED is which, test it with 12 volts and a 1K
ohm resistor in series with the LED.  When the CAS signal is correctly 
applied, the LED should glow.  A dim glow is probably OK.  If the LED
lights up very brightly, or explodes, it is likely that the CAS signal's
voltage is too high.  In this case, ISO1 has probably been destroyed.
Replace R30 (1.5K) with a higher value, calculated to allow approximately
10 mA to flow through the LED in the opto-isolator.	 We do not recommend
CAS signal voltages of more than 30 volts.
<p>
If the LED will not glow, make sure that there is at least +3 volts on
pin 6 of the DB-9 connector, measured against pin 7, when the CAS signal
is present.  The LED must glow when the CAS signal is present.
<p>
If the LED glows when CAS is applied, but the controller never seems to
&quot;see&quot; that the signal is there, you can test the entire CAS path
in the controller by using a DVM to measure the voltage on pin 13 of U1
(the PIC16C84).  Pin 13 should be near 5 volts when the CAS signal is not
present, and should fall to near 0 volts when the signal is present.
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="ptt">PTT Signal problems</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
If the power is not good, or the CAS signal is not good, you will never get
PTT (push-to-talk).  These sections should be verified before worrying about
the PTT circuit.
<p>
Pin 7 of U1 (the PIC16C84) should normally be around 0 volts, and should
rise to about 5 volts when the controller turns PTT on.  If not, verify
the CAS signal is working, then examine the section in this document on
a <a href="#dead">completely dead controller</a>.  When PTT is turned
on, the gate (pin 1) of Q6 should rise to about 5 volts.  If not, then 
either Q6 is bad (shorted) or R29 is open or incorrectly installed.
<p>
The controller supplies PTT as a closure to ground.  If the controller is
interfaced to the repeater correctly, there should be some positive voltage
on the drain (pin 2) of Q6.  When the controller turns PTT on, this positive
voltage should drop to near 0 volts.  If there is no positive voltage on 
pin 2 of Q6, then check the interface to the transmitter's PTT line.
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="dead">Completely Dead Controller</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
If the controller appears completely dead, and none of the power, CAS, or
PTT symptoms are found, then the problem may be related to the microprocesor.
Measure the DC voltage on Pin 4 of U1 (the PIC 16C84) with a DVM. This pin
should hava around 5 volts on it.  If it does not, check R17, R18, R19, Q5,
and D1.  Make sure that D1 is installed correctly, with the banded end of 
the diode towards the junction of R17 and R19.  Make sure that Q5 is oriented
correctly, and verify the values of R17, R18, and R19.
<p>
If U1 pin 4 has about 5 volts on it, make sure that the 3.58 MHz clock is
running.  Use an oscilloscope to look at U1 pin 15.  This pin should have
a nice square wave on it, at the 3.58 MHz clock frequency.  If the clock
is not found at pin 15, look for it at U3 (the M8870) pin 8.  If the clock
is present on U3 pin 8, but not on U1 pin 15, verify the installation of 
C20, a 33pF capacitor.  If the clock is not present on U3 pin 8, verify 
that power is applied to the U3, and that the crystal Y1 is properly 
installed.
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="audio">Audio problems</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
First, note that the controller should pass audio through to the transmitter
only when the CAS signal is present.  If the audio passes through when the
CAS signal is not present, and unsquelched audio is transmitted during the 
hang time, then it is likely that either you have forgotten to remove the 
init jumper (S1), or are overdriving the audio gate FET.  Remove the jumper
or reduce the signal applied with VR1.
<p>
The next common problem to cause the audio path to malfunction is the failure
to use dipped tantalum caps for c2, c7, c8, c9, c10, c11, c14 and c17.
The tantalum caps have a very low ESR (effective series resistance).  The
use of any other type of cap will cause the output of the op amp to sit at
the rail ( 13v).  Voltages around U5 measured with a DVM should be as
follows .  Pin3=6.5v, pin 1=6.5v , pin 7=6.5v.  If pin 1 or 7 is reading
higher (about 12 volts or more) you have a leaky cap or an open in the 
feedback path.  If pin 3 isn't reading around 6.5v check the values of r1
and r2, should be 10k.  Also note that you have installed the tantalum caps
in the board with the proper polarity. The square pad indicates the positive
side of the cap (except C7 and C8 where the square pad indicates the negative
side.) Tantalum caps are easily destroyed by reverse voltages, if you put it 
in backwards, throw it away and use a new one.
<p>
If the audio out of the controller is low, check to make sure that VR2 is a 
500k pot and R15 is 10k.
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="dtmf">DTMF decoding problems</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
If DTMF tones do not mute completely or not at all, try lowering the main RX
level at VR1.  You may be over driving the audio muting gate FET (Q1) and it
is starting to turn on.  Verify the installation of all the components in the
muting circuit:  R6, R7, R8, Q1, and Q2.
<p>
If DTMF tones do not mute and the controller doesn't respond to commands, 
can' t load password, make certain that VR1 isn't adjusted to low.  You 
should have around 2v P-P at u5 pin 1, ignoring the dc level.  Check the 
audio circuit for malfunctions as above.  If the audio through the 
controller is good check that C1, a .1uf cap is soldered in.  R5 and R23 
should be 100k.  Look with a scope at pin 2 on u3 the M8870.  You should
see audio here.  It should look similar to the signal at U5 (op-amp) pin
1 EXCEPT the signal should not  be biased at the 6.5v dc level.  If you
have audio at a dc level at the decoder pin2 then c1 is probably bad.  If
the audio looks good at the decoder be certain  R22 is 300k and C19 is
.1uf.  Probe pin 15 of U3 (STD) with a dvm or scope, you should see this
pin go high when you send DTMF to the controller.  If the STD signal is 
working check pin 6 of U1 (the PIC16C84) and see if the signal is getting
to the PIC.
<p>
Check the section on <a href="#audio">audio problems</a> if this section
does not help with your DTMF decoding problem.
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="voice">Voice messages are distorted or noisy
</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
The leading cause of noise on recorded messages is improper bypass caps
on the power supply leads around the 7805 and the ISD1420.  Be certain
that C13 is installed properly and is a minimum of 220uf @16v.  The
ISD1420 draws large bursts of current while recording.  If the caps are
not properly installed the voltage to the chip sags during record and
noise is recorded with the audio.
<p>
If your messages are distorted you are probably either overdriving the 
ISD1420, or the ISD1420 is overdriving the repeater controller's mixer or
your transmitter's microphone preamp.  Place the controller in the simplex
repeater mode and adjust VR-3 (record level) and VR-5 (play level) until 
the audio sounds natural.
<p>
Also check the values of R21 470k, c12 4.7 uf tantalum cap, c10 .1uf .
Check R9 22k, R10 10k and c5 .1uf .  Check C9 1uf tantalum,  R13 22k.
</td><td width="10%"></td></tr>
<tr><td colspan=3>
<font size=4><b><a name="lastresort">The last resort</a></b></font>
</td></tr><tr><td width="10%"></td><td width="80%">
If these hints don't get you going or don't address your problem, then
send a detailed, clearly written question to 
<script language="javascript">
mto = "\155\x61\u0069\x6c\164\x6f\u003a"
dom = "\u0040\156\150\162\143\u002e\156\145\164"
addr = "\150\x61\162\u0064\x77\u0061\162\x65\55\163\u0075\160\x70\u006f\162\u0074" + dom
document.writeln('<a href="'+mto+addr+'">'+addr+'</a>')
</script>.
Also, please email if you discover a problem, hint, or solution that is not 
documented in this page.
</td></tr>
</table>
<hr>
Back to the <a href="index.php">NHRC-2 Repeater Controller Page</a>
<hr>
<?php
$copydate="1996-2005";
$version="1.11";
include '../barefooter.inc';
?>

