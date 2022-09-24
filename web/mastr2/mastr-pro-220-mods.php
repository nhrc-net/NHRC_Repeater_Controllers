<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<html>
<head>
<title>NHRC MASTR II InfoSite -- Converting A GE MASTR Pro Receiver to 220 MHz</TITLE>
<meta name="description"
 content="Instructions to convert a GE MASTR Pro receiver for 220 MHz operation.">
<meta name="keywords" content="MASTR Pro, 220 MHz">
</head>
<BODY>
<!--   8 0   C o l u m n   W i d e   C o m m e n t                           -->
<center>
<font size=6><b>MASTR Pro Receiver Conversion for 220 Mhz</b></font><br>
</center>
<hr>
220 MHz conversion of GE MASTR Pro receiver by Peter Gailunas KA1OKQ<P>
MODELS: 4ER41Cxx , 150.8-174 MHz<BR>
 (xxODD) EG: xx= 11,13,15,17,19,21 <br>
Important must be ER41C<P>
I highly recommend that you obtain a service manual for the ER41C series receiver.  You can find
them at flea markets or your local GE dealer for around $ 10.00.<P>
Note: all capacitors are NP0 type ceramic disc.<P>
Preselector:<br>
<blockquote>
Remove 1-3/4 turns from solder end of all six helical resonators (L301-L312).<br>
Replace all removed taps at the same positions.<br>
Note: A propane blow torch is useful for removing helical resonators from the copper plated
casting. Cut resonators and reform the pigtail with wire forming pliers, clean capacitance hat
of any oxide. Install newly formed helical and resolder with torch.<P>
</blockquote>
First mixer:<br>
<blockquote>
Remove C 1/2<br>
Remove 1 turn from the top of L1<p>
</blockquote>
First osc:<br>
<blockquote>
Remove 1 turn from the top of L1.<br>
Change C29/30 to 24pf (27pf N/G, 22pf ok).<P>
</blockquote>
Second Mult:<br>
<blockquote>
Remove 1 turn from the top of L1<br>
Change C2/3 to 27pf<br>
Change C10/11 to 3pf <br>
Change C12/13 to 4pf (5pf N/G, 3 pf OK).<br>
NOTE: (be very careful not to break c1 when removing cover on old rev's).<P>
</blockquote>
Crystal:<br>
<blockquote>
ICM Cat. # 021240Y<P>
</blockquote>
Connector:<br>
<blockquote>
GE P/N 19A143191G1<P>
</blockquote>
Hook Up:<br>
<blockquote>
Wire system neg (pin 13) to gnd(pin1). Wire rx mute (pin2) to reg 10v(pin12). If multi-channel,
connect +10v to desired frequency (pin 6,7,8 or9). COS is available at pin 19 it transitions
high on signal. I use this line to drive an open collector 2n2222 for buffered cos. Use 10k
in series with the base of 2n2222.<P>
Volume pot is 250 ohm. Squelch pot is 2.5k or 3.5k (Use of other value pots results in
unpredictable squelch operation).<p>
Load AF output with 4 ohm 5 watt (AF amp may oscillate without it).<P>
</blockquote>
Alignment:<br>
<blockquote>
as per GE pub. LBI-3867P<P>
</blockquote>
Sensitivity:<br>
<blockquote>
12DB SINAD @ approx -113dBM/.5uV<P>
</blockquote>
Power supply:<br>
<blockquote>
It's ok to use 13.8 in place of 10V. I have found this to work fine save yourself a regulator.<P>
</blockquote>
Audio out:<p>
<blockquote>
Take repeater audio from the high side of the vol pot. The audio will be pre-emphasized at this
point. De-emphasize as required or inject directly into modulator of your exciter(that's
MODULATOR not normal audio input of the exciter). This yields retransmitted audio as good as the
signal transmitted to the repeater.<P>
If local speaker is not required remove audio output stage as follows.<br>
Remove r40 220 ohm 1/2 w<br>
Unplug wires from J13,14,15,16 ON audio/squelch board.<P>
Ground J15<br>
Take audio from J14<p>
</blockquote>
A word about receiver sensitivity:
<blockquote>
These receivers when properly modified should meet the sensitivity spec.  I have run the Advanced
receiver research GaAS FET preamps with excellent results.  I cannot recommend the use of other
makes of preamps.<P>
</blockquote>
History:<br>
<blockquote>
This conversion info was developed for the early days of the NEW ENGLAND NETWORK (1980).  The net
covered most of New England on 220 mhz. The system was way ahead of its time.  Little, if
anything,remains today of the system.<P>
</blockquote>
Thanks to:<br>
<blockquote>
Sergio Marino KG1C and Dave Tessatore K1DT for their help in the development of this conversion
info (mid 1980's)<p>
</blockquote>
Peter Gailunas/KA1OKQ</a><p>
<hr>
Back to <a href="/mastr2/">MASTR II InfoSite</a><br>
<hr>
<?php
$copydate="1997-2005";
$version="1.11";
include '../barefooter.inc';
?>
