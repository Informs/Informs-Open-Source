package InhaleWrite;
use strict;

BEGIN {
    my($LIBDIR);
    if ($0 =~ m!(.*[/\\])!) { $LIBDIR = $1; } else { $LIBDIR = './'; }
    unshift @INC, $LIBDIR . 'lib';

    use Exporter ();
    
    @InhaleWrite::ISA         = qw( Exporter );
    @InhaleWrite::EXPORT      = qw( );
    @InhaleWrite::EXPORT_OK   = qw( beginNewUnit copyUnit deleteUnit 
                                    deletePage deleteObject insertNewPage movePage updatePage
                                    insertEmptyObject insertObject copyObject updateObject
                                    updatePortfolio createPortfolio deletePortfolio
                                    saveMetadata updateUser createUser deleteUser createAccount updateAccount
				    insertStats addFaq updateFaq deleteFaq);
    %InhaleWrite::EXPORT_TAGS = qw( );
}

    use DBI;
    my $dbh = '';
    my $reuseDatabaseHandle = 1;

###############################
# declare the directory paths #
###############################

    my $dataPath = '';
    my $uploadPath = '';
    my $objectDirPath = '';
    my $objectVirPath = '';

    my $mysqlServer;
    my $mysqlDatabase;
    my $mysqlUsername;
    my $mysqlPassword;
    my $mysqlPort;

    loadInhaleINI();

###############################
# declare temporary variables #
###############################

    my $newline = "\n";
    my $status;

sub getDBH
{

    unless( $reuseDatabaseHandle )
    {
       my $dsn = "DBI:mysql:database=$mysqlDatabase;host=$mysqlServer;port=$mysqlPort";
	my $dbh = DBI->connect( $dsn, $mysqlUsername, $mysqlPassword, { 'ShowErrorStatement' => 1, 'HandleError' => sub { InhaleCore::error(shift,'database') } } );
	unless( $dbh ) { InhaleCore::error('Informs database is currently unavailable','database') }
       return( $dbh );
    }
    
    unless( $dbh )
    {
       my $dsn = "DBI:mysql:database=$mysqlDatabase;host=$mysqlServer;port=$mysqlPort";
	$dbh = DBI->connect( $dsn, $mysqlUsername, $mysqlPassword, { 'ShowErrorStatement' => 1, 'HandleError' => sub { InhaleCore::error(shift,'database') } } );
	unless( $dbh ) { InhaleCore::error('Informs database is currently unavailable','database') }

    }
    else {
    }

    return( $dbh );
}

sub saveMetadata {
    my(%args) = @_;
    my $unit = $args{unit};     
    my $metadata = $args{metadata};

    if(open(OUT, ">".untaintPath( $dataPath."metadata/$unit.txt" ))) {
        foreach (sort keys %$metadata) {
            print OUT "$_\t".compress($metadata->{$_})."\n";
        }    
    }
    else { warn $dataPath."metadata/$unit.txt" }
    close(OUT);
}

########################################################################
#                                                                      #
#  InhaleWrite::deletePage                                             #
#                                                                      #
#  [NAMED ARGUMENTS]    page => the page number to delete         MAN  #
#                                                                      #
#                       unit => the number of the unit            MAN  #
#                                                                      #
#                  noshuffle => boolean (1 or 0)                  OPT  #
#                                                                      #
########################################################################
#                                                                      #
#  Removes the specified page from the specified unit.                 #
#                                                                      #
#  The function will mark the object(s) used by the page for           #
#  deletion.                                                           #
#                                                                      #
#  If "noshuffle" (default 0) is set to 1, then the remaining pages    #
#  in the unit will not be reshuffled -- this is used when an entire   #
#  unit is being deleted and renumbering of the pages in not needed.   #
#                                                                      #
########################################################################

