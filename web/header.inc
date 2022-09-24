<?php
header("Content-type: text/html; charset=utf-8");
echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
echo "<html itemscope itemtype=\"http://schema.org/Organization\">\n";
echo "<head>\n";
echo "<!-- www.nhrc.net website content and design copyright (C) 2001-2011 NHRC LLC.  All Rights Reserved.  -->\n";
echo "<title>$title</title>\n";
echo "<meta name=\"viewport\" content=\"width=device-width, initial-scale=0.75\">\n";
if ($description != "") {
  echo "<meta name=\"description\" content=\"$description\">\n";
}
if ($keywords != "") {
  echo "<meta name=\"keywords\" content=\"$keywords\">\n";
}
echo "<link REL=\"SHORTCUT ICON\" HREF=\"/favicon.ico\">\n";
echo "<link rel=\"stylesheet\" href=\"/resources/nhrc-web-style.css\" type=\"text/css\">\n";
?>
<link href="https://plus.google.com/114537319830187621811" rel="publisher" />
<!-- Add the following three tags inside head -->
<meta itemprop="name" content="NHRC Repeater Controllers">
<meta itemprop="description" content="NHRC Repeater Controllers">

<!-- Google Analytics -->
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-122442-1', 'auto');
  ga('require', 'displayfeatures');
  ga('send', 'pageview');
</script>
<!-- end Google Analytics -->

