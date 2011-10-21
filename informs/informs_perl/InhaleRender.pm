package InhaleRender;
use strict;

BEGIN {
    my($LIBDIR);
    if ($0 =~ m!(.*[/\\])!) { $LIBDIR = $1; } else { $LIBDIR = './'; }
    unshift @INC, $LIBDIR . 'lib';

    use Exporter();

    @InhaleRender::ISA = qw(Exporter);

    @InhaleRender::EXPORT = qw( );

    @InhaleRender::EXPORT_OK = qw( inhaleRender inhaleRenderText generateStylesheet convertTags
                                   @accessibleTextColour @accessibleBackgroundColour
                                   @accessibleLinkColour @accessibleFontSize @accessibleFontType
                                   getPageCache addPageCache clearCache );

    %InhaleRender::EXPORT_TAGS = (

              render => [ qw( generateStylesheet inhaleRender inhaleRenderText convertTags getPageCache addPageCache ) ],

        colourscheme => [ qw( generateStylesheet 
                              @accessibleTextColour @accessibleBackgroundColour
                              @accessibleLinkColour @accessibleFontSize
                              @accessibleFontType ) ]
    );

}

use vars qw( @accessibleTextColour @accessibleBackgroundColour @accessibleLinkColour
              @accessibleFontSize @accessibleFontType );

sub init_colours {
    @accessibleTextColour       = ( '#000000', '#FFFFFF', '#FFFF00', '#000066', '#000000', '#000000', '#00FFFF', '#FFFFFF', '#000000', '#000000');
    @accessibleBackgroundColour = ( '#FFFFFF', '#000000', '#000066', '#FFFFCC', '#CCFF66', '#DEFAE3', '#000000', '#000099', '#FFCCFF', '#FFCC99');
    @accessibleLinkColour       = ( '#FF0000', '#0000FF', '#00FFFF', '#00FF00', '#FFFF00' , '#FF00FF', '#990000', '#000099', '#009900' );
    @accessibleFontSize         = ( 'xx-small', 'x-small', 'small', 'medium', 'large', 'x-large', 'xx-large' );
    @accessibleFontType         = ( 'Arial', 'Verdana', 'Times', 'Courier New, Courier', 'Helvetica', 'Geneva', 'Garamond', 'Comic Sans MS', 'Georgia', 'Sans-Serif' );
}

### DECLARE SOME GLOBAL VARIABLES

    my %pageCache       = ( );
    my %pageCacheTime   = ( );
    my $maxPageCache    = 100;
    my $purgeCache      = 10;
    my $purgeCacheCount = 0;
    my $cacheMinutes    = 5;

    my $objectVirPath = '';
    my $objectDirPath = '';
    my $htmlVirPath   = '';
    my $htmlDirPath   = '';
    my $cachePath     = '';
  
    initStuff();


########################################################################
#                                                                      #
#  InhaleRender::getPageCache                                          #
#                                                                      #
#  [ARGUMENTS]    1. file name                                         #
#                                                                      #
########################################################################
#                                                                      #
#  Fetch the requested file from the cache (it it exists).             #
#                                                                      #
#  The file contents will also be added to the memory cache.           #
#                                                                      #
#  Stale files will also be removed from the memory cache.             #
#                                                                      #
########################################################################

    sub getPageCache
    {
        my $page = shift || ''; 
	my $ret  = '';

	if( $page )
	{
	    my $t = time( );

	    foreach my $k ( keys %pageCache )
	    {
		if( $pageCacheTime{$k} + ($cacheMinutes*60) < $t ) 
		{ 
		    delete $pageCacheTime{ $k };
		    delete $pageCache{ $k };
		}
	    }

	    my $size = keys %pageCache;

	    if( $pageCache{ $page } )
	    {
		$ret = $pageCache{ $page };
	    }
	    else
	    {
	        my $temp = "$cachePath$page.txt";
	        $temp =~ /^(.*)$/;
	        my $cacheFile = $1;
	        if( open( IN, $cacheFile ) )
	        {
		    while( <IN> ) { $ret .= $_ }
		    close( IN );
		    $pageCache{$page} = $ret;
		    $pageCacheTime{$page} = $t;
		}
	    }

	}
	return( $ret );
    }


########################################################################
#                                                                      #
#  InhaleRender::addPageCache                                          #
#                                                                      #
#  [ARGUMENTS]    1. file name                                         #
#                 2. text                                              #
#                                                                      #
########################################################################
#                                                                      #
#  Add a page to the disk cache.                                       #
#                                                                      #
########################################################################

    sub addPageCache
    {
        my $page = shift || '';
	my $text = shift || '';

	my $temp = "$cachePath$page.txt";
	$temp =~ /^(.*)$/;
	my $cacheFile = $1;

	open( OUT, ">$cacheFile" );
	print OUT $$text;
	close( OUT );

    }


########################################################################
#                                                                      #
#  InhaleRender::clearCache                                            #
#                                                                      #
#  [ARGUMENTS]    1. unit number                                       #
#                 2. page number                                       #
#                                                                      #
########################################################################
#                                                                      #
#  Remove files from the cache.                                        #
#                                                                      #
#  If called without any arguments, all pages are removed.             #
#                                                                      #
#  If called with a unit number, all cached pages for that unit        #
#  are removed.                                                        #
#                                                                      #
#  If called with a unit & page number, all cached versions of         #
#  that page are removed.                                              #
#                                                                      #
########################################################################

    sub clearCache
    {
        my $unit = shift || '';
	my $page = shift || '';

	$unit =~ s/\D//g;
	$page =~ s/\D//g;

	opendir( DIR, $cachePath );
	my @files = readdir( DIR );
	closedir( DIR );

	unless( $unit )
	{
	    foreach my $file ( @files )
	    {
		$file =~ /^(.*)$/;
		$file = $1;
		if( $file =~ /txt$/ ) { unlink(untaintPath("$cachePath$file")) }
	    }
	    foreach my $k ( keys %pageCache )
	    {
	        delete $pageCacheTime{ $k };
		delete $pageCache{ $k };
	    }
	}
	elsif( $unit > 0 && $page > 0 )
	{
	    foreach my $file ( @files )
	    {
		$file =~ /^(.*)$/;
		$file = $1;
		if( $file =~ /^\d+?\_$unit\_$page\_/ ) { unlink(untaintPath("$cachePath$file")) }
	    }
	    foreach my $k ( keys %pageCache )
	    {
		if( $k =~ /^\d+?\_$unit\_$page\_/ ) 
		{ 
		    delete $pageCacheTime{ $k };
		    delete $pageCache{ $k };
		}
	    }
	}	
	elsif( $unit > 0 )
	{
	    foreach my $file ( @files )
	    {
		$file =~ /^(.*)$/;
		$file = $1;
		if( $file =~ /^\d+?\_$unit\_/ ) { unlink(untaintPath("$cachePath$file")) }
	    }
	    foreach my $k ( keys %pageCache )
	    {
		if( $k =~ /^\d+?\_$unit\_/ ) 
		{ 
		    delete $pageCacheTime{ $k };
		    delete $pageCache{ $k };
		}
	    }
	}	
    }


