
/*
 *
 *
 *
 * See
 * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/48
 */
var apiTarget, cascadePrivacyToggledState, cleanupAddressDisplay, conditionalLoadAccountSettingsOptions, constructProfileJson, copyLink, forceUpdateMarked, formatSocial, getProfilePrivacy, imageHandler, initialCascadeSetup, isoCountries, loadUserBadges, profileAction, renderCaptchas, saveProfileChanges, searchProfiles, setupProfileImageUpload, setupUserChat, validateAddress, verifyLoginCredentials;

profileAction = "update_profile";

apiTarget = uri.urlString + "/admin-api.php";

window._adp = new Object();


/*
 * Country codes:
 * https://raw.githubusercontent.com/OpenBookPrices/country-data/master/data/countries.json
 *
 * Formatted via
 *
 * result = subject.replace(/ +"([A-Z]{2})": +\{\r\n +"name": +"(([\w (),'&-]|\\u00[a-z])+)"(,\r\n +"code": +"\+?([\d ]+)")?\r\n +\},?/mg, '  $1:\r\n    name: "$2"\r\n    code: "$5"');
 *
 * Then removing the leading and trailing {}
 */

isoCountries = {
  ZW: {
    name: "Zimbabwe",
    code: "263"
  },
  ZM: {
    name: "Zambia",
    code: "260"
  },
  ZA: {
    name: "South Africa",
    code: "27"
  },
  YT: {
    name: "Mayotte",
    code: "262"
  },
  YE: {
    name: "Yemen",
    code: "967"
  },
  XK: {
    name: "Kosovo",
    code: "383"
  },
  WS: {
    name: "Samoa",
    code: "685"
  },
  WF: {
    name: "Wallis And Futuna",
    code: "681"
  },
  VU: {
    name: "Vanuatu",
    code: "678"
  },
  VN: {
    name: "Viet Nam",
    code: "84"
  },
  VI: {
    name: "Virgin Islands (US)",
    code: "1 340"
  },
  VG: {
    name: "Virgin Islands (British)",
    code: "1 284"
  },
  VE: {
    name: "Venezuela, Bolivarian Republic Of",
    code: "58"
  },
  VC: {
    name: "Saint Vincent And The Grenadines",
    code: "1 784"
  },
  VA: {
    name: "Vatican City State",
    code: "379"
  },
  UZ: {
    name: "Uzbekistan",
    code: "998"
  },
  UY: {
    name: "Uruguay",
    code: "598"
  },
  US: {
    name: "United States",
    code: "1"
  },
  UM: {
    name: "United States Minor Outlying Islands",
    code: "1"
  },
  UK: {
    name: "United Kingdom",
    code: ""
  },
  UG: {
    name: "Uganda",
    code: "256"
  },
  UA: {
    name: "Ukraine",
    code: "380"
  },
  TZ: {
    name: "Tanzania, United Republic Of",
    code: "255"
  },
  TW: {
    name: "Taiwan",
    code: "886"
  },
  TV: {
    name: "Tuvalu",
    code: "688"
  },
  TT: {
    name: "Trinidad And Tobago",
    code: "1 868"
  },
  TR: {
    name: "Turkey",
    code: "90"
  },
  TO: {
    name: "Tonga",
    code: "676"
  },
  TN: {
    name: "Tunisia",
    code: "216"
  },
  TM: {
    name: "Turkmenistan",
    code: "993"
  },
  TL: {
    name: "Timor-Leste, Democratic Republic of",
    code: "670"
  },
  TK: {
    name: "Tokelau",
    code: "690"
  },
  TJ: {
    name: "Tajikistan",
    code: "992"
  },
  TH: {
    name: "Thailand",
    code: "66"
  },
  TG: {
    name: "Togo",
    code: "228"
  },
  TF: {
    name: "French Southern Territories",
    code: ""
  },
  TD: {
    name: "Chad",
    code: "235"
  },
  TC: {
    name: "Turks And Caicos Islands",
    code: "1 649"
  },
  TA: {
    name: "Tristan de Cunha",
    code: "290"
  },
  SZ: {
    name: "Swaziland",
    code: "268"
  },
  SY: {
    name: "Syrian Arab Republic",
    code: "963"
  },
  SX: {
    name: "Sint Maarten",
    code: "1 721"
  },
  SV: {
    name: "El Salvador",
    code: "503"
  },
  SU: {
    name: "USSR",
    code: ""
  },
  ST: {
    name: "S\u00ef\u00bf\u00bdo Tom\u00ef\u00bf\u00bd and Pr\u00ef\u00bf\u00bdncipe",
    code: "239"
  },
  SS: {
    name: "South Sudan",
    code: "211"
  },
  SR: {
    name: "Suriname",
    code: "597"
  },
  SO: {
    name: "Somalia",
    code: "252"
  },
  SN: {
    name: "Senegal",
    code: "221"
  },
  SM: {
    name: "San Marino",
    code: "378"
  },
  SL: {
    name: "Sierra Leone",
    code: "232"
  },
  SK: {
    name: "Slovakia",
    code: "421"
  },
  SJ: {
    name: "Svalbard And Jan Mayen",
    code: "47"
  },
  SI: {
    name: "Slovenia",
    code: "386"
  },
  SH: {
    name: "Saint Helena, Ascension And Tristan Da Cunha",
    code: "290"
  },
  SG: {
    name: "Singapore",
    code: "65"
  },
  SE: {
    name: "Sweden",
    code: "46"
  },
  SD: {
    name: "Sudan",
    code: "249"
  },
  SC: {
    name: "Seychelles",
    code: "248"
  },
  SB: {
    name: "Solomon Islands",
    code: "677"
  },
  SA: {
    name: "Saudi Arabia",
    code: "966"
  },
  RW: {
    name: "Rwanda",
    code: "250"
  },
  RU: {
    name: "Russian Federation",
    code: "7"
  },
  RS: {
    name: "Serbia",
    code: "381"
  },
  RO: {
    name: "Romania",
    code: "40"
  },
  RE: {
    name: "Reunion",
    code: "262"
  },
  QA: {
    name: "Qatar",
    code: "974"
  },
  PY: {
    name: "Paraguay",
    code: "595"
  },
  PW: {
    name: "Palau",
    code: "680"
  },
  PT: {
    name: "Portugal",
    code: "351"
  },
  PS: {
    name: "Palestinian Territory, Occupied",
    code: "970"
  },
  PR: {
    name: "Puerto Rico",
    code: "1 787"
  },
  PN: {
    name: "Pitcairn",
    code: "872"
  },
  PM: {
    name: "Saint Pierre And Miquelon",
    code: "508"
  },
  PL: {
    name: "Poland",
    code: "48"
  },
  PK: {
    name: "Pakistan",
    code: "92"
  },
  PH: {
    name: "Philippines",
    code: "63"
  },
  PG: {
    name: "Papua New Guinea",
    code: "675"
  },
  PF: {
    name: "French Polynesia",
    code: "689"
  },
  PE: {
    name: "Peru",
    code: "51"
  },
  PA: {
    name: "Panama",
    code: "507"
  },
  OM: {
    name: "Oman",
    code: "968"
  },
  NZ: {
    name: "New Zealand",
    code: "64"
  },
  NU: {
    name: "Niue",
    code: "683"
  },
  NR: {
    name: "Nauru",
    code: "674"
  },
  NP: {
    name: "Nepal",
    code: "977"
  },
  NO: {
    name: "Norway",
    code: "47"
  },
  NL: {
    name: "Netherlands",
    code: "31"
  },
  NI: {
    name: "Nicaragua",
    code: "505"
  },
  NG: {
    name: "Nigeria",
    code: "234"
  },
  NF: {
    name: "Norfolk Island",
    code: "672"
  },
  NE: {
    name: "Niger",
    code: "227"
  },
  NC: {
    name: "New Caledonia",
    code: "687"
  },
  NA: {
    name: "Namibia",
    code: "264"
  },
  MZ: {
    name: "Mozambique",
    code: "258"
  },
  MY: {
    name: "Malaysia",
    code: "60"
  },
  MX: {
    name: "Mexico",
    code: "52"
  },
  MW: {
    name: "Malawi",
    code: "265"
  },
  MV: {
    name: "Maldives",
    code: "960"
  },
  MU: {
    name: "Mauritius",
    code: "230"
  },
  MT: {
    name: "Malta",
    code: "356"
  },
  MS: {
    name: "Montserrat",
    code: "1 664"
  },
  MR: {
    name: "Mauritania",
    code: "222"
  },
  MQ: {
    name: "Martinique",
    code: "596"
  },
  MP: {
    name: "Northern Mariana Islands",
    code: "1 670"
  },
  MO: {
    name: "Macao",
    code: "853"
  },
  MN: {
    name: "Mongolia",
    code: "976"
  },
  MM: {
    name: "Myanmar",
    code: "95"
  },
  ML: {
    name: "Mali",
    code: "223"
  },
  MK: {
    name: "Macedonia, The Former Yugoslav Republic Of",
    code: "389"
  },
  MH: {
    name: "Marshall Islands",
    code: "692"
  },
  MG: {
    name: "Madagascar",
    code: "261"
  },
  MF: {
    name: "Saint Martin",
    code: "590"
  },
  ME: {
    name: "Montenegro",
    code: "382"
  },
  MD: {
    name: "Moldova",
    code: "373"
  },
  MC: {
    name: "Monaco",
    code: "377"
  },
  MA: {
    name: "Morocco",
    code: "212"
  },
  LY: {
    name: "Libya",
    code: "218"
  },
  LV: {
    name: "Latvia",
    code: "371"
  },
  LU: {
    name: "Luxembourg",
    code: "352"
  },
  LT: {
    name: "Lithuania",
    code: "370"
  },
  LS: {
    name: "Lesotho",
    code: "266"
  },
  LR: {
    name: "Liberia",
    code: "231"
  },
  LK: {
    name: "Sri Lanka",
    code: "94"
  },
  LI: {
    name: "Liechtenstein",
    code: "423"
  },
  LC: {
    name: "Saint Lucia",
    code: "1 758"
  },
  LB: {
    name: "Lebanon",
    code: "961"
  },
  LA: {
    name: "Lao People's Democratic Republic",
    code: "856"
  },
  KZ: {
    name: "Kazakhstan",
    code: "7"
  },
  KY: {
    name: "Cayman Islands",
    code: "1 345"
  },
  KW: {
    name: "Kuwait",
    code: "965"
  },
  KR: {
    name: "Korea, Republic Of",
    code: "82"
  },
  KP: {
    name: "Korea, Democratic People's Republic Of",
    code: "850"
  },
  KN: {
    name: "Saint Kitts And Nevis",
    code: "1 869"
  },
  KM: {
    name: "Comoros",
    code: "269"
  },
  KI: {
    name: "Kiribati",
    code: "686"
  },
  KH: {
    name: "Cambodia",
    code: "855"
  },
  KG: {
    name: "Kyrgyzstan",
    code: "996"
  },
  KE: {
    name: "Kenya",
    code: "254"
  },
  JP: {
    name: "Japan",
    code: "81"
  },
  JO: {
    name: "Jordan",
    code: "962"
  },
  JM: {
    name: "Jamaica",
    code: "1 876"
  },
  JE: {
    name: "Jersey",
    code: "44"
  },
  IT: {
    name: "Italy",
    code: "39"
  },
  IS: {
    name: "Iceland",
    code: "354"
  },
  IR: {
    name: "Iran, Islamic Republic Of",
    code: "98"
  },
  IQ: {
    name: "Iraq",
    code: "964"
  },
  IO: {
    name: "British Indian Ocean Territory",
    code: "246"
  },
  IN: {
    name: "India",
    code: "91"
  },
  IM: {
    name: "Isle Of Man",
    code: "44"
  },
  IL: {
    name: "Israel",
    code: "972"
  },
  IE: {
    name: "Ireland",
    code: "353"
  },
  ID: {
    name: "Indonesia",
    code: "62"
  },
  IC: {
    name: "Canary Islands",
    code: ""
  },
  HU: {
    name: "Hungary",
    code: "36"
  },
  HT: {
    name: "Haiti",
    code: "509"
  },
  HR: {
    name: "Croatia",
    code: "385"
  },
  HN: {
    name: "Honduras",
    code: "504"
  },
  HM: {
    name: "Heard Island And McDonald Islands",
    code: ""
  },
  HK: {
    name: "Hong Kong",
    code: "852"
  },
  GY: {
    name: "Guyana",
    code: "592"
  },
  GW: {
    name: "Guinea-bissau",
    code: "245"
  },
  GU: {
    name: "Guam",
    code: "1 671"
  },
  GT: {
    name: "Guatemala",
    code: "502"
  },
  GS: {
    name: "South Georgia And The South Sandwich Islands",
    code: ""
  },
  GR: {
    name: "Greece",
    code: "30"
  },
  GQ: {
    name: "Equatorial Guinea",
    code: "240"
  },
  GP: {
    name: "Guadeloupe",
    code: "590"
  },
  GN: {
    name: "Guinea",
    code: "224"
  },
  GM: {
    name: "Gambia",
    code: "220"
  },
  GL: {
    name: "Greenland",
    code: "299"
  },
  GI: {
    name: "Gibraltar",
    code: "350"
  },
  GH: {
    name: "Ghana",
    code: "233"
  },
  GG: {
    name: "Guernsey",
    code: "44"
  },
  GF: {
    name: "French Guiana",
    code: "594"
  },
  GE: {
    name: "Georgia",
    code: "995"
  },
  GD: {
    name: "Grenada",
    code: "473"
  },
  GB: {
    name: "United Kingdom",
    code: "44"
  },
  GA: {
    name: "Gabon",
    code: "241"
  },
  FX: {
    name: "France, Metropolitan",
    code: "241"
  },
  FR: {
    name: "France",
    code: "33"
  },
  FO: {
    name: "Faroe Islands",
    code: "298"
  },
  FM: {
    name: "Micronesia, Federated States Of",
    code: "691"
  },
  FK: {
    name: "Falkland Islands",
    code: "500"
  },
  FJ: {
    name: "Fiji",
    code: "679"
  },
  FI: {
    name: "Finland",
    code: "358"
  },
  EU: {
    name: "European Union",
    code: "388"
  },
  ET: {
    name: "Ethiopia",
    code: "251"
  },
  ES: {
    name: "Spain",
    code: "34"
  },
  ER: {
    name: "Eritrea",
    code: "291"
  },
  EH: {
    name: "Western Sahara",
    code: "212"
  },
  EG: {
    name: "Egypt",
    code: "20"
  },
  EE: {
    name: "Estonia",
    code: "372"
  },
  EC: {
    name: "Ecuador",
    code: "593"
  },
  EA: {
    name: "Ceuta, Mulilla",
    code: ""
  },
  DZ: {
    name: "Algeria",
    code: "213"
  },
  DO: {
    name: "Dominican Republic",
    code: "1 809"
  },
  DM: {
    name: "Dominica",
    code: "1 767"
  },
  DK: {
    name: "Denmark",
    code: "45"
  },
  DJ: {
    name: "Djibouti",
    code: "253"
  },
  DG: {
    name: "Diego Garcia",
    code: ""
  },
  DE: {
    name: "Germany",
    code: "49"
  },
  CZ: {
    name: "Czech Republic",
    code: "420"
  },
  CY: {
    name: "Cyprus",
    code: "357"
  },
  CX: {
    name: "Christmas Island",
    code: "61"
  },
  CW: {
    name: "Curacao",
    code: "599"
  },
  CV: {
    name: "Cabo Verde",
    code: "238"
  },
  CU: {
    name: "Cuba",
    code: "53"
  },
  CR: {
    name: "Costa Rica",
    code: "506"
  },
  CP: {
    name: "Clipperton Island",
    code: ""
  },
  CO: {
    name: "Colombia",
    code: "57"
  },
  CN: {
    name: "China",
    code: "86"
  },
  CM: {
    name: "Cameroon",
    code: "237"
  },
  CL: {
    name: "Chile",
    code: "56"
  },
  CK: {
    name: "Cook Islands",
    code: "682"
  },
  CI: {
    name: "Cote d'Ivoire",
    code: "225"
  },
  CH: {
    name: "Switzerland",
    code: "41"
  },
  CG: {
    name: "Republic Of Congo",
    code: "242"
  },
  CF: {
    name: "Central African Republic",
    code: "236"
  },
  CD: {
    name: "Democratic Republic Of Congo",
    code: "243"
  },
  CC: {
    name: "Cocos (Keeling) Islands",
    code: "61"
  },
  CA: {
    name: "Canada",
    code: "1"
  },
  BZ: {
    name: "Belize",
    code: "501"
  },
  BY: {
    name: "Belarus",
    code: "375"
  },
  BW: {
    name: "Botswana",
    code: "267"
  },
  BV: {
    name: "Bouvet Island",
    code: ""
  },
  BT: {
    name: "Bhutan",
    code: "975"
  },
  BS: {
    name: "Bahamas",
    code: "1 242"
  },
  BR: {
    name: "Brazil",
    code: "55"
  },
  BQ: {
    name: "Bonaire, Saint Eustatius And Saba",
    code: "599"
  },
  BO: {
    name: "Bolivia, Plurinational State Of",
    code: "591"
  },
  BN: {
    name: "Brunei Darussalam",
    code: "673"
  },
  BM: {
    name: "Bermuda",
    code: "1 441"
  },
  BL: {
    name: "Saint Barth\u00ef\u00bf\u00bdlemy",
    code: "590"
  },
  BJ: {
    name: "Benin",
    code: "229"
  },
  BI: {
    name: "Burundi",
    code: "257"
  },
  BH: {
    name: "Bahrain",
    code: "973"
  },
  BG: {
    name: "Bulgaria",
    code: "359"
  },
  BF: {
    name: "Burkina Faso",
    code: "226"
  },
  BE: {
    name: "Belgium",
    code: "32"
  },
  BD: {
    name: "Bangladesh",
    code: "880"
  },
  BB: {
    name: "Barbados",
    code: "1 246"
  },
  BA: {
    name: "Bosnia & Herzegovina",
    code: "387"
  },
  AZ: {
    name: "Azerbaijan",
    code: "994"
  },
  AX: {
    name: "\u00ef\u00bf\u00bdland Islands",
    code: "358"
  },
  AW: {
    name: "Aruba",
    code: "297"
  },
  AU: {
    name: "Australia",
    code: "61"
  },
  AT: {
    name: "Austria",
    code: "43"
  },
  AS: {
    name: "American Samoa",
    code: "1 684"
  },
  AR: {
    name: "Argentina",
    code: "54"
  },
  AQ: {
    name: "Antarctica",
    code: "672"
  },
  AO: {
    name: "Angola",
    code: "244"
  },
  AM: {
    name: "Armenia",
    code: "374"
  },
  AL: {
    name: "Albania",
    code: "355"
  },
  AI: {
    name: "Anguilla",
    code: "1 264"
  },
  AG: {
    name: "Antigua And Barbuda",
    code: "1 268"
  },
  AF: {
    name: "Afghanistan",
    code: "93"
  },
  AE: {
    name: "United Arab Emirates",
    code: "971"
  },
  AD: {
    name: "Andorra",
    code: "376"
  },
  AC: {
    name: "Ascension Island",
    code: "247"
  }
};

