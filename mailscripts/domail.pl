#!/usr/local/bin/perl

# maybe: use Mail::Internet
# just lookup RFC 822 for header details
# we only care about From: and body of message

# TODO list:
#
#	send email back ; offer help
#	send back template for updating table
#
#
#



# Find From: line and parse email address

# get body

# look for our commands in body
#  #% is sure sign
#  also lines with word: stuff may be commands to us (if no #% then we use those)

# Find From: line and parse email address
my $from = '';

#TODO : move this to config file

$ITEM_TABLE = "rcatdb_items";
$CAT_TABLE = "rcatdb_categories";
$RCAT_TABLE = "rcatdb_rcats";
$RITEM_TABLE = "rcatdb_ritems";

$SPECIALCHARS = '#%';
# TODO: add 'description', 'content', 'rel:[RELATION]:handle|string|url
$IDENTS = "cat title url text handle content";
$ANONUSERID = 65535;
$TYPE = 'type';

open F, ">/home/abra/data/logfile";
@msg = <STDIN>;

open G, ">/home/abra/data/lastmsg";
print G @msg;
close G;

$subject = '';
$j = 0;
while ($line = shift(@msg)) {
	chomp $line;

#print F "line is |$line|\n";
	last if ($line eq '');
	if (($line =~/^From:/) && ($line =~/(\S+\@\S+)/)) {
		$from  = $1;
		if ($from =~ /<([^>]+)>/) {
			$from = $1;
		}

#print F "Found from $from\n";
	} elsif (($line =~ /^Subject:\s+(.+)$/)) {
		$subject = $1;
	}
}


# if there's anything left it should be the body
#print "Body is ",join("\n",@msg);
$body = join("\n",@msg);

print F "Body is $body\n";

# Now do our database stuff
BEGIN{
	unshift @INC, "/w/abra/cgi";
}
BEGIN{
	use RCategories;
	use Mysql;
	use DBI;

	$obj = RCategories->new(database => 'rcats', user => 'rcats', pass => 'meoow', host => 'localhost');
	$dbh = $obj->{'dbh'};

	if (!$obj) {
        	print "Error - cannot connect to database";
        	exit;
	}
}

use AbHeader qw( :all );
use AbUtils;

# lookup the $from user in our users database
# set default category, permissions, preferences
my $uref = getuserfromemail($from);

# look for our commands in body
#  #% is sure sign
#  also lines with word: stuff may be commands to us (if no #% then we use those)

&AbraParseText(\@msg,$uref);

&writedata($uref, $from, $body);
close F;
1;


