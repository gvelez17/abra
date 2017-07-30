#!/usr/local/bin/perl -T

# Script specifically for adding comments to URLs
# can be used by remote pages anywhere.
# for now the requirement is that the URL be pre-registered so has id
# TODO future auto-register URLs upon use, or queue for approval
#
# currently used within bTucson website but intended as part of 
# universal CommentWidget system 

# Because may be used from foriegn websites, have fixed fields 
# and higher level of security than blogform.pl or ab.pl needs

use CGI qw(:cgi-lib);

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
use RCategories;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

use CGI::Lite;
use PHP::Session;


# Get user input
%in = ();
$inref = \%in;
ReadParse(\%in);

        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';

open F, ">/home/abra/data/formlogfile";

open G, ">/home/abra/data/lastform";
print G "User input:\n";
print G %in;
foreach my $key (keys %in) {
	print G "$key: $in{$key}\n";
}
close G;

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}
# Security check - never allow anonymous users to post anything anywhere
$User = &AbSecure::get_username;
$userid = &AbSecure::get_userid($User);

print "right off, we are $User with id $userid";


$debug = 0;
$debug = $in{'_debug'} || $in{'_DEBUG'} || $debug;

if ($debug) {
	print "Content-type: text/html\n\n";
	print "Debug mode";
}

if (($in{'URL'} =~ /enbloc-system/) || ($in{'short_content'} =~ /work.*at.*home/i)) {
	die;
}

$cat = $in{'_catid'} || $in{'_CATID'};
$type = $in{'_type'} || $in{'_TYPE'};

$rel_itemid = $in{'_related_to_item'} || $in{'_RELATED_TO_ITEM'} || undef;
$relation = $in{'_relation'} || $in{'_RELATION'} ||  'HAS_COMMENT';

$reply = $in{'_reply'} || $in{'_REPLY'};

$item_rank = $COMMENT;

#$url = $in{'url'} || $in{'URL'} || '';

$anon_ok = 0;
## AACK - HACK - should use lookup table of multiple q & a's
if ($in{'human_check_1'} eq 'wall') { 
	$anon_ok = 1;
}

$username = &AbSecure::get_username;
$groupname = '';
if (! $username) {

	if ($anon_ok) {
		$username = 'Guest';
	} else {
		#$debug || print("Content-type: text/html\n\n");
		print("Content-type: text/html\n\n");
		print "Sorry, you must be logged in to perform posts.  Please press the back arrow to return to the page you were at and look for  the 'login' link, or use this <A HREF='http://abra.btucson.com/php/access_user/login.php'>generic login</A> page\n";
		exit;
	}
}	



my $ownerid = &AbSecure::get_userid($username);
if (! $ownerid) {
	#$debug || print "Content-type: text/html\n\n";
	 print "Content-type: text/html\n\n";
	 print "Sorry, username $username is not a recognized user.  Please <A HREF='http://iwhome.com/iwork/dform2.html'>contact Internet WorkShop</A> if you believe this error message is incorrect.\n";
	exit;
}


# TODO: default type PLUS x:y specific types - normalize, dammit!




$sec_level = $PUBLIC_ACCESS_LEVEL;
if ($username eq 'Guest') {
	$sec_level = $OWNER_ACCESS_LEVEL;
}

# add related_text

# TODO add comment text here

################################################


# add relation if $related_to is defined
if (defined($related_to)) {

	&AbUtils::add_relation($curid,$ITEMTYPE, $related_to, $ITEMTYPE, $relation); 

}

# we don't have perms to do this, but can set flag for crontab
# generally new items have to be approved anyway
# system("cd /home/sites/iwtucson/catpages/; /usr/local/bin/abmakeall.pl");

print "Location: $reply\n\n";
                                                                                                             
close F;

1;



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
	if ($sth) {
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
	
	print "Content-type: text/html\n\n";
	print "<HTML><font size='+1'>";
	print "Sorry, an error has occurred: $msg<p>";
	print "Got inputs ",%in;
	print "Please contact <A HREF='mailto:Golda\@AmericansForEdwards'>Golda\@AmericansForEdwards</A> and I will help you get set up right away!";
	print "</font></html>\n";
	exit(1);
}	
