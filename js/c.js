var Point, activityIndicatorOff, activityIndicatorOn, adData, allError, animateHoverShadows, animateLoad, backupDebugLog, bindClicks, bindCollapsors, bindCopyEvents, bindDismissalRemoval, bsAlert, buildArgs, buildMap, buildQuery, byteCount, cancelAsyncOperation, canonicalizePoint, cartoAccount, cartoMap, cartoVis, checkFileVersion, checkLoggedIn, cleanupToasts, copyText, createConvexHull, createMap, createMap2, createRawCartoMap, d$, dateMonthToString, deEscape, decode64, deepJQuery, defaultFillColor, defaultFillOpacity, defaultMapMouseOverBehaviour, delay, delayPolymerBind, disableDebugLogging, doCORSget, doMapBuilder, doNothing, downloadCSVFile, downloadCSVFileOnThread, e, enableDebugLogging, encode64, error1, fPoint, featureClickEvent, fetchCitation, fixTruncatedJson, foo, formatScientificNames, gMapsApiKey, generateCSVFromResults, getColumnObj, getConvexHull, getConvexHullConfig, getConvexHullPoints, getCorners, getElementHtml, getLocation, getMapCenter, getMapZoom, getMaxZ, getPointsFromBoundingBox, getPointsFromCartoResult, getPosterFromSrc, goTo, interval, isArray, isBlank, isBool, isEmpty, isHovered, isJson, isNull, isNumber, jsonTo64, lightboxImages, linkUsers, loadJS, localityFromMapBuilder, makePageCitationOverflow, mapNewWindows, openLink, openTab, overlayOff, overlayOn, p$, post64, prepURI, randomInt, randomString, reInitMap, reportDebugLog, roundNumber, roundNumberSigfig, safariDialogHelper, setupMapMarkerToggles, sortPointX, sortPointY, sortPoints, sortPointsXY, speculativeApiLoader, startLoad, stopLoad, stopLoadError, toFloat, toInt, toObject, toastStatusMessage, toggleGoogleMapMarkers, uri, validateAWebTaxon, wait,
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

try {
  uri = new Object();
  uri.o = $.url();
  uri.urlString = uri.o.attr('protocol') + '://' + uri.o.attr('host') + uri.o.attr("directory");
  uri.query = uri.o.attr("fragment");
} catch (error1) {
  e = error1;
  console.warn("PURL not installed!");
}

window.locationData = new Object();

locationData.params = {
  enableHighAccuracy: true
};

locationData.last = void 0;

window.debounce_timer = null;

if (window.adminParams == null) {
  window.adminParams = new Object();
}

if (window._adp == null) {
  window._adp = new Object();
}

isBool = function(str, strict) {
  var error2;
  if (strict == null) {
    strict = false;
  }
  if (strict) {
    return typeof str === "boolean";
  }
  try {
    if (typeof str === "boolean") {
      return str === true || str === false;
    }
    if (typeof str === "string") {
      return str.toLowerCase() === "true" || str.toLowerCase() === "false";
    }
    if (typeof str === "number") {
      return str === 1 || str === 0;
    }
    return false;
  } catch (error2) {
    e = error2;
    return false;
  }
};

isEmpty = function(str) {
  return !str || str.length === 0;
};

isBlank = function(str) {
  return !str || /^\s*$/.test(str);
};

isNull = function(str, dirty) {
  var error2, l;
  if (dirty == null) {
    dirty = false;
  }
  if (typeof str === "object") {
    try {
      l = str.length;
      if (l != null) {
        try {
          return l === 0;
        } catch (undefined) {}
      }
      return Object.size === 0;
    } catch (undefined) {}
  }
  try {
    if (isEmpty(str) || isBlank(str) || (str == null)) {
      if (!(str === false || str === 0)) {
        return true;
      }
      if (dirty) {
        if (str === false || str === 0) {
          return true;
        }
      }
    }
  } catch (error2) {
    e = error2;
    return false;
  }
  try {
    str = str.toString().toLowerCase();
  } catch (undefined) {}
  if (str === "undefined" || str === "null") {
    return true;
  }
  if (dirty && (str === "false" || str === "0")) {
    return true;
  }
  return false;
};

isJson = function(str) {
  var error2;
  if (typeof str === 'object' && !isArray(str)) {
    return true;
  }
  try {
    JSON.parse(str);
    return true;
  } catch (error2) {
    return false;
  }
  return false;
};

isArray = function(arr) {
  var error2, shadow;
  try {
    shadow = arr.slice(0);
    shadow.push("foo");
    return true;
  } catch (error2) {
    return false;
  }
};

isNumber = function(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
};

toFloat = function(str) {
  if (!isNumber(str) || isNull(str)) {
    return 0;
  }
  return parseFloat(str);
};

toInt = function(str) {
  var f;
  if (typeof str === "string") {
    str = str.replace("px", "").replace("em", "").replace("rem", "").replace("vw", "").replace("vh", "");
  }
  if (!isNumber(str) || isNull(str)) {
    return 0;
  }
  f = parseFloat(str);
  return parseInt(f);
};

String.prototype.toAscii = function() {

  /*
   * Remove MS Word bullshit
   */
  return this.replace(/[\u2018\u2019\u201A\u201B\u2032\u2035]/g, "'").replace(/[\u201C\u201D\u201E\u201F\u2033\u2036]/g, '"').replace(/[\u2013\u2014]/g, '-').replace(/[\u2026]/g, '...').replace(/\u02C6/g, "^").replace(/\u2039/g, "").replace(/[\u02DC|\u00A0]/g, " ");
};

String.prototype.toBool = function() {
  var test;
  test = this.toString().toLowerCase();
  return test === 'true' || test === "1";
};

Boolean.prototype.toBool = function() {
  return this.toString() === "true";
};

Number.prototype.toBool = function() {
  return this.toString() === "1";
};

String.prototype.addSlashes = function() {
  return this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0');
};

Array.prototype.max = function() {
  return Math.max.apply(null, this);
};

Array.prototype.min = function() {
  return Math.min.apply(null, this);
};

Array.prototype.containsObject = function(obj) {
  var error2, res;
  try {
    res = _.find(this, function(val) {
      return _.isEqual(obj, val);
    });
    return typeof res === "object";
  } catch (error2) {
    e = error2;
    console.error("Please load underscore.js before using this.");
    return console.info("https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js");
  }
};

Object.toArray = function(obj) {
  var shadowObj;
  try {
    shadowObj = obj.slice(0);
    shadowObj.push("foo");
    return obj;
  } catch (undefined) {}
  return Object.keys(obj).map((function(_this) {
    return function(key) {
      return obj[key];
    };
  })(this));
};

Object.size = function(obj) {
  var error2, key, size;
  if (typeof obj !== "object") {
    try {
      return obj.length;
    } catch (error2) {
      e = error2;
      console.error("Passed argument isn't an object and doesn't have a .length parameter");
      console.warn(e.message);
    }
  }
  size = 0;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      size++;
    }
  }
  return size;
};

Object.doOnSortedKeys = function(obj, fn) {
  var data, key, len, results, sortedKeys, t;
  sortedKeys = Object.keys(obj).sort();
  results = [];
  for (t = 0, len = sortedKeys.length; t < len; t++) {
    key = sortedKeys[t];
    data = obj[key];
    results.push(fn(data));
  }
  return results;
};

delay = function(ms, f) {
  return setTimeout(f, ms);
};

interval = function(ms, f) {
  return setInterval(f, ms);
};

roundNumber = function(number, digits) {
  var multiple;
  if (digits == null) {
    digits = 0;
  }
  multiple = Math.pow(10, digits);
  return Math.round(number * multiple) / multiple;
};

roundNumberSigfig = function(number, digits) {
  var digArr, needDigits, newNumber, significand, trailingDigits;
  if (digits == null) {
    digits = 0;
  }
  newNumber = roundNumber(number, digits).toString();
  digArr = newNumber.split(".");
  if (digArr.length === 1) {
    return newNumber + "." + (Array(digits + 1).join("0"));
  }
  trailingDigits = digArr.pop();
  significand = digArr[0] + ".";
  if (trailingDigits.length === digits) {
    return newNumber;
  }
  needDigits = digits - trailingDigits.length;
  trailingDigits += Array(needDigits + 1).join("0");
  return "" + significand + trailingDigits;
};

