<?php
/**
 *
 */
// ini_set("display_errors",1);
// ini_set("log_errors",1);
// error_reporting(E_ALL);
// session_start();
// Set this up so all the data is parsed and packaged to be returned as a nice neat set, and forward the data to the handler variable.
// The return URL is based on a secret and the nearest mod-60-sec microtime.
// Verification is checked against the previous and next mod 60
require_once(dirname(__FILE__).'/core/core.php');
$signin_type=$_REQUEST['login_type'];
# Import secrets
require_once(dirname(__FILE__).'/secrets.php');
?>
<!doctype html>
<html>
<head>
<title>Multi-Login Demo</title>
<link rel='stylesheet' type='text/css' href='css/oa.min.css' media='screen'/>
    <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js'></script>
    <script type="text/javascript" src="bower_components/js-base64/base64.js"></script>
<?php echo "<meta name=\"google-signin-client_id\" content=\"".$google_clientid."\">"; ?>
    <script type='text/javascript' src='js/oa.js'></script>
    </head>
    <body>
    <main>
<?php

$buffer="
";
## Don't change these! Configs for twitteroauth
define('CONSUMER_KEY', $twitter_clientid);
define('CONSUMER_SECRET', $twitter_secret);
define('OAUTH_CALLBACK', $returnurl);

$haveAuth=false;



function setAuthParams($idents,$special)
{
  /**
   * Each case will pass an array of unique, static, identifying
   * parameters. This function will take those parameters, make them
   * "neat", then use the login_handler functions to package them off
   * to the appropriate destination. If there isn't a redirect, then
   * this function handles the user-facing output.
   */
  // use the user ID to create a repeatable permutation of the
  // imploded values as the 'password'.

  // find a zip if not provided
  if(array_key_exists('location',$special) && !array_key_exists('zip',$special))
    {
      $url="http://maps.googleapis.com/maps/api/geocode/json?";
      $sensor="&sensor=false";
      $get=$url."address=".str_replace(" ","+",$special['location']).$sensor;
      if($json=@file_get_contents($get))
        {
          $arr=json_decode($json,true);
          $coord=$arr['results'][0]['geometry']['location'];
          $get=$url."latlng=".$coord['lat'].",".$coord['lng'].$sensor;
          if($json=@file_get_contents($get))
            {
              $x=json_decode($json,true);
              $ac=$x['results'][0]['address_components'];
              foreach($ac as $e)
                {
                  if($e['types'][0]=='postal_code')
                    {
                      $zip=$e['long_name'];
                      break;
                    }
                }
            }
        }
      if(isset($zip)) $special['zip']=$zip;
    }
  // do guessing for first/last name
  if(array_key_exists('full_name',$special) && !array_key_exists('last_name',$special))
    {
      $name=explode('',$special['full_name']);
      $special['first_name']=$name[0];
      $n=sizeof($name)-1; // almost always will return n=1
      $special['last_name']=$name[$n];
    }
  // create unique user string
  $user_unique_string=sha1($your_secret.$idents[0].implode("",$idents));
  return array_merge(array('password'=>$user_unique_string),$special);
}

/**
 * display provider switch to the left
 * Only display a provider if the secret is non-null.
*/

$buffer.= "<section id='provider_list'>
  <ul>";
if(!empty($google_clientid) && !empty($google_secret)) $buffer.="\n    <li><a href='?provider=google'><img src='res/gplus.svg' alt='Google+' style='width:128px' id='google_logo' class='logo_list'/></a></li>";
if(!empty($twitter_clientid) && !empty($twitter_secret)) $buffer.="\n    <li><a href='?provider=twitter'><img src='res/twitter-bird.svg' alt='Twitter' style='width:128px' id='twitter_logo' class='logo_list'/></a></li>";
if(!empty($facebook_appid) && !empty($facebook_secret)) $buffer.="\n    <li><a href='?provider=facebook'><img src='res/FB-fLogo.svg' alt='Facebook' style='width:128px' id='facebook_logo' class='logo_list'/></a></li>";
$buffer.="  </ul>
</section>
<section id='auth_panel'>";

