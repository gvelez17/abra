#!/usr/local/bin/perl -T
# Path to RCategories

# utils
 
BEGIN {
	unshift (@INC, '/w/abra/cgi');
      unshift (@INC, '/w/abra/lib');
}

use AbHeader qw(:all);
use AbUtils;
use AbMacros;
use RCategories;
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

#$q = "select * from rcatdb_categories where id = 306 or cid = 30 or cid = 306";
$q = "select * from rcatdb_categories";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

$BIZCAT = 306;
$EDITOR_ID = 7080;

$TARGET_DIR = '/home/sites/iwtucson/www/inc/cats2/';

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $catid = $ref->{'ID'};
	my $catcodestr = &AbUtils::abbrev_catcodestr($ref->{'CATCODE'});
	my $filename = $TARGET_DIR.$catcodestr.'.html';

	my $q0 = "select name, rel_url from rcatdb_categories where id = $catid";
	my($parent_name, $parent_url) = $dbh->selectrow_array($q0);
	
	open F, ">$filename";

	$parent_name =~ s/\s/\&nbsp\;/g;

	print F "<div class=ab_menu_topbar><span class=ab_menu_popdown onclick=\"ab_remove_panel(this)\">x</span>&nbsp;<A HREF='$parent_url' class=\"ab_menu_link\">$parent_name</A></div>\n";

	$q1 = "select id, name, rel_url, catcode, lastsubcode from rcatdb_categories where cid = $catid order by display_order asc, name asc";
	my $subcatref = $dbh->selectall_arrayref($q1);
	foreach $catref (@$subcatref) {	
		my ($id, $name,$rel_url, $catcode, $numsubcats) = @$catref;
		$name =~ s/\s+/\&nbsp\;/g;
		my $a_cstr = &AbUtils::abbrev_catcodestr($catcode);

		my $popright = "popright_$a_cstr";
		my $popleft = "popleft_$a_cstr";

#print "Working on $a_cstr\n";
		$expand_right = '';
		$expand_left = '';
		if ($numsubcats > 0) {
			$expand_left = "<div id=$popleft class=ab_menu_expandable_left onclick=\"ab_cascade(this,'$a_cstr')\">+</div>&nbsp;";
			$expand_right = "<span id=$popright class=ab_menu_expandable_right onclick=\"ab_cascade(this,'$a_cstr')\" onmouseover=\"ab_set_timer_cascade(this,event,'$a_cstr',false)\">&nbsp;&#187;</span>&nbsp;";
		} else {
			$expand_right = $expand_left = "<div class=ab_menu_noexpand>&nbsp;</div>&nbsp;";
		}

		print F "<A HREF='$rel_url' class=\"ab_menu_link\">$name</A>$expand_right<br>\n";

#print "Wrote to file $filename\n";
	}
	close F;
}

1;
