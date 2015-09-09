<?php

/***
 * Cross-Site Hasher. Will always return most secure hash possible.
 *Documentation and use is at https://github.com/tigerhawkvok/php-stronghash
 ***/

class stronghash
{
    public function __construct()
    {
        $this->default_rounds = 10000;
    }

    private function getDefaultRounds()
    {
        try {
            if (is_numeric($this->default_rounds)) {
                return $this->default_rounds;
            }
            throw new Exception('Non-numeric rounds');
        } catch (Exception $e) {
            return 10000;
        }
    }

    public function hasher($data, $salt = null, $use = null, $forcesalt = true, $rounds = null)
    {
        /***
     * Creates a hash with the most secure algo on the server, and
     * returns the result with the parameters to verify included
     ***/
    $rounds = preg_match('/^([0-9]+)$/', $rounds) ? $this->getDefaultRounds() : $rounds;
        if (!is_numeric($rounds) || $rounds < 1000) {
            $rounds = 10000;
        }
        $userset = empty($use) ? false : true;
        $cryptgo = false;
        $use_crypt = strpos($use, 'crypt') !== false ? true : false;
        $use_pbkdf2 = strpos($use, 'pbkdf2') !== false ? true : false;
        $simplerounds = strpos($use, '-multi') !== false ? true : false;
        $nonnative = strpos($use, '-nn') !== false ? true : false;
        if ($salt == null && $forcesalt === true) {
            $salt = self::genUnique();
        }
        if (function_exists('hash')) {
            // All more advanced algos also mean that hash() can be used
        $list = hash_algos();
            if (empty($use)) {
                # manually iterate through common inclusions and prefer
            # in order
            # We can't just break every time, in case the list is not
            # in order.
            foreach ($list as $algo) {
                if ($algo == 'sha512') {
                    $use = $algo;
                    break;
                }
                if ($algo == 'sha384') {
                    $use = $algo;
                }
                if ($algo == 'sha256') {
                    if ($use != 'sha384') {
                        $use = $algo;
                    }
                }
                if ($algo == 'sha224') {
                    if ($use != 'sha384' && $use != 'sha256') {
                        $use = $algo;
                    }
                }
            }
            }
            if (!empty($use)) {
                if (!empty($salt)) {
                    if ($use_crypt) {
                        $use = str_replace('crypt', '', $use);
                    }
                    if ($use_pbkdf2) {
                        $use = str_replace('pbkdf2', '', $use);
                    }
                // test crypt() usability
                if ((CRYPT_SHA512 == 1 && $use == 'sha512') || (CRYPT_SHA256 == 1 && $use == 'sha256')) {
                    $cryptgo = true;
                } elseif (CRYPT_BLOWFISH == 1) {
                    $cryptgo = true;
                    $use = 'blowfish';
                } elseif ($use_crypt) {
                    return array('status' => false,'error' => "Crypt was required but the requested algorithm $use isn't available");
                }

                // run PBKDF2 if present
                if (function_exists('hash_pbkdf2') && !$use_crypt && !$nonnative) {
                    return array('status' => true,'hash' => hash_pbkdf2($use, $data, $salt, $rounds),'salt' => $salt,'algo' => $use.'pbkdf2','rounds' => $rounds);
                } elseif (function_exists('crypt') && ($use_crypt || !$userset) && $cryptgo) {
                    $data = urlencode($data);
                    switch ($use) {
                      case 'sha512':
                        $salt = substr($salt, 0, 16);
                        $ss = "\$6\$rounds=$rounds\$".$salt."\$";
                        break;
                      case 'sha256':
                        $salt = substr($salt, 0, 16);
                        $ss = "\$5\$rounds=$rounds\$".$salt."\$";
                        break;
                      case 'blowfish':
                        $salt = substr(sha1($salt), 0, 22);
                        $ss = "\$2a\$07\$".$salt."\$";
                        break;
                      default:
                        $ss = false;
                      }
                    if ($ss !== false) {
                        // do crypt
                        $result = crypt($data, $ss);
                        $result_small = explode("\$", $result);
                        $size = sizeof($result_small);
                        $result_small = $result_small[$size - 1]; // trim the extra data in case the user wants an unadulterated hash.
                        return array('hash' => $result_small,'full_hash' => $result,'salt' => $salt,'algo' => $use.'crypt','rounds' => $rounds,'string' => $ss);
                    } // End crypt cases. Now all sophisticated algorithms supported by the system have been exhausted. Use basic hasher.
                    else {
                        // if this block was executed at the user request, only crypt() should have run.
                        if ($userset) {
                            return array('status' => false,'error' => "Unable to use $use in crypt().",'algo' => $use);
                        }
                        try {
                            # try non-native implmentation of pbkdf2
                            try {
                                $hash = self::pbkdf2(str_replace('-nn', '', $use), $data, $salt, $rounds, 128);
                            } catch (Exception $e) {
                                return array('status' => false,'error' => 'selfpbkdf2 error','use' => $use);
                                #$e->getMessage());
                            }

                            return array('status' => true,'hash' => $hash,'salt' => $salt,'algo' => $use.'pbkdf2-nn','rounds' => $rounds);
                        } catch (Exception $e) {
                            if (function_exists('hash_hmac') && strpos($use, 'hmac') !== false) {
                                return array('status' => true,'hash' => hash_hmac($use, $salt.$data, $salt),'salt' => $salt,'algo' => $use.'_hmac');
                            } elseif (!function_exists('hash_hmac') && strpos($use, 'hmac') !== false) {
                                return array('status' => false,'error' => 'hmac was required, but no such function exists.','algo' => $use);
                            }
                        }
                        $string = $salt.$data;
                        for ($i = 0;$i < $rounds;++$i) {
                            // a very very basic multi-round hash
                            $string = hash($use, sha1($string).$string);
                        }

                        return array('status' => true,'hash' => $string,'salt' => $salt,'algo' => $use.'-multi','rounds' => $rounds);
                    }
                } // End using crypt
                elseif (!function_exists('crypt') && $use_crypt) {
                    return array('status' => false,'error' => 'Crypt was required, but no such function exists.','algo' => $use);
                } elseif ((!function_exists('hash_pbkdf2') && ($use_pbkdf2 || !$userset)) || ($use_pbkdf2 && $nonnative)) {
                    try {
                        // try non-native implmentation of pbkdf2
                        // echo "Using $use 2";
                        $hash = self::pbkdf2(str_replace('-nn', '', $use), $data, $salt, $rounds, 128);

                        return array('status' => true,'hash' => $hash,'salt' => $salt,'algo' => $use.'pbkdf2-nn','rounds' => $rounds);
                    } catch (Exception $e) {
                        if ($use_pbkdf2) {
                            return array('status' => false,'error' => $e->getMessage(),'algo' => $use);
                        }
                    }
                } elseif (strpos($use, 'pbkdf2-nn') !== false) {
                    // echo "Using $use 3 ".str_replace("pbkdf2-nn","",$use);
                    $hash = self::pbkdf2(str_replace('pbkdf2-nn', '', $use), $data, $salt, $rounds, 128);

                    return array('hash' => $hash,'salt' => $salt,'algo' => $use,'rounds' => $rounds);
                }
                // we've walked through all instances of crypt and pbkdf2 by now
                if (function_exists('hash_hmac') && !$simplerounds) {
                    if ($userset && strpos($use, '_hmac') !== false) {
                        return array('status' => true,'hash' => hash_hmac(str_replace('hmac', '', $use), $salt.$data, $salt),'salt' => $salt,'algo' => $use);
                    }
                    if (!$userset) {
                        return array('status' => true,'hash' => hash_hmac($use, $salt.$data, $salt),'salt' => $salt,'algo' => $use.'hmac');
                    }
                } elseif (!function_exists('hash_hmac') && strpos($use, 'hmac') !== false && $userset) {
                    return array('status' => false,'error' => 'hmac was required, but the function does not exist','algo' => $use);
                } elseif ($simplerounds) {
                    // implies user set

                    $string = $salt.$data;
                    for ($i = 0;$i < $rounds;++$i) {
                        try {
                            // a very very basic multi-round hash
                            $string = hash($use, sha1($string).$string);
                        } catch (Exception $e) {
                            return array('status' => false,'error' => 'All available hashing methods have been exhausted, and none are compatible with your system.');
                        }
                    }

                    return array('status' => true,'hash' => $string,'salt' => $salt,'algo' => $use.'-multi','rounds' => $rounds);
                } else {
                    return array('status' => true,'hash' => hash($use, $salt.$data),'salt' => $salt,'algo' => $use);
                }
                } // End salt-requring functions
            else {
                return array('status' => true,'hash' => hash($use, $salt.$data),'salt' => $salt,'algo' => $use,'method' => 'hash');
            }
            } // End search for supported hash algos
        else {
            return array('status' => true,'hash' => sha1($salt.$data),'salt' => $salt,'algo' => 'sha1','method' => 'No algo');
        }
        } // End hash() supported
      else {
          return array('status' => true,'hash' => sha1($salt.$data),'salt' => $salt,'algo' => 'sha1','method' => 'hash() not supported');
      }

        return array('status' => false,'error' => 'Error in function!','provided' => array('data' => $data,'salt' => $salt,'use' => $use,'forcesalt' => $forcesalt,'rounds' => $rounds));
    }

