<?php


/*****************
 * Setup
 *****************/

# $show_debug = true;

if ($show_debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('Login is running in debug mode!');
}

require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
# This is a public API
header('Access-Control-Allow-Origin: *');

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);

$print_login_state = false;
require_once dirname(__FILE__).'/admin/async_login_handler.php';

$udb = new DBHelper($default_user_database, $default_sql_user, $default_sql_password, $sql_url, $default_user_table, $db_cols);
$login_status = getLoginState($get);

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

// function returnAjax($data)
// {
//     /***
//      * Return the data as a JSON object
//      *
//      * @param array $data
//      *
//      ***/
//     if (!is_array($data)) {
//         $data = array($data);
//     }
//     $data['execution_time'] = elapsed();
//     header('Cache-Control: no-cache, must-revalidate');
//     header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
//     header('Content-type: application/json');
//     $json = json_encode($data, JSON_FORCE_OBJECT); #  | JSON_UNESCAPED_UNICODE
//     $replace_array = array('&quot;','&#34;');
//     print str_replace($replace_array, '\\"', $json);
//     exit();
// }

# parse_str($_SERVER['QUERY_STRING'],$_POST);
$do = isset($_REQUEST['action']) ? strtolower($_REQUEST['action']) : null;
try {
$test = decode64($_REQUEST["test"]);
$test_sanitized = $db->sanitize($test);
$test_desanitized = deEscape($test_sanitized);
$testArr = array(
    "encoded" => $_REQUEST["test"],
    "decoded" => $test,
    "written" => $test_sanitized,
    "read_back" => $test_desanitized,
);
} catch (Exception $e) {
    $testArr = array();
}
switch ($do) {
  case 'upload':
      # Set access-control header
      header('Access-Control-Allow-Origin: amphibiandisease.org');
  case 'fetch':
      doCartoSqlApiPush($_REQUEST);
      break;
  case 'validate':
      doAWebValidate($_REQUEST);
      break;
  case 'is_human':
      validateCaptcha($_REQUEST);
      break;
  case 'search_projects':
  case 'search_project':
      searchProject($_REQUEST);
      break;
  case 'search_users':
  case 'search_user':
    searchUsers($_REQUEST);
    break;
  // case 'advanced_project_search':
  //   advancedSearchProject($_REQUEST);
  //   break;
  case 'chart':
      getChartData($_REQUEST);
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
        #"debug" => $testArr,
    ));

}

function searchProject($get)
{
    /***
     *
     ***/
    global $db;
    $q = $db->sanitize($get['q']);
    $search = array(
        'project_id' => $q,
        'project_title' => $q,
    );
    $cols = array('project_id', 'project_title', "dataset_arks");
    $response = array(
        'search' => $q,
    );
    if (!empty($get['cols'])) {
        if (checkColumnExists($get['cols'], false)) {
            # Replace the defaults
            $colList = explode(',', $get['cols']);
            $search = array();
            foreach ($colList as $col) {
                $col = trim($col);
                # If the column exists, we don't have to sanitize it
                # $col = $db->sanitize($col);
                $search[$col] = $q;
                $cols[] = $col;
            }
        } else {
            $response['notice'] = 'Invalid columns; defaults used';
        }
    }
    $cols[] = 'public';
    $response['status'] = true;
    $response['cols'] = $cols;
    $response['result'] = $db->getQueryResults($search, $cols, 'OR', true, true);
    foreach ($response['result'] as $k => $projectResult) {
        $response['result'][$k]['public'] = boolstr($projectResult['public']);
    }
    $response['count'] = sizeof($response['result']);
    returnAjax($response);
}




function searchUsers($get)
{
    /***
     *
     ***/
    global $udb, $login_status;
    $q = $udb->sanitize($get['q']);
    $response = array(
        'search' => $q,
    );

    $search = array(
        'username' => $q,
        'name' => $q,
        'dblink' => $q, #?
    );
    $cols = array('username', 'name', 'dblink', "email_verified", "alternate_email_verified", "admin_flag", "alternate_email");
    if (!empty($get['cols'])) {
        if (checkUserColumnExists($get['cols'], false)) {
            # Replace the defaults
            $colList = explode(',', $get['cols']);
            $search = array();
            foreach ($colList as $col) {
                $col = trim($col);
                # If the column exists, we don't have to sanitize it
                # $col = $db->sanitize($col);
                $search[$col] = $q;
                $cols[] = $col;
            }
        } else {
            $response['notice'] = 'Invalid columns; defaults used';
            $response["detail"] = checkUserColumnExists($get["cols"], false, true);
        }
    }

    $response['status'] = true;
    $result = $udb->getQueryResults($search, $cols, 'OR', true, true);
    $suFlag = $login_status['detail']['userdata']['su_flag'];
    $isSu = boolstr($suFlag);
    $adminFlag = $login_status['detail']['userdata']['admin_flag'];
    $isAdmin = boolstr($adminFlag);
    foreach ($result as $k => $entry) {
        $clean = array(
            'email' => $entry['username'],
            'uid' => $entry['dblink'],
            "has_verified_email" => boolstr($entry["email_verified"]) || boolstr($entry["alternate_email_verified"]),
        );
        if($isAdmin) {
            $clean["is_admin"] = boolstr($entry["admin_flag"]);
            $clean["alternate_email"] = $entry["alternate_email"];
            $tmpUser = new UserFunctions($clean["email"]);
            $clean["unrestricted"] = $tmpUser->meetsRestrictionCriteria();
        }
        $nameXml = $entry['name'];
        $xml = new Xml();
        $xml->setXml($nameXml);
        $clean['first_name'] = htmlspecialchars_decode($xml->getTagContents('fname'));
        $clean['last_name'] = htmlspecialchars_decode($xml->getTagContents('lname'));
        $clean['full_name'] = htmlspecialchars_decode($xml->getTagContents('name'));
        $clean['handle'] = $xml->getTagContents('dname');
        $result[$k] = $clean;
    }
    $response['result'] = $result;
    $response['count'] = sizeof($result);
    returnAjax($response);
}

