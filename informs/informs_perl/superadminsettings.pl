#!/home/zzintadm/perl/bin/perl -WT

use strict;
use lib "./";
use locale;

use InhaleCore qw( :DEFAULT );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw(  getFolioDetails getUserInfo );
use InhaleWrite qw( updateUser updatePortfolio createPortfolio deletePortfolio createUser );

    unless( $user->{userNumber} ) { deadParrot("access to this page is restricted to authorised users only"); }
    unless( $user->{userType} eq 'superadmin' ) { deadParrot("access to this page is restricted to authorised users only"); }


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

### CREATE NEW ACCOUNT

    if( $action eq 'createportfolio' && $folioInfo{portfolioParent} == 0 )
    {
	if( $text )
	{
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

    print qq(<a href="portfolio.pl?folio=$folio"> $folioInfo{portfolioName}</a> > super administrator</div>);
    print qq(<p /><br /><div style="margin:0px; width:70%; padding:10px; border:1px solid #cccccc;">);
    print qq(<h2>Superadministrator options - accounts</h2><p /><blockquote>);
    print qq(1. <a href="edituser.pl?folio=$folioInfo{portfolioAccount}&amp;a=newacc">create brand new institutional account</a>);
    print qq(<p />2. <a href="edituser.pl?folio=$folioInfo{portfolioAccount}&amp;a=listacc">administer existing admin users</a>);
    print qq(</blockquote></div>);
    print qq(<p /><br /><div style="margin:0px; width:70%; padding:10px; border:1px solid #cccccc;">);
    print qq(<h2>Superadministrator options - faq</h2><p /><blockquote>);
    print qq(1. <a href="faq.pl?folio=$folioInfo{portfolioAccount}&amp;a=addfaq">add a new faq</a>);
    print qq(<p />2. <a href="faq.pl?folio=$folioInfo{portfolioAccount}&amp;a=viewfaq">edit or delete an faq</a>);
    print qq(</blockquote></div>);
    print qq(<p /><br /><div style="margin:0px; width:70%; padding:10px; border:1px solid #cccccc;">);
    print qq(<h2>Superadministrator options  - general</h2><p /><blockquote>);
    print qq(<form action="superadminsettings.pl" method="post">);
    print qq(1. change administrator account password:<div class="ins">);
    print qq(<input type="text" name="text1" class="fixed" value="" size="20" maxlength="255" /> <span class="info">&lt;- type new password</span>);
    print qq(<br /><input type="text" name="text2" class="fixed" value="" size="20" maxlength="255" /> <span class="info">&lt;- into both boxes</span>);
    print qq(<br /><input type="submit" value="update" class="submit" />);
    print qq(<br /><input type="hidden" name="a" value="changeadminpassword" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);
    print qq(<form action="superadminsettings.pl" method="post">);
    print qq(2. change the title of the entire account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userAccountName}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">e.g. "University of Middlefield" or "Nowhere College"</span>);
    print qq(<input type="hidden" name="a" value="changeaccountname" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);
    print qq(<form action="superadminsettings.pl" method="post">);
    print qq(3. change the personal name of your administrator account:<div class="ins">);
    print qq(<input type="text" name="text" class="fixed" value="$user->{userRealName}" size="40" maxlength="100" /> <input type="submit" value="update" class="submit" />);
    print qq(<br><span class="info">e.g. "Helen Smith" or "administrator"</span>);
    print qq(<input type="hidden" name="a" value="changerealname" /><input type="hidden" name="folio" value="$folio" />);
    print qq(</div></form>);
    print qq(<form action="superadminsettings.pl" method="post">);
    print qq(4. change the contact email address for this account:<div class="ins">);
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
<title>Intute Informs - Super Administrator Options</title>
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
<script language="JavaScript">
<!--


//-->
</script>
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

        print qq(
<script language="JavaScript">
<!--
    setTimeout("top.location.href = 'superadminsettings.pl?folio=$folio'",6000);
//-->
</script>
        );
        print qq(...please wait a couple of seconds for this page to reload (or <a href="superadminsettings.pl?folio=$folio">click here</a>));
	print qq(</body></html>);
        exit;
    }
    else
    {
        print qq(<div class="oops">$msg</div><p />);
    }

}


1;
