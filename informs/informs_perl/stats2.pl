#!/home/zzintadm/perl/bin/perl -wT

use strict;
use lib "./";
use locale;
use Digest::MD5 qw(md5_hex);

use InhaleCore qw( :DEFAULT );
unless( new InhaleCore ) { deadParrot2("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw( statsSummary statsQuick lastEdited totalSteps lastViewed);

unless( $user->{userNumber} ) { deadParrot2("access to this page is restricted to authorised users only"); }

my $date  = $cgi->{a}     || deadParrot2('the following parameter is missing from your request: "a"');
my $folio = $cgi->{folio} || deadParrot2('the following parameter is missing from your request: "folio"');
my $subp  = $cgi->{b}     || '';

    $date =~ s/[^0-9:]//g;
    my($mon,$year) = split(/\:/, $date);

    my $fn = 'informs_stats_'.$folio.'_'.$year.'_'.$mon.'.csv';

    print qq(Content-Type:application/x-download\n);
    print qq(Content-Disposition: attachment; filename=$fn\n);
    print "Content-Description: This is a CSV file.\n\n";

    my $sub = 0;
    if( $subp ) { $sub = 1 }

    my @stats = statsSummary( month => $mon,
                               year => $year,
                              folio => $folio,
                          subfolios => $sub );

    print qq(Month,Portfolio,Unit,Title,,,,Number of Steps,,Last Edited,,Users,Hits, Last Viewed,,,\r\n);

    $mon = substr("00$mon",-2);

    my $tu = 0;
    my $th = 0;

##start foreach
foreach( @stats )
    {
	my @s = split(/\t/);

my $unit_edited = " ".lastEdited(unit => $s[0]."   "); 
my $totalsteps = totalSteps(unit => $s[0]);
my $lastviewed = " ".lastViewed(unit => $s[0]."   ");
if($lastviewed =~ /1970/){
$lastviewed='';
}

###add data to file
	print "$mon/$year,$s[1],$s[0],$s[4],,,,$totalsteps,,$unit_edited,,$s[2],$s[3],$lastviewed,,,\r\n";
	$tu += $s[2];
	$th += $s[3];

##end foreach
 }

    print qq(TOTAL,,,,,,,,,,,$tu,$th,\r\n);


sub deadParrot2 {
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

1;