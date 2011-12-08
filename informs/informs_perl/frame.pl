#!/usr/bin/perl -wT
  
#####################################################
# RENDER THE CONTENT FOR AN INDIVIDUAL INHALE FRAME #
#####################################################

use strict;

use lib "./";

use InhaleCore qw( :DEFAULT timeToRun getDate untaint );
new InhaleCore;

use InhaleRead qw( getObject getUnit getPage readMetadata );
use InhaleWrite qw( insertStats );
use InhaleRender qw( generateStylesheet inhaleRender inhaleRenderText getPageCache addPageCache );

use HTML::Entities ();

my $frameScript = 'page.pl';
my $fpage  = $cgi->{'page'}   || 0;
my $folio  = $cgi->{'folio'}  || 0;
my $frame  = $cgi->{'frame'}  || 'left';
my $action = $cgi->{'action'} || 'none';
my $render = $cgi->{'render'} || 'inhale';
my $quiz   = $cgi->{'quiz'}   || 0;
my $digest = $user->{'userID'};

my $unitnumber = $cgi->{unit} || 0;

my $customStylesheet = 0;
my $guideTemplate    = $user->{pathToData}."templates/inhale/guide2.html";
my $mainTemplate     = $user->{pathToData}."templates/inhale/main2.html";

if($render =~ /^\d\d\d\d$/) { 
    $customStylesheet = 1; 
    $guideTemplate = $user->{pathToData}."templates/inhale/guide_acc.html";
    $mainTemplate = $user->{pathToData}."templates/inhale/main_acc.html";
} 

if($action eq 'init') { $action = 'none'; }

#######
# second check to see if we're recovering from a pop-up blocker
####

if( $cgi->{'reopen'} ) 
{
    $fpage = $cgi->{'reopen'};

    if( $fpage =~ /^http/ )
    {
        print "Location: $fpage\n\n";
        exit;
    }
}

##################################################
# IF WE HAVE A VALID CACHE OF THE PAGE, USE THAT #
##################################################


my $cacheFile = $folio.'_'.$cgi->value('unit').'_'.$fpage.'_'.$user->{browser}.'_'.$render.'_'.$frame;

# my $cacheFile = $user->{pathToData}.'cache/'.$folio.'_'.$unitnumber.'_'.$fpage.'_'.$user->{browser}.'_'.$render.'_'.$frame.'.txt';

# die $cacheFile;

my $cache = getPageCache( $cacheFile );

if( $cache && !$quiz && !$user->{userNumber} )
{
    $cache =~ s/\@\@\@ID\@\@\@/$digest/g;

    print $cgi->{'header'};
    print $cache;

    my $elapsed = timeToRun();

    print qq(\n\n<!-- \n);
    print qq(\n   userID : ).$user->value('userNumber');
    print qq(\n    fetch : n/a);
    print qq(\n    total : $elapsed seconds);
    print qq(\n     info : ).$folio.'/'.$unitnumber.'/'.$fpage;
    print qq(\n       id : $digest);
    print qq(\n    cache : $cacheFile);
    print qq(\n\n-->\n);

    if( $frame eq 'left' )
    {
        insertStats( session => $digest,
                        unit => $unitnumber,
                        page => $fpage, );
    }

    exit;
}


#########################################
# populate the page/unit/object objects #
#########################################

my %template = ();

my %metadata = readMetadata( unit => $unitnumber );

my %iso3166 = getVocab( vocab => "iso3166-1" );
my %iso639  = getVocab( vocab => "iso639-1" );
my %dewey   = getVocab( vocab => "dewey" );
my %jacs    = getVocab( vocab => "jasc" );

