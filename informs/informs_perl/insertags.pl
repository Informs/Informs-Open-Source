#!/usr/bin/perl -wT

print "Content-type: text/html\n\n";

use DBI;
use POSIX;
use CGI;
require "config.pl";
my $q = new CGI;
my $folio = $q->param('folio');
my $unit = $q->param('unit');
my $title = $q->param('title');
my $tags = $q->param('tags') || "";
push (@tags, $q->param('tags'));
my $tags = join ("; ", @tags);
$tags =~s/'/\\'/g;
$title =~s/'/\\'/g;

@tagssplit = split (/\; /, $tags);

my $dbh = DBI->connect("DBI:mysql:informs:localhost:3306", $username, $password);

$sql="insert into informstags(tags,unit,title) values ('$tags','$unit','$title')";

my $sth=$dbh->prepare($sql);

   $sth->execute;

print <<END2

<meta http-equiv="refresh" content="0;url=/informs_perl/portfolio.pl?folio=$folio">

END2
