###
# Core helpers/imports for web workers
###

# jQuery DOM workaround
# `var document = self.document = {parentNode: null, nodeType: 9, toString: function() {return "FakeDocument"}};
# var window = self.window = self;
# var fakeElement = Object.create(document);
# fakeElement.nodeType = 1;
# fakeElement.toString=function() {return "FakeElement"};
# fakeElement.parentNode = fakeElement.firstChild = fakeElement.lastChild = fakeElement;
# fakeElement.ownerDocument = document;

# document.head = document.body = fakeElement;
# document.ownerDocument = document.documentElement = document;
# document.getElementById = document.createElement = function() {return fakeElement;};
# document.createDocumentFragment = function() {return this;};
# document.createElement = function() {return this;};
# document.getElementsByTagName = document.getElementsByClassName = function() {return [fakeElement];};
# document.getAttribute = document.setAttribute = document.removeChild =
#   document.addEventListener = document.removeEventListener =
#   function() {return null;};
# document.cloneNode = document.appendChild = function() {return this;};
# document.appendChild = function(child) {return child;};`

# importScripts "https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"
# try
#   importScripts "purl.min.js"
#   # Set up basic URI parameters
#   # Uses
#   # https://github.com/allmarkedup/purl
#   try
#     uri = new Object()
#     uri.o = $.url()
#     uri.urlString = uri.o.attr('protocol') + '://' + uri.o.attr('host')  + uri.o.attr("directory")
#     uri.query = uri.o.attr("fragment")
#   catch e
#     console.warn("PURL not installed!")

locationData = new Object()
locationData.params =
  enableHighAccuracy: true
locationData.last = undefined


isBool = (str,strict = false) ->
  if strict
    return typeof str is "boolean"
  try
    if typeof str is "boolean"
      return str is true or str is false
    if typeof str is "string"
      return str.toLowerCase() is "true" or str.toLowerCase() is "false"
    if typeof str is "number"
      return str is 1 or str is 0
    false
  catch e
    return false

isEmpty = (str) -> not str or str.length is 0

isBlank = (str) -> not str or /^\s*$/.test(str)

isNull = (str) ->
  try
    if isEmpty(str) or isBlank(str) or not str?
      unless str is false or str is 0 then return true
  catch e
    return false
  false

isJson = (str) ->
  if typeof str is 'object' and not isArray str then return true
  try
    JSON.parse(str)
    return true
  catch
    return false
  false

isArray = (arr) ->
  try
    shadow = arr.slice 0
    shadow.push "foo"
    return true
  catch
    return false


isNumber = (n) -> not isNaN(parseFloat(n)) and isFinite(n)

toFloat = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  parseFloat(str)

toInt = (str) ->
  if not isNumber(str) or isNull(str) then return 0
  f = parseFloat(str) # For stuff like 1.2e12
  parseInt(f)

String::toAscii = ->
  ###
  # Remove MS Word bullshit
  ###
  @replace(/[\u2018\u2019\u201A\u201B\u2032\u2035]/g, "'")
    .replace(/[\u201C\u201D\u201E\u201F\u2033\u2036]/g, '"')
    .replace(/[\u2013\u2014]/g, '-')
    .replace(/[\u2026]/g, '...')
    .replace(/\u02C6/g, "^")
    .replace(/\u2039/g, "")
    .replace(/[\u02DC|\u00A0]/g, " ")


String::toBool = ->
  test = @toString().toLowerCase()
  test is 'true' or test is "1"

Boolean::toBool = -> @toString() is "true"

Number::toBool = -> @toString() is "1"

String::addSlashes = ->
  `this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0')`

Array::max = -> Math.max.apply null, this

Array::min = -> Math.min.apply null, this

Array::containsObject = (obj) ->
  # Value-ish rather than indexOf
  # Uses underscore, but since I don't usually use it ...
  try
    res = _.find this, (val) ->
      _.isEqual obj, val
    typeof res is "object"
  catch e
    console.error "Please load underscore.js before using this."
    console.info  "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js"

Object.toArray = (obj) ->
  try
    shadowObj = obj.slice 0
    shadowObj.push "foo" # Throws error on obj
    return obj
  Object.keys(obj).map (key) =>
    obj[key]

Object.size = (obj) ->
  if typeof obj isnt "object"
    try
      return obj.length
    catch e
      console.error("Passed argument isn't an object and doesn't have a .length parameter")
      console.warn(e.message)
  size = 0
  size++ for key of obj when obj.hasOwnProperty(key)
  size

