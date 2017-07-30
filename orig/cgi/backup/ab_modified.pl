#!/usr/local/bin/perl -T
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC, '/w/abra/lib');
unshift(@INC, '/w/abra/cgi');
}

use AbHeader qw(:all);
use Abra;
use AbUtils;
use AbSecure;
use AbMacros;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

use CGI::Lite;
use PHP::Session;

# Hack for testing
#if ($0 =~ /org/) {
#	$DBNAME = 'rpub';
#	$DBUSER = 'groots';
#	$DBPASS = 'sqwert';
#	$THISCGI = "http://qs.abra.btucson.com/cgi/org.pl";
#} else {
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.btucson.com/cgi/ab.pl";
	$ADMINUSER = 1;

#}
$debug = 1;


# TODO: put these in a module
# additional tables: 
#	(about an item)
#	Metadata : id (item), userid, title, description, author, ACL  # primarily for DISPLAY - authoritative, nice information, entered by item owner 
#2do	WordLookup: keyword, id, userid, context (=catcode), relevence (=score,100% for handles)  # for SEARCHING - lots of info gathered by wg on results output page
#	Handles : id, handle, type, userid

#	(part of an item - ref by TYPE: in qualifier)
#	Content: id (item), summary, content, ACL # part of an item
#	RelatedContent: uid (relation), text, ACL # part of a relation
#
#	User: from AccessUser : id (user_id), login, pw, real_name, extra_info, email, tmp_mail, access_level, active
#	User_Profile : From AccessUser : id, users_id, language, address, postcode, city, country, phone, fax, homepage, notes, last_change, 
#2do	Event: id, userid, date, time, nicedate, location, description, directions, RSVP, ACL
#2do	Product: 

#	(for viewing data, other controls)												  # catcode comes from category of archive being searched at the time
#2do	UserPref
#2do	Filter
#	View

# Extra columns in ITEMS and CATEGORIES tables
#  	catcode, owner, ACL

# Extra column in RELATIONS tables
#2do	userid

# Do NOT use our templates for generating nice webpages 
# - just export to XML and use a stylesheet

# referred to in QUALIFIER:  TYPE:TABLENAME,TABLENAME,...
# URL generally is in the item itself as the value 
# id = ITEM id



# will need
# use UserPref.pm
# use DataMeta.pm
# use KnownRelations.pm
# use ACL.pm

$SHOWDELMASK = 1;
my %templatehash = ();

# Get user input
%in = ();
$inref = \%in;

$WWWUID = 444;	# TODO: set in install

defined($ENV{'QUERY_STRING'}) && ($CalledFromWeb = 1);
($< == $WWWUID) && ($CalledFromWeb = 1);

my $session_name = 'PHPSESSID';
my $cgi_lite = new CGI::Lite;
my $cookies = $cgi_lite->parse_cookies;

my $USER_VAR = 'user';
my $LOGINURL = 'http://abra.btucson.com/php/access_user/login.php';
my $REGISTERURL = 'http://abra.btucson.com/php/access_user/register.php';
my $ACCOUNTURL = 'http://abra.btucson.com/classes/access_user/example.php';


print "Content-type: text/html\n\n";
print "<!-- UID = ",$<,"Query string = ",$ENV{'QUERY_STRING'},"-->\n";
ReadParse(\%in);
$query = $in{CGI};

# Use MySQL (or DBI) to connect
$abra = new Abra;

$dbh->{'FetchHashKeyName'} = 'NAME_uc';



if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}


# Security check - never allow anonymous users to post anything anywhere
$User = &AbSecure::get_username;
$userid = &AbSecure::get_userid($User);

print "right off, we are $User with id $userid";


$curcat = $in{'_CATID'};
$curitem = $in{'_ITEMID'} || 0;
$userpref = $in{'_USERPREF'} || 0;	# ACL type code

#print "Userpref is $userpref\n";

$action = $in{'ACTION'} || '';
$nextpage = $in{'NEXTPAGE'} || '';

if ($curitem && !defined($curcat)) {
	$curcat = &AbUtils::getcatfromitem($curitem) || 0;
}

