#!/usr/local/bin/perl
# Path to RCategories

# abmake.pl

# produce html pages or snippets from templates
# defaults to converting *.tmpl -> *.html in the current working directory
# will add optional params for FROM and TO directories
# generally run in an /includes directory to produce files for inclusion by PHP

# should: 
# accepts param -c[id] for category id to apply, 
# or find file named .catid or .catname in current dir
# otherwise parses from each template file as
#  [|CATID:nnn|]
# or [|CATNAME:xxx|] 

$SHOW_FROM_LEVEL = 2;  # we are showing only under /root/UserDefined

$DEFAULT_FILE_NAME = 'abra.html';   # could be index.html, but then we don't overwrite ourselves...

$ALTERNATE_FILE_NAME = 'abra.html';

$DEFAULT_TEMPLATE_FILE = 'default.tmpl';

$MAX_DEPTH = 5;	# for recursion
#$MAX_DEPTH = 2;	# for recursion

$_depth = 0;

use File::Find;
use Carp;
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC,"/w/abra/cgi");
}

use AbHeader qw(:all);
use AbUtils;
use AbSecure;
use AbMacros;
use RCategories;
use Mysql;
use CommandWeb;


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


# HACK for testing
$rootdom = 'btucson.com';

$SHOWDELMASK = 1;
my %templatehash = ();


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

$curdir = `pwd`;
chomp $curdir;
$curcat = 0;
$rootcat = 0;
$target_dir = '';
$template_file = '';

# check dir for .catid or .catname, set defaultcat
if ( -e "PARENT_CAT_ID" ) {
	open F,"PARENT_CAT_ID";
	$rootcat = <F>;
	close F;
}
chomp $rootcat;

if ( -e "TARGET_DIR" ) {
	open F,"TARGET_DIR";
	$target_dir = <F>;
	close F;
}
chomp $target_dir;

if ( -e $DEFAULT_TEMPLATE_FILE ) {
	$template_file = $curdir .'/'.$DEFAULT_TEMPLATE_FILE;
} else {
	croak "No template file";
}
&process_cat($rootcat, $template_file, $target_dir);

1;

sub process_cat {
	my $curcat = shift;
	my $template_file = shift;
	my $target_dir = shift;

	my $userid = 0; 	# only write public stuff

	# build the index file for this cat, if not already there
	# need a way to check if the existing one is one we made, then we could overwrite

print "Processing cat id # $curcat , outputting to dir $target_dir...\n";

	if (! -e $target_dir) {
		mkdir($target_dir,0755);
	}
	my $target_file = "$target_dir/$DEFAULT_FILE_NAME";
	if ( -e "$target_file") {
		$target_file = "$target_dir/$ALTERNATE_FILE_NAME";
	}
	&process_template_file($curcat, $template_file, $target_file);

	my @subcats = ();
	&AbUtils::get_subcats($curcat, \@subcats, $userid,'N');

#print "Got ",$#subcats, " subcategories to process ...\n";
	# recursion will get expensive on big cattrees - use only so deep
	$_depth++;

	if ($_depth >= $MAX_DEPTH) {
#print "Not going deeper, we are already $_depth levels deep\n";
		$_depth--;
		return;
	}
	foreach my $catref (@subcats) {
#print "Working on ",$catref->{'ID'}," : ",$catref->{'NAME'}," \n";
		next if ($catref->{'NAME'} =~ /^\@/);
		my $subtarget_dir = $target_dir.'/'.$catref->{'NAME'};	
		&process_cat($catref->{'ID'}, $template_file, $subtarget_dir);
	}
		
	$_depth--;
	return;
}

