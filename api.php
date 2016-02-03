<?php


/*****************
 * Setup
 *****************/

#$show_debug = true;

require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
# This is a public API
header('Access-Control-Allow-Origin: *');

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);

$start_script_timer = microtime_float();

$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);

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

function returnAjax($data)
{
    /***
     * Return the data as a JSON object
     *
     * @param array $data
     *
     ***/
    if (!is_array($data)) {
        $data = array($data);
    }
    $data['execution_time'] = elapsed();
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
    header('Content-type: application/json');
    $json = json_encode($data, JSON_FORCE_OBJECT);
    $replace_array = array('&quot;','&#34;');
    print str_replace($replace_array, '\\"', $json);
    exit();
}

# parse_str($_SERVER['QUERY_STRING'],$_POST);
$do = isset($_REQUEST['action']) ? strtolower($_REQUEST['action']) : null;

switch ($do) {
  case 'fetch':
  case 'upload':
      doCartoSqlApiPush($_REQUEST);
      break;
  case "validate":
      doAWebValidate($_REQUEST);
      break;
  default:
    returnAjax(array(
        'status' => false,
        'error' => 'Invalid action',
        'human_error' => "The server recieved an instruction it didn't understand. Please try again.",
        'action' => $do,
        'request' => $_REQUEST,
        'post' => $_POST,
        'get' => $_GET,
    ));
    
}

function checkColumnExists($column_list)
{
    /***
     * Check if a comma-seperated list of columns exists in the
     * database.
     * @param string $column_list (comma-sep)
     * @return array
     ***/
    if (empty($column_list)) {
        return true;
    }
    global $db;
    $cols = $db->getCols();
    foreach (explode(',', $column_list) as $column) {
        if (!array_key_exists($column, $cols)) {
            returnAjax(array('status' => false, 'error' => 'Invalid column. If it exists, it may be an illegal lookup column.', 'human_error' => "Sorry, you specified a lookup criterion that doesn't exist. Please try again.", 'columns' => $column_list, 'bad_column' => $column));
        }
    }

    return true;
}

function doCartoSqlApiPush($get)
{
    global $cartodb_username, $cartodb_api_key;
    $sqlQuery = decode64($get['sql_query']);
    if (empty($sqlQuery)) {
        returnAjax(array(
        'status' => false,
        'error' => 'Invalid Query',
        'args_provided' => $get,
    ));
    }
    $cartoPostUrl = 'https://'.$cartodb_username.'.cartodb.com/api/v2/sql';
    $cartoArgSuffix = '&api_key='.$cartodb_api_key;
    $statements = explode(';', $sqlQuery);
    $responses = array();
    $parsed_responses = array();
    $urls = array();
    foreach ($statements as $statement) {
        $statement = trim($statement);
        if (empty($statement)) {
            continue;
        }
        $cartoArgs = 'q='.urlencode($statement).$cartoArgSuffix;
        #
        $cartoFullUrl = $cartoPostUrl.'?'.$cartoArgs;
        $urls[] = $cartoFullUrl;
        if (boolstr($get['alt'])) {
            $responses[] = json_decode(do_post_request($cartoPostUrl, $cartoArgs), true);
        } else {
            # Default
            $opts = array(
                'http' => array(
                    'method' => 'GET',
                    'request_fulluri' => true,
                    'timeout' => 3.5, # Seconds
                ),
            );
            $context = stream_context_create($opts);
            $response = file_get_contents($cartoFullUrl, false, $context);
            $responses[] = $response;
            $parsed_responses[] = json_decode($response, true);
        }
    }
    $cartoArgs = 'q='.$sqlQuery.$cartoArgSuffix;
    $cartoFullUrl = $cartoPostUrl.'?'.$cartoArgs;
    try {
        returnAjax(array(
            'status' => true,
            'sql_statements' => $statements,
            'post_response' => $responses,
            'parsed_responses' => $parsed_responses,
            # "urls_posted" => $urls,
        ));
    } catch (Exception $e) {
        returnAjax(array(
            'status' => false,
            'error' => $e->getMessage(),
            'human_error' => 'There was a problem uploading to the CartoDB server.',
        ));
    }
}

function tsvHelper($tsv) {
    return str_getcsv($tsv, "\t");
}

function doAWebValidate($get) {
    /***
     *
     ***/
    $amphibiaWebListTarget = "http://amphibiaweb.org/amphib_names.txt";
    $localAWebTarget = dirname(__FILE__) . "/aweb_list.txt";
    $dayOffset = 60 * 60 * 24;
    $response = array();
    # How old is our copy?
    if (filemtime($localAWebTarget) + $dayOffset < time()) {
        # Fetch a new copy
        $aWebList = file_get_contents($amphibiaWebListTarget);
        $h = fopen($localAWebTarget, "w+");
        $bytes = fwrite($h, $aWebList);
        fclose($h);
        if ($bytes === false) {
            $response["notices"] = array();
            $response["notices"][] = "Couldn't write updated AmphibiaWeb list to $localAWebTarget";
        }
    }
    
    //$aWebList = file_get_contents($localAWebTarget);
    $aWebListArray = array_map("tsvHelper", file($localAWebTarget));
    returnAjax($aWebListArray); # Testing
    
}