########################################################################
#                                                                      #
#  InhaleRender::convertTags                                           #
#                                                                      #
#  [ARGUMENTS]    1. a string to convert                          MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  I used to use HTML::Entities, but this seemed to clash with         #
#  allowing the database to be store objects in foreign languages.     #
#  I need to do a bit more testing with foreign language materials     #
#  to see which is the best route to take.                             #
#                                                                      #
#  Basically the function returns a string with the basic HTML         #
#  entities converted to their entity names.                           #
#                                                                      #
########################################################################

    sub convertTags 
    {
        my $str  = shift || ''; 
        if($str) {
    
            $str =~ s/\&/\&amp\;/g;
            $str =~ s/\</\&lt\;/g;
            $str =~ s/\>/\&gt\;/g;
            $str =~ s/\"/\&quot\;/g;
        }
        return($str);
    }

########################################################################
#                                                                      #
#  InhaleRender::restoreTags                                           #
#                                                                      #
#  [ARGUMENTS]    1. a string to convert                          MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  I need to do a bit more testing with foreign language materials     #
#  to see which is the best route to take for storing Unicode and      #
#  high ASCII stuff in the database.                                   #
#                                                                      #
#  Basically the function returns a string with the basic HTML         #
#  entities converted from their entity names.                         #
#                                                                      #
########################################################################

    sub restoreTags {
        my $str  = shift || '';
        if($str) {
    
            $str =~ s/\&lt\;/\</g;
            $str =~ s/\&gt\;/\>/g;
            $str =~ s/\&quot\;/\"/g;
            $str =~ s/\&amp\;/\&/g;
        }
        return($str);
    }

    sub generateStylesheet {
        my $str  = shift;
        my $type = shift || '';
	my $pf   = shift || '';
	my $curl = shift || '';
    
        my $ret = '';
    
        $str =~ s/\D//gi;
	if( $curl )
	{
            $ret = qq(<link rel="stylesheet" href="$curl" type="text/css" />);
	}
        elsif(length($str) != 4 && $type ne 'standalone') {
            $ret = '<link rel="stylesheet" href="'.$htmlVirPath.'inhale.css" type="text/css" />';
        }
        else {
    
            init_colours();
    
            my $textColour = $accessibleTextColour[substr($str, 0 , 1)]       || $accessibleTextColour[0];
            my $backColour = $accessibleBackgroundColour[substr($str, 0 , 1)] || $accessibleBackgroundColour[0];
            my $linkColour = $accessibleLinkColour[substr($str, 1 , 1)]       || $accessibleLinkColour[0];
            my $fontSize   = $accessibleFontSize[substr($str, 2 , 1)]         || $accessibleFontSize[3];
            my $fontType   = $accessibleFontType[substr($str, 5 , 1)]         || $accessibleFontType[0];
            my $linkVisited = $linkColour;
            $linkVisited =~ s/FF/FF/gi;;
    
            if($type ne 'standalone') { $ret .= qq(<style type="text/css">\n); }
    
            $ret .= qq(
body, td { color: $textColour; background: $backColour; font-size: $fontSize; font-family: $fontType; }
h3,h1 { font-weight: bold; font-size: 150%; align:center; }
a { color: $linkColour; text-decoration: underline; font-weight: bold; }
a:visited { color: $linkVisited; text-decoration: underline; font-weight: bold; }
a:hover { background-color: $linkColour; color:$backColour; text-decoration: underline; font-weight: bold; }
.userinput { align:center; border:solid $textColour 1px; width:95%; padding: 5px; }
.sideguide { padding: 5px; }
.content { padding: 10px; }
.heading { text-align: center; font-weight:bold; font-size: 110%; }
.action { font-weight:bold; }
.safe { border: $textColour solid 3px; }
.article { position: absolute; visibility: hidden; }
);
    
            if($type ne 'standalone') { $ret .= qq(</style>\n); }
    
            $ret .= qq(<!-- $str -->\n);
        }
        return($ret);
    }


########################################################################
#                                                                      #
#  InhaleRender::returnMIME                                            #
#                                                                      #
#  [NAMED ARGUMENTS]    type => a file type extension             MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  Returns a string containing a value that can be included in a       #
#  HTTP header as the content-type, followed by a boolean value        #
#  that indicates whether or not the file type can be easily           #
#  embedded into HTML.                                                 #
#                                                                      #
#  If the function doesn't know anything about the file type, then     #
#  an empty string will be returned.                                   #
#                                                                      #
########################################################################

    sub returnMIME {
        my(%args)= @_;
        unless(defined($args{type})) { $args{type} = ''; }    
        $args{type} = lc($args{type});
        my $ret = 'application/unknown';
        my $embed = 0;
        
        if   ($args{type} eq 'txt') { $ret = 'text/plain'; }
        elsif($args{type} eq 'htm') { $ret = 'text/html'; }
        elsif($args{type} eq 'css') { $ret = 'text/css'; }
        elsif($args{type} eq 'gif') { $ret = 'image/gif';  $embed = 1; }
        elsif($args{type} eq 'jpg') { $ret = 'image/jpeg'; $embed = 1; }
        elsif($args{type} eq 'jpe') { $ret = 'image/jpeg'; $embed = 1; }
        elsif($args{type} eq 'png') { $ret = 'image/png';  $embed = 1; }
        elsif($args{type} eq 'tif') { $ret = 'image/tiff'; $embed = 1; }
        elsif($args{type} eq 'bmp') { $ret = 'image/bmp';  $embed = 1; }
        elsif($args{type} eq 'rtf') { $ret = 'application/rtf'; }
        elsif($args{type} eq 'pdf') { $ret = 'application/pdf'; }
        elsif($args{type} eq 'doc') { $ret = 'application/msword'; }
        elsif($args{type} eq 'js')  { $ret = 'application/x-javascript'; }
        elsif($args{type} eq 'pib') { $ret = 'application/x-mspublisher'; }
        elsif($args{type} eq 'pps') { $ret = 'application/vnd.ms-powerpoint'; }
        elsif($args{type} eq 'ppt') { $ret = 'application/vnd.ms-powerpoint'; }
        elsif($args{type} eq 'xla') { $ret = 'application/vnd.ms-excel'; }
        elsif($args{type} eq 'xlc') { $ret = 'application/vnd.ms-excel'; }
        elsif($args{type} eq 'xlm') { $ret = 'application/vnd.ms-excel'; }
        elsif($args{type} eq 'xls') { $ret = 'application/vnd.ms-excel'; }
        elsif($args{type} eq 'xlt') { $ret = 'application/vnd.ms-excel'; }
        elsif($args{type} eq 'xlw') { $ret = 'application/vnd.ms-excel'; }
        elsif($args{type} eq 'zip') { $ret = 'application/zip'; }
        elsif($args{type} eq 'swf') { $ret = 'application/x-shockwave-flash'; $embed = 1; }
        elsif($args{type} eq 'mov') { $ret = 'video/quicktime'; }
        elsif($args{type} eq 'qt')  { $ret = 'video/quicktime'; }
        elsif($args{type} eq 'mpg') { $ret = 'video/mpeg'; }
        elsif($args{type} eq 'mpe') { $ret = 'video/mpeg'; }
        elsif($args{type} eq 'snd') { $ret = 'audio/basic'; }
        elsif($args{type} eq 'wav') { $ret = 'audio/x-wav'; }
        return($ret, $embed);
    }

