#!/home/zzintadm/perl/bin/perl -WT

use strict;
use lib "./";
use locale;

use InhaleCore qw( :DEFAULT );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw(  getFolioDetails  );
use InhaleWrite qw( updateUser updatePortfolio createPortfolio deletePortfolio );

    unless( $user->{userNumber} ) { deadParrot("access to this page is restricted to authorised users only"); }
    unless( $user->{userType} eq 'editor' || $user->{userType} eq 'admin' || $user->{userType} eq 'superadmin' ) { deadParrot("access to this page is restricted to authorised users only"); }


    my $folio   = $cgi->{folio}  || '1';
    my $action  = $cgi->{a}      || '';
    my $text    = $cgi->{text}   || '';
    my $text1   = $cgi->{text1}  || '';
    my $text2   = $cgi->{text2}  || '';

    unless( $user->{userPortfolioList} =~ /:$folio:/ )  { deadParrot("you do not have permissions to access the admin page for this portfolio!"); }

    print $cgi->{header};
    print pageHeader( );

    my %folioInfo = getFolioDetails( folio => $folio ); 

    if( $action eq 'changepassword' )
    {
	if( $text1 && $text1 == $text )
	{
	    updateUser( action => 'changepassword',
                             user => $user->{userNumber},
                             text => $text1 );
	    reload("the password was updated",$folio);
	}
	elsif( $text1 != $text2 )
	{
	    reload("error: the password was not changed - please enter the new password in both boxes",$folio);
	}
	else
	{
	    reload("error: the password was not changed - the password cannot be blank",$folio);
	}
    }

    if( $action eq 'changeemail' && $text ne $user->{userEmail} )
    {
	if( $text =~ /\@/ )
	{
	    updateUser( action => 'changeemail',
                             user => $user->{userNumber},
                             text => $text );
	    reload("the email address was updated",$folio);
	}
	else
	{
	    reload("error: the email address was not updated - please enter a valid address",$folio);
	}
    }

    if( $action eq 'changerealname' && $text ne $user->{userRealName} )
    {
	if( $text )
	{
	    updateUser( action => 'changerealname',
                             user => $user->{userNumber},
                             text => $text );
	    reload("your name was updated",$folio);
	}
	else
	{
	    reload("error: your name was not updated - it cannot be blank",$folio);
	}
    }


