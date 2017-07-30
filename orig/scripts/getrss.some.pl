#!/usr/bin/perl

use XML::RSS::Parser;
use Date::Manip;

BEGIN {
	unshift @INC, "/w/abra/lib";
}
use AbCat;
use AbUtils;
use AbHeader;
use Abra;

my $p = XML::RSS::Parser->new;

%feeds = (
	'weather','http://rss.weather.com/weather/rss/local/85713?cm_ven=LWO&cm_cat=rss&par=LWO_rss',
);
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';

$BASEDIR = '/home/sites/iwtucson/www/inc/news/';
$DAILYNEWSCAT = 43179;
$OWNER = 1;

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}


# add category /Tucson/News/Daily/[today's date]
$date = ParseDate("today");
$today = UnixDate($date, "%b %d, %Y");

my $newscat = &AbUtils::add_subcat(cid=>$DAILYNEWSCAT,newcatname=>$today,owner=>$OWNER);

# Retrieve feed
# add each item in this category
# get excerpt (1st several words)?


foreach my $fname (keys %feeds) {

	my $file = $BASEDIR . $fname. '.html';
	open F, ">$file";

	my $feed = $p->parse_uri($feeds{$fname});

	next unless $feed;

 	my $feed_title = $feed->query('/channel/title');
 	foreach my $i ( $feed->query('//item') ) { 
     		my $title = $i->query('title')->text_content;
     		my $link = $i->query('link')->text_content;

		if ($fname eq 'jobs') {
			next if ($title =~ /work from/i);
			next if ($title =~ /per day/i);
		}

		if ($title && $link) {
			# maybe should allow comment about jobs too, but not here
			if ($newscat && ($fname ne 'jobs') && ($fname ne 'weather') ) {
				my $item_title = $title." - ".$feed_title;
				&AbUtils::add_item(cid=>$newscat,item_owner=>$OWNER,itemname=>$item_title,url=>$link,security_level=>0);
			}
    	 		print F "<A TARGET='btucson_external' HREF='$link'>$title</A><br>\n";
     			print F "\n"; 
		}
	}
	close F;
}
1;
