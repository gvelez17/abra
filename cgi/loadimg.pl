#!/usr/local/bin/perl -T

use CGI;
use Carp;
use Image::Magick;

# Get user input
%in = ();

$ADMIN_USERNAME = 'gv';

$RESTRICTED_IMG_PATH = '/home/sites/iwtucson/www/restricted/';
$RESTRICTED_IMG_URLPATH = '/restricted/';

$REGULAR_IMG_PATH = '/home/sites/iwtucson/www/item_images/';
$REGULAR_IMG_URLPATH = '/item_images/';

$ORIGINAL_IMG_PATH = '/home/sites/iwtucson/www/item_image_originals/';

$THUMBNAIL_PATH = '/home/sites/iwtucson/www/item_thumbnails/';

# TODO TODO TODO - fix this hack to pass the %in hash to add_item
my $cgi = new CGI;

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


BEGIN {
# Hack for testing
  if ($0 =~ /org/) {
        $DBNAME = 'rpub';
        $DBUSER = 'groots';
        $DBPASS = 'sqwert';
  } else {
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
  }
}

open F, ">/home/abra/data/formlogfile";

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
use DBI;
use CommandWeb;

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}


$debug = 0;

if ($debug) {
	print "Content-type: text/html\n\n";
	print "Debug mode";
}

# make our hash
%in = ();
@names = $cgi->param;
for $name (@names) {
	if ($name ne 'image_file') {
		$in{$name} = $cgi->param($name);
	}
}

$related_to = $in{'_related_to_item'} || $in{'_RELATED_TO_ITEM'} || undef;
$relation = $in{'_relation'} || $in{'_RELATION'} ||  'HAS_COMMENT';

$debug && print "Using tag named $title_input, title is $title...\n";

chop $title;

$reply = $in{'_reply'} || $in{'_REPLY'};

$catid = $in{"_catid"};  # or error

$caption = $in{"caption"};
$credits = $in{"credits"};

$anon_ok = 0;
#
# we don't allow anonymous posting of images for now
#
### AACK - HACK - should use lookup table of multiple q & a's
#if ($in{'human_check_1'} eq 'wall') { 
#	$anon_ok = 1;
#}

$username = &AbSecure::get_username;
$groupname = '';
if (! $username) {

	if ($anon_ok) {
		$username = 'guest';
	} else {
		#$debug || print("Content-type: text/html\n\n");
		print("Content-type: text/html\n\n");
		print "Sorry, you must be logged in to perform posts.  Please press the back arrow to return to the page you were at and look for  the 'login' link, or use this <A HREF='http://abra.info/php/access_user/login.php'>generic login</A> page\n";
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

my $security_level = 0;
my $interest = 0;
my $origpath = '';
# create a db entry
#if ($username eq $ADMIN_USERNAME) {
	$imgpath = $REGULAR_IMG_PATH;
	$tinyimgpath = $THUMBNAIL_PATH;
	$imgurlpath = $REGULAR_IMG_URLPATH;
	$origpath = $ORIGINAL_IMG_PATH;
	$security_level = 0;
	$interest = 20;  # maybe accept $in{interest} or just administer later
#} else {
#	$imgpath = $RESTRICTED_IMG_PATH;
#	$imgurlpath = $RESTRICTED_IMG_URLPATH;
#	$tinyimgpath = '';  # No thumbnail for now
#	$security_level = 100;
# its enough that the image path is restricted, at least for now
#}

# TODO: add effective_date
$debug && print "Going to add image to cat $catid, related to $related_to, owned by $ownerid\n<p>";


$image_file = $cgi->param('image_file');

$ext = '';
if ($image_file =~ /\.([a-zA-Z]+)$/) {
	$ext = $1;
}

$ext = lc($ext);

my $imguid = &AbUtils::add_image(
	'cid' => $catid,
	'related_to' => $related_to,
	'caption' => $caption,
	'credits' => $credits,
	'owner' => $ownerid,
	'security_level' => $security_level,
	'ext' => $ext,
	'interest' => $interest
);


if ($related_to =~ /^([A-Za-z0-9\-\_]+)$/) {
	$related_to = $1;
} else {
	print "Insecure related to $related_to\n";
	exit;
}


# Now upload the image file
my $imgfilename = $related_to.'_'.$imguid.'.'.$ext;

my $imgfile = $imgpath . $imgfilename;
my $tinyimgfile = '';
my $orig_imgfile = '';
if ($tinyimgpath) {
	$tinyimgfile = $tinyimgpath . $imgfilename;
}
my $tmpimgfile = $imgpath . 'tmp.'.$imgfilename;

if ($origpath) {
	$orig_imgfile = $origpath . $imgfilename;
}

$debug && print "Trying to upload to $imgfile\n<p>";

$debug && print "now writing to $tmpimgfile\n";

open(F, ">$tmpimgfile") or die "Could not write to $tmpimgfile",$!;
# TODO: limit filesize!
while (<$image_file>) {
	print F $_;
}
close F;

# resize the sucker


my $img = Image::Magick->new();

eval {
	my $x = $img->Read($tmpimgfile);

	if ($orig_imgfile) {
		$img->Write($orig_imgfile);
	}

	$img->AdaptiveResize('200x200');
	$img->Write($imgfile);

	if ($tinyimgfile) {
		# make tiny thumbnail too
		# my $y = $img->Read($tmpimgfile);
		$img->AdaptiveResize('30x30');
		$img->Write($tinyimgfile);
	}
};

# delete the original
$debug || unlink $tmpimgfile;

# TODO: send to whoever is the sendto for cat



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
