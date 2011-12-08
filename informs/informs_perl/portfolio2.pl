#!/usr/bin/perl -wT

######
#
# checked for new account code (06/Feb/2007)
#

### render the index page for the portfolio
    
    use strict;
    use lib "./";
    
    use InhaleCore qw( :DEFAULT untaint timeToRun );
    use InhaleRead qw( getFolioDetails getFolioUnits getFolioUnitsById getUnit );
    use InhaleRender qw( :colourscheme clearCache );

### initialise

    new InhaleCore;
    
    my $digest  = $user->{userID};
    my $folio   = $cgi->{folio}  || '1';
    my $render  = $cgi->{render} || 'inhale';

### accessible stylesheet?
    
    my $customStylesheet = 0;
    my $templateName     = 'portfolio';
    my $printerIcon      = $user->{pathHtmlVir}.'gfx/printer.gif';
    
    if($render =~ /^\d\d\d\d$/) 
    { 
        $customStylesheet = 1; 
        $templateName     = 'portfolio_acc';
        $printerIcon      = $user->{pathHtmlVir}.'gfx/printer_large.gif';
    }     

### does the user have permission to edit this portfolio?
    
    my $userIsAdmin = 0;
    
    if( $user->{userPortfolioList} =~ /:$folio:/ )
    { 
        $userIsAdmin = 1; 
    }
        
