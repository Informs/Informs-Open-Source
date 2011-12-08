#!/usr/bin/perl -wT

use strict;
use lib "./";

use InhaleCore;
new InhaleCore;

use InhaleRender qw( :colourscheme );


my $render = $cgi->{'render'};
my $folio  = $cgi->{'folio'} || '1';
my $digest = $user->{'userID'};


if($render !~ /\d\d\d\d/) { $render = '5147'; }


my $css = generateStylesheet( $render );


print $cgi->{'header'};

print <<HEAD;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="en">
<head><title>Colour Scheme Selector</title>
$css
</head>
<body>


HEAD

my $textColour = $accessibleTextColour[substr($render,0,10)] || '#000000';

print qq(This page allows you to change the <a href="#1">text colours</a>, <a href="#2">link colour</a>, <a href="#3">font size</a> and <a href="#4">font typeface</a>.);
print qq(<p />Once you are happy with your choices, please <a href="portfolio.pl?folio=$folio&id=$digest&render=$render">click here</a>.);
print qq(<p /><form>Your current selection has the code <b>$render</b>.  &nbsp;If you can remember the code you used last time, you can enter it in the box here below:);
print qq(<p />&nbsp;&nbsp;&nbsp;<input type="text" name="render" maxlength="4" size="4" style="border:solid 5px $textColour; align:center; font-size: 100%; font-family: monospace" />&nbsp;<input style="font-size:100%; font-family: monospace" type="submit" value="change"></form><p />);
print qq(<p />If you would prefer to use the default colours and fonts, please <a href="portfolio.pl?folio=$folio&id=$digest&render=inhale">click here</a>.);


print q(<p /><br /><dl><a name="1"></a><dt>1. Change the text and background colours:<p /></dt>);
print "<dd>";

foreach my $num (0 .. 9) {
    if(!$accessibleTextColour[$num]) { next; }
    my $newRender = $num.substr($render,1,3);
    if($num == substr($render, 0, 1)) { next; }
    print qq(<a href="colourscheme.pl?render=$newRender&folio=$folio&id=$digest">change</a>&nbsp;to:&nbsp;<span style="border:solid $accessibleTextColour[$num] 2px; padding:5px; color:$accessibleTextColour[$num]; background-color:$accessibleBackgroundColour[$num]">&nbsp;The&nbsp;quick&nbsp;brown&nbsp;fox&nbsp;</span><p />\n);
}

print "<br />&nbsp;</dd>";

print q(<a name="2"></a><dt>2. Change the link colours:<p /></dt>);
print "<dd>";

foreach my $num (0 .. 9) {
    if(!$accessibleLinkColour[$num]) { next; }
    my $newRender = substr($render,0,1).$num.substr($render,2,2);
    if($num == substr($render, 1, 1)) { next; }
    print qq(<span style="padding:5px;"><a href="colourscheme.pl?render=$newRender&folio=$folio&id=$digest">change</a><span style="color:$accessibleLinkColour[$num];">&nbsp;<u>to&nbsp;this&nbsp;colour</u></span></span><p />\n);
}


print "<br />&nbsp;</dd>";

print q(<a name="3"></a><dt>3. Change the font size:<p /></dt>);
print "<dd>";

foreach my $num (0 .. 5) {
    my $newRender = substr($render,0,2).$num.substr($render,3,1);
    if($num == substr($render, 2, 1)) { next; }
    print qq(<span style="padding:5px; font-size: $accessibleFontSize[$num]"><a href="colourscheme.pl?render=$newRender&folio=$folio&id=$digest">change&nbsp;to&nbsp;to&nbsp;this&nbsp;size</a></span><p />\n);
}

print "<br />&nbsp;</dd>";

print q(<a name="4"></a><dt>4. Change the font type face:<p /></dt>);
print "<dd>";

foreach my $num (0 .. 9) {
    my $newRender = substr($render,0,3).$num;
    if($num == substr($render, 3, 1)) { next; }
    print qq(<span style="padding:5px;"><a href="colourscheme.pl?render=$newRender&folio=$folio&id=$digest">change</a>&nbsp;to:&nbsp;<span style="font-family: $accessibleFontType[$num]">$accessibleFontType[$num]</span></span><p />\n);
}

print "</dd></dl>";

print "...this feature may require the relevant fonts to already installed on your computer";

