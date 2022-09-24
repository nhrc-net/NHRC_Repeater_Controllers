<?php
$title = "NHRC MASTR II InfoSite -- MASTR II Duplex Conversion Information";
$category = "mastr2";
$item = "duplexing";
$description="GE MASTR II mobile radio full duplex conversion instructions.";
$keywords="MASTR II duplexing, MASTR II conversion, MASTR II, MASTR II repeater, MASTR II conversion, MASTR II";
$version="1.21";
$copydate="1997-2004";
include "../header.inc";
?>
<center>
<font size=6><b>Full Duplex Conversion</b></font><br>
</center>
<ol>
<font size=5><b><li>Before You Begin</b></font><p>
  You will want to have the MASTR II fully tuned up and
  operational on your repeater frequency before you begin...<p>
<font size=5><b><li>Add Receiver Antenna Jack</b></font><p>
  I have seen many MASTR IIs modified by drilling a hole in the cover over the
  receiver input jack for the receiver's input connector.  I hate this; it is
  ugly and limits where you can put the radio and what you can put on top of
  it.  I prefer adding a jack for the receiver antenna on the front panel of
  the radio, in the hole where the mounting lock used to be.<p>
  Remove the lock on the front panel of the radio.  Remove the jumper from the
  T/R switch on the power amplifier to the receiver front end.  This is a short
  jumper with RCA plugs on either end.<p>
  Prepare a length of RG142 or RG400 that is long enough to go from the hole
  where the lock was removed to the receiver input jack.  If you like, you can
  route this cable next to the existing antenna connector cable, by removing
  the side panel of the radio chassis, or you can use the hole through the
  plastic support to route the cable into the receiver oscillator area, and
  then over the mixer/preselector casting and into the antenna jack. Make sure
  that this cable is long enough so the channel-guard board will still fit in
  the radio when the cable is installed.  <b>Do not install the cable at this
  time.</b><p>
  Install a chassis mount N female connector on one end of this cable.
  You can also use a long, threaded
  SO-239 barrel connector, with a PL-259 on the inside.  Whatever connector
  you choose, it will be mounted in the hole that was formerly occupied by
  the lock. Depending on the connector you choose, you may need to drill holes
  in the front panel to mount the connector.<p>
  Install a male RCA-type plug on the other end of the cable.  I typically try
  to reuse one of the plugs from the T/R switch jumper; they seem to be quite
  resistant to soldering heat.  The molded plastic on these plugs can be cut
  away with big diagonal cutters, and the plastic inside the connector body
  melted with a soldering iron and pulled out with a dental pick.  Whatever
  RCA plug you use, make sure the shield coverage is as close to 100% as you
  can get.  The main goal here is to make sure that the antenna jack jumper
  is shielded extremely well.  Do not cut corners here!<p>
  After the cable is assembled, install the jack in the lock hole, route the
  cable, and plug the RCA plug into the receiver input jack.<p>
<font size=5><b><li>Deal with T/R Relay (or not...)</b></font><p>
  Once the radio is duplexed, there is no need for the T/R relay.  There are
  three things that can be done with it:<p>
    <ol>
    <b><li>Nothing.</b>  You can leave the T/R relay alone, clicking in every
    time the transmitter is keyed.  The problem with leaving the relay alone
    is that the relay can fail, or make a bad connection.<p>
    <b><li>Jumper it in Transmit.</b> You can jumper the radio's system board
    to keep the relay pulled in all the time. This eliminates the clicking,
    but the relay can still fail.  <b>jumper instructions go here...</b><p>
    <b><li>Remove the Relay.</b>  On some power amplifiers, there are two or
    three separate PC boards.  One PC board comprises the harmonic filter and
    the T/R relay.  If you have one of these PAs, you can remove the screws
    hold down the cover for the harmonic filter, and the screws that hold
    down the harmonic filter / T/R relay assembly, then unsolder the jumper
    that couples the PA output into the harmonic filter.  Remove the relay
    (this is a bit of work!) and jumper the harmonic filter output into the
    antenna jack on the PC board.  I typically cut away some of the foil on
    the bottom of the board, and use a bit of flattened braid for this jumper.
    Verify that you have not shorted out the PA's output, and reassemble the
    PA.  It is possible to remove the T/R relay on PAs that are made of a
    single board, but <b>extreme care</b> must be exercised or you will
    destroy the expensive RF transistors.  When loosening or tightening the
    transistor mounting nuts, you must hold the end of the stud with pliers
    or a small ignition wrench to prevent the transistor from rotating and
    breaking.  When reinstalling the PA to the heat sink <b>do not
    overtighten</b> the transistor stud or you will break it right off.
    (Some things are better left alone...)
    </ol>
    <p>
<font size=5><b><li>System Board Modifications</b></font><p>
  The modifications to the system board disable receiver muting during
  transmit, leave the receiver's power on all the time, and optionally, select
  the F1 channel element (ICOM) for the transmitter and receiver.<p>
  These modifications will require access to the top and bottom of the system
  board.  You will need to remove the bottom cover on the radio.  This cover is
  held on by two screws on the top side of the radio, on either side of the
  system board.<p>
  To disable the transmit receiver muting, cut the trace between H95 and H96.
  This trace starts at J904 pin 7 (IF/Audio/Squelch module RX MUTE) and goes
  to pin 6 of U901 (the 10 volt regulator IC).  This cut disables receiver
  muting during transmit.<p>
  Install a jumper from the trace leading to J903 pin 11 and the trace leading
  to J903 pin 12.  J903 is the system board connector for the
  oscillator/multiplier board.  This jumper supplies 10V to the oscillator
  all the time, regardless of whether the transmitter in on or not.<p>
  You may or may not wish to install a jumper on the system board to select
  F1 (channel 1) all the time.  I always install this jumper; I have never
  made a two-channel repeater.  J902 pin 8 is the exciter's F1 select, and
  J903 pin 1 is the oscillator/multiplier's F1 select.  Normally these two
  pins are connected together, through a trace between H2 and H5 on the
  systems board, but sometimes this trace is cut.  Both of these pins need
  to be grounded to select F1.  Convenient places to get ground for the F1
  selects include J902 pin 4 and J903 pin 10.<p>
