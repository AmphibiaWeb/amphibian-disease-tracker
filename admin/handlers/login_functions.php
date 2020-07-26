<?php

use Base32\Base32;

require_once dirname(__FILE__).'/../core/core.php';

class UserFunctions extends DBHelper
{
    public function __construct($username = null, $lookup_column = null, $db_params = null)
    {
        /***
         * @param string $username the user to be instanced with
         * @param string $lookup_column the column to look them up in.
         *                              Ignored if $username is null, defaults to $user_column
         * @param array $db_params Optional override database parameters.
         *                         The required keys are:
         *                         (string)"user" for SQL username,
         *                         (string)"database" as the SQL database,
         *                         and (string)"password" for SQL password,
         *                         with optional keys
         *                         (string)"url" (defaults to "localhost")
         *                         and (array)"cols" of type "column_name"=>"type".
         ***/
        global $user_data_storage,$profile_picture_storage,$site_security_token,$service_email,$minimum_password_length,$password_threshold_length,$db_cols,$default_user_table,$default_user_database,$password_column,$cookie_ver_column,$user_column,$totp_column,$totp_steps,$temporary_storage,$needs_manual_authentication,$totp_rescue,$ip_record,$default_user_database,$default_sql_user,$default_sql_password,$sql_url,$default_user_table,$baseurl,$twilio_sid,$twilio_token,$twilio_number,$site_name,$link_column,$app_column, $allowedEmailDomains, $allowedEmailTLDs, $notify_su_on_signup;
        # Set up the parameters in CONFIG.php
        $config_path = dirname(__FILE__).'/../CONFIG.php';
        require_once $config_path;
        if (!empty($db_params)) {
            if (!is_array($db_params)) {
                throw(new Exception("Invalid argument type for \$db_params"));
            }
            if (sizeof($db_params) != 4 || sizeof($db_params) != 3) {
                throw(new Exception('Bad database initialization parameters.'));
            }
            $must_have = array('user','database','password');
            if (array_key_exists('url', $db_params)) {
                $sql_url = $db_params['url'];
            }
            if (array_key_exists('cols', $db_params)) {
                $db_cols = $db_params['cols'];
            }
            foreach ($must_have as $key) {
                if (!array_key_exists($key, $db_params)) {
                    throw(new Exception('Bad database initialization parameters.'));
                }
                switch ($key) {
              case 'user':
                $default_sql_user = $db_params[$key];
                break;
              case 'database':
                $default_user_database = $db_params[$key];
                break;
              case 'password':
                $default_sql_password = $db_params[$key];
                break;
              default:
                throw(new Exception("Unknown key '$key' in database initialization parameters."));
              }
            }
        }

        try {
            # Configure the database
            $this->setSQLUser($default_sql_user);
            $this->setDB($default_user_database);
            $this->setSQLPW($default_sql_password);
            $this->setSQLURL($sql_url);
            $this->setCols($db_cols);
            $this->setTable($default_user_table);
        } catch (Exception $e) {
            # More complete message
            $message = 'Could not initialize database setup ['.$e->getMessage().'] in <'.$e->getTraceAsString().'> (using '.$config_path.')';
            throw(new Exception($message));
        }

        # Check it
        $details = $this->testSettings(null, true);
        if (!$details['status'] && $details != true) {
            # There's a database problem
            throw(new Exception('Database configuration problem - '.json_encode($details)));
        }

        if (!empty($user_data_storage)) {
            $user_data_storage .= substr($user_data_storage, -1) == '/' ? '' : '/';
            $this->data_path = $user_data_storage;
        } else {
            $this->data_path = 'userdata/';
        }

        if (!empty($profile_picture_storage)) {
            $profile_picture_storage .= substr($profile_picture_storage, -1) == '/' ? '' : '/';
            $this->picture_path = $profile_picture_storage;
        } else {
            $this->picture_path = $this->data_path.'profilepics/';
        }

        $this->siteKey = $site_security_token;
        $this->supportEmail = $service_email;
        $this->minPasswordLength = $minimum_password_length;
        $this->thresholdLength = $password_threshold_length;
        $this->pwColumn = $password_column;
        $this->pwcol = $password_column;
        $this->cookieColumn = $cookie_ver_column;
        $this->userColumn = $user_column;
        $this->usercol = $user_column;
        $this->linkColumn = $link_column;
        $this->tmpColumn = $temporary_storage;
        $this->totpColumn = $totp_column;
        $this->totpBackup = $totp_rescue;
        $this->totpSteps = $totp_steps;
        $this->needsAuth = $needs_manual_authentication;
        $this->ipColumn = $ip_record;
        $this->twilio_sid = $twilio_sid;
        $this->twilio_token = $twilio_token;
        $this->twilio_number = $twilio_number;
        $this->site = $site_name;
        $this->appKeyColumn = $app_column;
        $this->userlink = null;
        $this->allowedTLDs = $allowedEmailTLDs;
        $this->allowedDomains = $allowedEmailDomains;
        $this->suNotify = $notify_su_on_signup;

        $proto = 'http';
        if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on') {
            $proto .= 's';
        }

        if (empty($baseurl)) {
            $baseurl = $proto.'://';
            $baseurl .= $_SERVER['HTTP_HOST'];
        }

        # Get the domain and tld

        $base_long = str_replace('http://', '', strtolower($baseurl));
        $base_long = str_replace('https://', '', strtolower($base_long));
        $base_arr = explode('/', $base_long);
        $base = $base_arr[0];
        $url_parts = explode('.', $base);
        $tld = array_pop($url_parts);
        if ($url_parts[0] == 'www') {
            $domain = array_pop($url_parts);
        } else {
            $domain = implode('.', $url_parts);
        }
        $shorturl = $domain.'.'.$tld;

        $this->domain = $domain;
        $this->shortUrl = $shorturl;
        $this->qualDomain = $proto.'://'.$shorturl.'/';

