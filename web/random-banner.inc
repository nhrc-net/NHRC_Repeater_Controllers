<?php
//$banners[] = '<a href="/nhrc-3m2/"><img src="/bnrs/3m2banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
//$banners[] = '<a href="/nhrc-3m2plus/"><img src="/bnrs/nhrc-3m2-plus-banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
$banners[] = '<a href="/nhrc-4m2/"><img src="/bnrs/4m2banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
$banners[] = '<a href="/nhrc-vsq/"><img src="/bnrs/vsqbanner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
//$banners[] = '<a href="/nhrc-5/"><img src="/bnrs/nhrc5banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
//$banners[] = '<a href="/nhrc-10/"><img src="/bnrs/nhrc10banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
//$banners[] = '<a href="/nhrc-10/"><img src="/bnrs/nhrc-10-banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
//$banners[] = '<a href="/nhrc-remote/"><img src="/bnrs/remotebanner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
$banners[] = '<a href="/nhrc-remote-plus/"><img src="/bnrs/nhrc-remote-plus-banner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
$banners[] = '<a href="/nhrc-squelch/"><img src="/bnrs/squelchbanner.gif" width=432 height=72 border=0 alt="Click Me!"></a>';
//$banners[] = '<a href="http://www.qsl.net/k1rqg"><img src="/bnrs/hosstraders-banner.gif" width=432 height=72 border=0 alt="Hosstraders Banner Ad -- Click Me!"></a>';
echo '<font color="red">';
echo $banners[rand(0, count($banners) - 1)];
echo '</font>';
?>