/**
 * Handle providers in a massive switch block.
 */
switch($provider)
  {
  case 'google':
    try
      {
        // try g+, then oauth, THEN openid
        $buffer.="<script type='text/javascript'>$('#google_logo').css('opacity','1');</script>";
        try
          {
            // g+ login
            // can't debug this on rothstein without a higher php version
            // see index.html and the g+ app in ref
            # throw new Exception('ForceException');
              /*
                (function() {
                var po = document.createElement('script');
                po.type = 'text/javascript'; po.async = true;
                po.src = 'https://plus.google.com/js/client:plusone.js';
                var s = document.getElementsByTagName('script')[0];
                s.parentNode.insertBefore(po, s);
                })();
                <div class='g-signin2'
                data-scope='https://www.googleapis.com/auth/plus.login'
                data-requestvisibleactions='http://schemas.google.com/AddActivity'
                data-clientId='$google_clientid'
                data-accesstype='offline'
                data-callback='googleOAuthCallback'
                data-theme='dark'
                data-cookiepolicy='single_host_origin'>
                </div>
               */
            $buffer.= "
<script src=\"https://apis.google.com/js/platform.js\" async defer></script>
  <div id='gConnect'>
    <div class='g-signin2'
data-onload='false'
                data-clientId='$google_clientid'
        data-onsuccess='onSignInCallback'
data-onfailure='onFailureCallback'>
    </div>
  </div>";
          }
        catch(Exception $e)
          {
            // oauth2
              require_once 'lib/google-php-client/vendor/autoload.php';
              # require_once 'lib/google-php-client/src/Google/Service/Oauth2.php';
            $client = new Google_Client();
            $client->setApplicationName($sitename." Login");
            $client->setClientId($google_clientid);
            $client->setClientSecret($google_secret);
            $client->setRedirectUri($returnurl); // just back here, only do parsing on good return

            $oauth2 = new Google_Service_Oauth2($client);
            if (isset($_GET['code'])) {
              try {
                $buffer.="Enter block";
                $client->authenticate($_GET['code']);
                $buffer.=" Authenticated";
                $_SESSION['token'] = $client->getAccessToken();
                $buffer.=" Session Set";
                $redirect = $returnurl; //'http://' . $_SERVER['HTTP_HOST'] . $_SERVER['PHP_SELF'];
                $buffer.=" Redirect set";
                header('Location: ' . filter_var($redirect, FILTER_SANITIZE_URL));
                return;
              }
              catch(Exception $e) {
                $buffer.="<br/><pre>PHP error - $e</pre>";
              }
            }

            if (isset($_SESSION['token'])) {
              $client->setAccessToken($_SESSION['token']);
            }

            if (isset($_REQUEST['logout'])) {
              unset($_SESSION['token']);
              $client->revokeToken();
            }

            if ($client->getAccessToken()) {
              $user = $oauth2->userinfo->get();

              // These fields are currently filtered through the PHP sanitize filters.
              // See http://www.php.net/manual/en/filter.filters.sanitize.php
              $email = filter_var($user['email'], FILTER_SANITIZE_EMAIL);
              $img = filter_var($user['picture'], FILTER_VALIDATE_URL);
              $personMarkup = "$email<div><img src='$img?sz=50'></div>";

              // The access token may have been updated lazily.
              $_SESSION['token'] = $client->getAccessToken();
            } else {
              $authUrl = $client->createAuthUrl();
            }
            if(isset($user))   {
              //$buffer.= "<pre>User: ".print_r($user,true)."</pre>$personMarkup";
              //$buffer.= "<a class='logout' href='?provider=google&amp;logout=true'>Logout</a>";
              $hasAuth=true;
              $unique_credentials=array(
                $user['id'],
                $user['email'],
                $user['link'],
              );
              $ex=explode("@",$user['email']);
              $user_special=array(
                "email"=>$user['email'],
                "picture"=>$user['picture'],
                "first_name"=>$user['given_name'],
                "last_name"=>$user['family_name'],
                "full_name"=>$user['name'],
                "handle"=>$ex[0]
              );
            }
            else if(isset($authUrl)) {
              $buffer.= "
<script type='text/javascript'>
// preload resources
$(['res/gzip-svg.php?name=google_signin_hover.svg','res/gzip-svg.php?name=google_signin_click.svg']).preload();
function bindMouse() {
    // needs to handle old IE with PNGs
    $('#signin_button').on({
	mouseenter: function(){
	    $('#signin_button').attr('src','res/gzip-svg.php?name=google_signin_hover.svg');
	    $('#signin_button').attr('data','res/gzip-svg.php?name=google_signin_hover.svg');
	    console.log('MouseOver');
	},
	mouseleave: function(){
	    $('#signin_button').attr('src','res/gzip-svg.php?name=google_signin_button.svg');
	    $('#signin_button').attr('data','res/gzip-svg.php?name=google_signin_button.svg');
	    console.log('MouseOut');
	},
	mouseup: function(){
	    $('#signin_button').attr('src','res/gzip-svg.php?name=google_signin_hover.svg');
	    $('#signin_button').attr('data','res/gzip-svg.php?name=google_signin_hover.svg');
	    console.log('MouseUp');
	},
	mousedown: function(){
	    $('#signin_button').attr('src','res/gzip-svg.php?name=google_signin_click.svg');
	    $('#signin_button').attr('data','res/gzip-svg.php?name=google_signin_click.svg');
	    console.log('MouseDown');
	}
    });
}
</script>
<a class='login' href='$authUrl'>
";
              $buffer.="<img src='res/google_signin_button.svg' alt=Sign in with Google' style='width:320px;height:108px;' class='signin_button'/>.</a>";
            }
            else {
              $buffer.="<h1>Bad parsing. Application error.</h1>";
            }
          }
      }
    catch(Exception $e)
      {
          # TODO
      }
    break;
  case 'twitter':
    // https://dev.twitter.com/docs/auth/implementing-sign-twitter
    $buffer.="<script type='text/javascript'>$('#twitter_logo').css('opacity','1');</script>";
    require_once('lib/twitteroauth/twitteroauth/twitteroauth.php');
    define("OAUTH_CALLBACK",urlencode($baseurl."/oauth/oauth.php?provider=twitter"));
    // As readme; save token_credentials as json object in password field
    // Initial implementation as twitteroauth test.php
    // session instances should be replaced with DB calls
    if($_REQUEST['callback']!='true' && $_REQUEST['good_credentials']!='true')
      {
        /* If access tokens are not available redirect to connect page. */
        if (empty($_SESSION['access_token']) || empty($_SESSION['access_token']['oauth_token']) || empty($_SESSION['access_token']['oauth_token_secret'])) {
          //header('Location: ./clearsessions.php'); // fold into major session clearing mode of normal display
          $buffer.="<p>Need to make a better image.</p><pre>Callback URL: $returnurl | ".OAUTH_CALLBACK."</pre><a href='".appendQuery('callback=true')."'>Login with Twitter</a>";
        }
        else
          {
            $buffer.= "Temp: Go here to reset this: <a href='http://test.reallyactivepeople.com/oauth/lib/twitteroauth/clearsessions.php'>Test Clearing</a>";
            /* Get user access tokens out of the session. */
            $access_token = $_SESSION['access_token'];

            /* Create a TwitterOauth object with consumer/user tokens. */
            $connection = new TwitterOAuth(CONSUMER_KEY, CONSUMER_SECRET, $access_token['oauth_token'], $access_token['oauth_token_secret']);

            /* If method is set change API call made. Test is called by default. */
            $content = $connection->get('account/rate_limit_status');
            $buffer.= "<br/>Current API hits remaining: ".$content->remaining_hits;

            /* Get logged in user to help with tests. */
            $user = $connection->get('account/verify_credentials');
            //$buffer.="<pre>".print_r($user,true)."</pre>";
            $hasAuth=true;
            $unique_credentials=array(
              $user->id,
              $user->url,
              $user->screen_name,
            );
            $user_special=array(
              "email"=>$user->screen_name."@twitter.com",
              "picture"=>$user->profile_image_url,
              "full_name"=>$user->name,
              "location"=>$user->location,
              "handle"=>$user->screen_name
            );
          }
      }
    else if($_REQUEST['good_credentials']=='true')
      {
        // point here for verified
        $buffer.="Verified credentials";
      }
    else
      {
        /* If the oauth_token is old redirect to the connect page. */
        if (isset($_REQUEST['oauth_token']) && $_SESSION['oauth_token'] !== $_REQUEST['oauth_token']) {
          $_SESSION['oauth_status'] = 'oldtoken';
          //header('Location: ./clearsessions.php');
        }

        /* Create TwitteroAuth object with app key/secret and token key/secret from default phase */
        if(isset($_SESSION['oauth_token']))
          {
            $buffer.="We have a session token!";
            $connection = new TwitterOAuth(CONSUMER_KEY, CONSUMER_SECRET, $_SESSION['oauth_token'], $_SESSION['oauth_token_secret']);

            /* Request access tokens from twitter */
            $access_token = $connection->getAccessToken($_REQUEST['oauth_verifier']);

            /* Save the access tokens. Normally these would be saved in a database for future use. */
            $_SESSION['access_token'] = $access_token;

            /* Remove no longer needed request tokens */
            unset($_SESSION['oauth_token']);
            unset($_SESSION['oauth_token_secret']);

            /* If HTTP response is 200 continue otherwise send to connect page to retry */
            if (200 == $connection->http_code) {
              /* The user has been verified and the access tokens can be saved for future use */
              $_SESSION['status'] = 'verified';
              header('Location: ./oauth.php?provider=twitter'); // point back to this page for debug, eventually to handler page
            } else {
              /* Save HTTP status for error dialog on connnect page.*/
              header('Location: ./clearsessions.php'); // fold in to major session clearing mode
            }
          }
        else
          {
            $buffer.="No session token, redirect page";
            /* Build TwitterOAuth object with client credentials. */
            $connection = new TwitterOAuth(CONSUMER_KEY, CONSUMER_SECRET);

            /* Get temporary credentials. */
            $request_token = $connection->getRequestToken(OAUTH_CALLBACK);

            /* Save temporary credentials to session. */
            $_SESSION['oauth_token'] = $token = $request_token['oauth_token'];
            $_SESSION['oauth_token_secret'] = $request_token['oauth_token_secret'];

            /* If last connection failed don't display authorization link. */
            switch ($connection->http_code) {
            case 200:
              /* Build authorize URL and redirect user to Twitter. */
              $url = $connection->getAuthorizeURL($token);
              header('Location: ' . $url."&oauth_callback=".$returnurl);
              break;
            default:
              /* Show notification if something went wrong. */
              $buffer.= 'Could not connect to Twitter. Refresh the page or try again later.';
            }
          }
      }
    break;
  case 'facebook':
    // https://developers.facebook.com/docs/facebook-login/getting-started-web/
    // https://developers.facebook.com/apps
    require_once('lib/facebook-php/src/facebook.php');
    $config=array('appId'=>$facebook_appid,'secret'=>$facebook_secret);
    $facebook = new Facebook($config);
    $scope=array('scope'=>'email');
    $includefbsdk=true;

    /**
     * User URL redirects:
     * https://developers.facebook.com/docs/reference/php/facebook-getLoginStatusUrl/
     * and
     * https://developers.facebook.com/docs/reference/php/facebook-getLoginUrl/
     * then, to get users, use
     * https://developers.facebook.com/docs/reference/php/facebook-api/
     */
    $user_id = $facebook->getUser();
    if($user_id) {

      // We have a user ID, so probably a logged in user.
      // If not, we'll get an exception, which we handle below.
      try {
        $user_profile = $facebook->api('/me','GET');

        //$buffer.="<pre>".print_r($user_profile,true)."</pre>";
        /*
        $fql = 'SELECT name from user where uid = ' . $user_id;
        $ret_obj = $facebook->api(array(
          'method' => 'fql.query',
          'query' => $fql,
        ));
        // FQL queries return the results in an array, so we have
        //  to get the user's name from the first element in the array.
        $buffer.="FQL result: ".'<pre>Name: ' . $ret_obj[0]['name'] . '\n'.print_r($ret_obj,true).'</pre>';
        */
        $includefbsdk=false;
        $hasAuth=true;
        $unique_credentials=array(
          $user_profile['id'],
          $user_profile['link'],
          $user_profile['username']
        );
        $user_special=array(
          "email"=>$user_profile['email'],
          "picture"=>"https://graph.facebook.com/".$user_profile['username']."/picture",
          "first_name"=>$user_profile['first_name'],
          "last_name"=>$user_profile['last_name'],
          "handle"=>$user_profile['username'],
          "full_name"=>$user_profile['name'],
          "location"=>$user_profile['location']['name']
        );
      } catch(FacebookApiException $e) {
        // If the user is logged out, you can have a
        // user ID even though the access token is invalid.
        // In this case, we'll get an exception, so we'll
        // just ask the user to login again here.
        $login_url = $facebook->getLoginUrl($scope);
        $buffer.= '<div id="basic_fb_login"><p>Please <a href="' . $login_url . '">click here to login with Facebook</a>. If you see this instead of a fancy login, you may have blocked Facebook Javascript plugins.</p></div>';
        /*echo $e->getType();
          echo $e->getMessage();*/
      }
    } else {

      // No user, so print a link for the user to login
      $login_url = $facebook->getLoginUrl($scope);
      $buffer.='<div id="basic_fb_login"><p>Please <a href="' . $login_url . '">click here to login with Facebook</a>. If you see this instead of a fancy login, you may have blocked Facebook Javascript plugins.</p><?div>';

    }
    $fb_js_sdk="  window.fbAsyncInit = function() {
    FB.init({
      appId      : '".$facebook_appid."', // App ID
      channelUrl : '//".$domain."/channel.html', // Channel File
      status     : true, // check login status
      cookie     : true, // enable cookies to allow the server to access the session
      xfbml      : true  // parse XFBML
    });

    // Additional init code here
    $.getScript('js/fb.js');
  };


  // Load the SDK asynchronously
  (function(d){
     var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
     if (d.getElementById(id)) {return;}
     js = d.createElement('script'); js.id = id; js.async = true;
     js.src = '//connect.facebook.net/en_US/all.js';
     ref.parentNode.insertBefore(js, ref);
   }(document));";
    if($includefbsdk) $js.=$fb_js_sdk;
    $buffer.="<script type='text/javascript'>$('#facebook_logo').css('opacity','1');
$js
</script>";
    if($includefbsdk) $buffer.="<div id='fb-login-container'><fb:login-button show-faces='true' width='200' max-rows='1' scope='email'></fb:login-button></div>";
    break;
  default:
    // return an error
    $buffer.="<h1>Error - Bad Provider</h1><p>You seem to be trying to log in with a provider we don't support. Please select one of the provider options listed.</p>";
  }
if($hasAuth)
  {
    $buffer.="<pre>Claimed these credentials:\n".print_r($unique_credentials,true)."\n".print_r($user_special,true)."</pre>";
    $buffer.="<pre>Will send this info for processing:\n".print_r(setAuthParams($unique_credentials,$user_special),true)."</pre>";
  }
$buffer.= "</section><br class='clear'/>";
echo $buffer;
?>
</main>
</body>
<script type='text/javascript'>
  try{$(document).ready(bindMouse());}
catch(e){
// handle me
}
</script>
</html>
