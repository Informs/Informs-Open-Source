package InhaleCore;
use strict;
use locale;

BEGIN {
    my($LIBDIR);
    if ($0 =~ m!(.*[/\\])!) { $LIBDIR = $1; } else { $LIBDIR = './'; }
    unshift @INC, $LIBDIR . 'lib';

    use Exporter ();
    use vars qw( $user $cgi );
    
    @InhaleCore::ISA         = qw( Exporter );
    @InhaleCore::EXPORT      = qw( $cgi $user value error );
    @InhaleCore::EXPORT_OK   = qw( urlencode untaint setupUser setupCGI urldecode timeToRun 
                                   getDate setCookie convertDate convertTags restoreTags );
    %InhaleCore::EXPORT_TAGS = ( );
}

use CGI qw( param cookie );

use Time::HiRes qw( gettimeofday tv_interval );     # so that we can time things

use CGI::Carp qw( fatalsToBrowser );                # uncomment Carp if you need better error messages


# DECLARE SOME GLOBAL VARIABLES - note that some may be overwritten by the "initStuff()" call

    my $paranoid = 0;                               # set to 1 for extra-paranoid sanity checking
  
    my $time1         = 0;
    my $serverName    = $ENV{SERVER_NAME} || '';
    my $pathToCGI     = "http://$serverName/cgi-bin";
    my $pathToData    = './data/';
    my $uploadPath    = './uploads';
    my $objectVirPath = '';
    my $objectDirPath = '';
    my $htmlVirPath   = '';
    my $htmlDirPath   = '';
    my $cachePath     = './data/cache/';
    my $debug2screen  = 0;

    initStuff();

