#!/usr/bin/perl -wT

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
<meta name="description" content="Informs" />
<meta name="copyright" content="Informs 2011" />
<meta name="keywords" content="internet; resource; catalogue" />
<meta name="author" content="intute" />
<meta http-equiv="content-language" content="en" />
<title>Informs</title>
<link rel="stylesheet" type="text/css" media="screen" href="/SAMPLE.css" />
  	
</head>
<body>

<!--HEADER-->
<div id="header-container">
<div id="header" class="center">

</div>
</div>

<!--MAIN NAVIGATION-->
<div id="main-navigation-container">
<div id="main-navigation">

</div>
</div>

   		
<!--CONTENT CONTAINER-->
<div class="content-background">
<div class="content-container center">

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


<ul id="footer-logos">

</ul>

</div>
</div>

</body>
</html>

END_OF_HTML

}