sub process_template_file {

	my $curcat = shift;
	my $template_file = shift;
	my $target_file = shift;


#print "In process_tempalte_file trying to output from $template_file to $target_file using cat $curcat\n";
	
	# initialize templatehash
	my %templatehash = ();

	my $catcode  = &AbUtils::get_catcode($curcat);
        my $carr = &AbUtils::ArrayFromCatCode($catcode);
        my $lvl = &AbUtils::GetLevel($carr)+1;


	my $catref = &AbUtils::get_cat($curcat);
	my $catpath = &AbUtils::make_nice_catpath($catref,$rootdom,$SHOW_FROM_LEVEL);

	# refresh templatehash

	$catowner = &AbUtils::get_catowner($curcat);

	my @subcats = ();

	&AbUtils::get_subcats($curcat, \@subcats, $userid);
	&fmt_array_for_table(\@subcats, 4);	# 4-column table

	my @catitems = ();

	&get_all_catitems($curcat, $lvl, \@catitems);
#print "We have ",$#catitems," catitems for $curcat\n";

	&fmt_array_for_table(\@catitems, 5);	# 5-column table

	my @catrelated = ();
	&AbUtils::get_relations($curcat, 'category', 'ALL', \@catrelated);
	&fmt_array_for_table(\@catrelated, 5);	# 5-column table

	my @itemrelated = ();
	if ($curitem) {
		&AbUtils::get_relations($curitem, 'item', 'ALL', \@itemrelated);
		&fmt_array_for_table(\@itemrelated, 5);	# 5-column table
		$iref = &AbUtils::get_item_byid($curitem);
	}
#print "We have ",$#subcats," SUBCATS for $curcat\n";	
	foreach my $subcatref (@subcats) {
		$subcatref->{'CATLINK'} = &AbUtils::make_nice_link($subcatref, $rootdom, $SHOW_FROM_LEVEL);
		print "for SUBCAT ",$subcatref->{'NAME'}," nice catpath is ",$subcatref->{'CATLINK'}, "\n";
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
#	$templatehash{'THISCGI'} = $THISCGI;
	$templatehash{'BLOGCGI'} = $BLOGCGI;
	$templatehash{'USERPREF'} = $userpref;
	$templatehash{'THISLINK'} = &make_link($curcat, $curitem);
	$templatehash{'NEXTPAGE'} = $nextpage;
	$templatehash{'SHOW_LOGIN'} = $User eq '' ? 1 : 0;
	$templatehash{'LOGINLINK'} = "<A HREF=\"".$LOGINURL."\">login</A>";
	$templatehash{'REGISTERLINK'} = "<A HREF=\"".$REGISTERURL."\">register</A>";
	$templatehash{'ACCOUNTLINK'} = "<A HREF=\"".$ACCOUNTURL."\">my account</A>";
	$templatehash{'ABTYPES'} = \@ABTYPES;

#	if ($curitem) {
#        	$templatehash{'ITEMNAME'} = $iref->{'NAME'};
#	        $templatehash{'ITEMVALUE'} = &AbUtils::html_quotes($iref->{'VALUE'});
#        	$templatehash{'ITEMDESC'} = &AbUtils::html_quotes($iref->{'DESCRIPTION'});
#		$templatehash{'ITEMCODE'} = &AbUtils::catcodestr($iref->{'ITEMCODE'});
#	}

	# we know that vars are
	#'type','ID','CID','NAME','VALUE','QUALIFIER','route'


	my $abm;
	$abm = new AbMacros(catid=>$curcat);

	# we iterate on $template_file

	my $tmpstring = $abm->ProcessFile($template_file);

	# now output to corresponding .html (warn on overwrite?)

	&CommandWeb::OutputToFileFromString($tmpstring,$target_file,\%templatehash) || &ErrorExit("CommandWeb::OutputToWeb failed writing to $target_file, last error was $?, hash was ",%templatehash);

} # end processtemplatefile


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
	return $obj->del('type'=>'CATEGORY','id'=>$cid);
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

	return $obj->del('type'=>'ITEM','id'=>$id);
}


##############################################################
sub getcatfromitem {
	my $item = shift;
	@res = $obj->find('search'=>$item,'by'=>'ID', 'route'=>'YES');
	return $res[0]->{'CID'};
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
sub getnamefromid {
	my $item = shift;
	@res = $obj->find('search'=>$item,'by'=>'ID','route'=>'NO');
	return $res[0]->{'NAME'};
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

#print "Owner is $catowner, we are $userid, Our access level is $our_access_level";

	my $q = "select * from $ITEM_TABLE where CID = $curcat and ($our_access_level >= security_level OR security_level is NULL) order by effective_date desc, ENTERED desc";
	&AbUtils::get_query_results($itemref, $q);

#print "executed $q";

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
# returns all items in subcats of cat
sub get_all_catitems {
	my $curcat = shift;
	my $lvl = shift;
	my $itemref = shift;

# return array of hashes w/ID,NAME,VALUE,QUALIFIER	
#	@$itemref = $obj->find('search'=>$curcat,'by'=>'CID','sort'=>'NAME','filter'=>'ITEMS','multiple');

#	my $q = "select * from $ITEM_TABLE where CID = $curcat order by ENTERED desc";

 	my $q = "select rcatdb_items.id, rcatdb_items.itemcode, rcatdb_items.cid, rcatdb_items.name, rcatdb_items.short_content, rcatdb_items.url, rcatdb_items.qualifier, rcatdb_items.effective_date, rcatdb_items.entered, users.login from rcatdb_items,rcatdb_categories,users where LEFT(itemcode,$lvl) = LEFT(catcode,$lvl) and rcatdb_categories.id = $curcat and users.id=rcatdb_items.owner order by rcatdb_items.effective_date desc, entered desc, itemcode asc limit 100";


	&AbUtils::get_query_results($itemref, $q);

# values->urls if match
	for my $p (@$itemref) {

		$p->{'LINK'} = $p->{'URL'};
		
		$p->{DEL_ITEM} = &AbUtils::make_href_link($curcat,0,_DELITEM=>$p->{'ID'})."X</A>";

#TODO: improve templating

		$p->{SHORT_CONTENT} = &CommandWeb::HTMLize($p->{'SHORT_CONTENT'});
	
		$p->{META_DESCRIPTION};
		$p->{RELATED_LINKS} = &AbUtils::make_rel_links($p->{'ID'});
		$p->{TABLE_LINKS} = &make_table_links($p->{'ID'},$p->{'QUALIFIER'});
		$p->{ITEMCAT} = my $itemcat = $p->{'CID'};
		my $itemcatref = &AbUtils::get_cat($itemcat);
		$p->{ITEMCATPATH} = &AbUtils::make_nice_catpath($itemcatref,$rootdom,$SHOW_FROM_LEVEL);
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


