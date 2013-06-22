#!/usr/local/bin/perl -T
 
BEGIN {
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
#	$DBNAME = 'rpub';
#	$DBUSER = 'groots';
#	$DBPASS = 'sqwert';
#	$THISCGI = "http://qs.abra.info/cgi/org.pl";

#} else {
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "/cgi/ab.pl";
	$ADMINUSER = 1;
	$ALT_ADMIN_USER = 7886;
	$JASON_ADMIN_USER = 10925;

#}


if (($ENV{'SERVER_NAME'} =~ /myrecipesearcher.com/i) || ($ENV{'SERVER_NAME'} =~ /bcookin.com/i)) {
	#$DBNAME = 'ab_recipes';
	$THISCGI = 'http://'.$ENV{'SERVER_NAME'}.'/cgi/ab.pl';
	
}

$debug = 0;

if ($debug) {
	print "Content-type: text/html\n\n";
	print "Debug mode...";
}

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
my $LOGINURL = 'http://abra.info/php/access_user/login.php';
my $REGISTERURL = 'http://abra.info/php/access_user/register.php';
my $ACCOUNTURL = 'http://abra.info/classes/access_user/example.php';

my $LOGIN_SNIPPET = '/w/abra/templates/login.html';

ReadParse(\%in);

$ret_url = $in{'_REPLY'} || '';

if (!$debug && $ret_url) {
	print "Location: $ret_url\n\n";
} else {
	print "Content-type: text/html\n\n";
	print "<!-- UID = ",$<,"Query string = ",$ENV{'QUERY_STRING'},"-->\n";
}
$query = $in{CGI};


# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}

# Security check - never allow anonymous users to post anything anywhere
$User = &AbSecure::get_username;
$userid = &AbSecure::get_userid($User);

$is_admin_user = check_admin_user($userid);

$debug && print "right off, we are $User with id $userid <br>";


$curcat = $in{'_CATID'};
$curitem = $in{'_ITEMID'} || 0;
$userpref = $in{'_USERPREF'} || $is_admin_user;	# ACL type code

$itemowner = 0;
if ($curitem) {
	$itemowner = &AbUtils::get_itemowner($curitem);
}

$debug && print "Working on item $curitem in cat $curcat<br>\n";

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
$catowner = &AbUtils::get_catowner($curcat) || 0;

$debug && print "We are $userid catowner is $catowner<br>\n";

if ($curcat && ( $catowner && ($catowner == $userid) || $is_admin_user)) {


	$debug && print "Ok, working on cat $curcat...";

	# also set a flag for display later
	$bOwner = 1;

	if ($in{'newsubcat'} ne '') {
	
	# my @cattypes = $query->{'cattypes'};
	# print "Cattypes are ",@cattypes,"\n";

		my @cattypes = split('\0',$in{'cattypes'});
		#print "Cattypes are ",@cattypes,"\n";

		&AbUtils::add_subcat('cid'=>$curcat, 'newcatname'=>$in{'newsubcat'}, 
			'owner'=>$userid,'cattypesref'=>\@cattypes);
	}	

	if ($in{'_DELCAT'}) {	# TODO: check permissions (might not be subcat of curcat)
		&del_cat($in{'_DELCAT'});
	}

	if ($in{'_DELITEM'}) {	# TODO: check permissions
		print "Going to delete $curitem";
		&AbUtils::del_item($in{'_DELITEM'});
	}
	my $newid = 0;
	if (($in{'newitem'} ne '')||(($action eq 'AddItem') && ($in{'TYPE:content:content'} ne ''))) {
		my $edate = $in{'EFFECTIVE_DATE'};
# SO strange - nul character is coming out as true val length 1 !
		if ($edate && (length($edate) <= 1)) {
			$edate = '';
		}
$debug && print "Before add, edate is $edate length is ".length($edate);

if ($edate) {print "Truth value of edate is TRUE!";}

		$newid = &AbUtils::add_item(
			'cid' => $curcat, 
			'itemname' => $in{'newitem'}, 
			'handle' => $in{'newitemhandle'},
			'short_content' => $in{'SHORT_CONTENT'},
			'url' => $in{'URL'},
			'effective_date' => $edate,
		);
#print "*** add item successful, newid is $newid , relate is $in{'relateitemtoid'} *** <br>\n";
		if ($newid && $in{'relateitemtoid'}) {
			&AbUtils::add_relation($newid, $ITEMTYPE, $in{'relateitemtoid'});
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
		print "<br>calling edit with ",%in,"<p>";
                my $newcid = undef;
                if ($in{'catcode'}) {
                    my $new_catcode_str = $in{'catcode'};

                    # Might be of form NN/NN/NN instead of NN:NN:NN; fix slashes
                    $new_catcode_str =~ s/\//:/g;

                    my $new_catcode = &AbUtils::catcode_from_str($new_catcode_str);
                    $newcid = &AbUtils::catid_from_code($new_catcode);
                    $debug && print "<p>Got NEW cid: $newcid\n<p>\n";
                } else {
                    $newcid = $in{'catid'};
                }
		my $edit_result = &AbUtils::edit_item(
                	'cid' => $newcid,
			'id' => $curitem,
                	'itemname' => $in{'ITEMNAME'}
        	);

		if ($edit_result) {
			$curcat = $in{'catid'};
		}
		# on error?
	} elsif ($action eq 'EditCat') {
		print "<br>calling edit with ",%$iref,"<p>";
		my $edit_result = &AbUtils::edit_cat(
			'catid' => $curcat,
                	'parent_cid' => $in{'cid'},
                	'catname' => $in{'CATNAME'}
        	);

	}
} # end stuff we can do if we are category owner

# here are things we can do if we are item owner
if ($curitem && ($itemowner == $userid)) {

	if ($action eq 'EditItem') {
                print "<br>calling edit with ",%in,"<p>";
                
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
	

}



############################

my @subcats = ();
$debug && print "about to get subcats...";
&AbUtils::get_subcats($curcat, \@subcats, $userid);
&fmt_array_for_table(\@subcats, 4);	# 4-column table

my @catitems = ();

#&get_catitems($curcat, \@catitems);

$debug && print "About to get allowed catitems...";

&get_allowed_catitems($curcat, \@catitems, $userid);

#&fmt_array_for_table(\@catitems, 5);	# 5-column table

my @catrelated = ();
&AbUtils::get_relations($curcat, 'category', 'ALL', \@catrelated);
&fmt_array_for_table(\@catrelated, 5);	# 5-column table

$catref = new AbCat($curcat);
$catpath = &AbUtils::make_catpath($catref);

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
$templatehash{'CATCODE'} = &AbUtils::catcodestr($catref->{'CATCODE'});
$templatehash{'CATID'} = $curcat;
$templatehash{'ITEMID'} = $curitem;
$templatehash{'THISCGI'} = $THISCGI;
$templatehash{'BLOGCGI'} = $BLOGCGI;
$templatehash{'USERPREF'} = $userpref;
$templatehash{'THISLINK'} = &make_link($curcat, $curitem);
$templatehash{'NEXTPAGE'} = $nextpage;
$templatehash{'SHOW_LOGIN'} = $User eq '' ? 1 : 0;

if ($templatehash{'SHOW_LOGIN'}){
	open F, $LOGIN_SNIPPET;
	my @lines = <F>;
	$templatehash{'LOGINCODE'} = join("\n",@lines);
	close F;
}

$templatehash{'LOGINLINK'} = "<A HREF=\"".$LOGINURL."\">login</A>";
$templatehash{'REGISTERLINK'} = "<A HREF=\"".$REGISTERURL."\">register</A>";
$templatehash{'ACCOUNTLINK'} = "<A HREF=\"".$ACCOUNTURL."\">my account</A>";
$templatehash{'ABTYPES'} = \@ABTYPES;

if ($curitem) {
        $templatehash{'ITEMNAME'} = $iref->{'NAME'};
	$templatehash{'URL'} = $iref->{'URL'};
        $templatehash{'ITEMVALUE'} = &AbUtils::html_quotes($iref->{'VALUE'});
	$templatehash{'SHORT_CONTENT'} = $iref->{'SHORT_CONTENT'};
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

$templatehash{'SIDEBAR_IMGS'} = $abm->SideBarImgs();
$templatehash{'FEATURE_HEADLINES'} = $abm->FeatureHeadlines();
my $tmpstring = $abm->ProcessFile($templatefile);

#print "Basing output on $templatefile\n";

&CommandWeb::OutputfromTemplateString($tmpstring,\%templatehash) || &ErrorExit("CommandWeb::OutputToWeb failed on $templatefile, string was $tmpstring, hash was ",%templatehash);

$dbh->disconnect;

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
	# get data now for special types
	my $q = '';
	foreach my $key (keys %varhash) {
#print "Working on $key...";

		# do this before uc() because table name may be case-sensitive
		if ($key =~ /^TYPE/) {
			&AbUtils::prepare_template_hash_types($id, $templatehashref, \$key);


		}


                my $fieldname = uc($key);
                if (($fieldname ne 'ID') && ($fieldname !~ /^TYPE/) && $ItemFieldsRef->{$fieldname}) {
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

#print "Query is $q";

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

#print "Updating table $tname...\n";

		my $cols = '';

		my $rref = $tref->{$tname};
		foreach $key (keys %$rref) {
			$cols .= "$key".',';		
			$vals .= $dbh->quote($rref->{$key}).',';
		}
		$cols .= "id";
		$vals .= $id;

		$sqlst = "REPLACE INTO $tname ($cols) VALUES ($vals)";
#warn "replacing via $sqlst\n";
#print "Replacing $sqlst\n";
		my $sth = $dbh->prepare($sqlst);
		$sth->execute;
	}
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
	my $curcat = shift || 0;
	my $itemref = shift;
	my $userid = shift;

# First, who are we in relation to the category owner?
	my $catowner = &AbUtils::get_catowner($curcat) || 0;

	my $our_access_level = &AbUtils::get_access_level($userid, $catowner, $curcat) || 0;

$debug && print "Owner is $catowner, we are $userid, Our access level is $our_access_level";

	my $q = "select * from $ITEM_TABLE where CID = $curcat and ($our_access_level >= security_level OR security_level is NULL) order by effective_date desc, ENTERED desc";
	&AbUtils::get_query_results($itemref, $q);

$debug && print "executed $q";

# values->urls if match
	for my $p (@$itemref) {

#print "Hash is ",%$p,"<p>";	
		$p->{'LINK'} = $p->{'URL'};
		
		$p->{DEL_ITEM} = &AbUtils::make_href_link($curcat,0,_DELITEM=>$p->{'ID'})."X</A>";

#TODO: improve templating
	
		$p->{META_DESCRIPTION};
		$p->{RELATED_LINKS} ='';
# &AbUtils::make_rel_links($p->{'ID'});
		$p->{TABLE_LINKS} = ''; # &make_table_links($p->{'ID'},$p->{'QUALIFIER'});
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

################
sub testprint {
   if(!$obj->errorno())
     {
      foreach $l (@res)
       {
       	 # Take attantion of new $qualifier field...
       	 my %inp = %$l;
         my ($type,$id,$parent_category,$name,$value,$qualifier,$route) =
            ($inp{'type'},$inp{'ID'},$inp{'CID'},$inp{'NAME'},$inp{'VALUE'},$inp{'QUALIFIER'},$inp{'route'});
         print "Type:   $type<BR>\n";
         print "ID:     $id<BR>\n";
         print "PARENT: $parent_category<BR>\n";
         print "NAME:   $name<BR>\n";
         print "VALUE:  $value<BR>\n";
         print "PATH:   ";
         my @path = @$route;
         foreach my $p (@path)
          {
	   print "\\".$p->{'NAME'};
          }
         print "<BR>\n";
       }
     }
    print "<HR>\n";
}

sub check_admin_user {
	my $userid = shift;

	return (($userid == $ADMINUSER) 
	|| ($userid == $ALT_ADMIN_USER)
	|| ($userid == $JASON_ADMIN_USER) ) ;
} 
