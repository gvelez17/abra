#!/usr/local/bin/perl

# Hack to read template, field defs, create output
BEGIN {
	unshift(@INC,'/w/abra/cgi');
}
use CommandWeb;

if ($#ARGV != 2) {
	print "Usage:\n\trunt.pl [languagefile] [templatefile] [outputfile]\n\n";
	exit(0);
}

$langfile = $ARGV[0];
$tmplfile = $ARGV[1];
$outfile = $ARGV[2];


%vdefs = ();
&CommandWeb::BuildHashFromFile(\%vdefs, $langfile, '%%','%%:\s*');

$CommandWeb::aa = '%%';
$CommandWeb::zz = '%%';

&CommandWeb::OutputToFile($tmplfile, $outfile, \%vdefs);

print "Done.";

1;
