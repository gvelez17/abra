#!/usr/local/bin/perl -T

# utils
 
BEGIN {
      unshift (@INC, '/w/abra/lib');
}

use AbHeader qw(:all);
use Abra;
use AbCat;
use AbUtils;
use AbMacros;

$ab = new Abra;

 $LIMIT = "limit 50";
#$LIMIT = '';

if (!$dbh) {
	print "Error - cannot get database handle\n";
	exit;
}

$catstr = '4:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0';
$catcode = &AbUtils::catcode_from_str($catstr);
$qcatcode = $dbh->quote($catcode);
$level = 1;
$catwhere = "LEFT(catcode, $level) = LEFT($qcatcode, $level)";
#$catwhere = "catcode is NOT NULL";

#$q = "select * from rcatdb_categories where id = 306 or cid = 30 or cid = 306";
#$q = "select catid, catcode, title,lastsubcode from structure where catcode is NOT NULL $LIMIT";
$q = "select id, catcode, name, lastsubcode from rcatdb_categories where $catwhere and security_level=0 $LIMIT";

print "Query is $q\n\n";

$sth = $dbh->prepare($q);

$sth && $sth->execute() || die("Can't execute $q");

$TARGET_DIR = '/home/sites/abra/www/inc/abracats/';

while ($ref = $sth->fetchrow_hashref('NAME_uc')) {

	my $catid = $ref->{'ID'};
	my $catcode = $ref->{'CATCODE'};
	my $catname = $ref->{'NAME'};
	my $numsubcats = $ref->{'LASTSUBCODE'};

	my $catstr = &AbUtils::catcodestr($catcode);

print "\n\nWorking on cat $catname $catstr with $numsubcats subcategories\n";

	my $filename = &MakeParentCatFile($TARGET_DIR, $catcode);

# Lost changes made 12/14/07

# TODO:  abbreviate css codes

#TODO: could also write my title to my own catfile.  Now writing into my parent
	
	$firstline = '';
	if (! -e $filename) {

		$firstline = "<div class=abt><span class=abd onclick=\"ab_remove_panel(this)\">X</span>&nbsp;</div>\n";

	}
	open F, ">>$filename";
	
	$firstline && print F $firstline;

#warn "Writing to $filename\n";

	$catname =~ s/\s+/\&nbsp\;/g;
	my $a_cstr = &make_catcodedir($catcode);

	my $j_cstr = $a_cstr;
	$j_cstr =~ s/\//_/g;

	my $popright = "popright_$j_cstr";

	my $selectitem = "ab_item";

#print "Working on $a_cstr with $numsubcats subcats\n";
	$expand_right = '';
	if ($numsubcats > 0) {
		$expand_right = "<span id=$popright catname=\"$catname\" class=aber onclick=\"ab_cascade(this,'$a_cstr')\" onmouseover=\"ab_set_timer_cascade(this,event,'$a_cstr',false)\">&nbsp;&#187;</span>&nbsp;";
		$itemspan = "<A HREF=\"javascript:ab_select('$a_cstr','$catname')\"  class=ablnk>";
		$end_itemspan = "</A>";
		# tried onmouseover for itemspan but too reactive

	} else {
		$expand_right = "<span class=abnoex>&nbsp;</span>&nbsp;";
		$itemspan = "<a href=\"javascript:ab_select('$a_cstr','$catname')\" class=ablnkl>";
		$end_itemspan = "</a>";
	}

	print F "&nbsp;$itemspan$catname$end_itemspan&nbsp;$expand_right<br>\n";

	close F;
print "$filename\n";
}

1;



sub MakeParentCatFile{
	my $topdir = shift;
	my $catcode = shift;

	my $catfile = $topdir;

	my @catcode = unpack "C16", $catcode;

#print "Right off, catcode is @catcode\n";

	my $mcat = pop @catcode;
	$j = 15;
	while (($j > 0) && ! $mcat ) {
		$mcat = pop @catcode;
		$j--;
	}

# We don't push it back on because we want to write into our parent's index
#	if ($mcat) { push @catcode, $mcat; }

	$catfile .= join('/',@catcode);
#print "Tried join of $catlen items to get directory $catfile\n";
	$catfile .= '/index.html';
	if (-e $catfile) {
		return $catfile;
	} 

	my $wdir = $topdir;

	$j = 0;
        while (($mcat = shift @catcode) && ($j < 16)) {

#print "shifted $mcat...now catcode is ",@catcode,"...";
		$wdir .= '/'.$mcat;
		if (! -d $wdir) {
			mkdir ($wdir, 0755);
		}

		$j++;
	}

#print "Now I think it is $wdir\n";
	$catfile = $wdir . '/index.html';

	return $catfile;
}

sub make_catcodedir {

        my $code = shift;

        my @catcode = unpack "C16",$code;
        $j = 0;
        my $catcodestr = '';
        while (($j < 17) && ($catcode[$j] ne '0')) {
                $catcodestr .= $catcode[$j];
                $catcodestr .= "/";
                $j++;
        }
        chop $catcodestr;
        return $catcodestr;
}
