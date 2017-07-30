<HTML>
<BODY>
<?

$connection = mysql_connect("localhost","rcats","meoow");
$db = mysql_select_db("rcats");
$id = $_GET["id"];
if (! $id ) {
	$id = $_GET["ID"];
}
$uid = $_GET["uid"];
if (! $uid ) {
	$uid = $_GET["UID"];
}
$handle = $_GET["handle"];
if (! $handle ) {
	$handle = $_GET["HANDLE"];
}


$table = $_GET["table"];
if (! $table) {
	$table = $_GET["TABLE"];
}
$fields = $_GET["fields"];
if (! $fields) {
	$fields = $_GET["FIELDS"];
} 
if (! $fields) {
	$fields = 'content,type';
}

if ($id) {
	$q = "SELECT $fields from $table where ID = $id";
}
else {
	if ($uid) {
		$q = "SELECT $fields from $table where UID = $uid";
	} 
}
print "<!-- query is $q -->\n";

$sth = mysql_query($q, $connection);

while ($row = mysql_fetch_row($sth)) {
	$content = $row[0];
	$type = $row[1];
	if (($type == 'text')||($type == '')) {
		$content = preg_replace("/(https?:\/\/[^\s]+)/","<A HREF='$1'>$1</A>",$content);	

		# preserve hard returns, or try to
		$content = preg_replace("/\n/","<p>\n",$content);

	}
	print($content.'<hr>');
}

mysql_close($connection);

?>
</BODY>
</HTML>
