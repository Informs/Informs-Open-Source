#!/usr/bin/perl -wT

use strict;

use lib "./";

use Digest::MD5  qw(md5_hex);

use InhaleCore qw( :DEFAULT timeToRun untaint );
new InhaleCore();

use InhaleRead qw( validateUser getUserSession getAccountDetails getFolioDetails endSession getUserInfo );

require "confignew.pl";

##########
# various login / authentification scripts
# needs a lot lot more work!!!
###

use vars qw( $phrase );

$phrase = (localtime)[7];

my $action = $cgi->{action};
$cgi->{folio} = $cgi->{folio} || '';


if(!(defined($action))) { $action = 'firstcheck'; }

if   ($action eq 'logout')       { logout(); }
elsif($action eq 'login')        { login("please enter your log in details..."); }
elsif($action eq 'checkcookie')  { checkcookie(); }
elsif($action eq 'authenticate') { authenticate(); }
else                             { firstcheck(); }

print "\n\n<!-- page generated in ".timeToRun()." seconds -->\n\n";

sub login {
    my($message) = @_;

    print InhaleCore::setCookie("informs", "");              ### clear any existing cookies

   # print $cgi->{header};

header();

print <<END1;

<div id="feedback" class="feedbackform">
<h1>Informs users log in below:</h1>
<form name="feedbackform" id="feedbackform" method="post" action="$user->{pathToCGI}login2.pl">

<label>log in ID:</label><input type="text" name="idname" size="20" value="" />
<label>password:</label><input type="password" name="password" size="20" value="" />
<label>save details</label><input type="checkbox" name="reopen" class="informsbox" />
<input type="hidden" name="action" value="authenticate" />
<input type="hidden" name="folio" value="$cgi->{folio}" />
<input type="submit" class="feedback-form-button" value="Log in" />
<div class="feedbackspacer"></div>
</form>
</div>
<div class="feedbackspacer"></div>

<div class="informsupdated">

</div>

END1

footer();
print <<END1;
</div>

</body>
</html>

END1
        
}
sub logout 
{
    endSession( session => $user->{userSession} );

    print InhaleCore::setCookie("informs", "");

    unless($cgi->{folio}) { $cgi->{folio} = '1'; }
    my $link = qq(<a href="$user->{pathToCGI}portfolio.pl?folio=$cgi->{folio}">click here</a>); 

    unless($cgi->{folio}) { $link = '<a href="javascript:history.back()">click here</a>'; }
    

    print $cgi->{header};
print <<END2;
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" >
<meta HTTP-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT">
<meta HTTP-equiv="Pragma" content="no-cache">
<meta HTTP-equiv="Cache-Control" content="no-cache">
<meta http-equiv="refresh" content="1;url=/informs_perl/login2.pl">
<title>Informs :: log out</title>
<link rel="stylesheet" href="$user->{pathHtmlVir}inhale.css" type="text/css">
</head><body>
<div class="container">
<div align="left">
<p><br><p>
Thank you for using Informs - you have now been logged out of your account and will be redirected to the Informs home page.<p>
</div></div>
</body></html>

END2

}

