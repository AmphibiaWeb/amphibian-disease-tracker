<?php

/***
 * Update the variables in here and re-save as CONFIG.php for use.
 ***/

# pulls the user back to the main page if not logged in
$captive_login=false;
$debug=false;
$use_javascript_cookies=false;
$redirect_to_home = true;
$displaywarnings = true;
$allow_insecure_connections = false;

$require_two_factor = false;

$ask_twofactor_at_signup = false;
$ask_verify_phone_at_signup = false;
# Redirect the user after the account has been created
$post_create_redirect = false;


$baseurl = ""; # define if other than the hosted URL
$redirect_url = ""; # define if other than the hosted URL
$login_url = ""; # define if other than the hosted URL
# Usually only have to change this on strange configurations
$self_referential = $_SERVER['PHP_SELF'];

# Path to this library from callers, relative to the top level.
# Used mostly for AJAX calls.
$working_subdirectory = "/";
# Relative path from the pages it's embedded in. Often the same as above.
$relative_path = "/";

$site_name = "";

$default_user_table='userdata';
$default_user_database="";
$default_sql_user="";
$default_sql_password=""; # https://www.random.org/passwords/?num=1&len=24&format=plain&rnd=new
$sql_url = 'localhost';

/***
 * Required, but free to generate. Generate here:
 * https://www.google.com/recaptcha/admin/create
 ***/
$recaptcha_public_key="";
$recaptcha_private_key="";


/***
 * Very important! I suggest taking all three results and concatenating them:
 * https://www.random.org/passwords/?num=3&len=24&format=plain&rnd=new
 ***/
$site_security_token="";

/***
 * If not set, minimum password length defaults to 8, with a threshold of 20.
 ***/
$service_email='';
$minimum_password_length='';
$password_threshold_length='';

/***
 * Path to user data storage
 ***/
$user_data_storage='';
$profile_picture_storage = $user_data_storage.'';


/***
 * Does the user need to be manually authenticated?
 ***/

$needs_manual_authentication = false;
$is_smtp = false;
$is_pop3 = false;
$mail_host = "";
$mail_user = "";
$mail_password = "";


$notify_su_on_signup = false;

/***
 * If you edit this, change the mapping in login_functions.php
 ***/
$db_cols=array(
  "username"=>"text",
  "password"=>"text",
  "pass_meta"=>"text",
  "creation"=>"float(16)",
  "status_tracker"=>"text",
  "name"=>"text",
  "flag"=>"boolean",
  "admin_flag"=>"boolean",
  "su_flag"=>"boolean",
  "disabled"=>"boolean",
  "dtime"=>"int(8)",
  "last_ip"=>"varchar(32)",
  "last_login"=>"float(16)",
  "auth_key"=>"varchar(512)",
  "data"=>"text",
  "secdata"=>"text",
  "special_1"=>"text",
  "special_2"=>"text",
  "dblink"=>"varchar(255)",
  "defaults"=>"text",
  "public_key"=>"text",
  "private_key"=>"text",
  "app_key"=>"text",
  "secret"=>"varchar(255)",
  "emergency_code"=>"varchar(255)",
  "phone"=>"varchar(20)",
  "phone_verified"=>"bool",
  "random_seed"=>"varchar(255)",
  "server_encrypted"=>"varchar(255)",
);

/***
 * Specify column mappings
 ***/

$user_column = "username";
$link_column = "dblink";
$password_column = "password";
$cookie_ver_column = "auth_key";

$totp_column = "secret";
$totp_rescue = "emergency_code";

$app_column = "app_key";

# See https://github.com/tigerhawkvok/php-userhandler/blob/master/totp/doc/Use.md#digest-algorithm
# Leave as sha1 for compatibility with Google Authenticator
$totp_digest = "sha1";

$temporary_storage = "special_1";
$ip_record = "last_ip";


/***
 * Specify TOTP 30-second "steps" allowed to be off by
 ***/

$totp_steps = 1;

/***
 * SMS Configuration -- Twilio
 * Get your API key here: www.twilio.com/user/account
 * Strict SMS checks will throw exceptions if not set up.
 *
 ***/

$twilio_sid = "";
$twilio_token = "";
$twilio_number = "";

?>