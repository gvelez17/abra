package Abra;

# base class for all Abra objects
# deals with connecting to db
# in future may enumerate types & relations..
#  and have rules for how categories,items have to relate
# may also deal with security and wrap some DBI calls
# right now security is thru AbSecure

BEGIN {
        $AB_LIB_DIR = '/w/abra/cgi';    # have to know this before use

        unshift(@INC, $AB_LIB_DIR);
}

use AbHeader;
use DBI;

# dbh is a global exported from AbHeader

sub new {

        my $class = shift;
	my $self = {};
	bless $self, $class;

        $dbh = DBI->connect("DBI:mysql:$DBNAME",$DBUSER, $DBPASS);

	return $self;
}

1;
