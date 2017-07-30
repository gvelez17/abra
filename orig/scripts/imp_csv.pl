#!/usr/local/bin/perl

## Insert Dallas data into db
#
# split fields

# match sic name to code, find category || record & next

# move over subcode & create cat under Dallas

# check if identical item exists by name, cat
# if by name only, put in special list & next

# insert item

# insert matching ab_biz_org entry

# possibly insert related person for exec
##################################################################

BEGIN {
	unshift @INC, '/w/abra/lib';
}

use Text::CSV::Simple;
use DBI;
use AbHeader;
use Abra;
use AbUtils;

$DBNAME = 'rcats';
$DBUSER = 'rcats';
$DBPASS = 'meoow';

new Abra;

$DATA_FILE = 'WPO5100700.csv';
#$DATA_FILE = 'some.csv';
$SIC_FILE = 'sic.txt';
$DALLAS_BIZ_CID = 43203;
$SIC_CID = 43224;

$ERR_FILE = "err.txt";
open ERRF,">$ERR_FILE";

# split fields nicely

my $parser = Text::CSV::Simple->new;
my @data = $parser->read_file($DATA_FILE);

# Executive Name,Company Name,Primary Address,Secondary Address,City,State,Zip Code,
#Zip+4,SIC Description,Telephone Number,URL,First Name,Middle Initial,Last Name

my $q1 = "select catcode from rcatdb_categories where id = $DALLAS_BIZ_CID";
my ($dallas_catcode) = $dbh->selectrow_array($q1);
my @dallas_code_arr = unpack "C16", $dallas_catcode;

$CAT_LEVEL = 3;  # start adding at [3], after 3 valid codes
$SIC_LEVEL = 1;  # subcode starts at [1], the 2nd byte

my $q11 = "select catcode from rcatdb_categories where id = $SIC_CID";
my ($top_sic_catcode) = $dbh->selectrow_array($q11);
my @top_sic_code_arr = unpack "C16", $top_sic_catcode;
$TOP_SUBCODE = shift @top_sic_code_arr;

foreach $aref (@data) {
	# match SIC name to code
	my $sicdesc = $aref->[8];
	my $siccode = '';

	$sicline = `grep '$sicdesc' $SIC_FILE`;
	if ($sicline =~ /^(\d+)/) {
		$siccode = $1;
	}

	$siccode || (print ERRF "No match for $sicdesc\n") && next;

	# Find our existing SIC category
	my $q = "select id, catcode,name from rcatdb_categories where external_uri = 'SIC:$siccode'";
	my ($sic_catid, $sic_catcode,$sic_name) = $dbh->selectrow_array($q);

	print "found match $sic_catid for sic code $siccode desc $sicdesc\n";

	# move over subcode and create entry under Dallas
	my @sic_code_arr = unpack "C16",$sic_catcode;

	my @biz_code_arr = @dallas_code_arr;

	$j = $CAT_LEVEL;
	$k = $SIC_LEVEL;
	while (($k<16) && $sic_code_arr[$k] && ($sic_code_arr[$k] ne '0')) {
		$biz_code_arr[$j] = $sic_code_arr[$k];
		$j++;
		$k++;
	}
	$biz_catcode = pack "C16", @biz_code_arr;

	print "Made catcodestr ".&AbUtils::catcodestr($biz_catcode)." \n";

	# do we already have the category?
	my $q2 = "select id from rcatdb_categories where catcode = ".$dbh->quote($biz_catcode);
	my ($biz_cid) = $dbh->selectrow_array($q2);

	if (! $biz_cid) {

		# insert category & parents if necessary!
		my $last_parent_cid = $DALLAS_BIZ_CID;
		for ($n = $CAT_LEVEL; $n<=$j-1; $n++) {
		
			# get code & name for parent Dallas Biz & SIC code
			@parent_code_arr = (0) x 16;
		 	for ($m=0; $m<=$n; $m++) {
				$parent_code_arr[$m] = $biz_code_arr[$m];
			}
			$parent_catcode = pack "C16", @parent_code_arr;
			my $q21 = "select id from rcatdb_categories where catcode = ".$dbh->quote($parent_catcode);
			my ($parent_cid) = $dbh->selectrow_array($q21);
			if (! $parent_cid) {
				print "Adding parent category";
				@parent_sic_arr = @parent_code_arr;
				for ($i=0; $i<$CAT_LEVEL; $i++) {
					shift @parent_sic_arr;
				}
				unshift @parent_sic_arr, $TOP_SUBCODE;


				$parent_sic_catcode = pack "C16", @parent_sic_arr;

print "We're looking for SIC code ".&AbUtils::catcodestr($parent_sic_catcode);

				my $q22 = "select name from rcatdb_categories where catcode = ".$dbh->quote($parent_sic_catcode);
				my ($parent_name) = $dbh->selectrow_array($q22);

				my $q23 = "insert into rcatdb_categories set cid = $last_parent_cid, security_level=0,".
					"name = ".$dbh->quote($parent_name).",".
					"catcode = ".$dbh->quote($parent_catcode);

print "Trying to insert $q23\n";

				$dbh->do($q23);

				my $q24 = "select id from rcatdb_categories where catcode = ".$dbh->quote($parent_catcode);
				($last_parent_cid) = $dbh->selectrow_array($q24);
			} else {
				$last_parent_cid = $parent_cid;
			}

		}
		$biz_cid = $last_parent_cid;	
	}
	
	$biz_cid || print("Error - no valid category ID\n") && next;

	# now we're ready to insert the item under this category
# Executive Name,Company Name,Primary Address,Secondary Address,City,State,Zip Code,
#Zip+4,SIC Description,Telephone Number,URL,First Name,Middle Initial,Last Name
	my ($execname, $name, $addr1, $addr2, $city, $state, $zip, $zip4, $sicdesc, $phone, $url, $fname, $mi, $lname) = @$aref;

	$name = $dbh->quote(&uncap($name));
	$addr = $dbh->quote(&uncap($addr1)."\n".&uncap($addr2));
	$city || ($city = 'Garland');
	$city = $dbh->quote(&uncap($city));
	$state = 'TX';
	$zip = $dbh->quote($zip);
	$zip4 = $dbh->quote($zip4);
	$phone = $dbh->quote(&phonify($phone));
	if ($url) {
		$url = $dbh->quote('http://'.$url.'/');
	}

	# Do we already have this item?
	my $q4 = "select id from rcatdb_items where cid = $biz_cid and name = $name";
	my ($existing_id) = $dbh->selectrow_array($q4);

	if ($existing_id) {
		print "Already have $name\n";
		next;
	}

	my $q5 = "insert into rcatdb_items set name = $name, cid = $biz_cid";
	if ($url) {
		$q5 .= ", url = $url";
	}
	$dbh->do($q5);
	my ($newid) = $dbh->selectrow_array($q4);

	$newid || print("Error - insert failed: $q5\n") && next;

	my $q6 = "insert into ab_biz_org set id = $newid, addr = $addr, zip = $zip, zip4 = $zip4, phone = $phone, city = $city";
	$dbh->do($q6);

}

close ERRF;

1;

# TODO move to utils

sub uncap {
	my $s = shift;

	$s =~ s/\B([A-Z])/lc($1)/ge;

	return $s;

}

sub phonify {
	my $p = shift;

	my $g = '';
	$g = substr($p,0,3);
        $g .= '-';
        $g .= substr($p,3,3);
        $g .= '-';
        $g .= substr($p,6);

	return $g;
}


