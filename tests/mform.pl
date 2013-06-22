#!/usr/local/bin/perl
#
use DBI;
use HTML::DBTable;
#3306
my $dbh = DBI->connect("DBI:mysql:rcats:localhost","rcats",'meoow') || die("Failed to connect to db\n");
my $pd = new HTML::DBTable() || die("Failed to init HTML::DBTable object\n");
$pd->dbh($dbh);
$pd->tablename('person');
$pd->html(tablename=>'person');

1;
