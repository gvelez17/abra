
<?php 

include('/w/abra/classes/access_user/access_user_class.php'); 

$new_member = new Access_user;
// $new_member->language = "de"; // use this selector to get messages in other languages

if (isset($_POST['Submit'])) { // the confirm variable is new since ver. 1.84
	// if you don't like the confirm feature use a copy of the password variable

	if (isset($_POST['ref_page'])) {
		$ref_page = $_POST['ref_page'];
	} else {
		$ref_page = '';
	}

	if (isset($_GET['next_url'])) {
        	$my_next_url = $_GET['next_url'];
	} elseif (isset($_POST['next_url'])) {
        	$my_next_url = $_POST['next_url'];
	} else {
        	$my_next_url = $ref_page;
	}

	$new_member->register_user($_POST['login'], $_POST['password'], $_POST['confirm'], $_POST['name'], $_POST['info'], $_POST['email'], $my_next_url); // the register method

} 
$error = $new_member->the_msg; // error message



?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>New User Registration</title>
<style type="text/css">
<!--
label {
	display: block;
	float: left;
	width: 150px;
}
-->
</style>
</head>

<body>
<H1><font color="red">Due to spammers posting inappropriate content, all registrations must be manually approved.  Please send a note to <img src="/imgs/bctct.png"/> after registering, explaining briefly why you want to post stuff to bTucson and what your username is.  We will enable you within a couple days.</font></h1>

<h2>Quick Registration Form 
<?php echo (isset($title)) ? "for $title" : ""; ?>
</h2>
<p>Please fill in the following fields (fields with a * are required).
An email will be sent to you to confirm your registration.  As soon as you confirm (by clicking on the link sent to your email), you will be able to start adding items to all public categories!</p>
<form name="form1" method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">

  <input type=HIDDEN name=next_url value="<?php echo $my_next_url?>">

  <input type=HIDDEN name="ref_page" value="<?php echo (isset($_SERVER['HTTP_REFERER'])) ? $_SERVER['HTTP_REFERER'] : ""; ?>">

  <input type=HIDDEN name="title" value="<?php echo (isset($title)) ? $title : ""; ?>">

  <label for="login">Choose a username:</label>
  <input type="text" name="login" size="12" value="<?php echo (isset($_POST['login'])) ? $_POST['login'] : ""; ?>">
  * (min. 6 chars.) <p>
  <label for="password">Choose a password:</label>
  <input type="password" name="password" size="6" value="<?php echo (isset($_POST['password'])) ? $_POST['password'] : ""; ?>">
  * (min. 4 chars.) <p>
  <label for="confirm">Confirm password:</label>
  <input type="password" name="confirm" size="6" value="<?php echo (isset($_POST['confirm'])) ? $_POST['confirm'] : ""; ?>">
  * <p>
<br>
  <label for="name"><b>Real name:</b></label>
  <input type="text" name="name" size="30" value="<?php echo (isset($_POST['name'])) ? $_POST['name'] : ""; ?>">
  <p>
  <label for="email">E-mail:</label>
  <input type="text" name="email" size="30" value="<?php echo (isset($_POST['email'])) ? $_POST['email'] : ""; ?>"> *
<br>
<i>(Use a real email address here, it will not be displayed on the site but the system has to have it to send you a confirmation mail.)</i>
  <p>
  <input type="submit" name="Submit" value="Register Now!">
</form>
<p><b><?php echo (isset($error)) ? $error : "&nbsp;"; ?></b></p>
<p>&nbsp;</p>
<!-- Notice! you have to change this links here, if the files are not in the same folder -->
<p><a href="<?php echo $new_member->login_page; ?>">Login</a></p>
<i>If you experience any problems with the registration process please <A HREF="http://goldavelez.org/iwork/iwork/dform2.html">Contact us here</A></i>
</body>
</html>
