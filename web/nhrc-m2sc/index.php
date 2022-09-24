<?php 
$title = "NHRC-M2/SC Repeater Controller Interface Card for MASTR II Stations";
$category = "ge";
$item = "nhrc-m2sc";
$description="The NHRC-M2/SC, a repeater controller interface board for GE MASTR II Stations.";
$keywords="NHRC-M2/SC, repeater controller, NHRC, MASTR II, ";
$version="1.13";
$copydate="2009-2013";
include "../header.inc";
?>
<div class="pageHeadCentered">NHRC-M2/SC</div>
<div class="pageHeadCenteredSmaller">Repeater Controller Interface Board<br>
for General Electric MASTR II Stations</div>
<p>
<table border=0 width="100%">
  <tr>
    <td valign="top">
The NHRC-M2/SC is a board that plugs in inside the GE MASTR II station,
allowing repeater controllers to be easily interfaced without soldering
wires all over the back plane.  The NHRC-M2/SC can support an internal 
repeater controller, right in the card cage, or an external controller, 
interfaced through a common DB9 connector.
<p>
<div class="productFeatures">Features:</div>
<ul>
  <li>Plugs in inside a General Electric MASTR II station with no additional wiring.
  <li>Footprints for NHRC-3+, NHRC-4, and NHRC-4/MVP controllers on board.
  <li>DB9 Connector for easy interface of external controller
    <ul>
      <li>Easily configured for NHRC-5, NHRC-6, NHRC-7, or NHRC-10.
      <li>Jumpers permit alternative wiring scheme of DB9 connector.
    </ul>
  <li>Large prototype area allows custom interface circuitry to be built on this board.
  <li>All important backplane signals are labelled.
  <li>Allows simple connection to station, no soldering wires to backplane.
</ul>

<div class="productFeatures">What's Included:</div>
<ul>
  <li>NHRC-M2/SC Repeater Controller Interface Card
  <li>Four 1/2&quot; nylon standoffs
  <li>Eight 4-40 screws
  <li>DB9 Female connector
  <li>Center-off slide switch
  <li>10-pin Molex header
  <li>10-pin Molex head shell and 10 pins
  <li>Instruction Sheet
  <li><b>The high pass filter components are NOT included.</b>
  <li><b>This board ships <i>unassembled</i> so users may configure it for any purpose.</b>
</ul>
<div class="productFeatures">Installation:</div>
<blockquote>
The NHRC-M2/SC plugs into slot J1212 in the MASTR II Station, the 2nd slot from the left.
All signals needed to interface a repeater are available on the card.  Depending on user 
selection, the card can be set up for a internal NHRC controller, external NHRC controller, 
or any other controller that can be attached to the DB9 female connector on the card.  The
PTT control switch allows the user to select &quot;local&quot or &quot;remote&quot; PTT, 
or disable PTT, based on requirements.  User-installed straps allow the electrical
configuration of the 10 pin molex connector or DB9. 
In most cases, a repeater station will require no modification at all.
Base stations may require that straps on the 10 volt regulator card be moved.
</blockquote>
    </td>
    <td align=center valign=middle>
      <a href="nhrc-m2sc-image.php">
	<img src="card-bare-small.jpg" width=340 height=240 alt="[Picture of NHRC-M2/SC]" border=0>
      </a>
      <br>
      NHRC-M2/SC Bare Board
      <p>
      <a href="nhrc-m2sc-image.php">
	<img src="card-external-jack-small.jpg" width=340 height=240 alt="[Picture of NHRC-M2/SC]" border=0>
      </a>
      <br>
      NHRC-M2/SC Configured for External Controller<br>
      <font size=2>(shown with user-supplied high-pass filter components installed.)</font>
      <p>
      <a href="nhrc-m2sc-image.php">
        <img src="card-with-4mvp-small.jpg" width=340 height=240 alt="[Picture of NHRC-M2/SC]" border=0>
      </a>
      <br>
      NHRC-M2/SC Card with NHRC-4/MVP repeater controller installed<br>
      <font size=2>(shown with user-supplied high-pass filter components installed.)</font><br>
      (click on either image for a larger view.)
    </td>	
  </tr>
</table>
<p>
<div class="productFeatures">Documentation:</div>
<ul>
  <li><a href="NHRC-M2SC_Manual.pdf">NHRC-M2/SC Manual for Rev B boards</a>
      <img src="/resources/pdficonsmall.gif" width=22 height=24 border=0 alt="PDF icon"> (~123KB)
  <li><a href="NHRC-M2SC_Manual_Rev_C.pdf">NHRC-M2/SC Manual for Rev C boards</a>
      <img src="/resources/pdficonsmall.gif" width=22 height=24 border=0 alt="PDF icon"> (~28KB)
</ul>
<div class="productFeatures">Pricing:</div>
<blockquote>
  <table border=0 cellspacing=2>
    <tr>
      <td bgcolor=#00ffcc valign=top>NHRC-M2/SC</td>
      <td bgcolor=#00ffcc>MASTR II Station Interface Card</td>
      <td bgcolor=#00ffcc align=right valign=top>$59.00</td>
    </tr>
    <tr>
      <td bgcolor=#00ccff valign=top>Shipping &amp; Handling</td>
      <td bgcolor=#00ccff>&nbsp;</td>
      <td bgcolor=#00ccff align=right valign=top>see <a href="/shipping.php">Shipping Info</a></td>
    </tr>
  </table>
</blockquote>
<?php include '../footer.inc'; ?>
