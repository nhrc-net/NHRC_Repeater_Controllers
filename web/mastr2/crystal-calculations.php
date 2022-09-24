<?php
$title = "NHRC MASTR II InfoSite -- Crystal Frequency Calculations";
$category = "mastr2";
$item = "crystals";
$description="GE MASTR II mobile radio conversions: Crystal Frequency Calculations.";
$keywords="MASTR II Crystal Calculations";
$version="1.21";
$copydate="1997-2004";
include "../header.inc";
?>
<div align=center>
<font size=5><b>MASTR II Crystal Frequency Calculations</b></font>
</div>
<p>
These charts are intended to let you calculate your crystal frequency yourself,
should you desire to.  Otherwise, if you call a crystal vendor, like Bomar
Crystal, International Crystal Manufacturing, Jan Crystal, Marden, etc., you
can simply give them the part number of the channel element (PL19A129393G<i>some letter</i>), the frequency you want, and whether it is for transmit or receive,
and they will do the calculations and mail you the crystals.  This way, if there
should be a problem with the crystal frequency, it's their problem, not yours.
<p>
<div align=center>
<table border>
  <tr><TH colspan=2>MASTR II IF Frequencies</th></tr>
  <tr><th>Split(s)</th><th>IF<BR>Frequency</th></tr>
  <tr><td>25-30</td><td>11.2 MHz</td></tr>
  <tr><td>30-36</td><td>9.4 MHz</td></tr>
  <tr><td>36-42</td><td>11.2 MHz</td></tr>
  <tr><td>42-50</td><td>9.4 MHz</td></tr>
  <tr><td>138-174</td><td>11.2 MHz</td></tr>
  <tr><td>406-420</td><td>11.2 MHz</td></tr>
  <tr><td>450-512</td><td>11.2 MHz</td></tr>
</table>
</div>
<p>
<div align=center>
<table border>
  <tr>
    <td> </td>
    <th>Transmit<br>Crystal<br>Frequency</th>
    <th>Receive<br>Crystal<br>Frequency</th>
  </tr>
  <tr>
    <th>Low Band</th>
    <td>F<sub>TX</sub> / 3</td>
    <td>(F<sub>RX</sub> + IF) / 3</td>
  </tr>
  <tr>
    <th>VHF</th>
    <td>F<sub>TX</sub> / 12</td>
    <td>(F<sub>RX</sub> - IF) / 9</td>
  </tr>
  <tr>
    <th>UHF</th>
    <td>F<sub>TX</sub> / 36</td>
    <td>(F<sub>RX</sub> - IF) / 27</td>
  </tr>
</table>
</div>
<p>
<?php include '../footer.inc'; ?>
