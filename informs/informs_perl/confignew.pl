#!/home/intute/perl/bin/perl 

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = $year + 1900;
$month = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];

if ($hour < 10) {
$hour = "0$hour";
} else {
$hour = $hour;
}

if ($min < 10) {
$min = "0$min";
} else {
$min = $min;
}

if ($sec < 10) {
$sec = "0$sec";
} else {
$sec = $sec;
}

sub header {
print <<END_OF_HTML;
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="resource-type" content="document" />
<meta name="distribution" content="GLOBAL" />
<meta name="description" content="Intute Informs" />
<meta name="copyright" content="Intute 2009" />
<meta name="keywords" content="internet; resource; catalogue" />
<meta name="author" content="intute" />
<meta http-equiv="content-language" content="en" />
<title>Intute Informs</title>
<link rel="stylesheet" type="text/css" media="screen" href="/reset.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/intutenew.css" />
<link rel="stylesheet" type="text/css" media="print" href="/intute-print.css" />

   <!--[if IE]>
   	<link rel="stylesheet" href="/intute-ie.css" type="text/css">
   	<![endif]-->
   	
  	
</head>
<body>

<!--HEADER-->
<div id="header-container">
<div id="header" class="center">
<a href="http://www.intute.ac.uk/"><img src="http://www.informs.intute.ac.uk/intute-logo.gif"
border="0" alt="Intute" id="intute-logo" /></a>
<img src="http://www.informs.intute.ac.uk/tagline.gif" alt="The best of the web for education and
research" id="tagline" />
</div>
</div>

<!--MAIN NAVIGATION-->
<div id="main-navigation-container">
<div id="main-navigation">
<ul id="menu" class="center">
<li><a href="http://www.informs.intute.ac.uk/about.html">About
Informs</a></li>
<li><a href="http://www.informs.intute.ac.uk/informs_perl/login2.pl" class="link-on">Log
in</a></li>
<li><a href="http://www.informs.intute.ac.uk/informshelp.html">Help and
support</a></li>
<li><a href="http://www.informs.intute.ac.uk/contact.html">Contact
us</a></li>
</ul>
</div>
</div>

   		
<!--CONTENT CONTAINER-->
<div class="content-background">
<div class="content-container center">
           
                   <!--breadcrumbs-->
                           <p class="breadcrumbs smalltext"><a
href="http://www.intute.ac.uk">Home</a> &rsaquo; Informs</p>

END_OF_HTML

}

sub headerregister {
print <<END_OF_HTML;
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="resource-type" content="document" />
<meta name="distribution" content="GLOBAL" />
<meta name="description" content="Intute Informs" />
<meta name="copyright" content="Intute 2009" />
<meta name="keywords" content="internet; resource; catalogue" />
<meta name="author" content="intute" />
<meta http-equiv="content-language" content="en" />
<title>Intute Informs regsitered institutions</title>
<link rel="stylesheet" type="text/css" media="screen" href="/reset.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/intutenew.css" />
<link rel="stylesheet" type="text/css" media="print" href="/intute-print.css" />

   <!--[if IE]>
   	<link rel="stylesheet" href="/intute-ie.css" type="text/css">
   	<![endif]-->
   	
  	
</head>
<body>

<!--HEADER-->
<div id="header-container">
<div id="header" class="center">
<a href="http://www.intute.ac.uk/"><img src="http://www.informs.intute.ac.uk/intute-logo.gif"
border="0" alt="Intute" id="intute-logo" /></a>
<img src="http://www.informs.intute.ac.uk/tagline.gif" alt="The best of the web for education and
research" id="tagline" />
</div>
</div>

<!--MAIN NAVIGATION-->
<div id="main-navigation-container">
<div id="main-navigation">
<ul id="menu" class="center">
<li><a href="http://www.informs.intute.ac.uk/about.html">About
Informs</a></li>
<li><a href="http://www.informs.intute.ac.uk/informs_perl/login2.pl">Log
in</a></li>
<li><a href="http://www.informs.intute.ac.uk/informshelp.html">Help and
support</a></li>
<li><a href="http://www.informs.intute.ac.uk/contact.html">Contact
us</a></li>
<li><a href="http://www.informs.intute.ac.uk/forum/">User forum</a>
</li>
</ul>
</div>
</div>

   		
<!--CONTENT CONTAINER-->
<div class="content-background">
<div class="content-container center">
           
                   <!--breadcrumbs-->
                           <p class="breadcrumbs smalltext"><a
href="http://www.intute.ac.uk">Home</a> &rsaquo; Informs</p>

END_OF_HTML

}

