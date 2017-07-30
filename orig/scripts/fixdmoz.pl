#!/usr/local/bin/perl 

# add catcodes to dmoz categories

BEGIN { unshift @INC, '/w/abra/lib'; }

use AbHeader;
use Abra;
use AbCat;
use AbUtils;
use AbODP;

$ROOTCAT=43155;
$ROOTLEVEL = 1;

#$LIMIT = "limit 20";
$LIMIT = '';

# assign Top manually

$ab = new Abra;

my $q = "select catcode from rcatdb_categories where id = $ROOTCAT";
my ($rootcatcode) = $dbh->selectrow_array($q);

my $q1 = "select catid, topic, catcode from structure where catcode IS NULL $LIMIT";

$sth = $dbh->prepare($q1);

$sth && $sth->execute() || die("Can't execute $q");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

        my $dmoz_catid = $ref->{'CATID'};
	my $topic = $ref->{'TOPIC'};
	my $catcode = $ref->{'CATCODE'};

	if (! $catcode) {
		&AbODP::MakeCatCodes($dmoz_catid, $topic);  # goes back up tree
						# makes catcodes coming down
		# print "\nRan MakeCatCodes for $topic\n";
	}
}

$dbh->disconnect;

1;