Object.doOnSortedKeys = (obj, fn) ->
  sortedKeys = Object.keys(obj).sort()
  for key in sortedKeys
    data = obj[key]
    fn data

delay = (ms,f) -> setTimeout(f,ms)

roundNumber = (number,digits = 0) ->
  multiple = 10 ** digits
  Math.round(number * multiple) / multiple


roundNumberSigfig = (number, digits = 0) ->
  newNumber = roundNumber(number, digits).toString()
  digArr = newNumber.split(".")
  if digArr.length is 1
    return "#{newNumber}.#{Array(digits + 1).join("0")}"
  trailingDigits = digArr.pop()
  significand = "#{digArr[0]}."
  if trailingDigits.length is digits
    return newNumber
  needDigits = digits - trailingDigits.length
  trailingDigits += Array(needDigits + 1).join("0")
  "#{significand}#{trailingDigits}"


String::stripHtml = (stripChildren = false) ->
  str = this
  if stripChildren
    # Pull out the children
    str = str.replace /<(\w+)(?:[^"'>]|"[^"]*"|'[^']*')*>(?:((?:.)*?))<\/?\1(?:[^"'>]|"[^"]*"|'[^']*')*>/mg, ""
  # Script tags
  str = str.replace /<script[^>]*>([\S\s]*?)<\/script>/gmi, ''
  # HTML tags
  str = str.replace /<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, ''
  str

