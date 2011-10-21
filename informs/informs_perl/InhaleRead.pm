package InhaleRead;
use strict;
use locale;


BEGIN {
    my($LIBDIR);
    if ($0 =~ m!(.*[/\\])!) { $LIBDIR = $1; } else { $LIBDIR = './'; }
    unshift @INC, $LIBDIR . 'lib';

    use Exporter ( );
    
    @InhaleRead::ISA         = qw( Exporter );
    @InhaleRead::EXPORT      = qw( value );
    @InhaleRead::EXPORT_OK   = qw( getObject getUnit getPage getObjectData getFolioUnits getFolioUnitsById
                                   validateUser getUserNumber getAccountDetails getSubAccounts 
                                   getAccountNumbers readMetadata fetchLinks getParents getAccountObjects
                                   checkObjectExists getUserSession getFolioDetails endSession getNewSessionID
                                   statsQuick statsSummary getQuickUserInfo getAudit  
				   getUserInfo getEditorFolios searchFolioUnits browseFolioUnits searchByDate 
				   searchWithImages lastEdited totalSteps lastViewed getFaqCategories getFaqs 
				   getFaqQuestions getFaqCatsForSite getFaqAnswer getNumAccounts getNumLiveUnits copyCount getTags newAndUpdated);
    %InhaleRead::EXPORT_TAGS = ( );
}

    use DBI;
    my $dbh = '';
    my $reuseDatabaseHandle = 1;

###########################
# declare local variables #
###########################

    my $dataPath;			
    my $uploadPath;
    my $objectDirPath;
    my $objectVirPath;

    my $mysqlPort;
    my $mysqlServer;
    my $mysqlDatabase;
    my $mysqlUsername;
    my $mysqlPassword;
    
    loadInhaleINI( );

###############################
# declare temporary variables #
###############################

    my($filename, $undef, $tmp);
    my $newline = "\n";
    my $status;

    sub readMetadata {
        my(%args) = @_;
        my $unit = $args{unit} || '';	
        my %metadata = ( );

        if(open(IN, $dataPath."metadata/$unit.txt")) {
            while(my $line = <IN>) {
    	        $line =~ s/[\r\n]//gi;    	
      	        if($line) {
  	            my($id, $data) = split(/\t/, $line);
  	            if($data =~ /^\.+?$/) { $data = ''; }
	            $metadata{$id} = expand($data);
  	        }
            }
            close(IN);
        }

        return(%metadata);
    }

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

    return( $dbh );
}


