#!/usr/local/bin/perl

# import school data
$filename = "raw_schools.csv";
$CAT = 308;
$ROOTLEVEL = 3;

use Carp;
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC,"/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbSecure;
use AbMacros;
use Mysql;
use CommandWeb;
use AbCat;
use Abra;


	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.info/cgi/ab.pl";
	$ADMINUSER = 1;
$debug = 1;

%HAVECATS =();

# Use MySQL (or DBI) to connect
$abra = new Abra;

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

open F, "raw_schools.csv" || die("cant open file");
$DI = 32201;
$EL = 32202;
$JR = 32203;
$HI = 32204;
$PR = 32205;
$CH = 32206;
$UN = 32207;
$DB = 32208;
$VI = 32209; 

$max = 2000;
$j = 0;
while(<F>) {
	chomp;
	@f = split(",");
	for($i=0; $i<=$#f; $i++){
		$f[$i] =~ s/^"(.+)"$/$1/;
	}
	($type, $dist, $name, $addr, $city, $grd, $zip, $phone, $url, $admin) = @f;

print "Got $name for grades $grd in dist $dist run by $admin\n";
	$from_grade = 0;
	$to_grade = 0;
	if ($grd =~ /^\s*(\d+)\-(\d+)/) {
		$from_grade = $1;
		$to_grade = $2;
	} elsif ($grd =~ /^\s*K\-(\d+)/){
		$from_grade = 0;
		$to_grade = $1;
	} elsif ($grd =~ /^\s*PreK\-(\d+)/){
                $from_grade = -1;
                $to_grade = $1;
	} else {
		warn("Can't parse FROM grade from $grd\n");
	}
#print "Goes from $from_grade to $to_grade\n";

	# apply all relevent categories
	@catlist = ();
	
	if ($type eq 'C') {
		push @catlist, $CH;
	} elsif ($type eq 'P') {
		push @catlist, $PR;
	} elsif ($type eq 'V') {
		push @catlist, $VI;
	}

	if ($from_grade < 6) {
		push @catlist, $EL;
	}
	if ($to_grade > 8) {
		push @catlist, $HI;
	}
	if (($from_grade<=7) && ($to_grade>=8)) {
		push @catlist, $JR;
	}

	$catid = $catlist[0];

print "Primary category is $catid\n";

	if (! $catid) {
		warn "No category for $name\n";
		next;
	}
	$qname = $dbh->quote($name);
	$qurl = $dbh->quote($url);

	$qcheck = "select * from rcatdb_items where name = $qname";
        $sth = $dbh->prepare($qcheck);
        $sth->execute;
        $res = $sth->fetchrow_hashref('NAME_uc');

	$ADD_SCHOOL = 1;


        if ($res->{'ID'}) {
		print "$name is already in the database, not adding\n";
		$ADD_SCHOOL = 0;
	}

	if ($ADD_SCHOOL) {
		$q = "insert into rcatdb_items set cid = $catid, security_level = 0, name = $qname, url = $qurl";
		$dbh->do($q);
	}

        my ($newid, $newcat) = $dbh->selectrow_array("select id,cid from rcatdb_items where name = $qname");
	
	$newid || die("Insert seems to have failed for $qname");

print "ID is $newid\n\n";

	# we may have to add even primary cat
	for (my $catj=0; $catj<=$#catlist; $catj++) {
		my $nextcat = $catlist[$catj];

		next if ($nextcat == $newcat);  # already in primary cat

		my $qcheck = "select * from rcatdb_ritems where id = $newid and cat_dest = $nextcat";
	        my $sth = $dbh->prepare($qcheck);
        	$sth->execute;
        	my $res = $sth->fetchrow_hashref('NAME_uc');
 		if ($res->{'RELATION'} eq 'BELONGS_TO') {
			next;
		}
		my $qq = "insert into rcatdb_ritems set ID = $newid, RELATION = 'BELONGS_TO', CAT_DEST = $nextcat";
		$dbh->do($qq);
	}


	$qcheck = "select * from ab_biz_org where id = $newid";
        my $sth = $dbh->prepare($qcheck);
        $sth->execute;
        my $res = $sth->fetchrow_hashref('NAME_uc');
        if ($res->{ID}) {
		if ($res->{ADDR} ne $addr) {
			print "We had address $res->{ADDR} would set it to $addr\n";
		}
	} else {
		$q1 = "insert into ab_biz_org set id = $newid, addr = ".$dbh->quote($addr).",phone = ".$dbh->quote($phone).",zip = ".$dbh->quote($zip).",city = ".$dbh->quote($city);

		$dbh->do($q1);
	}

        $qcheck = "select * from ab_school where id = $newid";
        my $sth = $dbh->prepare($qcheck);
        $sth->execute;
        my $res = $sth->fetchrow_hashref('NAME_uc');
        if (! $res->{ID}) {
	
		$q2 = "insert into ab_school set id = $newid, school_type = ".$dbh->quote($type).",district = ".$dbh->quote($dist).",from_grade = $from_grade, to_grade = $to_grade, administrator = ".$dbh->quote($admin).",grades = ".$dbh->quote($grd).",degrees = ''";
		$dbh->do($q2);
	}

	
	$j++;
	last if $j > $max;
}

close F;

1;
