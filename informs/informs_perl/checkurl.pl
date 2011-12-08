#!/usr/bin/perl -wT

use strict;
use lib "./";

use InhaleCore;
new InhaleCore;

use LWP::UserAgent;

my $url = $cgi->{'url'};

print $cgi->{'header'};
print qq(<html><head><title>URL check</title></head><body onLoad="self.focus();"><font size="2">);
print qq(checking:<br /><a href="$url" target="_blank">$url</a><p />);

 
my $ua = LWP::UserAgent->new;    
$ua->proxy('http', 'http://wwwproxy.hud.ac.uk:3128');
$ua->timeout(10);


my $request = HTTP::Request->new('HEAD', $url);    
my $response = $ua->request($request);     


print "The server returned a HTTP status code of ".$response->code();

if($response->is_success) { print "<p /><b>The URL was fetched successfully!</b>"; }
elsif($response->is_redirect) { print "<p /><b>The web server has repsonded that the URL does not exist, and is trying to redirect you to another web page.</b><p />You may wish to manually check the URL."; }
elsif($response->is_error) { print qq(<p /><b style="color:red">The web server has reported that the URL does not exist, and has returned an error code.</b><p />You should manually check that the URL is valid.); }





