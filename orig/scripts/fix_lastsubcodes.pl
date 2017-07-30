#!/usr/local/bin/perl -T

# utils
# grab subtrees from structure table (has ODP) and stick into rcatdb_cats under appropriate category

# ex: ./fix_lastsubcodes.pl 66906 '
 
BEGIN {
      unshift (@INC, '/w/abra/lib');
}

use AbHeader qw(:all);
use Abra;
use AbCat;
use AbUtils;
use AbMacros;

$ab = new Abra;

#$LIMIT = "limit 50";
$LIMIT = '';

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}
$usage = "Usage: fix_lastsubcodes.pl [parent_cat_id]\n";
$parentcat = $ARGV[0] || die($usage);

# put in ref to original dmoz id


($parent_catcode) = $dbh->selectrow_array("select catcode from rcatdb_categories where id = $parentcat");


@parent_catcode = unpack "C16", $parent_catcode;
$parent_catlevel = &AbUtils::GetLevelfromCatcode($parent_catcode) + 1;

$parent_catcode_str = &AbUtils::catcodestr($parent_catcode);

print "Working on catcode $parent_catcode_str\n";


%CAT_ID = ();


$qcatcode = $dbh->quote($parent_catcode);


$CAT_ID{$parent_catcode} = $parentcat;

#$q = "select * from rcatdb_categories where id = 306 or cid = 30 or cid = 306";
$q = "select id, catcode, lastsubcode from rcatdb_categories where LEFT(catcode, $parent_catlevel) = LEFT($qcatcode, $parent_catlevel) $LIMIT";

print "Query is $q\n\n";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

print "Found ",$sth->rows()," rows\n";

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $mcatid = $ref->{'ID'};
	my $mcatcode = $ref->{'CATCODE'};
	my $mlastsubcode = $ref->{'LASTSUBCODE'};



		my $q1 = "select count(*) from rcatdb_categories where cid = $mcatid";
		my ($numsubcats) = $dbh->selectrow_array($q1);
	
		my $q2 = "update rcatdb_categories set lastsubcode = $numsubcats where id = $mcatid";

		print "Fixing: $q2\n";

		$dbh->do($q2);
}

$sth->finish;


1;



