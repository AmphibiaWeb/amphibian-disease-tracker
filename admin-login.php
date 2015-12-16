<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Amphibian Disease Portal Admin</title>
    <meta http-equiv="Content-Type" content="application/xhtml+xml;charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="chrome=1" />
    <meta name="theme-color" content="#445e14"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
    <link href="https://fonts.googleapis.com/css?family=Droid+Sans:400,700|Droid+Sans+Mono|Roboto:400,100,300,500,700,100italic,300italic,400italic,500italic,700italic" rel='stylesheet' type='text/css'/>
    <script src="bower_components/webcomponentsjs/webcomponents-lite.min.js"></script>

    <link rel="import" href="bower_components/polymer/polymer.html"/>
    <link rel="import" href="bower_components/font-roboto/roboto.html"/>
    <link rel="import" href="bower_components/paper-spinner/paper-spinner.html"/>
    <link rel="import" href="bower_components/paper-toast/paper-toast.html"/>
    <link rel="import" href="bower_components/neon-animation/neon-animation.html"/>
    <link rel="import" href="polymer-elements/copyright-statement.html"/>
    <link rel="import" href="polymer-elements/glyphicon-social-icons.html"/>

    <link rel="stylesheet" type="text/css" href="bower_components/bootstrap/dist/css/bootstrap.min.css"/>
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <script type="text/javascript" src="bower_components/bootstrap/dist/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="js/purl.min.js"></script>
    <script type="text/javascript" src="js/xmlToJSON.min.js"></script>
    <script type="text/javascript" src="bower_components/js-base64/base64.min.js"></script>
    <script type="text/javascript" src="bower_components/picturefill/dist/picturefill.min.js"></script>
    <script type="text/javascript" src="js/c.min.js"></script>
  </head>
  <body>
    <?php
       $debug = false;
       if($debug) {
           echo "<div class='alert alert-danger'><strong>Warning:</strong> Debugging is enabled on admin-login.php</div>";
           ini_set("error_log","/usr/local/web/amphibian_disease/error-admin.log");
           ini_set("display_errors",1);
           ini_set("log_errors",1);
           error_reporting(E_ALL);
           // $string = "Foobar";
           // $pass = "123";
           // $methods = print_r(openssl_get_cipher_methods(), true);
           // $encrypted = openssl_encrypt($string, "AES-256-CBC", $pass);
           // $decrypted = openssl_decrypt($encrypted, "AES-256-CBC", $pass);
           // $encrypt_test = "<pre>OpenSSL Encrypt Test: \n\n $methods \n\n $encrypted \n\n $decrypted</pre>";
           // echo $encrypt_test;
       }
       require_once("DB_CONFIG.php");
       require_once("admin/login.php");
       echo $login_output;
       ?>
  </body>
</html>
