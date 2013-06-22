#!/usr/local/bin/perl -T

#BEGIN{
#	print "Content-type: text/html\n\n";
#}


use CGI qw(:cgi-lib);
use Carp;
# Get user input
%in = ();


# TODO TODO TODO - fix this hack to pass the %in hash to add_item
$inref = \%in;
ReadParse(\%in);

#TODO : move this to config file

$ITEM_TABLE = "rcatdb_items";
$CAT_TABLE = "rcatdb_categories";
$RCAT_TABLE = "rcatdb_rcats";
$RITEM_TABLE = "rcatdb_ritems";
$USER_TABLE = "users";

$SPECIALCHARS = '#%';
# TODO: add 'description', 'content', 'rel:[RELATION]:handle|string|url
$IDENTS = "cat title url text handle";
$ANONUSERID = 65535;
$TYPE = 'type';

$GUEST_USER = 7079;

$TO_BE_CLASSIFIED = 66728;

$DEFAULT_COMMENT_RANK = 20;
$DEFAULT_COMMENT_RELATION = 'HAS_COMMENT';

BEGIN {
    $DBNAME = 'rcats';
    $DBUSER = 'rcats';
    $DBPASS = 'meoow';
}

open F, ">/home/abra/data/formlogfile";

open G, ">/home/abra/data/lastform";
print G "User input:\n";
foreach my $key (keys %in) {
	print G "$key: ",$in{$key},"\n";
}
close G;

if ($in{'title'} =~ /^test/i) {
	$TESTING = 1;
	print "Content-type: text/html\n";
	print "Status: 200 OK\n\n";
	print "testing";
}
$NO_LOC = 0;
if ($in{'title'} =~ /^gee/i) {
	$NO_LOC = 1;
}


# Now do our database stuff
BEGIN{
	unshift @INC, "/w/abra/lib";
}

use AbHeader qw(:all);
use AbUtils;
use AbCat;
use Abra;
use AbSecure;
use AbMacros;
use Mysql;
use CGI qw(:cgi-lib);
use DBI;
use CommandWeb;

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        &ErrorExit("Error - cannot get database handle\n");
}


$debug = 0;
$debug = $in{'_debug'} || $in{'_DEBUG'} || $debug;

if ($debug) {
	print "Content-type: text/html\n\n";
	print "Debug mode";
}

# die quietly for spammers
if (($in{'URL'} =~ /enbloc-system/) || ($in{'short_content'} =~ /work.*at.*home/i)
	|| ($in{'URL'} =~ /daimer/) || ($in{'URL'} =~ /3daybid/)) {
	die;
}

$NEWSITE = 0;
$servername = $ENV{'SERVER_NAME'};
if ($servername =~ /tech-for-teachers/) {
	$NEWSITE = 1;
}
# We need a category. First use catid, next try catcode, next generate from catstring

$catid = $in{"_catid"};  
$catcodestr = $in{'catcode'};  # in the form XX:YY:ZZ
$catstring = $in{'_cat'} || $in{'_CAT'};

#print "Got _catid: $catid, catcode: $catcodestr, _cat= $catstring\n";


$type = $in{'_type'} || $in{'_TYPE'};

$related_to = $in{'_related_to_item'} || $in{'_RELATED_TO_ITEM'} || undef;
$relation = $in{'_relation'} || $in{'_RELATION'} ||  'HAS_COMMENT';

$title_input = $in{'_title'} || 'title';
@alltitles = split(/\s+/,$title_input);
$title = '';

$short_content = $in{'short_content'} || $in{'SHORT_CONTENT'};

foreach $tinput (@alltitles) {
	$title .= $in{$tinput}.' ';
}

$debug && print "Using tag named $title_input, title is $title...\n";

chop $title;

$reply = $in{'_reply'} || $in{'_REPLY'};

$url = $in{'url'} || $in{'URL'} || '';



#$CARDINAL_ITEM = 90;
#$MAJOR_ITEM = 80;
#$NEWS_ITEM = 60;                # may be time-dependent, do this differently?
#$LISTING_URL_CONTENT = 50;
#$LISTING_URLONLY = 40;
#$LISTING_NOURL = 30;
#$PERMANENT_ITEM = 30;
#$COMMENT = 25;
#$MINOR_COMMENT = 10;