########################################################################
#                                                                      #
#  InhaleRead::getObject                                               #
#                                                                      #
#  [NAMED ARGUMENTS]    object => the number of the object        MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  InhaleRead::getUnit                                                 #
#                                                                      #
#  [NAMED ARGUMENTS]    unit   => the number of the unit          MAN  #
#                                                                      #
#                       folio  => the number of the portfolio     OPT  #
#                                                                      #
#                   skiperrors => boolean (1 or 0)                OPT  #
#                                                                      #
########################################################################
#                                                                      #
#  InhaleRead::getPage                                                 #
#                                                                      #
#  [NAMED ARGUMENTS]    page   => the number of the page          MAN  #
#                                                                      #
#                       unit   => the number of the unit          MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Constructors for creating and populating the three OObject hash     #
#  references (objects, pages and units).                              #
#                                                                      #
#  Each constructor requires named arguments to be passed, the         #
#  values of which should be numeric.                                  #
#                                                                      #
#  The optional folio argument of getUnit defaults to '1'.             #
#                                                                      #
#  Each constructor calls upon a private function to populate the      #
#  relevant OObject.                                                   #
#                                                                      #
#  If skiperrors (default 0) is set to 1, then otherwise fatal errors  #
#  are ignored.                                                        #
#                                                                      #
########################################################################

    sub getObject {
        my(%args)= @_;
        unless(defined($args{object}))      { $args{object} = '0'; }
        unless($args{object} =~ /^-?\d+?$/) { $args{object} = '0'; }
    
        my $self = {};
        bless($self);

        if($args{object} != 0) { loadObject($self, $args{object}); }
        return $self;
    }

    sub getUnit 
    {
        my(%args)= @_;
        unless(defined($args{unit})) { InhaleCore::error('InhaleRead::getUnit was called without passing a "unit" argument', 'bad call'); }
        unless($args{unit} > 0)      { InhaleCore::error('InhaleRead::getUnit was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }
        unless(defined($args{skiperrors})) { $args{skiperrors} = 0 }

	my $skiperrors = 1;
	if( $args{skiperrors} == 1 ) { $skiperrors = 1 }

        my $unitNumber  = $args{unit};
        my $folioNumber = $args{folio} || '1';

        my $self = {};
        bless($self);

        loadUnit( $self, $unitNumber, $folioNumber, $skiperrors );
        return $self;

    }

    sub getPage {
        my(%args)= @_;
        unless(defined($args{page})) { InhaleCore::error('InhaleRead::getPage was called without passing a "page" argument', 'bad call'); }
        unless(defined($args{unit})) { InhaleCore::error('InhaleRead::getPage was called without passing a "unit" argument', 'bad call'); }
        unless($args{page} > 0)      { InhaleCore::error('InhaleRead::getUnit was called with an invalid "page" argument ['.$args{page}.']', 'bad call'); }
        unless($args{unit} > 0)      { InhaleCore::error('InhaleRead::getUnit was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }

        my $pageNumber = $args{page};
        my $unitNumber = $args{unit};

        my $self = {};
        bless($self);

        loadPage($self, $pageNumber, $unitNumber);
        return $self;
    }


########################################################################
#                                                                      #
#  InhaleRead::loadObject                                              #
#                                                                      #
#  [ARGUMENTS]    1. a blessed reference to a hash                MAN  #
#                                                                      #
#                 2. the number of the object                     MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Populates an object OObject ;-)                                     #
#                                                                      #
#  The following values may be created:                                #
#                                                                      #
#    > encoding     - An optional value suitable for use as the        #
#                     charset value, either in the HTTP header or as   #
#                     a <meta http-equiv> tag, that specifies the      #
#                     most relevant "language" for the object.         #
#                     The default is "iso-8859-1".                     #
#                     See www.w3.org/International/O-HTTP-charset      #
#                                                                      #
#    > fileName     - The physical file name of the object as it is    #
#                     stored on the web server.                        #
#                                                                      #
#    > fileType     - An upper case three character string that        #
#                     represents the "file type" of the object.        #
#                     The string is typically the file extension for   #
#                     that type of object under the Win32 platform     #
#                     e.g. TXT, JPG, PDF, HTM, SWF, DOC, GIF, etc      #
#                                                                      #
#    > objectNumber - The number of the object.                        #
#                                                                      #
#    > ownerNumber  - The account number of the current owner of the   #
#                     object.                                          #
#                                                                      #
#    > timeStamp    - The time (in epoch seconds) that the object      #
#                     was either created or last editied.              #
#                                                                      #
#    > usageCounter - THIS ELEMENT IS NOW REDUNDANT AS THE OVERHEAD    #
#                     FOR IT'S CREATION WAS TOO MUCH                   #
#                                                                      #
#    > virLocation  - The URL path to the object, suitable for         #
#                     linking directly to the object in a              #
#                     hyperlink.                                       #
#                                                                      #
########################################################################

    sub loadObject {
        my $self         = shift;
        my $objectNumber = shift;

        $self->{objectNumber} = '';
        $self->{usageCounter} = 0;

### get a valid database handle and create a fresh statement handle...

        my $dbh = $dbh || getDBH( );
        my $sth = '';
	my @res = ( );

    
        $sth = $dbh->prepare(  "SELECT count( step ) FROM steps WHERE ( leftFrame = $objectNumber OR rightFrame = $objectNumber )"  );
        $sth->execute;
        @res = $sth->fetchrow_array;

	if( $res[0] )
        {
            $self->{usageCounter} = $res[0];
        }

### get object details...

        $sth = $dbh->prepare(  "SELECT filename,description,filetype,creationTimeStamp,owner,encoding,deleted FROM objects WHERE object = $objectNumber"  );
        $sth->execute;
        @res = $sth->fetchrow_array;

	my $deleted = 0;

	if( $res[0] )
	{
            $self->{objectNumber} = $objectNumber;
            $self->{fileName}     = $res[0];
            $self->{description}  = $res[1];
            $self->{fileType}     = $res[2];
            $self->{timeStamp}    = $res[3];
            $self->{ownerNumber}  = $res[4];
            $self->{encoding}     = $res[5];
	    $deleted              = $res[6];

            if(defined($self->{fileName})) { $self->{virLocation} = $objectVirPath.$self->{fileName}; }
            else { $self->{virLocation} = ''; }
	}
	else
	{
	    InhaleCore::error('unable to locate details for object #'.$objectNumber, 'database');
	}

	if( $deleted )
	{
            $sth = $dbh->prepare(  "UPDATE objects SET deleted=0 WHERE object=$objectNumber"  );
            $sth->execute;
	}

### close the DB statement handle...

        $sth->finish;
	$dbh->disconnect;

    }


########################################################################
#                                                                      #
#  InhaleRead::loadUnit                                                #
#                                                                      #
#  [ARGUMENTS]    1. a blessed reference to a hash                MAN  #
#                                                                      #
#                 2. the number of the unit                       MAN  #
#                                                                      #
#                 3. the number of the portfolio                  MAN  #
#                                                                      #
#                 4. skip errors?                                 OPT  #
#                                                                      #
########################################################################
#                                                                      #
#  Populates an unit OObject.                                          #
#                                                                      #
#  The following values may be created:                                #
#                                                                      #
#    > folioDescription -                                              #
#                                                                      #
#    > folioOpenMethod  -                                              #
#                                                                      #
#    > folioUnitTitle   -                                              #
#                                                                      #
#    > folioVisibility  -                                              #
#                                                                      #
#    > totalPages       -                                              #
#                                                                      #
#    > totalSteps       -                                              #
#                                                                      #
#    > unitNumber       -                                              #
#                                                                      #
#    > unitTitle        -                                              #
#                                                                      #
########################################################################

    sub loadUnit 
    {
        my $self        = shift;
        my $unitNumber  = shift;
        my $folioNumber = shift;
        my $skiperrors  = shift || 0;

        $self->{folioUnitTitle} = '';
        $self->{folioOpenMethod} = '';
        $self->{folioDescription} = '';
        $self->{folioVisibility} = '';
        $self->{userStylesheet} = '';
        $self->{totalPages} = 0;

### get a valid database handle and create a fresh statement handle...

        my $dbh = $dbh || getDBH( );
        my $sth = ''; 
        my @res = ( );
    
### get unit details...

        $sth = $dbh->prepare(  "SELECT title,description,visible,openMethod,portfolio,unit FROM units WHERE unit = $unitNumber"  );
        $sth->execute;
        @res = $sth->fetchrow_array;

        $self->{unitTitle}        = $res[0] || '';
        $self->{folioOpenMethod}  = $res[3] || '';
        $self->{folioDescription} = $res[1] || '';
        $self->{folioVisibility}  = $res[2] || '';
        $self->{folioUnitTitle}   = $res[0] || ''; 
        $self->{unitNumber}       = $res[5] || 0;
	my $portfolio             = $res[4] || 0;
        $self->{unitPortfolio}   = $res[4] || 0;
### pick any custom stylesheet...

        $sth = $dbh->prepare(  "SELECT css FROM accounts,portfolios where accounts.account=portfolios.account and portfolio=".$portfolio  );
        $sth->execute;
        @res = $sth->fetchrow_array;

	$self->{userStylesheet} = $res[0] || '';


### get the total number of steps in the unit...

        $sth = $dbh->prepare(  "SELECT COUNT(step) FROM steps WHERE unit = $unitNumber"  );
        $sth->execute;
        @res = $sth->fetchrow_array;
        $self->{totalPages} = $res[0] || 0;

        $self->{totalSteps} = $self->{totalPages} - 1;
        
### return an error if we didn't find the unit...

        if( ( $self->{unitNumber} < 1 ||  $self->{unitTitle} eq '' ) && !$skiperrors ) 
        { 
            InhaleCore::error('unable to locate details for unit #'.$unitNumber, 'database'); 
        }

### close the DB statement handle...

        $sth->finish;
	$dbh->disconnect;
    }
    
       
########################################################################
#                                                                      #
#  InhaleRead::loadPage                                                #
#                                                                      #
#  [ARGUMENTS]    1. a blessed reference to a hash                MAN  #
#                                                                      #
#                 2. the number of the page                       MAN  #
#                                                                      #
#                 3. the number of the unit                       MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Populates a page OObject.                                           #
#                                                                      #
#  The following values may be created:                                #
#                                                                      #
#    > unitNumber    - The unit number of the unit the page            #
#                      belongs to.                                     #
#                                                                      #
#    > pageNumber    - The page number of the page.                    #
#                                                                      #
#    > leftFrame     - Typically the number of the object to be        #
#                      displayed in the Guide at the Side.             #
#                                                                      #
#    > rightFrame    - Typically the number of the object (if any)     #
#                      to be displayed in the main righthand frame.    #
#                                                                      #
#    > rightFrameURL - If not database object is to be displayed in    #
#                      the main righthand frame, then this entry       #
#                      contains a URL to be loaded into the frame.     #
#                                                                      #
#    > heading       - An optional heading to be used in the Table     #
#                      of Contents for the entire unit.                #
#                                                                      #
#    > contents      - A compressed list of the full Table of          #
#                      Contents for the entire unit.                   #
#                                                                      #
#  A series of entries are also populated to hold information about    #
#  the preceeeding and following steps (if they exist), these are:     #
#                                                                      #
#            prevPageNumber            nextPageNumber                  #
#            prevLeftFrame             nextLeftFrame                   #
#            prevRightFrame            nextRightFrame                  #
#            prevRightFrameURL         nextRightFrameURL               #
#            prevHeading               nextHeading                     #
#                                                                      #
########################################################################

sub loadPage 
{
    my $self       = shift;
    my $pageNumber = shift;
    my $unitNumber = shift;

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';

### get all of the steps in the unit...

    $sth = $dbh->prepare(  "SELECT unit, step, leftFrame, rightFrame, url, toc FROM steps WHERE unit = $unitNumber ORDER BY step"  );
    $sth->execute;

### process all of the steps...

    while( my @res = $sth->fetchrow_array )
    {
        $self->{totalPages}++;
	
        if( $res[1] == $pageNumber )
        {
            $self->{unitNumber}    = $res[0];
            $self->{pageNumber}    = $res[1];
            $self->{leftFrame}     = $res[2] || 0;
            $self->{rightFrame}    = $res[3] || 0;
            $self->{rightFrameURL} = $res[4] || '';
            $self->{heading}       = $res[5] || '';
        }
        elsif( $res[1] == ($pageNumber + 1) )
        {
            $self->{nextPageNumber}    = $res[1];
            $self->{nextLeftFrame}     = $res[2] || 0;
            $self->{nextRightFrame}    = $res[3] || 0;
            $self->{nextRightFrameURL} = $res[4] || '';
            $self->{nextHeading}       = $res[5] || '';
        }
        elsif( $res[1] == ($pageNumber - 1) )
        {
            $self->{prevPageNumber}    = $res[1];
            $self->{prevLeftFrame}     = $res[2] || 0;
            $self->{prevRightFrame}    = $res[3] || 0;
            $self->{prevRightFrameURL} = $res[4] || '';
            $self->{prevHeading}       = $res[5] || '';
        }

### populate the table of contents...

        if( $res[5] )
        {
            my $parent = 0;
            if( $res[3] || $res[4] ) { $parent = 1; }

            if( $self->{contents} )  { $self->{contents} .= "\t".substr("00000".$res[1], -5)."=$parent=$res[5]"; }
            else                     { $self->{contents} .= substr("00000".$res[1], -5)."=$parent=$res[5]"; }
        }
    }    

### return an error if we didn't find the requested page...

    if( $self->{pageNumber} ne $pageNumber ) 
    { 
        InhaleCore::error('unable to locate details for page #'.$pageNumber .', unit #'.$unitNumber, 'database'); 
    }

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;
}


########################################################################
#                                                                      #
#  InhaleRead::checkObjectExists                                       #
#                                                                      #
#  [ARGUMENTS]     object => an object number                     MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Quick routine to check if an specified object exists.               #
#                                                                      #
#  Returns 1 (for true) or 0 (does not exist)                          #
#                                                                      #
########################################################################


    sub checkObjectExists 
    {
        my $objectNumber = shift;
	my $exists       = 0;

	$objectNumber    =~ s/\D//g;

	if( $objectNumber > 0 )
	{

### get a valid database handle and create a fresh statement handle...

            my $dbh = $dbh || getDBH( );
            my $sth = ''; 

            $sth = $dbh->prepare(  "SELECT filename FROM objects WHERE object=$objectNumber"  );
            $sth->execute;
            my @res = $sth->fetchrow_array;

	    my $fn = $res[0] || '';
	    if( $fn )
	    {
		$fn = $objectDirPath.$fn;
		if( -e $fn )
		{
		    $exists = 1;
		}
	    }

### close the DB statement handle...

            $sth->finish;
  	    $dbh->disconnect;
	}

	return( $exists );
    }


########################################################################
#                                                                      #
#  InhaleRead::getObjectData                                           #
#                                                                      #
#  [NAMED ARGUMENTS]    object => an object OObject               MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Returns the entire contents of the requested database object in     #
#  a scalar string.                                                    #
#                                                                      #
#  The binmode( ) function is used, so the string may contain binary.   #
#                                                                      #
#  A single named argument should be passed to the function and it     #
#  is expected that this be an database object OObject.  However,      #
#  the function will attempt to trap requests where the argument is    #
#  numeric and generate a temporary database object OObject.           #
#                                                                      #
########################################################################

sub getObjectData 
{
    my(%args)= @_;
    unless(defined($args{object})) { InhaleCore::error('getObject( ) was called without passing an "object" reference or argument', 'bad call'); }

    if(ref($args{object}) ne 'InhaleRead') { 
        if($args{object} =~ /^\d+?$/) { 
            $args{object} = getObject( object => $args{object} );
        }
        else {
            InhaleCore::error('getObject( ) was called without passing an "object" reference or argument', 'bad call');
        }
    }

    my $ret = '';
    my $location = $objectDirPath.$args{object}->{fileName};

    open(TEMP, $location) || InhaleCore::error('unable to access object file for object #'. $args{object}->{objectNumber}, 'database');
    binmode(TEMP);
    while(<TEMP>) {
        $ret .= $_;
    }
    close(TEMP);
    return($ret);
}


########################################################################
#                                                                      #
#  InhaleRead::value                                                   #
#                                                                      #
#  [ARGUMENTS]    1. a $page, $unit or $object OObject            MAN  #
#                                                                      #
#                 2. the name of the element to retrieve          MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Retrieves the value of the specified element from OObject.          #
#                                                                      #
#  One thing worth noting is that if the element is undefined then     #
#  an empty string is returned (as opposed to 'undef').  This comes    #
#  in handy if you want to avoid getting warnings about "Use of        #
#  uninitialized values".                                              #
#                                                                      #
########################################################################

sub value {
    my $var = shift;
    my $val = shift;
    
    my $ret = '';

    if(defined($var->{$val})) { $ret = $var->{$val}; }
#    else                      { warn "just to let you know that $val was undefined"; }
    return($ret);    
}


########################################################################
#                                                                      #
#  InhaleRead::getFolioUnits                                           #
#                                                                      #
#  [NAMED ARGUMENTS]    folio => the number of the portfolio      MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Returns a list of the units in the specified portfolio.             #
#                                                                      #
#  The list is a series of ^^ (double caret) delimited elements        #
#  containing the following details:                                   #
#                                                                      #
#      1) a sorting number (pre-padded with zeros)                     #
#                                                                      #
#      2) the number of the unit                                       #
#                                                                      #
#      3) the title of the unit                                        #
#                                                                      #
#      4) an optional free text description of the unit                #
#                                                                      #
#      3) details of how to open the unit                              #
#                                                                      #
#      6) the visibility of the unit (Y or N)                          #
#                                                                      #
########################################################################

sub getFolioUnits 
{
    my(%args)= @_;
    unless(defined($args{folio})) { InhaleCore::error('InhaleRead::getFolioUnits( ) was called without passing a "folio" argument', 'bad call'); }

    my $folio = $args{folio};
    my @units = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### fetch all the units in the portfolio...

    $sth = $dbh->prepare(  "SELECT unit, title, description, visible, displayOrder, openMethod FROM units WHERE portfolio = $folio order by title"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3];
    }
    return(@units);
}

sub getFolioUnitsById
{
    my(%args)= @_;
    unless(defined($args{folio})) { InhaleCore::error('InhaleRead::getFolioUnits( ) was called without passing a "folio" argument', 'bad call'); }

    my $folio = $args{folio};
    my @units = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### fetch all the units in the portfolio...

    $sth = $dbh->prepare(  "SELECT unit, title, description, visible, displayOrder, openMethod FROM units WHERE portfolio = $folio order by unit"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3];
    }
    return(@units);
}

#######################################################
# Search unit description for search form             #
#[NAMED ARGUMENTS]    term => the search term      MAN#
####################################################### 

sub searchFolioUnits 
{
    my(%args)= @_;
    unless(defined($args{term})) { InhaleCore::error('InhaleRead::searchFolioUnits( ) was called without passing a "term" argument', 'bad call'); }

    my $searchterm = $args{term};
    my @units = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### fetch all the units in the portfolio...

    $sth = $dbh->prepare(  "SELECT unit, title, description, portfolio, visible, displayOrder, openMethod, last_edited FROM units WHERE title like '%$searchterm%' or description  like '%$searchterm%' order by title"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3].'^^'.$res[7];
    }

    return(@units);
}


###############################################################
# Search unit description by date for search form             #
#[NAMED ARGUMENTS]    term => the search term      MAN        #
#[NAMED ARGUMENTS]    period => the date range     MAN        # 
############################################################### 

sub searchByDate 
{
    my(%args)= @_;
    unless(defined($args{term})) { InhaleCore::error('InhaleRead::searchByDate( ) was called without passing a "term" argument', 'bad call'); }
    unless(defined($args{period})) { InhaleCore::error('InhaleRead::searchByDate( ) was called without passing a "period" argument', 'bad call'); }

    my $searchterm = $args{term};
    my $period = $args{period};
    my @units = ( );
    my $year ='';
    my $month='';

### set the date sql depending on input...

### search within current month ###
if($period =~ /thismonth/){
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### get the current year
    $sth = $dbh->prepare(  "SELECT year(curdate())"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
    $year = $res[0];
    }
    my $sthx = ''; 
### get the current month
    $sthx = $dbh->prepare(  "SELECT month(curdate())"  );
    $sthx->execute;

    while( my @res = $sthx->fetchrow_array )
    {
    $month = $res[0];
    }

### some month formatting
if($month <10){
$month="0".$month;
}

my $searchdate=$year."-".$month;

   my $sthz = ''; 
### fetch all the units in the portfolio...

    $sthz = $dbh->prepare(  "SELECT unit, title, description, portfolio, visible, displayOrder, openMethod, last_edited FROM units WHERE last_edited like '$searchdate%' and title like '%$searchterm%' or last_edited like '$searchdate%' and description like '%$searchterm%' order by title"  );
    $sthz->execute;

    while( my @res = $sthz->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3].'^^'.$res[7];
    }
    return(@units);
}

### search within last 3 months ###
if($period =~ /last3months/){
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthy = ''; 

### fetch all the units in the portfolio...

    $sthy = $dbh->prepare(  "SELECT unit, title, description, portfolio, visible, displayOrder, openMethod, last_edited FROM units WHERE last_edited BETWEEN date(date_add(curdate( ) , INTERVAL -3 MONTH )) AND curdate() and title like '%$searchterm%' or last_edited BETWEEN date(date_add(curdate( ) , INTERVAL -3 MONTH )) AND curdate() and description like '%$searchterm%' order by title");
    $sthy->execute;

    while( my @res = $sthy->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3].'^^'.$res[7];
    }
    return(@units);
}

