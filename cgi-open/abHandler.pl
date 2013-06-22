#!/usr/local/bin/perl

# Handler for URLs like http://somedomain.com/abra/somekeyword

# Path to our libs
BEGIN {
      unshift (@INC, '/w/abra/cgi');
}

use AbHeader qw(:all);
use AbUtils;
use AbMacros;
use RCategories;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

# TODO replace direct dbh connection with overridden class for security
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "/cgi-open/abHandler.pl";

$debug = 1;

# print("Content-type: text/html\n\n");

# If the user had their own security, we get REMOTE_USER variable
if (defined $ENV{'REMOTE_USER'}) {
	$User = $ENV{'REMOTE_USER'};
}

# Use MySQL (or DBI) to connect
$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');
$dbh = $obj->{'dbh'};


#TODO: use error handler that prints content header
if (!$obj) {
	print "Error - cannot connect to database";
	exit;
}

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

my $rurl = $ENV{'REDIRECT_URL'};
my $keyword = '';
if ($rurl =~ /\/abra\/([^\/]+)$/) {
	$keyword = $1;

	my $q = 

	my $q = "select rcatdb_items.* from rcatdb_items,handles "
		." where rcatdb_items.id = handles.id and handles.handle = "
		.$dbh->quote($keyword);

	print "Content-type: text/html\n\n Query is $q\n";

	my $href = $dbh->selectrow_hashref($q);

	print "Resulting item is ";
	print %$href;


} else {
	print "Content-type: text/html\n\n";

	print "sorry, I don't know anything about $rurl";
}

1;
