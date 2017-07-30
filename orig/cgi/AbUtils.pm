package AbUtils;

use AbHeader qw(:all);
#use CatTree;
use Carp;

local *obj = *main::obj;
local *dbh = *main::dbh;

# state variables - set only if not set
# do NOT use 'my' - we want to be able to set these externally
$USE_THIS_CGI = $THISCGI if (! $USE_THIS_CGI);

$CUR_USER = '' if (! $CUR_USER);	# Current logged in user (verified)

$CUR_USERID = 0 if (! defined($CUR_USERID));  # now using $main::userid
					 # but calling progs may set differently

$VERIFIED_BY = '' if (! $VERIFIED_BY);	# How verified: may be one of
					#  HTACCESS
					#  ACCESS_USER_COOKIE
					#  (in future - DRUPAL?)
# Users actually could login first via htaccess as a group user,
# then via cookie as an individual.  The most recent login overrides for now.	
1;


##############################################################
sub string_is {
	my $str = shift;

	if ($str =~ /^(https?|file|ftp):/) {
		return $IS_URL;
	} elsif ($str =~ /^abra:/) {
		return $IS_ABRAURL;
	}		
	return 0;
}

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

	local *dbh = *main::dbh;

	$q = "select ID, TYPE from handles where handle = ".$dbh->quote($handle);
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my ($id, $type) = $sth->fetchrow_array;
	return ($id, $type);
}

##############################################################
sub get_catcode {
	my $cid = shift;

	local *dbh = *main::dbh;

	$q = "select catcode from rcatdb_categories where id = $cid";
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my ($catcode) = $sth->fetchrow_array;
	return $catcode;
}

##############################################################
sub get_catowner {
        my $cid = shift;

        local *dbh = *main::dbh;

        $q = "select owner from rcatdb_categories where id = $cid";
        my $sth = $dbh->prepare($q);
        $sth->execute();
        my ($owner) = $sth->fetchrow_array;
        return $owner;
}

#############################################################
sub get_ownername {
	my $ownerid = shift;

        local *dbh = *main::dbh;

        $q = "select real_name from users where id = $ownerid";
        my $sth = $dbh->prepare($q);
        $sth->execute();
        my ($ownername) = $sth->fetchrow_array;
        return $ownername;
}


##############################################################
sub get_itemowner {
        my $id = shift;

        local *dbh = *main::dbh;

        $q = "select owner from rcatdb_items where id = $id";
        my $sth = $dbh->prepare($q);
        $sth->execute();
        my ($owner) = $sth->fetchrow_array;
        return $owner;
}

##############################################################
sub getItemFields {
        my $q = "show fields from rcatdb_items";

       local *dbh = *main::dbh;

        my $href = $dbh->selectall_hashref($q, 'Field');

       # upper case field names TODO better way to do this 
        foreach my $key (keys %$href) {
                my $value = $href->{$key};
                delete $href->{$key};
                $href->{uc($key)} = $value;
        }

        return $href;
}

##############################################################
#  what is our default access level for this category?  
sub get_access_level {
	my $my_user_id = shift;
	my $cat_owner = shift;
	my $catid = shift;

        local *dbh = *main::dbh;

	# is this our own category?
	if ($my_user_id == $cat_owner) {
		return $OWNER_ACCESS_LEVEL;
	}

	# are we friends with this user?
	$q = "select access_level from ab_user_friends where userid = $cat_owner and $friend_id = $my_user_id";
       	my $sth = $dbh->prepare($q);
        $sth->execute();
        my ($default_access_level) = $sth->fetchrow_array;

	# are we allowed specific access to this category?
	$q = "select access_level from ab_access_permissions where catid = $catid and userid = $my_user_id";
        $sth = $dbh->prepare($q);
        $sth->execute();
        my ($category_access_level) = $sth->fetchrow_array;

	my $highest_access_level =  ($default_access_level > $category_access_level
		? $default_access_level
		: $category_access_level)
		|| $PUBLIC_SECURITY_LEVEL;

	return $highest_access_level;
}

