#!/usr/bin/perl

use XML::RSS::Parser;
use Date::Manip;
use warnings;
use Carp;

BEGIN {
	unshift @INC, "/w/abra/lib";
}
use AbCat;
use AbUtils;
use AbHeader;
use Abra;
use AbMacros;


%feeds = (
	#'starnet-local','http://rss.azstarnet.com/index.php?site=metro',
        'starnet-local', 'http://azstarnet.com/search/?f=rss&t=article&c=news/local&l=25&s=start_time&sd=desc',
	'city','http://rss.tucsonaz.gov/cgi-bin/rss.pl?feed=hottopics',
	'kvoa','http://www.kvoa.com/global/category.asp?c=40642&clienttype=rss',
#	'citizen-local','http://www.tucsoncitizen.com/altdaily/rss/local/',
	'weekly','http://www.tucsonweekly.com/Tucson/Rss.xml',
	'wire','http://news.google.com/news?q=tucson&output=rss',
#	'jobs','http://www.thingamajob.com/rss/L-Us-Tucson-Arizona-0.aspx',
#	'weather','http://rss.weather.com/weather/rss/local/85713?cm_ven=LWO&cm_cat=rss&par=LWO_rss',
#http://digg.com/rss_search?search=Tucson&area=all&type=both&section=all
);
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';

$BASEDIR = '/home/sites/iwtucson/www/inc/news/';
$NEWSCAT_DIR = '/home/sites/iwtucson/www/Tucson/News/Daily/';
$NEWS_REL_URL = '/Tucson/News/Daily';
$DAILYNEWSCAT = 43179;
$OWNER = 1;
$ITEM_RANK = 10;
$DISPLAY_MAX = 53180;

$NEWS_ITEM = 193890;
%news_content = ();

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}

my $abm = new AbMacros;

# add category /Tucson/News/Daily/[today's date]
$date = ParseDate("today");
$today = UnixDate($date, "%b %d %Y");

# create directory
$newdir = $NEWSCAT_DIR.'/'.$today;
if (! -e $newdir) {
	mkdir ($newdir, 0755);
}

my $newscatid = 0;

$q = "select id from rcatdb_categories where cid = $DAILYNEWSCAT AND name = '$today'";
($newscatid) = $dbh->selectrow_array($q);

if (! $newscatid) {
	$newscatid = &AbUtils::add_subcat(cid=>$DAILYNEWSCAT,newcatname=>$today,owner=>$OWNER);
}

my $newscat = new AbCat($newscatid);

my $disp_order = &calc_disp_order;

my $cq = "update rcatdb_categories set display_order = $disp_order where id = $newscatid";

$dbh->do($cq);

# Retrieve feed
# add each item in this category
# get excerpt (1st several words)?


foreach my $fname (keys %feeds) {
        my $p = XML::RSS::Parser->new;

	my $file = $BASEDIR . $fname. '.html';
	open F, ">$file" || die "Cannot open file $file for writing";
        my $feed;
        eval {
	  $feed = $p->parse_uri($feeds{$fname});
        };
	next unless $feed;
print "Got a feed\n";
 	#my $feed_title = $feed->query('/channel/title')->text_content;
	my $feed_title .= "$fname";
      eval {
 	foreach my $i ( $feed->query('//item') ) { 
                $item_content = '';
     		my $title = $i->query('title')->text_content;
print "Working on $title\n";
     		my $link = $i->query('link')->text_content;
                my $img = undef;
                if ($i->query('image')) {
                   $img = $i->query('image')->text_content;
                }
                my $descrip = '';
		if ($i->query('description')) {
                   $descrip = $i->query('description')->text_content;
                }
		my $pubDate = '';
		if (defined($i->query('pubDate'))) {
			$pubDate = $i->query('pubDate')->text_content || '';
		}
		if ($fname eq 'jobs') {
			next if ($title =~ /work from/i);
			next if ($title =~ /per day/i);
		}

		my $new_id = 0;
		my $item_title = '';

		if ($title && $link) {
			# maybe should allow comment about jobs too, but not here
			if ($newscatid && ($fname =~ /(starnet-local)|(citizen-local)|(kvoa)|(weekly)|(city)/) ) {
	
				my $existing = &AbUtils::get_item_by_url($link);
print "Found existing item $existing\n";
				if (! $existing) {	
					$item_title = $title." <small>(".$feed_title.")</small>";
					$new_id = &AbUtils::add_item(cid=>$newscatid,item_owner=>$OWNER,itemname=>$item_title,url=>$link,security_level=>0,short_content=>$descrip,item_rank=>$ITEM_RANK);

print "Added new item id is $new_id\n";

				} else {
					$new_id = $existing;
				}
			}
print "Calling comment window with $link $new_id\n";
			my $comment_window_code = $abm->CommentWindowCode($link, $new_id);
    	 		#print F "$pubDate <A  HREF='' onclick=\"$comment_window_code\" >$title</A><br>\n";
    	 		print F "<A  HREF='$NEWS_REL_URL/$new_id' onclick=\"$comment_window_code\" >$title</A><br>\n";
     			print F "\n"; 
                       
                        my $imgtag = '';
                        if ($img && $img =~ /^http/) {
                          $imgtag = "<img src='$img' class='fwiximg'/>";
                        }

                        $item_content = "<div class='fwixitem'>$imgtag <h3>$title></h3> <span class='fixdate'>$pubDate</span> $descrip <a href='$link'>read more...</a></div>\n";
                        $news_content{$pubDate} = $item_content; 
print "Done processing item\n";
		}

	}
      }; # eval
      warn "Last error: $!";
	close F;
}

my $max_items = 20;
my $cnt = 0;
my $new_content = '';
for my $key (sort keys %news_content) {
  $new_content .= $news_content{$key}; 
}
my $uq = "update rcatdb_items set short_content = ".$dbh->quote($new_content)." where id = $NEWS_ITEM";
$dbh->do($uq);
1;


sub calc_disp_order {

	# 10000 - days since Jul 8 2007

	my $since = 1183885562;
	my $t = time;
	
	my $retval = 10000 - ($t - $since)/86400;

	return $retval; 

}
