#!/usr/local/bin/perl -T
#
# modified from http://code.google.com/apis/adsense/developer/samples/perl/CreateAccount.pl.txt
# the original was Copyright 2005 Google Inc.  All rights reserved.
# modifications copyright 2007 Golda Velez.

BEGIN {
	unshift @INC, "/w/abra/lib";
}

BEGIN {
	use SOAP::Lite;

	use AdUtils;

	# SOAP Headers
	$developerEmail = 'adsense@iwhome.com';
	$developerPassword = 'Ping17pong';
#	$developerEmail = 'developer1@google.com';
#	$developerPassword = 'devpass';

# For now we produce output
print "Content-type: text/html\n\n";

print '<head><BASE HREF="http://btucson.com/">
<link href="/index.css" rel="styleSheet" type="text/css">
<link rel="shortcut icon" href="/favicon.ico" >
</head>';
print '<body><h1>The <A HREF="http://btucson.com/">bTucson.com</A> RevenueShare Program</h1>
<table><tr><td><A HREF="http://abra.info/"><img src="/imgs/abracat.png" alt="Powered by ABRA" border=0 valign=center></A></td><td><h2>Results of your request: </H2></td></tr></table>';


print "Doing the google stuff...";
######### Google stuff, ignore ###################################3
# The namespace used for API headers.
$namespace = "http://www.google.com/api/adsense/v2";

# Set up the connection to the server.
$wsdl_url = "https://www.google.com/api/adsense/v2/AccountService?wsdl";
#$wsdl_url = "https://sandbox.google.com/api/adsense/v2/AccountService?wsdl";
$accountService = SOAP::Lite->service($wsdl_url);

# Uncomment this line to display the XML request/response.
#$accountService->on_debug( sub { print @_ } );

# Disable autotyping.
$accountService->autotype(0);

# Register a fault handler.
$accountService->on_fault(\&AdUtils::faulthandler);

@headers =
  (SOAP::Header->name("developer_email")->value($developerEmail)->uri($namespace)->prefix("impl"),
   SOAP::Header->name("developer_password")->value($developerPassword)->uri($namespace)->prefix("impl"),
   SOAP::Header->name("client_id")->value("ignored")->uri($namespace)->prefix("impl"));
########################################################################

}

BEGIN {
        unshift(@INC, "/w/abra/lib");
}
use AbHeader qw(:all);
use Abra;
use CGI qw(:cgi-lib);
use CommandWeb;
use AbSecure;
use AbAcct;

# Use MySQL (or DBI) to connect
$abra = new Abra;

if (!$dbh) {
        print "Error - cannot get database handle\n";
        exit;
}


#print "Trying to create account...<br>";


#print "Going to get input now";

# Get our form inputs
ReadParse(\%in);
$userlogin = $in{'login'};
#$agreed = $in{'agree'};

$input_email = $in{'email'};

#if (! $agreed) {
#	print "Sorry, we can't set up the account unless you agree to the program policies.";
#	print "Press the back arrow to return to the form and make sure to check the 'agree' box";
#	exit(0);
#}	

# Get the user's email
my $macct = new AbAcct($userlogin);

# It doesn't matter if they already have a google client id - just swap it
## Do they already have a Google client id?
my $existing_google_client_id = $macct->get_google_client_id();

my $uemail = $input_email || $macct->{'email'};
if (! $uemail) {
	print "Sorry, unable to set up account.  It seems you didn't enter an email address on the form and we don't appear to have a valid email address on file for you. You may need to register a new account at <A HREF='http://btucson.com'>bTucson.com</A>";
	exit(0);
}

my $homeurl = 'http://bTucson.com/users/'.$userlogin;


#print "Got user data...<br>\n";

# Create the parameters.
$loginEmail = $uemail;
$entityType = 'Individual';
$websiteUrl = $homeurl;
$websiteLocale = 'en';
$usersPreferredLocale = 'en_US';
$emailPromotionPreferences = "false";
$synServiceTypes = ["ContentAds"];
$hasAcceptedTCs = "true";

#print "About to call Google...<br>\n";

# Call the web service method.
my $synServiceData = $accountService->createAdSenseAccount($loginEmail,
  $entityType, $websiteUrl, $websiteLocale, $usersPreferredLocale,
  $emailPromotionPreferences, $synServiceTypes, $hasAcceptedTCs,
  @headers);

# Extract and print results.
if (ref($synServiceData) eq "ARRAY") {
  $synServiceId = ($synServiceData)->[0]->{"id"};
  $synServiceType = ($synServiceData)->[0]->{"type"};
} else {
  $synServiceId = ($synServiceData)->{"id"};
  $synServiceType = ($synServiceData)->{"type"};
}

# Get code snippet
print "Generating the ad code...";
my $code_snippet = &AdUtils::generate_ad_code($synServiceId);

if ($existing_google_client_id) {
	$macct->update_google_clientid($synServiceId,$code_snippet,$uemail,'n');
} else {
	$macct->add_google_clientid($synServiceId,$code_snippet,$uemail,'n');
}

print "<HTML><BODY>Success! Your AdSense account has been created.  <b>An email with instructions for activating your new account has been sent to <i>$uemail</i></b>.  To receive advertising revenue for your writing, please <UL><LI><b>Follow the instructions in the email you receive</b> <LI>Make sure you are logged in when submitting articles <LI> Follow good writing practices: for reporting, be detailed and accurate and site your sources.  Make sure you are submitting to an appropriate category, and check the 'Feature' box if you would like your article considered for a site-wide feature. </UL>  <p><A HREF='http://bTucson.com/'>Return to bTucson.com</A> * <A HREF='http://bTucson.com/users/$userlogin'>View My Articles</A> <p><small>Technical note:  your new account has an associated " .
  $synServiceType . " syndication service with id " . $synServiceId . "</small>";

if ($existing_google_client_id) {
	print "<p><small>Your account previously had the associated syndication service id $existing_google_client_id.  That id has now been replaced with the new one.</small>";
}


print '<p><hr><A HREF="http://bTucson.com/">back to bTucson.com</A> &nbsp;&nbsp; <A HREF="/adsignup.php">back to the RevenueShare Signup page</A>';
print "</BODY></HTML>\n";

1;