# Each line might have
#
# optional_cntrlchars optional_cmd identifier: content
#
#
sub AbraParseText {
	my $linesref = shift;
	my $uref = shift;
	my $curcat = $uref->{cathome} || 0;
	my $curid = 0;
	my $lastident = '';
	$j = 0;
	my ($title, $text, $url, $handle) = ('','','','');
	my %namedhash = ();
	while ($j<=$#$linesref) {

		$line = $$linesref[$j];
		chomp $line;
		$j++;
#print "Procssing line:|$line|:\n";
		# is this line addressed to us? (we might get human emails mixed in)
		# continued on next line?
		while (($line =~ s/\+$//)&&($j<=$#$linesref)) {
			$line .= $$linesref[$j];
			chomp $line;
			$j++
		}
		
		$line =~ s/=20/ /g;
		
		$lastident = $ident;
		$ident = '';
		$table = '';
		$field = '';
################################################################
#
#  Parse the lines in the email
#
# 		Of the form 
# 	 	#%cmd ident: value 
		if ($line =~ /^\#\%\s*(\S*)\s+([^\s:]+):\s*(.*)$/) {
#rint "Found an ABRA command #%",$1,"\n";
			$cmd = $1;
			$ident = $2;
			$content = $3;
	
			if (($ident!~/^[a-zA-Z_0-9#%:]+$/) || ($IDENTS !~ /\b$ident\b/i)) {
				$ident = '';
			}
		# Of the form 
		# ident: value
		} elsif ($line =~ /^\s*([^\s:]+):\s*(.+)$/) {
			$cmd = '';
			$ident = $1;
			$content = $2;
			if (($ident!~/^[a-zA-Z_0-9#%:]+$/) || ($IDENTS !~ /\b$ident\b/i)) {
				$ident = '';
			}
#$ident && print("We recognize this one\n");

# TODO: recognize starting with 'text:' and ending with next control line
#  indent? endtext? %#?
		}
#rint "Before checking for type ident is $ident\n";
		# Lets see if its a special type, format will be
		# type:[tablename]:[fieldname]: [stuff]
		if (!$ident && ($line =~ /^\s*$TYPE:([^\s:]+):([^\s:]+):\s*(.+)$/i)) {
#rint "Found TYPE $1, $2 = $3\n";
			$ident = 'type';
			$table = $1;
			$field = $2;
			$namedhash{$table}{$field} = $3 || '';
		} elsif (!$ident && ($line =~ /^\#\%\s*(\S+)\s+$TYPE:([^\s:]+):([^\s:]+):\s*(.*)$/i)){
		
#rint "Found an ABRA command #%",$1," table $2 field $3 \n";
			$cmd = $1;
			$ident = 'type';
			$table = $2;
			$field = $3;
			$namedhash{$table}{$field} = $4;
		}
#rint "\ncmd is $cmd Ident is $ident\n";
		$ident || next;

		$cmd = lc($cmd);
		$ident = lc($ident);

# 		Is this a Content: or Text: type with possible continued lines? Would have to be format
# 		#%begin content:
# 		...
# 		#%end
		if (($cmd eq 'begin') && (($ident eq 'content')||($ident eq 'text'))) {
print "Found begin\n";
			$content .= "\n" if ($content);
			$line = $$linesref[$j];
			$j++;
			while (($line !~ /^\#\%end/)&&($j<=$#$linesref)) {
				$content .= $line;			
				$line = $$linesref[$j];
				$j++;
			}
		}
		elsif (($cmd eq 'begin') && ($ident eq 'type')) {
print "Found begin for table: $table and field $field\n";
			$namedhash{$table}{$field} .= "\n" if ($namedhash{$table}{$field});
			$line = $$linesref[$j];
			$j++;
			while (($line !~ /^\#\%end/)&&($j<=$#$linesref)) {
				$namedhash{$table}{$field} .= $line;			
				$line = $$linesref[$j];
				$j++;
			}
print "After it all the hash is:\n "; &printhashhash(\%namedhash);
		}
#		
######################################################3		
	
		if (!$title && $subject) {
			$title = $subject;
		}
		
#print "Found ident:$ident, cmd:$cmd, content:$content\n";
		if ($ident eq 'cat') {	# TODO make more general
			if ($lastident) { # if already processed any lines (cat should be first each group)
				$curid = AddItem($curcat, $title, $text, $url, $uref, &AbUtils::make_type_string(\%namedhash));
				&AbUtils::add_to_tables($curid,\%namedhash);
			}
			
			$curcat = &ParseCatString($content, $uref);
			$title = '';
			$text = '';
			$url = '';
		} elsif (($ident eq 'title')||($ident eq 'name')) {
			$title = $content;
		} elsif (($ident eq 'text')||($ident eq 'value')||($ident eq 'content')) {
			$text = $content;
		} elsif ($ident eq 'url') {
			$url = $content;
		} elsif ($ident eq 'handle') {
			&AbUtils::add_handle($curid, $content, 'I');
		}
	}
	$curid = AddItem($curcat, $title, $text, $url, $uref, &AbUtils::make_type_string(\%namedhash));
	&AbUtils::add_to_tables($curid,\%namedhash);
}

sub AddItem {
	my ($cid, $title, $text, $url, $uref, $qualifier) = @_;
	my $id = 0;

	if (! ($title || $text || $url)) { return 0;}

	if (! $title) { 

		$title = "from_".$uref->{'username'};
	}

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

	$id = &AbUtils::add_item($cid, $title, $value, 0, 0, $uref->{id},$qualifier);

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

print "Added item: $id:$title:$value\n";
	return $id;
}


sub ParseCatString {
	my $catstr = shift;
	my $uref = shift;
	my $cid = 0;
	my $parentcat = 0;

	# Is $catstr absolute or relative
	&trimblanks(\$catstr);
	my $cathome = $uref->{'cathome'};
	&addslashes(\$cathome);
	my $uid = $uref->{'id'};
	
	# if it doesn't start with a slash, set the users home category as parent
	if ($catstr !~ /^\//) {
		$parentcat = $uref->{'cathome'};
	}

	# if $catstr has no / chars, maybe is a handle
	if ($catstr !~ /\//) {
		# Lookup Handle
		# if successful return id
		# TODO
		$cid = &LookupCatByHandle($catstr, $parentcat, $userid);
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

		$cid = &LookupCatByHandle($catstr, $lastparentcat, $userid) 
			|| &LookupCatByName($catstr, $lastparentcat, $userid)
			|| &MakeCat($catstr, $lastparentcat, $userid);

#		push @catids, $cid;
		$lastparentcat = $cid if $cid;
print "For $catstr found $lastparentcat\n";
	}
	
	return ($lastparentcat || $parentcat);
}


sub LookupCatByHandle {
	my ($handle, $parentcat, $userid) = @_;
	$q = "select ID from handles where type='C' AND handle = ".$dbh->quote($handle).
		" AND ( (catid=0) OR (catid=$parentcat) OR (catid IS NULL)) ".
		" AND ( (userid=0) OR (userid=$userid) OR (userid IS NULL)) ";
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my ($id) = $sth->fetchrow_array;
print "found ID=$id from $q\n";
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
print "found ID=$id from $q\n";
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
	

sub writedata {
my ($uref, $from, $body) = @_;
open(F, ">/home/abra/data/test");
print F "user:",%$uref,"\n";
print F "From: $from\n\n",$body;
close F;
}

sub getuserfromemail {

	my $from = shift;
	my $uref = {};
	my $new_uref = {};
        $q = "select users.*,ab_users_emails.id,ab_users_cats.cathome,ab_users_cats.catlast from users, ab_users_emails,ab_users_cats where ab_users_emails.email = ".$dbh->quote($from)." and users.id = ab_users_emails.user_id and ab_users_cats.user_id = users.id";
;
print "Query is $q\n";
        my $sth = $dbh->prepare($q);
	if ($sth) {
  	      $sth->execute();
        	$new_uref = $sth->fetchrow_hashref;
print "Uref is $new_uref, Returned ",%$new_uref,"\n\n";
	}

	$uref->{'id'} = $new_uref->{'ab_users_emails.id'};
	$uref->{'username'} = $new_uref->{'login'};
	$uref->{'password'} = $new_uref->{'pw'};
	$uref->{'cathome'} = $new_uref->{'ab_users_cats.cathome'};
        $uref->{'catlast'} = $new_uref->{'ab_users_cats.catlast'}; 

	if (! $uref) {
		$uref = {};
print "Setting to anonymous";
		setanonymoususer($uref);
	}
	

	return $uref;
}

sub setanonymoususer {
	my $uref = shift;

	$uref->{id} = $ANONUSERID;
	$uref->{personid} = 0;
	$uref->{username} = 'anonymous';
	$uref->{password} = '';
	$uref->{cathome} = 0;
	$uref->{acl} = 0;
	$uref->{catlast} = 0;
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
