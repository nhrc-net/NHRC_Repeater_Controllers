<?php
$title = "NHRC MASTR II InfoSite -- Choosing a Radio to Convert";
$category = "mastr2";
$item = "choosing";
$description="Choosing a GE MASTR II mobile radio to convert.";
$keywords="MASTR II Repeater Conversion";
$version="1.23";
$copydate="1997-2012";
include "../header.inc";
?>
<div align=center>
<font size=6><b>MASTR II InfoSite</b></font><br>
<font size=5><b>Choosing a Radio to Convert</b></font><br>
</div>
<dl>
  <font size=5><b><dt>Bands and &quot;splits&quot;</b></font><dd>
    For the purposes of this article, we will assume that there are only 4 bands
    of interest for conversion: 10m, 6m, 2m, and 70cm.  A &quot;split&quot; is
    a region of a band that a radio built with certain parts will tune.  It is
    the range of frequencies that the radio is capable of operating on.  You
    will need to refer to the <a href="combination.php">combination numbers</a>
    to determine what radio you want to find to convert.<p>
    <ul>
    <font size=4><b><li>VHF Low Band:</b></font> There are 4 &quot;splits&quot;
    available in this band.  The only interesting splits are the
    &quot;12&quot; split (25-30 MHz, rare!), the &quot;13&quot; split (30-36)
    and the &quot;33&quot; split (42-50 MHz).  The &quot;23&quot; split should
    be avoided at all costs; it is useless for amateur operation.  The 12
    &amp; 13 split radios can be tuned into the amateur 10-meter band, and
    the 33 split radios can be tuned into the amateur 6-meter band.
    <p>
    <font size=4><b><li>VHF High Band:</b></font>  There are 2 splits available
    in the VHF high band.  The &quot;56&quot; split is from 138-155 MHz.
    These are more desirable for amateur work, and much more difficult to find.
    (If you find some, get one for me!)  The &quot;66&quot; split is from
    150.8-174 MHz, and is more commonly available.  The high split radios can
    be re-tuned into the amateur bands, typically without too much difficulty,
    but care must be taken that the transmitter does not have excessive
    spurious emissions.  The 66 split exciters can be modified to be
    56 split exciters by replacing a dozen or so disc capacitors.  The 66 split
    radios are preferred for 222 MHz conversion.
    <p>
    <font size=4><b><li>UHF:</b></font>  There are five different splits for UHF
    MASTR IIs.  Only three are interesting for amateur use: the &quot;77&quot;
    split (406-420 MHz), the &quot;78&quot; split (420-450 MHz, rare!), and the
    &quot;88&quot; split (450-470 MHz).  The other two splits (89 &amp; 91)
    are in the so-called &quot;T-band&quot; (UHF television spectrum) and are
    not useful to amateurs.
    The 77 split (406-420) radios can be retuned into the bottom segment of the
    420-450 MHz U.S. amateur 70cm band, where they are useful for linking
    repeaters, remote receivers, etc. (See <a href="crossbanding.php">
    Crossbanding Applications</a> for some ideas...)  The 78 split (420-450)
    radios are already in the U.S. amateur band, but are extremely rare.  Radios
    in the 88 split (450-470) split can be re-tuned into the 440-450 band and
    used as UHF repeaters.
  </ul>	<p>
  <font size=5><b><dt>Frequency Stability</b></font><dd>
    MASTR IIs are available in 2 PPM (parts per million) or 5 PPM frequency
    stability.  The difference between the 2 stabilities available is in the
    channel elements, which GE likes to call <i>ICOMs</i>, for Integrated
    Circuit Oscillator Modules.  The ICOMs are available in 3 different styles,
    both in receive and transmit varieties, for a total of 6 different ICOMs
    for a given band.<p>
    <ul>
      <font size=4><b><li>2C ICOMs:</b></font> These are the 2 PPM oscillators.
        They are what you want if you are going to build a wide-area coverage
	repeater that will not be in a climate-controlled environment.  The
	ICOMs themselves are more expensive, as are the crystals that go inside
	the ICOM.
	<p>
      <font size=4><b><li>5C ICOMs:</b></font> These are the 5 PPM oscillators.
	Most mobile radios will use 5 PPM oscillator stability and will have at
	least one 5C ICOM.  These are reasonably stable, and can be used for
	repeater operation if the environmental temperature is relatively
	constant.  5C ICOMs provide &quot;temperature compensation&quot; to
	EC ICOMs.
	<p>
      <font size=4><b><li>EC ICOMs:</b></font> These are used in conjunction
        with 5C ICOMs. <b>DO NOT USE EC ICOMs IN A RADIO WITHOUT A 5C ICOM
	INSTALLED.</b> The oscillator frequency will not be stable.  These ICOMs
	provide 5 PPM stability when used with a 5C ICOM.  They use a
	&quot;temperature compensation&quot; signal provided
	by a 5C ICOM.  Typically, the receiver has a 5C ICOM and the
	transmitter a EC ICOM.
    </ul><p>
    You can change the ICOM's frequency by replacing the crystal.  However, if
    you change the crystal yourself, you risk upsetting the temperature
    compensation of the ICOM, which must be matched to the crystal.  If you are
    going to pay for a 2C ICOM with a 2 PPM crystal, it is well worth the money
    to get a reputable crystal house (like International Crystal Manufacturing)
    to compensate the ICOM to match the crystal.  This typically costs about
    $25.00.<p>
  <font size=5><b><dt>Exciters</b></font><dd>
    The VHF high-band radio has two different exciters available: a
    &quot;multiplier&quot; exciter, and a &quot;PLL&quot; exciter.  The PLL
    exciter is preferred for repeater use, it has a somewhat cleaner output
    (less spurs) than the 150.8-174 MHz multiplier exciter does when it is
    tuned into the amateur 2-meter band.  The PLL exciter still requires a
    crystal in a special FM ICOM, it is not &quot;synthesized&quot; in the sense
    that you cannot change the operating frequency of the exciter without
    changing the ICOM crystal.  The PLL exciter is true FM, which may make it
    preferable for packet work.  (The multiplier exciters are phase-modulated.)
    <p>
    There is a true-FM exciter available for UHF MASTR IIs, but it is somewhat
    rare and the prices reflect that.  You can recognize this exciter by the 
    larger ICOM module, the FM ICOMs are about 50% wider and 50% thicker than
    the usual ones.<p>
  <font size=5><b><dt>Power Amplifiers</b></font><dd>
    In most cases, you will want the biggest PA you can find.  However, there
    is one important exception to this rule: MASTR II PAs don't like to operate
    below about 40% of rated power output, especially the UHF ones.  If you plan
    to drive an external amplifier with the transmitter output, check the input
    power level minimum and maximum of the external amplifier and choose your
    MASTR II power level accordingly.<p>
  <font size=5><b><dt>Accessories</b></font><dd>
    The typical accessories for a MASTR II include a control head, microphone,
    microphone hanger, speaker, power cable (control head to battery) and
    control head cable (radio to control head).  If you have no accessories,
    you will want to get the all of the above, with the possible exception of
    the microphone hanger.  Lack of these accessories make tune-up and service
    ridiculously difficult.  For building repeaters, you can get by with a
    control cable alone.<p>
  <font size=5><b><dt>Handle Color and UHF MASTR IIs</b></font><dd>
    Beware of <a href="pictures.php#silver">&quot;silver handle&quot;</a>
    UHF MASTR IIs.  These typically have a VHF exciter and a &quot;tripler
    PA&quot; in them.  These radios are notorious for spurs and general noise
    on the RF output.  The <a href="pictures.php#painted">
    &quot;painted handle&quot;</a> UHF radios are definitely preferred.  The
    silver handle radios are an older vintage MASTR II, and are perfectly ok
    for low band and VHF.<p
  <font size=5><b><dt>Stations!</b></font><dd>
    Many GE MASTR II stations have come on the market recently due to the fact
    that all Public Safety, Industrial, and Business users using 25 KHz channels
    are required to switch to 12.5 KHz channels by January 1, 2013.  These 
    surplus stations represent a tremendous opportunity for Amateur Radio
    repeater builders.  The stations have significantly better isolation 
    between transmit and receive, and many have continuous-duty power 
    amplifiers with large heat sinks.
  <font size=5><b><dt>What to Pay</b></font><dd>
    I have seen MASTR II mobiles sold at hamfests for as low as $15, with
    accessories, and for as much as $150, without accessories. $75-$100 is
    the typical price range.  More than $100 is too much.  Keep shopping.
    <p>
</dl>
<?php include '../footer.inc'; ?>
