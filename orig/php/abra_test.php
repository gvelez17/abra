<?

global $ITEM_TABLE;	# in case abra.php is included in a larger script
$ITEM_TABLE = 'rcatdb_items';

function abra_connect () {
	$sql_link = mysql_connect("localhost","rcats","meoow");
	mysql_select_db("rcats");
}

function output_catitems_by_cid($cid, $format, $cols, $separator) {

	$catitems = array();
	get_catitems ($cid, $catitems);
	output_array($catitems, $format, $cols, $separator);
}

function output_catitems($handle, $format, $cols, $separator) {

	//TODO: resolve ambiguous handles
	$cid = resolve_handle($handle);

	output_catitems_by_cid($cid, $format, $cols, $separator);
}

function mysqltimetodate ($timestamp) {
	$q = "select date_format('$timestamp','%m/%d/%y')";
	$result = mysql_query($q) or print("Error: ".mysql_error()." query was $q");
	list ($date) = mysql_fetch_row($result);
	return $date;
}

//#############################################################
function resolve_handle($handle) {

	$esch = mysql_real_escape_string($handle);
	$q = "select ID, TYPE from handles where handle = '$esch'";
	$result = mysql_query($q);
	list($id, $type) = mysql_fetch_row($result);
	return $id;
}


//#############################################################
function output_array($catitems, $format, $num_columns, $column_separator) {

	# Set Number of Columns to sensible value if undefined
	if (! $num_columns) {
		$num_columns = 1;
	}

	preg_match_all('/\|([^\|]+)\|/', $format, $matches);

	$numitems = count($catitems);

	$column_width = (int) $numitems / $num_columns;  # integer division

	$j = 0;
	foreach ($catitems as $ref) {
print "<!-- ID: ".$ref['ID'].$ref['id']." -->";
		$line = $format;
		foreach ($matches[1] as $key) {
			$rvalue = $ref[$key];
			$line = preg_replace("/\|$key\|/", $rvalue, $line);
		}
		$line = preg_replace('/\|([^\|]+)\|/','',$line);
		print $line;
		$j++;

		if ((($j % $column_width) == 0) && ($j != 0) && ($numitems - $j >= $column_width)) {
			print $column_separator;
		}
	}
	return '';
}


//###################################################################
// returns all subcategories of given category as array of hashes
function get_catitems($curcat, &$items) {
	global $ITEM_TABLE;

// return array of hashes w/ID,NAME,VALUE,QUALIFIER	
//	@$itemref = $obj->find('search'=>$curcat,'by'=>'CID','sort'=>'NAME','filter'=>'ITEMS','multiple');

	$q = "select * from $ITEM_TABLE where CID = $curcat order by ENTERED desc";
	get_query_results($items, $q);

// values->urls if match
	foreach ($items as $key => $val) {
		$items[$key]["URL"] = $items[$key]["VALUE"];

		$items[$key]["LINK"] = '<A HREF="'.$items[$key]["URL"].'">'.$items[$key]["NAME"].'</A>';
		// SOURCE, DATE	
		$items[$key]["DATE"] = mysqltimetodate($items[$key]["ENTERED"]);
		array ($types);
print "Item ".$items[$key]["ID"]." ";
		get_types($types, $items[$key]['QUALIFIER']);
		if ($types) {
			get_type_data($types, $items[$key], $items[$key]["ID"]);
		}

	}
	//TODO use proper URL matching

}


function safe_mailto ($email) {
	$parts = preg_split("/\@/",$email);
	$jstring = $parts[0]."'+unescape('%40')+'".$parts[1];
	$retstring = "<script>document.write('<A HREF=mai'+'lto:$jstring>$jstring</A>');</script>";
print "\n<!-- $retstring -->\n";
	return $retstring;
}

function get_types(&$types, $qual) {
print "Checking $qual for types...";
	if (preg_match("/TYPES?:([^\s]+)/", $qual, $matches)) {
		$types = preg_split("/,/",$matches[1]);
print "Found types from $qual<p>\n";
	}
}

function get_type_data(&$types, &$href, $id) {

	foreach ($types as $table) {
		$q = "select * from $table where ID = $id";
		$result = mysql_query($q) or next;
//print("Error: ".mysql_error()." query was $q");
		$row = mysql_fetch_array($result,MYSQL_ASSOC);
		if ($row) {
			foreach($row as $key => $val) {
				$href["$table:$key"] = $val;		
print("Assigning $val to $table : $key<br>\n");
			}
		}
		mysql_free_result($result);
	}
}


function get_query_results(&$href, $q) {
	$result = mysql_query($q) or print("Error: ".mysql_error()." query was $q");
	while ($row = mysql_fetch_array($result,MYSQL_BOTH)) {
			$href[] = $row;
	}
	mysql_free_result($result);
}

                                                             


?>
