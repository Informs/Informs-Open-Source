#!/home/zzintadm/perl/bin/perl 

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = $year + 1900;
$month = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];

$username = "zzintadm";
$password = "1ydf0rd";

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

<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Intute Informs</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />
<meta name="resource-type" content="document" />
<meta name="distribution" content="GLOBAL" />
<meta name="description" content="Informs is a flexible adaptive tool for the creation of interactive online tutorials. It consists of easy to use software and a database of tutorials for the UK HE and FE community." />
<meta name="copyright" content="Intute 2006 - 2008" />
<meta name="keywords" content="internet; tutorials; free; education; research; teaching; UK; higher education; further education" />
<meta name="author" content="intute" />
<meta http-equiv="content-language" content="en" />
<link rel="stylesheet" href="http://www.informs.intute.ac.uk/intute.css" type="text/css" title="intute" />
</head>
<body>
<div class="container">
<div class="option2top">
<div class="option2topleft"><a href="/"><img src="http://www.informs.intute.ac.uk/gfx/intute_informs.jpg"
class="logo" alt="Informs logo" /></a></div>
<div class="option2topright">
<div class="headerlinks">
<ul>
<li><a href="http://www.intute.ac.uk/contact.html">Contacts</a></li>
<li><a href="http://www.intute.ac.uk/feedback.html">Help desk</a></li>
<li><a href="http://www.intute.ac.uk/policy.html">Policy</a></li>
<li><a href="http://www.intute.ac.uk/sitemap.html">Site map</a></li>
<li><a href="http://feedback.intute.ac.uk/userfeedback">Survey</a></li>
</ul>
</div>

<script type="text/javascript" >
	function jumpMenu() {
location=document.getElementById('quickjump').menu.options[document.getElementById('quickjump').menu.selectedIndex].value;
	}
</script>

<div class="quicklinks">
<form id="quickjump" action="">
<p>
<select name="menu"><option selected="selected" value="#">Quick links</option>
<option value="#" class="sectiontitle">Subject groups</option>
<option value="http://www.intute.ac.uk/artsandhumanities/"> - Arts and humanities</option>
<option value="http://www.intute.ac.uk/healthandlifesciences/"> - Health and life sciences</option>
<option value="http://www.intute.ac.uk/sciences/"> - Science, engineering and technology</option>
<option value="http://www.intute.ac.uk/socialsciences/"> - Social sciences</option>
<option value="#" class="sectiontitle">Main links</option>
<option value="http://www.intute.ac.uk"> - Intute home</option>
<option value="http://www.intute.ac.uk/services.html"> - A-Z of Services</option>
<option value="http://www.intute.ac.uk/about.html"> - About us</option>
<option value="http://www.intute.ac.uk/search.html"> - Advanced search</option>
<option value="http://www.intute.ac.uk/browse.html"> - Browse by subject</option>
<option value="http://www.intute.ac.uk/contact.html"> - Contacts</option>
<option value="http://www.intute.ac.uk/copyright.html"> - Copyright</option>
<option value="http://www.intute.ac.uk/feedback.html"> - Feedback / helpdesk</option>
<option value="http://www.intute.ac.uk/help.html"> - Help</option>
<option value="http://www.intute.ac.uk/latest.html"> - New resources</option>
<option value="http://www.intute.ac.uk/sitemap.html"> - Site map</option>
<option value="http://www.vts.intute.ac.uk/"> - Virtual Training Suite</option>
</select>
<a href="Javascript:jumpMenu()"><img src="http://www.informs.intute.ac.uk/gfx/submit.gif" alt="Go"
class="gobutton" /></a>
</p>
</form>
</div>
</div>
</div>

END_OF_HTML

}


sub sidebar {

print <<END_OF_HTML;
<div class="level2left">
<div class="option3">
<ul>
<li class="top">Informs</li>
<li><a href="http://www.informs.intute.ac.uk/about.html">About Informs</a></li>
<li><a href="http://www.informs.intute.ac.uk/informs_perl/login2.pl">Log in</a></li>
<li><a href="http://www.informs.intute.ac.uk/informshelp.html">Help and support</a></li>
<li><a href="http://www.informs.intute.ac.uk/informs_perl/jump.pl?277-5174">Informs example</a></li>
<li><a href="http://www.informs.intute.ac.uk/contact.html">Contact us</a></li>
<li><a href="http://www.informs.intute.ac.uk/forum/">User forum</a>
</li>
</ul>
</div>
</div>
<div class="level2right">
END_OF_HTML
}

sub footer {

print <<END_OF_HTML;
<br />
<div class="footer">
<ul>
<li><a href="http://www.intute.ac.uk/copyright.html">Copyright &copy; 2006-2008</a></li>
<li><a href="http://www.intute.ac.uk/terms.html">Terms of use</a></li>
<li><a href="http://www.intute.ac.uk/privacy.html">Privacy policy</a></li>
<li><a href="http://www.intute.ac.uk/accessibility.html">Accessibility</a></li>
</ul>
<br />


<a href="http://www.manchester.ac.uk/"><img src="http://www.informs.intute.ac.uk/gfx/logo-uom.gif"
alt="University of Manchester logo" width="130" height="55"
class="unbordered" /></a>

<a href="http://www.mimas.ac.uk/"><img src="http://www.informs.intute.ac.uk/gfx/mimas-logo.gif"
alt="Mimas logo" width="176" height="36" class="unbordered" /></a>

<a href="http://www.jisc.ac.uk/"><img src="http://www.informs.intute.ac.uk/gfx/jisc.gif"
alt="JISC logo" class="unbordered" width="99" height="52" /></a>


</div>
END_OF_HTML

}

