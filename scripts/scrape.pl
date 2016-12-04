#!/usr/local/bin/perl

# scrape.pl

# import static links into rcats

use Carp;
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC,"/w/abra/cgi");
}

use AbHeader qw(:all);
use AbUtils;
use AbSecure;
use AbMacros;
use RCategories;
use Mysql;
use CommandWeb;


	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.btucson.com/cgi/ab.pl";
	$ADMINUSER = 1;

$debug = 1;


# HACK for testing
$rootdom = 'iwtucson.com';

$SHOWDELMASK = 1;
my %templatehash = ();

%fakein = ();
$inref = \%fakein;  # We need this global for AbUtils - passing ref wasn't working!


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

$file = $ARGV[0] || die("No file to process. Usage: \n scrape.pl [filename] [cat] \n");
$rootcat = $ARGV[1] || die("No root cat.  Usage: \n scrape.pl [filename] [cat] \n");

chomp $rootcat;

open F,$file || die("Cant open file $file");
my @lines = <F>;
close F;

my $src = join('',@lines);

my @p = split(/\n\n/, $src);

print "Read ",$#lines," lines and made into ",$#p," paragraphs, source was \n$src";

$subcatname = '';
$curcat = $rootcat;
foreach (@p) {

	if (/<H3><I>([^<]+)<\/I><\/H3>/i) {
		$subcatname = $1;
	 	$curcat = &AbUtils::add_subcat('cid'=>$rootcat, 'newcatname'=>$subcatname);
		print "Added subcategory $subcatname";
		next;
	}

	if (/<p><A HREF="([^"]+)">([^<]+)<\/A>([^<]+)<\/p>/i) {
		$url = $1;
		$title = $2;
		$desc = $3;
	
		%fakein = ();
		$fakein{'URL'} = $url;
		$fakein{'SHORT_CONTENT'} = $desc;

		$newid = &AbUtils::add_item(
			'itemowner'=>0,
			'security_level'=>0,
			'cid'=>$curcat,
			'itemname'=>$title,
			'iref'=>\%fakein
		);

		print "$newid : Added item $title : $url : $desc \n";

	}
}

print "Done.";
1;



