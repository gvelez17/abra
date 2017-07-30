<?

global $ITEM_TABLE;	# in case abra.php is included in a larger script
global $CAT_TABLE;
$ITEM_TABLE = 'rcatdb_items';
$CAT_TABLE = 'rcatdb_categories';

function abra_connect () {
	$sql_link = mysql_connect("localhost","rcats","meoow");
	mysql_select_db("rcats");
}

function output_all_subcatitems_by_cid($cid, $format, $cols, $separator) {

	$catitems = array();
	get_all_subcatitems ($cid, $catitems);
	output_array($catitems, $format, $cols, $separator);
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

function default_display_by_cid ($cid,$tablehead,$tablefoot) {
	abra_connect();

	if (! $cid) {
		return;
	}
	if (! $tablehead) {
		$tablehead = "<table>";
	}
	if (! $tablefoot) {
		$tablefoot = "</table>";
	}
        print $tablehead;
        output_all_subcatitems_by_cid($cid,"<tr><td>|DATE| |NAME| : |short_content|</td></tr>",4,"</td><td>");
        print $tablefoot;

}



//#############################################################
//## add user to abra system - to be called by access module
function add_user_cats($userid) {

print "Adding user categories...";
	abra_connect();

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
print "<!-- replacing for $key $rvalue -->\n";
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
function get_catitems($curcat, &$items) {
	global $ITEM_TABLE;

	$q = "select * from $ITEM_TABLE where CID = $curcat order by effective_date desc, ENTERED desc";
	get_query_results($items, $q);

print "<!-- query is $q -->\n";

// values->urls if match
	foreach ($items as $key => $val) {


		$items[$key]["URL"] = $items[$key]["VALUE"];

		$items[$key]["LINK"] = '<A HREF="'.$items[$key]["URL"].'">'.$items[$key]["NAME"].'</A>';
		// SOURCE, DATE	
		$items[$key]["DATE"] = mysqltimetodate($items[$key]["effective_date"]);
		array ($types);
		get_types($types, $items[$key]['QUALIFIER']);
		if ($types) {
			get_type_data($types, $items[$key], $items[$key]["ID"]);
		}

	}
	//TODO use proper URL matching

}
//###################################################################
function get_all_subcatitems($curcat, &$items) {
	global $ITEM_TABLE;
	global $CAT_TABLE;

	$catcode = '';
	$q = "select catcode from $CAT_TABLE where CID = $curcat";
 	$result = mysql_query($q);
	$catcode = mysql_fetch_field($result);
	$lvl = 0;
	while (($lvl < strlen($catcode)) && (substr($catcode,$lvl,1) != '\0')) {
		$lvl++;
	}
//HACK ACK ACK
	$lvl = 2;
	$q = "select $ITEM_TABLE.* from $ITEM_TABLE,$CAT_TABLE where ($CAT_TABLE.id = $curcat) AND (LEFT($ITEM_TABLE.itemcode,$lvl) = LEFT($CAT_TABLE.catcode,$lvl)) order by effective_date desc, ENTERED desc";

	get_query_results($items, $q);

print "<!-- query is $q -->\n";

// values->urls if match
	foreach ($items as $key => $val) {


		$items[$key]["URL"] = $items[$key]["VALUE"];

		$items[$key]["LINK"] = '<A HREF="'.$items[$key]["URL"].'">'.$items[$key]["NAME"].'</A>';
		// SOURCE, DATE	
		$items[$key]["DATE"] = mysqltimetodate($items[$key]["effective_date"]);
		array ($types);
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
	if (preg_match("/TYPES?:([^\s]+)/", $qual, $matches)) {
		$types = preg_split("/,/",$matches[1]);
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
