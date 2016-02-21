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

if(!function_exists("returnAjax")) {
    function returnAjax($data)
    {
        if (!is_array($data)) {
            $data = array($data);
        }
        $data['execution_time'] = elapsed();
        $data['completed'] = microtime_float();
        global $do;
        $data['requested_action'] = $do;
        $data['args_provided'] = $_REQUEST;
        if (!isset($data['status'])) {
            $data['status'] = false;
            $data['error'] = 'Server returned null or otherwise no status.';
            $data['human_error'] = "Server didn't respond correctly. Please try again.";
            $data['app_error_code'] = -10;
        }
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
        header('Content-type: application/json');
        global $billingTokens;
        if (is_array($billingTokens)) {
            $data['billing_meta'] = $billingTokens;
        }
        print @json_encode($data, JSON_FORCE_OBJECT);
        exit();
    }
        }

$response = array(
    "status" => true,
    "data" => "Simple test",
);

# Assuming living on /usr/local/web/aldo-dev
require_once(dirname(__FILE__)."/../amphibiaweb_disease/DB_CONFIG.php");
$print_login_state = false;


$response["data"] = "DB config & Import";

require_once(dirname(__FILE__)."/../amphibiaweb_disease/core/core.php");

$response["data"] = "Core import"; # 0.015 exec

$db = new DBHelper($default_database,$default_sql_user,$default_sql_password, $sql_url,$default_table,$db_cols);

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

// $ret = setCols($db_cols);
// $response["data"] = "Setcols x2"; # 5000 ms
// $response["cols"] = $ret;

returnAjax($response);


?>