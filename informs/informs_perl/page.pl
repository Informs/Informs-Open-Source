#!/home/zzintadm/perl/bin/perl -WT

use strict;
use lib "./";

use InhaleCore qw( :DEFAULT untaint timeToRun urlencode );
new InhaleCore;

use InhaleRead qw( getPage getUnit readMetadata fetchLinks );
use HTML::Entities ();

my $width = 260;
my $digest = $user->{'userID'};
my $action = $cgi->{'action'} || 'none';
my $render = $cgi->{'render'} || 'inhale';
my $newline = "\n";

my %template = ();
my %metadata = readMetadata( unit => $cgi->{'unit'} );

my %iso3166 = getVocab( vocab => "iso3166-1" );
my %iso639  = getVocab( vocab => "iso639-1" );
my %dewey   = getVocab( vocab => "dewey" );
my %jacs    = getVocab( vocab => "jasc" );

if($metadata{'1.2'}) { $template{dublinCore} .= qq(<meta name="DC.Title" lang="en" content=").makeSafe($metadata{'1.2'}).qq(" />\n); }
if($metadata{'1.4'}) { $template{dublinCore} .= qq(<meta name="DC.Description" lang="en" content=").makeSafe($metadata{'1.4'}).qq(" />\n); }
if($metadata{'1.3a'} && $metadata{'1.3b'}) { $template{dublinCore} .= qq(<meta name="DC.Language" scheme="RFC1766" content=").makeSafe($metadata{'1.3a'}).'-'.makeSafe($metadata{'1.3b'}).qq(" />\n); }
if($metadata{'9.1disc'}) { $template{dublinCore} .= qq(<meta name="DC.Subject" scheme="DDC" content=").makeSafe($metadata{'9.1disc'}).qq(" />\n); }
if($metadata{'9.1disc2'}) { $template{dublinCore} .= qq(<meta name="DC.Subject" scheme="JACS" content=").makeSafe($metadata{'9.1disc2'}).qq(" />\n); }
$template{dublinCore} .= qq(<meta name="DC.Relation.IsPartOf" scheme="URI" content="$user->{pathToCGI}portfolio.pl?folio=$cgi->{folio}" />\n);
$template{dublinCore} .= qq(<meta name="DC.Identifier" scheme="URI" content="$user->{pathToCGI}jump.pl?$cgi->{folio}:$cgi->{unit}" />\n);
$template{dublinCore} .= qq(<meta name="DC.Format" scheme="IMT" content="text/html" />\n);
$template{dublinCore} .= qq(<meta name="DC.Type" lang="DCMIType" content="Tutorial" />\n);
$template{dublinCore} .= qq(<meta name="DC.Creator" content="$user->{accountTitle}" />\n);
$template{dublinCore} .= qq(<meta name="DC.Publisher" content="Intute Informs, based at the University of Manchester, UK" />\n);
$template{dublinCore} .= qq(<meta name="DC.Rights" lang="en" content="http://www.informs.intute.ac.uk" />\n\n);

my $templog = untaint($user->{pathToData}."temp/".$digest.".txt", 4);

if($action eq 'init' && defined($ENV{HTTP_REFERER})) {
    $digest =~ s/[\W]//gi;
    open(OUT,">$templog");
    print OUT $ENV{HTTP_REFERER};
    close(OUT);
    my $temp = chmod 0666, $templog;
}

if($action eq 'initnoframes1') {
    if(defined($ENV{HTTP_REFERER})) {
        open(OUT,">$templog");
        print OUT $ENV{HTTP_REFERER};
        close(OUT);
        my $temp = chmod 0666, $templog;
    }
    print $cgi->{'header'};
    print initNoFrames1($cgi->{'folio'}, $cgi->{'unit'}, $cgi->{'page'}, $render, $digest, %template);
    exit;
}

if($action eq 'initnoframes2') { 
    my $page = getPage( page => $cgi->{'page'}, unit => $cgi->{'unit'} );

    if(defined($ENV{HTTP_REFERER})) {
        open(OUT,">$templog");
        print OUT $ENV{HTTP_REFERER};
        close(OUT);
        my $temp = chmod 0666, $templog;
    }
    print $cgi->{'header'};
    print initNoFrames2($cgi->{'folio'}, $cgi->{'unit'}, $page, $render, $digest, $cgi->{'page'}, %template);
    exit;
}

