#!/home/zzintadm/perl/bin/perl

require "config.pl";

use DBI;
use POSIX;
use CGI;
my $q = new CGI;

my $title = $q->param('title') || "";
my $name = $q->param('name') || "";
my $email = $q->param('email') || "";
my $institution = $q->param('institution') || "";
my $message = $q->param('message') || "informs registration request";
my $subject = $q->param('subject') || "";
my $type = $q->param('type') || "";

$message =~ s/&//g;
$message =~ s/"//g;
$message =~ s/'//g;
$message =~ s/;//g;
$message =~ s/://g;

print <<END_OF_HTML;
Content-type: text/html

<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Informs Registration</title>

<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta name="resource-type" content="document" />
<meta name="distribution" content="GLOBAL" />
<meta name="description" content="Suggest a site" />
<meta name="copyright" content="Intute 2010" />
<meta name="keywords" content="internet; resource; catalogue" />
<meta name="author" content="Intute Informs" />
<meta http-equiv="content-language" content="en" />
<link rel="stylesheet" href="/intute.css" type="text/css" title="intute" />
END_OF_HTML

if ($message =~ /levitra|href|tits|viagra|cialis|[pP]hentermine|tramadol|xanax|\[url/i) {
print <<END_OF_HTML;
</head>
<body>
<p>Suspected spam - <a href="http://www.informs.intute.ac.uk/register.html">please try again</a>.</p>

END_OF_HTML

} else {
print <<END_OF_HTML;
<meta http-equiv="refresh"
content="1;url=http://remedy.manchester.ac.uk/cgi-bin/Intute/Intute.cgi?type=$type&name=$name&email=$email&title=$title&institution=$institution&message=$message&subject=$subject">
</head>
<body>
<p>
Your Informs registration request is being sent to the helpdesk ... 
</p>
END_OF_HTML
}

print <<END_OF_HTML;
</body>
</html>
END_OF_HTML

