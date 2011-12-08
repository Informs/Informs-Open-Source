#!/usr/bin/perl -wT

print "Content-type: text/html\n\n";

use strict;
use lib "./";
use locale;

use InhaleCore;
new InhaleCore;

use InhaleRender qw( :render );
use InhaleRead qw( getObject );

my $object = getObject( object => $cgi->{object} );
my $render = $cgi->{render} || 'inhale' ;


print inhaleRender( object => $object, 
                    target => '_self', 
                   headers => 0, #
                    render => $render, 
                      user => $user,
                       cgi => $cgi );

print "\n\n";