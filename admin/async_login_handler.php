<?php

if (!isset($print_login_state)) {
    $print_login_state = true;
}

require_once dirname(__FILE__).'/CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
require_once dirname(__FILE__).'/handlers/login_functions.php';
#require_once(dirname(__FILE__).'/handlers/db_hook.inc');

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

if ($allow_insecure_connections !== true) {
    if (!(isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on')) {
        $data = array('status' => false,'error' => 'This application only accepts SSL connections');
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
        header('Content-type: application/json');
        print @json_encode($data, JSON_FORCE_OBJECT);
        exit();
    }
}

if(!function_exists("returnAjax")) {
    function returnAjax($data)
    {
        if (!is_array($data)) {
            $data = array($data);
        }
        $data['execution_time'] = elapsed();
        $data['completed'] = microtime_float();
        global $do;
        $data['requested_action'] = $do;
        $data['args_provided'] = $_REQUEST;
        if (!isset($data['status'])) {
            $data['status'] = false;
            $data['error'] = 'Server returned null or otherwise no status.';
            $data['human_error'] = "Server didn't respond correctly. Please try again.";
            $data['app_error_code'] = -10;
        }
        header('Cache-Control: no-cache, must-revalidate');
        header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
        header('Content-type: application/json');
        global $billingTokens;
        if (is_array($billingTokens)) {
            $data['billing_meta'] = $billingTokens;
        }
        print @json_encode($data, JSON_FORCE_OBJECT);
        exit();
    }
  }

parse_str($_SERVER['QUERY_STRING'], $_GET);
$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);
$do = isset($_REQUEST['action']) ? strtolower($_REQUEST['action']) : null;

if ($print_login_state === true) {
    switch ($do) {
      case 'get_login_status':
        returnAjax(getLoginState($_REQUEST));
        break;
      case "login":
          returnAjax( doAsyncLogin($_REQUEST) );
          break;
      case 'write':
        returnAjax(saveToUser($_REQUEST));
        break;
      case 'get':
        returnAjax(getFromUser($_REQUEST));
        break;
      case 'maketotp':
        returnAjax(generateTOTPForm($_REQUEST));
        break;
      case 'verifytotp':
        returnAjax(verifyTOTP($_REQUEST));
        break;
      case 'savetotp':
        returnAjax(saveTOTP($_REQUEST));
        break;
      case 'removetotp':
        returnAjax(removeTOTP($_REQUEST));
        break;
      case 'sendtotptext':
        returnAjax(sendTOTPText($_REQUEST));
        break;
      case 'totpstatus':
        returnAjax(hasTOTP($_REQUEST));
        break;
      case 'cansms':
        returnAjax(canSMS($_REQUEST));
        break;
      case 'verifyphone':
        returnAjax(verifyPhone($_REQUEST));
        break;
      case 'verifyemail':
        returnAjax(verifyEmail($_REQUEST));
        break;
      case 'removeaccount':
        returnAjax(removeAccount($_REQUEST));
        break;
      case 'verifynewuser':
        returnAjax(verifyUserAuth($_REQUEST));
        break;
      case 'startpasswordreset':
        returnAjax(doStartResetPassword($_REQUEST));
        break;
      case 'finishpasswordreset':
        returnAjax(finishResetPassword($_REQUEST));
        break;
      case 'changepassword':
          returnAjax(changePassword($_REQUEST));
          break;
      default:
        returnAjax(getLoginState($_REQUEST, true));
      }
}

function doAsyncLogin($get) {
    $u = new UserFunctions();
    $totp = empty($get["totp"]) ? false : $get["totp"];
    $r = $u->lookupUser($get["username"], $get["password"], true, $totp);
    if ($r["status"] === true) {
        $return = $u->createCookieTokens($r["data"]);
        unset($return["source"]);
        unset($return["raw_cookie"]);
        unset($return["basis"]);
    } else {
        $return = $r;
    }
    returnAjax($return);
}