########################################################################
#                                                                      #
#  %InhaleCore::checkCGI                                               #
#                                                                      #
########################################################################
#                                                                      #
#  Contains info about the max valid length, and content type of       #
#  certain CGI parameters.                                             #
#                                                                      #
#  n.b. if "use locale", then alphanumeric will include matches        #
#       outside of the [A-Za-z0-9] range (e.g. é, ç, ä, etc)           #
#                                                                      #
#   ADMIN                                                              #
#       Y = only authenticated users can pass it                       #
#                                                                      #
#   LENGTH                                                             #
#       a length of "0" means any length allowed                       #
#                                                                      #
#   REGEX                                                              #
#       a regex expression to be placed into a /^(regex)$/ match       #
#                                                                      #
#   TYPES                                                              #
#       A = alphanumeric                                               #
#       D = digits only                                                #
#       N = whole number                                               #
#       S = safe characters (e.g. alphanumeric & common punctuation)   #
#       X = anything goes :-D                                          #
#                                                                      #
########################################################################

    my %checkCGI = ( 
                        action => { regex => 'authenticate|checkcookie|confirm|delete|down|edit|global|hide|init|initnoframes\d|insert|jump|logout||move|noframes|none|unhide|up|yes' },
                            id => { len => 32, type => 'A' },
                        idname => { len => 30, type => 'S' },
                         folio => { len => 10, type => 'D' },
                      faqansid => { len => 10, type => 'D' },
                         frame => { len => 10, type => 'A' },
                      keywords => { len => 30, type => 'S' },
                        object => { len => 10, type => 'N' },
                           org => { regex => 'contents|jump' },
                          page => { len =>  3, type => 'D' },
                        reopen => { len => 999, type => 'X' },
                      password => { len => 30, type => 'S' },
                      postdata => { len =>  0, type => 'X' },
                          quiz => { len =>  1, type => 'D' },
                           q_1 => { len => 99, type => 'S' },
                           q_2 => { len => 99, type => 'S' },
                           q_3 => { len => 99, type => 'S' },
                           q_4 => { len => 99, type => 'S' },
                           q_5 => { len => 99, type => 'S' },
                           q_6 => { len => 99, type => 'S' },
                           q_7 => { len => 99, type => 'S' },
                           q_8 => { len => 99, type => 'X' },
                           q_9 => { len => 99, type => 'X' },
                          q_10 => { len => 99, type => 'X' },
                          q_11 => { len => 99, type => 'X' },
                          q_12 => { len => 99, type => 'X' },
                          q_13 => { len => 99, type => 'X' },
                          q_14 => { len => 99, type => 'X' },
                          q_15 => { len => 99, type => 'X' },
                          q_16 => { len => 99, type => 'X' },
                          q_17 => { len => 99, type => 'X' },
                          q_18 => { len => 99, type => 'X' },
                          q_19 => { len => 99, type => 'X' },
                          q_20 => { len => 99, type => 'X' },
                          q_21 => { len => 99, type => 'X' },
                          q_22 => { len => 99, type => 'X' },
                          q_23 => { len => 99, type => 'X' },
                          q_24 => { len => 99, type => 'X' },
                          q_25 => { len => 99, type => 'X' },
                          q_26 => { len => 99, type => 'X' },
                          q_27 => { len => 99, type => 'X' },
                          q_28 => { len => 99, type => 'X' },
                          q_29 => { len => 99, type => 'X' },
                          q_30 => { len => 99, type => 'X' },
                        render => { len => 10, type => 'A' },
                           tip => { len => 10, type => 'D' },
                          unit => { len => 10, type => 'D' },

### and now the "authenticated users" parameters....

                             a => { len => 32, type => 'X', admin => 'Y' },
                             b => { len => 32, type => 'X', admin => 'Y' },
                             c => { len => 32, type => 'X', admin => 'Y' },
                             d => { len => 32, type => 'X', admin => 'Y' },
                      checksum => { len => 32, type => 'A', admin => 'Y' },
                      copyinto => { len => 99, type => 'X', admin => 'Y' },
                       descbox => { len =>  0, type => 'X', admin => 'Y' },
                    descboxchk => { len => 32, type => 'A', admin => 'Y' },
                          from => { len => 10, type => 'D', admin => 'Y' },
                             s => { len => 32, type => 'A', admin => 'Y' },
                     thebutton => { len => 25, type => 'X', admin => 'Y' },
                           toc => { len => 99, type => 'X', admin => 'Y' },
                        txtbox => { len =>  0, type => 'X', admin => 'Y' },
                  searchmonths => { len =>  0, type => 'X', admin => 'Y' },
                     imagesyes => { len =>  0, type => 'X', admin => 'Y' }, 
                         faqid => { len =>  0, type => 'X', admin => '' }, 
                     objectnum => { len =>  0, type => 'X', admin => 'Y' }, 
                        txtmd5 => { len => 32, type => 'A', admin => 'Y' },
                         uopen => { regex => '1|2', admin => 'Y' },
                        upopen => { regex => '1|2', admin => 'Y' },
                           url => { len => 999, type => 'X', admin => 'Y' },
                          text => { len => 999, type => 'X', admin => 'Y' },
                         text1 => { len => 9999, type => 'X', admin => 'Y' },
                         text2 => { len => 9999, type => 'X', admin => 'Y' },
                         text3 => { len => 999, type => 'X', admin => 'Y' },
                         text4 => { len => 999, type => 'X', admin => 'Y' },
                         text5 => { len => 999, type => 'X', admin => 'Y' },
                         text6 => { len => 999, type => 'X', admin => 'Y' },
                         text7 => { len => 999, type => 'X', admin => 'Y' },
                         text8 => { len => 999, type => 'X', admin => 'Y' },
                          list => { len => 999, type => 'L', admin => 'Y' },
                        cssurl => { len => 999, type => 'X', admin => 'Y' },
                        utitle => { len => 99, type => 'X', admin => 'Y' },
                          uvis => { regex => 'Y|N', admin => 'Y' },

                   );
                
#################
#
#  INITIALISE THINGS
#
#  -> pull in server specific info from the "inhale.ini" file
#
########

