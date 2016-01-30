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
# Enable the next line for Braintree billing
# require_once("./braintree_billing.php");
require_once 'userhandler/async_login_handler.php';
require_once 'userhandler/app_handlers.php';

/*******************
 * The functions that actually do stuff
 * Called by the "action" key through verifyApp
 *******************/

function syncUserData($data_array)
{
    return $data_array['user_data'];
}

function authenticateWebRequest()
{
    /*
   * Check the authentication credentials using the stored server secrets for
   * hashes.
   */
  return false;
}