function getLoginState($get, $default = false)
{
    global $login_url;
    $conf = $get['hash'];
    $s = $get['secret'];
    $id = $get['dblink'];
    $u = new UserFunctions();
    $userDetail = $u->validateUser($id, $conf, $s, true);
    $loginStatus = $userDetail['status'];
    try {
        unset($userDetail['userdata']['password']);
        unset($userDetail['userdata']['secret']);
        unset($userDetail['userdata']['pass_meta']);
        unset($userDetail['userdata']['secdata']);
        unset($userDetail['userdata']['emergency_code']);
        unset($userDetail['userdata']['auth_key']);
        unset($userDetail['userdata']['data']);
        unset($userDetail['userdata']['private_key']);
        unset($userDetail['userdata']['random_seed']);
        unset($userDetail['userdata']['special_1']);
        unset($userDetail['userdata']['special_2']);
        unset($userDetail['userdata']['app_key']);
        unset($userDetail['userdata']['phone_verified']);
        unset($userDetail['userdata']['last_ip']);
        unset($userDetail['source']);
        unset($userDetail['salt']);
        unset($userDetail['calc_conf']);
        unset($userDetail['basis_conf']);
        unset($userDetail['iv']);
    } catch (Exception $e) {
        # Do nothing, that unset just failed
      $userDetail = $e->getMessage();
    }

    return array('status' => $loginStatus,'defaulted' => $default,'login_url' => $login_url,'detail' => $userDetail);
}

function hasTOTP($get)
{
    $user = $get['user'];
    $u = new UserFunctions($user);
    try {
        return $u->has2FA();
    } catch (Exception $e) {
        return false;
    }
}

function canSMS($get)
{
    $user = $get['user'];
    $u = new UserFunctions($user);
    try {
        # This should be non-strict
        return array('status' => $u->canSMS(false));
    } catch (Exception $e) {
        return array('status' => false,'error' => $e->getMessage());
    }
}

function generateTOTPForm($get)
{
    $user = $get['user'];
    $password = $get['password'];
    $u = new UserFunctions($user);
    $r = $u->lookupUser($user, $password);
    if ($r[0] === false) {
        $r['status'] = false;

        return $r;
    }
  # User is valid

  # Get a provider
  $baseurl = 'http';
    if ($_SERVER['HTTPS'] == 'on') {
        $baseurl .= 's';
    }
    $baseurl .= '://www.';
    $baseurl .= $_SERVER['HTTP_HOST'];
    $base = array_slice(explode('.', $baseurl), -2);
    $domain = $base[0];

    $r = $u->makeTOTP($domain);

  # Whether or not it fails, return $r

  return $r;
}

function saveTOTP($get)
{
    $user = $get['user'];
    $secret = $get['secret'];
    $hash = $get['hash'];
    $code = $get['code'];
    $u = new UserFunctions($user);
    $r = $u->validateUser($user, $hash, $secret);
    if ($r === false) {
        return array('status' => false,'error' => "Couldn't validate cookie information",'human_error' => 'Application error');
    }

    return $u->saveTOTP($code);
}

function verifyTOTP($get)
{
    $code = $get['code'];
    $user = $get['user'];
    $password = urldecode($get['password']);
    $password = str_replace(' ', '+', $password);
    $secret = $get['secret'];
    $hash = $get['hash'];
    $remote = $get['remote'];
    $is_encrypted = boolstr($get['encrypted']);
  # If it's a good code, pass the cookies back
  $u = new UserFunctions($user);

  /* print_r("bob"."\n\n");
  $e=$u->encryptThis("sally","bob");
  print_r($e."\n\n");
  print_r($u->decryptThis("sally",$e)."\n\n");*/

  $r = $u->lookupUser($user, $password, false, $code);

    if ($r[0] === false) {
        $r['status'] = false;
        $r['human_error'] = $r['message'];

        return $r;
    }
  ## The user and code is valid!
  $return = array('status' => true);
    $userdata = $r[1];
    $cookie_result = $u->createCookieTokens(null, true, $remote);
    $return['cookies'] = $cookie_result;
    $return['string'] = json_encode($cookie_result['raw_cookie']);

    return $return;
}

function removeTOTP($get)
{
    /***
   * Remove the TOTP code
   ***/
  $u = new UserFunctions();

    return $u->removeTOTP($get['username'], $get['password'], $get['code']);
}

