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


// $db = new DBHelper($default_database,$default_sql_user,$default_sql_password, $sql_url,$default_table,$db_cols);

// $reponse["data"] = "Duplicate DBHelper setup"; # 5000 ms exec

/*****************************************************************

  In the class DBHelper, the following is slowing it down:

  public function __construct($database, $user, $pw, $url = 'localhost', $table = null, $cols = null)
  {
  /***
  * @param string $database the database to connect to
  * @param string $user the username for the SQL database
  * @param string $pw the password for $user in $database
  * @param string $url the URL of the SQL server
  * @param string $table the default table
  * @param array $cols the column information. Note that it must be
  * specified here in the constructor!!
  ***
  $this->db = $database;
  $this->SQLuser = $user;
  $this->pw = $pw;
  $this->url = $url;
  $this->table = $table;
  if (is_array($cols)) {
    $this->setCols($cols);
  }
}


protected function setCols($cols, $dirty_columns = true)
{
    if (!is_array($cols)) {
        if (empty($cols)) {
            throw(new Exception('No column data provided'));
        } else {
            throw(new Exception('Invalid column data type (needs array)'));
        }
    }
    $shadow = array();
    foreach ($cols as $col => $type) {
        $col = $this->sanitize($col, $dirty_columns);
        $shadow[$col] = $type;
    }
    $this->cols = $shadow;
}


public static function cleanInput($input, $strip_html = true)
{
    $search = array(
        '@<script[^>]*?>.*?</script>@si',   // Strip out javascript
        '@<style[^>]*?>.*?</style>@siU',    // Strip style tags properly
        '@<![\s\S]*?--[ \t\n\r]*>@',         // Strip multi-line comments
    );
    if ($strip_html) {
        $search[] = '@<[\/\!]*?[^<>]*?>@si'; // Strip out HTML tags
    }
    $output = preg_replace($search, '', $input);
    # Replace HTML brackets for anything that slipped through
    $output = str_replace("<", "&#60;", $output);
    $output = str_replace(">", "&#62;", $output);
    return $output;
}


public function sanitize($input, $dirty_entities = false)
{
    # Emails get mutilated here -- let's check that first
    $preg = "/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/";
    if (preg_match($preg, $input) === 1) {
        # It's an email, let's escape it and be done with it
        $l = $this->openDB();
        $output = mysqli_real_escape_string($l, $input);

        return $output;
    }
    if (is_array($input)) {
        foreach ($input as $var => $val) {
            $output[$var] = $this->sanitize($val, $dirty_entities);
        }
    } else {
        if (get_magic_quotes_gpc()) {
            $input = stripslashes($input);
        }
        # We want JSON to pass through unscathed, just be escaped
        if (!$dirty_entities && json_encode(json_decode($input,true)) != $input) {
            $input = htmlentities(self::cleanInput($input));
            $input = str_replace('_', '&#95;', $input); // Fix _ potential wildcard
            $input = str_replace('%', '&#37;', $input); // Fix % potential wildcard
            $input = str_replace("'", '&#39;', $input);
            $input = str_replace('"', '&#34;', $input);
        }
        $l = $this->openDB();
        $output = mysqli_real_escape_string($l, $input);
    }

    return $output;
}

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

// $reponse["data"] = "UDB setup"; # 10000 ms exec

// $p = new Stronghash();

// $response["data"] = "First stronghash"; # 26 ms

// $q = new Stronghash();

// $response["data"] = "Second stronghash"; # 40 ms


returnAjax($response);


?>