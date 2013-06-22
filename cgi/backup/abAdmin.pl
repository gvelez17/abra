#!/usr/local/bin/perl -T


# Admin / Edit mode

BEGIN {
      unshift (@INC, '.');
        unshift(@INC, "/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbCat;
use Abra;
use AbSecure;
use AbMacros;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

use CGI::Lite;
use PHP::Session;

# Hack for testing
#if ($0 =~ /org/) {
#       $DBNAME = 'rpub';
#       $DBUSER = 'groots';
#       $DBPASS = 'sqwert';
#       $THISCGI = "http://qs.abra.info/cgi/org.pl";
#} else {
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
        $THISCGI = "/cgi/abAdmin.pl";
        $ADMINUSER = 1;
	$ALT_ADMIN_USER = 7886;
	$NANCY_ADMIN_USER = 0;   # todo
	$JASON_ADMIN_USER = 10925;

	$ITEMS_PER_PAGE = 10;

	$DONE_SECURITY_LEVEL = 101;

	$TEMPLATE_DIR = '/home/sites/iwtucson/itempages';
	$SINGLE_EDIT_TEMPLATE = 'tmplEditItem.html';
	$MULTIPLE_EDIT_TEMPLATE = 'tmplEditMult.html';
	$FORM_EDIT_TEMPLATE = 'fragEditItem.html';
#}
$debug = 1;

print "Content-type: text/html\n\n";
print "<!-- UID = ",$<,"Query string = ",$ENV{'QUERY_STRING'},"-->\n";
ReadParse(\%in);
$query = $in{CGI};


# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}

$dbh->{FetchHashKeyName} = 'NAME_uc';

# Who are we?  We will need edit privs to continue
# Security check - never allow anonymous users to post anything anywhere
$User = &AbSecure::get_username;
$userid = &AbSecure::get_userid($User);

print "in adAdmin.pl - right off, we are $User with id $userid";

die unless (($userid == $ADMINUSER) || ($userid == $ALT_ADMIN_USER) || ($userid == $JASON_ADMIN_USER));

# Either we have a specific item to edit, 
# or everything in a category,
# or we want the N most recent submitted items to approve
$DEFAULT_CAT = 301;
if ($userid == $ALT_ADMIN_USER){
	$DEFAULT_CAT = 43154;   # That's Tracy, administering bDallas.com
}

# more hacks for other categories
if ($ENV{'SERVER_NAME'} =~ /abra.info/) {
	$DEFAULT_CAT = 66727;
} elsif (($ENV{'SERVER_NAME'} =~ /bcookin.com/) || ($ENV{'SERVER_NAME'} =~ /myrecipesearch/)) {
	$DEFAULT_CAT = 76680;
}


$DOCAT = $in{_CATID} || $in{_catid} || $DEFAULT_CAT;

my $mcat = new AbCat($DOCAT);

print "Got cat $DOCAT...";

$LVL = $mcat->get_level() + 1; # 0-based 

print "Got level $LVL...";

# Right now just handling approvals 
@items = ();
%templatehash = ();

$templatehash{'ABCGI'} = "/cgi/ab.pl";

my $abm = new AbMacros;


if (($userid == $ADMINUSER) || ($userid == $ALT_ADMIN_USER) || ($userid == $JASON_ADMIN_USER)) { # that's me

	# get our cat mask
	$catcode = $dbh->quote($mcat->get_catcode());

	# get the ones with biz listings
	$q = "select rcatdb_items.*, ab_biz_org.*, rcatdb_categories.rel_url from rcatdb_items,ab_biz_org,rcatdb_categories where LEFT(catcode, $LVL) = LEFT($catcode, $LVL) and  rcatdb_items.security_level = 100 and rcatdb_items.id = ab_biz_org.id and rcatdb_items.cid = rcatdb_categories.id order by rcatdb_items.id desc limit $ITEMS_PER_PAGE";

	&AbUtils::get_query_results(\@items, $q);

	# now get the ones without biz listings
	$q2 = "select rcatdb_items.*,  rcatdb_categories.rel_url from rcatdb_items,rcatdb_categories where LEFT(catcode, $LVL) = LEFT($catcode, $LVL) and rcatdb_items.security_level = 100  and rcatdb_items.cid = rcatdb_categories.id order by rcatdb_items.id desc limit $ITEMS_PER_PAGE";

#print "Query 2 was $q2";

	# TODO: get all related table stuff in separate queries
	# there will be multiple possible tables
	# we already have an AbUtils.pm routine for this

	&AbUtils::get_query_results(\@items, $q2);

	# sort merged list by id desc
	@items = sort { $b->{'ID'} <=> $a->{'ID'} } @items;

	# Fixup items, set fields not selected initially
	foreach my $item (@items) {
		$item->{'ABCGI'} = "/cgi/ab.pl";
		$item->{'ABADMIN'} = $THISCGI;
		# subcat list
		# check for other types	
		
		my $curitem = $item->{'ID'};

          	# are we related from (ie are we a comment about)
                my $rq = "select rcatdb_items.EFFECTIVE_DATE, rcatdb_items.owner, rcatdb_items.ID, rcatdb_items.CID, rcatdb_items.NAME,  rcatdb_ritems.RELATION from rcatdb_items, rcatdb_ritems where rcatdb_ritems.item_dest = $curitem and rcatdb_items.id = rcatdb_ritems.id limit 1";

                my $relto_ref = $dbh->selectrow_hashref($rq);
		if ($relto_ref) {
			$item->{'RELFROM'} = "relates to: <A HREF='/".$relto_ref->{ID}."'>".$relto_ref->{NAME}."</A>";
		}

	}


	$edit_form_file = $TEMPLATE_DIR.'/'.$FORM_EDIT_TEMPLATE;

	$templatehash{'EDIT_ITEMS'} = $abm->AdminItems(\@items, $edit_form_file);

	$template_file = $TEMPLATE_DIR.'/'.$MULTIPLE_EDIT_TEMPLATE;

	print "Total ".$#items." +1 items<br>\n";

	&CommandWeb::OutputTemplate($template_file, \%templatehash);
}

1;
