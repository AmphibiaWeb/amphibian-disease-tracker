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

    $pid = $db->sanitize($_GET['id']);



    $loginStatus = getLoginState();

    ?>
    <title>Disease Dashboard</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta charset="UTF-8"/>
    <meta name="theme-color" content="#5677fc"/>
    <meta name="viewport" content="width=device-width, minimum-scale=1, initial-scale=1, maximum-scale=1.0, user-scalable=0" />

    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
    <link rel="stylesheet" type="text/css" href="bower_components/json-human/css/json.human.css" />
    <link rel="prerender" href="https://amphibiandisease.org/index.php" />
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
    <link rel="import" href="bower_components/paper-input/paper-textarea.html"/>
    <link rel="import" href="bower_components/paper-spinner/paper-spinner.html"/>
    <link rel="import" href="bower_components/paper-slider/paper-slider.html"/>
    <link rel="import" href="bower_components/paper-menu/paper-menu.html"/>
    <link rel="import" href="bower_components/paper-menu-button/paper-menu-button.html"/>
    <link rel="import" href="bower_components/paper-card/paper-card.html"/>

    <link rel="import" href="bower_components/paper-dropdown-menu/paper-dropdown-menu.html"/>
    <link rel="import" href="bower_components/paper-listbox/paper-listbox.html"/>


    <link rel="import" href="bower_components/paper-dialog/paper-dialog.html"/>
    <link rel="import" href="bower_components/paper-radio-group/paper-radio-group.html"/>
    <link rel="import" href="bower_components/paper-radio-button/paper-radio-button.html"/>

    <link rel="import" href="bower_components/paper-dialog-scrollable/paper-dialog-scrollable.html"/>
    <link rel="import" href="bower_components/paper-button/paper-button.html"/>
    <link rel="import" href="bower_components/paper-icon-button/paper-icon-button.html"/>
    <link rel="import" href="bower_components/paper-fab/paper-fab.html"/>
    <link rel="import" href="bower_components/paper-item/paper-item.html"/>
    <link rel="import" href="bower_components/paper-listbox/paper-listbox.html"/>
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
    <link rel="import" href="bower_components/iron-collapse/iron-collapse.html"/>

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
    <!-- <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4"></script> -->
    <google-maps-api api-key="AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4"></google-maps-api>
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
    <script type="text/javascript" src="bower_components/chart.js/dist/Chart.bundle.min.js"></script>
    <script type="text/javascript" src="js/c.min.js"></script>
    <script type="text/javascript" src="js/dashboard.js"></script>
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
    <div class="logo-container">
      <div class="square-object">
        <div class="square tile">
          <img src="assets/aw_logo512-trans.png" alt="AmphibiaWeb logo" class="content click" data-href="http://amphibiaweb.org/" data-newtab="true"/>
        </div>
      </div>
    </div>
    <p class="col-xs-12 login-status-bar text-right">
        <?php
        $user = $_COOKIE['amphibiandisease_fullname'];
        $test = $loginStatus['status'];
        if ($test) {
            ?>
      Logged in as <span class='header-bar-user-name'><?php echo $user; ?></span>
      <paper-icon-button icon="icons:dashboard" class="click" data-href="https://amphibiandisease.org/admin-page.html" data-toggle="tooltip" title="Administration Dashboard" data-placement="bottom"> </paper-icon-button>
      <paper-icon-button icon='icons:settings-applications' class='click' data-href="https://amphibiandisease.org/admin" data-toggle="tooltip" title="Account Settings" data-placement="bottom"></paper-icon-button>
        <?php

        } else {
            ?>
      <paper-icon-button icon="icons:exit-to-app" class="click" data-toggle="tooltip" title="Login" data-href="https://amphibiandisease.org/admin" data-placement="bottom"></paper-icon-button>
        <?php

        }
        if (!empty($pid)) {
            ?>
      <paper-icon-button icon="icons:language" class="click" data-toggle="tooltip" title="Project Browser" data-href="https://amphibiandisease.org/project.php" data-placement="bottom"> </paper-icon-button>
        <?php

        } ?>
      <paper-icon-button icon="icons:account-box" class="click" data-toggle="tooltip" title="Profiles" data-href="https://amphibiandisease.org/profile.php" data-placement="bottom"> </paper-icon-button>
      <paper-icon-button icon="icons:home" class="click" data-href="https://amphibiandisease.org" data-toggle="tooltip" title="Home" data-placement="bottom"></paper-icon-button>
    </p>
  </header>
  <main class="row">
    <?php
            # See
            # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/176
            # for scope and features

            # Fetch aggregate stats

        ?>
    <h2 class="col-xs-12">
      Disease Summary Dashboard <span class="badge">ALPHA</span>
    </h2>
    <section class="col-xs-12">
      <div class="row db-summary-region">
        <?php
            /***
             * Get some summary stats
             * See:
             * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/176#issuecomment-288560111
             ***/
            # Species count
            $query = "select `genus`, `specificepithet`, count(*) as count from `records_list` where genus is not null group by genus, specificepithet";
            $r = mysqli_query($db->getLink(), $query);
            $speciesCount = mysqli_num_rows($r);
            # Total samples
            $query = "select count(*) as count from `records_list` where genus is not null";
            $r = mysqli_query($db->getLink(), $query);
            $row = mysqli_fetch_row($r);
            $count = $row[0];
            # Country count
            $query = "select country, count(*) as count from `records_list` where genus is not null group by country";
            $r = mysqli_query($db->getLink(), $query);
            $countryCount = mysqli_num_rows($r);
            ?>
        <div class="col-xs-12 col-md-6 table-responsive">
          <table class="table table-striped table-bordered table-condensed">
            <thead>
              <tr>
                <td>
                  Total Samples
                </td>
                <td>
                  Number of Species
                </td>
                <td>
                  Number of Countries
                </td>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>
                  <?php echo $count; ?>
                </td>
                <td>
                  <?php echo $speciesCount; ?>
                </td>
                <td>
                  <?php echo $countryCount; ?>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
    <section class="col-xs-12">
      <div class="form form-horizontal row">
        <h3 class="col-xs-12">Create a chart</h3>
        <div class="col-xs-12 col-md-4 col-sm-6">
          <paper-dropdown-menu label="View" id="view-type"  class="chart-param" data-key="view">
            <paper-listbox class="dropdown-content" selected="0">
              <paper-item>Sample Counts</paper-item>
              <paper-item disabled>Project Count</paper-item>
            </paper-listbox>
          </paper-dropdown-menu>
        </div>
        <div class="col-xs-12 col-md-4 col-sm-6">
          <paper-dropdown-menu label="Binned By" id="binned-by"  data-key="bin" class="chart-param">
            <paper-listbox class="dropdown-content" selected="0">
              <paper-item>Location</paper-item>
              <paper-item>Species</paper-item>
              <paper-item> Infection </paper-item>
              <paper-item disabled>Time</paper-item>
            </paper-listbox>
          </paper-dropdown-menu>
        </div>
        <div class="col-xs-12 col-md-4">
          <paper-dropdown-menu label="Sort By" id="sort-by"  data-key="sort" class="chart-param">
            <paper-listbox class="dropdown-content" selected="0">
              <paper-item data-bins="location,species">Samples</paper-item>
              <paper-item data-bins="infection,location">Infection</paper-item>
              <paper-item data-bins="location">Country</paper-item>
              <paper-item data-bins="species">Genus</paper-item>
              <paper-item data-bins="species">Species</paper-item>
              <paper-item disabled>Time</paper-item>
            </paper-listbox>
          </paper-dropdown-menu>
        </div>
        <div class="col-xs-12">
          <button class="btn btn-success" id="generate-chart">Generate Chart</button>
        </div>
      </div>
    </section>
  </main>
    <?php
    require_once("./footer.php");
    ?>
</body>
</html>
