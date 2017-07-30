#!/usr/local/bin/perl -T
# Path to RCategories

BEGIN {
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

use CGI::Lite;
use PHP::Session;

# Hack for testing
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
        $THISCGI = "/cgi/abHome.pl";
        $ADMINUSER = 1;


	$TEMPLATE_DIR = '/home/sites/iwtucson/itempages';
	$DEFAULT_TEMPLATE_FILE = 'tmplBrowseItem.html';

	$IMG_BASE_DIR = '/home/sites/iwtucson/www/item_images';
	$IMG_BASE_URL = '/item_images';

	$MAXITEMS = 100;

	$ROOTCAT = 301;

#}
print "Content-type: text/html\n";
print "Status: 200 OK\n\n";
$debug = 1;

ReadParse(\%in);
$query = $in{CGI};


# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        warn "Error - cannot get database handle\n";
        exit;
}

$dbh->{FetchHashKeyName} = 'NAME_uc';

my $rurl = $ENV{'REDIRECT_URL'};
my $keyword = '';
if ($rurl =~ /^(.*\/)([^\/]+)$/) {
	$caturl = $1;
	$user = $2;

	# SECURITY CHECK
	$keyword =~ /^[a-zA-Z0-9_\-\.\s]*$/ || die "invalid keyword $keyword\n";
	$caturl =~ /^[a-zA-Z0-9\&\-_\s\/]*$/ || ($caturl =~ /^[a-zA-Z0-9\&\-_\s\/]*btucson\.com[a-zA-Z0-9\&\-_\s\/]*$/i) || die "invalid caturl $caturl\n";


# don't return results for robots.txt
	if ($user eq 'robots.txt') {
		print "Content-type: text/html\n";
		print "Status: 404 Not Found\n\n";
		print "No robots.txt - not found";
		exit 1;
	}

	my $href;

# We match first by login, then real name.  
#TODO: Handle case if one user's login is another's real name...

	my $quser = $dbh->quote($user);
	my $q = "select id,login from users where login = $quser or real_name = $quser limit 1";
	my ($ownerid,$login) = $dbh->selectrow_array($q);

	if (! $ownerid) {
		print "Sorry, $user is not a valid user on this system.\n";
		exit(0);
	}


       my $logged_username = &AbSecure::get_username;



       # use macros for some vars, and for replacing output
        my $abm;
        $abm = new AbMacros(catid=>$ROOTCAT,username=>$login);


	my $macct = new AbAcct($login);

	$guest = 0;
	if ($logged_username ne $login) {
		$guest = 1;
	}

	if ($guest) {
		print "<H3>".$login."'s Place</H3>\n";
		print "<small>back to <A HREF='http://bTucson.com/'>bTucson.com</A></small><p>";
		print "Items submitted by $login:<p>";
	} else {
		print "<H3>Welcome $login</H3>";
		print "<small>back to <A HREF='http://bTucson.com/'>bTucson.com</A></small><p>";
		my $gcode = $macct->get_google_client_id();

		if ($gcode) {
			print "You are signed up for RevenueShare with the Google ID $gcode<br>\n";
			print "To access your Google Adsense account, please visit ".
			   "<A HREF='http://adsense.google.com/'>http://adsense.google.com</A> ".
			   "and login with your email address <i><b>".$macct->get_google_email()."</b></i> and the password you chose when you set up the account.<p>";

			print "Following is a list of items running your ads (using the above adcode)<p>";
		} else {
			print "Your items:<p>";
		}
	}


	$q = "select rcatdb_items.* from rcatdb_items where owner = $ownerid and security_level = 0 order by effective_date desc limit $MAXITEMS";
	$sth = $dbh->prepare($q);

	$sth && $sth->execute() || die("Can't execute $q");

	while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

		$content = substr($ref->{'SHORT_CONTENT'},0,1000);
		$id = $ref->{'ID'};
		$title = $ref->{'NAME'} || 'No title';
		$edate = $ref->{'EFFECTIVE_DATE'};
		print "<small>$edate</small> <A HREF='/$id'>$title</A><br>$content...<p>\n";


	}
} else {

	print "sorry, I don't know anything about $rurl";
}

1;
