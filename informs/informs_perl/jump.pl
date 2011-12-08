#!/usr/bin/perl -wT

##########
# render the index page for the portfolio
###

use strict;
use diagnostics;
use lib "./";

use InhaleCore qw(:DEFAULT urldecode);
new InhaleCore;

use InhaleRead qw( getFolioUnits );

##########
# pick up incoming data
###

my $qs = urldecode($ENV{QUERY_STRING});

$qs =~ s/\W/_/gi;

$qs =~ s/^\_*//gi;
$qs =~ s/\_*$//gi;

while($qs =~ /__/) { $qs =~ s/__/_/gi; }

my @data = split(/_/, $qs);


my $render = $data[2] || 'inhale';
my $folio = $data[0];
my $unit = $data[1];
my $type = $data[3];

if($render ne 'inhale' && $render !~ /^\d\d\d\d$/) {
    if($render eq 'new') { $type = 'new'; }
    $render = 'inhale';
}

my @units = getFolioUnits( folio => $folio);

if(!scalar(@units)) {
   # @units = fetchFolioUnits(1);
}

my $server = $user->{pathToCGI};

if( $user->value('accountID') ) {
    $server = $user->{pathToCGI};
}

my $script = 'page.pl';

if($type eq 'new') { $script = 'page.pl'; }

foreach my $line (@units) {
    $line =~ s/[\r\n]//gi;
    my($temp, $objectID, $title, $description, $actionMethod) = split(/\^\^/, $line);
    my $unitID = $objectID;

    if($unitID eq $unit) {
        my $action = 'init';
        if($actionMethod eq 'noframes+js') { $action = 'initnoframes1'; }

        my $link = $server.$script.'?action='.$action.'&render='.$render.'&unit='.$objectID.'&page=1&folio='.$folio.'&id='.$user->{userID};

	print "Location: $link\n\n";
	exit;
    }
}

my $link = $server.$script.'?action=&render='.$render.'&unit='.$unit.'&page=1&folio=&id='.$user->{userID};

print "Location: $link\n\n";

