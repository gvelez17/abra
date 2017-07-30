#!/usr/local/bin/perl

# wgout.pl

# produce text file of relevent fields suitable for fast searching by glimpse

# Also produce url list of items for google sitemap

$ROOTCAT = 43154;  # /Dallas
$ROOTLEVEL = 2;

use Smart::Comments;
use Carp;
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC,"/w/abra/cgi");
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

%urls = ();

	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';

$TARGET_FILE = '/home/sites/bdallas/data/wgdata.txt';

$CAT_TARGET_FILE = '/home/sites/bdallas/data/wgcats.txt';

$URL_TARGET_FILE = '/home/sites/bdallas/www/external-urls.txt';

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

# print items with business listings

open F, ">$TARGET_FILE";
open U, ">$URL_TARGET_FILE";
$qc = "select LEFT(catcode, $ROOTLEVEL) from rcatdb_categories where id = $ROOTCAT";
my ($rootcatcode) = $dbh->selectrow_array($qc);

print "Rootcatcode is $rootcatcode with length ", length($rootcatcode),"\n\n";

$rootcatcode = $dbh->quote($rootcatcode);

$q = "select rcatdb_items.id, rcatdb_items.url, rcatdb_items.rank, rcatdb_items.name, rcatdb_items.short_content, ab_biz_org.addr, ab_biz_org.zip, ab_biz_org.phone, rcatdb_items.effective_date from rcatdb_items, ab_biz_org where LEFT(itemcode, $ROOTLEVEL) = $rootcatcode and security_level=0 AND rcatdb_items.id = ab_biz_org.id order by rcatdb_items.rank desc, rcatdb_items.effective_date desc, rcatdb_items.name asc ";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

warn (" for $q There are ".$sth->rows()." rows\n");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	$ref->{'SHORT_CONTENT'} =~ s/\n/<br>/g;

	print F $ref->{'ID'},"\t",$ref->{'RANK'},"\t",$ref->{'NAME'},"\t",$ref->{'ADDR'},"\t",$ref->{'ZIP'},"\t",$ref->{'PHONE'},"\t",$ref->{'EFFECTIVE_DATE'},"\t",$ref->{'SHORT_CONTENT'},"\n";

	my $url = $ref->{'URL'};
	if (! $urls{$url} && ($url =~ /^http/)) {
		print U "<A HREF='$url'></A>\n";
		$urls{$url} = 1;
	}

}
$sth->finish;

# now print items without business listings

$q = "select rcatdb_items.id, rcatdb_items.url, rcatdb_items.rank, rcatdb_items.name, rcatdb_items.short_content,rcatdb_items.effective_date from rcatdb_items LEFT JOIN ab_biz_org ON rcatdb_items.id = ab_biz_org.id where ab_biz_org.id IS NULL and LEFT(itemcode, $ROOTLEVEL) = $rootcatcode and security_level=0 order by rcatdb_items.rank desc, rcatdb_items.effective_date desc, rcatdb_items.name asc";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

warn ("for $q There are ".$sth->rows()." rows\n");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

        $ref->{'SHORT_CONTENT'} =~ s/\n/<br>/g;

        print F $ref->{'ID'},"\t",$ref->{'RANK'},"\t",$ref->{'NAME'},"\t\t\t\t",$ref->{'EFFECTIVE_DATE'},"\t",$ref->{'SHORT_CONTENT'},"\n";

        my $url = $ref->{'URL'};
        if (! $urls{$url} && ($url =~ /^http/)) {
                print U "<A HREF='$url'></A>\n";
                $urls{$url} = 1;
        }

}
$sth->finish;



close F;
close U;

print "\n\n-----------------now processing $CAT_TARGET_FILE -----------------------\n";

# print categories
open G, ">$CAT_TARGET_FILE";

$q = "select id, name, rel_url from rcatdb_categories where LEFT(catcode, $ROOTLEVEL) = $rootcatcode AND security_level=0";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

warn ("for $q There are ".$sth->rows()." rows\n");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	print G $ref->{'ID'},"\t",$ref->{'NAME'},"\t",$ref->{'REL_URL'},"\n";

}
$sth->finish;
$dbh->disconnect;
close G;


1;

