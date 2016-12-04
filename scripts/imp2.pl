#!/usr/bin/perl

# utils

BEGIN {
      unshift (@INC, '/w/abra/cgi');
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
#       $DBNAME = 'rpub';
#       $DBUSER = 'groots';
#       $DBPASS = 'sqwert';
#       $THISCGI = "http://qs.abra.btucson.com/cgi/org.pl";
#} else {
        $DBNAME = 'rcats';
        $DBUSER = 'rcats';
        $DBPASS = 'meoow';
        $THISCGI = "http://abra.btucson.com/cgi/ab.pl";
        $ADMINUSER = 1;

#}
$debug = 1;

$userid = 1;

# Use MySQL (or DBI) to connect
$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');
$dbh = $obj->{'dbh'};

# Example listing to parse

#<b><A HREF="http://www.joyfulcelebrationsinc.com/">Joyful Celebrations, Inc.</A></b>
# -- <i><A HREF="mailto:weddings@joyfulcelebrationsinc.com">weddings@joyfulcelebrationsinc.com</A></i><br>
#Phone: 520-884-8898<br>
#Address: P.O. Box 66022, Tucson, AZ 85728<br>
#FAX: 520-770-9671<br>
#Professional bridal consultant, wedding coordinator, and
#     planner. <br>
$file = $ARGV[0];

print "PRocessing $file\n";

open F,$file;
@lines = <F>;
close F;

$bizname = '';
$bizurl = '';
$bizph = '';
$bizaddr = '';
$bizfax = '';
$bizdesc = '';
$bizemail = '';

foreach $line (@lines) {
	
	if ($line =~ /<b><A HREF="([^"]+)">([^<]+)</) {

		&add_last_biz;		

		$bizurl = $1;
		$bizname = $2;
		$bizph = '';
		$bizaddr = '';
		$bizfax = '';
		$bizdesc = '';
		$bizemail = '';
		$needdesc = 1;

		$bizurl =~ s/\/$//;
	}
	
	elsif ($line =~ /mailto:([^"]+)"/) {
		$bizemail = $1;
	} elsif ($line =~ /Phone: ([^<]+)</) {
		$bizph = $1;
	} elsif ($needdesc && ($line !~ /Address:/)  && ($line !~ /FAX:/) && ($line !~ /^\s+$/) ) {
		$bizdesc .= $line;
		if ($bizdesc =~ /<br>/) {
			$needdesc = 0;
		}
	}
}


1;

sub add_last_biz {
#	print "Would add".
#		$bizname.":".
#		$bizurl.":".
#		$bizph.":".
#		$bizemail.":".
#		$bizdesc;


	$q = "select * from rcatdb_items where name = ".$dbh->quote($bizname).
                        " or url = ".$dbh->quote($bizurl);
	$sth = $dbh->prepare($q);
	$sth->execute;
	$res = $sth->fetchrow_hashref('NAME_uc');

#print "looking for $q, result was $res->{'NAME'}\n";	
	if ($res->{'NAME'}) {

		print "$bizname FOUND in db\n";
		$id = $res->{'ID'};
		$bizdesc =~ s/\s+/ /g;
	#	$bizdesc =~ s/\\r\\n/ /g;
	#	$bizdesc =~ s/\\n/ /g;
		$bizdesc = $dbh->quote($bizdesc);

print "adding desc: $bizdesc\n";
		$bizurl = $dbh->quote($bizurl);
		$q1 = "update rcatdb_items set short_content = $bizdesc where id = $id";
		$dbh->do($q1);
	
		$q2 = "update rcatdb_items set url = $bizurl where id = $id and (url is NULL or url = '')";
		$dbh->do($q2);

		$qrec = "update rcatdb_items set effective_date = '2006-01-02' where id = $id";
		$dbh->do($qrec);

		$q3 = "update ab_biz_org set  email = ".$dbh->quote($bizemail)." where id = $id and email is NULL";
		$dbh->do($q3);
	} else {
		print "$bizname NOT found in db, adding \n";
	
		$bizname = $dbh->quote($bizname);
		$bizurl = $dbh->quote($bizurl);
		$bizdesc = $dbh->quote($bizdesc);

		$q1 = "insert into rcatdb_items set cid = 306, security_level = 100, name = $bizname, url = $bizurl, short_content = $bizdesc";
		$dbh->do($q1);
	
		my ($newid) = $dbh->selectrow_array("select id from rcatdb_items where cid = 306 and name = $bizname");

		if ($newid) {
			$q2 = "insert into ab_biz_org set id = $newid, addr = ".$dbh->quote($bizaddr).",email = ".$dbh->quote($bizemail).",phone = ".$dbh->quote($bizph);
			$dbh->do($q2);
		} else {
			print "Insert FAILED on $bizname query was $q1\n";
		}

	}

}
