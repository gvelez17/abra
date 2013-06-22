<?php 
include($_SERVER['DOCUMENT_ROOT']."/classes/access_user/ext_user_profile.php"); 
error_reporting (E_ALL); // I use this only for testing
$update_profile = new Users_profile;

$update_profile->access_page($_SERVER['PHP_SELF'], $_SERVER['QUERY_STRING']); // protect this page too.

$update_profile->get_profile_data();

if (isset($_POST['user_data'])) {
	$update_profile->update_user($_POST['password'], $_POST['confirm'], $_POST['user_full_name'], $_POST['user_info'], $_POST['user_email']); // the update method
} 
if (isset($_POST['profile_data'])) {
	$update_profile->save_profile_date($_POST['id'], $_POST['language'], $_POST['address'], $_POST['postcode'], $_POST['city'], $_POST['country'], $_POST['phone'], $_POST['fax'], $_POST['homepage'], $_POST['notes'], $_POST['field_one']); 
} 
$error = $update_profile->the_msg; // error message
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>Update page example</title>
<style type="text/css">
<!--
label {
	display: block;
	float: left;
	width: 120px;
}
-->
</style>
</head>

<body>
<h2>Update user information:</h2>
<p>This two forms are an example how to update the user and user-profile information <br>
(fields with a * are required).</p>
<form name="form1" method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
  <label for="login">Login:</label>
  <b><?php echo $update_profile->user; ?></b><br>
  <label for="password">Password:</label>
  <input name="password" type="password" value="<?php echo (isset($_POST['password'])) ? $_POST['password'] : ""; ?>" size="6">
  * (min. 4 chars.) <br>
  <label for="confirm">Confirm password:</label>
  <input name="confirm" type="password" value="<?php echo (isset($_POST['confirm'])) ? $_POST['confirm'] : ""; ?>" size="6">
  * <br>
  <?php 
  echo $update_profile->create_form_field("user_full_name", "Real name:", 30);
  echo $update_profile->create_form_field("user_email", "E-mail:", 30, true);
  echo $update_profile->create_form_field("user_info", "Extra info:", 50);
  ?>
  <input type="submit" name="user_data" value="Update (user)">
</form>
<hr>
<h3>User profile</h3>
<p>This form is not saved while saving data for the user account!</p>
<form name="form1" method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
  <?php 
  echo $update_profile->create_form_field("address", "Address:");
  echo $update_profile->create_form_field("postcode", "Postcode:", 10);
  echo $update_profile->create_form_field("city", "City:");
  echo $update_profile->create_country_menu("country", "Country:");
  echo $update_profile->create_form_field("phone", "Phone:");
  echo $update_profile->create_form_field("fax", "Fax:");
  echo $update_profile->create_form_field("homepage", "Homepage:");
  echo $update_profile->create_text_area("notes", "Some text...");
  // You have to use the same field like the variable in the class 
  echo $update_profile->create_form_field("field_one", "Userfield 1:");
  echo $update_profile->language_menu("Language");
  ?>
  <input type="hidden" name="id" value="<?php echo  $update_profile->profile_id; ?>">
  <input type="submit" name="profile_data" value="Save (profile)">
</form>
<p><b><?php echo (isset($error)) ? $error : "&nbsp;"; ?></b></p>
<p>&nbsp;</p>
<!-- Notice! you have to change this links here, if the files are not in the same folder -->
<p><a href="<?php echo $update_profile->main_page; ?>">Main</a></p>
</body>
</html>
