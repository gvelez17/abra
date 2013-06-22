package AbSecure;

use AbHeader qw(:all);
use PHP::Session;
use CGI::Lite;

local *obj = *main::obj;
local *dbh = *main::dbh;

$USER_VAR = 'user';
$session_name = 'PHPSESSID';

$cgi_lite = new CGI::Lite;
$cookies = $cgi_lite->parse_cookies;

# state variables - set only if not set
# do NOT use 'my' - we want to be able to set these externally
$USE_THIS_CGI = $THISCGI if (! $USE_THIS_CGI);

$CUR_USER = '' if (! $CUR_USER);	# Current logged in user (verified)

$CUR_USERID = 0 if (! defined($CUR_USERID));  # now using $main::userid
					 # but calling progs may set differently

$VERIFIED_BY = '' if (! $VERIFIED_BY);	# How verified: may be one of
					#  HTACCESS
					#  ACCESS_USER_COOKIE
					#  (in future - DRUPAL?)
# Users actually could login first via htaccess as a group user,
# then via cookie as an individual.  The cookie login overrides for now.
1;

## put vars here if we have scoping issues
#sub new {
#        my $class = shift;
#        my $self = {};
#        bless $self, $class;
#        return $self;
#}


# Later maybe separate out security functions into separate module.  Here for now.
sub get_username {

	my $username = '';
	# If the user had their own security, we get REMOTE_USER variable
#print "Security check...";
	if (defined $ENV{'REMOTE_USER'}) {
		$username = $ENV{'REMOTE_USER'};
		$VERIFIED_BY = 'HTACCESS';
		$CUR_USER = $username;
		return $username;
	}
	
	# For right now either/or. Later maybe provide access by both names
#print "Checking for cookies...";
	if ($cookies->{$session_name}) {
#print "We have a session...";
		my $session = PHP::Session->new($cookies->{$session_name}, { create => 1 });
		$username = $session->get($USER_VAR);
		$VERIFIED_BY = 'ACCESS_USER_COOKIE';
#print "Username is $username<p>\n";
	} 
	
	$CUR_USER = $username;
	
	return $username;
}

sub get_userid {
	my $username = shift || $CUR_USER;

local *obj = *main::obj;
local *dbh = *main::dbh;

	if (! $username) {
		$username = get_username;
	}
	
	my $q = "select id from users where login = '$username'";
        my $userid = $dbh->selectrow_array($q);
	
	$CUR_USERID = $userid;
	return $userid;
}

	








# This is not very secure - someone else could create PHPSESSID with 'user' var
# not external hacker because this is server side.  
# But someone else on the server could, so it 
# is subject to hack by any user on the server who can create php files.
# probably need to check domain too
