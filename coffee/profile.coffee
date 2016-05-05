###
#
#
#
# See
# https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/48
###

profileAction = "update_profile"
apiTarget = "#{uri.urlString}/admin-api.php"


isoCountries =
  AF:
    name: "Afghanistan"
  AX:
    name: "Aland Islands"
  AL:
    name: "Albania"
  DZ:
    name: "Algeria"
  AS:
    name: "American Samoa"
  AD:
    name: "Andorra"
  AO:
    name: "Angola"
  AI:
    name: "Anguilla"
  AQ:
    name: "Antarctica"
  AG:
    name: "Antigua And Barbuda"
  AR:
    name: "Argentina"
  AM:
    name: "Armenia"
  AW:
    name: "Aruba"
  AU:
    name: "Australia"
  AT:
    name: "Austria"
  AZ:
    name: "Azerbaijan"
  BS:
    name: "Bahamas"
  BH:
    name: "Bahrain"
  BD:
    name: "Bangladesh"
  BB:
    name: "Barbados"
  BY:
    name: "Belarus"
  BE:
    name: "Belgium"
  BZ:
    name: "Belize"
  BJ:
    name: "Benin"
  BM:
    name: "Bermuda"
  BT:
    name: "Bhutan"
  BO:
    name: "Bolivia"
  BA:
    name: "Bosnia And Herzegovina"
  BW:
    name: "Botswana"
  BV:
    name: "Bouvet Island"
  BR:
    name: "Brazil"
  IO:
    name: "British Indian Ocean Territory"
  BN:
    name: "Brunei Darussalam"
  BG:
    name: "Bulgaria"
  BF:
    name: "Burkina Faso"
  BI:
    name: "Burundi"
  KH:
    name: "Cambodia"
  CM:
    name: "Cameroon"
  CA:
    name: "Canada"
  CV:
    name: "Cape Verde"
  KY:
    name: "Cayman Islands"
  CF:
    name: "Central African Republic"
  TD:
    name: "Chad"
  CL:
    name: "Chile"
  CN:
    name: "China"
  CX:
    name: "Christmas Island"
  CC:
    name: "Cocos (Keeling) Islands"
  CO:
    name: "Colombia"
  KM:
    name: "Comoros"
  CG:
    name: "Congo"
  CD:
    name: "Congo, Democratic Republic"
  CK:
    name: "Cook Islands"
  CR:
    name: "Costa Rica"
  CI:
    name: "Cote D\'Ivoire"
  HR:
    name: "Croatia"
  CU:
    name: "Cuba"
  CY:
    name: "Cyprus"
  CZ:
    name: "Czech Republic"
  DK:
    name: "Denmark"
  DJ:
    name: "Djibouti"
  DM:
    name: "Dominica"
  DO:
    name: "Dominican Republic"
  EC:
    name: "Ecuador"
  EG:
    name: "Egypt"
  SV:
    name: "El Salvador"
  GQ:
    name: "Equatorial Guinea"
  ER:
    name: "Eritrea"
  EE:
    name: "Estonia"
  ET:
    name: "Ethiopia"
  FK:
    name: "Falkland Islands (Malvinas)"
  FO:
    name: "Faroe Islands"
  FJ:
    name: "Fiji"
  FI:
    name: "Finland"
  FR:
    name: "France"
  GF:
    name: "French Guiana"
  PF:
    name: "French Polynesia"
  TF:
    name: "French Southern Territories"
  GA:
    name: "Gabon"
  GM:
    name: "Gambia"
  GE:
    name: "Georgia"
  DE:
    name: "Germany"
  GH:
    name: "Ghana"
  GI:
    name: "Gibraltar"
  GR:
    name: "Greece"
  GL:
    name: "Greenland"
  GD:
    name: "Grenada"
  GP:
    name: "Guadeloupe"
  GU:
    name: "Guam"
  GT:
    name: "Guatemala"
  GG:
    name: "Guernsey"
  GN:
    name: "Guinea"
  GW:
    name: "Guinea-Bissau"
  GY:
    name: "Guyana"
  HT:
    name: "Haiti"
  HM:
    name: "Heard Island & Mcdonald Islands"
  VA:
    name: "Holy See (Vatican City State)"
  HN:
    name: "Honduras"
  HK:
    name: "Hong Kong"
  HU:
    name: "Hungary"
  IS:
    name: "Iceland"
  IN:
    name: "India"
  ID:
    name: "Indonesia"
  IR:
    name: "Iran, Islamic Republic Of"
  IQ:
    name: "Iraq"
  IE:
    name: "Ireland"
  IM:
    name: "Isle Of Man"
  IL:
    name: "Israel"
  IT:
    name: "Italy"
  JM:
    name: "Jamaica"
  JP:
    name: "Japan"
  JE:
    name: "Jersey"
  JO:
    name: "Jordan"
  KZ:
    name: "Kazakhstan"
  KE:
    name: "Kenya"
  KI:
    name: "Kiribati"
  KR:
    name: "Korea"
  KW:
    name: "Kuwait"
  KG:
    name: "Kyrgyzstan"
  LA:
    name: "Lao People\'s Democratic Republic"
  LV:
    name: "Latvia"
  LB:
    name: "Lebanon"
  LS:
    name: "Lesotho"
  LR:
    name: "Liberia"
  LY:
    name: "Libyan Arab Jamahiriya"
  LI:
    name: "Liechtenstein"
  LT:
    name: "Lithuania"
  LU:
    name: "Luxembourg"
  MO:
    name: "Macao"
  MK:
    name: "Macedonia"
  MG:
    name: "Madagascar"
  MW:
    name: "Malawi"
  MY:
    name: "Malaysia"
  MV:
    name: "Maldives"
  ML:
    name: "Mali"
  MT:
    name: "Malta"
  MH:
    name: "Marshall Islands"
  MQ:
    name: "Martinique"
  MR:
    name: "Mauritania"
  MU:
    name: "Mauritius"
  YT:
    name: "Mayotte"
  MX:
    name: "Mexico"
  FM:
    name: "Micronesia, Federated States Of"
  MD:
    name: "Moldova"
  MC:
    name: "Monaco"
  MN:
    name: "Mongolia"
  ME:
    name: "Montenegro"
  MS:
    name: "Montserrat"
  MA:
    name: "Morocco"
  MZ:
    name: "Mozambique"
  MM:
    name: "Myanmar"
  NA:
    name: "Namibia"
  NR:
    name: "Nauru"
  NP:
    name: "Nepal"
  NL:
    name: "Netherlands"
  AN:
    name: "Netherlands Antilles"
  NC:
    name: "New Caledonia"
  NZ:
    name: "New Zealand"
  NI:
    name: "Nicaragua"
  NE:
    name: "Niger"
  NG:
    name: "Nigeria"
  NU:
    name: "Niue"
  NF:
    name: "Norfolk Island"
  MP:
    name: "Northern Mariana Islands"
  NO:
    name: "Norway"
  OM:
    name: "Oman"
  PK:
    name: "Pakistan"
  PW:
    name: "Palau"
  PS:
    name: "Palestinian Territory, Occupied"
  PA:
    name: "Panama"
  PG:
    name: "Papua New Guinea"
  PY:
    name: "Paraguay"
  PE:
    name: "Peru"
  PH:
    name: "Philippines"
  PN:
    name: "Pitcairn"
  PL:
    name: "Poland"
  PT:
    name: "Portugal"
  PR:
    name: "Puerto Rico"
  QA:
    name: "Qatar"
  RE:
    name: "Reunion"
  RO:
    name: "Romania"
  RU:
    name: "Russian Federation"
  RW:
    name: "Rwanda"
  BL:
    name: "Saint Barthelemy"
  SH:
    name: "Saint Helena"
  KN:
    name: "Saint Kitts And Nevis"
  LC:
    name: "Saint Lucia"
  MF:
    name: "Saint Martin"
  PM:
    name: "Saint Pierre And Miquelon"
  VC:
    name: "Saint Vincent And Grenadines"
  WS:
    name: "Samoa"
  SM:
    name: "San Marino"
  ST:
    name: "Sao Tome And Principe"
  SA:
    name: "Saudi Arabia"
  SN:
    name: "Senegal"
  RS:
    name: "Serbia"
  SC:
    name: "Seychelles"
  SL:
    name: "Sierra Leone"
  SG:
    name: "Singapore"
  SK:
    name: "Slovakia"
  SI:
    name: "Slovenia"
  SB:
    name: "Solomon Islands"
  SO:
    name: "Somalia"
  ZA:
    name: "South Africa"
  GS:
    name: "South Georgia And Sandwich Isl."
  ES:
    name: "Spain"
  LK:
    name: "Sri Lanka"
  SD:
    name: "Sudan"
  SR:
    name: "Suriname"
  SJ:
    name: "Svalbard And Jan Mayen"
  SZ:
    name: "Swaziland"
  SE:
    name: "Sweden"
  CH:
    name: "Switzerland"
  SY:
    name: "Syrian Arab Republic"
  TW:
    name: "Taiwan"
  TJ:
    name: "Tajikistan"
  TZ:
    name: "Tanzania"
  TH:
    name: "Thailand"
  TL:
    name: "Timor-Leste"
  TG:
    name: "Togo"
  TK:
    name: "Tokelau"
  TO:
    name: "Tonga"
  TT:
    name: "Trinidad And Tobago"
  TN:
    name: "Tunisia"
  TR:
    name: "Turkey"
  TM:
    name: "Turkmenistan"
  TC:
    name: "Turks And Caicos Islands"
  TV:
    name: "Tuvalu"
  UG:
    name: "Uganda"
  UA:
    name: "Ukraine"
  AE:
    name: "United Arab Emirates"
  GB:
    name: "United Kingdom"
  US:
    name: "United States"
  UM:
    name: "United States Outlying Islands"
  UY:
    name: "Uruguay"
  UZ:
    name: "Uzbekistan"
  VU:
    name: "Vanuatu"
  VE:
    name: "Venezuela"
  VN:
    name: "Viet Nam"
  VG:
    name: "Virgin Islands, British"
  VI:
    name: "Virgin Islands, U.S."
  WF:
    name: "Wallis And Futuna"
  EH:
    name: "Western Sahara"
  YE:
    name: "Yemen"
  ZM:
    name: "Zambia"
  ZW:
    name: "Zimbabwe"


