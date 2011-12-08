#!/usr/bin/perl -wT

use strict;
use lib "./";

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi2 = new CGI;

use InhaleCore qw( :DEFAULT untaint );
unless(new InhaleCore( 'safeCGI' )) { error("access to this page is restricted to authorised users only\nplease log into your portfolio before accessing this page"); }

use InhaleRead qw( );
use InhaleWrite qw( insertObject );

my $undef;
my $timestamp = time;

if($cgi2->param('textarea')) {

    print $cgi2->header;

    my $out=$cgi2->param('textarea');
    my $description = $cgi2->param('description');
    my $url = $cgi2->param('url');
    my $outfile = untaint($user->{pathToUploads}.time.int(rand(5000)).'.txt', 4);

    open(OUT,">".$outfile);
    print OUT $out;
    close(OUT);

    my($objectID, $filename) = insertObject( filename => $outfile, 
                                                 desc => $description, 
                                              account => $user->{userAccountNumber} );
    
print '<html>';
print '<head>';
print '<title>Informs - upload object</title>';
print '<link rel="stylesheet" href="/SAMPLE.css" type="text/css" />';
print '</head>';
print '<body>';
print '<p>The file has been uploaded as '.$objectID.'</p>';
print '<p>If the file is a HTML page then use this link to embed in your unit</p>';
print '<p>/objects/'.$filename.'</p>';
print '</body>';
print '</html>';
}

elsif($cgi2->param('thefile')) {
        
    print $cgi2->header;

    my $out='';
    my $filename = $cgi2->param('thefile');
    my $filehandle = $cgi2->param('thefile');
    my $description = $cgi2->param('description');
    my $url = $cgi2->param('url');

    if($filename!~/\./) {die 'filename does not contain an extension';}
    
    $filename=~s/\\/\//g;
    ($filename,$undef)=split(/\//,reverse($filename),2);
    $filename=reverse($filename);

    my @tmp = split(/\./,$filename);

    my $filetype = $tmp[-1];

    binmode($filehandle);
    while(<$filehandle>) {
       $out.=$_;
    }
    close($filehandle);

    my $outfile = untaint($user->{pathToUploads}.time.int(rand(5000)).'.'.$filetype, 4);
   
    open(OUT,">".$outfile) || die 'could not open '.$outfile.' for output';
    binmode(OUT);
    print OUT $out;
    close(OUT);

    if(length($out) + 500 < $ENV{CONTENT_LENGTH}) {print 'problem with upload file size....'.length($out).' / '.$ENV{CONTENT_LENGTH}}

    my($objectID, $filename2) = insertObject( filename => $outfile, 
                                                 desc => $description, 
                                              account => $user->{userAccountNumber} );

print '<html>';
print '<head>';
print '<title>Informs - upload object</title>';
print '<link rel="stylesheet" href="/SAMPLE.css" type="text/css" />';
print '</head>';
print '<body>';
print '<p>The file has been uploaded as object '.$objectID.'</p>';
print '<p>If the file is a HTML page then use this link to embed in your unit</p>';
print '<p>/objects/'.$filename2.'</p>';
print '</body>';
print '</html>';
}
else {
    print $cgi2->header; 
    
    print <<END1;

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1" />
<meta http-equiv="Expires" content="Fri, Jun 12 1981 08:20:00 GMT" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache" />
<title>Informs upload object</title>
<link rel="stylesheet" href="/SAMPLE.css" type="text/css" />
<style type="text/css">
.box {padding-top:10px; padding-left:10px; }
table.thisobject{
width:100%;
padding:20px;
text-align:right;
}
td.thisobject{
padding:10px;
text-align:left;
}

</style>
</head>
<body>
<div class="container">
<p><h2>Insert object</h2></p>
<div id="create"><div class="box">
<table class="thisobject">
<tr><td><form action="insertobject.pl" method="post" enctype="multipart/form-data">
file: </td><td class="thisobject"><input type="file" name="thefile"></td></tr>
<tr><td>description: </td><td class="thisobject"><input type="text" name="description" size="42"> <br /> tip : provide a full description to aid searching</td></tr>
<!-- URL (optional): <input type="text" name="url"> -->
<tr><td></td><td class="thisobject"><input type="submit" value="upload object" class="submit" >
</form></td></tr></table></div>


</div></div>
</body></html>

END1

}

