<?php
/**
 * This is where users are redirected after oauth.php handles the
 * login, verification, and packaging of data. This is the part that
 * mostly handles data interaction with a database, UI flow, etc.
 *
 * The handled values are made "clean" of provider tags and returned
 * in a single format. These values are then POSTed to the redirect
 * page specified in vars.php. If an authenticator function was
 * defined, instead the result of that is returned to the redirect page.
*/
ini_set("display_errors",1);
ini_set("log_errors",1);
error_reporting(E_ALL);
$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);
require_once "core/core.php";
require_once(dirname(__FILE__) . '/secrets.php'); // just in case. Shouldn't be needed

// Write the provided ID from the provider to a new user if not
// created. Create a fake email based on their provider identity if a
// real one can't be provided. The provided ID should be written to
// the password field, along with some other personal, hard-to-obtain
// information from each provider to securely identify each user.
$start_script_timer = microtime_float();

$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);

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

function returnAjax($data)
{
    /***
     * Return the data as a JSON object
     *
     * @param array $data
     *
     ***/
    if(!is_array($data)) $data=array($data);
    $data["execution_time"] = elapsed();
    header('Cache-Control: no-cache, must-revalidate');
    header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
    header('Content-type: application/json');
    $json = json_encode($data,JSON_FORCE_OBJECT);
    $replace_array = array("&quot;","&#34;");
    print str_replace($replace_array,"\\\"",$json);
    exit();
}


$provider = isset($_REQUEST['provider']) ? strtolower($_REQUEST['provider']):null;

switch($provider) {
case "google":
    returnAjax(authGoogle($_REQUEST));
    break;
case "test":
    returnAjax(
        array(
            "computed" => computeUserPassword($_REQUEST["q"]),
            "encoded" =>  base64_encode($_REQUEST["q"] . $your_secret . ($your_secret | $_REQUEST["q"])),
            )
        );
    break;
default:
    returnAjax(
        array(
            "status" => false,
            "error" => "Invalid provider",
        )
    );
}

function authGoogle($get) {
    require_once 'lib/google-php-client/vendor/autoload.php';
    global $google_clientid, $google_secret, $google_config_file_path;

    /*************************************************
     * Ensure you've downloaded your oauth credentials
     ************************************************/
    if (!file_exists($google_config_file_path)) {
            return array(
                "status" => false,
                "error" => "Bad config file path",
            );
        }
    /************************************************
     * NOTICE:
     * The redirect URI is to the current page, e.g:
     * http://localhost:8080/idtoken.php
     ************************************************/
    $redirect_uri = 'http://' . $_SERVER['HTTP_HOST'] . $_SERVER['PHP_SELF'];
    $client = new Google_Client();
    $client->setAuthConfig($google_config_file_path);
    $client->setRedirectUri($redirect_uri);
    $client->setScopes('email');
    /************************************************
     * If we're logging out we just need to clear our
     * local access token in this case
     ************************************************/
    if (isset($_REQUEST['logout'])) {
        unset($_SESSION['id_token']);
    }
    $token = $get["token"];
    try {
    /************************************************
     * If we have a code back from the OAuth 2.0 flow,
     * we need to exchange that with the
     * Google_Client::fetchAccessTokenWithAuthCode()
     * function. We store the resultant access token
     * bundle in the session, and redirect to ourself.
     ************************************************/
        if (!empty($token) && empty($get["tokens"])) {
        $fancyToken = array(
            "access_token" => $token,
        );
        $token = $client->fetchAccessTokenWithAuthCode($get["token"]);
        $client->setAccessToken($token);
        // store in the session also
        $_SESSION['id_token'] = $token;
        $token_data = $client->verifyIdToken();
        } else if (!empty($get["tokens"])) {
            $tokens = base64_decode($get["tokens"]);
            $client->setAccessToken($get["tokens"]);
            $ta = json_decode($tokens, true);
            $token_data = $client->verifyIdToken($ta["id_token"]);
        }else {
    /************************************************
  If we have an access token, we can make
  requests, else we generate an authentication URL.
    ************************************************/
        $authUrl = $client->createAuthUrl();
    }
    }catch (Exception $e) {
        $token2 = $get['token'];
        if (is_string($token2)) {
            if ($json = json_decode($token2, true)) {
                $token2 = $json;
            } else {
                // assume $token is just the token string
                $token2 = array(
                    'access_token' => $token2,
                );
            }
        }
        return array(
            "status" => false,
            "error" => $e->getMessage(),
            "stack" => $e->getTraceAsString(),
            "token" => $token,
            "computed_token" => $token2,
            "tokens" => base64_decode($get["tokens"]),
        );
    }
    /************************************************
  If we're signed in we can go ahead and retrieve
  the ID token, which is part of the bundle of
  data that is exchange in the authenticate step
  - we only need to do a network call if we have
  to retrieve the Google certificate to verify it,
  and that can be cached.
    ************************************************/
    $return = array(
        "status" => true,
        "auth_url" => $authUrl,
        "token_data" => $token_data,
        "identifier" => $token_data["email"],
        "verifier" => computeUserPassword($token_data["sub"]),
    );
    return $return;
}


function computeUserPassword($identity) {
    global $your_secret;
    # This complicated encoding is purely security through obscurity.
    $encoded = base64_encode($identity . $your_secret . ($your_secret | $identity));
    return hash("sha512", $encoded);
}
?>