$item_rank = $in{"_rank"};
if (! $item_rank) {
	if (defined($related_to)) {  # should only downgrade actual comments...
		$item_rank = $COMMENT;
	} 

# TODO: more ranking heuristics here
# if biz/org info but no url = LISTING_NOURL
# if both biz/org and url = LISTING_URLONLY
# ...

	else {
		$item_rank = $PERMANENT_ITEM;
	}
}

# see if user is adding a comment about this item at the same time (can add item + comment at once)
$comment_content = $in{'comment_content'} || '';
$comment_title = $in{'comment_title'} || '';
$comment_rank = $in{'comment_rank'} || $DEFAULT_COMMENT_RANK;
$comment_relation = $in{'comment_relation'} || $DEFAULT_COMMENT_RELATION;

$anon_ok = 0;
## AACK - HACK - should use lookup table of multiple q & a's
if ($in{'human_check_1'} eq 'wall') { 
	$anon_ok = 1;
}

$username = &AbSecure::get_username;
$groupname = '';
if (! $username) {

	if ($anon_ok) {
		$username = 'guest';
	} else {
		#$debug || print("Content-type: text/html\n\n");
		&ErrorExit("Sorry, you must be logged in to perform posts.  Please press the back arrow to return to the page you were at and look for  the 'login' link, or use this <A HREF='http://abra.info/php/access_user/login.php'>generic login</A> page\n");
	}
}	



my $ownerid = &AbSecure::get_userid($username);
if (! $ownerid) {
	#$debug || print "Content-type: text/html\n\n";
	 &ErrorExit("Sorry, username $username is not a recognized user.  Please <A HREF='http://iwhome.com/iwork/dform2.html'>contact Internet WorkShop</A> if you believe this error message is incorrect.\n");
}


# TODO: default type PLUS x:y specific types - normalize, dammit!

if ($TESTING){
	$debug = 1;
}

$cat = 0;
if ($catid) {
	$cat = $catid;
} elsif ($catcodestr) {

	# dumb thing has / instead of :
	$catcodestr =~ s/\//:/g;

$debug && print "Trying to get cat info from $catcodestr...";
	$code = &AbUtils::catcode_from_str($catcodestr);
	$cat = &AbUtils::catid_from_code($code);

$debug && print "..got catid $cat\n";
} elsif($catstring) {
	$cat = ParseCatString($catstring);
} 

$debug && print(" catstring is $catstring Cat is $cat");

if (! $cat  ) {
	&ErrorExit("Required field _catid or catcode not found, or category $catstring not found");
}

# TODO: send to whoever is the sendto for cat

%namedhash = ();
foreach $field (keys %in) {
	if ($field =~ /^(.*):(.*)$/) {
		$namedhash{$1}{$2} = $in{$field};
	} elsif ($type && ($field !~ /^_/)) {
		$namedhash{$type}{$field} = $in{$field};
	}
}

$debug && print "Adding $cat, $title, $short_content, $url, owned by $ownerid";

$sec_level = $PUBLIC_ACCESS_LEVEL;
if ($username eq 'guest') {
	$sec_level = $OWNER_ACCESS_LEVEL;
}

# special category is ok, also new sites
if (($cat == $TO_BE_CLASSIFIED)||($NEWSITE)) {
	$sec_level = $PUBLIC_ACCESS_LEVEL;
}

$debug && print "About to add item<br>";

my $curid = &AbUtils::add_item(
	'cid' => $cat,
	'itemname' => $title,
	'url' => $url,
	'security_level' => $sec_level,
	'item_owner' => $ownerid,
	'item_rank' => $item_rank,
	'short_content' => $short_content,
	'iref' => \%in
);

$debug && print "Completed add item, returned id $curid, About to add to tables ",%namedhash,"<br>\n";

### TODO HERE BUG HERE 	add_to_tables is crashing!
#&AbUtils::add_to_tables($curid,\%namedhash);

$debug && print "About to add relation to $related_to<br>\n";

# add relation if $related_to is defined
if (defined($related_to)) {
	&AbUtils::add_relation($related_to,$ITEMTYPE, $curid, $ITEMTYPE, $relation); 

}

# add comment item if the comment fields are defined - basically a whole other item + relation
my $comment_id = 0;
if ($comment_content) {
	$comment_title = $comment_title || 'Comment';
	$comment_id = &AbUtils::add_item( 
		'cid' => $cat,		# same as item we're commenting about
		'itemname' =>	$comment_title,
		'security_level' => $sec_level,
		'item_owner' => $ownerid,
		'item_rank' => $comment_rank,
		'short_content' => $comment_content
	);
	if ($comment_id) {
		&AbUtils::add_relation($curid, $ITEMTYPE, $comment_id, $ITEMTYPE, $comment_relation);
	}
}

