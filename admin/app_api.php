<?php

/*
 * Server functions to proxy out the database
 */

if (!(isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on')) {
    $data = array('status' => false,'error' => 'This application only accepts SSL connections');
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
    header('Content-type: application/json');
    print @json_encode($data, JSON_FORCE_OBJECT);
    exit();
}

parse_str($_SERVER['QUERY_STRING'], $_GET);

/***
 * The login handler will take care of the basic login checks.
 ***/
$print_login_state = false;
require_once 'async_login_handler.php';

$action = isset($_REQUEST['action']) ? strtolower($_REQUEST['action']) : null;
// main loop
$_REQUEST['data'] = preg_replace("/[\r\n ]/", '', $_REQUEST['data']); // fixes weirdness from app

function datestamp()
{
    return date('Ymd-HisO');
}

function isNull($data)
{
    # Strictly for my sanity
  try {
      if (is_array($data)) {
          $empty = true;
          foreach ($data as $v) {
              if (!empty($v)) {
                  $empty = false;
                  break;
              }
          }
          if ($empty) {
              return true;
          }
      }

      return empty($data);
  } catch (Exception $e) {
      return true;
  }
}

$start_script_timer = microtime_float();

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

# The wrapper function to register the application

function registerApp($appInformation)
{
    /***
   *
   *
   * @param bool new_user flag to create a new user
   *
   * These keys are for all new device registrations, including new
   * user creation
   * @key email username
   * @key string password a URL-encoded password
   * @key phone_verify (when asked)
   * @key string key the encryption key
   *
   * These keys are only for new user creation
   * @key string first_name
   * @key string last_name
   * @key int phone
   * @key string handle the display username
   ***/
  $username = $appInformation['username'];
    $device = $appInformation['device'];
    $newUser = boolstr($appInformation['new_user']);
    $return_data = array();
    $validuser_data = array();
    $u = new UserFunctions();
    $password = urldecode($appInformation['password']);
    $encryption_key = $appInformation['key'];
    if (isNull($password) || isNull($username) || isNull($device) || isNull($encryption_key)) {
        return array('status' => false,'error' => 'Required parameters missing','have_username' => !isNull($username),'have_password' => !isNull($password),'have_device' => !isNull($device),'have_encryption_key' => !isNull($encryption_key));
    }
    if ($newUser) {
        # Start the new user creation process
    # The application should have verified password correctness
    $name = array($appInformation['first_name'],$appInformation['last_name']);
        $handle = $appInformation['handle'];
        $phone = $appInformation['phone'];
        if (isNull($appInformation['first_name']) || isNull($appInformation['last_name']) || isNull($phone) || isNull($handle)) {
            return array('status' => false,'error' => 'Required parameters missing','have_name' => !isNull($name),'have_phone' => !isNull($phone),'have_handle' => !isNull($handle));
        }
        $result = $u->createUser($username, $password, $name, $handle, $phone);
        if ($result['status'] != true) {
            if (empty($r['human_error'])) {
                $result['human_error'] = $result['error'];
                $result['app_error_code'] = 999;
            }

            return $result;
        }
        $return_data['dblink'] = $result['dblink'];
        $validuser_data['dblink'] = $result['dblink'];
        $validuser_data['secret'] = $result['raw_secret'];
        $validuser_data['hash'] = $result['raw_auth'];
    } else {
        # Verify the user
    # Set up equivalent variables to finish registering the app
    $totp = isset($appInformation['totp']) ? $appInformation['totp'] : false;
        $result = $u->lookupUser($username, $password, true, $totp);
        if ($result['status'] === false && $result['totp'] === true) {
            $u->sendTOTPText();

            return array('status' => false,'human_error' => $result['human_error'],'error' => $result['error'],'app_error_code' => 109);
        }
    # Get the cookie tokens we'll use to validate in registerApp()
    $cookies = $u->createCookieTokens($result['data']);
        $return_data['dblink'] = $result['data']['dblink'];
        $validuser_data['dblink'] = $result['data']['dblink'];
        $validuser_data['secret'] = $cookies['raw_secret'];
        $validuser_data['hash'] = $cookies['raw_auth'];
    }
  # Get the data we need
  $phone_verify_code = $appInformation['phone_verify'];
    $r = $u->registerApp($validuser_data, $encryption_key, $device, $phone_verify_code);
    if ($r['status'] === false) {
        # Phone needs validation. Return the dblink and request
    # validation. Upon validation, re-ping this same target
    if ($r['app_error_code'] == 111) {
        return array_merge($r, array($return_data));
    }
        if (empty($r['human_error'])) {
            $r['human_error'] = $r['error'];
            $r['app_error_code'] = 999;
        }
    # $r["cookies"] = $cookies;
    # $r["lookup_data"] = $result;
    return $r;
    }
    $return_data['secret'] = $r['secret'];
    $return_data = array_merge(array('status' => true, 'message' => "Successful registration of device '$device'", 'details' => $r), $return_data);

    return $return_data;
}

# See if the user is trying to register. If they are, call the
# register function, otherwise, let it cascade down into the
# authorization.
if ($action == 'register') {
    returnAjax(registerApp($_REQUEST));
}

# We want to wrap  calls that aren't about login to a function that
# authorizes the application

function authorizeApp($authenticationInformation)
{
    /***
   * Primary wrapper function for everything not directly login / auth
   * related.
   *
   * @param array $authenticationInformation
   *
   * $authenticationInformation should be an array containing the
   * following keys:
   *
   * @key "auth" - the SHA1 hash of "entropy", server secret key, "action", "app_version"
   * @key "key"  - The encryption key to decrypt the server secret key
   * @key "app_version" - the application version number
   * @key "entropy" - A randomly generated string of 16 characters
   * @key "action" - The action to be executed
   * @key "data" - A base64-encoded JSON object with structured data for
   * the action
   * @key "user_id" - the dblink for the user. This will always be
   * appended to the values in the "data" key.
   ***/

  if (is_array($authenticationInformation)) {
      $auth = $authenticationInformation['auth'];
      $auth_key = $authenticationInformation['key'];
      $version = $authenticationInformation['app_version'];
      $entropy = $authenticationInformation['entropy'];
      $action = $authenticationInformation['action'];
      $user = $authenticationInformation['user_id'];
      $device = $authenticationInformation['device_identifier'];
      $action_data = smart_decode64($authenticationInformation['data']);
      if (!is_array($action_data)) {
          returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => 'Invalid data object', 'app_error_code' => 101));
      } else {
          # Check structure of variables
      try {
          # Reserved for specific data-type checking
      } catch (Exception $e) {
          returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => $e->getMessage(), 'app_error_code' => 108));
      }
      # Save variables to be used later
      $action_data['dblink'] = $user;
          $app_verify = array(
        'device' => $device,
        'authorization_token' => $auth,
        'auth_prepend' => $entropy,
        'auth_postpend' => $action.$version,
        'appsecret_key' => $auth_key,
        'dblink' => $user,
      );
          $action_data['application_verification'] = $app_verify;
          $u = new UserFunctions($user);
      }
  } else {
      returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => 'Invalid request', 'app_error_code' => 102));
  }
  /***
   * See if the action is a valid action.
   * Most of these are just going to be wrappers for the
   * async_login_handler functions.
   ***/
  if (empty($action)) {
      $action = 'sync';
  }
    $action_function_map = array(
    'save' => 'saveToUser',
    'read' => 'getFromUser',
    'sync' => 'syncUserData',
  );
    if (!array_key_exists($action, $action_function_map)) {
        returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => 'Invalid action', 'app_error_code' => 103));
    }
  # See if the user exists
  # get the key for $user from the server
  /***
   * Now, we want to authenticate the app against this information.
   * $auth should be the SHA1 hash of:
   *
   * $auth = sha1($entropy.$SERVER_KEY.$action.$version)
   *
   * If it isn't, the request is bad.
   ***/
  $r = $u->verifyApp($app_verify);
    if (!$r['status']) {
        returnAjax(array('status' => false, 'human_error' => "This app isn't authorized. Please log out and log back in.", 'error' => 'Invalid app credentials', 'app_error_code' => 106));
    }
  # Call the $action
  $action_data['user_data'] = $r['data'];
    $action_result = $action_function_map[$action]($action_data);
    $action_result['elapsed'] = elapsed();
    returnAjax($action_result);
}

$write = "\n".datestamp().' - '.json_encode($_REQUEST);
file_put_contents('access.log', $write, FILE_APPEND | LOCK_EX);

authorizeApp($_REQUEST);

/*******************
 * The functions that actually do stuff
 * Called by the "action" key through verifyApp
 *******************/

function syncUserData($data_array)
{
    return $data_array['user_data'];
}

function billUser($data_array)
{
    /***
   * Do a charge against the user, then update the status all around.
   ***/
}

function authenticateWebRequest()
{
    /*
   * Check the authentication credentials using the stored server secrets for
   * hashes.
   */
  return false;
}
