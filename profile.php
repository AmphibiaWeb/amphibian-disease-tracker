<!DOCTYPE html>
<html>
  <head>
    <?php
$debug = false;

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('Profile Browser is running in debug mode!');
}

$print_login_state = false;
require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
require_once dirname(__FILE__).'/admin/async_login_handler.php';
$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);

$as_include = true;
# The next include includes core, and DB_CONFIG, and sets up $db
# require_once(dirname(__FILE__)."/admin-api.php");

$loginStatus = getLoginState();

$viewUserId = $db->sanitize($_GET['id']);
if(empty($viewUserId) && $loginStatus["status"]) {
    $viewUserId = $loginStatus["detail"]["userdata"]["dblink"];
    # echo "<!-- ".print_r($loginStatus, true)."\n\n Using $viewUserId -->";
}
$setUser = array("dblink" => $viewUserId);
# echo "<!-- Setting user \n ".print_r($setUser, true) . "\n -->";
$selfUser = new UserFunctions();
$selfUserId = $selfUser->getHardlink();
$viewUser = new UserFunctions($viewUserId, "dblink");
$validUser = true;
$userdata = array();
$realProfileImagePath = "users/profiles/default.png";
$realProfileImagePathXS = "users/profiles/default.png";
$realProfileImagePathSM = "users/profiles/default.png";
try {
    $userdata = $viewUser->getUser($setUser);
    if(!is_array($userdata)) $userdata = array();
    if(empty($userdata["dblink"])) throw(new Exception("Bad User"));
    $profileImagePath = "users/profiles/" . $viewUserId;
    $extensions = array("bmp", "jpg", "jpeg", "png", "gif");
    foreach($extensions as $ext) {
        $testPath = realpath($profileImagePath . "." . $ext);
        echo "\n\n<!-- Testing path '" . $testPath . "' --> ";
        if(file_exists($testPath)) {
            $realProfileImagePath = $profileImagePath . "." . $ext;
            $realProfileImagePathXS = $profileImagePath . "-xs." . $ext;
            $realProfileImagePathSM = $profileImagePath . "-sm." . $ext;
            break;
        }
    }
    # else echo "<!-- Got data \n ".print_r($userdata, true) . "\n -->";
    #$nameXml = $userdata["name"];
    #$xml = new Xml();
    #$xml->setXml($nameXml);
    #$title = $xml->getTagContents("name");
    $title =  (!empty($_REQUEST["search"]) || $_REQUEST["mode"] == "search" || empty($viewUserId)) ? "User Search":$viewUser->getName();
} catch (Exception $e) {
    $validUser = false;
    $title = (!empty($_REQUEST["search"]) || $_REQUEST["mode"] == "search" || empty($viewUserId)) ? "User Search":"No Such User";
}


