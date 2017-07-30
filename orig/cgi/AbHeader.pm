package AbHeader;

require Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

@ISA = qw(Exporter);

$VERSION = "0.0.1";

###################################################################
# General use constants - imported automatically (plus one variable - lastError)
#
my @GENERAL = qw ($DBNAME $DBUSER $DBPASS @ABTYPES $ABHOME $ABTEMPLATE_DIR $DISPLAY_URL $DISPLAYPHP @MONTHS $ITEMTYPE $CATTYPE $RELTYPES $HAS_SUBCAT $IS_SUBCAT_OF $IS_URL $IS_ABRAURL
 $IS_HANDLE $IS_STRING $ITEM_TABLE $CAT_TABLE $RCAT_TABLE $RITEM_TABLE $THISCGI $BLOGCGI 
 $DEFAULT_SECURITY_LEVEL $PUBLIC_ACCESS_LEVEL $OWNER_ACCESS_LEVEL $FRIEND_ACCESS_LEVEL_DEFAULT $USERDEFINED_CAT $ADMIN_USERID);

my @RELVARS = qw ($DEFAULT_TEXT_RELATION $DEFAULT_RELATION %RELATIONS);

@MONTHS = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

$ABHOME = '/home/abra';
$ABTEMPLATE_DIR = '/home/abra/templates';
$THISCGI = "http://abra.btucson.com/cgi/ab.pl";
$BLOGCGI = "http://abra.btucson.com/cgi/blogview.pl";
$DISPLAY_URL = "http://abra.btucson.com/php/display.php";
$DISPLAYPHP = '/php/display.php';  #Generic display table script
$DBNAME = 'rcats';
$DBUSER = 'rcats';
$DBPASS = 'meoow';

# This probably should be parsed from DB rather than hardcoded
$USERDEFINED_CAT = 11;

$ADMIN_USERID = 1;

# Security related constants ; may be applied to read or write privileges 
# 'security_level' = read ; 'write_security_level'
$OWNER_ACCESS_LEVEL = 100;	# normalize to 100 - this is arbitrary
$PUBLIC_ACCESS_LEVEL = 0;	# Viewable by the anonymous public
$ANYUSER_ACCESS_LEVEL = 10;	# Logged in, but possibly unknown user
$ABRAUSER_ACCESS_LEVEL = 20;	# Logged in, registered, but we don't know them
$FRIEND_ACCESS_LEVEL_DEFAULT = 50;	# for very simple public/friends/private access scheme				  # 50-99 check friends' access level
$DEFAULT_SECURITY_LEVEL = $OWNER_ACCESS_LEVEL;



# db-specific constants - this should be editable by administrator

# types that may be applied to a category - ie user defined or prepackaged
# tables in the database.  In future maybe have types other than db tables?
@ABTYPES = (
	{'TABLENAME'=>'content',
	 'HELP'=>'For categories that will have associated text content'},
	{'TABLENAME'=>'jobs',
	 'HELP'=>'Built-in type for job listings'},
	{'TABLENAME'=>'person'},
	{'TABLENAME'=>'volunteer'},
	{'TABLENAME'=>'user',
	 'HELP'=>'Built-in type managing logins to this system'},
	{'TABLENAME'=>'metadata'}
);

# structural constants
$DEFAULT_TEXT_RELATION = 'MORE_INFO';
$DEFAULT_RELATION = 'LIKE';
$ITEMTYPE = 'I';
$CATTYPE = 'C';
$RELTYPES = {
	'I' => 'ITEM',
	'C' => 'CATEGORY'
};
$HAS_SUBCAT = 'HAS_SUBCAT';		# just in case we change these
$IS_SUBCAT_OF = 'IS_SUBCAT_OF';

$IS_URL = 1;
$IS_ABRAURL = 2;

$IS_HANDLE = 4;
$IS_STRING = 5;

$ITEM_TABLE = "rcatdb_items";
$CAT_TABLE = "rcatdb_categories";
$RCAT_TABLE = "rcatdb_rcats";
$RITEM_TABLE = "rcatdb_ritems";

%RELATIONS = (	# in future may have description of each, alternate names
	 'LIKE' => {'REVERSE' => 'LIKE',
	  'NICENAME' => 'Is similar to'},
	 'HAS_SUBCAT'=> {'REVERSE'=>'IS_SUBCAT_OF',
	   'NICENAME' => 'Link to subcategory'},
	 'IS_SUBCAT_OF' => { 'REVERSE'=> 'HAS_SUBCAT', 
	   'NICENAME' => 'Belongs to the category'},
	 'HAS' => {},
	 'IS_KIND_OF' => {},
	 'EXAMPLE_OF' => { 'REVERSE'=> 'SEE_EXAMPLE'},
	 'SEE_ALSO' => {},
	 'MORE_INFO'=> {
 	   'NICENAME' => 'Read more...'},
	 'COMMENT' => {},
	 'NOTE' => {},
	 'WHERE'=> {},
	 'WHEN' => {},
	 'WHY' => {},
	 'HOW' => {},
	 'RECOMMENDS' => { 'REVERSE'=>'RECOMMENDED_BY' },
	 'HOME' => {
	  	'NICENAME' => 'Home page or handle'},
	 'SAME_AS' => {},
	 'SEND_UPDATE_TEMPLATE_TO' => { 
		'REVERSE'=>'WANTS_UPDATE_TEMPLATE_FOR',
		'DESCRIPTION'=>'Categories to send users templates to update by email', 
		'QUALIFIED_BY'=>'Frequency' }
);





###################################################################


@EXPORT = ( @GENERAL );
@EXPORT_OK = ( @RELVARS, @GENERAL );

%EXPORT_TAGS = (
    'all'      => [ @EXPORT_OK ],
    'relations'   => [ @RELVARS ],
    'general'  => [ @GENERAL ]
);

1;
