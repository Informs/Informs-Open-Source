#!/home/zzintadm/perl/bin/perl -wT


use strict;
use lib "./";

use InhaleCore qw( :DEFAULT getDate );
new InhaleCore;

use InhaleRead qw( getUnit getPage getObject );
use InhaleRender qw( inhaleRender );

my $folio  = $cgi->{'folio'} || '1';
my $render = $cgi->{'render'} || 'inhale';
my $unit   = getUnit( unit => $cgi->{'unit'}, folio => $folio );

print $cgi->{header};

my $stylesheet = $render.'_print.css';

print <<HEAD;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Intute Informs :: $unit->{folioUnitTitle}</title>
<link rel="stylesheet" href="$user->{pathHtmlVir}$stylesheet" type="text/css">
</head>
<body class="body_main"><div class="content">
HEAD

print '<p><div style="text-align:left;"><b>'.$unit->{folioUnitTitle}.'</b><br />['.getDate( format => 'dd/mm/yyyy' ).']</div></p>';

my $output = '';

foreach my $loop ( 1 .. $unit->{totalPages} ) {
    my $page = getPage( page => $loop, unit => $cgi->{'unit'} );

    my $object1 = getObject( object => $page->{leftFrame} );
    my $object2 = getObject( object => $page->{rightFrame} );

    if($loop == 1) {
	$output .= inhaleRender( object => $object2, 
	                            cgi => $cgi, 
	                           user => $user, 
	                         target => 'print_copy', 
	                        headers => 1, 
	                         render => $render );
	$output .= "<p><ol>";
	next;
    }

    if($page->{rightFrameURL}) {
    	$output .= qq(<li>Open the following web site address in your web browser:<p><b>$page->{rightFrameURL}</b></li>);
    }

    if($object1) {
        $output .= '<li>';
        $output .= inhaleRender( object => $object1, 
                                    cgi => $cgi, 
                                   user => $user, 
                                 target => 'print_copy', 
                                headers => 1, 
                                 render => $render );
        $output .= '</p>';
    }    
}

my $answers = '';
my $question = 0;

while($output =~ /\<!-- start /) {
    $question++;
    my($a, $b) = split(/\<!-- start /, $output, 2);
    my($c, $d) = split(/ --\>/, $b, 2);
    
    my($obj, $num, $correct) = split(/\|/, $c);
    
    $output = $a.qq(\n<p /><b>Question $question</b><br />).$d;
    $answers .= qq(<b>Question $question</b> - $correct<br />\n);
    
}

print $output;
print '</ol><p /><hr size="1">';

if($answers) {
    print qq(<p><b>ANSWERS TO QUESTIONS</b></p><p><dl><dd>$answers</dd></dl></p>);
    print qq(<p><hr size="1" /></p>);
}

print qq(<p><div style="text-align:right;">...this unit is available online at the following web site address: <b>$user->{pathToCGI}jump.pl?$folio-$unit->{unitNumber}</b></div></p>);
print "</body></html>";



