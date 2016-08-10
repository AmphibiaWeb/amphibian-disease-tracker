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
    <meta name="theme-color" content="#5677fc"/>
    <meta name="viewport" content="width=device-width, minimum-scale=1, initial-scale=1, maximum-scale=1.0, user-scalable=0" />

    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
    <link rel="stylesheet" href="https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css" />
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
    <link rel="import" href="bower_components/paper-dialog/paper-dialog.html"/>
    <link rel="import" href="bower_components/paper-radio-group/paper-radio-group.html"/>
    <link rel="import" href="bower_components/paper-radio-button/paper-radio-button.html"/>
    <link rel="import" href="bower_components/paper-dialog-scrollable/paper-dialog-scrollable.html"/>
    <link rel="import" href="bower_components/paper-button/paper-button.html"/>
    <link rel="import" href="bower_components/paper-icon-button/paper-icon-button.html"/>
    <link rel="import" href="bower_components/paper-fab/paper-fab.html"/>
    <link rel="import" href="bower_components/paper-item/paper-item.html"/>
    <link rel="import" href="bower_components/paper-card/paper-card.html"/>

    <link rel="import" href="bower_components/gold-email-input/gold-email-input.html"/>
    <link rel="import" href="bower_components/gold-phone-input/gold-phone-input.html"/>

    <link rel="import" href="bower_components/iron-collapse/iron-collapse.html"/>

    <link rel="import" href="bower_components/iron-form/iron-form.html"/>
    <link rel="import" href="bower_components/iron-label/iron-label.html"/>
    <link rel="import" href="bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html"/>

    <link rel="import" href="bower_components/font-roboto/roboto.html"/>
    <link rel="import" href="bower_components/iron-icons/iron-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/image-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/social-icons.html"/>
    <link rel="import" href="bower_components/iron-icons/editor-icons.html"/>

    <link rel="import" href="bower_components/neon-animation/neon-animation.html"/>
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

    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
    <script type="text/javascript" src="bower_components/bootstrap/dist/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="js/purl.min.js"></script>
    <script type="text/javascript" src="js/xmlToJSON.min.js"></script>
    <script type="text/javascript" src="js/jquery.cookie.min.js"></script>
    <script type="text/javascript" src="bower_components/js-base64/base64.min.js"></script>
    <script type="text/javascript" src="bower_components/imagelightbox/dist/imagelightbox.min.js"></script>
    <script src="https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js"></script>

    <script type="text/javascript" src="js/c.js"></script>
    <script type="text/javascript" src="js/global-search.js"></script>

  </head>
  <body class="container-fluid">
    <header id="header-bar" class="fixed-bar clearfix row">
      <div class="logo-container">
        <div class="square-object">
          <div class="square tile">
            <img src="assets/aw_logo512-trans.png" alt="AmphibiaWeb logo" class="content click" data-href="http://amphibiaweb.org/" data-newtab="true"/>
          </div>
        </div>
      </div>
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
        <section class="col-xs-12" id="global-data-vis">
          <div id="alt-map" hidden></div>
          <div class="map-container" id="global-map-container">
            <!-- <google-map id="global-data-map" map-type="terrain" api-key="AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4" zoom="3" min-zoom="3"></google-map> -->
          </div>
          <script type="infowindow/html" id="infowindow_template">
            <div class="cartodb-popup v2">
              <a href="#close" class="cartodb-popup-close-button close">x</a>
              <div class="cartodb-popup-content-wrapper">
                <div class="cartodb-popup-header">
                  <img style="width: 100%" src="https://cartodb.com/assets/logos/logos_full_cartodb_light.png"/>
                </div>
                <div class="cartodb-popup-content">
                  <!-- content.data contains the field info -->
                  <h4>Species: </h4>
                  <p>{{content.data.genus}} {{content.data.specificepithet}}</p>
                  <p>Tested {{content.data.diseasetested}} as {{content.data.diseasedetected}} (Fatal: {{content.data.fatal}})</p>
                </div>
              </div>
              <div class="cartodb-popup-tip-container"></div>
            </div>
          </script>
          <div class="center-block" id="post-map-container">
            <p class="text-center center-block text-muted" id="post-map-subtitle">
              All Projects
            </p>
          </div>
          <div class="form form-horizontal row" id="global-records-search">
            <h3 class="col-xs-12">Search &amp; Visualize Records <span class="badge">BETA</span></h3>
            <div class="col-xs-12 col-md-6 col-lg-8">
              <div class="form-group" id="taxa-input-container">
                <label for="taxa-input" class="col-xs-4 col-sm-2 control-label">Taxa filter</label>
                <div class="col-xs-6 col-sm-9">
                  <input type="text" id="taxa-input" class="form-control submit-project-search" placeholder="e.g., Batrachoseps attenuatus. Default: No filter"/>
                </div>
                <div class="col-xs-2 col-sm-1">
                  <span class="glyphicon glyphicon-info-sign" title="Simple substring match against taxa represented in projects. Uses canonical AmphibiaWeb taxa." data-toggle="tooltip"></span>
                </div>
              </div>
              <div class="row">
                <div class="col-xs-12 center-block text-center">
                  <paper-button id="toggle-global-search-filters" raised>
                    <iron-icon icon="icons:filter-list"></iron-icon>
                    <span class="action-word">Show</span> Filters
                  </paper-button>
                  <iron-collapse id="global-search-filters">
                    <div class="collapse-content text-left">
                      <div class="form-group paper-elements">
                        <label for="disease-status" class="col-xs-4 col-sm-2 control-label">Disease Status</label>
                        <div class="col-xs-8 col-sm-10 ">
                          <paper-radio-group id="disease-status" selected="any">
                            <paper-radio-button name="any" data-search="*">Any</paper-radio-button>
                            <paper-radio-button name="positive" data-search="true">Positive</paper-radio-button>
                            <paper-radio-button name="negative" data-search="false">Negative</paper-radio-button>
                          </paper-radio-group>
                        </div>
                      </div>
                      <div class="form-group paper-elements">
                        <label for="morbidity-status" class="col-xs-4 col-sm-2 control-label">Morbidity Status</label>
                        <div class="col-xs-8 col-sm-10 ">
                          <paper-radio-group id="morbidity-status" selected="any">
                            <paper-radio-button name="any" data-search="*">Any</paper-radio-button>
                            <paper-radio-button name="positive" data-search="true">Positive</paper-radio-button>
                            <paper-radio-button name="negative" data-search="false">Negative</paper-radio-button>
                          </paper-radio-group>
                        </div>
                      </div>
                      <div class="form-group paper-elements">
                        <label for="pathogen-choice" class="col-xs-4 col-sm-2 control-label">Pathogen</label>
                        <div class="col-xs-8 col-sm-10 ">
                          <paper-radio-group id="pathogen-choice" selected="any">
                            <paper-radio-button name="any" data-search="*">Any</paper-radio-button>
                            <paper-radio-button name="bd" data-search="Batrachochytrium dendrobatidis"><span class="sciname">Batrachochytrium dendrobatidis</span></paper-radio-button>
                            <paper-radio-button name="bsal" data-search="Batrachochytrium salamandrivorans"><span class="sciname">Batrachochytrium salamandrivorans</span></paper-radio-button>
                          </paper-radio-group>
                        </div>
                      </div>
                    </div>
                  </iron-collapse>
                </div>
              </div>
              <div class="form-group">
                <iron-label class="control-label col-xs-4 col-sm-2" for="use-viewport-bounds">
                  Search in map view
                </iron-label>
                <div class="col-xs-5 col-sm-8">
                  <paper-toggle-button id="use-viewport-bounds" checked>Enabled</paper-toggle-button>
                  <span class="glyphicon glyphicon-info-sign" title="The bounds will be computed based on the area of the map that's visible" data-toggle="tooltip"></span>
                </div>
              </div>
              <div class="form-group">
                <label class="control-label col-xs-4 col-sm-2" for="bounds-container">Bounds</label>
                <div class="col-xs-8 col-sm-10 table-responsive">
                  <table class="table table-bordered margin-table" id="bounds-container">
                    <tr>
                      <th>Point</th>
                      <th>Latitude <span class="text-muted">(decimal degrees)</span></th>
                      <th>Longitude <span class="text-muted">(decimal degrees)</span></th>
                    </tr>
                    <tr>
                      <td>NW</td>
                      <td>
                        <input type="number" id="north-coordinate" placeholder="37.872483" class="form-control coord-input lat-input submit-project-search" value="90"/>
                      </td>
                      <td>
                        <input type="number" id="west-coordinate" placeholder="-122.258922" class="form-control coord-input lng-input submit-project-search" value="-180"/>
                      </td>
                    </tr>
                    <tr>
                      <td>SE</td>
                      <td>
                        <input type="number" id="south-coordinate" placeholder="-37.7963646" class="form-control coord-input lat-input submit-project-search" value="-90"/>
                      </td>
                      <td>
                        <input type="number" id="east-coordinate" placeholder="144.9589851" class="form-control coord-input lng-input submit-project-search" value="180"/>
                      </td>
                    </tr>
                  </table>
                </div>
              </div>
            </div>
            <div class="form-group">
              <div class="col-xs-12 col-md-6 col-lg-4 text-center center-block">
              <button class="btn btn-primary do-search" data-deep="false" id="do-global-search" data-toggle="tooltip" title="Show all results from projects containing at least one matching sample, with the project contained in the bounds"><iron-icon icon="icons:search"></iron-icon> <span class='hidden-xs'>Search In</span> Projects</button>
              <button class="btn btn-default do-search" data-deep="true" id="do-global-deep-search" data-toggle="tooltip" title="Show only specific samples that match the search criteria"><iron-icon icon="icons:search"></iron-icon> <span class='hidden-xs'>Search In</span> Samples</button>
              <button class="btn btn-warning btn-sm" id="reset-global-map"><iron-icon icon="icons:refresh"></iron-icon> Reset Map</button>
              </div>
            </div>
          </div>
        </section>
      </section>
      <section id="landing-blurb" class="row">
        <div class="subcontainer col-xs-12">
          <br/><br/>
          <div class="row">
            <div class="card-container col-xs-12 col-md-6 col-lg-3">
              <paper-card heading="Get Involved" class="card-tile" elevation="2" animated-shadow>
                <div class="card-content">
                  <p>
                    Learn the user workflow for the site
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
                    <span class='hidden-md-lg'>View the </span> Project Browser
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
<?php
   require_once("./footer.php");
   ?>
  </body>
</html>
