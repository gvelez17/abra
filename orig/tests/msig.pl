#!/usr/local/bin/perl

BEGIN {
	unshift @INC, '/w/abra/lib';
}

use Abra;
use SemSig;

&SemSig::get_semsig_by_uri("http://abra.btucson.com/");

1;