########################################################################
#                                                                      #
#  InhaleRender::inhaleRenderText                                      #
#                                                                      #
#  [NAMED ARGUMENTS]     text => the text to render               MAN  #
#                                                                      #
#                         cgi => a CGI OObject                    MAN  #
#                                                                      #
#                        user => a user OObject                   MAN  #
#                                                                      #
#                        type => the "type" of object that's      OPT  #
#                                being rendered or it's context        #
#                                                                      #
#                      target => the name of the HTML frame or    OPT  #
#                                window links should target            #
#                                (default is "inhale_main")            #
#                                                                      #
#                      render => the name of the "style" that     OPT  #
#                                is currently in use                   #
#                                (default is "inhale")                 #
#                                                                      #
#                     headers => a value indicating whether or    OPT  #
#                                not HTTP headers have already         #
#                                been generated, or need to be         #
#                                generated (default is "0")            #
#                                                                      #
########################################################################
#                                                                      #
#  See the following "inhaleRender" routine for more info on what      #
#  most of the arguments mean.                                         #
#                                                                      #
#  The "text" argument should be a string of text to be rendered.      #
#                                                                      #
#  The "type" argument is used to indicate the type of object, or      #
#  the context in which it's being rendered.  For example, pop up      #
#  tip boxes will usually pass "popup" as a value.                     #
#                                                                      #
#  The routine will also generate a throwaway object OObject to        #
#  store the relevant details in.                                      #
#                                                                      #
########################################################################

    sub inhaleRenderText 
    {
    
        my(%args)= @_;
        unless(defined($args{cgi}))  { InhaleCore::error('InhaleRender::inhaleRenderText() was called without passing a "cgi" object', 'bad call'); }
        unless(defined($args{user})) { InhaleCore::error('InhaleRender::inhaleRenderText() was called without passing a "user" object', 'bad call'); }
        unless(defined($args{text})) { InhaleCore::error('InhaleRender::inhaleRenderText() was called without passing a "text" argument', 'bad call'); }
    
        my $self = {};
        bless($self);
    
        $self->{content}    = $args{text};
        $self->{fileType}   = 'TXT';
        $self->{objectType} = $args{type} || '';
        
        unless(defined($args{headers}))  { $args{headers} = ''; }
        unless(defined($args{target}))   { $args{target}  = ''; }
        unless(defined($args{render}))   { $args{render}  = ''; }
    
        return( inhaleRender( object => $self, 
                                 cgi => $args{cgi}, 
                                user => $args{user},
                              target => $args{target}, 
                             headers => $args{headers}, 
                              render => $args{render} )
              );
    }