my $ItemFieldsRef = &AbUtils::getItemFields();

if (!defined($curcat) && $User && ($User ne 'guest')) {
	$curcat = &AbUtils::getcatfromuser($User) || 0;
}

&get_userprefs($userpref,\%templatehash);

############################
#TODO: action loop

# Only allow modifying anything if we are owner of the category
$bOwner = 0;
$catowner = &AbUtils::get_catowner($curcat);

if ($curcat && $catowner && ($catowner == $userid) || ($userid == $ADMINUSER)) {

	# also set a flag for display later
	$bOwner = 1;

	if ($in{'newsubcat'} ne '') {
	
	# my @cattypes = $query->{'cattypes'};
	# print "Cattypes are ",@cattypes,"\n";

		my @cattypes = split('\0',$in{'cattypes'});
		#print "Cattypes are ",@cattypes,"\n";
print "About to ad subcat...";
		&AbUtils::add_subcat('cid'=>$curcat, 'newcatname'=>$in{'newsubcat'}, 
			'owner'=>$userid, 'cattypesref'=>\@cattypes);
print "did it.";
	}	

	if ($in{'_DELCAT'}) {	# TODO: check permissions (might not be subcat of curcat)
		&del_cat($in{'_DELCAT'});
	}

	if ($in{'_DELITEM'}) {	# TODO: check permissions
		&del_item($in{'_DELITEM'});
	}
	my $newid = 0;
	if (($in{'newitem'} ne '')||(($action eq 'AddItem') && ($in{'TYPE:content:content'} ne ''))) {

		$newid = &AbUtils::add_item(
			'cid' => $curcat, 
			'itemname' => $in{'newitem'}, 
			'handle' => $in{'newitemhandle'},
		);

		if ($newid && $in{'relateitemtoid'}) {
			&add_relation($newid, $ITEMTYPE, $in{'relateitemtoid'});
		}

	}

	if ($in{'addcathandle'} ne '') {
		&add_handle($curcat, $in{'addcathandle'}, 'C');
	}

	if ($in{'relatecatto'} ne '') {
		my $rel = $in{'relatecatto'};
		&add_related($curcat, $CATTYPE, $in{'relatecatto'}, $in{'relatecat'});
	}

	if (($in{'relateitemto'} ne '')&&$curitem) {
		&add_related($curitem, $ITEMTYPE, $in{'relateitemto'}, $in{'relateitem'});
	}


	if (($action eq 'AddText') && $curitem && $in{'RELATION'}) {
		&AbUtils::add_related_text($curcat, $curitem, $in{'RELATION'},$in{'text'})  # TODO pass by ref without extra copy - how?

	} elsif ($action eq 'EditItem') {
		print "<br>calling edit with ",%$iref,"<p>";
		my $edit_result = &AbUtils::edit_item(
                	'cid' => $in{'catid'},
			'id' => $curitem,
                	'itemname' => $in{'ITEMNAME'}
        	);

		if ($edit_result) {
			$curcat = $in{'catid'};
		}
		# on error?
	}
} # end stuff we can do if we are category owner



############################

my @subcats = ();

&AbUtils::get_subcats($curcat, \@subcats, $userid);
&fmt_array_for_table(\@subcats, 4);	# 4-column table

my @catitems = ();

#&get_catitems($curcat, \@catitems);

&get_allowed_catitems($curcat, \@catitems, $userid);

#&fmt_array_for_table(\@catitems, 5);	# 5-column table

my @catrelated = ();
&AbUtils::get_relations($curcat, 'category', 'ALL', \@catrelated);
&fmt_array_for_table(\@catrelated, 5);	# 5-column table

$catref = &get_cat($curcat);
$catpath = &make_catpath($catref);

my @itemrelated = ();
if ($curitem) {
	&AbUtils::get_relations($curitem, 'item', 'ALL', \@itemrelated);
	&fmt_array_for_table(\@itemrelated, 5);	# 5-column table
	$iref = &AbUtils::get_item_byid($curitem);
}