loadUserBadges = ->
  ###
  #
  ###
  false


setupProfileImageUpload = ->
  ###
  # Bootstrap an uploader for images
  ###
  false


conditionalLoadAccountSettingsOptions = ->
  ###
  # Verify the account ownership, and if true, provide options for
  # various account settings.
  #
  # Largely acts as links back to admin-login.php
  ###
  false


constructProfileJson = (encodeForPosting = false, callback)->
  ###
  # Read all the fields and return a JSON formatted for the database
  # field
  #
  # See Github Issue #48
  #
  # @param bool encodeForPosting -> when true, returns a URI-encoded
  #   base64 string, rather than an actual object.
  ###
  response = false
  # Build it
  if typeof window.publicProfile is "object"
    tmp = window.publicProfile
  else
    tmp = new Object()
  inputs = $(".profile-data:not(.from-base-profile) .user-input")
  for el in inputs
    val = p$(el).value
    key = $(el).attr "data-source"
    key = key.replace "-", "_"
    parentKey = $(el).parents("[data-source]").attr "data-source"
    unless typeof tmp[parentKey] is "object"
      tmp[parentKey] = new Object()
    tmp[parentKey][key] = val
  # Prep it
  validateAddress tmp.institution, (newAddressObj) ->
    tmp.institution = newAddressObj
    if encodeForPosting
      response = post64 tmp
    else
      response = tmp
    console.info "Sending back response", response
    if typeof callback is "function"
      callback response
    else
      console.warn "No callback function! Profile construction got", response
    window.publicProfile = tmp
    false
  if encodeForPosting
    response = post64 tmp
  else
    response = tmp
  window.publicProfile = tmp
  console.log "Non-validated response object:", response
  response


