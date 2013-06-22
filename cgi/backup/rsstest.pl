#!/usr/local/bin/perl

use XML::RSS::Tools;

  my $rss_feed = XML::RSS::Tools->new;
  $rss_feed->rss_uri('http://www.kold.com/Global/category.asp?C=5166&clienttype=rss');
  $rss_feed->xsl_file('/inc/rss_transform.xsl');
  $rss_feed->transform;
  print $rss_feed->as_string;
