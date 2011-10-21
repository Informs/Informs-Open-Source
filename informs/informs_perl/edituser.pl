#!/home/zzintadm/perl/bin/perl -WT

use strict;
use lib "./";
use locale;

use InhaleCore qw( :DEFAULT );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw(  getFolioDetails getUserInfo getAccountDetails getEditorFolios );
use InhaleWrite qw( updateUser updatePortfolio createPortfolio deletePortfolio createUser createAccount updateAccount deleteUser );

$| = 1;

    unless( $user->{userNumber} ) { deadParrot("access to this page is restricted to authorised users only"); }
    unless( $user->{userType} eq 'admin' || $user->{userType} eq 'superadmin' ) { deadParrot("access to this page is restricted to authorised users only"); }

    my $folio   = $cgi->{folio}  || '1';
    my $action  = $cgi->{a}      || '';
    my $text    = $cgi->{text}   || '';
    my $text1   = $cgi->{text1}  || '';
    my $text2   = $cgi->{text2}  || '';
    my $text3   = $cgi->{text3}  || '';
    my $text4   = $cgi->{text4}  || '';
    my $text5   = $cgi->{text5}  || '';
    my $text6   = $cgi->{text6}  || '';
    my $text7   = $cgi->{text7}  || '';
    my $list    = $cgi->{list}   || '';
    my %folioInfo = getFolioDetails( folio => $folio ); 

    print $cgi->{header};
    print pageHeader( );

    print qq(> <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > editors</div><br />);

### brand new account

    if( $action eq 'newacc' && $user->{userType} eq 'superadmin')
    {
	$text4 = generatePassword( );

	print qq(<h2>Create brand new institutional account</h2><p /><div id="create"><div id="box"><blockquote>
       <form action="edituser.pl" method="post">\n);
	print qq(<input type="hidden" name="folio" value="$folio" />\n);
	print qq(<input type="hidden" name="a" value="newacc_doit" />\n);
	print qq(<p />1. account title<br /><input type="text" name="text" value="" size="40" />\n);
	print qq(<p />2. contact information<br /><input type="text" name="text1" value="" size="40" />\n);
	print qq(<p />3. administrator email (optional)<br /><input type="text" name="text2" value="" size="40" />\n);
	print qq(<p />4. administrator username<br /><input type="text" name="text3" value="" />\n);
	print qq(<p />5. administrator password (choose the random password or type a new one)<br /><input type="text" name="text4" value="$text4" />\n);
	print qq(<p />Please double check everything before clicking on the submit button!);
	print qq(<p /><input type="submit" value="submit" class="submit" /></form></blockquote></div></div>);
    }

    if( $action eq 'newacc_doit' && $user->{userType} eq 'superadmin')
    {
	print qq(<p />1. creating account... );
	my $account = createAccount( title => $text, contactInfo => $text1 );
	print qq(done -- new account is $account);

	print qq(<p />2. creating admin user... );
	createUser( account => $account, email => $text2, username => $text3, password => $text4, realname => "admin ($text)", role => 'admin' );
	print qq(done - login details <b>$text3</b> / <b>$text4</b>);

	print qq(<p />3. creating portfolio... );
	my $portfolio = createPortfolio( account => $account, title => $text, parent => 0 );
	print qq(done - new portfolio is $portfolio);

	print qq(<p /><a href="portfolio.pl?folio=$portfolio">go to portfolio $portfolio</a>);
    }

