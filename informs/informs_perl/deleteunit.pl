#!/home/zzintadm/perl/bin/perl -wT

use strict;
use lib "./";
use locale;


use Digest::MD5 qw(md5_hex);

use InhaleCore qw( :DEFAULT convertTags );
unless(new InhaleCore( 'safeCGI' )) { error("access to this page is restricted to authorised users only"); }

use InhaleRead qw( getUnit getFolioDetails );
use InhaleWrite qw( updatePortfolio deleteUnit );

my $folio  = $cgi->{folio}    || error('script was called without a required parameter', 'bad parameter');
my $unitNo = $cgi->{unit}     || error('script was called without a required parameter', 'bad parameter');
my $check  = $cgi->{checksum} || error('script was called without a required parameter', 'bad parameter');
my $action = $cgi->{action}   || '';

use Digest::MD5 qw(md5_hex);
my $checksum = md5_hex($unitNo, $folio, $user->{userNumber}, 'a bit of text');

unless($checksum eq $check) { error("script was called with an invalid parameter", 'bad parameter'); }

print $cgi->{header};
my %folioInfo = getFolioDetails( folio => $folio ); 

if($action) 
{
    print header();    

    deleteUnit( unit => $unitNo );

    print qq(<p />Unit $unitNo has been deleted from your portfolio);

    exit;
}
else 
{
    print header();    
    my $unit = getUnit( folio => $folio,
                         unit => $unitNo );
    print qq(
<h1>Delete Unit</h1>
<p /><div id="create2">
You are about to delete the following unit from your portfolio:
<p />
<table class="delete">
<tr><td align="right" valign="top"><b>unit&nbsp;number:</b></td><td align=left" valign="top">$unit->{unitNumber}</td></tr>
<tr><td align="right" valign="top"><b>unit&nbsp;title:</b></td><td align=left" valign="top">$unit->{folioUnitTitle}</td></tr>
<tr><td align="right" valign="top"><b>description:</b></td><td align=left" valign="top">$unit->{folioDescription}</td></tr>
</table>

<p />
Please confirm that you really do want to delete the above unit - if you select <img src="/gfx/deleteunityes.gif" border="0" alt="yes delete unit" />, then you will <b>not</b> be able to recover
the deleted unit!

<p /><br />
<div align="center">
<a href="deleteunit.pl?folio=$folio&unit=$unitNo&checksum=$checksum&action=delete"><img src="/gfx/deleteunityes.gif" border="0" alt="YES - DELETE THIS UNIT" /></a>
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
<a href="portfolio.pl?folio=$folio"><img src="/gfx/deleteno.gif" border="0" alt="NO - LEAVE THIS UNIT ALONE!" /></a>
</div></div>
);
    print qq(</div></body></html>);    
}


sub header {
<<HEAD
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" >
<meta HTTP-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT">
<meta HTTP-equiv="Pragma" content="no-cache">
<meta HTTP-equiv="Cache-Control" content="no-cache">
<title>Informs Project :: Delete Unit</title>
<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css">
</head>
<body>
<div class=container>
<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />
<div id="breadcrumb">Intute Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a>  >  <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > delete unit</div>

HEAD
}