#!/home/zzintadm/perl/bin/perl -WT

use strict;
use lib "./";
use locale;


use Digest::MD5 qw(md5_hex);

use InhaleCore qw( :DEFAULT convertDate getDate convertTags );
unless( new InhaleCore ) { deadParrot("access to this page is restricted to authorised users only!!"); }

use InhaleRender qw( :render clearCache );

use InhaleRead qw( getUnit getPage getObject getObjectData getAccountDetails getFolioDetails getUserInfo);
use InhaleWrite qw( movePage deletePage insertEmptyObject insertNewPage updateObject updatePage updatePortfolio copyObject );

unless( $user->{userNumber} ) { deadParrot("access to this page is restricted to authorised users only"); }

my $unitNo = $cgi->{unit}   || deadParrot('the following parameter is missing from your request: "unit"');
my $folio  = $cgi->{folio}  || deadParrot('the following parameter is missing from your request: "folio"');
my $pageNo = $cgi->{page}   || '';
my $action = $cgi->{action} || '';

my $unit = getUnit( unit => $unitNo, folio => $folio );
my $onLoad = '';
my %folioInfo = getFolioDetails( folio => $folio ); 

if($action eq 'jump') {
    $onLoad = qq(onLoad = "jumpOnLoad($pageNo);");
    $pageNo = '';
}


if($action eq 'delete') {
    print $cgi->{header};
    print pageHeader($onLoad);

    my $page = getPage( page => $pageNo, unit => $unitNo );

    my $object = getObject( object => $page->{leftFrame} );

    my $txtbox = getObjectData( object => $object );
$txtbox =~ s/[\n]/<br \/>/gi;
    my $content = inhaleRender( object => $object, 
                                   cgi => $cgi, 
                                  user => $user, 
                                target => '_self', 
                               headers => -1, 
                                render => 'inhale' );

    $content =~ s/\<p\>$//gi;
    $content =~ s/\<form /\<xform /gi;
    $content =~ s/\<\/form/\<\/xform/gi;

    my $content2 = $content;
    $content2 =~ s/\<.+?\>//gi;
    $content2 =~ s/\s//gi;
    if(!$content2) { $content = '<div align="left" style="color:#007F71; font-size:125%;"><b>this page is currently empty</b></div></body></html>'; }

    print "<b>You are about to delete the page shown below from the unit</b>";
    
    print "<p />Please confirm that you wish to delete the page by selecting one of the options:";
    
    my $digest = md5_hex($unitNo, $pageNo, $folio, $user->{userNumber});
    
    print q(<p /><br /><div align="left"><table><tr>);
    print qq(<td><a href="editunit.pl?folio=$folio&unit=$unitNo&page=$pageNo&action=confirm&b=$digest"><img src="/gfx/deleteunityes.gif" border="0" alt="YES - delete this page"></a></td><td>&nbsp;&nbsp;&nbsp;</td>);
    print qq(<td><a href="editunit.pl?folio=$folio&unit=$unitNo#$pageNo"><img src="/gfx/deleteno.gif" border="0" alt="NO - do not delete this page"></td></tr></table>);

    print qq(<p /><br /><p /><div align="left"><table width="80%" cellpadding="0" cellspacing="0" class="box"><tr><td class="preview">$content</td></tr></table></div>);
    goto ENDFLAG;

}


if($action eq 'global') {
    my $descboxMD5 = md5_hex($cgi->{'descbox'});
    my $checksum = md5_hex($cgi->{unit}, $cgi->{folio}, $user->{accountTitle}, $user->{userNumber}, length($user->{accountTitle}));
    
    if($checksum ne $cgi->{checksum}) { die "checksum $cgi->{checksum} ne $checksum"; }

    if($unit->{folioDescription} ne $cgi->{'descbox'} || $descboxMD5 ne $cgi->{descboxchk}) {
        updatePortfolio($cgi->{folio}, 'setDescription', $cgi->{unit}, $cgi->{'descbox'});
    }

    if($cgi->{'utitle'} ne $unit->{folioUnitTitle}) {  
        updatePortfolio($cgi->{folio}, 'renameUnit', $cgi->{unit}, $cgi->{'utitle'});
    }

    if($cgi->{'uvis'} ne $unit->{folioVisibility}) {
        my $action = 'hide';
        if($cgi->{uvis} eq 'Y') { $action = 'unhide'; }
        updatePortfolio($cgi->{folio}, $action, $cgi->{unit});
    }

    if($cgi->{'uopen'} > 0 && $cgi->{'uopen'} < 3 && $cgi->{'uopen'} ne $cgi->{'upopen'}) { 
        updatePortfolio($cgi->{folio}, 'openMethod', $cgi->{unit}, $cgi->{'uopen'});
    }

    clearCache( $unitNo );
    print qq(Location: $user->{pathToCGI}editunit.pl?folio=$folio&unit=$unitNo\n\n);

    exit;
}

