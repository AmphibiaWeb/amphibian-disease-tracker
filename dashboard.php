<?php
header('Access-Control-Allow-Origin: *');
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

$uid = $loginStatus['detail']['uid'];
$suFlag = $loginStatus['detail']['userdata']['su_flag'];
$isSu = boolstr($suFlag);

if ($isSu !== true) {
    $authorizedIntersectQuery = "SELECT `project_id` FROM `".$db->getTable()."` WHERE `public` is true";
    if (!empty($uid)) {
        $authorizedIntersectQuery .= " OR `access_data` LIKE '%".$uid."%' OR `author` LIKE '%".$uid."%'";
    }
} else {
    # A superuser gets to view everything
    $authorizedIntersectQuery = "SELECT `project_id` FROM `".$db->getTable()."`";
}

$authorizedIntersect = "INNER JOIN ($authorizedIntersectQuery) AS authorized ON authorized.project_id = ";


# Prep for possible async
$start_script_timer = microtime_float();
$_REQUEST = array_merge($_REQUEST, $_GET, $_POST);
# Check the status for any async flags we may want
if (toBool($_REQUEST["async"]) === true) {
    # Now we can do any feedbacks needed
    # Public API
    header('Access-Control-Allow-Origin: *');
    switch ($_REQUEST["action"]) {
        case "country_taxon":
            # Get the taxa in a given country
            $db->setTable("records_list");
            # select genus, specificepithet, count(*) as count from records_list where lower(country)='united states' group by genus, specificepithet order by genus, specificepithet
            $searchCountry = strtolower($db->sanitize($_REQUEST["country"]));
            # Test the country
            $tQuery = "SELECT DISTINCT LOWER(country) FROM ".$db->getTable()." AS records $authorizedIntersect records.project_id WHERE country IS NOT NULL";
            $cr = mysqli_query($db->getLink(), $tQuery);
            if ($cr === false) {
                returnAjax(array(
                    "status" => false,
                    "error" => "DATABASE_ERROR_0",
                ));
            }
            $validCountries = array();
            while ($row = mysqli_fetch_row($cr)) {
                $validCountries[] = $row[0];
            }
            if (!in_array($searchCountry, $validCountries)) {
                returnAjax(array(
                    "status" => false,
                    "error" => "COUNTRY_NOT_FOUND",
                    "taxa" => 0,
                    "country" => $searchCountry,
                    "countries_with_data" => $validCountries,
                ));
            }
            # Get the list
            $query = "SELECT genus, specificepithet, diseasedetected, count(*) as count FROM `".$db->getTable()."` AS records $authorizedIntersect records.project_id  WHERE LOWER(country)='".$searchCountry."' GROUP BY genus, specificepithet, diseasedetected ORDER BY genus, specificepithet, diseasedetected DESC";
            $r = mysqli_query($db->getLink(), $query);
            if ($r === false) {
                returnAjax(array(
                    "status" => false,
                    "error" => "DATABASE_ERROR_1",
                ));
            }
            $localeTaxonData = array();
            $taxa = 0;
            while ($row = mysqli_fetch_assoc($r)) {
                $taxon = $row["genus"] . " " . $row["specificepithet"];
                if (!isset($localeTaxonData[$taxon])) {
                    $localeTaxonData[$taxon] = array(
                        "true" => 0,
                        "false" => 0,
                        "no_confidence" => 0,
                    );
                    $taxa++;
                }
                $key = is_bool($row["diseasedetected"]) ? strbool($row["diseasedetected"]) : $row["diseasedetected"];
                $localeTaxonData[$taxon][$key] = $row["count"];
            }
            returnAjax(array(
                "status" => true,
                "country" => $searchCountry,
                "taxa" => $taxa,
                "data" => $localeTaxonData,
            ));
            break;
        case "taxon_exists":
            $db->setTable("records_list");
            $taxonStringParts = explode(" ", deEscape($_REQUEST["taxon"]));
            $genus = $db->sanitize(strtolower($taxonStringParts[0]));
            $species = $db->sanitize(strtolower($taxonStringParts[1]));
            $query = "SELECT count(*) AS count FROM `".$db->getTable()."` AS records $authorizedIntersect records.project_id  WHERE lower(`genus`) = '$genus'";
            if (!empty($species)) {
                $query .= " AND lower(`specificepithet`) = '$species'";
            }
            $r = mysqli_query($db->getLink(), $query);
            if ($r === false) {
                returnAjax(array(
                    "status"  => false,
                    "error" => "DATABASE_ERROR_2",
                    // "query" => $query,
                    // "dberr" => mysqli_error($db->getLink()),
                ));
            }
            $row = mysqli_fetch_row($r);
            $response = array(
                "status" => true,
                "exists" => $row[0] > 0,
                "taxon" => array(
                    "provided" => deEscape($_REQUEST["taxon"]),
                    "interpreted" => array(
                        "genus" => $genus,
                        "species" => $species,
                        "dwc" => array(
                            "genus" => $genus,
                            "specificepithet" => $species,
                        ),
                    ),
                ));
            returnAjax($response);
            break;
        case "locale_taxon":
        default:
            returnAjax(array(
                "status" => false,
                "error" => "INVALID_ACTION",
                "action" => $_REQUEST["action"]
            ));
    }
}

