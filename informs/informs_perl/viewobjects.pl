#!/home/zzintadm/perl/bin/perl -w

use strict;
use lib "./";
use InhaleCore qw( :DEFAULT convertDate );
unless(new InhaleCore( )) { die("access to this page is restricted to authorised users only\nplease log into your portfolio before accessing this page\n"); }

use InhaleRead qw( getAccountObjects );
use InhaleWrite qw( deleteObject );
print qq(Content-type: text/html\n\n);

my $action = $cgi->{action};
my $objectnum = $cgi->{objectnum} || '';;
my $acc = $user->{userAccountNumber};

if( $user->{userType} eq 'superadmin' && $cgi->{a} )
{
    $acc = $cgi->{a};
}

if($action =~/delete/){
    deleteObject( objectid => $objectnum );
}

print qq(<html><head><title>objects for account $user->{userAccountNumber}</title>
<style>
td,th { padding:2px 8px; font-size:80%; font-family:Arial,Verdana,Tahoma; }
td,th,table { border:1px solid #cccccc }
th { background:#DEFAE3; color:#007F71 }
</style>
<script language="JavaScript" type="text/javascript">
  function confirmDelete(anchor)
  {
    if (confirm('Delete this object?'))
    {
      anchor.href += '&action=delete';
      return true;
    }
    return false;
  }
</script>
</head><body>
<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />
<p>The following is a list of objects uploaded to your account</p>
<p />
<table cellpadding="2" border="1" cellspacing="0" width="100%">
<tr><th>object id</th><th>description</th><th>type</th><th>preview</th><th>delete</th></tr>
);

my @objects = getAccountObjects( account => $acc );

foreach ( @objects )
{
   my( $number,$desc,$type,$date,$path) = split(/\t/);

   unless( $desc ) { $desc = '<i>[ no description ]</i>' }

   my $creation = convertDate( time => $date, format => 'dd/mon/yyyy' ).' ('.convertDate( time => $date, format => 'hh:mm am/pm' ).')';

   my $p = qq(<a href="displayobject.pl?object=$number" target="_blank">click to view</a>);;
   my $l = qq(<a href="displayobject.pl?object=$number" target="_blank">$number</a>);

   if( $type eq 'GIF' || $type eq 'PNG' || $type eq 'JPG' )
   {
	$p = qq(<img src="$user->{pathObjectVir}$path" />);
	$l = $number;
   }

   print qq(<tr valign="top"><td align="center">$l</td><td>$desc</td><td>$type</td><td>$p</td><td><a href="viewobjects.pl?objectnum=$number" onclick="return confirmDelete(this);">delete</a></td></tr>);

}