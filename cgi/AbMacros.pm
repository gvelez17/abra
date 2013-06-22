#!/usr/local/bin/perl -T

package AbMacros;

# Built-in macros for preprocessing templates.  Feel free to add your own.

# Each AbMacros object may know the current item id, category

# call as

#	new AbMacros(%varhash)  where %varhash should have at least itemid, catid
#	$resultstring = abm->ProcessFile($filename)
#
#	Macros are defined explicitly in the ExpandMacro subroutine
#
#	Files to process can contain variables of the form
#
#		[% macroname %]
#
# or		
#
#		[% TYPE:tablename:field %]
#
# (names of macros should not contain : char or begin with 'TYPE')


BEGIN {
	use AbHeader;
	use AbUtils;
}

my $REVISION = '$Id $';
my $debug = 0;

local *obj = *main::obj;
local *dbh = *main::dbh;

# Our markers
# Do not use "my" for these package vars; we want them externally accessible
$aa = '\[\%';   $AA = '[%';
$zz = '\%\]';   $ZZ = '%]';

1;

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	my %args = ( 
		itemid => 0,
		catid => 0,
		@_
	);
	foreach my $key (%args) {
		$self->{$key} = $args{$key};
	}
	return $self;
}
	

sub ProcessFile {
	my $self = shift;
	my $templatefile = shift;
	my $retstring = '';

       	if (!open(INPUT, $templatefile)) {
       		return '';
	}
	while (<INPUT>) {
	
	        # Replace straightforward [%MACRONAME%] type variables
                s/$aa\s*([a-zA-Z0-9_]+)\s*$zz/$self->ExpandMacro($1)/ge;	

		# Deal with [%TYPE:tablename:field%] lookups
		s/$aa\s*TYPE:([a-zA-Z0-9_]+):([a-zA-Z0-9_]+)\s*$zz/$self->LookupField($1,$2)/ge;
		# that's all we do for now
		$retstring .= $_;
	}
	close INPUT;
	
	return $retstring;
}



sub ExpandMacro {
	my $self = shift;
	my $macro = shift;

	my $s = '';
	
	if ('browse' eq $macro) {
		$s = $thiscgi.'?_CATID='.$self->{catid}.'&NEXTPAGE=Browse';
	}
	
	return $s;
}


sub LookupField {
	my $self = shift;
	my $tablename = shift;
	my $fieldname = shift;

	local *dbh = *main::dbh;
	my $q = "select $fieldname from $tablename where id = ".$self->{itemid};
	my ($value) = $dbh->selectrow_array($q);
	if (!defined($value)) {
		$value = '';
	}
	return $value;
}





# all arrays have optional FMT_BEGIN, FMT_END
#
# ITEM: ID/ITEMID, ITEMNAME, ITEMVALUE, CATID, LINK, SHORT_CONTENT, DEL_ITEM
#	RELATED_LINKS
#	TABLE_LINKS
# 	RELATIONS : NAME
#
# CATEGORY: ID/CATID, CATNAME, CATPATH
#	CATITEMS
# 	SUBCATS: ID, NAME, VALUE
# 	CATRELATIONS: RELATION, NAME
#
# CATLIST
#
# HANDLE
