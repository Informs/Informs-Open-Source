#!/usr/bin/perl -wT

##########
# render the index page for the portfolio
###

use strict;
use lib "./";

use diagnostics;

use InhaleCore;
new InhaleCore;

use InhaleRead qw( getUnit getPage getObject getFolioDetails );
use InhaleWrite qw ( copyUnit updatePortfolio );

use Digest::MD5 qw(md5_hex);

unless( $user->{userNumber} ) { InhaleCore::error('this page is only accessible to authenticated users'); }

if(!$cgi->{'unit'} || !$cgi->{'folio'} || !$cgi->{'from'}) { InhaleCore::error("parameter missing"); }

my $from = $cgi->{'from'};
my $folio = $cgi->{'folio'};
my $unitNo  = $cgi->{'unit'};

my %folioInfo = getFolioDetails( folio => $folio );

if($cgi->{'action'}) {
print $cgi->{header};

    my $unit = getUnit( unit => $unitNo, account => $folio );
    my $total = $unit->{totalPages};
    my $target = $cgi->{'copyinto'} || InhaleCore::error("parameter 'copyinfo' missing");
    
    my($targetFolio, $md5) = split(/ /, $target);
    
    my $md5check = genMD5($user->{userNumber}, $targetFolio);
    if($md5check ne $md5) { die "invalid MD5 hash detected ($md5check ne $md5)"; }
    
    my $reuse = ' ';

    foreach my $loop (1 .. $total) {
        if($cgi->{'q_'.$loop}) { $reuse .= "$loop "; }
    }

    my $newUnit = copyUnit( from => $from, 
                            into => $targetFolio, 
                            unit => $unitNo, 
                           reuse => " " );
    
    updatePortfolio( $targetFolio, 'hide', $newUnit );

print qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1" />
<title>Informs copy unit</title>
<link rel="stylesheet" href="/inhale.css" type="text/css" />
</head>
<body>
<div class=container>
<div id=breadcrumb>Informs > <a href="login2.pl?action=checkcookie&folio=$folio">portfolios</a>  >  <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > copy unit</div><br />);

    print qq(<div id="copy"><h2>Unit Copied</h2><b>$unit->{folioUnitTitle}</b> has been copied to <b>$folioInfo{portfolioName}</b>);

#New unit #$newUnit in portfolio #$targetFolio has been created from unit #$unitNo in portfolio #$from);
    print qq(<p /><a href="editunit.pl?unit=$newUnit&folio=$targetFolio">click here</a> to start editing your new unit.</div></body></html>);
    exit;
}
else 
{
print $cgi->{header};
    my $unit = getUnit( unit => $unitNo, folio => $folio );

    my $total = $unit->{totalPages};
    my %left = ();
    my %right = ();

print qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1" />
<title>Informs copy unit</title>
<link rel="stylesheet" href="../inhale.css" type="text/css" />
</head>
<body>
<div class=container>
<div id=breadcrumb>Informs > <a href="login2.pl?action=checkcookie&folio=$folio">portfolios</a>  >  <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > copy unit</div><br />);
print qq(<div align="left">);

    print qq(<form action="copyunit.pl"><input type="hidden" name="folio" value="$folio"><input type="hidden" name="from" value="$from"><input type="hidden" name="unit" value="$unitNo"><input type="hidden" name="action" value="yes">);

    my @folios = split( /\:/, $user->{userPortfolioList} );

    print qq(<div id="copy"><h2>Copy unit</h2>
<p>Select destination portfolio:</p><select name="copyinto">);

    foreach my $uFolio ( @folios )
    {
	if( $uFolio )
	{
	    my %uFolio = getFolioDetails( folio => $uFolio );
            my $md5 = genMD5( $user->{userNumber}, $uFolio );
	    print qq(<option value="$uFolio $md5">$uFolio{portfolioName} ($uFolio{portfolioAccountTitle})</option>\n);
	}
    }

    print qq(</select>);

    my $hyperlinks = 0;
    my @hyperlinks = ();
    
    foreach my $loop (1 .. $total) 
    {
        my $page = getPage( page => $loop, unit => $unitNo );
        
        my $stepNo = $loop - 1;

        my $leftFrame = 0;
        my $leftOwner = 0;
        my $rightFrame = 0;
        my $rightOwner = 0;
        my $rightURL = '';
        my $leftLink = '';
        my $rightLink = '';
        
        
       if( $page->{rightFrame} == 0 && $page->{rightFrameURL} ) 
	{
            $hyperlinks++;
            push @hyperlinks, $page->{rightFrameURL};
       }
       }

    
    print qq(<p />
<p>Copy unit <b>$unit->{folioUnitTitle}</b> to your selected portfolio.</p><input type="submit" class="submit" value="copy"></div></form>);
    
    
    if($hyperlinks ) {
	print "<p /><br /><p /><p />";

        if($hyperlinks) {
            print "<p />Hyperlinks used by this unit:<div align=left>";
            foreach (@hyperlinks) { print qq(<a href="$_">$_</a><br />); }
   	    print "</div>";    
	}    
    }


    print "<p /></div><br /><br /><p /><p /><br /><br /><p /><p /><br /><br /><p /><br /><br /><p /><p /><br /><br /><p /><p /><br /><br /><p /></body></html>";
}


sub genMD5 {
    my(@data) = @_;
    push @data, 'tHe SeCrEt PaSsPhRaSe! :-)';
    return(md5_hex(@data));
}
