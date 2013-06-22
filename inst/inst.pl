#!/usr/bin/perl

# builds basic rcategories structure
# db, user and pass must already exist with appropriate permissions

BEGIN {
	unshift @INC,"../cgi";
}
use RCategories;

$DBNAME = 'wgsite';
$DBUSER = 'wguser';
$DBPASS='becker';

$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');

# add basic structure
`mysql $DBNAME -u$DBUSER -p$DBPASS < tables.sql`;

# add appropriate modules - ie persons, jobs, events, products, etc

1;