if($metadata{'1.2'}) { $template{dublinCore} .= qq(<meta name="DC.Title" lang="en" content=").makeSafe($metadata{'1.2'}).qq(">\n); }
if($metadata{'1.4'}) { $template{dublinCore} .= qq(<meta name="DC.Description" lang="en" content=").makeSafe($metadata{'1.4'}).qq(">\n); }
if($metadata{'1.3a'} && $metadata{'1.3b'}) { $template{dublinCore} .= qq(<meta name="DC.Language" scheme="RFC1766" content=").makeSafe($metadata{'1.3a'}).'-'.makeSafe($metadata{'1.3b'}).qq(">\n); }
if($metadata{'9.1disc'}) { $template{dublinCore} .= qq(<meta name="DC.Subject" scheme="DDC" content=").makeSafe($metadata{'9.1disc'}).qq(">\n); }
if($metadata{'9.1disc2'}) { $template{dublinCore} .= qq(<meta name="DC.Subject" scheme="JACS" content=").makeSafe($metadata{'9.1disc2'}).qq(">\n); }
$template{dublinCore} .= qq(<meta name="DC.Relation.IsPartOf" scheme="URI" content="$user->{pathToCGI}portfolio.pl?folio=$folio">\n);
$template{dublinCore} .= qq(<meta name="DC.Identifier" scheme="URI" content="$user->{pathToCGI}jump.pl?$folio:$unitnumber">\n);
$template{dublinCore} .= qq(<meta name="DC.Format" scheme="IMT" content="text/html">\n);
$template{dublinCore} .= qq(<meta name="DC.Type" lang="DCMIType" content="Tutorial">\n);
$template{dublinCore} .= qq(<meta name="DC.Creator" content="$user->{accountTitle}">\n);
$template{dublinCore} .= qq(<meta name="DC.Publisher" content="Informs, UK">\n);

my $object   = getObject( object => $cgi->{'object'} );
my $unit     = getUnit( unit => $unitnumber, folio => $folio );
my $page     = getPage( page => $fpage, unit => $unitnumber );


#######
# second check to see if we're recovering from a pop-up blocker
####

if( $fpage != $cgi->{'page'} && $page->{'rightFrameURL'} =~ /^http/ )
{
    print "Location: ".$page->{'rightFrameURL'}."\n\n";
    exit;
}

my $fetch = timeToRun();

{
    my $check = $cgi->{'object'} || 0;
    if($check != $page->{leftFrame} && $check != $page->{rightFrame} && $page->{rightFrame}) { InhaleCore::error("object $cgi->{object} does not form part of page $cgi->{page} of unit $unitnumber", 'database'); }
}

my $urlLink  = 'render='. $render .'&amp;unit='. $unit->{unitNumber} .'&amp;folio='. $folio . '&amp;id='. $digest;

if($action) { $urlLink .= '&amp;action='.$action; }


my $newline = "\n";

##################################################
# render the left hand "guide at the side" frame #
##################################################

