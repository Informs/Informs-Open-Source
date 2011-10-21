#!/home/zzintadm/perl/bin/perl -WT

use strict;
use CGI::Carp qw(fatalsToBrowser);

use lib "./";

use Digest::MD5  qw(md5_hex);

use InhaleCore qw( :DEFAULT timeToRun untaint );
new InhaleCore();

use InhaleRead qw( validateUser getUserSession getAccountDetails getFolioDetails endSession getUserInfo getNumAccounts getNumLiveUnits);

require "confignew.pl";

    my @admins = getUserInfo( account => 'any', user => 'admin' );
    my %accs = ();
    foreach ( @admins )
    {
	my @b = split(/\t/);
	$accs{$b[6]} = $b[0];
    }

    my $select = '';

    foreach my $a ( sort keys %accs )
    {
    $select .= qq($a<br />\n); 
    }

my $numaccounts = getNumAccounts();
my $numlive = getNumLiveUnits();

headerregister();
print <<END1;

<h1>Informs Registered Users</h1>

<p>There are <strong>$numaccounts</strong> registered institutions with <strong>$numlive</strong> published tutorials.</p>

<p>$select</p>

END1

footer();
print <<END1;
</div>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-1139367-1";
urchinTracker();
</script>
</body>
</html>

END1
