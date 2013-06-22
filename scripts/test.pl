#!/usr/local/bin/perl

BEGIN { 
	unshift(@INC,'/w/abra/cgi'); 
}
use AbUtils;

$CATID = 306;

$catref = &AbUtils::get_cat($CATID);

$link = &AbUtils::make_nice_link($catref, '',0);

print $link;

1;
