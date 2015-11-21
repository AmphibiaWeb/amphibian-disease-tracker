<?php
/***
 * Secrets and client IDs for services
 *
 * IMPORTANT: Fill out this file and save it as `secrets.php`.
 ***/

// The most important! Without this value, anyone could replicate your
// user's "password" with information from the right service. This
// ensures that the returned value is unique to you. It is strongly
// suggested you use the output of the following:
// https://www.random.org/passwords/?num=1&len=24&format=plain&rnd=new
$your_secret="";

/***
 * Client secrets. These are used to authenticate with the
 * application. Leaving these blank will cause that login method to
 * not be displayed as an option.
 ***/

# Google
$google_config_file_path = "credentials.json";
# Compute the Google params
$google_array = json_decode(file_get_contents($google_config_file_path), true);
$google_clientid = $google_array["web"]["client_id"];
$google_secret = $google_array["web"]["client_secret"];

# Twitter
$twitter_clientid='';
$twitter_secret='';


# Facebook
$facebook_appid="";
$facebook_secret="";
$facebook_clienttoken="";


### Site configurations ###
$provide_full_login=true; 

$sitename="Foo Bar";
$baseurl="https://foobar.com/";


$default='google';
$handler_destination="oauth_login_handler.php";


/***
 * This is where this library hooks up to your existing site
 ***/

# The data can be POSTed as a JSON object to a URL, 
# in which case that should be specified here.
$post_data_to_url=false;
# the data can also be sent as a GET request.
$send_data_as_get_to_url=false;
# Otherwise, this can handle the legwork to swap between 
# functions by supplying the following:
$include_urls=array();
$authenticator_function="";
$auth_uses_array=false;
$auth_variable_order=array();
$new_user_function="";
$new_users_use_array=false;
$new_users_variable_order=array();




/***
 * A little internal logic. Don't change these!
 ***/

if (preg_match('%(?<=//)(.*)(?<!/)%', $baseurl, $matches)) {
	$domain = $matches[0];
} else {
	$domain = $baseurl; //fallback
}

$provider= empty($_REQUEST['provider']) ? $default:$_REQUEST['provider'];
$returnurl=$baseurl."oauth/oauth.php";
switch($provider)
{
case 'google':
    $returnurl.='?provider='.$provider;
    break;
default:
    $returnurl.="?provider=".$provider."&callback=true";
}
?>