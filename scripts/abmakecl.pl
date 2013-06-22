#!/usr/local/bin/perl
# Path to RCategories

# abmakecl.pl

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


$DEFAULT_TEMPLATE_DIR = '/home/sites/iwtucson/catpages';

$ROOTCAT = 306;
$ROOTLEVEL = 3;

$DEFAULT_TEMPLATE_FILE = "$ROOTCAT".'.tmpl';

use File::Find;
use Carp;
 
BEGIN {
      unshift (@INC, '.');
      unshift (@INC,"/w/abra/cgi");
      unshift (@INC,"/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbSecure;
use AbMacros;
use RCategories;
use Mysql;
use CommandWeb;
use AbCat;
use Abra;


	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://abra.info/cgi/ab.pl";
	$ADMINUSER = 1;
$debug = 1;

%HAVECATS =();

# HACK for testing
$rootdom = 'btucson.com';
$ROOT_TARGET_DIR = '/home/sites/iwtucson/www';

$gencat = $ARGV[0];

$use_template_file = $ARGV[1] || $DEFAULT_TEMPLATE_FILE;

$SHOWDELMASK = 1;
my %templatehash = ();


# Use MySQL (or DBI) to connect
$abra = new Abra;


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
	$root_target_dir = <F>;
	close F;
}
chomp $root_target_dir;


if ( -e $use_template_file ) {
	$default_template_file = $curdir .'/'.$use_template_file;
} else {
	$default_template_file =  $DEFAULT_TEMPLATE_DIR.'/'.$use_template_file;
	if  ( ! -e $default_template_file ) {
		croak "No template file $default_template_file";
	}
}

$q = "select catcode from rcatdb_categories where id = $ROOTCAT";
($rootcatcode) = $dbh->selectrow_array($q);

$rootcatcode = $dbh->quote($rootcatcode);

if ($gencat) {
	$q = "select * from rcatdb_categories where security_level = 0 AND id = $gencat";
	print "Query is $q\n";
} else {

	#$q0 = "select cid from rcatdb_items where NOW() - ENTERED < 20000001000000";
	$q0 = "select distinct cid from rcatdb_items where NOW() - ENTERED < 80000001000000";
	$updatecats = $dbh->selectall_arrayref($q0);
	$updatestring = '';
	foreach my $upcatref (@$updatecats) {
		my ($upcat) = @$upcatref;
		$updatestring .= " id = $upcat ";
		$updatestring .= "or";
	}
	chop $updatestring; chop $updatestring;
	print $updatestring;

#	&prompt("Are you sure you want to regen ALL categories? ");
#	print("Doing everything new since yesterday = ".$#$updatecats." cats\n");
#	$q = "select * from rcatdb_categories where security_level = 0  AND LEFT(catcode, $ROOTLEVEL) = LEFT($rootcatcode, $ROOTLEVEL) order by id ";
	$q = "select * from rcatdb_categories where security_level = 0 and ($updatestring)";
}

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

# TODO this should be done item by item so we don't miss those with
# optional types missing
@apply_types = ('ab_biz_org');

warn ("There are ".$sth->rows()." rows\n");

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $curcat = $ref->{ID}; 
	my $template_file = $default_template_file;
	my $target_dir = $ROOT_TARGET_DIR . $ref->{'REL_URL'};

	if (! -e $target_dir) {
		mkdir($target_dir,0755);
	}
	
	@apply_types = ();
#print "We foudn types ",@apply_types,"\n";

	my $target_file = "$target_dir/$DEFAULT_FILE_NAME";
	if ( -e "$target_file") {
		$target_file = "$target_dir/$ALTERNATE_FILE_NAME";
	}

#print "Processing cat # $curcat $ref->{'NAME'} , outputting to \n$target_file using template $template_file\n\n";
	&process_template_file($curcat, $template_file, $target_file);
		
}
$sth->finish;
$dbh->disconnect;
1;