function checkColumnExists($column_list, $userReturn = true, $detailReturn = false)
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
            if ($userReturn || $detailReturn) {
                $response = array('status' => false, 'error' => 'Invalid column. If it exists, it may be an illegal lookup column.', 'human_error' => "Sorry, you specified a lookup criterion that doesn't exist. Please try again.", 'columns' => $column_list, 'bad_column' => $column);
                if ($userReturn) returnAjax($response);
                return $response;
            } else {
                return false;
            }
        }
    }
    if ($userReturn) {
        returnAjax(array('status' => true));
    } else {
        return true;
    }
}


function checkUserColumnExists($column_list, $userReturn = true, $detailReturn = false)
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
    global $udb;
    $cols = $udb->getCols();
    foreach (explode(',', $column_list) as $column) {
        if (!array_key_exists($column, $cols)) {
            if ($userReturn || $detailReturn) {
                $response = array('status' => false, 'error' => 'INVALID_OR_PROTECTED_COLUMN', 'human_error' => "Sorry, you specified a lookup criterion that doesn't exist, or is protected. Please try again.", 'columns' => $column_list, 'bad_column' => $column, "available_columns" => $cols);
                if ($userReturn) returnAjax($response);
                return $response;
            } else {
                return false;
            }
        }
    }
    if ($userReturn) {
        returnAjax(array('status' => true));
    } else {
        return true;
    }
}