</head>
<body>
<?php
//category company
//index news about contact warranty mailinglist
$categories[] = 'company';
$catpages['company'] = array('index', 'news', 'about', 'history', 'warranty', 'mailinglist');
$pages['company']['index'] = '/index.php';
$pages['company']['news'] = '/news.php';
$pages['company']['about'] = '/about.php';
$pages['company']['history'] = '/history.php';
$pages['company']['warranty'] = '/warranty.php';
$pages['company']['mailinglist'] = '/mailinglist.php';
$pageTitles['company']['index'] = 'Company Info';
$pageTitles['company']['news'] = 'News';
$pageTitles['company']['about'] = 'About NHRC';
$pageTitles['company']['history'] = 'NHRC History';
$pageTitles['company']['warranty'] = 'Our Warranty';
$pageTitles['company']['mailinglist'] = 'NHRC-User email list';
// category controllers.
// controllers comparison micro nhrc-2 nhrc-3+ nhrc-4 nhrc-6 nhrc-7
$categories[] = 'controllers';
$catpages['controllers'] = array('overview', 'comparison', 'micro', 'nhrc2.1', 'nhrc3.1', 'nhrc4', 'nhrc7');
$pages['controllers']['overview'] = '/controllers.php';
$pages['controllers']['comparison'] = '/comparison.php';
$pages['controllers']['micro'] = '/nhrc-micro/';
$pages['controllers']['nhrc2.1'] = '/nhrc-2.1/';
$pages['controllers']['nhrc3.1'] = '/nhrc-3.1/';
$pages['controllers']['nhrc4'] = '/nhrc-4/';
$pages['controllers']['nhrc7'] = '/nhrc-7/';
$pageTitles['controllers']['overview'] = 'Controllers';
$pageTitles['controllers']['comparison'] = 'Comparison';
$pageTitles['controllers']['micro'] = 'NHRC-&mu; (&quot;micro&quot;)';
$pageTitles['controllers']['nhrc2.1'] = 'NHRC-2.1';
$pageTitles['controllers']['nhrc3.1'] = 'NHRC-3.1';
$pageTitles['controllers']['nhrc4'] = 'NHRC-4';
$pageTitles['controllers']['nhrc7'] = 'NHRC-7';
$pageTitles['controllers']['nhrc10'] = 'NHRC-10';
//---------------------------------------------
// category ge
// ge-stuff nhrc3m2 nhrc4m2 nhrc4mvp nhrc-vsq
$categories[] = 'ge';
$catpages['ge'] = array('ge', 'nhrc4m2', 'nhrc-vsq', 'nhrc-m2sc');
$pages['ge']['ge'] = '/ge-stuff.php';
$pages['ge']['nhrc4m2'] = '/nhrc-4m2/';
$pages['ge']['nhrc-vsq'] = '/nhrc-vsq/';
$pages['ge']['nhrc-m2sc'] = '/nhrc-m2sc/';
$pageTitles['ge']['ge'] = 'Controllers for GE';
$pageTitles['ge']['nhrc4m2'] = 'NHRC-4/M2';
$pageTitles['ge']['nhrc-vsq'] = 'NHRC-VSQ';
$pageTitles['ge']['nhrc-m2sc'] = 'NHRC-M2SC';
//---------------------------------------------
// category DTMF
// ge-stuff nhrc3m2 nhrc4m2 nhrc4mvp nhrc-vsq
$categories[] = 'dtmf';
$catpages['dtmf'] = array('dtmf', 'nhrc-remote-plus');
$pageTitles['dtmf']['dtmf'] = 'DTMF Control';
$pageTitles['dtmf']['nhrc-remote-plus'] = 'NHRC-Remote+';
$pages['dtmf']['dtmf'] = '/nhrc-remote-plus/index.php';
$pages['dtmf']['nhrc-remote-plus'] = '/nhrc-remote-plus/';
//-----------------------------------------------
// category i14y
// interoperability nhrc7
$categories[] = 'i14y';
$catpages['i14y'] = array('interoperability', 'nhrc7');
$pages['i14y']['interoperability'] = '/interoperability.php';
$pages['i14y']['nhrc7'] = '/nhrc-7/index-i14y.php';
$pageTitles['i14y']['interoperability'] = 'Interoperability';
$pageTitles['i14y']['nhrc7'] = 'NHRC-7';
//-----------------------------------------------
// category accessories
// accessories nhrc-dad nhrc-remote nhrc-squelch
$categories[] = 'accessories';
$catpages['accessories'] = array('accessories', 'nhrc-dad-2', 'nhrc-remote-plus', 'nhrc-squelch', 'nhrc-vox');
$pages['accessories']['accessories'] = '/accessories.php';
$pages['accessories']['nhrc-dad-2'] = '/nhrc-dad-2/';
$pages['accessories']['nhrc-remote-plus'] = '/nhrc-remote-plus/';
$pages['accessories']['nhrc-squelch'] = '/nhrc-squelch/';
$pages['accessories']['nhrc-vox'] = '/nhrc-vox/';
$pageTitles['accessories']['accessories'] = 'Accessories';
$pageTitles['accessories']['nhrc-dad-2'] = 'NHRC-DAD-2';
$pageTitles['accessories']['nhrc-remote-plus'] = 'NHRC-Remote+';
$pageTitles['accessories']['nhrc-squelch'] = 'NHRC-Squelch';
$pageTitles['accessories']['nhrc-vox'] = 'NHRC-VOX';
// appnotes category
// appnotes
$categories[] = 'appnotes';
$catpages['appnotes'] = array('appnotes');
$pages['appnotes']['appnotes'] = '/appnotes/';
$pageTitles['appnotes']['appnotes'] = 'Application Notes';
// other category
// olddocs
$categories[] = 'obsolete';
$catpages['obsolete'] = array('olddocs');
$pages['obsolete']['olddocs'] = '/obsolete-manuals/';
$pageTitles['obsolete']['olddocs'] = 'Obsolete Manuals';
// retired category
// retired nhrc3
$categories[] = 'retired';
$catpages['retired'] = array('retired', 'nhrc2', 'nhrc3', 'nhrc3plus', 'nhrc3m2', 'nhrc3m2plus', 'nhrc4mvp', 'nhrc5', 'nhrc6', 'nhrc-remote', 'nhrc10', 'nhrc-dad', 'nhrc-pxp', 'cables');
$pages['retired']['retired'] = '/retired.php';
$pages['retired']['nhrc2'] = '/nhrc-2/';
$pages['retired']['nhrc3'] = '/nhrc-3/';
$pages['retired']['nhrc3plus'] = '/nhrc-3plus/';
$pages['retired']['nhrc3m2'] = '/nhrc-3m2/';
$pages['retired']['nhrc3m2plus'] = '/nhrc-3m2plus/';
$pages['retired']['nhrc4mvp'] = '/nhrc-4mvp/';
$pages['retired']['nhrc5'] = '/nhrc-5/';
$pages['retired']['nhrc6'] = '/nhrc-6/';
$pages['retired']['nhrc-remote'] = '/nhrc-remote/';
$pages['retired']['nhrc10'] = '/nhrc-10/';
$pages['retired']['nhrc-dad'] = '/nhrc-dad/';
$pages['retired']['nhrc-pxp'] = '/nhrc-pxp/';
$pages['retired']['cables'] = '/cables/';
$pageTitles['retired']['retired'] = 'Retired Products';
$pageTitles['retired']['nhrc2'] = 'NHRC-2';
$pageTitles['retired']['nhrc3'] = 'NHRC-3';
$pageTitles['retired']['nhrc3plus'] = 'NHRC-3+';
$pageTitles['retired']['nhrc3m2'] = 'NHRC-3/M2';
$pageTitles['retired']['nhrc3m2plus'] = 'NHRC-3/M2+';
$pageTitles['retired']['nhrc4mvp'] = 'NHRC-4/MVP';
$pageTitles['retired']['nhrc5'] = 'NHRC-5';
$pageTitles['retired']['nhrc6'] = 'NHRC-6';
$pageTitles['retired']['nhrc-remote'] = 'NHRC-Remote';
$pageTitles['retired']['nhrc10'] = 'NHRC-10';
$pageTitles['retired']['nhrc-dad'] = 'NHRC-DAD';
$pageTitles['retired']['nhrc-pxp'] = 'NHRC-PXP';
$pageTitles['retired']['cables'] = 'Cables';
// ordering category
// ordering shipping
$categories[] = 'ordering';
$catpages['ordering'] = array('ordering', 'shipping');
$pages['ordering']['ordering'] = '/ordering.php';
$pages['ordering']['shipping'] = '/shipping.php';
$pageTitles['ordering']['ordering'] = 'Ordering';
$pageTitles['ordering']['shipping'] = 'Shipping Information';
// mastr2 category
// m2index choosing conbination duplexing alignment align-low align-vhf align-uhf crossbanding cyrstals
$categories[] = 'mastr2';
$catpages['mastr2'] = array('m2index', 'choosing', 'combination', 'duplexing', 'alignment', 'align-low', 'align-vhf', 'align-uhf', 'crossbanding', 'crystals');
$pages['mastr2']['m2index'] = '/mastr2/';
$pages['mastr2']['choosing'] = '/mastr2/choosing.php';
$pages['mastr2']['combination'] = '/mastr2/combination.php';
$pages['mastr2']['duplexing'] = '/mastr2/duplexing.php';
$pages['mastr2']['alignment'] = '/mastr2/alignment.php';
$pages['mastr2']['align-low'] = '/mastr2/align-low.php';
$pages['mastr2']['align-vhf'] = '/mastr2/align-vhf.php';
$pages['mastr2']['align-uhf'] = '/mastr2/align-uhf.php';
$pages['mastr2']['crossbanding'] = '/mastr2/crossbanding.php';
$pages['mastr2']['crystals'] = '/mastr2/crystal-calculations.php';
$pageTitles['mastr2']['m2index'] = 'MASTR II InfoSite';
$pageTitles['mastr2']['choosing'] = 'Choosing a Radio';
$pageTitles['mastr2']['combination'] = 'Combinations';
$pageTitles['mastr2']['duplexing'] = 'Duplexing';
$pageTitles['mastr2']['alignment'] = 'Alignment';
$pageTitles['mastr2']['align-low'] = 'Low Band Alignment';
$pageTitles['mastr2']['align-vhf'] = 'VHF Alignment';
$pageTitles['mastr2']['align-uhf'] = 'UHF Alignment';
$pageTitles['mastr2']['crossbanding'] = 'Crossbanding';
$pageTitles['mastr2']['crystals'] = 'Crystal Frequencies';
// links category
// links
$categories[] = 'links';
$catpages['links'] = array('links');
$pages['links']['links'] = '/links.php';
$pageTitles['links']['links'] = 'Links';
// legal category
// legalnotice
$categories[] = 'legal';
$catpages['legal'] = array('legal');
$pages['legal']['legal'] = '/legal-notice.php';
$pageTitles['legal']['legal'] = 'Legal Notice';
//
// contact
$categories[] = 'contact';
$catpages['contact'] = array('contact');
$pages['contact']['contact'] = '/contact.php';
$pageTitles['contact']['contact'] = 'Contact NHRC';
?>
<table class="borderlessTable" width="100%">
  <tr>
    <td class="borderlessTableCell" align="left" valign="top">
    <a href="/"><img src="/resources/logo-white-on-navy.gif" width=314 height=72 border=0 alt="[NHRC REPEATER CONTROLLERS]"></a>
    </td>
    <td align="right" valign="top">
    <?php include "random-banner.inc"; ?>
    </td>
  </tr>
