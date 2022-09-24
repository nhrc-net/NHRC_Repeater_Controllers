<?php 
$title = "File Not Found";
$category = "";
$item = "";
$version = "3.01";
$copydate = "1999-2006";
// map old page names to new...
$fixmap['/about.html'] = '/about.php';
$fixmap['/about.shtml'] = '/about.php';
$fixmap['/controllers.shtml'] = '/controllers.php';
$fixmap['/ge-stuff.shtml'] = '/ge-stuff.php';
$fixmap['/index.shtml'] = '/index.php';
$fixmap['/mastr2/align-low.shtml'] = '/mastr2/align-low.php';
$fixmap['/mastr2/align-uhf.shtml'] = '/mastr2/align-uhf.php';
$fixmap['/mastr2/align-vhf.shtml'] = '/mastr2/align-vhf.php';
$fixmap['/mastr2/choosing.shtml'] = '/mastr2/choosing.php';
$fixmap['/mastr2/duplexing.shtml'] = '/mastr2/duplexing.php';
$fixmap['/mastr2/index.html'] = '/mastr2/index.php';
$fixmap['/mastr2/index.shtml'] = '/mastr2/index.php';
$fixmap['/mastr2/mastr-pro-220-mods.shtml'] = '/mastr2/mastr-pro-220-mods.php';
$fixmap['/nhrc/'] = '/index.php';
$fixmap['/nhrc2/'] = '/nhrc-2/index.php';
$fixmap['/nhrc2/index.shtml'] = '/nhrc-2/index.php';
$fixmap['/nhrc2/rptr.asm'] = '/nhrc-2/rptr.asm';
$fixmap['/nhrc3/'] = '/nhrc-3/index.php';
$fixmap['/nhrc3m2/'] = '/nhrc-3m2/index.php';
$fixmap['/nhrc3m2/index.html'] = '/nhrc-3m2plus/index.php';
$fixmap['/nhrc3m2/index.shtml'] = '/nhrc-3m2plus/index.php';
$fixmap['/nhrc4/'] = '/nhrc-4/index.php';
$fixmap['/nhrc4/index.shtml'] = '/nhrc-4/index.php';
$fixmap['/nhrc-2/index.shtml'] = '/nhrc-2/index.php';
$fixmap['/nhrc-3/index.shtml'] = '/nhrc-3/index.php';
$fixmap['/nhrc-3plus/index.shtml'] = '/nhrc-3plus/index.php';
$fixmap['/nhrc-4/index.shtml'] = '/nhrc-4/index.php';
$fixmap['/nhrc-4m2/index.shtml'] = '/nhrc-4m2/index.php';
$fixmap['/nhrc-4mvp/index.shtml'] = '/nhrc-4mvp/index.php';
$fixmap['/nhrc-vsq/index.shtml'] = '/nhrc-vsq/index.php';
$fixmap['/nhrc-squelch/index.shtml'] = '/nhrc-squelch/index.php';
$reqpage =  $_SERVER['REQUEST_URI'];
$newpage = $fixmap[$reqpage];
$referer = $_SERVER['HTTP_REFERER'];
if ($referer == "")
{
    $referer = "unknown referer";
}
if (($newpage != "") && ($newpage != $reqpage))
{
    header("Location: http://" . $_SERVER['HTTP_HOST'] . $newpage);
}
else
{
include "header.inc";
?>
<font size=6 face="Helvetica" color="red"><b>File Not Found</b></font><p>
<font size=4 face="Helvetica"><b>The requested file
(</b><?php echo $_SERVER['REQUEST_URI']; ?><b>) was not found on this server.</b></font><p>
<font face="Helvetica">
You have tried to reach a web page that is not on the<b>
<?php echo $_SERVER['SERVER_NAME']; ?></b> web server.<p>
If you got to this page by typing in a URL, make sure the punctuation and
capitalization is correct.<p>
If you found a &quot;dead link&quot;, please let us know about it by clicking 
<script language="javascript">
mto = "\155\x61\u0069\x6c\164\x6f\u003a"
addr = "\x77\x65\x62\u0040\156\150\162\143\u002e\156\145\164"
document.writeln('<a href="'+mto+addr+'?subject=404 error: <?php echo $reqpage . " from " . $referer; ?>">here</a>')
</script>
to email the webmaster.
<p>
Click <a href="/">here</a> for our home page.<p>
</font>
<?php 
include 'footer.inc';
}
?>