#!/usr/local/bin/perl

# abmake_rss.pl

# produce rss file for latest items from given subcat

$SHOW_FROM_LEVEL = 2;  # we are showing only under /root/UserDefined

#$ROOTCAT = 43154; # Dallas
$ROOTCAT = 301; # Tucson
$ROOTLEVEL = 2;

$EXCLUDE_CAT = 43179;	# rss news postings - don't repost!
$EXCLUDE_LEVEL = 4;

$MAX_ITEMS = 355;

$MAX_ITEM_LENGTH = 800;	# how much of short_content should we show on cat page

$MIN_FRONTPAGE_INTEREST = 20;  # only show good images on the front page

#use Smart::Comments;

use File::Find;
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
use AbDomains;
use Mysql;
use CommandWeb;
use AbCat;
use Abra;

use XML::RSS;

	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$ADMINUSER = 1;
$debug = 0;

%HAVECATS =();

# HACK for testing
$rootdom = 'bTucson.com';

# should use abDomains to set all domain-specific variables
$abdomain = new AbDomains($rootdom);

$ROOT_TARGET_DIR = '/home/sites/iwtucson/www';

$TARGET_FILE_NAME = 'rss.xml';

$gencat = $ARGV[0];

$target_file = $ARGV[1] || $ROOT_TARGET_DIR.'/'.$TARGET_FILE_NAME;

my %templatehash = ();

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

$curdir = `pwd`;
chomp $curdir;
$curcat = 0;
$rootcat = 0;
$target_dir = '';
$template_file = '';

# check dir for .catid or .catname, set defaultcat
if ( -e "PARENT_CAT_ID" ) {
	open F,"PARENT_CAT_ID";
	$rootcat = <F>;
	close F;
}
chomp $rootcat;


$q = "select catcode from rcatdb_categories where id = $ROOTCAT";
($rootcatcode) = $dbh->selectrow_array($q);

$rootcatcode = $dbh->quote($rootcatcode);

$q = "select catcode from rcatdb_categories where id = $EXCLUDE_CAT";
($exclude_catcode) = $dbh->selectrow_array($q);

$exclude_catcode = $dbh->quote($exclude_catcode);


# TODO this should be done item by item so we don't miss those with
# optional types missing
@apply_types = ('ab_biz_org');

my $rss = new XML::RSS (version => '1.0');
$rss->channel( 
	title	=>  "bTucson.com",
	link	=>  "http://bTucson.com",
	description => "the Tucson Superblog - read and add comments about any business, place or idea related to Tucson, Arizona",
	dc => {
		date => $today,
		subject =>  "Tucson, Arizona latest blog postings",
		creator =>  'admin@btucson.com',
		publisher => 'admin@btucson.com',
		rights  => 'Copyright 2007, Internet WorkShop',
		language => 'en-us',
	},
	syn => {
		updatePeriod	=> "daily",
		updateFrequency	=> "1",
	},
	taxo => [
		'http://www.dmoz.org/Regional/North_America/United_States/Arizona/Localities/T/Tucson/'
	]
);

 $rss->textinput(
   title        => "quick finder",
   description  => "Use the text input below to search bTucson.com",
   name         => "query",
   link         => "http://btucson.com/cgi-bin/wgtuc/webglimpse.cgi",
 );

$q = "select rcatdb_items.*, rcatdb_categories.rel_url from rcatdb_items,rcatdb_categories where rcatdb_items.security_level = 0 and LEFT(itemcode, $ROOTLEVEL) = LEFT($rootcatcode, $ROOTLEVEL)and LEFT(itemcode, $EXCLUDE_LEVEL) <> LEFT($exclude_catcode, $EXCLUDE_LEVEL) and rcatdb_items.cid = rcatdb_categories.id  and effective_date > DATE_SUB(CURDATE(), INTERVAL 7 DAY) order by id desc ";
print "Query is $q\n";
$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $itemlink = 'http://bTucson.com'.$ref->{'REL_URL'}.$ref->{'ID'};

	my $descrip = substr($ref->{'SHORT_CONTENT'}, 0, 252);
	$descrip =~ s/\s[^\s]+$//;  # cut off last partial word
	$descrip .= '...';

	$rss->add_item(
		title => $ref->{'NAME'},
		link => $itemlink,
		description => $descrip,

# TODO here - add namespace
# see http://search.cpan.org/~abh/XML-RSS-1.31/lib/XML/RSS.pm
#		my => {
#			category => $ref->{'REL_URL'},	
#		}
	);
}
$sth->finish;
$dbh->disconnect;

$rss->{output} = '1.0';

$rss->save($target_file);

1;

