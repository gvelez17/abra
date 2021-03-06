#!/usr/local/bin/perl -T

BEGIN {
      unshift (@INC, '/w/abra/lib/');
}
BEGIN {
       use AbHeader qw(:all);
       use AbUtils;
       use AbMacros;
       use Mysql;
       use CGI qw(:cgi-lib);
       use CommandWeb;
	use CGI::Lite;
	use PHP::Session;
	use AbCat;
	use Abra;

	use Date::Manip qw(ParseDate UnixDate);
}

        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
        $THISCGI = "http://abra.btucson.com/cgi/ab.pl";
        $ADMINUSER = 1;
      $TEMPLATE_DIR = '/home/sites/iwtucson/itempages';
        $DEFAULT_TEMPLATE_FILE = 'tmplBrowseItem.html';

print "Content-type: text/html\n\n";


# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}
# global - do not use my
$USE_TEMPLATE_DIR = $ABTEMPLATE_DIR if (! $USE_TEMPLATE_DIR);
$DEFAULT_TEMPLATE_DIR = $ABTEMPLATE_DIR;

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


$dbh->{FetchHashKeyName} = 'NAME_uc';

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

$catcode  = &AbUtils::get_catcode($curcat);

my @subcats = ();

&AbUtils::get_subcats($curcat, \@subcats, $userid);


#$CALLED_AS_BLOGVIEW && print "Content-type: text/html";

%templatehash = ();
$templatehash{'THISCGI'} = $THISCGI;
$templatehash{'BLOGCGI'} = $BLOGCGI;
$templatehash{'CATID'} = $curcat;

$DEBUG && print "Looking up header for catcode ";

$tmplheader = &AbUtils::lookupTemplatebyCatcode($curcat,$catcode, 'header') 
	||  get_template('tmplHeader.html');

$DEBUG && print "Header is $tmplheader";

&CommandWeb::OutputTemplate($tmplheader, \%templatehash);

$templatefile = &AbUtils::lookupTemplatebyCatcode($curcat,$catcode, 'blogentry') 
	||  get_template('tmplBlogEntry.html');

&getitems($curcat, \@subcats, $userid);

$tmplfooter = &AbUtils::lookupTemplatebyCatcode($curcat,$catcode, 'footer') 
	|| get_template('tmplFooter.html');

&CommandWeb::OutputTemplate($tmplfooter,\%templatehash);

1;

	
sub get_template {
	my $filename = shift;

	$filename = $USE_TEMPLATE_DIR.'/'.$filename;
print "Checking $filename";
	if (! -e $filename){
		$filename = $DEFAULT_TEMPLATE_DIR.'/'.$filename;
	}
	if (! -e $filename) {
		$filename = '';
	}
	return $filename;
}

sub getitems {
	my $curcat = shift;
	my $scatref = shift;
	my $userid = shift || 0;

	my $carr = &AbUtils::ArrayFromCatCode($catcode);
	my $lvl = &AbUtils::GetLevel($carr)+1;

$DEBUG && print "Getting items...";
        my $catowner = &AbUtils::get_catowner($curcat);
$DEBUG && print "Category owner is $catowner , we are $userid...";
        my $our_access_level = &AbUtils::get_access_level($userid, $catowner, $curcat) || 0;
$DEBUG && print "Access level is $our_access_level...";

	$q = "select rcatdb_items.id, rcatdb_items.itemcode, rcatdb_items.cid, rcatdb_items.name, rcatdb_items.short_content, rcatdb_items.url, rcatdb_items.qualifier, rcatdb_items.effective_date, rcatdb_items.entered from rcatdb_items,rcatdb_categories where LEFT(itemcode,$lvl) = LEFT(catcode,$lvl) and rcatdb_categories.id = $curcat and  ($our_access_level >= rcatdb_items.security_level) order by rcatdb_items.effective_date desc, entered desc, itemcode asc limit 100";

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
	$catref = new AbCat($cid);
	$templatehash{'CATPATH'} = $catref->make_nice_catpath('');

$DEBUG && print "Outputting $templatefile for ",$ref->{'ID'},"<br>";

	&CommandWeb::OutputTemplate($templatefile, \%templatehash)
}

#############################################################
sub getUserID {
        my $user = shift;


        #       my $q = "select ab_users_cats.id from ab_users_cats,users where ab_users_cats.user_id = users.id and login = '$user'";
                my $q = "select id from users where login = '$user'";
         return $dbh->selectrow_array($q);
     }

