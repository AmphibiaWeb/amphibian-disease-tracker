<?php
/***
 * This is designed to be included in a page, and doesn't have the
 * page framework on its own.
 * Be sure after including this file to output the variable
 *   $login_output
 * If you want a display!
 ***/

$debug = false;

if($debug) {
    error_reporting(E_ALL);
    ini_set("display_errors", 1);
    error_log("Login is running in debug mode!");
}

require_once(dirname(__FILE__).'/CONFIG.php');


if($require_two_factor)
  {
    # Implies this
    $ask_twofactor_at_signup = true;
  }

if($ask_twofactor_at_signup || $ask_verify_phone_at_signup)
  {
    # Override any redirects
    $post_create_redirect = false;
  }


if(!empty($self_referential))
  {
    $self_url = $self_referential;
  }
else
  {
    $self_url = $_SERVER['PHP_SELF'];
  }

if(empty($baseurl))
  {
    $baseurl = 'http';
    if ($_SERVER["HTTPS"] == "on") {$baseurl .= "s";}
    $baseurl .= "://";
    $baseurl.=$_SERVER['HTTP_HOST'];
  }

$base_long = str_replace("http://","",strtolower($baseurl));
$base_long = str_replace("https://","",strtolower($base_long));
$base_arr = explode("/",$base_long);
$base = $base_arr[0];
$url_parts = explode(".",$base);
$tld = array_pop($url_parts);
if($url_parts[0] == "www") {
    $domain = array_pop($url_parts);
}
else $domain = implode(".",$url_parts);
$shorturl = $domain . "." . $tld;

$cookie_domain = str_replace(".","_",$domain);
$cookielink = $domain."_link";
$cookie_domain = empty($_COOKIE[$cookielink]) ? $cookie_domain:$domain;


if(!is_numeric($minimum_password_length)) $minimum_password_length=8;
if(!is_numeric($password_threshold_length)) $password_threshold_length=20;

/*
 * Cookie names for tracking
 */

$cookieuser=$cookie_domain."_user";
$cookieperson=$cookie_domain."_name";
$cookieauth=$cookie_domain."_auth";
$cookiekey=$cookie_domain."_secret";
$cookiepic=$cookie_domain."_pic";
$cookielink=$cookie_domain."_link";


/*
 * Required inclusions
 */

require_once(dirname(__FILE__).'/core/core.php');
require_once(dirname(__FILE__).'/handlers/login_functions.php');


$xml=new Xml;
$user=new UserFunctions;


if($debug)
  {
    /*if($r===true) echo "<p>(Database OK)</p>";
      else echo "<p>(Database Error - ' $r ')</p>";*/
    echo "<p>Visiting $baseurl on '$shorturl' with a human domain '$domain'</p>";
    echo displayDebug($_REQUEST);
    echo "<p>".displayDebug(DBHelper::staticSanitize('tigerhawk_vok-goes.special@gmail.com'))."</p>";
    $xkcd_check="Robert'); DROP TABLE Students;--"; // https://xkcd.com/327/
    echo "<p>".displayDebug(DBHelper::staticSanitize($xkcd_check))."</p>"; // This should have escaped code
    echo "<p>User Validation:</p>";
    echo displayDebug($user->validateUser($_COOKIE[$cookielink],null,null,true));
    echo displayDebug($_COOKIE[$cookielink]);
    echo displayDebug($_COOKIE);
    echo "</div>";
  }

$login_output = "";

