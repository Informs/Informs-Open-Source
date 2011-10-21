#!/home/zzintadm/perl/bin/perl -wT

use strict;
use lib "./";
use CGI;    
use InhaleCore qw( :DEFAULT timeToRun );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw( searchFolioUnits getUnit getFolioDetails searchByDate searchWithImages);

my $q = new CGI;         
my $search = $q->param('txtbox');
my $dateselect = $q->param('searchmonths') || "";
my $imagesearch = $q->param('imagesyes') || "no";
my $userFolio = $q->param('folio') || 1;
my %folioInfo = getFolioDetails( folio => $userFolio ); 

print $cgi->{header};
print head();

my @stopwords = ("of","in","it","the","with","an","uk","to","is");
if (grep (/$search/i, @stopwords)) {
exit(0);
}
##### search within months and images #####
if($search && $dateselect && $imagesearch =~ /yes/){
print "Unfortunately it is not possible to restrict the image search by date edited.";
my @units = searchFolioUnits( term => $search );
}

##### search within months #####
elsif($search && $dateselect && $imagesearch =~ /no/){
#print "with dates ".$dateselect." ";
my @units = searchByDate( term => $search, period => $dateselect);

### DISPLAY UNITS...
if(@units ==0){
print "<b class=results>Sorry your search for <b class=search>".$search."</b> returned 0 results</b>";
}
else{
print "<b class=results>Your search for <b class=search><i>".$search."</i></b> returned ".@units." results</b><br /><br />";
}
print "<table class=searchit>";  
    foreach my $line (@units) 
    {
	 my $portfolio="";
	 my $portnum="";
	 my $searchfolioInfo="";
        $line =~ s/[\r\n]//gi;
        my($temp, $objectID, $title, $description, $portfolio, $actionMethod, $edited) = split(/\^\^/, $line);
        my $unit = getUnit( unit => $objectID );
	 my $portnum = $unit->{unitPortfolio};
	 my %searchfolioInfo = getFolioDetails( folio => $portnum ); 
        if(!$title || $title eq '') { $title = $unit->{unitTitle}; }
 
	 print qq(<tr><td><b class=search>$title</b></td><td class="copy"><a href="jump.pl?$userFolio-$objectID-inhale" title="view this unit">view unit</a> &nbsp;&nbsp;&nbsp;<a href="copyunit.pl?from=$portnum&amp;unit=$objectID&amp;folio=$userFolio" title="make a copy of this unit">copy unit</a></td>
	 </tr>);   
	 print "<tr><td colspan=2>".$description."</td></tr>";
	 print "<tr class=bottom><td colspan=2><b class=owner>owner :: ".$searchfolioInfo{portfolioName}."&nbsp;&nbsp; unit number :: $objectID";
	 if($edited){
	 print "&nbsp;&nbsp; last edited :: $edited</b></td></tr>";
	 }
	 else{
	 print "</b></td></tr>";
	 }
	 if(@units){
	 print "<tr><td colspan=2><hr class=bottom /></td></tr>";
	 }
    }
print "</table>";
##### end search within months #####
}

##### search with images #####
elsif($search && $imagesearch =~ /yes/){
my @units = searchWithImages( term => $search );
### DISPLAY UNITS...
if(@units ==0){
print "<b class=results>Sorry your search for <b class=search>".$search."</b> returned 0 results</b>";}
else{
print "<b class=results>Your search for <b class=search><i>".$search."</i></b> in the image database returned ".@units." results</b><br /><br />";
}
print "<table class=searchit>";  
    foreach my $line (@units) 
    {
	my $portfolio="";
	my $portnum="";
	my $searchfolioInfo="";
        $line =~ s/[\r\n]//gi;
        my($temp, $objectid, $filename, $description, $filetype) = split(/\^\^/, $line);
 
print qq(<tr><td><b class=search>Image id</b></td><td>$objectid</td><td class="copy"><img src="/objects/$filename" alt="$description" /></td>
</tr>);   
print qq(<tr class=bottom><td><b class=search>Description</b></td><td colspan=2>$description</td></tr>);

if(@units){
print "<tr><td colspan=3><hr class=bottom /></td></tr>";
}
    }
print "</table>";
##### end basic search with images #####
}

##### basic search #####
elsif($search && $dateselect !=~/[a-z]/ && $imagesearch =~ /no/){
#print "normal search";
my @units = searchFolioUnits( term => $search );
### DISPLAY UNITS...
if(@units ==0){
print "<b class=results>Sorry your search for <b class=search>".$search."</b> returned 0 results</b>";}
else{
print "<b class=results>Your search for <b class=search><i>".$search."</i></b> returned ".@units." results</b><br /><br />";
}
print "<table class=searchit>";  
    foreach my $line (@units) 
    {
	my $portfolio="";
	my $portnum="";
	my $searchfolioInfo="";
        $line =~ s/[\r\n]//gi;
        my($temp, $objectID, $title, $description, $portfolio, $actionMethod, $edited) = split(/\^\^/, $line);
	 my $unit = getUnit( unit => $objectID );
	 my $portnum = $unit->{unitPortfolio};
	 my %searchfolioInfo = getFolioDetails( folio => $portnum );
        if(!$title || $title eq '') { $title = $unit->{unitTitle}; }
 
	 print qq(<tr><td><b class=search>$title</b></td><td class="copy"><a href="jump.pl?$userFolio-$objectID-inhale" title="view this unit">view unit</a> &nbsp;&nbsp;&nbsp;<a href="copyunit.pl?from=$userFolio&amp;unit=$objectID&amp;folio=$userFolio" title="make a copy of this unit">copy unit</a></td>
	 </tr>);   
	 print "<tr><td colspan=2>".$description."</td></tr>";
	 print "<tr><td col span=2><b class=owner>owner :: ".$searchfolioInfo{portfolioName}."&nbsp;&nbsp; unit number :: $objectID";

	 if($edited){
	 print "&nbsp;&nbsp; last edited :: $edited</b></td></tr>";
	 }
	 else{
	 print "</b></td></tr>";
	 }

	 if(@units){
	 print "<tr><td colspan=2><hr class=bottom /></td></tr>";
	 }
    }
print "</table>";
##### end basic search #####
}

print foot();

sub head {
my($text,$folio) = @_;

<<HEAD 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html lang="en">
<head>
<title>Informs Search units</title>
<link rel="stylesheet" href="../inhale.css" type="text/css">
</head>
<body>
<div class="container">
<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />
<div id="breadcrumb">Intute Informs> <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a> > <a href="portfolio.pl?folio=$userFolio">$folioInfo{portfolioName}</a> > search</div>                 

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
</div></p><br />

HEAD
}

sub foot {
<<FOOT
</div>
</div>
</div>
</body></html>
FOOT
}

1;