    public static function genUnique($len = 128, $hash = true)
    {
        /***
     * Very slow unique string generator. Pings random.org, so it WILL impact load time.
     * Uses PHP rand(), computer time, current URL, best sha hash, and a true random value from random.org
     ***/
    $id1 = self::createSalt();
        $id2 = self::microtime_float();
        $id3 = rand(0, 10000000000);
        $id4_1 = self::createSalt(64);
        $id4_2 = $_SERVER['request_uri'];
        $id4_3 = self::microtime_float();
        $id4_4 = $id4_1.$id4_2.$id4;
        $id4 = sha1($id4_4.self::createSalt(128));
    // random.org input
    try {
        $rurl = 'http://www.random.org/strings/?num=1&len=20&digits=on&upperalpha=on&loweralpha=on&format=plain&rnd=new';
        $string = file_get_contents($rurl);
    } catch (Exception $e) {
        $string = '';
    }
        $seed = $string.$id1.$id2.$id3.$id4;
        if ($hash) {
            $hash = hash('sha512', $seed);

            return substr($hash, 0, $len);
        } else {
            return substr($seed, 0, $len);
        }
    }

    public static function createSalt($length = 32, $add_entropy = null, $do_secure = true)
    {
        if (@include_once('sources/csprng/support/random.php') !== false && $do_secure) {
            // Do this cryptographically securely
        try {
            $rng = new CSPRNG();
            $salt = $rng->GenerateString($length);
        } catch (Exception $e) {
            // run this again, not securely to escape the error
            self::createSalt($length, $add_entropy, false);
        }
        } else {
            // Don't give up the ghost, try something that's not quite as good
        $id1 = uniqid(mt_rand(), true);
            $id2 = md5(date('dDjlSwzWFmMntLYayABgGhiHsOZ'));
            $id3 = crc32(self::curPageURL());
            $charset = "!@#~`%^&*()-_+={}|[]:;'<>?,./";
            $repeats = rand(0, 64);
            $i = 0;
            $csl = strlen($charset);
            while ($i < $repeats) {
                $pos = rand(0, $csl - 1);
                $id4 = substr($charset, $pos, 1);
                ++$i;
            }
            $salt = sha1($id2.$id1.$id3.$id4.$add_entropy); // add extra entropy if provided.
        $len = strlen($salt);
            if ($length > $len) {
                $length = $len;
            }
            $diff = strlen($salt) - $length;
            $offset = rand(0, $diff);
            $salt = substr($salt, $offset, $length);
        }

        return $salt;
    }

