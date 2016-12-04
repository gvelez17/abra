#!/usr/local/bin/perl -T

# Return comments about given URL

BEGIN {
      unshift (@INC, '.');
        unshift(@INC, "/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbCat;
use AbAcct;
use Abra;
use AbSecure;
use AbMacros;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

use HTTP::Request::Common;
use LWP::UserAgent;
use LWP::Simple;

use XML::RSS::Parser;

use CGI::Lite;
use PHP::Session;

$MAP_WIDTH=400;
$MAP_HEIGHT=250;

$STATE_CODE = 'AZ';

$DEFAULT_CAT = 66728;  # to be classified

$DBNAME = 'rcats';
$DBUSER = 'rcats';
$DBPASS = 'meoow';
$THISCGI = "http://abra.btucson.com/cgi/ab.pl";
$ADMINUSER = 1;

$TEMPLATE_DIR = '/home/sites/abra/templates';
$TEMPLATE_FILE = 'tmplRelateToURL.html';
$ADD_TEMPLATE_FILE = 'tmplAddURL.html';

$IMG_BASE_DIR = '/home/sites/abra/www/item_images';
$IMG_BASE_URL = '/item_images';

$debug = 0;

#$debug = 1;

print "Content-type: text/html\n";
print "Status: 200 OK\n\n";


ReadParse(\%in);
$query = $in{CGI};

# Make handler able to display different templates depending on context
$req_url = $ENV{'REQUEST_URI'};

$obj_url = '';
$full_size = 0;

if ($req_url =~ /\/comments\/(.+)$/) {
	$obj_url = $1;
} elsif ($req_url =~ /\/about\/(.+)$/) {
        $obj_url = $1;
	$full_size = 1;
	$TEMPLATE_FILE = 'tmplRelateToURLFullPage.html';
}

# check for alternate template dir
if ($ENV{'SERVER_NAME'} =~ /btucson.com/) {
	$TEMPLATE_DIR = '/home/sites/iwtucson/itempages';
	$TEMPLATE_FILE = 'tmplAddURL.html';  # currently we always add to bTucson

}
## TODO- instead of hardcoding the category codes in the template we should have a way to figure them out here

# keep the http://
#if ($obj_url =~ /http:\/\/(.+)$/) {
#	$obj_url = $1;
#}
$obj_url =~ s/\/$//g;


# get comments from our db
# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        warn "Error - cannot get database handle\n";
        exit;
}

$dbh->{FetchHashKeyName} = 'NAME_uc';

# See if we know anything about the url
# if we do, it will be an item.  do a precise match for now because otherwise too slow.
# TODO: keep all URLs in lowercase, or at least index in lowercase
# we could have more than one item per url in current system
# Ironwood Terraces and Desert Museum both have same URL
#$q = "select ID, NAME, SHORT_CONTENT, CID from rcatdb_items where url = ".$dbh->quote($obj_url);
#my ($about_id, $name, $desc, $cid) = $dbh->selectrow_array($q); 

$q = "select ID,CID,NAME from rcatdb_items where url = ".$dbh->quote($obj_url);
my $ids_ref = $dbh->selectall_arrayref($q);
my $where = '';
my $name = '';
my $about_id = 0;
my $catid = 0;
for my $aref (@$ids_ref) {
	($about_id, $catid, $name) = @$aref;
	$where .= "rcatdb_ritems.id = $about_id or ";
}
chop $where; chop $where; chop $where;

$debug && print "Query was $q, where is $where";
my @items;
my %templatehash = ();
$templatehash = \%templatehash;

$templatehash->{URL} = $obj_url;

# If not in db, we pull up AddURL template; if it is already, we pull up RelateTo template
if (! $about_id) {
	$TEMPLATE_FILE = $ADD_TEMPLATE_FILE;
}

$templatehash->{CID} =$catid;
$templatehash->{ABOUT_ID} = $about_id;
$templatehash->{ID} = $about_id;

$debug && $about_id &&  print "..found id $about_id\n";

if ($about_id && $where) {

	# print comments if we have any, also related category & item URLs

	# select direct relations
	my $q1 = "select RELATION, NAME, EFFECTIVE_DATE, SHORT_CONTENT, URL, LOGIN from rcatdb_items, rcatdb_ritems,users where ($where) AND  (rcatdb_items.id = rcatdb_ritems.item_dest) AND users.id = rcatdb_items.owner order by rcatdb_items.id desc";
	
	&AbUtils::get_query_results(\@items, $q1);

#print "Next query was $q1, got ".$#items." results";
	# select inverse relations, add to list with inverted rels

	$templatehash->{REL_ITEMS} = \@items;

	# TODO print using abMacros
	for my $href (@items) {
		my $linkstart = ''; my $linkend = '';

		$relname = $RELATIONS{$href->{RELATION}}->{'NICENAME'} || $href->{RELATION};	
		$href->{NICEREL} = $relname;
		$href->{RELATED_URL} = $href->{URL};
		$href->{SHORT_CONTENT} = &CommandWeb::HTMLize($href->{SHORT_CONTENT});
	}
	$templatehash->{HAS_ITEMS} = 1;
	$templatehash->{NUM_COMMENTS} = $#items + 1;
	if ($#items < 0) {
		$templatehash->{HAS_ITEMS} = 0;
	}
}

$template_file = $TEMPLATE_DIR.'/'.$TEMPLATE_FILE;

$debug && print "Using template file $template_file from $TEMPLATE_FILE";

&CommandWeb::OutputTemplate($template_file, $templatehash);

$dbh->disconnect;

1;
exit;

####################################################################################
$debug && print "Request URL was $req_url, obj_url is $obj_url\n<br>";

# get comments from revyu.com

# this is just for urlencode - get it from more standard place TODO ?
use PCGI qw(:all);

$qstr = 'http://revyu.com/sparql/';

# NOTE: the reason the query fails for most urls is that
# revyu.com does not usually use the uri as the label, but
# puts it as 'see also' - so what they are reviewing is
# actually word strings, not uris.  SameAs may help but is not 
# always present
$astr = <<"END_QUERY_STRING";
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX rev: <http://purl.org/stuff/rev#>
SELECT DISTINCT ?review ?rating ?text
WHERE
{
  { ?thing foaf:homepage \<$obj_url\> .
    ?thing rev:hasReview ?review . 
    ?review rev:rating ?rating .
    ?review rev:text ?text . }
  UNION
  { ?thing rdfs:seeAlso <$obj_url> .
    ?thing rev:hasReview ?review .
    ?review rev:rating ?rating .
    ?review rev:text ?text . }
  UNION
  { ?thing owl:sameAs <$obj_url> .
    ?thing rev:hasReview ?review . 
    ?review rev:rating ?rating .
    ?review rev:text ?text . }
}
ORDER BY ?label
END_QUERY_STRING

$qstr .= '?query=';
$qstr .= urlencode($astr);


my $ua = LWP::UserAgent->new();
my $req = HTTP::Request->new(GET => $qstr);
my $resp = $ua->request($req);

my $rstr = $resp->content;
print "Raw result: $rstr\n<br>";
print "<hr> Query was:$astr<p>";

#print "Making new parser...";
#my $p = XML::RSS::Parser->new;

#$rstr = '<rss version="2.0">'.$rstr.'</rss>';

#print "Trying to parse raw result...";
#my $feed = $p->parse_string($rstr);


#print "Did we get anything?...";
if ($rstr) {

	print "Got response from revyu: <p>\n";
	$revcount = 1;
	while ($rstr =~ /<uri>([^<]+)<\/uri>/g) {
		my $revurl = $1;
		if ($revurl =~ /reviews\//) {
			print "<A TARGET='abra_actual_review' HREF='http://revyu.com/$revurl'>Review # $revcount</A><br>\n";
			$revcount++;
		}
	}
} else {
	print "revyu.com doesn't know about $obj_url yet";
}



1;



