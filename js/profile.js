
/*
 *
 *
 *
 * See
 * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/48
 */
var apiTarget, cleanupAddressDisplay, conditionalLoadAccountSettingsOptions, constructProfileJson, formatSocial, isoCountries, loadUserBadges, prettySocial, profileAction, saveProfileChanges, setupProfileImageUpload, validateAddress;

profileAction = "update_profile";

apiTarget = uri.urlString + "/admin-api.php";

isoCountries = {
  AF: {
    name: "Afghanistan"
  },
  AX: {
    name: "Aland Islands"
  },
  AL: {
    name: "Albania"
  },
  DZ: {
    name: "Algeria"
  },
  AS: {
    name: "American Samoa"
  },
  AD: {
    name: "Andorra"
  },
  AO: {
    name: "Angola"
  },
  AI: {
    name: "Anguilla"
  },
  AQ: {
    name: "Antarctica"
  },
  AG: {
    name: "Antigua And Barbuda"
  },
  AR: {
    name: "Argentina"
  },
  AM: {
    name: "Armenia"
  },
  AW: {
    name: "Aruba"
  },
  AU: {
    name: "Australia"
  },
  AT: {
    name: "Austria"
  },
  AZ: {
    name: "Azerbaijan"
  },
  BS: {
    name: "Bahamas"
  },
  BH: {
    name: "Bahrain"
  },
  BD: {
    name: "Bangladesh"
  },
  BB: {
    name: "Barbados"
  },
  BY: {
    name: "Belarus"
  },
  BE: {
    name: "Belgium"
  },
  BZ: {
    name: "Belize"
  },
  BJ: {
    name: "Benin"
  },
  BM: {
    name: "Bermuda"
  },
  BT: {
    name: "Bhutan"
  },
  BO: {
    name: "Bolivia"
  },
  BA: {
    name: "Bosnia And Herzegovina"
  },
  BW: {
    name: "Botswana"
  },
  BV: {
    name: "Bouvet Island"
  },
  BR: {
    name: "Brazil"
  },
  IO: {
    name: "British Indian Ocean Territory"
  },
  BN: {
    name: "Brunei Darussalam"
  },
  BG: {
    name: "Bulgaria"
  },
  BF: {
    name: "Burkina Faso"
  },
  BI: {
    name: "Burundi"
  },
  KH: {
    name: "Cambodia"
  },
  CM: {
    name: "Cameroon"
  },
  CA: {
    name: "Canada"
  },
  CV: {
    name: "Cape Verde"
  },
  KY: {
    name: "Cayman Islands"
  },
  CF: {
    name: "Central African Republic"
  },
  TD: {
    name: "Chad"
  },
  CL: {
    name: "Chile"
  },
  CN: {
    name: "China"
  },
  CX: {
    name: "Christmas Island"
  },
  CC: {
    name: "Cocos (Keeling) Islands"
  },
  CO: {
    name: "Colombia"
  },
  KM: {
    name: "Comoros"
  },
  CG: {
    name: "Congo"
  },
  CD: {
    name: "Congo, Democratic Republic"
  },
  CK: {
    name: "Cook Islands"
  },
  CR: {
    name: "Costa Rica"
  },
  CI: {
    name: "Cote D\'Ivoire"
  },
  HR: {
    name: "Croatia"
  },
  CU: {
    name: "Cuba"
  },
  CY: {
    name: "Cyprus"
  },
  CZ: {
    name: "Czech Republic"
  },
  DK: {
    name: "Denmark"
  },
  DJ: {
    name: "Djibouti"
  },
  DM: {
    name: "Dominica"
  },
  DO: {
    name: "Dominican Republic"
  },
  EC: {
    name: "Ecuador"
  },
  EG: {
    name: "Egypt"
  },
  SV: {
    name: "El Salvador"
  },
  GQ: {
    name: "Equatorial Guinea"
  },
  ER: {
    name: "Eritrea"
  },
  EE: {
    name: "Estonia"
  },
  ET: {
    name: "Ethiopia"
  },
  FK: {
    name: "Falkland Islands (Malvinas)"
  },
  FO: {
    name: "Faroe Islands"
  },
  FJ: {
    name: "Fiji"
  },
  FI: {
    name: "Finland"
  },
  FR: {
    name: "France"
  },
  GF: {
    name: "French Guiana"
  },
  PF: {
    name: "French Polynesia"
  },
  TF: {
    name: "French Southern Territories"
  },
  GA: {
    name: "Gabon"
  },
  GM: {
    name: "Gambia"
  },
  GE: {
    name: "Georgia"
  },
  DE: {
    name: "Germany"
  },
  GH: {
    name: "Ghana"
  },
  GI: {
    name: "Gibraltar"
  },
  GR: {
    name: "Greece"
  },
  GL: {
    name: "Greenland"
  },
  GD: {
    name: "Grenada"
  },
  GP: {
    name: "Guadeloupe"
  },
  GU: {
    name: "Guam"
  },
  GT: {
    name: "Guatemala"
  },
  GG: {
    name: "Guernsey"
  },
  GN: {
    name: "Guinea"
  },
  GW: {
    name: "Guinea-Bissau"
  },
  GY: {
    name: "Guyana"
  },
  HT: {
    name: "Haiti"
  },
  HM: {
    name: "Heard Island & Mcdonald Islands"
  },
  VA: {
    name: "Holy See (Vatican City State)"
  },
  HN: {
    name: "Honduras"
  },
  HK: {
    name: "Hong Kong"
  },
  HU: {
    name: "Hungary"
  },
  IS: {
    name: "Iceland"
  },
  IN: {
    name: "India"
  },
  ID: {
    name: "Indonesia"
  },
  IR: {
    name: "Iran, Islamic Republic Of"
  },
  IQ: {
    name: "Iraq"
  },
  IE: {
    name: "Ireland"
  },
  IM: {
    name: "Isle Of Man"
  },
  IL: {
    name: "Israel"
  },
  IT: {
    name: "Italy"
  },
  JM: {
    name: "Jamaica"
  },
  JP: {
    name: "Japan"
  },
  JE: {
    name: "Jersey"
  },
  JO: {
    name: "Jordan"
  },
  KZ: {
    name: "Kazakhstan"
  },
  KE: {
    name: "Kenya"
  },
  KI: {
    name: "Kiribati"
  },
  KR: {
    name: "Korea"
  },
  KW: {
    name: "Kuwait"
  },
  KG: {
    name: "Kyrgyzstan"
  },
  LA: {
    name: "Lao People\'s Democratic Republic"
  },
  LV: {
    name: "Latvia"
  },
  LB: {
    name: "Lebanon"
  },
  LS: {
    name: "Lesotho"
  },
  LR: {
    name: "Liberia"
  },
  LY: {
    name: "Libyan Arab Jamahiriya"
  },
  LI: {
    name: "Liechtenstein"
  },
  LT: {
    name: "Lithuania"
  },
  LU: {
    name: "Luxembourg"
  },
  MO: {
    name: "Macao"
  },
  MK: {
    name: "Macedonia"
  },
  MG: {
    name: "Madagascar"
  },
  MW: {
    name: "Malawi"
  },
  MY: {
    name: "Malaysia"
  },
  MV: {
    name: "Maldives"
  },
  ML: {
    name: "Mali"
  },
  MT: {
    name: "Malta"
  },
  MH: {
    name: "Marshall Islands"
  },
  MQ: {
    name: "Martinique"
  },
  MR: {
    name: "Mauritania"
  },
  MU: {
    name: "Mauritius"
  },
  YT: {
    name: "Mayotte"
  },
  MX: {
    name: "Mexico"
  },
  FM: {
    name: "Micronesia, Federated States Of"
  },
  MD: {
    name: "Moldova"
  },
  MC: {
    name: "Monaco"
  },
  MN: {
    name: "Mongolia"
  },
  ME: {
    name: "Montenegro"
  },
  MS: {
    name: "Montserrat"
  },
  MA: {
    name: "Morocco"
  },
  MZ: {
    name: "Mozambique"
  },
  MM: {
    name: "Myanmar"
  },
  NA: {
    name: "Namibia"
  },
  NR: {
    name: "Nauru"
  },
  NP: {
    name: "Nepal"
  },
  NL: {
    name: "Netherlands"
  },
  AN: {
    name: "Netherlands Antilles"
  },
  NC: {
    name: "New Caledonia"
  },
  NZ: {
    name: "New Zealand"
  },
  NI: {
    name: "Nicaragua"
  },
  NE: {
    name: "Niger"
  },
  NG: {
    name: "Nigeria"
  },
  NU: {
    name: "Niue"
  },
  NF: {
    name: "Norfolk Island"
  },
  MP: {
    name: "Northern Mariana Islands"
  },
  NO: {
    name: "Norway"
  },
  OM: {
    name: "Oman"
  },
  PK: {
    name: "Pakistan"
  },
  PW: {
    name: "Palau"
  },
  PS: {
    name: "Palestinian Territory, Occupied"
  },
  PA: {
    name: "Panama"
  },
  PG: {
    name: "Papua New Guinea"
  },
  PY: {
    name: "Paraguay"
  },
  PE: {
    name: "Peru"
  },
  PH: {
    name: "Philippines"
  },
  PN: {
    name: "Pitcairn"
  },
  PL: {
    name: "Poland"
  },
  PT: {
    name: "Portugal"
  },
  PR: {
    name: "Puerto Rico"
  },
  QA: {
    name: "Qatar"
  },
  RE: {
    name: "Reunion"
  },
  RO: {
    name: "Romania"
  },
  RU: {
    name: "Russian Federation"
  },
  RW: {
    name: "Rwanda"
  },
  BL: {
    name: "Saint Barthelemy"
  },
  SH: {
    name: "Saint Helena"
  },
  KN: {
    name: "Saint Kitts And Nevis"
  },
  LC: {
    name: "Saint Lucia"
  },
  MF: {
    name: "Saint Martin"
  },
  PM: {
    name: "Saint Pierre And Miquelon"
  },
  VC: {
    name: "Saint Vincent And Grenadines"
  },
  WS: {
    name: "Samoa"
  },
  SM: {
    name: "San Marino"
  },
  ST: {
    name: "Sao Tome And Principe"
  },
  SA: {
    name: "Saudi Arabia"
  },
  SN: {
    name: "Senegal"
  },
  RS: {
    name: "Serbia"
  },
  SC: {
    name: "Seychelles"
  },
  SL: {
    name: "Sierra Leone"
  },
  SG: {
    name: "Singapore"
  },
  SK: {
    name: "Slovakia"
  },
  SI: {
    name: "Slovenia"
  },
  SB: {
    name: "Solomon Islands"
  },
  SO: {
    name: "Somalia"
  },
  ZA: {
    name: "South Africa"
  },
  GS: {
    name: "South Georgia And Sandwich Isl."
  },
  ES: {
    name: "Spain"
  },
  LK: {
    name: "Sri Lanka"
  },
  SD: {
    name: "Sudan"
  },
  SR: {
    name: "Suriname"
  },
  SJ: {
    name: "Svalbard And Jan Mayen"
  },
  SZ: {
    name: "Swaziland"
  },
  SE: {
    name: "Sweden"
  },
  CH: {
    name: "Switzerland"
  },
  SY: {
    name: "Syrian Arab Republic"
  },
  TW: {
    name: "Taiwan"
  },
  TJ: {
    name: "Tajikistan"
  },
  TZ: {
    name: "Tanzania"
  },
  TH: {
    name: "Thailand"
  },
  TL: {
    name: "Timor-Leste"
  },
  TG: {
    name: "Togo"
  },
  TK: {
    name: "Tokelau"
  },
  TO: {
    name: "Tonga"
  },
  TT: {
    name: "Trinidad And Tobago"
  },
  TN: {
    name: "Tunisia"
  },
  TR: {
    name: "Turkey"
  },
  TM: {
    name: "Turkmenistan"
  },
  TC: {
    name: "Turks And Caicos Islands"
  },
  TV: {
    name: "Tuvalu"
  },
  UG: {
    name: "Uganda"
  },
  UA: {
    name: "Ukraine"
  },
  AE: {
    name: "United Arab Emirates"
  },
  GB: {
    name: "United Kingdom"
  },
  US: {
    name: "United States"
  },
  UM: {
    name: "United States Outlying Islands"
  },
  UY: {
    name: "Uruguay"
  },
  UZ: {
    name: "Uzbekistan"
  },
  VU: {
    name: "Vanuatu"
  },
  VE: {
    name: "Venezuela"
  },
  VN: {
    name: "Viet Nam"
  },
  VG: {
    name: "Virgin Islands, British"
  },
  VI: {
    name: "Virgin Islands, U.S."
  },
  WF: {
    name: "Wallis And Futuna"
  },
  EH: {
    name: "Western Sahara"
  },
  YE: {
    name: "Yemen"
  },
  ZM: {
    name: "Zambia"
  },
  ZW: {
    name: "Zimbabwe"
  }
};