########################################################################
#                                                                      #
#  InhaleRender::inhaleRender                                          #
#                                                                      #
#  [NAMED ARGUMENTS]   object => an object OObject                MAN  #
#                                                                      #
#                         cgi => a CGI OObject                    MAN  #
#                                                                      #
#                        user => a user OObject                   MAN  #
#                                                                      #
#                      target => the name of the HTML frame or    OPT  #
#                                window links should target            #
#                                (default is "inhale_main")            #
#                                                                      #
#                      render => the name of the "style" that     OPT  #
#                                is currently in use                   #
#                                (default is "inhale")                 #
#                                                                      #
#                     headers => a value indicating whether or    OPT  #
#                                not HTTP headers have already         #
#                                been generated, or need to be         #
#                                generated (default is "0")            #
#                                                                      #
#                  renderlist => a string containing details      OPT  #
#                                of any objects already                #
#                                rendered (used to catch               #
#                                recursive embeded objects)            #
#                                                                      #
#                       extra => extra information that can       OPT  #
#                                passed to the routine                 #
#                                                                      #
########################################################################
#                                                                      #
#  This is the main rendering routine for turning database objects     #
#  into the final HTML output.                                         #
#                                                                      #
#  The code has evolved over time and is currently fairly              #
#  horrendous!  Creating a tidier version of "inhaleRender" is         #
#  high on my list of "things to do".                                  #
#                                                                      #
#  The routine is designed to allow recursive calls for rendering      #
#  objects that themselves contain other objects.                      #
#                                                                      #
#  One of the assumptions that this routine makes is that the "thing"  #
#  you want to render is already encapsulated as an object OObject.    #
#  That's why the "inhaleRenderText" routine has to generate a         #
#  throwaway object to render arbitary chunks of text.                 #
#                                                                      #
#  Ignoring the mandatory arguments (all of which are OObjects),       #
#  here's some info on what the optional arguments do:                 #
#                                                                      #
#  target                                                              #
#                                                                      #
#      Some of the tags create hyperlinks and the "target" value is    #
#      used so that these links are opened in the correct window or    #
#      frame.  Typically this will be the main window, which is why    #
#      the value defaults to "inhale_main".                            #
#                                                                      #
#      Just to confuse things, I sometimes use "target" to             #
#      indicate that the output is being generated for either a        #
#      tip box or the printable version of the unit.                   #
#                                                                      #
#  render                                                              #
#                                                                      #
#      The value of "render" should be the name/number of the style-   #
#      sheet that is currently in use.  This defaults to the           #
#      standard stylesheet "inhale", but could contain a 4 digit       #
#      number if the accessible version of the unit was being used.    #
#                                                                      #
#  headers                                                             #
#                                                                      #
#      Currently, three different values could be passed in the        #
#      "headers" value and they are used to control whether or not     #
#      to wrap the object with a HTTP header and some suitable         #
#      <html><head>...</head> HTML:                                    #
#                                                                      #
#          value    meaning                                            #
#          =====    =======                                            #
#                                                                      #
#             -1    do not generate any HTTP headers at all            #
#                                                                      #
#              0    no headers have been generated yet and feel        #
#                   free to generate some if needed                    #
#                                                                      #
#              1    suitable headers have already been generated,      #
#                   so just create some HTML suitable for putting      #
#                   into the <body>                                    #
#                                                                      #
#      During recursive calls, the routine will automatically          #
#      update the "headers" value appropriately.                       #
#                                                                      #
#      The "headers" value will also dictate how things like PDF       #
#      files or Flash stuff are embedded into the page - e.g. if       #
#      no headers have been generated then simply redirect to the      #
#      PDF file, otherwise add a hyperlink to the PDF file.            #
#                                                                      #
#  renderlist                                                          #
#                                                                      #
#      Because the routine can call itself recursively, it needs       #
#      to keep a track of what's already been rendered otherwise       #
#      it would get stuck in a loop if object A embedded object B      #
#      which in turn embedded object A, etc.                           #
#                                                                      #
#      Typically you will not pass this as an argument yourself, and   #
#      just allow the routine to generate it "as and when" needed.     #
#                                                                      #
#  extra                                                               #
#                                                                      #
#      As with "renderlist", this is an argument that you will not     #
#      normally pass a value in and you'll just let the routine        #
#      populate it whenever it needs to.                               #
#                                                                      #
#      One example would be if your object had "[o:red apple]30[/o]"   #
#      in it.  Assuming that object 30 is an image of some kind, the   #
#      text "red apple" will be used to override the description of    #
#      the image so that the output for the image will contain         #
#      <img alt="red apple" src="...">.  When the routine calls        #
#      itself recursively to render object 30, "extra" will contain    #
#      "red apple".                                                    #
#                                                                      #
########################################################################

    sub inhaleRender 
    {
        my(%args)= @_;
        unless(defined($args{cgi}))    { InhaleCore::error('InhaleRender::inhaleRender() was called without passing a "cgi" object', 'bad call'); }
        unless(defined($args{user}))   { InhaleCore::error('InhaleRender::inhaleRender() was called without passing a "user" object', 'bad call'); }
        unless(defined($args{object})) { InhaleCore::error('InhaleRender::inhaleRender() was called without passing a "object" object', 'bad call'); }
    
        my $cgi        = $args{cgi};
        my $user       = $args{user};
        my $object     = $args{object};
    
        my $target     = $args{target}     || 'inhale_main';
        my $httpHeader = $args{headers}    || 0;
        my $render     = $args{render}     || 'inhale';
        my $renderList = $args{renderlist} || '';
        my $extraInfo  = $args{extra}      || '';
	 my $customCSS  = $args{customCSS}  || '';    

        unless(defined($object->{'objectType'})) { $object->{'objectType'} = ''; }
        
        my $ret  = '';
        my $temp = '';
        my $end  = '';        
        
        my $tipNumber = 0;
        my $question  = 0;
        my $type      = $object->{fileType};    
    
        if(($type eq 'TXT' || $type eq 'xXML')) {
    
            if($httpHeader < 0) {
                $httpHeader = 1;
                $ret .= "<!-- use template -->\n";
                $end = '';
            }
            elsif($httpHeader == 0) {
                $httpHeader++;
                $ret .= $cgi->{header} || "Content-type: text/html\n\n";
                $ret .= qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n);
    
                my $encoding = $object->{encoding} || 'ISO-8859-1';
                $encoding = qq(<meta http-equiv="Content-Type" content="text/html;charset=$encoding" />\n);
    
    
                if($object->{'objectType'} eq 'popup' || $extraInfo eq 'popup') { 
                    $ret .= qq(<html><head>\n<title>tip box</title>\n);
                    $ret .= $encoding;
                    $ret .= generateStylesheet($render,'','',$customCSS).qq(</head>\n);
                    $ret .= qq(<body class="popup" onload="self.focus()"><div class="content">\n);
                }
                else { 
                    $ret .= qq(<html><head>\n<title>Intute Informs</title>\n);
                    $ret .= $encoding;
                    $ret .= generateStylesheet($render,'','',$customCSS).qq(</head>\n);
                    $ret .= qq(<body class="body_main" onload="self.focus()"><div class="content">\n);
                    $end = qq(\n</body></html>\n\n);
                }
            }
        }
    