String::unescape = (strict = false) ->
  ###
  # Take escaped text, and return the unescaped version
  #
  # @param string str | String to be used
  # @param bool strict | Stict mode will remove all HTML
  #
  # Test it here:
  # https://jsfiddle.net/tigerhawkvok/t9pn1dn5/
  #
  # Code: https://gist.github.com/tigerhawkvok/285b8631ed6ebef4446d
  ###
  # Create a dummy element
  element = document.createElement("div")
  decodeHTMLEntities = (str) ->
    if str? and typeof str is "string"
      unless strict is true
        # escape HTML tags
        str = escape(str).replace(/%26/g,'&').replace(/%23/g,'#').replace(/%3B/g,';')
      else
        str = str.replace(/<script[^>]*>([\S\s]*?)<\/script>/gmi, '')
        str = str.replace(/<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, '')
      element.innerHTML = str
      if element.innerText
        # Do we support innerText?
        str = element.innerText
        element.innerText = ""
      else
        # Firefox
        str = element.textContent
        element.textContent = ""
    unescape(str)
  # Remove encoded or double-encoded tags
  fixHtmlEncodings = (string) ->
    string = string.replace(/\&amp;#/mg, '&#') # The rest, for double-encodings
    string = string.replace(/\&quot;/mg, '"')
    string = string.replace(/\&quote;/mg, '"')
    string = string.replace(/\&#95;/mg, '_')
    string = string.replace(/\&#39;/mg, "'")
    string = string.replace(/\&#34;/mg, '"')
    string = string.replace(/\&#62;/mg, '>')
    string = string.replace(/\&#60;/mg, '<')
    string
  # Run it
  tmp = fixHtmlEncodings(this)
  decodeHTMLEntities(tmp)


deEscape = (string) ->
  string = string.replace(/\&amp;#/mg, '&#') # The rest
  string = string.replace(/\&quot;/mg, '"')
  string = string.replace(/\&quote;/mg, '"')
  string = string.replace(/\&#95;/mg, '_')
  string = string.replace(/\&#39;/mg, "'")
  string = string.replace(/\&#34;/mg, '"')
  string = string.replace(/\&#62;/mg, '>')
  string = string.replace(/\&#60;/mg, '<')
  string




jsonTo64 = (obj, encode = true) ->
  ###
  #
  # @param obj
  # @param boolean encode -> URI encode base64 string
  ###
  try
    shadowObj = obj.slice 0
    shadowObj.push "foo" # Throws error on obj
    obj = toObject obj
  objString = JSON.stringify obj
  if encode is true
    encoded = post64 objString
  else
    encoded = encode64 encoded
  encoded


encode64 = (string) ->
  try
    Base64.encode(string)
  catch e
    console.warn("Bad encode string provided")
    string
decode64 = (string) ->
  try
    Base64.decode(string)
  catch e
    console.warn("Bad decode string provided")
    string

post64 = (string) ->
  s64 = encode64 string
  p64 = encodeURIComponent s64
  p64

byteCount = (s) => encodeURI(s).split(/%..|./).length - 1

`function shuffle(o) { //v1.0
    for (var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
}`



toObject = (array) ->
  rv = new Object()
  for index, element of array
    if element isnt undefined then rv[index] = element
  rv


String::toTitleCase = ->
  # From http://stackoverflow.com/a/6475125/1877527
  str =
    @replace /([^\W_]+[^\s-]*) */g, (txt) ->
      txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

  # Certain minor words should be left lowercase unless
  # they are the first or last words in the string
  lowers = [
    "A"
    "An"
    "The"
    "And"
    "But"
    "Or"
    "For"
    "Nor"
    "As"
    "At"
    "By"
    "For"
    "From"
    "In"
    "Into"
    "Near"
    "Of"
    "On"
    "Onto"
    "To"
    "With"
    ]
  for lower in lowers
    lowerRegEx = new RegExp("\\s#{lower}\\s","g")
    str = str.replace lowerRegEx, (txt) -> txt.toLowerCase()

  # Certain words such as initialisms or acronyms should be left
  # uppercase
  uppers = [
    "Id"
    "Tv"
    ]
  for upper in uppers
    upperRegEx = new RegExp("\\b#{upper}\\b","g")
    str = str.replace upperRegEx, upper.toUpperCase()
  str


Function::getName = ->
  ###
  # Returns a unique identifier for a function
  ###
  name = this.name
  unless name?
    name = this.toString().substr( 0, this.toString().indexOf( "(" ) ).replace( "function ", "" );
  if isNull name
    name = md5 this.toString()
  name



randomInt = (lower = 0, upper = 1) ->
  start = Math.random()
  if not lower?
    [lower, upper] = [0, lower]
  if lower > upper
    [lower, upper] = [upper, lower]
  return Math.floor(start * (upper - lower + 1) + lower)


randomString = (length = 8) ->
  i = 0
  charBottomSearchSpace = 65 # "A"
  charUpperSearchSpace = 126
  stringArray = new Array()
  while i < length
    ++i
    # Search space
    char = randomInt charBottomSearchSpace, charUpperSearchSpace
    stringArray.push String.fromCharCode char
  stringArray.join ""




openLink = (url) ->
  if not url? then return false
  open(url)
  false

openTab = (url) ->
  openLink(url)

goTo = (url) ->
  if not url? then return false
  location.href = url
  false



dateMonthToString = (month) ->
  conversionObj =
    0: "January"
    1: "February"
    2: "March"
    3: "April"
    4: "May"
    5: "June"
    6: "July"
    7: "August"
    8: "September"
    9: "October"
    10: "November"
    11: "December"
  try
    rv = conversionObj[month]
  catch
    rv = month
  rv



prepURI = (string) ->
  string = encodeURIComponent(string)
  string.replace(/%20/g,"+")


locationData = new Object()
locationData.params =
  enableHighAccuracy: true
locationData.last = undefined

getLocation = (callback = undefined) ->
  retryTimeout = 1500
  geoSuccess = (pos) ->
    clearTimeout geoTimeout
    locationData.lat = pos.coords.latitude
    locationData.lng = pos.coords.longitude
    locationData.acc = pos.coords.accuracy
    last = locationData.last
    locationData.last = Date.now() # ms, unix time
    elapsed = locationData.last - last
    if elapsed < retryTimeout
      # Don't run too many times
      return false
    console.info "Successfully set location"
    if typeof callback is "function"
      callback(locationData)
    false
  geoFail = (error) ->
    clearTimeout geoTimeout
    locationError = switch error.code
      when 0 then "There was an error while retrieving your location: #{error.message}"
      when 1 then "The user prevented this page from retrieving a location"
      when 2 then "The browser was unable to determine your location: #{error.message}"
      when 3 then "The browser timed out retrieving your location."
    console.error(locationError)
    if typeof callback is "function"
      callback(false)
    false
  # Actual location query
  if navigator.geolocation
    console.log "Querying location"
    navigator.geolocation.getCurrentPosition(geoSuccess,geoFail,locationData.params)
    geoTimeout = delay 1500, ->
      getLocation callback
  else
    console.warn("This browser doesn't support geolocation!")
    if callback?
      callback(false)


downloadCSVFile = (data, options) ->
  ###
  # Options:
  #
  options = new Object()
  options.create ?= false
  options.downloadFile ?= "datalist.csv"
  options.classes ?= "btn btn-default"
  options.buttonText ?= "Download File"
  options.iconHtml ?= """<iron-icon icon="icons:cloud-download"></iron-icon>"""
  options.selector ?= "#download-file"
  options.splitValues ?= false
  ###
  startTime = Date.now()
  textAsset = ""
  if isJson(data) and typeof data is "string"
    console.info "Parsing as JSON string"
    try
      jsonObject = JSON.parse data
    catch e
      console.error "COuldn't parse json! #{e.message}"
      console.warn e.stack
      console.info data
      throw "error"
  else if isArray data
    console.info "Parsing as array"
    jsonObject = toObject data
  else if typeof data is "object"
    console.info "Parsing as object"
    jsonObject = data
  else
    console.error "Unexpected data type '#{typeof data}' for downloadCSVFile()", data
    return false
  # Make sure options are available the rest of the way down
  unless options?
    options = new Object()
  options.create ?= false
  options.downloadFile ?= "datalist.csv"
  options.classes ?= "btn btn-default"
  options.buttonText ?= "Download File"
  options.iconHtml ?= """<iron-icon icon="icons:cloud-download"></iron-icon>"""
  options.selector ?= "#download-file"
  options.splitValues ?= false
  options.cascadeObjects ?= false
  options.objectAsValues ?= true
  # Parse it
  headerPlaceholder = new Array()
  do parser = (jsonObj = jsonObject, cascadeObjects = options.cascadeObjects) ->
    row = 0
    if options.objectAsValues
      options.splitValues = "::@@::"
    for key, value of jsonObj
      if typeof value is "function" then continue
      ++row
      # Escape as per RFC4180
      # https://tools.ietf.org/html/rfc4180#page-2
      try
        escapedKey = key.toString().replace(/"/g,'""')
        if row is 1
          unless options.objectAsValues
            console.log "Boring options", options.objectAsValues, options
            headerPlaceholder.push escapedKey
          else
            console.info "objectAsValues set"
            for col, data of value
              if isArray options.acceptableCols
                if col in options.acceptableCols
                  headerPlaceholder.push col
              else
                headerPlaceholder.push col
            console.log "Using as header", headerPlaceholder
        if typeof value is "object" and cascadeObjects
          # Parse it differently
          value = parser(value, true)
        handleValue = (providedValue = value, providedOptions = options) ->
          # Parse it all
          if isNull value
            escapedValue = ""
          else
            if typeof providedValue is "object"
              providedValue = JSON.stringify providedValue
            providedValue = providedValue.toString()
            tempValue = providedValue.replace(/,/g,'\,')
            tempValue = tempValue.replace(/"/g,'""')
            tempValue = tempValue.replace(/<\/p><p>/g,'","')
            if typeof providedOptions.splitValues is "string"
              tempValueArr = tempValue.split providedOptions.splitValues
              tempValue = tempValueArr.join "\",\""
              escapedKey = false
            escapedValue = tempValue
          if escapedKey is false
            # Special case of split values
            tmpTextAsset = "\"#{escapedValue}\"\n"
          else if isNumber escapedKey
            tmpTextAsset = "\"#{escapedValue}\","
          else unless isNull escapedKey
            tmpTextAsset = """"#{escapedKey}","#{escapedValue}"

            """
          tmpTextAsset
        # Build the textAsset string
        unless options.objectAsValues
          textAsset += handleValue(value)
        else
          tmpRow = new Array()
          for col in headerPlaceholder
            dataVal = value[col]
            if typeof dataVal is "object"
              try
                dataVal = JSON.stringify dataVal
                dataVal = dataVal.replace(/"/g,'""')
            tmpRow.push dataVal
          tmpRowString = tmpRow.join options.splitValues
          textAsset += handleValue tmpRowString, options
      catch e
        console.warn "Unable to run key #{key} on row #{row}", value, jsonObj
        console.warn e.stack
  textAsset = textAsset.trim()
  k = 0
  for col in headerPlaceholder
    col = col.replace(/"/g,'""')
    headerPlaceholder[k] = col
    ++k
  if options.objectAsValues
    options.header = headerPlaceholder
  if isArray options.header
    headerStr = options.header.join "\",\""
    textAsset = """
    "#{headerStr}"
    #{textAsset}
    """
    # CoffeScript 1.10 has a bug with """ leading ", so we needed to
    # start on a new line above. Remove it.
    textAsset = textAsset.trim()
    header = "present" # https://tools.ietf.org/html/rfc4180#page-4
  else
    # https://tools.ietf.org/html/rfc4180#page-4
    header = "absent"
  if textAsset.slice(-1) is ","
    textAsset = textAsset.slice(0, -1)
  file = "data:text/csv;charset=utf-8;header=#{header}," + encodeURIComponent(textAsset)
  selector = options.selector
  if options.create is true
    c = randomInt 0, 9999
    id = "#{selector.slice(1)}-download-button-#{c}"
    html = """
    <a id="#{id}" class="#{options.classes}" href="#{file}" download="#{options.downloadFile}">
      #{options.iconHtml}
      #{options.buttonText}
    </a>
    """
  else
    html = ""
  response =
    file: file
    options: options
    html: html
  elapsed = Date.now() - startTime
  console.debug "CSV Worker saved #{elapsed}ms from main thread"
  response



generateCSVFromResults = (resultArray, caller, selector = "#modal-sql-details-list") ->
  console.info "Worker CSV: Given", resultArray
  options =
    objectAsValues: true
    downloadFile: "adp-global-search-result-data_#{Date.now()}.csv"
    # acceptableCols: [
    #   "collectionid"
    #   "catalognumber"
    #   "fieldnumber"
    #   "sampleid"
    #   "diseasetested"
    #   "diseasestrain"
    #   "samplemethod"
    #   "sampledisposition"
    #   "diseasedetected"
    #   "fatal"
    #   "cladesampled"
    #   "genus"
    #   "specificepithet"
    #   "infraspecificepithet"
    #   "lifestage"
    #   "dateidentified"
    #   "decimallatitude"
    #   "decimallongitude"
    #   "alt"
    #   "coordinateuncertaintyinmeters"
    #   "collector"
    #   "fimsextra"
    #   "originaltaxa"
    #   ]
  try
    response = downloadCSVFile(resultArray, options)
  catch
    console.error "Sorry, there was a problem with this dataset and we can't do that right now."
    response =
      file: ""
      options: options
      html: ""
  response




validateAWebTaxon = (taxonObj, callback = null) ->
  ###
  #
  #
  # @param Object taxonObj -> object with keys "genus", "species", and
  #   optionally "subspecies"
  # @param function callback -> Callback function
  ###
  unless validationMeta?.validatedTaxons?
    # Just being thorough on this check
    unless typeof validationMeta is "object"
      validationMeta = new Object()
    # Create the array if it doesn't exist yet
    validationMeta.validatedTaxons = new Array()
  doCallback = (validatedTaxon) ->
    if typeof callback is "function"
      callback(validatedTaxon)
    false
  # Check the taxon against pre-validated ones
  if validationMeta.validatedTaxons.containsObject taxonObj
    console.info "Already validated taxon, skipping revalidation", taxonObj
    doCallback(taxonObj)
    return false
  args = "action=validate&genus=#{taxonObj.genus}&species=#{taxonObj.species}"
  if taxonObj.subspecies?
    args += "&subspecies=#{taxonObj.subspecies}"
  _adp.currentAsyncJqxhr = $.post "api.php", args, "json"
  .done (result) ->
    if result.status
      # Success! Save validated taxon, and run callback
      taxonObj.genus = result.validated_taxon.genus
      taxonObj.species = result.validated_taxon.species
      taxonObj.subspecies = result.validated_taxon.subspecies
      taxonObj.clade ?= result.validated_taxon.family
      validationMeta.validatedTaxons.push taxonObj
    else
      taxonObj.invalid = true
    taxonObj.response = result
    doCallback(taxonObj)
    return false
  .fail (result, status) ->
    # On fail, notify the user that the taxon wasn't actually validated
    # with a BSAlert, rather than toast
    prettyTaxon = "#{taxonObj.genus} #{taxonObj.species}"
    prettyTaxon = if taxonObj.subspecies? then "#{prettyTaxon} #{taxonObj.subspecies}" else prettyTaxon
    bsAlert "<strong>Problem validating taxon:</strong> #{prettyTaxon} couldn't be validated."
    console.warn "Warning: Couldn't validate #{prettyTaxon} with AmphibiaWeb with owrker"
  false
