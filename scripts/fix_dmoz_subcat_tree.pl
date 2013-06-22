#!/usr/local/bin/perl -T

# utils
# grab subtrees from structure table (has ODP) and stick into rcatdb_cats under appropriate category

# ex: ./fix_dmoz_subcat_tree.pl 66906 '
 
BEGIN {
      unshift (@INC, '/w/abra/lib');
}

use AbHeader qw(:all);
use Abra;
use AbCat;
use AbUtils;
use AbMacros;

$ab = new Abra;

$LIMIT = "limit 50";
#$LIMIT = '';

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}
$usage = "Usage: fix_dmoz_subcat_tree.pl [parent_cat_id]\n";
$parentcat = $ARGV[0] || die($usage);

# put in ref to original dmoz id


($parent_catcode) = $dbh->selectrow_array("select catcode from rcatdb_categories where id = $parentcat");


@parent_catcode = unpack "C16", $parent_catcode;
$parent_catlevel = &AbUtils::GetLevelfromCatcode($parent_catcode) + 1;

$parent_catcode_str = &AbUtils::catcodestr($parent_catcode);

$right_no = 16 - $parent_catlevel;

%CAT_ID = ();


$qcatcode = $dbh->quote($parent_catcode);


##### UNFINISHED CODE *************

warn("This program wasn't finished! \n");
exit;

$CAT_ID{$parent_catcode} = $parentcat;

#$q = "select * from rcatdb_categories where id = 306 or cid = 30 or cid = 306";
$q = "select catid, catcode, title,lastsubcode from structure where LEFT(catcode, $parent_catlevel) = LEFT($qcatcode, $parent_catlevel) $LIMIT";

print "Query is $q\n\n";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

print "Found ",$sth->rows()," rows\n";

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $mcatid = $ref->{'CATID'};
	my $mcatcode = $ref->{'CATCODE'};
	my $mcatname = $dbh->quote($ref->{'TITLE'});
	my $numsubcats = $ref->{'LASTSUBCODE'};

	my $mcatcodestr = &AbUtils::catcodestr($mcatcode);

print "\n\nGot cat $catname with $numsubcats subcategories code $mcatcodestr\n";

	if (! $mcatcode) {

		

	if (($mcatcode eq $catcode) && $newcatname ) {  # use our special name
		$mcatname = $dbh->quote($newcatname);
	}

	my @mcatcode = unpack "C16", $mcatcode;
	my @newcatcode = @parent_catcode;
	my $n = $parent_catlevel;
	for ($j=$dmoz_lvl; $j<16; $j++) {
		$newcatcode[$n] = $mcatcode[$j];
		$n++;
	}

	my $newcatcode = pack "C16",@newcatcode;
	my $catcodestr = &AbUtils::catcodestr($newcatcode);
print "New catcode is $catcodestr\n";
	my $qcatcode = $dbh->quote($newcatcode);

	$parentid = &getparent($newcatcode) || $parentcat;

	# check if exists
	my ($oldid) = $dbh->selectrow_array("select id from rcatdb_categories where catcode = $qcatcode limit 1");

	if (! $oldid) {

		my $nq = "insert into rcatdb_categories set cid=$parentid, name=$mcatname, catcode = $qcatcode";

print "inserting $nq\n";

		$dbh->do($nq);

		my ($newid) = $dbh->selectrow_array("select id from rcatdb_categories where catcode = $qcatcode limit 1");

	print "Result new id $catcodestr:$newid\n";
		$catcodestr =~ s/(\:0)+$//g;
		$CAT_ID{$catcodestr} = $newid;	
	}
}

# now fix parent cat (catid) and also lastsubcode

1;

sub getparent {
	my $catcode = shift;
	my $catlevel = &AbUtils::GetLevelfromCatcode($catcode) + 1;

	my $parentcat = substr($catcode, 0, $catlevel -1);
	my $parentstr =  &AbUtils::catcodestr($parentcat);
	$parentstr =~ s/(\:0)+$//g;
print "Looking up id for parent " . $parentstr."\n";

	my $parentid = $CAT_ID{$parentstr};
	return $parentid;
}

sub MakeParentCatFile{
	my $topdir = shift;
	my $catcode = shift;

	my $catfile = $topdir;

	my @catcode = unpack "C16", $catcode;

#print "Right off, catcode is @catcode\n";

	my $mcat = pop @catcode;
	$j = 15;
	while (($j > 0) && ! $mcat ) {
		$mcat = pop @catcode;
		$j--;
	}

# We don't push it back on because we want to write into our parent's index
#	if ($mcat) { push @catcode, $mcat; }

	$catfile .= join('/',@catcode);
#print "Tried join of $catlen items to get directory $catfile\n";
	$catfile .= '/index.html';
	if (-e $catfile) {
		return $catfile;
	} 

	my $wdir = $topdir;

	$j = 0;
        while (($mcat = shift @catcode) && ($j < 16)) {

#print "shifted $mcat...now catcode is ",@catcode,"...";
		$wdir .= '/'.$mcat;
		if (! -d $wdir) {
			mkdir ($wdir, 0755);
		}

		$j++;
	}

#print "Now I think it is $wdir\n";
	$catfile = $wdir . '/index.html';

	return $catfile;
}

sub make_catcodedir {

        my $code = shift;

        my @catcode = unpack "C16",$code;
        $j = 0;
        my $catcodestr = '';
        while (($j < 17) && ($catcode[$j] ne '0')) {
                $catcodestr .= $catcode[$j];
                $catcodestr .= "/";
                $j++;
        }
        chop $catcodestr;
        return $catcodestr;
}
