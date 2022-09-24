<?php
$title = "NHRC MASTR II InfoSite -- Crossbanding";
$category = "mastr2";
$item = "crossbanding";
$description="How to convert a GE MASTR II mobile radio into a crossband repeater.";
$keywords="MASTR II crossbanding";
$version="1.21";
$copydate="1997-2004";
include "../header.inc";
?>
<center>
<font size=6><b>MASTR II Crossband Applications</b></font><br>
</center>
<p>
<font size=4><b>Remote Receiver</b></font><br>
<blockquote>
  A crossband MASTR II makes an excellent remote receiver.  In this
  configuration, the MASTR II receives on a VHF band, and repeats what it
  hears on a UHF link frequency.  A UHF receiver for each link frequency is
  used at the repeater's transmitter site to receive the signal(s) from the
  remote receiver(s), and transmits it back out on the VHF
  repeater's output frequency.  A <i>voter</i> is often used at the
  transmitter site to choose the receiver with the best signal quality to
  re-transmit.<p>
  </blockquote>
<font size=4><b>Split Site Repeater</b></font><br>
  <blockquote>
  A pair of symetrical crossband MASTR IIs makes an excellent
  <i>split-site</i> repeater, particularly for the 6-meter band, where the
  cost and size of a duplexer is prohibitive.  This configuration uses a
  MASTR II that receives on 6 meters, and repeats the received signal onto
  a UHF link frequency.  At the second site, the other MASTR II receives
  the link frequency and re-transmits what it hears on the 6 meter repeater's
  output frequency.<p>
  </blockquote>
  <font size=5><b>Crossbanding Information</b></font><p>
<blockquote>
  I prefer to swap the transmitters.  Some people have told me that swapping the
  receivers is easier, but I don't think so.  Here's how to swap the trasmitters.
  It helps if the radios you want to crossband are operational and tuned up
  before you begin.  The <a href="duplexing.php">duplex modification</a> should
  be performed before crossbanding.<p>
  Perform the following steps to both radios:<br>
  <ol>
    <li>Remove the 6 screws holding the exciter in, and remove the exciter.
    <li>Unsolder the large black and red wires from the bottom of the PA.
    <li>Remove the 4 screws that attach the PA to the rest of the radio. Dismount
	the PA from the rest of the radio.  <B>DO NOT DISASSEMBLE THE PA.</b>
    <li>Swap the exciters and PAs, and install them into the other radio.  Be
	sure to keep the exciter with the correct PA, it will not be good if
	you mix these up.  Pay attention to the polarity of the power cables
	when you reattach them.
  </ol>
  </blockquote
<?php include '../footer.inc'; ?>
