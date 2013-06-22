#!/usr/local/bin/perl -T

# imports data from odditysoftware.com Arizona business listings database

# for specific city

#$BIZCAT = 32264;   # Marana/Business Directory
#$BIZCITY = 'Marana';
$BIZCAT = 42499;   # /Business Directory
$BIZCITY = 'Ajo';
$LVL = 5;
$BLANKS = 9;

$LIMIT = 10000;

# utils
 
BEGIN {
      unshift (@INC, '/w/abra/cgi');
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

$userid = 1;

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}


%letids = ();
for $let (A..Z) {

	my $q = "select id from rcatdb_categories where cid = $BIZCAT and name = ".$dbh->quote($let);
	my ($letid) = $dbh->selectrow_array($q);


	$letid{$let} = $letid ? $letid : &AbUtils::add_subcat('cid'=>$BIZCAT, 'newcatname'=>$let);
	print "$let : $letid\n";

}
@blanks = (0) x 16;
$blankcat = pack "C16",@blanks;
$blankcat = $dbh->quote($blankcat);

$cq = "select LEFT(catcode,$LVL) from rcatdb_categories where id = $BIZCAT";
($rootcatcode) = $dbh->selectrow_array($cq);
$rootcatcode = $dbh->quote($rootcatcode);

$q = "select * from biz_arizona where bizCity = ".$dbh->quote($BIZCITY)." LIMIT $LIMIT";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

$EDITOR_ID = 7080;

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	# check if category exists AT LEVEL 5 under business directory
	my $bizcat = $ref->{'BIZCAT'};
	my $qr = "select rcatdb_categories.id from rcatdb_categories where rcatdb_categories.NAME = ".$dbh->quote($bizcat)." AND RIGHT(catcode,$BLANKS) = RIGHT($blankcat,$BLANKS) and LEFT(catcode,$LVL) = $rootcatcode";

	my ($catid) = $dbh->selectrow_array($qr);

	if ($catid) {
		print "major category $bizcat already in place\n";
	}
	
	# add if not
	if (! $catid) {
		$let = substr($bizcat,0,1);
		$letid{$let} || warn("INvalid letter in $bizcat\n") && next;
		$catid = &AbUtils::add_subcat('cid'=>$letid{$let}, 'newcatname'=>$bizcat, 'owner'=>$EDITOR_ID);
		print "Added category $bizcat in subcat $let id $letid{$let}\n";
	}
	next unless $catid;	

	# check if subcategory exists UNDER THIS CATEGORY already
	my $bizsubcat = $ref->{'BIZCATSUB'};
        $qr = "select id,cid from rcatdb_categories where NAME = ".$dbh->quote($bizsubcat)." AND cid = $catid";
        my ($subcatid,$parentcat) = $dbh->selectrow_array($qr);

        # add if not
        if ($bizsubcat && (! $subcatid)) {
                $subcatid = &AbUtils::add_subcat('cid'=>$catid, 'newcatname'=>$bizsubcat, 'owner'=>$EDITOR_ID);
                print "Added subcategory $bizsubcat to category $catid\n";
        } 

	$usecatid = $subcatid || $catid;
		
	# add item data

	$qr = "select rcatdb_items.id,cid from rcatdb_items,ab_biz_org where NAME = ".$dbh->quote($ref->{'BIZNAME'})." and LEFT(itemcode, $LVL) = $rootcatcode and rcatdb_items.id = ab_biz_org.id and ab_biz_org.addr = ".$dbh->quote($ref->{'BIZADDR'});
	my ($bizid,$curcat) = $dbh->selectrow_array($qr);

	if ($bizid) {
		print "Already have this business $ref->{'BIZNAME'}\n";

		next if ($curcat == $usecatid);

		my ($have_rel) = $dbh->selectrow_array("select count(*) from rcatdb_ritems where ID = $bizid AND CAT_DEST = $usecatid");

		if (! $have_rel) {
			$qr = "insert into rcatdb_ritems set id = $bizid, RELATION='BELONGS_TO', CAT_DEST = $usecatid";
			$dbh->do($qr);

		}

		my ($have_cat_rel) = $dbh->selectrow_array("select count(*) from rcatdb_rcats where (ID = $curcat and CAT_DEST = $usecatid) or (ID = $usecatid and CAT_DEST = $curcat)");
		if (! $have_cat_rel) {
			my $qcr = "insert into rcatdb_rcats set id = $curcat, RELATION='SEE_ALSO',CAT_DEST=$usecatid";
			$dbh->do($qcr);
			print "Adding relationship between categories $curcat, $usecatid\n";
		}
		next;
	}

	my $url = '';
	if ($ref->{'BIZURL'}) {
		$url = 'http://'.$ref->{'BIZURL'};
	}

	my %morefields = (
		'URL' => $url,
		'EFFECTIVE_DATE' => '2006-01-01'
	);
	$inref = \%morefields;

	my $itemid = &AbUtils::add_item(
		'itemowner'=>$EDITOR_ID, 
		'security_level'=>0,
		'cid'=>$usecatid,
		'itemname'=>$ref->{'BIZNAME'},
		'iref'=>\%morefields
	);

	$itemid || print("Error adding item $ref->{'BIZNAME'} at URL $ref->{'BIZURL'}\n") && next;	
	
	 print("Added item $ref->{'BIZNAME'} at URL $ref->{'BIZURL'}\n");
	
	# add location data
	$qr = "insert into ab_location set id = $itemid, latitude = $ref->{'LOCLAT'}, longitude = $ref->{'LOCLONG'}, msa = $ref->{'LOCMSA'}, fips = $ref->{'LOCFIPS'}, areacode = $ref->{'LOCAREACODE'}";	

print "Adding location data: $qr\n";

	$dbh->do($qr);

	# add biz_org data
	$qr = "insert into ab_biz_org set id = $itemid, addr = ".$dbh->quote($ref->{'BIZADDR'}).", zip = ".$dbh->quote($ref->{'BIZZIP'}).", phone = ".$dbh->quote($ref->{'BIZPHONE'}).",email=".$dbh->quote($ref->{'BIZEMAIL'}).",city=".$dbh->quote($BIZCITY);
	$dbh->do($qr);


	print "did $qr\n";
}
$sth->finish;

$qs = "update rcatdb_categories set security_level = 0 where security_level is NULL";
$dbh->do($qs);
$qs = "update rcatdb_items set security_level = 0 where security_level is NULL";
$dbh->do($qs);

1;

