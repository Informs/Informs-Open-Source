#!/usr/bin/perl -wT

use strict;
use lib "./";
use locale;

use Digest::MD5 qw(md5_hex);

use InhaleCore qw( :DEFAULT );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRead qw( statsQuick );

unless( $user->{userNumber} ) { deadParrot("access to this page is restricted to authorised users only"); }

my $unitNo = $cgi->{unit}   || deadParrot('the following parameter is missing from your request: "unit"');
my $action = $cgi->{a}  || deadParrot('the following parameter is missing from your request: "a"');

print $cgi->{header};

print qq(<html><head><title>stats</title>
<style>
body,th,td { font-size:75%; font-family:Verdana,Tahoma,Arial; }
td,th { padding:3px 10px }
</style></head>
<body onload="self.focus();">
);

if( $action eq 'quick' )
{
    my %s = statsQuick( unit => $unitNo );

    my $p = '';

    print qq(<div align="center">jump: );

    foreach my $mon ( sort keys %s )
    {
	my $year  = substr($mon,0,4);

	if( $year ne $p ) 
	{
	    print qq(<a href="#$year">$year</a> &#183; );
	    $p = $year;
	}
    }

    print qq(<a href="#total">total</a>);

    print qq(<p /><table cellpadding="4" cellspacing="0" border="0" style="border:1px solid black">);
    print qq(<tr align="middle" style="background:#333;color:#FFF;"><th>month</th><th>hits</th><th>users</th><th colspan="4">&nbsp;</th></tr>);

    my %final = ( );

    foreach my $mon ( sort keys %s )
    {
	my $year  = substr($mon,0,4);
	my $month = substr($mon,4,2);

	$month = substr("JanFebMarAprMayJunJulAugSepOctNovDec",($month*3)-3,3);

	my @s = split( /\|/, $s{$mon} );

	my $tot = shift @s;
	my $ses = shift @s;
	my $stp = shift @s;

	$final{'tot'} += $tot;
	$final{'ses'} += $ses;
	$final{'stp'} = $stp;

	unless( $ses ) { next }

	print qq(<tr style="background:#FF9; font-weight:bold;" align="middle"><td><a name="$year"></a>$month $year</td><td>$tot</td><td>$ses</td><td style="background:#666;color:#FFF;">page</td><td style="background:#666;color:#FFF;">hits</td><td style="background:#666;color:#FFF;">users</td><td style="background:#666;color:#FFF;">%</td></tr>);		

	my $started = $ses;
	unless( $started ) { next }

	foreach my $l ( 1 .. $stp )
	{
	    my( $s, $t ) = split( /\^/, $s[$l-1] );
	    my $p = int(( ( $s / $started ) * 100 ) + 0.5 );

	    my $pagen = $l-1;
	    if( $pagen == 0 ) { $pagen = 'intro' }
	    print qq(<tr align="right"><td colspan="3">&nbsp;</td><td style="background:#999;color:#FFF;"><b>).qq($pagen</b></td><td style="background:#FF9">$t</td><td style="background:#FF9">$s</td><td style="background:#FF9">$p%</td></tr>);
	    $final{"step $l"} += $s;
	    $final{"step hits $l"} += $t;
	}
    }

    print qq(<tr align="middle" style="background:#333;color:#FFF;"><th><a name="total"></a>TOTAL</th><th>hits</th><th>users</th><th colspan="4">&nbsp;</th></tr>);
    print qq(<tr style="background:#FF9; font-weight:bold;" align="middle"><td>&nbsp;</td><td>$final{tot}</td><td>$final{ses}</td><td style="background:#666;color:#FFF;">page</td><td style="background:#666;color:#FFF;">hits</td><td style="background:#666;color:#FFF;">users</td><td style="background:#666;color:#FFF;">%</td></tr>);		
    foreach my $l ( 1 .. $final{stp} )
    {
	my $pagen = $l-1;
	if( $pagen == 0 ) { $pagen = 'intro' }
	my $p = int(( ( $final{"step $l"} / $final{ses} ) * 100 ) + 0.5 );
	print qq(<tr align="right"><td colspan="3">&nbsp;</td><td style="background:#999;color:#FFF;"><b>).qq($pagen</b></td><td style="background:#FF9">).$final{"step hits $l"}.qq(</td><td style="background:#FF9">).$final{"step $l"}.qq(</td><td style="background:#FF9">$p%</td></tr>);
    }

    print qq(</table><p /><br /><input type="button" value="close" onclick="self.close()" /></div><div style="height:500px"></div></body></html>);
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

1;