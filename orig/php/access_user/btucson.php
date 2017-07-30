<?php 
include($_SERVER['DOCUMENT_ROOT']."/classes/access_user/access_user_class.php"); 

$page_protect = new Access_user;
// $page_protect->login_page = "login.php"; // change this only if your login is on another page
$page_protect->access_page(); // only set this this method to protect your page

if (isset($_GET['action']) && $_GET['action'] == "log_out") {
	$page_protect->log_out(); // the method to log off
}

if (isset($_GET['next_url'])) {
        $my_next_url = $_GET['next_url'];
} elseif (isset($_POST['next_url'])) {
        $my_next_url = $_POST['next_url'];
} elseif (isset($_SERVER['HTTP_REFERER'])) {
        $my_next_url = $_SERVER['HTTP_REFERER'];
} else {
	$my_next_url = '';
}

if ($my_next_url <> '') {
	header("Location: $my_next_url");
}

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>bTucson user home</title>
</head>

<body>
<h2><?php echo "Hello ".$_SESSION['user']." !"; ?></h2>
<p>You are currently logged in.</p>
<p>&nbsp;</p>
<p><A HREF="http://abra.btucson.com/cgi/ab.pl">My Categories</A></p>
<!-- Notice! you have to change this links here, if the files are not in the same folder -->
<p><a href="./update_user.php">Update user account</a></p>
<p><a href="./update_user_profile.php">Update user PROFILE</a></p>
<p><a href="/classes/access_user/test_access_level.php">test access level </a></p>
<?php if ($page_protect->access_level >= DEFAULT_ADMIN_LEVEL) { // this link is only visible for admin level user ?>
<p><a href="/classes/access_user/admin_user.php">Admin page (user / access level update) </a></p>
<?php } // end hide admin menu link ?>
<p><a href="<?php echo $_SERVER['PHP_SELF']; ?>?action=log_out&next_url=<?php echo $my_next_url?>">Click here to log out.</a></p>
</body>

</html>

