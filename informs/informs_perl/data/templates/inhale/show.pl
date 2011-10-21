#!/usr/bin/perl -wT

use strict;

use CGI;
use CGI::Carp qw(fatalsToBrowser);

print "Content-type: text/html\n\n";

print q(<html><head><title>templates</title></head><body>);

open(IN,"guide.html");
my @temp = <IN>;
close(IN);
print q(<b>Guide at the Side template:</b><p>);
print q(<blockquote><pre>);
print makeSafe(@temp);
print q(</pre></blockquote>);

open(IN,"main.html");
my @temp = <IN>;
close(IN);
print q(<b>Main frame template:</b><p>);
print q(<blockquote><pre>);
print makeSafe(@temp);
print q(</pre></blockquote>);

print q(</body></html>);

sub makeSafe {
    my(@txt) = @_;
    my $ret = '';
    foreach my $line (@txt) {
        $line =~ s/[\r\n]//gi;
        $line =~ s/&/&amp;/gi;
        $line =~ s/\</&lt;/gi;
        $line =~ s/\>/&gt;/gi;
        $line =~ s/\{\{/\<font color="red"\>\{\{/gi;
        $line =~ s/\}\}/\}\}\<\/font\>/gi;
        $ret .= $line."\n";
    }
    return($ret);


}