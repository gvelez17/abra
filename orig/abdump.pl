#!/usr/local/bin/perl
# Path to RCategories

use AbHeader qw(:all);
use AbUtils;
use RCategories;
use Mysql;

&Init;
&AbConnect;	# sets obj, dbh

$q = "select * from $ITEM_TABLE";
$sth = $dbh->prepare($q) || die("Unable to prepare $q");
$sth->execute() || die("unable to execute $q");

#foreach item in rcatdb_items 
while ($ref = $sth->fetchrow_hashref('NAME_uc')) {
	
	generate or lookup catcode 
	
	foreach field {
	
		print "catcode:itemid:fieldname:value"
	}
		
	foreach table in types (dependent content) {
		
		get fields
		foreach field {
			print "catcode:itemid:TYPE tablename:fieldname:value"
		}
	}
	
	if value isurl or isfile {
		add url to wg_toindex w/catcode:itemid as extra data
	}
}
$sth->finish;

#index & search generated dump file + urls in wg_toindex

# Set global variables; used as sub for brevity
sub Init {
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
}

sub AbConnect {	
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
}

