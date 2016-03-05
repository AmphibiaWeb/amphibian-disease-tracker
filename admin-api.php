<?php

/***
 * Handle admin-specific requests
 ***/
$debug = false;

if($debug) {
    error_reporting(E_ALL);
    ini_set("display_errors", 1);
    error_log("AdminAPI is running in debug mode!");
}

$print_login_state = false;
require_once("DB_CONFIG.php");
require_once(dirname(__FILE__)."/core/core.php");

$db = new DBHelper($default_database,$default_sql_user,$default_sql_password, $sql_url,$default_table,$db_cols);

require_once(dirname(__FILE__)."/admin/async_login_handler.php");

# Declaring this makes Aldo slow
# $udb = new DBHelper($default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols);

$start_script_timer = microtime_float();

if(!function_exists('elapsed'))
  {
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

      if(!is_numeric($start_time))
        {
          global $start_script_timer;
          if(is_numeric($start_script_timer)) $start_time = $start_script_timer;
          else return false;
        }
      return 1000*(microtime_float() - (float)$start_time);
    }
  }

$admin_req=isset($_REQUEST['perform']) ? strtolower($_REQUEST['perform']):null;


$login_status = getLoginState($get);

if($as_include !== true) {
    if($login_status["status"] !== true) {
        if($admin_req == "list") {
            returnAjax(listProjects());
        }
        $login_status["error"] = "Invalid user";
        $login_status["human_error"] = "You're not logged in as a valid user to edit this. Please log in and try again.";
        returnAjax($login_status);
    }

    switch($admin_req)
    {
        # Stuff
    case "save":
        returnAjax(saveEntry($_REQUEST));
        break;
    case "new":
        returnAjax(newEntry($_REQUEST));
        break;
    case "delete":
        returnAjax(deleteEntry($_REQUEST));
        break;
    case "list":
        returnAjax(listProjects(false));
        break;
    case "sulist":
        returnAjax(suListProjects(false));
        break;
    case "get":
        returnAjax(readProjectData($_REQUEST));
        break;
    case "mint":
        $link = $_REQUEST["link"];
        $file = $_REQUEST["file"];
        $title64 = $_REQUEST["title"];
        $title = decode64($title64);
        if(empty($link) || empty($title)) {
            returnAjax(array(
                "status" => false,
                "error" => "BAD_PARAMETERS",
            ));
        }
        returnAjax(mintBcid($link, $file, $title));
        break;
    case "check_access":
        returnAjax(authorizedProjectAccess($_REQUEST));
        break;
    default:
        returnAjax(getLoginState($_REQUEST,true));
    }

}

function saveEntry($get)
{
  /***
   * Save a new taxon entry
   ***/

  $data64 = $get["data"];
  $enc = strtr($data64, '-_', '+/');
  $enc = chunk_split(preg_replace('!\015\012|\015|\012!','',$enc));
  $enc = str_replace(' ','+',$enc);
  $data_string = base64_decode($enc);
  $data = json_decode($data_string,true);
  if(!isset($data["id"]))
    {
      # The required attribute is missing
        $details = array (
                          "original_data" => $data64,
                          "decoded_data" => $data_string,
                          "data_array" => $data
                          );
      return array("status"=>false,"error"=>"POST data attribute \"id\" is missing","human_error"=>"The request to the server was malformed. Please try again.","details"=>$details);
    }
  # Add the perform key
  global $db;
  $ref = array();
  $ref["id"] = $data["id"];
  unset($data["id"]);
  try
    {
      $result = $db->updateEntry($data,$ref);
      # Now, we want to do image processing if an image was alerted
      $imgDetails = false;
      if(!empty($data["image"])) {
          $img = $data["image"];
          $imgDetails = array("has_provided_img"=>true);
          # Process away!
          $file = dirname(__FILE__)."/".$img;
          $imgDetails["file_path"] = $file;
          $imgDetails["relative_path"] = $img;
          if(file_exists($file))
          {
              $imgDetails["img_present"] = true;
              # Resize away
              try
              {
                  $i = new ImageFunctions($file);
                  $thumbArr = explode(".",$img);
                  $extension = array_pop($thumbArr);
                  $outputFile = dirname(__FILE__)."/".implode(".",$thumbArr)."-thumb.".$extension;
                  $imgDetails["resize_status"] = $i->resizeImage($outputFile,256,256);
              }
              catch(Exception $e)
              {
                  $imgDetails["resize_status"] = false;
                  $imgDetails["resize_error"] = $e->getMessage();
              }

          }
          else
          {
              $imgDetails["img_present"] = false;
          }
      }
    }
  catch(Exception $e)
    {
      return array("status"=>false,"error"=>$e->getMessage(),"humman_error"=>"Database error saving","data"=>$data,"ref"=>$ref,"perform"=>"save");
    }
  if($result !== true)
    {
      return array("status"=>false,"error"=>$result,"human_error"=>"Database error saving","data"=>$data,"ref"=>$ref,"perform"=>"save");
    }
  return array("status"=>true,"perform"=>"save","data"=>$data, "img_details"=>$imgDetails);
}