sub headerhelp {
print <<END_OF_HTML;
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="resource-type" content="document" />
<meta name="distribution" content="GLOBAL" />
<meta name="description" content="Intute Informs" />
<meta name="copyright" content="Intute 2009" />
<meta name="keywords" content="internet; resource; catalogue" />
<meta name="author" content="intute" />
<meta http-equiv="content-language" content="en" />
<title>Intute Informs faq</title>
<link rel="stylesheet" type="text/css" media="screen" href="/reset.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/intutenew.css" />
<link rel="stylesheet" type="text/css" media="print" href="/intute-print.css" />

   <!--[if IE]>
   	<link rel="stylesheet" href="/intute-ie.css" type="text/css">
   	<![endif]-->
   	
  	
</head>
<body>

<!--HEADER-->
<div id="header-container">
<div id="header" class="center">
<a href="http://www.intute.ac.uk/"><img src="http://www.informs.intute.ac.uk/intute-logo.gif"
border="0" alt="Intute" id="intute-logo" /></a>
<img src="http://www.informs.intute.ac.uk/tagline.gif" alt="The best of the web for education and
research" id="tagline" />
</div>
</div>

<!--MAIN NAVIGATION-->
<div id="main-navigation-container">
<div id="main-navigation">
<ul id="menu" class="center">
<li><a href="http://www.informs.intute.ac.uk/about.html">About
Informs</a></li>
<li><a href="http://www.informs.intute.ac.uk/informs_perl/login2.pl">Log
in</a></li>
<li><a href="http://www.informs.intute.ac.uk/informshelp.html" class="link-on">Help and
support</a></li>
<li><a href="http://www.informs.intute.ac.uk/contact.html">Contact
us</a></li>
<li><a href="http://www.informs.intute.ac.uk/forum/">User forum</a>
</li>
</ul>
</div>
</div>

   		
<!--CONTENT CONTAINER-->
<div class="content-background">
<div class="content-container center">
           
                   <!--breadcrumbs-->
                           <p class="breadcrumbs smalltext"><a
href="http://www.intute.ac.uk">Home</a> &rsaquo; Informs</p>

END_OF_HTML

}

sub footer {

print <<END_OF_HTML;

</div>

<!--end of content-container-->

<!--important div to prevent IE guillotine bug-->
<div style="clear: both"></div>

  </div>
<!--end of content background-->
</div>
  
   <!--FOOTER-->


<div id="footer-container">
   <div id="footer" class="center smalltext">

<ul>
<li><a href="/copyright.html">Copyright 2006-2010</a></li>
<li>|</li>
<li><a href="/terms.html">Terms of use</a></li>
<li>|</li>
<li><a href="/privacy.html">Privacy policy</a></li>
<li>|</li>
<li><a href="/accessibility.html">Accessibility</a></li>
<li>|</li>
<li><a href="/sitemap.html">Sitemap</a></li>
</ul>

<ul id="footer-logos">
<li><a href="http://www.mimas.ac.uk/"><img
src="http://www.informs.intute.ac.uk/mimas-logo.gif" alt="MIMAS" /></a></li>
<li><a href="http://www.jisc.ac.uk/"><img
src="http://www.informs.intute.ac.uk/jisc-logo.gif" alt="Joint Information Systems Committee (JISC)" /></a></li>
</ul>

</div>
</div>





</body>
</html>

END_OF_HTML

}

sub headerfaq {
print <<END_OF_HTML;
Content-type: text/html

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="resource-type" content="document" />
<meta name="distribution" content="GLOBAL" />
<meta name="description" content="Intute Informs" />
<meta name="copyright" content="Intute 2009" />
<meta name="keywords" content="internet; resource; catalogue" />
<meta name="author" content="intute" />
<meta http-equiv="content-language" content="en" />
<title>Intute Informs faq</title>
<link rel="stylesheet" type="text/css" media="screen" href="/reset.css" />
<link rel="stylesheet" type="text/css" media="screen" href="/intutenew.css" />
<link rel="stylesheet" type="text/css" media="print" href="/intute-print.css" />

   <!--[if IE]>
   	<link rel="stylesheet" href="/intute-ie.css" type="text/css">
   	<![endif]-->
   	
  	
</head>
<body>

<!--HEADER-->
<div id="header-container">
<div id="header" class="center">
<a href="http://www.intute.ac.uk/"><img src="http://www.informs.intute.ac.uk/intute-logo.gif"
border="0" alt="Intute" id="intute-logo" /></a>
<img src="http://www.informs.intute.ac.uk/tagline.gif" alt="The best of the web for education and
research" id="tagline" />
</div>
</div>

<!--MAIN NAVIGATION-->
<div id="main-navigation-container">
<div id="main-navigation">
<ul id="menu" class="center">
<li><a href="http://www.informs.intute.ac.uk/about.html">About
Informs</a></li>
<li><a href="http://www.informs.intute.ac.uk/informs_perl/login2.pl">Log
in</a></li>
<li><a href="http://www.informs.intute.ac.uk/informshelp.html" class="link-on">Help and
support</a></li>
<li><a href="http://www.informs.intute.ac.uk/contact.html">Contact
us</a></li>
<li><a href="http://www.informs.intute.ac.uk/forum/">User forum</a>
</li>
</ul>
</div>
</div>

   		
<!--CONTENT CONTAINER-->
<div class="content-background">
<div class="content-container center">
           
                   <!--breadcrumbs-->
                           <p class="breadcrumbs smalltext"><a
href="http://www.intute.ac.uk">Home</a> &rsaquo; <a href="http://www.informs.intute.ac.uk">Informs</a> &rsaquo; <a
href="http://www.informs.intute.ac.uk/informs_perl/faqhead.pl">FAQ</a></p>

END_OF_HTML

}

