#!/usr/local/bin/perl 

#############################################################
# Module template for inclusion in the ABRA project
#
# Module name: abra.pm
#
# This module associates names, keywords, categories, users & other info with data objects
#
#    Mainly serves as a shim for Categories.pm, adds some assumptions about
#    structure of category hierarchy, types of data, ownership.
#
# How will this code
#
# - interact with other local modules/scripts (API)
#  
#       called by cgi or email handling script to associate keywords with URL
#	can do simple lookups and output the data into flat files for full text search
#	may be called by indexing script to write out all metadata
#
# - interact with External data (what formats read/written)
#
#	reads/writes to MySQL database using RCategories.pm
#	writes to flat files on request
#	read flat files and parse out meta info?
#
# - interact with humans (ie users; programmers can use API)
#	
#	does not have UI, but recognizes user handles
#
# - interact with remote programs/servers (communication protocols)
#
#	does not offer remote interface
#
# Run 'perldoc abra.pm' for more info.
#
# Author: Golda Velez
# Contact: gvelez@abra.info
# Home of this module: http://abra.info/modules/
# License: PPL licensed - see http://webglimpse.net/dev/ppl.txt for details
# Copyright Internet WorkShop, Golda Velez 2003 all rights reserved
#
##########################################
#
#  Methods:
#
# all may be called with reference to hash of inputs
#
#	new_item(Name, URL, [CatID], [Types], [Keywords])  returns ID
#	relate_item(ID,RELNAME,data)  data may be other ID or text string
#		RELNAME may be 'KEYWORDS' or user-defined string
#		ID must belong to active user, data may or may not
#
#	delete_item(ID)
#	categorize(ID, CatID)	      adds ID to CatID
#
# Categories
#    first byte = hierarchy ID
#    under $USER_DEFINED, next 3 bytes are UserID

# Relationships - first item in relationship must be owned by user creating or editing relation

# Users can only edit categories & items in their section

# May relate own categories to global ones if desired.  Option to import subcategories.
# ? is this good idea, or better to encourage items to go into global area?
# ? then need ownership of each item

# 
#  all get* routines return list of hashes
#
#	getbyname(Name, [UserId]) 
#	getbyURL(URL, [UserId])
#	getbyID(ID)
#	getbyKeyword(Keyword,[regexp_flag],[options],[UserId])
#	get(%hash(ID,Name,Keyword,UserId) all values optional)
#
#	getrelated(ID, RELNAME, [fields])

# future mod: ? relationships owned by user as well as items/
#      user may want to relate general item to things, not all users interested
#	add_type_data # adds to table of name Type
#	get_related_categories
###################################################### 

package abra;

BEGIN {
	unshift @INC "./Julian";
}

use Categories;


# For our purposes, URL may be (try to follow RDF spec)
#	http://...
#	ftp://...
#	file://...
#	dbi://dbname/tablename?SQL_String
#	text://text string here

# Constants - move to header file later

$DBNAME = 'ABRA';
$DBUSER = 'abra';
$DBPASS = 'test';
$DBHOST = 'localhost';

# Globals
$whoami = 0;
$dbobj = undef;

my $debug = 0;

1;

# We may have a userid, or may be global

# One database assumed to exist, with some data owned by us and some possibly by others
# Or no owner may be specified


sub new {
 	my $proto = shift;
 	my $class = ref($proto) || $proto;
 	my $self = {};
 	my %inp = @_;

	$whoami = $inp{'userid'} || 0;
	
	$dbobj = Categories->new(database => $DBNAME, user=>$DBUSER,pass=>$DBPASS,host=>$DBHOST);
}


# mainly used to get names from URL/ID, for writing into actual text file
# search by name & keyword is done using glimpse on text files
sub GetName{

}

sub GetKeywords{

}


sub LookupbyName {

}

# not implemented in db at this time
sub LookupbyKeyword {

} 




=head1 NAME

abra - routines for naming things

=head1 SYNOPSIS

        use abra;

	[subroutines here]

=head1 DESCRIPTION


=over

=item [subroutine]