$templatehash{'SUBCATS'} = \@subcats;
$templatehash{'CATITEMS'} = \@catitems;
$templatehash{'ITEMRELATIONS'} = \@itemrelated;
$templatehash{'CATRELATIONS'} = \@catrelated;
@relation_names = ();
foreach my $mrel (keys(%RELATIONS)) {
	my $href = {'NAME'=>$mrel};
	push @relation_names, $href;
}
$templatehash{'RELATIONS'} = \@relation_names;
$templatehash{'CATPATH'} = $catpath;
$templatehash{'CATNAME'} = $catref->{'NAME'};
$templatehash{'CATVAL'} = $catref->{'VALUE'};

$catcode = $catref->{'CATCODE'} || $catref->{'catcode'};
if (! $catcode) {
	print "oops! <p>No catcode string!</p>\n";
} else {
	print "yes, <p>catcode is of length",length($catcode),"</p>\n";
}

$templatehash{'CATCODE'} = &AbUtils::catcodestr($catcode);
$templatehash{'CATID'} = $curcat;
$templatehash{'ITEMID'} = $curitem;
$templatehash{'THISCGI'} = $THISCGI;
$templatehash{'BLOGCGI'} = $BLOGCGI;
$templatehash{'USERPREF'} = $userpref;
$templatehash{'THISLINK'} = &make_link($curcat, $curitem);
$templatehash{'NEXTPAGE'} = $nextpage;
$templatehash{'SHOW_LOGIN'} = $User eq '' ? 1 : 0;
$templatehash{'LOGINLINK'} = "<A HREF=\"".$LOGINURL."\">login</A>";
$templatehash{'REGISTERLINK'} = "<A HREF=\"".$REGISTERURL."\">register</A>";
$templatehash{'ACCOUNTLINK'} = "<A HREF=\"".$ACCOUNTURL."\">my account</A>";
$templatehash{'ABTYPES'} = \@ABTYPES;

if ($curitem) {
        $templatehash{'ITEMNAME'} = $iref->{'NAME'};
        $templatehash{'SHORT_CONTENT'} = &AbUtils::html_quotes($iref->{'SHORT_CONTENT'});
        $templatehash{'ITEMDESC'} = &AbUtils::html_quotes($iref->{'DESCRIPTION'});
	$templatehash{'ITEMCODE'} = &AbUtils::catcodestr($iref->{'ITEMCODE'});
}

# we know that vars are
#'type','ID','CID','NAME','VALUE','QUALIFIER','route'

###################################################
# TODO: nextpage 

my $abm;
if ($curitem) {
	$abm = new AbMacros(itemid=>$curitem, catid=>$curcat);
} else {
	$abm = new AbMacros(catid=>$curcat);
}

# default next page
$templatefile = &lookupTemplate($curcat, $userid, $nextpage);
$possible_template_file = $ABTEMPLATE_DIR.'/tmpl'.$nextpage.'.html';
if (! $templatefile) {
	if ($bOwner && ($nextpage eq 'AddText')) {
		$templatefile = 'tmplAddText.html';
	} elsif ($bOwner && ($nextpage eq 'LookupHandles')) {
		$templatefile = 'tmplLookupHandles.html';
		$templatehash{'HANDLES'} = &get_handle_list;
	} elsif ($nextpage eq 'Browse') {
		$templatefile = 'tmplSimpleBrowse.html';
	} elsif ($bOwner && ($nextpage eq 'Edit')) {
		$templatefile = 'tmplBrowse.html';
	} elsif ($bOwner && ($nextpage eq 'EditItem')) {
#		my $tref = &AbUtils::get_subcat_tree_making_catcodes($curcat);
		my $tref = &AbUtils::get_subcat_tree($curcat);
		@$tref = sort { $a->{'SUBCATPATH'} cmp $b->{'SUBCATPATH'} } @$tref;
		$templatehash{'CATLIST'} = $tref;
		$templatefile = 'tmplEditItem.html';
		fill_template_from_db({ file=>$templatefile, templatehashref=>\%templatehash,id=>$curitem });
	} elsif ( -e  $possible_template_file ) {
		$templatefile = $possible_template_file;
	} else {
		$templatefile = 'tmplBrowse.html';
	}
}

