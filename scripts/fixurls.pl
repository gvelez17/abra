#!/usr/local/bin/perl 

BEGIN { unshift @INC, '/w/abra/lib'; }

use AbHeader;
use Abra;
use AbCat;
use AbUtils;

#$ROOTCAT = 308;
$ROOTCAT=43154;
$ROOTLEVEL = 2;
$show_from_level = 1;

$ab = new Abra;

#$cat = new AbCat($catid);

$q = "select catcode from rcatdb_categories where id = $ROOTCAT";
($rootcatcode) = $dbh->selectrow_array($q);

$rootcatcode = $dbh->quote($rootcatcode);

$q = "select * from rcatdb_categories where ((REL_URL is NULL) OR (REL_URL = '')) AND LEFT(catcode, $ROOTLEVEL) = LEFT($rootcatcode, $ROOTLEVEL) order by id ";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $catid = $ref->{'ID'};
	my $route = &AbUtils::make_route_from_cid($catid);

	my $relurl = '/';
	for (my $j = $#$route - $show_from_level; $j >=0; $j--) {
		my $p = $$route[$j];
		$relurl .= $p->{'NAME'}.'/';
	}
	my $q1 = "update rcatdb_categories set REL_URL = ".$dbh->quote($relurl)." where ID = $catid and (REL_URL = '' OR REL_URL is NULL) ";
	$dbh->do($q1);
	print "RELURL for $ref->{'NAME'} is $relurl \n";
}
$sth->finish;
$dbh->disconnect;
1;