function removeAccount($get)
{
    # The password pushed in will need to be encrypted as if from login
  $baseurl = 'http';
    if ($_SERVER['HTTPS'] == 'on') {
        $baseurl .= 's';
    }
    $baseurl .= '://www.';
    $baseurl .= $_SERVER['HTTP_HOST'];
    $base_long = str_replace('http://', '', strtolower($baseurl));
    $base_long = str_replace('https://', '', strtolower($base_long));
    $base_arr = explode('/', $base_long);
    $base = $base_arr[0];
    $url_parts = explode('.', $base);
    $tld = array_pop($url_parts);
    $domain = array_pop($url_parts);
    $u = new UserFunctions($_COOKIE[$domain.'_user']);

    return $u->removeThisAccount($get['username'], $get['password'], $get['code']);
}

function sendTOTPText($get)
{
    $user = $get['user'];
  # We don't need to verify the user here
  $u = new UserFunctions($user);
  # Ensure the user has SMS-ability and 2FA
  try {
      # Return status
      if (!$u->has2FA()) {
          return array('status' => false,'human_error' => 'Two-Factor authentication is not enabled for this account','error' => 'Two-Factor authentication is not enabled for this account','username' => $user);
      }
      if (!$u->canSMS()) {
          return array('status' => false,'human_error' => "Your phone setup isn't complete",'error' => 'User failed SMS check','username' => $user);
      }
      $result = $u->sendTOTPText();

      return array('status' => $result,'message' => 'Message sent');
  } catch (Exception $e) {
      return array('status' => false,'human_error' => 'There was a problem sending your text.','error' => $e->getMessage());
  }
}


function verifyEmail($get)
{
    /***
     * Verify an email
     * An empty or bad verification code generates a new one to be saved in the temp column
     ***/
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('Login is running in debug mode!');
    if(!isset($get["alternate"])) {
        $get["alternate"] = false;
    } else {
        $get["alternate"] = toBool($get["alternate"]);
    }
    if(empty($get["username"])) {
        return array(
            "status" => false,
            "error" => "INVALID_PARAMETERS",
            "human_error" => "This function needs the parameter 'username' specified.",
        );
    }
    $u = new UserFunctions($get['username']);
    try {
        return $u->verifyEmail($get['auth'], $get['alternate']);
    } catch (Exception $e) {
        return array(
            "status" => false,
            "error" => $e->getMessage(),
            "human_error" => "Unable to send verification email",
        );
    }
}

function verifyPhone($get)
{
    /***
     * Verify a phone number.
     * An empty or bad verification code generates a new one to be saved in the temp column
     ***/
    $u = new UserFunctions($get['username']);
    try {
        return $u->verifyPhone($get['auth']);
    } catch (Exception $e) {
        return array('status' => false,'error' => $e->getMessage(),'human_error' => 'Failed to send verification text.');
    }
}

function saveToUser($get)
{
    /***
   * These are OK to pass with plaintext, they'll change with a different device anyway (non-persistent).
   * Worst-case scenario it only exposes public function calls. Sensitive things will need explicit revalidation.
   ***/
  $conf = $get['hash'];
    $s = $get['secret'];
    $id = $get['dblink'];
    $replace = boolstr($get['replace']);
  /***
   * These fields can only be written to from directly inside of a script, rather than an AJAX call.
   ***/
  $protected_fields = array(
    'username',
    'password',
    'admin_flag',
    'su_flag',
    'private_key',
    'public_key',
    'creation',
    'dblink',
    'secret',
    'emergency_code',
  );
    if (!empty($conf) && !empty($s) && !empty($id) && !empty($get['data']) && !empty($get['col'])) {
        $u = new UserFunctions();
        if ($u->validateUser($id, $conf, $s)) {
            // Yes, writeToUser looks up the validation again, but it is a more robust feedback like this
          // Could pass in $get for validation data, but let's be more limited
          $val = array('dblink' => $id,'hash' => $conf,'secret' => $s);
            $data = decode64($get['data']);
            $col = decode64($get['col']);
            if (empty($data) || empty($col)) {
                return array('status' => false,'error' => 'Invalid data format (required valid base64 data)');
            }
          // User safety
          if (in_array($col, $protected_fields, true)) {
              return array('status' => false,'error' => 'Cannot write to $col : protected field');
          }

            return $u->writeToUser($data, $col, $val);
        } else {
            return array('status' => false,'error' => 'Invalid user');
        }
    }

    return array('status' => false,'error' => 'One or more required fields were left blank');
}

