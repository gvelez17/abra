#!/usr/local/bin/perl

use File::Find;

# $File::Find::dir is the current directory name, 
# $_ is the current filename within that directory 
# $File::Find::name is the complete pathname to the file. 

find(\&wanted, ("/home/sites/iwtucson/www"));


sub wanted {

	print "examining $File::Find::name in $File::Find::dir ...\n";
 }