loadUserBadges = function() {

  /*
   *
   */
  return false;
};

setupProfileImageUpload = function() {

  /*
   * Bootstrap an uploader for images
   */
  return false;
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
  var el, i, inputs, key, len, parentKey, response, tmp, val;
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
    parentKey = $(el).parents("[data-source]").attr("data-source");
    if (typeof tmp[parentKey] !== "object") {
      tmp[parentKey] = new Object();
    }
    tmp[parentKey][key] = val;
  }
  validateAddress(tmp.institution, function(newAddressObj) {
    tmp.institution = newAddressObj;
    if (encodeForPosting) {
      response = post64(tmp);
    } else {
      response = tmp;
    }
    if (typeof callback === "function") {
      callback(response);
    } else {
      console.warn("No callback function! Profile construction got", response);
    }
    window.publicProfile = tmp;
    return false;
  });
  if (encodeForPosting) {
    response = post64(tmp);
  } else {
    response = tmp;
  }
  window.publicProfile = tmp;
  console.log("Non-validated response object:");
  return response;
};

formatSocial = function() {
  return false;
};

prettySocial = function() {
  return false;
};

validateAddress = function(addressObject, callback) {

  /*
   * Get extra address validation information and save it
   *
   */
  var addressString, filter, newAddressObject, ref;
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
    humanHtml = addressString + "<br/>\n" + newAddressObject.city + ", " + newAddressObject.state + " " + newAddressObject.zip;
    newAddressObject.human_html = humanHtml;
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
  var addressObj;
  if (typeof publicProfile !== "undefined" && publicProfile !== null) {
    addressObj = publicProfile.institution;
    if (addressObj.human_html != null) {
      $("address").html(addressObj.human_html);
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
  startLoad();
  constructProfileJson(true, function() {
    var args;
    args = "perform=" + profileAction + "&data=" + data;
    return $.post(apiTarget, args, "json").done(function(result) {
      console.log("Save got", result);
      $("#save-profile").attr("disabled", "disabled");
      stopLoad();
      return false;
    }).fail(function(result, status) {
      console.error("Error!", result, status);
      stopLoadError();
      return false;
    });
  });
  return false;
};

$(function() {
  var cleanInputFormat;
  try {
    loadUserBadges();
  } catch (undefined) {}
  try {
    setupProfileImageUpload();
  } catch (undefined) {}
  try {
    conditionalLoadAccountSettingsOptions();
  } catch (undefined) {}
  $("#save-profile").click(function() {
    saveProfileChanges();
    return false;
  });
  $("#main-body input").keyup(function() {
    $("#save-profile").removeAttr("disabled");
    return false;
  });
  (cleanInputFormat = function() {
    var gpi, i, len, ref, ref1, results, value;
    if (!(typeof Polymer !== "undefined" && Polymer !== null ? (ref = Polymer.RenderStatus) != null ? ref._ready : void 0 : void 0)) {
      console.warn("Delaying input setup until Polymer.RenderStatus is ready");
      delay(500, function() {
        return cleanInputFormat();
      });
      return false;
    }
    console.info("Setting up input values");
    ref1 = $("gold-phone-input");
    results = [];
    for (i = 0, len = ref1.length; i < len; i++) {
      gpi = ref1[i];
      value = $(gpi).parent().attr("data-value");
      if (!isNull(value)) {
        results.push(p$(gpi).value = toInt(value));
      } else {
        results.push(void 0);
      }
    }
    return results;
  })();
  if (window.isViewingSelf === true) {
    cleanupAddressDisplay();
  }
  checkFileVersion(false, "js/profile.js");
  return false;
});

//# sourceMappingURL=maps/profile.js.map
