#!/usr/bin/perl -wT

use strict;
use lib "./";

use InhaleCore qw( :DEFAULT timeToRun );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw( browseFolioUnits searchFolioUnits getUnit getFolioDetails );

my $search    = $cgi->{'txtbox'} || '';
my $userFolio = $cgi->{'folio'} || 1;
my %folioInfo = getFolioDetails( folio => $userFolio ); 

print $cgi->{header};
print head();

if($search){
my @units = browseFolioUnits( term => $search );

### DISPLAY UNITS...

if(@units ==0){
print "<b class=results>Sorry your search for <b class=search>".$search."</b> returned 0 results</b>";}
else{
print "<b class=results>Displaying ".@units." units with title starting with <b class=search><i>".$search."</i></b><br /><br />";
}
print "<table class=searchit>";  
    foreach my $line (@units) 
    {

        $line =~ s/[\r\n]//gi;
        my($temp, $objectID, $title, $description, $portfolio, $actionMethod, $visibility) = split(/\^\^/, $line);
        my $unit = getUnit( unit => $objectID );
	 my $portnum = $unit->{unitPortfolio};
	 my %searchfolioInfo = getFolioDetails( folio => $portnum ); 
        if(!$title || $title eq '') { $title = $unit->{unitTitle}; }
 
print qq(<tr><td><b class=search>$title</b></td><td class="copy"><a href="jump.pl?$userFolio-$objectID-inhale" title="view this unit">view unit</a> &nbsp;&nbsp;&nbsp;<a href="copyunit.pl?from=$userFolio&amp;unit=$objectID&amp;folio=$userFolio" title="make a copy of this unit">copy unit</a></td>
</tr>);   
print "<tr><td colspan=2>".$description."</td></tr>";
print "<tr><td colspan=2><b class=owner>owner :: ".$searchfolioInfo{portfolioName}."&nbsp;&nbsp; unit number :: $objectID</b></td></tr>";

if(@units >1){
print "<tr><td colspan=2><hr /></td></tr>";
}
    }
print "</table>";
 }

print foot();

sub head {
my($text, $folio) = @_;

<<HEAD 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html lang="en">
<head>
<title>Informs Search units</title>
<link rel="stylesheet" href="/SAMPLE.css" type="text/css">
</head>
<body>
<div class="container">

<div id="breadcrumb">Informs> <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a> > <a href="portfolio.pl?folio=$userFolio">$folioInfo{portfolioName}</a> > browse</div>                 
<p>Display units with titles starting with ...</p>

<a href="search2.pl?folio=$userFolio&txtbox=a">A</a> |
<a href="search2.pl?folio=$userFolio&txtbox=b">B</a> |
<a href="search2.pl?folio=$userFolio&txtbox=c">C</a> |
<a href="search2.pl?folio=$userFolio&txtbox=d">D</a> |
<a href="search2.pl?folio=$userFolio&txtbox=e">E</a> |
<a href="search2.pl?folio=$userFolio&txtbox=f">F</a> |
<a href="search2.pl?folio=$userFolio&txtbox=g">G</a> |
<a href="search2.pl?folio=$userFolio&txtbox=h">H</a> |
<a href="search2.pl?folio=$userFolio&txtbox=i">I</a> |
<a href="search2.pl?folio=$userFolio&txtbox=j">J</a> |
<a href="search2.pl?folio=$userFolio&txtbox=k">K</a> |
<a href="search2.pl?folio=$userFolio&txtbox=l">L</a> |
<a href="search2.pl?folio=$userFolio&txtbox=m">M</a> |
<a href="search2.pl?folio=$userFolio&txtbox=n">N</a> |
<a href="search2.pl?folio=$userFolio&txtbox=o">O</a> |
<a href="search2.pl?folio=$userFolio&txtbox=p">P</a> |
<a href="search2.pl?folio=$userFolio&txtbox=q">Q</a> |
<a href="search2.pl?folio=$userFolio&txtbox=r">R</a> |
<a href="search2.pl?folio=$userFolio&txtbox=s">S</a> |
<a href="search2.pl?folio=$userFolio&txtbox=t">T</a> |
<a href="search2.pl?folio=$userFolio&txtbox=u">U</a> |
<a href="search2.pl?folio=$userFolio&txtbox=v">V</a> |
<a href="search2.pl?folio=$userFolio&txtbox=w">W</a> |
<a href="search2.pl?folio=$userFolio&txtbox=x">X</a> |
<a href="search2.pl?folio=$userFolio&txtbox=y">Y</a> |
<a href="search2.pl?folio=$userFolio&txtbox=z">Z</a> |

<div id="searchbox"><h2>Search all units</h2>
<form method="get" action="search.pl">
<input type="text" name="txtbox" value="$text" size="30">
<input type="hidden" name="folio" value="$userFolio">

<h3>Optional filters</h3>
<p>
Units last edited  
<select name="searchmonths">
<option value=""></option>
<option value="thismonth">this month</option>
<option value="last3months">last 3 months</option>
<option value="last6months">last 6 months</option>
</select>
<br /><br />
<input type="checkbox" name="imagesyes" value="yes" > Search image database only</p>
<input type="submit" value="search" class="submit">
</form>
</div><p/><br />

HEAD
}

sub foot {

<<FOOT
</div><br /><br /><br /><br /><br /><br /><br /><br />
<br /><br /><br /><br /><br /><br /><br /><br />
</div><br /><br /><br /><br /><br /><br /><br /><br />
<br /><br /><br /><br /><br /><br /><br /><br />
</body></html>
FOOT

}

1;