if($action eq 'confirm')
{
    my $digest = md5_hex($unitNo, $pageNo, $folio, $user->{userNumber});
    if($digest eq $cgi->{'b'}) {
        my $unit = getUnit( unit => $unitNo, folio => $folio );
        deletePage( unit=>$unitNo, page=>$pageNo );
	clearCache( $unitNo );
        if($pageNo == $unit->{totalPages}) { $pageNo--; }
        print qq(Location: $user->{pathToCGI}editunit.pl?folio=$folio&unit=$unitNo&action=jump&page=$pageNo\n\n);
        goto ENDFLAG;
    }
    else {
        $pageNo = '';
    }
}

if($action eq 'move') {
    my $moveTo = $cgi->{'b'};
    if($moveTo != $pageNo && $moveTo > 1 && $moveTo <= $unit->{totalPages}) {
        movePage($unitNo, $pageNo, $moveTo);
        clearCache( $unitNo );
        print qq(Location: $user->{pathToCGI}editunit.pl?folio=$folio&unit=$unitNo&action=jump&page=$moveTo\n\n);
        goto ENDFLAG;
    }
    else { die "move failed unit = $unitNo / page = $pageNo / moveTo = $moveTo"; }
}

if($action eq 'insert') {
    my( $newObjID, $newFilename ) = insertEmptyObject( account => $user->{userAccountNumber} );
    $pageNo++;  
    insertNewPage( page=> $pageNo, unit => $unitNo, objectLeft => $newObjID );
    clearCache( $unitNo );
    print qq(Location: $user->{pathToCGI}editunit.pl?folio=$folio&unit=$unitNo&action=jump&page=$pageNo\n\n);
    goto ENDFLAG;
}


