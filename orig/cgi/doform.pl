#!/usr/local/bin/perl -T

use CGI qw(:cgi-lib);

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

$SPECIALCHARS = '#%';
# TODO: add 'description', 'content', 'rel:[RELATION]:handle|string|url
$IDENTS = "cat title url text handle";
$ANONUSERID = 65535;
$TYPE = 'type';

BEGIN {
# Hack for testing
  if ($0 =~ /org/) {
        $DBNAME = 'rpub';
        $DBUSER = 'groots';
        $DBPASS = 'sqwert';
	$debug = 1;
  } else {
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
	$debug = 1;
  }
}

open F, ">/home/abra/data/formlogfile";

open G, ">/home/abra/data/lastform";
print G "User input:\n";
print G %in;
foreach my $key (keys %in) {
	print G "$key: $in{$key}\n";
}
close G;



# Now do our database stuff
BEGIN{
	unshift @INC, "/w/abra/cgi";
}
BEGIN{
	use RCategories;
	use Mysql;
	use DBI;

	$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');
	$dbh = $obj->{'dbh'};

	if (!$obj) {
        	print "Error - cannot connect to database";
        	exit;
	}
}

use AbHeader qw( :all );
use AbUtils;
use AbSecure;

$debug = 1;
$debug = $in{'_debug'} || $in{'_DEBUG'} || $debug;

$catstring = $in{'_cat'} || $in{'_CAT'};
$type = $in{'_type'} || $in{'_TYPE'};

$title_input = $in{'_title'} || 'title';
@alltitles = split(/\s+/,$title_input);
$title = '';
foreach $tinput (@alltitles) {
	$title .= $in{$tinput}.' ';
}
chop $title;

$reply = $in{'_reply'} || $in{'_REPLY'};

$url = $in{'url'} || $in{'URL'} || '';

if ($debug) {
	print "Content-type: text/html\n\n";
	print "Debug mode";
}

# Security check - never allow anonymous users to post anything anywhere
my $username = &AbSecure::get_username;
if (! $username) {
	$debug || print "Content-type: text/html\n\n";
	print "Sorry, you must be logged in to perform posts.  Please press the back arrow to return to the page you were at and look for  the 'login' link\n";
	exit;
}	

my $ownerid = &AbSecure::get_userid($username);
if (! $ownerid) {
	$debug || print "Content-type: text/html\n\n";
	 print "Sorry, username $username is not a recognized user.  Please <A HREF='http://iwhome.com/iwork/dform2.html'>contact Internet WorkShop</A> if you believe this error message is incorrect.\n";
	exit;
}


# TODO: default type PLUS x:y specific types - normalize, dammit!

$cat = ParseCatString($catstring);
$debug && print(" catstring is $catstring Cat is $cat");

if (! $debug) {$cat = 256;}	#just for now!!!!

if (! ($cat && $type) ) {
	&ErrorExit("Required fields _cat and _type not found (values $cat, $type), or category $catstring not found");
}

# TODO: send to me & Mike or whoever is the sendto for cat

%namedhash = ();
foreach $field (keys %in) {
	if ($field !~ /^_/) {
		$namedhash{$type}{$field} = $in{$field};
	}
}
print F "Trying to add cat $cat, title $title, url $url\n<br>";
$debug && print "Trying to add cat $cat, title $title, url $url\n<br>";


my $curid = &AbUtils::add_item(
	'cid' => $cat,
	'itemname' => $title,
	'itemvalue' => $url,
	'security_level' => 0,
	'iref' => \%in
);

#my $curid = AddItem($cat, $title, '', $url, 0, &AbUtils::make_type_string(\%namedhash));
#print "Got id $curid, Adding to tables: "; print keys(%namedhash{'students4'}); print "<p>\n";

&AbUtils::add_to_tables($curid,\%namedhash);

print "Location: $reply\n\n";
                                                                                                             
close F;

1;


# Each line might have
#
# optional_cntrlchars optional_cmd identifier: content
#
#

sub AddItem {
	my ($cid, $title, $text, $url, $uid, $qualifier) = @_;
	my $id = 0;

	if (! ($title || $text || $url)) { return 0;}

	my $value = $url;
	my $content = '';
	my $val_needs_id = 0;
	if ($value && $text) {
		# TODO HERE : need related text
		
		# how long is related text?
		if (length($text)> 2^16) {
			$content = substr($text,0,2^16);
		} else {
			$content = $text;
		}	
	} elsif ($text) {
			
		# still check how long text is, may be too long for value
		if (length($text) < 255) {
			$value = $text;
		} else {
#			$value = substr($text,0,252).'...';
			$value = $DISPLAY_URL."?table=content&id=$id";
			$val_needs_id = 1;
			$content = $text;
			if ($qualifier) { $qualifier .= ','; }
			$qualifier .= "TYPE:content";
		}
	}

	$id = &AbUtils::add_item($cid, $title, $value, 0, 0, $uid,$qualifier);

	if ($content) {

		$q = "insert into content set ID=$id, content=".$dbh->quote($content);	
		my $sth = $dbh->prepare($q);
		$sth->execute;

		if ($val_needs_id) {
			$q = "update rcatdb_items set value='$DISPLAY_URL?table=content&id=$id' where ID=$id";
			 $sth = $dbh->prepare($q);
                	 $sth->execute;
		}
	}

#print "Added item: $id:$title:$value\n";
	return $id;
}


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
