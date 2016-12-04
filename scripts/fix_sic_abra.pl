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


$siccode_str = '1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0';
$siccode = &AbUtils::catcode_from_str($siccode_str);
$qsiccode = $dbh->quote($siccode);

#$dbh->do("update rcatdb_categories set catcode = $qsiccode where id = 43224");

$abracode_str = '4:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0';
$abracode = &AbUtils::catcode_from_str($abracode_str);
$qabracode = $dbh->quote($abracode); 
$abra_id = 66727;

$dbh->do("update rcatdb_categories set catcode = $qabracode where id = $abra_id");

$q = "select id, catcode from rcatdb_categories where cid = 66727 or cid = 76564 or cid = 66728";
$sth = $dbh->prepare($q);
$sth->execute();

print "There are ".$sth->rows()." rows\n";

while (($id, $code) = $sth->fetchrow_array) {
	my @catcode = unpack "C16",$code;
	$catcode[0] = 4;
	$newcode = pack "C16",@catcode;
	$qnewcode = $dbh->quote($newcode);
	$nq = "update rcatdb_categories set catcode = $qnewcode where id = $id";
	$dbh->do($nq);
}

1;


