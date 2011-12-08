#!/usr/bin/perl -wT

use strict;
use lib "./";

use InhaleCore qw( :DEFAULT timeToRun untaint urlencode );
new InhaleCore;

use InhaleRead qw( getPage getUnit );

my $width = 260;
my $digest = $user->{'userID'};
my $action = $cgi->{'action'} || 'none';
my $render = $cgi->{'render'} || 'inhale';
my $newline = "\n";

if($action eq 'initnoframes1') {
    my $folio  = $cgi->{'folio'};
    my $unit   = $cgi->{'unit'};
    my $page   = $cgi->{'page'};
    my $render = $cgi->{'render'} || 'inhale';
    print $cgi->{'header'};
    print initNoFrames1($folio,$unit,$page,$render,$digest);
    exit;
}

if($action eq 'initnoframes2') { 
    my $folio  = $cgi->{'folio'};
    my $unit   = $cgi->{'unit'};
    my $page   = getPage( page => $cgi->{'page'}, unit => $cgi->{'unit'} );
    my $render = $cgi->{'render'} || 'inhale';

    print $cgi->{'header'};
    print initNoFrames2($folio,$unit,$page,$render,$digest,$cgi->{'page'});
    exit;
}

if($cgi->{'unit'}) {
    my $unit   = getUnit( unit => $cgi->{'unit'} );
    my $page   = getPage( page => $cgi->{'page'}, unit => $cgi->{'unit'} );
    my $rscript = 'frame.pl';
    my $js = '';
    
    if($cgi->{'page'} == 1) {
        $js = "<script language=\"JavaScript\"><!--
		if (self != top) {
		    width = screen.availWidth;
		    height = screen.availHeight;
		    if(height <= 20) { height = 480; }
		    if(width <= 20) { height = 600; }
		    
		    width = width - 100;
		    height = height - 200;

		    window.open('loadpage.pl?max=yes&unit=".$cgi->{'unit'}."&folio=".$cgi->{'folio'}."&page=".$cgi->{'page'}."&render=".$render."','inhale','scrollbars=yes,menubar=yes,directories=yes,toolbar=yes,resizable=yes,status=yes,width=' + width + ',height=' + height + 'screenX=20,screenY=5,top=5,left=20');
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

    if($cgi->{'max'}) {
	$js='';
    }

    my $urlLink = 'folio='. $cgi->{'folio'} .'&render='. $render .'&unit='. $cgi->{'unit'} .'&page='. $cgi->{'page'};
    $urlLink .= '&id='. $digest;

    if($action) { $urlLink .= '&action='.$action; }

    my $unload = 'onUnload="unloading();"';

    $js = "<script language=\"JavaScript\"><!--
    unloaded=0;

    window.moveTo(0,0); 
    if (navigator.appName == 'Microsoft Internet Explorer') { window.resizeTo(screen.availWidth,screen.availHeight); } 
    if (navigator.appName == 'Netscape') { window.outerHeight = screen.availHeight; window.outerWidth = screen.availWidth; }

    function unloading() {
	if(!unloaded) {
//	    alert('the main frameset in being unloaded');
	}
    }

//--></script>
";



### only the left hand frame is an INHALE object - the right hand frame is a remote URL
### ...but the right hand frame URL needs parsing to remove any "frame busting" code

    if($action eq 'noframes') {
        my $left = $rscript . '?object='. $page->{leftFrame} .'&frame=left&'. $urlLink;
        my $right = '';
        if($page->{rightFrame} < 0) {
	    $right = $page->{rightFrameURL};
        }
        elsif($page->{rightFrame} ne '0') {
            $right = 'frame.pl?object='. $page->{rightFrame} .'&frame=main&'. $urlLink;
        }
        elsif($page->{rightFrameURL}) {
	    $right = $page->{rightFrameURL};
	}
        print $cgi->{'header'};
        print '<html><head>'.$newline;
	print '<script LANGUAGE="JavaScript">
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
	print '</script></head><body onLoad="loader();">';
	print '</body></html>';
        
	print 'location: '. 
	exit;
    }

### both frames are INHALE objects
    
    elsif($page->{rightFrame} ne '0') {
        print $cgi->{'header'};
        print '<html><head><title>'. $unit->{unitTitle} .' :: '.$user->{browser}.'</title>'. $js .'</head>'. $newline;
        print '<iframe width="23%" height="650px" id="inhale_left" name="inhale_left" src="'. $rscript.'?object='. $page->{leftFrame} .'&amp;frame=left&amp;'. $urlLink .'"/></iframe>'.$newline;
        print '<iframe width="75%" height="650px" id="inhale_main" name="inhale_main" src="frame.pl?object='. $page->{rightFrame} .'&amp;frame=main&amp;'. $urlLink .'"/></iframe>'.$newline; 
        print noFrames($cgi->{'folio'}, $cgi->{'unit'}).'</html>'. $newline;

   }
    
### only the left hand frame is an INHALE object - the right hand frame is a remote URL

    elsif($page->{rightFrame} eq '0' && $page->{rightFrameURL}) {
        print $cgi->{'header'};
        print '<html><head><title>'.$unit->{unitTitle} .' :: '.$user->{browser}.'</title>'. $js .'</head>'. $newline;
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

print "\n\n<!-- ".timeToRun()." -->\n";

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
    my($folio,$unit,$page,$render,$digest) = @_;

    my $orgRefer = $ENV{HTTP_REFERER};
    }
    
    my $refer = '';
    if($orgRefer) {
        $refer = qq(<p>Alternatively you can <a href="$orgRefer">click here</a>, or use your browser's back button, to return to the previous page.</p>);
    }
    
<<NOFRAMES1;
    
    <html>
    <head>
    <title>Starting unit number $unit</title>
    <script LANGUAGE="JavaScript">
    <!--
    function launchGuide() {
        url = 'loadpage.pl?render=$render&unit=$unit&page=$page&id=$digest&folio=$folio&action=initnoframes2';

        openY = screen.availHeight;
        openY = (openY - 35);
        if(openY > 900) { openY = 900; }
        if(openY < 100) { openY = 350; }
        window.open(url,"guide","width=250,height="+openY+",directories=no,toolbar=no,status=no,resizable=yes,menubar=no,scrollbars=yes,screenX=0,screenY=0,top=0,left=0");
        if(history.length) {
            history.back();
        }
        else {
            self.close();
        }
    }
    // -->
    </script>
    </head>
    <body onLoad="launchGuide();">
    <script LANGUAGE="JavaScript"><!--
        if(history.length) {
            document.write("please click on your browsers' back button to return to the previous page");
        }
        else {
            document.write("please close this window or click on your browsers' back button to return to the previous page");
        }
    // -->
    </script>
    <noscript>
    	<p><b>This unit requires JavaScript and your web browser does not appear to support this.</b></p>
	
	<p>Please <a href="/cgi-bin/printunit.pl?folio=$folio&unit=$unit">click here</a> for a single page version of this unit that does not require JavaScript support.</p>
	
	$refer
    </noscript>
    </body></html>
NOFRAMES1

}

sub initNoFrames2 {
    my($folio,$unit,$page,$render,$digest,$pageNumber) = @_;
    my $urlLink = 'action=noframes&folio='. $folio .'&render='. $render .'&unit='. $unit .'&page='. $pageNumber .'&id='. $digest;

    my($left,$right) = '';
    
    
    if($page->{rightFrame} eq '-1' || $page->{rightFrame} eq '-2') {
        $left  = 'frame.pl?object='. $page->{leftFrame} .'&frame=left&'. $urlLink;
      	$right = 'proxy.pl?url='. urlencode($page->{rightFrameURL}) .'&rep='. abs($page->{rightFrame});
    }  
    
    ### both frames are INHALE objects
        
    elsif($page->{rightFrame} ne '0') {
     $left  = 'frame.pl?object='. $page->{leftFrame} .'&frame=left&'. $urlLink;
     $right = 'frame.pl?object='. $page->{rightFrame} .'&frame=main&'. $urlLink;
    }
        
    ### only the left hand frame is an INHALE object - the right hand frame is a remote URL
    
    elsif($page->{rightFrame} eq '0' && $page->{rightFrameURL}) {
        $left  = 'frame.pl?object='. $page->{leftFrame} .'&frame=left&'. $urlLink;
        $right = $page->{rightFrameURL};
    }

    else { 
        $left  = 'frame.pl?object='. $page->{leftFrame} .'&frame=left&'. $urlLink;
        $right = '/blankpage.html';
    }

    my $cleanUrl = $right;
    my $noFrames = noFrames($folio, $unit, $page);
    
<<NOFRAMES2;
    
<html>
<head><title>guide @ the side</title>
<script LANGUAGE="JavaScript">
<!--

    width=150;
    posX = (width + 10);

    openY = screen.availHeight;
    openX = screen.availWidth;
    openX = (openX - (posX + 12));
    openY = (openY - 82);
    if(openX > 400) { openY = 400; }
    if(openY > 400) { openY = 400; }
    if(openY < 100) { openY = 350; }
    if(openX < 100) { openY = 300; }

    initMain("$cleanUrl");
    self.focus();

    function initMain(url) {
        windowhandle = window.open(url,"inhale_main","width=" + openX + ",height=" + openY + ",directories=no,toolbar=yes,resizable=yes,menubar=no,scrollbars=yes,screenX=" + posX + ",screenY=0,top=0,left=" + posX);
	refocus();
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

// -->
</script>

</head>
<frameset onUnload="closeMain();" onLoad="self.inhale_left.location.href='$left';" frameborder="0" border="0" rows="80%,*">
<frame src="$left" name="inhale_left" scrolling="yes">
</frameset>
$noFrames
</html>

NOFRAMES2
}

sub noFrames {
    my($folio, $unit) = @_;

<<NOFRAMESET

<noframes>
<body>
<p><b>Your web browser does not appear to support framesets</b></p>

<p>Please <a href="/cgi-bin/printunit.pl?folio=$folio&unit=$unit">click here</a> for a single page version of this unit.</p>
</body>
</noframes>

NOFRAMESET


}