function newEntry($get)
{
  /***
   * Create a new entry
   *
   *
   * @param data a base 64-encoded JSON string of the data to insert
   ***/
  $data64 = $get["data"];
  $enc = strtr($data64, '-_', '+/');
  $enc = chunk_split(preg_replace('!\015\012|\015|\012!','',$enc));
  $enc = str_replace(' ','+',$enc);
  $data_string = base64_decode($enc);
  $data = json_decode($data_string,true);
  # Add the perform key
  global $db;
  try
  {
    $result = $db->addItem($data);
  }
  catch(Exception $e)
  {
    return array("status"=>false,"error"=>$e->getMessage(),"humman_error"=>"Database error saving","data"=>$data,"ref"=>$result,"perform"=>"new");
  }
  if($result !== true)
  {
    return array("status"=>false,"error"=>$result,"human_error"=>"Database error saving","data"=>$data,"ref"=>$result,"perform"=>"new");
  }
  return array("status"=>true,"perform"=>"new","data"=>$data);
}

function deleteEntry($get)
{
  /***
   * Delete a project entry described by the ID parameter
   *
   * @param $get["id"] The DB id to delete
   ***/
    return false; # Disabled for now, need auth checks
  global $db;
  $id = $get["id"];
  $result = $db->deleteRow($id,"id");
  if ($result["status"] === false)
  {
    $result["human_error"] = "Failed to delete item '$id' from the database";
  }
  return $result;
}

function listProjects($unauthenticated = true) {
    /***
     * List accessible projects to the user.
     *
     * @param bool $unauthenticated -> Check for authorized projects
     * to the user if false. Default true.
     ***/
    global $db, $login_status;
    $query = "SELECT `project_id`,`project_title` FROM " . $db->getTable() . " WHERE `public` IS TRUE";
    $l = $db->openDB();
    $r = mysqli_query( $l, $query );
    $authorizedProjects = array();
    $authoredProjects = array();
    $publicProjects = array();
    $queries = array();
    $queries[] = $query;
    while ( $row = mysqli_fetch_row($r) ) {
        $authorizedProjects[$row[0]] = $row[1];
        $publicProjects[] = $row[0];
    }
    if(!$unauthenticated) {
        try {
            $uid = $login_status["detail"]["uid"];
        } catch(Exception $e) {
            $queries[] = "UNAUTHORIZED";
        }
        if (!empty( $uid )) {
            $query = "SELECT `project_id`,`project_title`,`author` FROM " . $db->getTable() . " WHERE (`access_data` LIKE '%" . $uid . "%' OR `author`='$uid')";
            $queries[] = $query;
            $r = mysqli_query($l,$query);
            while ( $row = mysqli_fetch_row($r) ) {
                $authorizedProjects[$row[0]] = $row[1];
                if ($row[2] == $uid) {
                    $authoredProjects[] = $row[0];
                }
            }
        }
    }

    $result = array(
        "status" => true,
        "projects" => $authorizedProjects,
        "public_projects" => $publicProjects,
        "authored_projects" => $authoredProjects,
        "table" => $db->getTable(),
        "check_authentication" => !$unauthenticated,
    );

    return $result;
}