### search within last 6 months ###
if($period =~ /last6months/){
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthxx = ''; 

### fetch all the units in the portfolio...

    $sthxx = $dbh->prepare(  "SELECT unit, title, description, portfolio, visible, displayOrder, openMethod, last_edited FROM units WHERE last_edited BETWEEN date(date_add(curdate( ) , INTERVAL -6 MONTH )) AND curdate() and title like '%$searchterm%' or last_edited BETWEEN date(date_add(curdate( ) , INTERVAL -6 MONTH )) AND curdate() and description like '%$searchterm%' order by title");
    $sthxx->execute;

    while( my @res = $sthxx->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3].'^^'.$res[7];
    }
    return(@units);
}
}

####################################################################
# Search unit description including images for search form         #
#[NAMED ARGUMENTS]    term => the search term      MAN             # 
####################################################################

sub searchWithImages 
{
    my(%args)= @_;
    unless(defined($args{term})) { InhaleCore::error('InhaleRead::searchFolioUnits( ) was called without passing a "term" argument', 'bad call'); }

    my $searchterm = $args{term};
    my @units = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### fetch all the units in the portfolio...

    $sth = $dbh->prepare(  "SELECT object,filename,description,filetype FROM objects WHERE description like '%$searchterm%' 
				and filetype ='gif' or description like '%$searchterm%' and filetype='jpg' or description like '%$searchterm%' and 
				filetype ='png' or description like '%$searchterm%' and filetype='bmp'"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
        push @units, substr("00000".$res[0],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[3].'^^'.$res[4];
    }

    return(@units);
}


#########################################################################
# Get last edited date for unit for stats                               #
#[NAMED ARGUMENTS]    unit => the unit number                        MAN#
######################################################################### 

sub lastEdited 
{
    my(%args)= @_;
    unless(defined($args{unit})) { InhaleCore::error('InhaleRead::lastEdited( ) was called without passing a "unit" argument', 'bad call'); }

    my $unit = $args{unit};
    my $lastedited='';
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### get last edited date for the unit...

    $sth = $dbh->prepare(  "SELECT last_edited FROM units WHERE unit =$unit"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
       $lastedited= $res[0];
    }
    return($lastedited);
}

#########################################################################
# Get last viewed date for unit for stats                               #
#[NAMED ARGUMENTS]    unit => the unit number                        MAN#
######################################################################### 

sub lastViewed 
{
    my(%args)= @_;
    unless(defined($args{unit})) { InhaleCore::error('InhaleRead::lastEdited( ) was called without passing a "unit" argument', 'bad call'); }

    my $unit = $args{unit};
    my $lastviewed='';
    my $time='';
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my $sth2 = ''; 

### get last edited date for the unit...

    $sth = $dbh->prepare(  "SELECT max(time) FROM stats WHERE unit =$unit"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
    $time =$res[0];
    }
    $time =~ s/^\s+//;
    $time =~ s/\s+$//;

    $sth2 = $dbh->prepare(  "SELECT FROM_UNIXTIME('$time')" );
    $sth2->execute;

    while( my @dateout = $sth2->fetchrow_array )
    {
      $lastviewed= $dateout[0];
    }

    return($lastviewed);
}


##############################################################################
# Get the number of steps for a unit for stats                               #
#[NAMED ARGUMENTS]    unit => the unit number                             MAN#
############################################################################## 

sub totalSteps
{
    my(%args)= @_;
    unless(defined($args{unit})) { InhaleCore::error('InhaleRead::lastEdited( ) was called without passing a "unit" argument', 'bad call'); }

    my $unit = $args{unit};
    my $totalsteps='';
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### get last edited date for the unit...

    $sth = $dbh->prepare(  "SELECT count(*) FROM steps WHERE unit =$unit"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
       $totalsteps= $res[0];
    }
    return($totalsteps);
}


#######################################################
# no args just return list of distinct faq categories #
####################################################### 

sub getFaqCategories
{
my @faqCats = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqcats = ''; 

### get last edited date for the unit...

    $sthfaqcats = $dbh->prepare(  "SELECT distinct category from faq order by category"  );
    $sthfaqcats->execute;

    while( my @res = $sthfaqcats->fetchrow_array )
    {
       push @faqCats, '<option value ="'.$res[0].'">'.$res[0].'</option>';
    }
    return(@faqCats);
}

#######################################################
# no args just return list of faqs                    #
####################################################### 

sub getFaqs
{
my @faqs = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqs = ''; 

### get last edited date for the unit...

    $sthfaqs = $dbh->prepare(  "SELECT * from faq order by category"  );
    $sthfaqs->execute;

    while( my @res = $sthfaqs->fetchrow_array )
    {
       push @faqs, '<tr><td>'.$res[0].'</td><td>'.$res[1].'</td><td>'.$res[2].'</td><td>'.$res[3].'</td><td>'.$res[4].'</td><td><a href="faq.pl?folio=1&amp;a=editfaq&amp;faqid='.$res[0].'&amp;text='.$res[1].'&amp;text1='.$res[2].'&amp;text2='.$res[3].'">edit</a></td><td><a href="faq.pl?folio=1&amp;a=deletefaq&amp;faqid='.$res[0].'">delete</a></td></tr>';
    }
    return(@faqs);
}

###############################################################
# no args just return list of distinct faq categories and ids #
############################################################### 

sub getFaqCatsForSite
{
my @faqCatsForSite = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqcats = ''; 

### get last edited date for the unit...

    $sthfaqcats = $dbh->prepare(  "SELECT distinct category from faq order by category desc"  );
    $sthfaqcats->execute;

    while( my @res = $sthfaqcats->fetchrow_array )
    {
       push @faqCatsForSite, $res[0];
    }
return @faqCatsForSite
}


########################################################
#Returns a list of faqs per category                   #
#[NAMED ARGUMENTS]    category => the faq category  MAN#
########################################################  

sub getFaqQuestions
{
my(%args)= @_;
unless(defined($args{category})) { InhaleCore::error('InhaleRead::getFaqQuestions( ) was called without passing a "category" argument', 'bad call'); }
my $category = $args{category};
my @faqs = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqs = ''; 

### get last edited date for the unit...

    $sthfaqs = $dbh->prepare(  "SELECT * from faq where category like '$category' order by id"  );
    $sthfaqs->execute;

    while( my @res = $sthfaqs->fetchrow_array )
    {
       push @faqs, '<tr><td><a href="faqdetail.pl?faqansid='.$res[0].'">'.$res[2].'</a></td></tr>';
    }
    return(@faqs);
}

########################################################
#Returns the answer to an faq                          #
#[NAMED ARGUMENTS]    id => the faq category id     MAN#
########################################################  

sub getFaqAnswer
{
my(%args)= @_;
unless(defined($args{id})) { InhaleCore::error('InhaleRead::getFaqAnswer( ) was called without passing an "id" argument', 'bad call'); }
my $categoryid = $args{id};
my $faqans = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqs = ''; 

    $sthfaqs = $dbh->prepare(  "SELECT * from faq where id = $categoryid"  );
    $sthfaqs->execute;

    while( my @res = $sthfaqs->fetchrow_array )
    {
       $faqans .= $res[0].';'.$res[1].';'.$res[2].';'.$res[3];
    }
    return($faqans);
}


########################################################
#Returns the total number of Informs accounts          #
########################################################  

sub getNumAccounts
{
my $numaccounts = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqs = ''; 

    $sthfaqs = $dbh->prepare(  "SELECT count(*) from accounts"  );
    $sthfaqs->execute;

    while( my @res = $sthfaqs->fetchrow_array )
    {
       $numaccounts .= $res[0];
    }
    return($numaccounts);
}


########################################################
#Returns the total number of live units                #
########################################################  

sub getNumLiveUnits
{
my $numlive = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqs = ''; 

    $sthfaqs = $dbh->prepare(  "SELECT count(*) from units where visible='Y'"  );
    $sthfaqs->execute;

    while( my @res = $sthfaqs->fetchrow_array )
    {
       $numlive .= $res[0];
    }
    return($numlive);
}

########################################################
#Returns the number of times a unit has been copied    #
#[NAMED ARGUMENTS]    unit => the unit id           MAN#
########################################################  

sub copyCount
{
my(%args)= @_;
unless(defined($args{unit})) { InhaleCore::error('InhaleRead::copyCount( ) was called without passing a "unit" argument', 'bad call'); }
my $unitid = $args{unit};
my $copycount = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthcopied = ''; 

    $sthcopied = $dbh->prepare(  "SELECT count(*) from unitscopied where originalunitid = '$unitid'"  );
    $sthcopied->execute;

    while( my @res = $sthcopied->fetchrow_array )
    {
       $copycount .= $res[0];
    }
    return($copycount);
}


########################################################
#Returns the number of times a unit has been copied    #
#[NAMED ARGUMENTS]    unit => the unit id           MAN#
########################################################  

sub getTags
{
my(%args)= @_;
unless(defined($args{unit})) { InhaleCore::error('InhaleRead::copyCount( ) was called without passing a "unit" argument', 'bad call'); }
my $unitid = $args{unit};
my $myTags = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthcopied = ''; 

    $sthcopied = $dbh->prepare(  "SELECT tags from informstags where unit = '$unitid'  ORDER by tags ASC");
    $sthcopied->execute;

    while( my @res = $sthcopied->fetchrow_array )
    {
       $myTags .= " ". $res[0].", ";
    }
    return($myTags);
}


#######################################################
# Browse by unit title from search form               #
#[NAMED ARGUMENTS]    term => the browse letter    MAN#
####################################################### 

sub browseFolioUnits 
{
    my(%args)= @_;
    unless(defined($args{term})) { InhaleCore::error('InhaleRead::browseFolioUnits( ) was called without passing a "letter" argument', 'bad call'); }

    my $browseletter = $args{term};
    my @units = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### fetch all the units in the portfolio...

    $sth = $dbh->prepare(  "SELECT unit, title, description, portfolio, visible, displayOrder, openMethod FROM units WHERE title like '$browseletter%' order by title"  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
        push @units, substr("00000".$res[4],-5).'^^'.$res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[5].'^^'.$res[3];
    }

    return(@units);
}


sub getFolioDetails
{
    my( %args ) = @_;
    unless(defined($args{folio})) { InhaleCore::error('InhaleRead::getFolioDetails( ) was called without passing a "folio" argument', 'bad call'); }

    my %ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';
    my @res = ();

### get session details...

    $sth = $dbh->prepare(  "SELECT title,account,parent FROM portfolios WHERE portfolio=$args{folio} order by title desc"  );
    $sth->execute;

    @res = $sth->fetchrow_array( );
    $ret{portfolioName}    = $res[0] || '[ unknown portfolio title ]';
    $ret{portfolioAccount} = $res[1] || 0;
    $ret{portfolioParent}  = $res[2] || 0;

    $sth = $dbh->prepare(  "SELECT title,logo,css FROM accounts WHERE account=$ret{portfolioAccount} "  );
    $sth->execute;

    @res = $sth->fetchrow_array( );
    $ret{portfolioAccountTitle} = $res[0] || '[ unknown account title ]';
    $ret{portfolioCustomLogo}   = $res[1] || '';
    $ret{portfolioCutsomCSS}    = $res[2] || '';

    if( $ret{portfolioParent} )
    {
        $sth = $dbh->prepare(  "SELECT title FROM portfolios WHERE portfolio=$ret{portfolioParent}"  );
        $sth->execute;
        @res = $sth->fetchrow_array( );
	$ret{portfolioParentName} = $res[0];
    }
    else
    {
        $sth = $dbh->prepare(  "SELECT portfolio,title FROM portfolios WHERE account=$ret{portfolioAccount} AND parent > 0"  );
        $sth->execute;
	my @children = ( );

	while( @res = $sth->fetchrow_array( ) )
	{
	    push @children, $res[1].'  :::'.$res[0];

	}
	if( @children )
	{
	    $ret{portfolioChildren} = join( '|', sort @children );
	}
	else
	{
	    $ret{portfolioChildren} = '';
	}
    }

###

    $ret{accountImage} = $ret{portfolioCustomLogo};

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return( %ret );    
}


########################################################################
#                                                                      #
#  InhaleRead::validateUser                                            #
#                                                                      #
#  [NAMED ARGUMENTS]    username => a string to check             MAN  #
#                                                                      #
#                       password => a string to check             MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Check a user ID/password to make sure they are valid.               #
#                                                                      #
#                                                                      #
#                                                                      #
#                                                                      #
########################################################################

sub validateUser 
{
    my( %args ) = @_;
    unless( defined($args{username}) ) { InhaleCore::error('InhaleRead::validateUser( ) was called without passing a "username" argument', 'bad call'); }
    unless( defined($args{password}) ) { InhaleCore::error('InhaleRead::validateUser( ) was called without passing a "password" argument', 'bad call'); }

    my $account = '';
    if( defined($args{account}) ) { $account = $args{account}; }

    my $autologin = 0;
    if( $args{autologin} ) { $autologin = 1 }

    my $session = '';

    if( $account =~ /^\d\d*$/ )
    {
	$account = " AND account=$account";
    }
    
    if($args{username} && $args{password}) 
    {

### get a valid database handle and create a fresh statement handle...

        my $dbh = $dbh || getDBH( );
        my $sth = '';

### check username & password...

        $sth = $dbh->prepare(  "SELECT user,account FROM users WHERE username = '$args{username}' AND password = '$args{password}' $account"  );
        $sth->execute;

        my @res = $sth->fetchrow_array( );
	my $user    = $res[0] || 0;
	my $account = $res[1] || 0;

### if valid, create a new session...
### non-autologin sessions are deleted automatically by "getNewSessionID"...

	if( $user && $account )
	{
	    use Digest::MD5 qw(md5_hex);
	    my $time = time( );
            $session = md5_hex( $user, $args{username}, $args{password}, $time, rand(999) );

            $sth = $dbh->prepare(  "INSERT INTO sessions (user,account,session,timestamp,autologin,ip) VALUES ($user,$account,'$session',$time,$autologin,'$ENV{REMOTE_ADDR}')"  );
            $sth->execute;
	}

### close the DB statement handle...

        $sth->finish;
        $dbh->disconnect;

    }
    return( $session );
}


sub endSession 
{
    my( %args ) = @_;
    unless( defined($args{session}) ) { $args{session} = '' }

    my $session = $args{session};
    $session =~ s/[^a-zA-Z0-9]//g;
    unless( length( $session ) == 32 ) { return( 0 ) }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';

### remove session...

    $sth = $dbh->prepare(  "DELETE FROM sessions WHERE session='$session' "  );
    $sth->execute;

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return( 1 );
}


sub getUserSession
{
    my( %args ) = @_;
    my $ret = 0;

    if( defined( $args{session} ) ) 
    { 
### get a valid database handle and create a fresh statement handle...

        my $dbh = $dbh || getDBH( );
        my $sth = '';

### get session details...

        $sth = $dbh->prepare(  "SELECT user FROM sessions where session = '$args{session}' "  );
        $sth->execute;

        my @res = $sth->fetchrow_array( );
	$ret = $res[0] || 0;

### close the DB statement handle...

        $sth->finish;
        $dbh->disconnect;
    }
    return( $ret );    
}

sub getAccountDetails 
{
    my(%args)= @_;
    unless(defined($args{user}))    { InhaleCore::error('getAccountDetails( ) was called without passing an "user" argument', 'bad call'); }
    unless(defined($args{session})) { InhaleCore::error('getAccountDetails( ) was called without passing an "session" argument', 'bad call'); }

    my %ret = ( );
    $ret{userNumber}  = $args{user};
    $ret{userSession} = $args{session};

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';
    my @res = ();

### get session information...

    $sth = $dbh->prepare(  "SELECT timestamp,autologin FROM sessions WHERE session='$args{session}' AND user=$args{user}"  );
    $sth->execute;
    @res = $sth->fetchrow_array( );

    $ret{userLoginTime} = $res[0] || 0;
    $ret{userAutoLogin} = $res[1] || 0;

### get user information...

    $sth = $dbh->prepare(  "SELECT account,email,role,username,name FROM users WHERE user=$args{user}"  );
    $sth->execute;
    @res = $sth->fetchrow_array( );

    $ret{userAccountNumber} = $res[0] || 0;
    $ret{userEmail}         = $res[1] || '';
    $ret{userType}          = $res[2] || '';
    $ret{userName}          = $res[3] || '';
    $ret{userRealName}      = $res[4] || '';

### get account information...

    $sth = $dbh->prepare(  "SELECT title,logo,css,contactInfo FROM accounts WHERE account=$ret{userAccountNumber}"  );
    $sth->execute;
    @res = $sth->fetchrow_array( );
	
    $ret{userAccountName} = $res[0] || 0;
    $ret{userAccountLogo} = $res[1] || '';
    $ret{userAccountCSS}  = $res[2] || '';
    $ret{userAccountInfo} = $res[3] || '';

### get parent portfolio information...

    $sth = $dbh->prepare(  "SELECT portfolio,title FROM portfolios WHERE account=$ret{userAccountNumber} AND parent=0"  );
    $sth->execute;
    @res = $sth->fetchrow_array( );
	
    $ret{userAccountParentPortfolio}     = $res[0] || 0;
    $ret{userAccountParentPortfolioName} = $res[1] || '';

### get parent portfolio permissions...

    if( $ret{userType} eq 'superadmin' )
    {
        $sth = $dbh->prepare(  "SELECT portfolio FROM portfolios order by title"  );
        $sth->execute;
	my @list = ( );

	while( @res = $sth->fetchrow_array( ) )
	{
	    push @list, $res[0];
	}

	$ret{userPortfolioList} = ':'.join(':',@list).':';
    }
    elsif( $ret{userType} eq 'admin' )
    {
        $sth = $dbh->prepare(  "SELECT portfolio FROM portfolios WHERE account=$ret{userAccountNumber} order by title"  );
        $sth->execute;
	my @list = ( );

	while( @res = $sth->fetchrow_array( ) )
	{
	    push @list, $res[0];
	}

	$ret{userPortfolioList} = ':'.join(':',@list).':';
    }
    elsif( $ret{userType} eq 'editor' )
    {
        $sth = $dbh->prepare(  "SELECT portfolio FROM portfoliousers WHERE user=$args{user}"  );
        $sth->execute;
	my @list = ( );

	while( @res = $sth->fetchrow_array( ) )
	{
	    push @list, $res[0];
	}

	$ret{userPortfolioList} = ':'.join(':',@list).':';
    }
	
    unless($ret{userAccountNumber}) { InhaleCore::error('unable to locate account details for user'.$args{user}, 'database'); }
    
    return(%ret);
}

sub fetchLinks {
    my(%args)= @_;
    unless(defined($args{unit})) { InhaleCore::error('InhaleRead::getUnit was called without passing a "unit" argument', 'bad call'); }
    unless($args{unit} > 0)      { InhaleCore::error('InhaleRead::getUnit was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }

    my @ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

### 

    $sth = $dbh->prepare(  "SELECT step, rightFrame, url FROM steps WHERE unit = ".$args{unit}  );
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
        $ret[$res[0]] = $res[1].'|'.$res[2];
    }

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return(@ret);
}

sub getNewSessionID
{
    my $id = '';

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';

    use Digest::MD5 qw(md5_hex);
    my $addr = $ENV{REMOTE_ADDR} || '127.0.0.1';
    my $time = time( );
    my $data = $time.$addr.rand(2000);
    $id = "000000".substr(md5_hex($data),0,26);

    my $old = $time - ( 60 * 60 * 24 );

### insert session into lookup table...

    $sth = $dbh->prepare( qq[  INSERT INTO statslookup (sessionNumber,sessionID,time) VALUES (0,"$id",$time)  ] );
    $sth->execute;

### delete old sessions from lookup table...

    $sth = $dbh->prepare( qq[  DELETE FROM statslookup WHERE time < $old  ] );
    $sth->execute;

### delete old editor/admin sessions...

    $sth = $dbh->prepare( qq[  DELETE FROM sessions WHERE timestamp < $old AND autologin=0  ] );
    $sth->execute;

### close the DB statement handle...

    $sth->finish;
    $dbh->disconnect;

    return($id);
}

sub statsQuick
{
    my(%args)= @_;
    unless(defined($args{unit})) { InhaleCore::error('InhaleRead::statsQuick was called without passing a "unit" argument', 'bad call'); }
    unless($args{unit} > 0)      { InhaleCore::error('InhaleRead::statsQuick was called with an invalid "unit" argument ['.$args{unit}.']', 'bad call'); }

    my %ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';
    my @res = ( );

### get stats for unit...

    my %tmp = ( );
    my %ses = ( );
    my %mon = ( );

    $sth = $dbh->prepare( qq[  SELECT time,session,step,total FROM stats WHERE unit=$args{unit} ORDER BY time ] );
    $sth->execute;

    while( @res = $sth->fetchrow_array( ) )
    {

       my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $res[0] );
       $year += 1900;
       $mon++;
	$mon = substr("00$mon",-2);

	my $date = "$year$mon";
	$mon{$date} = 1;
	$tmp{"$date hits"}++;
	$tmp{"$date hits $res[2]"}++;

	unless( $ses{"$date $res[1]"} )
	{
	    $tmp{"$date sessions"}++;
	    $ses{"$date $res[1]"} = 1;
	}

	unless( $ses{"$date $res[1] $res[2]"} )
	{
	    $tmp{"$date $res[2]"}++;
	    $ses{"$date $res[1] $res[2]"} = 1;
	}

	if( $res[3] > $tmp{"$date total"} )
	{
	    $tmp{"$date total"} = $res[3];
	}

    }

    foreach my $m ( sort keys %mon )
    {
	$ret{$m} = qq($tmp{"$m hits"}|$tmp{"$m sessions"}|$tmp{"$m total"});
	foreach my $s ( 1 .. $tmp{"$m total"} )
	{
	    my $u = $tmp{"$m $s"} || 0;
	    my $t = $tmp{"$m hits $s"} || 0;

	    $ret{$m} .= qq(|$u^$t);
	}
    }

    $sth->finish;
    $dbh->disconnect;

    return( %ret );
}

#################################################################
# no args just return list of new and recently updated tutorials#
#################################################################

sub newAndUpdated
{
my @newTutorials = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sthfaqs = ''; 

### get details of new and recently updated units...

    $sthfaqs = $dbh->prepare(  "SELECT unit,title,description,portfolio FROM `units` WHERE visible='y' and last_edited is not null order by last_edited desc limit 10"  );
    $sthfaqs->execute;

    while( my @res = $sthfaqs->fetchrow_array )
    {
       push @newTutorials, $res[0].'^^'.$res[1].'^^'.$res[2].'^^'.$res[3];
    }
    return(@newTutorials);
}

sub getAccountObjects
{
    my(%args)= @_;
    unless(defined($args{account})) { InhaleCore::error('InhaleRead::getAccountObjects( ) was called without passing an "account" argument', 'bad call'); }

    my $acc = $args{account};
    $acc =~ s/\D//g;

    my @ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';

### get account objects...

    if( $acc )
    {
        $sth = $dbh->prepare(  "SELECT object,description,filetype,creationTimeStamp,filename FROM objects WHERE owner=$acc and filetype != 'TXT' "  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
	{
	    push @ret, join( "\t",@res );
	}
    }

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

    return( @ret )
}

sub statsSummary
{
    my(%args)= @_;
    unless(defined($args{folio})) { InhaleCore::error('InhaleRead::statsSummary was called without passing a "folio" argument', 'bad call'); }
    unless(defined($args{month})) { InhaleCore::error('InhaleRead::statsSummary was called without passing a "month" argument', 'bad call'); }
    unless(defined($args{year}))  { InhaleCore::error('InhaleRead::statsSummary was called without passing a "year" argument', 'bad call'); }
    unless(defined($args{subfolios})) { $args{subfolios} = 0 }

    my @ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';
    my @res = ( );

    my $month = $args{month} || 0;
    my $year  = $args{year}  || 0;
    my $folio = $args{folio} || 0;

    if( $month && $year && $folio )
    {
	use Time::Local;

	my $em = $month+1;
	my $ey = $year;
	if( $em == 13 ) { $em = 1; $ey++ }

	my $start = timelocal(0, 0, 0, 1, $month-1, $year-1900);
	my $end   = timelocal(0, 0, 0, 1, $em-1, $ey-1900);
	$end--;

	my @folios = ( );
	push @folios, $folio;
	my %pt = ( );

	$sth = $dbh->prepare(  "SELECT title FROM portfolios WHERE portfolio=$folio "  );
	$sth->execute;
	@res = $sth->fetchrow_array( );
	$pt{$folio} = $res[0] || '';

	if( $args{subfolios} )
	{
	    $sth = $dbh->prepare(  "SELECT portfolio,title FROM portfolios WHERE parent=$folio "  );
	    $sth->execute;
	    while( @res = $sth->fetchrow_array( ) )
	    {
		push @folios, $res[0];
		$pt{$res[0]} = $res[1];
	    }
	}

	my @units = ( );
	my %up    = ( );
	my %ut    = ( );

	foreach my $f ( @folios )
	{
	    $sth = $dbh->prepare(  "SELECT unit,title FROM units WHERE portfolio=$f"  );
	    $sth->execute;
	    while( @res = $sth->fetchrow_array( ) )
	    {
	        push @units, $res[0];
		$up{$res[0]} = $f;
		$ut{$res[0]} = $res[1];
	    }
	}

	my %tmp = ( );
	my %uh  = ( );
	my %uu  = ( );

	foreach my $u ( @units )
	{
	    $sth = $dbh->prepare(  "SELECT session FROM stats WHERE unit=$u AND time >= $start AND time <= $end"  );
	    $sth->execute;
	    while( @res = $sth->fetchrow_array( ) )
	    {
		$uh{$u}++;

		unless( $tmp{"$u $res[0]"} )
		{
		    $tmp{"$u $res[0]"} = 1;
		    $uu{$u}++;
	  	}
	    }
	}

	foreach my $u ( @units )
	{
	    my $users = $uu{$u} || 0;
	    my $hits  = $uh{$u} || 0;

	    my $utitle = $ut{$u} || 'unknown unit title!';
	    $utitle =~ s/\"/\'\'/g;

	    my $ptitle = $pt{$up{$u}} || 'unknown portfolio title!';
	    $ptitle =~ s/\"/\'\'/g;
	    push @ret, qq($u\t$up{$u}\t$users\t$hits\t"$utitle");
	}
    } 

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

    return( @ret );
}

sub getAudit 
{
    my $number = shift || '';
    my $type   = shift || '';
    my @audit  = ();
    
    $number =~ s/\D//gi;
    $type =~ s/\W//gi;

    my $atype = 'O';
    if( $type eq 'unit' ) { $atype = 'U' }

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 

    my $sql = qq( SELECT timeStamp,account,user,ip,eventText FROM audit WHERE type="$atype" AND id="$number" ORDER BY timestamp, event );
    $sth = $dbh->prepare($sql);
    $sth->execute;

    while( my @res = $sth->fetchrow_array )
    {
	push @audit, join( "\t", @res );
    }
   
    $sth->finish;
    $dbh->disconnect;

    return(@audit);
}

sub getQuickUserInfo
{
    my $account = shift || 0;
    my $user    = shift || 0;

    my @ret  = ();
    
### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = ''; 
    my $sql = '';
    my @res = ( );

    $sql = qq( SELECT title FROM accounts WHERE account=$account );
    $sth = $dbh->prepare($sql);
    $sth->execute;
    @res = $sth->fetchrow_array( );
    push @ret, $res[0];
   
    $sql = qq( SELECT name FROM users WHERE user=$user );
    $sth = $dbh->prepare($sql);
    $sth->execute;
    @res = $sth->fetchrow_array( );
    push @ret, $res[0];

    $sth->finish;
    $dbh->disconnect;

    return(@ret);
}

sub getUserInfo
{
    my(%args)= @_;
    unless(defined($args{account})) { InhaleCore::error('InhaleRead::getEditorInfo( ) was called without passing an "account" argument', 'bad call'); }
    unless(defined($args{user}))    { InhaleCore::error('InhaleRead::getEditorInfo( ) was called without passing an "user" argument', 'bad call'); }

    my $acc = $args{account};
    my $type ='';
    if( lc($args{user}) eq 'all' || lc($args{user}) eq 'admin' || lc($args{user}) eq 'editor' ) { $type = lc($args{user}) }

    my $user = $args{user};
    $user =~ s/\D//g;

    my @ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';

### get account objects...

    my $accSQL = '';
    if( $acc =~ /^\d+?$/ ) { $accSQL = " AND u.account=$acc " }

    if( $acc && ( $user || $type ))
    {
	if( $type eq 'all' && $acc =~ /^\d+?$/ )
	{
            $sth = $dbh->prepare(  "SELECT u.user,u.username,u.account,u.email,u.role,u.name,a.title FROM users u, accounts a WHERE u.account=$acc AND u.account=a.account order by a.title"  );
            $sth->execute;
            while( my @res = $sth->fetchrow_array( ) )
	    {
	        push @ret, join( "\t",@res );
	    }
        }
	elsif( $type eq 'all' )
	{
            $sth = $dbh->prepare(  "SELECT u.user,u.username,u.account,u.email,u.role,u.name,a.title FROM users u, accounts a WHERE u.account=a.account order by a.title"  );
            $sth->execute;
            while( my @res = $sth->fetchrow_array( ) )
	    {
	        push @ret, join( "\t",@res );
	    }
        }
	elsif( $type )
	{
            $sth = $dbh->prepare(  "SELECT u.user,u.username,u.account,u.email,u.role,u.name,a.title FROM users u, accounts a WHERE u.role='$type' $accSQL AND u.account=a.account order by a.title"  );
            $sth->execute;
            while( my @res = $sth->fetchrow_array( ) )
	    {
	        push @ret, join( "\t",@res );
	    }
        }
	elsif( $acc && $user )
	{
            $sth = $dbh->prepare(  "SELECT u.user,u.username,u.account,u.email,u.role,u.name,a.title FROM users u, accounts a WHERE u.account=$acc AND u.user=$user AND u.account=a.account"  );
            $sth->execute;
            while( my @res = $sth->fetchrow_array( ) )
	    {
	        push @ret, join( "\t",@res );
	    }
	}
    }

    if( $sth ) { $sth->finish }
    $dbh->disconnect;

    return( @ret )
}

sub getEditorFolios 
{
    my(%args)= @_;
    unless(defined($args{user}))    { InhaleCore::error('InhaleRead::getEditorFolios( ) was called without passing an "user" argument', 'bad call'); }

    my $user = $args{user};
    $user =~ s/\D//g;

    my @ret = ( );

### get a valid database handle and create a fresh statement handle...

    my $dbh = $dbh || getDBH( );
    my $sth = '';

    if( $user )
    {
        $sth = $dbh->prepare(  "SELECT p.portfolio,p.title,p.parent FROM portfolios p, portfoliousers u WHERE u.user=$user AND u.portfolio=p.portfolio"  );
        $sth->execute;
        while( my @res = $sth->fetchrow_array( ) )
        {
            push @ret, join( "\t",@res );
	}
    }
    if( $sth ) { $sth->finish }
    $dbh->disconnect;

    return( @ret )
}


########################################################################
#                                                                      #
#  InhaleRead - private routines                                       #
#                                                                      #
########################################################################
#                                                                      #
#  Various private routines for handling errors and locking files.     #
#                                                                      #
#  Please note that the locking mechanism utilises semaphore files,    #
#  as described by Sean M. Burke in issue 23 of The Perl Journal:      #
#                                                                      #
#      http://www.samag.com/documents/sam1013019385270/                #
#                                                                      #
########################################################################

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

sub expand {
    my($str) = @_;
    $str =~ s/\\r/\r/gi;
    $str =~ s/\\n/\n/gi;
    $str =~ s/\\t/\t/gi;
    return($str);
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
            if( $a eq 'datapath' )          { $dataPath = $b }
            if( $a eq 'uploadpath' )        { $uploadPath = $b }
            if( $a eq 'objectdirpath' )     { $objectDirPath = $b }
            if( $a eq 'objectvirpath' )     { $objectVirPath = $b }

	    if( $a eq 'mysqlport' )         { $mysqlPort = $b }
	    if( $a eq 'mysqlserver' )       { $mysqlServer = $b }
	    if( $a eq 'mysqldatabase' )     { $mysqlDatabase = $b }
	    if( $a eq 'mysqlusername' )     { $mysqlUsername = $b }
	    if( $a eq 'mysqlpassword' )     { $mysqlPassword = $b }

        }
    }
}



1;