sub initStuff {

    my $server = lc($ENV{SERVER_SOFTWARE});
    $server =~ s/[^a-z0-9]//gi;

    my $iniFile = '';

    foreach my $path (@INC) {
        if(open(IN,"$path/$server-inhale.ini")) { $iniFile = "$path/$server-inhale.ini"; }
        if(open(IN,"$path/inhale.ini"))         { $iniFile = "$path/inhale.ini"; }
    }

    unless($iniFile) { error("unable to locate INI file [inhale.ini or $server-inhale.ini]", "critical"); }

    open(IN,$iniFile);
    while(my $line = <IN>) {   
        $line =~ s/[\r\n]//gi;
        if($line && $line !~ /^\#/) {
            my($a,$b) = split(/\=/, $line);
            $a =~ s/ //gi;
            $a = lc($a);
   	    $b =~ s/^\s+?//gi;
	    if( $a eq 'servername' )    { $serverName = $b; }
	    if( $a eq 'pathtocgi' )     { $pathToCGI = $b; }
	    if( $a eq 'datapath' )      { $pathToData = $b; }
	    if( $a eq 'uploadpath' )    { $uploadPath = $b; }
            if( $a eq 'objectvirpath' ) { $objectVirPath = $b }
            if( $a eq 'objectdirpath' ) { $objectDirPath = $b }
            if( $a eq 'htmlvirpath' )   { $htmlVirPath = $b }
            if( $a eq 'htmldirpath' )   { $htmlDirPath = $b }

	    if($a eq 'cachepath')       { $cachePath = $b; }

        }
    }
}

########################################################################
#                                                                      #
#  InhaleCore::value                                                   #
#                                                                      #
#  [ARGUMENTS]    1. a $cgi or $user OObject                      MAN  #
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

    return($ret);    
}

########################################################################
#                                                                      #
#  InhaleCore::new                                                     #
#                                                                      #
########################################################################
#                                                                      #
#  Initiates the environment for INHALE scripts by creating $cgi and   #
#  $user objects that containt info about the CGI parameters and the   #
#  user making the request.                                            #
#                                                                      #
#  The $user object contains information about the user who is         #
#  invoking the script - e.g. type of web browser, unique tracking     #
#  ID, account details (if they've logged in), etc.                    #
#                                                                      #
#  The $cgi object contains a carefully filtered version of the CGI    #
#  parameters that were passed to the script.  The %checkCGI hash      #
#  is used to try and ensure that only valid parameter key names and   #
#  values are being passed.  A suitable HTTP header is also dropped    #
#  into the $cgi->{header} entry.                                      #
#                                                                      #
########################################################################

