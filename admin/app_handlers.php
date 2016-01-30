<?php

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
  global $action;
    $username = $appInformation['username'];
    $device = $appInformation['device'];
    $newUser = boolstr($appInformation['new_user']);
    $return_data = array('details' => array('requested_action' => $action));
    $validuser_data = array();
    $u = new UserFunctions();
    $password = urldecode($appInformation['password']);
    $encryption_key = $appInformation['key'];
    if (isNull($password) || isNull($username) || isNull($device) || isNull($encryption_key)) {
        return array('status' => false,'error' => 'Required parameters missing','have_username' => !isNull($username),'have_password' => !isNull($password),'have_device' => !isNull($device),'have_encryption_key' => !isNull($encryption_key), 'details' => array('requested_action' => $action));
    }
    if ($newUser) {
        # Start the new user creation process
    # The application should have verified password correctness
    $name = array($appInformation['first_name'],$appInformation['last_name']);
        $handle = $appInformation['handle'];
        $phone = $appInformation['phone'];
        if (isNull($appInformation['first_name']) || isNull($appInformation['last_name']) || isNull($phone) || isNull($handle)) {
            return array('status' => false,'error' => 'Required parameters missing','have_name' => !isNull($name),'have_phone' => !isNull($phone),'have_handle' => !isNull($handle), 'details' => array('requested_action' => $action));
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

            return array('status' => false,'human_error' => $result['human_error'],'error' => $result['error'],'app_error_code' => 109, 'details' => array('requested_action' => $action));
        } elseif ($result['status'] === false) {
            $errorCode = strtolower($result['desc']) == 'no numeric id' ? 117 : 110;
            $message = $errorCode == 117 ? 'Invalid credentials, or missing new user flag. Set new_user=true' : $result['message'];
            $result['human_error'] = $message;
            $result['app_error_code'] = $errorCode;
            $result['details']['requested_action'] = $action;

            return $result;
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
        $return_array = array_merge($r, array($return_data));
        $return_array['details']['requested_action'] = 'register';

        return $return_array;
    }
        if (empty($r['human_error'])) {
            $r['human_error'] = $r['error'];
        }
        if (empty($r['app_error_code'])) {
            $r['app_error_code'] = 999;
        }
        $r['cookies'] = $cookies;
        $r['lookup_data'] = $result;
        $r['validation_data_provided'] = $validuser_data;
        $r['details']['requested_action'] = $action;

        return $r;
    }
    $return_data['secret'] = $r['secret'];
    $r['requested_action'] = $action;
    $return_data = array_merge(array('status' => true, 'message' => "Successful registration of device '$device'", 'details' => $r));

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
  global $action;
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
            returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => 'Invalid data object', 'app_error_code' => 101, 'details' => array('requested_action' => $action, 'provided_data' => $authenticationInformation['data'], 'decoded_data' => $action_data, 'json_data' => base64_decode($authenticationInformation['data']))));
        } else {
            # Check structure of variables
      try {
          # Reserved for specific data-type checking
      } catch (Exception $e) {
          returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => $e->getMessage(), 'app_error_code' => 108, 'details' => array('requested_action' => $action)));
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
        returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => 'Invalid request', 'app_error_code' => 102, 'details' => array('requested_action' => $action)));
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
    'authorize' => 'getLoginState',
    'bill' => 'billUser',
    'newProfileImage' => 'setNewProfileImage',
    'getProfileImage' => 'getProfileImage',
  );
    if (!array_key_exists($action, $action_function_map)) {
        returnAjax(array('status' => false, 'human_error' => 'The application and server could not communicate. Please contact support.', 'error' => 'Invalid action', 'app_error_code' => 103, 'details' => array('requested_action' => $action)));
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
        $errorCode = !empty($r['app_error_code']) ? $r['app_error_code'] : 106;
        $humanError = !empty($r['human_error']) ? $r['human_error'] : "This app isn't authorized. Please log out and log back in.";
        $error = !empty($r['error']) ? $r['error'] : 'Invalid app credentials';
        returnAjax(array('status' => false, 'human_error' => $humanError, 'error' => $error, 'app_error_code' => $errorCode, 'details' => array('requested_action' => $action, 'original_response' => $r)));
    }
  # Call the $action
  $action_data['hash'] = $r['validation_tokens']['raw_auth'];
    $action_data['secret'] = $r['validation_tokens']['raw_secret'];
    $action_data['dblink'] = $r['userid'];
    $action_data['user_data'] = $r['data'];
    $action_data['post_data'] = $_REQUEST;
    if ($action == 'authorize') {
        // do nothing??
    $action_result = array('status' => true,'details' => array('original_result' => $r));
    } else {
        $action_result = $action_function_map[$action]($action_data);
    }
    $action_result['elapsed'] = elapsed();
    if (!empty($action_result['details'])) {
        $action_result['details'] = @array_merge($action_result['details'], array('requested_action' => $action));
    } else {
        $action_result['details'] = array('requested_action' => $action);
    }
    returnAjax($action_result);
}

#$write = "\n".datestamp()." - ".json_encode($_REQUEST);
#file_put_contents('access.log', $write, FILE_APPEND | LOCK_EX);

authorizeApp($_REQUEST);
