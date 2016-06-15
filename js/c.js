var Point, activityIndicatorOff, activityIndicatorOn, adData, animateHoverShadows, animateLoad, backupDebugLog, bindClicks, bindCopyEvents, bindDismissalRemoval, bsAlert, buildMap, byteCount, canonicalizePoint, cartoAccount, cartoMap, cartoVis, checkFileVersion, checkLoggedIn, cleanupToasts, copyText, createConvexHull, createMap, createMap2, createRawCartoMap, d$, dateMonthToString, deEscape, decode64, deepJQuery, defaultFillColor, defaultFillOpacity, defaultMapMouseOverBehaviour, delay, disableDebugLogging, doCORSget, doMapBuilder, downloadCSVFile, e, enableDebugLogging, encode64, error1, fPoint, foo, formatScientificNames, gMapsApiKey, getColumnObj, getConvexHull, getConvexHullConfig, getConvexHullPoints, getElementHtml, getLocation, getMapCenter, getMapZoom, getMaxZ, getPointsFromBoundingBox, getPosterFromSrc, goTo, isArray, isBlank, isBool, isEmpty, isHovered, isJson, isNull, isNumber, jsonTo64, lightboxImages, linkUsers, loadJS, localityFromMapBuilder, mapNewWindows, openLink, openTab, overlayOff, overlayOn, p$, post64, prepURI, randomInt, randomString, reInitMap, reportDebugLog, roundNumber, roundNumberSigfig, safariDialogHelper, setupMapMarkerToggles, sortPointX, sortPointY, sortPoints, startLoad, stopLoad, stopLoadError, toFloat, toInt, toObject, toastStatusMessage, toggleGoogleMapMarkers, uri,
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

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

