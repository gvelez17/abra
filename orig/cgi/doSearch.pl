#!/usr/local/bin/perl -T

#use CGI;

print "Content-type: text/html\n\n";

#$query = new CGI;

#@keywords = $query->keywords;
#@params = $query->param;

print "Doing search";
#print "Have @keywords and @params";

print "Raw ENV:\n<br>";
foreach $key (keys %ENV) {
	print "$key --> $ENV{$key}<br>";
}

$s = <STDIN>;
print "Raw input : $s\n<br>";

1;
