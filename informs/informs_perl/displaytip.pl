#!/home/zzintadm/perl/bin/perl -wT

use strict;
use lib "./";

use InhaleCore;
new InhaleCore;

use InhaleRead qw( getObject getObjectData );
use InhaleRender qw( inhaleRenderText inhaleRender );

my $render= $cgi->{render} || 'inhale';
my $tip = $cgi->{'tip'} || 0;

if($cgi->{'object'} == 4 && $tip < 1) { 
    my $object = getObject( object => $cgi->{'object'});

    my $render = inhaleRender( object => $object, 
                                  cgi => $cgi, 
                                 user => $user, 
                               target => 'inhale_main', 
                              headers => 0, 
                               render => $render );

    print $render;

    print "\n\n\n</body></html>\n\n\n\n\n\n\n\n\n";    

}
elsif($cgi->{'object'}) {

    my $object = getObject( object => $cgi->{'object'});
    my $output = getObjectData( object => $object );
    my ($tipText,$tipHeading) = split(/\^/, findTip($tip, $output));    
 
    $tipText = '[h]TIP: '.uc($tipHeading).'[/h]'."\n\n".$tipText.'<p>';


    my $render = inhaleRenderText( text => $tipText, 
                                    cgi => $cgi, 
                                   user => $user, 
                                 target => '_self', 
                                headers => 0, 
                                 render => $cgi->{'render'}, 
                                   type => 'popup' );
    
    print $render;
    
print <<CLOSE;
    
<script type="text/javascript" language="JavaScript">
<!--
    var message = '<p align="right">[ <a onClick="self.close();" href="#">close tip window</a> ]';
    document.write(message);
// -->
</script>
<noscript>
<p><b>Once you have finished reading this, you can close the tip window.</b></p>
</noscript>
</div>
</body></html>

CLOSE
       
}
else {
    print $cgi->{'header'};
}

print "\n\n\n\n\n\n\n\n\n\n";

sub findTip {
    my($tipToFind, $text) = @_;
    my($cnt, $tipNumber) = 0;
    my($return, $tipHeader) = '';
    my($dat, $pre, $aft);

    my $crlf = chr(255);

    $text =~ s/\r//g;
    $text =~ s/\n/$crlf/g;
    
    while($text =~ /\[t/i) {
        $tipNumber++;
        $cnt++; if($cnt > 100) {last}
        
        ($pre, $dat) = split(/\[t/i, $text, 2);
        ($tipHeader, $dat) = split(/\]/, $dat, 2);
        $tipHeader =~ s/\://g;
        
        if($tipHeader ne '') {
            $tipHeader = ' '.$tipHeader;
        }
        
        ($dat,$aft) = split(/\[\/t\]/i, $dat, 2);
        $dat =~ s/^ //g;
        $dat =~ s/ $//g;

        $text = $pre.' '.$dat.' '.$aft;
        if($tipNumber == $tipToFind) {
            $return = $dat.'^'.$tipHeader;
        }
    }
    $return =~ s/$crlf/\n/g;
    return($return);
}