### handle embedding of non textual objects
    
        if($type ne 'TXT' && $type ne 'xXML') {
            my $desc = $object->{description};
            my($mimeType, $embedInfo) = returnMIME( type => $type );
            if($embedInfo) {
                if($httpHeader > 0) { $ret .= embedObject( object => $object, extra => $extraInfo ); }
                else                { $ret .= "Location: ".$object->{virLocation}."\n\n"; }
            }
            else {
                if($httpHeader > 0) { $ret .= qq(object <a target="_blank" href="$object->{virLocation}">$object->{objectNumber}</a> of type $type<p>); }
                else                { $ret .= "Location: ".$object->{virLocation}."\n\n"; }
            }
        }
        elsif($type eq 'TXT') {
            my $txt = '';
    
            if($object->{content}) { $txt = $object->{content}; }
            else                   { $txt = InhaleRead::getObjectData( object => $object ); }
    
    
### tidy up those paragraphs and line breaks
    
            my $linebreak = chr(1);
            $txt =~ s/\r//g;
            while($txt =~ /\n\s+?\n/) { $txt =~ s/\n\s+?\n/\n\n/g; }
            while($txt =~ /\n\n\n/)   { $txt =~ s/\n\n\n/\n\n/g; }
            while($txt =~ /\n\n/)     { $txt =~ s/\n\n/$linebreak\<p \/\>$linebreak/g; }
            $txt =~ s/$linebreak/\n/g;

### ensure that the tags are balanced correctly
         
### perform simple replacements...
    
### [A] - action
### [B] - bold
### [H] - heading
### [I] - user input
### [K] - taks    
    
            if( $target eq 'print_copy' ) 
            { 
                $txt =~ s/\<p\>\n\[i\]/ \[i\]/gi;
                $txt =~ s/\[\/i\]\n\<p\>/\[\/i\] /gi;
            
                renderReplace( \$txt, 'b', '<b>', '</b>' );
                renderReplace( \$txt, 'c', '<i>', '</i>' );
                renderReplace( \$txt, 'd', '<u>', '</u>' );
                renderReplace( \$txt, 'a', '<span class="action">', '</span>' );
                renderReplace( \$txt, 'i', '<span class="userinput">', '</span>' );
                renderReplace( \$txt, 'h', '<b>', '</b>' );
                renderReplace( \$txt, 'k', '<b>Task:</b><div class="task">', '</div>' );
            }
            else {
                renderReplace( \$txt, 'b', '<b>', '</b>' );
                renderReplace( \$txt, 'c', '<i>', '</i>' );
                renderReplace( \$txt, 'd', '<u>', '</u>' );
                renderReplace( \$txt, 'a', '<span class="action">', '</span>' );
                renderReplace( \$txt, 'i', '<div style="text-align:center;"><div class="userinput">', '</div></div>' );
                renderReplace( \$txt, 'h', '<div style="text-align:center;"><h3>', '</h3></div>' );
                renderReplace( \$txt, 'k', '<div class="task">', '</div>' );
            }
    
### insert jumps
### [J] - jumps
    
            while( $txt =~ /\[j/i && $txt =~ /\[\/j\]/i ) {
            
                my($pre,$temp) = split(/\[j/i, $txt, 2);
                my($info, $rest) = split(/\]/, $temp, 2);
                my($dat,$aft) = split(/\[\/j\]/i, $rest, 2);                
                my @bits = split(/\:/, $info);                
                my $unit = $cgi->{'unit'};
                my $page = $cgi->{'page'};
                
                unless(defined($bits[1])) { $bits[1] = ''; }
                unless(defined($bits[2])) { $bits[2] = ''; }
                
                if($bits[2] =~ /^[-+]\d/) {
                    my $jumpto = $page;
                    my $val = $bits[2];
                    $val =~ s/^[-+]//gi;
    
                    if($bits[2] =~ /^-/) { $jumpto -= $val; }
                    else                 { $jumpto += $val; }
    
                    if($jumpto < 1) { $jumpto = 1; }
                    $bits[2] = $jumpto;
                    if($bits[1] !~ /^\d+?$/) { $bits[1] = $unit; }
                }
                else {
                    if($bits[1] !~ /^\d+?$/) { $bits[1] = $unit; }
                    if($bits[2] !~ /^\d+?$/) { $bits[2] = 1; }
                    else             { $bits[2]++; }
                }
                
                my $unitInfo = InhaleRead::getUnit( skiperrors => 1, unit => $bits[1] );

                unless($unitInfo->{unitNumber} eq $bits[1] && $bits[1]) {
                    $txt = $pre .qq(<br /><span class="rendererror">please check that you are jumping to a valid unit number (#$bits[1]):</span><b>[j$info]). $dat .qq([/j]</b>). $aft;
                    last;
                }                              
                
                if($bits[2] > $unitInfo->{totalSteps}) { $bits[2] =  $unitInfo->{totalPages}; }
                                            
                my $pageInfo = InhaleRead::getPage( page => $bits[2],
                                                    unit => $bits[1] );                
                if(@bits) { 
                    my $target = 'inhale_left';
                    if($cgi->value('action') eq 'none') {
                        if($pageInfo->{rightFrame} > 0) { $target = '_parent'; }
                        elsif($pageInfo->{rightFrameURL} ne '') { $target = '_parent'; }
                    }
                    
                    my $id     = $cgi->{'id'} || '';
                    my $folio  = $cgi->{'folio'} || '1';
                    my $action = $cgi->{'action'} || 'none';
                    my $render = $cgi->{'render'} || 'inhale';
                    
                    unless($dat) { $dat = 'click here'; }
                    
                    my $href = qq(page.pl?id=$id&amp;action=$action&amp;unit=$bits[1]&amp;page=$bits[2]&amp;render=$render&amp;folio=$folio);
                    
                    $txt = $pre .qq(<a href="$href" target="$target">$dat</a>). $aft;                   
                    
                }
                else {
                    $txt = $pre . $aft;
                }
            }
        
### insert referenced objects...
### [O] - objects
### code improved 11/Dec/2006 to remove common support problems...
    
            while($txt =~ /\[o/i && $txt =~ /\[\/o\]/i) {
                my($pre,$temp) = split(/\[o/i, $txt, 2);
                my($info, $rest) = split(/\]/, $temp, 2);
                my($dat,$aft) = split(/\[\/o\]/i, $rest, 2);
                $info =~ s/\://gi;
                $dat =~ s/[^-\d]//gi;
    
		my $exists = InhaleRead::checkObjectExists( $dat );

                if( $renderList !~ / $dat / && $exists ) {
                    $temp = inhaleRender( object => InhaleRead::getObject( object => $dat ), 
                                             cgi => $cgi, 
                                            user => $user, 
                                          target => 'inhale_main', 
                                         headers => 1, 
                                          render => $render, 
                                      renderlist => $renderList." $dat ", 
                                           extra => $info );
    
                    $txt = $pre . $temp . $aft;
                }
                elsif( !$dat ) {
		    $txt = $pre. qq(<p><span class="rendererror">ERROR: object number not specified in [O] tag</span></p>).$aft;
                }
		elsif( !$exists )
		{
		    $txt = $pre. qq(<p><span class="rendererror">ERROR: object #).$dat.qq( does not exist</span></p>).$aft;
		}
                else {
		    $txt = $pre. qq(<p><span class="rendererror">ERROR: unable to insert object #).$dat.qq(</span></p>).$aft;
                }
            }
    
### insert "quotes"
### [Q] - quotes
    
            while($txt =~ /\[q\]/i && $txt =~ /\[\/q\]/i) {
                my($pre, $temp) = split(/\[q\]/i, $txt, 2);
                my($dat, $aft) = split(/\[\/q\]/i, $temp, 2);
                $dat =~ s/^ //g;
                $dat =~ s/ $//g;
                $dat =~ s/^\"//g;
                $dat =~ s/\"$//g;
                $txt = $pre .'&quot;<span class="name">'. $dat .'</span>&quot;'. $aft;
            }
    
### centre stuff
### [P] - position stuff
    
            while($txt =~ /\[p/i && $txt =~ /\[\/p\]/i) {
                my($pre, $temp) = split(/\[p/i, $txt, 2);
                my($dat1, $aft) = split(/\[\/p\]/i, $temp, 2);
                my($inf, $dat) = split(/\]/, $dat1, 2);
                $inf =~ s/\W//gi;
    
                my $align = 'center';
                if($inf =~ /^l/i) { $align = 'left'; }
                if($inf =~ /^r/i) { $align = 'right'; }
            
                $dat =~ s/^ //g;
                $dat =~ s/ $//g;
                $dat =~ s/^\"//g;
                $dat =~ s/\"$//g;
                $txt = qq($pre<div align="$align">$dat</div>$aft);
            }
    
### insert URL's
### [U] - urls
    
            while( $txt =~ /\[u\](.*?)\[\/u\]/is ) 
	    {
                my( $pre, $tmp ) = split( /\[u\]/i, $txt, 2 );
                my( $dat, $aft ) = split( /\[\/u\]/i, $tmp, 2 );
    
                if( $target eq 'print_copy' )
                { 
                    $txt = $pre .'<b>'. $dat .'</b>'. $aft; 
                }
                else 
                { 
                    $txt = $pre .'<div style="text-align:center; font-size:90%;"><a href="'.$dat.'" target="'.$target.'">'. $dat .'</a></div>'. $aft; 
                }
            }
    
### insert lists
### [L] lists

            while( $txt =~ /\[l\](.*?)\[\/l\]/is ) 
	    {
                my( $pre, $temp ) = split( /\[l\]/i, $txt, 2 );
                my( $dat, $aft ) = split( /\[\/l\]/i, $temp, 2 );
                $dat =~ s/\<\/?p.*?\>/\n/gi;
                $dat =~ s/\<br.*?\>/\n/gi;
		  my @items = split( /\n/, $dat );

		$dat = "\n";
		foreach my $item ( @items )
		{
		    $item =~ s/^\s+?//g;
		    $item =~ s/\s+?$//g;
		    if( $item )
		    {
			$dat .= qq(<li>$item</li>\n);
		    }
		}
                $txt = "$pre\n<ul>$dat</ul>$aft";
            }
            
### insert tips
### [T] - tips
    
            while($txt =~ /\[t/i && $txt =~ /\[\/t\]/i) { 
                $tipNumber++;
            
                my($pre, $dat1) = split(/\[t/i, $txt, 2);
                my($tipHeader,$dat2) = split(/\]/, $dat1, 2);
    
                my $tipHeading = '';
                $tipHeader =~ s/\://g;
                if($tipHeader ne '') { $tipHeading = ' - '.$tipHeader; }
            
                my($dat, $aft) = split(/\[\/t\]/i, $dat2, 2);
                $dat =~ s/^ //g;
                $dat =~ s/ $//g;
    
                my $url = 'displaytip.pl?object='.$object->{objectNumber}.'&amp;tip='.$tipNumber.'&amp;render='.$render.'&amp;unit='.$cgi->{unit};
     
                if($extraInfo eq 'static') { 
                    $url = $user->{pathToCGI}.'/displaytip.pl?object='.$object->{objectNumber}.'&amp;tip='.$tipNumber.'&amp;render='.$render.'&amp;unit='.$cgi->{unit}; 
                }
    
                if(defined($cgi->{page})) { $url .= '&amp;page='.$cgi->{page}; }
    
                my $height = (int(165 + (length($dat) * 0.5)));
                if($height > 350) {$height = 350;}
                my $width = 400;
    
                my $insert = '';
    
                if($extraInfo eq 'static') { 
                    $insert = qq(\n<!--\nTIP $object->{objectNumber}\n$tipHeader\n$dat\n-->\n);
                    $txt = $pre.$insert.$aft;
                }
                elsif($target eq 'print_copy') { 
                    if($tipHeader) { $tipHeader = ' - '.$tipHeader; }
                    $txt = $pre.$insert.'<br /><blockquote><div align="left"><b>Useful Tip'.uc($tipHeader).':</b><br /><div class="tip">'.$dat.'</div></div></blockquote><br />'.$aft;
                }
                elsif($user->{showTips} eq 'window') {
                    $txt = $pre.$insert.'<br /><div style="font-size:90%" class="tip"><a title="'.niceQuotes(tidy($dat)).'" href="'.$url.'" onclick="tip'.$tipNumber.' = window.open(\''.$url.'\', \'tip'.$tipNumber.'\' , \'width='.$width.',height='.$height.',scrollbars=yes,screenX=20,screenY=20,top=20,left=20\'); return false" target="tip'.$tipNumber.'"><b>TIP:</b> '.$tipHeader.'</a></div>'.$aft;
                }
                elsif($user->{showTips} eq 'text') {
                    if($tipHeader) { $tipHeader = ' - '.$tipHeader; }
                    $txt = $pre.$insert.'<br /><div style="font-size:85%" class="tip"><b>TIP: '.$tipHeading.'</b><br />'.$dat.'</div>'.$aft;
                }
                else {
###tip for guide
                    if($tipHeader) { $tipHeader = ' - '.$tipHeader; }
$dat =~ s/&nbsp;/ /g;
$txt = $pre.$insert.'	
<script language="javascript"> 
function toggle'.$tipNumber.'() {
	var ele = document.getElementById("toggleText'.$tipNumber.'");
	var text = document.getElementById("displayText'.$tipNumber.'");
	if(ele.style.display == "block") {
    		ele.style.display = "none";
		text.innerHTML = "<img src=\"http://www.informs.intute.ac.uk/gfx/tip.gif\" border=\"0\" /> '.$tipHeading.'";
  	}
	else {
		ele.style.display = "block";
		text.innerHTML = "<img src=\"http://www.informs.intute.ac.uk/gfx/tip.gif\" border=\"0\" /> Hide Tip";
	}
} 
</script>
<p><a title="'.niceQuotes(tidy($dat)).'" id="displayText'.$tipNumber.'" href="javascript:toggle'.$tipNumber.'();"><img src="http://www.informs.intute.ac.uk/gfx/tip.gif" border="0" /> '.$tipHeading.'</a>
<div id="toggleText'.$tipNumber.'" style="display:none"><p class="tip"><b class="object">'.niceQuotes(tidy($dat)).'</b></p></div></p>'.$aft;  
		}
         }
        
### show questions
### [Z] - quiz
    
        my $loop = 0;

        while($txt =~ /\[z/i && $txt =~ /\[\/z\]/i) {
        
            my($ignore, $next) = split(/\[z/, $txt, 2);    
            
### normal question
    
            if($next =~ /^\:/) {
    
                my $prepend = '';
                my $correct = '';
                my $result = '';
                my $correctAnswer = '';

                if($question == 0) {
                    $prepend = qq(\n<a name="form"></a>\n);
                    $prepend.= qq(<form action="$ENV{SCRIPT_NAME}#form" method="get">\n);
		    $prepend.= qq(<input type="hidden" name="quiz" value="1" />\n);
                    
                    my @names = keys %$cgi;
                    my @bits = split(/\&/, $ENV{QUERY_STRING});
                    my %check = ();
                    foreach (@bits) { 
                        my($a, $b) = split(/\=/, $_, 2);
                        $check{$a}++;
                    }
                                        
                    foreach $temp (@names) {
                        if($temp !~ /^q\_/ && $check{$temp}) {
                            $prepend.= qq(<input type="hidden" name="$temp" value="$cgi->{$temp}" />\n);
                        }
                    }
                }
    
                $question++;
     
                my($pre, $dat1) = split(/\[z\:/i, $txt, 2);
                my($answer, $dat2) = split(/\]/, $dat1, 2);
                if($dat2=~/^\]/) {
                    $answer.=']';
                    $dat2 =~ s/^\]//g;
                    $answer =~ s/\[ +?/\[/g; 
                    $answer =~ s/ +?\]/\]/g; 
                }
                $answer =~ s/[\r\n]/ /gi;
                $answer =~ s/  / /gi;
                $correctAnswer = $answer;    
            
                $answer =~ s/^\://g;
            
                if($answer =~ /_today_/i) { 
                    $answer = '('.getDate("dd/mm/yyyy").')'; 
                    $correctAnswer = "(today's date)";
                }
            
                my($dat, $aft) = split(/\[\/z\]/i, $dat2, 2);
                $dat =~ s/^ //g;
                $dat =~ s/ $//g;
            
                if($cgi->{"q_".$question}) {
                    my $response = lc($cgi->{"q_".$question});
                    my $perfect = lc($answer);
                    $perfect =~ s/^\s*//gi;
                    $perfect =~ s/\s*$//gi;
                    $response =~ s/^\s*//gi;
                    $response =~ s/\s*$//gi;
                    
            $response =~ s/\W//g;
            $perfect =~ s/\W//g;
            $response =~ s/ //g;
            $perfect =~ s/ //g;
                
                    if($perfect eq $response) { 
                        $answer = '<span style="color:red">CORRECT!</span>'; 
                        $correct = 'y';
                    }
                    else { $answer = convertTags($answer); }
                }
                else {
                    $answer = '';
                }
    
                my $insert = $question;
                if($target eq 'print_copy') { $insert = $object->{objectNumber}.'|'.$question.'|'.$correctAnswer; }

#added to remove &amp; display in quiz answer 
$answer =~ s/&amp;/&/g;

                if($correct) {
                    $txt = $pre . $prepend .qq(\n<!-- start $insert -->\n<span class="question">$dat:</span>);
                    $txt.= qq(<br /><div align="center">);
                    $txt.= qq(<input class="textualinputcorrect" type="text" name="q_$question" value=") . convertTags($cgi->{'q_'.$question}) . q(" /></div>);
                    $txt.= qq(<div align="right"><div class="wrong3">$answer</div></div>\n);
                    $txt.= qq(<!-- end $question -->\n$aft);
                }
                else {
                    $txt = $pre . $prepend. qq(<br />\n<!-- start $insert -->\n<span class="question">$dat:</span>);
                    $txt.= qq(<br /><div align="center">);
                    $txt.= qq(<input class="textualinput" type="text" name="q_$question" value="). convertTags($cgi->{"q_".$question}) .q(" size="15" /></div>);
                    $txt.= qq(<div align="right"><span class="quizanswer">$answer</span></div>\n);
                    $txt.= qq(<!-- end $question -->\n$aft);
                }
            }
        
### MULTIPLE CHOICE!
        
            else {
    
                my $prepend = '';
                my $correct = '';
                my $correctAnswer = '';
                my $result = '';
    
                if($question == 0) {
                    $prepend = qq(\n<a name="form"></a>\n);
                    $prepend.= qq(<form action="$ENV{SCRIPT_NAME}#form" method="get">\n);
		    $prepend.= qq(<input type="hidden" name="quiz" value="1" />\n);
                    
                    my @names = keys %$cgi;
                    my @bits = split(/\&/, $ENV{QUERY_STRING});
                    my %check = ();
                    foreach (@bits) { 
                        my($a, $b) = split(/\=/, $_, 2);
                        $check{$a}++;
                    }                    
                    
                    foreach $temp (@names) {
                        if($temp !~ /^q\_/ && $check{$temp}) {
                            $prepend.= qq(<input type="hidden" name="$temp" value="$cgi->{$temp}" />\n);
                        }
                    }
                }

                my($pre, $dat1) = split(/\[z\]/i, $txt, 2);
                my($answer, $aft) = split(/\[\/z\]/, $dat1, 2);    
    
### this next chunk of code attempts to place the <form> tag in the preceeding <br />
### to avoid generating unwanted whitespace...
    
                if($question == 0 && ($pre =~ /\<p\>/ || $pre =~ /\<p \/\>/)) {
                     my $chr = chr(1);
                     $pre =~ s/\<p\>/$chr/gi;
                     $pre =~ s/\<p \/\>/$chr/gi;
                 
                    my @bits = split(/$chr/, $pre);
                    my $last = pop(@bits);
                    $pre = join('<br />', @bits);
                    $prepend .= "<br />$last";
                 }
    
                $question++;
    
                $answer =~ s/[\r]//gi;
                $answer =~ s/\<br\s*\/?\>/\n/g;
                my @test = split(/\n/, $answer);
    
                my $temp = $user->{userID};
                $temp =~ s/\D//gi;
                srand($temp);
                
                my @answers = ();
                
                foreach my $test (@test) {
                    $test =~ s/^\s*//gi;
                    $test =~ s/\s*$//gi;
                    $test =~ s/\<.+?\>//gi;
                    
                    if($test) { push @answers, $test; }
                }
    
                $correct = $answers[0];
                $correctAnswer = $answers[0];
                
# randomly shuffle @answers for this user - code taken from perlfaq4
    
                if(@answers > 1) {
    
                    my @array = @answers;
                    my $i;
                    for ($i = @array; --$i; ) {
                        my $j = int rand ($i+1);
                        @array[$i,$j] = @array[$j,$i];
                    }
                    @answers = @array;
                }
    
                my $chunk = '';
                my $reply = '';
                my $index = 0;
                
                my $insert = $question;
                if($target eq 'print_copy') { $insert = $object->{objectNumber}.'|'.$question.'|'.$correctAnswer; }
    
                foreach my $multi (@answers) {
                    $index++;
                    
                    my $studentAnswer = $cgi->value('q_'.$question);
                    
                    if($studentAnswer eq $index && $multi eq $correct) { 
                        $chunk = qq(<div class="multi"><input type="radio" name="q_$question" value="$index" checked /><b>$multi</b> <span class="wrong">Correct!</span></div>\n);
                        last;
                    }
                    if($studentAnswer eq $index) {
                        $chunk .= qq(<div class="multi"><input type="radio" name="q_$question" value="$index" checked />$multi</div>\n);
                        $reply = '<div class="wrong">...please try again!</div>';
                    }
                    else {
                        $chunk .= qq(<div class="multi"><input type="radio" name="q_$question" value="$index" />$multi</div>\n);
                    }
                }
                
                $txt = $pre. $prepend . qq(\n<br /><!-- start $insert -->) . $chunk . $reply . qq(<!-- end $question -->) . $aft;      
       
            }
            $loop++;
            if($loop > 200) { 
                my $str = qq(<p class="flash"><b><font color="red">the syntax of the following tag is not valid:</font></b><br />[z);
                $txt =~ s/\[Z/$str/i;
                last; 
            }
        }    
    
### insert "lost? click here to reload"
### [R] - reload
    
            while($txt =~ /\[r/i && $txt =~ /\[\/r\]/i) {
                my($pre, $temp) = split(/\[r\]/i, $txt, 2);
                my($dat, $aft) = split(/\[\/r\]/i, $temp, 2);
                $dat =~ s/^ //g;
                $dat =~ s/ $//g;
                $dat =~ s/^\"//g;
                $dat =~ s/\"$//g;
                if($target eq 'print_copy') { 
                $txt = $pre . $aft;
                }
                else { $txt = $pre .'<div style="font-size:90%"><a href="'.$dat.'" target="'.$target.'" title="[ click here to reload the correct page on&#10;the right hand side of the screen ]"><img src="'.$htmlVirPath.'gfx/lost.gif" alt="click here to reload the correct page on&#10;the right hand side of the screen" border="0" />Lost? ...click here</a></div>'.$aft; }
            }
    
            if($question > 0 && $target ne 'print_copy') { 
                $temp = '<!-- end '. $question .' -->';
                my $replace = qq($temp\n<br /><div align="center"><input type="submit" value="check answers" class="submit" /></form></div>\n);
                $txt =~ s/$temp/$replace/gi;
            }
            $ret .= $txt;        
        }
      
        $ret .= $end;
        return($ret);
    }
      

########################################################################
#                                                                      #
#  InhaleRender::renderReplace                                         #
#                                                                      #
#  [ARGUMENTS]    1. a reference to a string of text              MAN  #
#                                                                      #
#                 2. the [tag] to find                            MAN  #
#                                                                      #
#                 3. replacement opening HTML tag - e.g. <b>      MAN  #
#                                                                      #
#                 4. replacement end HTML tag - e.g. </b>         MAN  #
#                                                                      #
########################################################################
#                                                                      #
#  A quick and dirty routine for handling some of the simpler tag      #
#  replacements.                                                       #
#                                                                      #
########################################################################
    
    sub renderReplace2 {
        my($text, $find, $rep1, $rep2) = @_;
        my $cnt = 0;
        while($$text =~ /\[$find\]/i) {
            my($pre, $temp) = split(/\[$find\]/i, $$text, 2);
            my($dat, $aft) = split(/\[\/$find\]/i, $temp, 2);
    
            unless($pre) { $pre = ''; }
            unless($dat) { $dat = ''; }
            unless($aft) { $aft = ''; }
    
            $dat =~ s/^ +?//g;
            $dat =~ s/ +?$//g;
            $$text = $pre . $rep1 . $dat . $rep2 . $aft;
            $cnt++; if($cnt > 100) { last; }
        }
    }
    
    sub renderReplace 
    {
        my($text, $find, $rep1, $rep2) = @_;

        while( $$text =~ s/\[$find\](.*?)\[\/$find\]/$rep1$1$rep2/is ) 
        {

        }
    }
    
########################################################################
#                                                                      #
#  InhaleRender::embedObject                                           #
#                                                                      #
#  [NAMED ARGUMENTS]   object => an object OObject                MAN  #
#                                                                      #
#                       extra => optional extra info              OPT  #
#                                                                      #
########################################################################
#                                                                      #
#  Contains code for embedding various types of objects into the       #
#  HTML output.                                                        #
#                                                                      #
#  Only a few object types are currently handled "intelligently",      #
#  so this routine need a bit more work on it.                         #
#                                                                      #
########################################################################
    
    sub embedObject {
        my(%args)= @_;
        unless(defined($args{object})) { InhaleCore::error('InhaleRender::embedObject() was called without passing a "object" object', 'bad call'); }
        unless(defined($args{extra}))  { $args{extra}=''; }
 
        my $type = $args{object}->{fileType};
        my $ret = '';
    
        my $description = $args{extra} || $args{object}->{description};
    
        if($type eq 'GIF' || $type eq 'PNG' || $type eq 'JPG') {
            $ret = qq( <img src="$args{object}->{virLocation}" alt="[ $description ]" /> );
            return($ret);
        }
        elsif($type eq 'SWF') {    
            $ret .= <<SWF;

<div style="text-align:center;">
<object id="macromedia_home_shell_object" name="$args{object}->{virLocation}" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0" width="90%" height="90%">
<param name="movie" value="$args{object}->{virLocation}" /
<param name="scale" value="showall" />
<param name="quality" value="high" />
<param name="bgcolor" value="#e6e6dc" />
<param name="salign" value="lt" />
<param name="menu" value="false" />
<embed id="macromedia_home_shell_embed" width="90%" height="90%" name="macromedia_home_shell.swf" src="$args{object}->{virLocation}" scale="showall" quality="high" bgcolor="#e6e6dc" salign="lt" name="movie" menu="false" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash"></embed>
</object>
</div>
SWF

            return($ret);
        }
        else {
            $ret = qq(<br /><b><font color="red">object <a href="$args{object}->{virLocation}" target="_blank">$args{object}->{objectNumber}</a> to go here!</font></b><br />);
            return($ret);
        }
    }


########################################################################
#                                                                      #
#  VARIOUS PRIVATE ROUTINES FOR DOING MUNDANE STUFF                    #
#                                                                      #
#  tidy()                                                              #
#                                                                      #
#      remove leading and trailing whitespace                          #
#                                                                      #
#  niteQuotes()                                                        #
#                                                                      #
#      convert a string to make suitable for including in an "alt"     #
#      or "title" element                                              #
#                                                                      #
#  getDate()                                                           #
#                                                                      #
#      returns the current date in a couple of formats                 #
#                                                                      #
########################################################################

sub tidy {
    my($str) = @_;
    while($str =~ /^\s/s) { $str =~ s/^\s*//gis; }
    while($str =~ /\s$/s) { $str =~ s/\s*$//gis; }
    return($str);
}

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

sub getDate {
    my($format)=@_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon++;
    my $ret = '';
    
    if($format eq 'dd/mm/yyyy') { 
        $ret = substr("00".$mday, -2) ."/". substr("00".$mon, -2) ."/". $year; 
    }
    if($format eq 'dd/mm/yy') { 
        $ret = substr("00".$mday, -2) ."/". substr("00".$mon, -2) ."/". substr($year, -2); 
    }
    return($ret);
}


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
            if( $a eq 'objectvirpath' ) { $objectVirPath = $b }
            if( $a eq 'objectdirpath' ) { $objectDirPath = $b }
            if( $a eq 'htmlvirpath' )   { $htmlVirPath = $b }
            if( $a eq 'htmldirpath' )   { $htmlDirPath = $b }
	    if( $a eq 'cachepath' )     { $cachePath = $b; }

        }
    }
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


END { }



1;