</table>
<!-- main body -->
<table class="borderlessTable" width="100%">
  <tr>
    <td valign=top width=190>
<?php
foreach($categories as $cat)
{
    if ($category == $cat)
    {  // this category is selected
        foreach($catpages[$cat] as $catpage)
        {
            if ($catpage == $catpages[$cat][0])
            { // this is the overview page
                if ($item == $catpage)
                { // this page is current.
                    echo '<div class="majorNavSelected"><img src="/resources/majornavselected.gif" width=12 height=12 alt="*">';
                    echo $pageTitles[$cat][$catpage];
                    echo "</div>\n";
                } // if item == catpage
                else
                { // not the current page.
                    echo '<div class="majorNav"><img src="/resources/majornavunselected.gif" width=12 height=12 alt=" "><a href="';
                    echo $pages[$cat][$catpage];
                    echo '">';
                    echo $pageTitles[$cat][$catpage];
                    echo "</a></div>\n";
                } // if item == catpage
            } // if firsttime
            else
            {
                if ($item == $catpage)
                { // this page is current.
                    echo '<div class="minorNavSelected"><img src="/resources/minornavselected.gif" width=12 height=12 alt="o">';
                    echo $pageTitles[$cat][$catpage];
                    echo "</div>\n";
                } // if item == catpage
                else
                { // not the current page.
                    echo '<div class="minorNav"><img src="/resources/minornavunselected.gif" width=12 height=12 alt=" "><a href="';
                    echo $pages[$cat][$catpage];
                    echo '">';
                    echo $pageTitles[$cat][$catpage];
                    echo "</a></div>\n";
                } // if item == catpage
            } // if catpage...
        } // foreach catpages
    } // if $category == $cat
    else
    { // this category is not selected
        echo '<div class="majorNav"><img src="/resources/majornavunselected.gif" width=12 height=12 alt=" "><a href="';
        echo $pages[$cat][$catpages[$cat][0]];
        echo '">';
        echo $pageTitles[$cat][$catpages[$cat][0]];
        echo "</a></div>\n";
    } // if $category == $cat
} // foreach categories
?>
<!-- google search -->
	<p>
<table border=0 cellspacing=5><tr><td align="center" bgcolor="white">
<font size=2>Search Site with Google</font><br>
<form method="get" action="http://www.google.com/search">
<input type="text" name="q" size="20" maxlength="255" value="">
<input type="submit" value="Search">
<input type="hidden" name="sitesearch" value="nhrc.net">
</form>
</td></tr></table>
<!-- end google search -->
    </td>
    <td valign="top" bgcolor="white">
    <table cellpadding=6 width="100%">
      <tr>
        <td bgcolor=white>