if ($templatefile !~ /^\//) {
	$templatefile = $ABTEMPLATE_DIR.'/'.$templatefile;
}


my $tmpstring = $abm->ProcessFile($templatefile);

&CommandWeb::OutputfromTemplateString($tmpstring,\%templatehash) || &ErrorExit("CommandWeb::OutputToWeb failed on $templatefile, string was $tmpstring, hash was ",%templatehash);

1;


##############################################################
# abra://server/cat/subcat/subsubcat
# abra:handle	 (assume local context)
# abra:/cat/subcat/subsubcat (assume local context)
sub resolve_aburl {
	my $aburl = shift;

	if ($aburl =~ /^abra:([^\/]+)$/) {
		return &resolve_handle($1);
	} elsif (($aburl =~ /^abra:\/\/(.+)$/)||($aburl =~ /^abra:\/([^\/].+)$/)) {
		return &resolve_catpath($1);
	} else {
		return ();
	}
}

##############################################################
sub resolve_handle {
	my $handle = shift;

	$q = "select ID, TYPE from handles where handle = ".$dbh->quote($handle);
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my ($id, $type) = $sth->fetchrow_array;
	return ($id, $type);
}

##############################################################
sub get_handle_list {
	my $ref;		
	my @harr = ();

#TODO : add userid
	$q = "select handles.ID, handles.HANDLE, $ITEM_TABLE.NAME from handles, 
$ITEM_TABLE where handles.ID = $ITEM_TABLE.ID AND handles.TYPE='I'";
	&AbUtils::get_query_results(\@harr, $q);
	$q = "select handles.ID, handles.HANDLE, $CAT_TABLE.NAME from handles, $CAT_TABLE where handles.ID = $CAT_TABLE.ID and handles.TYPE='C'";
	$sth = $dbh->prepare($q);
	if ($sth && $sth->execute()) {
		while ($ref = $sth->fetchrow_hashref('NAME_uc')) {
			$ref->{'ISCATEGORY'} = 'Y';
			push @harr, $ref;
		}
		$sth->finish();
	}
	return \@harr;		

} 


##############################################################
sub resolve_catpath {


}


##############################################################
sub get_userprefs {
	($prefs,$href) = @_;

	($prefs && $SHOWDELMASK) && ($href->{'SHOW_DELETE'} = 1);
}




##############################################################
sub add_related {
	my $id = shift;
	my $type = shift;
	my $string = shift;
	my $relation = shift;

	$type = $RELTYPES->{$type};
	my $hid = 0;
	my $htype = '';
	($hid, $htype) = &resolve_handle($string);
	my $uid = 0;
	if ($hid) {
		$uid = &add_relation($id, $type, $hid, $htype, $relation);
	} else {
		$uid = &AbUtils::add_related($id, $type, $string, $relation);
	}
	if (! $uid) {
		print "Error, no relation added\n";
	}		

	return $uid;
}




##############################################################
sub add_relation {
	my $id = shift;
	my $fromtype = shift || $ITEMTYPE;
	my $destid = shift || 0;
	my $desttype = shift || $ITEMTYPE;
	my $relation = shift || $DEFAULT_RELATION;

	my $type = '';
	my $dest = '';
	if ($desttype eq $ITEMTYPE) {
		$dest = 'item_dest';
	} else {
		$dest = 'cat_dest';
	}

	if ($fromtype eq $ITEMTYPE) {
		$type = 'item';
	} else {
		$type = 'category';
	}

	&AbUtils::add_related($id, $type, $string, $relation);
	return $uid;
}