sub process_template_file {

	my $curcat = shift;
	my $template_file = shift;
	my $target_file = shift;


#print "In process_tempalte_file trying to output from $template_file to $target_file using cat $curcat\n";

	# use macros for some vars, and for replacing output
	my $abm;
	$abm = new AbMacros(catid=>$curcat);
	
	# initialize templatehash
	my %templatehash = ();

	my $catcode  = &AbUtils::get_catcode($curcat);
        my $carr = &AbUtils::ArrayFromCatCode($catcode);
        my $lvl = &AbUtils::GetLevel($carr)+1;


	my $catref = new AbCat($curcat);
	$HAVECATS{$curcat} = $catref;
	my $catpath = $catref->make_nice_catpath($rootdom);
#print "Nice path for $catref->{'NAME'} is $catpath\n";
	# refresh templatehash

	$catowner = &AbUtils::get_catowner($curcat);

	my @subcats = ();

	&AbUtils::get_subcats($curcat, \@subcats, $userid);

	return unless $#subcats;

	eval {
		@subcats = sort { $a->{'NAME'} <=> $b->{'NAME'} } @subcats;
	}
	&AbUtils::fmt_array_for_table(\@subcats, 2);	# 2-column table for use in left-side column

	my @catitems = ();

	&get_all_catitems($curcat, $lvl, \@catitems);
#print "We have ",$#catitems," catitems for $curcat\n";

	&AbUtils::fmt_array_for_table(\@catitems, 5);	# 5-column table

#	my @catrelated = ();
#	&AbUtils::get_relations($curcat, 'category', 'ALL', \@catrelated);
#	&AbUtils::fmt_array_for_table(\@catrelated, 5);	# 5-column table

	foreach my $subcatref (@subcats) {
		$subcatref->{'CATLINK'} = $subcatref->{REL_URL};
#print "for SUBCAT ",$subcatref->{'NAME'}," ID ",$subcatref->{'ID'}," nice catpath is ",$subcatref->{'CATLINK'}, "\n";
	}

	$templatehash{'SUBCATS'} = \@subcats;
	$templatehash{'CATITEMS'} = \@catitems;
	# $templatehash{'ITEMRELATIONS'} = \@itemrelated;
	# $templatehash{'CATRELATIONS'} = \@catrelated;
	@relation_names = ();
	foreach my $mrel (keys(%RELATIONS)) {
		my $href = {'NAME'=>$mrel};
		push @relation_names, $href;
	}
	$templatehash{'RELATIONS'} = \@relation_names;
	$templatehash{'CATPATH'} = $catpath;
	$templatehash{'MENUDIVS'} = $abm->MenuDivs;
	$templatehash{'DIVCATPATH'} = $abm->DivCatPath;
	$templatehash{'CATNAME'} = $catref->{'NAME'};
	$templatehash{'CATCODE'} = &AbUtils::catcodestr($catref->{'CATCODE'});
	$templatehash{'CATID'} = $curcat;
	$templatehash{'ITEMID'} = $curitem;
#	$templatehash{'THISCGI'} = $THISCGI;
	$templatehash{'BLOGCGI'} = $BLOGCGI;
	$templatehash{'USERPREF'} = $userpref;
	$templatehash{'THISLINK'} = $catref->{'REL_URL'};
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



	# we iterate on $template_file

	my $tmpstring = $abm->ProcessFile($template_file);

	# now output to corresponding .html (warn on overwrite?)

	&CommandWeb::OutputToFileFromString($tmpstring,$target_file,\%templatehash) || warn("CommandWeb::OutputToWeb failed writing to $target_file, last error was $?, hash was ",%templatehash);

} # end processtemplatefile


1;





