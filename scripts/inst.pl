#!/usr/bin/perl

use RCategories;

$DBNAME = 'groots';
$DBUSER = 'groots';
$DBPASS='sprout';

$obj = RCategories->new(database => $DBNAME, user => $DBUSER, pass => $DBPASS, host => 'localhost');
1;