if($cgi->{'unit'}) {
    my $unit   = getUnit( unit => $cgi->{'unit'} );
    my $page   = getPage( page => $cgi->{'page'}, unit => $cgi->{'unit'});
    my $rscript = 'frame.pl';
    my $js = '';
    
    if($cgi->{'page'} == 1) {
        $js = "<script language=\"JavaScript\" type=\"text/javascript\">

        <!--
		if (self != top) {
		    width = screen.availWidth;
		    height = screen.availHeight;
		    if(height <= 20) { height = 480; }
		    if(width <= 20) { height = 600; }
		    
		    width = width - 100;
		    height = height - 200;

		    window.open('page.pl?max=yes&amp;unit=".$cgi->{'unit'}."&amp;folio=".$cgi->{'folio'}."&amp;page=".$cgi->{'page'}."&amp;render=".$render."','inhale','scrollbars=yes,menubar=yes,directories=yes,toolbar=yes,resizable=yes,status=yes,width=' + width + ',height=' + height + 'screenX=20,screenY=5,top=5,left=20');
	            alert(window.history[-1]);
	            if(history.length) {
	                history.back();
	            }
	            else {
 	                self.close();
	            }
     		}
		//--></script>
";
    }

    my $urlLink = 'folio='. $cgi->{'folio'} .'&render='. $render .'&unit='. $cgi->{'unit'} .'&page='. $cgi->{'page'};
    $urlLink .= '&amp;id='. $digest;

    if($action) { $urlLink .= '&amp;action='.$action; }
    my $unload = '';    
    my $max = '';
    
    if($action eq 'init') { 
        $max .= qq(    window.moveTo(0,0); \n);
        $max .= qq(    if (navigator.appName == 'Microsoft Internet Explorer') { window.resizeTo(screen.availWidth,screen.availHeight); } \n);
        $max .= qq(    if (navigator.appName == 'Netscape') { window.outerHeight = screen.availHeight; window.outerWidth = screen.availWidth; } \n);

    }

    $js = "<script language=\"JavaScript\" type=\"text/javascript\">
<!--
    $max

//--></script>
";

    if($cgi->{org} eq 'contents') { 
        unless($page->{rightFrameURL} || $page->{rightFrame}) {
	    my @links = fetchLinks( unit => $cgi->{unit} );

	    foreach my $loop (1 .. $cgi->{page}) {
	        my($obj, $url) = split(/\|/, $links[$loop]);
	        if($obj || $url) {
	            $page->{rightFrame} = $obj;
	            $page->{rightFrameURL} = $url;
	        }
	    }
	}    
    }

### only the left hand frame is an INHALE object - the right hand frame is a remote URL
### ...but the right hand frame URL needs parsing to remove any "frame busting" code

    if($action eq 'noframes') {
        my $left = $rscript . '?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink;
        my $right = '';
        if($page->{rightFrame} < 0) {
	    $right = $page->{rightFrameURL};
        }
        elsif($page->{rightFrame} ne '0') {
            $right = 'frame.pl?object='. $page->{rightFrame} .'&amp;frame=main&amp;'. $urlLink;
        }
        elsif($page->{rightFrameURL}) {
	    $right = $page->{rightFrameURL};
	}
        print $cgi->{'header'};
        print '<html><head>'.$newline;
	print '<script language="JavaScript" type="text/javascript">
<!--
    function loader() {
        left = "'.$left.'";
	self.location = left;
';
	if($right) {
	    print'
        right = "'.$right.'";
	parent.launchMain(right);
	';
	}
	print '
    }    
// -->
';
	print '</script></head><body onload="loader();">';
	print '</body></html>';
        
	print 'location: '. 
	exit;
    }

### both frames are INHALE objects
    
    elsif($page->{rightFrame} ne '0') {
        print $cgi->{'header'};
        print qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">\n);
        print "<html lang=\"en\"><head>\n";
	 print qq(<meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1" />\n<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />\n<meta http-equiv="Pragma" content="no-cache" />\n<meta http-equiv="Cache-Control" content="no-cache" />\n);
	 print "$template{dublinCore}<title>". $unit->{unitTitle} .' :: '.$user->{browser}.'</title>'. $js .'</head>'. $newline;


        print '<iframe width="23%" height="650px" id="inhale_left" name="inhale_left" src="'. $rscript.'?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink .'"/></iframe>'.$newline;
        print '<iframe width="75%" height="650px" id="inhale_main" name="inhale_main" src="frame.pl?object='. $page->{rightFrame} .'&amp;;frame=main&amp;'. $urlLink .'"/></iframe>'.$newline; 
        print noFrames($cgi->{'folio'}, $cgi->{'unit'}).'</html>'. $newline;
        print qq(<!-- 1 -->);
    }
    
### only the left hand frame is an INHALE object - the right hand frame is a remote URL

    elsif($page->{rightFrame} eq '0' && $page->{rightFrameURL}) {
        print $cgi->{'header'};
        print qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">\n);
        print "<html lang=\"en\"><head>\n";
	 print qq(<meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1" />\n<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />\n<meta http-equiv="Pragma" content="no-cache" />\n<meta http-equiv="Cache-Control" content="no-cache" />\n);
	 print "$template{dublinCore}<title>".$unit->{unitTitle} .' :: '.$user->{browser}.'</title>'. $js .'</head>'. $newline;
        print '<iframe width="23%" height="650px name="inhale_left" scrolling="yes" marginheight="0" marginwidth="0" frameborder="1" src="'. $rscript .'?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink .'" /></iframe>'. $newline;
        print '<iframe width="75%" height="650px name="inhale_main" src="'. $page->{rightFrameURL}.'" /></iframe>'. $newline;
	 print qq(<!-- 2 -->);
    }
    
### only the left hand frame needs updating

    else {
$urlLink =~ s/\&amp;/\&/gi;
        print 'location: '.$user->{pathToCGI} . $rscript .'?object='. $page->{leftFrame} .'&frame=left&'. $urlLink ."\n\n";
}
}

end InhaleCore;

sub dumpError {
    my $error = shift;
    print $cgi->{'header'};
    print '<html><head><title>error message</title></head>';
    print '<body bgcolor="#FFFFFF" text="#000000"><font face="Verdana" size=2><dl><dt><b>your request has generated an error:</b><p><dd>';
    print $error;
    print '</dl></body></html>';
    exit;
}

sub initNoFrames1 {
    my($folio, $unit, $page, $render, $digest, %template) = @_;
    
    my $templog = untaint($user->{pathToData}."temp/".$digest.".txt", 4);

    my $orgRefer = $ENV{HTTP_REFERER};
    if(open(IN, $templog)) {
        $orgRefer = <IN>;
        close(IN);
    }
    
    my $refer = '';
    if($orgRefer) {
        $refer = qq(<p />Alternatively you can <a href="$orgRefer">click here</a>, or use your browser's back button, to return to the previous page.);
    }
    
<<NOFRAMES1;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
$template{dublinCore}
    <title>Starting unit number $unit</title>
    <script language="JavaScript" type="text/javascript">
    <!--

    var popUpOkay = 0;
    var windowhandle;

    function launchGuide() {
        url = 'page.pl?render=$render&amp;unit=$unit&amp;page=$page&amp;id=$digest&amp;folio=$folio&amp;action=initnoframes2';
        openY = screen.availHeight;
        openY = (openY - 35);
        if(openY > 900) { openY = 900; }
        if(openY < 100) { openY = 350; }
        windowhandle = window.open(url,"guide","width=280,height="+openY+",directories=no,toolbar=no,status=no,resizable=yes,menubar=no,scrollbars=yes,screenX=0,screenY=0,top=0,left=0");


	if( windowhandle != null ) {
	    popUpOkay = 1;
            if(history.length) {
                history.back();
            }
            else {
                self.close();
            }
        }
    }

    // -->
    </script>
</head>
<body>
    <script language="JavaScript" type="text/javascript">
    <!--
	launchGuide();
	if( popUpOkay == 0 ) {
	     document.write('<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css" />');
	     document.write('<div class="container">');
	     document.write('<p><img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" /></p>');     
            document.write('<p>It looks like you are running a web browser pop up blocker.</p>');
            document.write('<p /><a href="#" onclick="launchGuide(); return false;">Please click here to start the unit...</a>');
	     document.write('</div>');	
}
        else {
	    if(history.length) {
                document.write("please click on your browsers' back button to return to the previous page");
            }
            else {
                document.write("please close this window or click on your browsers' back button to return to the previous page");
            }
	}
    // -->
    </script>
    <noscript>
    	<b>This unit requires JavaScript and your web browser does not appear to support this.</b>
	<p />
	Please <a href="$user->{pathToCGI}printunit.pl?folio=$folio&amp;unit=$unit">click here</a> for a single page version of this unit that does not require JavaScript support.
	<p />
	$refer
    </noscript>
</body></html>
NOFRAMES1

}

sub initNoFrames2 {
    my($folio, $unit, $page, $render, $digest, $pageNumber, %template) = @_;
    my $urlLink = 'action=noframes&amp;folio='. $folio .'&amp;render='. $render .'&amp;unit='. $unit .'&amp;page='. $pageNumber .'&amp;id='. $digest;

    my($left,$right) = '';
    
    
    if($page->{rightFrame} eq '-1' || $page->{rightFrame} eq '-2') {
        $left  = 'frame.pl?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink;
      	$right = 'proxy.pl?url='. urlencode($page->{rightFrameURL}) .'&amp;rep='. abs($page->{rightFrame});
    }  
    
    ### both frames are INHALE objects
        
    elsif($page->{rightFrame} ne '0') {
        $left  = 'frame.pl?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink;
        $right = 'frame.pl?object='. $page->{rightFrame} .'&amp;frame=main&amp;'. $urlLink;
    }
        
    ### only the left hand frame is an INHALE object - the right hand frame is a remote URL
    
    elsif($page->{rightFrame} eq '0' && $page->{rightFrameURL}) {
        $left  = 'frame.pl?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink;
        $right = $page->{rightFrameURL};
    }

    my $cleanUrl = $right;
    if( $cleanUrl =~ /^http/ ) { $cleanUrl = urlencode( $right ) }

    my $noFrames = noFrames($folio, $unit, $page);

   
<<NOFRAMES2;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
<html lang=\"en\">
<head><title>guide @ the side</title>
<meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1" />
<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache" />
$template{dublinCore}
<script language="JavaScript" type="text/javascript">
<!--

    width=250;
    posX = (width + 50);

    openY = screen.availHeight;
    openX = screen.availWidth;
    openX = (openX - (posX + 12));
    openY = (openY - 82);
    if(openX > 900) { openY = 900; }
    if(openY > 900) { openY = 900; }
    if(openY < 100) { openY = 350; }
    if(openX < 100) { openY = 300; }

    var mainUrl = "$cleanUrl";

    initMain("1");
    checkMain();
    self.focus();


    function initMain(url) {
	openUrl = mainUrl + '&reopen=' + url;
        windowhandle = window.open(openUrl,"inhale_main","width=" + openX + ",height=" + openY + ",directories=no,toolbar=yes,resizable=yes,menubar=no,scrollbars=yes,screenX=" + posX + ",screenY=0,top=0,left=" + posX);
	checkMain();
	refocus();
    }

    function checkMain() {
	var mainIsOpen = true;
	if (windowhandle == null) { 
	    mainIsOpen = false;
	}
	return mainIsOpen;
    }

    function launchMain(url) {
        if(windowhandle.closed) {
            window.status="no window";
            initMain(url);
        }
        else {
            window.status="window ok";
            windowhandle.location.href = url;
	    refocus();
        }
    }

    function relaunchMain(url) {
	if(!windowhandle.closed) {
	    closeMain();
        }
	initMain(url);
    }

    function closeMain() {
        windowhandle.close();
    }

    function refocus() {
        windowhandle.focus();
        self.focus();
    }

    function initOnLoader()
    {
	self.inhale_left.location.href='$left';
    }

// -->
</script>

</head>


<iframe onunload="closeMain();" width="250" height="600" src="$left" name="inhale_left">
$noFrames
</iframe>

</html>

NOFRAMES2

}

sub noFrames {
    my($folio, $unit) = @_;

<<NOFRAMESET

<noframes>
<body>
<b>Your web browser does not appear to support framesets</b>
<p />
Please <a href="$user->{pathToCGI}printunit.pl?folio=$folio&amp;unit=$unit">click here</a> for a single page version of this unit.
</body>
</noframes>

NOFRAMESET

}

sub getVocab {
    my(%args) = @_;	
    my $file = $args{vocab};	
    my %ret = ();

    open(IN, $user->{pathToData}."metadata/vocabs/$file.txt");
    while(my $line = <IN> ) {
        $line =~ s/[\r\n]//gi;	
    	my($code, $default, $data) = split(/\t/, $line);
    	if($default) { $ret{'_default'} = $code; }
	if($code) { $ret{$code} = $data; }
    }	
    return(%ret);	
	
}

sub makeSafe {
    my($str) = @_;	
    if($str) {
        $str =~ s/<.+?>//gi;
        $str = HTML::Entities::encode($str);
    }
    return($str);
}




1;