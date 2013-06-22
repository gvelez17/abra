#!/usr/bin/perl

use LWP::Simple;
use XML::Simple;
use Date::Manip;
use Carp;
use Fatal;

# bio5 science news: http://bio5.org/rss.xml

BEGIN {
	unshift @INC, "/w/abra/lib";
}
use AbCat;
use AbUtils;
use AbHeader;
use Abra;
use AbMacros;


        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';

$OWNER = 11;

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}

my $abm = new AbMacros;


my $q = "select id, feed_url from ab_feeds";
my $xs = new XML::Simple;

my $feeds = $dbh->selectall_arrayref($q);
foreach my $feed (@$feeds) {
        print "Trying to retrieve uri: ".$feed->[1];
	my $f_content = LWP::Simple::get($feed->[1]) || next;
        my $wl = $xs->XMLin($f_content);
print "Parsed xml as : ";
print Dumper $wl;
        foreach my $item (@{$wl->{'channel'}->{'items'}->{'item'}}) {
          print Dumper $item;

        }
print Dumper $wl->{'channel'}->{'items'};

        my $uq = "update ab_feeds set feed_content = ".$dbh->quote($f_content);
        $dbh->do($uq);
}

1;
