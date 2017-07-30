#!/usr/local/bin/perl

# this is just for urlencode - get it from more standard place TODO ?
use PCGI qw(:all);

$qstr = 'http://revyu.com/sparql/';

$astr = <<"END_QUERY_STRING";

PREFIX rev: <http://purl.org/stuff/rev#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?thing ?review
WHERE
{
 ?thing rdfs:label "revyu.com" .
 ?thing rev:hasReview ?review .
}
 
END_QUERY_STRING

$qstr .= '?query=';
$qstr .= urlencode($astr);

print "Query is: \n ",$qstr,"\n";

`wget $qstr`;

1;
