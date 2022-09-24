<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
               "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
	<title>NHRC-4 Repeater Controller Quick Reference</title>
	<meta name="description" content="Quick Reference to the NHRC-4 Repeater Controller">
	<meta name="keywords" content="NHRC-4">
</head>
<body bgcolor=white>
<div align=center>
<FONT SIZE=6><B>NHRC-4 Repeater Controller Quick Reference</B></FONT><br>
</div>
<HR>
<a name="Configuration Flag Bits">
<div align=center>
<table border>
<caption><b>Configuration Flag Bits</b></caption>
<tr><th>Bit</th><th>Hex<br>Weight</th><th>Binary<br>Value</th><th>Feature</th></tr>
<tr>
  <td align=center>0</td>
  <td align=center>01</td>
  <td>00000001</td>
  <td>secondary port is duplex repeater</td>
</tr>
<tr>
  <td align=center>1</td>
  <td align=center>02</td>
  <td>00000010</td>
  <td>audio delay on primary receiver</td>
</tr>
<tr>
  <td align=center>2</td>
  <td align=center>04</td>
  <td>00000100</td>
  <td>audio delay on secondary receiver</td>
</tr>
<tr>
  <td align=center>3</td>
  <td align=center>08</td>
  <td>00001000</td>
  <td>disable DTMF muting</td>
</tr>
<tr>
  <td align=center>4</td>
  <td align=center>10</td>
  <td>00010000</td>
  <td>digital output is fan control</td>
</tr>
<tr>
  <td align=center>5</td>
  <td align=center>20</td>
  <td>00100000</td>
  <td>main receiver has priority over link receiver<font color=red>*</font></td>
</tr>
<tr>
  <td align=center>6</td>
  <td align=center>40</td>
  <td>01000000</td>
  <td>drop main transmitter to mute DTMF<font color=red>**</font></td>
</tr>
<tr>
  <td align=center>7</td>
  <td align=center>80</td>
  <td>10000000</td>
  <td>drop secondary transmitter to mute DTMF<font color=red>**</font></td>
</tr>
</table>
<font color=red>*</font>Software version &gt;= 1.4 only.<br>
<font color=red>*</font>Software version &gt;= 2.2 only.
</div></a>
<p>
<a name="Message Commands">
<div align=center><table border>
<caption><b>Commands</b></caption>
<tr><th>Command</th><th>Description</th></tr>
<tr><td>400x</td><td>0 &lt;= x &lt;= 4, play CW message x</td></tr>
<tr><td>600x</td><td>0 &lt;= x &lt;= 7, clear (0) config bit x</td></tr>
<tr><td>610x</td><td>0 &lt;= x &lt;= 7, set (1) config bit x</td></tr>
</table></div></a>
<p>
<a name="Message Contents">
<div align=center>
<table border>
<caption><b>Message Contents</b></caption>
<tr><th>Message Number</th><th>Contents</th><th>Default</th></tr>
<tr><td>0</td><td>ID message</td><td>DE NHRC/4</td></tr>
<tr><td>1</td><td>primary receiver timeout message</td><td>TO</td></tr>
<tr><td>2</td><td>valid command confirm message</td><td>OK</td></tr>
<tr><td>3</td><td>invalid command message</td><td>NG</td></tr>
<tr><td>4</td><td>secondary receiver timeout message</td><td>RB TO</td></tr>
</table>
</div>
</a>
<p>
<a name="Programming Memory Map">
<div align=center>
<table border>
<caption><b>Programming Memory Map</b></caption>
<tr><th>Address</th><th>Default Data</th><th>Comment</th></tr>
<tr><td valign=top>00</td><td valign=top>01</td><td>enable flag<br>
                              00 Primary &amp; Secondary off<br>
                              01 Primary repeater enabled<br>
                              02 Primary enabled, secondary alert mode<br>
                              03 Primary enabled, secondary monitor mode<br>
                              04 Primary enabled, secondary transmit mode<br>
</td></tr>
<tr><td>01</td><td>10</td><td>Configuration Flags (see table)</td></tr>
<tr><td valign=top>02</td><td valign=top>00</td><td>Digital output control<br>
                              00 off<br>
                              01 on<br>
                              02 1/2 sec on pulse</td></tr>
<tr><td>03</td><td>32</td><td>Hang timer preset, in tenths</td></tr>
<tr><td>04</td><td>1e</td><td>Primary receiver timout timer, in seconds</td></tr>
<tr><td>05</td><td>1e</td><td>Secondary receiver timout timer, in seconds</td></tr>
<tr><td>06</td><td>36</td><td>id timer preset, in 10 seconds</td></tr>
<tr><td>07</td><td>00</td><td>fan timer, in 10 seconds</td></tr>
<tr><td>08</td><td>01</td><td>primary receiver courtesy tone</td></tr>
<tr><td>09</td><td>11</td><td>primary receiver courtesy tone<br>
                              secondary transmitter enabled</td></tr>