function suListProjects() {
    global $db, $login_status;
    $suFlag = $login_status["detail"]["userdata"]["su_flag"];
    $isSu = boolstr($suFlag);
    if($isSu !== true) {
        return array (
            "status" => false,
            "error" => "INVALID_PERMISSIONS",
            "human_error" => "Sorry, you don't have permissions to do that."
        );
    }
    # Get a list of all the projects
    $query = "SELECT `project_id`,`project_title`, `public` FROM " . $db->getTable();
    try {
        $l = $db->openDB();
        $r = mysqli_query($l, $query);
        $projectList = array();
        while ($row = mysqli_fetch_row($r)) {
            $details = array(
                "title" => $row[1],
                "public" => boolstr($row[2])
            );
            $projectList[$row[0]] = $details;
        }
        return array(
            "status" => boolstr($suFlag),
            "projects" => $projectList
        );
    } catch (Exception $e) {
        return array(
            "status" => false,
            "error" => "SERVER_ERROR",
            "human_error" => "The server returned an error: " . $e->message()
        );
    }
}


function checkProjectAuthorized($projectData, $uid) {
    /***
     * Helper function for checking authorization
     ***/
    global $login_status;
    $currentUser = $login_status["detail"]["uid"];
    if($uid == $currentUser) {
        $suFlag = $login_status["detail"]["userdata"]["su_flag"];
        $isSu = boolstr($suFlag);
    } else {
        $isSu = false;
    }
    $isAuthor = $projectData["author"] == $uid;
    $isPublic = boolstr($projectData["public"]);
    $accessList = explode(",", $projectData["access_data"]);
    $editList = array();
    $viewList = array();
    foreach ($accessList as $viewer) {
        $permissions = explode(":", $viewer);
        $user = $permissions[0];
        $access = $permissions[1];
        if ($access == "READ") {
            $viewList[] = $user;
        }
        if ($access == "EDIT") {
            $editList[] = $user;
        }
        # Any other access value, including nullish, gives no permissions
    }
    $isEditor = in_array($uid, $editList);
    $isViewer = in_array($uid, $viewList);
    if($isSu === true) {
        # Superuser is everything!
        if(!$isEditor) {
            $editList[] = $uid;
        }
        $isAuthor = true;
        $isEditor = true;
    }
    $response = array(
        "can_edit" => $isAuthor || $isEditor,
        "can_view" => $isAuthor || $isEditor || $isViewer ||$isPublic,
        "is_author" => $isAuthor,
        "editors" => $editList,
        "viewers" => $viewList,
        "check" => array (
            "current_user" => $currentUser,
            "checked_user" => $uid,
            "is_checked" => $uid == $currentUser,
            "is_su" => $isSu,
        ),
    );
    return $response;
}


function authorizedProjectAccess($get) {
    global $db, $login_status;
    $project = $db->sanitize($get["project"]);
    $projectExists = $db->isEntry($project, "project_id", true);
    if(!$projectExists) {
        return array(
            "status" => false,
            "error" => "INVALID_PROJECT",
            "human_error" => "This project doesn't exist. Please check your project ID.",
            "project_id" => $project,
        );
    }
    $uid = $login_status["detail"]["uid"];
    $authorizedStatus = checkProjectAuthorized($project, $uid);
    $status = $authorizedStatus["can_view"];
    $results = array(
        "status" => $status,
        "project" => $project,
        "detailed_authorization" => $authorizedStatus,
    );
    if($status === true) {
        $results["detail"] = readProjectData($project, true);
    }
    return $results;
}