loadUserBadges = function() {

  /*
   *
   */
  return false;
};

setupProfileImageUpload = function(uploadFormId, bsColWidth, callback) {
  var author, html, placeIntoSelector, projectIdentifier, selector, uploadIdentifier;
  if (uploadFormId == null) {
    uploadFormId = "profile-image-uploader";
  }
  if (bsColWidth == null) {
    bsColWidth = "";
  }

  /*
   * Bootstrap an uploader for images
   */
  selector = "#" + uploadFormId;
  author = $.cookie(adminParams.domain + "_link");
  uploadIdentifier = window.profileUid;
  projectIdentifier = _adp.projectIdentifierString;
  if (!$(selector).exists()) {
    console.info("Creating uploader to append");
    html = "<form id=\"" + uploadFormId + "-form\" class=\"" + bsColWidth + " clearfix\">\n  <p class=\"visible-xs-block\">Tap the button to upload a file</p>\n  <fieldset class=\"hidden-xs\">\n    <legend class=\"sr-only\">Profile Image</legend>\n    <div id=\"" + uploadFormId + "\" class=\"media-uploader outline media-upload-target\">\n    </div>\n  </fieldset>\n</form>";
    placeIntoSelector = "main #upload-container-section";
    $(placeIntoSelector).append(html);
    if (!isNull(bsColWidth)) {
      $(placeIntoSelector).addClass("row");
    }
    console.info("Appended upload form", $(placeIntoSelector).exists());
    $(selector).submit(function(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
  }
  verifyLoginCredentials(function() {
    var needsInit;
    if (window.dropperParams == null) {
      window.dropperParams = new Object();
    }
    window.dropperParams.dropTargetSelector = selector;
    window.dropperParams.uploadPath = "../../users/profiles/";
    window.dropperParams.uploadText = "Drop your image here to set a new profile picture";
    needsInit = window.dropperParams.hasInitialized === true;
    loadJS("helpers/js-dragdrop/client-upload.min.js", function() {
      var error;
      window.dropperParams.mimeTypes = "image/*";
      console.info("Loaded drag drop helper");
      if (needsInit) {
        console.info("Reinitialized dropper");
        try {
          window.dropperParams.initialize();
        } catch (error) {
          console.warn("Couldn't reinitialize dropper!");
        }
      }
      window.dropperParams.postUploadHandler = function(file, result) {

        /*
         * The callback function for handleDragDropImage
         *
         * The "file" object contains information about the uploaded file,
         * such as name, height, width, size, type, and more. Check the
         * console logs in the demo for a full output.
         *
         * The result object contains the results of the upload. The "status"
         * key is true or false depending on the status of the upload, and
         * the other most useful keys will be "full_path" and "thumb_path".
         *
         * When invoked, it calls the "self" helper methods to actually do
         * the file sending.
         */
        var checkPath, cp2, e, error1, extension, fileName, linkPath, longType, mediaType, pathPrefix, previewHtml, thumbPath;
        window.dropperParams.dropzone.removeAllFiles();
        if (typeof result !== "object") {
          console.error("Dropzone returned an error - " + result);
          toastStatusMessage("There was a problem with the server handling your image. Please try again.");
          return false;
        }
        if (result.status !== true) {
          if (result.human_error == null) {
            result.human_error = "There was a problem uploading your image.";
          }
          toastStatusMessage("" + result.human_error);
          console.error("Error uploading!", result);
          return false;
        }
        try {
          console.info("Server returned the following result:", result);
          console.info("The script returned the following file information:", file);
          pathPrefix = window.dropperParams.uploadPath;
          fileName = result.full_path.split("/").pop();
          thumbPath = result.wrote_thumb;
          mediaType = result.mime_provided.split("/")[0];
          longType = result.mime_provided.split("/")[1];
          linkPath = file.size < 5 * 1024 * 1024 || mediaType !== "image" ? "" + pathPrefix + result.wrote_file : "" + pathPrefix + thumbPath;
          previewHtml = (function() {
            switch (mediaType) {
              case "image":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\" data-link-path=\"" + linkPath + "\">\n  <img src=\"" + linkPath + "\" alt='Uploaded Image' class=\"img-circle thumb-img img-responsive\"/>\n    <p class=\"text-muted\">\n      " + file.name + " -> " + fileName + "\n      (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n        Original Image\n      </a>)\n    </p>\n</div>";
              case "audio":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <audio src=\"" + linkPath + "\" controls preload=\"auto\">\n    <span class=\"glyphicon glyphicon-music\"></span>\n    <p>\n      Your browser doesn't support the HTML5 <code>audio</code> element.\n      Please download the file below.\n    </p>\n  </audio>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + fileName + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
              case "video":
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\">\n  <video src=\"" + linkPath + "\" controls preload=\"auto\">\n    <img src=\"" + pathPrefix + thumbPath + "\" alt=\"Video Thumbnail\" class=\"img-responsive\" />\n    <p>\n      Your browser doesn't support the HTML5 <code>video</code> element.\n      Please download the file below.\n    </p>\n  </video>\n  <p class=\"text-muted\">\n    " + file.name + " -> " + fileName + "\n    (<a href=\"" + linkPath + "\" class=\"newwindow\" download=\"" + file.name + "\">\n      Original Media\n    </a>)\n  </p>\n</div>";
              default:
                return "<div class=\"uploaded-media center-block\" data-system-file=\"" + fileName + "\" data-link-path=\"" + linkPath + "\">\n  <span class=\"glyphicon glyphicon-file\"></span>\n  <p class=\"text-muted\">" + file.name + " -> " + fileName + "</p>\n</div>";
            }
          })();
          $(window.dropperParams.dropTargetSelector).before(previewHtml);
          $("#validator-progress-container").remove();
          checkPath = linkPath.slice(0);
          cp2 = linkPath.slice(0);
          extension = cp2.split(".").pop();
          switch (mediaType) {
            case "application":
              console.info("Checking " + longType + " in application");
              switch (longType) {
                case "vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                case "vnd.ms-excel":
                  return excelHandler(linkPath);
                case "vnd.ms-office":
                  switch (extension) {
                    case "xls":
                      return excelHandler(linkPath);
                    default:
                      stopLoadError("Sorry, we didn't understand the upload type.");
                      return false;
                  }
                  break;
                case "zip":
                case "x-zip-compressed":
                  if (file.type === "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" || extension === "xlsx") {
                    return excelHandler(linkPath);
                  } else {
                    return zipHandler(linkPath);
                  }
                  break;
                case "x-7z-compressed":
                  return _7zHandler(linkPath);
              }
              break;
            case "text":
              return csvHandler(linkPath);
            case "image":
              return imageHandler(linkPath, result);
          }
        } catch (error1) {
          e = error1;
          console.error("There was a post-processing error: " + e.message);
          console.warn(e.stack);
          return toastStatusMessage("Your file uploaded successfully, but there was a problem in the post-processing.");
        }
      };
      if (typeof callback === "function") {
        return callback();
      }
    });
    return false;
  });
  return false;
};

imageHandler = function(path, ajaxResult) {
  var args, data, pdata, relativePath;
  if (ajaxResult == null) {
    ajaxResult = null;
  }

  /*
   * Take the image path provided and associate that with the user
   * profile iamge
   */
  startLoad();
  relativePath = path.replace(/^(\.\.\/)*([\w\/]+\.(jpg|jpeg|png|bmp|gif|webp|pnga))$/img, "$2");
  if (isNull(relativePath)) {
    console.error("Invalid path '" + path + "' parsed to invalid canonical path", relativePath);
    stopLoadError("Processing error. Please try again.");
    return false;
  }
  data = {
    profile_image_path: relativePath
  };
  console.log("Going to save", data);
  pdata = jsonTo64(data);
  args = "perform=write_profile_image&data=" + pdata;
  $.post(apiTarget, args, "json").done(function(result) {
    var message, ref, ref1;
    console.log("Save got", result);
    if (result.status !== true) {
      message = (ref = (ref1 = result.human_error) != null ? ref1 : result.error) != null ? ref : "Unknown error";
      stopLoadError("There was an error saving your profile image - " + message + ". Please try again later.");
      return false;
    }
    toastStatusMessage("Successfully updated your profile image");
    $(".profile-image").attr("src", relativePath);
    stopLoad();
    return false;
  }).fail(function(result, status) {
    console.error("Error!", result, status);
    stopLoadError("There was a problem saving to the server.");
    return false;
  });
  return false;
};

window.imageHandler = imageHandler;

getProfilePrivacy = function() {

  /*
   *
   */
  var i, j, len, len1, privacyGroup, privacyParams, privacyScope, privacyTarget, ref, toggle, toggles;
  privacyParams = new Object();
  ref = $(".privacy-group");
  for (i = 0, len = ref.length; i < len; i++) {
    privacyGroup = ref[i];
    privacyTarget = $(privacyGroup).attr("data-group");
    toggles = $(privacyGroup).find("paper-toggle-button");
    for (j = 0, len1 = toggles.length; j < len1; j++) {
      toggle = toggles[j];
      privacyScope = $(toggle).attr("data-scope");
      if (privacyParams[privacyTarget] == null) {
        privacyParams[privacyTarget] = new Object();
      }
      privacyParams[privacyTarget][privacyScope] = p$(toggle).checked;
    }
  }
  return privacyParams;
};

conditionalLoadAccountSettingsOptions = function() {

  /*
   * Verify the account ownership, and if true, provide options for
   * various account settings.
   *
   * Largely acts as links back to admin-login.php
   */
  return false;
};

constructProfileJson = function(encodeForPosting, callback) {
  var el, i, inputs, key, len, parentKey, privacy, response, tmp, val;
  if (encodeForPosting == null) {
    encodeForPosting = false;
  }

  /*
   * Read all the fields and return a JSON formatted for the database
   * field
   *
   * See Github Issue #48
   *
   * @param bool encodeForPosting -> when true, returns a URI-encoded
   *   base64 string, rather than an actual object.
   */
  response = false;
  if (typeof window.publicProfile === "object") {
    tmp = window.publicProfile;
  } else {
    tmp = new Object();
  }
  inputs = $(".profile-data:not(.from-base-profile) .user-input");
  for (i = 0, len = inputs.length; i < len; i++) {
    el = inputs[i];
    val = p$(el).value;
    key = $(el).attr("data-source");
    key = key.replace("-", "_");
    key = (function() {
      switch (key) {
        case "institution":
          return "name";
        default:
          return key;
      }
    })();
    parentKey = $(el).parents("[data-source]").attr("data-source");
    if (typeof tmp[parentKey] !== "object") {
      tmp[parentKey] = new Object();
    }
    tmp[parentKey][key] = val;
  }
  tmp.profile = p$("#bio-profile .user-input").value;
  privacy = getProfilePrivacy();
  tmp.privacy = privacy;
  validateAddress(tmp.institution, function(newAddressObj) {
    tmp.place = newAddressObj;
    if (encodeForPosting) {
      response = post64(tmp);
    } else {
      response = tmp;
    }
    console.info("Sending back response", response);
    if (typeof callback === "function") {
      callback(response);
    } else {
      console.warn("No callback function! Profile construction got", response);
    }
    delete tmp.institution;
    window.publicProfile = tmp;
    return false;
  });
  if (encodeForPosting) {
    response = post64(tmp);
  } else {
    response = tmp;
  }
  window.publicProfile = tmp;
  console.log("Non-validated response object:", response);
  return response;
};

formatSocial = function() {
  var el, error, error1, fab, i, icon, isGood, len, link, network, networkCss, realHref, ref;
  isGood = true;
  el = window.isViewingSelf ? "paper-input" : "paper-fab";
  ref = $(".social " + el);
  for (i = 0, len = ref.length; i < len; i++) {
    fab = ref[i];
    try {
      icon = $(fab).attr("icon");
      network = icon.split(":").pop();
      link = $(fab).attr("data-href");
    } catch (error) {
      try {
        network = $(fab).attr("data-source");
        network = network.replace(/_/g, "-");
        link = p$(fab).value;
      } catch (error1) {
        console.error("borkedy");
      }
    }
    realHref = link;
    switch (network) {
      case "twitter":
        if (link.search("@") === 0) {
          realHref = "https://twitter.com/" + (link.slice(1));
        } else if (link.match(/^https?:\/\/(www\.)?twitter.com\/\w+$/m)) {
          realHref = link;
        } else if (link.match(/^\w+$/m)) {
          realHref = "https://twitter.com/" + link;
        } else {
          realHref = "";
        }
        break;
      case "google-plus":
        if (link.search(/\+/) === 0) {
          realHref = "https://google.com/" + link;
        } else if (link.match(/^https?:\/\/((plus|www)\.)?google.com\/(\+\w+|\d+)$/m)) {
          realHref = link;
        } else if (link.match(/^\w+$/m)) {
          realHref = "https://google.com/+" + link;
        } else {
          realHref = "";
        }
        break;
      case "facebook":
        if (link.match(/^https?:\/\/((www)\.)?facebook.com\/\w+$/m)) {
          realHref = link;
        } else if (link.match(/^\w+$/m)) {
          realHref = "https://facebook.com/" + link;
        } else {
          realHref = "";
        }
    }
    if (isNull(realHref) && !isNull(link)) {
      console.warn(network + " has a questionable link", link, realHref);
      try {
        networkCss = network.replace(/-/g, "_");
        p$("." + networkCss + " paper-input").errorMessage = "We couldn't understand this profile";
        p$("." + networkCss + " paper-input").invalid = true;
        isGood = false;
      } catch (undefined) {}
    }
    $(fab).unbind().attr("data-href", realHref);
  }
  bindClicks("paper-fab");
  return isGood;
};

validateAddress = function(addressObject, callback) {

  /*
   * Get extra address validation information and save it
   *
   */
  var addressString, filter, isoCountry, newAddressObject, ref;
  addressObject.country_code = addressObject.country_code.toUpperCase();
  isoCountry = isoCountries[addressObject.country_code];
  if (isoCountry == null) {
    stopLoadError("Sorry, '" + addressObject.country_code + "' is an invalid country code");
  }
  newAddressObject = addressObject;
  newAddressObject.validated = false;
  newAddressObject.partially_validated = false;
  filter = {
    country: (ref = addressObject.country_code) != null ? ref : "US",
    postalCode: addressObject.zip
  };
  addressString = addressObject.street_number + " " + addressObject.street;
  console.log("Attempting validation with", addressString, filter);
  geo.geocode(addressString, filter, function(result) {
    var humanHtml, ref1, ref2, ref3, ref4;
    console.log("Address validator got", result);
    newAddressObject.validated = result.partial_match !== true;
    newAddressObject.partially_validated = result.partial_match === true;
    newAddressObject.parsed = result;
    newAddressObject.state = (ref1 = result.google.administrative_area_level_1) != null ? ref1 : "";
    newAddressObject.city = (ref2 = result.google.locality) != null ? ref2 : "";
    if (newAddressObject.validated) {
      newAddressObject.street_number = (ref3 = result.google.street_number) != null ? ref3 : addressObject.street_number;
      newAddressObject.street = (ref4 = result.google.route) != null ? ref4 : addressObject.street;
      if (result.google.postal_code_suffix != null) {
        newAddressObject.zip += "-" + result.google.postal_code_suffix;
      }
      addressString = newAddressObject.street_number + " " + newAddressObject.street;
    }
    humanHtml = addressString + "<br/>\n" + newAddressObject.city + ", " + newAddressObject.state + " " + newAddressObject.zip + "<br/>\n" + isoCountry.name;
    newAddressObject.human_html = humanHtml;
    console.info("New address object", newAddressObject);
    if (typeof callback === "function") {
      callback(newAddressObject);
    } else {
      console.warn("No callback fucntion! Address validation got", newAddressObject);
    }
    return false;
  });
  return false;
};

cleanupAddressDisplay = function() {

  /*
   * Display human-helpful address information, like city/state
   */
  var addressObj, labelHtml, mapsSearch, postHtml;
  if (window.publicProfile != null) {
    addressObj = window.publicProfile.place;
    if (addressObj.human_html != null) {
      mapsSearch = encodeURIComponent(addressObj.human_html.replace(/(<br\/>|\n|\\n)/g, " "));
      postHtml = "<div class=\"col-xs-12 col-md-3 col-lg-4\">\n  <paper-fab mini icon=\"maps:map\" data-href=\"https://www.google.com/maps/search/" + mapsSearch + "\" class=\"click materialblue newwindow\" data-newtab=\"true\" data-toggle=\"tooltip\" title=\"View in Google Maps\">\n  </paper-fab>\n</div>";
      labelHtml = "<label class=\"col-xs-4 capitalize\">\n  Address\n</label>";
      $("address").html(addressObj.human_html.replace(/\\n/g, "<br/> ")).addClass("col-xs-8 col-md-5 col-lg-4").before(labelHtml).after(postHtml).parent().addClass("row clearfix");
    } else {
      console.warn("Human HTML not yet defined for this user");
    }
  } else {
    console.warn("Public profile not set up");
  }
  return false;
};

saveProfileChanges = function() {

  /*
   * Post the appropriate JSON to the server and give user feedback
   * based on the response
   */
  var i, input, isGood, len, ref, result;
  startLoad();
  isGood = true;
  ref = $("paper-input");
  for (i = 0, len = ref.length; i < len; i++) {
    input = ref[i];
    try {
      result = p$(input).validate();
      if (result === false) {
        isGood = false;
      }
    } catch (undefined) {}
  }
  isGood = isGood && formatSocial();
  if (!isGood) {
    stopLoadError("Please check all required fields are completed");
    return false;
  }
  constructProfileJson(false, function(data) {
    var args, pdata;
    console.log("Going to save", data);
    pdata = jsonTo64(data);
    args = "perform=" + profileAction + "&data=" + pdata;
    $("#save-profile").attr("disabled", "disabled");
    return $.post(apiTarget, args, "json").done(function(result) {
      var message, ref1, ref2;
      console.log("Save got", result);
      if (result.status !== true) {
        $("#save-profile").removeAttr("disabled");
        message = (ref1 = (ref2 = result.human_error) != null ? ref2 : result.error) != null ? ref1 : "Unknown error";
        stopLoadError("There was an error saving - " + message + ". Please try again later.");
        return false;
      }
      $("#save-profile").attr("disabled", "disabled");
      stopLoad();
      return false;
    }).fail(function(result, status) {
      console.error("Error!", result, status);
      stopLoadError("There was a problem saving to the server.");
      return false;
    });
  });
  return false;
};

setupUserChat = function() {
  var sendChat;
  $(".conversation-list li").click(function() {
    var chattingWith;
    chattingWith = $(this).attr("data-uid");
    foo();
    return false;
  });
  $("#compose-message").keyup(function(e) {
    var kc;
    kc = e.keyCode ? e.keyCode : e.which;
    if (kc === 13) {
      sendChat();
    }
    return false;
  });
  $(".send-chat").click(function() {
    sendChat();
    return false;
  });
  sendChat = function() {
    toastStatusMessage("Would send message");
    return false;
  };
  return false;
};

forceUpdateMarked = function() {
  var val, valReal;
  val = $("marked-element script").text();
  valReal = val.replace(/\\n/g, "\n");
  return p$("marked-element").markdown = valReal;
};

copyLink = function(zeroClipObj, zeroClipEvent, html5) {
  var clip, clipboardData, e, error, successMessage, url;
  if (zeroClipObj == null) {
    zeroClipObj = _adp.zcClient;
  }
  if (html5 == null) {
    html5 = true;
  }
  url = p$("#profile-link-field").value;
  successMessage = "Profile URL copied to clipboard";
  if (html5) {
    try {
      clipboardData = {
        dataType: "text/plain",
        data: url,
        "text/plain": url
      };
      clip = new ClipboardEvent("copy", clipboardData);
      document.dispatchEvent(clip);
      toastStatusMessage(successMessage);
      return false;
    } catch (error) {
      e = error;
      console.error("Error creating copy: " + e.message);
      console.warn(e.stack);
    }
  }
  console.warn("Can't use HTML5");
  if (zeroClipObj != null) {
    zeroClipObj.setData(clipboardData);
    if (zeroClipEvent != null) {
      zeroClipEvent.setData(clipboardData);
    }
    zeroClipObj.on("aftercopy", function(e) {
      if (e.data["text/plain"]) {
        return toastStatusMessage(successMessage);
      } else {
        return toastStatusMessage("Error copying to clipboard");
      }
    });
    zeroClipObj.on("error", function(e) {
      console.error("Error copying to clipboard");
      console.warn("Got", e);
      if (e.name === "flash-overdue") {
        if (_adp.resetClipboard === true) {
          console.error("Resetting ZeroClipboard didn't work!");
          return false;
        }
        ZeroClipboard.on("ready", function() {
          _adp.resetClipboard = true;
          return copyLink();
        });
        _adp.zcClient = new ZeroClipboard($("#copy-profile-link").get(0));
      }
      if (e.name === "flash-disabled") {
        console.info("No flash on this system");
        ZeroClipboard.destroy();
        $("#copy-profile-link").tooltip("destroy");
        return toastStatusMessage("Clipboard copying isn't available on your system");
      }
    });
  } else {
    console.error("Can't use HTML, and ZeroClipboard wasn't passed");
  }
  return false;
};

searchProfiles = function() {

  /*
   * Handler to search profiles
   */
  var args, cols, item, search;
  search = $("#profile-search").val();
  if (isNull(search)) {
    $("#profile-result-container").empty();
    return false;
  }
  item = p$("#search-filter").selectedItem;
  cols = $(item).attr("data-cols");
  console.info("Searching on " + search + " ... in " + cols);
  args = "action=search_users&q=" + search + "&cols=" + cols;
  $.post(uri.urlString + "api.php", args, "json").done(function(result) {
    var button, html, i, len, profile, profiles, ref, s, showList;
    console.info(result);
    if (result.status !== true) {
      console.error("Problem searching profiles!");
      html = "<div class=\"alert alert-warning\">\n  <p>There was an error searching profiles.</p>\n</div>";
      $("#profile-result-container").html(html);
      return false;
    }
    html = "";
    showList = new Array();
    profiles = Object.toArray(result.result);
    if (profiles.length > 0) {
      for (i = 0, len = profiles.length; i < len; i++) {
        profile = profiles[i];
        showList.push(profile.name);
        button = "<button class=\"btn btn-primary search-profile-link\" data-href=\"" + uri.urlString + "profile.php?id=" + profile.uid + "\" data-uid=\"" + profile.uid + "\">\n  " + profile.full_name + " / " + profile.handle + "\n</button>";
        html += "<li class='profile-search-result'>" + button + "</li>";
      }
    } else {
      s = (ref = result.search) != null ? ref : search;
      html = "<p><em>No results found for \"<strong>" + s + "</strong>\"";
    }
    $("#profile-result-container").html(html);
    return bindClicks(".search-profile-link");
  }).fail(function(result, status) {
    return console.error(result, status);
  });
  return false;
};

verifyLoginCredentials = function(callback, skip) {

  /*
   * Checks the login credentials against the server.
   * This should not be used in place of sending authentication
   * information alongside a restricted action, as a malicious party
   * could force the local JS check to succeed.
   * SECURE AUTHENTICATION MUST BE WHOLLY SERVER SIDE.
   */
  var adminParams, args, hash, link, secret;
  adminParams = new Object();
  adminParams.domain = "amphibiandisease";
  adminParams.apiTarget = "admin-api.php";
  adminParams.adminPageUrl = "https://" + adminParams.domain + ".org/admin-page.html";
  adminParams.loginDir = "admin/";
  adminParams.loginApiTarget = adminParams.loginDir + "async_login_handler.php";
  hash = $.cookie(adminParams.domain + "_auth");
  secret = $.cookie(adminParams.domain + "_secret");
  link = $.cookie(adminParams.domain + "_link");
  args = "hash=" + hash + "&secret=" + secret + "&dblink=" + link;
  $.post(adminParams.loginApiTarget, args, "json").done(function(result) {
    if (result.status === true) {
      if (typeof _adp === "undefined" || _adp === null) {
        window._adp = new Object();
      }
      _adp.isUnrestricted = result.unrestricted;
      if (typeof callback === "function") {
        return callback(result);
      }
    } else {
      if (window.isViewingSelf === true) {
        return document.location.reload(true);
      } else {
        return console.info("Bad credentials, but not self-viewing");
      }
    }
  }).fail(function(result, status) {
    console.error("There was a problem verifying your login state");
    return false;
  });
  return false;
};

cascadePrivacyToggledState = function(el, cascadeDown) {
  var container, error, i, isChecked, j, len, len1, level, toggle, toggleLevel, toggles;
  if (cascadeDown == null) {
    cascadeDown = true;
  }

  /*
   *
   */
  try {
    isChecked = p$(el).checked;
    level = toInt($(el).attr("data-level"));
    container = $(el).parents(".privacy-group[data-group]");
    toggles = $(container).find("[data-scope]");
    if (isChecked) {
      for (i = 0, len = toggles.length; i < len; i++) {
        toggle = toggles[i];
        toggleLevel = toInt($(toggle).attr("data-level"));
        if (toggleLevel > level) {
          p$(toggle).checked = isChecked;
          p$(toggle).disabled = true;
        } else if (toggleLevel < level && cascadeDown) {
          p$(toggle).checked = !isChecked;
          p$(toggle).disabled = false;
        }
      }
    } else if (cascadeDown) {
      for (j = 0, len1 = toggles.length; j < len1; j++) {
        toggle = toggles[j];
        toggleLevel = toInt($(toggle).attr("data-level"));
        if (toggleLevel > level) {
          p$(toggle).disabled = false;
        }
      }
    }
  } catch (error) {
    console.error("An invalid element was passed cascading privacy toggles");
  }
  return false;
};

initialCascadeSetup = function() {
  var element, i, j, len, len1, ref, scope, scopesInOrder, selector;
  scopesInOrder = ["collaborators", "members", "public"];
  for (i = 0, len = scopesInOrder.length; i < len; i++) {
    scope = scopesInOrder[i];
    selector = ".privacy-toggle [data-scope='" + scope + "']";
    ref = $(selector);
    for (j = 0, len1 = ref.length; j < len1; j++) {
      element = ref[j];
      cascadePrivacyToggledState(element, false);
    }
  }
  return false;
};

renderCaptchas = function(response) {

  /*
   * Renders the captchas into their respective elements
   */
  var args, dest, profile, ref;
  animateLoad();
  dest = uri.urlString + "api.php";
  profile = (ref = window.profileUid) != null ? ref : uri.o.param("id");
  args = "action=is_human&recaptcha_response=" + response + "&user=" + profile;
  $.post(dest, args, "json").done(function(result) {
    var data, element, html, i, len, lookup, ref1, replaceMap;
    console.info("Checked response");
    console.log(result);
    replaceMap = {
      email: result.response.username,
      phone: result.response.phone,
      department_phone: result.response.public_profile.place.department_phone
    };
    ref1 = $(".g-recaptcha");
    for (i = 0, len = ref1.length; i < len; i++) {
      element = ref1[i];
      $(element).removeClass("g-recaptcha");
      lookup = $(element).attr("data-type");
      data = replaceMap[lookup];
      html = "<p class=\"col-xs-8\">\n  " + data + "\n</p>";
      $(element).replaceWith(html);
    }
    stopLoad();
    return false;
  }).fail(function(result, status) {
    stopLoadError("Sorry, there was a problem getting the contact information");
    return false;
  });
  return false;
};

$(function() {
  var cleanInputFormat, zcConfig;
  try {
    loadUserBadges();
  } catch (undefined) {}
  try {
    conditionalLoadAccountSettingsOptions();
  } catch (undefined) {}
  $("#save-profile").click(function() {
    saveProfileChanges();
    return false;
  });
  $(".user-input").keyup(function() {
    $("#save-profile").removeAttr("disabled");
    return false;
  });
  $("paper-toggle-button").on("change", function() {
    cascadePrivacyToggledState(this);
    $("#save-profile").removeAttr("disabled");
    return false;
  });
  (cleanInputFormat = function() {
    var callingCode, gpi, html, i, isoCC, j, len, len1, phone, plainValue, ref, ref1, ref2, results, value;
    if (!(typeof Polymer !== "undefined" && Polymer !== null ? (ref = Polymer.RenderStatus) != null ? ref._ready : void 0 : void 0)) {
      delay(500, function() {
        return cleanInputFormat();
      });
      return false;
    }
    console.info("Setting up input values");
    try {
      formatSocial();
      forceUpdateMarked();
    } catch (undefined) {}
    try {
      initialCascadeSetup();
    } catch (undefined) {}
    try {
      isoCC = window.publicProfile.place.country_code;
      callingCode = isoCountries[isoCC].code;
    } catch (undefined) {}
    if (!isNumber(callingCode)) {
      callingCode = 1;
    }
    ref1 = $("gold-phone-input");
    for (i = 0, len = ref1.length; i < len; i++) {
      gpi = ref1[i];
      value = $(gpi).parent().attr("data-value");
      if (!isNull(value)) {
        p$(gpi).value = toInt(value);
        p$(gpi).countryCode = callingCode;
      }
    }
    ref2 = $(".phone-number");
    results = [];
    for (j = 0, len1 = ref2.length; j < len1; j++) {
      phone = ref2[j];
      plainValue = $(phone).text();
      if (isNumber(plainValue)) {
        value = "+" + callingCode + plainValue;
        html = "<a href=\"tel:" + value + "\" class=\"phone-number-parsed\">\n  <iron-icon icon=\"communication:phone\" data-toggle=\"tooltip\" title=\"Click to call\"></iron-icon>\n  " + plainValue + "\n</a>";
        results.push($(phone).replaceWith(html));
      } else {
        results.push(void 0);
      }
    }
    return results;
  })();
  if (window.isViewingSelf !== true) {
    console.info("Foreign profile");
    cleanupAddressDisplay();
  } else {
    console.info("Doing self-profile checks");
    setupUserChat();
    verifyLoginCredentials();
    try {
      setupProfileImageUpload();
    } catch (undefined) {}
  }
  $("#profile-search").keyup(function(e) {
    if (!isNull($(this).val())) {
      return searchProfiles.debounce();
    }
  });
  zcConfig = {
    swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
  };
  _adp.zcConfig = zcConfig;
  ZeroClipboard.config(zcConfig);
  _adp.zcClient = new ZeroClipboard($("#copy-profile-link").get(0));
  $("#copy-profile-link").click(function() {
    return copyLink(_adp.zcClient);
  });
  checkFileVersion(false, "js/profile.js");
  return false;
});

//# sourceMappingURL=maps/profile.js.map
