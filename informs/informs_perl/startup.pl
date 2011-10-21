use strict; 

use lib qw( /home/zzintadm/html/informs/informs_perl  /home/zzintadm/html/informs/informs_perl/lib ); 
     
use Digest::MD5 ();
use HTTP::BrowserDetect ();

use CGI (); 
CGI->compile( qw( param cookie ) );

use InhaleCore (); 
use InhaleRead (); 
use InhaleWrite ();
use InhaleRender (); 


1;

