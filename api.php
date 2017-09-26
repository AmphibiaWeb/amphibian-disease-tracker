<?php



/*****************
* Setup
 *****************/

#$show_debug = true;

if ($show_debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('API is running in debug mode!');
}

require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
$start_script_timer = microtime_float();
# This is a public API
header('Access-Control-Allow-Origin: *');

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);

$flatTable = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, "records_list");

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
# parse_str($_SERVER['QUERY_STRING'],$_POST);
$do = isset($_REQUEST['action']) ? strtolower($_REQUEST['action']) : null;

switch ($do) {
    case 'upload':
        # Set access-control header
        header('Access-Control-Allow-Origin: amphibiandisease.org');
        # We still do an SqlApiPush
    case 'fetch':
        doCartoSqlApiPush($_REQUEST);
        break;
    case 'validate':
        returnAjax(doAWebValidate($_REQUEST));
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
    case "taxon":
         returnAjax(getTaxonData($_REQUEST));
        break;
    case "iucn":
        returnAjax(getTaxonIucnData($_REQUEST));
        break;
    case "aweb":
    case "amphibiaweb":
        returnAjax(getTaxonAWebData($_REQUEST));
        break;
    case "higher_taxa":
        returnAjax(updateTaxonRecordHigherInformation());
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
        if ($isAdmin) {
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
                if ($userReturn) {
                    returnAjax($response);
                }
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
                if ($userReturn) {
                    returnAjax($response);
                }
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
    /***
     *
     ***/
    global $cartodb_username, $cartodb_api_key, $db, $udb, $login_status;
    // error_reporting(E_ALL);
    // ini_set('display_errors', 1);
    // error_log('doCartoSqlApiPush is running in debug mode!');
    $sqlQuery = base64_decode(urldecode($get["sql_query"]));
    $method = "bdud";
    if (empty($sqlQuery) || !is_string($sqlQuery) || $sqlQuery == null) {
        $sqlQuery = decode64($get['sql_query'], true);
        $method = "d64";
        if (empty($sqlQuery)) {
            returnAjax(array(
                "status" => false,
                "error" => "QUERY_PARSE_ERROR",
                "raw" => $get["sql_query"],
                "provided" => $get,
            ));
        }
    }
    $eTest = print_r($sqlQuery, true);
    // returnAjax(array(
    //     "using" => $sqlQuery,
    //     "forced" => $eTest,
    //     "forced_empty" => empty($eTest),
    //     "empty" => empty($sqlQuery),
    //     "string" => is_string($sqlQuery),
    //     "nullish" => $sqlQuery == null,
    // ));

    $originalQuery = $sqlQuery;
    # If it's a "SELECT" style statement, make sure the accessing user
    # has permissions to read this dataset
    $searchSql = strtolower($sqlQuery);
    $queryPattern = '/(?i)([a-zA-Z]+(?: +INTO)?) +.*(?:FROM)?[ `]*(t[0-9a-f]{10,}[_]?[0-9a-f]*)[ `]*.*[;]?/m';
    $statements = explode(');', $sqlQuery);
    $checkedTablePermissions = array();
    $pidList = array();
    $effectiveKey = 0;
    $statementsSize = sizeof($statements);
    foreach ($statements as $k => $statement) {
        $statement = trim($statement);
        if (empty($statement)) {
            unset($statements[$k]);
            continue;
        }
        $effectiveKey++;
        $sqlAction = preg_replace($queryPattern, '$1', $statement);
        $sqlAction = strtolower(str_replace(" ", "", $sqlAction));
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
            if (!empty($pid)) {
                $requestedPermission = $restrictedActions[$sqlAction];
                $pArr = explode(",", $row["access_data"]);
                $permissions = array();
                foreach ($pArr as $access) {
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
        } elseif (!isset($unrestrictedActions[$sqlAction])) {
            # Unrecognized query type
            $allPermissionsMajor = array_merge($restrictedActions, $unrestrictedActions);
            $allPermissions = array();
            foreach ($allPermissionsMajor as $permission => $requiredPermission) {
                $allPermissions[] = $permission;
            }
            $actionExists = in_array($sqlAction, $allPermissions);
            $simpleStatements = json_decode(json_encode($statements), true);
            $simpleStatement = $simpleStatements[$effectiveKey];
            $hasWeirdEdgeCase = empty($simpleStatement) || !$actionExists;
            # If we hit this edge case and we're the last statement
            # anyway, we can skip it
            $okToSkip = $hasWeirdEdgeCase && $effectiveKey == $statementsSize;
            if ($okToSkip) {
                continue;
            }
            returnAjax(array(
                "status" => false,
                "error" => "UNAUTHORIZED_QUERY_TYPE",
                "query_type" => $sqlAction,
                "args_provided" => $get,
                "statement_context" => array(
                    "statements_count" => $statementsSize,
                    "statement_parsed" => $statement,
                    "effective_key" => $effectiveKey,
                    "action_exists" => $actionExists,
                    "allowed_actions" => $allPermissions,
                    "statement_number" => $k,
                    "statements" => $statements,
                ),
                "read_query" => $sqlQuery,
            ));
        }
        if (empty($statement)) {
            returnAjax(array(
                'status' => false,
                'error' => 'INVALID_QUERY',
                'args_provided' => $get,
            ));
        }
    }
    $cartoPostUrl = 'https://'.$cartodb_username.'.cartodb.com/api/v2/sql';
    $cartoArgSuffix = '&api_key='.$cartodb_api_key;
    $l = sizeof($statements);
    $lastIndex = $l - 1;
    foreach ($statements as $k => $statement) {
        # Re-append the closing parens
        if (substr_count($statement, "(") === substr_count($statement, ")") + 1) {
            $statements[$k] = $statement . ")";
        }
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
        );
        if ($show_debug === true) {
            $debug = array(
                "raw" => $get['sql_query'],
                "d64" => decode64($get['sql_query'], true),
                "foo" => base64_decode(urldecode($get["sql_query"])),
                "bar" => base64_decode($get["sql_query"]),
                "baz" => urldecode(base64_decode($get["sql_query"])),
                "method" => $method,
                # "urls_posted" => $urls,
                );
            $response = array_merge($response, $debug);
        }
        if (boolstr($get['blobby'])) {
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
     * Validate a taxon with Amphibiaweb.
     *
     * @param array $get ->
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
            if (array_key_exists($providedGenus, $synonymGenusList) && preg_match('/^(nov[.]{
			0,1
		}
		){
			0,1
		}
		(sp[.]{
			0,1
		}
		([ ]{
			0,1
		}
		\d+){
			0,1
		}
		)$/m', $providedSpecies)) {
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
                $aWebPretty['species'] = preg_match('/^nov[.]{
			0,1
		}
		(sp[.]{
			0,1
		}
		([ ]{
			0,1
		}
		(\d+)){
			0,1
		}
		)$/m', $providedSpecies) ?
                                       trim(preg_replace('/^nov[.]{
			0,1
		}
		(sp[.]{
			0,1
		}
		([ ]{
			0,1
		}
		(\d+)){
			0,1
		}
		)$/m', 'nov. sp. $3', $providedSpecies)) :
                                       trim(preg_replace('/^sp[.]{
			0,1
		}
		([ ]{
			0,1
		}
		(\d+)){
			0,1
		}
		$/m', 'sp. $2', $providedSpecies));
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
    return $response;
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
                break;
            case 'missing-input-response':
                $parsed_error = 'Please be sure to solve the CAPTCHA.';
                break;
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
        if (!empty($get["project"])) {
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
        if (!empty($get["user"])) {
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
            if (empty($result)) {
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




function getChartData($chartDataParams)
{
    global $default_table, $db, $flatTable, $login_status;
    $suFlag = $login_status['detail']['userdata']['su_flag'];
    $isSu = boolstr($suFlag);
    $uid = $login_status["detail"]["uid"];
    $mapType = "";
    # Build the permissions intersection
    if ($isSu !== true) {
        $authorizedIntersectQuery = "SELECT `project_id` FROM `".$db->getTable()."` WHERE `public` is true";
        if (!empty($uid)) {
            $authorizedIntersectQuery .= " OR `access_data` LIKE '%".$uid."%' OR `author` LIKE '%".$uid."%'";
        }
    } else {
        # A superuser gets to view everything
        $authorizedIntersectQuery = "SELECT `project_id` FROM `".$db->getTable()."`";
    }

    $authorizedIntersect = "INNER JOIN ($authorizedIntersectQuery) AS authorized ON authorized.project_id = ";
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
    if (!isset($chartDataParams["include_sp"])) {
        $chartDataParams["include_sp"] = false;
    }
    $ignoreSp = boolstr($chartDataParams["include_sp"]) ? "":"WHERE `specificepithet` !='sp.'";
    $stringDisease = "";
    switch (strtolower($chartDataParams["disease"])) {
        case "bd":
            $tested = "`diseasetested` = 'Bd' AND `genus` IS NOT NULL";
            $andTested = " AND $tested";
            if (empty($ignoreSp)) {
                $where = $ignoreSp . " AND $tested";
            } else {
                $where = "where " . $tested;
            }
            $stringDisease = "for Bd";
            break;
        case "bsal":
            $tested = "`diseasetested` = 'Bsal' AND `genus` IS NOT NULL";
            $andTested = " AND $tested";
            if (empty($ignoreSp)) {
                $where = $ignoreSp . $andTested;
            } else {
                $where = "where " . $tested;
            }
            $stringDisease = "for Bsal";
            break;
        default:
            $stringDisease = "for Bd and Bsal";
            if (empty($ignoreSp)) {
                $ignoreSp = " WHERE `genus` IS NOT NULL";
            } else {
                $ignoreSp .= " AND `genus` IS NOT NULL";
            }
            $where = $ignoreSp;
            $tested = "";
            $andTested = "";
    }
    switch ($chartDataParams["bin"]) {
        case "time":
            # Sort by time
            break;
        case "species":
            # Sort by species alphabetically
            switch ($chartDataParams["sort"]) {
                case "species":
                    $query = "select `genus`, `specificepithet`, count(*) as count from `".$flatTable->getTable()."` AS records $authorizedIntersect records.project_id $where group by `genus`, `specificepithet` order by `genus`, `specificepithet`";
                    $result = mysqli_query($flatTable->getLink(), $query);
                    if ($result === false) {
                        returnAjax(array(
                            "status" => false,
                            "error" => mysqli_error($flatTable->getLink()),
                            "human_error" => "We were unable to retrieve the records at this time",
                        ));
                    }
                    $labels = array();
                    $data = array();
                    $rowCount = 0;
                    while ($row = mysqli_fetch_assoc($result)) {
                        # Make Chart.js data
                        $species = $row["genus"]." ".$row["specificepithet"];
                        $labels[] = $species;
                        $data[] = $row["count"];
                        $rowCount++;
                    }
                    $chartData = array(
                        "labels" => $labels,
                        "datasets" => array(
                            array(
                                "label" => "Species Sample Count",
                                "data" => $data,
                            ),
                        ),
                    );
                    returnAjax(array(
                        "status" => true,
                        "data" => $chartData,
                        "axes" => array(
                            "x" => "Species",
                            "y" => "Samples"
                        ),
                        "title" => "Samples Per Taxon $stringDisease",
                        "use_preprocessor" => false,
                        "rows" => $rowCount,
                        "format" => "chart.js",
                        "provided" => $chartDataParams,
                        "full_description" => "Samples taken per species",
                    ));
                    break;
                case "genus":
                case "samples":
                default:
                    if ($chartDataParams["sort"] == "samples") {
                        $orderBy = "count DESC, `genus`";
                    } else {
                        $orderBy = "`genus`";
                    }
                    $query = "select `genus`,  count(*) as count from `".$flatTable->getTable()."` AS records $authorizedIntersect records.project_id $where group by `genus` order by $orderBy";
                    $result = mysqli_query($flatTable->getLink(), $query);
                    if ($result === false) {
                        returnAjax(array(
                            "status" => false,
                            "error" => mysqli_error($flatTable->getLink()),
                            "human_error" => "We were unable to retrieve the records at this time",
                        ));
                    }
                    $labels = array();
                    $data = array();
                    $rowCount = 0;
                    while ($row = mysqli_fetch_assoc($result)) {
                        # Make Chart.js data
                        $species = $row["genus"];
                        $labels[] = $species;
                        $data[] = $row["count"];
                        $rowCount++;
                    }
                    $chartData = array(
                        "labels" => $labels,
                        "datasets" => array(
                            array(
                                "label" => "Genus Sample Count",
                                "data" => $data,
                            ),
                        ),
                    );
                    returnAjax(array(
                        "status" => true,
                        "data" => $chartData,
                        "axes" => array(
                            "x" => "Genus",
                            "y" => "Samples"
                        ),
                        "title" => "Samples Per Genus $stringDisease",
                        "use_preprocessor" => false,
                        "rows" => $rowCount,
                        "format" => "chart.js",
                        "provided" => $chartDataParams,
                        "full_description" => "Samples taken per genus",
                        "include_new_species" => boolstr($chartDataParams["include_sp"]),
                    ));
            }
            break;
        case "location":
            # Location bin
            # Have to hit the Google API for each one to check the
            # country per coordinate
            # Look up the carto id fields
            $labels = array();
            $orderBy = $chartDataParams["sort"];
            $doInfectionSort = false;
            if (empty($orderBy)) {
                $orderBy = "samples DESC";
            } else {
                if ($orderBy == "infection") {
                    # We're going to do some magic
                    $doInfectionSort = true;
                    $orderBy = "samples DESC";
                } else {
                    $orderBy = $db->sanitize($orderBy);
                    if (!$flatTable->columnExists($orderBy, false)) {
                        $orderBy = "samples DESC";
                    }
                }
            }
            if (empty($where)) {
                $where = "WHERE `diseasedetected` IS NOT NULL";
            } else {
                $where .= " AND `diseasedetected` IS NOT NULL";
            }
            $allQuery = "SELECT `country`, count(*) as samples FROM `".$flatTable->getTable()."` AS records $authorizedIntersect records.project_id $where GROUP BY country ORDER BY $orderBy";
            $posQuery = "SELECT `country`, count(*) as samples FROM `".$flatTable->getTable()."` AS records $authorizedIntersect records.project_id $where AND `diseasedetected`='true' GROUP BY country ORDER BY $orderBy";
            $negQuery = "SELECT `country`, count(*) as samples FROM `".$flatTable->getTable()."` AS records $authorizedIntersect records.project_id $where AND `diseasedetected`='false' GROUP BY country ORDER BY $orderBy"; //or `diseasedetected` is null
            $result = mysqli_query($flatTable->getLink(), $allQuery);
            if ($result === false) {
                returnAjax(array(
                    "status" => false,
                    "error" => mysqli_query($db->getLink()),
                    "human_error" => "Error looking up bounding boxes",
                ));
            }
            $posResult = mysqli_query($flatTable->getLink(), $posQuery);
            $negResult = mysqli_query($flatTable->getLink(), $negQuery);
            $rowCount = 0;
            $returnedRows = mysqli_num_rows($result);
            $chartData = array();
            $chartDatasetData = array();
            $chartPosDatasetData = array();
            $chartNegDatasetData = array();
            $posData = array();
            while ($posRow = mysqli_fetch_assoc($posResult)) {
                $posData[$posRow["country"]] = $posRow["samples"];
            }
            $negData = array();
            while ($negRow = mysqli_fetch_assoc($negResult)) {
                $negData[$negRow["country"]] = $negRow["samples"];
            }
            if ($doInfectionSort) {
                $baseData = array();
                $posBaseData = array();
                $negBaseData = array();
            }
            while ($row = mysqli_fetch_assoc($result)) {
                if (empty($row["country"])) {
                    continue;
                }
                $labels[] = $row["country"];
                $key = $row["country"] . " total";
                $negSamples = null;
                $posSamples = null;
                if (array_key_exists($row["country"], $posData)) {
                    $posSamples = intval($posData[$row["country"]]);
                }
                if (array_key_exists($row["country"], $negData)) {
                    $negSamples = intval($negData[$row["country"]]);
                }
                if (empty($posSamples)) {
                    $posSamples = 0;
                }
                if (empty($negSamples)) {
                    $negSamples = 0;
                }
                if (!$doInfectionSort) {
                    $chartDatasetData[] = intval($row["samples"]);
                    $chartPosDatasetData[] = $posSamples;
                    $chartNegDatasetData[] = $negSamples;
                    $indeterminant = intval($row["samples"]) - $posSamples - $negSamples;
                    if ($indeterminant < 0) {
                        $indeterminant = 0;
                    }
                    $chartIndDatasetData[] = $indeterminant;
                } else {
                    # Percent to three decimals
                    $percent = intval($posSamples) * 10000 / intval($row["samples"]);
                    $smartKey = "$percent";
                    while (array_key_exists($smartKey, $baseData)) {
                        $smartKey = $smartKey . "0";
                    }
                    $baseData[$smartKey] = array(
                        "count" => intval($row["samples"]),
                        "country" => $row["country"],
                    );
                    $posBaseData[$smartKey] = $posSamples;
                    $negBaseData[$smartKey] = $negSamples;
                }
            }
            if ($doInfectionSort) {
                $labels = array();
                ksort($baseData, SORT_NUMERIC);
                foreach ($baseData as $k => $v) {
                    $labels[] = $v["country"];
                    $chartDatasetData[] = $v["count"];
                    $chartPosDatasetData[] = $posBaseData[$k];
                    $chartNegDatasetData[] = $negBaseData[$k];
                    $indeterminant = $v["count"] - $posBaseData[$k] - $negBaseData[$k];
                    if ($indeterminant < 0) {
                        $indeterminant = 0;
                    }
                    $chartIndDatasetData[] = $indeterminant;
                    $by = "by infection percent";
                }
            } else {
                $by = "by ".$orderBy;
            }
            $chartData = array(
                "labels" => $labels,
                "stacking" => array("x" => false, "y" => true),
                "datasets" => array(
                    // array(
                    //     "label" => "Total Samples",
                    //     "data" => $chartDatasetData,
                    //     "stack" => "totals",
                    // ),
                    array(
                        "label" => "Positive Samples",
                        "data" => $chartPosDatasetData,
                        "stack" => "PosNeg",
                    ),
                    array(
                        "label" => "Negative Samples",
                        "data" => $chartNegDatasetData,
                        "stack" => "PosNeg",
                    ),
                ),
            );
            $response = array(
                "status" => true,
                "data" => $chartData,
                "axes" => array(
                    "x" => "Country",
                    "y" => "Sample Count"
                ),
                "title" => "Samples Per Country",
                "use_preprocessor" => false,
                "rows" => $rowCount,
                "format" => "chart.js",
                "provided" => $chartDataParams,
                "full_description" => "Sample representation per country, $by",
                "basedata" => $baseData,
            );
            if ($show_debug === true) {
                $response["query"] = array(
                    "all" => $allQuery,
                    "pos" => $posQuery,
                    "neg" => $negQuery,
                );
            }
            returnAjax($response);
            break;
        case "infection":
        default:
            # Sort by `disease_positive`
            $query = "SELECT `project_id`,`project_title`,`disease_positive`, `disease_samples` FROM `$default_table` AS records $authorizedIntersect records.project_id";
            # do the query
            $db->invalidateLink();
            $result = mysqli_query($db->getLink(), $query);
            if ($result === false) {
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
            if (empty($chartDataParams["percent"])) {
                $chartDataParams["percent"] = true;
            }
            $percent = toBool($chartDataParams["percent"]);
            # By default, we want it grouped, unless it's a percent.
            if (empty($chartDataParams["group"])) {
                $chartDataParams["group"] = $percent ? false:true;
            }
            $group = toBool($chartDataParams["group"]);
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
            $binningProjectResults = array();
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
                    while ($i <= 100) {
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
                    if (intval($row["disease_samples"]) == 0) {
                        continue;
                    }
                    $rowCount++;
                    # Construct the counts based on the case above
                    switch ($countCase) {
                        case 1:
                            $calcPercent = ceil(100 * intval($row["disease_positive"]) / intval($row["disease_samples"]));
                            $countedProjects[$calcPercent]++;
                            break;
                        case 2:
                            $calcPercent = ceil(100 * intval($row["disease_positive"]) / intval($row["disease_samples"]));
                            foreach ($checkRange as $range) {
                                $key = $range["key"];
                                if (!$hasConstructedLabels) {
                                    $labels[] = $key;
                                    $binningProjectResults[$key] = array();
                                }
                                if ($calcPercent <= $range["max"] && $calcPercent >= $range["min"]) {
                                    # Array order is guaranteed, so this is fine
                                    $countedProjects[$key]++;
                                    $binningProjectResults[$key][] = array($row['project_id'] => $row['project_title']);
                                    if ($hasConstructedLabels) {
                                        break;
                                    }
                                }
                            }
                            break;
                        case 3:
                            foreach ($checkRange as $range) {
                                $key = $range["key"];
                                if (!$hasConstructedLabels) {
                                    $labels[] = $key;
                                }
                                if ($row["disease_positive"] <= $range["max"] && $row["disease_positive"] >= $range["min"]) {
                                    # Array order is guaranteed, so this is fine
                                    $countedProjects[$key]++;
                                    if ($hasConstructedLabels) {
                                        break;
                                    }
                                }
                            }
                            break;
                        case 4:
                            $count = $row["disease_positive"];
                            if (empty($countedProjects[$count])) {
                                $countedProjects[$count] = 0;
                            }
                            $countedProjects[$count]++;
                            break;
                    }
                    $hasConstructedLabels = true;
                }
                if ($countCase == 4) {
                    ksort($countedProjects);
                    # Build the labels
                    foreach ($countedProjects as $countSamples => $projectCount) {
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
                $adj = $countCase < 3 ? "percent":"number";
                returnAjax(array(
                    "status" => true,
                    "data" => $chartData,
                    "axes" => array(
                        "x" => "Taxon",
                        "y" => "Samples"
                    ),
                    "title" => "Infection Rate Per Project",
                    "data_details" => $binningProjectResults,
                    "rows" => $rowCount,
                    "format" => "chart.js",
                    "provided" => $chartDataParams,
                    "full_description" => "Project representation for $adj of positive samples",
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

function updateTaxonRecordHigherInformation()
{
    /***
     * Look at the records list and update all of the taxon's higher
     * information
     *
     *
     * This is a slow operation
     ***/
    global $db;
    $updateTime = microtime_float();
    $averageTaxonUpdate = array();
    $taxonCount = 0;
    $taxonSkipped = 0;
    $taxonFailed = 0;
    $queries = array();
    $errors = array();
    $db->setTable("records_list");
    $query = "SELECT `genus`,`specificepithet`, `taxonomy_modified` FROM `".$db->getTable()."` GROUP BY `genus`, `specificepithet`";
    $r = mysqli_query($db->getLink(), $query);
    $totalTaxa = mysqli_num_rows($r);
    while ($row = mysqli_fetch_assoc($r)) {
        if ($updateTime < $row["taxonomy_modified"] + 60*60*24) {
            # We've updated in the past 24 hours
            $taxonSkipped++;
            continue;
        }
        if (empty($row["genus"]) || empty($row["specificepithet"]) || $row["specificepithet"] == "sp.") {
            continue;
        }
        $start = microtime_float();
        $taxon = array(
            "genus" => $row["genus"],
            "species" => $row["specificepithet"],
        );
        $data = getTaxonAwebData($taxon);
        $order = $data["data"]["ordr"]; # Not a typo
        $family = $data["data"]["family"];
        $subfamily = $data["data"]["subfamily"];
        $clade = $data["data"]["clade"];
        # Update the database with these fields
        $updateQuery = "UPDATE `".$db->getTable()."` SET `order`='".$db->sanitize($order)."', `family`='".$db->sanitize($family)."', `subfamily`='".$db->sanitize($subfamily)."', `clade`='".$db->sanitize($clade)."', `taxonomy_modified`=".$updateTime." WHERE `genus`='".$taxon["genus"]."' AND `specificepithet`='".$taxon["species"]."'";
        #$queries[] = $updateQuery;
        # Do the query
        $r2 = mysqli_query($db->getLink(), $updateQuery);
        if ($r2 === false) {
            $taxonFailed++;
            $errors[] = mysqli_error($r2);
        }
        # Stats
        $elapsed = microtime_float() - $start;
        $averageTaxonUpdate[] = $elapsed;
        $taxonCount++;
        if (microtime_float() - $updateTime > 15) {
            # Do it only in tiny batches, to prevent script timeouts
            break;
        }
    }
    return array(
        "status" => true,
        "taxa_updated" => $taxonCount,
        "taxa_skipped" => $taxonSkipped,
        "taxa_not_examined" => $totalTaxa - $taxonCount - $taxonSkipped,
        "average_fetch_time" => array_sum($averageTaxonUpdate) / count($averageTaxonUpdate),
        "errors" => $errors,
        # "queries_to_be_executed" => $queries,
    );
}


function getTaxonData($taxonBase, $skipFetch = false)
{
    /***
     * Fetch the data for a given taxon
     ***/
    global $db;
    foreach ($taxonBase as $key => $value) {
        $taxonBase[$key] = $db->sanitize(strtolower($value));
    }
    if (empty($taxonBase["genus"])) {
        return array(
            "status" => false,
            "error" => "REQUIRED_COLS_MISSING",
        );
    }
    if (empty($taxonBase["species"])) {
        # Recursively call this across all the species
        #set_time_limit(0); # This can be very slow
        $query = "SELECT DISTINCT `specificepithet` FROM `records_list` WHERE `genus`='".$taxonBase["genus"]."' ORDER BY `specificEpithet`";
        $response = array(
          "status" => true,
          "genus" => $taxonBase["genus"],
          "isGenusLookup" => true,
          "taxa" => array(),
        );
        $r = mysqli_query($db->getLink(), $query);
        $i = 0;
        while ($row = mysqli_fetch_row($r)) {
            $newTaxonBase = $taxonBase;
            $newTaxonBase["species"] = $row[0];
            $taxonResponse = array(
                "species" => $row[0],
                "data" => getTaxonData($newTaxonBase, true),
            );
            $response["taxa"][] = $taxonResponse;
            $i++;
        }
        $response["count"] = $i;
        return $response;
    }
    if (!$skipFetch) {
        $iucn = getTaxonIucnData($taxonBase);
        $aweb = getTaxonAwebData($taxonBase);
    } else {
        $iucn = getTaxonIucnData($taxonBase);
        $aweb = array(
            "data" => array(
                "common_name" => array(),
            ),
        );
    }
    # Check ours
    $taxonString = $taxonBase["genus"]." ".$taxonBase["species"];
    $countQuery = "select `project_id`, `project_title` from `".$db->getTable()."` where sampled_species like '%$taxonString%'";
    $r = mysqli_query($db->getLink(), $countQuery);
    $adpData = array();
    if ($r !== false) {
        $count = mysqli_num_rows($r);
        $projects = array();
        while ($row = mysqli_fetch_row($r)) {
            $projects[$row[0]] = $row[1];
        }
        $adpData["project_count"] = $count;
        $adpData["projects"] = $projects;
    }
    $adpData["samples"] = 0;
    $adpData["countries"] = array();
    $samplesQuery = "select `country`,`diseasetested`, `diseasedetected`, `fatal` from `records_list` where `genus`='".$taxonBase["genus"]."' and `specificepithet`='".$taxonBase["species"]."' order by `diseasetested`";
    $r = mysqli_query($db->getLink(), $samplesQuery);
    $taxonBreakdown = array();
    if ($r !== false) {
        while ($row = mysqli_fetch_assoc($r)) {
            if (!in_array($row["country"], $adpData["countries"])) {
                $adpData["countries"][] = $row["country"];
            }
            $disease = $row["diseasetested"];
            if (!isset($taxonBreakdown[$disease])) {
                $taxonBreakdown[$disease] = array(
                    "detected" => array(
                        "true" => 0,
                        "false" => 0,
                        "no_confidence" => 0,
                        "total" => 0,
                    ),
                    "fatal" => array(
                        "true" => 0,
                        "false" => 0,
                        "unknown" => 0,
                        "total" => 0,
                    ),
                );
            }
            $taxonBreakdown[$disease]["detected"]["total"]++;
            $taxonBreakdown[$disease]["fatal"]["total"]++;
            switch (strtolower(strbool($row["diseasedetected"]))) {
                case "true":
                    $taxonBreakdown[$disease]["detected"]["true"]++;
                    break;
                case "false":
                    if (!empty($row["diseasedetected"]) && strtolower($row["diseasedetected"]) != "null") {
                        $taxonBreakdown[$disease]["detected"]["false"]++;
                        break;
                    }
                    # Otherwise, we want to treat this as the default case
                default:
                    $taxonBreakdown[$disease]["detected"]["no_confidence"]++;
            }
            switch (strtolower(strbool($row["fatal"]))) {
                case "true":
                    $taxonBreakdown[$disease]["fatal"]["true"]++;
                    break;
                case "false":
                    if (!empty($row["fatal"]) && strtolower($row["fatal"]) != "null") {
                        $taxonBreakdown[$disease]["fatal"]["false"]++;
                        break;
                    }
                    # Otherwise, fall through ...
                default:
                    $taxonBreakdown[$disease]["fatal"]["unknown"]++;
            }
        }
        $adpData["samples"] = mysqli_num_rows($r);
    }
    $adpData["disease_data"] = $taxonBreakdown;
    try {
        $mapUrl = "http://amphibiaweb.org/cgi/amphib_map?genus=".ucwords($taxonBase["genus"])."&species=".$taxonBase["species"];
        $bmUrl = get_final_url($mapUrl);
        # Pull out the shapefile
        $shapefile = "http://amphibiaweb.org/cgi/amphib_ws_shapefile?format=kml&genus=".ucwords($taxonBase["genus"])."&species=".$taxonBase["species"];
    } catch (Exception $e) {
        $mapUrl = false;
        $bmUrl = false;
        $shapefile = false;
    }
    $mapData = array(
        "url" => $mapUrl,
        "resolved_url" => $bmUrl,
        "shapefile" => $shapefile,
    );
    $response = array(
        "status" => true,
        "taxon" => array(
            "genus" => $taxonBase["genus"],
            "species" => $taxonBase["species"],
        ),
        "adp" => $adpData,
        "iucn" => array(
            "data" => $iucn["iucn"],
            "category" => $iucn["iucn_category"],
        ),
        "amphibiaweb" => array(
            "data" => $aweb["data"],
            "map" => $mapData,
        ),
        "isGenusLookup" => false,
    );
    return $response;
}


function getTaxonIucnData($taxonBase, $recursed = false)
{
    /***
     * Get the IUCN result for a given taxon
     *
     * @param array taxonBase -> an array requring keys "genus" and "species"
     ***/
    global $iucnToken, $db;
    $apiTarget = "http://apiv3.iucnredlist.org/api/v3/species/";
    $args = array("token" => $iucnToken);
    if (empty($taxonBase["genus"]) || empty($taxonBase["species"])) {
        return array(
            "status" => false,
            "error" => "REQUIRED_COLS_MISSING",
        );
    }
    if ($recursed) {
        # Logging
        error_log("Recursed entry calling with ".json_encode($taxonBase));
    }
    // $params = array(
    //     "genus" => $taxonBase["genus"],
    //     "species" => $taxonBase["species"],
    // );
    // $r = $db->doQuery($params, "*");
    // if ($r === false) {
    //     return array(
    //         "status" => false,
    //         "error" => "SPECIES_NOT_FOUND",
    //         "params" => $params,
    //     );
    // }
    // $taxon = mysqli_fetch_assoc($r);
    $response = array(
        "provided" => array(
            "taxon" => array($taxonBase),
        ),
    );
    # http://www.iucnredlist.org/static/categories_criteria_2_3#critical
    $iucnCategoryMap = array(
        "CR" => "Critically Endangered",
        "EN" => "Endangered",
        "VU" => "Vulnerable",
        "LC" => "Least Concern",
        "LR" => "Lower Risk",
        "CD" => "Conservation Dependant",
        "NT" => "Near Threatened",
        "EW" => "Extinct in the Wild",
        "EX" => "Extinct",
        "DD" => "Data Deficient",
        "NE" => "Not Evaluated",
    );
    # Set up so that we can skip this step if need be
    $badIucn = false;
    $badTaxon = false;
    $doIucn = true;
    if ($doIucn === true) {
        # IUCN returns an empty result unless "%20" is used to separate the
        # genus and species
        $nameTarget = $taxonBase["genus"] . "%20" . $taxonBase["species"];
        try {
            $iucnRawResponse = do_post_request($apiTarget.$nameTarget, $args);
            $iucnResponse = json_decode($iucnRawResponse, true);
        } catch (Exception $e) {
            // skip it?
        }
        if (isset($iucnResponse)) {
            $response["iucn"] =  $iucnResponse["result"][0];
            $response["iucn_category"] = $iucnCategoryMap[$response["iucn"]["category"]];
            if (empty($response["iucn_category"])) {
                $response["iucn_category"] = "No Data";
                $badTaxon = true;
                $response["status"] = false;
            } else {
                $response["status"] = true;
            }
        } else {
            $response["error"] = "INVALID_IUCN_RESPONSE";
            $response["target"] = array(
                "uri" => $apiTarget.$nameTarget,
                "raw_response" => $iucnRawResponse,
                "parsed_response" => $iucnResponse,
            );
            $badIucn = true;
            $response["status"] = false;
        }
    } else {
        // What are we even doing here
    }
    if ($badTaxon) {
        # Try synonyms
        error_log("Bad taxon, trying synonyms");
        $validation = doAWebValidate(array(
            "genus" => $taxonBase["genus"],
            "species" => $taxonBase["species"],
        ));
        if ($validation["status"]) {
            $checkSynonyms = array(
                $validation["validated_taxon"]["gaa_name"],
            );
            $itisEntries = $validation["validated_taxon"]["itis_names"];
            $synonymEntries = $validation["validated_taxon"]["synonym_names"];
            foreach (explode(",", $itisEntries) as $entry) {
                $checkSynonyms[] = $entry;
            }
            foreach (explode(",", $synonymEntries) as $entry) {
                $checkSynonyms[] = $entry;
            }
            # Now we have a list of all known synonyms
            foreach ($checkSynonyms as $taxon) {
                error_log("Checking synonym '".$taxon."' for ".json_encode($taxonBase));
                $taxonParts = explode(" ", strtolower($taxon));
                $genus = $taxonParts[0];
                $species = $taxonParts[1];
                set_time_limit(15); # Prevent timing out unless a
                                    # specific lookup actually fails
                $responseTmp = getTaxonIucnData(array(
                    "genus"  => $genus,
                    "species" => $species,
                ), true);
                if ($responseTmp["status"] === true) {
                    $response = $responseTmp;
                    break;
                }
            }
        }
    }
    return $response;
}

function getTaxonAWebData($taxonBase)
{
    /***
     *
     *
     * See:
     * http://amphibiaweb.org/ws.html
     ***/
    $apiTarget = "http://amphibiaweb.org/cgi/amphib_ws";
    foreach ($taxonBase as $key => $value) {
        $taxonBase[$key] = strtolower($value);
    }
    $args = array(
        "where-genus" => $taxonBase["genus"],
        "where-species" => $taxonBase["species"],
        "src" => "eol",
    );
    $awebRawResponse = do_post_request($apiTarget, $args);
    # There's a bunch of cdata bull that messes this up
    $replaceSearch = array(
        // "<![CDATA[",
        // "]]>",
        "\r\n",
        "\n",
    );
    $awebReplacedResponse = str_replace($replaceSearch, "", $awebRawResponse);
    $iter = 1;
    $awebEscapeTags = preg_replace('%<!\[cdata\[((?:(?!\]\]>).)*?)<(p|i|a)(?:\s*href=.*?)?>(.*?)</\g{2}>(.*?)\]\]>%sim', '<![CDATA[${1}&lt;${2}&gt;${3}&lt;/${2}&gt;${4}]]>', $awebReplacedResponse, -1, $tagCount);
    while ($tagCount > 0) {
        $replaced = preg_replace('%<!\[cdata\[((?:(?!\]\]>).)*?)<(p|i|a)(?:\s*href=.*?)?>(.*?)</\g{2}>(.*?)\]\]>%sim', '<![CDATA[${1}&lt;${2}&gt;${3}&lt;/${2}&gt;${4}]]>', $awebEscapeTags, 500, $tagCount);
        if (!empty($replaced)) {
            $awebEscapeTags = $replaced;
        }
        ++$iter;
    }
    $awebNoCdata = preg_replace('%<!\[cdata\[\s*?([\w\- ,;:\'"\ts\x{0080}-\x{017F}\(\)\/\.\r\n\?\&=]*?)\s*?\]\]>%usim', '${1}', $awebEscapeTags);

    # https://secure.php.net/manual/en/book.simplexml.php
    $awebXml = simplexml_load_string($awebNoCdata);
    #$awebXml = simplexml_load_string($awebReplacedResponse);
    #$awebXml = simplexml_load_string($awebRawResponse);
    $awebJson = json_encode($awebXml);
    $awebData = json_decode($awebJson, true);
    # Pretty up potential arrays
    $formattedAwebData = array();
    foreach ($awebData["species"] as $key => $value) {
        # Test the value -- see if it's arrayish
        if (preg_match('/^( *([A-Z][\w \-\x{0080}-\x{017F}]+),)+( *[A-Z][\w \-\x{0080}-\x{017F}]+)$/usm', $value)) {
            # OK, explode it
            $formattedValue = explode(",", $value);
        } else {
            $formattedValue = $value;
        }
        $formattedAwebData[$key] = $formattedValue;
    }
    $response = array(
        "taxon" => array(
            "genus" => $taxonBase["genus"],
            "species" => $taxonBase["species"],
        ),
        "data" => $formattedAwebData,
        // "aweb_notags" => $awebEscapeTags,
        // "aweb_notags_iter" => $iter,
        // "aweb_cdata_replaced" => $awebNoCdata,
        // "aweb_json" => $awebJson
    );
    return $response;
}