isNull = function(str) {
  var error2;
  try {
    if (isEmpty(str) || isBlank(str) || (str == null)) {
      if (!(str === false || str === 0)) {
        return true;
      }
    }
  } catch (error2) {
    e = error2;
    return false;
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

delay = function(ms, f) {
  return setTimeout(f, ms);
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
  var decodeHTMLEntities, element, fixHtmlEncodings, tmp;
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
  fixHtmlEncodings = function(string) {
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
  tmp = fixHtmlEncodings(this);
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

copyText = function(text, zcObj, zcElement) {

  /*
   *
   */
  var clip, clipboardData;
  try {
    clipboardData = {
      dataType: "text/plain",
      data: text
    };
    clip = new ClipboardEvent("copy", clipboardData);
    document.dispatchEvent(clip);
    return false;
  } catch (undefined) {}
  if (zcObj != null) {
    clipboardData = {
      "text/plain": text
    };
    zcObj.setData(clipboardData);
    zcObj.on("aftercopy", function(e) {
      if (e.data["text/plain"]) {
        toastStatusMessage("Copied to clipboard");
      } else {
        toastStatusMessage("Error copying to clipboard");
      }
      return window.resetClipboard = false;
    });
    zcObj.on("error", function(e) {
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
        return window.tempZC = new ZeroClipboard(zcElement);
      }
    });
  }
  return false;
};

bindCopyEvents = function(selector) {
  if (selector == null) {
    selector = ".click-copy";
  }
  loadJS("bower_components/zeroclipboard/dist/ZeroClipboard.min.js", function() {
    var zcConfig;
    zcConfig = {
      swfPath: "bower_components/zeroclipboard/dist/ZeroClipboard.swf"
    };
    ZeroClipboard.config(zcConfig);
    return $(selector).each(function() {
      var zcObj;
      zcObj = new ZeroClipboard(this);
      return $(this).click(function() {
        var copySelector, text;
        text = $(this).attr("data-clipboard-text");
        if (isNull(text)) {
          copySelector = $(this).attr("data-copy-selector");
          text = $(copySelector).val();
          if (isNull(text)) {
            try {
              text = p$(copySelector).value;
            } catch (undefined) {}
          }
          console.info("Copying text", text);
        }
        copyText(text, zcObj, this);
        return false;
      });
    });
  });
  return false;
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
  var l, len, len1, lower, lowerRegEx, lowers, m, str, upper, upperRegEx, uppers;
  str = this.replace(/([^\W_]+[^\s-]*) */g, function(txt) {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
  lowers = ["A", "An", "The", "And", "But", "Or", "For", "Nor", "As", "At", "By", "For", "From", "In", "Into", "Near", "Of", "On", "Onto", "To", "With"];
  for (l = 0, len = lowers.length; l < len; l++) {
    lower = lowers[l];
    lowerRegEx = new RegExp("\\s" + lower + "\\s", "g");
    str = str.replace(lowerRegEx, function(txt) {
      return txt.toLowerCase();
    });
  }
  uppers = ["Id", "Tv"];
  for (m = 0, len1 = uppers.length; m < len1; m++) {
    upper = uppers[m];
    upperRegEx = new RegExp("\\b" + upper + "\\b", "g");
    str = str.replace(upperRegEx, upper.toUpperCase());
  }
  return str;
};

Function.prototype.debounce = function() {
  var args, delayed, error2, execAsap, func, threshold, timeout;
  threshold = arguments[0], execAsap = arguments[1], timeout = arguments[2], args = 4 <= arguments.length ? slice.call(arguments, 3) : [];
  if (threshold == null) {
    threshold = 300;
  }
  if (execAsap == null) {
    execAsap = false;
  }
  if (timeout == null) {
    timeout = debounce_timer;
  }
  func = this;
  delayed = function() {
    if (!execAsap) {
      func.apply(func, args);
    }
    return console.log("Debounce applied");
  };
  if (timeout != null) {
    try {
      clearTimeout(timeout);
    } catch (error2) {
      e = error2;
    }
  } else if (execAsap) {
    func.apply(obj, args);
    console.log("Executed immediately");
  }
  return timeout = setTimeout(delayed, threshold);
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
  $(selector).attr("text", message).text(message).addClass(className);
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
  var l, len, ref, results, timeout;
  ref = window.metaTracker.toastTracker;
  results = [];
  for (l = 0, len = ref.length; l < len; l++) {
    timeout = ref[l];
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

deepJQuery = function(selector) {

  /*
   * Do a shadow-piercing selector
   *
   * Cross-browser, works with Chrome, Firefox, Opera, Safari, and IE
   * Falls back to standard jQuery selector when everything fails.
   */
  var error2, error3;
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
      return $(selector);
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
    var callable, error2, error3, url;
    try {
      url = $(this).attr("data-href");
      if (!isNull(url)) {
        $(this).unbind();
        try {
          if (url === uri.o.attr("path") && $(this).prop("tagName").toLowerCase() === "paper-tab") {
            $(this).parent().prop("selected", $(this).index());
          }
        } catch (error2) {
          e = error2;
          console.warn("tagname lower case error");
        }
        $(this).click(function() {
          var error3, ref, ref1, ref2;
          try {
            if (((ref = $(this).attr("newTab")) != null ? ref.toBool() : void 0) || ((ref1 = $(this).attr("newtab")) != null ? ref1.toBool() : void 0) || ((ref2 = $(this).attr("data-newtab")) != null ? ref2.toBool() : void 0)) {
              return openTab(url);
            } else {
              return goTo(url);
            }
          } catch (error3) {
            return goTo(url);
          }
        });
        return url;
      } else {
        callable = $(this).attr("data-function");
        if (callable != null) {
          $(this).unbind();
          return $(this).click(function() {
            var error3;
            try {
              console.log("Executing bound function " + callable + "()");
              return window[callable]();
            } catch (error3) {
              e = error3;
              return console.error("'" + callable + "()' is a bad function - " + e.message);
            }
          });
        }
      }
    } catch (error3) {
      e = error3;
      return console.error("There was a problem binding to #" + ($(this).attr("id")) + " - " + e.message);
    }
  });
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
    var nameStyle;
    nameStyle = $(this).css("font-style") === "italic" ? "normal" : "italic";
    return $(this).css("font-style", nameStyle);
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

checkFileVersion = function(forceNow, file) {
  var checkVersion, error2, key, keyExists;
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
      if (forceNow) {
        console.log("Forced version check:", result);
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
        return console.info("Your version of this page is up to date: have " + window._adp.lastMod[modKey] + ", got " + result.last_mod);
      }
    }).fail(function() {
      return console.warn("Couldn't check file version!!");
    }).always(function() {
      return delay(5 * 60 * 1000, function() {
        return checkVersion(filePath, modKey);
      });
    });
  };
  try {
    keyExists = window._adp.lastMod[key];
  } catch (error2) {
    keyExists = false;
  }
  if (forceNow || (window._adp.lastMod == null) || !keyExists) {
    checkVersion(file, key);
    return true;
  }
  return false;
};

window.checkFileVersion = checkFileVersion;

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

downloadCSVFile = function(data, options) {

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
  var c, file, header, headerStr, html, id, jsonObject, parser, selector, textAsset;
  textAsset = "";
  if (isJson(data)) {
    jsonObject = JSON.parse(data);
  } else if (isArray(data)) {
    jsonObject = toObject(data);
  } else if (typeof data === "object") {
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
  (parser = function(jsonObj, cascadeObjects) {
    var error2, escapedKey, escapedValue, key, results, row, tempValue, tempValueArr, value;
    row = 0;
    results = [];
    for (key in jsonObj) {
      value = jsonObj[key];
      if (typeof value === "function") {
        continue;
      }
      ++row;
      try {
        escapedKey = key.replace(/"/g, '""');
        if (typeof value === "object" && cascadeObjects) {
          value = parser(value, true);
        }
        if (isNull(value)) {
          escapedValue = "";
        } else {
          tempValue = value.replace(/"/g, '""');
          tempValue = value.replace(/<\/p><p>/g, '","');
          if (typeof options.splitValues === "string") {
            tempValueArr = tempValue.split(options.splitValues);
            tempValue = tempValueArr.join("\",\"");
            escapedKey = false;
          }
          escapedValue = tempValue;
        }
        if (escapedKey === false) {
          results.push(textAsset += "\"" + escapedValue + "\"\n");
        } else if (isNumber(escapedKey)) {
          results.push(textAsset += "\"" + escapedValue + "\",");
        } else if (!isNull(escapedKey)) {
          results.push(textAsset += "\"" + escapedKey + "\",\"" + escapedValue + "\"\n");
        } else {
          results.push(void 0);
        }
      } catch (error2) {
        e = error2;
        console.warn("Unable to run key " + key + " on row " + row, value, jsonObj);
        results.push(console.warn(e.stack));
      }
    }
    return results;
  })(jsonObject, false);
  textAsset = textAsset.trim();
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
  return false;
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
        return loadAdminUi();
      });
    } else {
      console.info("No admin setup requested");
    }
    return $("header .header-bar-user-name").click(function() {
      return goTo(uri.urlString + "profile.php");
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
  if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) == null) {
    return loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey + "&callback=gMapsCallback");
  } else {
    return window.gMapsCallback();
  }
};

getMapCenter = function(bb) {
  var bbArray, center, centerLat, centerLng, coords, i, l, len, point, totalLat, totalLng;
  if (bb == null) {
    bb = geo.canonicalBoundingBox;
  }
  if (bb != null) {
    i = 0;
    totalLat = 0.0;
    totalLng = 0.0;
    bbArray = Object.toArray(bb);
    for (l = 0, len = bbArray.length; l < len; l++) {
      coords = bbArray[l];
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

getPointsFromBoundingBox = function(obj) {
  var coords, corners, l, len, realCoords;
  corners = [[obj.bounding_box_n, obj.bounding_box_w], [obj.bounding_box_n, obj.bounding_box_e], [obj.bounding_box_s, obj.bounding_box_e], [obj.bounding_box_s, obj.bounding_box_w]];
  realCoords = new Array();
  for (l = 0, len = corners.length; l < len; l++) {
    coords = corners[l];
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
  zoomOutThreshold = 2;
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
      console.warn("Can't find '" + selector + "' - will use 480x650");
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
  var a, cat, catalog, center, classes, data, detected, error2, error3, error4, genus, googleMap, hull, i, id, idSuffix, iw, l, len, len1, len2, len3, m, mapHtml, mapObjAttr, mapSelector, marker, markerHtml, markerTitle, note, point, pointData, pointList, points, poly, q, r, ref, ref1, ref2, ref3, selector, species, ssp, t, testString, tested, zoom;
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
        for (l = 0, len = pointList.length; l < len; l++) {
          point = pointList[l];
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
          for (m = 0, len1 = ref2.length; m < len1; m++) {
            point = ref2[m];
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
      for (q = 0, len2 = hull.length; q < len2; q++) {
        point = hull[q];
        mapHtml += "<google-map-point latitude=\"" + point.lat + "\" longitude=\"" + point.lng + "\"> </google-map-point>";
      }
      mapHtml += "    </google-map-poly>";
    } else {
      mapHtml = "";
    }
    if (options.skipPoints !== true) {
      i = 0;
      for (t = 0, len3 = points.length; t < len3; t++) {
        point = points[t];
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
  var l, len, map, newObjects, o, obj, poly, polyOptions;
  map = p$(selector);
  map.map = null;
  o = map.objects;
  map._initGMap();
  newObjects = new Array();
  for (l = 0, len = o.length; l < len; l++) {
    obj = o[l];
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

createRawCartoMap = function(layers, callback, options, mapSelector) {
  var BASE_MAP, lMap, lTopoOptions, leafletOptions, mapOptions, params, ref, ref1;
  if (mapSelector == null) {
    mapSelector = "#global-data-map";
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
  BASE_MAP = geo.lMap;
  cartodb.createLayer(BASE_MAP, params, mapOptions).addTo(BASE_MAP, 1).on("done", function(layer) {
    var dataLayer, l, len;
    console.info("Done, returned", layer, "for type " + params.type);
    if (isArray(layers)) {
      for (l = 0, len = layers.length; l < len; l++) {
        dataLayer = layers[l];
        console.info("Re-adding sublayer", dataLayer);
        layer.createSubLayer(dataLayer);
      }
      console.info("Added layers to map");
    } else {
      console.warn("'layers' isn't an array", layers);
    }
    layer.getSubLayer(0).setInteraction(true);
    layer.getSubLayer(0).on("featureover", function(e, pos, pixel, data) {
      console.log("Mousover", data);
      return false;
    });
    layer.show();
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

getColumnObj = function() {
  var columnDatatype;
  columnDatatype = {
    id: "int",
    collectionID: "varchar",
    catalogNumber: "varchar",
    fieldNumber: "varchar",
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
    fimsExtra: "json",
    the_geom: "varchar"
  };
  if (_adp.activeCols != null) {
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
    var alt, bb_east, bb_north, bb_south, bb_west, column, columnDatatype, columnNamesList, coordinate, coordinatePair, dataGeometry, dataObject, defaultPolygon, err, error2, error3, geoJson, geoJsonGeom, geoJsonVal, i, iIndex, insertMaxLength, insertPlace, l, lat, lats, len, len1, ll, lng, lngs, m, n, ref, ref1, ref2, ref3, row, sampleLatLngArray, sqlQuery, tempList, transectPolygon, userTransectRing, value, valuesArr, valuesList;
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
        for (l = 0, len = userTransectRing.length; l < len; l++) {
          coordinatePair = userTransectRing[l];
          if (coordinatePair instanceof Point) {
            coordinatePair = coordinatePair.toGeoJson();
            userTransectRing[i] = coordinatePair;
          }
          if (coordinatePair.length !== 2) {
            throw {
              message: "Bad coordinate length for '" + coordinatePair + "'"
            };
          }
          for (m = 0, len1 = coordinatePair.length; m < len1; m++) {
            coordinate = coordinatePair[m];
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
      columnDatatype = getColumnObj();
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
                columnNamesList.push(column + " " + columnDatatype[column]);
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
            geoJsonVal = "ST_SetSRID(ST_Point(" + geoJsonGeom.coordinates[0] + "," + geoJsonGeom.coordinates[1] + "),4326)";
            valuesArr.push(geoJsonVal);
            valuesList.push("(" + (valuesArr.join(",")) + ")");
          }
          insertMaxLength = 15;
          insertPlace = 0;
          console.info("Inserting " + insertMaxLength + " at a time");
          while (valuesList.slice(insertPlace, insertPlace + insertMaxLength).length > 0) {
            tempList = valuesList.slice(insertPlace, insertPlace + insertMaxLength);
            insertPlace += insertMaxLength;
            sqlQuery += "INSERT INTO " + dataTable + " VALUES " + (tempList.join(", ")) + ";";
          }
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
  var apiPostSqlQuery, args, doStillWorking, e2, error2, error3, estimate, max, postTimeStart, story, updateUploadProgress, workingIter;
  apiPostSqlQuery = encodeURIComponent(encode64(sqlQuery));
  args = "action=upload&sql_query=" + apiPostSqlQuery;
  console.info("Querying:");
  console.info(sqlQuery);
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
  $.post("api.php", args, "json").done(function(result) {
    var cartoHasError, cartoResults, dataBlobUrl, dataVisUrl, error, j, key, parentCallback, prettyHtml, response, val;
    console.log("Got back", result);
    if (result.status !== true) {
      console.error("Got an error from the server!");
      console.warn(result);
      stopLoadError("There was a problem uploading your data. Please try again.");
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
      bsAlert("Error uploading your data: " + cartoHasError, "danger");
      stopLoadError("CartoDB returned an error: " + cartoHasError);
      return false;
    }
    console.info("Carto was successful! Got results", cartoResults);
    try {
      prettyHtml = JsonHuman.format(cartoResults);
    } catch (undefined) {}
    bsAlert("Upload to CartoDB of table <code>" + dataTable + "</code> was successful", "success");
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
        console.info("gcdc callback successful");
        return parentCallback(coords);
      });
      return false;
    });
  }).fail(function(result, status) {
    console.error("Couldn't communicate with server!", result, status);
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
  var coordPoint, l, len, point, sortedPoints;
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
  for (l = 0, len = pointArray.length; l < len; l++) {
    coordPoint = pointArray[l];
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

canonicalizePoint = function(point) {

  /*
   * Take really any type of point, and return a Point
   */
  var error2, error3, error4, gLatLng, pReal, pointObj, tempLat;
  pointObj = {
    lat: null,
    lng: null
  };
  try {
    tempLat = toFloat(point.lat);
    if (tempLat.toString() === point.lat) {
      point.lat = toFloat(point.lat);
      point.lng = toFloat(point.lng);
    } else {
      tempLat = toFloat(point[0]);
      if (tempLat.toString() === point[0]) {
        point[0] = toFloat(point[0]);
        point[1] = toFloat(point[1]);
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
  var canonicalPoint, chConfig, cpHull, error2, error3, l, len, len1, m, obj, point, realPointArray, simplePointArray;
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
  console.log("createConvexHull called with " + (Object.size(pointsArray)) + " points");
  pointsArray = Object.toArray(pointsArray);
  for (l = 0, len = pointsArray.length; l < len; l++) {
    point = pointsArray[l];
    canonicalPoint = canonicalizePoint(point);
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
  for (m = 0, len1 = cpHull.length; m < len1; m++) {
    point = cpHull[m];
    geo.canonicalBoundingBox.push(point.getObj());
  }
  obj = {
    hull: cpHull,
    points: realPointArray
  };
  geo.canonicalHullObject = obj;
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
  var boundingBox, coordinates, coords, eastMost, l, lat, len, lng, northMost, southMost, westMost;
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
  for (l = 0, len = coordinateSet.length; l < len; l++) {
    coordinates = coordinateSet[l];
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

localityFromMapBuilder = function(builder, callback) {
  var center;
  if (builder == null) {
    builder = window.mapBuilder;
  }
  center = getMapCenter(builder.points);
  geo.reverseGeocode(center.lat, center.lng, builder.points, function(locality) {
    console.info("Got locality '" + locality + "'");
    if (typeof callback === "function") {
      return callback(locality);
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
      var error3, l, len, mainResult, part, ref, tmp, type;
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
        for (l = 0, len = ref.length; l < len; l++) {
          part = ref[l];
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
      var error3, l, len, mainResult, part, ref, status, tmp, type;
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
        for (l = 0, len = ref.length; l < len; l++) {
          part = ref[l];
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
  return geocoder.geocode(request, function(result, status) {
    var east, googleBounds, l, len, locality, mustContain, ne, north, south, sw, tooEast, tooNorth, tooSouth, tooWest, validView, view, west;
    if (status === google.maps.GeocoderStatus.OK) {
      console.info("Google said:", result);
      mustContain = geo.getBoundingRectangle(boundingBox);
      validView = null;
      for (l = 0, len = result.length; l < len; l++) {
        view = result[l];
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
      if (typeof callback === "function") {
        return callback(locality);
      } else {
        return console.warn("No callback provided to geo.reverseGeocode()!");
      }
    }
  });
};

toggleGoogleMapMarkers = function(diseaseStatus, selector, callback) {
  var l, len, marker, markers, state;
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
  for (l = 0, len = markers.length; l < len; l++) {
    marker = markers[l];
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
  html = "<div class=\"row\">\n  <h3 class=\"col-xs-12\">\n    Toggle map markers\n  </h3>\n  <button class=\"btn btn-danger col-xs-3 toggle-marker\" data-disease-status=\"positive\">Positive</button>\n  <button class=\"btn btn-primary col-xs-3 toggle-marker\" data-disease-status=\"negative\">Negative</button>\n  <button class=\"btn btn-warning col-xs-3 toggle-marker\" data-disease-status=\"no_confidence\">Inconclusive</button>\n</div>";
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
  var error2, error3, gmm, gmmReal, l, len, len1, ll, llObj, m, marker, point, points, test;
  try {
    test = googleMapsMarkersArray[0];
    ll = test.getPosition();
  } catch (error2) {
    gmmReal = new Array();
    for (l = 0, len = googleMapsMarkersArray.length; l < len; l++) {
      point = googleMapsMarkersArray[l];
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
    googleMapsMarkersArray = gmmReal;
  }
  points = new Array();
  for (m = 0, len1 = googleMapsMarkersArray.length; m < len1; m++) {
    marker = googleMapsMarkersArray[m];
    points.push(marker.getPosition());
  }
  points.sort(sortPointY);
  points.sort(sortPointX);
  return getConvexHullConfig(points);
};

sortPointX = function(a, b) {
  return a.lng() - b.lng();
};

sortPointY = function(a, b) {
  return a.lat() - b.lat();
};

getConvexHullPoints = function(points) {
  var hullPoints, l, len, pObj, point, realHull;
  hullPoints = new Array();
  chainHull_2D(points, points.length, hullPoints);
  realHull = new Array();
  for (l = 0, len = hullPoints.length; l < len; l++) {
    point = hullPoints[l];
    pObj = new Point(point.lat(), point.lng());
    realHull.push(pObj);
  }
  console.info("Got hull from " + points.length + " points:", realHull);
  return realHull;
};

getConvexHullConfig = function(points, map) {
  var hullPoints, polygonConfig;
  if (map == null) {
    map = geo.googleMap;
  }
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

function sortPointX(a, b) {
    return a.lng() - b.lng();
}
function sortPointY(a, b) {
    return a.lat() - b.lat();
}

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
  if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) == null) {
    return loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey);
  }
});


/*
 *
 */

enableDebugLogging = function() {

  /*
   * Overwrite console logs with custom events
   */
  var error2, html, logHistory;
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
  $("#debug-reporter").click(function() {
    return reportDebugLog();
  });
  window.debugLoggingEnabled = true;
  try {
    p$(".debug-enable-context").disabled = true;
  } catch (undefined) {}
  return false;
};

backupDebugLog = function(suppressMessage) {
  var error2, logHistory;
  if (suppressMessage == null) {
    suppressMessage = false;
  }
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
  if ((typeof localStorage !== "undefined" && localStorage !== null ? localStorage.debugLog : void 0) != null) {
    delete localStorage.debugLog;
    delete _debug;
  }
  if (typeof window.sysLog === "function") {
    console.log = sysLog;
    console.info = sysInfo;
    console.warn = sysWarn;
    console.error = sysError;
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
  var html;
  if (window._debug != null) {
    backupDebugLog();
    console.info("Opening debug reporter");
    html = "<paper-dialog modal id=\"report-bug-modal\">\n  <h2>Bug Report</h2>\n  <paper-dialog-scrollable>\n    <div>\n      <p>Copy the text below</p>\n      <textarea readonly rows=\"10\" class=\"form-control\">\n        " + localStorage.debugLog + "\n      </textarea>\n      <br/><br/>\n      <p>And email it to <a href=\"mailto:support@velociraptorsystems.com?subject=Debug%20Log\">support@velociraptorsystems.com</a></p>\n    </div>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog-modal>";
    $("#report-bug-modal").remove();
    $("body").append(html);
    safariDialogHelper("#report-bug-modal");
  }
  return false;
};

window.reportDebugLog = reportDebugLog;

$(function() {
  var setupContext;
  window.debugLoggingEnabled = false;
  (setupContext = function() {
    var ref;
    if (!(typeof Polymer !== "undefined" && Polymer !== null ? (ref = Polymer.RenderStatus) != null ? ref._ready : void 0 : void 0)) {
      console.warn("Delaying context until Polymer.RenderStatus is ready");
      delay(500, function() {
        return setupContext();
      });
      return false;
    }
    console.info("Setting up context events");
    return $("footer paper-icon-button[icon='icons:bug-report']").contextmenu(function(event) {
      var html, inFn, outFn;
      event.preventDefault();
      console.info("Showing bug report context menu");
      html = "<paper-material class=\"bug-report-context-wrapper\" style=\"top:" + event.pageY + "px;left:" + event.pageX + "px;position:absolute\">\n  <paper-menu class=context-menu\">\n    <paper-item class=\"debug-enable-context\" data-fn=\"enableDebugLogging\">\n      Enable debug reporting\n    </paper-item>\n    <paper-item class=\"debug-disable-context\" data-fn=\"disableDebugLogging\">\n      Disable debug reporting\n    </paper-item>\n  </paper-menu>\n</paper-material>";
      $(".bug-report-context-wrapper").remove();
      $("body").append(html);
      inFn = function(el) {
        $(this).addClass("iron-selected");
        return false;
      };
      outFn = function(el) {
        $(this).removeClass("iron-selected");
        return false;
      };
      $(".bug-report-context-wrapper paper-item").hover(inFn, outFn).click(function() {
        var fn;
        fn = $(this).attr("data-fn");
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
    });
  })();
  if ((typeof localStorage !== "undefined" && localStorage !== null ? localStorage.debugLog : void 0) != null) {
    return enableDebugLogging();
  }
});

//# sourceMappingURL=maps/c.js.map