function readProjectData($get, $precleaned = false, $debug = false) {
    /***
     *
     ***/
    global $db, $login_status;
    if($precleaned) {
        $project = $get;
    } else {
        $project = $db->sanitize($get["project"]);
    }
    $userdata = $login_status["detail"];
    unset($userdata["source"]);
    unset($userdata["iv"]);
    unset($userdata["userdata"]["random_seed"]);
    unset($userdata["userdata"]["special_1"]);
    unset($userdata["userdata"]["special_2"]);
    unset($userdata["userdata"]["su_flag"]);
    unset($userdata["userdata"]["admin_flag"]);
    # Base response
    $response = array(
        "status" => false,
        "error" => "Unprocessed read",
        "human_error" => "Server error handling project read",
        "project" => array(
            "project_id" => $project,
            "public" => false,
        ),
        "user" => array(
            "user" => $login_status["detail"],
            "has_edit_permissions" => false,
            "has_view_permissions" => false,
            "is_author" => false,
        ),

    );
    if($debug) $response["debug"] = array();
    # Actual projecting
    $query = "SELECT * FROM " . $db->getTable() . " WHERE `project_id`='" . $project . "'";
    if($debug) $response["debug"]["query"] = $query;
    $l = $db->openDB();
    $r = mysqli_query( $l, $query );
    $row = mysqli_fetch_assoc($r);
    # First check the user auth
    $uid = $userdata["uid"];
    if($debug) {
        $pc = array(
            "checked_id" => $uid,
            "checked_data" => $row,
            "performed_query" => $query,
        );
        $response["debug"]["permissions"] = $pc;
    }
    $permission = checkProjectAuthorized($row, $uid);
    if ($permission["can_view"] !== true) {
        $response["human_error"] = "You are not authorized to view this project";
        $response["error"] = "ACCESS_AUTHORIZATION_FAILED";
        $response["details"] = $permission;
        return $response;
    }
    # It's good, so set permissions
    $response["user"]["has_edit_permissions"] = $permission["can_edit"];
    $response["user"]["has_view_permissions"] = $permission["can_view"];
    $response["user"]["is_author"] = $permission["is_author"];
    # Rewrite the users to be more practical
    $u = new UserFunctions($row["author"], "dblink");
    $detail = $u->getUser($row["author"]);
    $accessData = array(
        "editors" => array(),
        "viewers" => array(),
        "total" => array(),
        "editors_list" => array(),
        "viewers_list" => array(),
        "author" => $u->getUsername(),
        "composite" => array(),
    );
    # Add the author to the lists
    $accessData["editors_list"][] = $u->getUsername();
    $accessData["total"][] = $u->getUsername();
    $accessData["editors"][] = $u->getHardlink();
    $accessData["composite"][$u->getUsername()] = $u->getHardlink();
    # Editors
    foreach ($permission["editors"] as $editor) {
        # Get the editor data
        $u = new UserFunctions($editor, "dblink");
        $detail = $u->getUser($editor);
        $editor = array(
            "email" => $u->getUsername(),
            "user_id" => $u->getHardlink(),
        );
        $accessData["editors"][] = $editor;
        $accessData["editors_list"][] = $u->getUsername();
        $accessData["total"][] = $u->getUsername();
        $accessData["composite"][$u->getUsername()] = $editor;
    }
    foreach ($permission["viewers"] as $viewer) {
        # Get the viewer data
        $u = new UserFunctions($viewer, "dblink");
        $detail = $u->getUser($viewer);
        $viewer = array(
            "email" => $u->getUsername(),
            "user_id" => $u->getHardlink(),
        );
        $accessData["viewers"][] = $viewer;
        $accessData["viewers_list"][] = $u->getUsername();
        $accessData["composite"][$u->getUsername()] = $viewer;
        if (!in_array($accessData["total"], $u->getUsername())) {
            $accessData["total"][] = $u->getUsername();
        }
    }
    sort($accessData["total"]);
    # Replace the dumb permissions
    $row["access_data"] = $accessData;
    # Append it
    $row["public"] = boolstr($row["public"]);
    $row["includes_anura"] = boolstr($row["includes_anura"]);
    $row["includes_caudata"] = boolstr($row["includes_caudata"]);
    $row["includes_gymnophiona"] = boolstr($row["includes_gymnophiona"]);
    $response["project"] = $row;
    # Do we want to flag if the current user is a superuser?
    # Return it!
    $response["status"] = true;
    $response["error"] = "OK";
    $response["human_error"] = null;
    $response["project_id"] = $project;
    $response["project_id_raw"] = $get["project"];
    return $response;
}


