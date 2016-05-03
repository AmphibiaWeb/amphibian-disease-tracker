<!DOCTYPE html>
<html>
  <head>
    <?php
$debug = false;

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('Project Browser is running in debug mode!');
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
    echo "<!-- ".print_r($loginStatus, true)."\n\n Using $viewUserId -->";
}
$setUser = array("dblink" => $viewUserId);
echo "<!-- Setting user \n ".print_r($setUser, true) . "\n -->";
$selfUser = new UserFunctions();
$selfUserId = $selfUser->getHardlink();
$viewUser = new UserFunctions($viewUserId, "dblink");
$validUser = true;
$userdata = array();
try {
    $userdata = $viewUser->getUser($setUser);
    if(!is_array($userdata)) $userdata = array();
    if(empty($userdata["dblink"])) throw(new Exception("Bad User"));
    else echo "<!-- Got data \n ".print_r($userdata, true) . "\n -->";
    $nameXml = $userdata["name"];
    $xml = new Xml();
    $xml->setXml($nameXml);
    $title = $xml->getTagContents("name");
} catch (Exception $e) {
    $validUser = false;
    $title = "No Such User";
}



       ?>
    <title>Profile - <?php echo $title; ?></title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta charset="UTF-8"/>
    <meta name="theme-color" content="#445e14"/>
    <meta name="viewport" content="width=device-width, minimum-scale=1, initial-scale=1" />

    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
    <link rel="stylesheet" type="text/css" href="bower_components/json-human/css/json.human.css" />
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

    <link rel="import" href="bower_components/iron-form/iron-form.html"/>
    <link rel="import" href="bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html"/>

    <link rel="import" href="bower_components/font-roboto/roboto.html"/>
    <link rel="import" href="bower_components/iron-icons/iron-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/image-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/social-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/communication-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/editor-icons.html"/>

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
    <script type="text/javascript" src="js/profile.js"></script>
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
           $test = $loginStatus['status'];
           if ($test) {
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

        <paper-icon-button icon="icons:home" class="click" data-href="https://amphibiandisease.org/home.php" data-toggle="tooltip" title="Home" data-placement="bottom"></paper-icon-button>
      </p>
    </header>
    <main>
      <?php
         if ($validUser) {
             $isViewingSelf = $viewUserId == $selfUserId;
             # Fetch the structured data for the profile
             if($isViewingSelf) {
               $title = "You ($title)";
               $titlePossessive = "Your";
             }
             else {
               $titlePossessive = $title . "'s";
             }
             ?>
      <h1 id="title">User Profile - <?php echo $title ?></h1>
      <section id="main-body" class="row">
        <p class='col-xs-12'>A beautiful cacophony of data and narcissism</p>
        <div id="basic-profile" class="col-xs-12 col-md-6 profile-region">
          <h3>Basic Profile</h3>
        </div>
        <div id="institution-profile" class="col-xs-12 col-md-6 profile-region">
          <h3>Institution Information</h3>
        </div>
        <div id="bio-profile" class="col-xs-12 profile-region">
          <h3><?php echo $titlePossessive; ?> Bio</h3>
        </div>
      </section>
        <?php
           # Section for self
             if($isViewingSelf) {
           ?>
        <div class="row">
          <div class="col-xs-12">
            <button class="btn btn-success pull-right disabled" id="save-profile">
              <iron-icon icon="icons:save"></iron-icon>
              Save Changes to Profile
            </button>
          </div>
        </div>
        <section class="row conversations">
          <h3 class="col-xs-12">
            Conversations
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
                  <input type="text" class="form-control" placeholder="Type your message ..." />
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
          <p class="col-xs-12">
            Viewing Other
          </p>
        </section>
           <?php
             }
           ?>
      <?php
         } elseif (!$validUser) {
             ?>
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
         } ?>
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