### perform actions...    
    
    if($userIsAdmin && $cgi->{'action'}) 
    {
        use InhaleWrite qw( updatePortfolio );
    
        if   ($cgi->{'action'} eq 'hide')   { updatePortfolio( $folio, 'hide',     $cgi->{'unit'}); }
        elsif($cgi->{'action'} eq 'unhide') { updatePortfolio( $folio, 'unhide',   $cgi->{'unit'}); }
        elsif($cgi->{'action'} eq 'up')     { updatePortfolio( $folio, 'moveUp',   $cgi->{'unit'}); }
        elsif($cgi->{'action'} eq 'down')   { updatePortfolio( $folio, 'moveDown', $cgi->{'unit'}); }    
        print "Location: $user->{pathToCGI}portfolio.pl?id=$digest&render=$render&folio=$folio\n\n";
        exit;
    }
 
    my %folioInfo = getFolioDetails( folio => $folio ); 
    my %template1 = ();
    my %template2 = ();
    
    open(TEMPLATE, $user->{pathToData}."templates/inhale/".$templateName."1.html") || die $user->{pathToData}."/templates/inhale/".$templateName."1.html";
    my @template1 = <TEMPLATE>;
    close(TEMPLATE);
    
    open(TEMPLATE, $user->{pathToData}."templates/inhale/".$templateName."2.html") || die $user->{pathToData}."/templates/inhale/".$templateName."2.html";
    my @template2 = <TEMPLATE>;
    close(TEMPLATE);
    
    open(TEMPLATE, $user->{pathToData}."templates/inhale/".$templateName."3.html") || die $user->{pathToData}."/templates/inhale/".$templateName."3.html";
    my @template3 = <TEMPLATE>;
    close(TEMPLATE);

    $template1{printerIcon} = $printerIcon;
    $template2{printerIcon} = $printerIcon;

    if($userIsAdmin) {

	$template1{adminStuff} .= qq(<div id="breadcrumb">Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a>);

       #need this to finish breadcrumb 
       if($folioInfo{portfolioParent}){
	$template1{adminStuff} .= qq( > <a href="portfolio.pl?folio=$folioInfo{portfolioParent}&amp;render=$render&amp;id=$digest">$folioInfo{portfolioParentName}</a> > $folioInfo{portfolioName}</div>);
       } else{
	$template1{adminStuff} .=qq( > $folioInfo{portfolioName}</div>);
       } 

        $template1{adminStuff} .= qq(<p /><div align="left"><table class="options"><tr><td align="left" colspan="1"> options</td><td class="user" colspan="4">Logged in as:<strong> ).$user->{userRealName}.qq(</strong></td></tr><tr><td class="options"><form action="$user->{pathToCGI}createunit.pl?"><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="create unit"></form></td>);
        $template1{adminStuff} .= qq(<td class="options"><form action="$user->{pathToCGI}search.pl?"><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="search units"></form></td>);

    if( $user->{userType} eq 'admin' ) 
	{ 
	    $template1{adminStuff} .= qq(<td class="options"><form action="$user->{pathToCGI}adminsettings.pl?"><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="administrator"></form></td>); 
	}
        if( $user->{userType} eq 'editor' ) 
	{ 
	    $template1{adminStuff} .= qq(<td class="options"><form action="$user->{pathToCGI}editorsettings.pl?"><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="editor options"></form></td>); 
	}
        if( $user->{userType} eq 'superadmin' ) 
	{ 
	    $template1{adminStuff} .= qq(<td class="options"><form action="$user->{pathToCGI}adminsettings.pl?"><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="administrator"></form></td>); 
	    $template1{adminStuff} .= qq(<td class="options"><form action="$user->{pathToCGI}superadminsettings.pl?"><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="super admin"></form></td>); 
	}
        $template1{adminStuff} .= qq(<td class="options"><form action="$user->{pathToCGI}login2.pl?"><input type="hidden" name="action" value="logout" /><input type="hidden" name="folio" value="$folio" /><input type="submit" class="submit" value="log out"></form></td></tr></table></div>);
        $template1{logInStuff}  = '';
       }
    else {
        if( $user->{userNumber} ) 
        { 
            $template1{adminStuff}  = qq(<div align="center" style="border:4px dashed #000; padding:6px 20px; background:#FFF;"><b>you are logged in as ).$user->{userRealName}.qq(</b></div>);
            $template1{adminStuff} .= qq(<p /><b>options:</b><ul style="margin-top:0px; font-weight:bold;">);
	    if( $folio != $user->{userAccountParentPortfolio} ) { $template1{adminStuff} .= qq(<li><a href="portfolio.pl?folio=).$user->{userAccountParentPortfolio}.qq(">return to portfolio #$user->{userAccountParentPortfolio} ($user->{userAccountParentPortfolioName})</a></li>); }
            $template1{adminStuff} .= qq(<li><a href="search.pl?folio=$folio">search all units</a></li>);
            $template1{adminStuff} .= qq(<li><a href="login2.pl?action=logout&amp;folio=$folio">logout</a></li></ul>);
            $template1{logInStuff}  = ''; 
        }
        else
        { 
            $template1{logInStuff} = qq(<a href="login2.pl?folio=$folio">administrator log in</a>); 
        }
    }
        
    $template1{'cssLink'}       = generateStylesheet($render, '', $folio, $folioInfo{portfolioCutsomCSS} );
    $template1{'folioNumber'}   = $folio;
    $template1{'render'}        = $render;
    $template1{'accountTitle'}  = $folioInfo{portfolioName}." Units"; 
    $template1{'accountTitle'}.= qq(</h1><img src="/images/key.jpg" alt="key" />); 
    
    if( $folioInfo{portfolioCustomLogo} ) 
    { 
        $template1{'portfolioLogo'} = qq(<img src="$folioInfo{portfolioCustomLogo}" border="0" alt="[ portfolio logo ]" />); 
    }
   
    my @units = getFolioUnitsById( folio => $folio );
    
    print $cgi->{'header'};

    my $image = '';
    if($folioInfo{accountImage}) 
    { 
        $image = '<p /><img src="'.$folioInfo{accountImage}.'" border="0" />'; 
    }
    
    my $cnt = 0;    
  
    if( $folioInfo{portfolioCustomLogo} ) 
    { 
        $template1{'portfolioLogo'} = qq(<img src="$folioInfo{portfolioCustomLogo}" border="0" alt="[ portfolio logo ]" />); 
    }
    else { $template1{'portfolioLogo'} = qq(<br />); }
    
### DISPLAY UNITS...
    
    foreach my $line (@units) 
    {
        $cnt++;
        $line =~ s/[\r\n]//gi;
        my($temp, $objectID, $title, $description, $actionMethod, $visibility) = split(/\^\^/, $line);
    
        my $unit = getUnit( unit => $objectID );
        if(!$title || $title eq '') { $title = $unit->{unitTitle}; }
    
        my $action = 'init';
        if($actionMethod eq 'noframes+js') { $action = 'initnoframes1'; }
    
        $template2{unitLink} = 'jump.pl?'.$folio.'-'.$unit->{unitNumber}.'-'.$render;
        $template2{unitTitle} = $title;
        $template2{unitDescription} = $description;
        $template2{printableLink} = qq(printunit.pl?folio=$folio&amp;unit=$objectID);
        $template2{unitColour} = '';
   
        if($visibility eq 'N') {
            if(!$userIsAdmin) { next; }
            $template2{unitColour} = ' bgcolor="#CCCCCC"';
        }
        if($userIsAdmin) {
            my $admin;
    
            use Digest::MD5 qw(md5_hex);
            my $checksum = md5_hex($objectID, $folio, $user->{userNumber}, 'a bit of text');
    
            $admin .= qq(<tr><td align="left"><font size="2">);
            $admin .= '&nbsp;<b>link</b>: <a title="link to this unit" href="jump.pl?'.$folio.'-'.$objectID.'">'.$user->{pathToCGI}.'jump.pl?'.$folio.'-'.$objectID.'</a>';
            $admin .= qq(<br />&nbsp;<b>options:</b> <b><a href="editunit.pl?unit=$objectID&amp;folio=$folio" title="edit this unit">edit</a></b>);           
            $admin .= qq( | <b><a href="copyunit.pl?from=$folio&amp;unit=$objectID&amp;folio=" title="make a copy of this unit">copy</a></b>);
            $admin .= qq( | <b><a href="deleteunit.pl?unit=$objectID&amp;folio=$folio&amp;checksum=$checksum" title="delete this unit">delete</a></b>);
	     if($visibility eq 'Y') { $admin .= qq( | <b><a href="portfolio.pl?action=hide&amp;folio=$folio&amp;unit=$objectID" title="hide this unit from end users">hide unit</a></b>); }
            else { $admin .= qq( | <b><a href="portfolio.pl?action=unhide&amp;folio=$folio&amp;unit=$objectID" title="make this unit visible to end users">publish unit</a></b>); }
            $admin .= '</td</tr>';
            
            if($visibility eq 'N') { $template2{numberOfSteps}= qq( <img src="/images/userhide.jpg" alt="this unit is hidden from students" />); }
	     else{ $template2{numberOfSteps}= qq(<img src="/images/user.jpg" alt="this unit is available to students" />); }

            $template2{adminStuff} = $admin;
        }
        elsif( $user->{userNumber} > 0 ) {
            $template2{adminStuff} = qq(<tr><td align="left"><font size="2">&nbsp;<b>options:</b> <a href="copyunit.pl?from=$folio&amp;unit=$objectID&amp;folio=">copy this unit into your portfolio</a></td></tr>);
        }
    
        my @template = @template2;
    
        if($description) { @template = @template3;}
    
        foreach my $line2 (@template) {
            while($line2 =~ /\{\{/ && $line2 =~ /\}\}/) {
                my($a, $b) = split(/\{\{/, $line2, 2);
                my($c, $d) = split(/\}\}/, $b, 2);
                my $replace = "<!-- $c not found -->";
                if(defined($template2{$c})) { $replace = $template2{$c}; }
                $line2 = $a.$replace.$d;
            }
            $template1{units} .= $line2;
        }
    }
        
    if(!scalar(@units)) 
    {
        unless($user->{userNumber}) { $template1{units} .= '<p /><blockquote><i>...this portfolio is currently empty</i></blockquote></ p>'; }
        else { $template1{units} .= '<p /><blockquote><i>...no units are currently assigned to this portfolio</i></blockquote></ p>'; }
    
    } 
    
    
    if( $folioInfo{portfolioParent} ) 
    {
        my $icon = '';
    
        if( $user->{userNumber} )
        {
            $icon = qq( <img src="$user->{pathHtmlVir}gfx/editno.gif" alt="you cannot edit units in this portfolio" />);
            if( $user->{userPortfolioList} =~ /:$folioInfo{portfolioParent}:/ ) { $icon = qq( <img src="$user->{pathHtmlVir}gfx/edityes.gif" alt="you can edit units in this portfolio" />); }
        }
    }
    
   $template1{subAccounts}.=qq(  <a href="$user->{pathToCGI}portfolio.pl?folio=$folio">Order by title</a> | <b id="clicky" style="font-weight:normal; color: #007F71;cursor:pointer; white-space: nowrap;" onClick="hider('portfoliotext');">Hide description</b> |);
         
    if( $folioInfo{portfolioChildren} ) 
    {
        $template1{subAccounts} .= qq( <a href="javascript:toggle('otherportfolios')">View / hide $folioInfo{portfolioAccountTitle} portfolios </a><ul class="otherportfolios" id="otherportfolios">);
    
        my @children = split( /\|/, $folioInfo{portfolioChildren} );
    
        foreach( @children )
        {
            my( $name, $number ) = split( /  :::/ );
    
            my $icon = '';
    
            $template1{subAccounts} .= qq(<li><b><a href="portfolio.pl?folio=$number&amp;render=$render&amp;id=$digest">$name</a></b>$icon</li>);
        }
        $template1{subAccounts} .= '</ul>';
        $template1{subAccounts} .= qq(<script type="text/javascript"> 
	 document.getElementById('otherportfolios').style.display="none"; // collapse list 
	 function toggle(list){ 
	 var listElementStyle=document.getElementById(list).style; 
	 if (listElementStyle.display=="none"){ 
	 listElementStyle.display="block"; 
 	 }
	 else{ listElementStyle.display="none"; 
 	 } 
	 } 
	 </script>);    
    } 
       
    foreach my $line (@template1) {
        while($line =~ /\{\{/ && $line =~ /\}\}/) {
            my($a, $b) = split(/\{\{/, $line, 2);
            my($c, $d) = split(/\}\}/, $b, 2);
            my $replace = "<!-- $c not found -->";
            if(defined($template1{$c})) { $replace = $template1{$c}; }
            $line = $a.$replace.$d;
        }
        print $line;
    }
        
    print qq(\n\n<!-- page generated in ).timeToRun()." seconds -->\n\n"; 
    



    
end InhaleCore;
    
1;
        
