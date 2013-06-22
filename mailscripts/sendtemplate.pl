#!/usr/local/bin/perl

# Send template to user to be filled out and returned for processing
# by domail.pl script
#
# constructs template like so
#
#   cat: category-handle
#   title:  	
#   #%begin content:
#
#   #%end

BEGIN {
	$INCLUDE_DIR = '/w/abra/cgi';
	unshift(@INC, $INCLUDE_DIR);
}

use AbHeader qw(:all);
use AbUtils;
use AbMacros;
use CommandWeb;
use RCategories;
use Mysql;

# Hack for testing
if ($0 =~ /org/) {
	$DBNAME = 'rpub';
	$DBUSER = 'groots';
	$DBPASS = 'sqwert';
	$THISCGI = "http://qs.abra.info/cgi/org.pl";
} else {
	$DBNAME = 'rcats';
	$DBUSER = 'rcats';
	$DBPASS = 'meoow';
	$THISCGI = "http://qs.abra.info/cgi/ab.pl";
}

$INSTRUCTIONS = " For each category to be updated, reply to this message and \n".
	"enter lines starting with\n".
	"title: \n".
	"text: \n".
	"url: \n".
	"or other fields under the appropriate category.  To enter several lines \n".
	"of text, enclose in \n".
	"#%begin text \n".
	"#%end text\n".
	"markers.  Then just send mail.\n";

$debug = 1;
# Use MySQL (or DBI) to connect
$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');
$dbh = $obj->{'dbh'};

# for all users with emails and notify_ok = Y
my $q = "select user.id, person.email from user, person where user.id = person.id and user.notify_ok = 'Y'";
my $sth = $dbh->prepare($q);
$sth->execute();
my ($userid, $email);
print "Query is $q\n";
while (($userid, $email) = $sth->fetchrow_array) {

print "Found user $userid\n";

	# lookup list of categories user wants notifications of
	# Look for relations of type  SEND_UPDATE_TEMPLATE_TO
#
#	my @carray = ();
#	&AbUtils::get_cats_by_relation($userid, 'SEND_UPDATE_TEMPLATE_TO',\@carray);
#
#	foreach $ref (@carray) {	
#		# relation qualifier has frequency crontab style?  
#		# send today?
#		$freq = $ref->{'QUALIFIER'};
#	#TODO HERE - check if send today?
#
#		# create template from category (qualifer TYPES, allow url, content)
#	}
#
# For now just send every damn subcat
	my %templatehash = ();
	my $curcat = &AbUtils::getcatfromuserid($userid);
	my $abm = new AbMacros(catid=>$curcat);
	my $tref = &AbUtils::get_subcat_tree($curcat);
        @$tref = sort { $a->{'SUBCATPATH'} cmp $b->{'SUBCATPATH'} } @$tref;

my $SENDMAIL = "/usr/lib/sendmail -t";
my $lastErr = '';
open(MAIL, "| $SENDMAIL") || die("Cannot open pipe to $SENDMAIL\n");
print MAIL "From: abra\@abra.info\n";
print MAIL "To: $email\n";
print MAIL "Subject: abra update\n"; 
print MAIL "\n";
print MAIL $INSTRUCTIONS, "\n\n";
foreach my $a (@$tref) {
	$a->{'SUBCATPATH'} =~ s/\\/\//g;
	print MAIL 'cat: ',$a->{'SUBCATPATH'},"\n";
}
close MAIL;

        $templatehash{'CATLIST'} = $tref;
        $templatefile = 'tmplSendEmail.html';
	my $tmpstring = $abm->ProcessFile($templatefile);

# put this into an email
	&CommandWeb::OutputfromTemplateString($tmpstring,\%templatehash) || &ErrorExit("CommandWeb::OutputToWeb failed on $templatefile, string was $tmpstring, hash was ",%templatehash);
	
}

1;