if($action eq 'edit') {
    
    my $check = md5_hex($unitNo, $pageNo, $user->{userNumber}, getDate());

    if($cgi->{s} ne $check) 
    {
        print $cgi->{header};
        print qq(<html><body><h1>502 - Authentication Error</h1>);
        print qq(<p />Your request has generated an authentication error.<p />Please use your web browser's back button to return to the previous page and then manually refresh that page to ensure it is valid.);
        print qq(<p />If the error continues, please contact <a href="mailto:andrew.priest\@manchester.ac.uk">andrew.priest\@manchester.ac.uk</a></body></html>);
        exit;
    }
    

    if($cgi->{'txtmd5'}) { 
        my $checksum = md5_hex($unitNo, $pageNo, $cgi->{txtmd5}, $folio);
        my $page = getPage( page => $pageNo, unit => $unitNo );

        if($cgi->value('url') =~ /^\s*$/) { $cgi->{url} = ''; }
        if($cgi->value('toc') =~ /^\s*$/) { $cgi->{toc} = ''; }

        clearCache( $unitNo );

        if($checksum eq $cgi->{'checksum'}) 
        {
            my $objectNumber = $page->{leftFrame};
            if($pageNo == 1) { $objectNumber = $page->{rightFrame}; }
            my $object = getObject( object => $objectNumber );
            my $txtmd5 = md5_hex($cgi->{'txtbox'});
            if($txtmd5 ne $cgi->{txtmd5}) 
	    {
                my $owner = $object->{ownerNumber}; 
                if( $user->{userPortfolioList} =~ /:$owner:/) {
                    updateObject( $objectNumber, $cgi->{'txtbox'}, $object->{description});
                    InhaleWrite::audit('unit', $cgi->{'unit'}, "object #$objectNumber of page #$cgi->{'page'} edited");
                }
                else { 

                    my $new = copyObject( content => $cgi->{'txtbox'}, 
                                           object => $object,
                                          account => $user->{userAccountNumber}, 
                                             page => $page );

                    updatePage( replace => $object->{objectNumber},
                                   with => $new,
                                   page => $page );
                                              
                    InhaleWrite::audit('unit', $cgi->{'unit'}, "new object #$new created from object #$objectNumber owned by account #$owner");
                }
            }
        }

	if($pageNo > 1) {
   	    if($cgi->{'url'} > 0) { 
                updatePage( page => $page, url => "", right => $cgi->{'url'} ) 
	    }
	    elsif($cgi->{'url'} eq "") { 
                updatePage( page => $page, url => "", right => '0' ) 
	    }

            elsif($page->{rightFrameURL} ne $cgi->{'url'}) { 
                updatePage( page => $page, url => $cgi->{'url'} , right => '0' ) 
            }
        
            if($page->{heading} ne $cgi->{'toc'}) { 
                updatePage( page => $page, toc => $cgi->{'toc'} ) 
            }
        }
        
        if($cgi->{'thebutton'} =~ /finish/) {
            print qq(Location: $user->{pathToCGI}editunit.pl?folio=$folio&unit=$unitNo&action=jump&page=$pageNo\n\n);
            goto ENDFLAG;
        }
        else {
            print qq(Location: $user->{pathToCGI}editunit.pl?folio=$folio&page=$pageNo&unit=$unitNo&action=edit&s=$check\n\n);
            goto ENDFLAG;
        }
    }    
    
    print $cgi->{header};
    print pageHeader($onLoad);    
    my $unitTitle = convertTags($unit->{folioUnitTitle});   
    my $title = 'step '.($pageNo - 1);
    my $page = getPage( page => $pageNo, unit =>$unitNo );
    my $objectNumber = $page->{leftFrame};

    if($pageNo == 1) { 
        $objectNumber = $page->{rightFrame}; 
        $title = 'introduction page';
    }

    my $object = getObject( object => $objectNumber );
    my $txtbox = getObjectData( object => $object );
    my $txtmd5 = md5_hex($txtbox);
    
    $txtbox = convertTags($txtbox);

    my $checksum = md5_hex($unitNo, $pageNo, $txtmd5, $folio);
    
    my $extra = '';
    
    if($pageNo > 1) {
        my $url = convertTags( $page->value('rightFrameURL') );
        my $obj = $page->value('rightFrame');

	if($obj =~ /^\d\d*$/ && $obj > 0) {
            $extra .= qq(<dd>&nbsp;</dd><dt>Optional URL/object ID number associated with this step:</dt><dd><input size="50" type="text" name="url" value="$obj" class="fixed" />);
            $extra .= qq(&nbsp;-&nbsp;<font size="2">[ <a href="#" onClick="window.open('displayobject.pl?object=' + document.theform.url.value, 'help', 'resizable=yes,menubar=yes,scrollbars=yes,status=yes,width=400,height=300');">preview object</a> ]</font></dd>);
 	}
 	else {
            $extra .= qq(<dd>&nbsp;</dd><dt>Optional URL associated with this step:</dt><dd><input size="40" type="text" name="url" value="$url" class="fixed" />);
      }

        my $toc = $page->value('heading');
        $extra .= qq(<dd>&nbsp;</dd><dt>Optional entry for the Table of Contents:</dt><dd><input size="40" type="text" name="toc" value="$toc" class="fixed" /></dd>);
    }
    
    my $content = inhaleRender( object => $object, 
                                   cgi => $cgi, 
                                  user => $user, 
                                target => '_self', 
                               headers => -1, 
                                render => 'inhale' );


        print <<HTML2;

<b>unit number $unitNo - "$unitTitle"</b>
<p />
<form enctype="multipart/form-data" action="editunit.pl" method="post" name="theform" onSubmit="return clickedButton;">
<input type="hidden" name="page" value="$pageNo">    
<input type="hidden" name="unit" value="$unitNo">    
<input type="hidden" name="folio" value="$folio">
<input type="hidden" name="action" value="edit">
<input type="hidden" name="txtmd5" value="$txtmd5">
<input type="hidden" name="checksum" value="$checksum">
<input type="hidden" name="s" value="$check">

<p>

<div align="left"><table cellpadding="8" cellspacing="0" width="100%" class="box" border="1px" bordercolor="#cccccc">
<tr><td align="left" colspan="2" class="boxhead"><b>$title</b></td></tr>
<tr><td><table cellpadding="2" cellspacing="0" width="100%" border="0">
    
<tr><td align="center">

<br />
<table cellpadding="0" cellspacing="0" border="0"><tr>
<td valign="top"><textarea cols="130" rows="19" name="txtbox" class="fixed" onkeyup="mtShortCuts();">$txtbox</textarea></td>
<td valign="top"> 

</td></tr></table>
<p />

<div align="left" fontsize:"smaller" font-style:"italic" padding:5px>
<p>
<h3 style="font-style:italic; font-size:small">You can also use the following tags for additional options in your tutorial:</h3>
<ul>
<li style="padding:5px; font-style:italic; font-size:small">
[k] Task Box: this tag displays the enclosed text in a box to indicate a task that you want the user to perform e.g.<br />
[k]think of several useful keywords and write them down[/k]
</li>
<li style="padding:5px; font-style:italic; font-size:small">
[t] Tip: this tag displays the enclosed text a "tip" and is displayed in a box.   An optional tip title can be specified within the opening tag e.g.
<br />
[t:copying text]press CTRL and C to copy the highlighted text[/t]<br />
[t]contact Tech Support to activate your account[t]
</li>
<li style="padding:5px; font-style:italic; font-size:small">
[z] Quiz: this tag inserts a self-assessed question and answer into the page - the answer should be specified within the opening tag e.g.<br />
[z:Paris]in which city does the Eiffel Tower stand?[/z]
</li>
</ul>
</div>

<input type="submit" name="thebutton" value="submit changes" class="submit" onClick="clickedButton=true" />
&nbsp;
<input type="submit" name="thebutton" value="finish editing" class="submit" onClick="clickedButton=true" />
<p />

<div align="left"><dl >
$extra
</dl></div>
</td></tr>
</table>
</form>
</td></tr>
<tr><td class="preview">$content</td></tr>
</table>

HTML2

}

if($unitNo && !$pageNo) {
    print $cgi->{header};
    print pageHeader($onLoad);
    

    my $totalPages = $unit->{totalPages};
    my $descbox = $unit->{folioDescription};
    my $descboxCHK = md5_hex($descbox);
    my $title = convertTags($unit->{folioUnitTitle});
    my $cssurl = $unit->{userStylesheet} || 'none';
    my $checksum = md5_hex($cgi->{unit}, $cgi->{folio}, $user->{accountTitle}, $user->{userNumber}, length($user->{accountTitle}));
    
    print qq(<b>unit number $unitNo - "$title"</b><p />);
    print qq(<a href="http://www.informs.intute.ac.uk/informs_perl/jump.pl?$folio-$unitNo">Preview this unit</a>\n);
    print qq(<form action="editunit.pl" method="post">\n);
    print qq(<input type="hidden" name="folio" value="$cgi->{folio}">\n);
    print qq(<input type="hidden" name="unit" value="$cgi->{unit}">\n);
    print qq(<input type="hidden" name="action" value="global">\n);
    print qq(<input type="hidden" name="checksum" value="$checksum">\n);
    print qq(<input type="hidden" name="descboxchk" value="$descboxCHK">\n);

    print qq(<div align="left"><table cellpadding="8" cellspacing="0" width="90%" class="box" >);
    print qq(<tr><td align="left" colspan="2" class="boxhead"><h2>global options for this unit</h2></td></tr>);
    print qq(<tr><td><table cellpadding="2" cellspacing="0" width="100%" border="0">);
    
    print qq(<tr><td align="right" width="30%">title of unit:</td><td><input type="text" name="utitle" value="$title" size="50" class="fixed"></td></tr>);

    print qq(<tr><td align="right" valign="top">optional brief description:</td><td><textarea cols="48" rows="6" name="descbox" class="fixed">$descbox</textarea></td></tr>);

    print qq(<tr><td align="right">open unit in:</td><td><select class="edit" name="uopen">);
    if($unit->{folioOpenMethod} eq 'noframes+js') { print qq(<option value="1">iframes</option><option value="2" selected>two separate windows</option></select><input type="hidden" name="upopen" value="2">); }
    else { print qq(<option value="1" selected>iframes</option><option value="2">two separate windows</option></select><input type="hidden" name="upopen" value="1">); }
    print qq(</td></tr>);

    print qq(<tr><td align="right">status is currently:</td><td><select class="edit" name="uvis">);
    if(lc($unit->{folioVisibility}) eq 'y') { print qq(<option value="N">hidden / draft</option><option value="Y" selected>visible / available</option></select>); }
    else { print qq(<option value="N" selected>hidden / draft</option><option value="Y">visible / available</option></select>); }
    print qq(</td></tr>);

    print qq(<tr><td align="right" width="30%">custom CSS link:</td><td><span style="font-size:90%">$cssurl</span></td></tr>);

    print qq(<tr><td>&nbsp;</td></tr><tr><td></td><td align="left"><input type="submit" value="update global options" class="submit"></td></tr></table></td></tr></table></div></form>);


    print qq(<p /><br /><h2>this unit contains $totalPages pages:</h2><ul class="edit">);

    {
        my $page = getPage( page => 1, unit => $unitNo );
        my %contents = ();
    
        if($page->{contents}) {
            my @a = split(/\t/, $page->{contents});
            foreach (@a) {
                my @b = split(/\=/);
                $b[0] =~ s/^0*//gi;
                $contents{$b[0]} = " - ".$b[2];
            }
        }

        foreach my $pageNo (1 .. $totalPages) {
            my $pageName = 'introduction page';
            if($pageNo > 1) { $pageName = 'step number '.($pageNo-1); }
            my $check = md5_hex($unitNo, $pageNo, $user->{userNumber}, getDate());
            my $contents = $contents{$pageNo} || '';
            print qq(<li>[ <a href="editunit.pl?folio=$cgi->{folio}&unit=$cgi->{unit}&page=$pageNo&action=edit&s=$check">edit</a> ] - <a href="#$pageNo">$pageName</a>$contents</li>);
        }
    }
    
    print "</ul>";

    foreach my $pageNo (1 .. $totalPages) {
        my $page = getPage( page => $pageNo, unit => $unitNo);
        
        my $pageName = 'introduction page';
        if($pageNo > 1) { $pageName = 'step number '.($pageNo-1); }

        my $check = md5_hex($unitNo, $pageNo, $user->{userNumber}, getDate());
        
        my $content = '';
        my $objectNumber = '';
        my $object = '';
    
        if($pageNo == 1) {
            $object = getObject( object => $page->{rightFrame} );
            $objectNumber = $page->{rightFrame};
            my $txtbox = getObjectData( object => $object );
            $content = inhaleRender( object => $object, 
                                        cgi => $cgi, 
                                       user => $user, 
                                     target => '_self', 
                                    headers => -1, 
                                     render => 'inhale');
        }
        else {
            $object = getObject( object => $page->{leftFrame} );
            $objectNumber = $page->{leftFrame};
            my $txtbox = getObjectData( object => $object );
            $content = inhaleRender( object => $object, 
                                        cgi => $cgi, 
                                       user => $user, 
                                     target => '_self', 
                                    headers => -1, 
                                     render => 'inhale');
        }

        my $ownerName = 'this portfolio';
        if($object->{ownerNumber} == $user->{userAccountNumber}) { $ownerName = qq(your account: "$user->{userAccountName}"); }
        else { 
            my %acc = getAccountDetails( user => $object->{ownerNumber}, session => 'null' );
            $ownerName = qq(account #$object->{ownerNumber}: "$acc{userAccountName}");
        }

        my $info = "this page uses database object number ".$object->{objectNumber}." (owned by $ownerName) ";
        $info .= "and was last edited on ".convertDate( time => $object->{timeStamp}, format => 'dd/mon/yyyy' ).' at '.convertDate( time => $object->{timeStamp}, format => 'hh:mm am/pm' );


        $content =~ s/\<p\>$//gi;
        $content =~ s/\<form /\<xform /gi;
        $content =~ s/\<\/form/\<\/xform/gi;
        
        my $content2 = $content;
        $content2 =~ s/\<.+?\>//gi;
        $content2 =~ s/\s//gi;
        
        if(!$content2) { $content = '<div align="left"><h2>this page is currently empty</h2></div>'; }

        print qq(<a name="$pageNo"></a><p /><br /><h2>$pageName</h2><p /><div align="left"><table cellpadding="8" cellspacing="0" width="90%" class="box">);

        print qq(<tr><td class="objectinfo">$info</td></tr>);
        print qq(<tr><td><table cellpadding="2" cellspacing="0" width="100%" border="0">);
    
        my $url = 'no URL is loaded into the main window for this page';
        if($page->{rightFrame} == 0 && $page->{rightFrameURL}) { $url = qq(main window is loaded with <a href="$page->{rightFrameURL}">$page->{rightFrameURL}</a>); }
        if($page->{rightFrame} > 0 ) { $url = qq(main window is loaded with object <a href="#" onClick="window.open('displayobject.pl?object=$page->{rightFrame}', 'help', 'resizable=yes,menubar=yes,scrollbars=yes,status=yes,width=400,height=300'); return false;">$page->{rightFrame}</a>); }
        if($pageNo == 1) { $url = 'main window is loaded with the text shown above'; }
        
        my $action = 'none';
        if($unit->{folioOpenMethod}) { $action = 'initnoframes2'; }
    
        my $toc = '';
        if($page->{heading}) { $toc = "TOC entry: <h2>$page->{heading}</h2>"; }

        print qq(<tr><td style="font-size:80%">$url</td></tr><tr><td style="font-size:80%">);
        
        print qq(&nbsp;&nbsp;&#149;&nbsp;&nbsp;<a href="editunit.pl?folio=$folio&unit=$unitNo&page=$pageNo&action=edit&s=$check">edit this page</a>);
        print qq(<br />&nbsp;&nbsp;&#149;&nbsp;&nbsp;<a href="editunit.pl?folio=$folio&unit=$unitNo&page=$pageNo&action=insert">insert a new blank page after this page</a>);
        print qq(<br />&nbsp;&nbsp;&#149;&nbsp;&nbsp;<a href="page.pl?render=inhale?folio=$folio&unit=$unitNo&page=$pageNo&action=none" target="_blank" >preview this page</a> (opens in a new window));
        if($pageNo > 1 && $totalPages > 2) { 
            print qq(<br />&nbsp;&nbsp;&#149;&nbsp;&nbsp;<a href="editunit.pl?folio=$folio&unit=$unitNo&page=$pageNo&action=delete">delete this page</a>);
            print qq(<br />&nbsp;&nbsp;&#149;&nbsp;&nbsp;move this step so it becomes step number );
            my @options = ();
            foreach my $moveTo (1 .. $totalPages-1) {
                if($moveTo != ($pageNo - 1)) {
                    my $moveTo2 = $moveTo + 1;
                    push @options, qq(<a href="editunit.pl?folio=$folio&unit=$unitNo&page=$pageNo&action=move&b=$moveTo2">$moveTo</a>);
                }
            }
            if(scalar(@options) >= 2) {
                foreach (0 .. (scalar(@options)-3)) {
                   print "$options[$_], ";
                }
                print "$options[-2] or $options[-1]";
            }
            else {
                print $options[-1];
            }
        }

        print qq(</td></tr>);

        print qq(</table></td></tr>);

        if($toc) { print qq(<tr class="objectinfo"><td bgcolor="#DEFAE3">$toc</td></tr>); }

        print qq(<tr><td class="preview">$content</td></tr>);

        print qq(</table></div>);
    
    }

    print qq(<p /><hr /><p /><a href="viewaudit.pl?a=$unitNo&b=unit">view the audit trail for this unit</a>);

    print qq(</div></body></html>);
}

ENDFLAG: end InhaleCore;

sub deadParrot {
    my($error) = @_;
    print $cgi->{header};

    if($error =~ /^\d*$/) {
        print qq(<h2>error!</h2><p>your request generated an error code of <b><font color="red">$error</font></b>);
    }
    else {
        print qq(<h2>error!</h2><p><dl><dt>your request generated the following error:<p><dd><b><font color="red">$error</font></b></dl>);
    }
    print "</body></html>";
    exit;
}

sub pageHeader { 
    my($onLoad) = @_;

<<HEADER

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 

<html lang="en">
<head>
<title>Intute Informs edit unit</title>
<script type="text/javascript" src="http://www.informs.intute.ac.uk/tinymce/jscripts/tiny_mce/tiny_mce.js"></script>
<script type="text/javascript">
	tinyMCE.init({
		// General options
              mode : "textareas",
		theme : "advanced",
		plugins : "safari,pagebreak,style,layer,table,save,advhr,advimage,advlink,emotions,iespell,inlinepopups,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template",

		// Theme options
		theme_advanced_buttons1 : "save,newdocument,|,bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,formatselect,fontselect,fontsizeselect",
		theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor",
		theme_advanced_buttons3 : "hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen",
		theme_advanced_buttons4 : "moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template",
		theme_advanced_toolbar_location : "top",
		theme_advanced_toolbar_align : "left",
		theme_advanced_statusbar_location : "bottom",
		theme_advanced_resizing : "true",
              apply_source_formatting : "true",                                        

		// Example content CSS (should be your site CSS)
		content_css : "/css/content.css",

		// Drop lists for link/image/media/template dialogs
		template_external_list_url : "lists/template_list.js",
		external_link_list_url : "lists/link_list.js",
		external_image_list_url : "lists/image_list.js",
		media_external_list_url : "lists/media_list.js",

		// Replace values for the template plugin
		template_replace_values : {
			username : "Some User",
			staffid : "991234"
		}
	});
</script>

<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css" />
<style type="text/css">
input,select,textarea {font-family:Arial; font-size:90%; }
body { }
div.container {
text-align: left;
width: 85%;
margin-left: auto;
margin-right: auto;
}
.button { font-family: Arial, Verdana, Helvetica; font-size:90%; font-weight: bold; text-transform: uppercase; }
td { padding-right:8px; padding-left:8px;}
input,select { }
.box { border: 1px solid #cccccc }
.boxhead {color: #000000; padding-left:10px;  }
.preview {font-family: Arial; padding:20px; font-size:90%; }
.objectinfo {font-family: Arial; font-size:80%; }
.fixed { font-family: Arial, Lucida Console, Courier New; text-align:left;}
.boxed { border: 1px solid #cccccc; font-size:80%; margin-top:2px; }

</style>

<script language="JavaScript">
<!--

var clickedButton = false;


function jumpOnLoad (v) {
    location.href = '#' + v;
}

function formatStr (v) {

    if (!document.selection) return;

    var str = document.selection.createRange().text;
    document.theform.txtbox.focus();

    var range = document.selection.createRange();
    if (range.parentElement().name != 'txtbox') return;

    var strpre = '';
    var straft = '';

    if (!str) {
        strpre = ' ';
        straft = ' ';
    }

    while (str.substring(0,1) == ' ') {
        str = str.substring(1, str.length);
        strpre = ' ';
    }
    while (str.substring(str.length-1,str.length) == ' ') {
        str = str.substring(0, str.length-1);
        straft = ' ';
    }

    document.selection.createRange().text = strpre + '[' + v + ']' + str + '[/' + v + ']' + straft;
}

function insertList() {
  var str = document.selection.createRange().text;
  document.theform.txtbox.focus();

  var newline = "\\n";
  var liststr = "";
  var extra = " single";
  var item = 1;
  var looper = 0;

  while(item) {
      var item = prompt("CREATE A LIST OF ITEMS\\ntype in a" + extra + " item for the list or click on CANCEL to finish", "");
      if(item) {
          liststr = liststr + item + newline;
          looper++;
          extra = "other";
      }
  }

  if(looper) {
      var sel = document.selection.createRange();
      sel.text = newline + '[l]' + newline + liststr + '[/l]' + newline;
  }
  return;
}


function insertURL(chr) {
  var str = document.selection.createRange().text;
  document.theform.txtbox.focus();

  var item = prompt("INSERT A WEB LINK\\ntype in the URL address", "http://");

  if(item) {
      var sel = document.selection.createRange();
      sel.text = ' [' + chr + ']' + item + '[/' + chr + '] ';
  }
  return;
}

function pagejumper(pagenumber) {
    document.theform.pagejump.value = pagenumber;
    document.theform.submit();
}

function mtShortCuts () {
    if (event.altKey != true) return;
    if (event.keyCode == 49) formatStr('a');
    if (event.keyCode == 50) formatStr('q');
    if (event.keyCode == 51) formatStr('i');
    if (event.keyCode == 52) formatStr('b');
    if (event.keyCode == 53) insertList();
    if (event.keyCode == 54) insertURL('r');
}


//-->
</script>
</head>
<body $onLoad><div class="container">
<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />
<div id="breadcrumb">Intute Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a> > <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > <b>edit</b>

HEADER

}




1;