##############################################################
sub fill_template_from_db {
	my ($arg_ref) = @_;

	my $id = $arg_ref->{id} || return;
	my $templatefile = $arg_ref->{file} || return;
	my $templatehashref = $arg_ref->{templatehashref} || return;

	# TODO currently only for Items table rcatdb_items; should be more general

	return unless $id;

	# parse template file for (simple) variables
	my %varhash = ();
	if ($templatefile !~ /^\//) {
        	$templatefile = $ABTEMPLATE_DIR.'/'.$templatefile;
	}
	open F, $templatefile;
	while (<F>) {
		while (/\|([^\|]+)\|/g) {
			$varhash{$1} = 1;
		}
	}
	close F;

	# check rcatdb_items table for matching field names
	my $q = '';
	foreach my $key (keys %varhash) {
                my $fieldname = uc($key);
                if (($fieldname ne 'ID') && $ItemFieldsRef->{$fieldname}) {
			$q .= $fieldname.',';
		}
	} 
	return unless $q;

	# select existing values from database
	chop $q;
	$q = "select ".$q." from rcatdb_items where ID = $id";
	my $sth = $dbh->prepare($q) || return;
        $sth->execute() || return;
	my $dataref = $sth->fetchrow_hashref('NAME_uc');

	# fill in template hash accordingly
	foreach my $key (keys %$dataref) {
		$templatehashref->{$key} = $dataref->{$key};
	}

	return;
}


##############################################################
sub fill_template_from_input {
	my $templatehashref = shift;
	my $inputref = shift;

	foreach my $key (keys %$inputref) {
                my $fieldname = uc($key);
                if (($fieldname ne 'ID') && $ItemFieldsRef->{$fieldname}) {
			$templatehashref->{$key} = $inputref->{$key};
		}
	}
	return;
}


##############################################################
sub edit_item {
	my $id = shift;
	my $itemname = shift;
	my $catid = shift || 0;
    	my $iref = shift || 0;

        my %quals = ();
        my $qualifier = &AbUtils::find_types($iref, \%quals);
	&update_tables($id, \%quals);

# update any relevent fields except ID
	my $q = '';
	foreach my $key (keys %$iref) {
		$fieldname = uc($key);
		my $value = $iref->{$key};

		# Special field handling; set defaults
		if (($fieldname eq 'EFFECTIVE_DATE') && ! $value) {	
#			$value = 'today';
# TODO HERE
		}

		if (($fieldname ne 'ID') && $ItemFieldsRef->{$fieldname}) {
			# TODO check type of field
			$qvalue = $dbh->quote($value);
			
			$q .= "$fieldname = $qvalue,";
		}
	}
	chop $q;
	return unless $q;
	
	$q = "update rcatdb_items set ".$q." where ID = $id";	# don't leave dangerous global update query in $q

print "Query is $q";

	my $sth = $dbh->prepare($q);
	$sth->execute;

	return;

}



##############################################################
sub add_handle {
	my $id = shift || return;
	my $handle = shift || '';
	my $type = shift || 'I';

	$sqlst = "INSERT into handles SET id=$id, handle=".$dbh->quote($handle).",type=".$dbh->quote($type);
	my $sth = $dbh->prepare($sqlst);
	$sth->execute;
}

##############################################################
sub add_to_tables {
	my $id = shift;
	my $tref = shift;

	my $sqlst;
	foreach $tname (keys %$tref) {

#TODOTODOTODO:ERROR CHECKING!

		$sqlst = "INSERT into $tname SET id=$id";
		my $rref = $tref->{$tname};
		foreach $key (keys %$rref) {
			$sqlst .= ", $key=".$dbh->quote($rref->{$key});
		}
		my $sth = $dbh->prepare($sqlst);
		$sth->execute;
	}
}

##############################################################
sub update_tables {
	my $id = shift;
	my $tref = shift;

	my $sqlst;
	foreach $tname (keys %$tref) {

#TODOTODOTODO:ERROR CHECKING!

# Using Replace - but we need to make sure all tables have Primary Key / unique index set

# Have to add TYPES: Qualifier if adding new table entry
# may as well separate INSERT and UPDATE

		my $cols = '';

		my $rref = $tref->{$tname};
		foreach $key (keys %$rref) {
			$cols .= "$key".',';		
			$vals .= $dbh->quote($rref->{$key}).',';
		}
		$cols .= "id";
		$vals .= $id;

		$sqlst = "REPLACE INTO $tname ($cols) VALUES ($vals)";

		my $sth = $dbh->prepare($sqlst);
		$sth->execute;
	}
}

