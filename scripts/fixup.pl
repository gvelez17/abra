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

$q = "select * from rcatdb_categories";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

$BIZCAT = 306;
$EDITOR_ID = 7080;

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$wantparent = $ref->{'CID'};
	$thisid = $ref->{'ID'};

	$q1 = "select count(*) from rcatdb_categories where id = $wantparent";

	($count) = $dbh->selectrow_array($q1);

	if ($wantparent && ! $count) {
		print "deleting ".$ref->{'NAME'}." id ".$ref->{'ID'}." parent supposed to be $wantparent\n";
		$dbh->do("delete from rcatdb_categories where id = $thisid");
		$dbh->do("delete from rcatdb_rcats where id = $thisid or CAT_DEST = $thisid");
	} else {
		my $q2 = "select count(*) from rcatdb_items where cid = $thisid";
		my ($itemcount) = $dbh->selectrow_array($q2);
		if ($itemcount == 0) {
#			print "category $thisid ".$ref->{'NAME'}." has 0 items\n";
	#		$dbh->do("delete from rcatdb_categories where id = $thisid");
	#		$dbh->do("delete from rcatdb_rcats where id = $thisid or CAT_DEST = $thisid");
	#		$dbh->do("delete from rcatdb_ritems where cat_dest = $thisid");
		}
	}
}

$q = "select * from rcatdb_rcats";
$sth = $dbh->prepare($q);
$sth->execute();
while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$wantcat = $ref->{'ID'};
	$wantcat2 = $ref->{'CATDEST'};

	$q1 = "select count(*) from rcatdb_categories where id = $wantcat";
	($count) = $dbh->selectrow_array($q1);

	if ($count && $wantcat2) {
		$q2 = "select count(*) from rcatdb_categories where id = $wantcat2";
		($count) = $dbh->selectrow_array($q2);
	} 

	if (! $count) {
		print "Deleting relation for $wantcat";
		$dbh->do("delete from rcatdb_rcats where id = $wantcat");
	}
}



$q = "select * from rcatdb_items";
$sth = $dbh->prepare($q);
$sth->execute();
while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$wantcat = $ref->{'CID'};
	$itemid = $ref->{'ID'};

	$q1 = "select count(*) from rcatdb_categories where id = $wantcat";
	($count) = $dbh->selectrow_array($q1);

	if (! $count) {
		print "Would delete because of no cat item ".$ref->{'NAME'};
#		$dbh->do("delete from rcatdb_items where id = $itemid");
	}
}

$q = "select * from ab_biz_org";
$sth = $dbh->prepare($q);
$sth->execute();
while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$wantid = $ref->{'ID'};
	
	$q1 = "select count(*) from rcatdb_items where id = $wantid";
	($count) = $dbh->selectrow_array($q1);

	if (! $count) {
		$dbh->do("delete from ab_biz_org where id = $wantid");
		print "Deleting from ab_biz_org because no item id\n";
	}
}


$q = "select * from ab_location";
$sth = $dbh->prepare($q);
$sth->execute();
while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$wantid = $ref->{'ID'};
	
	$q1 = "select count(*) from rcatdb_items where id = $wantid";
	($count) = $dbh->selectrow_array($q1);

	if (! $count) {
		$dbh->do("delete from ab_location where id = $wantid");
	}
}



	
$q = "select * from rcatdb_ritems";
$sth = $dbh->prepare($q);
$sth->execute();
while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$wantid = $ref->{'ID'};
	$wantcat = $ref->{'CAT_DEST'};
	
	$q1 = "select count(*) from rcatdb_items where id = $wantid";
	($count) = $dbh->selectrow_array($q1);

	if (! $count) {
		$dbh->do("delete from rcatdb_ritems where id = $wantid");
	}

	if ($wantcat and ($ref->{'RELATION'} eq 'BELONGS_TO')) {
		$q2 = "select count(*) from rcatdb_categories where id = $wantcat";
		($count) = $dbh->selectrow_array($q2);
		if (! $count) {
			print "Deleting item $wantid cat $wantcat from ritems\n";
		 	$dbh->do("delete from rcatdb_ritems where id = $wantid");
		}
	}

}

1;