function doCartoSqlApiPush($get)
{
    global $cartodb_username, $cartodb_api_key, $db, $udb, $login_status;

    // error_reporting(E_ALL);
    // ini_set('display_errors', 1);
    // error_log('Login is running in debug mode!');

    $sqlQuery = decode64($get['sql_query'], true);
    if(empty($sqlQuery)) {
        $sqlQuery = base64_decode(urldecode($get["sql_query"]));
    }
    $originalQuery = $sqlQuery;
    # If it's a "SELECT" style statement, make sure the accessing user
    # has permissions to read this dataset
    $searchSql = strtolower($sqlQuery);
    $queryPattern = '/(?i)([a-zA-Z]+(?: +INTO)?) +.*(?:FROM)?[ `]*(t[0-9a-f]{10,}[_]?[0-9a-f]*)[ `]*.*[;]?/m';
    $statements = explode(');', $sqlQuery);
    $checkedTablePermissions = array();
    $pidList = array();
    foreach($statements as $k=>$statement) {
        if(empty($statement)) {
            unset($statements[$k]);
            continue;
        }
        $sqlAction = preg_replace($queryPattern, '$1', $statement);
        $sqlAction = strtolower(str_replace(" ","", $sqlAction));
        $restrictedActions = array(
            "select" => "READ",
            "delete" => "EDIT",
            "insert" => "EDIT",
            "insertinto" => "EDIT",
            "update" => "EDIT",
        );
        $unrestrictedActions = array(
            "create" => true,
        );
        # Looking up the columns is a safe action
        if (preg_match('/\A(?i)SELECT +\* +(?:FROM)?[ `]*(t[0-9a-f]{10,}[_]?[0-9a-f]*)[ `]* +(WHERE FALSE)[;]?\Z/m', $statement)) {
            # Successful match
            unset($restrictedActions["select"]);
            $unrestrictedActions["select"] = true;
        }
        if (isset($restrictedActions[$sqlAction])) {
            # Check the user
            # If bad, kick the access out
            $cartoTable = preg_replace($queryPattern, '$2', $statement);
            $checkedTablePermissions[] = $cartoTable;
            $cartoTableJson = str_replace('_', '&#95;', $cartoTable);
            $accessListLookupQuery = 'SELECT `project_id`, `author`, `access_data`, `public` FROM `'.$db->getTable()."` WHERE `carto_id` LIKE '%".$cartoTableJson."%' OR `carto_id` LIKE '%".$cartoTable."%'";
            $l = $db->openDB();
            $r = mysqli_query($l, $accessListLookupQuery);
            $row = mysqli_fetch_assoc($r);
            $pid = $row["project_id"];
            $pidList[$cartoTable] = $pid;
            # Non-existant projects are fair game
            if(!empty($pid)) {
                $requestedPermission = $restrictedActions[$sqlAction];
                $pArr = explode(",", $row["access_data"]);
                $permissions = array();
                foreach($pArr as $access) {
                    $up = explode(":", $access);
                    $permissions[$up[0]] = $up[1];
                } # End loop
                $csvString = preg_replace('/(:(EDIT|READ))/m', '', $row['access_data']);
                $users = explode(',', $csvString);
                $users[] = $row['author'];
                $isPublic = boolstr($row['public']);
                $suFlag = $login_status['detail']['userdata']['su_flag'];
                $isSu = boolstr($suFlag);
                # Get current user ID
                if ($login_status['status'] !== true && !$isPublic) {
                    $response = array(
                        'status' => false,
                        'error' => 'NOT_LOGGED_IN',
                        'human_error' => 'Attempted to access private project without being logged in',
                        'args_provided' => $get,
                        "project_id" => $pid,
                        "query_type" => $sqlAction,
                        'is_public_dataset' => $isPublic,
                        "statement_parsed" => $statement,
                    );
                    returnAjax($response);
                } # End login check
                $uid = $login_status['detail']['uid'];
                if (!in_array($uid, $users) && !$isPublic && $isSu !== true) {
                    $response = array(
                        'status' => false,
                        'error' => 'UNAUTHORIZED_USER',
                        'human_error' => "User $uid isn't authorized to access this dataset",
                        'args_provided' => $get,
                        "project_id" => $pid,
                        'is_public_dataset' => $isPublic,
                        "statement_parsed" => $statement,
                    );
                    returnAjax($response);
                } # End authorized  user check
                if ($requestedPermission == "EDIT") {
                    # Editing has an extra filter
                    $hasPermission = $permissions[$uid];
                    if ($hasPermission !== $requestedPermission && $isSu !== true) {
                        $response = array(
                            'status' => false,
                            'error' => 'UNAUTHORIZED_USER',
                            'human_error' => "User '$uid' isn't authorized to edit this dataset",
                            'args_provided' => $get,
                            "project_id" => $pid,
                            "query_type" => $sqlAction,
                            "user_permissions" => $hasPermission,
                            "statement_parsed" => $statement,
                        );
                        returnAjax($response);
                    } # End edit permission check
                } # End edit permission case
            } # End project existence check
        } else if (!isset($unrestrictedActions[$sqlAction])) {
            # Unrecognized query type
            returnAjax(array(
                "status" => false,
                "error" => "UNAUTHORIZED_QUERY_TYPE",
                "query_type" => $sqlAction,
                "args_provided" => $get,
                "statement_parsed" => $statement,
            ));
        }
        if (empty($statement)) {
            returnAjax(array(
                'status' => false,
                'error' => 'Invalid Query',
                'args_provided' => $get,
            ));
        }
    }
    $cartoPostUrl = 'https://'.$cartodb_username.'.cartodb.com/api/v2/sql';
    $cartoArgSuffix = '&api_key='.$cartodb_api_key;
    $l = sizeof($statements);
    $lastIndex = $l - 1;
    foreach($statements as $k=>$statement) {
        # Re-append the closing parens
        if(substr_count($statement, "(") === substr_count($statement, ")") + 1) $statements[$k] = $statement . ")";
    }
    $responses = array();
    $parsed_responses = array();
    $urls = array();
    ini_set('allow_url_fopen', true);
    try {
        set_time_limit(0);
    } catch (Exception $e) {
        $length = 30 * sizeof($statements);
        set_time_limit($length);
    }
    if (!boolstr($get['blobby'])) {
        foreach ($statements as $statement) {
            $statement = trim($statement);
            if (empty($statement)) {
                continue;
            }
            $cartoArgs = 'q='.urlencode($statement).$cartoArgSuffix;
            # Fetch a table
            $cartoTable = preg_replace($queryPattern, '$2', $statement);
            $sqlAction = preg_replace($queryPattern, '$1', $statement);
            $cartoFullUrl = $cartoPostUrl.'?'.$cartoArgs;
            $urls[] = $cartoFullUrl;
            if (boolstr($get['alt'])) {
                $responses[] = json_decode(do_post_request($cartoPostUrl, $cartoArgs, 'GET'), true);
            } else {
                # Default
                $opts = array(
                    'http' => array(
                        'method' => 'GET',
                        #'request_fulluri' => true,
                        'ignore_errors' => true,
                        'timeout' => 3.5, # Seconds
                    ),
                );
                $context = stream_context_create($opts);
                $response = file_get_contents($cartoFullUrl, false, $context);
                $responses[] = $response;
                $decoded = json_decode($response, true);
                $decoded["query"] = $statement;
                $decoded["encoded_query"] = urlencode($statement);
                $decoded["table"] = $cartoTable;
                $decoded["project_id"] = $pidList[$cartoTable];
                $decoded["blobby"] = false;
                $decoded["sql_action"] = $sqlAction;
                $parsed_responses[] = $decoded;
            }
        }
    } else {
        $cartoArgs = 'q='.$sqlQuery.$cartoArgSuffix;
        $cartoFullUrl = $cartoPostUrl.'?'.$cartoArgs;
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
        $decoded = json_decode($response, true);
        $decoded["query"] = $sqlQuery;
        $decoded["blobby"] = true;
        $parsed_responses[] = $decoded;

    }
    try {
        $response = array(
            'status' => true,
            'sql_statements' => $statements,
            'post_response' => $responses,
            'parsed_responses' => $parsed_responses,
            'blobby' => boolstr($get['blobby']),
            "query_type" => $sqlAction,
            "parsed_query" => $originalQuery,
            "checked_tables" => $checkedTablePermissions,
            #"foo" => base64_decode(urldecode($get["sql_query"])),
            #"bar" => base64_decode($get["sql_query"]),
            #"baz" => urldecode(base64_decode($get["sql_query"])),
            # "urls_posted" => $urls,
        );
        if(boolstr($get['blobby'])) {
            $response["project_id"] = $pid;
            $response["query_type"] = $sqlAction;
        }
        returnAjax($response);
    } catch (Exception $e) {
        returnAjax(array(
            'status' => false,
            'error' => $e->getMessage(),
            'human_error' => 'There was a problem uploading to the CartoDB server.',
            'blobby' => boolstr($get['blobby']),
            "query_type" => $sqlAction,
            "project_id" => $pid,
        ));
    }
}