function mintBcid($projectLink, $datasetRelativeUri = null, $datasetTitle, $addToExpedition = false, $fimsAuthCookiesAsString = null) {
    /***
     *
     * Mint a BCID for a dataset (originally, a BCID for a project).
     *
     * Sample response:
     *
     *{"projectCode":"AMPHIB","validationXml":"https:\/\/raw.githubusercontent.com\/biocodellc\/biocode-fims\/master\/Documents\/AmphibianDisease\/amphibiandisease.xml","projectId":"26","datasetTitle":"Amphibian Disease"},
     *
     * See
     * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
     *
     * Resolve the ark with https://n2t.net/
     *
     * @param string $datasetRelativeUri -> the relative URI (to root)
     *   of a dataset. If this file doesn't exist, assume it's a
     *   project identifier.
     * @param string $datasetTitle -> title of the dataset
     * @param array $addToExpedition -> If an array, add to the expedition
     *   in key "expedition", or the the saved expedition for the
     *   project in key "project_id"
     * @param string $fimsAuthCookie -> the formatted cookie string to
     *   place in a POST header
     * @return array
     ***/
    global $db;
    # FIMS probably already does this, but let's be a good net citizen.
    $datasetRelativeUri = $db->sanitize($datasetRelativeUri);
    $datasetTitle = $db->sanitize($datasetTitle);
    $projectLink = $db->sanitize($projectLink);
    $dataFileName = array_pop(explode("/", $datasetRelativeUri));
    $dataNameArray = explode(".", $dataFileName);
    array_pop($dataFileName);
    $dataFileIdentifier = implode(".", $dataFileName);
    $datasetCanonicalUri = "https://amphibiandisease.org/project.php?id=" . $projectLink . "#dataset:" . $dataFileIdentifier;
    # Is the dataset a file, or a project identifier?
    $filePath = dirname(__FILE__) . "/" . $datasetRelativeUri;
    if( strpos($datasetRelativeUri, ".") === false || !file_exists($filePath)) {
        # No file extension == no file
        # Prevent legacy things from breaking
        $datasetCanonicalUri = "https://amphibiandisease.org/project.php?id=" . $projectLink;
    }
    $fimsMintUrl = "http://www.biscicol.org/biocode-fims/rest/bcids";
    # http://biscicol.org/biocode-fims/rest/fims.wadl#idp752895712
    $fimsMintData = array(
        "webAddress" => $datasetCanonicalUri,
        "title" => $datasetTitle,
        "resourceType" => "http://purl.org/dc/dcmitype/Dataset",
    );
    try {
        if(empty($fimsAuthCookiesAsString)) {
            global $fimsPassword;
            $fimsAuthUrl = "http://www.biscicol.org/biocode-fims/rest/authenticationService/login";
            $fimsPassCredential = $fimsPassword;
            $fimsUserCredential = "amphibiaweb"; # AmphibianDisease
            $fimsAuthData = array(
                "username" => $fimsUserCredential,
                "password" => $fimsPassCredential,
            );
            # Post the login
            $params = array('http' => array(
                'method' => "POST",
                'content' => http_build_query($fimsAuthData),
                'header'  => 'Content-type: application/x-www-form-urlencoded',
            ));
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAuthUrl, false, $ctx);
            $loginHeaders = $http_response_header;
            $cookies = array();
            $cookiesString = "";
            foreach ($http_response_header as $hdr) {
                if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                    $cookiesString .= $matches[1] . ";";
                    parse_str($matches[1], $tmp);
                    $cookies += $tmp;
                }
            }
            $loginResponse = json_decode($rawResponse, true);
            if(empty($loginResponse["url"])) {
                throw(new Exception("Invalid Login Response"));
            }
        } else {
            $loginResponse = "NO_LOGIN_CREDENTIALS_PROVIDED";
            $cookiesString = $fimsAuthCookiesAsString;
        }
        # Post the args
        $headers = "Content-type: application/x-www-form-urlencoded\r\n" .
                 "Cookie: " . $cookiesString . "\r\n";
        $params["http"]["header"] = $headers;
        $params["http"]["content"] = http_build_query($fimsMintData);
        $ctx = stream_context_create($params);
        $rawResponse = file_get_contents($fimsMintUrl, false, $ctx);
        $resp = json_decode($rawResponse, true);
        # Get the ID in the result
        /***
         * Example result:
         {"login_response":{"url":"http:\/\/www.biscicol.org\/index.jsp"},"mint_response":{"identifier":"ark:\/21547\/AKQ2"},"response_headers":{"0":"HTTP\/1.1 200 OK","1":"X-FRAME-OPTIONS: DENY","2":"Set-Cookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;Path=\/;HttpOnly","3":"Expires: Thu, 01 Jan 1970 00:00:00 GMT","4":"Content-Type: application\/json","5":"Content-Length: 44","6":"Server: Jetty(9.2.6.v20141205)"},"cookies":{"JSESSIONID":"vvt1703eq52ub0jazasfu87h"},"post_headers":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n","post_params":{"http":{"method":"POST","content":"webAddress=https%3A%2F%2Famphibiandisease.org%2Fproject.php%3Fid%3Dfoobar&title=test&resourceType=http%3A%2F%2Fpurl.org%2Fdc%2Fdcmitype%2FDataset","header":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n"}},"execution_time":2675.9889125824}
        ***/
        $identifier = $resp["identifier"];
        if(empty($identifier)) {
            throw(new Exception("Invalid identifier in response"));
        }
        return array(
            "status" => true,
            "ark" => $identifier,
            "project_permalink" => $datasetCanonicalUri,
            "project_title" => $datasetTitle,
            "responses" => array(
                "login_response" => $loginResponse,
                "mint_response" => $resp,
            ),

        );
    } catch(Exception $e) {
        return array (
            "status" => false,
            "error" => $e->getMessage(),
            "human_error" => "There was a problem communicating with the FIMS project. Please try again later.",
        );
    }

}