if($_REQUEST['q']=='logout')
  {
    setcookie($cookieuser,false,time()-3600*24*365,'/');
    setcookie($cookieperson,false,time()-3600*24*365,'/');
    setcookie($cookieauth,false,time()-3600*24*365,'/');
    setcookie($cookiekey,false,time()-3600*24*365,'/');
    setcookie($cookiepic,false,time()-3600*24*365,'/');
    // do JS cookie wipe too
    $deferredJS.="\n$.removeCookie('$cookieuser',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookieperson',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookieauth',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookiekey',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookiepic',{path:'/'});";
    $deferredJS.="\nresetLoginState();";
    $deferredScriptBlock = "<script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js'></script>
<script type='text/javascript' src='".$relative_path."js/loadJQuery.js'></script>
<script type='text/javascript'>
var loadLast = function () {
    try {
        $deferredJS
    }
    catch (e)
    {
        console.error(\"Couldn't load deferred calls\");
    }
}
</script>";
    header("Refresh: 2; url=".$baseurl);
    ob_end_flush();
    $login_output.="<h1>Logging out ...</h1>".$deferredScriptBlock;
  }

try
{
  $logged_in=$user->validateUser($_COOKIE[$cookielink]);
  if(!$user->has2FA() && $require_two_factor === true && !isset($_REQUEST['2fa']) && $logged_in && $_REQUEST['q']!='logout')
    {
      # If require two factor is on, always force it post login
      header("Refresh: 0; url=".$self_url."?2fa=t");
      $deferredJS.="\nwindow.location.href=\"".$self_url."?2fa=t\";";
      ob_end_flush();
    }
  # This should only show when there isn't two factor enabled ...
  $twofactor = $user->has2FA() ? "Remove two-factor authentication":"Add two-factor authentication";
  $phone_verify_template = "<form id='verify_phone' onsubmit='event.preventDefault();'>
  <input type='tel' id='phone' name='phone' value='".$user->getPhone()."' readonly='readonly'/>
  <input type='hidden' id='username' name='username' value='".$user->getUsername()."'/>
  <button id='verify_phone_button'>Verify Phone Now</button>
  <p>
    <small>
      <a href='#' id='verify_later'>
        Verify Later
      </a>
    </small>
  </p>
</form>";
  try
    {
  $needPhone = !$user->canSMS();
$deferredJS .= "console.log('Needs phone? ',".strbool($needPhone).",".DBHelper::staticSanitize($user->getPhone()).");\n";
  $altPhone = "<p>Congratulations! Your phone number is verified.</p>";
}
  catch(Exception $e)
    {
  $needPhone = false;
  $deferredJS .= "console.warn('An exception was thrown checking for SMS-ability:','".$e->getMessage()."');\n";
  $altPhone = "<p>You don't have a phone number registered with us. Please go to account settings and add a phone number.</p>";
}
  $verifyphone_link =  $needPhone ? "<li><a href='?q=verify'>Verify Phone</a></li>":null;
  $phone_verify_form = $needPhone ? $phone_verify_template : $altPhone;

}
catch (Exception $e)
  {
    # There have been no cookies set.
    $logged_in = false;
    $twofactor = "Please log in.";
  }

$login_output = "";

if($_REQUEST['q']=='logout')
  {
    setcookie($cookieuser,false,time()-3600*24*365,'/');
    setcookie($cookieperson,false,time()-3600*24*365,'/');
    setcookie($cookieauth,false,time()-3600*24*365,'/');
    setcookie($cookiekey,false,time()-3600*24*365,'/');
    setcookie($cookiepic,false,time()-3600*24*365,'/');
    // do JS cookie wipe too
    $deferredJS.="\n$.removeCookie('$cookieuser',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookieperson',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookieauth',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookiekey',{path:'/'});";
    $deferredJS.="\n$.removeCookie('$cookiepic',{path:'/'});";
    $deferredScriptBlock = "<script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js'></script>
<script type='text/javascript' src='".$relative_path."js/loadJQuery.min.js'></script>
<script type='text/javascript'>
var loadLast = function () {
    try {
        $deferredJS
    }
    catch (e)
    {
        console.error(\"Couldn't load deferred calls\");
    }
}
</script>";
    header("Refresh: 2; url=".$baseurl);
    ob_end_flush();
    $login_output.="<h1>Logging out ...</h1>".$deferredScriptBlock;
  }

try
{
  $logged_in=$user->validateUser($_COOKIE[$cookielink]);
  if(!$user->has2FA() && $require_two_factor === true && !isset($_REQUEST['2fa']) && $logged_in && $_REQUEST['q']!='logout')
    {
      # If require two factor is on, always force it post login
      header("Refresh: 0; url=".$self_url."?2fa=t");
      $deferredJS.="\nwindow.location.href=\"".$self_url."?2fa=t\";";
      ob_end_flush();
    }
  # This should only show when there isn't two factor enabled ...
  $twofactor = $user->has2FA() ? "Remove two-factor authentication":"Add two-factor authentication";
  $phone_verify_template = "<form id='verify_phone' onsubmit='event.preventDefault();'>
  <input type='tel' id='phone' name='phone' value='".$user->getPhone()."' readonly='readonly'/>
  <input type='hidden' id='username' name='username' value='".$user->getUsername()."'/>
  <button id='verify_phone_button' class='btn btn-primary'>Verify Phone Now</button>
  <p>
    <small>
      <a href='#' id='verify_later'>
        Verify Later
      </a>
    </small>
  </p>
</form>";
  try
    {
  $needPhone = !$user->canSMS();
  $deferredJS .= "console.log('Needs phone? ',".strbool($needPhone).",".DBHelper::staticSanitize($user->getPhone()).");\n";
  $altPhone = "<p>Congratulations! Your phone number is verified.</p>";
}
  catch(Exception $e)
    {
  $needPhone = false;
  $deferredJS .= "console.warn('An exception was thrown checking for SMS-ability:','".$e->getMessage()."');\n";
  $altPhone = "<p>You don't have a phone number registered with us. Please go to account settings and add a phone number.</p>";
}
  $verifyphone_link =  $needPhone ? "<li><a href='?q=verify'>Verify Phone</a></li>":null;
  $phone_verify_form = $needPhone ? $phone_verify_template : $altPhone;

}
catch (Exception $e)
  {
    # There have been no cookies set.
    $logged_in = false;
    $twofactor = "Please log in.";
  }

if($logged_in)
  {
    $xml->setXml($_COOKIE[$cookieperson]);
    $full_name=$xml->getTagContents("<name>");
    $first_name=$xml->getTagContents("<fname>");
    $display_name=$xml->getTagContents("<dname>");
    if(empty($first_name)) $first_name = $_COOKIE[$cookieperson];
  }
else
  {
    if($captive_login)
      {
        header("Refresh: 0; url=$baseurl");
        $deferredJS.="\nwindow.location.href=\"$baseurl\";";
      }
  }

// $random = "<li><a href='#' id='totp_help'>Help with Two-Factor Authentication</a></li>";

try
  {
    $has2fa = strbool($user->has2FA());
  }
catch(Exception $e)
  {
    $has2fa = false;
  }
$settings_blob = "<section id='account_settings' class='panel panel-default clearfix'><div class='panel-heading'><h2 class='panel-title'>Settings</h2></div><div class='panel-body'><ul id='settings_list'><li><a href='#' id='showAdvancedOptions' data-domain='$domain' data-user-tfa='".$has2fa."' role='button' class='btn btn-default'>Account Settings</a></li>".$verifyphone_link.$random."</ul></div></section>";

$login_output.="<div id='login_block'>";
$alt_forms="<div id='alt_logins'>
<!-- OpenID, Google, Twitter, Facebook -->
</div>";
$login_preamble = "
	    <h2 id='title'>User Login</h2>";
if($_REQUEST['m']=='login_error') $login_preamble.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p><strong>There was a problem setting your login credentials</strong>. Please try again.</p></div>";
$loginform = "<script src='bower_components/bootstrap/dist/js/bootstrap.min.js' type='text/javascript' charset='utf-8'></script>
	    <form id='login' method='post' action='?q=submitlogin' class='form-horizontal'>
            <fieldset>
              <legend>Login</legend>
<div class='form-group col-sm-9 col-md-5'>
	      <label for='username' class='control-label'>
		Email:
	      </label>
	      <input class='form-control' type='email' name='username' id='username' placeholder='user@domain.com' autofocus='autofocus' required='required'/>
	      </div>
<div class='form-group col-sm-9 col-md-5 has-feedback'>
	      <label for='password' class='control-label'>
		Password:
	      </label>
	      <input class='form-control' type='password' name='password' id='password' placeholder='Password' class='password-input' required='required'/> <span class='glyphicon glyphicon-question-sign do-password-reset form-control-feedback' style='pointer-events:all;' id='reset-password-icon' data-toggle='tooltip' title='Forgot Password?'></span>
</div>
</fieldset>";
$loginform_close="	      <br/>
	      <button id='login_button' class='btn btn-primary'>Login</button>
	    </form>$alt_forms<br/><p id='form_create_new_account'><small>Don't have an account yet? <a href='?q=create'>Create one</a>!</small></p>";
$big_login=$login_preamble.$loginform.$loginform_close;
$small_login=$loginform.$loginform_close;
if($_REQUEST['q']=='submitlogin')
  {
    if(!empty($_POST['username']) && !empty($_POST['password']))
      {
        $totp = empty($_POST["totp"]) ? false:$_POST["totp"];
        $res = $user->lookupUser($_POST['username'], $_POST['password'],true,$totp);
        if($res[0] === false && $res["totp"] === true)
          {
            # User has two factor authentication. Prompt!
            $totpclass = $res["error"]===false ? "bg-success":"bg-danger";
            $is_encrypted = empty($res["encrypted_hash"]) || empty($res["encrypted_secret"]);
            $hash =  $is_encrypted ? $_COOKIE[$cookieauth]:$res["encrypted_hash"];
            $secret =  $is_encrypted ? $_COOKIE[$cookiekey]:$res["encrypted_secret"];
            $totp_buffer = "<section id='totp_prompt' class='row'>
  <div class='$totp_class alert alert-danger col-xs-12 col-md-6 center-block' id='totp_message'>".$res["human_error"]."</div>
  <form id='totp_submit' onsubmit='event.preventDefault();' class='form-horizontal clearfix col-xs-12'>
    <fieldset>
      <legend>Two-Factor Authentication</legend>
      <input type='number' id='totp_code' name='totp_code' placeholder='Code' pattern='[0-9]{6}' size='6' maxlength='6'/>
      <input type='hidden' id='username' name='username' value='".$_POST['username']."'/>
      <input type='hidden' id='password' name='password' value='".$res["encrypted_password"]."'  class='password-input'/>
      <input type='hidden' id='secret' name='secret' value='".$secret."'/>
      <input type='hidden' id='hash' name='hash' value='".$hash."'/>
      <input type='hidden' id='remote' name='remote' value='".$_SERVER['REMOTE_ADDR']."'/>
      <input type='hidden' id='encrypted' name='encrypted' value='".$user->strbool($is_encrypted)."'/>
      <br/>
      <br/>
      <button id='verify_totp_button' class='totpbutton btn btn-primary'>Verify</button>
    </fieldset>
    <p><small><a href='#' id='alternate_verification_prompt'>I can't use my app</a></small></p>
  </form>
</section>";
            $login_output .= $totp_buffer;
          }
        else if($res[0] !==false)
          {
            // Successful login
            $userdata=$res[1];
            $id=$userdata['id'];
            $name_block = $userdata['name'];
            $xml->setXml($name_block);
            echo "<!-- Name block: ".$name_block." -->";
            # Be sure we get the name from the actual userdata
            $full_name=$xml->getTagContents("<name>");
            $first_name=$xml->getTagContents("<fname>");
            $display_name=$xml->getTagContents("<dname>");
            # Account for possible differnt modes of saving
            if(empty($first_name)) $first_name = $name_block;
            $login_output.="<h1 id='welcome_back'>Welcome back, ".$first_name."</h1>"; //Welcome message

            $cookie_result=$user->createCookieTokens($userdata);
            if($debug)
              {
                echo "<p>Cookie Result:</p>";
                echo displayDebug($cookie_result);
                echo "<p>Entering cookie handling post call ...</p>";
              }
            if(!$cookie_result['status'])
              {
                  echo "<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button>".$cookie_result['error']."</div>";
                if($debug) echo "<p>Got a cookie error, see above cookie result</p>";
              }
            else
              {
                // Need access -- name (id), email. Give server access?
                $logged_in=true;
                if($redirect_to_home !== true && empty($redirect_url))
                  {
                    $durl = $self_url;
                  }
                else
                  {
                    if($redirect_to_home === true) $durl = $baseurl;
                    else $durl = $redirect_url;
                  }
                if(isset($_COOKIE[$cookieuser]) || $logged_in===true)
                  {
                    $cookiedebug.=" cookie-enter";
                    // Cookies are set
                    $result=$user->lookupItem($_COOKIE[$cookieuser],'username');
                    if($result!==false)
                      {
                        // good user
                        // Check auth
                        $cookiedebug.='good-user check-auth '.print_r($_COOKIE[$cookieuser],true);
                        $userdata=mysqli_fetch_assoc($result);
                        $pw_characters=json_decode($userdata['password'],true);

                        // pieces:
                        $salt=$cookie_result['source'][1];
                        $otsalt=$cookie_result['source'][2];
                        $cookie_secret=$cookie_result['source'][0]; // won't grab new data until refresh, use passed

                        $value_create=array($cookie_secret,$salt,$otsalt,$_SERVER['REMOTE_ADDR'],$site_security_token);
                        $value=sha1(implode('',$value_create));
                        if($value==$cookie_result['raw_auth'])
                          {
                            // Good cookie
                            $cookiedebug.=' good-auth';
                            $logged_in=true;
                            $user_cookie=$_COOKIE[$cookieuser];
                            if($use_javascript_cookies) $deferredJS.="\n".$cookie_result['js'];
                          }
                        else
                          {
                            // bad cookie
                            $cookiedebug.="\n bad-auth ".print_r($cookie_result,true)." for $cookieuser. \nExpecting: $value from ".print_r($value_create,true)."\n Given:\n ".$cookie_result['raw_auth']." from ".print_r($cookie_result['source'],true)." \nRaw cookie:\n".print_r($_COOKIE,true);
                            if(!$debug)
                              {
                                $cookiedebug.="\n\nWiping ...";
                                setcookie($cookieuser,false,time()-3600*24*365);
                                setcookie($cookieperson,false,time()-3600*24*365);
                                setcookie($cookieauth,false,time()-3600*24*365);
                                setcookie($cookiekey,false,time()-3600*24*365);
                                setcookie($cookiepic,false,time()-3600*24*365);
                                $durl.="?m=login_error";
                              }
                            else $cookiedebug.="\nWould wipe here";
                          }
                      }
                    else
                      {
                        // bad user
                        $cookiedebug.=' bad-user';
                        if(!$debug)
                          {
                            $cookiedebug.="\n\nWiping ...";
                            setcookie($cookieuser,false,time()-3600*24*365);
                            setcookie($cookieperson,false,time()-3600*24*365);
                            setcookie($cookieauth,false,time()-3600*24*365);
                            setcookie($cookiekey,false,time()-3600*24*365);
                            setcookie($cookiepic,false,time()-3600*24*365);
                            $durl.="?m=login_error";
                          }
                        else $cookiedebug.="\nWould wipe here";
                      }
                    if(!$user->has2FA() && $require_two_factor === true)
                      {
                        # If require two factor is on, always force it post login
                        if($debug !== true)
                          {
                            header("Refresh: 0; url=".$self_url."?2fa=t");
                            $deferredJS.="\nwindow.location.href=\"".$self_url."?2fa=t\";";
                           }
                        ob_end_flush();
                        $cancel_redirects = true;
                        $login_output .= "<h1>You must set up two-factor authentication to continue.</h1><p>You'll be redirected in less than 10 seconds ...</p>";
                      }
                    else
                      {
                        $login_output.="<p>Logging in from another device or browser will end your session here. You will be redirected in 3 seconds...</p>";
                        $deferredJS .= "\nsetTimeout(function(){window.location.href=\"".$durl."\";},3000);";
                      }
                  }
                else
                  {
                    $logged_in=false;
                    $cookiedebug.='cookies not set for '.$domain;
                  }
                if($debug)
                  {
                    echo "<pre>CookieDebug:\n";
                    echo $cookiedebug;
                    echo "\nCookie Result:\n</pre>";
                    echo displayDebug($cookie_result);
                    echo "<p>Cookie Supervar</p>";
                    echo displayDebug($_COOKIE);
                    echo "<p>Would refresh to:".$durl."</p>";

                  }
                else if($cancel_redirects !== true) header("Refresh: 3; url=".$durl);
              }
            ob_end_flush(); // Flush the buffer, start displaying
          }
        else
          {
            ob_end_flush();
            $login_output.=$login_preamble;
            $login_output.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p><strong>Sorry!</strong> " . $res['message'] . "</p><aside class='ssmall'>Did you mean to <a href='?q=create' class='alert-link'>create a new account instead?</a> Or did you need to <a href='#' class='alert-link do-password-reset'>reset your password?</a></aside></div>";
            $failcount=intval($_POST['failcount'])+1;
            $loginform_whole = $loginform."
              <input type='hidden' name='failcount' id='failcount' value='$fail'/>".$loginform_close;


            if($failcount<10) $login_output.=$loginform_whole;
            else
              {
                $result=lookupItem($_POST['username'],'username',null,null,false,true);
                if($result!==false)
                  {
                    $userdata=mysqli_fetch_assoc($result);
                    $id=$userdata['id'];
                  }
                $query="UPDATE `$default_user_table` SET dtime=".$user->microtime_float()." WHERE id=$id";
                $query2="UPDATE `$default_user_table` SET disabled=true WHERE id=$id";
                $l=openDB();
                $result1=mysqli_query($l,$query);
                if(!$result1) echo "<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>".mysqli_error($l)."</p></div>";
                else
                  {
                    $result2=execAndCloseDB($l,$query2);
                    if(!$result2) echo "<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>".mysqli_error($l)."</p></div>";
                    else
                      {
                          $login_output.="<div class='alert alert-danger'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p><strong>Sorry, you've had ten failed login attempts.</strong> Your account has been disabled for 1 hour.</p></div>";
                      }
                  }

              }
          }
      }
    else
      {
        $login_output.="<h1>Whoops! You forgot something.</h1><h2>Please try again.</h2>";
        $login_output.=$loginform.$loginform_close;
      }
  }
else if($_REQUEST['q']=='create')
  {
    // Create a new user
    // display login form
    // include a captcha and honeypot

    $login_output .= "<link rel='stylesheet' type='text/css' href='".$relative_path."css/otp.min.css'/>";
    if(!empty($recaptcha_public_key) && !empty($recaptcha_private_key))
      {

        $prefill_email = $_POST['username'];
        $prefill_display = $_POST['dname'];
        $prefill_lname = $_POST['lname'];
        $prefill_fname = $_POST['fname'];
        $createform = "<style type='text/css'>.hide { display:none !important; }</style>
<link rel='stylesheet' type='text/css' href='".$relative_path."bower_components/bootstrap/dist/css/bootstrap.min.css'/>
<section class='clearfix'>
              <div id='password_security' class='bs-callout bs-callout-info invisible col-sm-4 hidden-xs pull-right'>

              </div>
	    <form id='login' method='post' action='?q=create&amp;s=next' class='form-horizontal pull-left col-sm-8 creation-form'>
<h1>Welcome to $shorturl</h1>
<fieldset>
<legend>Create a new account</legend>
<div class='form-group'>
	      <label class='col-sm-3 col-md-2' for='username'>
		Email:
	      </label>
	      <input class='col-sm-5 col-md-3' type='email' name='username' id='username' value='$prefill_email' autofocus='autofocus' placeholder='user@domain.com' required='required'/>
	      </div>
<div><div class='form-group'>
	      <label class='col-sm-3 col-md-2 control-label' for='password'>
		Password:
	      </label>
<div class='col-sm-5 col-md-3'>
	      <input class='create form-control password-input' type='password' name='password' id='password' placeholder='Password' required='required' aria-describedby='passText'/>
</div>
	      </div></div>
<span id='helpText' class='help-block invisible'><span class='hidden-xs'>Check the sidebar to the right for the password requirements and your current password's status.</span><span class='visible-xs-inline-block'>We require a password of at least $minimum_password_length characters with at least <strong>one upper case</strong> letter, at least <strong>one lower case</strong> letter, and at least <strong>one digit or special character</strong>.You can also use any long password of at least $password_threshold_length characters, with no security requirements.</span></span>
<div><div class='form-group'>
	      <label class='col-sm-3 col-md-2 control-label' for='password2'>
		Confirm Password:
	      </label>
<div class='col-sm-5 col-md-3'>
	      <input class='create form-control password-input' type='password' name='password2' id='password2'  placeholder='Confirm password' required='required'/>
</div>
	      </div></div>
<div class='form-group'>
              <label class='col-sm-3 col-md-2' for='fname'>
                First Name:
              </label>
	      <input class='col-sm-5 col-md-3' type='text' name='fname' id='fname' value='$prefill_fname' placeholder='Leslie' required='required'/>
	      </div>
<div class='form-group'>
              <label class='col-sm-3 col-md-2' for='lname'>
                Last Name:
              </label>
	      <input class='col-sm-5 col-md-3' type='text' name='lname' id='lname' value='$prefill_lname' placeholder='Smith' required='required'/>
	      </div>
<div class='form-group'>
              <label class='col-sm-3 col-md-2' for='dname'>
                Display Name:
              </label>
	      <input class='col-sm-5 col-md-3' type='text' name='dname' id='dname' placeholder='ThatUser1337' required='required'/>
	      </div>
<div class='form-group'>
              <label class='col-sm-3 col-md-2' for='phone'>
                Phone:
              </label>
	      <input class='col-sm-5 col-md-3' type='tel' name='phone' id='phone' placeholder='555 123-4567'/>
	      </div>
<div class='form-group'>
              <label for='honey' class='hide' >
                Do not fill this field
              </label>
	      <input type='text' name='honey' id='honey' class='hide'/>
</div>
        <p>Please do the<a href='https://en.wikipedia.org/wiki/CAPTCHA' class='newwindow'>CAPTCHA test</a> below to prove you're human:</p>
        <script src='https://www.google.com/recaptcha/api.js'></script>
        <div class=\"g-recaptcha\" data-sitekey=\"".$recaptcha_public_key."\"></div>

              <br class='clearfix'/>
	      <button id='createUser_submit' class='btn btn-success btn-lg col-xs-12 col-lg-3' disabled='disabled'>Create</button>
</fieldset>
	    </form>
</section>
<br class='clear'/>";
        $secnotice="<br/><p><small>Remember your security best practices! Do not use the same password you use for other sites. While your information is <a href='http://en.wikipedia.org/wiki/Cryptographic_hash_function' $newwindow>hashed</a> with a multiple-round hash function, <a href='http://arstechnica.com/security/2013/05/how-crackers-make-minced-meat-out-of-your-passwords/' $newwindow>passwords are easy to crack!</a></small></p>
";
        $createform.=$secnotice; # Password security notice
        if($_SERVER["HTTPS"] != "on" && $displaywarnings === true)
          {
            $createform.="<div class='alert alert-warning text-center'>Warning: This form is insecure.</div>";
          }

        if($_REQUEST['s']=='next')
          {
            $email_preg="/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/";
            if(!empty($_POST['honey']))
              {
                  $login_ouptut.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p><strong>Whoops!</strong> You tripped one of our bot tests. If you are not a bot, please go back and try again. Read your fields carefully!</p></div>";
                $_POST['email']='bob';
              }
            # https://developers.google.com/recaptcha/docs/verify
            $recaptcha_uri = "https://www.google.com/recaptcha/api/siteverify";
            $recaptcha_params = array(
              "secret" => $recaptcha_private_key,
              "response" => $_POST["g-recaptcha-response"],
              "remoteip" => $_SERVER["REMOTE_ADDR"]
            );
try {
    if ($debug)  $login_output .= "<pre>Querying reCAPTCHA: ".displayDebug($recaptcha_params)."\n to $recaptcha_uri</pre>";
    $bareResponse = do_post_request($recaptcha_uri,$recaptcha_params);
    if ($debug) $login_output .= "<pre>Bare output: ".displayDebug($bareResponse)."</pre>";
            $resp = json_decode($bareResponse,true);
            if(empty($bareResponse) || $bareResponse === false) throw new Exception("Bad Response");
            if ($debug) $login_output .= "<pre>Parsed output: ".displayDebug($resp)."</pre>";
} catch(Exception $e)
{
$resp["success"] = false;
$resp["post-error"] = $e->getMessage();
$resp["full_error"] = $e;
$resp["login_caught_error"] = true;
}

if (!$resp["success"]) #  && !$debug
              {
                // What happens when the CAPTCHA was entered
                // incorrectly
$error = empty($resp["error-codes"]) ? $resp["post-error"]:$resp["error-codes"];
if(empty($error)) $error = "Unknown Error";
$login_output.= "<div class='alert alert-danger'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button>The reCAPTCHA wasn't entered correctly. Go back and try it again." . " (reCAPTCHA said: " . $error . ")</div>";
if ($debug) $login_output .= "<pre>".displayDebug($resp)."</pre>";
              }
            else
              {
                // Successful verification
                if(preg_match($email_preg,$_POST['username']))
                  {
                    if($_POST['password']==$_POST['password2'])
                      {
                        if(preg_match('/(?=^.{'.$minimum_password_length.',}$)((?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$/',$_POST['password']) || strlen($_POST['password'])>=$password_threshold_length) // validate email, use in validation to notify user.
                          {
                            $res=$user->createUser($_POST['username'],$_POST['password'],array($_POST['fname'],$_POST['lname']),$_POST['dname'],$_POST['phone']);
                            if($res["status"])
                              {
                                $login_output.="<div class='alert alert-success text-center center-block'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button>
<h3> ".$res["message"]." </h3><p>You can <a class='alert-link' href='".$self_url."'>return to your profile page here</a>.</p></div>"; //jumpto1
                                if($user->needsManualAuth())
                                  {
                                    $login_output.="<div class='alert alert-warning text-center center-block'><p>Your ability to login will be restricted until you've been authorized.</p></div>";
                                  }
                                // email user
                                $to=$_POST['username'];
                                $headers  = 'MIME-Version: 1.0' . "\r\n";
                                $headers .= 'Content-type: text/html; charset=iso-8859-1' . "\r\n";
                                $headers .= "From: [".$shorturl."] Mailer Bot <blackhole@".$shorturl.">";
                                $subject='New Account Creation';
                                $body = "<p>Congratulations! Your new account has been created. Your username is this email address ($to). We do not keep a record of your password we can access, so please be sure to remember it!</p><p>If you do forget your password, you can go to the login page to reset it. All secure data will be lost in the reset.</p>";
                                if(mail($to,$subject,$body,$headers)) $login_output.="<p>A confirmation email has been sent to your inbox at $to .</p>";
                                else
                                  {
                                    // no email
                                  }

                                /***
                                 * Post login behavior ...
                                 ***/
                                $deferredJS.=$res['js'];
                                if($post_create_redirect)
                                  {
                                    if($redirect_to_home !== true && empty($redirect_url))
                                      {
                                        $durl = $self_url;
                                      }
                                    else
                                      {
                                        if($redirect_to_home === true) $durl = $baseurl;
                                        else $durl = $redirect_url;
                                      }
                                    $deferredJS.="\nwindow.location.href=\"$durl\";";
                                    header("Refresh: 3; url=".$durl);
                                  }
                                else
                                {
                                  # Let's show a nice message
                                  $html = "<p >You may <a href='$baseurl/$redirect_url'>want to visit your administration page</a>, but otherwise we suggest <a href='$baseurl'>going home</a> and navigating from there.</p>";

                                }
                                if($ask_verify_phone_at_signup)
                                  {
                                    # Verify the phone number
                                    $phone_verify_template = "<form id='verify_phone' onsubmit='event.preventDefault();'>
  <input type='tel' id='phone' name='phone' value='".$user->getPhone()."' readonly='readonly'/>
  <input type='hidden' id='username' name='username' value='".$user->getUsername()."'/>
  <button id='verify_phone_button' class='btn btn-primary'>Verify Phone Now</button>
  <p>
    <small>
      <a href='#' id='verify_later'>
        Verify Later
      </a>
    </small>
  </p>
</form>";
                                    $login_output .= "<h2>Verifying your Phone</h2>".$phone_verify_template;
                                  }
                                # Give the option to add two-factor now; force it if flag enabled
                                if($ask_twofactor_at_signup)
                                  {
                                    # Give user 2FA
                                      $totp_add_form = "<section id='totp_add' class='row'>
  <div id='totp_message' class='col-xs-12 col-md-6 alert alert-warning center-block'>
    Two factor authentication is required when setting up an account with $shorturl. If you don't know what this is, click \"Help with two-factor authentication\" below.
  </div>
  <form id='totp_start' onsubmit='event.preventDefault();' class='col-xs-12 clearfix'>
    <fieldset>
      <legend>Login to continue</legend>
      <div class='form-group'>
        <label for='username' class='sr-only'>Username:</label>
        <input type='email' value='".$user->getUsername()."' readonly='readonly' id='username' name='username' class='form-control'/>
      </div>
      <div class='form-group'>
        <label for='password' class='sr-only'>Password:</label>
        <input type='password' id='password' name='password' placeholder='Verify Password'/>
      </div>
      <input type='hidden' id='secret' name='secret' value='".$_COOKIE[$cookiekey]."'/>
      <input type='hidden' id='hash' name='hash' value='".$_COOKIE[$cookieauth]."'/>
      <br/>
      <button id='add_totp_button' class='totpbutton btn btn-primary'>Add Two-Factor Authentication</button>
    </fieldset>
  </form>
  <div class='alert alert-info col-xs-12 col-md-6'>
    <button id='totp_help' class='alert-link btn btn-link'>Help with Two-Factor Authentication</button>
  </div>
</section>";
                                    $login_output .= "<h2 class='row'>Adding two-factor authentication</h2>".$totp_add_form;
                                  }

                              }
                            else
                              {
                                if($debug) $login_output.=displayDebug($res);
                                $feedback = empty($res["human_error"]) ? $res["error"] : $res["human_error"];
                                $login_output.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>".$feedback."</p><p>Use your browser's back button to try again.</p></div>";
                                $deferredJS = "console.warn('Got response',".json_encode($res).")";
                              }
                            ob_end_flush();
                          }
                        else
                          {
                              $login_output.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>Your password was not long enough ($minimum_password_length characters) or did not match minimum complexity levels (one upper case letter, one lower case letter, one digit or special character). You can also use <a href='http://imgs.xkcd.com/comics/password_strength.png' id='any_long_pass' class='lightboximage'>any long password</a> of at least $password_threshold_length characters. Please go back and try again.</p></div>";
                          }
                      }
                    else $login_output.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>Your passwords did not match. Please go back and try again.</p></div>";
                  }
                else $login_output.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p><strong>Error</strong>: Your email address was invalid. Please enter a valid email.</p></div>";
              }
          }
        else $login_output.=$createform;
      }
    else $login_output.="<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>This site's ReCAPTCHA library hasn't been set up. Please contact the site administrator.</p></div>";
  }
else if($_REQUEST['q'] == "verify")
  {
    $login_output .= $phone_verify_form;
  }
else if(isset($_REQUEST['confirm']))
  {
    $token = $_REQUEST['token'];
    $userToActivate = $_REQUEST['user'];
    $encoded_key = $_REQUEST['key'];
    $result = $user->verifyUserAuth($encoded_key,$token,$userToActivate);
    if($result['status'] === false)
      {
          $login_output .= "<div class='alert alert-warning'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><h1>Could not verify user</h1><p>".$result['message']."</p></div>";
      }
    else
      {
          if ($result["admin_confirm_sent"] && $result["user_confirm_sent"])
          {
            $messageFollowUp = "Check your inbox for a confirmation.";
          }
          else
          {
            $messageFollowUp = "<strong>However, not all confirmations could not be sent</strong> (".$result["error"].").";
          }
          $login_output .= "<div class='alert alert-info'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button><p>The user was successfully activated. $messageFollowUp</p></div>";
      }
    if($debug)
      {
        echo displayDebug($result);
      }
  }
else if(isset($_REQUEST['2fa']))
  {
      if($logged_in && !$user->has2FA())
      {
          # Give user 2FA
          $totp_add_form = "<section id='totp_add' class='row'>
  <div id='totp_message' class='alert alert-info col-xs-12 col-md-6 center-block'>Two factor authentication is very secure, but when you enable it, you'll be unable to log in without your mobile device.</div>
  <form id='totp_start' onsubmit='event.preventDefault();' class='col-xs-12 clearfix'>
    <fieldset>
      <legend>Login to continue</legend>
      <div class='form-group'>
        <label for='username' class='sr-only'>Username:</label>
        <input type='email' value='".$user->getUsername()."' readonly='readonly' id='username' name='username' class='form-control'/>
      </div>
      <div class='form-group'>
        <label for='password' class='sr-only'>Password:</label>
        <input type='password' id='password' name='password' placeholder='Verify Password'/>
      </div>
      <input type='hidden' id='secret' name='secret' value='".$_COOKIE[$cookiekey]."'/>
      <input type='hidden' id='hash' name='hash' value='".$_COOKIE[$cookieauth]."'/>
      <br/>
      <button id='add_totp_button' class='totpbutton btn btn-primary'>Add Two-Factor Authentication</button>
    </fieldset>
  </form>
  <div class='alert alert-info col-xs-12 col-md-6'>
    <button id='totp_help' class='alert-link btn btn-link'>Help with Two-Factor Authentication</button>
  </div>
</section>";
          if($require_two_factor) $totp_add_form = "<h1>This site requires two-factor authentication</h1><h2>Please set up two-factor authentication to continue.</h2>".$totp_add_form;
          $login_output .= $totp_add_form;
      }
      else if ($logged_in && $user->has2FA())
      {
          # Remove 2FA from the user
          $totp_remove_form = "<section id='totp_remove_section' class='row'>
    <div id='totp_message' class='alert alert-warning col-xs-12 col-md-6 center-block'>Are you sure you want to disable two-factor authentication?</div>
  <form id='totp_remove' onsubmit='event.preventDefault();' class='form-horizontal col-xs-12 clearfix'>
    <fieldset>
      <legend>Remove Two-Factor Authentication</legend>
      <input type='email' value='".$user->getUsername()."' readonly='readonly' id='username' name='username'/><br/>
      <input type='password' id='password' name='password' placeholder='Password'/><br/>
      <input type='text' id='code' name='code' placeholder='Authenticator Code or Backup Code' size='32' maxlength='32' autocomplete='off'/><br/>
      <button id='remove_totp_button' class='totpbutton btn btn-danger'>Remove Two-Factor Authentication</button>
    </fieldset>
  </form>
</section>";
          $login_output .= $totp_remove_form;
      }
      else if (!$logged_in)
      {
          $login_output .= "<div class='alert alert-warning'><p>You have to be logged in to set up two factor authentication.<br/><a href='?q=login'>Click here to log in</a></p></div>";
      }
      else
      {
          # Should never trigger
          throw(new Exception("Unexpected condition setting up two-factor authentication"));
      }
      if($logged_in)
      {
          $login_output .= $settings_blob;
      }
  }
else if(strtolower($_REQUEST["action"]) == "finishpasswordreset")
{
    # Pass it off to the JS handler
    $resetString = " window.checkPasswordReset = true; window.resetParams = new Object(); resetParams.key = '".$_REQUEST["key"]."'; resetParams.verify = '".$_REQUEST["verify"]."'; resetParams.user = '".$_REQUEST["user"]."';";
}
else
{
    $resetString = "window.checkPasswordReset = false";
    if($redirect_to_home !== true && empty($redirect_url))
    {
        $durl = $self_url;
    }
    else
    {
        if($redirect_to_home === true) $durl = $baseurl;
        else $durl = $redirect_url;
    }

    if(!$logged_in) $login_output.=$login_preamble . $loginform.$loginform_close;
    else $login_output.="<aside class='ssmall pull-right'><a href='?q=logout' class='btn btn-warning btn-sm'><span class='glyphicon glyphicon-log-out' aria-hidden='true'></span> Logout</a></aside><h1 id='signin_greeting'>Welcome back, $first_name</h1><br/><p id='logout_para'></p>".$settings_blob."<button id='next' name='next' class='btn btn-primary continue click' data-href='$durl'>Continue &#187;</button>";
    $deferredJS .= "\n$(\"#next\").click(function(){window.location.href=\"".$durl."\";});";
        }
    $login_output.="</div>";
    ob_end_flush();

    $totpOverride = !empty($redirect_url) ? "window.totpParams.home = \"".$redirect_url."\";\n":null;
    $totpOverride .= !empty($relative_path) ? "window.totpParams.relative = \"".$relative_path."\";\n":null;
    $totpOverride .= !empty($working_subdirectory) ? "window.totpParams.subdirectory = \"".$working_subdirectory."\";\n":null;
    $totpOverride .= "window.totpParams.domain = \"".$domain."\";\n";
    try
    {
        $need_tfa = !$user->has2FA();
    }
    catch (Exception $e)
    {
        $need_tfa = false;
    }
    $totpOverride .= $need_tfa && $require_two_factor ? "window.totpParams.tfaLock = true;\n":"window.totpParams.tfaLock = false;\n";

    $deferredScriptBlock = "<script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js'></script>
<script type='text/javascript' src='".$relative_path."js/loadJQuery.min.js'></script>
<script type='text/javascript'>
        if(typeof passwords != 'object') passwords = new Object();
        passwords.overrideLength=$password_threshold_length;
        passwords.minLength=$minimum_password_length;
        if(typeof totpParams != 'object') totpParams = new Object();
        $totpOverride
        $resetString

var loadLast = function () {
    try {
        loadJS('".$relative_path."js/c.min.js',function() {
            try {
              $deferredJS
            } catch(e) {
              console.error(\"Couldn't load deferred calls\");
            }
          }, function(){
            $('#totp_message').addClass('alert alert-danger').text('There was a problem loading this page. Please refresh and try again.');
            console.error(\"The page couldn't load the primary scripts! This page may not function.\");
        });

    }
    catch (e)
    {
        console.error(\"Couldn't load login scripts!\");
    }
}
</script>";


$login_output .= $deferredScriptBlock;
?>
