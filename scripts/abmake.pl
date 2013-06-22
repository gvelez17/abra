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
#  [CATID=nnn]
# or [CATNAME=xxx] 

use File::Find;
use Carp;
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC,"/w/abra/cgi");
	unshift(@INC, "/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbSecure;
use AbMacros;
use RCategories;
use Mysql;
use CommandWeb;
use AbCat;


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
	$THISCGI = "http://abra.info/cgi/ab.pl";
	$ADMINUSER = 1;

#}
$debug = 1;

$rootdom = 'btucson.com';
$SHOW_FROM_LEVEL = 2;

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

# check dir for .catid or .catname, set defaultcat
if ( -e ".catid" ) {
	open F,".catid";
	($rootcat) = <F>;
	close F;
}
chomp $rootcat;

warn("About to call find, we are in directory $curdir\n");

find(\&process_template_file, ($curdir));

1;



sub process_template_file {

# $File::Find::dir is the current directory name, 
# $_ is the current filename within that directory 
# $File::Find::name is the complete pathname to the file. 

	# is this one of our template files?
	/(.*)\.tmpl$/ || return(0);

	# initialize templatehash
	my %templatehash = ();
	my $templatefile = $_;
	my $outputfile = $1.'.html';

	# check file for [CATID=] or [CATNAME=] on first line
	open F, $_ || carp("Can't open $_") && return(0);
	my $firstline = <F>;
	close F;

	my $curdir = $File::Find::dir;
	my $catidfile = $curdir.'/.catid';

print "Firstline is $firstline \n";

	if ($firstline =~ /\[\|?\s*CATID\s*:\s*(\d+)\s*\|?\]/) {
		$curcat = $1;
	} elsif ( -e $catidfile) {
		open F, $catidfile || carp("Can't open cat id file $catidfile") && return(0);
		$curcat = <F>;
		close F;
	} else {
		$curcat = $rootcat;
	}

	chomp $curcat;

	my $catcode  = &AbUtils::get_catcode($curcat);
        my $carr = &AbUtils::ArrayFromCatCode($catcode);
        my $lvl = &AbUtils::GetLevel($carr)+1;

	my $catref = new AbCat($curcat);
	my $catpath = $catref->make_nice_catpath($rootdom, $SHOW_FROM_LEVEL);

print "catpath is $catpath using show_from_level $SHOW_FROM_LEVEL\n";

print "Working on $_ in $curdir using category $curcat : $catpath...\n\n";
	# refresh templatehash

	$catowner = &AbUtils::get_catowner($curcat);

	my @subcats = ();

	&AbUtils::get_subcats($curcat, \@subcats, $userid,'Y');
	&fmt_array_for_table(\@subcats, 4);	# 4-column table

	my @catitems = ();

	&get_all_public_catitems($curcat, $lvl, \@catitems);

#	&AbUtils::get_all_blogitems($curcat, $lvl, \@catitems);

print "We have ",$#catitems," catitems for $curcat\n";

	&fmt_array_for_table(\@catitems, 5);	# 5-column table

	my @catrelated = ();
	&AbUtils::get_relations($curcat, 'category', 'ALL', \@catrelated);
	&fmt_array_for_table(\@catrelated, 5);	# 5-column table

	$catref = new AbCat($curcat);
	$catpath = $catref->make_nice_catpath($rootdom, $SHOW_FROM_LEVEL);

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

	# we iterate on $templatefile

	my $tmpstring = $abm->ProcessFile($templatefile);

	# now output to corresponding .html (warn on overwrite?)

	&CommandWeb::OutputToFileFromString($tmpstring,$outputfile,\%templatehash) || &ErrorExit("CommandWeb::OutputToWeb failed on $templatefile, string was $tmpstring, hash was ",%templatehash);

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
# returns all items in subcats of cat
sub get_all_public_catitems {
        my $curcat = shift;
        my $lvl = shift;
        my $itemref = shift;

# return array of hashes w/ID,NAME,VALUE,QUALIFIER
#       @$itemref = $obj->find('search'=>$curcat,'by'=>'CID','sort'=>'NAME','filter'=>'ITEMS','multiple');

#       my $q = "select * from $ITEM_TABLE where CID = $curcat order by ENTERED desc";

        my $q = "select rcatdb_items.id, rcatdb_items.itemcode, rcatdb_items.cid, rcatdb_items.name, rcatdb_items.short_content,
rcatdb_items.url, rcatdb_items.qualifier, rcatdb_items.effective_date, rcatdb_items.entered, users.login from rcatdb_items
,rcatdb_categories, users where LEFT(itemcode,$lvl) = LEFT(catcode,$lvl) and rcatdb_categories.id = $curcat and (users.id = rcatdb_items.owner) and rcatdb_items.security_level <= $PUBLIC_ACCESS_LEVEL  order by rcatdb_items.effective_date desc, entered desc, itemcode asc limit 100";


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
                my $itemcatref = new AbCat($itemcat);
                $p->{ITEMCATPATH} = $itemcatref->make_nice_catpath($rootdom,$SHOW_FROM_LEVEL);
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

	@res = $obj->find('search'=>$catid,'sort'=>'ID','by'=>'ID','filter'=>'CATEGORIES','multiple'=>'YES',
                     'route'=>'YES','partial'=>'NO','reverse'=>'NO','rules'=>$rules);
	return $res[0];
}


sub make_catpath {

	my $catref = shift;

	my $retstring = "\\".&AbUtils::make_href_link(0)."root</A>\\";

	my $path = $catref->{'route'};
	my $j;

print "Route in make_catpath is ",@$path;
print "\nPath has ",$#$path, " entries\n";

        for ($j = $#$path; $j>=0; $j--)
        {
	   my $p = $$path[$j];

print "processing $j : ",$p->{'ID'},$p->{'NAME'},"\n";
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