####################################################################
# returns all items in subcats of cat
sub get_all_catitems {
	my $curcat = shift;
	my $lvl = shift;
	my $itemref = shift;

# return array of hashes

	my $sel_types = '';
	my $sel_tables = '';
	my $where_tables = '';
	foreach $abtype (@apply_types) {
		$sel_types .= ','. $abtype.'.*';
		$sel_tables .= ','.$abtype;
		$where_tables .= " and $abtype.id = rcatdb_items.id ";
	}

 	my $q = "select rcatdb_items.id, rcatdb_items.itemcode, rcatdb_items.cid, rcatdb_items.name, rcatdb_items.short_content, rcatdb_items.url, rcatdb_items.qualifier, rcatdb_items.effective_date, rcatdb_items.entered from rcatdb_items,rcatdb_categories where rcatdb_categories.id = $curcat and  LEFT(itemcode,$lvl) = LEFT(catcode,$lvl) and rcatdb_items.security_level = 0 $where_tables  order by rcatdb_items.effective_date desc, rank desc, entered desc, itemcode asc limit 100";

#print "Query is $q\n";

	&AbUtils::get_query_results($itemref, $q);

#print "Got $#$itemref results\n";

	$rel_limit = 100 - $#$itemref;

	$q1 = "select rcatdb_items.id, rcatdb_items.itemcode, rcatdb_items.cid, rcatdb_items.name, rcatdb_items.short_content, rcatdb_items.url, rcatdb_items.qualifier, rcatdb_items.effective_date, rcatdb_items.entered $sel_types from rcatdb_items, rcatdb_ritems where rcatdb_ritems.id = rcatdb_items.id and rcatdb_items.security_level = 0 and rcatdb_ritems.cat_dest = $curcat and rcatdb_ritems.relation = 'BELONGS_TO'  order by rcatdb_items.effective_date desc, rank desc, entered desc, itemcode asc limit $rel_limit";

	&AbUtils::get_query_results($itemref, $q1);

#print "rquery is $q1\n";
#print "With related, have $#$itemref results\n";

# values->urls if match
	for my $p (@$itemref) {

	# hardcode for now to test crashing
		my $extra_ref = $dbh->selectrow_hashref("select ADDR, PHONE from ab_biz_org where ID = ".$p->{'ID'});
		if ($extra_ref) {
			$p->{'ADDR'} = $extra_ref->{'ADDR'};
			$p->{'PHONE'} = $extra_ref->{'PHONE'};
		}

		$p->{'LINK'} = $p->{'URL'};
		
#TODO: improve templating

		$p->{SHORT_CONTENT} = &CommandWeb::HTMLize($p->{'SHORT_CONTENT'});
	
		$p->{META_DESCRIPTION};
#print "finding related links...";
#		$p->{RELATED_LINKS} = &AbUtils::make_rel_links($p->{'ID'});

		$p->{ITEMCAT} = my $itemcat = $p->{'CID'};
#print "Going to get cat for item...";
		my $itemcatref;
		if (exists $HAVECATS{$itemcat}) {
			$itemcatref = $HAVECATS{$itemcat};
		} else {
			$itemcatref = new AbCat($itemcat);
			$HAVECATS{$itemcat} = $itemcatref;
		}
#print "got it..";

		my $item_show_from_level = $SHOW_FROM_LEVEL;  # must match $rootdom or whatever dom is passed

		$p->{ITEMCATPATH} = $itemcatref->make_nice_catpath($rootdom,$item_show_from_level);

		$p->{ITEMCODE} = &AbUtils::catcodestr($p->{'ITEMCODE'});
#print "made catcodestr\n";

	}
	#TODO use proper URL matching
}

sub prompt {
        my($prompt,$def) = @_;
        $prompt = &subvars($prompt);
        if ($def) {
                if ($prompt =~ /:$/) {
                        chop $prompt;
                }
                if ($prompt =~ /\s$/) {
                        chop $prompt;
                }
                print $prompt," [",$def,"]: ";
        } else {
                if ($prompt !~ /[:\?]\s*$/) {
                        $prompt .= ': ';
                } elsif ($prompt !~ /\s$/) {
                        $prompt .= ' ';
                }
                print $prompt;
        }
        $| = 1;
        $_ = <STDIN>;
        chomp;
        return $_?$_:$def;
}

