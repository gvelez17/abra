#!/usr/local/bin/perl -T
# Path to RCategories

# utils
 
BEGIN {
      unshift (@INC, '/w/abra/cgi');
}

use AbHeader qw(:all);
use AbUtils;
use AbMacros;
use RCategories;
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
$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');
$dbh = $obj->{'dbh'};


if (!$obj) {
	print "Error - cannot connect to database";
	exit;
}

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

$q = "select rcatdb_categories.* from rcatdb_categories, rcatdb_items where LEFT(catcode,3) = LEFT(itemcode,3) and RIGHT(catcode,10) <> RIGHT(itemcode,10) and rcatdb_items.id = 101200  ";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

$BIZCAT = 306;
$EDITOR_ID = 7080;

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {


	$q1 = "select LEFT(catcode, 5) from rcatdb_categories where id = ".$ref->{'ID'};
	my ($goodparentcode) = $dbh->selectrow_array($q1);

	my $catname = $ref->{'NAME'};	
	my $catid = $ref->{'ID'};

	@goodparentcode = unpack "C5", $goodparentcode;
my $pstr = join(':',@goodparentcode);
print "Short parent code for $catid is $pstr\n";
	@blanks = (0) x 11;
	push @goodparentcode, @blanks;
	$fullparentcode = pack "C16",@goodparentcode;

print "Full parent code is ".&AbUtils::catcodestr($fullparentcode)."\n";


	# find the correct parent cat
	$q2 = "select id, name from rcatdb_categories where catcode = ".$dbh->quote($fullparentcode);
	my ($parentid, $parentname) = $dbh->selectrow_array($q2);

	# check if we already have this subcat
	$q3 = "select id from rcatdb_categories where cid = $parentid and name = ".$dbh->quote($catname);
	my ($alreadycat) = $dbh->selectrow_array($q3);

	my $newcatid = $parentid;
	if ($alreadycat) {
		$newcatid = $alreadycat;
		print "Moving $catname to category of same name at level 6\n";
	} elsif ($parentname and ($parentname ne $catname)) {
		$newcatid = &AbUtils::add_subcat(cid=>$parentid,newcatname=>$catname);
		print "Created new cat $catname level 6 subcategory of $parentname\n";
	} else {
		print "Moving items to parent $newcatid at level 5\n";
	}

	# now move all the items
	if ($newcatid) {
		print "Moving items...";
		$q4 = "update rcatdb_items set cid = $newcatid where cid = $catid";
		$dbh->do($q4);
		print "did all ".$dbh->rows."\n";
	}

}

