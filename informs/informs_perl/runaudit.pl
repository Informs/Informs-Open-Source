#!/home/zzintadm/perl/bin/perl -w

    use strict;
    use DBI;

use lib "./";

use InhaleCore qw( :DEFAULT timeToRun getDate untaint );
new InhaleCore;

use InhaleRead qw( getObject getUnit getPage readMetadata );
use InhaleWrite qw( insertStats );
use InhaleRender qw( generateStylesheet inhaleRender inhaleRenderText getPageCache addPageCache );

    $| = 1;

    print "Content-type: text/html\n\n";

    print qq(<html><head>
<style>
body { font-size:80%; font-family:Verdana,Tahoma,Arial }
b { color:#F00 }
</style>
</head><body>);

    my $server = lc($ENV{SERVER_SOFTWARE});
    $server =~ s/[^a-z0-9]//gi;
    my $iniFile = '';

    foreach my $path (@INC) {
        if(open(IN,"$path/$server-inhale.ini")) { $iniFile = "$path/$server-inhale.ini"; }
        if(open(IN,"$path/inhale.ini"))         { $iniFile = "$path/inhale.ini"; }
    }

    unless($iniFile) { die("unable to locate INI file [inhale.ini or $server-inhale.ini]"); }
    my $time = time( );
    my $mysqlServer;
    my $mysqlDatabase;
    my $mysqlUsername;
    my $mysqlPassword;
    my $mysqlPort;
    my $dataPath = '';
    my $uploadPath = '';
    my $objectPath = '';
    my $objectVirPath = '';

    open(IN,$iniFile);
    while(my $line = <IN>) {   
        $line =~ s/[\r\n]//gi;
        if($line && $line !~ /^\#/) {
            my($a,$b) = split(/\=/, $line);
            $a =~ s/ //gi;
            $a = lc($a);
            $b =~ s/^\s+?//gi;
            if($a eq 'datapath')                { $dataPath = $b; }
            if($a eq 'uploadpath')              { $uploadPath = $b; }
            if($a eq 'objectpath')              { $objectPath = $b; }
            if($a eq 'objectvirtualpath')       { $objectVirPath = $b; }

	    if( $a eq 'mysqlport' )         { $mysqlPort = $b }
	    if( $a eq 'mysqlserver' )       { $mysqlServer = $b }
	    if( $a eq 'mysqldatabase' )     { $mysqlDatabase = $b }
	    if( $a eq 'mysqlusername' )     { $mysqlUsername = $b }
	    if( $a eq 'mysqlpassword' )     { $mysqlPassword = $b }
        }
    }

    my $dsn = "DBI:mysql:database=$mysqlDatabase;host=$mysqlServer;port=$mysqlPort";
    my $dbh = DBI->connect( $dsn, $mysqlUsername, $mysqlPassword, { 'ShowErrorStatement' => 1, } );
    unless( $dbh ) { die('Informs database is currently unavailable') }

    my %accounts = ( );    
    my %folios   = ( );    
    my %units    = ( );
    my %objects  = ( );
    my %orphans  = ( );
    my %files    = ( );
    my %fnames   = ( );
    my %cdate    = ( );

    my @sql = ( );

    my $log = '';

    print qq(<p />reading accounts...<ul>);
    {
        my $sth = $dbh->prepare(  "SELECT account FROM accounts ORDER BY account"  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
	{
	    $accounts{$res[0]} = 1;
	}
	$sth->finish( );
    }
    print qq(</ul>);
    print qq(<p />reading portfolios...<ul>);
    {
        my $sth = $dbh->prepare(  "SELECT portfolio,account FROM portfolios ORDER BY portfolio"  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
	{
	    unless( $accounts{$res[1]} ) { error("<b>portfolio $res[0] linked to non existent account $res[1]</b>") }
	    $folios{$res[0]} = $res[1]; 
	}
	$sth->finish( );
    }
    print qq(</ul>);
    print qq(<p />reading units...<ul>);
    {
        my $sth = $dbh->prepare(  "SELECT unit,portfolio FROM units ORDER BY unit"  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
	{
	    unless( $folios{$res[1]} ) { error("<b>unit $res[0] linked to non existent portfolio $res[1]</b>") }
	    $units{$res[0]} = $res[1]; 
	}
	$sth->finish( );
    }
    print qq(</ul>);
    print qq(<p />reading steps...<ul>);
    {
        my $sth = $dbh->prepare(  "SELECT unit,step,leftFrame,rightFrame FROM steps ORDER BY unit"  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
	{
	    unless( $units{$res[0]} ) { error("<b>non existent unit $res[0] appears in steps table</b>") }
	    if( $res[2] )             { $objects{$res[2]} = $res[0] }
	    if( $res[3] )             { $objects{$res[3]} = $res[0] }
	}
	$sth->finish( );
    }
    print qq(</ul>);
    print qq(<p />reading objects...<ul>);
    {
        my $sth = $dbh->prepare(  "SELECT object,owner,deleted,filename,readonly,creationTimeStamp FROM objects ORDER BY object"  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
	{
	    if( $objects{$res[0]} && $res[2] )
	    { 
		error("<b>object $res[0] was earmarked for deletion, but is actually in use by unit $objects{$res[0]} - removing deletion flag!</b>");
		push @sql, "UPDATE objects SET deleted=0 WHERE object=$res[0]";
	    }
	    unless( $accounts{$res[1]} ) { error("object $res[0] owned by non existent account $res[1]") }
	    unless( $objects{$res[0]} ) {
	  	if( !$res[2] && $res[4] ) { error("object $res[0] might be an orphan, but is marked <b>read only</b> in the table") }
		elsif( $res[2] ) {  error("object $res[0] might be an orphan, but is earmarked for deletion ($res[2])") }
		elsif( $res[5] > ( $time - ( 60*60*24*30*3 ) ) )
		{
		    error("<b>object $res[0] might be an orphan, but it was created recently</b>");
		}
		else 
		{
		    error("object $res[0] might be an orphan");
		    $orphans{$res[0]} = 1;
	 	}
	    }
	    unless( -e "$objectPath$res[3]" ) 
	    { 
		error("<b>object $res[0] doesn't appear to exist - $objectPath$res[3]</b>");
		if( $objects{$res[0]} )
	 	{ 
		}
	    }
	    else 
	    {
		$files{$res[0]} = "$objectPath$res[3]";
		$fnames{$res[3]} = $res[0];
	    }
	}
	$sth->finish( );
    }
    print qq(</ul>);    

    print qq(<p />Parsing all text object files...<ul>);
    foreach my $o ( sort keys %files )
    {
	unless( $files{$o} =~ /txt$/i ) { next }

	unless( open(IN,$files{$o}) ) { die "unable to open object $o file - $files{$o}\n" }

	my $f = '';

	while(<IN>)
	{
	    chomp;
	    $f .= $_;
	}
	close(IN);
	while( $f =~ s/\[o[^\]]*\]\s*(\d\d*?)\s*\[\/o\]//i )
	{
	    my $obj = $1;
	    $obj =~ s/\D//g;

	    unless($files{$obj}) { error("<b>object $o ($files{$o}) contains reference to non existent object $obj !</b>") }
	    if( $orphans{$obj} )
	    {
		delete($orphans{$obj});
		error("$obj not an orphan after all -- referenced in object $o");
	    }
	}
    }
    print qq(</ul>);
    print qq(<p />I reckon these are orphan files -- earmarking them for deletion...<ul>);
    foreach my $o ( sort keys %orphans )
    {
	error("$o - $files{$o}");
	push @sql, "UPDATE objects SET deleted=$time WHERE object=$o";
    }
    print qq(</ul>);
    print qq(<p />Running any SQL statements...<ol>);
    foreach my $s ( @sql )
    {
        print qq(<li>$s</li>\n);
        my $sth = $dbh->prepare( $s );
        $sth->execute;
    }
    print qq(</ol>);
    print qq(<p />checking all object directories...<ul>);
    foreach my $l1 ( 0 .. 15 )
    {
	my $d1 = substr("0123456789abcdef",$l1,1);
	    
        foreach my $l2 ( 0 .. 15 )
        {
	    my $d2 = substr("0123456789abcdef",$l2,1);
	    opendir(DIR,"$objectPath$d1/$d1$d2/");
	    my @f = readdir(DIR);
	    closedir(DIR);

	    foreach my $f ( @f )
	    {
		if( $f =~ /^\./ ) { next }
	        my $fn = "$d1/$d1$d2/$f";

		unless( defined($fnames{$fn}))
		{
		    my $nd0t = $objectPath."_deleted/";
		    $nd0t =~ /^(.+?)$/;
		    my $nd0 = $1;

		    my $nd1t = $objectPath."_deleted/$d1/";
		    $nd1t =~ /^(.+?)$/;
		    my $nd1 = $1;
		
		    my $nd2t = $objectPath."_deleted/$d1/$d1$d2/";
		    $nd2t =~ /^(.+?)$/;
		    my $nd2 = $1;

		    my $nd3t = $objectPath."_deleted/$d1/$d1$d2/$f";
		    $nd3t =~ /^(.+?)$/;
		    my $nd3 = $1;

		    my $nd4t = $objectPath.$fn;
		    $nd4t =~ /^(.+?)$/;
		    my $nd4 = $1;

		    error("no reference for $fn - moving it into the <b>_deleted</b> subfolder!");
		    mkdir($nd0);
		    mkdir($nd1);
		    mkdir($nd2);

		    rename( $nd4, $nd3 );

		}
	    }
	}
    }

sub error
{
    my $str = shift;
    print qq(<li>$str</li>\n);

}