##############################################################
sub get_handle_list {
	my $ref;		
	my @harr = ();

local *dbh = *main::dbh;

#TODO : add userid
	$q = "select handles.ID, handles.HANDLE, $ITEM_TABLE.NAME from handles, 
$ITEM_TABLE where handles.ID = $ITEM_TABLE.ID AND handles.TYPE='I'";
	&get_query_results(\@harr, $q);
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


# TODO: hash all routine inputs!!!!
#my %param = shift;

##############################################################
sub add_subcat {

local *obj = *main::obj;
local *dbh = *main::dbh;

	my %param = (
		cid => 0,
		newcatname => '',
		value => '',
		owner => 0,
		@_
	);
	my $cattypesref = $param{'cattypesref'};
	my $newid = 0;

	my $qualifier = '';
	if ($#$cattypesref >=0) {
		$qualifier = "TYPE:";
	}
	foreach my $cattype (@$cattypesref) {
		$qualifier .= "$cattype,";		# Do we want TYPE:x,y format?
	}
	chop $qualifier;


	# is there one already named this?
	my ($count) = $dbh->selectrow_array("select count(*) from rcatdb_categories where cid = ".$param{cid}." and name = ".$dbh->quote($param{newcatname}));
	if ($count) {
		return 0;
	}


	my $catcode = &GenSubCatCode($param{'cid'});
	my $qcatcode = $dbh->quote($catcode);

	$newid = $obj->add('type'=>'CATEGORY', 'category'=>$param{cid}, 'name'=>$param{newcatname}, 'value'=>$param{value}, columns=>{'QUALIFIER'=>$qualifier,'owner'=>$param{owner}});

# obj->add does not handle our pre-quoted binary catcode string correctly	
	$q = "update $CAT_TABLE set catcode = $qcatcode where id = $newid";
	$dbh->do($q);


	if ($newid) {

		if ($debug) {
			print "Added new subcategory: $newid<br>\n";
		}
	} else {
		print "Error: ", $obj->error,"<p>\n";
		print "Query was ",$obj->history('lastquery'),"<p>\n";
	} 
	
	return $newid;
}

# Generate new catcode for new subcategory of parent cat passed
sub GenSubCatCode {
	my $parentcid = shift;

local *obj = *main::obj;
local *dbh = *main::dbh;
	my $catcode = '';

	my $q = "select cid, catcode, lastsubcode from $CAT_TABLE where id = $parentcid";
	my ($grandparentcid, $parentcode, $lastsubcode) = $dbh->selectrow_array($q);
	my @catcode = ();

## TODO check is '' same as pack "C16" array of 0 ?

	if (! $parentcode && ($parentcid > 0)) { # need info, not on top level, recurse

		$parentcode = &GenSubCatCode($grandparentcid);
		$qparentcode = $dbh->quote($parentcode);
#print "Setting parent id $parentcid to code ",&catcodestr($parentcode)," based on grandparent $granparentcid \n<br>";
		$q = "update $CAT_TABLE set catcode = $qparentcode, lastsubcode=0 where id=$parentcid";
		$dbh->do($q);
		# don't return - now proceed to set our catcode
	}

	if ($parentcode) {	# Do we have a valid parent catcode?
       		@catcode = unpack "C16", $parentcode;
		my $lvl = &GetLevel(\@catcode) + 1;
		$lastsubcode++;
		$catcode[$lvl] = $lastsubcode;
		$catcode = pack "C16",@catcode;
		$q = "update $CAT_TABLE set lastsubcode = $lastsubcode where id = $parentcid";
		$dbh->do($q);
		return($catcode);
	} elsif ($parentcid == 0) {	# If we already are on top level
		@catcode = (0) x 16;
		if (! defined($lastsubcode)) {
			$lastsubcode = 0;
		}
		my $lvl = 0;
		$rootcatcode = pack "C16",@catcode;
		$qrootcatcode = $dbh->quote($rootcatcode);
		$lastsubcode++;
		$catcode[$lvl] = $lastsubcode;
		$catcode = pack "C16",@catcode;
#print "Parent is root; Set category at level $lvl to ",&catcodestr($catcode)," for child of $parentcid whose code was ",&catcodestr($parentcode),"<br>\n";
		$q = "update $CAT_TABLE set lastsubcode = $lastsubcode,catcode=$qrootcatcode where id = $parentcid";
		$dbh->do($q);
		return($catcode);
	} 

	# should never happen
	return '';
}

# Returns level from catcode as string
# matches GetLevel - index of last nonzero level
sub GetLevelfromCatcode {
	my $catcode = shift;

        my  @catcode = unpack "C16", $catcode;
        my $lvl = &GetLevel(\@catcode);
	return $lvl;
}


# Returns index of last nonzero level;
# category 01 04 80 0 0 0 0 would be level 2
sub GetLevel {
        my $catref = shift;
                                                                               
        my $lvl = 0;
        while (($lvl < 16) && ($$catref[$lvl] > 0)) {
                $lvl++;
        }
	$lvl -= 1;
        return ($lvl);
}

sub CatCodeFromArray {
		my @cats = @_;
		my $catid = pack "C16", @cats;
}

sub ArrayFromCatCode {
		my $catcode = shift;
		
		my @cats = unpack "C16",$catcode;
$main::DEBUG && print "Array is ",@cats,"<br>\n";
		return \@cats;
}

sub RootCatCode {
	my @cats = (0) x 16;
	my $catcode = &CatCodeFromArray(@cats);
	return $catcode;
}

# maybe have other kinds of things we can attach to a relation - but text will be most common
##############################################################
sub add_related_text {
	my $cid = shift;
	my $itemid = shift;
	my $relation = shift || $DEFAULT_TEXT_RELATION;
	my $text = shift;

local *obj = *main::obj;
local *dbh = *main::dbh;
	# create relation first, we need uid
	my $uid = $obj->r_add(type=>'item',id=>$itemid,relation=>$relation, columns=>{'QUALIFIER'=>'TYPE:relatedcontent'});

## Patch in case Rcategories.pm doesn't do qualifier
#my $dumq = "Update rcatdb_ritems set qualifier='TYPE:relatedcontent'
#where (uid=$uid) and (qualifier IS NULL)";
#my $dumsth = $dbh->prepare($dumq);
##print "dum patch is $dumq\n";
#$dumsth->execute;
# end dum patch

	if (! $uid) {
		print "Error: ",$obj->error,"\n";
		print "Query was ",$obj->history('lastquery'),"<p>\n";
	}		
	# now add entry for text
	my $q = "INSERT INTO relatedcontent SET uid = $uid, text=".$dbh->quote($text);
	my $sth = $dbh->prepare($q);
	$sth->execute;
}

##############################################################
sub add_related {
	my $id = shift;
	my $type = shift;
	my $string = shift;
	my $relation = shift;

local *obj = *main::obj;
local *dbh = *main::dbh;
	$type = $RELTYPES->{$type};
	my $hid = 0;
	my $htype = '';
	($hid, $htype) = &resolve_handle($string);
	my $uid = 0;
	if ($hid) {
		$uid = &add_relation($id, $type, $hid, $htype, $relation);
	} else {
		$uid = $obj->r_add(type=>$type,id=>$id,qualifier=>$string,relation=>$relation);
	}
	if (! $uid) {
		print "Error: ",$obj->error,"\n";
		print "Query was ",$obj->history('lastquery'),"<p>\n";
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

local *obj = *main::obj;
local *dbh = *main::dbh;

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

	my $uid = $obj->r_add(type=>$type,id=>$id,$dest=>$destid,relation=>$relation);

	return $uid;
}

##############################################################
sub edit_item {

local *obj = *main::obj;
local *dbh = *main::dbh;

	my %param = (
		itemowner => $main::userid,
		catid => 0,
		@_
	);
	foreach my $var (
		'id',
		'catid',
		'itemname',
		) {	
		$$var = $param{$var};
	}
 	my $itemowner = &AbUtils::get_itemowner($id);

        if (($itemowner != $main::userid) && ($main::userid != $ADMIN_USERID)) {
		print "Content-type: text/html\n\n";
		print "Sorry, you are $main::userid , not the owner of this item ($id owned by $itemowner)  or $ADMIN_USERID - you cannot edit items here\n";
		exit(0);
        }
        my %quals = ();
        my $qualifier = &AbUtils::find_types($main::inref, \%quals);
        &main::update_tables($id, \%quals);

	my $ItemFieldsRef = &getItemFields;

# update any relevent fields except ID
        my $q = '';
        foreach my $key (keys %{$main::inref}) {
                $fieldname = uc($key);
                my $value = $main::inref->{$key};

                # Special field handling; set defaults
                if (($fieldname eq 'EFFECTIVE_DATE') && ! $value) {
#                       $value = 'today';
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

        $q = "update rcatdb_items set ".$q." where ID = $id";   # don't leave dangerous global update query in $q

        my $sth = $dbh->prepare($q);
        $sth->execute;

        return;

}


##############################################################
sub add_item {

local *obj = *main::obj;
local *dbh = *main::dbh;

	my %param = (
		itemowner => $main::userid,
		security_level => undef,	
		@_
	);
	foreach my $var (
		'itemowner',
		'cid',
		'itemname',
		'handle',
		'security_level',
		'iref') {

		$$var = $param{$var};
	}

 	my $catowner = &AbUtils::get_catowner($cid);
	($cat_security_level) = $dbh->selectrow_array("select security_level from rcatdb_categories where id = $cid");
	if (! defined($security_level)) {
		$security_level = $cat_security_level;
		if (! defined($security_level)) {
			$security_level=$DEFAULT_SECURITY_LEVEL; 
		}
	}	
        if (($cat_security_level > 0) && ($catowner != $main::userid)) {
		print "Content-type: text/html\n\n";
		print "Sorry, you are $main::userid , not the owner $catowner of this category - you cannot add items here\n";
		exit(0);
        }

	my %quals = ();
	if ($main::inref && ! $qualifier) {
		$qualifier = &find_types($main::inref, \%quals);
	}
	# Item VALUE
	($linkid, $linktype) = (0,'');
	# preprocess value/URL of type abra://
	if (($linkid, $linktype) = resolve_aburl($itemval)) {
		if ($linktype eq $ITEMTYPE) {
			$itemval = &make_link(0,$linktype);
		} else {
			$itemval = &make_link($linktype);
		}
	}

	# Handle for this item

	my $newid = $obj->add('type'=>'ITEM', 'category'=>$cid, 'name'=>$itemname, 'value'=>$itemval, columns=>{'QUALIFIER'=>$qualifier});

	 # Make sure security_level is an integer
	 $security_level += 0;
	 
	# now apply our values
	my $q = "update rcatdb_items set ";
	my $something_to_set = 0;
	if ($itemowner) {
		$q .= " owner = $itemowner, ";
		$something_to_set = 1;
	} 
	# its possible to have a security_level with no owner
	# anonymous, publicly accessible items are security_level=0
	if (defined($security_level)) {
		$q .= "security_level = $security_level, ";
		$something_to_set = 1;
	}
	my $qvals = '';
	foreach $field ('URL','SHORT_CONTENT','EFFECTIVE_DATE') { # TODO: pull out this list

#print "checking, value for $field is ",$main::inref->{$field},"\n<br>";
#print "Keys are ",keys(%{$main::inref}),"\n<br>";
		if (defined($val = $main::inref->{$field})) {
			$qvals .= "$field = ".$dbh->quote($val).',';
		}
	}	
	if ($qvals) {
		$q .= $qvals;
		$something_to_set = 1;
	}

	if ($something_to_set) {
		$q =~ s/\,\s*$//;
		$q .= " where id = $newid";
#print "Setting vals: $q<br>\n";
		$dbh->do($q);
	}



	if ($handle) {
		&add_handle($newid, $handle, $ITEMTYPE); #TODO: userid
	} 
	
	# VALUE/URL for this item - may be link to existing item
	if ($linkid) {
		&add_relation($newid, $ITEMTYPE, $linkid, $linktype, 'HOME');
	}
	# Add long content if we have it
	if ($main::inref->{'text'} && $newid) {

		my $content = $main::inref->{'text'};
		my $q = "insert into content set ID=$newid, content=".$dbh->quote($content);
		my $sth = $dbh->prepare($q);
		$sth->execute;

		if (! defined ($main::inref->{'URL'}) ) {
			$q = "update rcatdb_items set value='$DISPLAY_URL?table=content&id=$newid' where ID=$newid";
			 $sth = $dbh->prepare($q);
                	 $sth->execute;
		}

		$q = 'update rcatdb_items set qualifier = CONCAT(qualifier," TYPE:content")'." where ID=$newid";
		$sth = $dbh->prepare($q);
                $sth->execute;
	}

	if (! $newid ) {
		print "Error: ", $obj->error,"<p>\n";
	} 

	 # Set ITEMCODE to catcode (needed for quick finding all items in subcat of cat)
        $q = "update rcatdb_items,rcatdb_categories set itemcode = catcode where rcatdb_items.id = $newid and rcatdb_categories.id = $cid";
        $sth = $dbh->prepare($q);
        $sth->execute;


        if (! $main::inref->{'EFFECTIVE_DATE'}) {
               # Set effective_date (later should have way to let user set this) TODO
                $q = "update rcatdb_items set effective_date = ENTERED where id = $newid";
                $sth = $dbh->prepare($q);
                $sth->execute;
        }
 
	if ($debug && $newid) {
		print "Added new item: $newid<br>\n";
	}

	&add_to_tables($newid, \%quals);
	return $newid;
}

################################################################
#  Find types from web input where key = "TYPE:xxx", value=value
#
sub find_types {
	my $iref = shift;
	my $tref = shift;

	my $qualifier = '';
	foreach $key (keys %$iref) {
		if ($key =~ /^TYPE:([a-zA-Z0-9_-]+):([a-zA-Z0-9_-]+)$/i) {

			if ($iref->{$key}) {   # don't add blank items

				$tref->{$1}->{$2} = $iref->{$key};
			}
		}
	}


	return &make_type_string($tref);
}

################################################################
#  Make TYPES:xxx,yyy,zzz type string from hash of hashes
#  where keys of parent hash are type (table) names
#
sub make_type_string {
	my $href = shift;
	
	my $qualifier = join(',',(keys %$href)) || '';
	$qualifier && ($qualifier = 'TYPE:'.$qualifier);
	
	return $qualifier;
}
	
# return array of types
sub parse_type_string {
	my $s = shift;

	my @tarr = ();
	if ($s =~ /TYPES?:([^\s]+)/) {
		@tarr = split(/\,/,$1);	
	}
	return @tarr;
}	

##################################################################
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

##################################################################
sub split_qualifier {
        my $qual = shift;
        my $aref = shift;

        while ($qual =~ /TYPE:([^\s,]+)/g) {
                push @$aref,$1;
        }
}

##############################################################
sub add_handle {
	my $id = shift || return;
	my $handle = shift || '';
	my $type = shift || 'I';

local *obj = *main::obj;
local *dbh = *main::dbh;

	$sqlst = "INSERT into handles SET id=$id, handle=".$dbh->quote($handle).",type=".$dbh->quote($type);
	my $sth = $dbh->prepare($sqlst);
	$sth->execute;
}

##############################################################
sub add_to_tables {
	my $id = shift;
	my $tref = shift;
	my $sqlst;

local *obj = *main::obj;
local *dbh = *main::dbh;

# TODO be robust against undefined fields
	foreach $tname (keys %$tref) {
		# get field list for this table
		# TODO find the 'right' way to do this instead of this hokey thing
		my $q = "select * from $tname where 1=0";
		my $sth = $dbh->prepare($q);
		$sth->execute;
		my $anameref = $sth->{NAME};
		my $oknames = join(' ',@$anameref);
		$sqlst = "INSERT into $tname SET id=$id";
		my $rref = $tref->{$tname};
		foreach $key (keys %$rref) {
			if (defined($rref->{$key}) && ($oknames =~ /\b$key\b/)) {
				$sqlst .= ", $key=".$dbh->quote($rref->{$key});
			}
		}
#print "Adding to tables : $sqlst\n<br>";
		$sth = $dbh->prepare($sqlst);
		$sth->execute;
	}
	return 1;
}

##############################################################
sub del_cat {
	my $cid = shift;

local *obj = *main::obj;
	return $obj->del('type'=>'CATEGORY','id'=>$cid);
}

##############################################################
sub del_item {
	my $id = shift;
local *obj = *main::obj;
local *dbh = *main::dbh;

       my $itemowner = &AbUtils::get_itemowner($id);

        if ($itemowner != $main::userid) {
                print "Sorry, you are $main::userid , not the owner of this item ($id owned by $itemowner) - you cannot delete items here\n";
                exit(0);
        }

	my $q = "delete from handles where type='$ITEMTYPE' and id=$id";
	my $sth = $dbh->prepare($q);
	$sth->execute;
	return $obj->del('type'=>'ITEM','id'=>$id);
}

#############################################################
# create a new user's area in the category tree
# any user with a valid user id can have a cat created if one does not exist
sub init_user_cat {
	my $userid = shift;

local *dbh = *main::dbh;

	# login is at least guaranteed non blank
	my $q = "select real_name, public_handle, login from users, ab_users_cats where users.id = $userid and ab_users_cats.user_id = $userid";
	my ($real_name, $public_handle, $login) = $dbh->selectrow_array($q);	

	my $catname = 	$public_handle ? $public_handle :
			$real_name     ? $real_name :
			$login 	       ? $login : 
					  '' 
			|| return;
	

	my $newcatid = add_subcat('cid' => $USERDEFINED_CAT, 'newcatname' => $catname, 'owner' => $userid);

	$q = "update ab_users_cats set cathome = $newcatid where $user_id = $userid";
	$dbh->do($q);

	return $newcatid;
}



##############################################################
sub getcatfromitem {
	my $item = shift;
	@res = $obj->find('search'=>$item,'by'=>'ID', 'route'=>'YES');
	return $res[0]->{'CID'};
}

##############################################################
#  get user's home category
#  create one if not defined!  calls init_user_cat()
sub getcatfromuser {
	my $user = shift;


local *dbh = *main::dbh;
	my $q = "select catlast,cathome,users.id from ab_users_cats, users  where users.login = ".$dbh->quote($user)." and ab_users_cats.user_id = users.id";
        my $sth = $dbh->prepare($q);
	my $cid = 0;
	my $cid2 = 0;
	my $userid = 0;
        if ($sth) {
		$sth->execute();
        	($cid,$cid2,$userid) = $sth->fetchrow_array;
		$cid = $cid || $cid2;
	}

	if (! $cid ) {
		
		if (! $userid ) {
			# try just looking the userid from the users table only
			$q = "select id from users where login = '$user'";
			($userid) = $dbh->selectrow_array($q);
			return unless $userid;

			# TODO - create item for this user under Users as well?

			# create ab_users_cats entry for this user
			$q = "insert into ab_users_cats values (0,$userid,0,0,'')";
			$dbh->do($q);
		}

		$cid = init_user_cat($userid);
	}

	return($cid);	
}

##############################################################
sub getcatfromuserid {
	my $userid = shift;

local *dbh = *main::dbh;

	#my $q = "select catlast,cathome from ab_users_cats where id = $userid";
	my $q = "select catlast,cathome from user where id = $userid";
        my $sth = $dbh->prepare($q);
	my $cid = 0;
	my $cid2 = 0;
        if ($sth) {
		$sth->execute();
        	($cid,$cid2) = $sth->fetchrow_array;
		$cid = $cid || $cid2;
	}

	if (! $cid && $userid) {
		$cid = init_user_cat($userid);
	}

	return($cid);	
}
##############################################################
sub getnamefromid {
	my $item = shift;

local *obj = *main::obj;
	@res = $obj->find('search'=>$item,'by'=>'ID','route'=>'NO');
	return $res[0]->{'NAME'};
}

##############################################################
sub get_cat_from_item {
	my $id = shift;

local *dbh = *main::dbh;

	my ($cid) = $dbh->selectrow_array("select CID from $ITEM_TABLE where ID = $id");

	return $cid;	

}


##############################################################
# Get items or categories related to id 
sub get_cats_by_relation {
	my ($targetid, $relation, $ref) = @_;

local *dbh = *main::dbh;
	my $q1 = "select ID,QUALIFIER from $RCAT_TABLE where RELATION = '$relation' and ITEM_DEST = $targetid";

	&get_query_results($ref, $q1);

	my $q2 = '';
	my $inv = &inverse_relation($relation);
	if ($inv) {
		$q2 = "select CAT_DEST,QUALIFIER from $RITEM_TABLE where RELATION = '$inverse' and ID = $targetid";
		my $sth = $dbh->prepare($q);
		if ($sth && $sth->execute()) {
			while (my ($cat_dest, $qual) = $sth->fetchrow_array) {
				push @$ref, {'ID'=>$cat_dest, 'QUALIFIER'=>$qual};
			}
			$sth->finish();
		}

		# we do it manually to match CAT_DEST to ID for the inverse
		#&get_query_results($ref, $q2);
	}
}


##############################################################
sub inverse_relation {
	my $relation = shift;

	my $inv = $RELATIONS{$relation}->{'REVERSE'} || '';

	return $inv;
}

##############################################################
sub get_relations {
	my ($id, $type, $filter, $ref) = @_;

#	@$ref = $obj->r_list($type=>$id,'filter'=>$filter);
	my $q = '';

	if ($type eq 'item') {
		$q = "select * from $RITEM_TABLE where (ID = $id) or (ITEM_DEST = $id)";
		# leaves out categories related to items
	} elsif ($type eq 'cat') {
		$q =  "select * from $RCAT_TABLE where (ID = $id) or (CAT_DEST = $id)";
		# leaves out items related to categories
	} else {
		return $ref;
	}
	&AbUtils::get_query_results($ref, $q);
	my $related_cat;
	my @types = ();
	foreach my $href (@$ref) {
		$related_cat = 0;
		$related_item = 0;
               if ($id == $href->{'ID'}) { # usual
                       $related_cat = $href->{'CAT_DEST'};
		       $related_item = $href->{'ITEM_DEST'};
                       $relation = $href->{'RELATION'};
               } elsif ($id == $href->{'CAT_DEST'}) {
                       $related_cat = $href->{'ID'};
#TODO chck if thing is actually item or cat
                       $relation = &AbUtils::inverse_relation($href->{'RELATION'});
               } elsif ($id == $href->{'ITEM_DEST'}) {
			$related_item = $href->{'ID'};
			$relation = &AbUtils::inverse_relation($href->{'RELATION'});
		}
		

               if ($related_cat) {
                       $catref = &get_cat($related_cat);
               }

               if ($href->{'RELATION'} eq $HAS_SUBCAT) {
			undef $href;
		}
#print %$href;
		if ($related_item && $related_cat) {
			$href->{'LINK'} = &make_link($related_cat,$related_item);
			$href->{'NAME'} = &make_catpath($catref);
		} elsif ($related_item) {
			my $item_cid = &get_cat_from_item($related_item);
			$href->{'LINK'} = &make_link($item_cid,$related_item);
			$href->{'NAME'} = &getnamefromid($related_item);
                } elsif ($related_cat) {
                        $href->{'LINK'} = &make_link($related_cat);
                        $href->{'NAME'} = &make_catpath($catref);
		} elsif ($IS_URL == &AbUtils::string_is($href->{'QUALIFIER'})) {
			$href->{'LINK'} = $href->{'QUALIFIER'};
		} elsif (&AbUtils::has_table_entries($href->{'UID'},$href->{'QUALIFIER'},\@types)) {

#print "<br>MAking Table Link<br>\n";

			$href->{'LINK'} = &AbUtils::make_related_link($href->{'CID'},$href->{'UID'},\@types);
		}

#print "<p> so link is ",$href->{'LINK'};

		if ($href->{'NAME'} eq '') {
			$href->{'NAME'} = $href->{'QUALIFIER'} || $href->{'RELATION'};
		}
	}
	return $ref;
}

#############################################################
# Get table names from qualifier string
sub has_table_entries {
	my $id = shift; 	# for index
	my $qualstring = shift;
	my $aref = shift;

	@$aref = parse_type_string($qualstring);

	if ($#$aref >=0) {
		return 1;
	} else {
		return 0;
	}

#TODO decide the best way to insert generic database table data with overridable user views
}


##############################################################
# make link to related data in specific table fields 
sub make_related_link {
	my $cid = shift || 0;	# for back link
	my $uid = shift || 0;   
	my $aref = shift;	  # need array of table names & indices 
	my $type = $aref->[0] || return('');	
# TODO: get FIELDS
	my $link = "$DISPLAY_URL?UID=$uid&TABLE=$type&FIELDS=text";
	return $link;
}

############################################################################
# assumes static pages pregenerated of form http://domain.com/subcat/subcat/...
sub make_nice_link {
	my $catref = shift;
	my $root_site = shift;
	my $show_from_level = shift || 0;

	my $retstring = "http:\/\/$root_site\/";
	$show_from_level-- if ($show_from_level); # the root domain is a level

	if (! defined($catref->{'route'})) {
		$catref->{'route'} = make_route_from_cid($catref->{'ID'});
	}
	my $path = $catref->{'route'};
	my $j;

        for ($j = $#$path - $show_from_level; $j>=0; $j--)
        {
	   $p = $$path[$j];
	   $retstring .= $p->{'NAME'}.'/';
        }

	return $retstring;

}

##############################################################
sub make_link {
	my $cid = shift;
	my $id = shift || 0;
	my %extra = @_;

	return unless defined($cid);

	my $userpref = $main::userpref;	# ugly - should make this into obj

	my $link = $USE_THIS_CGI.'?_USERPREF='.$userpref.'&_CATID='.$cid;

	if ($id) {
		$link .= '&_ITEMID='.$id;
	}

	for my $key (keys %extra) {
		$link .= "&".$key."=".$extra{$key};
	}

	return $link;
}

##################################################################
sub make_href_link {
	return "<A HREF=\"".&make_link(@_)."\">";
}

##############################################################
# returns all subcategories of given category as array of hashes
sub get_subcats {
	my $curcat = shift;
	my $subcatref = shift;
	my $userid = shift || 0;
	my $get_related = shift || 'Y';

	# Get our default access level for parent category
	# TODO: find a quick way to display subcats with special access for this user
	my $catowner = &get_catowner($curcat);
$main::DEBUG && print "Category owner is $catowner , we are $userid...";
        my $our_access_level = &get_access_level($userid, $catowner, $curcat) || 0;

	if ($userid == $main::ADMINUSER) {
		$our_access_level = $OWNER_ACCESS_LEVEL;
	}

# return array of hashes w/ID,NAME,VALUE,QUALIFIER 	
	&get_query_results($subcatref, "select * from $CAT_TABLE where CID = $curcat AND ($our_access_level >=security_level OR security_level is NULL) ORDER BY name");
# add entries for deleting each cat; fix catcode
	for $p (@$subcatref) {
		my $id =$p->{'ID'};
		$p->{'DEL_CAT'} = &make_href_link($curcat,0,_DELCAT=>$id)."X</A>";
		$p->{'SUBCATCODE'} = &catcodestr($p->{'CATCODE'});

		$p->{'route'} = &make_route_from_cid($p->{'ID'});
	}

	if ($get_related eq 'Y') {

		#TODO move this more into template, or at least read TemplateBits file
# now add related cats
#		my @relcats = $obj->r_find('search'=>$curcat,'by'=>'ID', 'filter'=>'CATEGORIES','additional'=>"RELATION='$HAS_SUBCAT'", 'multiple');
#		push @relcats, $obj->r_find('search'=>$curcat,'by'=>'CAT_DEST','filter'=>'CATEGORIES','additional'=>"RELATION='$IS_SUBCAT_OF'",'multiple');

		my @relcats = ();
		my $q = "select $CAT_TABLE.* from $CAT_TABLE, $RCAT_TABLE where $RCAT_TABLE.ID = $curcat AND $CAT_TABLE.ID = $RCAT_TABLE.CAT_DEST AND $RCAT_TABLE.RELATION = '$HAS_SUBCAT'";

		&get_query_results(\@relcats, $q);
		$q = "select $CAT_TABLE.* from $CAT_TABLE, $RCAT_TABLE where $RCAT_TABLE.CAT_DEST = $curcat AND $CAT_TABLE.ID = $RCAT_TABLE.ID AND $RCAT_TABLE.RELATION = '$IS_SUBCAT_OF'";

		&get_query_results(\@relcats, $q);

		for $p (@relcats) {
			$p->{NAME} = '@'.$p->{NAME};
			$p->{'SUBCATCODE'} = &catcodestr($p->{'CATCODE'});
			$p->{'route'} = &make_route_from_cid($p->{'ID'});
		}
		push @$subcatref, @relcats;
	}

	return $subcatref;
}

#########################################################################################
sub make_rel_links {
	my $id = shift;

	my @related = ();
        &get_relations($id, 'item', 'ALL', \@related);

	my $linkstring = '';
	foreach my $rel (@related) {

	# TODO: lookup nicename from %RELATIONS (change to hash of hashes first)
                 $linkstring .= "<A HREF='".$rel->{'LINK'}."'>".$rel->{'RELATION'}.":".$rel->{'NAME'}."</A> ";

	}
	return $linkstring;
}


# Pasted Julian's code from find() in RCategories.pm so we can just make the route as needed
sub make_route_from_cid {
	my $CID = shift;

local *obj = *main::obj;
local *dbh = *main::dbh;

	my @route_array = ();
	while ($CID != 0) {
           my $q = "SELECT * FROM $CAT_TABLE WHERE ID=$CID";
           my $sth = $dbh->prepare($q);
           my $ref;
           if($sth) {
             	if($sth->execute()) {
               		$ref = $sth->fetchrow_hashref('NAME_uc');
               		if(ref($ref)) {
                 		$CID = $ref->{'CID'};
                 		push(@route_array,$ref);
                	} else {
                 		$CID = 0;
                	}
               		$sth->finish();
              	} else {
               		return(undef);
              	}
           } else {
             	return(undef);
           }
       }
       return \@route_array;
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

local *obj = *main::obj;
local *dbh = *main::dbh;

	@res = $obj->find('search'=>$catid,'sort'=>'ID','by'=>'ID','filter'=>'CATEGORIES','multiple'=>'YES',
                     'route'=>'YES','partial'=>'NO','reverse'=>'NO','rules'=>$rules);
	return $res[0];
}

# assumes static pages pregenerated of form http://domain.com/subcat/subcat/...
sub make_nice_catpath {
	my $catref = shift;
	my $root_site = shift;
	my $show_from_level = shift || 0;


	my $retstring = "\\";

	$site_link = "http:\/\/$root_site\/";
	if ($show_from_level == 0) {
		$retstring .= "<A HREF='$site_link'>$root_site</A>\\";
	} elsif($show_from_level > 0) {
		$show_from_level--;
	}

	if (! defined($catref->{'route'})) {
		$catref->{'route'} = make_route_from_cid($catref->{'ID'});
	}

	my $path = $catref->{'route'};
	my $j;

        for ($j = $#$path - $show_from_level; $j>=0; $j--)
        {
	   $p = $$path[$j];
	   $site_link .= $p->{'NAME'}.'/';
	   $site_link =~ s/\&/\%26/g;
	   $site_link =~ s/\?/\%3f/g;
           $retstring .= "<A HREF='$site_link'>".$p->{'NAME'}."</A>\\";
        }

	$site_link .= $catref->{'NAME'}.'/';
	$site_link =~ s/\&/\%26/g;
        $site_link =~ s/\?/\%3f/g;

        $retstring .= "<A HREF='$site_link'>".$catref->{'NAME'}."</A>\\";

	return $retstring;

}


sub make_catpath {

	my $catref = shift;
	my $show_from_level = shift || 0;

	my $retstring = "\\";

	if ($show_from_level == 0) {
		$retstring .= &make_href_link(0)."root</A>\\";
	} elsif($show_from_level > 0) {
		$show_from_level--;
	}

	if (! defined($catref->{'route'})) {
		$catref->{'route'} = make_route_from_cid($catref->{'ID'});
	}
	my $path = $catref->{'route'};
	my $j;

        for ($j = $#$path - $show_from_level; $j>=0; $j--)
        {
	   $p = $$path[$j];
           $retstring .= &make_href_link($p->{'ID'}).$p->{'NAME'}."</A>\\";
        }
	$retstring .= &make_href_link($catref->{'ID'}).$catref->{'NAME'}."</A>\\";

	return $retstring;
}

sub make_hotlinked_relcatpath {        
	my $catid = shift;              # Todo use more transparent call syntax
        my $parentid = shift;           # and be consistent with make_catpath above
        my $keepparent = shift || 0;

        my $cref = &get_cat($catid);
        my $path = $cref->{'route'};
        my $j;
        my $retstring = '';
        my $lastid = 0;

        for ($j = $#$path; $j>=0; $j--)
        {
           my $p = $$path[$j];
           if ($retstring || ($lastid == $parentid)) {
                   $retstring .= &make_href_link($p->{'ID'}).$p->{'NAME'}."<\A>\\";
           } else {
                $lastid = $p->{'ID'};
                if ($keepparent && ($lastid == $parentid)) {
                        $retstring .= &make_href_link($p->{'ID'}).$p->{'NAME'}."</A>\\";
                }
           }
        }
        $retstring .= &make_href_link($cref->{'ID'}).$cref->{'NAME'}."</A>\\";
        return $retstring;
}


sub make_relcatpath {
        my $catid = shift;		# Todo use more transparent call syntax
        my $parentid = shift;		# and be consistent with make_catpath above
        my $keepparent = shift || 0;
        my $cref = &get_cat($catid);
        my $path = $cref->{'route'};
        my $j;
        my $retstring = '';
        my $lastid = 0;
        for ($j = $#$path; $j>=0; $j--)
        {
           my $p = $$path[$j];
           if ($retstring || ($lastid == $parentid)) {
                   $retstring .= $p->{'NAME'}."\\";
           } else {
                $lastid = $p->{'ID'};
                if ($keepparent && ($lastid == $parentid)) {
                        $retstring .= $p->{'NAME'}."\\";
                }
           }
        }
        $retstring .= $cref->{'NAME'}."\\";
        return $retstring;
}


##############################################################
# returns all subcategories recursively of given category as array of hashes
#
# Having problems keeping all vars - use global
#
@cattree = ();

sub get_subcat_tree {
	my $curcat = shift || return;
	my $parentcat = shift || $curcat;
	my $keepparent = shift || 0;

local *obj = *main::obj;
local *dbh = *main::dbh;

# return array of hashes w/ID,NAME,VALUE,QUALIFIER	
	my @subcats = $obj->find('search'=>$curcat,'by'=>'CID','sort'=>'NAME','filter'=>'CATEGORIES','multiple');
# add entries for deleting each cat
	for $p (@subcats) {
		my $id =$p->{'ID'};
		$p->{DEL_CAT} = &AbUtils::make_href_link($curcat,0,_DELCAT=>$id)."X</A>";
		$p->{SUBCATPATH} = &make_relcatpath($id, $parentcat, $keepparent);
	}
	#TODO move this more into template, or at least read TemplateBits file
# now add related cats
#	my @relcats = $obj->r_find('search'=>$curcat,'by'=>'ID', 'filter'=>'CATEGORIES','additional'=>"RELATION='$HAS_SUBCAT'", 'multiple');
#	push @relcats, $obj->r_find('search'=>$curcat,'by'=>'CAT_DEST','filter'=>'CATEGORIES','additional'=>"RELATION='$IS_SUBCAT_OF'",'multiple');

	my @relcats = ();
	my $q = "select $CAT_TABLE.* from $CAT_TABLE, $RCAT_TABLE where $RCAT_TABLE.ID = $curcat AND $CAT_TABLE.ID = $RCAT_TABLE.CAT_DEST AND $RCAT_TABLE.RELATION = '$HAS_SUBCAT'";
	&AbUtils::get_query_results(\@relcats, $q);

	for $p (@relcats) {
                my $id =$p->{'ID'};
		$p->{NAME} = '@'.$p->{NAME};
		$p->{SUBCATPATH} = &make_relcatpath($id, $id, 1);
	}
	
# Recurse for tree
	foreach $p (@subcats) {
		&get_subcat_tree($p->{'ID'}, $parentcat);
#print "Subcatpath for ",$p->{'ID'}, " is ", $p->{SUBCATPATH},",br>\n";
	}
	foreach $p (@relcats) {
		&get_subcat_tree($p->{'ID'}, $p->{'ID'}, 1);
	}
	push @cattree, @subcats;
	push @cattree, @relcats;	

	return \@cattree;
}



##################
## only need to call once on imported category trees
@tcattree = ();
%subcathash = ();
$subcatref = \%subcathash;
sub get_subcat_tree_making_catcodes {
	my $curcat = shift || 0;
# return array of hashes w/ID,NAME,VALUE,QUALIFIER	
#

local *obj = *main::obj;
local *dbh = *main::dbh;

	$subcatref->{$curcat} = [];
	@{$subcatref->{$curcat}} = $obj->find('search'=>$curcat,'by'=>'CID','sort'=>'NAME','filter'=>'CATEGORIES','multiple');

#	print "There are ",$#{$subcatref->{$curcat}}, " subcategories of $curcat\n<br>";

# Recurse for tree
	foreach $p (@{$subcatref->{$curcat}}) {
		# avoid loops
#		print "Checking on ",$p->{'ID'},"...";
		if (exists($subcatref->{$p->{'ID'}})) {
			next;
		}
#		print "is new, doing it\n<br>";

		if (! $p->{'catcode'} ) {
			my $newcode = &AbUtils::GenSubCatCode($p->{'CID'});
			my $nq = "update $CAT_TABLE set catcode = ".$dbh->quote($newcode)." where id = ".$p->{'ID'};
			$dbh->do($nq);
#print "Just executed $nq <br>\n";

		}
		if ($p->{'ID'}) {
			&get_subcat_tree_making_catcodes($p->{'ID'}, $p->{'CID'});
#print "Subcatpath for ",$p->{'ID'}, " is ", $p->{SUBCATPATH},",br>\n";	
		}
	}
	push @tcattree, @{$subcatref->{$curcat}};
if ($#tcattree > 20000) { exit("Too many categories"); }
	return \@tcattree;
}

#####################################################
# check TYPES column and put values into hash for output
# only get the ones we need for this particular string
sub prepare_template_hash_types {


local *obj = *main::obj;
local *dbh = *main::dbh;

	my $curitem = shift;
	my $href = shift;    # \%templatehash
	my $tstringref = shift;  # template string containing TYPE:

local *dbh;

	# TODO -bad - don't hardcode [| chars
	while($$tstringref =~ /\[\|TYPE:([^\:\s]+):([^\:\s]+)\s*\|\]/g) {
#warn "Examining $_ $1 $2 $3 \n";
		my $table = $1;
		my $field = $2;
		my $q = "select $field from $table where id = $curitem";
#warn "executing $q\n";
		my ($val) = $dbh->selectrow_array($q);
		if (defined($val)) {
			$href->{"TYPE:$table:$field"} = $val;
#warn "Set TYPE:$table:$field to $val\n";
		}
	}
#warn "now hash is ",%$href;
	return;

}

#############################################################
sub lookupTemplatebyCatcode {
	my $cid = shift || 0;
        my $catcode = shift || '';
        my $pagetype= shift || '';

local *obj = *main::obj;
local *dbh = *main::dbh;


        if (!$catcode) {
                return '';
        }

#	my $lvl = &GetLevelfromCatcode($catcode);

#print "$catcode is level $lvl";	



       # if ($userid) {
       #         $where .= "viewprefs.userid = $userid";
       # }

# this should work but didn't
#        my $q = "select views.template_file from views, viewprefs 
#		where views.uid = viewprefs.viewid 
#		and (LEFT(viewprefs.catcode,$lvl) = LEFT($catcode,$lvl)))";
	my $q = "select views.template_file from views, viewprefs, rcatdb_categories
		where views.uid = viewprefs.viewid
		and rcatdb_categories.cid = $cid
		and LEFT(viewprefs.catcode, viewprefs.level) = LEFT(rcatdb_categories.catcode,viewprefs.level)";

        if ($pagetype) {
                $pagetype = lc($pagetype);
                $q .= " and pagetype = '$pagetype'";
        }
        my $sth = $dbh->prepare($q);

#print "<br>Query is $q<br>";
        my $tfile = '';
        if ($sth) {
                $sth->execute();
                $tfile = $sth->fetchrow_array;
        }
#print "result was $tfile";
        # TODO: deal with case where multiple matches are found - pick best
        return $tfile;
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


# Get item as hash
sub get_item_byid {
	my $id = shift;
local *obj = *main::obj;
local *dbh = *main::dbh;
	my $q = "select * from $ITEM_TABLE where ID = $id";
	my $sth = $dbh->prepare($q);
	if ($sth && $sth->execute()) {
		my $ref = $sth->fetchrow_hashref('NAME_uc');
		$sth->finish();
		return $ref;
	}
	return 0;
}


####################################################################################
# get query results as an array of hashes, and put in the passed ref to an array
sub get_query_results {
	my ($href, $q) = @_;

local *obj = *main::obj;
local *dbh = *main::dbh;

#print "Query is $q\n";

	my $sth = $dbh->prepare($q);
	if ($sth && $sth->execute()) {
		while (my $ref = $sth->fetchrow_hashref('NAME_uc')) {
			push @$href, $ref;
		}
		$sth->finish();
	}
}




#################################################
# could check for existence of HTML::Defaultify
sub html_quotes {
	my $str = shift;

	$str =~ s/(['"])/\&quot;/g;
	return $str;
}
sub escape_quotes {
	my $href = shift;

	foreach my $key (keys %$href) {
		$href->{$key} =~ s/(['"])/\\$1/g;
	}
}

sub escape_quotes_str {
	my $str = shift;

	$str  =~ s/(['"])/\\$1/g;
	return $str;
}

sub catcodestr {
	my $code = shift;
	my @catcode = unpack "C16",$code;
	return join(':',@catcode);
}

sub dbcatcode {
	my $id =shift;
	my $q = "select * from $CAT_TABLE where id = $id";
	my $r = $dbh->selectrow_hashref($q);
	my $s = &catcodestr($r->{'catcode'});
	return($s);
}



