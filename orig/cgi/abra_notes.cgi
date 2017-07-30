#!/usr/bin/perl -wT

unshift @INC, '/w/abra2/cgi';
use AbraNotes;
use Data::Dumper;

my $ab_app = AbraNotes->new();
$ab_app->run();

1;