sub authenticate {
    my $id          = lc($cgi->{'idname'});
    my $password    = lc($cgi->{'password'});
    my $storecookie = lc($cgi->{'reopen'});
    my $cookie      = '';

    if( lc($storecookie) eq 'on' || $storecookie > 1 ) { $storecookie = 1 } else { $storecookie = 0 }

    my $session = validateUser( username => $id, password => $password, autologin => $storecookie );

    if( $session ) {
        my $digest = md5_hex($phrase.$id);
        my $server = $ENV{HTTP_HOST};
        
        if(defined($storecookie) && $storecookie ne '') {
            print InhaleCore::setCookie( "informs", $session, $storecookie );
        }
        else {
            print InhaleCore::setCookie( "informs", $session, $storecookie );
        }
        
        print $cgi->{header};
        print qq(<html><head>\n<script language="JavaScript">\n<!--\n);
        print qq(    window.location.href='$user->{pathToCGI}login2.pl?action=checkcookie&folio=$cgi->{folio}';\n);
        print qq(//--></script>\n);
        print qq(<noscript>\n);
        print qq(<META HTTP-EQUIV="Refresh" CONTENT="1;URL=$user->{pathToCGI}login2.pl?action=checkcookie&folio=$cgi->{folio}">\n);
        print qq(</noscript></head><body><a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$cgi->{folio}">please click here</a> if you are not re-directed after a few seconds...\n);
        print qq(</body></html>\n);    
    }
    else {
        login("sorry - unable to log you in with the details you entered...");
        my $time = localtime(time);

        my $message = qq(
BAD LOG IN ATTEMPT
==================
    IP: $ENV{REMOTE_ADDR}
  TIME: $time
  USER: $id
  PASS: $password
 AGENT: $ENV{HTTP_USER_AGENT}
 REFER: $ENV{HTTP_REFERER}
);

        open(OUT, ">>".untaint($user->{pathToData}."logs/badlogins.txt", 4));
        print OUT $message;
        close(OUT);
        exit;
    }
}

sub firstcheck {
    my $cookie = InhaleCore::readCookie('informs') || '';
    
    unless($cookie) {
        login("please enter your log in details...");
        exit;
    }

    my($id,$md5) = split(/\//,$cookie);
    my $digest = md5_hex($phrase.$id);
    if($md5 ne $digest) {
        login("sorry, your previous session has timed out - please log in again...");
        exit;
    } 
    unless($cgi->{folio}) { $cgi->{folio} = $user->{accountNumber}; }
    unless($cgi->{folio}) { $cgi->{folio} = '1'; }
    print "Location: $user->{pathToCGI}portfolio.pl?render=inhale&folio=$cgi->{folio}\n\n";
}

sub checkcookie {
    my $cookie = InhaleCore::readCookie('informs') || '';

    unless($cookie) {
        login("$ENV{HTTP_COOKIE} sorry - your browser does not seem to accepting cookies...");
        exit;
    }

    my $userNumber = getUserSession( session => $cookie );

    unless($cgi->{folio}) { $cgi->{folio} = $user->{accountNumber} || '1'; }
    my $link = qq($user->{pathToCGI}portfolio.pl?folio=$cgi->{folio});

    my %acc = getAccountDetails( user => $userNumber, session => $cookie ); 
    my $otherlink = '';
    
    print $cgi->{header};
    my @folios = split( /\:/, $user->{userPortfolioList} );


    foreach my $uFolio ( @folios )
    {
	if( $uFolio )
	{
	    my %uFolio = getFolioDetails( folio => $uFolio );
	    if( $uFolio{portfolioParent} )
	    {
		if( $user->{userType} eq 'superadmin' ) { next }
	        $otherlink .= qq(<tr><td><a href="portfolio.pl?folio=$uFolio">$uFolio{portfolioName}</a></td></tr>\n);
	    }
	    else
	    {
	        $otherlink .= qq(<tr><td><a href="portfolio.pl?folio=$uFolio"><b>$uFolio{portfolioName}</b></a></td></tr>\n);
	    }
	}
    }

print <<END3;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" />
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en" />
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />
<meta name="description" content="Informs is a flexible adaptive tool for the creation of interactive online tutorials. It consists of easy to use software and a database of tutorials for the UK HE and FE community." />
<meta name="keywords" content="internet; tutorials; free; education; research; teaching; UK; higher education; further education" />
<meta http-equiv="content-language" content="en" />
<meta http-equiv="pragma" content="no-cache" />
<script language="JavaScript">
<!--

//-->
</script>
<title>Informs</title>
<link rel="stylesheet" href="$user->{pathHtmlVir}SAMPLE.css" type="text/css" />
</head>
<body>
<div class="container">
<p class="login">Logged in as:<strong> $user->{userRealName}</strong></p>
<p class="opentext">Welcome to Informs.  Please select a portfolio from the list or <a href="login2.pl?action=logout&folio=$cgi->{folio}">log out</a>.</p>
<table class="front">
$otherlink
</table>
<br /><br /><br />
</div>
</body>
</html>

END3

}