# we don't have perms to do this, but can set flag for crontab
# generally new items have to be approved anyway
# system("cd /home/sites/iwtucson/catpages/; /usr/local/bin/abmakeall.pl");

$dbh->disconnect;                                                                                                             
close F;

if ($NO_LOC){
	print "Content-type: text/html\n\n";
}

if (! $reply){
	$reply = "/thankyou.php";
}

if ($reply =~ /php$/) {
	$reply .= "\?id=$curid\&sec=$sec_level";
}


print "Location: $reply\n\n";

1;

exit;



sub ParseCatString {
	my $catstr = shift;
	my $uid = 0; # no user 
	my $cid = 0;
	my $parentcat = 0;

	# Is $catstr absolute or relative
	&trimblanks(\$catstr);
	my $cathome = '/';
	
	# if $catstr has no / chars, maybe is a handle
	if ($catstr !~ /\//) {
		# Lookup Handle
		# if successful return id
		# TODO
		$debug && print("About to lookup by handle...");
		$cid = &LookupCatByHandle($catstr, $parentcat);
		return($cid) if $cid;
	}

	# Now we have a fully qualified catpath, we think
	# could be names or handles at each level
	# if we can't find one we make it a subcategory
	$cid = &ResolveCatPathMakingEntries($catstr, $parentcat, $uid);

	return($cid);
}


sub ResolveCatPathMakingEntries {
	my $catpath = shift;
	my $parentcat = shift;
	my $userid = shift;

	my $type;
	@cats = split('/',$catpath);

	$lastparentcat = $parentcat;
#	@catids  = ();

	foreach $catstr (@cats) {

		$cid = &LookupCatByHandle($catstr, $lastparentcat) 
			|| &LookupCatByName($catstr, $lastparentcat, $userid)
			|| &MakeCat($catstr, $lastparentcat, $userid);

#		push @catids, $cid;
		$lastparentcat = $cid if $cid;
	}
	
	return ($lastparentcat || $parentcat);
}


sub LookupCatByHandle {
	my ($handle, $parentcat) = @_;
	$debug && print("Looking up by handle $handle, parentcat=$parentcat...");
	if ($parentcat) {
		$q = "select ID from handles where type='C' AND handle = ".$dbh->quote($handle).
		" AND ( (catid=0) OR (catid=$parentcat) OR (catid IS NULL)) ";
	} elsif ($handle) {
		$q =  "select ID from handles where type='C' AND handle = ".$dbh->quote($handle);
	}
	$debug && print("Query is $q...");
	my $sth = $dbh->prepare($q);
	my $id = 0;
	if ($q && $sth) {
		$sth->execute();
	        $id = $sth->fetchrow_array;
	}
	return $id;
}

sub LookupCatByName {
	my ($catname, $parentcat, $userid) = @_;

	$q = "select ID from $CAT_TABLE where name='$catname'";
	if ($lastparentcat) {
		$q .= " and cid=$lastparentcat";
	}
	
	# Ignore userid for now; should use in case multiple results returned
	
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my ($id) = $sth->fetchrow_array;
	return $id;
}

sub MakeCat {

}


sub addslashes {
	$sref = shift;
	
	if ($$sref !~ /^\//) {
		$$sref = '/'.$ssref;
	} 
	if ($$sref !~ /\/$/) {
		$$sref .= '/';
	}
}

sub trimblanks {  # with possibly embedded spaces
	$sref =shift;

	$$sref =~ s/^\s*(.+)$/$1/g;	# trim leading
	$$sref =~ s/\s+$//g;		# trim trailing
}
	



sub printhashhash {
	my $href = shift;
	foreach my $key (keys(%$href)){
		printhash($href->{$key});
	}
}

sub printhash {
	my $href = shift;

	foreach my $key (keys(%$href)) {
		print "$key: ";
		print $href->{$key};
		print "\n";
	}
	print "\n";
}

sub ErrorExit {
	my $msg = shift;

	close F;
	
	print "Content-type: text/html\n\n";
	print "<HTML><font size='+1'>";
	print "Sorry, an error has occurred: $msg<p>";
	print "Got inputs ",%in;
	print "Please contact <A HREF='mailto:Golda\@AmericansForEdwards'>Golda\@AmericansForEdwards</A> and I will help you get set up right away!";
	print "</font></html>\n";
	exit(1);
}	