function tsvHelper($tsv)
{
    return str_getcsv($tsv, "\t");
}

function doAWebValidate($get)
{
    /***
     *
     ***/
    $amphibiaWebListTarget = 'http://amphibiaweb.org/amphib_names.txt';
    $localAWebTarget = dirname(__FILE__).'/aweb_list.txt';
    $dayOffset = 60 * 60 * 24;
    $response = array(
        'status' => false,
        'args_provided' => $get,
        'notices' => array(),
    );
    # We need, at minimum, genus and species
    if (empty($get['genus'])) {
        $response['error'] = 'MISSING_ARGUMENTS';
        $response['human_error'] = 'You need to a genus and species to validate';
        returnAjax($response);
    }
    if (empty($get['species'])) {
        $response["notices"][] = "No species provided. Using generic species";
        $get["species"] = "sp";
    }
    # How old is our copy?
    if (filemtime($localAWebTarget) + $dayOffset < time()) {
        # Fetch a new copy
        $aWebList = file_get_contents($amphibiaWebListTarget);
        $h = fopen($localAWebTarget, 'w+');
        $bytes = fwrite($h, $aWebList);
        fclose($h);
        if ($bytes === false) {
            $response['notices'][] = "Couldn't write updated AmphibiaWeb list to $localAWebTarget";
        }
    }
    $response['aweb_list_age'] = time() - filemtime($localAWebTarget);
    $response['aweb_list_max_age'] = $dayOffset;
    //$aWebList = file_get_contents($localAWebTarget);
    $aWebListArray = array_map('tsvHelper', file($localAWebTarget));

    /*
     * For a given row, we have this numeric key to real id mapping:
     *
     * Object {0: "order", 1: "family", 2: "subfamily", 3: "genus", 4: "subgenus", 5: "species", 6: "common_name", 7: "gaa_name", 8: "synonymies", 9: "itis_names", 10: "iucn", 11: "isocc", 12: "intro_isocc", 13: "aweb_uid", 14: "uri/guid", 15: "taxon_notes_public"}
     */
    $genusList = array();
    $synonymList = array();
    $synonymGenusList = array();
    foreach ($aWebListArray as $k => $entry) {
        if ($k == 0) {
            continue;
        } # Prevent match on "genus"
        $genus = strtolower($entry[3]);
        $genusList[$genus] = $k;
        $gaaEntry = strtolower($entry[7]);
        if (!empty($gaaEntry)) {
            if (strpos($gaaEntry, ',') !== false) {
                $synon = explode(',', $gaaEntry);
            } else {
                $synon = array($gaaEntry);
            }
            foreach ($synon as $oldName) {
                $key = trim($oldName);
                $synonymList[$key] = $k;
                $oldGenus = explode(' ', $key);
                $oldGenus = $oldGenus[0];
                $synonymGenusList[$oldGenus] = $k;
            }
        }
        $synonEntry = strtolower($entry[8]);
        if (!empty($synonEntry)) {
            if (strpos($synonEntry, ',') !== false) {
                $synon = explode(',', $synonEntry);
            } else {
                $synon = array($synonEntry);
            }
            foreach ($synon as $oldName) {
                $key = trim($oldName);
                $synonymList[$key] = $k;
                $oldGenus = explode(' ', $key);
                $oldGenus = $oldGenus[0];
                $synonymGenusList[$oldGenus] = $k;
            }
        }
        $itisEntry = strtolower($entry[9]);
        if (!empty($itisEntry)) {
            if (strpos($itisEntry, ',') !== false) {
                $itis = explode(',', $itisEntry);
            } else {
                $itis = array($itisEntry);
            }
            foreach ($itis as $oldName) {
                $key = trim($oldName);
                $synonymList[$key] = $k;
                $oldGenus = explode(' ', $key);
                $oldGenus = $oldGenus[0];
                $synonymGenusList[$oldGenus] = $k;
            }
        }
    }
    # First check: Does the genus exist?
    $providedGenus = strtolower($get['genus']);
    $providedSpecies = strtolower($get['species']);
    if (!array_key_exists($providedGenus, $genusList)) {
        # Are they using an old name?
        $testSpecies = $providedGenus.' '.$providedSpecies;
        if (!array_key_exists($testSpecies, $synonymList)) {
          # For 'nov. sp.', 'sp.' variants, and with following digits,
          # check genus only
          # See
          # http://regexr.com/3d1kb
          if (array_key_exists($providedGenus, $synonymGenusList) && preg_match('/^(nov[.]{0,1} ){0,1}(sp[.]{0,1}([ ]{0,1}\d+){0,1})$/m', $providedSpecies) ) {
                # OK, they were just looking for a genus anyway
                $row = $synonymGenusList[$providedGenus];
                $aWebMatch = $aWebListArray[$row];
                $aWebCols = $aWebListArray[0];
                $aWebPretty = array();
                $skipCols = array(
                    'species',
                    'gaa_name',
                    'common_name',
                    'synonymies',
                    'itis_names',
                    'iucn',
                    'isocc',
                    'intro_isocc',
                );
                foreach ($aWebMatch as $key => $val) {
                    $prettyKey = $aWebCols[$key];
                    if (!in_array($prettyKey, $skipCols)) {
                        $prettyKey = str_replace('/', '_or_', $prettyKey);
                        if (strpos($val, ',') !== false) {
                            $val = explode(',', $val);
                            foreach ($val as $k => $v) {
                                $val[$k] = trim($v);
                            }
                        }
                        $aWebPretty[$prettyKey] = $val;
                    }
                }
                # Pretty format the 'nov sp'/'sp'/etc
                $aWebPretty['species'] = preg_match('/^nov[.]{0,1} (sp[.]{0,1}([ ]{0,1}(\d+)){0,1})$/m', $providedSpecies) ?
                                       trim(preg_replace('/^nov[.]{0,1} (sp[.]{0,1}([ ]{0,1}(\d+)){0,1})$/m', 'nov. sp. $3', $providedSpecies)) :
                                       trim(preg_replace('/^sp[.]{0,1}([ ]{0,1}(\d+)){0,1}$/m', 'sp. $2', $providedSpecies));
                $response['status'] = true;
                $response['notices'][] = "Your genus '$providedGenus' was a synonym in the AmphibiaWeb database. It was automatically converted to the canonical genus.";
                $response['notices'][] = "You provided a generic species '".$aWebPretty['species']."'. Only the genus has been validated.";
                $response['original_taxon'] = $providedGenus;
                # Note that Unicode characters may return escaped! eg, \u00e9.
                $response['validated_taxon'] = $aWebPretty;
                returnAjax($response);
            }
            # Nope, just failed
            $response['error'] = 'INVALID_GENUS';
            $response['human_error'] = "'<span class='genus'>$providedGenus</span>' isn't a valid AmphibiaWeb genus (checked ".sizeof($genusList)." genera), nor is '<span class='sciname'>$testSpecies</span>' a recognized synonym.";
            returnAjax($response);
        }
        # Ah, a synonym eh?
        $row = $synonymList[$testSpecies];
        $aWebMatch = $aWebListArray[$row];
        $aWebCols = $aWebListArray[0];
        $aWebPretty = array();
        foreach ($aWebMatch as $key => $val) {
            $prettyKey = $aWebCols[$key];
            $prettyKey = str_replace('/', '_or_', $prettyKey);
            if (strpos($val, ',') !== false) {
                $val = explode(',', $val);
                foreach ($val as $k => $v) {
                    $val[$k] = trim($v);
                }
            }
            $aWebPretty[$prettyKey] = $val;
        }
        if (empty($aWebPretty['subspecies']) && !empty($get['subspecies'])) {
            $aWebPretty['subspecies'] = $get['subspecies'];
        }
        $response['status'] = true;
        $response['notices'][] = "Your entry '$testSpecies' was a synonym in the AmphibiaWeb database. It was automatically converted to the canonical taxon.";
        $response['original_taxon'] = $testSpecies;
        # Note that Unicode characters may return escaped! eg, \u00e9.
        $response['validated_taxon'] = $aWebPretty;
        returnAjax($response);
    }
    # Cool, so the genus exists.
    $speciesList = array();
    $speciesListComparative = array();
    foreach ($aWebListArray as $row => $entry) {
        if ($row == 0) {
            continue;
        } # Prevent match on "species"
        $genus = strtolower($entry[3]);
        if ($genus == $providedGenus) {
            $species = $entry[5];
            $speciesList[$species] = $row;
            $speciesListComparative[] = $species;
        }
    }
    if (!array_key_exists($providedSpecies, $speciesList)) {
        # Are they using an old name?
        $testSpecies = $providedGenus.' '.$providedSpecies;
        if (!array_key_exists($testSpecies, $synonymList)) {
          # For 'nov. sp.', 'sp.' variants, and with following digits,
          # check genus only
          # See
          # http://regexr.com/3d1kb
          if (preg_match('/^(nov[.]{0,1} ){0,1}(sp[.]{0,1}([ ]{0,1}\d+){0,1})$/m', $providedSpecies)) {
                # OK, they were just looking for a genus anyway
                $row = $genusList[$providedGenus];
                $aWebMatch = $aWebListArray[$row];
                $aWebCols = $aWebListArray[0];
                $aWebPretty = array();
                $skipCols = array(
                    'species',
                    'gaa_name',
                    'common_name',
                    'synonymies',
                    'itis_names',
                    'iucn',
                    'isocc',
                    'intro_isocc',
                );
                foreach ($aWebMatch as $key => $val) {
                    $prettyKey = $aWebCols[$key];
                    if (!in_array($prettyKey, $skipCols)) {
                        $prettyKey = str_replace('/', '_or_', $prettyKey);
                        if (strpos($val, ',') !== false) {
                            $val = explode(',', $val);
                            foreach ($val as $k => $v) {
                                $val[$k] = trim($v);
                            }
                        }
                        $aWebPretty[$prettyKey] = $val;
                    }
                }
                # Pretty format the 'nov sp'/'sp'/etc
                $aWebPretty['species'] = preg_match('/^nov[.]{0,1} (sp[.]{0,1}([ ]{0,1}(\d+)){0,1})$/m', $providedSpecies) ?
                                       trim(preg_replace('/^nov[.]{0,1} (sp[.]{0,1}([ ]{0,1}(\d+)){0,1})$/m', 'nov. sp. $3', $providedSpecies)) :
                                       trim(preg_replace('/^sp[.]{0,1}([ ]{0,1}(\d+)){0,1}$/m', 'sp. $2', $providedSpecies));
                $response['notices'][] = "You provided a generic species '".$aWebPretty['species']."'. Only the genus has been validated.";
                $response['status'] = true;
                # Note that Unicode characters may return escaped! eg, \u00e9.
                $response['validated_taxon'] = $aWebPretty;
                returnAjax($response);
            }
            # Gender? Latin sucks.
            # See: sylvaticus vs sylvatica
            if (strlen($providedSpecies) > 3) {
                $key = array_find(substr($providedSpecies, 0, -3), $speciesListComparative);
            } else {
                $key = false;
            }
            if ($key !== false) {
                $response['notices'][] = 'FUZZY_SPECIES_MATCH';
                $response['notices'][] = "This is just a probable match for your entry '$testSpecies'. We ignored the species gender ending for you. If this isn't a match, your species is invalid";
                $trueSpecies = $speciesListComparative[$key];
                $aWebRow = $speciesList[$trueSpecies];
                $aWebMatch = $aWebListArray[$aWebRow];
                $aWebCols = $aWebListArray[0];
                $aWebPretty = array();
                foreach ($aWebMatch as $key => $val) {
                    $prettyKey = $aWebCols[$key];
                    $prettyKey = str_replace('/', '_or_', $prettyKey);
                    if (strpos($val, ',') !== false) {
                        $val = explode(',', $val);
                        foreach ($val as $k => $v) {
                            $val[$k] = trim($v);
                        }
                    }
                    $aWebPretty[$prettyKey] = $val;
                }
                if (empty($aWebPretty['subspecies']) && !empty($get['subspecies'])) {
                    $aWebPretty['subspecies'] = $get['subspecies'];
                }
                $response['status'] = true;
                $response['original_taxon'] = $testSpecies;
                # Note that Unicode characters may return escaped! eg, \u00e9.
                $response['validated_taxon'] = $aWebPretty;
                returnAjax($response);
            }
            # Nope, just failed
            $response['error'] = 'INVALID_SPECIES';
            $response['human_error'] = "'$providedSpecies' isn't a valid AmphibiaWeb species in the genus '$providedGenus', nor is '$testSpecies' a recognized synonym.";
            $response['human_error_html'] = "'<span class='species'>$providedSpecies</span>' isn't a valid AmphibiaWeb species in the genus '<span class='genus'>$providedGenus</span>', nor is '<span class='sciname'>$testSpecies</span>' a recognized synonym.";
            returnAjax($response);
        }
        # Let's play the synonym game again!
        $row = $synonymList[$testSpecies];
        $aWebMatch = $aWebListArray[$row];
        $aWebCols = $aWebListArray[0];
        $aWebPretty = array();
        foreach ($aWebMatch as $key => $val) {
            $prettyKey = $aWebCols[$key];
            $prettyKey = str_replace('/', '_or_', $prettyKey);
            if (strpos($val, ',') !== false) {
                $val = explode(',', $val);
                foreach ($val as $k => $v) {
                    $val[$k] = trim($v);
                }
            }
            $aWebPretty[$prettyKey] = $val;
        }
        if (empty($aWebPretty['subspecies']) && !empty($get['subspecies'])) {
            $aWebPretty['subspecies'] = $get['subspecies'];
        }
        $response['status'] = true;
        $response['notices'][] = "Your entry '$testSpecies' was a synonym in the AmphibiaWeb database. It was automatically converted to the canonical taxon.";
        $response['original_taxon'] = $testSpecies;
        # Note that Unicode characters may return escaped! eg, \u00e9.
        $response['validated_taxon'] = $aWebPretty;
        returnAjax($response);
    }
    # The genus and species is valid.
    # Prep for the user response
    $aWebRow = $speciesList[$providedSpecies];
    $aWebMatch = $aWebListArray[$aWebRow];
    $aWebCols = $aWebListArray[0];
    $aWebPretty = array();
    foreach ($aWebMatch as $key => $val) {
        $prettyKey = $aWebCols[$key];
        $prettyKey = str_replace('/', '_or_', $prettyKey);
        if (strpos($val, ',') !== false) {
            $val = explode(',', $val);
            foreach ($val as $k => $v) {
                $val[$k] = trim($v);
            }
        }
        $aWebPretty[$prettyKey] = $val;
    }
    if (empty($aWebPretty['subspecies']) && !empty($get['subspecies'])) {
        $aWebPretty['subspecies'] = $get['subspecies'];
    }
    $response['status'] = true;
    # Note that Unicode characters may return escaped! eg, \u00e9.
    $response['validated_taxon'] = $aWebPretty;
    returnAjax($response);
}