?>
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
?>
    <title>Data Dashboard</title>
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
    <link rel="import" href="bower_components/iron-icons/maps-icons.html"/>
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
    <script type="text/javascript">
      // Initial script
      <?php
        if (isset($_REQUEST["taxon"])) {  ?>
      window.noDefaultRender = true;
      <?php
        }
        ?>
    </script>
    <script type="text/javascript" src="js/c.min.js"></script>
    <script type="text/javascript" src="js/dashboard.js"></script>
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
      paper-progress.top10-progress {
      --paper-progress-active-color: rgb(220,30,25);
      --paper-progress-secondary-color: rgb(25,70,220);
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
        if (!empty($pid)) {
?>
      <paper-icon-button icon="icons:language" class="click" data-toggle="tooltip" title="Project Browser" data-href="https://amphibiandisease.org/project.php" data-placement="bottom"> </paper-icon-button>
        <?php
        }
?>
      <paper-icon-button icon="icons:account-box" class="click" data-toggle="tooltip" title="Profiles" data-href="https://amphibiandisease.org/profile.php" data-placement="bottom"> </paper-icon-button>
      <paper-icon-button icon="icons:home" class="click" data-href="https://amphibiandisease.org" data-toggle="tooltip" title="Home" data-placement="bottom"></paper-icon-button>
    </p>
  </header>
  <main class="row">
    <?php
            # Handle taxon
            if (isset($_REQUEST["taxon"])) {
                try {
                    $taxonStringParts = explode(" ", deEscape($_REQUEST["taxon"]));
                    $genus = $taxonStringParts[0];
                    $species = $taxonStringParts[1];
                    ?>
    <script type="text/javascript">
      var activeTaxon = {genus: "<?php echo $genus; ?>", species: "<?php echo $species; ?>"};
      var noDefaultRender = true;
      startLoad();
      fetchMiniTaxonBlurb(activeTaxon, "section#taxon-detail");
    </script>
    <section id="taxon-detail" class="col-xs-12">

    </section>
  </main>
  <?php
    require_once("./footer.php");
    ?>
</body>
</html>
                    <?php
                } catch (Exception $e) {
                    ?>
    <h2 class="col-xs-12">
      Invalid taxon
    </h2>
    <p class="col-xs-12">
      Please try again.
    </p>
                    <?php
                }
                die();
            }
            # See
            # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/176
            # for scope and features

            # Fetch aggregate stats
    ?>
    <h2 class="col-xs-12">
      Data Dashboard <span class="badge">ALPHA</span>
      <br/>
      <small>Visualize data for all <?php if($loginStatus["status"] === true) echo "authorized and "; ?>publicly accessible projects</small>
    </h2>
    <div class="col-xs-12 tab-area-grandparent">
      <div class="tab-area-container">
        <ul class="nav nav-tabs" role="tablist">
          <li role="presentation" class="active">
            <a href="#charts" aria-controls="charts" role="tab" data-toggle="tab">Charts</a>
          </li>
          <li role="presentation">
            <a href="#list" aria-controls="list" role="tab" data-toggle="tab">List</a>
          </li>
        </ul>
        <div class="tab-content">
          <div role="tabpanel" class="tab-pane row fade active in" id="charts">
            <section class="col-xs-12">
              <div class="row db-summary-region">
                <?php

                /***
                 * Get some summary stats
                 * See:
                 * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/176#issuecomment-288560111
                 ***/
                # Species count
                $query = "select `genus`, `specificepithet`, count(*) as count from `records_list` AS records $authorizedIntersect records.project_id  where genus is not null group by genus, specificepithet";
                $r = mysqli_query($db->getLink(), $query);
                $speciesCount = mysqli_num_rows($r);
                # Total samples
                $query = "select count(*) as count from `records_list` AS records $authorizedIntersect records.project_id  where genus is not null";
                $r = mysqli_query($db->getLink(), $query);
                $row = mysqli_fetch_row($r);
                $count = $row[0];
                # Country count
                $query = "select country, count(*) as count from `records_list` AS records $authorizedIntersect records.project_id   where genus is not null group by country";
                $r = mysqli_query($db->getLink(), $query);
                $countryCount = mysqli_num_rows($r);
                ## Top 10
                ## See
                ## https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/232
                $queryCountryTop10N = "select `country`, count(*) as count from `records_list`  AS records $authorizedIntersect records.project_id  where `genus` is not null group by `country` order by count desc limit 10";
                $querySpeciesTop10N = "select `genus`, `specificepithet`, count(*) as count from `records_list`  AS records $authorizedIntersect records.project_id  where `genus` is not null group by `genus`, `specificepithet` order by count desc limit 10";
                $top10CountryTBody = array();
                $top10SpeciesTBody = array();
                $rCN = mysqli_query($db->getLink(), $queryCountryTop10N);
                $rSN = mysqli_query($db->getLink(), $querySpeciesTop10N);
                $i = 0;
                while ($row = mysqli_fetch_assoc($rCN)) {
                    if ($i == 0) {
                        $max = intval($row["count"]);
                    }
                    $queryCountryTop10P = "select `country`, count(*) as count from `records_list` AS records $authorizedIntersect records.project_id where `genus` is not null AND (`diseasedetected` is true or lower(`diseasedetected`)='true') AND `country`='".$row["country"]."' group by `country` order by count desc limit 10";
                      $rCP = mysqli_query($db->getLink(), $queryCountryTop10P);
                      $rowPos = mysqli_fetch_assoc($rCP);
                      $progressPositive = 100 * intval($rowPos["count"]) / $max;
                      $progressNegative = 100 * intval($row["count"]) / $max;
                      $progressBar = "<paper-progress value='$progressPositive' secondary-progress='$progressNegative' class='top10-progress'></paper-progress>";
                      $top10CountryTBody[] = "<td>".$row["country"]."</td><td>$progressBar</td><td>".$row["count"]."</td>";
                      $i++;
                }
                $top10CountryCont = "<tr>".implode("</tr><tr>", $top10CountryTBody)."</tr>";
                $i = 0;
                while ($row = mysqli_fetch_assoc($rSN)) {
                    if ($i == 0) {
                        $max = intval($row["count"]);
                    }
                    $querySpeciesTop10P = "select `genus`, `specificepithet`, count(*) as count from `records_list` AS records $authorizedIntersect records.project_id   where `genus` is not null AND (`diseasedetected` is true or lower(`diseasedetected`)='true') AND `genus`='".$row["genus"]."' AND `specificepithet`='".$row["specificepithet"]."'  group by `genus`, `specificepithet` order by count desc limit 10";
                    $rSP = mysqli_query($db->getLink(), $querySpeciesTop10P);
                    $rowPos = mysqli_fetch_assoc($rSP);
                    $progressNegative = 100 * intval($row["count"]) / $max;
                    $progressPositive = 100 * intval($rowPos["count"]) / $max;
                    $progressBar = "<paper-progress value='$progressPositive' secondary-progress='$progressNegative' class='top10-progress'></paper-progress>";
                    $top10SpeciesTBody[] = "<td><span class='sciname'><span class='genus'>".$row["genus"]."</span> <span class='species'>".$row["specificepithet"]."</span></span></td><td>$progressBar</td><td>".$row["count"]."</td>";
                    $i++;
                }
                $top10SpeciesCont = "<tr>".implode("</tr><tr>", $top10SpeciesTBody)."</tr>";
                ?>
                <div class="col-xs-12 col-md-6 table-responsive">
                  <table class="table table-striped table-bordered table-condensed">
                    <thead>
                      <tr>
                        <th>
                          Total Samples
                        </th>
                        <th>
                          Number of Species
                        </th>
                        <th>
                          Number of Countries
                        </th>
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
                <div class="col-xs-12">
                  <button type="button" class="btn btn-info collapse-trigger" data-target="#top-ten-collapse" id="top-ten-collapse-button-trigger">
                    Toggle View of Top Ten Countries &amp; Taxa
                  </button>
                  <iron-collapse id="top-ten-collapse">
                    <div class="collapse-content row">
                      <div class="col-xs-12 col-md-6 table-responsive">
                        <table class="table table-striped table-bordered table-condensed">
                          <thead>
                            <tr>
                              <th>
                                Country
                              </th>
                              <th>
                                Relative
                              </th>
                              <th>
                                Count
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            <?php echo $top10CountryCont;
                                  ?>
                          </tbody>
                        </table>
                      </div>
                      <div class="col-xs-12 col-md-6 table-responsive">
                        <table class="table table-striped table-bordered table-condensed">
                          <thead>
                            <tr>
                              <th>
                                Taxon
                              </th>
                              <th>
                                Relative
                              </th>
                              <th>
                                Count
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            <?php echo $top10SpeciesCont;
                                  ?>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </iron-collapse>
                </div>
              </div>
            </section>
            <section class="col-xs-12">
              <div class="form form-horizontal row">
                <h3 class="col-xs-12">Create a chart</h3>
                <div class="col-xs-12 col-md-3 col-sm-6" style="margin-top: 1em">
                  <paper-radio-group id="diseasetested-select" selected="both">
                    <paper-radio-button id="bd-only" data-disease="bd" name="bd"><span class='sciname'>B. d.</span></paper-radio-button>
                    <paper-radio-button id="bsal-only" data-disease="bsal" name="bsal"><span class='sciname'>B. sal.</span></paper-radio-button>
                    <paper-radio-button id="bd-bsal" data-disease="both" name="both">Both</paper-radio-button>
                  </paper-radio-group>
                </div>
                <div class="col-xs-12 col-md-3 col-sm-6">
                  <paper-dropdown-menu label="View" id="view-type"  class="chart-param" data-key="view">
                    <paper-listbox class="dropdown-content" selected="0">
                      <paper-item>Sample Counts</paper-item>
                      <paper-item disabled>Project Count</paper-item>
                      <paper-item disabled>Infection Rate</paper-item>
                    </paper-listbox>
                  </paper-dropdown-menu>
                </div>
                <div class="col-xs-12 col-md-3 col-sm-6">
                  <paper-dropdown-menu label="Binned By" id="binned-by"  data-key="bin" class="chart-param">
                    <paper-listbox class="dropdown-content" selected="0">
                      <paper-item>Location</paper-item>
                      <paper-item data-value="species">Taxon Group</paper-item>
                      <paper-item> Infection </paper-item>
                      <paper-item disabled>Time</paper-item>
                    </paper-listbox>
                  </paper-dropdown-menu>
                </div>
                <div class="col-xs-12 col-md-3 col-sm-6">
                  <paper-dropdown-menu label="Sort By" id="sort-by"  data-key="sort" class="chart-param">
                    <paper-listbox class="dropdown-content" selected="0">
                      <paper-item data-bins="location,species" data-value="samples">Samples</paper-item>
                      <paper-item data-bins="infection,location" data-value="percent-infected">Percent infected</paper-item>
                      <paper-item data-bins="location" data-value="country">Country</paper-item>
                      <paper-item data-bins="species" data-value="genus">Genus</paper-item>
                      <paper-item data-bins="species" data-value="species">Species</paper-item>
                      <paper-item disabled>Time</paper-item>
                    </paper-listbox>
                  </paper-dropdown-menu>
                </div>
                <div class="col-xs-12">
                  <button class="btn btn-success" id="generate-chart">Generate Chart</button>
                  <paper-toggle-button id="include-unnamed" class="chart-param" data-key="include_sp">Include Unnamed Species (eg, <i>Rana sp.</i>)</paper-toggle-button>
                </div>
              </div>
              <div class="col-xs-12 clearfix" id="locale-zoom-canvas-container">
                <canvas id="locale-zoom-chart">

                </canvas>
              </div>
            </section>
          </div> <!-- .tab-pane -->
          <div role="tabpanel" class="tab-pane row fade" id="list">
            <h3 class="col-xs-12">Species Lists</h3>
            <p class="col-xs-12">Below follows a list of taxa for which data exists here:</p>
            <?php
            /***
             * Show a list of all the (authorized) species on the
             * dashboard. See issue:
             * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/204
             ***/
            $query = "select distinct `genus`, `specificepithet`, `order`, `family`, `subfamily` from `records_list` AS records $authorizedIntersect records.project_id WHERE genus IS NOT NULL ORDER BY `order`, family, subfamily, genus, specificepithet";
            $r = mysqli_query($db->getLink(), $query);
            $speciesCount = mysqli_num_rows($r);
            $html = "";
            $usedOrder = array();
            $usedFamily = array();
            $usedSubfamily = array();
            $unsorted = array();
            while ($row = mysqli_fetch_assoc($r)) {
                if (empty($row["order"]) || strtolower($row["order"]) == "null") {
                    $unsorted[] = $row;
                    continue;
                }
                if (!in_array($row["order"], $usedOrder)) {
                    $html .= "<h2 class='order-label'>".$row["order"]."</h2>";
                    $usedOrder[] = $row["order"];
                }
                if (!in_array($row["family"], $usedFamily)) {
                    $html .= "<h3 class='family-label'>".$row["family"]."</h3>";
                    $usedFamily[] = $row["family"];
                }
                if (!in_array($row["subfamily"], $usedSubfamily)) {
                    $html .= "<h4 class='subfamily-label'>".$row["subfamily"]."</h4>";
                    $usedSubfamily[] = $row["subfamily"];
                }
                $html .= "<p class='species-list-label'>".$row["genus"]." ".$row["specificepithet"]."</p>
<button class='btn btn-default species-list-button aweb-button click' data-href='http://amphibiaweb.org/cgi/amphib_query?rel-genus=equals&rel-species=equals&where-genus=".$row["genus"]."&where-species=".$row["specificepithet"]."' data-newtab='true'>AmphibiaWeb <iron-icon icon='icons:open-in-new'></iron-icon></button>
<button class='btn btn-default species-list-button data-summary-button click' data-href='https://amphibiandisease.org/dashboard.php?taxon=".$row["genus"]."+".$row["specificepithet"]."'>Portal Stats</button>
<br/>";
            }
            if (!empty($unsorted)) {
                $html .= "<h2 class='order-label'>Taxa with no higher data</h2>";
                foreach ($unsorted as $row) {
                    $html .= "<p class='species-list-label'>".$row["genus"]." ".$row["specificepithet"]."</p>
            <button class='btn btn-default species-list-button aweb-button click' data-href='http://amphibiaweb.org/cgi/amphib_query?rel-genus=equals&rel-species=equals&where-genus=".$row["genus"]."&where-species=".$row["specificepithet"]."' data-newtab='true'>AmphibiaWeb <iron-icon icon='icons:open-in-new'></iron-icon></button>
            <button class='btn btn-default species-list-button data-summary-button click' data-href='https://amphibiandisease.org/dashboard.php?taxon=".$row["genus"]."+".$row["specificepithet"]."'>Portal Stats</button>
            <br/>";
                }
            }
if (empty($html)) $html = $query;
                ?>
            <section class="col-xs-12 species-list"><?php echo $html; ?></section>
          </div>
        </div> <!-- .tab-content -->
      </div> <!-- .tab-area-container -->
    </div> <!-- .tab-area-grandparent -->
  </main>
    <?php
    require_once("./footer.php");
?>
</body>
</html>