    public static function microtime_float()
    {
        list($usec, $sec) = explode(' ', microtime());

        return ((float) $usec + (float) $sec);
    }

    private static function curPageURL()
    {
        $pageURL = 'http';
        if ($_SERVER['HTTPS'] == 'on') {
            $pageURL .= 's';
        }
        $pageURL .= '://';
        if ($_SERVER['SERVER_PORT'] != '80') {
            $pageURL .= $_SERVER['SERVER_NAME'].':'.$_SERVER['SERVER_PORT'].$_SERVER['REQUEST_URI'];
        } else {
            $pageURL .= $_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
        }

        return $pageURL;
    }

    private static function strbool($bool)
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

    public function verifyHash($hash, $orig_data, $orig_salt = null, $orig_algo = null, $orig_rounds = null, $debug = false)
    {
        $was_array = false;
        if (is_array($orig_data)) {
            $was_array = true;
            $refhash = $orig_data;
            $orig_salt = $orig_data['salt'];
            $orig_algo = $orig_data['algo'];
            $orig_rounds = preg_match('/^([0-9]+)$/', $orig_data['rounds']) ? $orig_data['rounds'] : $this->getDefaultRounds(); // natural number
        $orig_data = $orig_data['hash'];
        } else {
            $refhash = array('hash' => $orig_data,'salt' => $orig_salt,'algo' => $orig_algo,'rounds' => $orig_rounds);
        } //$this->hasher($orig_data,$orig_salt,$orig_algo,false,$orig_rounds);
    if (strlen($orig_data) != strlen($hash) && !is_array($hash)) {
        $base_args = array('data' => $hash,'salt' => $orig_salt,'algo' => $orig_algo,'forcesalt' => false,'rounds' => $orig_rounds);
        $hash = $this->hasher($hash, $orig_salt, $orig_algo, false, $orig_rounds);
        $hash_compare = $hash['hash'];
    } elseif (is_array($hash)) {
        $hash_compare = $hash['hash'];
    } else {
        $hash_compare = $hash;
    }

        if ($debug === true) {
            $match = $hash_compare == $refhash['hash'];
            $match_slow = self::slow_equals($hash_compare, $refhash['hash']);

            return array('pw_hashed' => $refhash['hash'],'pw_compare' => $hash_compare,'data' => $refhash,'match' => $match,'slow_match' => $match_slow,'computed_hash' => array('computed' => $hash,'args' => $base_args),'was_array' => $was_array);
        }

        if (!isset($refhash[0]) || $refhash[0] !== false) {
            return self::slow_equals($hash_compare, $refhash['hash']);
        } else {
            return false;
        }
    }

/*
 * Password hashing with PBKDF2.
 * Original Author: havoc AT defuse.ca
 * www: https://defuse.ca/php-pbkdf2.htm
 */

// Compares two strings $a and $b in length-constant time.
  private static function slow_equals($a, $b)
  {
      $diff = strlen($a) ^ strlen($b);
      for ($i = 0; $i < strlen($a) && $i < strlen($b); ++$i) {
          $diff |= ord($a[$i]) ^ ord($b[$i]);
      }

      return $diff === 0;
  }

/*
 * PBKDF2 key derivation function as defined by RSA's PKCS #5: https://www.ietf.org/rfc/rfc2898.txt
 * $algorithm - The hash algorithm to use. Recommended: SHA256
 * $password - The password.
 * $salt - A salt that is unique to the password.
 * $count - Iteration count. Higher is better, but slower. Recommended: At least 1000.
 * $key_length - The length of the derived key in bytes.
 * $raw_output - If true, the key is returned in raw binary format. Hex encoded otherwise.
 * Returns: A $key_length-byte key derived from the password and salt.
 *
 * Test vectors can be found here: https://www.ietf.org/rfc/rfc6070.txt
 *
 * This implementation of PBKDF2 was originally created by https://defuse.ca
 * With improvements by http://www.variations-of-shadow.com
 */
  private static function pbkdf2($algorithm, $password, $salt, $count, $key_length, $raw_output = false)
  {
      $algorithm = strtolower($algorithm);
      if (!in_array($algorithm, hash_algos(), true)) {
          throw(new Exception('PBKDF2 ERROR: Invalid hash algorithm "'.$algorithm.'"'));
      }
      if ($count <= 0 || $key_length <= 0) {
          throw(new Exception('PBKDF2 ERROR: Invalid parameters.'));
      }

      $hash_length = strlen(hash($algorithm, '', true));
      $block_count = ceil($key_length / $hash_length);

      $output = '';
      for ($i = 1; $i <= $block_count; ++$i) {
          // $i encoded as 4 bytes, big endian.
      $last = $salt.pack('N', $i);
      // first iteration
      $last = $xorsum = hash_hmac($algorithm, $last, $password, true);
      // perform the other $count - 1 iterations
      for ($j = 1; $j < $count; ++$j) {
          $xorsum ^= ($last = hash_hmac($algorithm, $last, $password, true));
      }
          $output .= $xorsum;
      }

      if ($raw_output) {
          return substr($output, 0, $key_length);
      } else {
          return bin2hex(substr($output, 0, $key_length));
      }
  }
}