##############################################################
sub del_cat {
	my $cid = shift;
print "Can't do this right now - TODO\n";
}

##############################################################
sub del_item {
	my $id = shift;
	my $q = "delete from handles where type='$ITEMTYPE' and id=$id";
	my $sth = $dbh->prepare($q);
	$sth->execute;

	my $href = &AbUtils::get_item_byid($id);

	# delete associated types
	my @tarr = &AbUtils::parse_type_string($href->{'QUALIFIER'});
	foreach $table (@tarr) {
		$q = "delete from $table where id = $id";
	 	my $sth = $dbh->prepare($q);
		$sth->execute;
	}
	print "Can't do this right now - TODO";
}



#############################################################
sub getUserID {
	my $user = shift;
#	my $q = "select ab_users_cats.id from ab_users_cats,users where ab_users_cats.user_id = users.id and login = '$user'";
	my $q = "select id from users where login = '$user'";
	return $dbh->selectrow_array($q);
}

#############################################################
sub lookupTemplate {
	my $cid = shift || 0;
	my $userid = shift || 0;
	my $pagetype= shift || '';

	if (!$cid && !$userid) {
		return '';
	}
	my $where = '';
	if ($userid) {
		$where .= "viewprefs.userid = $userid";
	} 
	if ($cid) {
		if ($where) { 
			$where .= ' or ';
		}
		$where .= "viewprefs.cid = $cid";
	}
	
	my $q = "select views.template_file from views, viewprefs where views.uid = viewprefs.viewid and ($where)";
	if ($pagetype) {
		$pagetype = lc($pagetype);
		$q .= " and pagetype = '$pagetype'";
	}
	my $sth = $dbh->prepare($q);
	my $tfile = '';
	if ($sth) {
		$sth->execute();
		$tfile = $sth->fetchrow_array;
	}
	# TODO: deal with case where multiple matches are found - pick best
	return $tfile;
}






##############################################################
sub make_link {
	my $cid = shift || return('');
	my $id = shift || 0;
	my %extra = @_;

	my $link = $THISCGI."?_USERPREF=$userpref&_CATID=$cid&NEXTPAGE=$nextpage";

	if ($id) {
		$link .= "&_ITEMID=$id";
	}

	for my $key (keys %extra) {
		$link .= "&".$key."=".$extra{$key};
	}

	return $link;
}





####################################################################
# returns all items we have permission to see 
# in a given category as array of hashes
sub get_allowed_catitems {
	my $curcat = shift;
	my $itemref = shift;
	my $userid = shift;

# First, who are we in relation to the category owner?
	my $catowner = &AbUtils::get_catowner($curcat);

	my $our_access_level = &AbUtils::get_access_level($userid, $catowner, $curcat) || 0;

print "Owner is $catowner, we are $userid, Our access level is $our_access_level";

	my $q = "select * from $ITEM_TABLE where CID = $curcat and ($our_access_level >= security_level OR security_level is NULL) order by effective_date desc, ENTERED desc";
	&AbUtils::get_query_results($itemref, $q);

print "executed $q";

# values->urls if match
	for my $p (@$itemref) {

#print "Hash is ",%$p,"<p>";	
		$p->{'LINK'} = $p->{'URL'};
		
		$p->{DEL_ITEM} = &AbUtils::make_href_link($curcat,0,_DELITEM=>$p->{'ID'})."X</A>";

#TODO: improve templating
	
		$p->{META_DESCRIPTION};
		$p->{RELATED_LINKS} = &AbUtils::make_rel_links($p->{'ID'});
		$p->{TABLE_LINKS} = &make_table_links($p->{'ID'},$p->{'QUALIFIER'});
		$p->{ITEMCODE} = &AbUtils::catcodestr($p->{'ITEMCODE'});
	}
	#TODO use proper URL matching
}
####################################################################
# returns all subcategories of given category as array of hashes
sub get_catitems {
	my $curcat = shift;
	my $itemref = shift;

# return array of hashes w/ID,NAME,VALUE,QUALIFIER	

	my $q = "select * from $ITEM_TABLE where CID = $curcat order by ENTERED desc";
	&AbUtils::get_query_results($itemref, $q);
	

# values->urls if match
	for my $p (@$itemref) {

		$p->{'LINK'} = $p->{'URL'};
		
		$p->{DEL_ITEM} = &AbUtils::make_href_link($curcat,0,_DELITEM=>$p->{'ID'})."X</A>";

#TODO: improve templating
	
		$p->{META_DESCRIPTION};
		$p->{RELATED_LINKS} = &AbUtils::make_rel_links($p->{'ID'});
		$p->{TABLE_LINKS} = &make_table_links($p->{'ID'},$p->{'QUALIFIER'});
		$p->{ITEMCODE} = &AbUtils::catcodestr($p->{'ITEMCODE'});
	}
	#TODO use proper URL matching
}