        # Let's be nice and try to set up a user
        try {
            if (!empty($username)) {
                # We're initiating a specified user
                $key = empty($lookup_column) ? $this->userColumn : $lookup_column;
                $this->getUser(array($key => $username));
            } else {
                $this->getUser();
            }
        } catch (Exception $e) {
            # If we tried on our own, let's do nothing; if it was user specified, re-throw it
            if (!empty($username)) {
                $key = empty($lookup_column) ? $this->userColumn : $lookup_column;
                $us = array($key => $username);
                throw(new Exception("Problem setting '$username' as ".print_r($us, true).': '.$e->getMessage()));
            }
        }
    }

    /***
     * Helper functions
     ***/

    private function getSiteKey()
    {
        return $this->siteKey;
    }
    public function getSiteName()
    {
        return $this->site;
    }
    public function getDomain()
    {
        return $this->domain;
    }
    public function getQualifiedDomain()
    {
        return $this->qualDomain;
    }
    public function getShortUrl()
    {
        return $this->shortUrl;
    }
    private function getMinPasswordLength()
    {
        if (!is_numeric($this->minPasswordLength)) {
            $this->minPasswordLength = 8;
        }
        $length = intval($this->minPasswordLength);

        return $length;
    }
    private function getThresholdLength()
    {
        return $this->thresholdLength;
    }
    private function getSupportEmail()
    {
        return $this->supportEmail;
    }
    public function needsManualAuth()
    {
        return $this->needsAuth === true;
    }
    private function getMailObject()
    {
        require_once dirname(__FILE__).'/../PHPMailer/PHPMailerAutoload.php';
        require_once dirname(__FILE__).'/../CONFIG.php';
        global $is_smtp,$mail_host,$mail_user,$mail_password,$is_pop3;
        $mail = new PHPMailer();
        if ($is_smtp) {
            $mail->isSMTP();
            $mail->SMTPAuth = true;
            $mail->Host = $mail_host;
            $mail->Username = $mail_user;
            $mail->Password = $mail_password;
            $mail->SMTPSecure = 'tls';
            $mail->Port = 587;
        }
        if ($is_pop3) {
            $mail->isPOP3();
        } # Need to expand this
        $mail->From = 'blackhole@'.$this->getShortUrl();
        $mail->FromName = $this->getDomain().' Mailer Bot';
        $mail->isHTML(true);

        return $mail;
    }
    private function needsSUNotification()
    {
        return toBool($this->suNotify);
    }
    private function getSecret($is_test = false)
    {
        $userdata = $this->getUser();
        if ($is_test) {
            return empty($userdata[$this->tmpColumn]) ? false : $userdata[$this->tmpColumn];
        }

        return empty($userdata[$this->totpColumn]) ? false : $userdata[$this->totpColumn];
    }

    private function setTempSecret($secret = '')
    {
        $userdata = $this->getUser();
        $l = $this->openDB();
        $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='$secret' WHERE `".$this->userColumn."`='".$this->getUsername()."'";
        $r = mysqli_query($l, $query);
        if ($r === false) {
            return array('status' => false,'error' => mysqli_error($l));
        }

        return array('status' => true);
    }



    public function has2FA()
    {
        $userdata = $this->getUser();

        return !empty($userdata[$this->totpColumn]);
    }
    public function getUser($user_id = null)
    {
        /***
         * Get the user, and assign one if it hasn't been assigned already
         *
         * @param string|array $user_id Either a column/value pair or an ID for the default column
         * @return array of the user result column
         ***/

        if (empty($this->user) || !empty($user_id)) {
            $this->setUser($user_id);
        } elseif (empty($this->user)) {
            # Try a cookie
            $cookielink = $this->domain.'_link';
            $altcookielink = str_replace('.', '_', $this->domain).'_link';
            $ucookielink = empty($_COOKIE[$cookielink]) ? $altcookielink : $cookielink;
            $this->setUser($ucookielink);
        }
        $userdata = $this->user;
        $userdata['img'] = $this->getUserPicture();
        if (!array($userdata)) {
            if (empty($userdata)) {
                # Couldn't get the user in any automated way
            $error = 'Unable to retrieve user';
            } else {
                # The user was bad
            $error = 'Bad user provided - ';
                if (is_string($userdata)) {
                    $error .= $userdata;
                } elseif (is_array($userdata)) {
                    $error .= current($userdata).' of type '.key($userdata);
                } else {
                    $error .= 'unrecognized type';
                }
            }
            throw(new Exception($error));
        }

        if (@array_key_exists($this->userColumn, $userdata)) {
            $this->username = $userdata[$this->userColumn];
        }
        if (@array_key_exists($this->linkColumn, $userdata)) {
            $this->userlink = $userdata[$this->linkColumn];
        }

        return $userdata;
    }

    private function setUser($user_id = null)
    {
        /***
         * Set the user for this object. Always overwrites current user.
         * Only intended to be called by getUser()
         *
         * @param string|array $user_id Either a column/value pair or an ID for the default column
         ***/
        $ouid = $user_id;
        $cookielink = $this->domain.'_link';
        $altcookielink = str_replace('.', '_', $this->domain).'_link';
        $ucookielink = empty($_COOKIE[$cookielink]) ? $altcookielink : $cookielink;
        if (!empty($user_id) && is_array($user_id) && sizeof($user_id) == 1) {
            # Specified as a column/value pair
            $col = key($user_id);
            $user_id = current($user_id);
        } elseif (!empty($user_id) && !is_array($user_id)) {
            # Just a id with the default column
            $col = $this->userColumn;
        } elseif (!empty($_COOKIE[$ucookielink])) {
            # See if we can get this from the cookies
            $user_id = $_COOKIE[$ucookielink];
            $col = $this->linkColumn;
        }

        # Do we have an ID to work with?
        if (empty($user_id) || empty($col)) {
            # We couldn't get it from direct assignment or cookies
            throw(new Exception("Unable to set user for '".$col."' => '".$user_id."', and unable to read cookies. {".print_r($ouid, true).'}'));
        }

        # Inputs are sanitized in lookupItem
        $result = $this->lookupItem($user_id, $col);
        if ($result !== false && !is_array($result)) {
            $userdata = mysqli_fetch_assoc($result);
            if (is_array($userdata)) {
                $this->user = $userdata;
            }
        }
        if (!is_array($this->user)) {
            # Bad query - let getUser() handle it
            $this->user = null;
        }
    }

    public function getUsername()
    {
        return $this->username;
    }

    public function getHardlink()
    {
        $link = $this->userlink;
        # Has this been defined yet?
        // if (empty($link)) {
        //     try {
        //         $this->getUser();
        //         $link = $this->userlink;
        //     } catch(Exception $e) {
        //         $link = null;
        //     }
        // }
        return $link;
    }

    protected function getNameTag($tag = "name") {
        $userdata = $this->getUser();
        if (!is_array($userdata)) return false;
        $nameXml = $userdata["name"];
        $xml = new Xml();
        $xml->setXml($nameXml);
        return $xml->getTagContents($tag);
    }

    public function getName() {
        return $this->getNameTag("name");
    }

    public function getFirstName() {
        return $this->getNameTag("fname");
    }

    public function getLastName() {
        return $this->getNameTag("lname");
    }

    public function getProfile() {
        /***
         * Returns the public_profile of the userdata
         ***/
        # Are profiles configured?
        if (!$this->columnExists("public_profile")) {
            return false;
        }
        $userdata = $this->getUser();
        $profile = $userdata["public_profile"];
        $jProfile = json_decode($profile, true);
        return is_array($jProfile) ? $jProfile : false;
    }

    private function getUserWhere() {
        return " WHERE `".$this->linkColumn."`='".$this->getHardlink()."'";
    }


    public static function isValidEmail($email, $maxLength = 100) {
        $preg = "/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/";
        return preg_match($preg, $email) == 1 && strlen($email) <= $maxLength;
    }

    public function getPhone()
    {
        $userdata = $this->getUser();

        return self::cleanPhone($userdata['phone']);
    }

    public function hasPhone()
    {
        $userdata = $this->getUser();

        return self::isValidPhone($userdata['phone']);
    }

    private function getDigest()
    {
        $allowed_digest = array(
            'md5',
            'sha1',
            'sha256',
            'sha512',
        );
        if (!in_array($this->totpdigest, $allowed_digest)) {
            return 'sha1';
        }

        return $this->totpdigest;
    }

    public function setTwilioSID($sid)
    {
        $this->twilio_sid = $sid;
    }
    public function getTwilioSID()
    {
        return $this->twilio_sid;
    }

    public function setTwilioToken($token)
    {
        $this->$twilio_token = $token;
    }
    public function getTwilioToken()
    {
        return $this->twilio_token;
    }

    public function setTwilioNumber($number)
    {
        # Validate it
        if (!self::isValidPhone($number)) {
        throw(new Exception('Invalid phone number'));
        }
    }
    public function getTwilioNumber()
    {
        return $this->twilio_number;
    }

    public function canSMS($strict = true, $throw = true)
    {
        /***
         * Return if the user can get an SMS
         * @param bool $strict if true, throw an exception for bad setup,
         *                     and false if unverified; otherwise, false for
         *                     bad setup, and true if the number is OK (regardless of verification)
         * @return bool
         ***/
        $twilioSID = $this->getTwilioSID();
        $twilioToken = $this->getTwilioToken();
        $twilio_status = !empty($twilioSID) && !empty($twilioToken);
        if (!$twilio_status && $strict === true) {
            if ($throw) {
                throw(new Exception("Twilio has not been configured. Be sure that \$twilio_sid, \$twilio_token, and \$twilio_number are specified in config.php, or call setTwilioSID(), setTwilioToken(), and setTwilioNumber() first."));
            }

            return false;
        } elseif (!$twilio_status) {
            return false;
        }
        $userdata = $this->getUser();
        if ($strict) {
            if (!self::isValidPhone($this->getPhone())) {
                if ($throw) {
                    throw(new Exception('Illegal phone number.'));
                }

                return false;
            }
        }
        # If we're strict, the user only can SMS when the phone number is verified.
        # Otherwise, we just return the status of the phone number itself.
        $verified = $strict ? $userdata['phone_verified'] == true : self::isValidPhone($this->getPhone());

        return $verified;
    }

    private static function cleanPhone($number)
    {
        /***
         * @param string $number
         * @return int $number
         ***/
        # Common things that may show up in a phone number
        $number = preg_replace('/[^0-9]/', '', $number);
        # Remove the country code for the US
        if (substr($number, 0, 1) == '1') {
            $number = substr($number, 1);
        }

        return $number;
    }

    private static function isValidPhone($number)
    {
        $number = self::cleanPhone($number);

        return strlen($number) == 10;
    }

    public static function microtime_float()
    {
        list($usec, $sec) = explode(' ', microtime());

        return ((float) $usec + (float) $sec);
    }

    public static function strbool($bool)
    {
        // returns the string of a boolean as 'true' or 'false'.
        if (is_string($bool)) {
            $bool = boolstr($bool);
        } // if a string is passed, convert it to a bool
        if (is_bool($bool)) {
            return $bool ? 'true' : 'false';
        } else {
            return 'non_bool';
        }
    }

    public static function doLoadOTP()
    {
        require_once dirname(__FILE__).'/../base32/src/Base32/Base32.php';
        require_once dirname(__FILE__).'/../totp/lib/OTPHP/OTPInterface.php';
        require_once dirname(__FILE__).'/../totp/lib/OTPHP/OTP.php';
        require_once dirname(__FILE__).'/../totp/lib/OTPHP/TOTPInterface.php';
        require_once dirname(__FILE__).'/../totp/lib/OTPHP/TOTP.php';
    }

    public function checkTOTP($provided)
    {
        /***
         * Check the TOTP code provided by the user.
         * In all but exceptional circumstances, this should be the
         * function used.
         *
         * @param int $provided Provided TOTP passcode
         * @return bool
         ***/
        return $this->verifyTOTP($provided);
    }

    private function verifyTOTP($provided, $is_test = false)
    {
        /***
         * Check the TOTP code provided by the user
         *
         * @param int $provided Provided OTP passcode
         * @param bool $is_test if it's a test run, check the temporary rather than real column.
         * @return bool
         ***/
        self::doLoadOTP();
        $secret = $this->getSecret($is_test);
        if ($secret === false) {
            return false;
        }
        try {
            $totp = new OTPHP\TOTP($secret);
            $totp->setDigest($this->getDigest());
            if ($totp->verify($provided)) {
                return true;
            }
            if (!is_numeric($this->totpSteps)) {
                throw(new Exception('Bad TOTP step count'));
            }
            $i = 1;
            while ($i <= $this->totpSteps) {
                $test = array();
                $test[] = $totp->now();
                $test[] = $totp->at(time() + 30 * $i);
                $test[] = $totp->at(time() - 30 * $i);
                ++$i;
                # Check on every iteration. It'll usually be faster.
                if (in_array($provided, $test)) {
                    return true;
                }
            }

            return false;
        } catch (Exception $e) {
            throw(new Exception('Bad parameters provided to verifyOTP :: '.$e->getMessage()));
        }
    }

    public function makeTOTP($provider = null)
    {
        /***
         * Assign a user a multifactor authentication code
         *
         * @param string $provider The provider giving 2FA.
         * @return array with the status in the key "status", errors in "error" and "human_error",
         * username in "username", and provisioning data in "uri"
         ***/
        if (empty($this->username)) {
            $this->getUser();
            # We MUST have this properly assigned
            if (empty($this->username)) {
                return array('status' => false,'error' => 'Unable to get user.');
            }
        }
        if ($this->getSecret() !== false) {
            return array('status' => false,'error' => '2FA has already been enabled for this user.','human_error' => "You've already enabled 2-factor authentication.",'username' => $this->username);
        }
        try {
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
            $salt = Stronghash::createSalt();
            require_once dirname(__FILE__).'/../base32/src/Base32/Base32.php';
            $secret = Base32::encode($salt);
            ## The resulting provisioning URI should now be sent to the user
            ## Flag should be set server-side indicating the change id pending
            $l = $this->openDB();
            $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='$secret' WHERE `".$this->userColumn."`='".$this->username."'";
            $r = mysqli_query($l, $query);
            if ($r === false) {
                return array('status' => false,'human_error' => 'Database error','error' => mysqli_error($l));
            }
            # The data was saved correctly
            # Let's create the provisioning stuff!

            self::doLoadOTP();
            $totp = new OTPHP\TOTP($secret);
            $totp->setDigest($this->getDigest());
            $totp->setLabel($this->username);
            $totp->setIssuer($provider);
            $uri = $totp->getProvisioningURI($label, $provider);
            # iPhones don't actually accept the full, valid URI
            $unsafe_uri = urldecode($uri);
            $uri_args = explode('?', $unsafe_uri);
            $iphone_uri = $uri_args[0].'?';
            $iphone_args = array();
            $iphone_safe_args = array('secret','issuer');
            foreach (explode('&', $uri_args[1]) as $paramval) {
                $pv = explode('=', $paramval);
                $param = $pv[0];
                $val = $pv[1];
                if (in_array($param, $iphone_safe_args)) {
                    $iphone_args[] = $param.'='.$val;
                }
            }
            $iphone_uri .= implode('&', $iphone_args);
            /* $iphone32 = str_replace("=","",$secret_part[1]); */
            /* $iphone_uri = $secret_part[0]."secret=".$iphone32; #still no good */
            $retarr = self::generateQR($iphone_uri);

            # Let's get a human-readable secret
            $human_secret0 = str_replace('=', '', $secret);
            $i = 0;
            $human_secret = '';
            foreach (str_split($human_secret0) as $char) {
                $human_secret .= $char;
                ++$i;
                if ($i == 4) {
                    $human_secret .= ' ';
                    $i = 0;
                }
            }
            $retarr['secret'] = $secret;
            $retarr['human_secret'] = $human_secret;
            $retarr['username'] = $this->username;

            return $retarr;
        } catch (Exception $e) {
            return array('status' => false,'human_error' => 'Unexpected error in makeTOTP','error' => $e->getMessage(),'username' => $this->username,'provider' => $provider,'label' => $totp->getLabel(),'uri' => $uri,'secret' => $secret);
        }
    }

    public function saveTOTP($code)
    {
        /***
         * Read the tentative secret and make it real
         *
         * @params int $code Provided TOTP code at prompt
         * @return array
         ***/

        if ($this->verifyTOTP($code, true)) {
            # If it's good, make the secret "real" in the $this->totpColumn
            $userdata = $this->getUser();
            $secret = $userdata[$this->tmpColumn];
            $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->totpColumn."`='$secret', `".$this->tmpColumn."`=''  WHERE `".$this->userColumn."`='".$this->username."'";
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
            $backup = Stronghash::createSalt();
            $backup_store = hash('sha512', $backup);
            $query2 = 'UPDATE `'.$this->getTable().'` SET `'.$this->totpBackup."`='$backup_store' WHERE `".$this->userColumn."`='".$this->username."'";
            $l = $this->openDB();
            mysqli_query($l, 'BEGIN');
            $r = mysqli_query($l, $query);
            if ($r === false) {
                $e = mysqli_error($l);
                mysqli_query($l, 'ROLLBACK');

                return array('status' => false,'error' => $e,'human_error' => 'Could not save secret','username' => $this->username);
            }
            $r = mysqli_query($l, $query2);
            if ($r === false) {
                $e = mysqli_error($l);
                mysqli_query($l, 'ROLLBACK');

                return array('status' => false,'error' => $e,'human_error' => 'Could not create backup code','username' => $this->username);
            }
            mysqli_query($l, 'COMMIT');
            # Let the user know
            return array('status' => true,'username' => $this->username,'backup' => $backup);
        } else {
            # The code is wrong, feed back to the user
            return array('status' => false,'error' => '0','human_error' => 'Invalid code.');
        }
    }

    public function removeTOTP($username, $password, $code)
    {
        /***
         * Remove two factor authentication
         *
         * @param string $username
         * @param string $password
         * @param string $code Either the Authenticator code, or previously generated backup code.
         * @return bool|array true if success, array if failure
         ***/
        $l = $this->openDB();
        $verify = $this->lookupUser($username, $password);
        # Verify will always be false; but let's see if "error" is also false.
        if ($verify['totp'] !== true) {
            # Either the user doesn't have it, or the credentials are bad
            if ($verify[0] === true) {
                # Credentials are fine
                return array('status' => false,'error' => 'Invalid operation','human_error' => "You don't have two-factor authentication turned on");
            } else {
                return array('status' => false,'error' => 'Bad credentials','result' => $verify,'human_error' => 'Sorry, bad username or password.');
            }
        }
        $this->getUser();
        # Check code for length, if it's long it's the backup
        if (strlen($code) > 6) {
            # Check against $this->totpBackup
            $query = 'SELECT `'.$this->totpBackup.'` FROM `'.$this->getTable().'` WHERE `'.$this->userColumn."`='".$this->username."'";
            $r = mysqli_query($l, $query);
            if ($r === false) {
                return array('status' => false,'error' => mysqli_error($l),'human_error' => 'Database error');
        }
            $row = mysqli_fetch_row($r);
            $hash = hash('sha512', $code);
            if ($hash !== $row[0]) {
                return array('status' => false,'error' => 'Bad backup code','human_error' => 'The backup code you entered was invalid. Please try again.');
            }
        } else {
            # Verify the code
            if (!$this->verifyTOTP($code)) {
                return array('status' => false,'error' => 'Bad TOTP code','human_error' => 'The code you entered was invalid. Please try again.');
            }
        }
        # Unset backup and totpcol
        $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->totpColumn."`='', `".$this->tmpColumn."`='', `".$this->totpBackup."`='' WHERE `".$this->userColumn."`='".$this->getUsername()."'";
        mysqli_query($l, 'BEGIN');
        $r = mysqli_query($l, $query);
        if ($r === false) {
            $e = mysqli_error($l);
            mysqli_query($l, 'ROLLBACK');

            return array('status' => false,'error' => $e,'human_error' => 'Could not unset two-factor authentication','username' => $this->getUsername());
        }
        $r = mysqli_query($l, 'COMMIT');
        if ($r === false) {
            return array('status' => false,'error' => mysqli_error($l),'human_error' => 'Server error verifying removal. Please try again.');
        }

        return array('status' => true,'query' => $query,'username' => $this->getUsername());
    }

    public function sendTOTPText()
    {
        /***
         * Send a text message to the destination number with the TOTP code
         ***/
        # Get the current TOTP value for the user
        # Send the text through Twilio
        # Return the status and updated message
        if ($this->has2FA()) {
            try {
                self::doLoadOTP();
                $totp = new OTPHP\TOTP($this->getSecret());
                $totp->setDigest($this->getDigest());
                $message = 'Your authentication code for '.$this->getSiteName().' is: '.$totp->now().' . It is valid for 30 seconds.';
                $this->textUser($message);

                return true;
            } catch (Exception $e) {
                return false;
            }
        } else {
            throw(new Exception('User does not have TOTP enabled to send a text!'));
        }
    }

    public static function generateQR($uri, $data_path = null, $identifier_path = null)
    {
        /***
         * Generate a QR code from a string
         *
         * @param string $uri
         * @param string $data_path The path to the write directory
         * @param string $identifier_path An optional subdirectory for paths; makes loops easier
         * @returns array with the main results in "svg" and "raw" keys, with a Google fallback in the "url" key
         ***/
        try {
            require_once dirname(__FILE__).'/../qr/qrlib.php';
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
            $salt = Stronghash::createSalt();
            $persistent = !empty($data_path);
            if (!$persistent) {
                $tmp_dir = dirname(__FILE__).DIRECTORY_SEPARATOR.'temp'.DIRECTORY_SEPARATOR;
                if (!file_exists($tmp_dir)) {
                    if (!mkdir($tmp_dir)) {
                        # Could not write to temporary path
                        throw(new Exception("Could not write to '$tmp_dir'"));
                    }
                }
                $web_dir = 'temp/';
                $filename = $tmp_dir.sha1($salt).'.png';
            } else {
                # Persistent file
                $file = $sha1($salt.$uri);
                if (substr($data_path, -1) != '/') {
                    $data_path .= DIRECTORY_SEPARATOR;
                }
                $full_path = empty($identifier_path) ? $data_path : $data_path.$identifier_path.DIRECTORY_SEPARATOR;
                if (!file_exists($full_path)) {
                    if (!mkdir($full_path)) {
                        # Could not write to the storage path
                        throw(new Exception("Could not write to '$full_path'"));
                    }
                }
                $filename = $full_path.$file.'.png';
            }
            $svg = QRcode::svg($uri, false, QR_ECLEVEL_H, 8, 1);
            if (function_exists('ImageCreate')) {
                QRcode::png($uri, $filename, QR_ECLEVEL_H, 8, 1);
            }
            $raw = base64_encode(file_get_contents_curl($filename));
            $raw = 'data:image/png;base64,'.$raw;
            if (!$persistent) {
                unlink($filename);
            }
            # As a final option, get a URL fallback
            # https://developers.google.com/chart/infographics/docs/qr_codes?csw=1
            $url = 'https://chart.googleapis.com/chart?cht=qr&chs=500x500&chld=H&chl='.$uri;

            return array('status' => true,'uri' => $uri,'svg' => $svg,'raw' => $raw,'url' => $url);
        } catch (Exception $e) {
            return array('status' => false,'human_error' => 'Unable to generate QR code','error' => $e->getMessage(),'uri' => $uri,'identifier' => $identifier,'persistent' => $persistent);
        }
    }

    /***
     * Primary functions
     ***/

    public function createUser($username, $pw_in, $name, $dname, $phone = null)
    {
        /***
         * Create a new user
         *
         * @param string $username A valid email address
         * @param string pw_in The input password. This function will hash it.
         * @param array $name An array of form array(firstName,lastName)
         * @param string $dname The display name of the user.
         * @return array {"status"=>bool,"error"=>message,"message"=>user message,[userdata,cookies,auth_result]}
         ***/
        if (strlen($pw_in) > 8192) {
            return array('status' => false,'error' => 'Passwords must be less than 8192 characters in length.');
        }
        // Send email for validation
        $ou = $username;
        /***
         * Weaker, but use if you have problems with the sanitize() function.
         $l=$this->openDB();
         $user=mysqli_real_escape_string($l,$username);
        ***/
        $user = $this->sanitize($username);
        $preg = "/[a-z0-9!#$%&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/";
        if (!self::isValidEmail($username)) {
            return array('status' => false,'error' => 'Your email is not a valid email address. Please try again.');
        } else {
            $username = $user;
        } # synonymize

        if (strlen(implode(' ', $name)) > 200 || strlen($dname) > 100) {
            return array('status' => false,'error' => 'Your name must be less than 100 characters.');
        }

        $result = $this->lookupItem($user, $this->userColumn);
        if ($result !== false) {
            $data = mysqli_fetch_assoc($result);
            if ($data[$this->userColumn] == $username) {
                return array('status' => false, 'error' => 'Duplicate username', 'human_error' => 'Your email is already registered. Please try again. Did you forget your password?', 'app_error_code' => 123);
            }
        }
        if (strlen($pw_in) < $this->getMinPasswordLength()) {
            return array('status' => false,'error' => 'Your password is too short. Please try again.');
        }
        # Complexity checks here, if not relegated to JS ...
        if (!class_exists('Stronghash')) {
            require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
        }
        $hash = new Stronghash();
        $creation = self::microtime_float();
        $pw1 = $hash->hasher($pw_in);
        $pw_store = json_encode($pw1);
        $algo = $pw1['algo'];
        $salt = $pw1['salt'];
        if (!empty($pw1['rounds'])) {
            $rounds = '<rounds>'.$pw1['rounds'].'</rounds>';
        }
        $data_init = "<xml><algo>$algo</algo>$rounds</xml>";
        $name = $this->sanitize($name);
        $dname = $this->sanitize($dname);
        $iv = $this->getIV();
        # only encrypt if requested, then put in secdata
        $ne = self::encryptThis($salt.$pw, implode(' ', $name), $iv);
        $sdata_init = '<xml><name>'.$ne.'</name></xml>';
        $names = '<xml><name>'.$this->sanitize(implode(' ', $name)).'</name><fname>'.$this->sanitize($name[0]).'</fname><lname>'.$name[1].'</lname><dname>'.$this->sanitize($dname).'</dname></xml>';
        $hardlink = sha1($salt.$creation);
        $store = array();
        foreach ($this->getCols() as $key => $type) {
            switch ($key) {
            case $this->userColumn:
                $store[$key] = $user;
                break;
            case $this->pwColumn:
                $store[$key] = $pw_store; # Generated
                break;
            case 'salt':
                $store[$key] = $salt; # Generated
            case 'creation':
                $store[$key] = $creation; # Generated
                break;
            case 'name':
                $store[$key] = $names; # Generated
                break;
            case 'flag':
                // Is the user active, or does it need authentication first?
                // Default "true" means immediately active.
                $store[$key] = !$this->needsManualAuth();
                break;
            case 'dtime':
                $store[$key] = 0;
                break;
            case 'data':
                $store[$key] = $data_init;
                break;
            case 'secdata':
                $store[$key] = $sdata_init;
                break;
            case $this->linkColumn:
                $store[$key] = $hardlink;
                break;
            case 'phone':
                $store[$key] = self::isValidPhone($phone) ? self::cleanPhone($phone) : null;
                break;
            case 'phone_verified':
            case 'admin_flag':
            case 'su_flag':
            case 'disabled':
                $store[$key] = false;
                break;
            case 'random_seed':
                $store[$key] = $iv;
                break;
            default:
                $store[$key] = '';
            }
        }

        $test_res = $this->addItem($store, null, false, true); # Precleaned
        if ($test_res) {
            # Get ID value
            # The TOTP column has never been set up, so no worries
            # We do want to set the override, though, in case the manual
            # authentication flag has been set.
            $res = $this->lookupUser($user, $pw_in, true, false, true);
            $userdata = $res[1];
            $id = $userdata['id'];
            $message = 'Success!';
            if (is_numeric($id) && !empty($userdata)) {
                $this->getUser(array('id' => $id));
                $auth_result = array();
                if ($this->needsManualAuth()) {
                    $auth_result = $this->requireUserAuth($user);
                    if ($auth_result['mailer']['emails_sent'] != $auth_result['mailer']['attempts_made']) {
                        $mailer_copy = $auth_result['mailer'];
                        unset($mailer_copy['destinations']);
                        $message .= "</h3></div><div class='alert alert-danger'><button type='button' class='close' data-dismiss='alert' aria-label='Close'><span aria-hidden='true'>&times;</span></button>Not all authentication validation emails could be sent, so please be sure to notify <a href='mailto:".$this->getSupportEmail()."?subject=Manual%20Validation'>email support with a description of this error</a> from the same email address you used to sign up.</small><br/>Error details:<code>".print_r($mailer_copy, true).'</code></div><div>';
                        unset($auth_result['status']);
                    }
                }
                $cookies = $this->createCookieTokens();
                if ($this->needsSUNotification() && !$this->needsManualAuth()) {
                    # Superusers should be notified of the signup
                    $newUserSubject = "New user for ".$this->getQualifiedDomain();
                    $newUserBody = "<p>A new user has signed up for ".$this->getQualifiedDomain().".</p><p>Their username is: <code>".$user."</code></p><p>If this is unexpected or impermissible, take care to revoke them immediately.";
                    $this->mailSuperusers($newUserSubject, $newUserBody);
                }
                return array_merge(array('status' => true, 'message' => $message), $userdata, $cookies, $auth_result);
            } else {
                /*
                 , "lookup_result" => $res, "storage_passed" => $store,
                */
                return array('status' => false,'error' => 'Failure: Unable to verify user creation', 'human_error' => 'Ther was an error confirming creation of your user. Please try again. Your user may have been partially created already.','add' => $test_res, 'userdata' => $userdata);
            }
        } else {
            return array('status' => false,'error' => 'Failure: unknown database error. Your user was unable to be saved.', 'storage_data' => $store, 'field_data' => $fields, 'add_result' => $test_res);
        }
    }

    public function lookupUser($username, $pw, $return = true, $totp_code = false, $override = false)
    {
        /***
         * Primary function to check login validation.
         *
         * @param string|int $username a username looking at a column set by the
         * usercol of this object
         * @param string $pw the plaintext password of the user
         * @param bool $return whether to return user data, or just the
         *                      boolean lookup state
         * @param bool|int $totp_code - false if none is needed/given,
         *                              otherwise the code
         * @param bool $override
         ***/

        if (strlen($pw) > 8192) {
            throw(new Exception('Passwords must be less than 8192 characters in length.'));
        }
        # check it's a valid email! validation skipped.
        $xml = new Xml();
        $result = $this->lookupItem($username, $this->userColumn);
        if ($result !== false) {
            try {
                $userdata = mysqli_fetch_assoc($result);
                if (is_numeric($userdata['id'])) {
                    # check password
                    if (!class_exists('Stronghash')) {
                        require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
                    }
                    $hash = new Stronghash();
                    $data = json_decode($userdata[$this->pwColumn], true);
                    $original_data = $data;
                    $data['raw_db'] = $userdata[$this->pwColumn];
                    # Decrypt the password if totp_code is_numeric()
                    if (is_numeric($totp_code)) {
                        $pw = $this->decryptWithStoredKey($pw);
                    }
                    if (empty($data) || empty($data['salt'])) {
                        try {
                            # Try legacy
                            $xml->setXml($userdata['data']);
                            $data['algo'] = $xml->getTagContents('<algo>');
                            $data['rounds'] = $xml->getTagContents('<rounds>');
                            /* Default rounds for sha512 */
                            if (empty($data['rounds'])) {
                                $data['rounds'] = 10000;
                            }
                            if (empty($data['algo'])) {
                                $data['algo'] = 'sha512';
                            }
                            $data['salt'] = null;
                            $data['hash'] = $userdata['pass'];
                            $data['legacy'] = true;
                            $pw = $userdata['salt'].$pw.$userdata['creation'];
                        } catch (Exception $e) {
                            return array(false,'status' => false, 'message' => 'No valid password data');
                        }
                    }
                    if ($hash->verifyHash($pw, $data)) {
                        $this->getUser($userdata[$this->userColumn]);

                        ## Does the user have 2-factor authentication?
                        if ($this->has2FA()) {
                            $l = $this->openDB();
                            if (empty($totp_code)) {
                                # The user has 2FA turned on, prompt it
                                /*
                                 * Here we create a temporary, dummy
                                 * password for the client to save and
                                 * pass again. Since we're storing an
                                 * encrypted hash, even the data being
                                 * taken is no more "public" than it
                                 * already is in the password
                                 * column. However, it keeps us validating
                                 * a session in progress of TOTP-ing.
                                 */
                                $key = Stronghash::createSalt();
                                $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='$key' WHERE `".$this->userColumn."`='".$this->username."'";
                                $r = mysqli_query($l, $query);
                                if ($r === false) {
                                    throw(new Exception('Unable to encrypt password'));
                                }
                                $encrypted_pw = urlencode(self::encryptThis($key, $pw, $this->getIV()));

                                # Encrypt the keys to validate the user asynchronously
                                # Of course, this this was called asynchronously, the keys will be empty ...

                                $cookiekey = $this->domain.'_secret';
                                #$cookiekey=str_replace(".","_",$this->domain)."_secret";
                                $cookieauth = $this->domain.'_auth';
                                #$cookieauth=str_replace(".","_",$this->domain)."_auth";

                                $encrypted_secret = self::encryptThis($key, $_COOKIE[$cookiekey], $this->getIV());
                                $encrypted_hash = self::encryptThis($key, $_COOKIE[$cookieauth], $this->getIV());

                                return array(false,'status' => false,'totp' => true,'error' => false,'human_error' => 'Please enter the code generated by the authenticator application on your device.','encrypted_password' => $encrypted_pw,'encrypted_secret' => $encrypted_secret,'encrypted_hash' => $encrypted_hash);
                            }
                            if ($this->verifyTOTP($totp_code) !== true) {
                                # Bad TOTP code
                                return array(false,'status' => false,'totp' => true,'error' => 'Invalid TOTP code','human_error' => 'Bad verification code. Please try again.');
                            }
                            # Remove the encryption key
                            $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='' WHERE `".$this->userColumn."`='".$this->username."'";
                            mysqli_query($l, $query);
                            # Return decrypted userdata, if applicable
                            # The salt is the password key "salt"
                            $decname = self::decryptThis($data['salt'].$pw, $userdata['name'], $this->getIV());
                            if (empty($decname)) {
                                $decname = $userdata['name'];
                            }
                            if (!$return) {
                                return array(true,$decname,'status' => true);
                            } else {
                                $returning = array(true,$userdata,'status' => true,'data' => $userdata);

                                return $returning;
                            }
                        }

                        if (($userdata['flag'] || $override) && !$userdata['disabled']) {
                            # This user is OK and not disabled, nor pending validation
                            # Return decrypted userdata, if applicable
                            # The salt is the password key "salt"
                            $decname = self::decryptThis($data['salt'].$pw, $userdata['name'], $this->getIV());
                            if (empty($decname)) {
                                $decname = $userdata['name'];
                            }
                            if (!$return) {
                                return array(true,$decname,'status' => true);
                            } else {
                                $returning = array(true,$userdata,'status' => true,'data' => $userdata);

                                return $returning;
                            }
                        } else {
                            if (!$userdata['flag']) {
                                return array(false,'status' => false,'message' => 'Your login information is correct, but your account is still being validated, or has been disabled. Please try again later.');
                            }
                            if ($userdata['disabled']) {
                                # do a time check
                                if ($userdata['dtime'] + 3600 > self::microtime_float()) {
                                    $rem = intval($userdata['dtime']) - intval(self::microtime_float()) + 3600;
                                    $min = $rem % 60;
                                    $sec = $rem - 60 * $min;

                                    return array(false,'status' => false,'message' => 'Your account has been disabled for too many failed login attempts. Please try again in '.$min.' minutes and '.$sec.' seconds.');
                                } else {
                                    # Clear login disabled flag
                                    $query1 = 'UPDATE `'.$this->getTable().'` SET `disabled`=false WHERE `id`='.$userdata['id'];
                                    $l = $this->openDB();
                                    $result = mysqli_query($l, $query1);
                                }
                            }
                            # All checks passed.
                            if (!$return) {
                                $decname = self::decryptThis($salt.$pw, $userdata['name'], $this->getIV());
                                if (empty($decname)) {
                                    $decname = $userdata['name'];
                                }

                                return array(true,$decname,'status' => true);
                            } else {
                                $userdata['img'] = $this->getUserPicture();
                                $returning = array(true,$userdata,'status' => true,'data' => $userdata);

                                return $returning;
                            }
                        }
                    } else {
                        return array(false,'status' => false,'message' => 'Sorry, your username or password is incorrect.','error' => 'Bad Password'); # , "data" => $data, "check_results" => $hash->verifyHash($pw, $data, null, null, null, true)
                    }
                # end good username loop
                } else {
                    return array(false,'status' => false,'message' => 'Sorry, your username or password is incorrect.','error' => 'Bad username','desc' => 'No numeric id');
                }
            } catch (Exception $e) {
                return array(false,'status' => false,'message' => 'System error. Please try again. If the problem persists, please report it.','error' => $e->getMessage());
            }
        } else {
            return array(false,'status' => false,'message' => 'Sorry, your username or password is incorrect.','error' => 'Bad username','desc' => $result['error']);
        }
    }


    public function hasAlternateEmail() {
        $key = "alternate_email";
        if ($this->columnExists($key) !== true) {
            $this->addColumn($key, "varchar(255)");
        }
        try {
            $u = $this->getUser();
        } catch (Exception $e) {
            return false;
        }
        return !empty($u[$key]);
    }

    public function verifyEmail($auth_code = null, $alternate = false) {
        if ($alternate === true) {
            if (!$this->hasAlternateEmail()) return array(
                "status" => false,
                "is_good" => false,
                "error" => "NO_ALTERNATE_EMAIL",
                "human_error" => "This user has no alternate email",
            );
        }
        if ($alternate === true) {
            $email = $this->getAlternateEmail();
        } else {
            $email = $this->getUsername();
        }
        if ($this->isVerified($alternate) === true) {
            return array(
                "status" => false,
                "is_good" => true,
                "error" => "ALREADY_VERIFIED",
                "human_error" => "You've already verified " . $email,
                "meets_restriction_criteria" => $this->meetsRestrictionCriteria(),
                "email" => $email,
            );
        }
        if (empty($auth_code)) {
            return $this->sendEmailVerification($alternate);
        } else {
            # Check it
            $response = array(
                "status" => false,
                "verification_action" => "VALIDATE_CODE",
                "auth_code" => $auth_code,
                "alternate" => $alternate,
                "email" => $email,
            );
            $secret = $this->getSecret(true);
            if ($auth_code == $secret) {
                # Good
                $response["is_good"] = true;
                # Update the column
                $lookup = array($this->userColumn => $this->getUsername());
                $key = $alternate ? "alternate_email_verified" : "email_verified";
                $query = "UPDATE `".$this->getTable()."` SET `".$key."` = TRUE ".$this->getUserWhere();
                $r = mysqli_query($this->getLink(), $query);
                if ($r === false) {
                    $reponse["error"] = mysqli_error($this->getLink());
                    $reponse["human_error"] = "Error updating verified status";
                } else {
                    $response["status"] = true;
                    if ($this->isVerified($alternate)) $this->setTempSecret("");
                }
                $response["is_verified"] = $this->isVerified($alternate);
                $response["meets_restriction_criteria"] = $this->meetsRestrictionCriteria();
            } else {
                # Bad
                $response["error"] = "BAD_AUTH_CODE";
                $response["human_error"] = "Invalid authorization code";
            }
            return $response;
        }
    }


    public function sendEmailVerification($alternate = false) {
        /***
         *
         ***/

        if (!class_exists('Stronghash')) {
            require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
        }
        $auth = Stronghash::createSalt(32);
        $r = $this->setTempSecret($auth);
        if ($r["status"] === false) {
            throw(new Exception('Could not prepare authorization code - '.$r['error']));
        }
        $mail = $this->getMailObject();
        $mail_subject = '['.$this->getDomain().'] Verify Your Email';
        $mail->Subject = $mail_subject;
        include dirname(__FILE__).'/../CONFIG.php';
        $url = !isset($login_url) ? 'login.php' : $login_url;
        $rel_dir = str_replace($relative_path, '', $working_subdirectory);
        if (substr($rel_dir, -1) != '/' && !empty($rel_dir)) {
            $rel_dir = $rel_dir.'/';
        }
        $link = $this->getQualifiedDomain().$rel_dir.$url.'?action=verifyemail&alternate='.strbool($alternate).'&token='.$auth.'&username='.$this->getUsername();
        $explanation = $alternate ? "<strong>".$this->getAlternateEmail()."</strong> as an alias of ".$this->getUsername() : "<strong>".$this->getUsername()."</strong>";
        $body = "<html><head><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\"/></head><body><p>Thanks for verifying! We're sending this email to ".$explanation." to verify ownership of this email. Click <a href='".$link."' class='btn btn-primary'>this link to verify</a>, or enter the following into your verification page:</p>\n<p class='text-center'><code>$auth</code></p><p>If you did not request this email, feel free to ignore it.</p></body></html>";
        $mail->Body = $body;
        $u = $this->getUser();
        $email = $alternate ? $u["alternate_email"] : $this->getUsername();
        $mail->addAddress($email);
        $success = $mail->send();
        $error = $success ? null : $mail->ErrorInfo;
        return array(
            "status" => $success,
            "error" => $error,
            "verification_action" => "SEND_EMAIL",
            "alternate" => $alternate,
        );

    }

    public function mailSuperusers($subject, $body)
    {
        /***
         * Send an email to site superusers
         ***/
        $mail = $this->getMailObject();
        $mail_subject = '[Server Notice] ' . $subject;
        $mail->Subject = $mail_subject;
        $body = "<html><head><link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\"/></head><body>".$body."</body></html>";
        $mail->Body = $body;
        # Get superusers
        $query = "SELECT `username` FROM `".$this->getTable()."` WHERE `su_flag` IS TRUE";
        $this->invalidateLink();
        $r = mysqli_query($this->getLink(), $query);
        if ($r === false) {
            return array(
                "status" => false,
                "error" => mysqli_error($this->getLink()),
            );
        }
        # Add superusers as destination
        while ($row = mysqli_fetch_row($r)) {
            $mail->addAddress($row[0]);
        }
        # Send it
        $success = $mail->send();
        $error = $success ? null : $mail->ErrorInfo;
        return array(
            "status" => $success,
            "error" => $error,
        );
    }

    public function isVerified($alternate = false)
    {
        $key = $alternate ? "alternate_email_verified" : "email_verified";
        $colCheck = array(
            "key" => $key,
            "exists" => $this->columnExists($key),
            "query" => $this->columnExists($key, true),
        );
        if ($colCheck['exists'] !== true) {
            $r = $this->addColumn($key, "BOOLEAN", 0);
            if ($r["status"] !== true) {
                $r['col_check'] = $colCheck;
                return $r;
            }
        }
        $u = $this->getUser();
        return toBool($u[$key]);
    }

    public function meetsRestrictionCriteria() {
        try {
            if ($this->isAdmin() || $this->isSU()) return true;
            if ($this->isVerified() !== true) return false;
            if ($this->hasAlternateEmail()) {
                if ($this->isVerified(true) === true) {
                    $alternateMatch = $this->matchEmailAgainstRestrictions($this->getAlternateEmail());
                    if ($alternateMatch === true) return true;
                }
            }
            return $this->matchEmailAgainstRestrictions($this->getUsername());
        } catch (Exception $e) {
            return false;
        }
    }

    public function alternateIsAllowed() {
        if ($this->hasAlternateEmail()) {
            return $this->matchEmailAgainstRestrictions($this->getAlternateEmail());
        } else return false;
    }

    public function emailIsAllowed() {
        return $this->matchEmailAgainstRestrictions($this->getUsername());
    }

    public function isAdmin() {
        try {
            $u = $this->getUser();
            return toBool($u["admin_flag"]);
        } catch (Exception $e) {
            return false;
        }
    }

    public function isSU() {
        try {
            $u = $this->getUser();
            return toBool($u["su_flag"]);
        } catch (Exception $e) {
            return false;
        }
    }

    public static function examineEmail($email) {
        $domainParts = explode("@", $email);
        $qualifiedDomain = array_pop($domainParts);
        $domainBaseParts = explode(".", $qualifiedDomain);
        $tld = array_pop($domainBaseParts);
        while(sizeof($domainBaseParts) > 1) {
            $tld2 = array_pop($domainBaseParts);
            $tld = $tld2 . "." . $tld;
        }
        $domain = array_pop($domainBaseParts);
        $response = array(
            "tld" => $tld,
            "domain" => $domain,
            "email" => $email,

        );
        return $response;
    }

    public function examineEmailDeep($email) {
        $domainParts = explode("@", $email);
        $qualifiedDomain = array_pop($domainParts);
        $domainBaseParts = explode(".", $qualifiedDomain);
        $tld = array_pop($domainBaseParts);
        $i = 1;
        $tldTwo = null;
        while(sizeof($domainBaseParts) > 1) {
            $tld2 = array_pop($domainBaseParts);
            $tld = $tld2 . "." . $tld;
            ++$i;
            if ($i == 2) $tldTwo = $tld;
        }
        $domain = array_pop($domainBaseParts);
        $response = array(
            "tld" => $tld,
            "tld2" => $tldTwo,
            "domain" => $domain,
            "email" => $email,
            "allowedDomains" => $this->allowedDomains,
            "allowedTLDs" => $this->allowedTLDs,
        );
        $status = null;
        if (is_array($this->allowedDomains)) {
            $response["checkedDomains"] = true;
            if (sizeof($this->allowedDomains) > 0) {
                # Match
                $hasFullDomain = in_array($qualifiedDomain, $this->allowedDomains);
                $hasBaseDomain = in_array($domain, $this->allowedDomains);
                if (!($hasFullDomain || $hasBaseDomain)) $status = false;
                else $response["validDomain"] = true;
            } else $response["validDomain"] = null;
        } else $response["checkedDomains"] = false;
        if (is_array($this->allowedTLDs)) {
            $response["checkTlds"] = true;
            if (sizeof($this->allowedTLDs) > 0) {
                # Regex substring
                $imploded = implode("|", $this->allowedTLDs);
                $matchTlds = str_replace(".","\.", $imploded);
                $reg = '/[\w.]+@(\w+\.)+('.$matchTlds.')/';
                $regMatch = boolstr(preg_match($reg, $email));
                $response['reg'] = $reg;
                $response['regMatch'] = $regMatch;
                # Match
                $baseTldMatch = in_array($tld, $this->allowedTLDs);
                if (!empty($tldTwo)) {
                    $europeTldMatch = in_array($tldTwo, $this->allowedTLDs);
                } else $europeTldMatch = false;
                if (!($baseTldMatch || $europeTldMatch || $regMatch)) $status = false;
                else $response["validTld"] = true;
            }
        } else $response["checkTlds"] = false;
        if ($status === null) $status = true;
        $response["status"] = $status;
        return $response;
    }

    private function matchEmailAgainstRestrictions($email) {
        $domainParts = explode("@", $email);
        $qualifiedDomain = array_pop($domainParts);
        $domainBaseParts = explode(".", $qualifiedDomain);
        $tld = array_pop($domainBaseParts);
        $i = 1;
        $tldTwo = null;
        while(sizeof($domainBaseParts) > 1) {
            $tld2 = array_pop($domainBaseParts);
            $tld = $tld2 . "." . $tld;
            ++$i;
            if ($i == 2) $tldTwo = $tld;
        }
        $domain = array_pop($domainBaseParts);
        if (is_array($this->allowedDomains)) {
            if (sizeof($this->allowedDomains) > 0) {
                # Match
                $hasFullDomain = in_array($qualifiedDomain, $this->allowedDomains);
                $hasBaseDomain = in_array($domain, $this->allowedDomains);
                if (!($hasFullDomain || $hasBaseDomain)) return false;
            }
        }
        if (is_array($this->allowedTLDs)) {
            if (sizeof($this->allowedTLDs) > 0) {
                # Regex substring
                $imploded = implode("|", $this->allowedTLDs);
                $matchTlds = str_replace(".","\.", $imploded);
                $reg = '/[\w.]+@(\w+\.)+('.$matchTlds.')/';
                $regMatch = boolstr(preg_match($reg, $email));
                # Match
                $baseTldMatch = in_array($tld, $this->allowedTLDs);
                if (!empty($tldTwo)) {
                  $europeTldMatch = in_array($tldTwo, $this->allowedTLDs);
                } else $europeTldMatch = false;
                if (!($baseTldMatch || $europeTldMatch || $regMatch)) return false;
            }
        }
        return true;
    }

    public function getRestrictionCriteria() {
        $domains = "any";
        if (is_array($this->allowedDomains)) {
            if (sizeof($this->allowedDomains) > 0) {
                $domains = implode(", ", $this->allowedDomains);
            }
        }
        $tlds = "any";
        if (is_array($this->allowedTLDs)) {
            if (sizeof($this->allowedTLDs) > 0) {
                $tlds = implode(", ", $this->allowedTLDs);
            }
        }
        return array(
            "domains" => $domains,
            "tlds" => $tlds,
        );

    }

    public function setAlternateEmail($email) {
        $email = trim($email);
        $email = $this->sanitize($email);
        # Check it's an email
        if (!self::isValidEmail($email)) {
            return array(
                "status" => false,
                "error" => "INVALID_EMAIL",
                "email" => $email,
            );
        }
        # Write it to the DB
        $response = array(
            "status" => false,
            "email" => $email,
        );
        $key = "alternate_email";
        if ($this->columnExists($key) !== true) {
            $reponse["column"] = $this->addColumn($key, "varchar(255)");
            if ($response["column"]["status"] !== true) {
                $response["error"] = "BAD_COLUMN";
                $response["human_error"] = "Couldn't create column '$key'";
                return $response;
            }
        }
        $query = "UPDATE `".$this->getTable()."` SET `".$key."`='".$email."', `alternate_email_verified`=FALSE".$this->getUserWhere();

        $this->invalidateLink();
        $r = mysqli_query($this->getLink(), $query);

        if ($r === false) {
            $response["status"] = false;
            $response["error"] = mysqli_error($this->getLink());
            $reponse["human_error"] = "Could not save alternate email";
        } else {
            $response["status"] = true;
            $response["verification_status"] = $this->sendEmailVerification(true);
        }
        return $response;
    }

    public function getAlternateEmail() {
        if ($this->hasAlternateEmail()) {
            $u = $this->getUser();
            return $u["alternate_email"];
        }
        return false;
    }

    public function getUserPicture($id = null, $path = null, $extra_types_array = null)
    {
        if (empty($id)) {
            $id = $this->getHardlink();
        }
        if (empty($path)) {
            $path = $this->picture_path;
        } else {
            $path .= substr($path, -1) == '/' ? '' : '/';
        }
      //$path = $this->qualDomain . $path;
    $valid_ext = array('jpg','jpeg','png','bmp','gif','svg');
        if (is_array($extra_types_array)) {
            $valid_ext = array_merge($extra_types_array);
        }
        foreach ($valid_ext as $ext) {
            $file = $id.'.'.$ext;
            if (file_exists($path.$file)) {
                return $this->qualDomain.$path.$file;
            }
        }

        return $this->qualDomain.$path.'default.png';
    }

    public function setImageAsUserPicture($image, $path = null) {
        /***
         * Sets an image as one for a user
         *
         * @param string $image -> filename for an image asset
         * @param string $path -> path to $image
         ***/
        if (empty($path)) {
            $path = $this->picture_path;
        }
        if (strpos($image, $path) === 0) {
           $image = str_replace($path, "", $image);
        }
        $sourceImage = $path . $image;
        $imageData = file_get_contents_curl($sourceImage);
        $iParts = explode(".", $image);
        $extension = array_pop($iParts);
        $imgUri = $path.$this->getHardlink().'.'.$extension;
        $imgSmallUri = $path.$this->getHardlink().'-sm.'.$extension;
        $imgTinyUri = $path.$this->getHardlink().'-xs.'.$extension;
        try {
            file_put_contents($imgUri, $imageData);
            #rename($sourceImage, $imageUri);
        } catch (Exception $e) {
            return array('status' => false,'error' => $e->getMessage(),'human_error' => 'There was an error in processing your image','app_error_code' => 119,'path' => $path,'img_path' => $imgUri, "source" => $sourceImage);
        }
        try {
            # Shrinkify image
            require_once dirname(__FILE__).'/image_functions.php';
            @resizeImage($imgUri, $imgSmallUri, 512, 512);
            @resizeImage($imgUri, $imgTinyUri, 128, 128);

            return array('status' => true, 'image_uri' => $imgUri, 'small_image_uri' => $imgSmallUri, 'tiny_image_uri' => $imgTinyUri, "source" => $sourceImage);
        } catch (Exception $e) {
            return array('status' => true,'image_uri' => $imgUri,'error' => $e->getMessage(),'human_error' => 'There was an error in shrinking your image','app_error_code' => 122,'path' => $path, "source" => $sourceImage);
        }
    }

    public function setUserPicture($image, $path = null)
    {
        if (empty($path)) {
            $path = $this->picture_path;
        }
        if (is_array($image)) {
            # Parse the chunked base 64 image that was sent as a POST
            $imgArray = $image;
            $imgComposite = array();
            $extension = $imgArray['extension'];
            if (empty($extension)) {
                $extension = 'jpg';
            }
            foreach ($imgArray as $k => $v) {
                if (preg_match('/i[0-9]+/', $k)) {
                    $k = str_replace('i', '', $k);
                    $imgComposite[$k] = html_entity_decode($v);
                }
            }
            if (!empty($imgComposite)) {
                ksort($imgComposite);
                $image = implode('', $imgComposite);
            } else {
                return array('status' => false, 'error' => 'Could not parse POST','human_error' => 'There was an error uploading your image','app_error_code' => 118);
            }
            $imgUri = $path.$this->getHardlink().'.'.$extension;
            $imgSmallUri = $path.$this->getHardlink().'-sm.'.$extension;
            $imgTinyUri = $path.$this->getHardlink().'-xs.'.$extension;
            try {
                file_put_contents($imgUri, base64_decode($image));
            } catch (Exception $e) {
                return array('status' => false,'error' => $e->getMessage(),'human_error' => 'There was an error in processing your image','app_error_code' => 119,'path' => $path,'img_path' => $imgUri);
            }
            try {
                # Shrinkify image
            require_once dirname(__FILE__).'/image_functions.php';
                @resizeImage($imgUri, $imgSmallUri, 512, 512);
                @resizeImage($imgUri, $imgTinyUri, 128, 128);

                return array('status' => true, 'image_uri' => $imgUri, 'small_image_uri' => $imgSmallUri, 'tiny_image_uri' => $imgTinyUri);
            } catch (Exception $e) {
                return array('status' => true,'image_uri' => $imgUri,'error' => $e->getMessage(),'human_error' => 'There was an error in shrinking your image','app_error_code' => 122,'path' => $path);
            }
        }
        # It's not of POST-form
        return array('status' => false,'error' => 'Unsupported image upload method','app_error_code' => 120,'human_error' => 'The upload method you tried is not yet supported. Please try an alternate method.');
    }

    public function validateUser($userid = null, $hash = null, $secret = null, $detail = false)
    {
        /***
     * Returns true or false based on user validation
     *
     * Requires:
     * 1) a device that has logged in (via a cookie-based secret)
     * 2) is originating at the same IP address
     * 3) Pinged server has correct config file
     * 4) Has database value
     *
     * Can be spoofed with inspected code at the same IP.
     * Similarly, gets around 2FA at the same IP.
     *
     * @param string $userid User email
     * @param string $hash Provide the final computed string to work with
     * @param string $secret Provide the cookie secret to work with
     * @param bool $detail Provide detailed returns
     * @return bool|array bool if $detail is false, array if $detail is true
     ***/
      $cookiekey = $this->domain.'_secret';
        $altcookiekey = str_replace('.', '_', $this->domain).'_secret';
        $cookieauth = $this->domain.'_auth';
        $altcookieauth = str_replace('.', '_', $this->domain).'_auth';
        $originalId = $userid;
        if ($userid === true) {
            # We are short-cutting getting the details back for the
        # current user
        $userid = null;
            $detail = true;
        }
        if (strpos($userid, '@') === false && !empty($userid)) {
            $userid = array($this->linkColumn => $userid);
        }
        try {
            $userdata = $this->getUser($userid);
        } catch (Exception $e) {
            # There is no data at all here, or something horribly broken.
        $userdata = '';
        }
        if (is_array($userdata)) {
            $pw_characters = json_decode($userdata[$this->pwColumn], true);
            $salt = $pw_characters['salt'];
            $userid = $userdata[$this->linkColumn];
            # Is a restricted user valid?
            if (isset($userdata['restricted_user'])) {
                if (!$permitRestricted  && $userdata['restricted_user'] != false) {
                    return array(
                        'status' => false,
                        'state' => false,
                        'error' => 'Unprivledged user ID in restricted context',
                        'uid' => $userid,
                    );
                }
            }
            if (empty($hash) || empty($secret)) {
                $secret = $_COOKIE[$cookiekey];
                $hash = $_COOKIE[$cookieauth];
                if (empty($hash) || empty($secret)) {
                    $secret = $_COOKIE[$altcookiekey];
                    $hash = $_COOKIE[$altcookieauth];
                }
                $from_cookie = true;
                if (empty($hash) || empty($secret)) {
                    if ($detail) {
                        return array('state' => false,'status' => false,'error' => 'Empty verification tokens','uid' => $userid, 'salt' => $salt,'calc_conf' => $conf,'basis_conf' => $hash,'have_secret' => self::strbool(!empty($secret)),'from_cookie' => self::strbool($from_cookie),'cookie_checked' => $cookiekey);
                    }

                    return false;
                }
            } else {
                $from_cookie = false;
            }

            $current_ip = $_SERVER['REMOTE_ADDR'];
            $ipArray = explode(".", $current_ip);
            array_pop($ipArray);
            $ipTop = implode(".", $ipArray);
            $current_ip = $ipTop;

        # Are they logging in from the same IP?
        if ($userdata[$this->ipColumn] != $current_ip) {
            if ($detail) {
                return array('state' => false,'status' => false,'error' => 'Different IP address on login','uid' => $userid,'salt' => $salt,'calc_conf' => $conf,'basis_conf' => $hash,'have_secret' => self::strbool(!empty($secret)),'from_cookie' => self::strbool($from_cookie),'stored_ip' => $userdata[$this->ipColumn],'current_ip' => $current_ip, "full_current_ip" => $_SERVER['REMOTE_ADDR']);
            }

            return false;
        }

            $value_create = array($secret,$salt,$userdata[$this->cookieColumn],$userdata[$this->ipColumn],$this->getSiteKey());

            $conf = sha1(implode('', $value_create));
            $state = $conf == $hash;
            $error = null;
            if ($state) {
                $this->getUser($userdata[$this->userColumn]);
            } else {
                $error = 'Bad credentials';
                $userdata = null;
            }
            if ($detail) {
                return array('state' => self::strbool($state),'status' => $state,'uid' => $userid,'salt' => $salt,'calc_conf' => $conf,'basis_conf' => $hash,'from_cookie' => self::strbool($from_cookie),'got_user_pass_info' => is_array($pw_characters),'got_userdata' => is_array($userdata),'userdata' => $userdata,'source' => $value_create,'error' => $error,'cookie_checked' => $cookiekey, 'iv' => $this->getIV());
            }

            return $state;
        } else {
            // empty result
          if ($detail) {
              return array('state' => false,'status' => false,'error' => 'Invalid userid lookup','uid' => $userid,'col' => $col,'basis_conf' => $hash,'have_cookie_secret' => self::strbool(!empty($secret)),'cookie_checked' => $cookiekey);
          }

            return false;
        }
        if ($detail) {
            $detail = array('uid' => $userid,'col' => $col,'basis_conf' => $hash,'have_secret' => self::strbool(!empty($secret)),'cookie_checked' => $cookiekey);
            if (is_array($result)) {
                $detail['error'] = $result['error'];
            }

            return $detail;
        }

        return false;
    }

    public function createCookieTokens($username = null, $password_or_is_data = true, $remote = null)
    {
        /***
         * Create the cookies to be used everywhere else in the
         * application
         *
         * @param
         * @param
         * @param
         * @return
         ***/
        try {
            if (empty($username)) {
                $userdata = $this->getUser();
                $username = $this->username;
            } elseif ($password_or_is_data === true) {
                $userdata = $username;
                $username = $this->username;
            } else {
                $r = $this->lookupUser($username, $password_or_is_data);
                if ($r['status'] === false) {
                    return array(false,'status' => false,'error' => 'Bad user credentials','username' => $username);
                }
                $userdata = $r[1];
            }
            $id = $userdata['id'];
            $dblink = $userdata[$this->linkColumn];

        # Nom, cookies!
        $expire_days = 7;
            $expire = time() + 3600 * 24 * $expire_days;
        # Create a one-time key, store serverside
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
            $otsalt = Stronghash::createSalt();
            $cookie_secret = Stronghash::createSalt();
            $pw_characters = json_decode($userdata[$this->pwColumn], true);
            $salt = $pw_characters['salt'];
            $current_ip = empty($current_ip) ? $_SERVER['REMOTE_ADDR'] : $remote;
            $ipArray = explode(".", $current_ip);
            array_pop($ipArray);
            $ipTop = implode(".", $ipArray);
            $current_ip = $ipTop;

        # store it
        $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->cookieColumn."`='$otsalt', `".$this->ipColumn."`='$current_ip', `last_login`='".microtime_float()."' WHERE id='$id'";
            $l = $this->openDB();
            mysqli_query($l, 'BEGIN');
            $result = mysqli_query($l, $query);
            if ($result === false) {
                $r = mysqli_query($l, 'ROLLBACK');

                return array(false,'status' => false,'error' => '<p>'.mysqli_error($l).'<br/><br/>ERROR: Could not update login state.</p>');
            } else {
                $r = mysqli_query($l, 'COMMIT');
            }

            $value_create = array($cookie_secret,$salt,$otsalt,$current_ip,$this->getSiteKey());

            # authenticated since last login. Nontransposable outside network.

            $value = sha1(implode('', $value_create));

            $cookieuser = $this->domain.'_user';
            $cookieperson = $this->domain.'_name';
            $cookiewholeperson = $this->domain.'_fullname';
            $cookieauth = $this->domain.'_auth';
            $cookiekey = $this->domain.'_secret';
            $cookiepic = $this->domain.'_pic';
            $cookielink = $this->domain.'_link';

            # Read the XML information ...
            $xml = new Xml();
            $xml->setXml($userdata['name']);
            $user_greet = $xml->getTagContents('<fname>');
            $user_full_name = $xml->getTagContents('<name>'); // for now
            setcookie($cookieauth, $value, $expire);
            setcookie($cookiekey, $cookie_secret, $expire);
            setcookie($cookieuser, $username, $expire);
            setcookie($cookieperson, $user_greet, $expire);
            setcookie($cookiewholeperson, $user_full_name, $expire);
            $path = $this->getUserPicture($userdata['id']);
            setcookie($cookiepic, $path, $expire);
            setcookie($cookielink, $dblink, $expire);

            $js_expires = ",{expires:$expire_days,path:'/'});\n";
            $jquerycookie = "$.cookie('$cookieauth','$value'".$js_expires;
            $jquerycookie .= "$.cookie('$cookiekey','$cookie_secret'".$js_expires;
            $jquerycookie .= "$.cookie('$cookieuser','$username'".$js_expires;
            $jquerycookie .= "$.cookie('$cookieperson','$user_greet'".$js_expires;
            $jquerycookie .= "$.cookie('$cookiewholeperson','$user_full_name'".$js_expires;
            $jquerycookie .= "$.cookie('$cookiepic','$path'".$js_expires;
            $jquerycookie .= "$.cookie('$cookielink','$dblink'".$js_expires;

            $raw_data = array(
                $cookieuser => $username,
                $cookieauth => $value,
                $cookiekey => $cookie_secret,
                $cookiepic => $path,
                $cookieperson => $user_greet,
                $cookiewholeperson => $user_full_name,
                $cookielink => $dblink,
            );

            return array(
                'status' => true,
                'user' => "{ '$cookieuser':'$username'}",
                'auth' => "{'$cookieauth':'$value'}",
                'secret' => "{'$cookiekey':'$cookie_secret'}",
                'pic' => "{'$cookiepic':'$path'}",
                'name' => "{'$cookieperson':'$user_greet'}",
                'full_name' => "{'$cookiewholeperson':'$user_full_name'}",
                'link' => "{'$cookielink':'$dblink'}",
                'js' => $jquerycookie,
                'source' => $value_create,
                'ip_given' => $remote,
                'raw_auth' => $value,
                'raw_uid' => $dblink,
                'raw_secret' => $cookie_secret,
                'raw_cookie' => $raw_data,
                'basis' => $value_create,
                'expires' => "{expires:$expire_days,path:'/'}",
            );
        } catch (Exception $e) {
            return array('status' => false,'error' => 'Unexpected exception in cookies: '.$e->getMessage(),'provided_data' => array('user_data' => $username,'data_flag' => $password_or_is_data,'remote' => $remote));
        }
    }

    public function registerApp($validation_data, $encryption_key, $device, $phone_verify_code = null)
    {
        $status = $this->validateUser($validation_data['dblink'], $validation_data['hash'], $validation_data['secret'], true);
        $status['status'] = boolstr($status['status']);
        if ($status['status'] != true) {
            if ($status['error'] == 'Invalid userid lookup') {
                $human_error = 'Please create your user first';
                $status['error'] = 'New user flag missing';
            } else {
                $human_error = 'There was a problem validating your credentials. Please try again.';
            }

            return array_merge(array('status' => $status['status'], 'error' => 'Invalid validation credentials', 'human_error' => $human_error, 'app_error_code' => 110, 'original_error' => $status['error'], 'details' => $status), $status);
        }
        $validationStatus = $status;
    # Application verification requires SMS
    $phoneStatus = $this->verifyPhone($phone_verify_code);
        if ($phoneStatus['is_good'] === true) {
            # The phone is good and the user is good, do the device mapping
      $l = $this->openDB();
            $query = 'SELECT `'.$this->appKeyColumn.'` FROM `'.$this->getTable().'` WHERE `'.$this->linkColumn."`='".$this->getHardlink()."'";
            $r = mysqli_query($l, $query);
            if ($r === false) {
                return array('status' => false,'error' => mysqli_error($l),'human_error' => "The database couldn't read the device list",'query' => $query,'app_error_code' => 113);
            }
      # We want the current entries
      $row = mysqli_fetch_row($r);
            $encryptedSecretsJson = html_entity_decode($row[0]);
            $encryptedSecretsArray = json_decode($encryptedSecretsJson, true);
      # Even if this device is already registered, we want to
      # overwrite the association
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
      # Create a secret
      $server_secret = Stronghash::createSalt();
      # Encrypt it with $encryption_key ...
      $data = self::encryptThis($encryption_key, $server_secret, $this->getIV());
            $encryptedSecretsArray[$device] = $data;
            $encryptedSecretsJson = json_encode($encryptedSecretsArray);
      # ... and save it
      if (empty($validation_data['application_verification'])) {
          $validation_data['application_verification'] = 'none_provided';
      }
            $status = $this->writeToUser($encryptedSecretsJson, $this->appKeyColumn, $validation_data);
            if ($status['status'] !== true) {
                if (empty($status['app_error_code'])) {
                    $status['original_status'] = $status;
                    $status['app_error_code'] = 112;
                    $status['human_error'] = 'Could not register app to server';
                } else {
                }
                $validation_data['initial_validation'] = $validationStatus;
                $status['validation_data_provided'] = $validation_data;

                return $status;
            }
            $status['secret'] = $server_secret;
      //$status["key"] = "";
      $status[$this->linkColumn] = $this->getHardlink();
            $status['id_name'] = $this->linkColumn;

            return $status;
        } else {
            return array('status' => false,'human_error' => 'Please validate your phone number to continue','error' => 'Phone validation needed','app_error_code' => 111,'twilio' => $phoneStatus,'details' => array('requested_action' => 'register'));
        }
    }

    public function verifyApp($verify_data)
    {
        /***
     * Verify an application
     *
     * @param array $verify_data
     * @return array
     ***/
    try {
        try {
            # Verify the struture of $verify_data
        if (!(isset($verify_data['device']) && isset($verify_data['authorization_token']) && isset($verify_data['auth_prepend']) && isset($verify_data['appsecret_key']) && isset($verify_data['dblink']))) {
            return array('status' => false,'human_error' => 'The application and server could not communicate. Please contact support.','error' => 'Invalid verification data structure','app_error_code' => 107);
        }
            $userdata = $this->getUser();
        } catch (Exception $e) {
            return array('status' => false,'human_error' => "We couldn't verify the application. Please try again, or contact support",'error' => $e->getMessage(),'app_error_code' => 100);
        }
        $l = $this->openDB();
        $query = 'SELECT `'.$this->appKeyColumn.'` FROM `'.$this->getTable().'` WHERE `'.$this->linkColumn."`='".$this->getHardlink()."'";
        $r = mysqli_query($l, $query);
        if ($r === false) {
            # The query failed
        return array('status' => false,'human_error' => "You haven't registered the application yet. Please sign in first.",'error' => mysqli_error($l),'app_error_code' => -1);
        }
        if (mysqli_num_rows($r) == 0) {
            return array('status' => false,'human_error' => "You haven't registered the application yet. Please sign in first.",'error' => 'No valid rows','app_error_code' => 104);
        }
        $row = mysqli_fetch_row($r);
        $encryptedSecretsJson = $row[0];
        if (empty($encryptedSecretsJson)) {
            return array('status' => false,'human_error' => "You haven't registered the application yet. Please sign in first.",'error' => 'No content in verification column','app_error_code' => 104);
        }
        $encryptedSecretsJson = html_entity_decode($encryptedSecretsJson);
        $encryptedSecretsArray = json_decode($encryptedSecretsJson, true);
      # Does this device exist?
      if (!array_key_exists($verify_data['device'], $encryptedSecretsArray)) {
          $validDevices = array();
          foreach ($encryptedSecretsArray as $device => $secret) {
              $validDevices[] = $device;
          }

          return array('status' => false,'human_error' => "This device isn't yet registered. Please log in with this device first",'error' => 'Invalid device','app_error_code' => 105, 'details' => array('device' => $verify_data['device'],'valid_devices' => $validDevices,'raw_json' => $encryptedSecretsJson, 'raw_encrypted' => $encryptedSecretsArray));
      }
        $secret = self::decryptThis($verify_data['appsecret_key'], $encryptedSecretsArray[$verify_data['device']], $this->getIV());
      # Now we can verify the provided auth token
      $computedToken = sha1($verify_data['auth_prepend'].$secret.$verify_data['auth_postpend']);
        $providedToken = $verify_data['authorization_token'];
        if ($computedToken === $providedToken) {
            return array('status' => true,'data' => $userdata,'userid' => $this->getHardlink(),'validation_tokens' => $this->createCookieTokens());
        } else {
            return array('status' => false,'human_error' => 'Invalid credentials. Please log out and log back in.','error' => 'Invalid credentials','app_error_code' => 106);
        }
    } catch (Exception $e) {
        return array('status' => false,'human_error' => 'Server error. Please try again later.','error' => 'Unexpected exception: '.$e->getMessage(),'app_error_code' => -1);
    }
    }

    public function writeToUser($data, $col, $validation_data = null, $replace = true, $alert_forbidden_column = true)
    {

        /***
         * Write data to a user column.
         *
         * @param string $data the data to be written
         * @param string $col the database column to be written to
         * @param array $validation_data data to verify access to the
         * user. An array of "password"=>$password or manually provided
         * cookie data with $this->linkColumn as the key. If this isn't
         * provided, cookies are used.
         * @param bool $replace whether to replace existing
         * data. Otherwise, it appends. Default: true.
         * @return
         ***/

        $vmeta = false;
        $error = false;
        if (empty($data) || empty($col)) {
            return array('status' => false,'error' => 'Bad request');
        }
        $validated = false;
        if (is_array($validation_data)) {
            if (array_key_exists($this->linkColumn, $validation_data) && !empty($validation_data[$this->linkColumn])) {
                // confirm with validateUser();
                $validated = $this->validateUser($validation_data[$this->linkColumn], $validation_data['hash'], $validation_data['secret']);
                $method = 'Confirmation token';
                $where_col = $this->linkColumn;
                $user = $validation_data[$this->linkColumn];
            } elseif (array_key_exists('password', $validation_data)) {
                # confirm with lookupUser();
                # If TOTP is enabled, this lookup will always fail ...
                $vmeta = $this->lookupUser($validation_data['username'], $validation_data['password']);
                $validated = $vmeta[0];
                if ($validated) {
                    $this->getUser(array('username' => $validation_data['username']));
                }
                $method = 'Password';
            } elseif (array_key_exists('application_verification', $validation_data)) {
                # The user is accessing through an app. Check the
                # verification chain.
                $status = $this->verifyApp($validation_data['application_verification']);
                if ($status['status'] !== true) {
                    // array("status"=>false,"error"=>"Bad application verification","human_error"=>"There was a problem verifying the application","app_error_code"=>106);
                    return $status;
                }
            } else {
                return array('status' => false,'error' => 'Bad validation data');
            }
        } else {
            $validated = $this->validateUser();
            $method = 'Cookie';
        }
        if ($validated) {
            $userdata = $this->getUser();
            $where_col = $this->linkColumn;
            $user = $userdata[$where_col];
            if (empty($user)) {
                return array('status' => false,'error' => 'Problem assigning user');
            }
            // write it to the db
            // replace or append based on flag
            $real_col = $this->sanitize($col, true);
            if (!$replace) {
                # pull the existing data ...
                $l = $this->openDB();
                $prequery = "SELECT `$real_col` FROM `".$this->getTable()."` WHERE `$where_col`='$user'";
                # Look for relevent JSON entries or XML entries and replace them
                $r = mysqli_query($l, $prequery);
                $row = mysqli_fetch_row($r);
                $d = $row[0];
                $jd = json_decode($d, true);
                if ($jd == null) {
                    # XML -- only takes one tag in!!
                    $xml_data = explode('</', $data);
                    $tag = array_pop($xml_data);
                    $tag = $this->sanitize(substr($tag, 0, -1));
                    $tag = '<'.$tag.'>';
                    $xml = new Xml();
                    $xml->setXml($data);
                    $tag_data = $xml->getTagContents($tag);
                    $clean_tag_data = $this->sanitize($tag_data);
                    $new_data = $xml->updateTag($tag, $clean_tag_data);
                } else {
                    $jn = json_decode($data, true);
                    foreach ($jn as $k => $v) {
                        $ck = $this->sanitize($k);
                        $cv = $this->sanitize($v);
                        $jd[$ck] = $cv;
                    }
                    $new_data = json_encode($jd);
                }
                $real_data = mysqli_real_escape_string($l, $new_data);
            } else {
                $real_data = $this->sanitize($data);
            }

            if (empty($real_data)) {
                return array('status' => false,'error' => 'Invalid input data (sanitization error)');
            }
            $query = 'UPDATE `'.$this->getTable()."` SET `$real_col`=\"".$real_data."\" WHERE `$where_col`='$user'";
            $l = $this->openDB();
            mysqli_query($l, 'BEGIN');
            $r = mysqli_query($l, $query);
            $finish_query = $r ? 'COMMIT' : 'ROLLBACK';
            if ($finish_query == 'ROLLBACK') {
                $error = mysqli_error($l);
            }
            $r2 = mysqli_query($l, $finish_query);

            return array('status' => $r,'data' => $data,'col' => $col,'action' => $finish_query,'result' => $r2,'method' => $method,'error' => $error);
        } else {
            return array('status' => false,'error' => 'Bad validation','method' => $method,'validated_meta' => $vmeta, 'working_data' => $validation_data, 'link_col' => $this->linkColumn);
        } #,"validated_details_token"=>$this->validateUser($validation_data[$this->linkColumn],$validation_data['hash'],$validation_data['secret'],true));
    }

    public static function createRandomUserPassword($newPasswordLength = 16)
    {
        /***
         *
         ***/
        $sourcePasswordLength = 2 * $newPasswordLength;
        if (!class_exists('Stronghash')) {
            require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
        }
        $passwordBase = Stronghash::createSalt($sourcePasswordLength);
        $ambiguousCharacters = array(
            'l',
            '1',
            'I',
            'O',
            '0',
            'Q',
            'D',
            'B',
            '8',
            'G',
            '6',
            'b',
            'S',
            '5',
            'Z',
            '2',
        );
        $passwordNiceBase = str_replace($ambiguousCharacters, '', $passwordBase);
        $passwordNice = substr($passwordNiceBase, 0, $newPasswordLength);

        return $passwordNice;
    }

    public function resetUserPassword($method = null, $totp = null)
    {
        /***
         * Set up the password reset functionality.
         * When invoked, provide the user with a pair of tokens to verify
         * they own the username.
         *
         * The client UI then should get the credentials provided by this
         * function and invoke doUpdatePassword().
         *
         * @param string $method "email" or "sms"
         * @param int $totp TOTP passcode if 2FA is set up
         * @return array
         ***/
        # If the user has 2FA set up, first prompt for the code
        try {
            $userdata = $this->getUser();
        } catch (Exception $e) {
            $callback = array('status' => false,'action' => 'BAD_USER', 'error' => $e->getMessage());

            return $callback;
        }
        if ($this->has2FA() && $totp == null) {
            $callback = array('status' => false,'action' => 'GET_TOTP','canSMS' => $this->canSMS());

            return $callback;
        } else {
            if ($this->has2FA()) {
                # Verify the 2FA
                if (!$this->checkTOTP($totp)) {
                    return array('status' => false, 'action' => 'BAD_TOTP', 'canSMS' => $this->canSMS());
                }
            }
            # We want to do a soft canSMS check, first.
            if ($this->canSMS(false) && empty($method)) {
                # The system can SMS, but can the user?
                if ($this->canSMS()) {
                    # The user can SMS and no method is supplied
                    $callback = array('status' => false,'action' => 'NEED_METHOD');

                    return $callback;
                }
            } elseif ($this->canSMS(false) and $method == 'sms') {
                # The system can SMS ...
                if (!$this->canSMS()) {
                    # The system can SMS but the user isn't verified, but asked
                    # for SMS verification.
                    $callback = array('status' => false,'action' => 'SMS_NOT_VERIFIED');

                    return $callback;
                } else {
                    # The user and system CAN SMS, and the method is set. We
                    # can do this normally, now.
                }
            } elseif (!$this->canSMS(false) and $method == 'sms') {
                # The system can't SMS
                $callback = array('status' => false,'action' => 'ILLEGAL_METHOD','error' => 'The system is not set up for SMS', 'human_error' => "The system requested to send a text message, but it's unsupported. Please try a different method.");

                return $callback;
            } elseif (!$this->canSMS(false) and empty($method)) {
                # If the system can't SMS, and there's no method, assume email
                $method = 'email';
            }
            # Calculate out the secrets
            /*
             * We want a multi-part secret here. So, we create a random
             * string and random 8-character key.
             *
             * We give the user the
             * substr(hash('md5',salt.$rand_string),0,8) and the key
             *
             * We encrypt the $rand_string with $key and stash it in
             * $this->tmpColumn .
             *
             * When it comes time to verify the reset, we decrypt
             * $this->tmpColumn and compare the first 8 characters of the md5.
             *
             * Note that the use of md5 was mostly for speed an
             * convenience. While a stronger hash would be less prone to
             * "guessing", the fact that we're truncating it to eight
             * characters for the user makes it moot.
             */
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
            $rand_string = Stronghash::createSalt();
            $key = self::createRandomUserPassword(8);
            $pw_data = json_decode($userdata[$this->pwColumn], true);
            $salt = $pw_data['salt'];
            $user_verify_token = substr(hash('md5', $salt.$rand_string), 0, 8);
            $encrypted_secret = self::encryptThis($key, $rand_string, $this->getIV());
            $this->setTempSecret($encrypted_secret);
            # These tokens are the ones we'll send to the user
            $user_tokens = array('key' => $key,'verify' => $user_verify_token);

            # If the user has SMS and email, check $method
            if ($method == 'email') {
                # Reset by email
                include dirname(__FILE__).'/../CONFIG.php';
                $url = !isset($login_url) ? 'login.php' : $login_url;
                $rel_dir = str_replace($relative_path, '', $working_subdirectory);
                if (substr($rel_dir, -1) != '/' && !empty($rel_dir)) {
                    $rel_dir = $rel_dir.'/';
                }
                $email_link = $this->getQualifiedDomain().$rel_dir.$url.'?action=finishpasswordreset&key='.urlencode($user_tokens['key']).'&verify='.urlencode($user_tokens['verify']).'&user='.$this->getUsername();
                $mail = $this->getMailObject();
                $subject = '['.$this->getDomain().'] Account Reset';
                $mail->Subject = $subject;
                $body = "<p>You've requested to reset the password to ".$this->getDomain().". Click or copy-paste the link below to reset your password.</p><pre><a href='".$email_link."'>".$email_link.'</a></pre><p>You can also enter a verification code of <strong>'.$user_tokens['verify'].'</strong> and key of <strong>'.$user_tokens['key']."</strong> on the reset page.</p><p>If you didn't request a password change, you can ignore this email.</p>.";
                $mail->Body = $body;
                $mail->addAddress($this->getUsername());
                $status = $mail->send();
                $email = array(
                    'to' => $this->getUsername(),
                    'subject' => $mail->Subject,
                    'body' => $mail->Body,
                );
                $to = $this->getUsername();
                $headers = 'MIME-Version: 1.0'."\r\n";
                $headers .= 'Content-type: text/html; charset=iso-8859-1'."\r\n";
                $headers .= 'From: ['.$this->getDomain().'] Mailer Bot <blackhole@'.$this->getDomain().'>';
                #mail($to,$subject,$body,$headers);
                # You can include email as a callback arg for debugging, but
                # not for release -- VERY insecure
                $callback = array('status' => $status,'method' => 'email');
                if (!$status) {
                    $callback['error'] = $mail->ErrorInfo;
                    $callback['human_error'] = 'There was a problem sending the email. Please try again later.';
                }

                return $callback;
            } elseif ($method == 'sms') {
                # Reset by text
                if ($this->canSMS(false)) {
                    $sms_message = 'At the reset password prompt, for KEY enter '.$user_tokens['key'].' , and for VERIFY enter '.$user_tokens['verify'];
                    $t_obj = $this->textUser($sms_message);

                    return array('status' => true,'method' => 'sms','twilio' => $t_obj);
                } else {
                    return array('status' => false,'method' => 'sms','error' => "The user can't SMS",'human_error' => 'Sorry, SMS is not a valid option for this account. Please try another option.');
                }
            } else {
                # Bad reset method
                $callback = array('status' => false,'method' => $method, 'action' => 'INVALID_METHOD' ,'error' => 'INVALID_METHOD', 'human_error' => 'The application requested an invalid reset method. Please report this error.');

                return $callback;
            }
        }
    }

    public function doUpdatePassword($passwordBlob, $isResetPassword = false)
    {
        /***
         * If the user requested to update their password, do a check on their
         * authentication, then invoke changeUserPassword()
         *
         * @param string|array $passwordBlob If the password is being
         *                                  reset, then $passwordBlob
         *                                  should be an array with the
         *                                  keys "key" and
         *                                  "verify". Otherwise, it should
         *                                  be an array with keys "old"
         *                                  and "new".
         ***/
        try {
            if (!is_array($passwordBlob)) {
                throw(new Exception('Invalid password object (should be array)'));
            }
            if ($isResetPassword === true) {
                try {
                    $emailPassword = $passwordBlob['email_password'] == true;
                    $ua = array(
                        $this->userColumn => $passwordBlob['user'],
                    );
                    $this->setUser($ua);

                    return $this->changeUserPassword($passwordBlob, $emailPassword, true);
                } catch (Exception $e) {
                    # Handle the exception
                    return array('status' => false, 'error' => $e->getMessage(),'human_error' => 'There was an error resetting your password ('.$e->getMessage().').','app_error_code' => 150, 'blob' => $passwordBlob, 'user_set_array' => $ua);
                }
            } else {
                # We're updating, not restting the password.
                try {
                    if (!array_key_exists('old', $passwordBlob) or !array_key_exists('new', $passwordBlob)) {
                        throw(new Exception("Password object requires keys 'old' and 'new'"));
                    }
                    $oldPassword = $passwordBlob['old'];
                    $newPassword = $passwordBlob['new'];

                    return $this->changeUserPassword($oldPassword, $newPassword);
                } catch (Exception $e) {
                    # Handle the exception
                    return array('status' => false, 'error' => $e->getMessage(),'human_error' => 'There was a server error changing your password.','app_error_code' => 151);
                }
            }
        } catch (Exception $e) {
            # All top-level exceptions
            return array('status' => false,'error' => $e->getMessage(),'given' => $passwordBlob,'usingResetPassword' => $isResetPassword);
        }
    }

    private function changeUserPassword($oldPassword, $newPassword = null, $isResetPassword = false)
    {
        /***
         * Replace the password stored.
         * If there are any encrypted fields, decrypt them and re-encrypt them in the process.
         * Trash the encrypted fields if we're resetting.
         * Update the cookies.
         *
         * @param string|array $oldPassword If the password is being
         *                                  reset, then $oldPassword
         *                                  should be an array with the
         *                                  keys "key" and
         *                                  "verify". Otherwise, it should
         *                                  be the plain-text string of
         *                                  the old password.
         * @param string $newPassword If $isResetPassword is true,
         *                            this field can be "true" to
         *                            email the new password.
         *
         * @param bool $isResetPassword Is the password being reset?
         ***/
        try {
            if ($isResetPassword === true) {
                $userdata = $this->getUser();
                if (empty($userdata)) {
                    throw(new Exception('Base user not set'));
                }
                $doEmailPassword = $newPassword === true;
                # We can't verify the old password, so we have to verify the
                # reset token provided under $oldPassword instead
                if (!is_array($oldPassword)) {
                    throw(new Exception('Bad credential format'));
                }
                $key = $oldPassword['key'];
                $verify = $oldPassword['verify'];
                if (empty($key) or empty($verify)) {
                    throw(new Exception('Not all required credentials were provided'));
                }
                # Now, we verify the supplied credentials
                $pw_data = json_decode($userdata[$this->pwColumn], true);
                $salt = $pw_data['salt'];
                # Pull the secret from the temp column
                $secret = $this->getSecret(true);
                $string = self::decryptThis($key, $secret, $this->getIV());
                $test_string = $salt.$string;
                $match_token = substr(hash('md5', $test_string), 0, 8);
                if ($match_token != $verify) {
                    # The computed token doesn't match the provided one
                    // $testPass = "123abc";
                    // $method = self::getPreferredCipherMethod();
                    // $iv = self::getIV();
                    // $testPass = md5($testPass);
                    // $foo = openssl_encrypt("FooBar", $method, $testPass, 0, $iv);
                    // $foo64 = base64_encode($foo);
                    // $bar64 = openssl_decrypt(base64_decode($foo64), $method, $testPass, 0, $iv);
                    // $bar = openssl_decrypt($foo, $method, $testPass, 0, $iv);
                    // $barTrim = rtrim($bar, "\0");
                    // $barTrim64 = rtrim($bar64, "\0");
                    // $testPass = substr($testPass, 0, 8);
                    // $faz = self::encryptThis("FooBar", $testPass, $this->getIV());
                    // $baz = self::decryptThis($faz, $testPass);
                    #throw( new Exception('Invalid reset tokens (got '.$string.' and match '.$match_token.' from '.$salt.' and '.$secret.' [input->'.$key.':'.$verify.' with iv '.$this->getIV().']). Tested '.$foo.' decoding to '.$bar.' with '.$method. " (64: $foo64 to $bar64 to $barTrim64 vs ".$barTrim.") Also $faz -> $baz and " . openssl_error_string() ) );
                    throw( new Exception('Invalid reset tokens') );
                }
                # The token matches -- let's make them a new password and
                # provide it.
                if (!class_exists('Stronghash')) {
                    require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
                }
                $newPassword = self::createRandomUserPassword();
                $hash = new Stronghash();
                $pw1 = $hash->hasher($newPassword);
                $pwStore = json_encode($pw1);
                # We don't need or want to recalculate a hardlink. The old
                # salt isn't used anywhere where the old value is relevant.
                $algo = $pw1['algo'];
                $rounds = $pw1['rounds'];
                # We need to update the "data" column with the $algo and
                # $rounds data
                $data = $userdata['data'];
                $xml = new Xml();
                $xml->setXml($data);
                $data = $xml->updateTag('<rounds>', $this->sanitize($rounds));
                $data = $xml->updateTag('<algo>', $this->sanitize($algo));

                /*
                 * We can't use writeToUser() since it requires user
                 * validation, which we don't have by definition, so we're
                 * going to manually construct the query here.
                 */
                $query = 'UPDATE `'.
                      $this->getTable().'` SET `'.
                      $this->pwColumn.'`="'.
                      $this->sanitize($pwStore, true).'", `data`="'.
                      $data.'" WHERE `'.
                      $this->userColumn."`='".
                      $this->getUsername()."'";
                $l = $this->openDB();
                mysqli_query($l, 'BEGIN');
                $r = mysqli_query($l, $query);
                $finish_query = $r ? 'COMMIT' : 'ROLLBACK';
                $callback = array('status' => $r,'action' => $finish_query,'new_password' => $newPassword, 'new_password_length' => strlen($newPassword), 'minimum_length' => $this->getMinPasswordLength(), 'maximum_length' => 8192);
                if ($finish_query == 'ROLLBACK') {
                    $callback['error'] = mysqli_error($l);
                    $callback['new_password'] = null;
                }

                $r2 = mysqli_query($l, $finish_query);
                $callback['status'] = $r && $r2;
                if ($r2 !== true) {
                    $callback['error'] = 'Unable to commit your password reset';
                }
                if ($callback['status'] === true) {
                    $verifySetPw = $this->lookupUser($this->getUsername(), $newPassword, false);
                    $callback['verification_data'] = $verifySetPw['status'];
                    # It all worked, remove the secret
                    $this->setTempSecret();
                    if ($doEmailPassword === true) {
                        $mail = $this->getMailObject();
                        $mail->Subject = '['.$this->getDomain().'] New Password';
                        $mail->Body = "<p>You've successfully reset the password to ".$this->getDomain().". Here is your new password:.</p><pre>$newPassword</pre><p>If you didn't request a password change, please log in and change your password IMMEDIATELY, and we suggest adding two-factor authentication.</p>.";
                        $mail->addAddress($this->getUsername());
                        $status = $mail->send();
                        $mailDetail = array('status' => $status,'method' => 'email');
                        if (!$status) {
                            $mailDetail['error'] = $mail->ErrorInfo;
                        }
                        $callback['mail_details'] = $mailDetail;
                    }
                }
                $callback['mail_requested'] = $doEmailPassword;

                return $callback;
            } else {
                # We want to look at the current user, and make sure it's OK
                # before re-assigning the password
                $userLookup = $this->lookupUser($this->getUsername(), $oldPassword);
                # If this user checks out, now we can overwrite their old password
                if ($userLookup['status'] === false) {
                    # Bad user
                    throw(new Exception('Invalid original credentials'));
                }
                $currentUser = $userLookup['data'];
                if (strlen($newPassword) < $this->getMinPasswordLength()) {
                    throw(new Exception('New password is too short. It should be at least '.$this->getMinPasswordLenght().' characters'));
                }
                $currentUser = $userLookup['data'];
                if (strlen($newPassword) < $this->getMinPasswordLength()) {
                    throw(new Exception('New password is too short. It should be at least '.$this->getMinPasswordLength().' characters'));
                }
                if (strlen($newPassword) > 8192) {
                    throw(new Exception('New password is too long. It should be less than 8192 characters'));
                }
                if (!class_exists('Stronghash')) {
                    require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
                }
                $hash = new Stronghash();

                $hashedPw = $hash->hasher($newPassword);
                $pwStore = json_encode($hashedPw);
                # We don't need or want to recalculate a hardlink. The old
                # salt isn't used anywhere where the old value is relevant.
                $algo = $hashedPw['algo'];
                $rounds = $hashedPw['rounds'];

                # We need to update the "data" column with the $algo and
                # $rounds data
                $xml = new Xml();
                $xml->setXml($data);
                $data = $currentUser['data'];
                $backupData = $data;
                $backupPassword = $currentUser[$this->pwColumn];
                $data = $xml->updateTag('<rounds>', $this->sanitize($rounds));
                $data = $xml->updateTag('<algo>', $this->sanitize($algo));

                /*
                 * We can't use writeToUser() since it requires user
                 * validation, and the second part of the update will always fail.
                 * So, we're going to manually construct the query here.
                 */
                $l = $this->openDB();

                $query = 'UPDATE `'.
                      $this->getTable().'` SET `'.
                      $this->pwColumn.'`="'.
                      mysqli_real_escape_string($l, $pwStore).'", `data`="'.
                      mysqli_real_escape_string($l, $data).'" WHERE `'.
                      $this->userColumn."`='".
                      $this->getUsername()."'";

                mysqli_query($l, 'BEGIN');
                $r = mysqli_query($l, $query);
                $finish_query = $r ? 'COMMIT' : 'ROLLBACK';
                $callback = array('status' => $r,'action' => $finish_query,'new_password' => $newPassword);
                if ($finish_query == 'ROLLBACK') {
                    $callback['error'] = mysqli_error($l);
                }
                $r2 = mysqli_query($l, $finish_query);
                $callback['status'] = $r && $r2;
                if ($callback['status']) {
                    $verifySetPw = $this->lookupUser($this->getUsername(), $newPassword, false);
                    $callback['verification_data'] = $verifySetPw['status'];
                    if (!$verifySetPw['status']) {
                        # verify setting with a lookup
                        # if bad, revert to old
                        # if reset, try again
                        $revert = array();
                        $query2 = 'UPDATE `'.
                                $this->getTable().'` SET `'.
                                $this->pwColumn.'`="'.
                                $backupPassword.'", `data`="'.
                                $backupData.'" WHERE `'.
                                $this->userColumn."`='".
                                $this->getUsername()."'";
                        mysqli_query($l, 'BEGIN');
                        $r = mysqli_query($l, $query2);
                        $finish_query = $r ? 'COMMIT' : 'ROLLBACK';
                        $revert['action'] = $finish_query;
                        if ($finish_query == 'ROLLBACK') {
                            $revert['error'] = mysqli_error($l);
                        }
                        $r2 = mysqli_query($l, $finish_query);
                        $revert['status'] = $r && $r2;
                        $revert['debug'] = array(
                            'new_data' => $data,
                            'new_password' => $pwStore,
                            'original_query' => $query,
                            'restored_to' => $backupPassword,
                            'old_data' => $backupData,
                        );
                        $callback['revert_status'] = $revert;
                        $callback['original_status'] = $callback['status'];
                        $callback['status'] = false;
                    }
                }

                return $callback;
            }
        } catch (Exception $e) {
            # Bad user
            throw(new Exception('Invalid user credentials - '.$e->getMessage()));
        }
    }

    public function removeThisAccount($username, $password, $totp = false)
    {
        /***
         * Remove a user account
         *
         * @param string username the same username as this object's
         * @param string password the user's password
         * @param int totp the TOTP code
         * @return array
         ***/
        $userdata = $this->getUser();
        if ($this->getUsername() != $username) {
            return array('status' => false,'error' => 'Nonmatching names');
        }
        $l = $this->openDB();
        if (is_numeric($totp)) {
            if (!class_exists('Stronghash')) {
                require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
            }
            $key = Stronghash::createSalt();
            $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='$key' WHERE `".$this->userColumn."`='".$this->getUsername()."'";
            $r = mysqli_query($l, $query);
            if ($r === false) {
                throw(new Exception('Unable to encrypt password'));
            }
            # Play nice with lookupUser
            $encrypted_pw = self::encryptThis($key, $pw, $this->getIV());
            $lookup = $this->lookupUser($username, $encrypted_pw, false, $totp, true);
        } else {
            $lookup = $this->lookupUser($username, $password, false, $totp, true);
        }
        if ($lookup[0] !== true) {
            return array('status' => false,'error' => 'Bad lookup','lookup' => $lookup);
        }
        # This is the same user the object was called on, and they're
        # logged in validly
        $query = 'DELETE FROM `'.$this->getTable().'` '.$this->getUserWhere().' LIMIT 1';
        $status = mysqli_query($l, $query);
        if ($status !== true) {
            return array('status' => $status,'error' => mysqli_error($l));
        } else {
            return array('status' => $status);
        }
    }

    public function forceDeleteCurrentUser($confirm = false) {
        /***
         * Deletes a user. Does no checks in the process.
         *
         * @param bool $confirm -> must be true to execute
         ***/
        if (!$confirm) {
            return array(
                "status" => false,
                "error" => "CONFIRM_FLAG_NOT_SET",
                "target_user" => $this->getHardlink(),
            );
        }
        $l = $this->openDB();
        $targetHardlink = $this->getHardlink();
        $userWhere = $this->getUserWhere();
        $query = 'DELETE FROM `'.$this->getTable().'` '.$userWhere.' LIMIT 1';
        $status = mysqli_query($l, $query);
        if ($status !== true) {
            return array('status' => $status,'error' => mysqli_error($l), "target_user" => $targetHardlink, "selector" => $userWhere);
        } else {
            return array('status' => $status, "deleted_user" => $targetHardlink, "selector" => $userWhere);
        }
    }

    public function getAuthTokens($target_user = null, $secret_key = null)
    {
        /***
     * Get the authorization key for this user
     *
     * @param array target_user set the target user with 'col'=>'val'
     * @param string secret_key set the secret key, if desired
     * @return array with the used secret key in "secret", and result
     * in "auth"
     ***/
    $this->setUser($target_user);
        $target_userdata = $this->getUser($target_user);
        if ($target_userdata['flag'] != false) {
            return array('status' => false,'message' => 'Already activated','target_user' => $target_user,'target_userdata' => $target_userdata);
        }
    # The user needs it, let's make one
    $return = array();
        $userString = $target_userdata['creation'].$this->getUsername();
    # We'll use a secret key that is never kept on the server
    if (empty($secret_key)) {
        if (!class_exists('Stronghash')) {
            require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
        }
        $secret_key = base64_encode(Stronghash::createSalt(strlen($userString)));
    }
        $return['secret'] = $secret_key;
        $auth_code = $secret_key ^ $userString;
        $auth_result = sha1($auth_code);
        $return['auth'] = $auth_result;
        $return['user'] = $target_userdata[$this->linkColumn];
        $return['target_user'] = $target_user;
        $return['status'] = true;

        return $return;
    }

    public function requireUserAuth($user_email)
    {
        /***
     * Set up the flags and verification tokens to disable a user until the authorization flag is passed
     * Note that if this function fails, the user is still
     * flagged. The flag must be clared manually.
     *
     * If you're using Amazon AWS, see this:
     * http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-domains.html
     *
     * @param string $user_email User identifier
     * @return array
     ***/
    # Look at the 'flag' item
    $target_user = $this->getUser(array($this->userColumn => $user_email));
        $components = $this->getAuthTokens($target_user[$this->linkColumn]);
    # Pull in the configuration files
    include dirname(__FILE__).'/../CONFIG.php';
        $url = !isset($login_url) ? 'login.php' : $login_url;
        $rel_dir = str_replace($relative_path, '', $working_subdirectory);
        if (substr($rel_dir, -1) != '/' && !empty($rel_dir)) {
            $rel_dir = $rel_dir.'/';
        }
        $link = $this->getQualifiedDomain().$rel_dir.$url.'?confirm=true&token='.$components['auth'].'&user='.$components['user'].'&key=';
    # get all the administrative users, and encrypt the key with their
    # user DB link

    $mail_subject = '['.$this->getDomain().'] New User - Authentication Needed';
        $success = false;
    # Loop through all the admins ....
    $l = $this->openDB();
        $query = 'SELECT `'.$this->userColumn.'`, `'.$this->linkColumn.'` FROM '.$this->getTable().' WHERE `admin_flag`=TRUE';
        $r = mysqli_query($l, $query);
        $i = 0;
        $j = 0;
        if ($r === false) {
            return array('status' => false,'error' => 'No valid administrators to use this function');
        }
        $errors = array();
        $destinations = array();
        while ($row = mysqli_fetch_row($r)) {
            $to = $row[0];
            if (!empty($to)) {
                # If there are valid admins, we want to say it succeeded
            # whether or not it did
            $success = true;
            }
            $dblink = $row[1];
            $cryptkey = self::encryptThis($dblink, $components['secret'], $this->getIV());
            $encoded_key = urlencode(base64_encode($cryptkey));
            $admin_link = $link.$encoded_key;
            $destinations[] = array('to' => $to,'key' => $encoded_key,'crypted' => $cryptkey,'encrypted_with' => $dblink,'emailed_link' => $admin_link);
            $mail = $this->getMailObject();
            $mail->Subject = $mail_subject;
            $body = '<p>'.$user_email.' is requesting access to '.$this->getDomain().".</p><p>To authorize them, clik this link:</p><p><a href='".$admin_link."'>Click here to authorize ".$user_email.'</a></p><p>Thank you. This message will only work for '.$to.'.</p>';
            $mail->Body = $body;
            $mail->addAddress($to);
        # If this works even once, we want to tell the user it worked
        if ($mail->send()) {
            # if ($success === false) $success = true;
            ++$i;
        } else {
            $errors[$to] = $mail->ErrorInfo;
            $lasterror = $mail->ErrorInfo;
        }
            ++$j;
        }
        if (sizeof($destinations) == 0) {
            $errors = array('message' => 'No valid destinations','rows' => mysqli_num_rows($r));
        }

        return array('status' => $success,'mailer' => array('emails_sent' => $i,'attempts_made' => $j,'errors' => $errors,'destinations' => $destinations,'last_error' => $lasterror),'config_meta' => array('ref_config' => dirname(__FILE__).'/../CONFIG.php','working_dir' => $working_subdirectory,'url' => $url),'user' => array('user_email' => $user_email,'target_user' => $target_user[$this->linkColumn],'user_set_params' => array($this->userColumn => $user_email)),'components' => $components);
    }

    public function verifyUserAuth($encoded_key, $token, $target_user)
    {
        /***
     * If a user needs to be authorized before being allowed access,
     * check the authorization token here and update the flag
     * Note that the user calling this themselves must be an
     * administrator, or the function will fail.
     *
     ***/
    $ret = array();
        try {
            $thisUserStatus = $this->validateUser(true);
            $thisUserdata = $thisUserStatus['userdata'];
            $thisUserEmail = $thisUserdata[$this->usercol];
            if ($thisUserStatus['status'] !== true) {
                throw(new Exception("You're not logged in as a valid user."));
            }
            if (boolstr($thisUserdata['admin_flag']) !== true) {
                throw(new Exception("You must be logged in with an administrative user account to authorize a new user (logged in as '".$thisUserEmail."' )."));
            }
        } catch (Exception $e) {
            $cookielink = $this->domain.'_link';
            $altcookielink = str_replace('.', '_', $this->domain).'_link';
            $ucookielink = empty($_COOKIE[$cookielink]) ? $altcookielink : $cookielink;

            return array('status' => false,'error' => $e->getMessage(),'message' => 'Please log in before attempting to authenticate a user: '.$e->getMessage(),'cookie' => $ucookielink,'value' => $_COOKIE[$ucookielink],'userdata' => $thisUserdata, 'userstatus' => $thisUserStatus);
        }
        $thisUserEmail = $thisUserdata[$this->userColumn];
        $target_user = array($this->linkColumn => $target_user);
        try {
            $userdata = $this->getUser($target_user);
        } catch (Exception $e) {
            return array('status' => false,'error' => $e->getMessage(),'message' => 'Bad target user','target' => $target_user);
        }
    # Is the user already authorized?
    if ($userdata['flag']) {
        $ret['status'] = true;
        $ret['message'] = 'Already authenticated';

        return $ret;
    }
        $working_key = base64_decode(urldecode($encoded_key));
        $key = self::decryptThis($thisUserdata[$this->linkColumn], $working_key, $this->getIV());
        $components = $this->getAuthTokens($target_user, $key);
        $primary_token = $components['auth'];
        if ($primary_token != $token) {
            $ret['status'] = false;
            $ret['message'] = 'Bad token';
            $ret['provided_token'] = $token;
        /* $ret['encoded_key'] = urldecode($encoded_key); */
        /* $ret['key_to_decrypt'] = $working_key; */
        /* $ret['decryption_user'] = $userdata[$this->linkColumn]; */
        /* $ret['decrypted_key'] = $key; */
        $ret['components'] = $components;

            return $ret;
        }
        $l = $this->openDB();
        $query = 'UPDATE `'.$this->getTable().'` SET `flag`=TRUE WHERE `'.$this->linkColumn."`='".$target_user[$this->linkColumn]."'";
        $r = mysqli_query($l, $query);
        if ($r === false) {
            $ret['status'] = false;
            $ret['message'] = 'MySQL error';
            $ret['error'] = 'MySQL error: '.mysqli_error($l);
        } else {
            $ret['status'] = true;
        }
        $mail = $this->getMailObject();

    # Let the user know
    $mail->Subject = 'Authorization granted to '.$this->getDomain();
        $mail->Body = '<p>Your access to '.$this->getDomain()." as been enabled. <a href='".$this->getQualifiedDomain()."'>Click here to visit the site</a>.";
        $userMail = $mail;
        $userMail->addAddress($userdata[$this->userColumn]);
        $user = $userMail->send();
        if ($user) {
            $ret['user_confirm_sent'] = true;
        } else {
            $ret['user_confirm_sent'] = false;
            $ret['error'] .= ' User: '.$userMail->ErrorInfo;
        }
    # Send out an email to admins saying that they've been authorized.
    $query = 'SELECT `'.$this->userColumn.'` FROM '.$this->getTable().' WHERE `admin_flag`=TRUE';
        $r = mysqli_query($l, $query);
        $mail = $this->getMailObject();
        $mail->Subject = '['.$this->getDomain().'] New User Authenticated';
        $mail->Body = '<p>'.$userdata[$this->userColumn].' was granted access to '.$this->getDomain().' by '.$thisUserEmail.'.</p><p>No further action is required, and you can disregard emails asking to grant this user access.</p><p><strong>If you believe this to be in error, immediately take steps to take your site offline</strong></p>';
        while ($row = mysqli_fetch_row($r)) {
            $to = $row[0];
            $mail->addAddress($to);
        }
        if ($mail->send()) {
            $ret['admin_confirm_sent'] = true;
        } else {
            $ret['admin_confirm_sent'] = false;
            $ret['error'] .= ' Admin: '.$mail->ErrorInfo;
        }

        return $ret;
    }

    public function textUser($message, $strict = true)
    {
        /***
     * Send a message to a user
     *
     * @param string $message
     * @return twilio message object
     * @throws exception when user can't SMS
     ***/
    if ($this->canSMS($strict)) {
        try {
            require_once dirname(__FILE__).'/../twilio/Services/Twilio.php';
            $client = new Services_Twilio($this->getTwilioSID(), $this->getTwilioToken());

            return $client->account->messages->sendMessage($this->getTwilioNumber(), $this->getPhone(), $message);
        } catch (Exception $e) {
            throw(new Exception('Could not SMS - '.$e->getMessage()));
        }
    } else {
        throw(new Exception('This user has no phone number'));
    }
    }

    public function verifyPhone($auth_code = null)
    {
        /***
     * Verify the phone with a random code
     *
     * @param string $auth_code
     * @return array
     ***/
    if (!$this->canSMS(false)) {
        # Twilio is not configured, or there's an illegal phone number
        if (self::isValidPhone($this->getPhone())) {
            throw(new Exception('SMS is not properly configured. Check your CONFIG.'));
        } else {
            return array('status' => false,'error' => 'Bad phone','human_error' => "We don't have a valid phone number to text a message to!",'fatal' => true);
        }
    }
        $u = $this->getUser();
        if ($u['phone_verified'] == true) {
            return array('status' => false,'is_good' => true,'error' => 'Number already authorized','human_error' => "You've already verified this phone number");
        }
        if (empty($auth_code)) {
            # The setup is complete, send it
        return $this->textUserVerify();
        } else {
            # Check it
        $l = $this->openDB();
            $query = 'SELECT `'.$this->tmpColumn.'` FROM `'.$this->getTable().'` WHERE `'.$this->userColumn."`='".$this->getUsername()."'";
            $r = mysqli_query($l, $query);
            if ($r === false) {
                throw(new Exception('Error reading from database: '.mysqli_error($l)));
            }
            $row = mysqli_fetch_row($r);
            $db_code = $row[0];
            if ($db_code == $auth_code) {
                # Set verified to true, and empty the special
            $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='', `phone_verified`=true WHERE `".$this->userColumn."`='".$this->getUsername()."'";
                mysqli_query($l, 'BEGIN');
                $r = mysqli_query($l, $query);
                if ($r === false) {
                    $error = mysqli_error($l);
                    mysqli_query($l, 'ROLLBACK');
                    throw(new Exception("Error updating databse: $error"));
                }
                mysqli_query($l, 'COMMIT');

                return array('status' => true,'message' => 'Phone number confirmed','is_good' => true);
            } else {
                # Do it again
            return $this->textUserVerify();
            }
        }
    }

    private function textUserVerify()
    {
        /***
     * Send a text message to a user's stored phone, and
     * save the authentication string provided.
     *
     * @return array with the twilio object in key "twilio"
     ***/
        if (!class_exists('Stronghash')) {
            require_once dirname(__FILE__).'/../core/stronghash/php-stronghash.php';
        }
        $auth = Stronghash::createSalt(8);
    # Write auth to tmpcol
    $query = 'UPDATE `'.$this->getTable().'` SET `'.$this->tmpColumn."`='$auth' WHERE `".$this->userColumn."`='".$this->getUsername()."'";
        $l = $this->openDB();
        $r = mysqli_query($l, $query);
        if ($r === false) {
            throw(new Exception('Could not prepare authorization code - '.mysqli_error($l)));
        }
        $auth_string = "Thanks for verifying! Enter the following into your current page:\n$auth";
    # Text it to the user; set the strict flag to false
    $obj = $this->textUser($auth_string, false);

        return array('status' => true,'message' => 'Check your phone for your authorization code.','twilio' => $obj);
    }

    private function getUserSeed($seedColumn = 'random_seed', $verbose = false)
    {
        # For legacy setups, make sure the random_seed column is there
        $r = $this->addColumn($seedColumn, 'varchar(255)');
        if ($r['status'] === true
            ||
            ($r['status'] === false && $r['error'] == 'COLUMN_EXISTS')) {
            # Get the seed!
            try {
                $u = $this->getUser();
                if (!empty($u[$seedColumn])) {
                    return $u[$seedColumn];
                }
                $criteria = array($this->linkColumn => $this->getHardlink());
                $seed = Stronghash::createSalt().Stronghash::genUnique(96);
                $entry = array(
                    $seedColumn => $seed,
                );
                try {
                    $r = $this->updateEntry($entry, $criteria);
                    if ($r !== true) {
                        if ($verbose) {
                            return $r;
                        }

                        return false;
                    }

                    return $seed;
                } catch (Exception $e) {
                    if ($verbose) {
                        return $e->getMessage();
                    }

                    return false;
                }
            } catch (Exception $e) {
                # Not created yet
                return Stronghash::createSalt().Stronghash::genUnique(96);
            }
        }
        # No column, and couldn't create it
        if ($verbose) {
            return 'NOT_EXIST_CANT_CREATE';
        }

        return false;
    }


    private static function getPreferredCipherMethod()
    {
        /***
         * Get the best functional OpenSSL cipher method.
         *
         * Should only be called in contexts that the library's
         * presence is already checked.
         *
         * @return string The cipher method that encodes and decodes
         * best, correctly on the client machine.
         ***/
        # TODO method to determine best cipher method
        $methods = openssl_get_cipher_methods();
        $testPass = "123abc";
        $testString = "FooBar";
        $testIV = sha1($testString);
        $testMethods = array(
            'AES-256-CBC-HMAC-SHA1',
            "AES-128-CBC-HMAC-SHA1",
            "AES-256-CBC",
            "AES-192-CBC",
            "AES-128-CBC",
        );
        foreach($testMethods as $method) {
            $iv = self::getIV($testIV, $method);
            $foo = openssl_encrypt($testString, $method, $testPass, 0, $iv);
            $bar = openssl_decrypt($foo, $method, $testPass, 0, $iv);
            if ($testString == $bar) {
                return $method;
            }
        }
    }

    public function getIV($base = null, $method = null) {
        /***
         *
         ***/
        if (empty($base)) $base = $this->getUserSeed();
        if (empty($method)) $method = self::getPreferredCipherMethod();
        $length = openssl_cipher_iv_length($method);
        while(strlen($base) < $length) {
            $base .= hash("sha512", $base);
        }
        $iv = substr($base, 0, $length);
        return $iv;
    }

    public static function encryptThis($key, $string, $iv = '')
    {
        /***
         * @param string $key
         * @param string $string
         * @param string $iv -> Initialization value
         * @return string An encrypted, base64-encoded result
         ***/

        $cipherkey = md5($key);
        # For native functions here, no "same-string" data should
        # be stored, so we just want SOMETHING
        if (empty($iv)) {
            $iv = sha1($cipherkey);
        }
        if (function_exists(openssl_encrypt)) {
            $method = self::getPreferredCipherMethod();
            # http://us3.php.net/manual/en/function.openssl-encrypt.php
            $encrypted = openssl_encrypt($string, $method, $cipherkey, 0, $iv);
        } elseif (function_exists(mcrypt_encrypt)) {
            $encrypted = mcrypt_encrypt(MCRYPT_RIJNDAEL_256, $cipherkey, $string, MCRYPT_MODE_CBC, $iv);
        } else {
            # Well .... let's not fail, at least.
            $encrypted = $string;
        }
        $encrypted = base64_encode($encrypted);

        return $encrypted;
    }

    public static function decryptThis($key, $encrypted, $iv = '')
    {
        /***
     * @param string $key
     * @param string $encrypted A base 64 encoded string
     * @param string $iv -> Initialization value
     * @return string The decrypted string
     ***/
        $decoded = base64_decode($encrypted);
        $cipherkey = md5($key);
        # For native functions here, no "same-string" data should
        # be stored, so we just want SOMETHING
        if (empty($iv)) {
            $iv = sha1($cipherkey);
        }
        if (function_exists(openssl_decrypt)) {
            $method = self::getPreferredCipherMethod();
            # http://us3.php.net/manual/en/function.openssl-decrypt.php
            $decrypted = openssl_decrypt($decoded, $method, $cipherkey, 0, $iv);
        } elseif (function_exists(mcrypt_decrypt)) {
            $decrypted = mcrypt_decrypt(MCRYPT_RIJNDAEL_256, $cipherkey, $decoded, MCRYPT_MODE_CBC, $iv);
        } else {
            # Well, damn. Let's not fail at any rate.
            $decrypted = $encrypted;
        }
        # Remove any padding before returning
        return rtrim($decrypted, "\0");
    }

    public function decryptWithStoredKey($encrypted)
    {
        /***
     * @param string $encrypted A base 64 encoded string
     * @return string|bool decrypted string or false
     ***/
    $this->getUser();
        if (!empty($this->userColumn)) {
            $l = $this->openDB();
            $query = 'SELECT `'.$this->tmpColumn.'` FROM `'.$this->getTable().'` WHERE `'.$this->userColumn."`='".$this->username."'";
            $r = mysqli_query($l, $query);
            if ($r === false) {
                throw(new Exception('Could not get decryption key -- '.mysqli_error($l)));
            }
            $row = mysqli_fetch_row($r);
            $key = $row[0];
            $string = self::decryptThis($key, $encrypted, $this->getIV());

            return $string;
        }

        return false;
    }
}
