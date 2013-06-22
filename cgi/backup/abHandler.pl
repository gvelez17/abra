#!/usr/local/bin/perl -T

BEGIN {
      unshift (@INC, '.');
        unshift(@INC, "/w/abra/lib");
}

use AbHeader qw(:all);
use AbUtils;
use AbCat;
use AbAcct;
use Abra;
use AbSecure;
use AbMacros;
use AbDomains;
use Mysql;
use CGI qw(:cgi-lib);
use CommandWeb;

use CGI::Lite;
use PHP::Session;

$MAP_WIDTH=400;
$MAP_HEIGHT=250;

$MAX_DESCRIP_LENGTH = '120';

# Hack for testing
#if ($0 =~ /org/) {
#       $DBNAME = 'rpub';
#       $DBUSER = 'groots';
#       $DBPASS = 'sqwert';
#       $THISCGI = "http://qs.abra.info/cgi/org.pl";
#} else {
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
        $THISCGI = "http://abra.info/cgi/ab.pl";
        $ADMINUSER = 1;
        $ALT_ADMIN_USER = 7886;
	$JASON_ADMIN_USER = 10925;

	$DEFAULT_TEMPLATE_FILE = 'tmplBrowseItem.html';
	$IMG_BASE_URL = '/item_images';
	$IMG_ORIG_URL = '/item_image_originals';

#}
$debug = 0;
if ($debug) {
	print "Content-type: text/html\n\n";
}

ReadParse(\%in);
$query = $in{CGI};

# Make handler able to display different templates depending on context
$req_url = $ENV{'REQUEST_URI'};
$debug && print "<!-- request url is $req_url -->\n";

# what domain are we?
$TEMPLATE_DIR = '/home/sites/iwtucson/itempages';
$IMG_BASE_DIR = '/home/sites/iwtucson/www/item_images';
$IMG_ORIG_DIR = '/home/sites/iwtucson/www/item_image_originals';
$STATE_CODE = 'AZ';
$domain = 'btucson.com';
$city = 'Tucson';
if (($ENV{'SERVER_NAME'} =~ /dallas/i)) {
	$domain = 'bdallas.com';
	$city = 'Garland';
	$STATE_CODE = 'TX';
	$TEMPLATE_DIR = '/home/sites/bdallas/itempages';
	$IMG_BASE_DIR = '/home/sites/bdallas/www/item_images';
	$IMG_ORIG_DIR = '/home/sites/bdallas/www/item_image_originals';
	$DEFAULT_SEARCH_ID = 5;
} elsif (($ENV{'SERVER_NAME'} =~ /abra.info/i)) {
	$domain = 'abra.info';
	$city = '';
	$STATE_CODE = '';
	$TEMPLATE_DIR = '/home/sites/abra/itempages';
	$IMG_BASE_DIR = '/home/sites/abra/www/item_images';
	$IMG_ORIG_DIR = '/home/sites/abra/www/item_image_originals';

} elsif (($ENV{'SERVER_NAME'} =~ /tech-for-teachers/i)) {
	$domain = 'tech-for-teachers.com';
	$city = '';
	$STATE_CODE = '';
	$TEMPLATE_DIR = '/home/sites/teachtech/itempages';
	$IMG_BASE_DIR = '/home/sites/teachtech/www/item_images';
	$IMG_ORIG_DIR = '/home/sites/teachtech/www/item_image_originals';
}

$abdomain = new AbDomains($domain);

if (($in{ACTION} eq 'RELATE') || ($req_url =~ /relate_to/)) {
	$DEFAULT_TEMPLATE_FILE = 'tmplRelateToItem.html';
}

# Use MySQL (or DBI) to connect
$abra = new Abra;


if (!$dbh) {
        warn "Error - cannot get database handle\n";
        exit;
}

$dbh->{FetchHashKeyName} = 'NAME_uc';