formatSocial = ->
  false


prettySocial = ->
  false


validateAddress = (addressObject, callback) ->
  ###
  # Get extra address validation information and save it
  #
  ###
  newAddressObject = addressObject
  newAddressObject.validated = false
  newAddressObject.partially_validated = false
  filter =
    country: addressObject.country_code ? "US"
    postalCode: addressObject.zip
  addressString = "#{addressObject.street_number} #{addressObject.street}"
  console.log "Attempting validation with", addressString, filter
  geo.geocode addressString, filter, (result) ->
    console.log "Address validator got", result
    newAddressObject.validated = result.partial_match isnt true
    newAddressObject.partially_validated = result.partial_match is true
    newAddressObject.parsed = result
    newAddressObject.state = result.google.administrative_area_level_1 ? ""
    newAddressObject.city = result.google.locality ? ""
    if newAddressObject.validated
      newAddressObject.street_number = result.google.street_number ? addressObject.street_number
      newAddressObject.street = result.google.route ? addressObject.street
      if result.google.postal_code_suffix?
        newAddressObject.zip += "-#{result.google.postal_code_suffix}"
      addressString = "#{newAddressObject.street_number} #{newAddressObject.street}"
    humanHtml = """
    #{addressString}<br/>
    #{newAddressObject.city}, #{newAddressObject.state} #{newAddressObject.zip}
    """
    newAddressObject.human_html = humanHtml
    if typeof callback is "function"
      callback newAddressObject
    else
      console.warn "No callback fucntion! Address validation got", newAddressObject
    false
  false

