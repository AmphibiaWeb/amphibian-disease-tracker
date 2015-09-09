<?php

require_once("./braintree/lib/Braintree.php");
require_once("./userhandler/core/core.php");

## Uncomment the following lines to move to produciton
# Braintree_Configuration::environment('production'); 
# Braintree_Configuration::merchantId("MERCHANT_ID");
# Braintree_Configuration::publicKey("MERCHANT_PUBLIC_KEY");
# require_once("./braintree_key_config.php");
# Braintree_Configuration::privateKey($braintree_private_key);


# Sample sandbox server. Change to suit your own configuration.
Braintree_Configuration::environment('sandbox');
Braintree_Configuration::merchantId('zrvcsvtqmsmmrbc8');
Braintree_Configuration::publicKey('mbbcq4cdn7nzfbzz');
Braintree_Configuration::privateKey('c49787639f66d66fc361e07d648c4056');

$billingTokens = array();

try 
{
  $clientToken = Braintree_ClientToken::generate(
    array("customerId" => substr($_REQUEST["device"],0,36))
      );
}
catch (InvalidArgumentException $e) 
{
  // This client doesn't exist yet
  $clientToken = Braintree_ClientToken::generate();
}

$billingTokens["token"] = $clientToken;

function billUser($full_data_array) 
{
  /***
   * Do a charge against the user, then update the status all around.
   *
   * https://developers.braintreepayments.com/android+php/reference/request/transaction/sale
   ***/
  $data_array = $full_data_array["post_data"];
  $brainTreeTransaction = array (
    "amount" => $data_array["amount"],
      "paymentMethodNonce" => $data_array["nonce"],
      'customer' => array(
        //'id' => substr($data_array["customerId"],0,36)
             ),
      'options' => array(
        'storeInVaultOnSuccess' => true,
          'submitForSettlement' => true
          ),
      
    );
  global $billingTokens;
  $billingTokens = array();
  try 
  {
    $braintree = Braintree_Transaction::sale($brainTreeTransaction);
    $result = array("status"=>$braintree->success,"braintree_result"=>$braintree);
    if(!$braintree->success) {
      $result["app_error_code"] = 115;
      $result["details"] = array();
      $result["requested_action"] = "bill";
      $result["human_error"] = "Failed to charge your card. Please try again later.";
      $result["given"] = $data_array;
    }
    else
    {
      try
      {
        # Post-process
        $billingTokens["status"] = true;
        $postProcessDetails = array();
        $givenArgs = smart_decode64($data_array["billActionDetail"]);
        $billingTokens["provided"] = $givenArgs;
        $postAction = $givenArgs["action"];
        switch($postAction) 
        {
          # Set all the $postProcessDetails data
        case "session":
          break;
        case "roleChange":
          $newRole = $givenArgs["newRole"];
          # Do the role change
          break;
        default:
          throw(new Exception("Bad post-process action '$postAction'"));
          break;
        }
        $billingTokens["post_process_details"] = $postProcessDetails;
      }
      catch(Exception $e) {
        # An internal error! We want to log this.
        $error_id = Stronghash::createSalt();
        $write = "\n\n\n\n".datestamp()." - ".json_encode($_REQUEST);
        $write .= "\nError ID: $error_id";
        $write .= "\nGot error: ".$e->getMessage();
        $write .= "\n".implode("\n",jTraceEx($e));
        file_put_contents('billing_errors.log', $write, FILE_APPEND | LOCK_EX);
        $billingTokens["status"] = false;
        $billingTokens["error"] = $e->getMessage();
        $billingTokens["human_error"] = "Your card was charged, but we couldn't update the server. Please contact support with error ID $error_id";
        $billingTokens["need_popup"] = true;
        $result["status"] = false;
        $result["app_error_code"] = 116;
      }
    }
  }
  catch (Exception $e) 
  {
    # Just the Braintree errors
    $result = array("status"=>false,"error"=>$e->getMessage(),"human_error"=>"Unable to charge your card","app_error_code"=>114,"given"=>$data_array);
  }

  return $result;
}




/**
 * jTraceEx() - provide a Java style exception trace
 * @param $exception
 * @param $seen      - array passed to recursive calls to accumulate trace lines already seen
 *                     leave as NULL when calling this function
 * @return array of strings, one entry per trace line
 */
function jTraceEx($e, $seen=null) {
  $starter = $seen ? 'Caused by: ' : '';
  $result = array();
  if (!$seen) $seen = array();
  $trace  = $e->getTrace();
  $prev   = $e->getPrevious();
  $result[] = sprintf('%s%s: %s', $starter, get_class($e), $e->getMessage());
  $file = $e->getFile();
  $line = $e->getLine();
  while (true) {
    $current = "$file:$line";
    if (is_array($seen) && in_array($current, $seen)) {
      $result[] = sprintf(' ... %d more', count($trace)+1);
      break;
    }
    $result[] = sprintf(' at %s%s%s(%s%s%s)',
                        count($trace) && array_key_exists('class', $trace[0]) ? str_replace('\\', '.', $trace[0]['class']) : '',
                        count($trace) && array_key_exists('class', $trace[0]) && array_key_exists('function', $trace[0]) ? '.' : '',
                        count($trace) && array_key_exists('function', $trace[0]) ? str_replace('\\', '.', $trace[0]['function']) : '(main)',
                        $line === null ? $file : basename($file),
                        $line === null ? '' : ':',
                        $line === null ? '' : $line);
    if (is_array($seen))
      $seen[] = "$file:$line";
    if (!count($trace))
      break;
    $file = array_key_exists('file', $trace[0]) ? $trace[0]['file'] : 'Unknown Source';
    $line = array_key_exists('file', $trace[0]) && array_key_exists('line', $trace[0]) && $trace[0]['line'] ? $trace[0]['line'] : null;
    array_shift($trace);
  }
  $result = join("\n", $result);
  if ($prev)
    $result  .= "\n" . jTraceEx($prev, $seen);

  return $result;
}

?>