<!DOCTYPE html>
<html>
  <head>
<?php
$debug = false;

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('Home page is running in debug mode!');
}

$print_login_state = false;
require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
require_once dirname(__FILE__).'/admin/async_login_handler.php';

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);
$loginStatus = getLoginState();
?>
    <title>Amphibian Disease Portal</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta charset="UTF-8"/>
    <meta name="theme-color" content="#445e14"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
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
    <link rel="import" href="bower_components/paper-dialog/paper-dialog.html"/>
    <link rel="import" href="bower_components/paper-dialog-scrollable/paper-dialog-scrollable.html"/>
    <link rel="import" href="bower_components/paper-button/paper-button.html"/>
    <link rel="import" href="bower_components/paper-icon-button/paper-icon-button.html"/>
    <link rel="import" href="bower_components/paper-fab/paper-fab.html"/>
    <link rel="import" href="bower_components/paper-item/paper-item.html"/>
    <link rel="import" href="bower_components/paper-card/paper-card.html"/>

    <link rel="import" href="bower_components/gold-email-input/gold-email-input.html"/>
    <link rel="import" href="bower_components/gold-phone-input/gold-phone-input.html"/>

    <link rel="import" href="bower_components/iron-form/iron-form.html"/>
    <link rel="import" href="bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html"/>

    <link rel="import" href="bower_components/font-roboto/roboto.html"/>
    <link rel="import" href="bower_components/iron-icons/iron-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/image-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/social-icons.html"/>

    <link rel="import" href="bower_components/neon-animation/neon-animation.html"/>

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

    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
    <script type="text/javascript" src="bower_components/bootstrap/dist/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="js/purl.min.js"></script>
    <script type="text/javascript" src="js/xmlToJSON.min.js"></script>
    <script type="text/javascript" src="js/jquery.cookie.min.js"></script>
    <script type="text/javascript" src="bower_components/js-base64/base64.min.js"></script>
    <script type="text/javascript" src="bower_components/imagelightbox/dist/imagelightbox.min.js"></script>

    <script type="text/javascript" src="js/c.js"></script>

  </head>
  <body class="container-fluid">
    <header id="header-bar" class="fixed-bar clearfix row">
     <p class="col-xs-12 text-right">
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
             # TODO replace login icon with glyphicon login icon
          ?>
          <paper-button class="click materialgreen" data-toggle="tooltip" title="Login" data-href="https://amphibiandisease.org/admin" data-placement="bottom">
              <iron-icon icon="icons:exit-to-app"></iron-icon>
              Log In
          </paper-button>
          <paper-button class="click materialgreen" data-toggle="tooltip" title="Sign Up" data-href="https://amphibiandisease.org/admin-login.php?q=create" data-placement="bottom">
              <iron-icon icon="icons:lightbulb-outline"></iron-icon>
              Sign Up
          </paper-button>

      <?php
         } ?>
        <paper-icon-button icon="icons:update" class="click" data-toggle="tooltip" title="News &amp; Updates" data-href="http://updates.amphibiandisease.org" data-placement="bottom"> </paper-icon-button>
        <paper-icon-button icon="icons:language" class="click" data-toggle="tooltip" title="Project Browser" data-href="https://amphibiandisease.org/project.php" data-placement="bottom"> </paper-icon-button>
        <paper-icon-button icon="icons:account-box" class="click" data-toggle="tooltip" title="Profiles" data-href="https://amphibiandisease.org/profile.php" data-placement="bottom"> </paper-icon-button>
        </p>
    </header>
    <main>
      <h1 id="title" class="main-title">The Amphibian Disease Portal</h1>
      <section id="main-body" class="row">
        <h2 class="col-xs-12 subtitle">A repository for aggregating information on <i>Bd</i> and <i>Bsal</i></h2>
        <div class="subcontainer col-xs-12">
          <div id="amphibian-images-carousel" class="carousel slide" data-ride="carousel">
            <!-- Indicators -->
            <ol class="carousel-indicators">
              <li data-target="#amphibian-images-carousel" data-slide-to="0" class="active"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="1"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="2"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="3"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="4"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="5"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="6"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="7"></li>
              <li data-target="#amphibian-images-carousel" data-slide-to="8"></li>
            </ol>

            <!-- Wrapper for slides -->
            <div class="carousel-inner" role="listbox">
              <div class="item active">
                <img src="assets/carousel/DSC03218.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/DSCN0400.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/DSCN1372.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/IMG_2927.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/IMG_3818-2.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/IMG_4227-2.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/IMG_20151013_165045-01.jpg" alt="...">
              </div>
              <div class="item">
                <img src="assets/carousel/IMG_20151027_185105.jpg" alt="...">
              </div>
            </div>

            <!-- Controls -->
            <a class="left carousel-control" href="#amphibian-images-carousel" role="button" data-slide="prev">
              <span class="glyphicon glyphicon-chevron-left" aria-hidden="true"></span>
              <span class="sr-only">Previous</span>
            </a>
            <a class="right carousel-control" href="#amphibian-images-carousel" role="button" data-slide="next">
              <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
              <span class="sr-only">Next</span>
            </a>
          </div>
        </div>
        <br/>
        <br/>
      </section>
      <section id="landing-blurb" class="row">
        <div class="subcontainer col-xs-12">
          <br/><br/>
          <div class="row">
            <div class="card-container col-xs-12 col-md-6 col-lg-3">
              <paper-card heading="Documentation" class="card-tile" elevation="2" animated-shadow>
                <div class="card-content">
                  <p>
                    Read the documentation for the site
                  </p>
                </div>
                <div class="card-actions">
                  <paper-button class="click" data-href="https://amphibian-disease-tracker.readthedocs.org" data-newtab="true">
                    <iron-icon icon="icons:chrome-reader-mode"></iron-icon>
                    Documentation
                  </paper-button>
                </div>
              </paper-card>
            </div>
            <div class="card-container col-xs-12 col-md-6 col-lg-3">
              <paper-card heading="Blog" class="card-tile" elevation="2" animated-shadow>
                <div class="card-content">
                  <p>
                    Keep up to date with the project
                  </p>
                </div>
                <div class="card-actions">
                  <paper-button class="click" data-href="http://updates.amphibiandisease.org/" data-newtab="true">
                    <iron-icon icon="icons:update"></iron-icon>
                    Updates &amp; Blog
                  </paper-button>
                </div>
              </paper-card>
            </div>
            <div class="card-container col-xs-12 col-md-6 col-lg-3">
              <paper-card heading="Browse Project Data" class="card-tile" elevation="2" animated-shadow>
                <div class="card-content">
                  <p>
                    See all projects and access datasets
                  </p>
                </div>
                <div class="card-actions">
                  <paper-button class="click" data-href="https://amphibiandisease.org/project.php">
                    <iron-icon icon="icons:language"></iron-icon>
                    View the Project Browser
                  </paper-button>
                </div>
              </paper-card>
            </div>
            <div class="card-container col-xs-12 col-md-6 col-lg-3">
              <paper-card heading="AmphibiaWeb" class="card-tile" elevation="2" animated-shadow>
                <div class="card-content">
                  <p>
                    Visit AmphibiaWeb!
                  </p>
                </div>
                <div class="card-actions">
                  <paper-button class="click" data-href="http://amphibiaweb.org" data-newtab="true">
                    amphibiaweb.org
                  </paper-button>
                </div>
              </paper-card>
            </div>
          </div>
        </div>
        <br/><br/>
      </section>
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
