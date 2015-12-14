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


$login_status = getLoginState($get);
if($login_status["status"] !== true) {
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
   * Create a new taxon entry
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

?>