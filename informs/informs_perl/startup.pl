#!/usr/bin/perl -wT

use strict; 

use lib qw( /YOUR/PATH/TO/informs/informs_perl  /YOUR/PATH/TO/informs/informs_perl/lib ); 
     
use Digest::MD5 ();
use HTTP::BrowserDetect ();

use CGI (); 
CGI->compile( qw( param cookie ) );

use InhaleCore (); 
use InhaleRead (); 
use InhaleWrite ();
use InhaleRender (); 


1;