if($frame eq 'left')
{

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon++;

    unless( $user->{userNumber} )
    {    
        insertStats( session => $digest,
                        unit => $unitnumber,
                        page => $fpage, );
    }
   
    print $cgi->{'header'};

    open(TEMPLATE, $guideTemplate) || die;
    my @template = <TEMPLATE>;
    close(TEMPLATE);    

    $template{'javascriptOnLoad'} = '';
    $template{'javascript'} = '';
    $template{'editLink'} = '';
    $template{'netscapeMargin'} = '';
    $template{'contents'} = '';
    $template{'characterEncoding'} = $object->{encoding} || 'ISO-8859-1';
    
    if($user->{browser} =~ /NETSCAPE4/) { $template{'netscapeMargin'} = 'marginheight="0" marginwidth="0" topmargin="0" bottommargin="0" rightmargin="0" leftmagin="0"'; }
    
    my $showCollapseBar = 0;


    if($user->{browser} =~ /(IE5|IE4|IE6|IE+)/i && $action ne 'noframes') {
  #      $showCollapseBar = 1;    
  #      $template{'javascriptOnLoad'} = "toggle('button1'); ".$template{'javascriptOnLoad'};
  #      $template{'toolbar'} .= qq(<td valign="top" align="left" width="100%"><a href="#" onclick="return false;"><img height="21" width="20" onclick="toggle('button1');" name="button1" border="0" src="$user->{pathHtmlVir}gfx/b2.gif" alt="toggle the guide to free up more screen space or to show the guide" /></a></td>);
    }
    else { $template{'toolbar'} .= qq(<td valign="top" align="left" width="100%"><img src="$user->{pathHtmlVir}gfx/cthru.gif" height="1" width="1" /></td>); }


    $template{'javascript'} .= javascriptContents();
    if($cgi->{page} eq '1'){ 
    $template{'toolbar'} .= qq(<td align="right"><a href="displaytip.pl?object=4&amp;render=$render" target="help" onclick="window.open('displaytip.pl?object=4&amp;render=$render', 'help', 'toolbar=yes,scrollbars=yes,width=400,height=400');">  Help </a></td>\n);
    }

    if($page->{contents}) {

        $template{'toolbar'} .= qq(<td align="right"><a href="javascript:toggleTOC('TOC');"> Contents</a></td>);

        my @pages = split(/\t/, $page->{contents});
        my @links = ();
        @pages = sort(@pages);
        
        $template{'contents'} .= qq(<div id="TOC" class="article"><table width="100%" bgcolor="white" bordercolor="black" border="1" cellpadding="7" cellspacing="0"><tr>);
        $template{'contents'} .= qq(<td><font size="2"><b>contents:</b>\n);
        if($cgi->{page} eq '1') { $template{'contents'} .= qq(<br />&nbsp;&#149;&nbsp;introduction page\n); }
 
        else { 
            my $target = '_top';
            if($action ne 'none') { $target = '_self'; }
            $template{'contents'} .= qq(<br />&nbsp;&#149;&nbsp;<a href="page.pl?unit=$unitnumber&amp;action=$action&amp;page=1&amp;folio=$folio&amp;id=$digest&amp;org=contents" target="$target">introduction page</a>\n); 
        }

        foreach (0 .. scalar(@pages) - 1) {
            my($page, $parent, $text) = split(/\=/, $pages[$_], 3);
            my $img = 'c2';
            if($_ == scalar(@pages) - 1) { $img = 'c3'; }
            
            $page =~ s/^0*//gi;
 
            if($page eq $cgi->{page}) { 
                $template{'contents'} .= qq(<br />&nbsp;&#149;&nbsp;$text);
            }
            else {
                my $target = '_self';
                if($action eq 'none') { $target = '_top'; }
                if($parent && $action eq 'none') { $target = '_top'; }
                
                $template{'contents'} .= qq(<br />&nbsp;&#149;&nbsp;<a href="page.pl?unit=$unitnumber&amp;action=$action&amp;page=$page&amp;folio=$folio&amp;id=$digest&amp;org=contents" target="$target">$text</a>\n);
            }
        }

        $template{'contents'} .= qq(<div align="right"><a href="#" onclick="hide('TOC'); return false;"><img src="$user->{pathHtmlVir}gfx/up.gif" alt="hide the Table of Contents" align="bottom" border="0" /></a></div>);
        $template{'contents'} .= qq(</font></td></tr></table></div>);
      }


    $template{'toolbar'} .= qq(<td align="right"><a href="printunit.pl?unit=$unitnumber&amp;folio=$folio&amp;id=$digest" target="_blank"> Print</a></td>\n);

    $template{'cssLink'} = generateStylesheet( $render , '', $folio, $unit->{userStylesheet});

    my $nextPageText = 'next step >>';
    my $prevPageText = '<< previous step';

    if($page->{pageNumber} == 1) {
        $template{'pageInfo'} = '';
        $nextPageText = 'continue >>';    
    }
    else {
        $template{'pageInfo'} = '(step '. ($page->{pageNumber} - 1) .' of '. ($page->{totalPages} - 1) .')';
        if($page->{pageNumber} == 2) {
            $prevPageText = '<< introduction';
        }
    }

    $template{'heading'} = $unit->{folioUnitTitle};

    $template{'previousOnClick'} = 'parent.unloaded=1;';
    $template{'nextOnClick'} = 'parent.unloaded=1;';

    if($page->value('pageNumber') eq '1') {
        $template{'previousLink'} = qq(portfolio.pl?id=$digest&amp;folio=).$cgi->value('folio').qq(&amp;render=$render);
	
    if(open(IN,"./temp/".untaint($digest, 4).".txt")) { 
            $template{'previousLink'} = <IN>;
            close(IN);
        }
        $template{'previousTarget'} = '_top';
        $template{'previousTargetJS'} = 'top';
    }
    elsif($page->value('prevRightFrame') eq '0' && $page->value('prevRightFrameURL') eq '') {
        $template{'previousLink'} = $frameScript.'?'. $urlLink .'&amp;page='. $page->value('prevPageNumber');
        #$template{'previousTarget'} = 'inhale_left';
        $template{'previousTarget'} = '_self';
        $template{'previousTargetJS'} = 'self';
        $template{'previousTitle'} = $prevPageText;
    }
    else {
        $template{'previousLink'} = $frameScript.'?'. $urlLink .'&amp;page='. $page->value('prevPageNumber');
        $template{'previousTarget'} = '_parent';
        $template{'previousTargetJS'} = 'top';
        $template{'previousTitle'} = $prevPageText;
    }

    if($page->value('nextRightFrame') eq '') {
        $template{'nextLink'} = qq(portfolio.pl?id=$digest&amp;folio=).$cgi->value('folio').qq(&amp;render=$render);
        if(open(IN,"./temp/".untaint($digest, 4).".txt")) { 
            $template{'nextLink'} = <IN>;
            close(IN);
        }
        $template{'nextTarget'} = '_top';
        $template{'nextTargetJS'} = 'top';
### last page
    }
    elsif($page->value('nextRightFrame') eq '0' && $page->value('nextRightFrameURL') eq '') { 
        $template{'nextLink'} = $frameScript.'?'. $urlLink .'&amp;page='. $page->value('nextPageNumber');
        $template{'nextTarget'} = '_self';
        $template{'nextTargetJS'} = 'self';
        $template{'nextTitle'} = $nextPageText;
    }
    else { 
        $template{'nextLink'} = $frameScript.'?'. $urlLink .'&amp;page='. $page->value('nextPageNumber');
        $template{'nextTarget'} = '_parent';
        $template{'nextTargetJS'} = 'top';

        $template{'nextTitle'} = $nextPageText;
    }

    if($action eq 'noframes') {
        $template{'javascriptToggle'} = '';

        $template{'previousTarget'} = '_self';
        $template{'previousTargetJS'} = 'self';
        $template{'previousLink'} = $frameScript.'?'. $urlLink .'&amp;page='. $page->value('prevPageNumber');
        $template{'previousTitle'} = $prevPageText;
  
        $template{'nextTarget'} = '_self';
        $template{'nextTargetJS'} = 'self';
        $template{'nextLink'} = $frameScript.'?'. $urlLink .'&amp;page='. $page->value('nextPageNumber');
        $template{'nextTitle'} = $nextPageText;

        if($page->{pageNumber} eq '1') {
            $template{'previousLink'} = '#';
            $template{'previousOnClick'} = 'parent.close();';
        }
        if($page->value('nextRightFrame') eq '') {
            $template{'nextLink'} = '#';
            $template{'nextOnClick'} = 'parent.close();';
        }
   }


###############################################
# pick up and render the frame content object #
###############################################

    if($page->{leftFrame}) {
        $template{'content'} = inhaleRender( object => $object,
                                                cgi => $cgi, 
                                               user => $user,
                                             target => 'inhale_main', 
                                            headers => -1,
					  customCSS => $unit->{userStylesheet},
                                             render => $render );
    }
    else {
        my $text = '<p>You have opened an Informs tutorial. This is an online tool that allows you to learn using live online resources.</p>
		<p>The tutorials are displayed in two panes:</p>
		<ul>
		<li>The left pane which contains your instructions.</li>
		<li>The main window, which contains the resource.</li>
		</ul>
		<p>Read the introduction to this tutorial on the right, and then [a]click on[/a] [q]'.$nextPageText.'[/q]...</p>';
        if($showCollapseBar) {
            $text .= '<p />[o]1[/o]';
        }

        $template{'content'} = inhaleRenderText( text => $text,
                                                  cgi => $cgi, 
                                                 user => $user, 
                                               target => 'inhale_main', 
                                              headers => -1, 
                                               render => $render );
    }

    if($action eq 'noframes') 
    {
	$template{'content'} = qq(
		<script type="text/javascript" language="JavaScript">
		    var isMainWindowOpen = parent.checkMain( );
		    if( isMainWindowOpen == false ) {
			document.write('<p /><div style="font-weight:bold; border:1px solid #cccccc; padding:5px 10px;"><a href="#" onClick="parent.initMain($cgi->{page}); return false;">Please click here to open the main browser window</a></div><p />');
		    }
		</script>\n) . $template{'content'};
    }

    my $output = '';

######
# display the template
###

    foreach my $line (@template) {
        while($line =~ /\{\{/ && $line =~ /\}\}/) {
            my($a, $b) = split(/\{\{/, $line, 2);
            my($c, $d) = split(/\}\}/, $b, 2);
            my $replace = "<!-- $c not found -->";
            if(defined($template{$c})) { $replace = $template{$c}; }
            $line = $a.$replace.$d;
        }
	$output .= $line;
    }
    print $output;

    my $elapsed = timeToRun();

    print qq(\n\n<!-- );
    print qq(\n   userID : ).$user->value('userNumber');
    print qq(\n    fetch : $fetch seconds);
    print qq(\n    total : $elapsed seconds);
    print qq(\n     info : ).$cgi->value('folio').'/'.$unit->value('unitNumber').'/'.$page->value('pageNumber');
    print qq(\n       id : $digest);
    print qq(\n\n-->\n);

    $output =~ s/$digest/\@\@\@ID\@\@\@/g;

    unless( $user->{userNumber} ) 
    {   
   #     addPageCache( $cacheFile, \$output );
    }

}


#########################
# render the main frame #
#########################

if($frame eq 'main') {

    open(TEMPLATE, $mainTemplate) || die;
    my @template = <TEMPLATE>;
    close(TEMPLATE);
    
    $template{'cssLink'} = generateStylesheet( $render , '', $folio, $unit->{userStylesheet} );
    $template{'javascriptRefreshPage'} = javascriptReloadPage();
    $template{'javascriptOnLoad'} = '';
    $template{'characterEncoding'} = $object->{encoding} || 'ISO-8859-1';
    $template{'content'} = inhaleRender( object => $object,
                                            cgi => $cgi, 
                                           user => $user, 
                                         target => 'inhale_main',
				      customCSS => $unit->{userStylesheet},
                                        headers => -1, 
                                        render => $render );

    if($template{content} =~ /\<\!-- use template --\>/) {

         print "Content-Type: text/html; charset=$template{'characterEncoding'}\n\n";

	my $output = '';

        foreach my $line (@template) {
            while($line =~ /\{\{/ && $line =~ /\}\}/) {
                my($a, $b) = split(/\{\{/, $line, 2);
                my($c, $d) = split(/\}\}/, $b, 2);
                my $replace = "<!-- $c not found -->";
                if(defined($template{$c})) { $replace = $template{$c}; }
                $line = $a.$replace.$d;
            }
            $output .= $line;
        }
	print $output;

        my $elapsed = timeToRun();

        print qq(<!-- \n\n);
        print qq(   userID : ).$user->value('userNumber');
        print qq(\n    fetch : $fetch seconds);
        print qq(\n    total : $elapsed seconds);
        print qq(\n     info : ).$cgi->value('folio').'/'.$unit->value('unitNumber').'/'.$page->value('pageNumber');
        print qq(\n       id : $digest);
        print qq(\n-->\n);

        $output =~ s/$digest/\@\@\@ID\@\@\@/g;

        unless( $user->{userNumber} ) 
        {   
         #   addPageCache( $cacheFile, \$output );
        }

    }
    elsif($template{content} =~ /^Location/i) {
        print $template{content};
        exit;
    }
    else {
        print $cgi->{'header'};
        print "not sure what to do here!";
	print $template{content};
    }

}

end InhaleCore;

sub javascriptContents {

<<_INLINE_BLOCK_1_0

    var TOCstatus = 0;
    var obj = '';

    function toggleTOC(object) {

        if(TOCstatus) {
            hide(object);
        }
        else {
            show(object);
            obj = object;
//            setTimeout('hide(obj)', 1000);
        }
    }

    function show(object) {
        TOCstatus = 1;

        if(document.getElementById) {
                document.getElementById(object).style.visibility = 'visible';
        }               
        else if (document.layers && document.layers[object] != null) {
            document.layers[object].visibility = 'visible';
        }    
        else if (document.all) {
            document.all[object].style.visibility = 'visible';
        }
    }
    function hide(object) {
        TOCstatus = 0;
        if(document.getElementById) {
                document.getElementById(object).style.visibility = 'hidden';
        }               
        else if (document.layers && document.layers[object] != null) {
            document.layers[object].visibility = 'hidden';
        }    
        else if (document.all) {
             document.all[object].style.visibility = 'hidden';
        }
    }

_INLINE_BLOCK_1_0

}    

sub javascriptReloadPage {
<<JS1
<script type=\"text/javascript\" language=\"JavaScript\"><!--
var windowStillOpen = 1;
    function refreshThePage() {
//          window.location.reload(true);

        if (document.layers) {
            location.reload(); 
        }
        else { 
            window.location.reload(); 
        }
    }
//-->
</script>

JS1
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