function getFromUser($get)
{
    $conf = $get['hash'];
    $s = $get['secret'];
    $id = $get['dblink'];
    if (!empty($conf) && !empty($s) && !empty($id) && !empty($get['col'])) {
        $u = new UserFunctions();
        if ($u->validateUser($id, $conf, $s)) {
            require_once dirname(__FILE__).'/CONFIG.php';
            global $default_user_database,$default_user_table;
            $col = decode64($get['col']);
            $l = $u->openDB($default_user_database);
            $query = "SELECT $col FROM `$default_user_table` WHERE dblink='$id'";
            $r = mysqli_query($l, $query);
            $row = mysqli_fetch_row($r);

            return array('status' => true,'data' => deescape($row[0]),'col' => $col,'id' => $id);
        } else {
            return array('status' => false,'error' => 'Invalid user');
        }
    }

    return array('status' => false,'error' => 'One or more required fields were left blank');
}

function verifyUserAuth($get)
{
    $token = $get['token'];
    $userToActivate = $get['user'];
    $encoded_key = $get['key'];
    $user = new UserFunctions();

    return $user->verifyUserAuth($encoded_key, $token, $userToActivate);
}

function getProfileImage($profile)
{
    $u = new UserFunctions();

    return array('status' => true,'img' => $u->getUserPicture($profile));
}

function setNewProfileImage($get)
{
    $conf = $get['hash'];
    $s = $get['secret'];
    $id = $get['dblink'];
    if (!empty($conf) && !empty($s) && !empty($id)) {
        $u = new UserFunctions();
        if ($u->validateUser($id, $conf, $s)) {
            $result = $u->setUserPicture($get);
            if (!is_array($result)) {
                $result = array('status' => false,'error' => 'Invalid server response setting image','human_error' => 'There was a server error setting your image','app_error_code' => 121);
            }

            return $result;
        } else {
            return array('status' => false,'error' => 'Invalid user', 'human_error' => 'The app could not authorize you to the server','app_error_code' => 106);
        }
    }
    $emptyState = array(
        'hash' => $conf,
        'secret' => $s,
        'userid' => $id,
        'provided' => $get,
    );

    return array('status' => false,'error' => 'One or more required fields were left blank','human_error' => 'There was a problem communicating with the server','app_error_code' => 107,'details' => $emptyState);
}

function doStartResetPassword($get)
{
    $u = new UserFunctions($get['username']);

    return $u->resetUserPassword($get['method'], $get['totp']);
}

function finishResetPassword($get)
{
    try {
        $u = new UserFunctions($get['username']);
        $passwordBlob = array(
          'key' => $get['key'],
          'verify' => $get['verify'],
          'user' => $get['username'],
          'email_password' => $get['email_password'],
      );
        $ret = $u->doUpdatePassword($passwordBlob, true);
    } catch (Exception $e) {
        $ret = array('status' => false,'error' => $e->getMessage(),'human_error' => 'There was a server problem validating the reset. Please try again.', 'parse_error' => $e->getMessage());
    }

    return $ret;
}

function changePassword($get)
{
    /***
     * Note that this function assumes that the preprocessor took care
     * of verifying the new password was as intended. It does NOT
     * check for a matched password.
     ***/
    try {
        $u = new UserFunctions($get['username']);
        $passwordBlob = array(
            'old' => $get['old_password'],
            'new' => $get['new_password'],
        );
        $ret = $u->doUpdatePassword($passwordBlob);
    } catch (Exception $e) {
        $ret = array('status' => false,'error' => $e->getMessage(),'human_error' => 'There was a problem updating your password ('.$e->getMessage().'). Please try again.');
    }
    $ret['action'] = 'changepassword';

    return $ret;
}
