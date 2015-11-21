<?php
$buffer="
<!doctype html>
<html>
  <head>
    <title>Multi-Login Demo</title>
    <link rel='stylesheet' type='text/css' href='css/main.css' media='screen'/>
    <script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js'></script>
    <script type='text/javascript' src='js/handlers.js'></script>
  </head>
  <body>
    <article>";
// Set this up so all the data is parsed and packaged to be returned as a nice neat set, and forward the data to the handler variable.
require_once('vars.php');
require_once('helpers.php');
$signin_type=$_REQUEST['login_type'];
$provider= empty($_REQUEST['provider']) ? $default:$_REQUEST['provider'];
$domain=$baseurl;
// The return URL is based on a secret and the nearest mod-60-sec microtime. 
// Verification is checked against the previous and next mod 60
$returnurl=appendQuery(($provider!='openid' ? "callback=true":null));



function setAuthParams()
{
  // save the auth data
  // A user is going to authenticate to the server when they need to do a lookup. Encrypted data is encrypted by their salted openid?
}

// display provider switch to the left
$buffer.= "<section id='provider_list'>
  <ul>
    <li><a href='?provider=openid'>".dispSVG('res/openid.svg','OpenID','128',null,'openid_logo','logo_list',true)."</a></li>
    <li><a href='?provider=google'>".dispSVG('res/gplus.svg','Google+','128',null,'google_logo','logo_list',true)."</a></li>
    <li><a href='?provider=twitter'>".dispSVG('res/twitter-bird.svg','Twitter','128',null,'twitter_logo','logo_list',true)."</a></li>
    <li><a href='?provider=facebook'>".dispSVG('res/FB-fLogo.svg','Facebook','128',null,'facebook_logo','logo_list',true)."</a></li>
  </ul>
