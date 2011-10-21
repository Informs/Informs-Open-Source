#!/home/zzintadm/perl/bin/perl -WT

use strict;
use lib "./";
use locale;
use SendMail 2.09;
use InhaleCore qw( :DEFAULT );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw(  getFolioDetails getUserInfo );
use InhaleWrite qw( updateUser updatePortfolio createPortfolio deletePortfolio createUser );

    unless( $user->{userNumber} ) { deadParrot("access to this page is restricted to authorised users only"); }
    unless( $user->{userType} eq 'admin' || $user->{userType} eq 'superadmin' ) { deadParrot("access to this page is restricted to authorised users only"); }


    my $folio   = $cgi->{folio}  || '1';
    my $action  = $cgi->{a}      || '';
    my $text    = $cgi->{text}   || '';
    my $text1   = $cgi->{text1}  || '';
    my $text2   = $cgi->{text2}  || '';
    my $text3   = $cgi->{text3}  || '';

    unless( $user->{userPortfolioList} =~ /:$folio:/ )  { deadParrot("you do not have permissions to access the admin page for this portfolio!"); }

    print $cgi->{header};
    print pageHeader( );

    my %folioInfo = getFolioDetails( folio => $folio ); 

    if( $action eq 'changeportfolioname' && $text ne $folioInfo{portfolioName} )
    {
	if( $text )
	{
	$text =~ s/'/\\'/g;
	    updatePortfolio( $user->{userNumber}, 'changeportfoliotitle', $folio, $text );
	    reload("the portfolio name was updated",$folio);
	}
	else
	{
	    reload("error: the portfolio name was not updated - it cannot be blank",$folio);
	}

    }

    if( $action eq 'createportfolio' && $folioInfo{portfolioParent} == 0 )
    {
	if( $text )
	{
	    $text =~ s/'/\\'/g;
	    my $new = createPortfolio(   title => $text,
                                        parent => $folio,
                                       account => $folioInfo{portfolioAccount} );
	    reload("the new portfolio (#$new) was created",$folio);
	}
	else
	{
	    reload("error: the new portfolio was not created - it's title cannot be blank",$folio);
	}
    }

    if( $action eq 'confirmdeleteportfolio' && $folioInfo{portfolioParent} && $folio eq $text )
    {

	deletePortfolio( portfolio => $text );

	print qq(<div class="ok">portfolio #$folio was deleted!</div><p />\n);
	print qq(<script language="JavaScript">
<!--
    setTimeout("top.location.href = 'portfolio.pl?folio=$folioInfo{portfolioParent}'",6000);
//-->
</script>
        ...please wait a couple of seconds for this page to reload (or <a href="portfolio.pl?folio=$folioInfo{portfolioParent}">click here</a>)
	);
	exit;
    }

    if( $action eq 'deleteportfolio' && $folioInfo{portfolioParent} && $folio eq $text )
    {
	print qq(You have chosen to delete <b>#$folio</b> - $folioInfo{portfolioName}<p /><blockquote>);
	print qq(<div style="padding:5px 20px; background:#FFF; border:1px solid #cccccc;">);
	print qq(If you decide to continue, any units currently in that portfolio will be <span class="oops">permanently deleted</span>!);
	print qq(<p />Please carefully select one of the following options...<p />);

	print qq(<div align="center">);
	print qq(<a href="adminsettings.pl?folio=$folio&amp;a=confirmdeleteportfolio&amp;text=$text"><img src="/gfx/deleteunityes.gif" border="0" alt="YES - DELETE THIS UNIT" /></a>);
	print qq( &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; <a href="adminsettings.pl?folio=$folio"><img src="/gfx/deleteno.gif" border="0" alt="NO - LEAVE THIS UNIT ALONE!" /></a>);
	print qq(</div></div></blockquote>);

	print q(<p /><br /><p /><p />notes: deleting a porfolio will do the following...<p /><ul>);
	print qq(<li>remove all units from the database</li>);
	print qq(<li>remove all statistics relating to those units from the database</li>);
	print qq(<li>earmark for deletion all of the objects used by those units</li>);
   	print qq(</ol></body></html>);
	exit;
    }

    if( $action eq 'changeadminpassword' )
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

#####user changed account name - let us know
my $message = "";
$message = "$user->{userNumber} - $user->{userRealName} has changed their Informs account name to $text\n\n";

my($sm) = new SendMail;
my $sender="";
$sender .= "andrew.priest\@manchester.ac.uk";
$sm->From($sender);
$sm->To($sender);
$sm->Subject("Informs account name change");

#
# Now send the submitted data to the user.
#
my($localtime) = scalar(localtime());
my($mailbody) = <<__END__MAILBODY__;

Informs Account

$message

__END__MAILBODY__

$sm->setMailBody($mailbody);

if ($sm->sendMail() != 0) {
  printError($sm->{'error'});
  exit;
}
	    reload("your name was updated",$folio);
	}
	else
	{
	    reload("error: your name was not updated - it cannot be blank",$folio);
	}
    }


    if( $action eq 'changeaccountname' && $text ne $user->{userAccountName} )
    {
	if( $text )
	{
	    updateUser( action => 'changeaccountname',
                          account => $user->{userAccountNumber},
                             text => $text );
	    reload("the account title was updated",$folio);
	}
	else
	{
	    reload("error: the account title was not changed - the title cannot be blank",$folio);
	}
    }

    if( $action eq 'changelogo' && $text ne $user->{userAccountLogo} )
    {
	if( $text && $text =~ /^http/i )
	{
            updateUser( action => 'changelogo',
                          account => $user->{userAccountNumber},
                             text => $text );
	    reload("the account logo URL was updated",$folio);
	}
	elsif( $text eq '' )
	{
            updateUser( action => 'changelogo',
                          account => $user->{userAccountNumber},
                             text => $text );
	    reload("the account logo URL was updated",$folio);
	}
	else
	{
	    reload('error - the logo URL must start with "http://..."',$folio);
	}
    }

    if( $action eq 'changecss' && $text ne $user->{userAccountCSS} )
    {
	if( $text && $text =~ /^http/i )
	{
            updateUser( action => 'changecss',
                          account => $user->{userAccountNumber},
                             text => $text );
	    reload("the account CSS URL was updated",$folio);
	}
	elsif( $text eq '' )
	{
            updateUser( action => 'changecss',
                          account => $user->{userAccountNumber},
                             text => $text );
	    reload("the account CSS URL was updated",$folio);
	}
	else
	{
	    reload('error - the CSS URL must start with "http://..."',$folio);
	}
    }

    print qq(<a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > administrator</div>);
  
    print qq(<p /><br /><div style="margin:0px; width:73%; padding:10px; border:1px solid #cccccc; ">);

    print qq(<h2>Administrator options for $folioInfo{portfolioName}</h2><p /><blockquote>);

    print qq(<form action="adminsettings.pl" method="post">);
    print qq(1. change portfolio title:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$folioInfo{portfolioName}" size="50" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<input type="hidden" name="a" value="changeportfolioname" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    unless( $folioInfo{portfolioParent} )
    {
        print qq(<form action="adminsettings.pl" method="post">);
	 print qq(2. create a new sub portfolio:<div class="ins">);
        print qq(<input type="text" name="text" class="fixed" value="" size="50" maxlength="100" /> <input type="submit" value="update" class="submit" />);
        print qq(<br><span class="info">enter the title of the new portfolio</span>);
        print qq(<input type="hidden" name="a" value="createportfolio" /><input type="hidden" name="folio" value="$folio" />);
        print qq(</div></form>);
    }
    else
    {
        print qq(<form action="adminsettings.pl" method="post">);
	 print qq(2. delete this portfolio:<div class="ins">);
        print qq(<input type="text" name="text" class="fixed" value="" size="40" maxlength="100" /> <input type="submit" class="submit" value="delete" />);
        print qq(<br><span class="info">to delete this portfolio, enter the number <b>$folio</b> in the box above and click the "delete" button</span>);
        print qq(<input type="hidden" name="a" value="deleteportfolio" /><input type="hidden" name="folio" value="$folio" />);
        print qq(</div></form>);
    }

    my($tm,$year) = (localtime)[4,5];
    $year += 1900;
    $tm++;

    my $ty = $year;
    $tm--;
    if( $tm == 0 ) { $tm = 12; $ty-- }

    print qq(<form action="stats2.pl" method="get" target="_blank">);
    print qq(3. download monthly usage statistics:<div class="ins">);
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
    print qq( <input type="hidden" name="folio" value="$folio" /><input type="submit" value="download" class="submit" /> <span class="info">stats file in CSV format</span>);
    print qq(</div></form>);

    print qq(</div>);

    print qq(<p /><br /><div style="margin:0px; width:73%; padding:10px; border:1px solid #cccccc;">);
    print qq(<h2>Objects database</h2><p /><blockquote>);
    print qq(<p />1. <a href="insertobject.pl" target="_blank">upload new object</a> into the database);
    if( $folioInfo{portfolioAccount} != $user->{userAccountNumber} )
    {
        print qq(<p />2. <a href="viewobjects.pl?a=$folioInfo{portfolioAccount}" target="_blank">list all of the uploaded objects</a> in the database for $folioInfo{portfolioAccount});
        print qq(<p />3. <a href="viewobjects.pl?a=$user->{userAccountNumber}" target="_blank">list all of the uploaded objects</a> in the database for your account);
    }
    else
    {
        print qq(<p />2. <a href="viewobjects.pl" target="_blank">list all of the uploaded objects</a> in the database for your account);
    }
    print qq(</div>);


    if( $user->{userType} eq 'admin' )
    {
        my @editors = getUserInfo( account => $user->{userAccountNumber}, user => 'editor' );

        print qq(<p /><br /><div style="margin:0px; width:73%; padding:10px; border:1px solid #cccccc; ">);

        print qq(<h2>Administrator options - Editor accounts</h2><p /><blockquote>);
        print qq(1. <a href="edituser.pl?folio=$folio&amp;a=neweditor">create new Editor</a>);

        if( scalar( @editors ) )
        {
           print qq(<p />2. <a href="edituser.pl?folio=$folio&amp;a=listeditors">administer existing Editors</a>);
        }
        print qq(</blockquote></div>);
    }


    print qq(<p /><br /><div style="margin:0px; width:73%; padding:10px; border:1px solid #cccccc; ">);

    print qq(<h2>Administrator options  - general</h2><p /><blockquote>);

    print qq(<form action="adminsettings.pl" method="post">);
    print qq(1. change administrator account password: (must start with a character)<div class="ins">);
    print qq(<input type="text" name="text1" class="fixed" value="" size="20" maxlength="255" /> <span class="info">&lt;- type new password</span><br />);
    print qq(<br /><input type="text" name="text2" class="fixed" value="" size="20" maxlength="255" /> <span class="info">&lt;- into both boxes</span>);
    print qq(<br /><input type="submit" value="update" class="submit" />);
    print qq(<br /><input type="hidden" name="a" value="changeadminpassword" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(<form action="adminsettings.pl" method="post">);
    print qq(2. change the personal name of your administrator account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userRealName}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">e.g. "Helen Smith" or "administrator"</span>);
    print qq(<input type="hidden" name="a" value="changerealname" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(<form action="adminsettings.pl" method="post">);
    print qq(3. change the contact email address for this account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userEmail}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">this is the email address we will use for contacting you</span>);
    print qq(<input type="hidden" name="a" value="changeemail" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(<form action="adminsettings.pl" method="post">);
    print qq(4. add custom logo for your account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userAccountLogo}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">enter the full URL of the logo (normally hosted on your own web server) or leave blank for default</span>);
    print qq(<input type="hidden" name="a" value="changelogo" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(<form action="adminsettings.pl" method="post">);
    print qq(5. add custom stylesheet for units in all of your portfolios:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userAccountCSS}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit"/>);
    print qq(<br><span class="info">enter the full URL of the CSS file (normally hosted on your own web server) or leave blank for default</span>);
    print qq(<input type="hidden" name="a" value="changecss" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);

    print qq(</blockquote>);

    print qq(</div>);

    print qq(</div></body></html>);

sub pageHeader 
{ 

<<HEADER
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 

<html lang="en">
<head>
<title>Intute Informs - Administrator Options</title>
<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css" />
<style type="text/css">
input,select,textarea { font-size:90%;}
body { font-size:90% }
.fixed { white-space : nowrap;}
.info { color:#007F71; font-size:80% }
.ins { padding: 3px 0x 15px 25px; }
.oops { font-weight:bold; color:#F00 }
.ok { font-weight:bold; color:#090 }
</style>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">

</head>
<body>
<div class="container">
<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />
<div id="breadcrumb">Intute Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a>  >  <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a>

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
    print "</div></body></html>";
    exit;
}

sub reload
{
    my $msg = shift;
    my $folio = shift;

    unless( $msg =~ /error/i )
    {
        print qq(<div class="ok">$msg</div><p />);

        print qq(...please wait a couple of seconds for this page to reload (or <a href="adminsettings.pl?folio=$folio">click here</a>));
	 print qq(</div></body></html>);
        exit;
    }
    else
    {
        print qq(<div class="oops">$msg</div><p />);
    }

}

1;