cleanupAddressDisplay = ->
  ###
  # Display human-helpful address information, like city/state
  ###
  if publicProfile?
    addressObj = publicProfile.institution
    if addressObj.human_html?
      $("address").html addressObj.human_html
    else
      console.warn "Human HTML not yet defined for this user"
  else
    console.warn "Public profile not set up"
  false

saveProfileChanges = ->
  ###
  # Post the appropriate JSON to the server and give user feedback
  # based on the response
  ###
  startLoad()
  isGood = true
  for input in $("paper-input")
    try
      result = p$(input).validate()
      if result is false
        isGood = false
  unless isGood
    stopLoadError "Please check all required fields are completed"
    return false
  constructProfileJson false,  (data) ->
    console.log "Going to save", data
    pdata = post64 data
    args = "perform=#{profileAction}&data=#{pdata}"
    $("#save-profile").attr "disabled", "disabled"
    $.post apiTarget, args, "json"
    .done (result) ->
      console.log "Save got", result
      unless result.status is true
        $("#save-profile").removeAttr "disabled"
        message = result.human_error ? result.error ? "Unknown error"
        stopLoadError "There was an error saving - #{message}. Please try again later."
        return false
      $("#save-profile").attr "disabled", "disabled"
      stopLoad()
      false
    .fail (result, status) ->
      console.error "Error!", result, status
      stopLoadError "There was a problem saving to the server."
      false
  false


setupUserChat = ->
  $(".conversation-list li").click ->
    # Load that user's chat
    chattingWith = $(this).attr "data-uid"
    foo()
    false
  $("#compose-message").keyup (e) ->
    kc = if e.keyCode then e.keyCode else e.which
    if kc is 13
      sendChat()
    false
  $(".send-chat").click ->
    sendChat()
    false
  sendChat = ->
    toastStatusMessage "Would send message"
    false
  false


$ ->
  # On load page events
  try
    loadUserBadges()
  try
    setupProfileImageUpload()
  try
    conditionalLoadAccountSettingsOptions()
  $("#save-profile").click ->
    saveProfileChanges()
    false
  $("#main-body input").keyup ->
    $("#save-profile").removeAttr "disabled"
    false
  do cleanInputFormat = ->
    unless Polymer?.RenderStatus?._ready
      console.warn "Delaying input setup until Polymer.RenderStatus is ready"
      delay 500, ->
        cleanInputFormat()
      return false
    console.info "Setting up input values"
    for gpi in $("gold-phone-input")
      value = $(gpi).parent().attr "data-value"
      unless isNull value
        # Fix the formatting of the display
        p$(gpi).value = toInt value
  if window.isViewingSelf is true
    cleanupAddressDisplay()
  checkFileVersion false, "js/profile.js"
  false