function associateBcidsWithExpeditions() {
    /***
     *
     ***/
}



function mintExpedition($projectLink, $projectTitle, $publicProject = false, $associateDatasets = false, $fimsAuthCookiesAsString = null) {
    /***
     *
     *
     *
     *{"projectCode":"AMPHIB","validationXml":"https:\/\/raw.githubusercontent.com\/biocodellc\/biocode-fims\/master\/Documents\/AmphibianDisease\/amphibiandisease.xml","projectId":"26","projectTitle":"Amphibian Disease"},
     *
     * See
     * https://fims.readthedocs.org/en/latest/amphibian_disease_example.html
     *
     * Resolve the ark with https://n2t.net/
     *
     * See
     * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/55
     *
     * @param string $projectLink -> the project link to associate
     *   with this expedition. It does not yet need to exist in the
     *   database.
     * @param string $projectTitle -> The project title
     * @param boolean $publicProject -> Is the project a public one?
     * @param boolean $associateDatasets -> If the project exists,
     *   then the database column "datasets" is checked for values to
     *   associate with the expedition
     * @param string $fimsAuthCookie -> the formatted cookie string to
     *   place in a POST header
     * @return array
     ***/
    global $db;
    # Does the project exist?
    $projectLink = $db->sanitize($projectLink);
    $projectUri = "https://amphibiandisease.org/project.php?id=" . $projectLink;
    $fimsMintUrl = "http://www.biscicol.org/biocode-fims/rest/expeditions";
    # http://biscicol.org/biocode-fims/rest/fims.wadl#idp752991232
    $fimsMintData = array(
        "projectId" => 26, # From FIMS site
        "webAddress" => $projectUri, # Well, we want this but it isn't part of the spec at this time
        "expeditionCode" => $projectLink,
        "expeditionTitle" => $projectTitle,
        "public" => boolstr($publicProject),
    );
    try {
        if(empty($fimsAuthCookiesAsString)) {
            global $fimsPassword;
            $fimsPassCredential = $fimsPassword;
            $fimsUserCredential = "amphibiaweb"; # AmphibianDisease
            $fimsAuthUrl = "http://www.biscicol.org/biocode-fims/rest/authenticationService/login";
            $fimsAuthData = array(
                "username" => $fimsUserCredential,
                "password" => $fimsPassCredential,
            );
            # Post the login
            $params = array('http' => array(
                'method' => "POST",
                'content' => http_build_query($fimsAuthData),
                'header'  => 'Content-type: application/x-www-form-urlencoded',
            ));
            $ctx = stream_context_create($params);
            $rawResponse = file_get_contents($fimsAuthUrl, false, $ctx);
            $loginHeaders = $http_response_header;
            $cookies = array();
            $cookiesString = "";
            foreach ($http_response_header as $hdr) {
                if (preg_match('/^Set-Cookie:\s*([^;]+)/', $hdr, $matches)) {
                    $cookiesString .= $matches[1] . ";";
                    parse_str($matches[1], $tmp);
                    $cookies += $tmp;
                }
            }
            $loginResponse = json_decode($rawResponse, true);
            if(empty($loginResponse["url"])) {
                throw(new Exception("Invalid Login Response"));
            }
        } else {
            $loginResponse = "NO_LOGIN_CREDENTIALS_PROVIDED";
            $cookiesString = $fimsAuthCookiesAsString;
        }
        # Post the args
        $headers = "Content-type: application/x-www-form-urlencoded\r\n" .
                 "Cookie: " . $cookiesString . "\r\n";
        $params["http"]["header"] = $headers;
        $params["http"]["content"] = http_build_query($fimsMintData);
        $ctx = stream_context_create($params);
        $rawResponse = file_get_contents($fimsMintUrl, false, $ctx);
        $resp = json_decode($rawResponse, true);
        # Get the ID in the result
        /***
         * Example result:
         {"login_response":{"url":"http:\/\/www.biscicol.org\/index.jsp"},"mint_response":{"identifier":"ark:\/21547\/AKQ2"},"response_headers":{"0":"HTTP\/1.1 200 OK","1":"X-FRAME-OPTIONS: DENY","2":"Set-Cookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;Path=\/;HttpOnly","3":"Expires: Thu, 01 Jan 1970 00:00:00 GMT","4":"Content-Type: application\/json","5":"Content-Length: 44","6":"Server: Jetty(9.2.6.v20141205)"},"cookies":{"JSESSIONID":"vvt1703eq52ub0jazasfu87h"},"post_headers":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n","post_params":{"http":{"method":"POST","content":"webAddress=https%3A%2F%2Famphibiandisease.org%2Fproject.php%3Fid%3Dfoobar&title=test&resourceType=http%3A%2F%2Fpurl.org%2Fdc%2Fdcmitype%2FDataset","header":"Content-type: application\/x-www-form-urlencoded\r\nCookie: JSESSIONID=vvt1703eq52ub0jazasfu87h;\r\n"}},"execution_time":2675.9889125824}
        ***/
        $identifier = $resp["identifier"];
        if(empty($identifier)) {
            throw(new Exception("Invalid identifier in response"));
        }
        return array(
            "status" => true,
            "ark" => $identifier,
            "project_permalink" => $projectUri,
            "project_title" => $projectTitle,
            "responses" => array(
                "login_response" => $loginResponse,
                "mint_response" => $resp,
            ),

        );
    } catch(Exception $e) {
        return array (
            "status" => false,
            "error" => $e->getMessage(),
            "human_error" => "There was a problem communicating with the FIMS project. Please try again later.",
        );
    }

}

?>