</section>
<section id='auth_panel'>";
switch($provider)
  {
  case 'google':
    try
      {
	// try g+ then oauth, THEN openid
	$buffer.="<script type='text/javascript'>$('#google_logo').css('opacity','1');</script>";
	try
	  {
	    // g+ login
	    // can't debug this on rothstein without a higher php version
	    // see index.html and the g+ app in ref
	    throw new Exception('ForceException');
	    $buffer.= "  
<script type='text/javascript'>
  (function() {
    var po = document.createElement('script');
    po.type = 'text/javascript'; po.async = true;
    po.src = 'https://plus.google.com/js/client:plusone.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(po, s);
  })();
  </script>
  <div id='gConnect'>
    <button class='g-signin'
        data-scope='https://www.googleapis.com/auth/plus.login'
        data-requestvisibleactions='http://schemas.google.com/AddActivity'
        data-clientId='{{ CLIENT_ID }}'
        data-accesstype='offline'
        data-callback='onSignInCallback'
        data-theme='dark'
        data-cookiepolicy='single_host_origin'>
    </button>
  </div>";
	  }
	catch(Exception $e)
	  {
	     // oauth2
	    require_once 'modular/google-php-client/Google_Client.php';
	    require_once 'modular/google-php-client/contrib/Google_Oauth2Service.php';
	    session_start();
	    $client = new Google_Client();
	    $client->setApplicationName($site_title." Login");
	    $client->setClientId($google_clientid);
	    $client->setClientSecret($google_secret);
	    $client->setRedirectUri($returnurl);
	    $oauth2 = new Google_Oauth2Service($client);
	    
	    if (isset($_GET['code'])) 
	      {
		$client->authenticate($_GET['code']);
		$_SESSION['token'] = $client->getAccessToken();
		$redirect = 'http://' . $_SERVER['HTTP_HOST'] . $_SERVER['PHP_SELF'];
		header('Location: ' . filter_var($redirect, FILTER_SANITIZE_URL));
		return;
	      }
	    
	    if (isset($_SESSION['token'])) {
	      $client->setAccessToken($_SESSION['token']);
	      // save this to a db
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
	      // The access token may have been updated lazily.
	      $_SESSION['token'] = $client->getAccessToken();
	    } else {
	      $authUrl = $client->createAuthUrl();
	    }
	    if(isset($user))   $buffer.= "<pre>".print_r($user,true)."</pre>";
	    if(isset($authUrl)) {
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
	      $buffer.=dispSVG('res/google_signin_button.svg','Sign in with Google',320,108,'signin_button',null,true)."</a>";
	    } else {
	      $buffer.= "<a class='logout' href='?logout'>Logout</a>";
	    }
	  }
      }
    catch(Exception $e)
      {
	require_once 'modular/openid.php';
	// do google openid login
      }
    break;
  case 'openid':
    require_once 'modular/openid.php';
    $buffer.="<script type='text/javascript'>$('#openid_logo').css('opacity','1');</script>";
    try 
      {
	$openid = new LightOpenID($domain);
	if(!$openid->mode) 
	  {
	    if(isset($_POST['openid_url'])) 
	      {
		$openid->identity = $_POST['openid_url'];
		if($signin_type=='login')
		  {
		    $openid->required = array('username'=>'contact/email');
		  }
		else if($signin_type=='new')
		  {
		    $openid->required = array('username'=>'contact/email','name'=>'namePerson', 'dname'=>'namePerson/friendly','zip'=>'contact/postalCode/home');
		  }
		else
		  {
		    $openid->required = array('username'=>'contact/email');
		    $openid->optional = array('name'=>'namePerson', 'dname'=>'namePerson/friendly','zip'=>'contact/postalCode/home');
		  }
		$openid->returnURL=$returnurl;
		header('Location: ' . $openid->authUrl());
	      }
	    $buffer.= "
<form action='' method='post'>
    <label for='openid_url'>OpenID: </label><input type='text' name='openid_url' required='required' /> <button>Submit</button>
</form>";
	    
	  } 
	else if($openid->mode == 'cancel') 
	  {
	    $buffer.= 'User has canceled authentication!';
	    // handle the rejection
	  } 
	else 
	  {
	    $ok=boolstr($openid->validate());
	    if($ok)
	      {
	        $data=$openid->getAttributes();
	        if($signin_type!='new')
	          {
	            // Do a user lookup for login
		    // identity provider --> password
		    // the [contact/email] field is their user id.
	            // If it fails, offer to create a new user
	            // if so, change $signin_type so it triggers the subsequent code block ...
	          }
	        if($signin_type=='new')
	          {
	            // Create a user
	            require('modular/login_functions.php');
	            $res=createUser($data['contact/email'],$provider,$data['namePerson'],$data['namePerson/friendly'],$data['contact/postalCode/home']);
	            // handle the user creation 
	            // Direct to profile editor
	          }

	      }
	    else
	      {
		// it didn't validate
	      }
	    $buffer.= "<pre>";
	    $buffer.= 'User ' . ($ok ? $openid->identity . ' has ' : 'has not ') . "logged in.\n";
	    $buffer.= "We have the following identity: ".$openid->identity."\n";
	    $buffer.= strbool($ok)."\n";
	    print_r($openid->getAttributes());
	    $assoc_url=explode("?",$openid->authUrl());
	    $assoc_url=$assoc_url[0]."?openid.mode=associate&openid.assoc_type=HMAC-SHA1&openid.session_type=";
	    $response=file_get_contents($assoc_url);
	    $lines=explode("\n",$response);
	    foreach($lines as $line) 
	      {
		$el=explode(":",$line);
		$associate_array[$el[0]]=$el[1];
	      }
	  }
      } 
    catch(ErrorException $e) 
      {
	$buffer.= $e->getMessage();
      }
    break;
  case 'twitter':
    // https://dev.twitter.com/docs/auth/implementing-sign-twitter
    $buffer.="<script type='text/javascript'>$('#twitter_logo').css('opacity','1');</script>";
    break;
  case 'facebook':
    // https://developers.facebook.com/docs/facebook-login/getting-started-web/
    $buffer.="<script type='text/javascript'>$('#facebook_logo').css('opacity','1');</script>";
    break;
  default:
    // return an error
  }
$buffer.= "</section><br class='clear'/>";
echo $buffer;
?>
    </article>
  </body>
  <script type='text/javascript'>
    try{$(document).ready(bindMouse());}
    catch(e){}
  </script>
</html>