#!/usr/local/bin/perl -T

package AbBlogView;

# Path to RCategories
#
BEGIN {
      unshift (@INC, '/w/abra/cgi/');
      unshift (@INC, '.');
}
BEGIN {
       use AbHeader qw(:all);
       use AbUtils;
       use AbMacros;
       use RCategories;
       use Mysql;
       use CGI qw(:cgi-lib);
       use CommandWeb;
	use CGI::Lite;
	use PHP::Session;

	use Date::Manip qw(ParseDate UnixDate);
}

my $session_name = 'PHPSESSID';
my $cgi_lite = new CGI::Lite;
my $cookies = $cgi_lite->parse_cookies;

# Get user input
my %in = ();
$WWWUID = 444;  # TODO: set in install
$CalledFromWeb = 0;
$User = '';
$userid = 0;

$DEBUG = 1;
$CALLED_AS_BLOGVIEW = 1;
$EXTERNAL_CATID = 0;
$MAX_URL_DISPLAY_LENGTH = 40;

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

my $USER_VAR = 'user';

defined($ENV{'QUERY_STRING'}) && ($CalledFromWeb = 1);
($< == $WWWUID) && ($CalledFromWeb = 1);
if ($CalledFromWeb) {
        print "Content-type: text/html\n\n";
        print "<!-- UID = ",$<,"Query string = ",$ENV{'QUERY_STRING'},"-->\n";                    ReadParse(\%in);
        $query = $in{CGI};

        # If the user had their own security, we get REMOTE_USER variable
        if (defined $ENV{'REMOTE_USER'}) {
                $User = $ENV{'REMOTE_USER'};
        }        
	# otherwise check for a PHP Session cookie
        elsif ($cookies->{$session_name}) {
$DEBUG && print "Session name is $session_name, cookie is ",$cookies->{$session_name};
              my $session = PHP::Session->new($cookies->{$session_name}, { create => 1 });
              $User = $session->get($USER_VAR);
	}
	$userid = &getUserID($User);
$DEBUG && print "We are user $User with id $userid...";

} else {
        print "Welcome to ABRA\n\n";
        &CommandWeb::ParseCommandLine(\%in);
}

$curcat = $in{'_CATID'} || $EXTERNAL_CATID || 0;
$curitem = $in{'_ITEMID'} || 0;
$userpref = $in{'_USERPREF'} || 0;      # ACL type code


my @subcats = ();

&AbUtils::get_subcats($curcat, \@subcats, $userid);


$CALLED_AS_BLOGVIEW && print "Content-type: text/html";

%templatehash = ();
$templatehash{'THISCGI'} = $THISCGI;
$templatehash{'BLOGCGI'} = $BLOGCGI;
$templatehash{'CATID'} = $curcat;

$tmplheader = $ABTEMPLATE_DIR.'/tmplHeader.html';

&CommandWeb::OutputTemplate($tmplheader, \%templatehash);

$templatefile = $ABTEMPLATE_DIR.'/tmplBlogEntry.html';
&getitems($curcat, \@subcats, $userid);

$tmplfooter = $ABTEMPLATE_DIR.'/tmplFooter.html';

&CommandWeb::OutputTemplate($tmplfooter,\%templatehash);

1;

	


sub getitems {
	my $curcat = shift;
	my $scatref = shift;
	my $userid = shift || 0;

	my $catcode  = &AbUtils::get_catcode($curcat);
	my $carr = &AbUtils::ArrayFromCatCode($catcode);
	my $lvl = &AbUtils::GetLevel($carr)+1;

$DEBUG && print "Getting items...";
        my $catowner = &AbUtils::get_catowner($curcat);
$DEBUG && print "Category owner is $catowner , we are $userid...";
        my $our_access_level = &AbUtils::get_access_level($userid, $catowner, $curcat) || 0;
$DEBUG && print "Access level is $our_access_level...";

	$q = "select rcatdb_items.id, rcatdb_items.itemcode, rcatdb_items.cid, rcatdb_items.name, rcatdb_items.short_content, rcatdb_items.url, rcatdb_items.qualifier, rcatdb_items.effective_date, rcatdb_items.entered from rcatdb_items,rcatdb_categories where LEFT(itemcode,$lvl) = LEFT(catcode,$lvl) and rcatdb_categories.id = $curcat and  ($our_access_level >= rcatdb_items.security_level) order by rcatdb_items.effective_date desc, entered desc, itemcode asc ";

$DEBUG && print "Query is $q\n<br>";

	$sth = $dbh->prepare($q);
	$sth->execute();
	while ($ref = $sth->fetchrow_hashref('NAME_uc') ) {

		push @arows, $ref;
		my $id = $ref->{'ID'};
		my $q1 = "select content,type from content where id = $id";
		my $sth = $dbh->prepare($q1);
		$sth->execute;
		my ($content, $valtype) = $sth->fetchrow_array;
		if ($content) {
			if ($valtype eq 'text') {
				$content = "<PRE>".$content."</PRE>";
			} else { 
				$content =~ s/\n\n/<p>/g;

				$content =~ s/\n/<br>/g;
			}
			

			$ref->{'CONTENT'} = $content;
		}
		my $cid = $ref->{'CID'};


		push @$scatref, $cid;
$DEBUG && print "Printing item $id<br>\n";
		&printrow($ref,$cid);

	}
	return 1;
}

sub printrow {
	my $ref = shift;
	my $cid = shift;
	my %templatehash = {};
	if ($ref->{'EFFECTIVE_DATE'}) {
		my $datestr = $ref->{'EFFECTIVE_DATE'};
		# TODO check if have Date::Manip
		my $date = ParseDate($datestr);
		$datestr = UnixDate($date, "%a %b %e %Y"); # make sure treats as scalar
		$templatehash{'DATE'} = $datestr;
	} else {
		$timestr = $ref->{'ENTERED'};  # yymmdd
		$yr = substr($timestr,0,2);
		$mo = substr($timestr,2,2);
		$day = substr($timestr, 4,2);
		$templatehash{'DATE'} = "$mo\/$day\/$yr";
	}
	$templatehash{'NAME'} = $ref->{'NAME'};
	$templatehash{'SHORT_CONTENT'} = $ref->{'SHORT_CONTENT'};
	$templatehash{'ITEMCODE'} = &AbUtils::catcodestr($ref->{'ITEMCODE'});
	$templatehash{'ID'} = $ref->{'ID'};
	
	$templatehash{'URL'} = $ref->{'URL'};

	$templatehash{'DISPLAY_URL'} = substr($ref->{'URL'},0,$MAX_URL_DISPLAY_LENGTH);




#if ($templatehash{'ITEMCODE'} =~ /^23:2:3/) { return;};

	if (exists $ref->{'CONTENT'}) {
		$templatehash{'CONTENT'} = $ref->{'CONTENT'};
	}
	$catref = &AbUtils::get_cat($cid);
	$templatehash{'CATPATH'} = &AbUtils::make_catpath($catref);

	&CommandWeb::OutputTemplate($templatefile, \%templatehash)
}

#############################################################
sub getUserID {
        my $user = shift;


        #       my $q = "select ab_users_cats.id from ab_users_cats,users where ab_users_cats.user_id = users.id and login = '$user'";
                my $q = "select id from users where login = '$user'";
         return $dbh->selectrow_array($q);
     }