<font size=5><b><li>Powering the MASTR II</b></font><p>
  Since the Mastr II was designed to be used in either a positive or 
  negative ground vehicle, the A- is NOT connected to the chassis ground,
  but it is usually desired to strap them together when building a repeater.<p>
  There are several power leads for the Mastr II.  There are the large 
  RED lead that powers up the PA (TX A+), as well as the A+ (16 Ga yellow)
  and IGN SWITCH (red).  All of those need +13.8 Volts DC.<p>
  Then are the grounds...  The large black wire (TX A-) and the A- 
  (16 ga black), these can all be tied together.<p>
  If you don't have voltage connected to all of the points necessary 
  (common when you don't use a control head and cable) the radio won't 
  operate correctly or at all.<p>
  If you are or aren't using a cable, you need to insure all of the 
  voltages and grounds are being supplied as connecting voltage to the
  two large terminals only supplies power to the Transmitter PA, again,
  as the radio was designed to operate either positive or negative ground 
  and the chassis is not connected to A- (power ground), but it needs to 
  be, and also A+ needs supplied to the IGN lead and A+ lead as this 
  supplies voltage to the rest of the radios circuitry.<p>
  Install a 3 to 5 amp fuse in a holder from the large red wire to both
  the IGN and A+.  Then install a wire from the large black lead to both 
  A- pins. (Thanks to W3KKC for this section.)<p>
  
<font size=5><b><li>Controller Interfacing</b></font><p>
  There are at several different schools of thought on interfacing
  MASTR II radios to repeater controllers.
  <ul>
  <li>An interface cable for the repeater controller can be wired to the
      control head.
  <li>An interface cable for the repeater controller can be wired directly
      into the radio's system board.
  <li>A control cable can be &quot;sacrificed&quot; by cutting off the control
      head plugs and installing a small box with volume and squelch controls
      and an interface cable for the repeater controller.
  <li>Some combination of the above.
  </ul>
  In any event, consultation of the system board or control head schematics
  are a must. <p>
  <dl>
    <dt><b>CAS/COR</b><dd><p>
      Be very careful of the CAS signal, it cannot source much
      current at all, and replacing the hybrid on the IFAS board is very
      expensive.  You can convert the CAS signal to open-collector by using a
      2N2222, with the emitter grounded and the base connected to the CAS signal
      through a 10K resistor.  The collector of the 2N2222 will be pulled to
      ground when the squelch is open (signal being received).<p>
    <dt><b>PTT</b><dd><p>
      Push To Talk requires a closure to ground to transmit.  You can use an
      &quot;open-collector&quot; or &quot;open-drain&quot; signal from your
      repeater controller to supply the PTT signal.<p>
    <dt><b>Transmit Audio</b><dd><p>
      Inject the transmit audio into the microphone input of the radio.  Be
      aware that this input has a +10V bias applied, which is intended to power
      the microphone preamp.  You might need to insert a DC blocking capacitor
      here, probably an electrolytic in the range of 1-10&#181;F (watch the
      polarity!).  If you are planning to use a local microphone on the control
      head, you might want to insert a resistor in series with the controller's
      audio output to prevent the controller from loading down the microphone's
      output.  5K would be a good value to start with.<p>
    <dt><b>Receiver Audio</b><dd><p>
      Receiver audio should be taken from &quot;Volume/Squelch Hi&quot;.  This
      signal is unsquelched and not de-emphasized, and is not subject to
      adjustment by the volume control.  The controller should provide muting
      so unsquelched audio does not play over the repeater during the repeater's
      tail (hang time).<p>
      This source of receiver audio must be de-emphasized.  The deemphasis
      filter should have a -6dB/octave slope for proper frequency response.  If
      the receiver audio is not de-emphasized, the repeater will sound really
      &quot;tinny&quot;.  Many controllers have built-in deemphasis filters.  If
      yours does not, you can make your own with a 15K resistor and a .22&#181;F
      capacitor.  Wire one side of the 15K resistor to the volume/squelch hi
      signal, and the other side to one side of the .22&#181;F capacitor.
      Ground the other leg of the capacitor.  Take the receiver audio from the
      capacitor-resistor junction.<p>
    <dt><b>CTCSS</b><dd><p>
      We prefer the Comm-Spec <a href="http://www.com-spec.com/ts64.htm">
      TS-64</a> CTCSS board for use with these radios, 
      rather than the GE unit.  The TS-64 can simultaneously encode and 
      decode, and the CTCSS frequency can be changed by simply moving some 
      DIP switches.  Use volume/squelch hi for the TS-64's input
      (for decode), and TX CG HI for the CTCSS encode.  You may or may not 
      want to use the TS-64's high-pass filter to remove the CTCSS tone 
      from the received audio.  You will still need to deemphasize the 
      audio, regardless of whether you use the TS-64's low pass filter. 
      The CTCSS detect signal from the TS-64 gets wired to your controller. 
      Consult the controller's and TS-64's manuals for this wiring.
  </dl>
</ol>
<?php include '../footer.inc'; ?>
