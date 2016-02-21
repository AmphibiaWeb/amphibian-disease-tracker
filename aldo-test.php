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

$response["data"] = "DB config";

require_once(dirname(__FILE__)."/../amphibiaweb_disease/core/core.php");

$response["data"] = "Core import";

$db = new DBHelper($default_database,$default_sql_user,$default_sql_password, $sql_url,$default_table,$db_cols);

$response["data"] = "DB setup";

$print_login_state = false;

require_once(dirname(__FILE__)."/../amphibiaweb_disease/admin/async_login_handler.php");

$response["data"] = "Async import"

// $udb = new DBHelper($default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols); # 5000 ms

// $reponse["data"] = "UDB setup";

# Complete import
# Status: Slow, 5000 ms


returnAjax($response);


?>