<?php
$title = "NHRC MASTR II InfoSite - General Alignment Instructions";
$category = "mastr2";
$item = "alignment";
$description="GE MASTR II mobile radio conversions Tune-Up Information.";
$keywords="MASTR II Tune-Up Information";
$version="1.31";
$copydate="1997-2004";
include "../header.inc";
?>
<div align=center>
<font size=6><b>General Alignment Instructions</b></font>
</div>
<p>
<dl>
  <dt>
    <font size=4>Service Manuals</font><p>
  <dd>
      Service Manuals for MASTR II radios are available from a variety of sources,
      including ebay, hamfests.  There are some PDFs around on the internet for 
      some of the parts, but a complete manual is invaluable.  Expect to pay $5 to 
      $15 for a used manual for a mobile MASTR II.  We <i>strongly</i> recommend
      that you get one for the radio that you plan to convert.  Sometimes, these
      manuals can be found for cheap at hamfests, other times you may have to buy
      manuals from GE.<p>
  <dt>
      <font size=4>Using the Metering Jacks</font><br>
  <dd>
      <div align=center>
      <table border><tr><th bgcolor=white>
	<font size=4 color=black>Metering Jack Diagram</font><br>
	<img src="M2-metering-jack.gif" width=96 height=144 border=0>
	</th></tr></table></div><br>
	You don't need to use the GE test set to tune up a MASTR II.  In fact, we have
	<i>never</i> used one at all.  You can get by with a sensitive voltmeter.<p>
	An analog meter will work fine, provided it is of fairly high input impedance.
	We always use DMMs.  If you have a DMM with a bar-graph display, in addition to
	the digits, so much the better.  The key to using a DMM is to make all adjustments
	<i>slowly</i>, so you are not subject to the relatively long hysteresis of the
	meter.  You will typically use the 200 mV, 2 V, and 20V scales on your DMM to
	align the radio.<p>
	Most of the measurements on the metering jack are measured against A-, which
        is accessible at pins 8 and 9 of the metering jack.  Metering position G appears
        to be the exception, and is measured with metering jack pin 5 as the low (-) side
        and metering jack pin 6 as the high (+) side.  This difference rears its ugly head
	in the VHF-hi exciter, where the GE test set is referenced to A+ rather than A-.
	<b>We recommend that when aligning VHF exciters, unless you know exactly what 
	you are doing, you place both multimeter leads as indicated in the diagram for 
	reading metering position G.  This does not apply to the GE test set.</b>
	<p>
	Connecting to the metering jack itself may involve some creativity.  The
	socket holes are a somewhat inconvenient size.  We
	have used large canvas needles, heavy resistor leads, even brass tacks!  Make
	sure that whatever you stick in there cannot fall out and short something out
	in the radio.<p>
	The diagram above shows the pinout of the metering jack.  The letters next
	to the jack indicate the GE test set measurement position that appears on the
	adjacent pin.  These letters are referenced in the service manuals, not the
	pin number.  A, B, C, D, F, and G appear to be the most commonly used
	measurements on the MASTR II (based on a quick survey of three service manuals.)
	In the unlikely event that your manual references E, I, or J, you will need
	to consult the schematics to see which pin number is used.  (Please let me
	know!)<p>
	Most (or all) of the adjustments in a MASTR II are relative, as opposed to
	absolute.  The adjustments involve either <i>peaking</i> or <i>dipping</i> a
	specific metering jack reading by adjusting one or more controls, usually
        variable inductors (coils) or variable capacitors.<p>
<blockquote>
<i>Peaking</i> an adjustment is relatively straight forward: tune the specified
controls to get the largest reading on the meter.  You may need to change the
voltage range selected on the meter during this process.  If you cannot find a
peak, it is likely that an earlier stage in the radio is not properly aligned.
Back up one or two steps and make sure that the previous stages are correctly
aligned.<p>
<i>Dipping</i> can be a bit trickier.  The idea here is to find the low reading
for the specified controls.  Sometimes, the dip will be somewhat shallow.  This
is usually OK.  If you can't find a dip, then backtrack like above.<p>
</blockquote>
Beware of "false" dips and peaks.  Sometimes you will find a control that exhibits
the desired dip or peak more than once in it's adjustment range.  Usually the most
pronounced (bigger) dip or peak is the correct one.<p>
When aligning transmitters, <b>do not</b> leave the transmitter keyed
(transmitting) for an extended period.  Connect the meter, key up, make your
adjustment, and unkey.  It is possible to damage the exciter during tune-up while
it is not properly aligned.  Be sure a dummy load is connected to the transmitter
output during alignment and testing.<p>
  <dt>
      <font size=4>What you will need</font><p>
  <dd>
      You will need to have the following tools and test equipment available in
      order to successfully align a MASTR II:
      <ul>
	<li>A <i>wattmeter</i> that is accurate at the transmitter frequency
	<li>A <i>dummy load</i> of sufficient power handling capacity to handle the
	    full transmitter output for at least 5 minutes.
	<li>A <i>Signal Generator</i> that can generate a stable signal, with
	    modulation applied, at the receiver frequency.
	<li>Nylon or Delrin <i>alignment tools</i>.  Radio Shack sells some of
	    these, but we cannot vouch for them, having never used them.
	    Usually the cheap one suck.  You will need one or two sizes of
	    hex-head alignment tools, and a small screwdriver head tool.
	<li>A <i>high-current power supply</i>.  You're not going to get 100 watts
	    (or more) of RF if you hook the radio to a 5 or 10 amp power supply.
	    Use a supply that is capable of delivering at least 20 amps continuous
	    duty.
	<li>A <i>Frequency Counter</i> capable of operation at the transmitter
	    frequency.
      </ul><p>
      In addition to all that, a <i>spectrum analyzer</i> is not required, but if
      you are planning to use your MASTR II as a repeater at a crowded site, it
      would definitely be a good idea to make sure that the transmitter output is
      spectrally pure.  Operation of a spectrum analyzer is beyond the scope of
      this document, but whoever owns one will likely know how to use it.<p>
  <dt>
      <font size=4>Other Information</font><p>
  <dd>
      <B>Do not attach the signal generator to the antenna jack</b> unless the radio
      has already been duplexed, and then double-check to make sure that the generator
      is connected to the <i>receiver</i> jack, not the transmitter jack.  Failure to
      heed this warning will likely result in a blown-up signal generator.  If the
      radio has not yet been duplexed, disconnect the cable from the T/R relay on the
      power amplifier, and plug the generator into the RCA jack on the
      receiver's front end.<p>
</dl>
<?php include '../footer.inc'; ?>
