<?php


/*****************
 * Setup
 *****************/

$show_debug = true;

if($show_debug) {
error_reporting(E_ALL);
ini_set("display_errors", 1);
error_log("Login is running in debug mode!");
}

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
    $json = json_encode($data, JSON_FORCE_OBJECT); #  | JSON_UNESCAPED_UNICODE
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
    global $cartodb_username, $cartodb_api_key, $db;
    $sqlQuery = decode64($get['sql_query']);
    # If it's a "SELECT" style statement, make sure the accessing user
    # has permissions to read this dataset
    $searchSql = strtolower($sqlQuery);
    if(strpos($searchSql, "select") !== false) {
        # Check the user
        # If bad, kick the access out
        $cartoTable = preg_replace('/(?i)SELECT .*FROM[ `]*(t[0-9a-f]*_[0-9a-f]*)[ `]*.*;/m', '$1', $sqlQuery);
        $accessListLookupQuery = "SELECT `author`, `access_data` FROM `" . $db->getTable() . "` WHERE `carto_id` LIKE '%" . $cartoTable . "%'";
        $l = $db->openDB();
        $r = mysqli_query($l, $accessListLookupQuery);
        $row = mysqli_fetch_assoc($r);
        $csvString = preg_replace('/(:(EDIT|READ))/m', '', $row["access_data"]);
        $users = explode(",", $csvString);
        $users[] = $row["author"];
        # Get current user ID
        require_once(dirname(__FILE__)."/admin/async_login_handler.php");
        $login_status = getLoginState($get);
        if($login_status["status"] !== true) {
            $response = array(
                "status" => false,
                "error" => "NOT_LOGGED_IN",
                "human_error" => "Attempted to read from table `$cartoTable` without being logged in",
                "args_provided" => $get,
            );
            returnAjax($response);
        }
        $uid = $login_status["detail"]["uid"];
        if(!in_array($uid, $users)) {
            $response = array(
                "status" => false,
                "error" => "UNAUTHORIZED_USER",
                "human_error" => "User $uid isn't authorized to access this dataset",
                "args_provided" => $get,
            );
            returnAjax($response);            
        }
    }
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
    $response = array(
        "status" => false,
        "args_provided" => $get,
        "notices" => array(),
    );
    # We need, at minimum, genus and species
    if(empty($get["genus"]) or empty($get["species"])) {
        $response["error"] = "MISSING_ARGUMENTS";
        $response["human_error"] = "You need to provide both a genus and species to validate";
        returnAjax($response);
    }
    # How old is our copy?
    if (filemtime($localAWebTarget) + $dayOffset < time()) {
        # Fetch a new copy
        $aWebList = file_get_contents($amphibiaWebListTarget);
        $h = fopen($localAWebTarget, "w+");
        $bytes = fwrite($h, $aWebList);
        fclose($h);
        if ($bytes === false) {
            $response["notices"][] = "Couldn't write updated AmphibiaWeb list to $localAWebTarget";
        }
    }

    //$aWebList = file_get_contents($localAWebTarget);
    $aWebListArray = array_map("tsvHelper", file($localAWebTarget));
    /*
     * For a given row, we have this numeric key to real id mapping:
     *
     * Object {0: "order", 1: "family", 2: "subfamily", 3: "genus", 4: "subgenus", 5: "species", 6: "common_name", 7: "gaa_name", 8: "synonymies", 9: "itis_names", 10: "iucn", 11: "isocc", 12: "intro_isocc", 13: "aweb_uid", 14: "uri/guid", 15: "taxon_notes_public"}
     */
    $genusList = array();
    $synonymList = array();
    foreach($aWebListArray as $k=>$entry) {
        if($k == 0) continue; # Prevent match on "genus"
        $genus = strtolower($entry[3]);
        $genusList[] = $genus;
        $synonEntry = strtolower($entry[8]);
        if(!empty($synonEntry)) {
            if(strpos($synonEntry, ",") !== false) {
                $synon = explode(",", $synonEntry);
            } else {
                $synon = array($synonEntry);
            }
            foreach($synon as $oldName) {
                $key = trim($oldName);
                $synonymList[$key] = $k;
            }
        }
        $itisEntry = strtolower($entry[9]);
        if(!empty($itisEntry)) {
            if(strpos($itisEntry, ",") !== false) {
                $itis = explode(",", $itisEntry);
            } else {
                $itis = array($itisEntry);
            }        
            foreach($itis as $oldName) {
                $key = trim($oldName);
                $synonymList[$key] = $k;
            }
        }
    }
    # First check: Does the genus exist?
    $providedGenus = strtolower($get["genus"]);
    $providedSpecies = strtolower($get["species"]);
    if (!in_array($providedGenus, $genusList)) {
        # Are they using an old name?
        $testSpecies = $providedGenus . " " . $providedSpecies;
        if(!array_key_exists($testSpecies, $synonymList)) {
            # Nope, just failed
            $response["error"] = "INVALID_GENUS";
            $response["human_error"] = "'$providedGenus' isn't a valid AmphibiaWeb genus, nor is '$testSpecies' a recognized synonym.";
            returnAjax($response);
        }
        # Ah, a synonym eh?
        $row = $synonymList[$testSpecies];
        $aWebMatch = $aWebListArray[$row];
        $aWebCols = $aWebListArray[0];
        $aWebPretty = array();
        foreach($aWebMatch as $key=>$val) {
            $prettyKey = $aWebCols[$key];
            $prettyKey = str_replace("/", "_or_", $prettyKey);
            if(strpos($val, ",") !== false) {
                $val = explode(",", $val);
                foreach($val as $k=>$v) {
                    $val[$k] = trim($v);
                }
            }
            $aWebPretty[$prettyKey] = $val;
        }
        if(empty($aWebPretty["subspecies"]) && !empty($get["subspecies"])) {
            $aWebPretty["subspecies"] = $get["subspecies"];
        }
        $response["status"] = true;
        $response["notices"][] = "Your entry '$testSpecies' was a synonym in the AmphibiaWeb database. It was automatically converted to the canonical taxon.";
        # Note that Unicode characters may return escaped! eg, \u00e9.
        $response["validated_taxon"] = $aWebPretty;
        returnAjax($response);
    }
    # Cool, so the genus exists.
    $speciesList = array();
    foreach($aWebListArray as $row=>$entry) {
        if($row == 0) continue; # Prevent match on "species"
        $genus = strtolower($entry[3]);
        if($genus == $providedGenus) {
            $species = $entry[5];
            $speciesList[$species] = $row;
        }
    }
    if(!array_key_exists($providedSpecies, $speciesList)) {
        # Are they using an old name?
        $testSpecies = $providedGenus . " " . $providedSpecies;
        if(!array_key_exists($testSpecies, $synonymList)) {
            # Nope, just failed
            $response["error"] = "INVALID_SPECIES";
            $response["human_error"] = "'$providedSpecies' isn't a valid AmphibiaWeb species in the genus '$providedGenus', nor is '$testSpecies' a recognized synonym.";
            returnAjax($response);
        }
        # Let's play the synonym game again!
        $row = $synonymList[$testSpecies];
        $aWebMatch = $aWebListArray[$row];
        $aWebCols = $aWebListArray[0];
        $aWebPretty = array();
        foreach($aWebMatch as $key=>$val) {
            $prettyKey = $aWebCols[$key];
            $prettyKey = str_replace("/", "_or_", $prettyKey);
            if(strpos($val, ",") !== false) {
                $val = explode(",", $val);
                foreach($val as $k=>$v) {
                    $val[$k] = trim($v);
                }
            }
            $aWebPretty[$prettyKey] = $val;
        }
        if(empty($aWebPretty["subspecies"]) && !empty($get["subspecies"])) {
            $aWebPretty["subspecies"] = $get["subspecies"];
        }
        $response["status"] = true;
        $response["notices"][] = "Your entry '$testSpecies' was a synonym in the AmphibiaWeb database. It was automatically converted to the canonical taxon.";
        # Note that Unicode characters may return escaped! eg, \u00e9.
        $response["validated_taxon"] = $aWebPretty;
        returnAjax($response);
    }
    # The genus and species is valid.
    # Prep for the user response
    $aWebRow = $speciesList[$providedSpecies];
    $aWebMatch = $aWebListArray[$aWebRow];
    $aWebCols = $aWebListArray[0];
    $aWebPretty = array();
    foreach($aWebMatch as $key=>$val) {
        $prettyKey = $aWebCols[$key];
        $prettyKey = str_replace("/", "_or_", $prettyKey);
        if(strpos($val, ",") !== false) {
            $val = explode(",", $val);
            foreach($val as $k=>$v) {
                $val[$k] = trim($v);
            }
        }
        $aWebPretty[$prettyKey] = $val;
    }
    if(empty($aWebPretty["subspecies"]) && !empty($get["subspecies"])) {
        $aWebPretty["subspecies"] = $get["subspecies"];
    }
    $response["status"] = true;
    # Note that Unicode characters may return escaped! eg, \u00e9.
    $response["validated_taxon"] = $aWebPretty;
    returnAjax($response);

}