### edit account

    if( $action eq 'editacc' && $user->{userType} eq 'superadmin')
    {
	my @admin = getUserInfo( account => $text2, user => 'admin' );
	my( $userNumber, $username, $account, $email, $role, $name, $title ) = split( /\t/, $admin[0] );
	my %info = getAccountDetails( user => $userNumber, session => 'null' );

	print qq(<h2>Edit account $text2 ($title)</h2><p />);

	print qq(<div id="create"><div id="box"><blockquote><form action="edituser.pl" method="post">\n);
	print qq(<input type="hidden" name="folio" value="$folio" />\n);
	print qq(<input type="hidden" name="a" value="editacc_doit" />\n);
	print qq(<input type="hidden" name="text1" value="$text1" />\n);
	print qq(<input type="hidden" name="text2" value="$text2" />\n);

	print qq(<p />1. account title<br /><input type="text" name="text" value="$title" size="40" />\n);
	print qq(<p />2. contact information<br /><input type="text" name="text3" value="$info{userAccountInfo}" size="40" />\n);
	print qq(<p />3. account admin email (optional)<br /><input type="text" name="text4" size="40" value="$email" size="40" />\n);
	print qq(<p />4. account admin real name<br /><input type="text" name="text7" value="$name" size="40" />\n);
	print qq(<p />5. account admin login username<br /><input type="text" name="text5" value="$username" size="40" />\n);
	print qq(<p />6. account admin login password (leave blank or enter a new password to reset it)<br /><input type="text" name="text6" value="" size="40" />\n);
	print qq(<p />Please double check everything before clicking on the submit button!);
	print qq(<p /><input type="submit" value="submit" class="submit" /></form></blockquote></div></div>);
    }

    if( $action eq 'editacc_doit' && $user->{userType} eq 'superadmin')
    {
	my @admin = getUserInfo( account => $text2, user => 'admin' );
	my( $userNumber, $username, $account, $email, $role, $name, $title ) = split( /\t/, $admin[0] );
	my %info = getAccountDetails( user => $userNumber, session => 'null' );

	my $updates = '';

	if( $text ne $title )
	{
	    updateAccount( account => $text2, action => 'updatetitle', text => $text );
	    $updates .= qq(<li>account title changed to <b>$text</b></li>);
	}

	if( $text3 ne $info{userAccountInfo} )
	{
	    updateAccount( account => $text2, action => 'updatecontactinfo', text => $text3 );
	    $updates .= qq(<li>account contact info changed to <b>$text3</b></li>);
	}

	if( $text4 ne $email )
	{
	    updateUser( action => 'changeemail', user => $userNumber, text => $text4 );
	    $updates .= qq(<li>account admin email address changed to <b>$text4</b></li>);
	}

	if( $text5 ne $username )
	{
	    updateUser( action => 'changeusername', user => $userNumber, text => $text5 );
	    $updates .= qq(<li>account admin login username changed to <b>$text5</b></li>);
	}

	if( $text6 )
	{
	    updateUser( action => 'changepassword', user => $userNumber, text => $text6 );
	    $updates .= qq(<li>account admin login password changed to <b>$text6</b></li>);
	}

	if( $text7 ne $name )
	{
	    updateUser( action => 'changerealname', user => $userNumber, text => $text7 );
	    $updates .= qq(<li>account admin real name changed to <b>$text7</b></li>);
	}

	unless( $updates ) { $updates = qq(<li>...nothing!</li>); }

	if( $updates )
	{
	    print qq(<p /><b>Edit account $text2 ($title)</b><p />The following just happened...<ul>$updates</ul>);

	}
    }

### list accounts

    if( $action eq 'listacc' && $user->{userType} eq 'superadmin' )
    {
	print qq(<h2>Existing accounts</h2>Select one to edit.<br /><br /><div id="exist"> <p /><ol>);

	foreach( getUserInfo( account => 'any', user => 'admin' ) )
	{
	    my( $userNumber, $username, $account, $email, $role, $name, $title ) = split(/\t/);
	    print qq(<li value="$account"><a href="edituser.pl?a=editacc&amp;text1=$userNumber&amp;text2=$account&amp;folio=$folio">$title</a> - $username / $name</li>);
	}
	print qq(</ol></div>);
    }

### list all editors

    if( $action eq 'listeditors' && $user->{userType} eq 'admin' )
    {
	print qq(<h2>List Editors</h2><p /><p>The following Editors exist for your account along with the portfolios each Editor can edit.<br />To update any Editor, click on the relevant link.</p><div id="create"><div id="box"><ul>);

	foreach( getUserInfo( account => $user->{userAccountNumber}, user => 'editor' ) )
	{
	    my( $userNumber, $username, $account, $email, $role, $name, $title ) = split(/\t/);

	    my @folios = getEditorFolios( user => $userNumber );
	    print qq(<li><a href="edituser.pl?a=editeditor&amp;folio=$folio&amp;text=$userNumber">$username - $name</a>);
	    foreach( @folios ) 
	    {
		my( $folioNumber, $folioTitle, $folioParent ) = split( /\t/ );

	 	if( $folioParent ) { print qq(<br />$folioNumber: $folioTitle) }
	 	else               { print qq(<br />$folioNumber: <b>$folioTitle</b>) }
	    }
	    print qq(</li>);
	}
	print qq(</ul></div></div>);
    }

