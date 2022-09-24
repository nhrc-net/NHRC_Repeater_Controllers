<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
	<title>NHRC-2 Repeater Controller Quick Reference</title>
	<meta name="description" content="Quick Reference to the NHRC-2 Repeater Controller">
	<meta name="keywords" content="NHRC-2">
</head>
<body bgcolor=white>
<FONT SIZE=6><STRONG><center>NHRC-2 Repeater Controller Quick Reference</center></STRONG></FONT>
<HR>

<a name="Electrical Connections">
<center><table border>
<caption><b>Electrical Connections</b></caption>
<tr><th>Pin</th><th>Use</th></tr>
<tr><td>1</td><td>Ground</td></tr>
<tr><td>2</td><td>+13.8 Volts</td></tr>
<tr><td>3</td><td>PTT (active low)</td></tr>
<tr><td>4</td><td>TX Audio</td></tr>
<tr><td>5</td><td>RX Audio</td></tr>
<tr><td>6</td><td>CAS +</td></tr>
<tr><td>7</td><td>CAS -</td></tr>
<tr><td>8</td><td>Ground/TX Audio Return</td></tr>
<tr><td>9</td><td>Ground/RX Audio Return</td></tr>
</table></center></a>
<p>
<a name="Configuration Flag Bits">
<center><table border>
<caption><b>Configuration Flag Bits</b></caption>
<tr><th>Bit</th><th>Hex Weight</th><th>Feature</th></tr>
<tr><td>0</td><td>01</td><td>ISD Absent</td></tr>
<tr><td>1</td><td>02</td><td>Simplex repeater mode</td></tr>
<tr><td>2</td><td>04</td><td>n/a</td></tr>
<tr><td>3</td><td>08</td><td>n/a</td></tr>
<tr><td>4</td><td>10</td><td>suppress courtesy tone</td></tr>
<tr><td>5</td><td>20</td><td>suppress DTMF muting</td></tr>
<tr><td>6</td><td>40</td><td>use tail message for courtesy tone</td></tr>
<tr><td>7</td><td>80</td><td>n/a</td></tr>
</table></center></a>
<p>
<a name="Message Commands">
<center><table border>
<caption><b>Message Commands</b></caption>
<tr><th>Command</th><th>Description</th></tr>
<tr><td>400x</td><td>0 &lt;= x &lt;= 3, play CW message x</td></tr>
<tr><td>401x</td><td>0 &lt;= x &lt;= 3, play voice message x</td></tr>
<tr><td>410x</td><td>0 &lt;= x &lt;= 3, record voice message x</td></tr>
</table></center></a>
<p>
<a name="Message Contents">
<center><table border>
<caption><b>Message Contents</b></caption>
<tr><th>Message Number</th><th>Stored Voice</th><th>CW</th></tr>
<tr><td>0</td><td>Initial ID</td><td>ID message</td></tr>
<tr><td>1</td><td>Normal ID message</td><td>timeout message (&quot;TO&quot;)</td></tr>
<tr><td>2</td><td>Time-out Message</td><td>confirm message (&quot;OK&quot;)</td></tr>
<tr><td>3</td><td>Tail Message</td><td>invalid message (&quot;NG&quot;)</td></tr>
</table></center></a>
<p>
<a name="Programming Memory Map">
<center><table border>
<caption><b>Programming Memory Map</b></caption>
<tr><th>Address</th><th>Default Data</th><th>Comment</th></tr>
<tr><td>00</td><td>01</td><td>enable flag</td></tr>
<tr><td>01</td><td>00</td><td>configuration flags</td></tr>
<tr><td>02</td><td>32</td><td>hang timer preset, in tenths</td></tr>
<tr><td>03</td><td>1e</td><td>time-out timer preset, in seconds</td></tr>
<tr><td>04</td><td>36</td><td>id timer preset, in 10 seconds</td></tr>
<tr><td>05</td><td>00</td><td>tail message counter</td></tr>
<tr><td>06</td><td>0f</td><td>'O'    OK Message</td></tr>
<tr><td>07</td><td>0d</td><td>'K' </td></tr>
<tr><td>08</td><td>ff</td><td>EOM </td></tr>
<tr><td>09</td><td>05</td><td>'N'    NG Message</td></tr>
<tr><td>0a</td><td>0b</td><td>'G' </td></tr>
<tr><td>0b</td><td>ff</td><td>EOM </td></tr>
<tr><td>0c</td><td>03</td><td>'T'    TO Message</td></tr>
<tr><td>0d</td><td>0f</td><td>'O' </td></tr>
<tr><td>0e</td><td>ff</td><td>EOM </td></tr>
<tr><td>0f</td><td>09</td><td>'D'    CW ID starts here</td></tr>
<tr><td>10</td><td>02</td><td>'E'    </td></tr>
<tr><td>11</td><td>00</td><td>space  </td></tr>
<tr><td>12</td><td>05</td><td>'N'    </td></tr>
<tr><td>13</td><td>3e</td><td>'1'    </td></tr>
<tr><td>14</td><td>0d</td><td>'K'    </td></tr>
<tr><td>15</td><td>09</td><td>'D'    </td></tr>
<tr><td>16</td><td>0f</td><td>'O'    </td></tr>
<tr><td>17</td><td>29</td><td>'/'    </td></tr>
<tr><td>18</td><td>0a</td><td>'R'    </td></tr>
<tr><td>19</td><td>ff</td><td>EOM    </td></tr>
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
</table></center></a>
<p>
<a name="Morse Code Character Encoding">
<center><table border>
<caption><b>Morse Code Character Encoding</b></caption>
<tr><th>Character</th><th>Morse Code</th><th>Binary Encoding</th><th>Hex Encoding</th></tr>
<tr><td>sk</td><td>...-.-</td><td>01101000</td><td>68</td></tr>
<tr><td>ar</td><td>.-.-.</td><td>00101010</td><td>2a</td></tr>
<tr><td>bt</td><td>-...-</td><td>00110001</td><td>31</td></tr>
<tr><td>/</td><td>-..-.</td><td>00101001</td><td>29</td></tr>
<tr><td>0</td><td>-----</td><td>00111111</td><td>3f</td></tr>
<tr><td>1</td><td>.----</td><td>00111110</td><td>3e</td></tr>
<tr><td>2</td><td>..---</td><td>00111100</td><td>3c</td></tr>
<tr><td>3</td><td>...--</td><td>00111000</td><td>38</td></tr>
<tr><td>4</td><td>....-</td><td>00110000</td><td>30</td></tr>
<tr><td>5</td><td>.....</td><td>00100000</td><td>20</td></tr>
<tr><td>6</td><td>-....</td><td>00100001</td><td>21</td></tr>
<tr><td>7</td><td>--...</td><td>00100011</td><td>23</td></tr>
<tr><td>8</td><td>---..</td><td>00100111</td><td>27</td></tr>
<tr><td>9</td><td>----.</td><td>00101111</td><td>2f</td></tr>
<tr><td>a</td><td>.-</td><td>00000110</td><td>06</td></tr>
<tr><td>b</td><td>-...</td><td>00010001</td><td>11</td></tr>
<tr><td>c</td><td>-.-.</td><td>00010101</td><td>15</td></tr>
<tr><td>d</td><td>-..</td><td>00001001</td><td>09</td></tr>
<tr><td>e</td><td>.</td><td>00000010</td><td>02</td></tr>
<tr><td>f</td><td>..-.</td><td>00010100</td><td>14</td></tr>
<tr><td>g</td><td>--.</td><td>00001011</td><td>0b</td></tr>
<tr><td>h</td><td>....</td><td>00010000</td><td>10</td></tr>
<tr><td>i</td><td>..</td><td>00000100</td><td>04</td></tr>
<tr><td>j</td><td>.---</td><td>00011110</td><td>1e</td></tr>
<tr><td>k</td><td>-.-</td><td>00001101</td><td>0d</td></tr>
<tr><td>l</td><td>.-..</td><td>00010010</td><td>12</td></tr>
<tr><td>m</td><td>--</td><td>00000111</td><td>07</td></tr>
<tr><td>n</td><td>-.</td><td>00000101</td><td>05</td></tr>
<tr><td>o</td><td>---</td><td>00001111</td><td>0f</td></tr>
<tr><td>p</td><td>.--.</td><td>00010110</td><td>16</td></tr>
<tr><td>q</td><td>--.-</td><td>00011011</td><td>1b</td></tr>
<tr><td>r</td><td>.-.</td><td>00001010</td><td>0a</td></tr>
<tr><td>s</td><td>...</td><td>00001000</td><td>08</td></tr>
<tr><td>t</td><td>-</td><td>00000011</td><td>03</td></tr>
<tr><td>u</td><td>..-</td><td>00001100</td><td>0c</td></tr>
<tr><td>v</td><td>...-</td><td>00011000</td><td>18</td></tr>
<tr><td>w</td><td>.--</td><td>00001110</td><td>0e</td></tr>
<tr><td>x</td><td>-..-</td><td>00011001</td><td>19</td></tr>
<tr><td>y</td><td>-.--</td><td>00011101</td><td>1d</td></tr>
<tr><td>z</td><td>--..</td><td>00010011</td><td>13</td></tr>
<tr><td>space</td><td></td><td>00000000</td><td>00</td></tr>
<tr><td>EOM</td><td></td><td>11111111</td><td>ff</td></tr>
</table></center></a>
<hr>
<a href="index.php">NHRC-2 Repeater Controller Page</a>
<hr>
<?php
$copydate="1996-2005";
$version="1.21";
include '../barefooter.inc';
?>

