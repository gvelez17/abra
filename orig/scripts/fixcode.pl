#!/usr/local/bin/perl -T
# Path to RCategories

# utils
 
BEGIN {
      unshift (@INC, '/w/abra/lib');
}

use AbHeader qw(:all);
use AbUtils;
use AbMacros;
use Abra;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

use CGI::Lite;
use PHP::Session;

# Hack for testing
#if ($0 =~ /org/) {
#	$DBNAME = 'rpub';
#	$DBUSER = 'groots';
#	$DBPASS = 'sqwert';
#	$THISCGI = "http://qs.abra.btucson.com/cgi/org.pl";
#} else {
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.btucson.com/cgi/ab.pl";
	$ADMINUSER = 1;

#}
$debug = 1;

# Use MySQL (or DBI) to connect
$ab = new Abra;

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

#$parentid = 308;
#$childid = 260;
#@childids = (32201,32202,32203,32204,32205,32206,32207,32208,32209);

#$parentid = 43203;
#@childids = (66656);

#$parentid = 303;
#@childids = (76658);

#$parentid = 66727;
#@childids = (76693,76585,76588);

$parentid = 77964;
@childids = (32188,32250);

for $childid (@childids) {
	my $catcode = &AbUtils::GenSubCatCode($parentid);
	my $qcatcode = $dbh->quote($catcode);

	my $q = "update rcatdb_categories set catcode = $qcatcode where id = $childid";
	$dbh->do($q);

	my $q2 = "update rcatdb_items set itemcode = $qcatcode where cid = $childid";
	$dbh->do($q2);
}

1;