print qq(<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />);
print qq(<div id="breadcrumb">Intute Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a>  >  <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > editor</div>);

    print qq(<p /><br /><div style="padding:10px; padding-left:20px; padding-top:5px; border:1px solid #cccccc;">);

    print qq(<h2>Editor options for portfolio - ($folioInfo{portfolioName})</h2><p /><blockquote>);

    my($tm,$year) = (localtime)[4,5];
    $year += 1900;
    $tm++;

    my $ty = $year;
    $tm--;
    if( $tm == 0 ) { $tm = 12; $ty-- }

    print qq(<form action="stats2.pl" method="get" target="_blank">);
    print qq(1. download monthly usage statistics for this portfolio:<div class="ins">);
    print qq(<select name="a" class="fixed">);

    foreach my $y ( 2004 .. $year )
    {
	foreach my $m ( 1 .. 12 )
	{
	    my $mon = substr("JanFebMarAprMayJunJulAugSepOctNovDec", ($m*3)-3, 3);
	    if( $tm == $m && $ty == $y ) { print qq(<option value="$m:$y" selected>$mon $y</option>\n); }
 	    else { print qq(<option value="$m:$y">$mon $y</option>\n); }
	}
    }

    print qq(</select>);
    if( !$folioInfo{portfolioParent} && $folioInfo{portfolioChildren} )
    {
        print qq(<input type="checkbox" name="b" /> include all sub-portfolios);
    }
    print qq(<br /><input type="hidden" name="folio" value="$folio" /><input type="submit" value="download" class="submit"/> <span class="info">the stats file is in CSV (comma separated values) format</span>);
    print qq(</div></form>);

    print qq(</div>);

    print qq(<p /><br /><div style="padding:10px; padding-left:20px;padding-top:5px; border:1px solid #cccccc;">);
    print qq(<h2>Objects database</h2><p /><blockquote>);
    print qq(<p />1. <a href="insertobject.pl" target="_blank">upload new object</a> into the database);
    if( $folioInfo{portfolioAccount} != $user->{userAccountNumber} )
    {
        print qq(<p />2. <a href="viewobjects.pl?a=$folioInfo{portfolioAccount}" target="_blank">list all of the uploaded objects</a> in the database for account #$folioInfo{portfolioAccount});
        print qq(<p />3. <a href="viewobjects.pl?a=$user->{userAccountNumber}" target="_blank">list all of the uploaded objects</a> in the database for account #$user->{userAccountNumber} (your account));
    }
    else
    {
        print qq(<p />2. <a href="viewobjects.pl" target="_blank">list all of the uploaded objects</a> in the database for account #$folioInfo{portfolioAccount} ($user->{userAccountName}));
    }
    print qq(</div>);


    print qq(<p /><br /><div style="padding:10px; padding-left:20px; padding-top:5px;border:1px solid #cccccc;">);

    print qq(<h2>Editor options  - general</h2><p /><blockquote>);

    print qq(<form action="editorsettings.pl" method="post">);
    print qq(1. change your password:<div class="ins">);
    print qq(<input type="text" name="text1" class="fixed" value="" size="20" maxlength="255" /> <span class="info">&lt;- type new password</span>);
    print qq(<br /><input type="text" name="text2" class="fixed" value="" size="20" maxlength="255" /> <span class="info">&lt;- into both boxes</span>);
    print qq(<br /><input type="submit" value="update" class="submit" />);
    print qq(<br /><input type="hidden" name="a" value="changepassword" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(<form action="editorsettings.pl" method="post">);
    print qq(2. change the personal name of your user account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userRealName}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">e.g. "Helen Smith" or "administrator"</span>);
    print qq(<input type="hidden" name="a" value="changerealname" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(<form action="editorsettings.pl" method="post">);
    print qq(3. change the contact email address for your user account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userEmail}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">this is the email address we will use for contacting you</span>);
    print qq(<input type="hidden" name="a" value="changeemail" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(</blockquote>);

    print qq(</div>);

    print qq(</body></html>);

sub pageHeader 
{ 

<<HEADER
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 

<html lang="en">
<head>
<title>Intute Informs - Editor Options</title>
<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css" />
<style type="text/css">
input,select,textarea { font-family: Arial; font-size:90%; }
body { font-size:90% }
.fixed { font-family: Arial, Lucida Console, Courier New; }
.info { color:#060; font-size:80% }
.ins { padding: 3px 0x 15px 25px }
.oops { font-weight:bold; color:#F00 }
.ok { font-weight:bold; color:#090 }
a { color:#00F; text-decoration:none }
a:hover { color:#F00; text-decoration:underline }
</style>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">

</head>
<body>
<div class="container">
HEADER

}

sub deadParrot {
    my($error) = @_;
    print $cgi->{header};

    if($error =~ /^\d*$/) {
        print qq(<h2>error!</h2><p>your request generated an error code of <b><font color="red">$error</font></b>);
    }
    else {
        print qq(<h2>error!</h2><p><dl><dt>your request generated the following error:<p><dd><b><font color="red">$error</font></b></dl>);
    }
    print "</body></html>";
    exit;
}

sub reload
{
    my $msg = shift;
    my $folio = shift;

    unless( $msg =~ /error/i )
    {
        print qq(<div class="ok">$msg</div><p />);

        print qq(...please wait a couple of seconds for this page to reload (or <a href="editorsettings.pl?folio=$folio">click here</a>));
	 print qq(</body></html>);
        exit;
    }
    else
    {
        print qq(<div class="oops">$msg</div><p />);
    }

}

1;
