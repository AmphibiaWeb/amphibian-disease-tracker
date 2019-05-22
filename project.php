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
$suffix = empty($pid) ? 'Browser' : '#'.$pid;

$validProject = $db->isEntry($pid, 'project_id', true);
$loginStatus = getLoginState();

       ?>
    <title>Project <?php echo $suffix ?></title>
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
    <google-maps-api api-key="AIzaSyCkFBPtFAuZZmfxCgWVLY-8klRR6Dz4aeM"></google-maps-api>
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
    <script type="text/javascript" src="js/project.min.js"></script>
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
    <main>
      <?php
         if (empty($pid)) {
             ?>
      <h1 id="title">Amphibian Disease Project Browser</h1>
      <section id="major-map" class="row">
          <?php
         $search = array(
             'public' => '', # Loose query
         );
             $cols = array(
             'project_id',
             'project_title',
             'public',
             'carto_id',
             'bounding_box_n',
             'bounding_box_e',
             'bounding_box_w',
             'bounding_box_s',
             'locality',
         );
             $list = $db->getQueryResults($search, $cols, 'AND', true, true);
             $polyOpacity = '0.35';
             $superCoords = array();
             $averageLat = 0;
             $averageLng = 0;
             $polys = 0;
             $polyHtml = '';
             foreach ($list as $project) {
                 try {
                     $carto = json_decode(deEscape($project['carto_id']), true);
                 # Escaped or unescaped
                 $bpoly = empty($carto['bounding&#95;polygon']) ? $carto['bounding_polygon'] : $carto['bounding&#95;polygon'];
                 } catch (Exception $e) {
                 }
                 if (empty($project['project_id']) || empty($project['locality'])) {
                     if (empty($bpoly["multibounds"])) {
                         continue;
                     }
                 }
                 if (boolstr($project['public'])) {
                     $polyColor = '#ff7800';
                   # Depending on the type of data stored, it could be
                   # in paths or not
                   if (toBool($bpoly['paths']) === false && !empty($bpoly["multibounds"])) {
                       $bpoly['paths'] = is_array($bpoly["multibounds"]) ? $bpoly["multibounds"][0] : $bpoly["multibounds"];
                   }
                     $coords = empty($bpoly['paths']) ? $bpoly : $bpoly['paths'];
                 } else {
                     # Private
                     $polyColor = '#9C27B0'; # See https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/64
                     if (!empty($bpoly["multibounds"])) {
                         # Replace this with an approximation
                       $boringMultiBounds = array();
                         foreach ($bpoly["multibounds"] as $polySet) {
                             # We want to get the four corners of each polySet
                         $polySetBoundingBox = array();
                             $north = -90;
                             $south = 90;
                             $west = 180;
                             $east = -180;
                             foreach ($polySet as $points) {
                                 if ($points["lat"] > $north) {
                                     $north = $points["lat"];
                                 }
                                 if ($points["lng"] > $east) {
                                     $east = $points["lng"];
                                 }
                                 if ($points["lng"] < $west) {
                                     $west = $points["lng"];
                                 }
                                 if ($points["lat"] < $south) {
                                     $south = $points["lat"];
                                 }
                             }
                             $polySetBoundingBox[] = array("lat" => $north, "lng" => $west);
                             $polySetBoundingBox[] = array("lat" => $north, "lng" => $east);
                             $polySetBoundingBox[] = array("lat" => $south, "lng" => $east);
                             $polySetBoundingBox[] = array("lat" => $south, "lng" => $west);
                             $polySetBoundingBox[] = array("lat" => $north, "lng" => $west);
                             $boringMultiBounds[] = $polySetBoundingBox;
                         }
                         $bpoly["multibounds"] = $boringMultiBounds;
                     } else {
                         $coords = array();
                         $coords[] = array('lat' => $project['bounding_box_n'], 'lng' => $project['bounding_box_w']);
                         $coords[] = array('lat' => $project['bounding_box_n'], 'lng' => $project['bounding_box_e']);
                         $coords[] = array('lat' => $project['bounding_box_s'], 'lng' => $project['bounding_box_e']);
                         $coords[] = array('lat' => $project['bounding_box_s'], 'lng' => $project['bounding_box_w']);
                         $coords[] = array('lat' => $project['bounding_box_n'], 'lng' => $project['bounding_box_w']);
                     }
                 }
                 $superCoords[] = $coords;
             # If we don't do this by project first, the center is
             # weighted by boundry complication rather than number of
             # projects
             ++$polys;
                 $points = 0;
                 $projAverageLat = 0;
                 $projAverageLng = 0;
             # Need to enable both click-events and clickable
             if (empty($bpoly["multibounds"])) {
                 $html = "\n<google-map-poly closed fill-color='$polyColor' fill-opacity='$polyOpacity' stroke-weight='1' click-events clickable geodesic data-project='".$project['project_id']."'>";
                 foreach ($coords as $point) {
                     ++$points;
                     $lat = $point['lat'];
                     $lng = $point['lng'];
                     $projAverageLat = $projAverageLat + $lat;
                     $projAverageLng = $projAverageLng + $lng;
                     $html .= "\n\t<google-map-point latitude='$lat' longitude='$lng'></google-map-point>";
                 }
                 $html .= "</google-map-poly>\n";
                 $polyHtml .= $html;
             } else {
                 # We have a multibounds-type display
                 foreach ($bpoly["multibounds"] as $boundSet) {
                     # We'll repeat this for each set of points in the multibounds object
                     $html = "\n<google-map-poly closed fill-color='$polyColor' fill-opacity='$polyOpacity' stroke-weight='1' click-events clickable geodesic data-project='".$project['project_id']."'>\n <!-- Points: ".print_r($boundSet, true)."\n -->\n";
                     foreach ($boundSet as $point) {
                         ++$points;
                         $lat = $point['lat'];
                         $lng = $point['lng'];
                         $projAverageLat = $projAverageLat + $lat;
                         $projAverageLng = $projAverageLng + $lng;
                         $html .= "\n\t<google-map-point latitude='$lat' longitude='$lng'></google-map-point>";
                     }
                     $html .= "</google-map-poly>\n";
                     $polyHtml .= $html;
                 }
             }
                 $projAverageLat = $projAverageLat / $points;
                 $projAverageLng = $projAverageLng / $points;
                 $averageLat = $averageLat + $projAverageLat;
                 $averageLng = $averageLng + $projAverageLng;
             }
             $averageLat = $averageLat / $polys;
             $averageLng = $averageLng / $polys; ?>
        <google-map class="col-xs-11 col-md-9 center-block" id="community-map" latitude="<?php echo $averageLat; ?>" longitude="<?php echo $averageLng; ?>" zoom="2" map-type="hybrid" api-key="AIzaSyCkFBPtFAuZZmfxCgWVLY-8klRR6Dz4aeM">
          <?php echo $polyHtml; ?>
        </google-map>
        <p class="text-center text-muted col-xs-12">Community Project Map</p>
        <div class="col-xs-12">
          <div class="row">
            <!-- Controls for the map view -->
            <div class="col-xs-12 col-md-4">
              <paper-toggle-button id="projects-by-map-view" class="map-view-control map-view-master">
                Only show projects in map view
              </paper-toggle-button>
            </div>
            <div class="col-xs-12 col-md-4">
              <paper-toggle-button id="show-dataless-projects" class="map-view-control" disabled>
                Show projects without data and locales
              </paper-toggle-button>
            </div>
          </div>
        </div>
        <script type="text/javascript">
          _adp.aggregateHulls = <?php echo json_encode($superCoords); ?>;
        </script>
      </section>
      <?php

         } elseif (!$validProject) {
             ?>
      <h1 id="title">Invalid Project</h1>
      <?php

         } else {
             $search = array('project_id' => $pid);
             $result = $db->getQueryResults($search, '*', 'AND', false, true);
             $project = $result[0];
             foreach ($project as $attr=>$data) {
                 $decoded = htmlspecialchars_decode(html_entity_decode($data));
                 if (!empty($decoded)) {
                     $project[$attr] = $decoded;
                 }
             } ?>
      <h1 id="title">
        <?php echo $project['project_title']; ?>
      </h1>
      <?php

         } ?>
      <section id="main-body" class="row">
        <?php if (empty($pid)) {
             $search = array(
              'public' => '', # Loose query
          );
             $cols = array(
              'project_id',
              'project_title',
              'public',
              'author_data',
              'locality',
              "sampled_collection_end"
          );
    # See
    # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/178
    #
    # This block should also have a corresponding list updated in ./coffee/project.coffee
    $orderBy = array(
        "date" => "sampled_collection_end",
        "affliation" => "author_data", # in author_data
        "lab" => "pi_lab",
        "contact" => "author_data", # in author_data
    );
             $authorDataOrderBy = array(
        "affiliation" => "affiliation",
        "contact" => "name",
    );
             if (isset($_REQUEST["sort"])) {
                 $orderKey = $_REQUEST["sort"];
                 if (!array_key_exists($orderKey, $orderBy)) {
                     # Invalid order key
            $orderKey = null;
                 }
             }
             if (empty($orderKey)) {
                 $orderKey = "date";
             }
             $orderColumn = $orderBy[$orderKey];
             if (!array_find($orderColumn, $cols, false, true)) {
                 $cols[] = $orderColumn;
             }
             $list = $db->getQueryResults($search, $cols, 'AND', true, true, $orderColumn);
             $html = '';
             $i = 0;
             $count = sizeof($list);
             $userMax = intval($_REQUEST["pagination"]);
             if ($userMax < 10) {
                 $userMax = 10;
             }
             $max = $userMax;
             $page = isset($_REQUEST['page']) ? intval($_REQUEST['page']) : 1;
             if ($page > 1) {
                 $multiplier = $page - 1;
                 $skip = $multiplier * $max;
        #echo "<!-- Skipping $skip on page $page with multiplier $multiplier for max $max for total results $count -->";
             } else {
                 $skip = 0;
             }
             $originalMax = $max;
             $announcedStartSpot = false;
             if ($skip > $count) {
                 $html = "<h4>Whoops! <small class='text-muted'>These aren't the droids you're looking for</small></h4><p>You requested a project count that doesn't exit yet. Check back in a few weeks ;-)</p>";
             } else {
                 $htmlList = array();
                 foreach ($list as $k => $project) {
                     # This check also used to check for empty localities:
            #  || empty($project['locality'])
            #
            # but removed to address #163
            if (empty($project['project_id'])) {
                #echo "<!-- Skipping item $i for empty project -->";
                $count--;
                continue;
            }
                     ++$i;
                     if ($i < $skip + 1) {
                         continue;
                     }
                     if (!$announcedStartSpot) {
                         #echo "<!-- Starting list from item $i after skipping $skip (total: $count) -->";
                $announcedStartSpot = true;
                     }
                     if ($i > $max + $skip) {
                         break;
                     }
                     $authorData = json_decode($project['author_data'], true);
                     $icon = boolstr($project['public']) ? '<iron-icon icon="social:public"></iron-icon>' : '<iron-icon icon="icons:lock"></iron-icon>';
                     $shortProjectTitle = htmlspecialchars_decode(html_entity_decode($project['project_title']));
                     $tooltipTitle = "Project #".substr($project['project_id'], 0, 8)."...";
                     if (strlen($shortProjectTitle) > 43) {
                         $shortProjectTitle = substr($shortProjectTitle, 0, 40) . "...";
                         $tooltipTitle = DBHelper::staticSanitize($project['project_title']);
                     }
                     $affilEncode = htmlspecialchars($authorData["affiliation"]);
                     $affiliationIcon = "<iron-icon icon='social:school' data-toggle='tooltip' title='".$affilEncode."'></iron-icon>";
                     $orderData = $project[$orderColumn];
                     $projectCreatedOn = floatval($authorData["entry_date"]);
                     if ($orderKey == "date") {
                         if (empty($orderData)) {
                             # No data for the project -- sort by project creation
                    $orderData = $projectCreatedOn;
                         } else {
                             $orderData = floatval($orderData);
                         }
                         $arrayKey = $orderData;
                     } else {
                         # If we were searching by author_data, we were looking
                # inside a key
                if ($orderColumn == "author_data") {
                    $authorDataKey = $authorDataOrderBy[$orderKey];
                    $orderData = $authorData[$authorDataKey];
                }
                # All the other keys may be redundant -- add project
                # creation
                $arrayKey = $orderData . $projectCreatedOn;
                     }
                     $hasData = strbool(intval($project["sampled_collection_end"]) > 0);
                     $hasLocale = strbool($project["lat"] != 0 && $project["lng"] != 0);
                     $projectHtml = "<button class='btn btn-primary' data-href='https://amphibiandisease.org/project.php?id=".$project['project_id']."' data-project='".$project['project_id']."' data-toggle='tooltip' title='".$tooltipTitle."' data-order-ref='$orderData' data-order-canonical='$arrayKey' data-has-datafile='$hasData' data-has-locale='$hasLocale'>".$icon.' '.$shortProjectTitle.'</button> by <span class="is-user" data-email="'.$authorData['contact_email'].'">'.$authorData['name'] . '</span>' . $affiliationIcon;
                     $htmlList[$arrayKey] = '<li data-has-datafile="'.$hasData.'"  data-has-locale="'.$hasLocale.'">'.$projectHtml."</li>\n";
                 }
                 if ($i < $max) {
                     $count = $i;
                     $max = $i;
                 }
                 if ($skip > 0) {
                     $upperBound = $max + $skip > $count ? $count : $max + $skip;
                     $lowerBound = $skip + 1;
                     $max = $lowerBound.' &#8212; '.$upperBound;
                 }
                 ksort($htmlList);
                 $html = '<ul id="project-list" class="col-xs-12 col-md-8 col-lg-6 hidden-xs project-list project-list-page">'.implode("\n", $htmlList).'        </ul>';
             }
          # Build the paginator
          $pages = intval($count / $originalMax);
    #echo "<!-- pages breakdown: iv = $pages with $count items and orig $originalMax -->";
    if (($count % $originalMax) > 0) {
        $pages++;
    }
    #echo "<!-- revised pages = $pages / " . $count % $originalMax . " -->";
    # https://getbootstrap.com/components/#pagination
    $olderDisabled = $page > 1 ? '' : 'disabled';
             $nextPage = $page + 1;
             $previousPage = $page - 1;
             $newerDisabled = $page * $originalMax <= $count ? '' : 'disabled';
             $oByText = $orderKey == "date" ? "sampling date" : $orderKey;
             $sortText = "$count, ordered by <span class='sort-by-placeholder-text' data-order-key='$orderKey'>".$oByText."</span>";
             if ($upperBound != $count) {
                 $sortText = "about ".$sortText;
             } ?>
        <div class="col-xs-12 visible-xs-block text-right">
          <button id="toggle-project-viewport" class="btn btn-primary">Show Project List</button>
        </div>
        <h2 class="col-xs-12 status-notice hidden-xs project-list project-list-page">Showing <?php echo $max; ?> newest projects <small class="text-muted">of <?php echo $sortText; ?></small></h2>
        <div class="col-xs-12 pagination-selection-container">
          <!-- <div class="row"> -->
            <h3 class="small display-inline">
              Showing
            </h3>
            <paper-dropdown-menu label="Results per page" class="pagination" id="pagination-selector-dropdown" disabled>
              <paper-listbox class="dropdown-content" selected="0">
                <paper-item>10</paper-item>
                <paper-item>15</paper-item>
                <paper-item>25</paper-item>
                <paper-item>50</paper-item>
                <paper-item>100</paper-item>
              </paper-listbox>
            </paper-dropdown-menu>
            <h3 class="small display-inline">
              projects per page
            </h3>
          <!-- </div> -->
        </div>
    <?php
        echo $html; ?>

        <div class="col-xs-12 col-md-4 col-lg-6 project-search project-list-page">
          <paper-card heading="Search Projects" elevation="2">
            <div class="card-content form-horizontal">
              <div class="search-project form-group">
                <label for="project-search" class="col-xs-12 col-md-4 col-lg-3 control-label">Search Projects</label>
                <div class="col-xs-12 col-md-7 col-lg-9">
                  <input type="text" class="form-control" placeholder="Project ID or name..." name="project-search" id="project-search"/>
                </div>
              </div>
            </div>
            <paper-radio-group selected="names" id="search-filter">
              <paper-radio-button name="names" data-cols="project_id,project_title,project_obj_id" data-cue="Project ID or name...">
                Project Names &amp; IDs
              </paper-radio-button>
              <paper-radio-button name="users" data-cols="author_data,pi_lab" data-cue="Name or email...">
                PIs, Labs, Creators, Affiliation
              </paper-radio-button>
              <paper-radio-button name="taxa" data-cols="sampled_species,sampled_clades" data-cue="Scientific name...">
                Project Taxa
              </paper-radio-button>
            </paper-radio-group>
            <ul id="project-result-container">

            </ul>
          </paper-card>
        </div>
        <nav class="col-xs-12 project-pagination center-block text-center" id="project-pagination">
          <ul class="pagination">
            <li class="<?php echo $olderDisabled; ?>">
              <a href="?page=<?php echo $previousPage; ?>"><span aria-hidden="true">&larr;</span> Previous</a>
            </li>
            <?php
          $k = 1;
             while ($k <= $pages) {
                 echo "<li><a href='?page=".$k."&pagination=".$originalMax."'>".$k."</a></li>\n";
                 ++$k;
             } ?>
            <li class="<?php echo $newerDisabled; ?>">
              <a href="?page=<?php echo $nextPage; ?>">Next <span aria-hidden="true">&rarr;</span></a>
            </li>
          </ul>
        </nav>
        <?php

         } elseif (!$validProject) {
             ?>
        <h2 class="col-xs-12">Project <code><?php echo $pid ?></code> doesn&#39;t exist.</h2>
        <p>Did you want to <a href="project.php">browse our projects instead?</a></p>
        <?php

         } else {
             $projectCitation = ""; ?>
        <?php
          $authorData = json_decode($project['author_data'], true);
             $authorName = preg_replace('!\s+!', ' ', $authorData["name"]);
             $authorParts = explode(" ", $authorName);
             $authorNameFormal = $authorParts[1] . ", " . substr($authorParts[0], 0, 1);
             $creationTime = $authorData["entry_date"];
             $today = date("d M Y");
             $phpTime = intval($creationTime) / 1000;
             $creationYear = date("Y", $phpTime); ?>
        <div class="citation-block col-xs-12">
          <p class="text-muted">
            Recommended citation:
          </p>
          <cite class="self-citation" data-project="Project #<?php echo $pid; ?>">
            <span class="author-name"><?php echo $authorNameFormal; ?></span>. <span class="creation-year"><?php echo $creationYear; ?> "<?php echo $project['project_title']; ?>" AmphibiaWeb: Amphibian Disease Portal. &lt;https://n2t.net/<?php echo $project['project_obj_id']; ?>&gt;  Accessed <?php echo $today; ?>.
          </cite>
        </div>
        <h2 class="col-xs-12">
          Project Abstract
        </h2>
        <marked-element class="project-abstract col-xs-12 indent">
          <div class="markdown-html"></div>
          <script type="text/markdown"><?php echo deEscape($project['sample_notes']); ?></script>
        </marked-element>

        <div class="col-xs-12 basics-list">
          <h2>Project Basics</h2>

          <div class="row">
            <paper-input readonly label="ARK identifier" value="<?php echo $project['project_obj_id']; ?>" class="col-xs-9 col-md-11 ark-identifier"></paper-input>
            <paper-fab icon="icons:content-copy" class="materialblue" id="copy-ark" data-ark="<?php echo $project['project_obj_id']; ?>" data-clipboard-text="https://n2t.net/<?php echo $project['project_obj_id']; ?>" data-toggle="tooltip" title="Copy Link"></paper-fab>
          </div>
          <paper-input readonly label="Project pathogen" value="<?php echo $project['disease']; ?>"></paper-input>
          <div class="row">
            <paper-input readonly label="Project PI" class="col-xs-9 col-md-11" value="<?php echo $project['pi_lab']; ?>"></paper-input>
            <paper-fab icon="social:person" class="materialblue is-user" data-name="<?php echo $project['pi_lab']; ?>"></paper-fab>
          </div>
          <div class="row">
            <?php
               $class = empty($project['publication']) ? "col-xs-12" : "col-xs-9 col-md-11";
             $hidden = empty($project['publication']) ? "hidden" : "";
             $pub = preg_replace('%^(doi|ark|(https?://)?(dx\.)?doi\.org(/|:)|(https?://)?(www\.)?biscicol\.org/id(/|:)|(https?://)?(www\.)?n2t.net(/|:)):? *%im', '', $project['publication']); ?>
            <paper-input readonly label="DOI" class="<?php echo $class; ?>" value="<?php echo $pub; ?>" id="doi-input"></paper-input>
            <paper-fab icon="icons:description" class="materialblue click" data-function="showCitation" data-toggle="tooltip" title="Show Citation" <?php echo $hidden; ?>></paper-fab>
          </div>
          <div class="row">
            <paper-input readonly label="Project Contact" value="<?php echo $authorData['name']; ?>" class="col-xs-9 col-md-11"></paper-input>
            <paper-fab icon="social:person" class="materialblue is-user" data-name="<?php echo $authorData['name']; ?>"></paper-fab>
          </div>
          <paper-input readonly label="Diagnostic Lab" value="<?php echo $authorData['diagnostic_lab']; ?>"></paper-input>
          <paper-input readonly label="Affiliation" value="<?php echo $authorData['affiliation']; ?>"></paper-input>
          <div class="row" id="email-fill">
            <?php
               require_once 'admin/CONFIG.php'; ?>
            <script src="https://www.google.com/recaptcha/api.js" async defer></script>
            <p class="col-xs-12 col-md-3 col-lg-2 col-xl-1">
              Contact email:
              <br/>
              <span class="text-muted small">Please solve the CAPTCHA to see the contact email</span>
            </p>
            <div class="g-recaptcha col-xs-12 col-md-9 col-lg-10 col-xl-11" data-sitekey="<?php echo $recaptcha_public_key; ?>" data-callback="renderEmail"></div>
          </div>
        </div>
        <div class="needs-auth col-xs-12" id="auth-block">
<?php
   $limitedProject = array();
             $cleanCarto = deEscape($project['carto_id']);
             $carto = json_decode($cleanCarto, true);
    # TODO RECONSTRUCT LIMITED MULTIBOUNDS HERE
    $multiBounds = $carto["bounding_polygon"]["multibounds"];
             $north = -90;
             $south = 90;
             $west = 180;
             $east = -180;
             foreach ($multiBounds as $polygon) {
                 foreach ($polygon as $point) {
                     if ($point["lat"] > $north) {
                         $north = $point["lat"];
                     }
                     if ($point["lng"] > $east) {
                         $east = $point["lng"];
                     }
                     if ($point["lng"] < $west) {
                         $west = $point["lng"];
                     }
                     if ($point["lat"] < $south) {
                         $south = $point["lat"];
                     }
                 }
             }
             $corners = array(
        array(
            "lat" => $north,
            "lng" => $west,
        ),
        array(
            "lat" => $north,
            "lng" => $east,
        ),
        array(
            "lat" => $south,
            "lng" => $east,
        ),
        array(
            "lat" => $south,
            "lng" => $west,
        ),
        array(
            "lat" => $north,
            "lng" => $west,
        ),
    );
             $cartoLimited = array(
       'bounding_polygon' => array(
           'fillColor' => $carto['bounding_polygon']['fillColor'],
           'fillOpacity' => $carto['bounding_polygon']['fillOpacity'],
           "multibounds" => array($corners), # $carto["bounding_polygon"]["multibounds"], # TEMPORARY
       ),
   );
             $limitedProjectCols = array(
       'public',
       'bounding_box_n',
       'bounding_box_e',
       'bounding_box_w',
       'bounding_box_s',
       'lat',
       'lng',
   );
             foreach ($limitedProjectCols as $col) {
                 $limitedProject[$col] = $project[$col];
             }
             $limitedProject['carto_id'] = $cartoLimited;
             $jsonDataLimited = json_encode($limitedProject);
             $jsonData = json_encode($project);

             if (boolstr($project['public']) === true) {
                 # Public project, base renders
?>
          <script type="text/javascript">
            renderMapWithData(<?php echo $jsonData; ?>);
          </script>

<?php

             } else {
                 # Set the most limited public data possible. After correct user
    # validation, it'll render a simple map
?>
          <script type="text/javascript">
            setPublicData(<?php echo $jsonDataLimited; ?>);
          </script>

<?php

             } ?>
        </div>
        <div class="col-xs-12">
          <h2>Species List</h2>
          <h3>Click on a species below to see the AmphibiaWeb entry</h3>
          <ul class="species-list">
<?php
          $aWebUri = 'http://amphibiaweb.org/cgi/amphib_query?rel-genus=equals&amp;rel-species=equals&amp;';
             $args = array('where-genus' => '', 'where-species' => '');
             $speciesList = explode(',', $project['sampled_species']);
             sort($speciesList);
             $i = 0;
             $realSpecies = array();
             foreach ($speciesList as $species) {
                 if (empty($species)) {
                     continue;
                 }
                 ++$i;
                 $realSpecies[] = $species;
                 $speciesParts = explode(' ', $species);
                 $args['where-genus'] = $speciesParts[0];
                 $args['where-species'] = $speciesParts[1];
                 $badSpecies = preg_match('/^(nov[.]{0,1} ){0,1}(sp[.]{0,1}([ ]{0,1}[\w ]+){0,1})$/m', $speciesParts[1]) || empty($speciesParts[1]);
                 if ($badSpecies) {
                     $linkUri = $aWebUri.'where-genus='.$speciesParts[0];
                 } else {
                     $linkUri = $aWebUri.'where-genus='.$speciesParts[0].'&amp;where-species='.$speciesParts[1];
                 }

                 $html = '<li class="aweb-link-species" data-species="'.$species.'" data-positive="false" data-negative="false" data-inconclusive="false"> <span class="sciname no-underline" data-href="'.$linkUri.'"data-newtab="true"><span class="genus">'.$speciesParts[0].'</span> <span class="species">'.$speciesParts[1].'</span></span> <paper-icon-button icon="editor:insert-chart" class="click" data-href="dashboard.php?taxon='.$species.'"></paper-icon-button></li>';
                 echo $html;
             }
             if ($i === 0) {
                 echo '<h3>Sorry, there are no species associated with this project.</h3>';
                 $speciesJson = '{}';
             } else {
                 $speciesJson = json_encode($realSpecies);
             } ?>
          </ul>
          <script type="text/javascript">
            _adp.pageSpeciesList = <?php echo $speciesJson; ?>;
          </script>
        </div>
        <h2 class="col-xs-12 project-identifier">
          <span class="text-muted small">
            Project
            #<?php echo $pid; ?>
          </span>
        </h2>
        <?php

         } ?>
      </section>
    </main>
<?php
   require_once("./footer.php");
   ?>
  </body>
</html>
