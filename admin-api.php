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

$udb = new DBHelper($default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$db_cols);

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

## ONE OFF CHANGE
$l = $db->openDB();
$query = "ALTER TABLE `" . $db->getTable() . "` MODIFY `carto_id` TEXT";
$result = mysqli_query($l, $query);
returnAjax($result);

$login_status = getLoginState($get);

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
  case "get":
      returnAjax(readProjectData($_REQUEST));
      break;
  // case "test":
  //     returnAjax($db->testSettings());
  //     break;
  default:
    returnAjax(getLoginState($_REQUEST,true));
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
   * Delete a taxon entry
   * Delete an entry described by the ID parameter
   *
   * @param $get["id"] The DB id to delete
   ***/
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


function checkProjectAuthorized($projectData, $uid) {
    /***
     * Helper function for checking authorization
     ***/
    $isAuthor = $projectData["author"] == $uid;
    $isPublic = $projectData["public"];
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
    $response = array(
        "can_edit" => $isAuthor || $isEditor,
        "can_view" => $isAuthor || $isEditor || $isViewer ||$isPublic,
        "is_author" => $isAuthor,
        "editors" => $editList,
        "viewers" => $viewList,
    );
    return $response;
}


function readProjectData($get, $debug = true) {
    /***
     *
     ***/
    global $db, $login_status;
    $project = $db->sanitize($get["project"]);
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
        return $response;
    }
    # It's good, so set permissions
    $response["user"]["has_edit_permissions"] = $permission["can_edit"];
    $response["user"]["has_view_permissions"] = $permission["can_view"];
    $response["user"]["is_author"] = $permission["is_author"];
    # Rewrite the users to be more practical
    $u = new UserFunctions();
    $u->getUser($row["author"]);
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
    $response["project"] = $row;    
    # Return it!
    $response["status"] = true;
    $response["error"] = "OK";
    $response["human_error"] = null;
    return $response;
}

?>