$isLoggedIn = $loginStatus['status'];
$isPublic = !$isLoggedIn;
$isMember = $isLoggedIn;
$isCollaborator = false;

       ?>
    <title>Profile - <?php echo $title; ?></title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta charset="UTF-8"/>
    <meta name="theme-color" content="#445e14"/>
    <meta name="viewport" content="width=device-width, minimum-scale=1, initial-scale=1" />

    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
    <link rel="stylesheet" type="text/css" href="bower_components/json-human/css/json.human.css" />
    <link rel="prerender" href="https://amphibiandisease.org/project.php" />
    <link href="https://fonts.googleapis.com/css?family=Droid+Sans:400,700|Droid+Sans+Mono|Roboto:400,100,300,500,700,100italic,300italic,400italic,500italic,700italic" rel='stylesheet' type='text/css'/>

    <link rel="icon" type="image/png" sizes="16x16" href="assets/favicon16.png" />
    <link rel="icon" type="image/png" sizes="32x32" href="assets/favicon32.png" />
    <link rel="icon" type="image/png" sizes="64x64" href="assets/favicon64.png" />
    <link rel="icon" type="image/png" sizes="128x128" href="assets/favicon128.png" />
    <link rel="icon" type="image/png" sizes="256x254" href="assets/favicon256.png" />
    <link rel="icon" type="image/png" sizes="512x512" href="assets/favicon512.png" />
    <link rel="icon" type="image/png" sizes="1024x1024" href="assets/favicon1024.png" />

    <script src="bower_components/webcomponentsjs/webcomponents-lite.min.js"></script>

    <link rel="import" href="bower_components/polymer/polymer.html"/>


    <link rel="import" href="bower_components/paper-toggle-button/paper-toggle-button.html"/>
    <link rel="import" href="bower_components/paper-checkbox/paper-checkbox.html"/>
    <link rel="import" href="bower_components/paper-toast/paper-toast.html"/>
    <link rel="import" href="bower_components/paper-input/paper-input.html"/>
    <link rel="import" href="bower_components/paper-spinner/paper-spinner.html"/>
    <link rel="import" href="bower_components/paper-slider/paper-slider.html"/>
    <link rel="import" href="bower_components/paper-menu/paper-menu.html"/>
    <link rel="import" href="bower_components/paper-card/paper-card.html"/>

    <link rel="import" href="bower_components/paper-dialog/paper-dialog.html"/>
    <link rel="import" href="bower_components/paper-radio-group/paper-radio-group.html"/>
    <link rel="import" href="bower_components/paper-radio-button/paper-radio-button.html"/>

    <link rel="import" href="bower_components/paper-dialog-scrollable/paper-dialog-scrollable.html"/>
    <link rel="import" href="bower_components/paper-button/paper-button.html"/>
    <link rel="import" href="bower_components/paper-icon-button/paper-icon-button.html"/>
    <link rel="import" href="bower_components/paper-fab/paper-fab.html"/>
    <link rel="import" href="bower_components/paper-item/paper-item.html"/>
    <link rel="import" href="bower_components/paper-material/paper-material.html"/>

    <link rel="import" href="bower_components/gold-email-input/gold-email-input.html"/>
    <link rel="import" href="bower_components/gold-phone-input/gold-phone-input.html"/>
    <link rel="import" href="bower_components/gold-zip-input/gold-zip-input.html"/>

    <link rel="import" href="bower_components/iron-form/iron-form.html"/>
    <link rel="import" href="bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html"/>

    <link rel="import" href="bower_components/font-roboto/roboto.html"/>
    <link rel="import" href="bower_components/iron-label/iron-label.html"/>
    <link rel="import" href="bower_components/iron-icons/iron-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/image-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/social-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/communication-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/editor-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/maps-icons.html"/>

    <link rel="import" href="bower_components/neon-animation/neon-animation.html"/>

    <link rel="import" href="bower_components/marked-element/marked-element.html"/>

    <link rel="import" href="bower_components/google-map/google-map.html"/>
    <link rel="import" href="bower_components/google-map/google-map-marker.html"/>
    <link rel="import" href="bower_components/google-map/google-map-poly.html"/>

    <link rel="import" href="polymer-elements/copyright-statement.html"/>
    <link rel="import" href="polymer-elements/glyphicon-social-icons.html"/>


    <script type="text/javascript">
      (function(){var p=[],w=window,d=document,e=f=0;p.push('ua='+encodeURIComponent(navigator.userAgent));e|=w.ActiveXObject?1:0;e|=w.opera?2:0;e|=w.chrome?4:0;
      e|='getBoxObjectFor' in d || 'mozInnerScreenX' in w?8:0;e|=('WebKitCSSMatrix' in w||'WebKitPoint' in w||'webkitStorageInfo' in w||'webkitURL' in w)?16:0;
      e|=(e&16&&({}.toString).toString().indexOf("\n")===-1)?32:0;p.push('e='+e);f|='sandbox' in d.createElement('iframe')?1:0;f|='WebSocket' in w?2:0;
      f|=w.Worker?4:0;f|=w.applicationCache?8:0;f|=w.history && history.pushState?16:0;f|=d.documentElement.webkitRequestFullScreen?32:0;f|='FileReader' in w?64:0;
      p.push('f='+f);p.push('r='+Math.random().toString(36).substring(7));p.push('w='+screen.width);p.push('h='+screen.height);var s=d.createElement('script');
      s.src='bower_components/whichbrowser/detect.php?' + p.join('&');d.getElementsByTagName('head')[0].appendChild(s);})();
      /*window.onerror = function(e) {
      console.warn("Error thrown: "+e);
      return true;
      }*/
    </script>
    <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4"></script>
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
    <script type="text/javascript" src="bower_components/bootstrap/dist/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="js/purl.min.js"></script>
    <script type="text/javascript" src="js/xmlToJSON.min.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js"></script>
    <script type="text/javascript" src="js/jquery.cookie.min.js"></script>
    <script type="text/javascript" src="bower_components/js-base64/base64.min.js"></script>
    <script type="text/javascript" src="bower_components/picturefill/dist/picturefill.min.js"></script>
    <script type="text/javascript" src="bower_components/imagelightbox/dist/imagelightbox.min.js"></script>
    <script type="text/javascript" src="bower_components/JavaScript-MD5/js/md5.min.js"></script>
    <script type="text/javascript" src="bower_components/json-human/src/json.human.js"></script>
    <script type="text/javascript" src="bower_components/zeroclipboard/dist/ZeroClipboard.min.js"></script>
    <script type="text/javascript" src="js/c.min.js"></script>
    <script type="text/javascript" src="js/profile.min.js"></script>
    <script type="text/javascript">
      // Initial script
    </script>
    <style is="custom-style">
      paper-toggle-button.red {
      --paper-toggle-button-checked-bar-color:  var(--paper-red-500);
      --paper-toggle-button-checked-button-color:  var(--paper-red-500);
      --paper-toggle-button-checked-ink-color: var(--paper-red-500);
      }
      paper-input[disabled], paper-input[readonly] {
      --paper-input-container-focus-color: var(--paper-orange-500);
      --paper-input-container-underline: var(--paper-grey-300);
      --paper-input-container-underline-disabled: var(--paper-grey-300);
      }
    </style>
  </head>
  <body class="container-fluid">
    <header id="header-bar" class="fixed-bar clearfix row">
      <p class="col-xs-12 login-status-bar text-right">
        <?php
           $user = $_COOKIE['amphibiandisease_fullname'];

           if ($isLoggedIn) {
               ?>
        Logged in as <span class='header-bar-user-name'><?php echo $user;
               ?></span>
        <paper-icon-button icon="icons:dashboard" class="click" data-href="https://amphibiandisease.org/admin-page.html" data-toggle="tooltip" title="Administration Dashboard" data-placement="bottom"> </paper-icon-button>
        <paper-icon-button icon='icons:settings-applications' class='click' data-href="https://amphibiandisease.org/admin" data-toggle="tooltip" title="Account Settings" data-placement="bottom"></paper-icon-button>
        <?php

           } else {
               ?>
        <paper-icon-button icon="icons:exit-to-app" class="click" data-toggle="tooltip" title="Login" data-href="https://amphibiandisease.org/admin" data-placement="bottom"></paper-icon-button>
        <?php

           }
               ?>
        <paper-icon-button icon="icons:language" class="click" data-toggle="tooltip" title="Project Browser" data-href="https://amphibiandisease.org/project.php" data-placement="bottom"> </paper-icon-button>
        <paper-icon-button icon="icons:account-box" class="click" data-toggle="tooltip" title="Profiles" data-href="https://amphibiandisease.org/profile.php" data-placement="bottom"> </paper-icon-button>

        <paper-icon-button icon="icons:home" class="click" data-href="https://amphibiandisease.org/home.php" data-toggle="tooltip" title="Home" data-placement="bottom"></paper-icon-button>
      </p>
    </header>
    <main>
      <?php
         if ($validUser && !( !empty($_REQUEST["search"]) || $_REQUEST["mode"] == "search" )) {
             $isViewingSelf = $viewUserId == $selfUserId;
             # Helper setup
             $baseStructuredData = array(
                 "place" => array(
                     "name" => "",
                     "street_number" => "",
                     "street" => "",
                     "country_code" => "",
                     "zip" => "",
                     "department" => "",
                     "department_phone" => "",
                 ),
                 "social" => array(
                     "twitter" => "",
                     "google_plus" => "",
                     "linkedin" => "",
                     "facebook" => "",
                     "other" => array(),
                 ),
                 "profile" => "",
                 "privacy" => array(
                     "phone" => array(
                         "public" => false,
                         "members" => false,
                         "collaborators" => false,
                     ),
                     "department_phone" => array(
                         "public" => false,
                         "members" => false,
                         "collaborators" => false,
                     ),
                     "email" => array(
                         "public" => false,
                         "members" => false,
                         "collaborators" => false,
                     ),
                 ),

             );
             # Fetch the structured data for the profile
             $structuredData = $baseStructuredData;
             # Fetch and overwrite keys
             $profile = $viewUser->getProfile();
             if(is_array($profile)) {
                 $structuredData = array_merge($structuredData, $profile);
             }
             $place = $structuredData["place"];
             $social = $structuredData["social"];
             $bio = $structuredData["profile"];
             $privacyConfig = $structuredData["privacy"];
             # Helper captcha function
             $hasIncludedCaptcha = false;
             require_once 'admin/CONFIG.php';
             function getCaptchaData($dataType = "email") {
                 /***
                  *
                  ***/
                 global $hasIncludedCaptcha, $recaptcha_public_key;
                 if(!$hasIncludedCaptcha) {
                     echo '<script src="https://www.google.com/recaptcha/api.js" async defer></script>';
                     $hasIncludedCaptcha = true;
                 }
                 $html = '<div class="g-recaptcha col-xs-8" data-sitekey="'.$recaptcha_public_key.'" data-callback="renderCaptchas" data-type="'.$dataType.'"></div>';
                 return $html;

             }

             # Helper function
             function getElement($fillType, $fill = "", $class = "row", $forceReadOnly = false, $required = false) {
                 /***
                  * Get a given public_profile element type and return
                  * it, based on context.
                  ***/
                 global $isViewingSelf;
                 # Title case and replace _ with " " on fillType
                 $fillType = ucwords($fillType);
                 $dataSource = str_replace(" ", "_", strtolower($fillType));
                 $addClass = " " . str_replace(" ", "-", strtolower($fillType));
                 $emptyFill = false;
                 if(empty($fill)) {
                     $emptyFill = true;
                     if(!$isViewingSelf) $fill = "Not Provided";
                     $class .= " no-data-provided";
                 }
                 $class .= $addClass;
                 $requiredText = $required ? "required" : "";
                 if($isViewingSelf && !$forceReadOnly) {
                     # Should be an editable field
                     $elType = "paper-input";
                     if(strpos($class, "phone") !== false) $elType = "gold-phone-input";
                     if(strpos($class, "zip") !== false) $elType = "gold-zip-input";
                     if(strpos($class, "google_plus") !== false) {
                         $fill = str_replace(" ", "+", $fill);
                     }
                     if(strpos($class, "address") === false) {
                         $element = "<div class='profile-input profile-data $class' data-value='$fill'><$elType class='user-input col-xs-12' value='$fill' label='$fillType' auto-validate data-source='$dataSource' $requiredText></$elType></div>";
                     } else {
                         # Address input
                         global $place;
                         $element = "<div class='profile-input profile-data row address street-number'>
  <paper-input class='user-input col-xs-12'
               type='number'
value='".$place["street_number"]."'
               label='Street Number' data-source='street-number'
               auto-validate></paper-input>
</div>
<div class='profile-input profile-data row address street'>
  <paper-input class='user-input col-xs-12'
               label='Street Name' data-source='street'
value='".$place["street"]."'
               required
               auto-validate></paper-input>
</div>
<div class='profile-input profile-data row address country-code'>
  <paper-input class='user-input col-xs-12'
               label='Country Code' data-source='country-code'
value='".$place["country_code"]."'
               maxlength='2'
               required
               auto-validate></paper-input>
</div>
<div class='profile-input profile-data row address zip'>
  <gold-zip-input class='user-input col-xs-12'
               label='ZIP code' data-source='zip'
value='".$place["zip"]."'
               required
               auto-validate></gold-zip-input>
</div>";
                     }
                 } else {
                     # Not viewing self
                     if(strpos($class, "social") !== false) {
                         if(!$emptyFill) {
                             $link = $fill;
                             $link = str_replace(" ", "+", $link);
                             if(strpos($class, "facebook") !== false) {
                                 $icon = '    <paper-fab mini class="click glyphicon" icon="glyphicon-social:facebook" data-href="'.$link.'" newtab="true"></paper-fab>';
                             } else if(strpos($class, "google-plus") !== false) {
                                 $icon = '    <paper-fab mini class="click glyphicon" icon="glyphicon-social:google-plus" data-href="'.$link.'" newtab="true"></paper-fab>';
                             } else if(strpos($class, "twitter") !== false) {
                                 $icon = '    <paper-fab mini class="click glyphicon" icon="glyphicon-social:twitter" data-href="'.$link.'" newtab="true"></paper-fab>';
                             } else if(strpos($class, "linkedin") !== false) {
                                 $icon = '    <paper-fab mini class="click glyphicon" icon="glyphicon-social:linkedin" data-href="'.$link.'" newtab="true"></paper-fab>';
                             } else {
                                 $icon = "";
                             }
                             $element = "<div class='profile-bio-group profile-data $class'>$icon</div>";
                         }
                     } else {
                         # Not social
                         # Some special cases
                         if(strpos($class, "phone") !== false) {
                             # Wrap in phone wrapper
                             $fill = "<span class='phone-number'>$fill</span>";
                         }
                         $fillKey = strtolower(str_replace(" ", "_", $fillType));
                         global $privacyConfig, $isCollaborator, $isMember, $isPublic;
                         if(array_key_exists($fillKey, $privacyConfig)) {
                             # We need to respect privacy settings
                             $dataClass = $fillType == "email" ? "col-xs-6":"col-xs-8";
                             $button = $fillType == "email" ? "<paper-fab mini icon='' class='materialblue do-mailto' data-email='$fill'></paper-fab>":"";
                             if ($isCollaborator) {
                                 $willShare = $privacyConfig[$fillKey]["collaborator"];
                                 if($willShare) {
                                     $element = "<div class='profile-bio-group profile-data $class'><label class='col-xs-4 capitalize'>$fillType</label><p class='$dataClass'>$fill</p>$button</div>";
                                 }
                             } else if ($isMember) {
                                 $willShare = $privacyConfig[$fillKey]["member"];
                                 if($willShare) {
                                     $element = "<div class='profile-bio-group profile-data $class'><label class='col-xs-4 capitalize'>$fillType</label><p class='$dataClass'>$fill</p>$button</div>";
                                 }
                             } else {
                                 # Public
                                 $willShare = $privacyConfig[$fillKey]["public"];
                                 if($willShare) {
                                     # Hide behind a captcha
                                     if(!$emptyFill) {
                                         $fill = getCaptchaData($fillKey);
                                     }
                                     $element = "<div class='profile-bio-group profile-data $class'><label class='col-xs-4 capitalize'>$fillType</label>$fill</div>";
                                 }
                             }
                             if(!$willShare) {
                                 $element = "";
                             }

                         } else {
                             # General case, not a special element
                             $element = "<div class='profile-bio-group profile-data $class'><label class='col-xs-4 capitalize'>$fillType</label><p class='col-xs-8'>$fill</p></div>";
                         }
                     }
                 }
                 return $element;
             }

             # Set up terms
             if($isViewingSelf) {
               $title = "You ($title)";
               $titlePossessive = "Your";
             }
             else {
               $titlePossessive = $title . "'s";
             }
             function getPublishableData() {
                 global $structuredData, $privacyConfig, $isCollaborator, $isMember, $isPublic;
                 $publishedStructuredData = $structuredData;
                 foreach($privacyConfig as $category=>$config) {
                     # Check permissions
                     if($isCollaborator) {
                         $willShare = $config["collaborator"];
                     } else if ($isMember) {
                         $willShare = $config["member"];
                     } else {
                         $willShare = $config["public"];
                     }
                     if(!$willShare) {
                         unset($publishedStructuredData["place"][$category]);
                     }
                 }
                 return $publishedStructuredData;
             }
             ?>
      <h1 id="title">User Profile - <?php echo $title ?></h1>
      <section id="main-body" class="row">
        <paper-fab id="enter-search" icon="icons:search" class="click" data-href="?mode=search" data-toggle="tooltip" title="Search Profiles"></paper-fab>
        <script type="text/javascript">
          window.publicProfile = <?php echo json_encode($structuredData); ?>;
          window.isViewingSelf = <?php echo strbool($isViewingSelf); ?>;
          window.profileUid = "<?php echo $viewUserId; ?>";
        </script>
        <?php if($isViewingSelf) { ?>
        <div class="col-xs-12 self-link">
          <div class="form-group">
            <div class="col-xs-10 col-sm-8 col-md-6">
              <div class="input-group">
                <iron-icon icon="icons:link"></iron-icon>
                <?php
                   $profileLink = "https://amphibiandisease.org/profile.php?id=" . $viewUser->getHardlink();
                   ?>
                <paper-input label="Profile Link" id="profile-link-field" readonly value="<?php echo $profileLink; ?>"/>
              </div>
            </div>
            <div class="fab-wrapper col-xs-2">
              <paper-fab icon="icons:content-copy" class="materialblue" id="copy-profile-link" data-clipboard-text="<?php echo $profileLink; ?>" data-toggle="tooltip" title="Copy Link"></paper-fab>
            </div>
          </div>
        </div>
        <?php } ?>
        <div id="basic-profile" class="col-xs-12 col-md-6 profile-region" data-source="social">
          <h3>Basic Profile</h3>
          <style type="text/css">
            #profile-image-uploader {
            background: url('<?php echo $viewUser->getuserPicture(); ?>') no-repeat center center;
            }
          </style>
          <div id="upload-container-section" hidden>

          </div>
          <div class="row profile-image-container">
            <img class="profile-image img-responsive"
                 id="user-profile-image"
                 src="<?php echo $realProfileImagePathXS; ?>"
                 srcset="<?php echo $realProfileImagePath; ?> 1024w, <?php echo $realProfileImagePathSM; ?> 512w, <?php echo $realProfileImagePathXS; ?> 128w"
                 alt="Profile image" />
            <?php if($isViewingSelf) { ?>
            <button class="btn btn-default col-xs-12 col-md-6 col-lg-3" id="expose-uploader">
              Change Profile Image
            </button>
            <?php } ?>
          </div>

          <?php echo getElement("name", $viewUser->getName(), "row", true); ?>
          <?php
             $dateCreated = date("d F Y", $userdata["creation"]);
             echo getElement("user since", $dateCreated, "row", true); ?>
          <?php echo getElement("email", $viewUser->getUsername(), "row", true); ?>
          <?php echo getElement("phone", $viewUser->getPhone(), "row from-base-profile"); ?>
          <?php echo getElement("twitter", $social["twitter"], "row social twitter"); ?>
          <?php echo getElement("google plus", $social["google_plus"], "row social google_plus"); ?>
          <?php echo getElement("linkedin", $social["linkedin"], "row social linkedin"); ?>
          <?php echo getElement("facebook", $social["facebook"], "row social facebook"); ?>
        </div>
        <div id="institution-profile" class="col-xs-12 col-md-6 profile-region" data-source="institution">
          <h3>Institution Information</h3>
          <?php echo getElement("institution", $place["name"]); ?>
          <?php echo getElement("department", $place["department"]); ?>
          <div class="profile-data address">
            <address
               data-number="<?php echo $place['street_number']; ?>"
               data-street="<?php echo $place['street']; ?>"
               data-country="<?php echo $place['country_code']; ?>"
               data-zip="<?php echo $place['zip']; ?>"
               >
              <?php echo getElement("address", $place["street_number"] ." ". $place["street"]); ?>
            </address>
          </div>
          <?php echo getElement("department phone", $place["department_phone"]); ?>

        </div>
        <div id="bio-profile" class="col-xs-12 profile-region" data-source="profile">
          <h3><?php echo $titlePossessive; ?> Bio</h3>
          <?php
             $bio = str_replace("\\n", "\n", $bio);
             if(!$isViewingSelf) {
                if(empty($bio)) $bio = "*No profile provided*";
                ?>
          <marked-element>
            <div class="markdown-html"></div>
            <script type="text/markdown"><?php echo $bio; ?></script>
          </marked-element>
          <?php } else { ?>
          <iron-autogrow-textarea label="Profile Text" placeholder="Any profile bio text you'd like. Markdown accepted." value="<?php echo $bio; ?>" rows="5" class="user-input"></iron-autogrow-textarea>
          <?php } ?>
        </div>
      </section>
        <?php
           # Section for self
           function boolToChecked($group, $privacyKey) {
               global $privacyConfig;
               $boolValueStr = $privacyConfig[$group][$privacyKey];
               $bool = toBool($boolValueStr);
               return $bool ? "checked" : "";

           }
             if($isViewingSelf) {
           ?>
        <section class="row" data-source="privacy">
          <h3 class="col-xs-12">Privacy Settings</h3>
          <div class="privacy-group col-xs-12 col-md-4" data-group="email">
            <h4>Email Visibility</h4>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="public-visibility" data-scope="public" <?php echo boolToChecked("email", "public"); ?> data-level="0">Visible</paper-toggle-button>
                <span>Public Visibility</span>
              </iron-label>
            </div>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="member-visibility" data-scope="member" <?php echo boolToChecked("email", "member"); ?> data-level="1">Visible</paper-toggle-button>
                <span>ADP Member Visibility</span>
              </iron-label>
            </div>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="collaborator-visibility" data-scope="collaborator" <?php echo boolToChecked("email", "collaborator"); ?> data-level="2">Visible</paper-toggle-button>
                <span>Collaborator Visibility</span>
              </iron-label>
            </div>
          </div>
          <div class="privacy-group col-xs-12 col-md-4" data-group="phone">
            <h4>Phone Number Visibility</h4>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="public-visibility" data-scope="public" <?php echo boolToChecked("phone", "public"); ?> data-level="0">Visible</paper-toggle-button>
                <span>Public Visibility</span>
              </iron-label>
            </div>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="member-visibility" data-scope="member" <?php echo boolToChecked("phone", "member"); ?> data-level="1">Visible</paper-toggle-button>
                <span>ADP Member Visibility</span>
              </iron-label>
            </div>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="collaborator-visibility" data-scope="collaborator" <?php echo boolToChecked("phone", "collaborator"); ?> data-level="2">Visible</paper-toggle-button>
                <span>Collaborator Visibility</span>
              </iron-label>
            </div>
          </div>
          <div class="privacy-group col-xs-12 col-md-4" data-group="department_phone">
            <h4>Department Phone Number Visibility</h4>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="public-visibility" data-scope="public"  <?php echo boolToChecked("department_phone", "public"); ?> data-level="0">Visible</paper-toggle-button>
                <span>Public Visibility</span>
              </iron-label>
            </div>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="member-visibility" data-scope="member" <?php echo boolToChecked("department_phone", "member"); ?> data-level="1">Visible</paper-toggle-button>
                <span>ADP Member Visibility</span>
              </iron-label>
            </div>
            <div class="privacy-toggle">
              <iron-label>
                <paper-toggle-button class="collaborator-visibility" data-scope="collaborator" <?php echo boolToChecked("department_phone", "collaborator"); ?> data-level="2">Visible</paper-toggle-button>
                <span>Collaborator Visibility</span>
              </iron-label>
            </div>
          </div>
        </section>
        <div class="row">
          <div class="col-xs-12">
            <button class="btn btn-success pull-right" id="save-profile" disabled>
              <iron-icon icon="icons:save"></iron-icon>
              Save Changes to Profile
            </button>
          </div>
        </div>
        <section class="row conversations" hidden>
          <h3 class="col-xs-12">
            Conversations (maybe tabbed with profile view?)
          </h3>
          <div class="conversation-part-container col-xs-12 col-md-6 col-lg-3">
            <div class="conversation-list">
              <ul>
                <li>
                  User
                </li>
                <li>
                  Conversation
                </li>
                <li>
                  List
                </li>
                <li>
                  User
                </li>
                <li>
                  Conversation
                </li>
                <li>
                  List
                </li>
                <li>
                  User
                </li>
                <li>
                  Conversation
                </li>
                <li>
                  List
                </li>
              </ul>
            </div>
          </div>
          <div class="conversation-part-container col-xs-12 col-md-6 col-lg-9">
            <div class="user-conversation">
              <ol>
                <li class="from-me">
                  Hello, how are you
                </li>
                <li class="to-me">
                  I am fine how are you?
                </li>
                <li class="from-me">
                  quite well
                </li>
                <li class="from-me">
                  I like to respond
                </li>
                <li class="from-me">
                  Hello, how are you
                </li>
                <li class="to-me">
                  I am fine how are you?
                </li>
                <li class="from-me">
                  quite well
                </li>
                <li class="from-me">
                  I like to respond
                </li>
                <li class="from-me">
                  Hello, how are you
                </li>
                <li class="to-me">
                  I am fine how are you?
                </li>
                <li class="from-me">
                  quite well
                </li>
                <li class="from-me">
                  I like to respond
                </li>
                <li class="from-me">
                  Hello, how are you
                </li>
                <li class="to-me">
                  I am fine how are you?
                </li>
                <li class="from-me">
                  quite well
                </li>
                <li class="from-me">
                  I like to respond
                </li>
              </ol>
            </div>
            <div class="chat-entry-container form-horizontal">
              <div class="form-group">
                <div class="col-xs-10">
                  <input id="compose-message" type="text" class="form-control" placeholder="Type your message ..." />
                </div>
                <div class="col-xs-2 text-center">
                  <paper-icon-button icon="icons:send" class="send-chat" data-toggle="tooltip" title="Send Message"></paper-icon-button>
                </div>
              </div>
            </div>
          </div>
        </section>
        <?php
             } # End self section
             else {
           ?>
        <section class="row misc">
        </section>
           <?php
             }
           ?>
      <?php
         } elseif ( empty( $viewUserId ) || !empty($_REQUEST["search"]) || $_REQUEST["mode"] == "search") {
             ?>
      <h1 id="title">User Search</h1>
      <section id="main-body" class="row">
        <div class="col-xs-12 col-md-4 pull-right">
          <div class="form-horizontal">
            <div class="search-profile form-group">
              <label for="profile-search" class="col-xs-12 col-md-5 col-lg-4 control-label">Search Profiles</label>
              <div class="col-xs-12 col-md-7 col-lg-8">
                <input type="text" class="form-control" placeholder="Profile ID or name..." name="profile-search" id="profile-search"/>
              </div>
            </div>
          </div>
          <paper-radio-group selected="names" id="search-filter">
            <paper-radio-button name="names" data-cols="name,username,alternate_email" data-cue="Name, handle, or email...">
              Name / Email
            </paper-radio-button>
            <paper-radio-button name="institution" data-cols="public_profile" data-cue="Institution name">
              Institution
            </paper-radio-button>

          </paper-radio-group>
        </div>
        <ul id="profile-result-container" class="col-xs-12 col-md-8">
          <li>Enter a search to the right to find users</li>
        </ul>
      </section>
      <?php } elseif (!$validUser) { ?>


      <h1 id="title">Invalid User</h1>
      <section id="main-body" class="row">
        <blockquote class="force-center-block col-xs-12 col-md-8 col-lg-6">
          <div>
            <p>It's like it's been erased.</p>
            <p>Erased ... from existence</p>
          </div>
          <footer>
            Marty &amp; Doc Brown, <cite title="Back to the Future">Back to the Future</cite>
          </footer>
        </blockquote>
        <p class="col-xs-12">
          No one is here. You can go back to safety
          and <a href="profile.php">view your own profile</a>.
        </p>
      </section>
      <?php
         } # / not valid user
         ?>
    </main>
    <footer class="row">
      <div class="col-md-7 col-xs-12">
        <copyright-statement copyrightStart="2015">AmphibiaWeb &amp; AmphibianDisease.org</copyright-statement>
      </div>
      <div class="col-md-1 col-xs-4">
        <paper-icon-button icon="icons:chrome-reader-mode" class="click" data-href="https://amphibian-disease-tracker.readthedocs.org" data-toggle="tooltip" title="Documentation" data-newtab="true"></paper-icon-button>
      </div>
      <div class="col-md-1 col-xs-4">
        <paper-icon-button icon="glyphicon-social:github" class="click" data-href="https://github.com/AmphibiaWeb/amphibian-disease-tracker" data-toggle="tooltip" title="Visit us on GitHub" data-newtab="true"></paper-icon-button>
      </div>
      <div class="col-md-1 col-xs-4">
        <paper-icon-button icon="icons:bug-report" class="click" data-href="https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/new" data-toggle="tooltip" title="Report an issue" data-newtab="true"></paper-icon-button>
      </div>
      <div class="col-md-2 col-xs-6 hidden-xs">
        Written with <paper-icon-button icon="icons:polymer" class="click" data-href="https://www.polymer-project.org" data-newtab="true"></paper-icon-button>
      </div>
    </footer>
  </body>
</html>
