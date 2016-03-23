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
    $cols = array('project_id', 'project_title');
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
                $search[$col] = $q;
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
    global $udb;
    $q = $udb->sanitize($get['q']);
    $response = array(
        'search' => $q,
    );
    $search = array(
        'username' => $q,
        'name' => $q,
        'dblink' => $q, #?
    );
    $cols = array('username', 'name', 'dblink');
    $response['status'] = true;
    $result = $udb->getQueryResults($search, $cols, 'OR', true, true);
    foreach ($result as $k => $entry) {
        $clean = array(
            'email' => $entry['username'],
            'uid' => $entry['dblink'],
        );
        $nameXml = $entry['name'];
        $xml = new Xml();
        $xml->setXml($nameXml);
        $clean['first_name'] = $xml->getTagContents('fname');
        $clean['last_name'] = $xml->getTagContents('lname');
        $clean['full_name'] = $xml->getTagContents('name');
        $clean['handle'] = $xml->getTagContents('dname');
        $result[$k] = $clean;
    }
    $response['result'] = $result;
    $response['count'] = sizeof($result);
    returnAjax($response);
}

function checkColumnExists($column_list, $userReturn = true)
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
            if ($userReturn) {
                returnAjax(array('status' => false, 'error' => 'Invalid column. If it exists, it may be an illegal lookup column.', 'human_error' => "Sorry, you specified a lookup criterion that doesn't exist. Please try again.", 'columns' => $column_list, 'bad_column' => $column));
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
    $sqlQuery = decode64($get['sql_query']);
    # If it's a "SELECT" style statement, make sure the accessing user
    # has permissions to read this dataset
    $searchSql = strtolower($sqlQuery);
    $queryPattern = '/(?i)([a-zA-Z]+(?:(?! +FROM) +[a-zA-Z]+)?) +.*(?:FROM)?[ `]*(t[0-9a-f]+[_]?[0-9a-f]*)[ `]*.*[;]?/m';
    $sqlAction = preg_replace($queryPattern, '$1', $sqlQuery);
    $sqlAction = strtolower(str_replace(" ","", $sqlAction));
    $restrictedActions = array(
        "select" => "READ",
        "delete" => "EDIT",
        "insert" => "EDIT",
        "insertinto" => "EDIT",
        "update" => "EDIT",
    );
    if (isset($restrictedActions[$sqlAction])) {
        # Check the user
        # If bad, kick the access out
        $cartoTable = preg_replace($queryPattern, '$2', $sqlQuery);
        $cartoTableJson = str_replace('_', '&#95;', $cartoTable);
        $accessListLookupQuery = 'SELECT `project_id`, `author`, `access_data`, `public` FROM `'.$db->getTable()."` WHERE `carto_id` LIKE '%".$cartoTableJson."%' OR `carto_id` LIKE '%".$cartoTable."%'";
        $l = $db->openDB();
        $r = mysqli_query($l, $accessListLookupQuery);
        $row = mysqli_fetch_assoc($r);
        $pid = $row["project_id"];
        $requestedPermission = $restrictedActions[$sqlAction];
        $pArr = explode(",", $row["access_data"]);
        $permissions = array();
        foreach($pArr as $access) {
            $up = explode(":", $access);
            $permissions[$up[0]] = $up[1];
        }
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
            );
            returnAjax($response);
        }
        $uid = $login_status['detail']['uid'];
        if (!in_array($uid, $users) && !$isPublic && $isSu !== true) {
            $response = array(
                'status' => false,
                'error' => 'UNAUTHORIZED_USER',
                'human_error' => "User $uid isn't authorized to access this dataset",
                'args_provided' => $get,
                "project_id" => $pid,
                'is_public_dataset' => $isPublic,
            );
            returnAjax($response);
        }
        if ($requestedPermission == "EDIT") {
            # Editing has an extra filter
            $hasPermission = $permissions[$uid];
            if ($hasPermission !== $requestedPermission && $isSu !== true) {
                $response = array(
                    'status' => false,
                    'error' => 'UNAUTHORIZED_USER',
                    'human_error' => "User $uid isn't authorized to edit this dataset",
                    'args_provided' => $get,
                    "project_id" => $pid,
                    "query_type" => $sqlAction,
                    "user_permissions" => $hasPermission,
                );
                returnAjax($response);
            }
        }
    } else {
        # Unrecognized query type
        returnAjax(array(
            "status" => false,
            "error" => "UNAUTHORIZED_QUERY_TYPE",
            "query_type" => $sqlAction,
            "args_provided" => $get,
        ));
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
    ini_set('allow_url_fopen', true);
    if (!boolstr($get['blobby'])) {
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
                $parsed_responses[] = json_decode($response, true);
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
        $parsed_responses[] = json_decode($response, true);
    }
    try {
        returnAjax(array(
            'status' => true,
            'sql_statements' => $statements,
            'post_response' => $responses,
            'parsed_responses' => $parsed_responses,
            'blobby' => boolstr($get['blobby']),
            "query_type" => $sqlAction,
            "project_id" => $pid,
            # "urls_posted" => $urls,
        ));
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
    if (empty($get['genus']) or empty($get['species'])) {
        $response['error'] = 'MISSING_ARGUMENTS';
        $response['human_error'] = 'You need to provide both a genus and species to validate';
        returnAjax($response);
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
            $response['human_error'] = "'$providedGenus' isn't a valid AmphibiaWeb genus (checked ".sizeof($genusList)." genera), nor is '$testSpecies' a recognized synonym.";
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
        global $db;
        $project = $db->sanitize($get['project']);
        $query = array(
            'project_id' => $project,
        );
        $result = $db->getQueryResults($query, 'author_data', 'AND', false, true);
        $author_data = json_decode($result[0]['author_data'], true);
        $a = array(
            'status' => true,
            'author_data' => $author_data,
            'raw_result' => $result[0],
        );
    }
    returnAjax($a);
}
