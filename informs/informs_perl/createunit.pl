#!/home/zzintadm/perl/bin/perl -wT

    use strict;
    use lib "./";
    use locale;

    use Digest::MD5 qw(md5_hex);

    use InhaleCore qw( :DEFAULT convertTags );
    new InhaleCore;

    use InhaleWrite qw( beginNewUnit insertEmptyObject insertNewPage );
    use InhaleRead qw( getFolioDetails getFolioUnits getUnit );

    my $numberOfSteps = $cgi->{steps} || 2;

    if(!$user->{userNumber}) { die("ERROR - access to this page is restricted to authorised users only\n"); }

    my $folio = $cgi->{folio} || die("ERROR - the following parameter is missing from your request: folio\n");
    my $action = $cgi->{action} || '';
    my %folioInfo = getFolioDetails( folio => $folio ); 

    print $cgi->{header};
   
print qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 

<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1" />
<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache" />
<title>Informs Project create unit</title>
<link rel="stylesheet" href="http://www.informs.intute.ac.uk/inhale.css" type="text/css" />
</head>
<body>);
print qq(<div class=container>);
print qq(<img src="/images/intute_informs.jpg" class="logo" alt="Informs logo" border="0" />);
print qq(<div id="breadcrumb">Intute Informs > <a href="$user->{pathToCGI}login2.pl?action=checkcookie&folio=$folio">portfolios</a>  >  <a href="portfolio.pl?folio=$folio">$folioInfo{portfolioName}</a> > create unit</div>);

    unless( $user->{userPortfolioList} =~ /:$folio:/ ) { die("ERROR - you do not have permission to create new units in portfolio $folio"); }

    if($action eq 'confirm') {
        if($cgi->{utitle}) { 
            $cgi->{txtbox} =~ s/[\r\n]/ /gi;
            my $unit = beginNewUnit( folio => $folio,
                                     title => $cgi->{utitle},
                                   account => $user->{userAccountNumber},
                                      desc => $cgi->{txtbox}, 
                                     blank => 1 );
                                      
            if($cgi->{page} > 0) {
                foreach my $loop (1 .. $cgi->{page}) {
                    my( $object, $fileName ) = insertEmptyObject( account => $user->{userAccountNumber} );

                    insertNewPage( objectLeft => $object,
                                         page => ($loop+1), 
                                         unit => $unit );
                }            
            }
            print qq(<p /><div align="left"><h2>New unit number $unit has been created!</h2><p /><br />);
            print qq(<p />...<a href="editunit.pl?unit=$unit&folio=$folio">click here</a> to start editing your new unit</a></div>)

        }       
        else {
            $action = '';
        }
    }
    
    if($action ne 'confirm') {
    
        print qq(<p />);
        print qq(<h2>Create a new unit in $folioInfo{portfolioName}</h2><div id="create"><br />);
 
        print qq(<form action="createunit.pl" method="post">);
        print qq(<input type="hidden" name="folio" value="$folio">);
        print qq(<input type="hidden" name="action" value="confirm">);
        print qq(<ol>);
        print qq(<li>title of new unit:</li>);
        print qq(<br /><input type="text" name="utitle" size="40" value=").convertTags($cgi->value('utitle')).qq(" /><br />&nbsp;</li>);

        print qq(<li>optional description of the new unit:</li>);
        print qq(<br /><textarea name="txtbox" cols="40" rows="5">).convertTags($cgi->value('txtbox')).qq(</textarea><br />&nbsp;</li>);

        print qq(<li>select number of blank steps to create:</li>);
        print qq(<br /><select name="page">);
        
        foreach (0 .. 20) {
            if($_ eq $numberOfSteps) { print qq(<option value="$_" selected>$_</option>); }
            else { print qq(<option value="$_">$_</option>); }
        }
        
        print qq(</select><br /><i>note - you can always add extra steps or delete unwanted steps later on</i><br />&nbsp;</li>);

        print qq(<p /><input type="submit" value="create new unit" class="submit" >);
        
        print qq(</form></div>);

    }
    print "</div><br /><br /><br /><br /></body></html>";