# Currently only support table 'content'
sub make_table_links {
	my $id = shift;
	my $qual = shift;

	my @types = ();
	split_qualifier($qual, \@types);
	my $retstring = '';

	foreach my $tab (@types) {
		$retstring .= "<A HREF='$DISPLAYPHP?table=$tab&id=$id'>$tab</A> ";
	}
	return $retstring;
}


sub split_qualifier {
	my $qual = shift;
	my $aref = shift;
	
	while ($qual =~ /TYPE:([^\s,]+)/g) {
		push @$aref,$1;
	}
}


sub fmt_array_for_table {
	my $aref = shift;
	my $cols = shift;

	my $j = 0;
	for my $href (@$aref) {
	
		if (($j % $cols) == 0) {
			$href->{FMT_BEGIN} = '<TR><TD>';
		} else {
			$href->{FMT_BEGIN} = '<TD>';
		}

		if (($j % $cols) == (-1 % $cols)) {
			$href->{FMT_END} = '</TD></TR>';
		} else {
			$href->{FMT_END} = '</TD>';
		}
		$j++;
	}
}


sub get_cat {
	my $catid = shift;

	my $catref = 0;

	my $q = "select * from rcatdb_categories where id = $catid";

	$catref = $dbh->selectrow_hashref($q);
	
        $catref->{'route'} = &AbUtils::make_route_from_cid($catref->{'CID'});
	$catref->{'CATCODESTR'} = &AbUtils::catcodestr($catref->{'CATCODE'});
print "GOT $catref->{'CATCODESTR'} ; hash is ",%$catref;
	return $catref;
}


sub make_catpath {

	my $catref = shift;

	my $retstring = "\\".&AbUtils::make_href_link(0)."root</A>\\";

	my $path = $catref->{'route'};
	my $j;

        for ($j = $#$path; $j>=0; $j--)
        {
	   my $p = $$path[$j];
           $retstring .= &AbUtils::make_href_link($p->{'ID'}).$p->{'NAME'}."</A>\\";
        }
	$retstring .= &AbUtils::make_href_link($catref->{'ID'}).$catref->{'NAME'}."</A>\\";

	return $retstring;
}


sub ErrorExit {

        my $msg = shift;

#	$msg = &subvars($msg);

        print STDERR scalar localtime, "$msg";

        print "ERROR: $msg\n\n";

        if ($debug) {
                my $name;
                print "Inputs were: <p>\n";
                foreach $name (keys (%in)) {
                        print "$name = $in{$name} <p>\n";
                }
        }

        exit 0;
}

sub printhasharr {
	$ref = shift;
	foreach my $a (@$ref) {
		print "entry:",%$a;
		print "<br>\n";
	}
}

sub printarrarr {

	$ref = shift;
	foreach my $l (@$ref) {
		print "entry:",@$l;
         my ($t,$uid,$id,$type,$cat,$item,$qualifier) = @$l;
         print "Type:   $t<BR>\n";
         print "UID:    $uid<BR>\n";
         print "ID:     $id<BR>\n";
         print "TYPE:   $type<BR>\n";
         print "CAT:    $cat<BR>\n";
         print "ITEM:   $item<BR>\n";
         print "QUALIFIER:  $qualifier<BR>\n";

		print "<br>\n";
	}
}



