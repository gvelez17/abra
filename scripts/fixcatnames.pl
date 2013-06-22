#!/usr/local/bin/perl -T

 
BEGIN {
      unshift (@INC, '/w/abra/lib');
}
use Abra;
use AbHeader qw(:all);
use AbUtils;
use AbMacros;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.info/cgi/ab.pl";
	$ADMINUSER = 1;

$debug = 1;

# Use MySQL (or DBI) to connect
$abra = new Abra;

if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}

$q = "select rcatdb_categories.* from rcatdb_categories where name LIKE \"%'%\" ";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");


while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $name = $ref->{'NAME'};
	my $rel_url = $ref->{'REL_URL'};
	$name =~ s/\'//g;
	$rel_url =~ s/\'//g;
	$id = $ref->{'ID'};

	my $qu = "update rcatdb_categories set name = ".$dbh->quote($name).", rel_url = ".$dbh->quote($rel_url)." where id = $id";

	$dbh->do($qu);
}

