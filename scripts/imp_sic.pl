#!/usr/local/bin/perl

#!/usr/local/bin/perl -T

BEGIN {
      unshift (@INC, '.');
        unshift(@INC, "/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbCat;
use AbAcct;
use Abra;
use Mysql;

        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';

$EDITOR_ID = 7886; # Tracy

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        warn "Error - cannot get database handle\n";
        exit;
}

$dbh->{FetchHashKeyName} = 'NAME_uc';

$SIC_CAT_ID = 43224;

open F, "sic.txt" || die("Can't open sic.txt for reading\n");

$maxlines = 30000;

$j = 0;

while (<F>) {
	$j++;
	last if ($j>$maxlines );

	chomp;

	my $sic = '';
	my $name = '';
	if (/^([^\*]+)\*\s+(.+)$/) {
		$sic = $1;
		$name = $2;
	} else {
		print $_," doesn't match pattern\n";
		next;
	}

	# Do we already have this category?
	my $q = "select id from rcatdb_categories where external_uri = 'SIC:$sic'";
	my ($have_id) = $dbh->selectrow_array($q);
	
	if ($have_id) {
		print "We already have $sic: $name\n";
		next;
	}

	# If not, generate a catcode and add this cat
	
	# unless it ends with 99, those are redundant
	# (when we add items, we strip off the 99's for the cat)
	next if ($sic =~ /99$/);

	# fix up the name
	$name =~ s/\,*\s*nec\s*$//i;
	$name =~ s/\,*\s*Not Elsewhere Classified//i;

	# find the parent category
	$parent_cat = $SIC_CAT_ID;
	$parent_code = $sic;
	chop $parent_code; chop $parent_code;
	$parent_code =~ s/99$//g;
	if ($parent_code) {
		my $q1 = "select id from rcatdb_categories where external_uri = 'SIC:$parent_code'";
		($parent_cat) = $dbh->selectrow_array($q1);
	} 

	if (! $parent_cat) {
		print "ERR cannot find valid parent cat for $sic\n";
		warn "ERR cannot find valid parent cat for $sic\n";
		next;
	}

	$newcatid = &AbUtils::add_subcat('cid'=>$parent_cat,
			'newcatname'=>$name,
			'owner'=>$EDITOR_ID );

	if ($newcatid) {
		my $q2 = "update rcatdb_categories set external_uri = 'SIC:$sic' where id = $newcatid";
		$dbh->do($q2);
	} else {
		warn "ERR insert cat failed on $name, $sic under $parent_cat\n";
	}

}
1;

