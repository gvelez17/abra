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

$debug = 1;
if ($debug) {
	print "Content-type: text/html\n\n";
}

print "Content-type: text/html\n";
print "Status: 200 OK\n\n";

ReadParse(\%in);
$query = $in{CGI};

$sparql = $in{SPARQL};


# this is just for urlencode - get it from more standard place TODO ?
use PCGI qw(:all);

$qstr = 'http://revyu.com/sparql/';

$qstr .= '?query=';
$qstr .= urlencode($sparql);


my $ua = LWP::UserAgent->new();
my $req = HTTP::Request->new(GET => $qstr);
my $resp = $ua->request($req);

my $rstr = $resp->content;
print "Raw result: $rstr\n<br>";
print "status: ".$resp->status_line."\n<br>";
print "<hr> Query was:$qstr<p>";

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


# get comments from our db
# Use MySQL (or DBI) to connect
#$abra = new Abra;
#

#if (!$dbh) {
#        warn "Error - cannot get database handle\n";
#        exit;
#}

#$dbh->{FetchHashKeyName} = 'NAME_uc';