<tr><td>0a</td><td>31</td><td>primary receiver courtesy tone<br>
                              secondary receiver alert mode</td></tr>
<tr><td>0b</td><td>03</td><td>secondary receiver courtesy tone</td></tr>
<tr><td>0c</td><td>33</td><td>secondary receiver courtesy tone<br>
                              secondary transmitter enabled</td></tr>
<tr><td>0d</td><td>00</td><td>reserved</td></tr>
<tr><td>0e</td><td>0f</td><td>'O'    OK Message</td></tr>
<tr><td>0f</td><td>0d</td><td>'K' </td></tr>
<tr><td>10</td><td>ff</td><td>EOM </td></tr>
<tr><td>11</td><td>ff</td><td>EOM </td></tr>
<tr><td>12</td><td>ff</td><td>EOM </td></tr>
<tr><td>13</td><td>ff</td><td>EOM </td></tr>
<tr><td>14</td><td>05</td><td>'N'    NG Message</td></tr>
<tr><td>15</td><td>0b</td><td>'G' </td></tr>
<tr><td>16</td><td>ff</td><td>EOM </td></tr>
<tr><td>17</td><td>ff</td><td>EOM </td></tr>
<tr><td>18</td><td>ff</td><td>EOM </td></tr>
<tr><td>19</td><td>ff</td><td>EOM </td></tr>
<tr><td>1a</td><td>03</td><td>'T'    TO Message</td></tr>
<tr><td>1b</td><td>0f</td><td>'O' </td></tr>
<tr><td>1c</td><td>ff</td><td>EOM </td></tr>
<tr><td>1d</td><td>ff</td><td>EOM </td></tr>
<tr><td>1e</td><td>ff</td><td>EOM </td></tr>
<tr><td>1f</td><td>ff</td><td>EOM </td></tr>
<tr><td>20</td><td>0a</td><td>'R'    TO Message</td></tr>
<tr><td>21</td><td>22</td><td>'B' </td></tr>
<tr><td>22</td><td>00</td><td>' ' </td></tr>
<tr><td>23</td><td>03</td><td>'T' </td></tr>
<tr><td>24</td><td>0f</td><td>'O' </td></tr>
<tr><td>25</td><td>ff</td><td>EOM </td></tr>
<tr><td>26</td><td>09</td><td>'D'    CW ID starts here</td></tr>
<tr><td>27</td><td>02</td><td>'E'    </td></tr>
<tr><td>28</td><td>00</td><td>space  </td></tr>
<tr><td>29</td><td>05</td><td>'N'    </td></tr>
<tr><td>2a</td><td>10</td><td>'H'    </td></tr>
<tr><td>2b</td><td>0a</td><td>'R'    </td></tr>
<tr><td>2c</td><td>15</td><td>'C'    </td></tr>
<tr><td>2d</td><td>29</td><td>'/'    </td></tr>
<tr><td>2e</td><td>30</td><td>'4'    </td></tr>
<tr><td>2f</td><td>0a</td><td>EOM    </td></tr>
<tr><td>30</td><td>ff</td><td>EOM    </td></tr>
<tr><td>31</td><td>ff</td><td>EOM    </td></tr>
<tr><td>32</td><td>ff</td><td>EOM    </td></tr>
<tr><td>33</td><td>ff</td><td>EOM    </td></tr>
<tr><td>34</td><td>ff</td><td>EOM    </td></tr>
<tr><td>35</td><td>ff</td><td>EOM    </td></tr>
<tr><td>36</td><td>ff</td><td>EOM    </td></tr>
<tr><td>37</td><td>ff</td><td>EOM    </td></tr>
<tr><td>38</td><td>ff</td><td>EOM    </td></tr>
<tr><td>39</td><td>ff</td><td>EOM    </td></tr>
<tr><td>3a</td><td>ff</td><td>EOM  can fit 20 letter id</td></tr>
<tr><td>3b</td><td>ff</td><td>EOM  (safety)</td></tr>
</table>
</div>
</a>
<p>
<a name="Morse Code Character Encoding">
<div align=center>
<b>Morse Code Character Encoding</b>
<table cellspacing=10>
<tr><td align=left>
<table border=1>
<tr><th>Character</th><th>Morse<br>Code</th><th>Binary<br>Encoding</th><th>Hex<br>Encoding</th></tr>
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
</table></td><td align=right><table border>
<tr><th>Character</th><th>Morse<br>Code</th><th>Binary<br>Encoding</th><th>Hex<br>Encoding</th></tr>
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
</table>
</table>
</div>
</a>
<hr>
<a href="/nhrc-4/">NHRC-4 Repeater Controller Page</a><br>
<a href="/nhrc-4m2/">NHRC-4/M2 Repeater Controller Page</a><br>
<a href="/nhrc-4mvp/">NHRC-4/MVP Repeater Controller Page</a>
<hr>
<?php
$copydate="1997-2005";
$version="1.21";
include '../barefooter.inc';
?>