String.prototype.stripHtml = function(stripChildren) {
  var str;
  if (stripChildren == null) {
    stripChildren = false;
  }
  str = this;
  if (stripChildren) {
    str = str.replace(/<(\w+)(?:[^"'>]|"[^"]*"|'[^']*')*>(?:((?:.)*?))<\/?\1(?:[^"'>]|"[^"]*"|'[^']*')*>/mg, "");
  }
  str = str.replace(/<script[^>]*>([\S\s]*?)<\/script>/gmi, '');
  str = str.replace(/<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, '');
  return str;
};

String.prototype.unescape = function(strict) {
  var decodeHTMLEntities, element, tmp;
  if (strict == null) {
    strict = false;
  }

  /*
   * Take escaped text, and return the unescaped version
   *
   * @param string str | String to be used
   * @param bool strict | Stict mode will remove all HTML
   *
   * Test it here:
   * https://jsfiddle.net/tigerhawkvok/t9pn1dn5/
   *
   * Code: https://gist.github.com/tigerhawkvok/285b8631ed6ebef4446d
   */
  element = document.createElement("div");
  decodeHTMLEntities = function(str) {
    if ((str != null) && typeof str === "string") {
      if (strict !== true) {
        str = escape(str).replace(/%26/g, '&').replace(/%23/g, '#').replace(/%3B/g, ';');
      } else {
        str = str.replace(/<script[^>]*>([\S\s]*?)<\/script>/gmi, '');
        str = str.replace(/<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, '');
      }
      element.innerHTML = str;
      if (element.innerText) {
        str = element.innerText;
        element.innerText = "";
      } else {
        str = element.textContent;
        element.textContent = "";
      }
    }
    return unescape(str);
  };
  tmp = deEscape(this);
  return decodeHTMLEntities(tmp);
};

deEscape = function(string) {
  string = string.replace(/\&amp;#/mg, '&#');
  string = string.replace(/\&quot;/mg, '"');
  string = string.replace(/\&quote;/mg, '"');
  string = string.replace(/\&#95;/mg, '_');
  string = string.replace(/\&#39;/mg, "'");
  string = string.replace(/\&#34;/mg, '"');
  string = string.replace(/\&#62;/mg, '>');
  string = string.replace(/\&#60;/mg, '<');
  return string;
};

String.prototype.escapeQuotes = function() {
  var str;
  str = this.replace(/"/mg, "&#34;");
  str = str.replace(/'/mg, "&#39;");
  return str;
};

getElementHtml = function(el) {
  return el.outerHTML;
};

jQuery.fn.outerHTML = function() {
  e = $(this).get(0);
  return e.outerHTML;
};

jQuery.fn.outerHtml = function() {
  return $(this).outerHTML();
};

buildQuery = function(obj) {
  var k, key, queryList, v, value;
  queryList = new Array();
  for (k in obj) {
    v = obj[k];
    key = k.replace(/[^A-Za-z\-_\[\]]/img, "");
    value = encodeURIComponent(v).replace(/\%20/g, "+");
    queryList.push(key + "=" + value);
  }
  return queryList.join("&");
};

buildArgs = buildQuery;


jQuery.fn.selectText = function(){
    var doc = document
        , element = this[0]
        , range, selection
    ;
    if (doc.body.createTextRange) {
        range = document.body.createTextRange();
        range.moveToElementText(element);
        range.select();
    } else if (window.getSelection) {
        selection = window.getSelection();
        range = document.createRange();
        range.selectNodeContents(element);
        selection.removeAllRanges();
        selection.addRange(range);
    }
};
;

copyText = function(text, zcObj, zcElement) {

  /*
   *
   */
  var clip, clipboardData, identifier, ref;
  if (window.copyDebouncer == null) {
    window.copyDebouncer = new Object();
  }
  if (Date.now() - window.copyDebouncer.last < 300) {
    console.warn("Skipping copy on debounce");
    return false;
  }
  window.copyDebouncer.last = Date.now();
  identifier = md5($(zcElement).html());
  try {
    clipboardData = {
      dataType: "text/plain",
      data: text
    };
    clip = new ClipboardEvent("copy", clipboardData);
    document.dispatchEvent(clip);
    return false;
  } catch (undefined) {}
  if (((ref = _adp.copyObject) != null ? ref[identifier] : void 0) != null) {
    clipboardData = {
      "text/plain": text
    };
    console.info("Setting up clipboard events for \"" + text + "\"");
    _adp.copyObject[identifier].setData(clipboardData);
    _adp.copyObject[identifier].on("copy", function(e) {
      try {
        return e.clipboardData = {
          setData: _adp.copyObject[identifier].setData(clipboardData)
        };
      } catch (undefined) {}
    });
    _adp.copyObject[identifier].on("aftercopy", function(e) {
      if (e.data["text/plain"] === text) {
        toastStatusMessage("Copied to clipboard");
        console.info("Succesfully copied", e.data["text/plain"]);
        window.hasRetriedCopy = false;
      } else {
        if (e.data["text/plain"]) {
          console.warn("Incorrect copy: instead of '" + text + "', '" + e.data["text/plain"] + "'");
          if (!window.hasRetriedCopy) {
            window.hasRetriedCopy = true;
            delete window.copyDebouncer.last;
            delay(100, function() {
              console.warn("Re-trying copy");
              $(zcElement).click();
              return console.info("Sent click");
            });
          } else {
            console.error("Re-copy failed!");
            toastStatusMessage("Error copying to clipboard. Please try again");
          }
        } else {
          console.error("Bad data passed", e.data["text/plain"]);
          toastStatusMessage("Error copying to clipboard. Please try again");
          window.hasRetriedCopy = false;
        }
      }
      window.resetClipboard = false;
      return _adp.copyObject[identifier].setData(clipboardData);
    });
    _adp.copyObject[identifier].on("error", function(e) {
      console.error("Error copying to clipboard");
      console.warn("Got", e);
      if (e.name === "flash-overdue") {
        if (window.resetClipboard === true) {
          console.error("Resetting ZeroClipboard didn't work!");
          return false;
        }
        ZeroClipboard.on("ready", function() {
          window.resetClipboard = true;
          return copyLink(window.tempZC, text);
        });
        window.tempZC = new ZeroClipboard(zcElement);
      }
      if (e.name === "flash-disabled") {
        console.info("No flash on this system");
        ZeroClipboard.destroy();
        $(".click-copy").remove();
        p$("paper-dialog").refit();
        return toastStatusMessage("Clipboard copying isn't available on your system");
      }
    });
  } else {
    console.error("Can't copy: zcObject doesn't exist for identifier " + identifier);
  }
  return false;
};

bindCopyEvents = function(selector) {
  if (selector == null) {
    selector = ".click-copy";
  }
  loadJS("bower_components/zeroclipboard/dist/ZeroClipboard.min.js", function() {
    var copySelector, el, identifier, len, ref, results, t, text, zcConfig;
    zcConfig = {
      swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
    };
    ZeroClipboard.config(zcConfig);
    ref = $(selector);
    results = [];
    for (t = 0, len = ref.length; t < len; t++) {
      el = ref[t];
      identifier = md5($(el).html());
      if (_adp.copyObject == null) {
        _adp.copyObject = new Object();
      }
      if (_adp.copyObject[identifier] == null) {
        console.info("Setting up copy events for identifier", identifier);
        _adp.copyObject[identifier] = new ZeroClipboard(el);
        text = $(el).attr("data-clipboard-text");
        if (isNull(text)) {
          copySelector = $(el).attr("data-copy-selector");
          text = $(copySelector).val();
          if (isNull(text)) {
            try {
              text = p$(copySelector).value;
            } catch (undefined) {}
          }
        }
        console.info("Registering copy text", text);
        try {
          delete window.copyDebouncer.last;
        } catch (undefined) {}
        results.push(copyText(text, _adp.copyObject[identifier], el));
      } else {
        results.push(console.info("Copy event already set up for identifier", identifier));
      }
    }
    return results;
  });
  return false;
};

buildQuery = function(obj) {
  var k, key, queryList, v, value;
  queryList = new Array();
  for (k in obj) {
    v = obj[k];
    key = k.replace(/[^A-Za-z\-_\[\]]/img, "");
    value = encodeURIComponent(v).replace(/\%20/g, "+");
    queryList.push(key + "=" + value);
  }
  return queryList.join("&");
};

jsonTo64 = function(obj, encode) {
  var encoded, objString, shadowObj;
  if (encode == null) {
    encode = true;
  }

  /*
   *
   * @param obj
   * @param boolean encode -> URI encode base64 string
   */
  try {
    shadowObj = obj.slice(0);
    shadowObj.push("foo");
    obj = toObject(obj);
  } catch (undefined) {}
  objString = JSON.stringify(obj);
  if (encode === true) {
    encoded = post64(objString);
  } else {
    encoded = encode64(encoded);
  }
  return encoded;
};

encode64 = function(string) {
  var error2;
  try {
    return Base64.encode(string);
  } catch (error2) {
    e = error2;
    console.warn("Bad encode string provided");
    return string;
  }
};

decode64 = function(string) {
  var error2;
  try {
    return Base64.decode(string);
  } catch (error2) {
    e = error2;
    console.warn("Bad decode string provided");
    return string;
  }
};

post64 = function(string) {
  var p64, s64;
  s64 = encode64(string);
  p64 = encodeURIComponent(s64);
  return p64;
};

jQuery.fn.polymerSelected = function(setSelected, attrLookup) {
  var attr, error2, error3, itemSelector, val;
  if (setSelected == null) {
    setSelected = void 0;
  }
  if (attrLookup == null) {
    attrLookup = "attrForSelected";
  }

  /*
   * See
   * https://elements.polymer-project.org/elements/paper-menu
   * https://elements.polymer-project.org/elements/paper-radio-group
   *
   * @param attrLookup is based on
   * https://elements.polymer-project.org/elements/iron-selector?active=Polymer.IronSelectableBehavior
   */
  attr = $(this).attr(attrLookup);
  if (setSelected != null) {
    if (!isBool(setSelected)) {
      try {
        return $(this).get(0).select(setSelected);
      } catch (error2) {
        e = error2;
        return false;
      }
    } else {
      $(this).parent().children().removeAttribute("aria-selected");
      $(this).parent().children().removeAttribute("active");
      $(this).parent().children().removeClass("iron-selected");
      $(this).prop("selected", setSelected);
      $(this).prop("active", setSelected);
      $(this).prop("aria-selected", setSelected);
      if (setSelected === true) {
        return $(this).addClass("iron-selected");
      }
    }
  } else {
    val = void 0;
    try {
      val = $(this).get(0).selected;
      if (isNumber(val) && !isNull(attr)) {
        itemSelector = $(this).find("paper-item")[toInt(val)];
        val = $(itemSelector).attr(attr);
      }
    } catch (error3) {
      e = error3;
      return false;
    }
    if (val === "null" || (val == null)) {
      val = void 0;
    }
    return val;
  }
};

jQuery.fn.polymerChecked = function(setChecked) {
  var val;
  if (setChecked == null) {
    setChecked = void 0;
  }
  if (setChecked != null) {
    return jQuery(this).prop("checked", setChecked);
  } else {
    val = jQuery(this)[0].checked;
    if (val === "null" || (val == null)) {
      val = void 0;
    }
    return val;
  }
};

isHovered = function(selector) {
  return $(selector + ":hover").length > 0;
};

jQuery.fn.exists = function() {
  return jQuery(this).length > 0;
};

jQuery.fn.isVisible = function() {
  return jQuery(this).is(":visible") && jQuery(this).css("visibility") !== "hidden";
};

jQuery.fn.hasChildren = function() {
  return Object.size(jQuery(this).children()) > 3;
};

byteCount = (function(_this) {
  return function(s) {
    return encodeURI(s).split(/%..|./).length - 1;
  };
})(this);

function shuffle(o) { //v1.0
    for (var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
};

toObject = function(array) {
  var element, index, rv;
  rv = new Object();
  for (index in array) {
    element = array[index];
    if (element !== void 0) {
      rv[index] = element;
    }
  }
  return rv;
};

loadJS = function(src, callback, doCallbackOnError) {
  var error2, errorFunction, onLoadFunction, s;
  if (callback == null) {
    callback = new Object();
  }
  if (doCallbackOnError == null) {
    doCallbackOnError = true;
  }

  /*
   * Load a new javascript file
   *
   * If it's already been loaded, jump straight to the callback
   *
   * @param string src The source URL of the file
   * @param function callback Function to execute after the script has
   *                          been loaded
   * @param bool doCallbackOnError Should the callback be executed if
   *                               loading the script produces an error?
   */
  if ($("script[src='" + src + "']").exists()) {
    if (typeof callback === "function") {
      try {
        callback();
      } catch (error2) {
        e = error2;
        console.error("Script is already loaded, but there was an error executing the callback function - " + e.message);
      }
    }
    return true;
  }
  s = document.createElement("script");
  s.setAttribute("src", src);
  s.setAttribute("async", "async");
  s.setAttribute("type", "text/javascript");
  s.src = src;
  s.async = true;
  onLoadFunction = function() {
    var error3, error4, state;
    state = s.readyState;
    try {
      if (!callback.done && (!state || /loaded|complete/.test(state))) {
        callback.done = true;
        if (typeof callback === "function") {
          try {
            return callback();
          } catch (error3) {
            e = error3;
            console.error("Postload callback error for " + src + " - " + e.message);
            return console.warn(e.stack);
          }
        }
      }
    } catch (error4) {
      e = error4;
      return console.error("Onload error - " + e.message);
    }
  };
  errorFunction = function() {
    var error3, error4;
    console.warn("There may have been a problem loading " + src);
    try {
      if (!callback.done) {
        callback.done = true;
        if (typeof callback === "function" && doCallbackOnError) {
          try {
            return callback();
          } catch (error3) {
            e = error3;
            return console.error("Post error callback error - " + e.message);
          }
        }
      }
    } catch (error4) {
      e = error4;
      return console.error("There was an error in the error handler! " + e.message);
    }
  };
  s.setAttribute("onload", onLoadFunction);
  s.setAttribute("onreadystate", onLoadFunction);
  s.setAttribute("onerror", errorFunction);
  s.onload = s.onreadystate = onLoadFunction;
  s.onerror = errorFunction;
  document.getElementsByTagName('head')[0].appendChild(s);
  return true;
};

String.prototype.toTitleCase = function() {
  var len, len1, lower, lowerRegEx, lowers, str, t, u, upper, upperRegEx, uppers;
  str = this.replace(/([^\W_]+[^\s-]*) */g, function(txt) {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
  lowers = ["A", "An", "The", "And", "But", "Or", "For", "Nor", "As", "At", "By", "For", "From", "In", "Into", "Near", "Of", "On", "Onto", "To", "With"];
  for (t = 0, len = lowers.length; t < len; t++) {
    lower = lowers[t];
    lowerRegEx = new RegExp("\\s" + lower + "\\s", "g");
    str = str.replace(lowerRegEx, function(txt) {
      return txt.toLowerCase();
    });
  }
  uppers = ["Id", "Tv"];
  for (u = 0, len1 = uppers.length; u < len1; u++) {
    upper = uppers[u];
    upperRegEx = new RegExp("\\b" + upper + "\\b", "g");
    str = str.replace(upperRegEx, upper.toUpperCase());
  }
  return str;
};

Function.prototype.getName = function() {

  /*
   * Returns a unique identifier for a function
   */
  var name;
  name = this.name;
  if (name == null) {
    name = this.toString().substr(0, this.toString().indexOf("(")).replace("function ", "");
  }
  if (isNull(name)) {
    name = md5(this.toString());
  }
  return name;
};

Function.prototype.debounce = function() {
  var args, delayed, error2, execAsap, func, key, ref, threshold, timeout;
  threshold = arguments[0], execAsap = arguments[1], timeout = arguments[2], args = 4 <= arguments.length ? slice.call(arguments, 3) : [];
  if (threshold == null) {
    threshold = 300;
  }
  if (execAsap == null) {
    execAsap = false;
  }
  if (timeout == null) {
    timeout = window.debounce_timer;
  }

  /*
   * Borrowed from http://coffeescriptcookbook.com/chapters/functions/debounce
   * Only run the prototyped function once per interval.
   *
   * @param threshold -> Timeout in ms
   * @param execAsap -> Do it NAOW
   * @param timeout -> backup timeout object
   */
  if (((ref = window.core) != null ? ref.debouncers : void 0) == null) {
    if (window.core == null) {
      window.core = new Object();
    }
    core.debouncers = new Object();
  }
  try {
    key = this.getName();
  } catch (undefined) {}
  try {
    if (core.debouncers[key] != null) {
      timeout = core.debouncers[key];
    }
  } catch (undefined) {}
  func = this;
  delayed = function() {
    if (key != null) {
      clearTimeout(timeout);
      delete core.debouncers[key];
    }
    if (!execAsap) {
      return func.apply(func, args);
    }
  };
  if (timeout != null) {
    try {
      clearTimeout(timeout);
    } catch (error2) {
      e = error2;
    }
  }
  if (execAsap) {
    func.apply(obj, args);
    console.log("Executed " + key + " immediately");
    return false;
  }
  if (key != null) {
    return core.debouncers[key] = delay(threshold, function() {
      return delayed();
    });
  } else {
    console.log("Delaying '" + key + "' for " + threshold + " ms");
    return window.debounce_timer = delay(threshold, function() {
      return delayed();
    });
  }
};

randomInt = function(lower, upper) {
  var ref, ref1, start;
  if (lower == null) {
    lower = 0;
  }
  if (upper == null) {
    upper = 1;
  }
  start = Math.random();
  if (lower == null) {
    ref = [0, lower], lower = ref[0], upper = ref[1];
  }
  if (lower > upper) {
    ref1 = [upper, lower], lower = ref1[0], upper = ref1[1];
  }
  return Math.floor(start * (upper - lower + 1) + lower);
};

randomString = function(length) {
  var char, charBottomSearchSpace, charUpperSearchSpace, i, stringArray;
  if (length == null) {
    length = 8;
  }
  i = 0;
  charBottomSearchSpace = 65;
  charUpperSearchSpace = 126;
  stringArray = new Array();
  while (i < length) {
    ++i;
    char = randomInt(charBottomSearchSpace, charUpperSearchSpace);
    stringArray.push(String.fromCharCode(char));
  }
  return stringArray.join("");
};

animateLoad = function(elId) {
  var error2, selector;
  if (elId == null) {
    elId = "loader";
  }

  /*
   * Suggested CSS to go with this:
   *
   * #loader {
   *     position:fixed;
   *     top:50%;
   *     left:50%;
   * }
   * #loader.good::shadow .circle {
   *     border-color: rgba(46,190,17,0.9);
   * }
   * #loader.bad::shadow .circle {
   *     border-color:rgba(255,0,0,0.9);
   * }
   *
   * Uses Polymer 1.0
   */
  if (isNumber(elId)) {
    elId = "loader";
  }
  if (elId.slice(0, 1) === "#") {
    selector = elId;
    elId = elId.slice(1);
  } else {
    selector = "#" + elId;
  }
  try {
    if (!$(selector).exists()) {
      $("body").append("<paper-spinner id=\"" + elId + "\" active></paper-spinner");
    } else {
      $(selector).attr("active", true);
    }
    return false;
  } catch (error2) {
    e = error2;
    return console.log('Could not animate loader', e.message);
  }
};

startLoad = animateLoad;

stopLoad = function(elId, fadeOut) {
  var error2, selector;
  if (elId == null) {
    elId = "loader";
  }
  if (fadeOut == null) {
    fadeOut = 1000;
  }
  if (elId.slice(0, 1) === "#") {
    selector = elId;
    elId = elId.slice(1);
  } else {
    selector = "#" + elId;
  }
  try {
    if ($(selector).exists()) {
      $(selector).addClass("good");
      return delay(fadeOut, function() {
        $(selector).removeClass("good");
        return $(selector).removeAttr("active");
      });
    }
  } catch (error2) {
    e = error2;
    return console.log('Could not stop load animation', e.message);
  }
};

stopLoadError = function(message, elId, fadeOut) {
  var error2, selector;
  if (elId == null) {
    elId = "loader";
  }
  if (fadeOut == null) {
    fadeOut = 10000;
  }
  if (elId.slice(0, 1) === "#") {
    selector = elId;
    elId = elId.slice(1);
  } else {
    selector = "#" + elId;
  }
  try {
    if ($(selector).exists()) {
      $(selector).addClass("bad");
      if (message != null) {
        toastStatusMessage(message, "", fadeOut);
      }
      return delay(fadeOut, function() {
        $(selector).removeClass("bad");
        return $(selector).removeAttr("active");
      });
    }
  } catch (error2) {
    e = error2;
    return console.log('Could not stop load error animation', e.message);
  }
};

toastStatusMessage = function(message, className, duration, selector) {
  var html, ref, timeout;
  if (className == null) {
    className = "";
  }
  if (duration == null) {
    duration = 3000;
  }
  if (selector == null) {
    selector = "#status-message";
  }

  /*
   * Pop up a status message
   */
  if (((ref = window.metaTracker) != null ? ref.isToasting : void 0) == null) {
    if (window.metaTracker == null) {
      window.metaTracker = new Object();
      window.metaTracker.toastTracker = new Array();
      window.metaTracker.isToasting = false;
    }
  }
  if (window.metaTracker.isToasting) {
    timeout = delay(250, function() {
      return toastStatusMessage(message, className, duration, selector);
    });
    window.metaTracker.toastTracker.push(timeout);
    return false;
  }
  window.metaTracker.isToasting = true;
  if (!isNumber(duration)) {
    duration = 3000;
  }
  if (selector.slice(0, 1) === !"#") {
    selector = "#" + selector;
  }
  if (!$(selector).exists()) {
    html = "<paper-toast id=\"" + (selector.slice(1)) + "\" duration=\"" + duration + "\"></paper-toast>";
    $(html).appendTo("body");
  }
  $(selector).attr("text", message).html(message).addClass(className);
  try {
    p$(selector).show();
  } catch (undefined) {}
  return delay(duration + 500, function() {
    var error2, isOpen;
    try {
      isOpen = p$(selector).opened;
    } catch (error2) {
      isOpen = false;
    }
    if (!isOpen) {
      $(selector).empty();
      $(selector).removeClass(className);
      $(selector).attr("text", "");
    }
    return window.metaTracker.isToasting = false;
  });
};

cleanupToasts = function() {
  var len, ref, results, t, timeout;
  ref = window.metaTracker.toastTracker;
  results = [];
  for (t = 0, len = ref.length; t < len; t++) {
    timeout = ref[t];
    try {
      results.push(clearTimeout(timeout));
    } catch (undefined) {}
  }
  return results;
};

openLink = function(url) {
  if (url == null) {
    return false;
  }
  window.open(url);
  return false;
};

openTab = function(url) {
  return openLink(url);
};

goTo = function(url) {
  if (url == null) {
    return false;
  }
  window.location.href = url;
  return false;
};

mapNewWindows = function(stopPropagation) {
  var len, selector, t, useSelectors;
  if (stopPropagation == null) {
    stopPropagation = true;
  }
  useSelectors = [".newwindow", ".newWindow", ".new-window", "[newwindow]", "[new-window]"];
  for (t = 0, len = useSelectors.length; t < len; t++) {
    selector = useSelectors[t];
    $(selector).each(function() {
      var curHref;
      curHref = $(this).attr("href");
      if (curHref == null) {
        curHref = $(this).attr("data-href");
      }
      $(this).click(function(e) {
        if (stopPropagation) {
          e.preventDefault();
          e.stopPropagation();
        }
        return openTab(curHref);
      });
      return $(this).keypress(function() {
        return openTab(curHref);
      });
    });
  }
  return false;
};

deepJQuery = function(selector) {

  /*
   * Do a shadow-piercing selector
   *
   * Cross-browser, works with Chrome, Firefox, Opera, Safari, and IE
   * Falls back to standard jQuery selector when everything fails.
   */
  var error2, error3;
  if (typeof jQuery === "undefined" || jQuery === null) {
    console.warn("Danger -- jQuery isn't defined. Selectors may fail.");
  }
  try {
    if (!$("html /deep/ " + selector).exists()) {
      throw "Bad /deep/ selector";
    }
    return $("html /deep/ " + selector);
  } catch (error2) {
    e = error2;
    try {
      if (!$("html >>> " + selector).exists()) {
        throw "Bad >>> selector";
      }
      return $("html >>> " + selector);
    } catch (error3) {
      e = error3;
      return $(p$(selector));
    }
  }
};

d$ = function(selector) {
  return deepJQuery(selector);
};

bindClicks = function(selector) {
  if (selector == null) {
    selector = ".click";
  }

  /*
   * Helper function. Bind everything with a selector
   * to execute a function data-function or to go to a
   * URL data-href.
   */
  $(selector).each(function() {
    var callable, error2, error3, error4, newTab, ref, ref1, ref2, ref3, tagType, url;
    try {
      url = (ref = $(this).attr("data-href")) != null ? ref : $(this).attr("href");
      if (!isNull(url)) {
        try {
          tagType = $(this).prop("tagName").toLowerCase();
        } catch (error2) {
          tagType = null;
        }
        try {
          if (url === uri.o.attr("path") && tagType === "paper-tab") {
            $(this).parent().prop("selected", $(this).index());
          }
        } catch (error3) {
          e = error3;
          console.warn("tagname lower case error");
        }
        newTab = ((ref1 = $(this).attr("newTab")) != null ? ref1.toBool() : void 0) || ((ref2 = $(this).attr("newtab")) != null ? ref2.toBool() : void 0) || ((ref3 = $(this).attr("data-newtab")) != null ? ref3.toBool() : void 0);
        if (tagType === "a" && !newTab) {
          return true;
        }
        if (tagType === "a") {
          $(this).keypress(function() {
            return openTab(url);
          });
        }
        $(this).unbind().click(function(e) {
          var error4;
          e.preventDefault();
          e.stopPropagation();
          try {
            if (newTab) {
              return openTab(url);
            } else {
              return goTo(url);
            }
          } catch (error4) {
            return goTo(url);
          }
        });
        return url;
      } else {
        callable = $(this).attr("data-function");
        if (callable != null) {
          $(this).unbind();
          return $(this).click(function() {
            var args, error4, error5;
            try {
              console.log("Executing bound function " + callable + "()");
              try {
                args = null;
                if (!isNull($(this).attr("data-args"))) {
                  args = $(this).attr("data-args").split(",");
                }
              } catch (undefined) {}
              try {
                if (args != null) {
                  return window[callable].apply(window, args);
                } else {
                  return window[callable]();
                }
              } catch (error4) {
                return window[callable]();
              }
            } catch (error5) {
              e = error5;
              return console.error("'" + callable + "()' is a bad function - " + e.message);
            }
          });
        }
      }
    } catch (error4) {
      e = error4;
      return console.error("There was a problem binding to #" + ($(this).attr("id")) + " - " + e.message);
    }
  });
  try {
    bindCollapsors();
  } catch (undefined) {}
  return false;
};

bindCollapsors = function(selector) {
  var len, ref, t, toggle, toggleEvent;
  if (selector == null) {
    selector = ".collapse-trigger";
  }

  /*
   * Bind the events for collapse-triggers
   */
  toggleEvent = function(caller) {
    var ref, target, validTargetElements;
    target = $(caller).attr("data-target");
    if (!$(target).exists()) {
      console.error("Couldn't find target " + target);
      return false;
    }
    validTargetElements = ["iron-collapse"];
    if (ref = p$(target).tagName.toLowerCase(), indexOf.call(validTargetElements, ref) >= 0) {
      p$(target).toggle();
    } else {
      console.error("Target type " + (p$(target).tagName.toLowerCase()) + " is an invalid target");
    }
    return false;
  };
  ref = $(selector);
  for (t = 0, len = ref.length; t < len; t++) {
    toggle = ref[t];
    $(toggle).click(function() {
      return toggleEvent.debounce(50, null, null, this);
    });
  }
  return false;
};

dateMonthToString = function(month) {
  var conversionObj, error2, rv;
  conversionObj = {
    0: "January",
    1: "February",
    2: "March",
    3: "April",
    4: "May",
    5: "June",
    6: "July",
    7: "August",
    8: "September",
    9: "October",
    10: "November",
    11: "December"
  };
  try {
    rv = conversionObj[month];
  } catch (error2) {
    rv = month;
  }
  return rv;
};

getPosterFromSrc = function(srcString) {

  /*
   * Take the "src" attribute of a video and get the
   * "png" screencap from it, and return the value.
   */
  var dummy, error2, split;
  try {
    split = srcString.split(".");
    dummy = split.pop();
    split.push("png");
    return split.join(".");
  } catch (error2) {
    e = error2;
    return "";
  }
};

doCORSget = function(url, args, callback, callbackFail) {
  var corsFail, createCORSRequest, error2, settings, xhr;
  if (callback == null) {
    callback = void 0;
  }
  if (callbackFail == null) {
    callbackFail = void 0;
  }
  corsFail = function() {
    if (typeof callbackFail === "function") {
      return callbackFail();
    } else {
      throw new Error("There was an error performing the CORS request");
    }
  };
  settings = {
    url: url,
    data: args,
    type: "get",
    crossDomain: true
  };
  try {
    $.ajax(settings).done(function(result) {
      if (typeof callback === "function") {
        callback();
        return false;
      }
      return console.log(response);
    }).fail(function(result, status) {
      return console.warn("Couldn't perform jQuery AJAX CORS. Attempting manually.");
    });
  } catch (error2) {
    e = error2;
    console.warn("There was an error using jQuery to perform the CORS request. Attemping manually.");
  }
  url = url + "?" + args;
  createCORSRequest = function(method, url) {
    var xhr;
    if (method == null) {
      method = "get";
    }
    xhr = new XMLHttpRequest();
    if ("withCredentials" in xhr) {
      xhr.open(method, url, true);
    } else if (typeof XDomainRequest !== "undefined") {
      xhr = new XDomainRequest();
      xhr.open(method, url);
    } else {
      xhr = null;
    }
    return xhr;
  };
  xhr = createCORSRequest("get", url);
  if (!xhr) {
    throw new Error("CORS not supported");
  }
  xhr.onload = function() {
    var response;
    response = xhr.responseText;
    if (typeof callback === "function") {
      callback(response);
    }
    console.log(response);
    return false;
  };
  xhr.onerror = function() {
    console.warn("Couldn't do manual XMLHttp CORS request");
    return corsFail();
  };
  xhr.send();
  return false;
};

lightboxImages = function(selector, lookDeeply) {
  var jqo, options;
  if (selector == null) {
    selector = ".lightboximage";
  }
  if (lookDeeply == null) {
    lookDeeply = false;
  }

  /*
   * Lightbox images with this selector
   *
   * If the image has it, wrap it in an anchor and bind;
   * otherwise just apply to the selector.
   *
   * Requires ImageLightbox
   * https://github.com/rejas/imagelightbox
   */
  options = {
    onStart: function() {
      return overlayOn();
    },
    onEnd: function() {
      overlayOff();
      return activityIndicatorOff();
    },
    onLoadStart: function() {
      return activityIndicatorOn();
    },
    onLoadEnd: function() {
      return activityIndicatorOff();
    },
    allowedTypes: 'png|jpg|jpeg|gif|bmp|webp',
    quitOnDocClick: true,
    quitOnImgClick: true
  };
  jqo = lookDeeply ? d$(selector) : $(selector);
  return loadJS("bower_components/imagelightbox/dist/imagelightbox.min.js", function() {
    jqo.click(function(e) {
      var error2;
      try {
        e.preventDefault();
        e.stopPropagation();
        $(this).imageLightbox(options).startImageLightbox();
        return console.warn("Event propagation was stopped when clicking on this.");
      } catch (error2) {
        e = error2;
        return console.error("Unable to lightbox this image!");
      }
    }).each(function() {
      var error2, imgUrl, tagHtml;
      console.log("Using selectors '" + selector + "' / '" + this + "' for lightboximages");
      try {
        if ($(this).prop("tagName").toLowerCase() === "img" && $(this).parent().prop("tagName").toLowerCase() !== "a") {
          tagHtml = $(this).removeClass("lightboximage").prop("outerHTML");
          imgUrl = (function() {
            switch (false) {
              case !!isNull($(this).attr("data-layzr-retina")):
                return $(this).attr("data-layzr-retina");
              case !!isNull($(this).attr("data-layzr")):
                return $(this).attr("data-layzr");
              case !!isNull($(this).attr("data-lightbox-image")):
                return $(this).attr("data-lightbox-image");
              default:
                return $(this).attr("src");
            }
          }).call(this);
          $(this).replaceWith("<a href='" + imgUrl + "' class='lightboximage'>" + tagHtml + "</a>");
          return $("a[href='" + imgUrl + "']").imageLightbox(options);
        }
      } catch (error2) {
        e = error2;
        return console.log("Couldn't parse through the elements");
      }
    });
    return console.info("Lightboxed the following:", jqo);
  });
};

activityIndicatorOn = function() {
  return $('<div id="imagelightbox-loading"><div></div></div>').appendTo('body');
};

activityIndicatorOff = function() {
  $('#imagelightbox-loading').remove();
  return $("#imagelightbox-overlay").click(function() {
    return $("#imagelightbox").click();
  });
};

overlayOn = function() {
  return $('<div id="imagelightbox-overlay"></div>').appendTo('body');
};

overlayOff = function() {
  return $('#imagelightbox-overlay').remove();
};

formatScientificNames = function(selector) {
  if (selector == null) {
    selector = ".sciname";
  }
  return $(".sciname").each(function() {
    var genus, nameStyle, species;
    nameStyle = $(this).css("font-style") === "italic" ? "normal" : "italic";
    $(this).css("font-style", nameStyle);
    genus = $(this).find(".genus").text();
    species = $(this).find(".species").text();
    if (!isNull(genus) && !isNull(species)) {
      return $(this).unbind().addClass("sciname-click").click(function() {
        var target;
        target = uri.urlString + "dashboard.php?taxon=" + genus + "+" + species;
        goTo(target);
        return false;
      });
    }
  });
};

prepURI = function(string) {
  string = encodeURIComponent(string);
  return string.replace(/%20/g, "+");
};

window.locationData = new Object();

locationData.params = {
  enableHighAccuracy: true
};

locationData.last = void 0;

getLocation = function(callback) {
  var geoFail, geoSuccess, retryTimeout;
  if (callback == null) {
    callback = void 0;
  }
  retryTimeout = 1500;
  geoSuccess = function(pos) {
    var elapsed, last;
    clearTimeout(window.geoTimeout);
    window.locationData.lat = pos.coords.latitude;
    window.locationData.lng = pos.coords.longitude;
    window.locationData.acc = pos.coords.accuracy;
    last = window.locationData.last;
    window.locationData.last = Date.now();
    elapsed = window.locationData.last - last;
    if (elapsed < retryTimeout) {
      return false;
    }
    console.info("Successfully set location");
    if (typeof callback === "function") {
      callback(window.locationData);
    }
    return false;
  };
  geoFail = function(error) {
    var locationError;
    clearTimeout(window.geoTimeout);
    locationError = (function() {
      switch (error.code) {
        case 0:
          return "There was an error while retrieving your location: " + error.message;
        case 1:
          return "The user prevented this page from retrieving a location";
        case 2:
          return "The browser was unable to determine your location: " + error.message;
        case 3:
          return "The browser timed out retrieving your location.";
      }
    })();
    console.error(locationError);
    if (typeof callback === "function") {
      callback(false);
    }
    return false;
  };
  if (navigator.geolocation) {
    console.log("Querying location");
    navigator.geolocation.getCurrentPosition(geoSuccess, geoFail, window.locationData.params);
    return window.geoTimeout = delay(1500, function() {
      return getLocation(callback);
    });
  } else {
    console.warn("This browser doesn't support geolocation!");
    if (callback != null) {
      return callback(false);
    }
  }
};

getMaxZ = function() {
  var mapFunction;
  mapFunction = function() {
    return $.map($("body *"), function(e, n) {
      if ($(e).css("position") !== "static") {
        return parseInt($(e).css("z-index") || 1);
      }
    });
  };
  return Math.max.apply(null, mapFunction());
};

foo = function() {
  toastStatusMessage("Sorry, this feature is not yet finished");
  stopLoad();
  return false;
};

safariDialogHelper = function(selector, counter, callback) {
  var delayTimer, error2, newCount;
  if (selector == null) {
    selector = "#download-chooser";
  }
  if (counter == null) {
    counter = 0;
  }

  /*
   * Help Safari display paper-dialogs
   */
  if (typeof callback !== "function") {
    callback = function() {
      return bindDismissalRemoval();
    };
  }
  if (counter < 10) {
    try {
      d$(selector).get(0).open();
      delay(125, function() {
        return d$(selector).get(0).refit();
      });
      if (typeof callback === "function") {
        callback();
      }
      return stopLoad();
    } catch (error2) {
      e = error2;
      newCount = counter + 1;
      delayTimer = 250;
      return delay(delayTimer, function() {
        console.warn("Trying again to display dialog after " + (newCount * delayTimer) + "ms");
        return safariDialogHelper(selector, newCount, callback);
      });
    }
  } else {
    return stopLoadError("Unable to show dialog. Please try again.");
  }
};

bindDismissalRemoval = function() {
  return $("[dialog-dismiss]").unbind().click(function() {
    return $(this).parents("paper-dialog").remove();
  });
};

p$ = function(selector) {
  var error2;
  try {
    return $$(selector)[0];
  } catch (error2) {
    return $(selector).get(0);
  }
};

bsAlert = function(message, type, fallbackContainer, selector) {
  var html, topContainer;
  if (type == null) {
    type = "warning";
  }
  if (fallbackContainer == null) {
    fallbackContainer = "body";
  }
  if (selector == null) {
    selector = "#bs-alert";
  }

  /*
   * Pop up a status message
   * Uses the Bootstrap alert dialog
   *
   * See
   * http://getbootstrap.com/components/#alerts
   * for available types
   */
  if (!$(selector).exists()) {
    html = "<div class=\"alert alert-" + type + " alert-dismissable hanging-alert\" role=\"alert\" id=\"" + (selector.slice(1)) + "\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n    <div class=\"alert-message\"></div>\n</div>";
    topContainer = $("main").exists() ? "main" : $("article").exists() ? "article" : fallbackContainer;
    $(topContainer).prepend(html);
  } else {
    $(selector).removeClass("alert-warning alert-info alert-danger alert-success");
    $(selector).addClass("alert-" + type);
  }
  $(selector + " .alert-message").html(message);
  bindClicks();
  mapNewWindows();
  return false;
};

animateHoverShadows = function(selector, defaultElevation, raisedElevation) {
  var handlerIn, handlerOut;
  if (selector == null) {
    selector = "paper-card.card-tile";
  }
  if (defaultElevation == null) {
    defaultElevation = 2;
  }
  if (raisedElevation == null) {
    raisedElevation = 4;
  }
  handlerIn = function() {
    return $(this).attr("elevation", raisedElevation);
  };
  handlerOut = function() {
    return $(this).attr("elevation", defaultElevation);
  };
  $(selector).hover(handlerIn, handlerOut);
  return false;
};

allError = function(message) {
  stopLoadError(message);
  bsAlert(message, "danger");
  console.error(message);
  return false;
};

checkFileVersion = function(forceNow, file, callback) {
  var checkVersion, error2, error3, key, keyExists;
  if (forceNow == null) {
    forceNow = false;
  }
  if (file == null) {
    file = "js/c.min.js";
  }

  /*
   * Check to see if the file on the server is up-to-date with what the
   * user sees.
   *
   * @param bool forceNow force a check now
   */
  if ((typeof _adp !== "undefined" && _adp !== null ? _adp.lastModChecked : void 0) == null) {
    if (window._adp == null) {
      window._adp = new Object();
    }
    window._adp.lastModChecked = new Object();
  }
  key = file.split("/").pop().split(".")[0];
  checkVersion = function(filePath, modKey) {
    if (filePath == null) {
      filePath = file;
    }
    if (modKey == null) {
      modKey = key;
    }
    return $.get(uri.urlString + "meta.php", "do=get_last_mod&file=" + filePath, "json").done(function(result) {
      var html;
      window._adp.lastModChecked[modKey] = Date.now();
      if (forceNow) {
        doNothing();
      }
      if (!isNumber(result.last_mod)) {
        return false;
      }
      if (_adp.lastMod == null) {
        window._adp.lastMod = new Object();
      }
      if (_adp.lastMod[modKey] == null) {
        window._adp.lastMod[modKey] = result.last_mod;
      }
      if (result.last_mod > _adp.lastMod[modKey]) {
        html = "<div id=\"outdated-warning\" class=\"alert alert-warning alert-dismissible fade in\" role=\"alert\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>We have page updates!</strong> This page has been updated since you last refreshed. <a class=\"alert-link\" id=\"refresh-page\" style=\"cursor:pointer\">Click here to refresh now</a> and get bugfixes and updates.\n</div>";
        if (!$("#outdated-warning").exists()) {
          $("body").append(html);
          $("#refresh-page").click(function() {
            return document.location.reload(true);
          });
        }
        return console.warn("Your current version of this page is out of date! Please refresh the page.");
      } else if (forceNow) {
        return doNothing();
      }
    }).fail(function() {
      return console.warn("Couldn't check file version!!");
    }).always(function() {
      delay(5 * 60 * 1000, function() {
        return checkVersion(filePath, modKey);
      });
      if (typeof callback === "function") {
        return callback();
      }
    });
  };
  try {
    keyExists = window._adp.lastMod[key];
  } catch (error2) {
    keyExists = false;
  }
  if (forceNow || (window._adp.lastMod == null) || !keyExists) {
    try {
      if (!((Date.now() - toInt(window._adp.lastModChecked[key])) < (15 * 1000))) {
        checkVersion(file, key);
      }
    } catch (error3) {
      checkVersion(file, key);
    }
    return true;
  }
  return false;
};

window.checkFileVersion = checkFileVersion;

fixTruncatedJson = function(str) {
  var chunk, error2, json, m, q, stack;
  json = str;
  chunk = json;
  q = false;
  m = false;
  stack = [];
  while (m = chunk.match(/[^\{\[\]\}"]*([\{\[\]\}"])/)) {
    switch (m[1]) {
      case "{":
        stack.push("}");
        break;
      case "[":
        stack.push("]");
        break;
      case "}":
      case "]":
        stack.pop();
        break;
      case '"':
        if (!q) {
          q = true;
          stack.push('"');
        } else {
          q = false;
          stack.pop();
        }
    }
    chunk = chunk.substring(m[0].length);
  }
  if (chunk[chunk.length - 1] === ":") {
    json += '""';
  }
  while (stack.length) {
    json += stack.pop();
  }
  try {
    return JSON.parse(json);
  } catch (error2) {
    return false;
  }
};

checkLoggedIn = function(callback) {

  /*
   * Checks the login credentials against the server.
   * This should not be used in place of sending authentication
   * information alongside a restricted action, as a malicious party
   * could force the local JS check to succeed.
   * SECURE AUTHENTICATION MUST BE WHOLLY SERVER SIDE.
   */
  var args, hash, link, loginTarget, secret;
  hash = $.cookie(uri.domain + "_auth");
  secret = $.cookie(uri.domain + "_secret");
  link = $.cookie(uri.domain + "_link");
  args = "hash=" + hash + "&secret=" + secret + "&dblink=" + link;
  loginTarget = uri.urlString + "admin/async_login_handler.php";
  $.post(loginTarget, args, "json").done(function(result) {
    console.info("Got", result);
    return callback(result);
  }).fail(function(result, status) {
    var response;
    response = {
      status: false
    };
    return callback(response);
  });
  return false;
};

doNothing = function() {
  return null;
};

downloadCSVFile = function(data, options, callback) {

  /*
   * Options:
   *
  options = new Object()
  options.create ?= false
  options.downloadFile ?= "datalist.csv"
  options.classes ?= "btn btn-default"
  options.buttonText ?= "Download File"
  options.iconHtml ?= """<iron-icon icon="icons:cloud-download"></iron-icon>"""
  options.selector ?= "#download-file"
  options.splitValues ?= false
   */
  var error2, postMessageContent, worker;
  try {
    postMessageContent = {
      action: "csv",
      data: data,
      options: options
    };
    worker = new Worker("js/global-search-worker.min.js");
    console.info("Generating an off-thread worker for CSV population");
    worker.addEventListener("message", function(e) {
      var error2, file, html, postCallback;
      html = e.data.html;
      file = e.data.file;
      options = e.data.options;
      console.info("CSV Web worker returned", e.data);
      postCallback = function() {
        var selector;
        selector = options.selector;
        if (options.create === true && !$(selector).exists()) {
          $(selector).append(html);
        } else {
          $(selector).attr("download", options.downloadFile).attr("href", file).removeClass("disabled").removeAttr("disabled");
        }
        return false;
      };
      if (typeof callback === "function") {
        try {
          return callback(function() {
            return postCallback();
          });
        } catch (error2) {
          return postCallback();
        }
      } else {
        return postCallback();
      }
    });
    worker.postMessage(postMessageContent);
  } catch (error2) {
    e = error2;

    /*
     * Classic way! Do it on thread
     */
    console.warn("Web workers aren't supported or otherwise failed");
    console.warn(e.message);
    console.warn("Doing work on-thread");
    downloadCSVFileOnThread(data, options);
  }
  return false;
};

downloadCSVFileOnThread = function(data, options) {

  /*
   * On-Thread fallback for Web Worker
   *
   * Check downloadCSVFile for canonical version
   */
  var c, col, file, header, headerPlaceholder, headerStr, html, id, jsonObject, k, len, parser, selector, t, textAsset;
  textAsset = "";
  if (isJson(data)) {
    console.info("Parsing as JSON string");
    jsonObject = JSON.parse(data);
  } else if (isArray(data)) {
    console.info("Parsing as array");
    jsonObject = toObject(data);
  } else if (typeof data === "object") {
    console.info("Parsing as object");
    jsonObject = data;
  } else {
    console.error("Unexpected data type '" + (typeof data) + "' for downloadCSVFile()", data);
    return false;
  }
  if (options == null) {
    options = new Object();
  }
  if (options.create == null) {
    options.create = false;
  }
  if (options.downloadFile == null) {
    options.downloadFile = "datalist.csv";
  }
  if (options.classes == null) {
    options.classes = "btn btn-default";
  }
  if (options.buttonText == null) {
    options.buttonText = "Download File";
  }
  if (options.iconHtml == null) {
    options.iconHtml = "<iron-icon icon=\"icons:cloud-download\"></iron-icon>";
  }
  if (options.selector == null) {
    options.selector = "#download-file";
  }
  if (options.splitValues == null) {
    options.splitValues = false;
  }
  if (options.cascadeObjects == null) {
    options.cascadeObjects = false;
  }
  if (options.objectAsValues == null) {
    options.objectAsValues = true;
  }
  headerPlaceholder = new Array();
  (parser = function(jsonObj, cascadeObjects) {
    var col, dataVal, error2, escapedKey, handleValue, key, len, results, row, t, tmpRow, tmpRowString, value;
    row = 0;
    if (options.objectAsValues) {
      options.splitValues = "::@@::";
    }
    results = [];
    for (key in jsonObj) {
      value = jsonObj[key];
      if (typeof value === "function") {
        continue;
      }
      ++row;
      try {
        escapedKey = key.toString().replace(/"/g, '""');
        if (row === 1) {
          if (!options.objectAsValues) {
            console.log("Boring options", options.objectAsValues, options);
            headerPlaceholder.push(escapedKey);
          } else {
            console.info("objectAsValues set");
            for (col in value) {
              data = value[col];
              if (isArray(options.acceptableCols)) {
                if (indexOf.call(options.acceptableCols, col) >= 0) {
                  headerPlaceholder.push(col);
                }
              } else {
                headerPlaceholder.push(col);
              }
            }
            console.log("Using as header", headerPlaceholder);
          }
        }
        if (typeof value === "object" && cascadeObjects) {
          value = parser(value, true);
        }
        handleValue = function(providedValue, providedOptions) {
          var escapedValue, tempValue, tempValueArr, tmpTextAsset;
          if (providedValue == null) {
            providedValue = value;
          }
          if (providedOptions == null) {
            providedOptions = options;
          }
          if (isNull(value)) {
            escapedValue = "";
          } else {
            if (typeof providedValue === "object") {
              providedValue = JSON.stringify(providedValue);
            }
            providedValue = providedValue.toString();
            tempValue = providedValue.replace(/"/g, '""');
            tempValue = tempValue.replace(/,/g, '\,');
            tempValue = tempValue.replace(/<\/p><p>/g, '","');
            if (typeof providedOptions.splitValues === "string") {
              tempValueArr = tempValue.split(providedOptions.splitValues);
              tempValue = tempValueArr.join("\",\"");
              escapedKey = false;
            }
            escapedValue = tempValue;
          }
          if (escapedKey === false) {
            tmpTextAsset = "\"" + escapedValue + "\"\n";
          } else if (isNumber(escapedKey)) {
            tmpTextAsset = "\"" + escapedValue + "\",";
          } else if (!isNull(escapedKey)) {
            tmpTextAsset = "\"" + escapedKey + "\",\"" + escapedValue + "\"\n";
          }
          return tmpTextAsset;
        };
        if (!options.objectAsValues) {
          results.push(textAsset += handleValue(value));
        } else {
          tmpRow = new Array();
          for (t = 0, len = headerPlaceholder.length; t < len; t++) {
            col = headerPlaceholder[t];
            dataVal = value[col];
            if (typeof dataVal === "object") {
              try {
                dataVal = JSON.stringify(dataVal);
                dataVal = dataVal.replace(/"/g, '""');
              } catch (undefined) {}
            }
            tmpRow.push(dataVal);
          }
          tmpRowString = tmpRow.join(options.splitValues);
          results.push(textAsset += handleValue(tmpRowString, options));
        }
      } catch (error2) {
        e = error2;
        console.warn("Unable to run key " + key + " on row " + row, value, jsonObj);
        results.push(console.warn(e.stack));
      }
    }
    return results;
  })(jsonObject, options.cascadeObjects);
  textAsset = textAsset.trim();
  k = 0;
  for (t = 0, len = headerPlaceholder.length; t < len; t++) {
    col = headerPlaceholder[t];
    col = col.replace(/"/g, '""');
    headerPlaceholder[k] = col;
    ++k;
  }
  if (options.objectAsValues) {
    options.header = headerPlaceholder;
  }
  if (isArray(options.header)) {
    headerStr = options.header.join("\",\"");
    textAsset = "\"" + headerStr + "\"\n" + textAsset;
    textAsset = textAsset.trim();
    header = "present";
  } else {
    header = "absent";
  }
  if (textAsset.slice(-1) === ",") {
    textAsset = textAsset.slice(0, -1);
  }
  file = ("data:text/csv;charset=utf-8;header=" + header + ",") + encodeURIComponent(textAsset);
  selector = options.selector;
  if (options.create === true) {
    c = $(selector).find("button").length;
    id = (selector.slice(1)) + "-download-button-" + c;
    html = "<a id=\"" + id + "\" class=\"" + options.classes + "\" href=\"" + file + "\" download=\"" + options.downloadFile + "\">\n  " + options.iconHtml + "\n  " + options.buttonText + "\n</a>";
    $(selector).append(html);
  } else {
    $(selector).attr("download", options.downloadFile).attr("href", file);
  }
  return file;
};

linkUsers = function(selector) {
  var profilePageArg, profilePageUri;
  if (selector == null) {
    selector = ".is-user";
  }

  /*
   * Links users to user profiles
   *
   * See #107 for description
   * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/107
   */
  profilePageUri = "https://amphibiandisease.org/profile.php";
  profilePageArg = "?id=";
  $(selector).addClass("linked-user-profile").attr("title", "Visit Profile").attr("data-toggle", "tooltip").click(function() {
    var args, cols, dest, search, searchRaw, setEmail, setUid;
    setUid = $(this).attr("data-uid");
    setEmail = $(this).attr("data-email");
    if (!isNull(setUid)) {
      dest = "" + profilePageUri + profilePageArg + setUid;
      document.location.href = dest;
      return false;
    }
    if (isNull(setEmail)) {
      searchRaw = $(this).text();
      if (isNull(searchRaw)) {
        searchRaw = $(this).attr("data-name");
        if (isNull(searchRaw)) {
          console.error("Unable to find a search criterion!");
          return false;
        }
      }
      cols = "name";
    } else {
      searchRaw = setEmail;
      cols = "username,alternate_email";
    }
    startLoad();
    search = encodeURIComponent(searchRaw);
    args = "action=search_users&q=" + search + "&cols=" + cols;
    $.post(uri.urlString + "api.php", args, "json").done(function(result) {
      var defaultProfile, profiles, uid;
      console.info("Found", result);
      if (result.status !== true) {
        console.error("Error searching for profile");
        stopLoadError("There was an error looking up the user. Please try again later.");
        return false;
      }
      profiles = Object.toArray(result.result);
      if (profiles.length < 1) {
        stopLoadError("Couldn't find user '" + searchRaw + "'");
        return false;
      }
      stopLoad();
      defaultProfile = profiles[0];
      uid = defaultProfile.uid;
      dest = "" + profilePageUri + profilePageArg + uid;
      document.location.href = dest;
      return false;
    }).fail(function(result, status) {
      console.error(result, status);
      stopLoadError("Error communicating with server. Please try again later.");
      return false;
    });
    return false;
  });
  return false;
};

fetchCitation = function(citationQuery, callback) {

  /*
   * Fetch and format a citation. Uses CrossRef API:
   * https://github.com/CrossRef/rest-api-doc/blob/master/rest_api.md
   *
   * Output format should be Proceedings B style:
   * https://www.zotero.org/styles/proceedings-of-the-royal-society-b?source=1
   * http://rspb.royalsocietypublishing.org/faq#question1
   *
   * Example:
   *
   * Oneal E, Knowles LL. 2012 Ecological selection as the cause and sexual differentiation as the consequence of species divergence? Proc R Soc B 280: 20122236; doi: 10.1098/rspb.2012.2236
   *
   * @param string citationQuery -> pre-formatted string for the
   *   CrossRef API.
   * @param function callback -> callback for the citation. Callback
   *   provided with  the citation as arg1, then the PDF URL as arg2.
   */
  var eQ, postUrl, totalUrl;
  postUrl = "https://api.crossref.org/works/";
  eQ = encodeURIComponent(citationQuery);
  totalUrl = "" + postUrl + citationQuery;
  $.get(totalUrl, "", "json").done(function(result) {
    var author, authorJoin, authorString, authors, citation, continuous, doi, doiContinuous, doiNumbers, error2, error3, error4, error5, givenPart, i, initials, initialsArray, issue, j, len, len1, n, published, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, t, u, url, volBlob;
    console.info("Citation base", result);
    j = result.message;
    authors = new Array();
    i = 0;
    authorJoin = ", ";
    ref = j.author;
    for (t = 0, len = ref.length; t < len; t++) {
      author = ref[t];
      initialsArray = author.given.split(" ");
      initials = "";
      for (u = 0, len1 = initialsArray.length; u < len1; u++) {
        givenPart = initialsArray[u];
        n = givenPart.slice(0, 1);
        initials += n;
      }
      authorString = author.family + " " + initials;
      authors.push(authorString);
      ++i;
      if (i > 2) {
        ++i;
        authors.push("et al");
        break;
      }
    }
    if (i === 2) {
      authorJoin = " and ";
    }
    published = (ref1 = (ref2 = (ref3 = j["published-print"]) != null ? (ref4 = ref3["date-parts"]) != null ? (ref5 = ref4[0]) != null ? ref5[0] : void 0 : void 0 : void 0) != null ? ref2 : (ref6 = j["published-online"]) != null ? (ref7 = ref6["date-parts"]) != null ? (ref8 = ref7[0]) != null ? ref8[0] : void 0 : void 0 : void 0) != null ? ref1 : "In press";
    issue = !isNull(j.issue) ? "(" + j.issue + ")" : "";
    if (isNull(j.volume)) {
      j.volume = "";
    }
    if (isNull(j.volume) && isNull(issue)) {
      volBlob = "";
    } else {
      volBlob = "" + j.volume + issue + ":";
    }
    try {
      try {
        doi = j.DOI;
        doiNumbers = doi.replace(/[^0-9]/mg, "");
        doiContinuous = doiNumbers.slice(-8);
        continuous = " " + doiContinuous + "; doi: " + doi;
      } catch (error2) {
        continuous = j.page + ".";
      }
      citation = (authors.join(authorJoin)) + ". " + published + " " + j.title[0] + ". " + j["container-title"][0] + " " + volBlob + continuous;
    } catch (error3) {
      e = error3;
      console.warn("Couldn't generate full citation");
      console.warn(j);
      citation = (authors.join(", ")) + ". " + j.title[0] + ". " + j["container-title"][0] + ". In press.";
    }
    console.log(citation);
    if (typeof callback === "function") {
      try {
        url = !isNull(j.URL) ? j.URL : j.link[0].URL;
        if (url.search("http:") !== -1) {
          url = url.replace(/^(http):\/\/(([a-z0-9]+\.?)+)(.*)$/g, "https://$2$4");
        }
      } catch (error4) {
        url = "https://dx.doi.og/" + citationQuery;
      }
      try {
        callback(citation, url);
      } catch (error5) {
        e = error5;
        console.error("Callback failed, couldn't display citation - " + e.message);
        console.warn(e.stack);
        stopLoadError("Failed to display citation");
      }
    }
    return false;
  }).fail(function(result, status) {
    console.error("Failed to fetch citation");
    return stopLoadError("Failed to fetch citation");
  });
  return false;
};

cancelAsyncOperation = function(caller, asyncOperation) {
  var error2, error3;
  if (asyncOperation == null) {
    asyncOperation = _adp.currentAsyncJqxhr;
  }

  /*
   * Abort the current operation
   *
   * https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/abort
   */
  try {
    if (caller != null) {
      $(caller).remove();
    }
  } catch (undefined) {}
  try {
    if (asyncOperation.readyState === XMLHttpRequest.DONE) {
      console.warn("Couldn't cancel operation -- it's already completed");
      return false;
    }
    asyncOperation.abort();
    try {
      stopLoadBarsError(null, "Operation Cancelled");
    } catch (error2) {
      stopLoadError("Operation Cancelled");
    }
  } catch (error3) {
    console.error("Couldn't abort current async operation");
  }
  return false;
};

generateCSVFromResults = function(resultArray, caller, selector) {
  var error2, options, startTime;
  if (selector == null) {
    selector = "#modal-sql-details-list";
  }

  /*
   * Main CSV record generator. Generally the one called, and may
   * instance the web worker copy.
   */
  startTime = Date.now();
  console.info("Source CSV data:", resultArray);
  options = {
    objectAsValues: true,
    downloadFile: "adp-global-search-result-data_" + (Date.now()) + ".csv"
  };
  try {
    downloadCSVFile(resultArray, options, function(postCallback) {
      var elapsed, error2, html;
      $("#download-file").remove();
      html = "<a tabindex=\"-1\" id=\"download-file\" class=\"paper-button-link\">\n  <paper-button disabled>\n    <iron-icon icon=\"icons:cloud-download\"></iron-icon>\n    Download File\n  </paper-button>\n</a>";
      $(caller).replaceWith(html);
      $(selector + " #download-file paper-button").removeAttr("disabled");
      if (typeof postCallback === "function") {
        try {
          postCallback();
        } catch (error2) {
          e = error2;
          console.warn("Couldn't run postCallbacak after downloadCSV file -- " + e.message);
        }
      }
      elapsed = Date.now() - startTime;
      console.debug("GenerateCSVFromResults completed in " + elapsed + "ms");
      return stopLoad();
    });
  } catch (error2) {
    animateLoad();
    stopLoadError("Sorry, there was a problem with this dataset and we can't generate a downloadable file.");
  }
  return false;
};

validateAWebTaxon = function(taxonObj, callback) {
  var args, doCallback, ref;
  if (callback == null) {
    callback = null;
  }

  /*
   *
   *
   * @param Object taxonObj -> object with keys "genus", "species", and
   *   optionally "subspecies"
   * @param function callback -> Callback function
   */
  if (((ref = window.validationMeta) != null ? ref.validatedTaxons : void 0) == null) {
    if (typeof window.validationMeta !== "object") {
      window.validationMeta = new Object();
    }
    window.validationMeta.validatedTaxons = new Array();
  }
  doCallback = function(validatedTaxon) {
    if (typeof callback === "function") {
      callback(validatedTaxon);
    }
    return false;
  };
  if (window.validationMeta.validatedTaxons.containsObject(taxonObj)) {
    console.info("Already validated taxon, skipping revalidation", taxonObj);
    doCallback(taxonObj);
    return false;
  }
  args = "action=validate&genus=" + taxonObj.genus + "&species=" + taxonObj.species;
  if (taxonObj.subspecies != null) {
    args += "&subspecies=" + taxonObj.subspecies;
  }
  _adp.currentAsyncJqxhr = $.post("api.php", args, "json").done(function(result) {
    if (result.status) {
      taxonObj.genus = result.validated_taxon.genus;
      taxonObj.species = result.validated_taxon.species;
      taxonObj.subspecies = result.validated_taxon.subspecies;
      if (taxonObj.clade == null) {
        taxonObj.clade = result.validated_taxon.family;
      }
      window.validationMeta.validatedTaxons.push(taxonObj);
    } else {
      taxonObj.invalid = true;
    }
    taxonObj.response = result;
    doCallback(taxonObj);
    return false;
  }).fail(function(result, status) {
    var prettyTaxon;
    prettyTaxon = taxonObj.genus + " " + taxonObj.species;
    prettyTaxon = taxonObj.subspecies != null ? prettyTaxon + " " + taxonObj.subspecies : prettyTaxon;
    bsAlert("<strong>Problem validating taxon:</strong> " + prettyTaxon + " couldn't be validated.");
    return console.warn("Warning: Couldn't validated " + prettyTaxon + " with AmphibiaWeb");
  });
  return false;
};


/*
 * Show page citationsin the overflow for non-project pages
 */

makePageCitationOverflow = function() {
  var citationHtml, citationString, d, error2, item, itemId, len, menu, month, param, projectPageRequiredParams, t;
  projectPageRequiredParams = ["project_id", "id", "projectid"];
  for (t = 0, len = projectPageRequiredParams.length; t < len; t++) {
    param = projectPageRequiredParams[t];
    if (!isNull(uri.o.param(param))) {
      console.info("Not creating overflow citation - page is project-specific");
      return false;
    }
  }
  if (uri.o.data.seg.path[0] === "admin-login.php") {
    return false;
  }

  /*
   * Sample:
   *
   * AmphibiaWeb. 2016. Amphibian Disease Portal <http://amphibiandisease.org>. University of California, Berkeley, CA, USA. Accessed 27 Sep 2016.
   */
  d = new Date();
  month = dateMonthToString(d.getMonth());
  citationString = "AmphibiaWeb. " + (d.getUTCFullYear()) + ". " + ($("title").text()) + " &lt;" + uri.o.data.attr.source + "&gt;. University of California, Berkeley, CA, USA. Accessed " + (d.getUTCDate()) + " " + month + " " + (d.getUTCFullYear()) + ".";
  citationHtml = "<paper-dialog id=\"page-citation\" modal>\n  <h2>Citation</h2>\n  <paper-dialog-scrollable>\n    <div>\n      <p style=\"opacity:0\">\n        " + citationString + "\n      </p>\n      <paper-input value=\"" + (citationString.escapeQuotes()) + "\" label=\"Citation\" readonly></paper-input>\n    </div>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
  itemId = "dialog-trigger-item";
  try {
    item = document.createElement("paper-item");
    item.setAttribute("id", itemId);
    item.textContent = "Show Citation";
    menu = p$("header paper-menu");
    Polymer.dom(menu).appendChild(item);
  } catch (error2) {
    item = "<paper-item id=\"" + itemId + "\">\n  Show Citation\n</paper-item>";
    $("header paper-menu-button .paper-menu").append(item);
  }
  $("#page-citation").remove();
  $("body").append(citationHtml);
  delay(250, function() {
    return $("#" + itemId).click(function() {
      console.debug("Clicked trigger item");
      return p$("#page-citation").open();
    });
  });
  return citationString;
};

delayPolymerBind = function(selector, callback, iter) {
  var element, error2, ref, superSlowBackup, uid;
  if (iter == null) {
    iter = 0;
  }
  if (typeof window._dpb !== "object") {
    window._dpb = new Object();
  }
  uid = md5(selector) + md5(callback);
  if (isNull(window._dpb[uid])) {
    window._dpb[uid] = false;
  }
  superSlowBackup = 1000;
  if ((typeof Polymer !== "undefined" && Polymer !== null ? (ref = Polymer.Base) != null ? ref.$$ : void 0 : void 0) != null) {
    if (window._dpb[uid] === false) {
      iter = 0;
      window._dpb[uid] = true;
    }
    try {
      element = Polymer.Base.$$(selector);
      callback(element);
      delay(superSlowBackup, function() {
        console.info("Doing " + superSlowBackup + "ms delay callback for " + selector);
        return callback(element);
      });
    } catch (error2) {
      e = error2;
      console.warn("Error trying to do the delayed polymer bind - " + e.message);
      if (iter < 10) {
        ++iter;
        delay(75, function() {
          return delayPolymerBind(selector, callback, iter);
        });
      } else {
        console.error("Persistent error in polymer binding (" + e.message + ")");
        console.error(e.stack);
        element = $(selector).get(0);
        callback(element);
        delay(superSlowBackup, function() {
          element = document.querySelector(selector);
          console.info("Doing " + superSlowBackup + "ms delay callback for " + selector);
          console.info("Using element", element);
          return callback(element);
        });
      }
    }
  } else {
    if (iter < 50) {
      delay(100, function() {
        ++iter;
        return delayPolymerBind(selector, callback, iter);
      });
    } else {
      console.error("Failed to verify Polymer was set up, attempting manual");
      element = document.querySelector(selector);
      callback(element);
    }
  }
  return false;
};

$(function() {
  var error2;
  bindClicks();
  formatScientificNames();
  lightboxImages();
  animateHoverShadows();
  checkFileVersion();
  linkUsers();
  try {
    $(".do-mailto").click(function() {
      var email;
      email = $(this).attr("data-email");
      document.location.href = "mailto:" + email;
      return false;
    });
  } catch (undefined) {}
  try {
    $("body").tooltip({
      selector: "[data-toggle='tooltip']"
    });
  } catch (error2) {
    e = error2;
    console.warn("Tooltips were attempted to be set up, but do not exist");
  }
  try {
    checkAdmin();
    if ((typeof adminParams !== "undefined" && adminParams !== null ? adminParams.loadAdminUi : void 0) === true) {
      loadJS("js/admin.js", function() {
        console.info("Loaded admin file");
        if (typeof window.loadAdminUi !== "function") {
          if (window.loadAdminUi == null) {
            window.loadAdminUi = function() {
              var html;
              html = "<div class='bs-callout bs-callout-danger'>\n  <h4>Error loading administration</h4>\n  <p>\n    We failed to load the administrative interface. Try refreshing the page.\n  </p>\n  <p>\n    If you continue to see this error, please check your network connection.\n  </p>\n</div>            ";
              $("main #main-body").html(html);
              return false;
            };
          }
        }
        return loadAdminUi();
      });
    } else {
      console.info("No admin setup requested");
    }
    $("header .header-bar-user-name").click(function() {
      return goTo(uri.urlString + "profile.php");
    });
  } catch (undefined) {}
  loadJS(uri.urlString + "js/prism.js");
  try {
    makePageCitationOverflow();
  } catch (undefined) {}
  try {
    return delay(500, function() {
      return setupDebugContext();
    });
  } catch (undefined) {}
});


/*
 * Do Georeferencing from data
 *
 * Plug into CartoDB via
 * http://docs.cartodb.com/cartodb-platform/cartodb-js.html
 */

uri.domain = uri.o.attr("host").split(".").reverse().pop();

cartoAccount = "mvz";

gMapsApiKey = "AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4";

cartoMap = null;

cartoVis = null;

defaultFillColor = "#ff7800";

defaultFillOpacity = 0.35;

adData = new Object();

window.geo = new Object();

geo.GLOBE_WIDTH_GOOGLE = 256;

geo.initLocation = function() {
  try {
    window.locationData.lat = 37.871527;
    window.locationData.lng = -122.262113;
    return getLocation(function() {
      return _adp.currentLocation = new Point(window.locationData.lat, window.locationData.lng);
    });
  } catch (undefined) {}
};

geo.init = function(doCallback) {

  /*
   * Initialization script for the mapping protocols.
   * Urls are taken from
   * http://docs.cartodb.com/cartodb-platform/cartodb-js.html
   */
  var cartoDBCSS;
  try {
    window.locationData.lat = 37.871527;
    window.locationData.lng = -122.262113;
    getLocation(function() {
      return _adp.currentLocation = new Point(window.locationData.lat, window.locationData.lng);
    });
  } catch (undefined) {}
  cartoDBCSS = "<link rel=\"stylesheet\" href=\"https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css\" />";
  $("head").append(cartoDBCSS);
  if (doCallback == null) {
    doCallback = function() {
      getCanonicalDataCoords(geo.dataTable);
      return false;
    };
  }
  window.gMapsCallback = function() {
    return doCallback();
  };
  return speculativeApiLoader();
};

speculativeApiLoader = function() {
  var directLoadApi, mapsApiElement, ref;
  if (!isNull(typeof google !== "undefined" && google !== null ? (ref = google.maps) != null ? ref.Geocoder : void 0 : void 0)) {

    /*
     * Use maps element in attempt to address
     *
     * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/137
     * https://github.com/GoogleWebComponents/google-map/issues/308
     */
    directLoadApi = function() {
      var ref1;
      if (!isNull(typeof google !== "undefined" && google !== null ? (ref1 = google.maps) != null ? ref1.Geocoder : void 0 : void 0)) {
        try {
          console.debug("API element was insufficient. Loading direct API");
        } catch (undefined) {}
        return loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey + "&callback=gMapsCallback");
      }
    };
    if (!$("google-maps-api").exists()) {
      mapsApiElement = "<google-maps-api\n  api-key=\"" + gMapsApiKey + "\" >\n</google-maps-api>";
      $("head").append(mapsApiElement);
      $("google-maps-api").on("api-load", function() {
        try {
          return window.gMapsCallback();
        } catch (undefined) {}
      });
      return delay(300, function() {
        return directLoadApi();
      });
    } else {
      return directLoadApi();
    }
  } else {
    try {
      return window.gMapsCallback();
    } catch (undefined) {}
  }
};

getMapCenter = function(bb) {
  var bbArray, center, centerLat, centerLng, coords, i, len, point, t, totalLat, totalLng;
  if (bb == null) {
    bb = geo.canonicalBoundingBox;
  }
  if (bb != null) {
    i = 0;
    totalLat = 0.0;
    totalLng = 0.0;
    bbArray = Object.toArray(bb);
    for (t = 0, len = bbArray.length; t < len; t++) {
      coords = bbArray[t];
      ++i;
      point = canonicalizePoint(coords);
      totalLat += point.lat;
      totalLng += point.lng;
    }
    centerLat = toFloat(totalLat) / toFloat(i);
    centerLng = toFloat(totalLng) / toFloat(i);
    center = {
      lat: centerLat,
      lng: centerLng
    };
  } else {
    center = {
      lat: window.locationData.lat,
      lng: window.locationData.lng
    };
  }
  center = canonicalizePoint(center);
  return center;
};

getCorners = function(coordSet) {

  /*
   * Get the corners of a coordinate set
   */
  var east, edge, i, len, north, points, polyBoundingBox, south, t, west;
  polyBoundingBox = new Array();
  north = -90;
  south = 90;
  west = 180;
  east = -180;
  i = 0;
  for (t = 0, len = coordSet.length; t < len; t++) {
    points = coordSet[t];
    if (i === 0) {
      console.debug("Sample point:", points);
    }
    ++i;
    if (points.lat > north) {
      north = points.lat;
    }
    if (points.lng > east) {
      east = points.lng;
    }
    if (points.lng < west) {
      west = points.lng;
    }
    if (points.lat < south) {
      south = points.lat;
    }
  }
  edge = {
    lat: north,
    lng: west
  };
  polyBoundingBox.push(edge);
  edge = {
    lat: north,
    lng: east
  };
  polyBoundingBox.push(edge);
  edge = {
    lat: south,
    lng: east
  };
  polyBoundingBox.push(edge);
  edge = {
    lat: south,
    lng: west
  };
  polyBoundingBox.push(edge);
  edge = {
    lat: north,
    lng: west
  };
  polyBoundingBox.push(edge);
  return polyBoundingBox;
};

getPointsFromBoundingBox = function(obj, asObj) {
  var bbSet, boringMultiBounds, boundingPolygon, cartoData, cartoJson, cartoObj, coords, corners, direction, err1, error2, error3, failCase, key, len, len1, len2, len3, polygon, realCoords, ref, ref1, superPoints, t, tempBoundingBox, testCoordBounds, u, w, x;
  if (asObj == null) {
    asObj = false;
  }

  /*
   * @param Object obj -> either an object with bounding box corners,
   *   or a projectData object.
   */
  testCoordBounds = ["n", "e", "w", "s"];
  failCase = false;
  for (t = 0, len = testCoordBounds.length; t < len; t++) {
    direction = testCoordBounds[t];
    key = "bounding_box_" + direction;
    if (isNull(obj[key]) || toInt(obj[key]) === 0) {
      failCase = true;
      break;
    }
  }
  if (!failCase) {
    corners = [[obj.bounding_box_n, obj.bounding_box_w], [obj.bounding_box_n, obj.bounding_box_e], [obj.bounding_box_s, obj.bounding_box_e], [obj.bounding_box_s, obj.bounding_box_w]];
  } else {
    cartoObj = obj.carto_id;
    if (typeof cartoObj !== "object") {
      try {
        cartoData = JSON.parse(deEscape(cartoObj));
      } catch (error2) {
        e = error2;
        err1 = e.message;
        try {
          cartoData = JSON.parse(cartoObj);
        } catch (error3) {
          e = error3;
          if (cartoObj.length > 511) {
            cartoJson = fixTruncatedJson(cartoObj);
            if (typeof cartoJson === "object") {
              console.debug("The carto data object was truncated, but rebuilt.");
              cartoData = cartoJson;
            }
          }
          if (isNull(cartoData)) {
            console.error("Couldn't get bounding points: cartoObj must be JSON string or obj");
            return false;
          }
        }
      }
    } else {
      cartoData = cartoObj;
    }
    boundingPolygon = (ref = cartoData.bounding_polygon) != null ? ref : cartoData['bounding&#95;polygon'];
    if (!isNull(boundingPolygon)) {
      if (!isNull(boundingPolygon.multibounds)) {
        console.debug("Using multibound coordinate assignment");
        boringMultiBounds = new Array();
        ref1 = boundingPolygon.multibounds;
        for (u = 0, len1 = ref1.length; u < len1; u++) {
          polygon = ref1[u];
          tempBoundingBox = getCorners(polygon);
          console.debug("Poly got corners " + (JSON.stringify(tempBoundingBox)), tempBoundingBox);
          boringMultiBounds.push(tempBoundingBox);
        }
        superPoints = new Array();
        for (w = 0, len2 = boringMultiBounds.length; w < len2; w++) {
          bbSet = boringMultiBounds[w];
          superPoints = superPoints.concat(bbSet);
        }
        corners = getCorners(superPoints);
      } else {
        console.error("Project objects with no intrinsic bounding box and no multibounds are not supported yet");
        return false;
      }
    } else {
      console.error("Bad bounding box set, and not a projectData object");
      return false;
    }
  }
  realCoords = new Array();
  for (x = 0, len3 = corners.length; x < len3; x++) {
    coords = corners[x];
    console.log("Pushing corner", coords);
    realCoords.push(canonicalizePoint(coords));
  }
  return realCoords;
};

if (geo.mapSelector == null) {
  geo.mapSelector = "#transect-viewport";
}

getMapZoom = function(bb, selector, zoomIt) {
  var adjAngle, angle, coords, eastMost, error2, k, lat, lng, map, mapHeight, mapScale, mapWidth, northMost, nsAdjAngle, nsAngle, nsMapScale, nsZoomRaw, ref, ref1, refTight, refZoom, southMost, westMost, zoomBasis, zoomCalc, zoomCalcBoundaryScale, zoomComfy, zoomOutThreshold, zoomRaw;
  if (selector == null) {
    selector = geo.mapSelector;
  }
  if (zoomIt == null) {
    zoomIt = true;
  }

  /*
   * Get the zoom factor for Google Maps
   *
   * @param array|object bb -> Collection of Point objects
   * @param selector -> The map to reference
   * @param bool zoomIt -> if selector is a Google Map element, then
   *   apply zoom to it
   */
  zoomOutThreshold = $(window).width() < 1024 ? 1 : 2;
  if (bb != null) {
    eastMost = -180;
    westMost = 180;
    northMost = -90;
    southMost = 90;
    if (isArray(bb)) {
      bb = toObject(bb);
    }
    console.info("Working with dataset", bb);
    if (Object.size(bb) < 3) {
      console.warn("Danger: Very small dataset");
    }
    for (k in bb) {
      coords = bb[k];
      lng = coords.lng != null ? coords.lng : coords[1];
      lat = coords.lat != null ? coords.lat : coords[0];
      if (lng < westMost) {
        westMost = lng;
      }
      if (lng > eastMost) {
        eastMost = lng;
      }
      if (lat < southMost) {
        southMost = lat;
      }
      if (lat > northMost) {
        northMost = lat;
      }
    }
    angle = eastMost - westMost;
    nsAngle = northMost - southMost;
    while (angle < 0) {
      angle += 360;
    }
    while (nsAngle < 0) {
      nsAngle += 360;
    }
    if (!$(selector).exists()) {
      console.warn("Can't find '" + selector + "' - will use 650x480");
    }
    mapWidth = (ref = $(selector).width()) != null ? ref : 650;
    mapHeight = (ref1 = $(selector).height()) != null ? ref1 : 480;
    adjAngle = 360 / angle;
    mapScale = adjAngle / geo.GLOBE_WIDTH_GOOGLE;
    nsAdjAngle = 360 / nsAngle;
    nsMapScale = nsAdjAngle / geo.GLOBE_WIDTH_GOOGLE;
    zoomRaw = Math.log(mapWidth * mapScale) / Math.LN2;
    nsZoomRaw = Math.log(mapHeight * nsMapScale) / Math.LN2;
    console.info("Calculated raw zoom", zoomRaw, nsZoomRaw);
    console.info("Sources", mapWidth, mapScale, Math.LN2);
    if (nsZoomRaw < zoomOutThreshold) {
      nsZoomRaw = 100;
    }
    if (zoomRaw < zoomOutThreshold) {
      zoomRaw = 100;
    }
    zoomBasis = nsZoomRaw < zoomRaw ? nsZoomRaw : zoomRaw;
    if (zoomOutThreshold > zoomBasis || zoomBasis > 20) {
      zoomBasis = 7.5;
    }
    zoomCalc = toInt(zoomBasis);
    console.log("Diff between zoomBasis vs zoomCalc", zoomBasis - zoomCalc);
    refTight = .6;
    refZoom = 16;
    zoomCalcBoundaryScale = refTight / refZoom;
    zoomComfy = zoomCalcBoundaryScale * zoomBasis;
    if (zoomBasis - zoomCalc < zoomComfy) {
      --zoomCalc;
    }
  } else {
    zoomCalc = 7;
  }
  if (zoomIt) {
    if ($(selector).exists()) {
      if ($(selector).get(0).tagName.toLowerCase() === "google-map") {
        console.log("Trying to assign zoom");
        try {
          map = p$(selector);
          if (map.isAttached) {
            console.info("Setting zoom on " + selector + " to " + zoomCalc);
            map.zoom = zoomCalc;
            map.ready = function() {
              return map.zoom = zoomCalc;
            };
          } else {
            console.info("Deferring till ready");
            $(selector).on("google-map-ready", function() {
              return map.zoom = zoomCalc;
            });
          }
        } catch (error2) {
          console.warn("Zoom setting failed!");
        }
      }
    }
  }
  return zoomCalc;
};

geo.getMapZoom = getMapZoom;

defaultMapMouseOverBehaviour = function(e, latlng, pos, data, layerNumber) {
  return console.log(e, latlng, pos, data, layerNumber);
};

createMap2 = function(pointsObj, options, callback) {

  /*
   * Essentially a copy of CreateMap
   * Redo with
   * https://elements.polymer-project.org/elements/google-map#event-google-map-click
   *
   * @param array|object pointsObj -> an array or object of points
   *  (many types supported). For infowindow, the key "data" should be
   *  specified with FIMS data keys, eg, {"lat":37, "lng":-122, "data":{"genus":"Bufo"}}
   * @param object options -> {onClickCallback:function(), classes:[]}
   */
  var a, cat, catalog, center, classes, data, detected, error2, error3, error4, genus, googleMap, hull, i, id, idSuffix, iw, len, len1, len2, len3, mapHtml, mapObjAttr, mapSelector, marker, markerHtml, markerTitle, note, point, pointData, pointList, points, poly, r, ref, ref1, ref2, ref3, selector, species, ssp, t, testString, tested, u, w, x, zoom;
  console.log("createMap2 was provided options:", options);
  if (options == null) {
    options = new Object();
    options = {
      polyParams: {
        fillColor: defaultFillColor,
        fillOpacity: defaultFillOpacity
      },
      classes: "",
      onClickCallback: null,
      skipHull: false,
      skipPoints: false,
      boundingBox: null,
      selector: "#carto-map-container",
      bsGrid: "col-md-9 col-lg-6",
      resetMapBuilder: true,
      onlyOne: true
    };
  }
  if (options.selector != null) {
    selector = options.selector;
  } else {
    selector = "#carto-map-container";
  }
  if (isNull(options.onlyOne)) {
    options.onlyOne = true;
  }
  try {
    if (((options != null ? (ref = options.polyParams) != null ? ref.fillColor : void 0 : void 0) != null) && ((options != null ? (ref1 = options.polyParams) != null ? ref1.fillOpacity : void 0 : void 0) != null)) {
      poly = options.polyParams;
    } else {
      poly = {
        fillColor: defaultFillColor,
        fillOpacity: defaultFillOpacity
      };
    }
    console.info("createMap2 working with data", pointsObj);
    if (!(Object.size(pointsObj) < 3)) {
      data = createConvexHull(pointsObj, true);
      hull = data.hull;
      points = data.points;
    } else {
      try {
        pointList = Object.toArray(pointsObj);
      } catch (error2) {
        pointList = new Array();
      }
      points = new Array();
      options.skipHull = true;
      if (pointList.length === 0) {
        options.skipPoints = true;
      } else {
        for (t = 0, len = pointList.length; t < len; t++) {
          point = pointList[t];
          console.log("Checking", point, "in", pointList);
          points.push(canonicalizePoint(point));
        }
      }
      if (options.boundingBox != null) {
        if (options.boundingBox.nw != null) {
          points.push(canonicalizePoint(options.boundingBox.nw));
          points.push(canonicalizePoint(options.boundingBox.ne));
          points.push(canonicalizePoint(options.boundingBox.sw));
          points.push(canonicalizePoint(options.boundingBox.se));
        } else {
          ref2 = options.boundingBox;
          for (u = 0, len1 = ref2.length; u < len1; u++) {
            point = ref2[u];
            points.push(canonicalizePoint(point));
          }
        }
        hull = createConvexHull(points);
        options.skipHull = false;
      }
    }
    console.info("createMap2 working with", points);
    try {
      zoom = getMapZoom(points, selector);
      console.info("Got zoom", zoom);
    } catch (error3) {
      zoom = "";
    }
    if (options.skipHull !== true) {
      mapHtml = "<google-map-poly closed fill-color=\"" + poly.fillColor + "\" fill-opacity=\"" + poly.fillOpacity + "\" stroke-weight=\"1\">";
      for (w = 0, len2 = hull.length; w < len2; w++) {
        point = hull[w];
        mapHtml += "<google-map-point latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\"> </google-map-point>";
      }
      mapHtml += "    </google-map-poly>";
    } else {
      mapHtml = "";
    }
    if (options.skipPoints !== true) {
      i = 0;
      for (x = 0, len3 = points.length; x < len3; x++) {
        point = points[x];
        markerHtml = "";
        markerTitle = "";
        try {
          if (pointsObj[i].infoWindow != null) {
            iw = pointsObj[i].infoWindow;
            markerTitle = escape((ref3 = iw.title) != null ? ref3 : "");
            markerHtml = iw.html;
            if (pointsObj[i].data != null) {
              pointData = pointsObj[i].data;
              detected = pointData.diseasedetected != null ? pointData.diseasedetected : pointData.diseaseDetected;
              catalog = pointData.catalognumber != null ? pointData.catalognumber : pointData.catalogNumber;
              species = pointData.specificepithet != null ? pointData.specificepithet : pointData.specificEpithet;
              ssp = pointData.infraspecificepithet != null ? pointData.infraspecificepithet : pointData.infraspecificeEpithet;
              if (ssp == null) {
                ssp = "";
              }
              if (isNull(markerTitle)) {
                catalog + ": " + pointData.genus + " " + species + " " + ssp;
              }
            } else {
              detected = "";
            }
          } else if (pointsObj[i].data != null) {
            pointData = pointsObj[i].data;
            genus = pointData.genus;
            species = pointData.specificepithet != null ? pointData.specificepithet : pointData.specificEpithet;
            note = pointData.originaltaxa != null ? pointData.originaltaxa : pointData.originalTaxa;
            detected = pointData.diseasedetected != null ? pointData.diseasedetected : pointData.diseaseDetected;
            tested = pointData.diseasetested != null ? pointData.diseasetested : pointData.diseaseTested;
            if (genus == null) {
              genus = "No Data";
            }
            if (species == null) {
              species = "";
            }
            note = !isNull(note) ? "(" + note + ")" : "";
            testString = (detected != null) && (tested != null) ? "<br/> Tested <strong>" + detected + "</strong> for " + tested : "";
            markerHtml = "<p>\n  <em>" + genus + " " + species + "</em> " + note + "\n  " + testString + "\n</p>";
            if ((pointData.catalogNumber != null) || (pointData.catalognumber != null)) {
              cat = pointData.catalognumber != null ? pointData.catalognumber : pointData.catalogNumber;
              ssp = pointData.infraspecificepithet != null ? pointData.infraspecificepithet : pointData.infraspecificEpithet;
              markerTitle = cat + ": " + genus + " " + species;
            }
          }
        } catch (undefined) {}
        point = canonicalizePoint(point);
        marker = "<google-map-marker latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\" data-disease-detected=\"" + detected + "\" title=\"" + markerTitle + "\" animation=\"DROP\">\n  " + markerHtml + "\n</google-map-marker>";
        mapHtml += marker;
      }
      center = getMapCenter(points);
    } else {
      if (window.locationData == null) {
        try {
          window.locationData.lat = 37.871527;
          window.locationData.lng = -122.262113;
          getLocation(function() {
            return _adp.currentLocation = new Point(window.locationData.lat, window.locationData.lng);
          });
        } catch (undefined) {}
      }
      center = new Point(window.locationData.lat, window.locationData.lng);
      zoom = 14;
    }
    mapObjAttr = geo.googleMap != null ? "map=\"geo.googleMap\"" : "";
    idSuffix = $("google-map").length;
    id = "transect-viewport-" + idSuffix;
    mapSelector = "#" + id;
    if ((options != null ? options.classes : void 0) != null) {
      if (typeof options.classes === "object") {
        a = Object.toArray(options.classes);
        classes = a.join(" ");
      } else {
        classes = options.classes;
      }
      classes = escape(classes);
    } else {
      classes = "";
    }
    googleMap = "<google-map id=\"" + id + "\" latitude=\"" + center.lat + "\" longitude=\"" + center.lng + "\" map-type=\"hybrid\" click-events  zoom=\"" + zoom + "\" class=\"col-xs-12 " + options.bsGrid + " center-block clearfix google-map transect-viewport map-viewport " + classes + "\" api-key=\"" + gMapsApiKey + "\" " + mapObjAttr + ">\n      " + mapHtml + "\n</google-map>";
    if (options.onlyOne === true) {
      selector = $("google-map").get(0);
    }
    if (!$(selector).exists()) {
      try {
        console.debug("Selector does not exist:", selector);
      } catch (undefined) {}
      selector = "#carto-map-container";
      if (!$(selector).exists()) {
        selector = "body";
      }
    }
    if ($(selector).get(0).tagName.toLowerCase() !== "google-map") {
      console.log("Appending map to selector " + selector, $(selector));
      $(selector).addClass("map-container has-map").append(googleMap);
    } else {
      console.log("Replacing map at selector " + selector);
      $(selector).replaceWith(googleMap);
    }
    console.log("Attaching events to " + mapSelector);
    if (window.mapBuilder == null) {
      window.mapBuilder = new Object();
      window.mapBuilder.points = new Array();
      window.mapBuilder.selector = "#" + $(mapSelector).attr("id");
    }
    if ((options != null ? options.resetMapBuilder : void 0) !== false) {
      window.mapBuilder.points = new Array();
    } else {
      window.mapBuilder.selector = "#" + $(mapSelector).attr("id");
    }
    if ((options != null ? options.onClickCallback : void 0) == null) {
      if (options == null) {
        options = new Object();
      }
      options.onClickCallback = function(point, mapElement) {
        if (window.mapBuilder == null) {
          window.mapBuilder = new Object();
          window.mapBuilder.selector = "#" + $(mapElement).attr("id");
          window.mapBuilder.points = new Array();
        }
        window.mapBuilder.points.push(point);
        try {
          $("#using-computed-locality").remove();
        } catch (undefined) {}
        $("#init-map-build").removeAttr("disabled");
        $("#init-map-build .points-count").text(window.mapBuilder.points.length);
        marker = document.createElement("google-map-marker");
        marker.setAttribute("latitude", point.lat);
        marker.setAttribute("longitude", point.lng);
        marker.setAttribute("animation", "DROP");
        Polymer.dom(mapElement).appendChild(marker);
        return false;
      };
    }
    $("" + mapSelector).on("google-map-click", function(e) {
      var ll;
      ll = e.originalEvent.detail.latLng;
      point = canonicalizePoint(ll);
      console.info("Clicked point " + (point.toString()), point, ll);
      if (typeof options.onClickCallback === "function") {
        options.onClickCallback(point, this);
      } else {
        console.warn("google-map-click wasn't provided a callback");
      }
      return false;
    });
    r = {
      selector: mapSelector,
      html: googleMap,
      points: points,
      hull: hull,
      center: center
    };
    console.info("Map", r);
    geo.googleMapWebComponent = googleMap;
    if (typeof callback === "function") {
      console.log("createMap2 calling back");
      callback(r);
    }
    r;
  } catch (error4) {
    e = error4;
    console.error("Couldn't create map! " + e.message);
    console.warn(e.stack);
  }
  return false;
};

reInitMap = function(selector) {
  var len, map, newObjects, o, obj, poly, polyOptions, t;
  map = p$(selector);
  map.map = null;
  o = map.objects;
  map._initGMap();
  newObjects = new Array();
  for (t = 0, len = o.length; t < len; t++) {
    obj = o[t];
    if (obj.tagName.toLowerCase() === "google-map-poly") {
      obj._points = new Array();
      $(obj).find("google-map-point").each(function() {
        var lat, lng, newLL, newPoint;
        lat = $(this).attr("latitude");
        lng = $(this).attr("longitude");
        newPoint = {
          lat: toFloat(lat),
          lng: toFloat(lng)
        };
        newLL = new google.maps.LatLng(newPoint);
        return obj._points.push(newLL);
      });
      obj.path = null;
      obj.map = map.map;
      polyOptions = {
        clickable: obj.clickable || obj.draggable,
        draggable: obj.draggable,
        editable: obj.editable,
        geodesic: obj.geodesic,
        map: obj.map,
        strokeColor: obj.strokeColor,
        strokeOpacity: obj.strokeOpacity,
        strokePosition: obj._convertStrokePosition(),
        strokeWeight: obj.strokeWeight,
        visible: !obj.hidden,
        zIndex: obj.zIndex
      };
      poly = new google.maps.Polygon(polyOptions);
      poly.setPaths(obj._points);
      obj._setPoly(poly);
      newObjects.push(obj);
    }
  }
  return map.objects = newObjects;
};

buildMap = function(mapBuilderObj, options, callback) {
  if (mapBuilderObj == null) {
    mapBuilderObj = window.mapBuilder;
  }
  if (options == null) {
    options = {
      selector: mapBuilderObj.selector,
      resetMapBuilder: false
    };
  }
  createMap2(mapBuilderObj.points, options, callback);
  return false;
};

getPointsFromCartoResult = function(cartoResultRows, sorted) {
  var cartoCoords, coords, error2, len, oldPoints, p, pointObj, pointString, points, row, rows, t;
  if (sorted == null) {
    sorted = false;
  }

  /*
   * From a cartoDB result row, return an array of points
   *
   * @param obj|array cartoResultRows -> The returned carto result rows
   * @param bool sorted -> Should the results be sorted?
   *
   * @return array
   */
  try {
    rows = Object.toArray(cartoResultRows);
    points = new Array();
    for (t = 0, len = rows.length; t < len; t++) {
      row = rows[t];
      pointString = row.st_asgeojson;
      pointObj = JSON.parse(pointString);
      cartoCoords = pointObj.coordinates;
      coords = {
        lat: cartoCoords[1],
        lng: cartoCoords[0]
      };
      p = canonicalizePoint(coords);
      points.push(p);
    }
    if (sorted) {
      oldPoints = points.slice(0);
      points = sortPoints(oldPoints);
    }
    return points;
  } catch (error2) {
    e = error2;
    console.error("Couldn't get points: " + e.message);
    console.warn(e.stack);
  }
  return false;
};

featureClickEvent = function(e, latlng, pos, data, layer, template) {

  /*
   * Generalized click event
   */
  var col, colNames, colNamesManual, options, val;
  console.log("Clicked feature event", data, pos, latlng);
  colNames = new Array();
  for (col in data) {
    val = data[col];
    colNames.push(col);
  }
  colNamesManual = ["genus", "specificepithet", "diseasedetected", "dateidentified"];
  if (template != null) {
    options = {
      infowindowTemplate: template,
      templateType: 'mustache'
    };
  } else {
    options = null;
  }
  return false;
};

createRawCartoMap = function(layers, callback, options, mapSelector, clickEvent) {
  var BASE_MAP, googleMapOptions, lMap, lTopoOptions, leafletOptions, mapOptions, params, ref, ref1, ref2, ref3;
  if (mapSelector == null) {
    mapSelector = "#global-data-map";
  }
  if (clickEvent == null) {
    clickEvent = featureClickEvent;
  }

  /*
   * Create a raw CartoDB map
   *
   * See
   * https://docs.cartodb.com/cartodb-platform/cartodb-js/getting-started/#creating-visualizations-at-runtime
   *
   */
  if (isNull(options)) {
    options = new Object();
  }
  if (layers.user_name == null) {
    params = {
      user_name: (ref = options.user_name) != null ? ref : cartoAccount,
      type: (ref1 = options.type) != null ? ref1 : "cartodb",
      sublayers: layers,
      extra_params: {
        map_key: window.apiKey,
        api_key: window.apiKey
      }
    };
  } else {
    params = layers;
  }
  console.info("Creating map", params);
  mapOptions = {
    cartodb_logo: false,
    https: true,
    mobile_layout: true
  };
  try {
    googleMapOptions = {
      center: new google.maps.LatLng((ref2 = mapOptions.center_lat) != null ? ref2 : 0, (ref3 = mapOptions.center_lon) != null ? ref3 : 0),
      zoom: mapOptions.zoom,
      mapTypeId: google.maps.MapTypeId.TERRAIN
    };
    geo.googleMap = p$(mapSelector).map;
  } catch (undefined) {}
  leafletOptions = {
    center: [window.locationData.lat, window.locationData.lng],
    zoom: 5
  };
  if (geo.lMap == null) {
    lMap = new L.Map("global-map-container", leafletOptions);
    geo.lMap = lMap;
    lTopoOptions = {
      attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
    };
    L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', lTopoOptions).addTo(lMap);
  }
  BASE_MAP = localStorage.useTestMap ? geo.googleMap : geo.lMap;
  cartodb.createLayer(BASE_MAP, params, mapOptions).addTo(BASE_MAP, 1).on("done", function(layer) {
    var dataLayer, error2, i, len, max, setTemplate, shortTable, suTemp, t;
    try {
      layer.setParams("table_name", params.named_map.params.table_name);
    } catch (error2) {
      console.warn("Couldn't explicitly set table");
    }
    if (isArray(layers)) {
      for (t = 0, len = layers.length; t < len; t++) {
        dataLayer = layers[t];
        console.info("Re-adding sublayer", dataLayer);
        layer.createSubLayer(dataLayer);
      }
      console.info("Added layers to map");
    }
    if (geo.mapSublayers == null) {
      geo.mapSublayers = new Array();
    }
    max = layer.getSubLayerCount();
    try {
      layer.setInteraction(true);
    } catch (undefined) {}
    try {
      layer.unbind("featureClick");
    } catch (undefined) {}
    layer.on("featureClick", function(e, latlng, pos, data, layerIndex) {
      var tableName;
      tableName = params.named_map.params.table_name.slice(0, 63);
      clickEvent.debounce(150, false, null, e, latlng, pos, data, layer, $("#infowindow_template_" + tableName).outerHtml());
      return false;
    }).on("error", function(err) {
      return console.warn("Error on layer feature click", err);
    });
    i = 0;
    setTemplate = function(sublayerToSet, tableName, count, carrySublayerIndex, workingLayer) {
      var colNamesManual, error3, infoWindowParser, infoWindowTemplate, ref4, ref5, selector, template;
      if (count == null) {
        count = 0;
      }
      selector = "#infowindow_template_" + tableName;
      template = (ref4 = (ref5 = window._adp.templates) != null ? ref5[tableName] : void 0) != null ? ref4 : $(selector).html();
      if (isNull(template)) {
        template = $(selector).html();
        if (isNull(template) && modulo(count, 100) === 0 && count > 0) {
          console.warn("Warning: null template for table '" + tableName + "' @ sublayer " + carrySublayerIndex, template);
        }
      }
      if (!isNull(template)) {
        infoWindowTemplate = {
          template: template,
          width: 218,
          maxHeight: 250
        };
        sublayerToSet.infowindow.set(infoWindowTemplate);
        console.info("Successfully set template " + selector + " on sublayer " + carrySublayerIndex);
        try {
          colNamesManual = ["genus", "specificepithet", "diseasedetected", "dateidentified"];
          infoWindowParser = function(inputHtml) {
            var outputHtml;
            console.debug("Running infowindow parser on ", inputHtml);
            $("body .temp-parser").remove();
            $("body").append("<div class='temp-parser'>\n  " + inputHtml + "\n</div>");
            $(".temp-parser").find(".unix-date").each(function() {
              var d, dateMs, y;
              dateMs = $(this).text();
              if (isNull(dateMs)) {
                $(this).parent().remove();
              }
              if (isNumber(dateMs)) {
                dateMs = toInt(dateMs);
              }
              d = new Date(dateMs);
              y = d.getUTCFullYear();
              return $(this).replaceWith(y);
            });
            $(".temp-parser").find(".disposition").each(function() {
              var label;
              label = $(this).find(".disposition-label");
              if (isNull(label)) {
                console.debug("Removed empty disposition from label");
                return $(this).remove();
              }
            });
            outputHtml = $(".temp-parser").html();
            $(".temp-parser").remove();
            console.debug("Parser output", outputHtml);
            return outputHtml;
          };
          options = {
            infowindowTemplate: $(selector).html(),
            templateType: 'mustache',
            sanitizeTemplate: infoWindowParser
          };
          try {
            workingLayer.getSubLayer(carrySublayerIndex).infowindow.sanitizeTemplate = infoWindowParser;
            console.debug("Assigned template parser to sublayer");
          } catch (error3) {
            e = error3;
            console.warn("Couldn't assign template parser - " + e.message);
            console.warn(e.stack);
          }
          cartodb.vis.Vis.addInfowindow(geo.lMap, workingLayer.getSubLayer(carrySublayerIndex), colNamesManual, options);
          console.info("Successfully assigned template " + selector + " to sublayer " + carrySublayerIndex + " in vis");
          console.debug("template", template);
          console.debug("selector", $(selector).html());
        } catch (undefined) {}
        if (carrySublayerIndex === 0) {
          try {
            workingLayer.infowindow.set("template", template);
            console.info("Successfully assigned template to primary layer", template);
          } catch (undefined) {}
        }
        if (carrySublayerIndex === workingLayer.getSubLayerCount() - 1) {
          console.info("Showing layer for '" + tableName + "' after successful template assignment for all sublayers");
          workingLayer.show();
        }
      } else {
        if (count < 100) {
          delay(200, function() {
            count = count + 1;
            return setTemplate(sublayerToSet, tableName, count, carrySublayerIndex, workingLayer);
          });
        } else {
          console.warn("Timed out (count: " + count + ") trying to assign a template for '" + tableName + "'", selector, "https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/154");
          workingLayer.show();
        }
      }
      return false;
    };
    while (i < max) {
      suTemp = layer.getSubLayer(i);
      suTemp.setInteraction(true);
      try {
        shortTable = params.named_map.params.table_name.slice(0, 63);
        setTemplate(suTemp, shortTable, 0, i, layer);
      } catch (undefined) {}
      geo.mapSublayers.push(suTemp);
      ++i;
    }
    try {
      console.log("Layer counts:", BASE_MAP.overlayMapTypes.length);
    } catch (undefined) {}
    if (typeof callback === "function") {
      callback();
    }
    return false;
  }).on("error", function(errorString) {
    toastStatusMessage("Couldn't load maps!");
    return console.error("Couldn't get map - " + errorString);
  });
  return false;
};

createMap = function(dataVisIdentifier, targetId, options, callback) {
  var dataVisJson, dataVisUrl, postConfig, sampleUrl;
  if (dataVisIdentifier == null) {
    dataVisIdentifier = "38544c04-5e56-11e5-8515-0e4fddd5de28";
  }
  if (targetId == null) {
    targetId = "carto-map-container";
  }

  /*
   * Creates a map and does some simple bindings.
   *
   * The default data is the one from the documentation, and shouldn't
   * be used in production.
   *
   * See:
   * http://docs.cartodb.com/cartodb-platform/cartodb-js.html#api-methods
   *
   */
  if (dataVisIdentifier == null) {
    console.info("Can't create map without a data visualization identifier");
  }
  geo.mapId = targetId;
  geo.mapSelector = "#" + targetId;
  postConfig = function() {
    var error2, fakeDiv, forceCallback, gMapCallback, googleMapOptions;
    if (options == null) {
      options = {
        cartodb_logo: false,
        https: true,
        mobile_layout: true,
        gmaps_base_type: "hybrid",
        center_lat: window.locationData.lat,
        center_lon: window.locationData.lng,
        zoom: getMapZoom(geo.boundingBox)
      };
    }
    geo.mapParams = options;
    if (!$("#" + targetId).exists()) {
      fakeDiv = "<div id=\"" + targetId + "\" class=\"carto-map wide-map map-container\">\n  <!-- Dynamically inserted from unavailable target -->\n</div>";
      $("main #main-body").append(fakeDiv);
    }
    if (typeof callback !== "function") {
      callback = function(layer, cartoMap) {
        return cartodb.createLayer(cartoMap, dataVisUrl).addTo(cartoMap).done(function(layer) {
          var error2;
          geo.mapLayer = layer;
          try {
            layer.setInteraction(true);
            return layer.on("featureOver", defaultMapMouseOverBehaviour);
          } catch (error2) {
            return console.warn("Can't set carto map interaction");
          }
        });
      };
    }
    googleMapOptions = {
      center: new google.maps.LatLng(options.center_lat, options.center_lon),
      zoom: options.zoom,
      mapTypeId: google.maps.MapTypeId.HYBRID
    };
    geo.googleMap = new google.maps.Map(document.getElementById(targetId), googleMapOptions);
    geo.cartoMap = geo.googleMap;
    gMapCallback = function(layer) {
      console.info("Fetched data into Google Map from CartoDB account " + cartoAccount + ", from data set " + dataVisIdentifier);
      geo.mapLayer = layer;
      geo.cartoMap = geo.googleMap;
      clearTimeout(forceCallback);
      if (typeof callback === "function") {
        callback(layer, geo.cartoMap);
      }
      return false;
    };
    try {
      console.info("About to render map with options", geo.cartoUrl, options);
      cartodb.createLayer(geo.googleMap, geo.cartoUrl, options).addTo(geo.googleMap).on("done", function(layer) {
        return gMapCallback(layer);
      }).on("error", function(errorString) {
        toastStatusMessage("Couldn't load maps!");
        return console.error("Couldn't get map - " + errorString);
      });
      forceCallback = delay(1000, function() {
        if (typeof callback === "function") {
          console.warn("Callback wasn't called, forcing");
          return callback(null, geo.cartoMap);
        }
      });
    } catch (error2) {
      console.warn("The map threw an error! " + e.message);
      console.warn(e.stack);
      clearTimeout(forceCallback);
      if (typeof callback === "function") {
        callback(null, geo.cartoMap);
      }
    }
    return false;
  };

  /*
   * Now that we have the helper function, let's get the viz data
   */
  if (typeof dataVisIdentifier !== "object") {
    if (/^https?:\/\/.*$/m.test(dataVisIdentifier)) {
      dataVisUrl = dataVisIdentifier;
    } else {
      dataVisUrl = "https://" + cartoAccount + ".cartodb.com/api/v2/viz/" + dataVisIdentifier + "/viz.json";
    }
    geo.cartoUrl = dataVisUrl;
    return postConfig();
  } else {
    dataVisJson = new Object();
    sampleUrl = "http://tigerhawkvok.cartodb.com/api/v2/viz/38544c04-5e56-11e5-8515-0e4fddd5de28/viz.json";
    return $.get(sampleUrl, "", "json").done(function(result) {
      var key, results, value;
      dataVisJson = result;
      results = [];
      for (key in dataVisIdentifier) {
        value = dataVisIdentifier[key];
        results.push(dataVisJson[key] = value);
      }
      return results;
    }).fail(function(result, status) {
      return dataVisJson = dataVisIdentifier;
    }).always(function() {
      dataVisUrl = dataVisJson;
      geo.cartoUrl = dataVisUrl;
      return postConfig();
    });
  }
};

getColumnObj = function(forceBase) {
  var columnDatatype;
  if (forceBase == null) {
    forceBase = false;
  }
  columnDatatype = {
    id: "int",
    collectionID: "varchar",
    catalogNumber: "varchar",
    sampleId: "varchar",
    diseaseTested: "varchar",
    diseaseStrain: "varchar",
    sampleMethod: "varchar",
    sampleDisposition: "varchar",
    diseaseDetected: "varchar",
    fatal: "boolean",
    cladeSampled: "varchar",
    genus: "varchar",
    specificEpithet: "varchar",
    infraspecificEpithet: "varchar",
    lifeStage: "varchar",
    dateIdentified: "date",
    decimalLatitude: "decimal",
    decimalLongitude: "decimal",
    alt: "decimal",
    coordinateUncertaintyInMeters: "decimal",
    Collector: "varchar",
    originalTaxa: "varchar",
    sex: "varchar",
    datum: "text",
    fimsExtra: "json",
    the_geom: "varchar"
  };
  if ((_adp.activeCols != null) && !forceBase) {
    return _adp.activeCols;
  }
  return columnDatatype;
};

geo.requestCartoUpload = function(totalData, dataTable, operation, callback) {

  /*
   * Acts as a shim between the server-side uploader and the client.
   * Send a request to the server to authenticate the current user
   * status, then, if successful, do an authenticated upload to the
   * client.
   *
   * Among other things, this approach secures the cartoDB API on the server.
   */
  var allowedOperations, args, data, hash, link, secret;
  startLoad();
  try {
    data = totalData.data;
  } catch (undefined) {}
  if (typeof data !== "object") {
    console.info("This function requires the base data to be a JSON object.");
    toastStatusMessage("Your data is malformed. Please double check your data and try again.");
    return false;
  }
  allowedOperations = ["edit", "insert", "delete", "create"];
  if (indexOf.call(allowedOperations, operation) < 0) {
    console.error(operation + " is not an allowed operation on a data set!");
    console.info("Allowed operations are ", allowedOperations);
    toastStatusMessage("Sorry, '" + operation + "' isn't an allowed operation.");
    return false;
  }
  if (isNull(dataTable)) {
    console.error("Must use a defined table name!");
    toastStatusMessage("You must name your data table");
    return false;
  }
  link = $.cookie(uri.domain + "_link");
  hash = $.cookie(uri.domain + "_auth");
  secret = $.cookie(uri.domain + "_secret");
  if (!((link != null) && (hash != null) && (secret != null))) {
    console.error("You're not logged in. Got one or more invalid tokens for secrets.", link, hash, secret);
    toastStatusMessage("Sorry, you're not logged in. Please log in and try again.");
    return false;
  }
  dataTable = dataTable + "_" + link;
  args = "hash=" + hash + "&secret=" + secret + "&dblink=" + link;
  if ((typeof adminParams !== "undefined" && adminParams !== null ? adminParams.apiTarget : void 0) == null) {
    console.warn("Administration file not loaded. Upload cannot continue");
    stopLoadError("Administration file not loaded. Upload cannot continue");
    return false;
  }
  $.post(adminParams.apiTarget, args, "json").done(function(result) {
    var alt, bb_east, bb_north, bb_south, bb_west, cdbfy, column, columnDatatype, columnDef, columnNamesList, coordinate, coordinatePair, dataGeometry, dataObject, defaultPolygon, err, error2, error3, geoJson, geoJsonGeom, geoJsonVal, i, iIndex, insertMaxLength, insertPlace, lat, lats, len, len1, ll, lng, lngs, longestStatement, lowCol, maxStatementLength, n, ref, ref1, ref2, ref3, ref4, row, sampleLatLngArray, shortestStatement, sqlQuery, statements, t, tempList, transectPolygon, u, userTransectRing, value, valuesArr, valuesList;
    if (result.status) {

      /*
       * Now that we've done an authenticated request, and handled that
       * sort of error, we can actually use CartoDB's SQL API and
       * upload the data.
       *
       * http://docs.cartodb.com/cartodb-platform/sql-api.html
       *
       * The data itself will be preprocessed as a GeoJSON:
       * http://geojson.org/geojson-spec.html
       * http://www.postgis.org/documentation/manual-svn/ST_SetSRID.html
       * http://www.postgis.org/documentation/manual-svn/ST_Point.html
       *
       * Assume Spatial Reference System 4326, http://spatialreference.org/ref/epsg/4326/
       * http://www.postgis.org/documentation/manual-svn/using_postgis_dbmanagement.html#spatial_ref_sys
       */
      sampleLatLngArray = new Array();
      lats = new Array();
      lngs = new Array();
      for (n in data) {
        row = data[n];
        ll = new Array();
        for (column in row) {
          value = row[column];
          switch (column) {
            case "decimalLongitude":
              ll[1] = value;
              lngs.push(value);
              break;
            case "decimalLatitude":
              ll[0] = value;
              lats.push(value);
          }
        }
        sampleLatLngArray.push(ll);
      }
      bb_north = (ref = lats.max()) != null ? ref : 0;
      bb_south = (ref1 = lats.min()) != null ? ref1 : 0;
      bb_east = (ref2 = lngs.max()) != null ? ref2 : 0;
      bb_west = (ref3 = lngs.min()) != null ? ref3 : 0;
      defaultPolygon = [[bb_north, bb_west], [bb_north, bb_east], [bb_south, bb_east], [bb_south, bb_west]];
      try {
        userTransectRing = JSON.parse(totalData.transectRing);
        userTransectRing = Object.toArray(userTransectRing);
        i = 0;
        for (t = 0, len = userTransectRing.length; t < len; t++) {
          coordinatePair = userTransectRing[t];
          if (coordinatePair instanceof Point) {
            coordinatePair = coordinatePair.toGeoJson();
            userTransectRing[i] = coordinatePair;
          }
          if (coordinatePair.length !== 2) {
            throw {
              message: "Bad coordinate length for '" + coordinatePair + "'"
            };
          }
          for (u = 0, len1 = coordinatePair.length; u < len1; u++) {
            coordinate = coordinatePair[u];
            if (!isNumber(coordinate)) {
              throw {
                message: "Bad coordinate number '" + coordinate + "'"
              };
            }
          }
          ++i;
        }
      } catch (error2) {
        e = error2;
        console.warn("Error parsing the user transect ring - " + e.message);
        userTransectRing = void 0;
      }
      transectPolygon = userTransectRing != null ? userTransectRing : defaultPolygon;
      geoJson = {
        type: "GeometryCollection",
        geometries: [
          {
            type: "MultiPoint",
            coordinates: sampleLatLngArray
          }, {
            type: "Polygon",
            coordinates: transectPolygon
          }
        ]
      };
      dataGeometry = "ST_AsBinary(" + (JSON.stringify(geoJson)) + ", 4326)";
      columnDatatype = getColumnObj(true);
      switch (operation) {
        case "edit":
          sqlQuery = "UPDATE " + dataTable + " ";
          foo();
          return false;
        case "insert":
        case "create":
          sqlQuery = "";
          if (operation === "create") {
            sqlQuery = "CREATE TABLE " + dataTable + " ";
          }
          dataObject = {
            the_geom: dataGeometry
          };
          valuesList = new Array();
          columnNamesList = new Array();
          columnNamesList.push("id int");
          _adp.rowsCount = Object.size(data);
          for (i in data) {
            row = data[i];
            i = toInt(i);
            valuesArr = new Array();
            lat = 0;
            lng = 0;
            alt = 0;
            err = 0;
            geoJsonGeom = {
              type: "Point",
              coordinates: new Array()
            };
            iIndex = i + 1;
            valuesArr.push(iIndex);
            for (column in row) {
              value = row[column];
              if (i === 0) {
                lowCol = column.toLowerCase();
                columnDef = (ref4 = columnDatatype[column]) != null ? ref4 : columnDatatype[lowCol];
                if (typeof columnDef === "object") {
                  columnDef = columnDef.type;
                }
                if (isNull(columnDef)) {
                  columnDef = "text";
                }
                columnNamesList.push(column + " " + columnDef);
              }
              try {
                value = value.replace("'", "&#95;");
              } catch (undefined) {}
              switch (column) {
                case "decimalLongitude":
                  geoJsonGeom.coordinates[1] = value;
                  break;
                case "decimalLatitude":
                  geoJsonGeom.coordinates[0] = value;
              }
              if (typeof value === "string") {
                valuesArr.push("'" + value + "'");
              } else if (isNull(value)) {
                valuesArr.push("null");
              } else {
                valuesArr.push(value);
              }
            }
            if (i === 0) {
              console.log("We're appending to col names list");
              columnNamesList.push("the_geom geometry");
              if (operation === "create") {
                sqlQuery = sqlQuery + " (" + (columnNamesList.join(",")) + "); ";
              }
            }
            geoJsonVal = "ST_SetSRID(ST_Point(" + geoJsonGeom.coordinates[1] + "," + geoJsonGeom.coordinates[0] + "),4326)";
            valuesArr.push(geoJsonVal);
            valuesList.push("(" + (valuesArr.join(",")) + ")");
          }
          maxStatementLength = 4096;
          insertMaxLength = 15;
          insertPlace = 0;
          console.info("Inserting statements of max length " + maxStatementLength);
          longestStatement = 0;
          shortestStatement = maxStatementLength;
          tempList = new Array();
          while (valuesList.slice(insertPlace, insertPlace + insertMaxLength).length > 0) {
            statements = 0;
            while (tempList.join(", ").length < maxStatementLength - 1) {
              ++statements;
              tempList = valuesList.slice(insertPlace, insertPlace + statements);
              if (statements > insertMaxLength) {
                break;
              }
            }
            statements--;
            if (statements > longestStatement) {
              longestStatement = statements;
            }
            if (statements < shortestStatement) {
              shortestStatement = statements;
            }
            tempList = valuesList.slice(insertPlace, insertPlace + statements);
            insertPlace += statements;
            sqlQuery += "INSERT INTO " + dataTable + " VALUES " + (tempList.join(", ")) + ";";
          }
          cdbfy = "SELECT cdb_cartodbfytable('" + dataTable + "');";
          sqlQuery += cdbfy;
          console.info("Constructed statements: maximum " + longestStatement + " rows, minimum " + shortestStatement + " rows");
          break;
        case "delete":
          sqlQuery = "DELETE FROM " + dataTable + " WHERE ";
          foo();
          return false;
      }
      try {
        return geo.postToCarto(sqlQuery, dataTable, callback);
      } catch (error3) {
        return stopLoadBarsErrors();
      }
    } else {
      console.error("Unable to authenticate session. Please log in.");
      return stopLoadError("Sorry, your session has expired. Please log in and try again.");
    }
  }).fail(function(result, status) {
    console.error("Couldn't communicate with server!", result, status);
    console.warn("" + uri.urlString + adminParams.apiTarget + "?" + args);
    stopLoadError("There was a problem communicating with the server. Please try again in a bit. (E-001)");
    return $("#upload-data").removeAttr("disabled");
  });
  return false;
};

geo.postToCarto = function(sqlQuery, dataTable, callback) {
  var apiPostSqlQuery, args, doStillWorking, e2, error2, error3, estimate, estimateStartRef, max, postTimeStart, story, updateUploadProgress, workingIter;
  apiPostSqlQuery = encodeURIComponent(encode64(sqlQuery));
  args = "action=upload&sql_query=" + apiPostSqlQuery;
  console.info("Querying:");
  console.info(sqlQuery);
  try {
    _adp.postedSqlQuery = sqlQuery;
    _adp.postedSqlQueryStatements = sqlQuery.split(");");
  } catch (undefined) {}
  console.info("POSTing to server");
  $("#data-sync").removeAttr("indeterminate");
  postTimeStart = Date.now();
  workingIter = 0;
  story = ["A silly story for you, while you wait!", "Everything had gone according to plan, up 'til this moment.", "His design team had done their job flawlessly,", "and the machine, still thrumming behind him,", "a thing of another age,", "was settled on a bed of prehistoric moss.", "They'd done it.", "But now,", "beyond the protection of the pod", "and facing an enormous Tyrannosaurus rex with dripping jaws,", "Professor Cho reflected that,", "had he known of the dinosaur's presence,", "he wouldn’t have left the Chronoculator", "- and he certainly wouldn't have chosen 'Staying&#39; Alive',", "by The Beegees,", "as his dying soundtrack.", "Curse his MP3 player!", "The End.", "Yep, your data is still being processed", "And we're out of fun things to say", "We hope you think it's all worth it"];
  doStillWorking = function() {
    var extra;
    extra = story[workingIter] != null ? "(" + story[workingIter] + ")" : "";
    toastStatusMessage("Still working ... " + extra);
    ++workingIter;
    return window._adp.secondaryTimeout = delay(15000, function() {
      return doStillWorking();
    });
  };
  try {
    estimate = toInt(.7 * _adp.rowsCount);
    console.log("Estimate " + estimate + " seconds");
    window._adp.uploader = true;
    $("#data-sync").removeAttr("indeterminate");
    max = estimate * 30;
    try {
      p$("#data-sync").max = max;
    } catch (undefined) {}
    (updateUploadProgress = function(prog) {
      try {
        p$("#data-sync").value = prog;
      } catch (undefined) {}
      ++prog;
      if (window._adp.uploader && prog <= max) {
        return delay(33, function() {
          return updateUploadProgress(prog);
        });
      } else if (prog > max) {
        toastStatusMessage("This may take a few minutes. We'll give you an error if things go wrong.");
        return window._adp.secondaryTimeout = delay(15000, function() {
          return doStillWorking();
        });
      } else {
        return console.log("Not running upload progress indicator", prog, window._adp.uploader, max);
      }
    })(0);
  } catch (error2) {
    e = error2;
    console.warn("Can't show upload status - " + e.message);
    console.warn(e.stack);
    try {
      window._adp.initialTimeout = delay(5000, function() {
        var estMin, minWord;
        estMin = toInt(estimate / 60) + 1;
        minWord = estMin > 1 ? "minutes" : "minute";
        toastStatusMessage("Please be patient, it may take a few minutes (we guess " + estMin + " " + minWord + ")");
        return window._adp.secondaryTimeout = delay(15000, function() {
          return doStillWorking();
        });
      });
    } catch (error3) {
      e2 = error3;
      console.error("Can't show backup upload notices! " + e2.message);
      console.warn(e2.stack);
    }
  }
  estimateStartRef = Date.now();
  $.post("api.php", args, "json").done(function(result) {
    var cartoHasError, cartoResults, dataBlobUrl, dataVisUrl, error, j, key, parentCallback, prettyHtml, realDuration, response, val;
    console.log("Got back response from carto", result);
    try {
      realDuration = roundNumber((Date.now() - estimateStartRef) / 1000, 1);
      console.info("Really took " + realDuration + "s (estimated " + estimate + "s)", realDuration / estimate);
    } catch (undefined) {}
    if (result.status !== true) {
      console.error("Got an error from the server!");
      console.warn(result);
      stopLoadError("There was a problem uploading your data. Please try again.");
      bsAlert("<strong>There was a problem uploading your data</strong>: the server said <code>" + result.error + "</code>", "danger");
      return false;
    }
    cartoResults = result.post_response;
    cartoHasError = false;
    for (j in cartoResults) {
      response = cartoResults[j];
      if (!isNull(response != null ? response.error : void 0)) {
        error = (response != null ? response.error : void 0) != null ? response.error[0] : "Unspecified Error";
        cartoHasError = error;
      }
      try {
        response = JSON.parse(response);
        for (key in response) {
          val = response[key];
          if (key === "error") {
            cartoHasError = val;
          }
        }
      } catch (undefined) {}
    }
    if (cartoHasError !== false) {
      console.error("There was an error communicating with cartoDB!");
      bsAlert("Error uploading your data to CartoDB: <code>" + cartoHasError + "</code>", "danger");
      stopLoadError("CartoDB returned an error: " + cartoHasError);
      return false;
    }
    console.info("Carto was successful! Got results", cartoResults);
    try {
      prettyHtml = JsonHuman.format(cartoResults);
    } catch (undefined) {}
    bsAlert("Upload to CartoDB of table <code>" + dataTable + "</code> was successful", "success");
    $("#cancel-new-upload").remove();
    toastStatusMessage("Data parse and upload successful");
    geo.dataTable = dataTable;
    dataBlobUrl = "";
    if (!isNull(dataBlobUrl)) {
      dataVisUrl = "https://" + cartoAccount + ".cartodb.com/api/v2/viz/" + dataBlobUrl + "/viz.json";
    } else if (typeof dataBlobUrl === "object") {
      dataVisUrl = dataBlobUrl;
    } else {
      dataVisUrl = "";
    }
    parentCallback = function(coords) {
      var options, ref;
      console.info("Initiating parent callback");
      stopLoad();
      try {
        max = p$("#data-sync").max;
        p$("#data-sync").value = max;
      } catch (undefined) {}
      $("#data-sync").removeAttr("indeterminate");
      options = {
        boundingBox: geo.boundingBox,
        bsGrid: ""
      };
      if (((ref = window.mapBuilder) != null ? ref.selector : void 0) != null) {
        options.selector = window.mapBuilder.selector;
      } else if ($("google-map").exists()) {
        options.selector = $($("google-map").get(0)).attr("id");
      } else {
        options.selector = "#carto-map-container";
      }
      _adp.defaultMapOptions = options;
      if (typeof callback === "function") {
        return callback(geo.dataTable, coords, options);
      } else {
        return console.info("requestCartoUpload recieved no callback");
      }
    };
    return geo.init(function() {
      console.info("Post init");
      getCanonicalDataCoords(geo.dataTable, null, function(coords, options) {
        console.info("gcdc callback successful", coords);
        return parentCallback(coords);
      });
      return false;
    });
  }).fail(function(result, status) {
    var kbSize;
    kbSize = args.length / 1024;
    console.error("Couldn't communicate with server (" + result.status + " " + result.statusText + ")! POST size " + kbSize + " kiB", result, status);
    console.warn("" + uri.urlString + adminParams.apiTarget + "?" + args);
    stopLoadError("There was a problem communicating with the server. Please try again in a bit. (E-002)");
    return bsAlert("Couldn't upload dataset. Please try again later.", "danger");
  }).always(function() {
    var duration;
    try {
      duration = Date.now() - postTimeStart;
      console.info("POST and process took " + duration + "ms");
      clearTimeout(window._adp.initialTimeout);
      clearTimeout(window._adp.secondaryTimeout);
      window._adp.uploader = false;
      return $("#upload-data").removeAttr("disabled");
    } catch (undefined) {}
  });
  return false;
};

sortPoints = function(pointArray, asObj) {
  var coordPoint, len, point, sortedPoints, t;
  if (asObj == null) {
    asObj = true;
  }

  /*
   * Take an array of Points and return a Google Maps compatible array
   * of coordinate objects
   */
  window.upper = upperLeft(pointArray);
  pointArray.sort(pointSort);
  sortedPoints = new Array();
  for (t = 0, len = pointArray.length; t < len; t++) {
    coordPoint = pointArray[t];
    if (asObj) {
      sortedPoints.push(coordPoint.getObj());
    } else {
      point = coordPoint.toSimplePoint();
      sortedPoints.push(point);
    }
  }
  delete window.upper;
  return sortedPoints;
};

canonicalizePoint = function(point, swapConvention) {
  var error2, error3, error4, gLatLng, pReal, pointObj, tempLat;
  if (swapConvention == null) {
    swapConvention = false;
  }

  /*
   * Take really any type of point, and return a Point
   */
  pointObj = {
    lat: null,
    lng: null
  };
  try {
    tempLat = toFloat(point.lat);
    if (tempLat.toString() === point.lat) {
      if (!swapConvention) {
        point.lat = toFloat(point.lat);
        point.lng = toFloat(point.lng);
      } else {
        point.lat = toFloat(point.lng);
        point.lng = toFloat(point.lat);
      }
    } else {
      tempLat = toFloat(point[0]);
      if (tempLat.toString() === point[0]) {
        if (!swapConvention) {
          point[0] = toFloat(point[0]);
          point[1] = toFloat(point[1]);
        } else {
          point[0] = toFloat(point[1]);
          point[1] = toFloat(point[0]);
        }
      }
    }
  } catch (undefined) {}
  if (typeof (point != null ? point.lat : void 0) === "number") {
    pointObj = point;
  } else if (typeof (point != null ? point[0] : void 0) === "number") {
    pointObj = {
      lat: point[0],
      lng: point[1]
    };
  } else {
    try {
      if (typeof point.lat() === "number") {
        pointObj.lat = point.lat();
        pointObj.lng = point.lng();
      } else {
        throw "Not fPoint";
      }
    } catch (error2) {
      try {
        if (typeof point.getLat() === "number") {
          pointObj = point.getObj();
        } else {
          throw "Not Point";
        }
      } catch (error3) {
        if ((typeof google !== "undefined" && google !== null ? google.map : void 0) != null) {
          try {
            gLatLng = point.getPosition();
            pointObj.lat = gLatLng.lat();
            pointObj.lng = gLatLng.lng();
          } catch (error4) {
            throw "Unable to determine point type";
          }
        }
      }
    }
  }
  pReal = new Point(pointObj.lat, pointObj.lng);
  return pReal;
};

createConvexHull = function(pointsArray, returnObj) {
  var canonicalPoint, chConfig, cpHull, elapsed, error2, error3, len, len1, len2, obj, point, realPointArray, simplePointArray, startTime, swapConventions, t, u, w;
  if (returnObj == null) {
    returnObj = false;
  }

  /*
   * Take an array of points of multiple types and get a minimum convex
   * hull back
   *
   * @param obj|array pointsArray -> An array of points or simple
   *   object of points
   *
   * @return array -> an array of Point objects
   */
  simplePointArray = new Array();
  realPointArray = new Array();
  startTime = Date.now();
  console.log("createConvexHull called with " + (Object.size(pointsArray)) + " points");
  pointsArray = Object.toArray(pointsArray);
  swapConventions = false;
  for (t = 0, len = pointsArray.length; t < len; t++) {
    point = pointsArray[t];
    if (Math.abs(point.lng) > 90) {
      break;
    }
    if (Math.abs(point.lat) > 90) {
      swapConventions = true;
      break;
    }
  }
  for (u = 0, len1 = pointsArray.length; u < len1; u++) {
    point = pointsArray[u];
    canonicalPoint = canonicalizePoint(point, swapConventions);
    realPointArray.push(canonicalPoint);
  }
  try {
    console.info("Getting convex hull (original: " + pointsArray.length + "; canonical: " + realPointArray.length + ")", realPointArray);
    try {
      chConfig = getConvexHull(realPointArray);
    } catch (error2) {
      console.warn("Couldn't run real way!");
      simplePointArray = sortPoints(realPointArray, false);
      cpHull = getConvexHullPoints(simplePointArray);
    }
    cpHull = chConfig.paths;
  } catch (error3) {
    e = error3;
    console.error("Unable to get convex hull - " + e.message);
    console.warn(e.stack);
  }
  geo.canonicalBoundingBox = new Array();
  for (w = 0, len2 = cpHull.length; w < len2; w++) {
    point = cpHull[w];
    geo.canonicalBoundingBox.push(point.getObj());
  }
  obj = {
    hull: cpHull,
    points: realPointArray
  };
  geo.canonicalHullObject = obj;
  try {
    elapsed = Date.now() - startTime;
    console.debug("createConvexHull completed in " + elapsed + "ms");
  } catch (undefined) {}
  if (returnObj === true) {
    return obj;
  }
  return cpHull;
};

fPoint = function(lat, lng) {
  this.latval = lat;
  this.lngval = lng;
  this.lat = function() {
    return this.latval;
  };
  this.lng = function() {
    return this.lngval;
  };
  this.toString = function() {
    return "(" + this.x + ", " + this.y + ")";
  };
  return this.toString();
};

Point = function(lat, lng) {
  this.lat = toFloat(lat);
  this.lng = toFloat(lng);
  this.x = (this.lng + 180) * 360;
  this.y = (this.lat + 90) * 180;
  this.distance = function(that) {
    var dx, dy;
    dx = that.x - this.x;
    dy = that.y - this.y;
    return Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2));
  };
  this.slope = function(that) {
    var dx, dy;
    dx = that.x - this.x;
    dy = that.y - this.y;
    return dy / dx;
  };
  this.toString = function() {
    return "(" + this.lat + ", " + this.lng + ")";
  };
  this.getObj = function() {
    var o;
    o = {
      lat: this.lat,
      lng: this.lng
    };
    return o;
  };
  this.getLatLng = function() {
    var obj;
    if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) != null) {
      obj = this.getObj();
      return new google.maps.LatLng(obj);
    } else {
      return this.getObj();
    }
  };
  this.getLat = function() {
    return this.lat;
  };
  this.getLng = function() {
    return this.lng;
  };
  this.toSimplePoint = function() {
    var p;
    p = new fPoint(this.lat, this.lng);
    return p;
  };
  this.toGeoJson = function() {
    var gj;
    gj = [this.lat, this.lng];
    return gj;
  };
  return this.toString();
};

geo.Point = Point;


// A custom sort function that sorts p1 and p2 based on their slope
// that is formed from the upper most point from the array of points.
function pointSort(p1, p2) {
    // Exclude the 'upper' point from the sort (which should come first).
    if(p1 == upper) return -1;
    if(p2 == upper) return 1;

    // Find the slopes of 'p1' and 'p2' when a line is
    // drawn from those points through the 'upper' point.
    var m1 = upper.slope(p1);
    var m2 = upper.slope(p2);

    // 'p1' and 'p2' are on the same line towards 'upper'.
    if(m1 == m2) {
        // The point closest to 'upper' will come first.
        return p1.distance(upper) < p2.distance(upper) ? -1 : 1;
    }

    // If 'p1' is to the right of 'upper' and 'p2' is the the left.
    if(m1 <= 0 && m2 > 0) return -1;

    // If 'p1' is to the left of 'upper' and 'p2' is the the right.
    if(m1 > 0 && m2 <= 0) return 1;

    // It seems that both slopes are either positive, or negative.
    return m1 > m2 ? -1 : 1;
}

// Find the upper most point. In case of a tie, get the left most point.
function upperLeft(points) {
    var top = points[0];
    for(var i = 1; i < points.length; i++) {
        var temp = points[i];
        if(temp.y > top.y || (temp.y == top.y && temp.x < top.x)) {
            top = temp;
        }
    }
    return top;
};

Number.prototype.toRad = function() {
  return this * Math.PI / 180;
};

geo.distance = function(lat1, lng1, lat2, lng2) {

  /*
   * Distance across Earth curvature
   *
   * Measured in km
   */
  var R, arc, curve, dLat, dLon, semiLat, semiLng;
  R = 6371;
  dLat = (lat2 - lat1).toRad();
  dLon = (lng2 - lng1).toRad();
  semiLat = dLat / 2;
  semiLng = dLon / 2;
  arc = Math.pow(Math.sin(semiLat), 2) + Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) * Math.pow(Math.sin(semiLng), 2);
  curve = 2 * Math.atan2(Math.sqrt(arc), Math.sqrt(1 - arc));
  return R * curve;
};

geo.getBoundingRectangle = function(coordinateSet) {
  var boundingBox, coordinates, coords, eastMost, lat, len, lng, northMost, southMost, t, westMost;
  if (coordinateSet == null) {
    coordinateSet = geo.boundingBox;
  }
  coordinateSet = Object.toArray(coordinateSet);
  if (isNull(coordinateSet)) {
    console.warn("Need a set of coordinates for the bounding rectangle!");
    return false;
  }
  northMost = -90;
  southMost = 90;
  westMost = 180;
  eastMost = -180;
  for (t = 0, len = coordinateSet.length; t < len; t++) {
    coordinates = coordinateSet[t];
    coords = canonicalizePoint(coordinates);
    lat = coords.lat;
    lng = coords.lng;
    if (lat > northMost) {
      northMost = lat;
    }
    if (lat < southMost) {
      southMost = lat;
    }
    if (lng < westMost) {
      westMost = lng;
    }
    if (lng > eastMost) {
      eastMost = lng;
    }
  }
  boundingBox = {
    nw: [northMost, westMost],
    ne: [northMost, eastMost],
    se: [southMost, eastMost],
    sw: [southMost, westMost],
    north: northMost,
    east: eastMost,
    west: westMost,
    south: southMost
  };
  geo.computedBoundingRectangle = boundingBox;
  return boundingBox;
};

window.lastRanGeocoder = 0;

wait = function(ms) {
  var end, start;
  start = new Date().getTime();
  console.log("Will wait " + ms + "ms after " + start);
  end = start;
  while (end < start + ms) {
    end = new Date().getTime();
    if (window.endWait === true) {
      end = start + ms + 1;
    }
  }
  console.log("Waited " + ms + "ms");
  return end;
};

localityFromMapBuilder = function(builder, callback) {
  var MAX_QUERIES_PER_SECOND, center, maxQueryRate, maxQueryRateEff, sinceLastGeocoder;
  if (builder == null) {
    builder = window.mapBuilder;
  }

  /*
   *
   *
   * @param builder -> an object with an array of (canonicalized) points under
   *   mapBuilder.points, and a selector under mapBuilder.selector
   */
  MAX_QUERIES_PER_SECOND = 50;
  maxQueryRateEff = MAX_QUERIES_PER_SECOND / 20;
  maxQueryRate = 1000 / maxQueryRateEff;
  sinceLastGeocoder = Date.now() - window.lastRanGeocoder - randomInt(1, 25);
  if (sinceLastGeocoder < maxQueryRate) {
    console.debug("It's been " + sinceLastGeocoder + "ms since last attempt to geocode (min: " + maxQueryRate + "ms), delaying");
    delay(maxQueryRate, function() {
      return localityFromMapBuilder(builder, callback);
    });
    return false;
  }
  window.lastRanGeocoder = Date.now();
  center = getMapCenter(builder.points);
  geo.reverseGeocode(center.lat, center.lng, builder.points, function(locality, googleResult) {
    var error2;
    console.info("Got locality '" + locality + "'", googleResult);
    builder.views = googleResult;
    if (typeof callback === "function") {
      try {
        return callback(locality, builder);
      } catch (error2) {
        return callback(locality);
      }
    }
  });
  return false;
};

doMapBuilder = function(builder, createMapOptions, callback) {
  if (builder == null) {
    builder = window.mapBuilder;
  }
  if (createMapOptions == null) {
    createMapOptions = {
      selector: builder.selector,
      resetMapBuilder: false
    };
  }
  if (createMapOptions.resetMapBuilder == null) {
    createMapOptions.resetMapBuilder = false;
  }
  if (typeof (builder != null ? builder.points : void 0) !== "object") {
    console.error("Invalid builder", builder);
    return false;
  }
  return buildMap(builder, createMapOptions, function(map) {
    geo.boundingBox = map.hull;
    return localityFromMapBuilder(map, function(locality) {
      map.locality = locality;
      console.info("Map results:", map);
      if (typeof callback === "function") {
        callback(map);
      }
      return false;
    });
  });
};

geo.geocode = function(address, filter, callback) {

  /*
   *
   *
   * @param string address -> Text address
   * @param obj filter -> A componentRestrictions object. See
   *   https://developers.google.com/maps/documentation/javascript/geocoding#ComponentFiltering
   * @param func callback
   */
  var args, componentsArr, componentsString, doGeocoder, error2, geocoder, key, restrictionlessApiKey, str, url, val;
  try {
    if (geo.geocoder != null) {
      geocoder = geo.geocoder;
    } else {
      geocoder = new google.maps.Geocoder;
      geo.geocoder = geocoder;
    }
  } catch (error2) {
    e = error2;
    console.error("Couldn't instance a google map geocoder - " + e.message);
    console.warn(e.stack);
    return false;
  }
  doGeocoder = function() {
    var geocoderData;
    geocoderData = {
      address: address,
      componentRestrictions: filter
    };
    return geocoder.geocode(geocoderData, function(result, status) {
      var error3, len, mainResult, part, ref, t, tmp, type;
      console.log("Geocoder fetched", result, status);
      console.log("Provided", geocoderData);
      if (status !== google.maps.GeocoderStatus.OK) {
        console.warn("Geocoder failed -- Google said", status);
        return false;
      }
      mainResult = result[0];
      tmp = new Object();
      tmp.google = new Object();
      tmp.human = mainResult.formatted_address;
      try {
        ref = mainResult.address_components;
        for (t = 0, len = ref.length; t < len; t++) {
          part = ref[t];
          try {
            type = part.types[0];
            tmp.google[type] = part.long_name;
          } catch (error3) {
            continue;
          }
        }
      } catch (undefined) {}
      tmp.partial_match = mainResult.partial_match;
      if (typeof callback === "function") {
        return callback(tmp);
      } else {
        return console.warn("No callback provided! Got address object", tmp);
      }
    });
  };
  restrictionlessApiKey = null;
  if ((address != null) && (restrictionlessApiKey != null)) {
    url = "https://maps.googleapis.com/maps/api/geocode/json";
    componentsArr = new Array();
    for (key in filter) {
      val = filter[key];
      str = key + ":" + (encodeURIComponent(val));
      componentsArr.push(str);
    }
    componentsString = componentsArr.join("|");
    args = "address=" + (encodeURIComponent(address)) + "&components=" + componentsString + "&key=" + restrictionlessApiKey;
    console.log("Trying", url + "?" + args);
    $.get(url, args, "json").done(function(result) {
      var error3, len, mainResult, part, ref, status, t, tmp, type;
      console.log("API hit fetched", result);
      mainResult = result.results[0];
      status = result.status;
      if (status !== google.maps.GeocoderStatus.OK) {
        console.warn("Geocoder failed -- Google said", status);
        doGeocoder();
        return false;
      }
      tmp = new Object();
      tmp.google = new Object();
      tmp.human = mainResult.formatted_address;
      try {
        ref = mainResult.address_components;
        for (t = 0, len = ref.length; t < len; t++) {
          part = ref[t];
          try {
            type = part.types[0];
            tmp.google[type] = part.long_name;
          } catch (error3) {
            continue;
          }
        }
      } catch (undefined) {}
      tmp.partial_match = mainResult.partial_match;
      if (typeof callback === "function") {
        return callback(tmp);
      } else {
        return console.warn("No callback provided! Got address object", tmp);
      }
    }).fail(function(result, status) {
      console.error("Error (" + status + "): Couldn't post to Google, trying geocoder");
      return doGeocoder();
    });
  } else {
    doGeocoder();
  }
  return false;
};

geo.reverseGeocode = function(lat, lng, boundingBox, callback) {
  var error2, geocoder, ll, request;
  if (boundingBox == null) {
    boundingBox = geo.boundingBox;
  }

  /*
   * https://developers.google.com/maps/documentation/javascript/examples/geocoding-reverse
   */
  try {
    if (geo.geocoder != null) {
      geocoder = geo.geocoder;
    } else {
      geocoder = new google.maps.Geocoder;
      geo.geocoder = geocoder;
    }
  } catch (error2) {
    e = error2;
    console.error("Couldn't instance a google map geocoder - " + e.message);
    console.warn(e.stack);
    return false;
  }
  ll = {
    lat: toFloat(lat),
    lng: toFloat(lng)
  };
  request = {
    location: ll
  };
  console.debug("Starting reverse geocoder");
  return geocoder.geocode(request, function(result, status) {
    var east, error3, googleBounds, len, locality, mustContain, ne, north, south, sw, t, tooEast, tooNorth, tooSouth, tooWest, validView, view, west;
    if (status === google.maps.GeocoderStatus.OK) {
      console.info("Google said:", result);
      geo.geocoderViews = result;
      mustContain = geo.getBoundingRectangle(boundingBox);
      validView = null;
      for (t = 0, len = result.length; t < len; t++) {
        view = result[t];
        validView = view;
        googleBounds = view.geometry.bounds;
        if (googleBounds == null) {
          continue;
        }
        ne = googleBounds.getNorthEast();
        sw = googleBounds.getSouthWest();
        north = ne.lat();
        south = sw.lat();
        east = ne.lng();
        west = sw.lng();
        if (north < mustContain.north) {
          continue;
        }
        if (south > mustContain.south) {
          continue;
        }
        if (west > mustContain.west) {
          continue;
        }
        if (east < mustContain.east) {
          continue;
        }
        break;
      }
      locality = validView.formatted_address;
      tooNorth = north < mustContain.north;
      tooSouth = south > mustContain.south;
      tooWest = west > mustContain.west;
      tooEast = east < mustContain.east;
      if (tooNorth || tooSouth || tooWest || tooEast) {
        console.warn("The last locality, '" + locality + "', doesn't contain all coordinates!");
        console.warn("North: " + (!tooNorth) + ", South: " + (!tooSouth) + ", East: " + (!tooEast) + ", West: " + (!tooWest));
        console.info("Using", validView, mustContain);
        locality = "near " + locality + " (nearest region)";
      }
      console.info("Computed locality: '" + locality + "'");
      geo.computedLocality = locality;
      window.lastRanGeocoder = Date.now();
      if (typeof callback === "function") {
        try {
          return callback(locality, result);
        } catch (error3) {
          return callback(locality);
        }
      } else {
        return console.warn("No callback provided to geo.reverseGeocode()!");
      }
    } else {
      console.error("There was a problem getting the locality", result, status);
      if (typeof callback === "function") {
        console.warn("Proceeding anyway with fake locality 'Bad Locality'");
        geo.computedLocality = "Bad Locality";
        return callback("Bad Locality");
      }
    }
  });
};

toggleGoogleMapMarkers = function(diseaseStatus, selector, callback) {
  var len, marker, markers, state, t;
  if (diseaseStatus == null) {
    diseaseStatus = "positive";
  }
  if (selector == null) {
    selector = "#transect-viewport";
  }

  /*
   *
   */
  selector = selector + " google-map-marker[data-disease-detected='" + diseaseStatus + "']";
  markers = $(selector);
  console.info("Got " + markers.length + " markers");
  state = void 0;
  for (t = 0, len = markers.length; t < len; t++) {
    marker = markers[t];
    if (state == null) {
      state = !p$(marker).open;
      console.info("Setting " + diseaseStatus + " markers open state to " + state);
    }
    p$(marker).open = state;
  }
  if (typeof callback === "function") {
    callback(state);
  }
  return false;
};

setupMapMarkerToggles = function() {

  /*
   *
   */
  var html;
  html = "<div class=\"row\">\n  <h3 class=\"col-xs-12\">\n    Toggle map markers\n  </h3>\n  <button class=\"btn btn-danger col-xs-3 toggle-marker\" data-disease-status=\"positive\">Positive</button>\n  <button class=\"btn btn-primary col-xs-3 toggle-marker\" data-disease-status=\"negative\">Negative</button>\n  <button class=\"btn btn-warning col-xs-3 toggle-marker\" data-disease-status=\"no_confidence\"><span class=\"hidden-xs\">Inconclusive</span><span class=\"visible-xs-inline\">?</span></button>\n</div>";
  if (!$(".toggle-marker").exists()) {
    $("google-map + div").append(html);
  }
  console.log("Setting up events for map marker toggles");
  $(".toggle-marker").unbind().click(function() {
    var status;
    status = $(this).attr("data-disease-status");
    $(".aweb-link-species").removeAttr("hidden");
    console.log("Clicked '" + status + "' toggle");
    return toggleGoogleMapMarkers(status, null, function(isOpen) {
      if (status === "no_confidence") {
        status = "inconclusive";
      }
      if (isOpen) {
        console.info("Hiding selector", ".aweb-link-species:not([data-" + status + "='true'])");
        return $(".aweb-link-species:not([data-" + status + "='true'])").attr("hidden", "hidden");
      } else {
        return console.info("Removing hidden attribute");
      }
    });
  });
  return false;
};


/*
 * Minimum Convex Hull
 * view-source:http://www.geocodezip.com/v3_map-markers_ConvexHull.asp
 */

getConvexHull = function(googleMapsMarkersArray) {
  var error2, error3, gmm, gmmReal, len, len1, ll, llObj, marker, point, points, t, test, u;
  try {
    test = googleMapsMarkersArray[0];
    ll = test.getPosition();
  } catch (error2) {
    gmmReal = new Array();
    for (t = 0, len = googleMapsMarkersArray.length; t < len; t++) {
      point = googleMapsMarkersArray[t];
      gmm = new google.maps.Marker;
      try {
        ll = point.getLatLng();
      } catch (error3) {
        llObj = {
          lat: point.lat,
          lng: point.lng
        };
        ll = new google.maps.LatLng(llObj);
      }
      gmm.setPosition(ll);
      gmmReal.push(gmm);
    }
    googleMapsMarkersArray = gmmReal.slice(0);
  }
  points = new Array();
  for (u = 0, len1 = googleMapsMarkersArray.length; u < len1; u++) {
    marker = googleMapsMarkersArray[u];
    points.push(marker.getPosition());
  }
  points.sort(sortPointY);
  points.sort(sortPointX);
  try {
    console.debug("Convex hull being formed from", points.slice(0));
  } catch (undefined) {}
  return getConvexHullConfig(points);
};

sortPointX = function(a, b) {
  return a.lng() - b.lng();
};

sortPointY = function(a, b) {
  return a.lat() - b.lat();
};

sortPointsXY = function(pointArray) {

  /*
   * Sort an array of points by first Y then X
   */
  pointArray.sort(sortPointY);
  pointArray.sort(sortPointX);
  return pointArray;
};

getConvexHullPoints = function(points) {

  /*
   * Get the actual convex hull.
   *
   * You almost never want to call this directly -- call
   * createConvexHull() instead.
   *
   * @param array points -> pre-configured and pre-sorted points.
   *
   * @return array
   */
  var error2, hullPoints, len, len1, len2, len3, oldPoints, pObj, point, realHull, t, u, w, x;
  hullPoints = new Array();
  if (!isArray(points)) {
    console.error("Function requires an array");
    return false;
  }
  realHull = new Array();
  try {

    /*
     * Set up for algorithm from
     * https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain#JavaScript
     *
     *
     * This successfully plots project 9eb9fc11cf289dd2c7b68665a5eaa018
     */
    if (!(points[0] instanceof Point)) {
      oldPoints = points.slice(0);
      points = new Array();
      for (t = 0, len = oldPoints.length; t < len; t++) {
        point = oldPoints[t];
        points.push(canonicalizePoint(point));
      }
      hullPoints = convexHull(points);
    }
    for (u = 0, len1 = hullPoints.length; u < len1; u++) {
      point = hullPoints[u];
      pObj = new Point(point.lat, point.lng);
      realHull.push(pObj);
    }
  } catch (error2) {

    /*
     * Set up for algorith from
     * https://github.com/mgomes/ConvexHull
     *
     * Usually works, but fails for
     * 9eb9fc11cf289dd2c7b68665a5eaa018
     */
    if (points[0] instanceof Point) {
      oldPoints = points.slice(0);
      points = new Array();
      for (w = 0, len2 = oldPoints.length; w < len2; w++) {
        point = oldPoints[w];
        points.push(point.toSimplePoint());
      }
      console.debug("Converted Point array to fPoint array", points.slice(0));
    }
    chainHull_2D(points, points.length, hullPoints);
    for (x = 0, len3 = hullPoints.length; x < len3; x++) {
      point = hullPoints[x];
      pObj = new Point(point.lat(), point.lng());
      realHull.push(pObj);
    }
  }
  console.info("Got hull from " + points.length + " points:", realHull);
  return realHull;
};

getConvexHullConfig = function(points, map) {
  var hullPoints, polygonConfig;
  if (map == null) {
    map = geo.googleMap;
  }

  /*
   * Gets the convex hull with all the standard configuration helpers
   * for a Google Map object.
   *
   * Expects everything to be "pretty" -- you almost certainly want to
   * call createConvexHull() instead.
   *
   * @param array points -> well-formed array of points
   * @param GoogleMap map -> Google Map object
   */
  hullPoints = getConvexHullPoints(points);
  return polygonConfig = {
    map: map,
    paths: hullPoints,
    fillColor: defaultFillColor,
    fillOpacity: defaultFillOpacity,
    strokeWidth: 2,
    strokeColor: "#0000FF",
    strokeOpacity: 0.5
  };
};


function cross(o, a, b) {
   return (a.lat - o.lat) * (b.lng - o.lng) - (a.lng - o.lng) * (b.lat - o.lat)
}

/**
 * @param points An array of [X, Y] coordinates
 */
function convexHull(points) {
   points.sort(function(a, b) {
      return a.lat == b.lat ? a.lng - b.lng : a.lat - b.lat;
   });

   var lower = [];
   for (var i = 0; i < points.length; i++) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], points[i]) <= 0) {
         lower.pop();
      }
      lower.push(points[i]);
   }

   var upper = [];
   for (var i = points.length - 1; i >= 0; i--) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], points[i]) <= 0) {
         upper.pop();
      }
      upper.push(points[i]);
   }

   upper.pop();
   lower.pop();
   return lower.concat(upper);
}
;


    var gmarkers = [];
    var points = [];
    var hullPoints = [];
    var map = null;
      var polyline;
     function calculateConvexHull() {
      if (polyline) polyline.setMap(null);
      document.getElementById("hull_points").innerHTML = "";
      points = [];
      for (var i=0; i < gmarkers.length; i++) {
        points.push(gmarkers[i].getPosition());
      }
      points.sort(sortPointY);
      points.sort(sortPointX);
      DrawHull();
}

     function DrawHull() {
     hullPoints = [];
     chainHull_2D( points, points.length, hullPoints );
     polyline = new google.maps.Polygon({
      map: map,
      paths:hullPoints,
      fillColor:"#FF0000",
      strokeWidth:2,
      fillOpacity:0.5,
      strokeColor:"#0000FF",
      strokeOpacity:0.5
     });
     displayHullPts();
}

function displayHullPts() {
     document.getElementById("hull_points").innerHTML = "";
     for (var i=0; i < hullPoints.length; i++) {
       document.getElementById("hull_points").innerHTML += hullPoints[i].toUrlValue()+"<br>";
     }
   }
;


// Copyright 2001, softSurfer (www.softsurfer.com)
// This code may be freely used and modified for any purpose
// providing that this copyright notice is included with it.
// SoftSurfer makes no warranty for this code, and cannot be held
// liable for any real or imagined damage resulting from its use.
// Users of this code must verify correctness for their application.
// http://softsurfer.com/Archive/algorithm_0203/algorithm_0203.htm
// Assume that a class is already given for the object:
//    Point with coordinates {float x, y;}
//===================================================================

// isLeft(): tests if a point is Left|On|Right of an infinite line.
//    Input:  three points P0, P1, and P2
//    Return: >0 for P2 left of the line through P0 and P1
//            =0 for P2 on the line
//            <0 for P2 right of the line

function isLeft(P0, P1, P2) {
    return (P1.lng() - P0.lng()) * (P2.lat() - P0.lat()) - (P2.lng() - P0.lng()) * (P1.lat() - P0.lat());
}
//===================================================================

// chainHull_2D(): A.M. Andrew's monotone chain 2D convex hull algorithm
// http://softsurfer.com/Archive/algorithm_0109/algorithm_0109.htm
//
//     Input:  P[] = an array of 2D points
//                   presorted by increasing x- and y-coordinates
//             n = the number of points in P[]
//     Output: H[] = an array of the convex hull vertices (max is n)
//     Return: the number of points in H[]


function chainHull_2D(P, n, H) {
    // the output array H[] will be used as the stack
    var bot = 0,
    top = (-1); // indices for bottom and top of the stack
    var i; // array scan index
    // Get the indices of points with min x-coord and min|max y-coord
    var minmin = 0,
        minmax;

    var xmin = P[0].lng();
    for (i = 1; i < n; i++) {
        if (P[i].lng() != xmin) {
            break;
        }
    }

    minmax = i - 1;
    if (minmax == n - 1) { // degenerate case: all x-coords == xmin
        H[++top] = P[minmin];
        if (P[minmax].lat() != P[minmin].lat()) // a nontrivial segment
            H[++top] = P[minmax];
        H[++top] = P[minmin]; // add polygon endpoint
        return top + 1;
    }

    // Get the indices of points with max x-coord and min|max y-coord
    var maxmin, maxmax = n - 1;
    var xmax = P[n - 1].lng();
    for (i = n - 2; i >= 0; i--) {
        if (P[i].lng() != xmax) {
            break;
        }
    }
    maxmin = i + 1;

    // Compute the lower hull on the stack H
    H[++top] = P[minmin]; // push minmin point onto stack
    i = minmax;
    while (++i <= maxmin) {
        // the lower line joins P[minmin] with P[maxmin]
        if (isLeft(P[minmin], P[maxmin], P[i]) >= 0 && i < maxmin) {
            continue; // ignore P[i] above or on the lower line
        }

        while (top > 0) { // there are at least 2 points on the stack
            // test if P[i] is left of the line at the stack top
            if (isLeft(H[top - 1], H[top], P[i]) > 0) {
                break; // P[i] is a new hull vertex
            }
            else {
                top--; // pop top point off stack
            }
        }

        H[++top] = P[i]; // push P[i] onto stack
    }

    // Next, compute the upper hull on the stack H above the bottom hull
    if (maxmax != maxmin) { // if distinct xmax points
        H[++top] = P[maxmax]; // push maxmax point onto stack
    }

    bot = top; // the bottom point of the upper hull stack
    i = maxmin;
    while (--i >= minmax) {
        // the upper line joins P[maxmax] with P[minmax]
        if (isLeft(P[maxmax], P[minmax], P[i]) >= 0 && i > minmax) {
            continue; // ignore P[i] below or on the upper line
        }

        while (top > bot) { // at least 2 points on the upper stack
            // test if P[i] is left of the line at the stack top
            if (isLeft(H[top - 1], H[top], P[i]) > 0) {
                break;  // P[i] is a new hull vertex
            }
            else {
                top--; // pop top point off stack
            }
        }

// breaks algorithm
//        if (P[i].lng() == H[0].lng() && P[i].lat() == H[0].lat()) {
//            return top + 1; // special case (mgomes)
//        }

        H[++top] = P[i]; // push P[i] onto stack
    }

    if (minmax != minmin) {
        H[++top] = P[minmin]; // push joining endpoint onto stack
    }

    return top + 1;
}
;

$(function() {
  if ($("google-maps-api").exists()) {
    $("google-maps-api").on("api-load", function() {
      try {
        return window.gMapsCallback();
      } catch (undefined) {}
    });
  }
  return speculativeApiLoader();
});


/*
 * Debug log helper.
 * Assumes Bootstrap styles/js are included (as well as a bunch of my
 * standard stuff)
 *
 * Displayed elements are from the Polymer project
 */

enableDebugLogging = function() {

  /*
   * Overwrite console logs with custom events
   */
  var css, error2, html, logHistory;
  if (window.debugLoggingEnabled) {
    return false;
  }
  if ((typeof localStorage !== "undefined" && localStorage !== null ? localStorage.debugLog : void 0) != null) {
    try {
      logHistory = JSON.parse(localStorage.debugLog);
      window._debug = logHistory;
      console.info("Restored log history to local object");
    } catch (error2) {
      console.warn("Unable to restore log history");
      window._debug = new Array();
    }
  } else {
    window._debug = new Array();
  }
  window.sysConsole = console;
  window.sysLog = console.log;
  window.sysInfo = console.info;
  window.sysWarn = console.warn;
  window.sysError = console.error;
  window.sysDebug = console.debug;
  console.debug = function() {
    var args, messageObject;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    messageObject = {
      callType: "debug",
      "arguments": args
    };
    _debug.push(messageObject);
    sysDebug.apply(console, arguments);
    return backupDebugLog(true);
  };
  console.log = function() {
    var args, messageObject;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    messageObject = {
      callType: "log",
      "arguments": args
    };
    _debug.push(messageObject);
    sysLog.apply(console, arguments);
    return backupDebugLog(true);
  };
  console.info = function() {
    var args, messageObject;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    messageObject = {
      callType: "info",
      "arguments": args
    };
    _debug.push(messageObject);
    sysInfo.apply(console, arguments);
    return backupDebugLog(true);
  };
  console.warn = function() {
    var args, messageObject;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    messageObject = {
      callType: "warn",
      "arguments": args
    };
    _debug.push(messageObject);
    sysWarn.apply(console, arguments);
    return backupDebugLog(true);
  };
  console.error = function() {
    var args, messageObject;
    args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
    messageObject = {
      callType: "error",
      "arguments": args
    };
    _debug.push(messageObject);
    sysError.apply(console, arguments);
    return backupDebugLog(true);
  };
  $(window).on("popstate", function(ev) {
    console.log("Navigation event");
    return false;
  });
  $(window).unload(function(ev) {
    console.log("unload event");
    return false;
  });
  $("#debug-reporter").remove();
  html = "<paper-fab id=\"debug-reporter\" icon=\"icons:send\" data-toggle=\"tooltip\" title=\"Send Debug Report\" elevation=\"5\">\n</paper-fab>";
  $("body").append(html);
  css = "<style type=\"text/css\">\n  #debug-reporter {\n    background: #F44336;\n    color: #fff!important;\n    position: fixed;\n    right: 1rem;\n    bottom: 1rem;\n    cursor: pointer;\n  }\n</style>";
  $("#debug-reporter").before(css);
  $("#debug-reporter").click(function() {
    return reportDebugLog();
  });
  window.debugLoggingEnabled = true;
  try {
    p$(".debug-enable-context").disabled = true;
  } catch (undefined) {}
  backupDebugLog();
  return false;
};

backupDebugLog = function(suppressMessage) {
  var error2, logHistory;
  if (suppressMessage == null) {
    suppressMessage = false;
  }

  /*
   * Saves the debug log to local storage
   */
  if ((typeof localStorage !== "undefined" && localStorage !== null) && (window._debug != null)) {
    if (!suppressMessage) {
      console.info("Saving backup of debug log");
    }
    try {
      logHistory = JSON.stringify(window._debug);
      localStorage.debugLog = logHistory;
    } catch (error2) {
      e = error2;
      sysError.apply(console, ["Unable to backup debug log! " + e.message, window._debug]);
    }
  }
  return false;
};

window.enableDebugLogging = enableDebugLogging;

disableDebugLogging = function() {

  /*
   * Disable debug logging and replace bindings for system calls.
   */
  if ((typeof localStorage !== "undefined" && localStorage !== null ? localStorage.debugLog : void 0) != null) {
    delete localStorage.debugLog;
    delete _debug;
  }
  if (typeof window.sysLog === "function") {
    console.log = sysLog;
    console.info = sysInfo;
    console.warn = sysWarn;
    console.error = sysError;
    console.debug = sysDebug;
  }
  $("#debug-reporter").remove();
  window.debugLoggingEnabled = false;
  try {
    p$(".debug-disable-context").disabled = true;
  } catch (undefined) {}
  return false;
};

window.disableDebugLogging = disableDebugLogging;

reportDebugLog = function() {

  /*
   * Render the modal dialog to enable sending reports
   */
  var e1, e2, e3, e4, error2, error3, error4, error5, error6, getModalContents, html, visibleTestTime;
  if (window._debug != null) {
    backupDebugLog();
    console.info("Opening debug reporter");
    getModalContents = function() {
      var modalContents;
      modalContents = "<div>\n  <p>Copy the text below</p>\n  <textarea readonly rows=\"10\" class=\"form-control\">\n    " + localStorage.debugLog + "\n  </textarea>\n  <br/><br/>\n  <p>And email it to <a href=\"mailto:support@velociraptorsystems.com?subject=Debug%20Log\">support@velociraptorsystems.com</a></p>\n</div>";
      return modalContents;
    };
    html = "<paper-dialog modal id=\"report-bug-modal\">\n  <h2>Bug Report</h2>\n  <paper-dialog-scrollable>\n    " + (getModalContents()) + "\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog-modal>";
    $("#report-bug-modal").remove();
    $("body").append(html);
    try {
      safariDialogHelper("#report-bug-modal");
    } catch (error2) {
      e = error2;
      console.warn("Warning -- couldn't use safariDialogHelper to open. Some browsers may have an issue seeing this alert. (" + e.message + ")");
      console.debug(e.stack);
      try {
        try {
          p$("#report-bug-modal").open();
        } catch (error3) {
          e1 = error3;
          console.warn("Couldn't use p$ to show modal, trying direct ... (" + e1.message + ")");
          document.querySelector("#report-bug-modal").open();
        }
        visibleTestTime = 3000;
        delay(visibleTestTime, function() {
          var errObj;
          if (!$("#report-bug-modal").isVisible()) {
            errObj = function() {
              this.message = "Modal failed visibility test at " + visibleTestTime + "ms";
              return this.name = "InvisibleModalError";
            };
            throw errObj;
          }
        });
      } catch (error4) {
        e2 = error4;
        console.error("Unable to show bug report modal! " + e2.message);
        console.warn(e2.stack);
        try {
          bsAlert(getModalContents());
        } catch (error5) {
          e3 = error5;
          console.error("Couldn't show fallback bsAlert! " + e3.message);
          console.warn(e3.stack);
          try {
            startLoad();
            stopLoadError("Unable to show bug report modal!");
          } catch (error6) {
            e4 = error6;
            console.error("Couldn't alert user to the problem! " + e4.message);
            console.warn(e3.stack);
          }
        }
      }
    }
  }
  return false;
};

window.reportDebugLog = reportDebugLog;


/*
 * This file should be modular. Set up helper functions.
 *
 * This should NEVER overwrite the real versions, so we'll do these
 * checks on a delay (except the delay helper)
 */

if (typeof delay !== "function") {
  delay = function(ms, f) {
    return setTimeout(f, ms);
  };
}

delay(100, function() {
  var ref, ref1;
  if (typeof (typeof jQuery !== "undefined" && jQuery !== null ? (ref = jQuery.fn) != null ? ref.isVisible : void 0 : void 0) !== "function") {
    jQuery.fn.isVisible = function() {
      return jQuery(this).is(":visible") && jQuery(this).css("visibility") !== "hidden";
    };
  }
  if (typeof (typeof jQuery !== "undefined" && jQuery !== null ? (ref1 = jQuery.fn) != null ? ref1.exists : void 0 : void 0) !== "function") {
    jQuery.fn.exists = function() {
      return jQuery(this).length > 0;
    };
  }
  if (typeof p$ !== "function") {
    p$ = function(selector) {
      var error2;
      try {
        return $$(selector)[0];
      } catch (error2) {
        return $(selector).get(0);
      }
    };
  }
  if (typeof isNull !== "function") {
    isEmpty = function(str) {
      return !str || str.length === 0;
    };
    isBlank = function(str) {
      return !str || /^\s*$/.test(str);
    };
    isNull = function(str, dirty) {
      var error2, l;
      if (dirty == null) {
        dirty = false;
      }
      if (typeof str === "object") {
        try {
          l = str.length;
          if (l != null) {
            try {
              return l === 0;
            } catch (undefined) {}
          }
          return Object.size === 0;
        } catch (undefined) {}
      }
      try {
        if (isEmpty(str) || isBlank(str) || (str == null)) {
          if (!(str === false || str === 0)) {
            return true;
          }
          if (dirty) {
            if (str === false || str === 0) {
              return true;
            }
          }
        }
      } catch (error2) {
        e = error2;
        return false;
      }
      try {
        str = str.toString().toLowerCase();
      } catch (undefined) {}
      if (str === "undefined" || str === "null") {
        return true;
      }
      if (dirty && (str === "false" || str === "0")) {
        return true;
      }
      return false;
    };
  }
  if (typeof bsAlert !== "function") {
    bsAlert = function(message, type, fallbackContainer, selector) {
      var css, html, topContainer;
      if (type == null) {
        type = "warning";
      }
      if (fallbackContainer == null) {
        fallbackContainer = "body";
      }
      if (selector == null) {
        selector = "#bs-alert";
      }

      /*
       * Pop up a status message
       * Uses the Bootstrap alert dialog
       *
       * See
       * http://getbootstrap.com/components/#alerts
       * for available types
       */
      if (!$(selector).exists()) {
        html = "<div class=\"alert alert-" + type + " alert-dismissable hanging-alert\" role=\"alert\" id=\"" + (selector.slice(1)) + "\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n    <div class=\"alert-message\"></div>\n</div>";
        topContainer = $("main").exists() ? "main" : $("article").exists() ? "article" : fallbackContainer;
        $(topContainer).prepend(html);
      } else {
        $(selector).removeClass("alert-warning alert-info alert-danger alert-success");
        $(selector).addClass("alert-" + type);
      }
      $(selector + " .alert-message").html(message);
      css = "<style type=\"text/css\">\n  .hanging-alert {\n    position: fixed;\n    top: 0;\n    width: 50%;\n    margin: 0;\n    left: 25%;\n    z-index: 5999;\n  }\n</style>";
      $(selector).before(css);
      bindClicks();
      mapNewWindows();
      return false;
    };
    if (typeof openTab !== "function") {
      openLink = function(url) {
        if (url == null) {
          return false;
        }
        window.open(url);
        return false;
      };
      openTab = function(url) {
        return openLink(url);
      };
      goTo = function(url) {
        if (url == null) {
          return false;
        }
        window.location.href = url;
        return false;
      };
    }
    if (typeof mapNewWindows !== "function") {
      mapNewWindows = function(stopPropagation) {
        if (stopPropagation == null) {
          stopPropagation = true;
        }
        return $(".newwindow").each(function() {
          var curHref;
          curHref = $(this).attr("href");
          if (curHref == null) {
            curHref = $(this).attr("data-href");
          }
          $(this).click(function(e) {
            if (stopPropagation) {
              e.preventDefault();
              e.stopPropagation();
            }
            return openTab(curHref);
          });
          return $(this).keypress(function() {
            return openTab(curHref);
          });
        });
      };
    }
    if (typeof bindClicks !== "function") {
      bindClicks = function(selector) {
        if (selector == null) {
          selector = ".click";
        }

        /*
         * Helper function. Bind everything with a selector
         * to execute a function data-function or to go to a
         * URL data-href.
         */
        $(selector).each(function() {
          var callable, error2, error3, error4, newTab, ref2, ref3, ref4, ref5, tagType, url;
          try {
            url = (ref2 = $(this).attr("data-href")) != null ? ref2 : $(this).attr("href");
            if (!isNull(url)) {
              try {
                tagType = $(this).prop("tagName").toLowerCase();
              } catch (error2) {
                tagType = null;
              }
              try {
                if (url === uri.o.attr("path") && tagType === "paper-tab") {
                  $(this).parent().prop("selected", $(this).index());
                }
              } catch (error3) {
                e = error3;
                console.warn("tagname lower case error");
              }
              newTab = ((ref3 = $(this).attr("newTab")) != null ? ref3.toBool() : void 0) || ((ref4 = $(this).attr("newtab")) != null ? ref4.toBool() : void 0) || ((ref5 = $(this).attr("data-newtab")) != null ? ref5.toBool() : void 0);
              if (tagType === "a" && !newTab) {
                return true;
              }
              if (tagType === "a") {
                $(this).keypress(function() {
                  return openTab(url);
                });
              }
              $(this).unbind().click(function(e) {
                var error4;
                e.preventDefault();
                e.stopPropagation();
                try {
                  if (newTab) {
                    return openTab(url);
                  } else {
                    return goTo(url);
                  }
                } catch (error4) {
                  return goTo(url);
                }
              });
              return url;
            } else {
              callable = $(this).attr("data-function");
              if (callable != null) {
                $(this).unbind();
                return $(this).click(function() {
                  var args, error4, error5;
                  try {
                    console.log("Executing bound function " + callable + "()");
                    try {
                      args = null;
                      if (!isNull($(this).attr("data-args"))) {
                        args = $(this).attr("data-args").split(",");
                      }
                    } catch (undefined) {}
                    try {
                      if (args != null) {
                        return window[callable].apply(window, args);
                      } else {
                        return window[callable]();
                      }
                    } catch (error4) {
                      return window[callable]();
                    }
                  } catch (error5) {
                    e = error5;
                    return console.error("'" + callable + "()' is a bad function - " + e.message);
                  }
                });
              }
            }
          } catch (error4) {
            e = error4;
            return console.error("There was a problem binding to #" + ($(this).attr("id")) + " - " + e.message);
          }
        });
        return false;
      };
    }
  }
  if (typeof Function.debounce !== "function") {
    Function.prototype.getName = function() {

      /*
       * Returns a unique identifier for a function
       */
      var name;
      name = this.name;
      if (name == null) {
        name = this.toString().substr(0, this.toString().indexOf("(")).replace("function ", "");
      }
      if (isNull(name)) {
        name = md5(this.toString());
      }
      return name;
    };
    return Function.prototype.debounce = function() {
      var args, delayed, error2, execAsap, func, key, ref2, threshold, timeout;
      threshold = arguments[0], execAsap = arguments[1], timeout = arguments[2], args = 4 <= arguments.length ? slice.call(arguments, 3) : [];
      if (threshold == null) {
        threshold = 300;
      }
      if (execAsap == null) {
        execAsap = false;
      }
      if (timeout == null) {
        timeout = window.debounce_timer;
      }

      /*
       * Borrowed from http://coffeescriptcookbook.com/chapters/functions/debounce
       * Only run the prototyped function once per interval.
       *
       * @param threshold -> Timeout in ms
       * @param execAsap -> Do it NAOW
       * @param timeout -> backup timeout object
       */
      if (((ref2 = window.core) != null ? ref2.debouncers : void 0) == null) {
        if (window.core == null) {
          window.core = new Object();
        }
        core.debouncers = new Object();
      }
      try {
        key = this.getName();
      } catch (undefined) {}
      func = this;
      delayed = function() {
        if (!execAsap) {
          return func.apply(func, args);
        }
      };
      try {
        if (core.debouncers[key] != null) {
          timeout = core.debouncers[key];
        }
      } catch (undefined) {}
      if (timeout != null) {
        try {
          clearTimeout(timeout);
        } catch (error2) {
          e = error2;
        }
      }
      if (execAsap) {
        func.apply(obj, args);
        console.log("Executed " + key + " immediately");
        return false;
      }
      if (key != null) {
        return core.debouncers[key] = delay(threshold, function() {
          return delayed();
        });
      } else {
        return window.debounce_timer = delay(threshold, function() {
          return delayed();
        });
      }
    };
  }
});

window.debugScriptSetup = false;

$(function() {
  var bootstrapDebugSetup, setupContext;
  (bootstrapDebugSetup = function() {
    window.debugScriptSetup = true;
    if ((typeof localStorage !== "undefined" && localStorage !== null ? localStorage.debugLog : void 0) != null) {
      window.debugLoggingEnabled = true;
      return enableDebugLogging();
    } else {
      return window.debugLoggingEnabled = false;
    }
  })();
  (setupContext = function(count) {
    var allowedBugReportElements, doShowBugReportContext, error2, html, len, preurl, ref, t, tagType, waited;
    if (!(typeof Polymer !== "undefined" && Polymer !== null ? (ref = Polymer.RenderStatus) != null ? ref._ready : void 0 : void 0)) {
      if (typeof Polymer !== "undefined" && Polymer !== null) {
        if (count > 20) {
          waited = count * 500;
          console.warn("Fake it till you make it -- after waiting " + waited + "ms, we're going to pretend Polymer is ready");
          try {
            Polymer.RenderStatus._ready = true;
          } catch (undefined) {}
        }
      } else {
        if (count > 20) {
          try {
            console.warn("Inserting Polymer components into DOM");
            preurl = "https://cdn.rawgit.com/download/polymer-cdn/1.5.0/lib";
            html = "<script src=\"" + preurl + "/webcomponentsjs/webcomponents-lite.min.js\"></script>\n<link rel=\"import\" href=\"" + preurl + "/polymer/polymer.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-spinner/paper-spinner.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-menu/paper-menu.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-material/paper-material.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-dialog/paper-dialog.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-dialog-scrollable/paper-dialog-scrollable.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-button/paper-button.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-icon-button/paper-icon-button.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-fab/paper-fab.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/paper-item/paper-item.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/iron-icons/iron-icons.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/iron-icons/image-icons.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/iron-icons/social-icons.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/iron-icons/editor-icons.html\"/>\n<link rel=\"import\" href=\"" + preurl + "/neon-animation/neon-animation.html\"/>\n</";
            $("head").append(html);
            count = -2;
          } catch (error2) {
            e = error2;
            console.error("Unable to insert Polymer into DOM (" + e.message + ")");
          }
        }
      }
      console.warn("Delaying context until Polymer.RenderStatus is ready");
      delay(500, function() {
        count++;
        return setupContext(count);
      });
      return false;
    }
    console.info("Setting up context events");
    $("paper-icon-button[icon='icons:bug-report']").contextmenu(function(event) {
      doShowBugReportContext.debounce(null, null, null, this, event);
      return false;
    });
    allowedBugReportElements = ["paper-button", "button"];
    for (t = 0, len = allowedBugReportElements.length; t < len; t++) {
      tagType = allowedBugReportElements[t];
      $(tagType).find("[icon='icons:bug-report']").parents(tagType).contextmenu(function(event) {
        doShowBugReportContext.debounce(null, null, null, this, event);
        return false;
      });
    }
    return doShowBugReportContext = function(clickedElement, event) {
      var inFn, outFn;
      event.preventDefault();
      console.info("Showing bug report context menu");
      html = "<paper-material class=\"bug-report-context-wrapper\" style=\"top:" + event.pageY + "px;left:" + event.pageX + "px;position:absolute\">\n  <paper-menu class=context-menu\">\n    <paper-item class=\"debug-enable-context\" data-fn=\"enableDebugLogging\">\n      Enable debug reporting\n    </paper-item>\n    <paper-item class=\"debug-disable-context\" data-fn=\"disableDebugLogging\">\n      Disable debug reporting\n    </paper-item>\n  </paper-menu>\n</paper-material>";
      $(".bug-report-context-wrapper").remove();
      $("body").append(html);
      inFn = function(el) {
        $(clickedElement).addClass("iron-selected");
        return false;
      };
      outFn = function(el) {
        $(clickedElement).removeClass("iron-selected");
        return false;
      };
      $(".bug-report-context-wrapper paper-item").hover(inFn, outFn).click(function() {
        var fn;
        fn = $(clickedElement).attr("data-fn");
        return false;
      });
      $(".debug-enable-context").click(function() {
        return enableDebugLogging();
      });
      $(".debug-disable-context").click(function() {
        return disableDebugLogging();
      });
      if (window.debugLoggingEnabled) {
        try {
          p$(".debug-enable-context").disabled = true;
        } catch (undefined) {}
      } else {
        try {
          p$(".debug-disable-context").disabled = true;
        } catch (undefined) {}
      }
      return delay(5000, function() {
        return $(".bug-report-context-wrapper").remove();
      });
    };
  })(0);
  window.setupDebugContext = function() {
    console.log("**** Debug Context Events Enabled ***");
    bootstrapDebugSetup();
    setupContext();
    return true;
  };
  try {
    return setupDebugContext();
  } catch (undefined) {}
});

//# sourceMappingURL=maps/c.js.map
