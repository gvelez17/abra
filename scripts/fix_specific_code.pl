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
#	$THISCGI = "http://qs.abra.info/cgi/org.pl";
#} else {
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.info/cgi/ab.pl";
	$ADMINUSER = 1;

#}
$debug = 1;

# Use MySQL (or DBI) to connect
$ab = new Abra;

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}


$catid = 77599;
$catcodestr = '23:19:15:8:1';

@catcode = split(':',$catcodestr);


for ($j = $#catcode +1; $j<16; $j++) {
	$catcode[$j] = '0';
}

$catcode = pack "C16", @catcode;

$q = "update rcatdb_categories set catcode = ".$dbh->quote($catcode)." where id = $catid";

print "Q is $q\n";

$dbh->do($q);
1;


