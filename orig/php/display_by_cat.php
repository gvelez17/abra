<HTML>
<BODY>
<?

include "abra.php";

$connection = mysql_connect("localhost","rcats","meoow");
$db = mysql_select_db("rcats");
$cid = $_GET["cid"];
if (! $cid ) {
	$cid = $_GET["CID"];
}
if (! $cid) {
	$cid = $_GET["_CATID"];
}


if ($cid) {
	print "<table>";
	output_catitems_by_cid($cid,"<tr><td>|NAME|<br>|short_content|</td></tr>",4,"</td><td>");
	print "</table>";

}
mysql_close($connection);

?>
</BODY>
</HTML>