sub new {
    shift @_;
    my $args = shift || '';


    use HTTP::BrowserDetect;
    my $cgiHandle = new CGI;

    $time1 = [gettimeofday];

    $cgi = {};
    $user = {};
    bless($cgi);
    bless($user);
    $cgi->{'header'} .= "Content-Type: text/html\n\n";
    $user->{userNumber}        = 0;
    $user->{userType}          = 'user';
    $user->{userPortfolioList} = '';


    my $cookie = $cgiHandle->cookie('informs') || '';
    $cookie =~ s/[^a-zA-Z0-9]//g;

    if( length( $cookie ) == 32 ) 
    {
        require "InhaleRead.pm";

	my $userNumber = InhaleRead::getUserSession( session => $cookie );
	$user->{userNumber} = $userNumber;

	if( $userNumber )
	{
	    my %temp = InhaleRead::getAccountDetails( user => $userNumber, session => $cookie );

	    foreach my $key ( keys %temp )
	    {
		$user->{$key} = $temp{$key};
	    }
        }
    }

#
#  Build up an entry in $user->{browser} that contains a shorthand version
#  of the web browser being used.
#
#  Requires Lee Semel's HTTP::BrowserDetect module from http://www.cpan.org
#  although it would be fairly easy to recode to use something else...
#
    $user->{userIP}        = $ENV{REMOTE_ADDR};
    $user->{showTips}      = 'icon';    
    $user->{serverName}    = $serverName;
    $user->{pathToCGI}     = $pathToCGI;
    $user->{pathToData}    = $pathToData;
    $user->{pathToUploads} = $uploadPath;
    $user->{pathObjectVir} = $objectVirPath;
    $user->{pathObjectDir} = $objectDirPath;
    $user->{pathHtmlVir}   = $htmlVirPath;
    $user->{pathHtmlDir}   = $htmlDirPath;
    $user->{pathToCache}   = $cachePath;

    if(open(IN, $pathToData.'offline.txt') && $user->{userNumber} != 1) {
        my $message = '';
        while(<IN>) { $message .= $_; }
        close(IN);
	siteOffline($message);    
	exit;    
    }

    my $prefix = '';
    my $browser = new HTTP::BrowserDetect($ENV{HTTP_USER_AGENT});

    if($browser->ie)          { $prefix = 'IE'; }
    elsif($browser->gecko)    { $prefix = 'GECKO'; }
    elsif($browser->netscape) { $prefix = 'NETSCAPE'; }
    elsif($browser->opera)    { $prefix = 'OPERA'; }

    if($prefix) {
        if($browser->version() < 4)   { $user->{browser} = $prefix.'3'; }
	elsif($browser->major(4))     { $user->{browser} = $prefix.'4'; }
	elsif($browser->major(5))     { $user->{browser} = $prefix.'5'; }
	elsif($browser->major(6))     { $user->{browser} = $prefix.'6'; }
	elsif($browser->major(7))     { $user->{browser} = $prefix.'7'; }
	else                          { $user->{browser} = $prefix.'X'; }
    }
    elsif($browser->lynx) { $user->{browser} = 'LYNX'; }
    else { $user->{browser} = 'UNKNOWN'; }

    foreach my $param ($cgiHandle->param) 
    {
        my $key = lc($param);
	my @val = $cgiHandle->param($key);
	my $val = '';

	if( scalar(@val) == 1 ) { $val = $val[0] }

	my $len = length($val);
	$key =~ s/\W//g;

	if($key eq 'amp') { next; }                  # skip for clients who don't know the difference between "&" and "&amp;"

        if($args eq 'safeCGI') { 
 	    $cgi->{$key} = $val;
	    next;
	}

	unless(defined($checkCGI{$key})) { error("unknown param $key", 'bad parameter'); }

	if(defined($checkCGI{$key}{admin}) && !$user->{userNumber}) { error('you are not currently logged in as a valid user', 'not logged in'); }
	
 	unless($user->{userNumber}) {
 	    if($val =~ /(\<|\>|&gt;|&lt;)/) { 
 	        if($paranoid) { error('invalid value passed to script', 'bad parameter'); }
 	    }
 	}	

	if($checkCGI{$key}{regex}) {
	    my $regex = $checkCGI{$key}{regex};
	    if($val !~ /^($regex)$/) { error("parameter $key failed to match an allowed value", 'bad parameter'); }
	}

	unless($paranoid) {
	    if(defined($checkCGI{$key}{type})) {
	        if($checkCGI{$key}{type} eq 'N')            { $val =~ s/[^\-0-9]//gi; }
   	        if($checkCGI{$key}{type} eq 'D')            { $val =~ s/\D//gi; }
	        if($checkCGI{$key}{type} eq 'A')            { $val =~ s/\W//gi; }
	        if($checkCGI{$key}{type} eq 'L')            { $val = join( "\t", @val ); }
	        if($checkCGI{$key}{type} eq 'S')            { $val =~ s/[^\w\@\-\_\!\"\'\,\.\(\)\:\;\\\/\[\]\&\{\}\£\$\*\? ]//gi; }
	    }
	    if(defined($checkCGI{$key}{len})) {
	        if($checkCGI{$key}{len} && length($val) > $checkCGI{$key}{len}) { 
                    $val = substr($val, 0, $checkCGI{$key}{len}); 
                }
            }
	    
	    if($key eq 'folio' && !$val)                { $val = 1; }
  	    elsif($key eq 'unit' && !$val)              { $val = 1; }
	    elsif($key eq 'page' && !$val)              { $val = 1; }
	    elsif($key eq 'render' && !$val)            { $val = 'inhale'; }
	    elsif($key eq 'frame' && !$val)             { $val = 'left'; }
	    elsif($key eq 'id') {
	        if($val !~ /^[a-f0-9A-F]+?$/) { $val = generateID(); } 
	        if(length($val) != 32)        { $val = generateID(); }
	    }
	}
	else {
	    if($checkCGI{$key}{type} eq 'N' && $val !~ /-*\d+?/) { error("[$key] - parameter is not numeric", 'bad parameter'); }
	    if($checkCGI{$key}{type} eq 'D' && $val =~ /\D/)     { error("[$key] - parameter is not numeric", 'bad parameter'); }
	    if($checkCGI{$key}{type} eq 'A' && $val =~ /\W/)     { error("[$key] - parameter is not alphanumeric", 'bad parameter'); }
	    if($checkCGI{$key}{type} eq 'S') {
	        if($val =~ /[^\w\@\-\_\!\"\'\,\.\(\)\:\;\\\/\[\]\&\{\}\£\$\*\? ]/) { 
	            error("[$key] - parameter contains invalid characters");
	        }
	    }
	    if($checkCGI{$key}{len} && length($val) > $checkCGI{$key}{len}) {
	        error("[$key] - parameter is too long", 'bad parameter'); 
	    }
	}


	if($val =~ /[\`\|]/) {  $val =~ s/\`/\'/gi; $val =~ s/\|/\¦/gi; }
	$cgi->{$key} = $val;
    }

    if( defined( $cgiHandle->param('id') ) ) 
    { 
        $user->{userID} = $cgiHandle->param('id') 
    }
    else
    {
	if( defined( $cgiHandle->cookie("tempid") ) )
	{
            $user->{userID} = $cgiHandle->cookie("tempid");
	}
	else
	{
            $user->{userID} = generateID();
	}
    }

    return($user->{userNumber});
}

#################
#
#  THE END
#
#  -> reclaim a little bit of memory by destroying the global variables
#
########

sub end {
    $cgi = '';
    $user = '';
}

#################
#
#  TWO COOKIE HANDLING ROUTINES
#
#  -> based on code written by kovacsp@egr.uri.edu 
#     (see http://www.egr.uri.edu/~kovacsp/cookie-lib/)
#
#  -> cookie values to be set are added to the next HTTP header
#     (i.e. $cgi{header})
#
########

sub readCookie {
    my($find) = @_;
    my($chip, $val);
    my $ret = '';
    if(defined($ENV{'HTTP_COOKIE'})) {
        foreach (split(/; /, $ENV{'HTTP_COOKIE'})) {
            s/\+/ /g;
            ($chip, $val) = split(/=/,$_,2); # splits on the first =.
            $chip =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
            $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;

            if($chip eq $find) { $ret = $val; }
        }
        return($ret);
    }
}

sub setCookie {

    my( $name, $value, $perm ) = @_;
    
    my $domain = $serverName;
    my $path = '/';
    my $ret = '';
    my $expires = '';

    if( $perm ) 
    { 
        my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );
        $year += 1901;
	$expires = "; expires=Mon, 01-Mar-$year 12:00:00 GMT"; 
    }
    unless($value) { $expires = '; expires=Mon, 25-Mar-1970 10:56:57 GMT'; }

    $ret .= "Set-Cookie: $name\=$value; path\=$path".$expires."\n";
    return($ret);
}
    
    
sub error 
{
    my $error = shift || 'an unknown error has occurred';
    my $type  = shift || 'general';
    my %args  = @_;

    my $time = time();
    my $localtime = '('.localtime($time).')';
    my $html = '';
    my $email = '';
    
    open(IN, $pathToData."templates/error.html");
    while(<IN>) { $html .= $_; }
    close(IN);

    my $extra = '';
    
    if($type eq 'not logged in') { $extra = qq(The error message was generated because you have tried to access a restricted page without providing the correct credintials.&nbsp; If you have a valid account on this web site, then please use the <a href="/perl/login2.pl">log in page</a> before attempting to access the requested page again.); }
    if($type eq 'bad parameter') { $extra = qq(The error message was generated because an incorrect or invalid parameter was passed to the server as part of your page request.&nbsp; One likely cause of this error is that the previous page you were viewing contained an invalid or incorrect link.); }
    if($type eq 'critical')      { $extra = qq(The error message was generated because the server is currently unable to handle certain valid requests - please accept our apologies as we look into the matter.); }
    if($type eq 'bad call')      { $extra = qq(The error message was generated because of bad internal function call - please accept our apologies whilst we look into the matter.); }
    if($type eq 'database')      { $extra = qq(The error message was generated because the database returned an error message - please accept our apologies whilst we look into the matter.); }
    if($type eq 'lock failure')  { $extra = qq(The error message was generated because the script was unable to gain safe access to the database, or was unable to gain a secure lock on one of the database files.<p />Please try reloading the page again to see if the error message persists.); }

    $html =~ s/\{\{error message\}\}/$error/gi;
    $html =~ s/\{\{error number\}\}/$time/gi;
    $html =~ s/\{\{extra info\}\}/$extra/gi;

    print qq(Content-type: text/html\n\n);
    print $html;

    $email .= qq(

ERROR  : $error
type   : $type
time   : $time $localtime

);


    $email .= qq(\n
PASSED HASH CONTAINS:
=====================\n);

    foreach (sort keys %args) {
        $email .= "    $_ = $args{$_}\n";
    }


    $email .= qq(\n
USER HASH CONTAINS:
===================\n);

    foreach (sort keys %$user) {
        $email .= "    $_ = $user->{$_}\n";
    }

    $email .= qq(\n
CGI.pm RECKONS THESE ARE THE ORIGINAL CGI PARAMETERS:
=====================================================\n);

    my $cgiHandle = new CGI;
    foreach my $param ($cgiHandle->param) {
	my $key = convertTags(lc($param));
	my $val = convertTags($cgiHandle->param($param));
        $email .= "    $key = $val\n";
    }

    $email .= qq(\n
CGI HASH CONTAINS:
==================\n);

    foreach (sort keys %$cgi) {
        $email .= "    $_ = $cgi->{$_}\n";
    }

    $email .= qq(\n
ENV HASH CONTAINS:
==================\n);

    foreach (sort keys %ENV) {
        $email .= "    $_ = $ENV{$_}\n";
    }

    $email .= qq(\n
PERL CALLER SAYS:
=================);

    foreach (0 .. 20) {
        my @caller = caller($_);
        if(@caller) {
            $email .= qq(\n\ndebug$_: );
            my $sp = '';
            foreach my $loop (0 .. 4) { 
                if($caller[$loop] =~ /[\\\/]/) {
                    my @x = split(/[\\\/]/, $caller[$loop]);
                    $caller[$loop] = $x[-1];
                }                        
                $email .= $sp.(' package', 'filename', ' line no', '    subr', 'has args')[$loop]." = $caller[$loop]\n";
                $sp = '        ';
            }
        }
    }
    
    use Mail::Sender;
    my $sender = new Mail::Sender { smtp => '', from => '' };

    if ($sender->MailMsg({ smtp => '',
		           from => '',
		             to =>'',
		        subject => 'error message '.$time.' ['.$error.']',
		            msg => $email
    }) < 0) {  }
    else {  }

    if( $debug2screen )
    {
	print qq(<pre>\n\n$email</pre>);
    }
    exit;

}


########################################################################
#                                                                      #
#  InhaleCore::generateID                                              #
#                                                                      #
########################################################################
#                                                                      #
#  Generates a unique ID so that we can track the usage of units.      #
#                                                                      #
#  The ID is a more-or-less random MD5 hex hash.                       #
#                                                                      #
#  The ID is passed from script to script using the "id" parameter.    #
#                                                                      #
#  If the routine generates a new ID, then it will try to send it      #
#  to the web browser as a per-session cookie by adding it the next    #
#  HTTP header (using the $cgi->{header} entry).                       #
#                                                                      #
########################################################################

sub generateID 
{ 
    require "InhaleRead.pm";

    my $id = InhaleRead::getNewSessionID( );

    if(defined($cgi->{'header'})) 
    {
        $cgi->{'header'} = setCookie('tempid', $id) . $cgi->{'header'};
    }
    else 
    {
        $cgi->{'header'} = setCookie('tempid', $id);  	
    }
    
    return($id);
    
}

########################################################################
#                                                                      #
#  InhaleCore::untaint                                                 #
#                                                                      #
########################################################################
#                                                                      #
#  General purpose untainting routine.                                 #
#                                                                      #
#  Takes up to two arguments:                                          #
#                                                                      #
#      1) the string to untaint                                        #
#                                                                      #
#      2) an optional numeric value to specificy what to untaint       #
#                                                                      #
########################################################################

sub untaint {
    my($str) = shift;
    my($die) = shift;

    if($die) {
        $str =~ /^(.+)$/;
        $str = $1;

        if($die eq '1') {
            $str =~ s/\`/\'/g;			# replace backticks with single quotes
            $str =~ s/[\\\|\/\`]//g;		# remove the *really* naughty characters
        }
        if($die eq '2') {
            $str =~ s/[\\\|\/\.\`\,\-\¬]//g;	# remove all the naughty characters
        }
        elsif($die eq '3') {
            $str =~ s/\W//gi;			# remove all non alpha-numeric chars
        }
        elsif($die eq '4') {
            $str =~ s/[\`\*\|\?\<\>\"]//gi;	# remove things that shouldn't appear in a dir path
        }
	else {
	    die "unknown option passed to untaint method";
	}
    }    
    else {
        unless ($str =~ m#^([\w.-]+)$#) { error('tainted characters found in the incoming data', 'bad parameter'); }
        $str = $1;				# safe
    }
    return($str);
}

sub timeToRun {
    return(tv_interval ( $time1, [gettimeofday]));
}


sub siteOffline {
    print "Content-type: text/html\n\n";
    print qq(<html><head><title>Informs Web Site</title></head>\n);
    print qq(<body><h1>503 Service Unavailable</h1>\n);
    print @_;
    print qq(</body></html>\n);
    exit;
}


#################
#
#  QUICK TIDY
#
#  -> quick and dirty routine to tidy up strings to make them
#     a bit more presentable as "quotes" in HTML or tip box text
#
########

sub niceQuotes {
    my($str) = @_;
    if($str) {
        $str =~ s/\"/\'\'/g;
        $str =~ s/\&/\&amp\;/g;
        $str =~ s/\<.+?\>//g;
        $str =~ s/&amp;quot;/&quot\;/g;
    }
    return($str);
}


#################
#
#  FOUR CONVERSION ROUTINES
#
#  -> bog standard routines to do quick URL en/decoding and
#     HTML entity conversions
#     
########

sub urlencode {
    my($str) = @_;
    $str =&escape($str, '[\x00-\x20"#%&=/+:;.\'<>?\x7F-\xFF]');
    $str =~ s/ /\+/g;
    return($str);
}
sub escape {
    my($str, $pat)=@_;
    $str =~ s/($pat)/sprintf("%%%02lx", unpack('C', $1))/ge;
    return($str);
}
sub urldecode {
    my($str) = @_;
    $str =~ s/%([A-Fa-f0-9]{2})/pack("c", hex($1))/ge;
    return($str);
}

sub convertTags {
    my($str) = @_;
    $str =~ s/\&/\&amp\;/g;
    $str =~ s/\</\&lt\;/g;
    $str =~ s/\>/\&gt\;/g;
    $str =~ s/\"/\&quot\;/g;
    return($str);
}

sub restoreTags {
    my($str) = @_;
    $str =~ s/\&lt\;/\</g;
    $str =~ s/\&gt\;/\>/g;
    $str =~ s/\&quot\;/\"/g;
    $str =~ s/\&amp\;/\&/g;
    return($str);
}


########################################################################
#                                                                      #
#  InhaleCore::convertDate                                             #
#                                                                      #
########################################################################
#                                                                      #
#  Returns a date/time string in various human readable formats.       #
#                                                                      #
#  Takes up to two named arguments:                                    #
#                                                                      #
#      1) time                                                         #
#         a time in epoch seconds to convert                           #
#                                                                      #
#      2) format (optional)                                            #
#         the format to convert to - defaults to 'dd/mm/yyyy'          #
#                                                                      #
########################################################################

sub convertDate {
    my(%args)= @_;
    unless(defined($args{time})) { error('InhaleCore::convertDate was called without passing an "time" argument', 'bad call'); }

    my $time = $args{time};
    my $format = lc($args{format}) || 'dd/mm/yyyy';

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $year += 1900;
    $mon++;
    my $ret = '';
    
    if($format eq 'dd/mon/yyyy') { 
        $ret = substr("00".$mday, -2) ."/". substr("JanFebMarAprMayJunJulAugSepOctNovDec", ($mon-1) * 3, 3) ."/". $year; 
    }
    elsif($format eq 'dd/mm/yy') { 
        $ret = substr("00".$mday, -2) ."/". substr("00".$mon, -2) ."/". substr($year, -2); 
    }
    elsif($format eq 'hh:mm:ss') {
        $ret = substr("00".$hour, -2).':'.substr("00".$min, -2).':'.substr("00".$sec, -2);
    }
    elsif($format eq 'hh:mm am/pm') {
        my $ext = 'am';
        if($hour == 0) { $hour = 12; }
        elsif($hour == 12) { $ext = 'pm'; }
        elsif($hour > 12) { $ext = 'pm'; $hour -= 12; }

        $ret = $hour.':'.substr("00".$min, -2).$ext;
    }
    elsif($format eq 'yyyy-mm-dd') {
        $ret = $year.'-'.substr("00".$mon, -2) ."-". substr("00".$mday, -2); 
    }
    else { 
        $ret = substr("00".$mday, -2) ."/". substr("00".$mon, -2) ."/". $year; 
    }


    return($ret);
}


########################################################################
#                                                                      #
#  InhaleCore::getDate                                                 #
#                                                                      #
########################################################################
#                                                                      #
#  Returns the current date/time in various human readable formats.    #
#                                                                      #
#  Takes one optional named argument:                                  #
#                                                                      #
#      1) format (optional)                                            #
#         the format to convert to - defaults to 'dd/mm/yyyy'          #
#                                                                      #
########################################################################

sub getDate {
    my(%args)= @_;
    my $format = $args{format} || 'dd/mm/yyyy';
    return(convertDate( time => time(), format => $format ));
}


#################
#
#  ANOTHER QUICK TIDY
#
#  -> remove unwanted whitespace from a string
#
########

sub tidy {
    my($str) = @_;
    while($str =~ /^\s/s) { $str =~ s/^\s*//gis; }
    while($str =~ /\s$/s) { $str =~ s/\s*$//gis; }
    return($str);
}



END { }

1;