function validateCaptcha($get)
{
    global $recaptcha_private_key;
    $params = array(
        'secret' => $recaptcha_private_key,
        'response' => $get['recaptcha_response'],
    );
    $raw_response = do_post_request('https://www.google.com/recaptcha/api/siteverify', $params);
    $response = json_decode($raw_response, true);
    if ($response['success'] === false) {
        switch ($response['error-codes'][0]) {
        case 'invalid-input-response':
            $parsed_error = 'Invalid CAPTCHA. Please retry it.';
        case 'missing-input-response':
            $parsed_error = 'Please be sure to solve the CAPTCHA.';
        default:
            $parsed_error = 'There was a problem with your CAPTCHA. Please try again.';
        }
        $a = array(
            'status' => false,
            'error' => 'Bad CAPTCHA',
            'human_error' => $parsed_error,
            'recaptcha_response' => array(
                'raw_response' => $raw_response,
                'parsed_response' => $response,
            ),
        );
    } else {
        if(!empty($get["project"])) {
            global $db;
            $project = $db->sanitize($get['project']);
            $query = array(
                'project_id' => $project,
            );
            $resultCols = array(
                "author_data",
                "technical_contact",
                "technical_contact_email",
            );
            $result = $db->getQueryResults($query, $resultCols, 'AND', false, true);
            $author_data = json_decode($result[0]['author_data'], true);
            $a = array(
                'status' => true,
                'author_data' => $author_data,
                "technical" => array(
                    "name" => $result[0]["technical_contact"],
                    "email" => $result[0]["technical_contact_email"],
                ),
                'raw_result' => $result[0],
            );
        }
        if(!empty($get["user"])) {
            global $udb;
            $viewUser = $udb->sanitize($get["user"]);
            $cols = array(
                "username",
                "phone",
                "alternate_email",
                "public_profile",
            );
            $query = array(
                "dblink" => $viewUser,
            );
            $result = $udb->getQueryResults($query, $cols, "OR", false, true);
            if(empty($result)) {
                $response = $udb->getQueryResults($query, $cols, "OR", false, true, false, true);
            } else {
                $response = $result[0];
                $response["public_profile"] = json_decode($response["public_profile"], true);
            }
            $a = array(
                "status" => true,
                "response" => $response,
                "raw_result" => $result,
                "query" => $get,
            );
        }
    }
    returnAjax($a);
}




