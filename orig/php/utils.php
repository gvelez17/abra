<?php
    function mysql_fetch_array_r($result, $index_row = "", $fetch = MYSQL_ASSOC){
            while ($row = mysql_fetch_array($result,$fetch)){
	                $whole_result[$row[$index_row]] = $row;
        	}
	    return $whole_result;
    }
?>
