<?php

$start_script_timer = microtime_float();

function microtime_float()
{
    if (version_compare(phpversion(), '5.0.0', '<')) {
        list($usec, $sec) = explode(' ', microtime());

        return ((float) $usec + (float) $sec);
    } else {
        return microtime(true);
    }
}

if (!function_exists('elapsed')) {
    function elapsed($start_time = null)
    {
        /***
         * Return the duration since the start time in
         * milliseconds.
         * If no start time is provided, it'll try to use the global
         * variable $start_script_timer
         *
         * @param float $start_time in unix epoch. See http://us1.php.net/microtime
         ***/

        if (!is_numeric($start_time)) {
            global $start_script_timer;
            if (is_numeric($start_script_timer)) {
                $start_time = $start_script_timer;
            } else {
                return false;
            }
        }

        return 1000 * (microtime_float() - (float) $start_time);
    }
        }



$response = array(
    "status" => true,
    "data" => "Simple test",
);

# Base functions and simple returnr
# Status: Fast

# Assuming living on /usr/local/web/aldo-dev
require_once(dirname(__FILE__)."/../amphibiaweb_disease/DB_CONFIG.php");
$print_login_state = false;

require_once(dirname(__FILE__)."/../amphibiaweb_disease/admin/async_login_handler.php");

$response["data"] = "DB config & Import";

require_once(dirname(__FILE__)."/../amphibiaweb_disease/core/core.php");

$response["data"] = "Core import"; # 0.015 exec

$db = new DBHelper($default_database,$default_sql_user,$default_sql_password, $sql_url,$default_table,$db_cols);

$response["data"] = "DB setup"; # 30 exec

$test = "Here is a test sentence with CHARACTERS";
$dirty = true;

$response["data"] = "Vars";

try {
$result = $db->sanitize($test, $dirty);

$response["data"] = "Sanitize 1";
} catch(Exception $e) {
$response["data"] = "Sanitize 1, error " . $e->getMessage();
}


$result = $db->sanitize($test, $dirty);

$response["data"] = "Sanitize 2";


// $db2 = new DBHelper($default_database,$default_sql_user,$default_sql_password, $sql_url,$default_table,$db_cols);

// $response["data"] = "Duplicate DBHelper setup"; # 5000 ms exec

$cols = array();
function setCols($cols, $dirty_columns = true)
{
    global $db;
    if (!is_array($cols)) {
        if (empty($cols)) {
            returnAjax('No column data provided');
        } else {
            returnAjax('Invalid column data type (needs array)');
        }
    }
    $shadow = array();
    foreach ($cols as $col => $type) {
        # $col = DBHelper::cleanInput($col); # 32 ms
        $col = reducedSanitize($col, $dirty_columns); # 5000 ms
        $shadow[$col] = $type;
    }
    $cols = $shadow;
    return $cols;
}

function openDB()
{
    /***
     * @return mysqli_resource
     ***/
    global $default_database,$default_sql_user,$default_sql_password, $sql_url;
    if ($l = mysqli_connect($sql_url, $default_sql_user, $default_sql_password)) {
        if (mysqli_select_db($l, $default_database)) {
            return $l;
        } 
        returnAjax("Could not select DB");
    }
    returnAjax('Could not connect to database.');
}

function reducedSanitize($input) {
    global $db;
    $l = openDB();
    $output = mysqli_real_escape_string($l, $input);
    mysqli_close($l);
    return $output;
}

$response["data"] = "Fn Setcols"; # 33 ms

$ret = setCols($db_cols);
$response["data"] = "Setcols x1"; # 5000 ms
$response["cols"] = $ret;

// setCols($db_cols);
// $response["data"] = "Setcols x2";

/*****************************************************************

  In the class DBHelper, the following is slowing it down:
*/

function sanitize($input, $dirty_entities = false)
{
    global $db;
    if (is_array($input)) {
        # IGNORE FOR DEBUG PURPOSES
        foreach ($input as $var => $val) {
            $output[$var] = $db->sanitize($val, $dirty_entities);
        }
    } else {
        if (get_magic_quotes_gpc()) {
            $input = stripslashes($input);
        }
        # We want JSON to pass through unscathed, just be escaped
        if (!$dirty_entities && json_encode(json_decode($input,true)) != $input) {
            $input = htmlentities(DBHelper::cleanInput($input));
            $input = str_replace('_', '&#95;', $input); // Fix _ potential wildcard
            $input = str_replace('%', '&#37;', $input); // Fix % potential wildcard
            $input = str_replace("'", '&#39;', $input);
            $input = str_replace('"', '&#34;', $input);
        }
        // $l = $db->openDB();
        // $output = mysqli_real_escape_string($l, $input);
        // mysqli_close($l);
        $output = $input;
    }

    return $output;
}
/*
public function openDB()
{
    /***
     * @return mysqli_resource
     ***
    if ($l = mysqli_connect($this->getSQLURL(), $this->getSQLUser(), $this->getSQLPW())) {
        if (mysqli_select_db($l, $this->getDB())) {
            return $l;
        }
    }
    throw(new Exception('Could not connect to database.'));
}

*****************************************************************/

// $udb = new DBHelper($default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols);

// $response["data"] = "UDB setup"; # 10000 ms exec

// $p = new Stronghash();

// $response["data"] = "First stronghash"; # 26 ms

// $q = new Stronghash();

// $response["data"] = "Second stronghash"; # 40 ms


returnAjax($response);


?>