my $rurl = $ENV{'REDIRECT_URL'};
warn "Redirect URL is \|$rurl\|\n";
my $keyword = '';
if ($rurl =~ /^(.*\/)([^\/]+)$/) {
	$caturl = $1;
	$keyword = $2;

	# SECURITY CHECK
	$keyword =~ /^[a-zA-Z0-9_\-\,\.\s]*$/ || die "invalid keyword $keyword\n";
	$caturl =~ /^[a-zA-Z0-9\&\-_\,\s\/]*$/ || ($caturl =~ /^[a-zA-Z0-9\&\-_\s\/]*$domain[a-zA-Z0-9\&\-_\s\/]*$/i) || die "invalid caturl $caturl\n";

#$debug = 1;

$debug && warn "Got keyword: $keyword in category $caturl\n";

	my $href;

# is it an item id? 
	if ($keyword =~ /^[0-9]+$/) {
		my $q = "select rcatdb_items.*, rcatdb_categories.rel_url from rcatdb_items, rcatdb_categories where rcatdb_items.id = $keyword and rcatdb_items.security_level = 0 and rcatdb_categories.id = rcatdb_items.cid";
		$href = $dbh->selectrow_hashref($q);
	
		#  Normalize the URL to the main category we belong to
#		if (($ENV{'REDIRECT_STATUS'} eq '404') && ($caturl ne $href->{'REL_URL'})) {
#			my $newloc = $href->{'REL_URL'};
#			if ($newloc !~ /\/$/) { $newloc .= '/'; }
#			$newloc .= $keyword;
#			print "Location: $newloc\n";
#			print "Status: 301\n\n";
#			exit 1;			
#		}	

	}

# is it a handle?
	if (! $href) {
		my $q = "select rcatdb_items.* from rcatdb_items,handles "
		." where rcatdb_items.id = handles.id and handles.handle = "
		.$dbh->quote($keyword);

		$href = $dbh->selectrow_hashref($q);

	}

# are we logged in ?
	my $username = &AbSecure::get_username;
$debug && print "Got username $username\n";

# don't return results for robots.txt
	if ($keyword eq 'robots.txt') {
		print "Content-type: text/html\n";
		print "Status: 404 Not Found\n\n";
		print "No robots.txt - not found";
		exit 1;
	}


# if we can't find it at all, just search
	if (! $href) {

		my $newurl = '';
		if ($domain eq 'bdallas.com') {
			$newurl = 'http://'.$domain.'/cgi-bin/wgdallas/webglimpse.cgi?ARCHID_1=5&ARCHID_2=6&limit=500%3A100&cache=yes&alternate=yes&ref=abHandler&query=';
		} else {
			$newurl = 'http://'.$domain.'/cgi-bin/wgtuc/webglimpse.cgi?ARCHID_2=2&ARCHID_3=3&limit=500%3A100&cache=yes&alternate=yes&ref=abHandler&query=';
		}

		# protect against phishing attacks
		$keyword =~ s/[^a-zA-Z0-9_\-\s]/ /g;

		$newurl .= $keyword;

		print "Location: $newurl\n";
		print "Status: 200 OK\n\n";

		warn "Trying to redirect to location $newurl\n";

		exit 1;

	}


# Ok, we have something to go on

	print "Content-type: text/html\n";
	print "Status: 200 OK\n\n";

#print "<!-- UID = ",$<,"Query string = ",$ENV{'QUERY_STRING'},"-->\n";
#print "<!-- ENV is: ";
#foreach my $var (keys %ENV) {
#	print $var, " : " , $ENV{$var},"<br>\n";
#}
#print "-->";
	my $curcat = $href->{'CID'};

	# are we logged in?
	my $macct;
	if ($username) {
		$macct = new AbAcct($username);
	}

        # use macros for some vars, and for replacing output
	my $abm;
	$abm = new AbMacros(catid=>$curcat,username=>$username);

	$href->{'MENUDIVS'} = $abm->MenuDivs;
	$href->{'DIVCATPATH'} = $abm->DivCatPath;
	$href->{'LOGIN'} = $abm->Login($rurl);

	# we already got the cat info, may as well use it
	my $mcat = $abm->getCat;
	$href->{'CATNAME'} = $mcat->{'NAME'};

	# get the name of the item owner
	my $owner_login = '';
	if ($href->{'OWNER'}) {
		($owner_login) = $dbh->selectrow_array("select LOGIN from users where id = ".$href->{'OWNER'}); 
	}
	$href->{'OWNER_LOGIN'} = $owner_login || 'guest';

	my $extra_ref = $dbh->selectrow_hashref("select ADDR, PHONE,CITY,ZIP from ab_biz_org where ID = ".$href->{'ID'});
        my $addr = '';
	my $do_gmap = 0;
        if ($extra_ref) {
	      $href->{'ADDR'} = $extra_ref->{'ADDR'};
              $href->{'PHONE'} = $extra_ref->{'PHONE'};
	      $href->{'ZIP'} = $extra_ref->{'ZIP'};
	      if ($extra_ref->{'CITY'}) {
			$city = $extra_ref->{'CITY'};
			if ($city ne 'Tucson') {
				$href->{'CITY'} = $city;
			}		
	      }
	      $href->{'ADDR'} =~ s/\s+$//g;
              $addr = $href->{'ADDR'}.', '.$city.', '.$STATE_CODE.' '.$href->{'ZIP'}.', USA'; # TODO get state code correctly
		
	      if ($href->{'ADDR'} &&($href->{'ADDR'} !~ /^P\.?\s*O\.?\s*Box/i)) {
			$do_gmap = 1;
	      }
	      if ($do_gmap) {	
		      $href->{'GOOGLE_MAP'} = $abm->GoogleMap($MAP_WIDTH,$MAP_HEIGHT);
		}
        }
	if ($do_gmap) {
		$href->{'GOOGLE_MAP_SCRIPT'} = $abm->GoogleMapScript($addr);  # we need this anyway
	}

	if ($href->{'URL'}) {
		$href->{'COMMENT_VIEW'} = $abm->CommentViewLink($href->{'URL'},$href->{'ID'});
	}


# Oddity db locations data is crap!
#	my $loc_ref = $dbh->selectrow_hashref("select LATITUDE, LONGITUDE from ab_location where ID = ".$href->{'ID'});
#	if ($loc_ref) {
#	}


	# fixup text content
	$href->{'SHORT_CONTENT'} = &CommandWeb::HTMLize($href->{'SHORT_CONTENT'});

	# provide meta descrip - TODO add DESCRIP field optional
	$href->{'DESCRIP'} = $href->{'SHORT_CONTENT'};
	$href->{'DESCRIP'} =~ s/\<[^>]+\>//g;       				# remove tags
	$href->{'DESCRIP'} = substr($href->{'DESCRIP'},0,$MAX_DESCRIP_LENGTH);  # chop down
	$href->{'DESCRIP'} =~ s/\b[^\s]+$//;  # cut off partial words
	if ($href->{'DESCRIP'}) {
		$href->{'DESCRIP'} .= '...';
	}


        $href->{'FEATURE'} = $abm->Feature($href->{'CID'});

	$href->{'CAT_SPECIAL'} = $abm->Cat_Special($href->{'CID'}, $href);


	
	# if we have an item
	my $curitem = $href->{'ID'};
	if ($curitem) {

		my $WANT_CONTENT = 1;


		# Set some macro fields; should really just inherit or use Item obj
		$abm->SetVar('ID',$curitem);
		$abm->SetVar('ITEMNAME',$href->{'NAME'});	

		# these are things we can do for an item
		$href->{'ADD_COMMENT'} = $abm->AddComment;
		$href->{'LOAD_IMAGE'} = $abm->LoadImage;

		if ($username && (($macct->{'ID'} == $href->{'OWNER'}) || ($macct->{'ID'} == $ADMINUSER)
			  || ($macct->{'ID'} == $ALT_ADMIN_USER) 
			  || ($macct->{'ID'} == $JASON_ADMIN_USER) )) {
			$href->{'EDIT_ITEM'} = $abm->EditItem($curitem);
		}

		# set up the adcode
		$href->{'GOOGLE_AD_CODE'} = $abm->GoogleAdCode($href->{'OWNER'});

		# get our fields
		my $rq1 = "select rcatdb_items.EFFECTIVE_DATE, rcatdb_items.owner, rcatdb_items.ID, rcatdb_items.CID, rcatdb_items.NAME, rcatdb_items.URL, rcatdb_items.SHORT_CONTENT, rcatdb_ritems.RELATION,users.login from rcatdb_items, rcatdb_ritems,users where rcatdb_ritems.id = $curitem and rcatdb_items.security_level = 0 and rcatdb_items.id = rcatdb_ritems.item_dest and rcatdb_items.owner = users.id order by rcatdb_items.EFFECTIVE_DATE desc";
	
		&AbUtils::get_query_results(\@itemrelated, $rq1);

		$href->{'RELITEMS'} = \@itemrelated;

		# are we related from (ie are we a comment about) 
		my $rq2 = "select rcatdb_items.EFFECTIVE_DATE, rcatdb_items.owner, rcatdb_items.ID, rcatdb_items.CID, rcatdb_items.NAME, rcatdb_items.URL, rcatdb_ritems.RELATION from rcatdb_items, rcatdb_ritems where rcatdb_ritems.item_dest = $curitem and rcatdb_items.security_level = 0 and rcatdb_items.id = rcatdb_ritems.id";
#print $rq;

		my @relatedfromitem = ();
	
		&AbUtils::get_query_results(\@relatedfromitem, $rq2);

		$href->{'RELFROM'} = \@relatedfromitem;
		for my $ritem (@relatedfromitem) {
			$ritem->{URL} = "http://$domain/".$ritem->{ID};

		}

		# get related categories
		@relcats = ();
		&AbUtils::get_item_relcats($curitem, \@relcats);

#print "Have $#itemrelated related items using $rq";
#foreach my $itemref (@itemrelated) {
#	print "Got related item : ".$itemref->{NAME}.$itemref->{SHORT_CONTENT}."<p>";
#}

		# Do we have any images?
		my $iq = "select uid, ext, caption, credits from ab_images where item_id = $curitem and security_level = 0";


		my $imguids_ref = $dbh->selectall_arrayref($iq);

		# TODO: select random image, or rotate within session
                my $which_img = 0;
#                my ($img_uid,$ext,$caption,$credits) = @{$imguids_ref->[$which_img]};
		my $img_tag = "<div class=\"img_feature\">\n";
		my $have_img = 0;
		$href->{'ITEM_IMG'} = '';
		for my $slice (@$imguids_ref) {
			my ($img_uid, $ext, $caption, $credits) = @$slice;

			if ($img_uid) {
				$img_url = $IMG_BASE_URL.'/'.$curitem.'_'.$img_uid.'.'.$ext;
				$img_file = $IMG_BASE_DIR.'/'.$curitem.'_'.$img_uid.'.'.$ext;
				next unless ( -e $img_file);
				$img_orig_url = $IMG_ORIG_URL.'/'.$curitem.'_'.$img_uid.'.'.$ext;
				$img_orig_file = $IMG_ORIG_DIR.'/'.$curitem.'_'.$img_uid.'.'.$ext;

				# TODO: move this layout stuff into AbMacros.pm
				my $img_prelink = '';
				my $img_postlink = '';
				if (-e $img_orig_file) {
					$img_prelink = "<A HREF='$img_orig_url' alt='full size image'>";
					$img_postlink = "</A>";
				}	
				$img_tag .= $img_prelink."<IMG SRC=\"$img_url\">$img_postlink $caption --$credits\n";
				$have_img = 1;

			}
		}
		$img_tag .= "</div>\n";
		if ($have_img) {
			$href->{'ITEM_IMG'} = $img_tag;
		}

	}

	foreach my $itemref (@itemrelated) {

		$itemref->{'SHORT_CONTENT'} = &CommandWeb::HTMLize($itemref->{'SHORT_CONTENT'});
		$itemref->{'RELATED_URL'} = $itemref->{'URL'};

	}

        foreach my $subcatref (@relcats) {
                $subcatref->{'CATLINK'} = $subcatref->{REL_URL};
        }


        $href->{'RELCATS'} = \@relcats;

	#TODO:move to AbMacros
	$href->{'META_KEYWORDS'} = $href->{'NAME'}.','.$href->{'CATNAME'}.','.$city;
	foreach my $mcat (@relcats) {
		$href->{'META_KEYWORDS'} .= ','.$mcat->{'NAME'};
	}
	$href->{'META_KEYWORDS'} .= ",Arizona,Pima County,Southern Arizona,AZ,Old Pueblo,blog,superblog,Tuscon,bTucson,Be $city,comments,feedback,reviews";

	$href->{'META_DESC'} = $abdomain->makeItemMetaDesc($href, \@itemrelated);
	$template_file = $TEMPLATE_DIR.'/'.$href->{CID};

# todo: look for parent cat, or use catcode instead

	if (! -e $template_file) {
		$template_file = $TEMPLATE_DIR.'/'.$DEFAULT_TEMPLATE_FILE;
	}

	&CommandWeb::OutputTemplate($template_file, $href);

} else {
	print "Content-type: text/html\n\n";

	print "sorry, I don't know anything about $rurl";
}

$dbh->disconnect;

1;