sub deletePage 
{
    my(%args)= @_;
    unless(defined($args{page})) { InhaleCore::error('InhaleWrite::deletePage was called without passing a "page" argument', 'bad call'); }
    unless(defined($args{unit})) { InhaleCore::error('InhaleWrite::deletePage was called without passing a "unit" argument', 'bad call'); }
    unless($args{page} > 0)      { InhaleCore::error('InhaleWrite::deletePage was called with an invalid "page" argument ['.$args{page}.']', 'bad call'); }
    unless($args{unit} > 0)      { InhaleCore::error('InhaleWrite::deletePage was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }

    unless(defined($args{noshuffle})) { $args{noshuffle} = 0 }

    my @objects = ( );
    my $exists  = 0;

    my $shuffle = 1;
    if( $args{noshuffle} == 1 ) { $shuffle = 0 }

    audit('unit', $args{unit}, "attempting to delete page #".$args{page}." from unit #".$args{unit});

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    $sth = $dbh->prepare(  "SELECT count( step ) FROM steps WHERE unit=$args{unit} AND step=$args{page}"  );
    $sth->execute;
    my @res = $sth->fetchrow_array;
    $exists = $res[0] || 0;

    if( $exists )
    {
        my $time = time( );

####### first of all, find out which objects are used by the page...

        $sth = $dbh->prepare(  "SELECT leftFrame,rightFrame FROM steps WHERE unit=$args{unit} AND step=$args{page}"  );
        $sth->execute;

	while( @res = $sth->fetchrow_array( ) )
	{
	    my $l = $res[0] || 0;
	    my $r = $res[1] || 0;

  	    if( $l ) { push @objects, $l }
	    if( $r ) { push @objects, $r }
	}

####### earmark those objects for deletion...

	foreach my $object ( @objects )
	{
            $sth = $dbh->prepare( " UPDATE objects SET deleted=$time WHERE object=$object " );
            $sth->execute;
	}

####### delete the specified page...

        $sth = $dbh->prepare(  "DELETE FROM steps WHERE unit=$args{unit} AND step=$args{page}"  );
        $sth->execute;


	if( $shuffle )
	{	
########### get details of the remaining pages so that they can be renumbered...

            $sth = $dbh->prepare(  "SELECT step FROM steps WHERE unit=$args{unit} ORDER BY step"  );
            $sth->execute;

	    my $counter = 0;
           my %counter = ( );

	    while( my @res = $sth->fetchrow_array )
	    {
	        $counter++;
	        $counter{$res[0]} = $counter;
	    }

	    foreach my $k ( sort { $counter{$a} <=> $counter{$b} } keys %counter )
	    {
	        if( $k != $counter{$k} )
	        {
                    $sth = $dbh->prepare(  "UPDATE steps SET step=$counter{$k} WHERE unit=$args{unit} AND step=$k"  );
                    $sth->execute;
		}
	    }
	}
    }
    else {
        InhaleCore::error('InhaleWrite::deletePage was unable to find page #'.$args{page}.' in unit #'.$args{unit}, 'bad call');
    }

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}

########################################################################
#                                                                      #
#  InhaleWrite::deleteUnit                                             #
#                                                                      #
#  [NAMED ARGUMENTS]    unit => the number of the unit            MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Firstly, we run through the "steps" table to find out just how      #
#  many pages there are in the unit.                                   #
#                                                                      #
#  Then we loop through and delete all of the pages using the          #
#  deletePage() routine.                                               #
#                                                                      #
#  Finally, we remove the entry from the "units" table.                #
#                                                                      #
########################################################################

sub deleteUnit 
{
    my(%args)= @_;
    unless(defined($args{unit})) { InhaleCore::error('InhaleWrite::deleteUnit was called without passing a "unit" argument', 'bad call'); }
    unless($args{unit} > 0)      { InhaleCore::error('InhaleWrite::deletePage was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }

    audit('unit', $args{unit}, "attempting to delete unit #$args{unit} from database");


### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### delete the steps in the unit...

    $sth = $dbh->prepare(  "SELECT step FROM steps WHERE unit=$args{unit}"  );
    $sth->execute;
    while( my @res = $sth->fetchrow_array )
    {
	my $step = $res[0] || 0;

	if( $step )
	{
	    deletePage( unit => $args{unit}, page => $step, noshuffle => 1 );
	}	
    }

### delete the unit...

    $sth = $dbh->prepare(  "DELETE FROM units WHERE unit=$args{unit}"  );
    $sth->execute;

### nuke any stats...

    $sth = $dbh->prepare(  "DELETE FROM stats WHERE unit=$args{unit}"  );
    $sth->execute;

### update the audit trail...

    audit('unit', $args{unit}, "unit #$args{unit} deleted from database");

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

}

########################################################################
#                                                                      #
#  InhaleWrite::deleteObject                                           #
#                                                                      #
#  [NAMED ARGUMENTS]    objectid => the number of the object      MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Remove the entry from the "objects table.                           #
#                                                                      #
########################################################################

sub deleteObject 
{
    my(%args)= @_;
    audit('object', $args{objectid}, "attempting to delete object #$args{objectid} from database");

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### delete the object...

    $sth = $dbh->prepare(  "DELETE FROM objects WHERE object=$args{objectid}"  );
    $sth->execute;

### update the audit trail...

    audit('object', $args{objectid}, "unit #$args{objectid} deleted from database");

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}

########################################################################
#                                                                      #
#  InhaleWrite::copyUnit                                               #
#                                                                      #
#  [NAMED ARGUMENTS]    unit  => the number of the unit           MAN  #
#                                                                      #
#                       from  => the number of the portfolio      MAN  #
#                                where the original exists             #
#                                                                      #
#                       into  => the number of the portfolio      MAN  #
#                                where the copy should go              #
#                                                                      #
#                       reuse => string detailing which pages     OPT  #
#                                should be reused                      #
#                                                                      #
########################################################################
#                                                                      #
#  Copies a unit from the specified portfolio into the other           #
#  specified portfolio.                                                #
#                                                                      #
#  The optional 'reuse' argument specifies which, if any, of the       #
#  database objects that make up the unit should be literally          #
#  re-used - i.e. the new unit will use the exact same objects as      #
#  the original and any alterations to the original objects will       #
#  appear in the new unit.                                             #
#                                                                      #
#  If objects are reused, then the ownership of the object remains     #
#  with the owner of the original unit.  If the unit is being          #
#  copied into a different portfolio, then the new owner will still    #
#  be able to edit the objects - however, at the point of editing      #
#  the object, a new object will be created and this will replace      #
#  the original.  In other words, any changes they want to make to     #
#  the copy won't overstamp the original version of the unit.          #
#                                                                      #
#  The reuse argument can contain one of three things:                 #
#                                                                      #
#  1) The string 'none' (which is also the default) - this means       #
#     that none of the objects should be reused and new copies         #
#     should be created.                                               #
#                                                                      #
#  2) The string 'all' - this means that all of the objects should     #
#     be reused in the new unit.                                       #
#                                                                      #
#  3) A space separated string of the pages numbers to reuse, for      #
#     example '1 3 4' means "reuse pages 1, 3 and 4".  The function    #
#     will figure out which objects are being used by the specified    #
#     steps.                                                           #
#                                                                      #
########################################################################

sub copyUnit {
    my(%args)= @_;
    unless(defined($args{from})) { InhaleCore::error('InhaleWrite::copyUnit was called without passing a "from" argument', 'bad call'); }
    unless(defined($args{into})) { InhaleCore::error('InhaleWrite::copyUnit was called without passing a "into" argument', 'bad call'); }
    unless(defined($args{unit})) { InhaleCore::error('InhaleWrite::copyUnit was called without passing a "unit" argument', 'bad call'); }
    unless($args{unit} > 0)      { InhaleCore::error('InhaleWrite::copyUnit was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }
    unless($args{from} > 0)      { InhaleCore::error('InhaleWrite::copyUnit was called with an invalid "from" argument ['.$args{from}.']', 'bad call'); }
    unless($args{into} > 0)      { InhaleCore::error('InhaleWrite::copyUnit was called with an invalid "into" argument ['.$args{into}.']', 'bad call'); }

    audit('unit', $args{unit}, "unit #$args{unit} is being copied from portfolio #$args{from} to portfolio #$args{into}"); 

### delcare temporary variables...

    my %existingUnit = ( );
    
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my @res = ( );

### get the details of the unit...
   
    $sth = $dbh->prepare(  "SELECT title,description,openMethod FROM units WHERE unit=$args{unit}"  );
    $sth->execute;
    @res = $sth->fetchrow_array;

    $existingUnit{title} = $res[0] || '';
    $existingUnit{desc}  = $res[1] || '';
    $existingUnit{open}  = $res[2] || '';

    unless( $existingUnit{title} ) { InhaleCore::error("InhaleWrite::copyUnit was unable to locate unit number $args{unit}", 'database'); }

###

    $sth = $dbh->prepare(  "SELECT MAX(displayOrder) FROM units WHERE portfolio = $args{into}"  );
    $sth->execute;
    @res = $sth->fetchrow_array;
    my $newOrder = $res[0] || 0;
    $newOrder++;

### insert new unit...

    $existingUnit{title} = cleanSQL( $existingUnit{title} );
    $existingUnit{desc}  = cleanSQL( $existingUnit{desc} );
    $existingUnit{open}  = cleanSQL( $existingUnit{open} );

    $sth = $dbh->prepare( qq[  INSERT INTO units (unit,title,description,portfolio,visible,displayOrder,openMethod) VALUES (0,"$existingUnit{title}","$existingUnit{desc}",$args{into},"N",$newOrder,"$existingUnit{open}")  ] );
    $sth->execute;
    my $newUnitID = $dbh->{'mysql_insertid'} || 0;

    unless( $newUnitID > 0 ) { InhaleCore::error('InhaleWrite::copyUnit was unable to retrieve the new unit ID from the database', 'database'); }

    audit('unit', $newUnitID, "new unit #$newUnitID was created by copying unit #$args{unit} from portfolio #$args{from} into portfolio #$args{into}"); 

### fetch all of the steps from the original unit...

    $sth = $dbh->prepare(  "SELECT step,leftFrame,rightFrame,url,toc FROM steps WHERE unit=$args{unit}"  );
    $sth->execute;
    my @sql = ( );

    while( my @res = $sth->fetchrow_array )
    {
	my $nStep  = $res[0];
	my $nLeft  = $res[1];
	my $nRight = $res[2];
	my $nURL   = $res[3];
	my $nToc   = $res[4];

	if( $nLeft > 0 )
	{
	    my $sth2 = $dbh->prepare(  "SELECT description,filename FROM objects WHERE object=$nLeft"  );
	    $sth2->execute;
	    my @res2 = $sth2->fetchrow_array( );
	    my $oDesc = $res2[0] || '';
	    my $oFile = $res2[1] || InhaleCore::error("InhaleWrite::copyUnit was unable to get file details for object $nLeft", 'database');;

	    my( $newObject, $newFilename ) = insertEmptyObject( account => $InhaleCore::user->{userAccountNumber},
                                                                   desc => $oDesc );
            open(OBJIN, $objectDirPath.$oFile) || InhaleCore::error("InhaleWrite::copyUnit was unable to gain read access for objectID $newObject", 'database');
            binmode(OBJIN);

            open(OBJOUT, ">".untaintPath($objectDirPath.$newFilename)) || InhaleCore::error("InhaleWrite::copyUnit was unable to write to new objectID $newObject", 'database');
            binmode(OBJOUT);

            while(<OBJIN>) { print OBJOUT $_; }

            close(OBJOUT);
            close(OBJIN);

	    $nLeft = $newObject;
	}
	    
	if( $nRight > 0 )
	{
	    my $sth2 = $dbh->prepare(  "SELECT description,filename FROM objects WHERE object=$nRight"  );
	    $sth2->execute;
	    my @res2 = $sth2->fetchrow_array( );
	    my $oDesc = $res2[0] || '';
	    my $oFile = $res2[1] || InhaleCore::error("InhaleWrite::copyUnit was unable to get file details for object $nRight", 'database');;

	    my( $newObject, $newFilename ) = insertEmptyObject( account => $InhaleCore::user->{userAccountNumber},
                                                                   desc => $oDesc );
            open(OBJIN, $objectDirPath.$oFile) || InhaleCore::error("InhaleWrite::copyUnit was unable to gain read access for objectID $newObject", 'database');
            binmode(OBJIN);

            open(OBJOUT, ">".untaintPath($objectDirPath.$newFilename)) || InhaleCore::error("InhaleWrite::copyUnit was unable to write to new objectID $newObject", 'database');
            binmode(OBJOUT);

            while(<OBJIN>) { print OBJOUT $_; }

            close(OBJOUT);
            close(OBJIN);

	    $nRight = $newObject;
	}

        $nURL  = cleanSQL( $nURL );
        $nToc  = cleanSQL( $nToc );

        my $sth2 = $dbh->prepare( qq[  INSERT INTO steps (unit,step,leftFrame,rightFrame,url,toc) VALUES ($newUnitID,$nStep,$nLeft,$nRight,"$nURL","$nToc")  ] );
        $sth2->execute;

    }

    audit('unit', $args{unit}, "unit #$args{unit} was copied into portfolio #$args{into} and becomes unit #$newUnitID"); 
    audit('unit', 4, "unit #$newUnitID was created in portfolio #$args{into} by copying unit #$args{unit} from portfolio #$args{from}"); 

### add stats to unitscopied table   
    my $copytime = time( );

    my $sth19 = $dbh->prepare( qq[Select account from portfolios where portfolio =$args{into}] );
    $sth19->execute;
    my @res19 = $sth19->fetchrow_array( );
    my $accountin = $res19[0] || '';

    my $sth20 = $dbh->prepare( qq[  INSERT INTO unitscopied (id,newunitid,originalunitid,fromportfolio,toportfolio,account,timestamp) VALUES ('',$newUnitID,$args{unit},$args{from},$args{into},$accountin,$copytime)  ] );
    $sth20->execute;
   
### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return($newUnitID);
}

########################################################################
#                                                                      #
#  InhaleWrite::insertEmptyObject                                      #
#                                                                      #
#  [NAMED ARGUMENTS]    account => account number to assign       MAN  #
#                                  the new object to                   #
#                                                                      #
#                       desc    => short free text description    OPT  #
#                                  of the object                       #
#                                                                      #
########################################################################
#                                                                      #
#  Inserts a new blank/empty TXT object into the database.             #
#                                                                      #
#  Returns the ID of the new object and the filename.                  #
#                                                                      #
########################################################################

sub insertEmptyObject 
{
    my(%args)= @_;
    unless(defined($args{account})) { InhaleCore::error('InhaleWrite::insertEmptyObject was called without passing a "account" argument', 'bad call'); }
    unless(defined($args{desc})) { $args{desc} = ''; }
    unless($args{account} > 0) { InhaleCore::error('InhaleWrite::insertEmptyObject was called with an invalid "account" argument ['.$args{account}.']', 'bad call'); }

    my $file = untaintPath($uploadPath.time().int(rand(9999)).'.txt');
    
    open(TEMP, ">$file") || die "could not generate a new object at $file";
    close(TEMP);    

    my($objectID, $filename) = insertObject( filename => $file, 
                                                 desc => $args{desc}, 
                                              account => $args{account}, 
                                               delete => 1 );

    audit('object', $objectID, "empty object created");

    return( $objectID, $filename );

}


########################################################################
#                                                                      #
#  InhaleRead::copyObject                                              #
#                                                                      #
#  [NAMED ARGUMENTS]    account => the account number to          MAN  #
#                                  assign the new object to            #
#                                                                      #
#                       content => optional scalar containing     OPT  #
#                                  the content to be used for          #
#                                  the new object                      #
#                                                                      #
#                        object => an $object OObject             MAN  #
#                                                                      #
#                          page => a $page object                 MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Creates a new copy of an existing database object and returns       #
#  the ID number of the new object.                                    #
#                                                                      #
#  If an account number is not passed, then the new object will be     #
#  assigned to $cgi->{folio} or to $user->{accountnumber}.             #
#                                                                      #
#  The actual content of the new object can be passed using the        #
#  "content" argument, otherwise the new object will have the same     #
#  content as the original.                                            #
#                                                                      #
########################################################################

sub copyObject {
    my(%args)= @_;

    unless(defined($args{object}))  { InhaleCore::error('InhaleWrite::copyObject was called without passing a "object" object', 'bad call'); }
    unless(defined($args{page}))    { InhaleCore::error('InhaleWrite::copyObject was called without passing a "page" object', 'bad call'); }
    unless(defined($args{account})) { InhaleCore::error('InhaleWrite::copyObject was called without passing a "account" argument', 'bad call'); }

    unless(ref($args{object}) eq 'InhaleRead') { InhaleCore::error('InhaleWrite::copyObject was called without passing a valid "object" object', 'bad call'); }
    unless(ref($args{page}) eq 'InhaleRead')   { InhaleCore::error('InhaleWrite::copyObject was called without passing a valid "page" object', 'bad call'); }

    unless(defined($args{content})) { $args{content} = InhaleRead::getObjectData( object => $args{object} ); }

    my( $newObject, $newFilename ) = insertEmptyObject( account => $args{account},
                                          desc => $args{object}->{description} );

    updateObject($newObject, $args{content}, $args{object}->{description});

    return($newObject);
}

########################################################################
#                                                                      #
#  InhaleRead::insertObject                                            #
#                                                                      #
#  [NAMED ARGUMENTS]    account => account number to assign       MAN  #
#                                  the object to                       #
#                                                                      #
#                        delete => boolean value to indicate      OPT  #
#                                  whether or not the temporary        #
#                                  object file should be deleted       #
#                                                                      #
#                          desc => description of the object      OPT  #
#                                                                      #
#                      filename => physical path to the file      MAN  #
#                                  to create the object from           #
#                                                                      #
########################################################################
#                                                                      #
#  To insert a new object in to the database, the object should        #
#  already exist as a file on the server.  If you pass a true value    #
#  to the "delete" argument, then the file will be deleted once        #
#  the object has been entered into the database.                      #
#                                                                      #
#  You can also pass an optional description to be assigned to the     #
#  object.                                                             #
#                                                                      #
#  The routine returns two scalar values                               #
#                                                                      #
#     1) the ID number of the newly created object                     #
#                                                                      #
#     2) the filename assigned to the new object                       #
#                                                                      #
########################################################################

sub insertObject {
    my(%args)= @_;
    use Digest::MD5 qw(md5_hex);

    unless(defined($args{filename})) { InhaleCore::error('InhaleWrite::insertObject was called without passing a "filename" argument', 'bad call'); }
    unless(defined($args{account}))  { InhaleCore::error('InhaleWrite::insertObject was called without passing a "account" argument', 'bad call'); }

    unless(defined($args{desc}))   { $args{desc} = ''; }
    unless(defined($args{delete})) { $args{delete} = ''; }
    
    open(FILEIN, $args{filename}) || InhaleCore::error('InhaleWrite::insertObject was unable to open the file passed in the "filename" argument ['.$args{filename}.']', 'bad call');
    binmode(FILEIN);
    my @file = <FILEIN>;
    close(FILEIN);


    my $filename = '';
    my @tmp = split(/\./, $args{filename});
    my $fileType = uc(substr($tmp[-1], 0, 3));

    my $newID = 0;
    my $timeStamp = time();
    
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### insert a new object into the database...

    $args{desc} = cleanSQL( $args{desc} );
    $fileType   = cleanSQL( $fileType );

    $sth = $dbh->prepare( qq[  INSERT INTO objects (object,filename,description,filetype,creationTimeStamp,owner,encoding) VALUES (0,"empty","$args{desc}","$fileType",$timeStamp,$args{account},"") ]  );
    $sth->execute;

    $newID = $dbh->{'mysql_insertid'} || 0;

    unless( $newID > 0 ) { InhaleCore::error('InhaleWrite::insertObject was unable to retrieve the new object ID from the database', 'database'); }

    my $md5 = md5_hex($timeStamp.$fileType.$newID);
    $filename = substr($md5,0,1).'/'.substr($md5,0,2).'/'.$newID.'_'.$md5.'.'.$tmp[-1];
   
    my $outputname = untaintPath($objectDirPath.$filename);
    my $error = '';

    open( FILEOUT, '>'.$outputname ) || InhaleCore::error('InhaleWrite::insertObject was unable to create the final object file  ['.$outputname.']', 'bad call');
    binmode( FILEOUT );
    print FILEOUT @file;
    close( FILEOUT );

    if($args{delete}) {
        my $temp = chmod 0666, $outputname;             ### for *nix servers, chmod the files so that 
        $temp = chmod 0666, $args{filename};            ### they can be updated/deleted
        unlink($args{filename});  
    }

### update the database with the filename of the new object...

    $sth = $dbh->prepare(  "UPDATE objects SET filename = '$filename' WHERE object = $newID"  );
    $sth->execute;

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return($newID, $filename);
}

#####################################
# update an object and it's details #
#####################################
# check $data for dodgy content?
# write details to a log file?
#

sub updateObject {
    my $objectNumber = shift;
    my $data         = shift;
    my $desc         = shift;

    my $fileLocation = '';
    $data =~ s/\r//g;
    
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    $sth = $dbh->prepare(  "SELECT filename, description FROM objects WHERE object = $objectNumber"  );
    $sth->execute;
    my @res = $sth->fetchrow_array;

    $fileLocation = untaintPath( $objectDirPath.$res[0] );

    unless( $res[0] ) { InhaleCore::error('InhaleWrite::updateObject was unable to locate the object file for object #'.$objectNumber, 'bad call'); }

    if($res[1] ne $desc) 
    { 
        audit( 'object', $objectNumber, "object description altered" ); 
	$desc =~ s/\"/\'\'/g;
        $sth = $dbh->prepare(  "UPDATE objects set description = \"$desc\" WHERE object = $objectNumber"  );
        $sth->execute;
    }
    
    open(FILEOUT,'>'.$fileLocation) || InhaleCore::error('InhaleWrite::updateObject was unable to update the object file for object #'.$objectNumber, 'bad call');
    print FILEOUT $data;
    close(FILEOUT);

    audit('object', $objectNumber, "object updated");

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}

###################################
# update an page and it's details #
###################################
# check $data for dodgy content?
# write details to a log file?
#

########################################################################
#                                                                      #
#  InhaleRead::updatePage                                              #
#                                                                      #
#  [NAMED ARGUMENTS]    page => a page OObject                    MAN  #
#                                                                      #
#                        url => a replacement URL for the page    OPT  #
#                                                                      #
#                        toc => a replacement TOC entry for the   OPT  #
#                               page                                   #
#                                                                      #
#                       left => a replacement object ID number    OPT  #
#                               for the left-hand frame                #
#                                                                      #
#                      right => a replacement object ID number    OPT  #
#                               for the right-hand frame               #
#                                                                      #
#                    replace => the ID number of an object to     OPT  #
#                               replace...                             #
#                                                                      #
#                       with => ...the ID number of an object     OPT  #
#                               to replace the old one with            #
#                                                                      #
########################################################################
#                                                                      #
#  A routine to update the details for a specific page in a given      #
#  unit.  The unit number and page number are picked up from the       #
#  page OObject.                                                       #
#                                                                      #
#  If any of the optional arguments are passed with a blank entry,     #
#  the the routine assumes you want to blank out any value that        #
#  already exists - e.g. if the page currently has a URL assigned to   #
#  the right-hand frame, then an argument of url => "" will remove     #
#  the assigned URL.                                                   #
#                                                                      #
#  The "replace/with" arguments must both be populated if you wish     #
#  to use this function.  The routine will examine the specified       #
#  page and if it uses the object specified in "replace", then it      #
#  will replace that entry with the object specified in "with".        #
#  For example, if the page has the following attributes:              #
#                                                                      #
#              toc = "example page"                                    #
#       left frame = 140                                               #
#      right frame = 0                                                 #
#              url = "http://www.google.com"                           #
#                                                                      #
#  ...then passing the following arguments:                            #
#                                                                      #
#      replace => 140                                                  #
#         with => 905                                                  #
#                                                                      #
#  ...then the page's attributes will change to:                       #
#                                                                      #
#              toc = "example page"                                    #
#       left frame = 905                                               #
#      right frame = 0                                                 #
#              url = "http://www.google.com"                           #
#                                                                      #
#  ...basically - if you already know the object is either the left    #
#  or right hand frame object, then just use the "left" or "right"     #
#  arguments and if you don't know then use the "replace/with".        #
#                                                                      #
########################################################################

sub updatePage 
{
    my(%args)= @_;
    unless(defined($args{page}))          { InhaleCore::error('InhaleWrite::updatePage was called without passing a "page" object', 'bad call'); }
    unless($args{page}->{pageNumber} > 0) { InhaleCore::error('InhaleWrite::updatePage was called without passing a valid "page" object', 'bad call'); }

    my @sql  = ( );
    my $page = $args{page}->{pageNumber};
    my $unit = $args{page}->{unitNumber};

### replace the URL

    if(defined($args{url})) 
    { 
        push @sql, ' UPDATE steps SET url = "'.cleanSQL($args{url}).'" WHERE unit='.$unit.' AND step='.$page; 
        push @sql, ' UPDATE units SET last_edited = CURDATE() WHERE unit='.$unit; 
        if($args{url}) 
	{
	    audit('unit', $args{page}->{unitNumber}, "changing URL for page #$args{page}->{pageNumber} to \"$args{url}\""); 
	}
        else {
	    audit('unit', $args{page}->{unitNumber}, "removing URL for page #$args{page}->{pageNumber}"); 
	}
    }

### replace the TOC

    if(defined($args{toc})) 
    { 
        push @sql, qq( UPDATE steps SET toc = "$args{toc}" WHERE unit = $unit AND step = $page ); 
        push @sql, ' UPDATE units SET last_edited = CURDATE() WHERE unit='.$unit; 
        if($args{toc}) 
	{ 
	    audit('unit', $args{page}->{unitNumber}, "changing TOC entry for page #$args{page}->{pageNumber} to \"$args{toc}\""); 
	}
        else { 
	    audit('unit', $args{page}->{unitNumber}, "removing TOC entry for page #$args{page}->{pageNumber}"); 
	}
    }

### replace the left-hand frame entry

    if(defined($args{left})) 
    { 
        push @sql, qq( UPDATE steps SET leftFrame = $args{left} WHERE unit = $unit AND step = $page ); 
        push @sql, ' UPDATE units SET last_edited = CURDATE() WHERE unit='.$unit; 
        audit('unit', $args{page}->{unitNumber}, "changing left-hand frame for page #$args{page}->{pageNumber} to \"$args{left}\""); 
    }

### replace the right-hand frame entry

    if(defined($args{right})) 
    { 
        push @sql, qq( UPDATE steps SET rightFrame = $args{right} WHERE unit = $unit AND step = $page ); 
        push @sql, ' UPDATE units SET last_edited = CURDATE() WHERE unit='.$unit; 
        audit('unit', $args{page}->{unitNumber}, "changing right-hand frame for page #$args{page}->{pageNumber} to \"$args{right}\""); 
    }

### handle "replace/with" requests

    if(defined($args{replace}) && defined($args{with})) 
    { 
        push @sql, ' UPDATE units SET last_edited = CURDATE() WHERE unit='.$unit; 
        push @sql, qq( UPDATE steps SET leftFrame = $args{with} WHERE unit = $unit AND leftFrame = $args{replace} ); 
        push @sql, qq( UPDATE steps SET rightFrame = $args{with} WHERE unit = $unit AND rightFrame = $args{replace} ); 
    }

# die join("\n",@sql);


### if there are some, run the SQL statements...

    if( @sql )
    {
        my $dbh = $dbh || getDBH( );
        my $sth = ''; 

	foreach my $sql ( @sql )
	{
            $sth = $dbh->prepare( $sql );
  	    $sth->execute;
	}

        $sth->finish;
        $dbh->disconnect;
    }	
}

########################################################################
#                                                                      #
#  InhaleWrite::insertNewPage                                          #
#                                                                      #
#  [NAMED ARGUMENTS]    page => the page number to insert         MAN  #
#                                                                      #
#                       unit => the number of the unit            MAN  #
#                                                                      #
#                 objectLeft => object number to use for the      MAN  #
#                               guide at the side                      #
#                                                                      #
#                objectRight => object number to use for the      OPT  #
#                               main frame (defaults to 0)             #
#                                                                      #
#             objectRightURL => optional URL for use in the       OPT  #
#                               main frame                             #
#                                                                      #
#                        toc => optional table of contents        OPT  #
#                               entry                                  #
#                                                                      #
########################################################################
#                                                                      #
#  Inserts a new page into the specified unit.  Any existing pages     #
#  will be shuffled to accomodate the new page at the requested        #
#  position.                                                           #
#                                                                      #
########################################################################

sub insertNewPage 
{
    my(%args)= @_;
    unless(defined($args{page}))           { InhaleCore::error('InhaleWrite::insertNewPage was called without passing a "page" argument', 'bad call'); }
    unless(defined($args{unit}))           { InhaleCore::error('InhaleWrite::insertNewPage was called without passing a "unit" argument', 'bad call'); }
    unless(defined($args{objectLeft}))     { InhaleCore::error('InhaleWrite::insertNewPage was called without passing a "objectLeft" argument', 'bad call'); }
    unless(defined($args{objectRight}))    { $args{objectRight} = '0'; }
    unless(defined($args{objectRightURL})) { $args{objectRightURL} = ''; }
    unless(defined($args{toc}))            { $args{toc} = ''; }

    audit('unit', $args{unit}, "attempting to insert a new page #".$args{page});

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### check to see if we need to shunt any of the existing pages up...

    $sth = $dbh->prepare(  "SELECT step FROM steps WHERE unit = $args{unit} AND step >= $args{page} ORDER BY step DESC"  );
    $sth->execute;

    my @toMove = ( );

    while( my @res = $sth->fetchrow_array )
    {
	push @toMove, $res[0];
    }

### if there any any pages to shunt up, then do that now...

    if( @toMove )
    {
	foreach my $step ( @toMove )
	{
	    my $newStep = $step + 1;
	    $sth = $dbh->prepare(  "UPDATE steps SET step = $newStep WHERE unit = $args{unit} AND step = $step"  );
	    $sth->execute;
	}
    }

### insert the new page...

    $args{objectRightURL} = cleanSQL( $args{objectRightURL} );
    $args{toc}            = cleanSQL( $args{toc} );

    $sth = $dbh->prepare( qq[  INSERT INTO steps (unit,step,leftFrame,rightFrame,url,toc) VALUES ($args{unit},$args{page},$args{objectLeft},$args{objectRight},"$args{objectRightURL}","$args{toc}")  ] );
    $sth->execute;

    audit('object', $args{objectLeft}, "inserted as new page #$args{page} into unit #$args{unit} in portfolio #".$InhaleCore::cgi->{folio});
    audit('unit', $args{unit}, "object #$args{objectLeft} inserted as new page #$args{page} in portfolio #".$InhaleCore::cgi->{folio});

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}

sub audit 
{
    my $type = shift || '';
    my $num  = shift || ''; 
    my $text = shift || '';

    my $time    = time( );
    my $user    = $InhaleCore::user->{userNumber};
    my $account = $InhaleCore::user->{userAccountNumber};
    my $atype   = 'O';
    if( $type eq 'unit' ) { $atype = 'U' }

    if( $num > 0 )
    {
        $text = cleanSQL( $text );

### get a valid database handle and create a fresh statement handle...

        my $dbh = $dbh || getDBH( );
        my $sth = ''; 

        my $sql = qq(insert into audit (event,id,account,user,timeStamp,ip,type,eventText) values (0,$num,$account,$user,$time,"$ENV{REMOTE_ADDR}","$atype","$text" ) );
        $sth = $dbh->prepare($sql);
        $sth->execute;

        $sth->finish;
        $dbh->disconnect;
    }
}

sub updatePortfolio 
{
    my($userID, $action, @data) = @_;
    my $ret = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### change unit visibility

    if( $action eq 'hide' && $data[0] ) 
    {
        $sth = $dbh->prepare(  "UPDATE units SET visible='N' WHERE unit=$data[0]"  );
        $sth->execute;
        audit('unit', $data[0], 'changed unit status to "hidden"');
    }
    
    if( $action eq 'unhide' && $data[0] ) 
    {
        $sth = $dbh->prepare(  "UPDATE units SET visible='Y' WHERE unit=$data[0]"  );
        $sth->execute;
        audit('unit', $data[0], 'changed unit status to "visible"');
    }

### delete unit -- replaced with "deleteunit( )" function!

    if($action eq 'delete unit') 
    {
	die "delete unit is no longer supported by updatePortfolio!";
    }

### change unit title

    if($action eq 'renameUnit' && $data[0] && $data[1] ) 
    {
        $sth = $dbh->prepare(  'UPDATE units SET title="'.cleanSQL($data[1]).'" WHERE unit='.$data[0]  );
        $sth->execute;
        audit('unit', $data[0], "unit renamed to \"$data[1]\"");
    }

### change unit description

    if($action eq 'setDescription') 
    {
        $sth = $dbh->prepare(  'UPDATE units SET description="'.cleanSQL($data[1]).'" WHERE unit='.$data[0]  );
        $sth->execute;
        audit('unit', $data[0], "unit description altered");
    }

### change open method

    if($action eq 'openMethod') 
    { 
	my $openMethod = 'frameset';

        if( $data[1] == 2 ) 
  	{ 
            $openMethod = 'noframes+js'; 
            audit('unit', $data[0], "changed unit open method to \"two separate windows\""); 
        }
	else
	{
            audit('unit', $data[0], "changed unit open method to \"frameset\""); 
	}

        $sth = $dbh->prepare(  "UPDATE units SET openMethod='$openMethod' WHERE unit=$data[0]"  );
        $sth->execute;
    }

### move unit position in portfolio

    if( lc($action) eq 'moveup' || lc($action) eq 'movedown' ) 
    { 
        $sth = $dbh->prepare(  "SELECT portfolio FROM units WHERE unit=$data[0]"  );
        $sth->execute;
        my @res = $sth->fetchrow_array( );

	my $portfolio = $res[0] || 0;

	if( $portfolio )
	{
	    my %all = ( );
  	    my $pos = 0;
	    my $cnt = 0;

            $sth = $dbh->prepare(  "SELECT unit FROM units WHERE portfolio=$portfolio ORDER BY displayOrder"  );
            $sth->execute;

	    while( my @res = $sth->fetchrow_array )
	    {
		$cnt++;
		if( $res[0] == $data[0] ) { $pos = $cnt }
		$all{$res[0]} = $cnt;
	    }

	    my $new = $pos;
	    if( lc($action) eq 'moveup'   ) 
	    { 
 	        audit('unit', $data[0], "unit moved position upwards within the portfolio"); 
		$new--;
	    }
	    if( lc($action) eq 'movedown' )
	    { 
 	        audit('unit', $data[0], "unit moved position downwards within the portfolio"); 
		$new++;
	    }

	    foreach my $unit ( keys %all )
	    {
		my $upos = $all{$unit};
		if( $upos == $new ) { $all{$unit} = $pos }
		if( $upos == $pos ) { $all{$unit} = $new }

	        $sth = $dbh->prepare(  "UPDATE units SET displayOrder=$all{$unit} WHERE unit=$unit"  );
	        $sth->execute;
	    }
	}
    }
	

### change unit description

    if( lc($action) eq 'changeportfoliotitle' ) 
    {
        $sth = $dbh->prepare(  'UPDATE portfolios SET title="'.cleanSQL($data[1]).'" WHERE portfolio='.$data[0]  );
        $sth->execute;
    }
    if( $sth ) { $sth->finish }
    $dbh->disconnect;
 
    return($ret);
}

########################################################################################
#
#   1. insert into UNIT and get a new unit number
#   2. insert into PORTFOLIO
#   3. create & insert OBJECT
#   4. insert into STEPS
#
#
#


########################################################################
#                                                                      #
#  InhaleWrite::beginNewUnit                                           #
#                                                                      #
#  [NAMED ARGUMENTS]   folio => the portfolio number to create    MAN  #
#                               the new unit in                        #
#                                                                      #
#                      title => the title of the new unit         MAN  #
#                                                                      #
#                       desc => optional description for the      OPT  #
#                               new unit                               #
#                                                                      #
#                      blank => optional boolean value for        OPT  #
#                               creating a blank intro page            #
#                                                                      #
#                                                                      #
########################################################################
#                                                                      #
#  This routine handles creating a new unit, and optionally also       #
#  adding a blank introduction page (if the "blank" argument contains  #
#  a true value - e.g. "1").                                           #
#                                                                      #
#  Both the "unit" and "portfolio" database tables are updated with    #
#  all the relevant information                                        #
#                                                                      #
########################################################################

sub beginNewUnit 
{
    my(%args)= @_;
    unless(defined($args{folio}))   { InhaleCore::error('InhaleWrite::beginNewUnit was called without passing a "folio" argument', 'bad call'); }
    unless(defined($args{title}))   { InhaleCore::error('InhaleWrite::beginNewUnit was called without passing a "title" argument', 'bad call'); }
    unless(defined($args{account})) { InhaleCore::error('InhaleWrite::beginNewUnit was called without passing a "account" argument', 'bad call'); }
    unless(defined($args{desc}))    { $args{desc}  = ''; }
    unless(defined($args{blank}))   { $args{blank} = ''; }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### insert details for the new unit

    $sth = $dbh->prepare(  "SELECT MAX(displayOrder) FROM units WHERE portfolio = $args{folio}"  );
    $sth->execute;
    my @res = $sth->fetchrow_array;
    my $newOrder = $res[0] || 0;
    $newOrder++;

    $args{title} = cleanSQL( $args{title} );
    $args{desc}  = cleanSQL( $args{desc} );

    $sth = $dbh->prepare( qq[  INSERT INTO units (unit,title,description,portfolio,visible,displayOrder,openMethod,date) VALUES (0,"$args{title}","$args{desc}",$args{folio},"N",$newOrder,"frameset",CURDATE())  ] );
    $sth->execute;
    my $newUnitID = $dbh->{'mysql_insertid'} || 0;

    unless( $newUnitID ) { InhaleCore::error('InhaleWrite::beginNewUnit failed to create the new unit', 'database'); }

    audit('unit', $newUnitID, "creating a brand new unit #$newUnitID for portfolio #".$args{folio} );

### if necc, insert a blank intro page

    if($args{blank}) {

        my $tempFile = untaintPath($objectDirPath.time().'_'.int(rand(10000)).'.txt');
        open(OUT,">$tempFile") || die $tempFile;
        print OUT '';
        close(OUT);

        audit('unit', $newUnitID, "attempting to insert a new page #1");

        my($objectID, $objectFile) = insertObject( filename => $tempFile, 
                                                    account => $args{account},
                                                       desc => 'page1',
                                                       delete => 1 );

        $sth = $dbh->prepare( qq[  INSERT INTO steps (unit,step,leftFrame,rightFrame,url,toc) VALUES ($newUnitID,1,0,$objectID,"","")  ] );
        $sth->execute;

        audit('unit', $newUnitID, "object #$objectID inserted as new page #1 in portfolio #$args{folio}");
    }

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return( $newUnitID );
}

sub movePage {
    my($unitID, $pageOld, $pageNew) = @_;

    audit('unit', $unitID, "attempting to move page #$pageOld to become page #".$pageNew);

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    my $min = $pageOld;
    my $max = $pageNew;

    if($pageOld > $pageNew) {
        $min = $pageNew;
        $max = $pageOld;
    }

## swap adjacent pages

    if(($max - $min) == 1) 
    { 
        audit('unit', $unitID, "...swapping pages #$max and #$min");

        $sth = $dbh->prepare(  "UPDATE steps SET step=9999 WHERE unit=$unitID AND step=$pageOld"  );
        $sth->execute;
        $sth = $dbh->prepare(  "UPDATE steps SET step=$pageOld WHERE unit=$unitID AND step=$pageNew"  );
        $sth->execute;
        $sth = $dbh->prepare(  "UPDATE steps SET step=$pageNew WHERE unit=$unitID AND step=9999"  );
        $sth->execute;
    }
    else
    {
	my @sql = ( );

        audit('unit', $unitID, "...moving old page #$pageOld to become new page #$pageNew");
        audit('unit', $unitID, "...shuffling other pages into place");

        push @sql, qq( UPDATE steps SET step=9999 WHERE unit=$unitID AND step=$pageOld );

### need to move remaining pages down...

        if($pageNew > $pageOld) 
        {
            foreach my $page ( $min+1 .. $max ) 
	    {
		my $new = $page-1;
	        push @sql, qq( UPDATE steps SET step=$new WHERE unit=$unitID AND step=$page );
	    }
	}

### need to move remaining pages up...

        if($pageNew < $pageOld) 
        {
            for ( my $page=$max-1; $page >= $min; $page-- ) 
	    {
		my $new = $page+1;
	        push @sql, qq( UPDATE steps SET step=$new WHERE unit=$unitID AND step=$page );
	    }
	}

### run the SQL to shift everything...

	push @sql, qq( UPDATE steps SET step=$pageNew WHERE unit=$unitID AND step=9999 );

        foreach my $sql (@sql)
	{
	    $sth = $dbh->prepare( $sql );
	    $sth->execute;
	}
    }

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}

########################################################################
#                                                                      #
#  InhaleWrite::updateUser                                             #
#                                                                      #
#  [NAMED ARGUMENTS]    user => user number                       OPT  #
#                                                                      #
#                    account => account number                    OPT  #
#                                                                      #
#                       text => string                            MAN  #
#                                                                      #
#                     action => what to do                        MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Updates information about a user.                                   #
#                                                                      #
#  "changeLogo" and "changeCSS" don't really belong here!              #
#                                                                      #
########################################################################

sub updateUser
{
    my(%args)= @_;
    unless(defined($args{action}))   { InhaleCore::error('InhaleWrite::updateUser was called without passing a "action" argument', 'bad call'); }
    unless(defined($args{text}))     { InhaleCore::error('InhaleWrite::updateUser was called without passing a "text" argument', 'bad call'); }

    unless(defined($args{account}))  { $args{account} = 0 }
    unless(defined($args{user}))     { $args{user}    = 0 }

    $args{account} =~ s/\D//g;
    $args{user}    =~ s/\D//g;

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    if( lc($args{action}) eq 'changepassword' && $args{user} )
    {
        $sth = $dbh->prepare(  "UPDATE users SET password='".cleanSQL( $args{text} )."' WHERE user=".$args{user}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'changeemail' && $args{user} )
    {
        $sth = $dbh->prepare(  "UPDATE users SET email='".cleanSQL( $args{text} )."' WHERE user=".$args{user}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'changerealname' && $args{user} )
    {
        $sth = $dbh->prepare(  "UPDATE users SET name='".cleanSQL( $args{text} )."' WHERE user=".$args{user}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'changeusername' && $args{user} )
    {
        $sth = $dbh->prepare(  "UPDATE users SET username='".cleanSQL( $args{text} )."' WHERE user=".$args{user}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'changeaccountname' && $args{account}  )
    {
        $sth = $dbh->prepare(  "UPDATE accounts SET title='".cleanSQL( $args{text} )."' WHERE account=".$args{account}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'changelogo' && $args{account}  )
    {
        $sth = $dbh->prepare(  "UPDATE accounts SET logo='".cleanSQL( $args{text} )."' WHERE account=".$args{account}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'changecss' && $args{account}  )
    {
        $sth = $dbh->prepare(  "UPDATE accounts SET css='".cleanSQL( $args{text} )."' WHERE account=".$args{account}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'cleareditor' && $args{user}  )
    {

        $sth = $dbh->prepare(  "DELETE FROM portfoliousers WHERE user=".$args{user}  );
        $sth->execute;
    }

    if( lc($args{action}) eq 'updateeditor' && $args{user} )
    {
        $sth = $dbh->prepare(  "INSERT INTO portfoliousers (portfolio,user) VALUES ($args{text},$args{user})" );
        $sth->execute;
    }

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;
}

########################################################################
#                                                                      #
#  InhaleWrite::createUser                                             #
#                                                                      #
########################################################################
#                                                                      #
#  Create a brand new user.  The following parameters can be passed:   #
#                                                                      #
#     realname        (MAN)                                            #
#     username        (MAN)                                            #
#     password        (MAN)                                            #
#     email           (OPT)                                            #
#     account         (MAN)                                            #
#     role            (MAN)                                            #
#                                                                      #
########################################################################

sub createUser
{
    my(%args)= @_;
    unless(defined($args{username})) { InhaleCore::error('InhaleWrite::createUser was called without passing a "username" argument', 'bad call'); }
    unless(defined($args{realname})) { InhaleCore::error('InhaleWrite::createUser was called without passing a "realname" argument', 'bad call'); }
    unless(defined($args{password})) { InhaleCore::error('InhaleWrite::createUser was called without passing a "password" argument', 'bad call'); }
    unless(defined($args{account}))  { InhaleCore::error('InhaleWrite::createUser was called without passing a "account" argument', 'bad call'); }
    unless(defined($args{role}))     { InhaleCore::error('InhaleWrite::createUser was called without passing a "role" argument', 'bad call'); }

    $args{account} =~ s/\D//g;

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    if( $args{account} )
    {
        $sth = $dbh->prepare(  "INSERT INTO users (user,username,password,account,email,role,name) VALUES(0,'".cleanSQL($args{username})."','".cleanSQL($args{password})."',$args{account},'".cleanSQL($args{email})."','".cleanSQL($args{role})."','".cleanSQL($args{realname})."' )" );
        $sth->execute;
    }

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;
}


########################################################################
#                                                                      #
#  InhaleWrite::createPortfolio                                        #
#                                                                      #
#  [NAMED ARGUMENTS]  account => account number                   MAN  #
#                                                                      #
#                       title => portfolio title                  MAN  #
#                                                                      #
#                      parent => parent portfolio number          OPT  #
#                                                                      #
########################################################################
#                                                                      #
#  Creates a brand new portfolio for the specified account.            #
#                                                                      #
#  If "parent" is blank or zero, then it's a new top level portfolio,  #
#  otherwise it will be a sub-portfolio under "parent"                 #
#                                                                      #
########################################################################

sub createPortfolio
{
    my(%args)= @_;
    unless(defined($args{account}))   { InhaleCore::error('InhaleWrite::createPortfolio was called without passing a "account" argument', 'bad call'); }
    unless(defined($args{title}))     { InhaleCore::error('InhaleWrite::createPortfolio was called without passing a "title" argument', 'bad call'); }

    unless(defined($args{parent}))  { $args{parent} = 0 }

    $args{account} =~ s/\D//g;
    $args{parent}  =~ s/\D//g;

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my $ret = 0;

    if( $args{account} && $args{title} )
    {
        $sth = $dbh->prepare( " INSERT INTO portfolios (portfolio,title,account,parent) VALUES (0,'".cleanSQL($args{title})."',$args{account},$args{parent})" );
        $sth->execute;
        $ret = $dbh->{'mysql_insertid'} || 0;
    }

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

### return ID of new portfolio...

    return( $ret );
}

########################################################################
#                                                                      #
#  InhaleWrite::deletePortfolio                                        #
#                                                                      #
#  [NAMED ARGUMENTS]  portfolio => portfolio number               MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Deletes the specified portfolio, along with any units that were     #
#  in the portfolio.                                                   #
#                                                                      #
########################################################################

sub deletePortfolio
{
    my(%args)= @_;
    unless(defined($args{portfolio}))   { InhaleCore::error('InhaleWrite::deletePortfolio was called without passing a "portfolio" argument', 'bad call'); }

    $args{portfolio} =~ s/\D//g;

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my @res = ( );

    if( $args{portfolio} )
    {
	my @units = ( );
	my @objects = ( );

        $sth = $dbh->prepare( " SELECT unit FROM units WHERE portfolio=$args{portfolio} " );
        $sth->execute;

	while( @res = $sth->fetchrow_array( ) )
	{
	    my $unit = $res[0] || 0;

	    if( $unit )
	    {
	        deleteUnit( unit => $unit );
	    }
	}

        $sth = $dbh->prepare( " DELETE FROM portfolios WHERE portfolio=$args{portfolio} " );
        $sth->execute;
    }

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

}

########################################################################
#                                                                      #
#  InhaleWrite::createAccount                                          #
#                                                                      #
#  [NAMED ARGUMENTS]      title => account title                  MAN  #
#                                                                      #
#                   contactInfo => contact information            MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Create a brand new account.                                         #
#                                                                      #
#                                                                      #
########################################################################

sub createAccount
{
    my(%args)= @_;
    unless(defined($args{title}))       { InhaleCore::error('InhaleWrite::createAccount was called without passing a "title" argument', 'bad call'); }
    unless(defined($args{contactInfo})) { InhaleCore::error('InhaleWrite::createAccount was called without passing a "contactInfo" argument', 'bad call'); }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my $ret = 0;

    $sth = $dbh->prepare( " INSERT INTO accounts (title,contactInfo) values ('".cleanSQL($args{title})."','".cleanSQL($args{contactInfo})."')" );
    $sth->execute;
    $ret = $dbh->{'mysql_insertid'} || 0;

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

    return( $ret );
}


########################################################################
#                                                                      #
#  InhaleWrite::updateAccount                                          #
#                                                                      #
#  [NAMED ARGUMENTS]     action => ...                            MAN  #
#                                                                      #
#                       account => account number                 MAN  #
#                                                                      #
#                          text => string                         MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Update account details.  Action can be one of the following:        #
#                                                                      #
#       updateTitle                                                    #
#       updateContactInfo                                              #
#                                                                      #
########################################################################

sub updateAccount
{
    my(%args)= @_;
    unless(defined($args{action}))  { InhaleCore::error('InhaleWrite::updateAccount was called without passing a "action" argument', 'bad call'); }
    unless(defined($args{account})) { InhaleCore::error('InhaleWrite::updateAccount was called without passing a "account" argument', 'bad call'); }
    unless(defined($args{text}))    { InhaleCore::error('InhaleWrite::updateAccount was called without passing a "text" argument', 'bad call'); }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my $ret = 0;

    $args{text} =~ s/\"/\'\'/g;

    if( lc($args{action}) eq 'updatetitle' )
    {
        $sth = $dbh->prepare( ' UPDATE accounts SET title="'.cleanSQL($args{text}).'" WHERE account='.$args{account} );
        $sth->execute;
    }

    if( lc($args{action}) eq 'updatecontactinfo' )
    {
        $sth = $dbh->prepare( ' UPDATE accounts SET contactInfo="'.cleanSQL($args{text}).'" WHERE account='.$args{account} );
        $sth->execute;
    }

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

    return( $ret );
}

########################################################################
#                                                                      #
#  InhaleWrite::deleteUser                                             #
#                                                                      #
#  [NAMED ARGUMENTS]       user => number of user to delete       MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Deletes the specified user from the database                        #
#                                                                      #
########################################################################

sub deleteUser
{
    my(%args)= @_;
    unless(defined($args{user}))  { InhaleCore::error('InhaleWrite::deleteUser was called without passing a "user" argument', 'bad call'); }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    my $user = $args{user};
    $user =~ s/\D//g;

    if( $user )
    {
        $sth = $dbh->prepare( ' DELETE FROM portfoliousers WHERE user='.$args{user} );
        $sth->execute;

        $sth = $dbh->prepare( ' DELETE FROM sessions WHERE user='.$args{user} );
        $sth->execute;

        $sth = $dbh->prepare( ' DELETE FROM users WHERE user='.$args{user} );
        $sth->execute;
    }

### close the DB statement handle...

    if( $sth ) { $sth->finish }
    $dbh->disconnect;
}

sub insertStats 
{
    my(%args)= @_;

    unless(defined($args{session})) { InhaleCore::error('InhaleWrite::insertStats was called without passing a "session" argument', 'bad call'); }
    unless(defined($args{page}))    { InhaleCore::error('InhaleWrite::insertStats was called without passing a "page" argument', 'bad call'); }
    unless(defined($args{unit}))    { InhaleCore::error('InhaleWrite::insertStats was called without passing a "unit" argument', 'bad call'); }
    unless($args{page} > 0)         { InhaleCore::error('InhaleWrite::insertStats was called with an invalid "page" argument ['.$args{page}.']', 'bad call'); }
    unless($args{unit} > 0)         { InhaleCore::error('InhaleWrite::insertStats was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }
    
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my @res = ( );

    $sth = $dbh->prepare(  "SELECT sessionNumber FROM statslookup WHERE sessionID='$args{session}'"  );
    $sth->execute;
    @res = $sth->fetchrow_array;
    my $sn = $res[0] || 0;

    $sth = $dbh->prepare(  "SELECT MAX(step) FROM steps WHERE unit=$args{unit}"  );
    $sth->execute;
    @res = $sth->fetchrow_array;
    my $total = $res[0] || 0;

    my $time = time( );

    $sth = $dbh->prepare( qq[  INSERT INTO stats (time,session,unit,step,total) VALUES ($time,$sn,$args{unit},$args{page},$total)  ] );
    $sth->execute;

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}

########################################################################
#                                                                      #
#  InhaleWrite::addFaq                                                 #
#                                                                      #
#  [NAMED ARGUMENTS]  category => faq category                    MAN  #
#                                                                      #
#                       question => faq                           MAN  #
#                                                                      #
#                      answer => faq answer                            #
#                                                                      #
########################################################################

sub addFaq
{
    my(%args)= @_;
    unless(defined($args{category}))   { InhaleCore::error('InhaleWrite::addFaq was called without passing a "category" argument', 'bad call'); }
    unless(defined($args{question}))     { InhaleCore::error('InhaleWrite::addFaq was called without passing a "question" argument', 'bad call'); }
    unless(defined($args{answer}))     { InhaleCore::error('InhaleWrite::addFaq was called without passing an "answer" argument', 'bad call'); }
 
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaq = ''; 

    if( $args{category} && $args{question} && $args{answer} )
    {
        $sthfaq = $dbh->prepare( " INSERT INTO faq(id,category,question,answer,last_edit) VALUES ('','$args{category}','$args{question}','$args{answer}', CURDATE() ) " );
        $sthfaq->execute;
    }

### close the DB statement handle...

    if( $sthfaq ) { $sthfaq->finish }
    $dbh->disconnect;

### return ID of new question...

    return( $args{question} );
}

########################################################################
#                                                                      #
#  InhaleWrite::updateFaq                                              #
#                                                                      #
#  [NAMED ARGUMENTS]  category => faq category                    MAN  #
#                                                                      #
#                     question => faq                             MAN  #
#                                                                      #
#                       answer => faq answer                           #
#                                                                      #
#			    faqid => faq id for update                    #
#                                                                      #
########################################################################

sub updateFaq
{
    my(%args)= @_;
    unless(defined($args{faqid}))   { InhaleCore::error('InhaleWrite::updateFaq was called without passing a "faqid" argument', 'bad call'); }
    unless(defined($args{category}))   { InhaleCore::error('InhaleWrite::updateFaq was called without passing a "category" argument', 'bad call'); }
    unless(defined($args{question}))     { InhaleCore::error('InhaleWrite::updateFaq was called without passing a "question" argument', 'bad call'); }
    unless(defined($args{answer}))     { InhaleCore::error('InhaleWrite::updateFaq was called without passing an "answer" argument', 'bad call'); }
 
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqupdate = ''; 

    if( $args{category} && $args{question} && $args{answer} && $args{faqid} )
    {
       $sthfaqupdate = $dbh->prepare( " UPDATE faq SET category ='$args{category}',question='$args{question}',answer='$args{answer}', last_edit=CURDATE() where id = $args{faqid} " );
       $sthfaqupdate->execute;
    }

### close the DB statement handle...

    if( $sthfaqupdate ) { $sthfaqupdate->finish }
    $dbh->disconnect;
}

########################################################################
#                                                                      #
#  InhaleWrite::deleteFaq                                              #
#                                                                      #
#  [NAMED ARGUMENTS]     faqid => faq id for update                    #
#                                                                      #
########################################################################

sub deleteFaq
{
    my(%args)= @_;
    unless(defined($args{faqid}))   { InhaleCore::error('InhaleWrite::deleteFaq was called without passing a "faqid" argument', 'bad call'); }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqdelete = ''; 

    if( $args{faqid} )
    {
#print qq(In sql \n";
       $sthfaqdelete = $dbh->prepare( " delete from faq where id=$args{faqid} " );
       $sthfaqdelete->execute;
    }

### close the DB statement handle...

    if( $sthfaqdelete ) { $sthfaqdelete->finish }
    $dbh->disconnect;
}

#########################################
#                                       #
#  VARIOUS PRIVATE ROUTINES FOLLOW....  #
#                                       #
#########################################

sub cleanSQL
{
    my $str = shift;
    $str =~ s/\"/\\"/g;
    return( $str );
}

sub compress {
    my($str) = @_;
    $str =~ s/\r/\\r/gi;
    $str =~ s/\n/\\n/gi;
    $str =~ s/\t/\\t/gi;
    return($str);
}

##########################################
# private routine to untaint a file path #
##########################################

sub untaintPath {
    my($path) = @_;
    $path =~ /^(.*)$/;
    my $ret = $1;
    $ret =~ s/\`\*\|\?\<\>\"//gi;
    return($ret);
}

############################
# load the INHALE.INI file #
############################

sub loadInhaleINI {

    my $server = lc($ENV{SERVER_SOFTWARE});
    $server =~ s/[^a-z0-9]//gi;

    my $iniFile = '';

    foreach my $path (@INC) {
        if(open(IN,"$path/$server-inhale.ini")) { $iniFile = "$path/$server-inhale.ini"; }
        if(open(IN,"$path/inhale.ini"))         { $iniFile = "$path/inhale.ini"; }
    }

    unless($iniFile) { error("unable to locate INI file [inhale.ini or $server-inhale.ini]"); }
    
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
            if($a eq 'objectdirpath')           { $objectDirPath = $b; }
            if($a eq 'objectvirpath')           { $objectVirPath = $b; }

	    if( $a eq 'mysqlport' )         { $mysqlPort = $b }
	    if( $a eq 'mysqlserver' )       { $mysqlServer = $b }
	    if( $a eq 'mysqldatabase' )     { $mysqlDatabase = $b }
	    if( $a eq 'mysqlusername' )     { $mysqlUsername = $b }
	    if( $a eq 'mysqlpassword' )     { $mysqlPassword = $b }
        }
    }
}








1;