### update editor

    if( $action eq 'editeditor' && $user->{userType} eq 'admin' )
    {
	my $okay = 0;

	foreach( getUserInfo( account => $user->{userAccountNumber}, user => 'editor' ) )
	{
	    my( $userNumber, $username, $account, $email, $role, $name, $title ) = split(/\t/);
	    if( $userNumber == $text ) { $okay = 1 }
	}
	unless( $okay ) { die "You do not have permission to update user $text\n" }

	my @u = getUserInfo( account => $user->{userAccountNumber}, user => $text );
	my( $userNumber, $username, $account, $email, $role, $name, $title ) = split( /\t/, $u[0] );
	unless( $userNumber ) { die "Oooops - there was a problem fetching the info for user $text\n" }

	print qq(<h2>Update Editor</h2>);

	print qq(<div id="create"><div id="box"><blockquote><form action="edituser.pl" method="get">\n);
	print qq(<input type="hidden" name="folio" value="$folio" />\n);
	print qq(<input type="hidden" name="a" value="editeditor_doit" />\n);
	print qq(<input type="hidden" name="text" value="$text" />\n);

	print qq(<p />1. real name<br /><input type="text" name="text1" value="$name" size="40" /> (<a href="edituser.pl?a=deleteeditor&amp;folio=$folio&amp;text=$userNumber">delete this editor</a>)\n);
	print qq(<p />2. login username<br /><input type="text" name="text2" value="$username" size="40" />\n);
	print qq(<p />3. login password (leave blank or enter new password to reset)<br /><input type="text" name="text3" value="" size="40" />\n);
	print qq(<p />4. email address<br /><input type="text" name="text4" value="$email" size="40" />\n);
	print qq(<p />5. portfolios this user can edit:);

	my @flist = split( /\:/, $user->{userPortfolioList} );
	my @folios = getEditorFolios( user => $userNumber );

	foreach my $f ( @flist )
	{
	    unless( $f ) { next }
 	    my %folioInfo = getFolioDetails( folio => $f ); 

	    my $checked = '';

	    foreach ( @folios )
	    {
	        my( $folioNumber, $folioTitle, $folioParent ) = split( /\t/ );
		if( $folioNumber == $f ) { $checked = ' checked' }
	    }

	    if( $folioInfo{portfolioParent} ) { print qq(<br />&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox"$checked name="list" value="$f" />portfolio $f: $folioInfo{portfolioName}); }
	    else                              { print qq(<br />&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox"$checked name="list" value="$f" />portfolio $f: <b>$folioInfo{portfolioName}</b>); }
	}

	print qq(<p />Please double check everything before clicking on the submit button!);
	print qq(<p /><input type="submit" value="submit" class="submit" /></form></blockquote></div></div>);
    }

    if( $action eq 'deleteeditor' && $user->{userType} eq 'admin' )
    {
	my $okay = 0;
	my $updates = '';

	foreach( getUserInfo( account => $user->{userAccountNumber}, user => 'editor' ) )
	{
	    my( $userNumber, $username, $account, $email, $role, $name, $title ) = split(/\t/);
	    if( $userNumber == $text ) { $okay = 1 }
	}
	unless( $okay ) { die "You do not have permission to update user $text\n" }

	my @u = getUserInfo( account => $user->{userAccountNumber}, user => $text );
	my( $userNumber, $username, $account, $email, $role, $name, $title ) = split( /\t/, $u[0] );
	unless( $userNumber ) { die "Oooops - there was a problem fetching the info for user $text\n" }

	deleteUser( user => $userNumber );	

	print qq(<p />The Editor was deleted!<p /><a href="edituser.pl?folio=$folio&a=listeditors">return to editor list</a>);
    }

    if( $action eq 'editeditor_doit' && $user->{userType} eq 'admin' )
    {
	my $okay = 0;
	my $updates = '';

	foreach( getUserInfo( account => $user->{userAccountNumber}, user => 'editor' ) )
	{
	    my( $userNumber, $username, $account, $email, $role, $name, $title ) = split(/\t/);
	    if( $userNumber == $text ) { $okay = 1 }
	}
	unless( $okay ) { die "You do not have permission to update user $text\n" }

	my @u = getUserInfo( account => $user->{userAccountNumber}, user => $text );
	my( $userNumber, $username, $account, $email, $role, $name, $title ) = split( /\t/, $u[0] );
	unless( $userNumber ) { die "Oooops - there was a problem fetching the info for user $text\n" }

	updateUser( action => 'cleareditor', text => 'all', user => $text );
	$updates .= qq(<li>cleared current permissions</li>);

	foreach my $canedit ( split( /\t/, $list ) )
	{
	    updateUser( action => 'updateeditor', text => $canedit, user => $text );
	    $updates .= qq(<li>permission granted to edit portfolio $canedit</li>);
	}

	if( $text1 ne $name )
	{
	    updateUser( action => 'changerealname', user => $userNumber, text => $text1 );
	    $updates .= qq(<li>editor real name changed to <b>$text1</b></li>);
	}
	
	if( $text2 ne $username )
	{
	    updateUser( action => 'changeusername', user => $userNumber, text => $text2 );
	    $updates .= qq(<li>editor login username changed to <b>$text2</b></li>);
	}

	if( $text3 )
	{
	    updateUser( action => 'changepassword', user => $userNumber, text => $text3 );
	    $updates .= qq(<li>editor login password changed to <b>$text3</b></li>);
	}

	if( $text4 ne $email )
	{
	    updateUser( action => 'changeemail', user => $userNumber, text => $text4 );
	    $updates .= qq(<li>editor email address changed to <b>$text4</b></li>);
	}

	unless( $updates ) { $updates = qq(<li>...nothing!</li>); }

	if( $updates )
	{
	    print qq(<p /><b>Update Editor details</b><p />The following just happened...<ul>$updates</ul>);

	}
	print qq(<p /><a href="edituser.pl?folio=$folio&a=listeditors">return to editor list</a>);
    }


### create new editor

    if( $action eq 'neweditor' && $user->{userType} eq 'admin' )
    {
	$text4 = generatePassword( );

	print qq(<h2>Create brand new Editor</h2><p /><div id="create" align="left"><div id="box"><form action="edituser.pl" method="post">\n);
	print qq(<input type="hidden" name="folio" value="$folio" />\n);
	print qq(<input type="hidden" name="a" value="neweditor_doit" />\n);
	print qq(<p />1. real name<br /><input type="text" name="text1" value="" size="40" />\n);
	print qq(<p />2. email (optional)<br /><input type="text" name="text2" value="" size="40" />\n);
	print qq(<p />3. login username<br /><input type="text" name="text3" value="" />\n);
	print qq(<p />4. login password (choose the random password or type a new one)<br /><input type="text" name="text4" value="$text4" />\n);

       print qq(<p />Please double check everything before clicking on the submit button);
	print qq(<p /><input type="submit" class="submit" value="submit" /></form></div></div>);
    }

    if( $action eq 'neweditor_doit' && $user->{userType} eq 'admin')
    {
	if( $text1 && $text3 && $text4 )
	{
	    print qq(<p />1. creating editor... );
	    createUser( account => $user->{userAccountNumber}, email => $text2, username => $text3, password => $text4, realname => $text1, role => 'editor' );
  	    print qq(done - login details <b>$text3</b> / <b>$text4</b>);
	}
	else
	{
	    print qq(<p />There was a problem creating the new editor -- please use the back button and check you entered the details correctly.);
	}

	print qq(<p /><a href="edituser.pl?folio=$folio&a=listeditors">return to editor list</a>);
    }



    print qq(</div></body></html>);

sub pageHeader 
{ 

<<HEADER
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 

<html lang="en">
<head>
<title>Intute Informs User Options</title>
<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css" />
<style type="text/css">
input,select,textarea { font-family: sans-serif; font-size:90%; }
body { font-size:90% }
.fixed { }
.info { color:#060; font-size:80% }
.ins { padding: 3px 0x 15px 25px }
.oops { font-weight:bold; color:#F00 }
.ok { font-weight:bold; color:#090 }
li { padding-bottom:5px; list-style: none; }
#box {padding:10px;
padding-left:20px;}
</style>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">

</head>
<body>
<div class="container">
<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />
<div id="breadcrumb">Intute Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a>


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

        print qq(
<script language="JavaScript">
<!--
    setTimeout("top.location.href = 'edituser.pl?folio=$folio'",6000);
//-->
</script>
        );
        print qq(...please wait a couple of seconds for this page to reload (or <a href="adminsettings.pl?folio=$folio">click here</a>));
	print qq(</div></body></html>);
        exit;
    }
    else
    {
        print qq(<div class="oops">$msg</div><p />);
    }

}

sub generatePassword
{
    my @words = qw( apple orange spider robin lemon green brown blue yellow pepper dragon purple house );
    my $d = int(rand(900)+100);

    srand( );

    return( $words[int(rand(scalar(@words)))].$d );

}


1;