function getChartData($chartDataParams) {
    global $default_table, $db;
    $mapType = "";
    /***
     * Create opportunities for several bins
     *
     * Bin by:
     * - location
     * - time
     * - species
     * - positive species
     *
     ***/
    switch($chartDataParams["sort"]) {
    case "time":
        # Sort by time
        break;
    case "species":
        # Sort by species alphabetically
        break;
    case "location":
        # Location bin
        # Have to hit the Google API for each one to check the
        # country per coordinate
        break;
    case "infection":
    default:
        # Sort by `disease_positive`
        $query = "SELECT `disease_positive`, `disease_samples` FROM `$default_table`";
        # do the query
        $db->invalidateLink();
        $result = mysqli_query($db->getLink(), $query);
        if($result === false) {
          returnAjax(array(
            "status" => false,
            "error" => mysqli_error($db->getLink()),
            "human_error" => "There was an application error getting your chart data",
          ));
        }
        $returnedRows = mysqli_num_rows($result);
        # Set up how we'll count this
        $countedProjects = array();
        # By default, we want to view a percentage distribution
        if(empty($chartDataParams["percent"])) $chartDataParams["percent"] = true;
        $percent = toBool($chartDataParams["percent"]);
        # By default, we want it grouped, unless it's a percent.
        if(empty($chartDataParams["group"])) $chartDataParams["group"] = $percent ? false:true;
        $grouped = toBool($chartDataParams["group"]);
        /***
        * We have a few potential counting methods.
        *
        * 1) Binned by percent -- CEIL(disease_positive /
        * diesase_samples)
        * 2) Binned by grouped percent -- 0-10%, 11%-25%, 26%-50%,
        * 51%-75%, 76%-89%, 90%+
        * 3) Binned by count range -- 0-10, 11-25, 26-50, 51-100, 101-250,
        * 251-500, 501-1000, 1001-2000, 2001-5000, 5001-9999, 10000+
        * 4) A raw count list.
        ***/
        $countCase = null;
        $checkRange = null;
        $labels = array();
        $hasConstructedLabels = false;
        $rowCount = 0;
        if ($percent) {
          if ($group) {
            # Grouped percentages
            $countCase = 2;
            $countedProjects = array(
              "0-10" => 0,
              "11-25" => 0,
              "26-50" => 0,
              "51-75" => 0,
              "76-89" => 0,
              "90+" => 0,

            );
            $checkRange = array(
              array(
                "min" => 0,
                "max" => 10,
                "key" => "0-10",
              ),
              array(
                "min" => 11,
                "max" => 25,
                "key" => "11-25",
              ),
              array(
                "min" => 26,
                "max" => 50,
                "key" => "26-50",
              ),
              array(
                "min" => 51,
                "max" => 75,
                "key" => "51-75",
              ),
              array(
                "min" => 76,
                "max" => 89,
                "key" => "76-89",
              ),
              array(
                "min" => 90,
                "max" => 100,
                "key" => "90+",
              ),
            );
          } else {
            # Raw percentages
            $countCase = 1;
            $i = 0;
            while($i <= 100) {
              $countedProjects[$i] = 0;
              $labels[] = $i."%";
              $i++;
            }
            $hasConstructedLabels = true;
          }
        } else {
          if ($group) {
            $countCase = 3;
            $countedProjects = array(
              "0-10" => 0,
              "11-25" => 0,
              "26-50" => 0,
              "51-100" => 0,
              "101-250" => 0,
              "251-500" => 0,
              "501-1000" => 0,
              "1001-2000" => 0,
              "2001-5000" => 0,
              "5001-9999" => 0,
              "10000+" => 0,

            );
            $checkRange = array(
              array(
                "min" => 0,
                "max" => 10,
                "key" => "0-10",
              ),
              array(
                "min" => 11,
                "max" => 25,
                "key" => "11-25",
              ),
              array(
                "min" => 26,
                "max" => 50,
                "key" => "26-50",
              ),
              array(
                "min" => 51,
                "max" => 100,
                "key" => "51-100",
              ),
              array(
                "min" => 101,
                "max" => 250,
                "key" => "101-250",
              ),
              array(
                "min" => 251,
                "max" => 500,
                "key" => "251-500",
              ),
              array(
                "min" => 501,
                "max" => 1000,
                "key" => "501-1000",
              ),
              array(
                "min" => 1001,
                "max" => 2000,
                "key" => "1001-2000",
              ),
              array(
                "min" => 2001,
                "max" => 5000,
                "key" => "2001-5000",
              ),
              array(
                "min" => 5001,
                "max" => 9999,
                "key" => "5001-9999",
              ),
              array(
                "min" => 10000,
                "max" => PHP_INT_MAX,
                "key" => "10000+",
              ),
            );
          } else {
            $countCase = 4;
          }
        }
        # We now have the parameters to build the chart data
        try {
          # Iterate over each row of the data
          while ($row = mysqli_fetch_assoc($result)) {
            # Skip entries with no data
            if(intval($row["disease_samples"]) == 0) continue;
            $rowCount++;
            # Construct the counts based on the case above
            switch($countCase) {
              case 1:
              $calcPercent = ceil(100 * intval($row["disease_positive"]) / intval($row["disease_samples"]));
              $countedProjects[$calcPercent]++;
              break;
              case 2:
              $calcPercent = ceil(100 * intval($row["disease_positive"]) / intval($row["disease_samples"]));
              foreach($checkRange as $range)  {
                $key = $range["key"];
                if(!$hasConstructedLabels) $labels[] = $key;
                if($calcPercent <= $range["max"]) {
                  # Array order is guaranteed, so this is fine
                  $countedProjects[$key]++;
                  if($hasConstructedLabels) break;

                }
              }
              break;
              case 3:
              foreach($checkRange as $range)  {
                $key = $range["key"];
                if(!$hasConstructedLabels) $labels[] = $key;
                if($row["disease_samples"] <= $range["max"]) {
                  # Array order is guaranteed, so this is fine
                  $countedProjects[$key]++;
                  if($hasConstructedLabels) break;

                }
              }
              break;
              case 4:
              $count = $row["disease_samples"];
              if(empty($countedProjects[$count])) $countedProjects[$count] = 0;
              $countedProjects[$count]++;
              break;
            }
            $hasConstructedLabels = true;
          }
          if ($countCase == 4) {
            ksort($countedProjects);
            # Build the labels
            foreach($countedProjects as $countSamples => $projectCount ) {
              $labels[] = $countSamples;
            }
          }
          # We now have a valid countedProjects value, and some labels
          $chartData = array(
            "labels" => $labels,
            "datasets" => array(
              array(
                "label" => "Project Count",
                "data" => $countedProjects,
              ),
            ),
          );
          returnAjax(array(
            "status" => true,
            "data" => $chartData,
            "rows" => $rowCount,
            "format" => "chart.js",
            "provided" => $chartDataParams,
            "parsed_options" => array("group" => $group, "percent" => $percent),
                     // "query" => $query,
                     // "returned_rows" => $returnedRows,
          ));
        } catch (Exception $e) {
          returnAjax(array(
            "status" => false,
            "error" => $e->getMessage(),
            "human_error" => "There was an error fetching your dataset",
          ));
        }
        break;
      }
      returnAjax(array(
        "status" => false,
        "error" => "NO_CAUGHT_CASE",
        "human_error" => "There was an application error parsing your chart data request",
      ));
    }
