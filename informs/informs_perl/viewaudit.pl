#!/home/zzintadm/perl/bin/perl -wT


use strict;
use lib "./";
use InhaleCore qw( :DEFAULT convertDate );
new InhaleCore;
use InhaleRead qw( getAudit getQuickUserInfo );
print "Content-Type: text/html; charset=ISO-8859-1\n\n";

my $object = $cgi->{a} || '';
my $type   = $cgi->{b} || '';

my $max = 70;

my @audit  = getAudit($object, $type);

print qq(<html><head><title>audit trail for $type #$object</title></head><body onload="self.focus();"><pre style="font-family: Lucida Console; font-size:70%">);

print "    time   account/user      IP address   action performed\n";
print "========   ============   =============   ================\n";

my $prev = 0;
my $pdat = 0;

my %users = ( );

foreach my $line (@audit) {
    $line =~ s/[\r\n]//gi;
    my($time, $account, $user, $ip, $mess) = split(/\t/, $line);
    
    $users{"$account|$user"} = 1;

    if($time - $prev > 10) { print "\n"; }
    
    my $date = convertDate( time => $time, format => 'dd/mon/yyyy' );
    

    if($pdat eq $date && $pdat) { 
        $pdat = $date;
        $date = "       ";
    }
    else {
        print "<font color=blue>          --------==[ $date ]==--------</font>\n\n";
        $pdat = $date;
    }
        
    $prev = $time;
    print substr("      ".convertDate( time => $time, format => 'hh:mm:ss' ), -8);
    print substr("                            $account/$user",-15);
    print "  ".substr("                            $ip",-15)."  ";
    
    if(length($mess) > $max) {
        my @words = split(/ /, $mess);
        my $x = '';
        my $y = '';
        foreach my $word (@words) {
            if($y || length($x.$word) > $max) {
                $y .= "$word ";
            }
            else {
                $x .= "$word ";
            }
            $mess = "$x\n                                          $y";
        }
    }
    if($mess =~ /delete/) { print "<font color=red>$mess</font>\n"; }
    elsif($mess =~ /insert(ed)?/) { print "<font color=green>$mess</font>\n"; }
    elsif($mess =~ /created?/) { print "<font color=green>$mess</font>\n"; }
    else { print "$mess\n"; }
       
}    

print qq(\n\n<hr />\n\nUser Information:\n\n);

foreach ( sort keys %users )
{
    my($a,$u) = split(/\|/);

    my($an,$un) = getQuickUserInfo( $a,$u);

    unless($un) { $un = 'unknown user' }
    unless($an) { $an = 'unknown account' }

    print substr("                    $a/$u",-15)." : $an - $un\n";
}

print qq(\n\n</pre></body></html>);