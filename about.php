<!DOCTYPE html>
<html>
  <head>
<?php
$debug = false;

if ($debug) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
    error_log('About page is running in debug mode!');
}

$print_login_state = false;
require_once 'DB_CONFIG.php';
require_once dirname(__FILE__).'/core/core.php';
require_once dirname(__FILE__).'/admin/async_login_handler.php';

$db = new DBHelper($default_database, $default_sql_user, $default_sql_password, $sql_url, $default_table, $db_cols);
$loginStatus = getLoginState();
?>
    <title>About the Amphibian Disease Portal</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta charset="UTF-8"/>
    <meta name="theme-color" content="#5677fc"/>
    <meta name="viewport" content="width=device-width, minimum-scale=1, initial-scale=1, maximum-scale=1.0, user-scalable=0" />

    <link rel="stylesheet" type="text/css" media="screen" href="css/main.css"/>
    <link rel="stylesheet" href="https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css" />
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
    <link rel="import" href="bower_components/paper-spinner/paper-spinner.html"/>
    <link rel="import" href="bower_components/paper-slider/paper-slider.html"/>
    <link rel="import" href="bower_components/paper-menu/paper-menu.html"/>
    <link rel="import" href="bower_components/paper-dialog/paper-dialog.html"/>
    <link rel="import" href="bower_components/paper-radio-group/paper-radio-group.html"/>
    <link rel="import" href="bower_components/paper-radio-button/paper-radio-button.html"/>
    <link rel="import" href="bower_components/paper-dialog-scrollable/paper-dialog-scrollable.html"/>
    <link rel="import" href="bower_components/paper-button/paper-button.html"/>
    <link rel="import" href="bower_components/paper-icon-button/paper-icon-button.html"/>
    <link rel="import" href="bower_components/paper-menu-button/paper-menu-button.html"/>


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

    <script type="text/javascript" src="js/c.min.js"></script>

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
        <paper-icon-button icon="icons:home" class="click" data-href="https://amphibiandisease.org" data-toggle="tooltip" title="Home" data-placement="bottom"></paper-icon-button>
        <paper-icon-button icon="icons:language" class="click" data-toggle="tooltip" title="Project Browser" data-href="https://amphibiandisease.org/project.php" data-placement="bottom"> </paper-icon-button>
        <paper-icon-button icon="icons:account-box" class="click" data-toggle="tooltip" title="Profiles" data-href="https://amphibiandisease.org/profile.php" data-placement="bottom"> </paper-icon-button>
        </p>
    </header>
    <main>
      <h1 id="title" class="main-title">About</h1>
      <section id="main-body" class="row">
        <div class="text-wrapper col-xs-12">
          <h2 id="data-use-policy-and-information">
            Data Use Policy and Information
          </h2>

          <p>A necessary part of a project that solicits, stores and
          shares data is a clear understanding of the data sharing and
          use policy.</p>

          <h3 id="goals">Goals</h3>
          <p>The aim of the Amphibian Disease portal is to facilitate
          data sharing of chytrid disease presence and absence from
          field and lab studies, which we view as the first step to
          effectively address the global amphibian crisis. We aim to
          encourage collaboration and facilitate coordination among
          researchers and agencies involved in amphibian disease
          studies, particularly chytridiomycosis.</p>

          <h3 id="data">Data</h3>
          <ol>
            <li><strong>Contributors and Users</strong> <br/> We refer
              to individuals who upload datasets and project information
              as Contributors. We refer to individuals who download or
              otherwise use data on the portal and the website as
              Users. We will never share Contributor information that is
              not public on the site.</li>

            <li><strong>Ownership of Data</strong> <br/> The Amphibian
              Disease Portal (http://amphibiandisease.org) is developed
              and maintained by the AmphibiaWeb Project, Museum of
              Vertebrate Zoology, University of California, Berkeley. As
              a non-profit, educational and research entity, this is a
              public domain database and website that supplies data
              freely. We offer no guarantees or warranty, implied or
              explicit, about the completeness or accuracy of data nor
              its most appropriate use. We provide data for use in
              research and education only requesting attribution to the
              Contributor. We appreciate acknowledgement to the
              Amphibian Disease Portal and AmphibiaWeb.</li>

            <li><strong>Accuracy</strong> <br/> To the best of their
              abilities, Contributors will provide accurate and complete
              data. The expectation is one of good faith representation
              of data that you fully own and control to be uploaded to
              the Amphibian Disease Portal. Geocoordinates for sensitive
              species or sites may not be purposely obscured. If there
              are legitimate reasons to protect localities, it is
              preferred to encumber data, i.e., keep private (see
              Embargo Policy).</li>

            <li><strong>Data Licensing</strong> <br/> Contributors upon
              uploading data to the Portal agrees to these terms and
              specifically allowing us to assign unique digital object
              identifiers to projects and datasets under <a href="https://creativecommons.org/licenses/by/3.0/">Creative
              Commons Attribution 3.0</a></li>

            <li><strong>Public Availability and Embargo
                Policy</strong> <br/> We recognize that data on some point
              records may be deemed premature for public use, such as
              graduate student dissertations or other active research
              projects. We need to balance that with the intent of the
              Portal to facilitate collaborations and aggregate data to
              study disease. Thus, basic information on Projects will be
              publicly viewable (e.g., Principal Investigator, Contact
              name, basic abstract, generalized area of interest to be
              determined by Contributor) and will be accessible on the
              portal without user registration and be subject to search
              engine results.  Datasets (point records) associated with
              projects are private by default until the Contributor
              chooses to make those data public. Once made public, it
              may not be revoked. We recommend projects and their
              datasets be made fully public within 2 years or whenever
              the datasets are first published (including
              dissertations). If Contributors have not made their data
              public within 2 years and have not requested a
              continuance, we reserve the right to make these data
              public.</li>
          </ol>
          <p> <a href="mailto:amphibiaweb+data@berkeley.edu">Email us feedback and any
          suggestions or questions.</a></p>
          <h2> Project License </h2>
          <p>
            This project is <a href="https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/LICENSE">licensed under the GNU General Public License</a>. The full source code is available at <a href="https://github.com/AmphibiaWeb/amphibian-disease-tracker">https://github.com/AmphibiaWeb/amphibian-disease-tracker</a>.
          </p>
          <h2>
            Privacy
          </h2>
          <p>
            This site only retains basic information that you provide on registration, and basic session information such as your last login IP address.
          </p>
          <p>
            We do use cookies to manage your authentication and one-time notices.
          </p>
          <p>
            Your password is stored according to best practices, with a <a href="https://en.wikipedia.org/wiki/Salt_(cryptography)">salted</a> <a href="https://en.wikipedia.org/wiki/Cryptographic_hash_function">hash</a> stored with 10,000 of <a href="https://en.wikipedia.org/wiki/PBKDF2">PBKDF2</a>. Your data is physically located on servers at UC Berkeley.
          </p>
          <h3>GDPR Compliance</h3>
          <p>
                All personal information we collect about you, other than transient information like your last login IP address and time, is available from <a href="profile.php">your personal profile page</a>. If it's not visible on that page, we don't have that information about you.
          </p>
          <p>
                Your basic contact data is visible to others to the extent configured on your profile page, and is searchable when adding collaborators or filtering projects.
          </p>
          <p>
                Any new session irretrievably overwrites old transient data about you, and such transient data only reflects your current session (not historical). You may delete your account permanantly and irretrievably by visiting your dashboard, going to account settings, expanding the "more" button, and selecting "Remove Account".
          </p>
          <h2>Disclaimer</h2>
          <h3>Use of Data</h3>
          <p>
            amphibiandisease.org is a public database created for the
            purpose of education and scientific investigation. These
            data are not confirmed as official
            results. amphibiandisease.org does not offer any warranty
            or representation, expressed or implied, about data
            accuracy, completeness, or appropriateness for a
            particular purpose. You assume full responsibility for
            using amphibiandisease.org data or information presented
            on its website. You understand and agree that neither
            amphibiandisease.org nor its Partners are responsible or
            liable for any claim, loss or damage resulting from the
            use of amphibiandisease.org website. See <a href="https://github.com/AmphibiaWeb/amphibian-disease-tracker/blob/master/LICENSE">the text of the
            GPL license</a> for more information on warranty and liability
            disclaimers.
          </p>
          <h3>
          No Regulatory Authority
          </h3>
          <p>
          amphibiandisease.org has no regulatory authority, and
          submitting data to it does not constitute an official
          pathogen-reporting record.
          </p>
        </div>
      </section>
    </main>
<?php
   require_once("./footer.php");
   ?>
  </body>
</html>
