var Point, activityIndicatorOff, activityIndicatorOn, adData, animateHoverShadows, animateLoad, bindClicks, bindDismissalRemoval, bsAlert, byteCount, cartoAccount, cartoMap, cartoVis, checkFileVersion, cleanupToasts, createMap, d$, deEscape, decode64, deepJQuery, defaultMapMouseOverBehaviour, delay, doCORSget, e, encode64, fPoint, foo, formatScientificNames, gMapsApiKey, getConvexHull, getConvexHullConfig, getConvexHullPoints, getLocation, getMapCenter, getMapZoom, getMaxZ, getPosterFromSrc, goTo, isBlank, isBool, isEmpty, isHovered, isJson, isNull, isNumber, jsonTo64, lightboxImages, loadJS, mapNewWindows, openLink, openTab, overlayOff, overlayOn, p$, post64, prepURI, randomInt, roundNumber, roundNumberSigfig, safariDialogHelper, sortPointX, sortPointY, sortPoints, startLoad, stopLoad, stopLoadError, toFloat, toInt, toObject, toastStatusMessage, uri,
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

try {
  uri = new Object();
  uri.o = $.url();
  uri.urlString = uri.o.attr('protocol') + '://' + uri.o.attr('host') + uri.o.attr("directory");
  uri.query = uri.o.attr("fragment");
} catch (_error) {
  e = _error;
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
  } catch (_error) {
    e = _error;
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
  try {
    if (isEmpty(str) || isBlank(str) || (str == null)) {
      if (!(str === false || str === 0)) {
        return true;
      }
    }
  } catch (_error) {
    e = _error;
    return false;
  }
  return false;
};

isJson = function(str) {
  if (typeof str === 'object') {
    return true;
  }
  try {
    JSON.parse(str);
    return true;
  } catch (_error) {
    e = _error;
    return false;
  }
  return false;
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
  if (!isNumber(str) || isNull(str)) {
    return 0;
  }
  return parseInt(str);
};

String.prototype.toBool = function() {
  return this.toString().toLowerCase() === 'true' || this.toString() === "1";
};

Boolean.prototype.toBool = function() {
  return this.toString() === 'true';
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
  var res;
  try {
    res = _.find(this, function(val) {
      return _.isEqual(obj, val);
    });
    return typeof res === "object";
  } catch (_error) {
    e = _error;
    console.error("Please load underscore.js before using this.");
    return console.info("https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js");
  }
};

Object.toArray = function(obj) {
  return Object.keys(obj).map((function(_this) {
    return function(key) {
      return obj[key];
    };
  })(this));
};

Object.size = function(obj) {
  var key, size;
  if (typeof obj !== "object") {
    try {
      return obj.length;
    } catch (_error) {
      e = _error;
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

deEscape = function(string) {
  string = string.replace(/\&quot;/mg, '"');
  string = string.replace(/\&quote;/mg, '"');
  string = string.replace(/\&#95;/mg, '_');
  string = string.replace(/\&#39;/mg, "'");
  string = string.replace(/\&#34;/mg, '"');
  return string;
};

jsonTo64 = function(obj) {
  var objString;
  if (typeof obj === "array") {
    obj = toObject(arr);
  }
  objString = JSON.stringify(obj);
  return encodeURIComponent(encode64(objString));
};

encode64 = function(string) {
  try {
    return Base64.encode(string);
  } catch (_error) {
    e = _error;
    console.warn("Bad encode string provided");
    return string;
  }
};

decode64 = function(string) {
  try {
    return Base64.decode(string);
  } catch (_error) {
    e = _error;
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
  var attr, itemSelector, val;
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
      } catch (_error) {
        e = _error;
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
    } catch (_error) {
      e = _error;
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
  var errorFunction, onLoadFunction, s;
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
      } catch (_error) {
        e = _error;
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
    var state;
    state = s.readyState;
    try {
      if (!callback.done && (!state || /loaded|complete/.test(state))) {
        callback.done = true;
        if (typeof callback === "function") {
          try {
            return callback();
          } catch (_error) {
            e = _error;
            console.error("Postload callback error for " + src + " - " + e.message);
            return console.warn(e.stack);
          }
        }
      }
    } catch (_error) {
      e = _error;
      return console.error("Onload error - " + e.message);
    }
  };
  errorFunction = function() {
    console.warn("There may have been a problem loading " + src);
    try {
      if (!callback.done) {
        callback.done = true;
        if (typeof callback === "function" && doCallbackOnError) {
          try {
            return callback();
          } catch (_error) {
            e = _error;
            return console.error("Post error callback error - " + e.message);
          }
        }
      }
    } catch (_error) {
      e = _error;
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
  var args, delayed, execAsap, func, threshold, timeout;
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
    } catch (_error) {
      e = _error;
    }
  } else if (execAsap) {
    func.apply(obj, args);
    console.log("Executed immediately");
  }
  return setTimeout(delayed, threshold);
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

animateLoad = function(elId) {
  var selector;
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
  } catch (_error) {
    e = _error;
    return console.log('Could not animate loader', e.message);
  }
};

startLoad = animateLoad;

stopLoad = function(elId, fadeOut) {
  var selector;
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
  } catch (_error) {
    e = _error;
    return console.log('Could not stop load animation', e.message);
  }
};

stopLoadError = function(message, elId, fadeOut) {
  var selector;
  if (elId == null) {
    elId = "loader";
  }
  if (fadeOut == null) {
    fadeOut = 5000;
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
  } catch (_error) {
    e = _error;
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
  $(selector).get(0).show();
  return delay(duration + 500, function() {
    $(selector).empty();
    $(selector).removeClass(className);
    $(selector).attr("text", "");
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
    } catch (_error) {}
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
  try {
    if (!$("html /deep/ " + selector).exists()) {
      throw "Bad /deep/ selector";
    }
    return $("html /deep/ " + selector);
  } catch (_error) {
    e = _error;
    try {
      if (!$("html >>> " + selector).exists()) {
        throw "Bad >>> selector";
      }
      return $("html >>> " + selector);
    } catch (_error) {
      e = _error;
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
    var callable, url;
    try {
      url = $(this).attr("data-href");
      if (!isNull(url)) {
        $(this).unbind();
        try {
          if (url === uri.o.attr("path") && $(this).prop("tagName").toLowerCase() === "paper-tab") {
            $(this).parent().prop("selected", $(this).index());
          }
        } catch (_error) {
          e = _error;
          console.warn("tagname lower case error");
        }
        $(this).click(function() {
          var ref, ref1, ref2;
          try {
            if (((ref = $(this).attr("newTab")) != null ? ref.toBool() : void 0) || ((ref1 = $(this).attr("newtab")) != null ? ref1.toBool() : void 0) || ((ref2 = $(this).attr("data-newtab")) != null ? ref2.toBool() : void 0)) {
              return openTab(url);
            } else {
              return goTo(url);
            }
          } catch (_error) {
            return goTo(url);
          }
        });
        return url;
      } else {
        callable = $(this).attr("data-function");
        if (callable != null) {
          $(this).unbind();
          return $(this).click(function() {
            try {
              console.log("Executing bound function " + callable + "()");
              return window[callable]();
            } catch (_error) {
              e = _error;
              return console.error("'" + callable + "()' is a bad function - " + e.message);
            }
          });
        }
      }
    } catch (_error) {
      e = _error;
      return console.error("There was a problem binding to #" + ($(this).attr("id")) + " - " + e.message);
    }
  });
  return false;
};

getPosterFromSrc = function(srcString) {

  /*
   * Take the "src" attribute of a video and get the
   * "png" screencap from it, and return the value.
   */
  var dummy, split;
  try {
    split = srcString.split(".");
    dummy = split.pop();
    split.push("png");
    return split.join(".");
  } catch (_error) {
    e = _error;
    return "";
  }
};

doCORSget = function(url, args, callback, callbackFail) {
  var corsFail, createCORSRequest, settings, xhr;
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
  } catch (_error) {
    e = _error;
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
      try {
        e.preventDefault();
        e.stopPropagation();
        $(this).imageLightbox(options).startImageLightbox();
        return console.warn("Event propagation was stopped when clicking on this.");
      } catch (_error) {
        e = _error;
        return console.error("Unable to lightbox this image!");
      }
    }).each(function() {
      var imgUrl, tagHtml;
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
      } catch (_error) {
        e = _error;
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
  var geoFail, geoSuccess;
  if (callback == null) {
    callback = void 0;
  }
  geoSuccess = function(pos, callback) {
    window.locationData.lat = pos.coords.latitude;
    window.locationData.lng = pos.coords.longitude;
    window.locationData.acc = pos.coords.accuracy;
    window.locationData.last = Date.now();
    if (callback != null) {
      callback(window.locationData);
    }
    return false;
  };
  geoFail = function(error, callback) {
    var locationError;
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
    if (callback != null) {
      callback(false);
    }
    return false;
  };
  if (navigator.geolocation) {
    return navigator.geolocation.getCurrentPosition(geoSuccess, geoFail, window.locationData.params);
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
  var delayTimer, newCount;
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
    } catch (_error) {
      e = _error;
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
  try {
    return $$(selector)[0];
  } catch (_error) {
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
  return $(selector + " .alert-message").html(message);
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
  var checkVersion, key, keyExists;
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
  } catch (_error) {
    keyExists = false;
  }
  if (forceNow || (window._adp.lastMod == null) || !keyExists) {
    checkVersion(file, key);
    return true;
  }
  return false;
};

window.checkFileVersion = checkFileVersion;

$(function() {
  bindClicks();
  formatScientificNames();
  lightboxImages();
  animateHoverShadows();
  checkFileVersion();
  try {
    $("body").tooltip({
      selector: "[data-toggle='tooltip']"
    });
  } catch (_error) {
    e = _error;
    console.warn("Tooltips were attempted to be set up, but do not exist");
  }
  try {
    checkAdmin();
    if ((typeof adminParams !== "undefined" && adminParams !== null ? adminParams.loadAdminUi : void 0) === true) {
      return loadJS("js/admin.js", function() {
        console.info("Loaded admin file");
        return loadAdminUi();
      });
    } else {
      return console.info("No admin setup requested");
    }
  } catch (_error) {}
});


/*
 * Do Georeferencing from data
 *
 * Plug into CartoDB via
 * http://docs.cartodb.com/cartodb-platform/cartodb-js.html
 */

uri.domain = uri.o.attr("host").split(".").reverse().pop();

cartoAccount = "tigerhawkvok";

gMapsApiKey = "AIzaSyAZvQMkfFkbqNStlgzNjw1VOWBASd74gq4";

cartoMap = null;

cartoVis = null;

adData = new Object();

window.geo = new Object();

geo.GLOBE_WIDTH_GOOGLE = 256;

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
    getLocation();
  } catch (_error) {}
  cartoDBCSS = "<link rel=\"stylesheet\" href=\"https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/themes/css/cartodb.css\" />";
  $("head").append(cartoDBCSS);
  if (doCallback == null) {
    doCallback = function() {
      createMap(adData.cartoRef);
      return false;
    };
  }
  window.gMapsCallback = function() {
    return loadJS("https://cartodb-libs.global.ssl.fastly.net/cartodb.js/v3/3.15/cartodb.js", doCallback, false);
  };
  return loadJS("https://maps.googleapis.com/maps/api/js?key=" + gMapsApiKey + "&callback=gMapsCallback");
};

getMapCenter = function(bb) {
  var center, centerLat, centerLng, coords, i, k, totalLat, totalLng;
  if (bb != null) {
    i = 0;
    totalLat = 0.0;
    for (k in bb) {
      coords = bb[k];
      ++i;
      totalLat += coords[0];
    }
    centerLat = toFloat(totalLat) / toFloat(i);
    i = 0;
    totalLng = 0.0;
    for (k in bb) {
      coords = bb[k];
      ++i;
      totalLng += coords[1];
    }
    centerLng = toFloat(totalLng) / toFloat(i);
    centerLat = toFloat(centerLat);
    centerLng = toFloat(centerLng);
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
  return center;
};

getMapZoom = function(bb, selector) {
  var adjAngle, angle, coords, eastMost, k, lng, mapScale, mapWidth, oz, ref, westMost, zo, zoomCalc;
  if (selector == null) {
    selector = geo.mapSelector;
  }

  /*
   * Get the zoom factor for Google Maps
   */
  if (bb != null) {
    eastMost = -180;
    westMost = 180;
    for (k in bb) {
      coords = bb[k];
      lng = coords.lng != null ? coords.lng : coords[1];
      if (lng < westMost) {
        westMost = lng;
      }
      if (lng > eastMost) {
        eastMost = lng;
      }
    }
    angle = eastMost - westMost;
    if (angle < 0) {
      angle += 360;
    }
    mapWidth = (ref = $(selector).width()) != null ? ref : 650;
    adjAngle = 360 / angle;
    mapScale = adjAngle / geo.GLOBE_WIDTH_GOOGLE;
    zoomCalc = toInt(Math.log(mapWidth * mapScale) / Math.LN2);
    oz = zoomCalc;
    --zoomCalc;
    zo = zoomCalc;
    if (zoomCalc < 1) {
      zoomCalc = 7;
    }
  } else {
    zoomCalc = 7;
  }
  return zoomCalc;
};

geo.getMapZoom = getMapZoom;

defaultMapMouseOverBehaviour = function(e, latlng, pos, data, layerNumber) {
  return console.log(e, latlng, pos, data, layerNumber);
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
   */
  if (dataVisIdentifier == null) {
    console.info("Can't create map without a data visualization identifier");
  }
  geo.mapId = targetId;
  geo.mapSelector = "#" + targetId;
  postConfig = function() {
    var fakeDiv, forceCallback, gMapCallback, googleMapOptions;
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
      fakeDiv = "<div id=\"" + targetId + "\" class=\"carto-map wide-map\">\n  <!-- Dynamically inserted from unavailable target -->\n</div>";
      $("main #main-body").append(fakeDiv);
    }
    if (typeof callback !== "function") {
      callback = function(layer, cartoMap) {
        return cartodb.createLayer(cartoMap, dataVisUrl).addTo(cartoMap).done(function(layer) {
          geo.mapLayer = layer;
          try {
            layer.setInteraction(true);
            return layer.on("featureOver", defaultMapMouseOverBehaviour);
          } catch (_error) {
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
    } catch (_error) {
      console.warn("The map threw an error! " + e.message);
      console.wan(e.stack);
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
  } catch (_error) {}
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
    var alt, apiPostSqlQuery, bb_east, bb_north, bb_south, bb_west, column, columnDatatype, columnNamesList, coordinate, coordinatePair, dataGeometry, dataObject, defaultPolygon, doStillWorking, e2, err, estimate, geoJson, geoJsonGeom, geoJsonVal, i, iIndex, insertMaxLength, insertPlace, l, lat, lats, len, len1, ll, lng, lngs, m, max, n, postTimeStart, ref, ref1, ref2, ref3, row, sampleLatLngArray, sqlQuery, story, tempList, transectPolygon, updateUploadProgress, userTransectRing, value, valuesArr, valuesList, workingIter;
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
        for (l = 0, len = userTransectRing.length; l < len; l++) {
          coordinatePair = userTransectRing[l];
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
        }
      } catch (_error) {
        e = _error;
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
          valuesList = "";
          dataObject = {
            the_geom: dataGeometry
          };
          valuesList = new Array();
          columnNamesList = new Array();
          columnNamesList.push("id int");
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
              } catch (_error) {}
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
      apiPostSqlQuery = encodeURIComponent(encode64(sqlQuery));
      args = "action=upload&sql_query=" + apiPostSqlQuery;
      console.info("Querying:");
      console.info(sqlQuery);
      console.info("GeoJSON:", geoJson);
      console.info("GeoJSON String:", dataGeometry);
      console.info("POSTing to server");
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
        estimate = toInt(.7 * valuesList.length);
        console.log("Estimate " + estimate + " seconds");
        window._adp.uploader = true;
        $("#data-sync").removeAttr("indeterminate");
        max = estimate * 30;
        p$("#data-sync").max = max;
        (updateUploadProgress = function(prog) {
          p$("#data-sync").value = prog;
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
      } catch (_error) {
        e = _error;
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
        } catch (_error) {
          e2 = _error;
          console.error("Can't show backup upload notices! " + e2.message);
          console.warn(e2.stack);
        }
      }
      return $.post("api.php", args, "json").done(function(result) {
        var cartoHasError, cartoResults, dataBlobUrl, dataVisUrl, error, j, parentCallback, prettyHtml, response;
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
        }
        if (cartoHasError !== false) {
          bsAlert("Error uploading your data: " + cartoHasError, "danger");
          stopLoadError("CartoDB returned an error: " + cartoHasError);
          return false;
        }
        console.info("Carto was successful! Got results", cartoResults);
        try {
          prettyHtml = JsonHuman.format(cartoResults);
        } catch (_error) {}
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
        parentCallback = function() {
          console.info("Initiating parent callback");
          stopLoad();
          max = p$("#data-sync").max;
          p$("#data-sync").value = max;
          if (typeof callback === "function") {
            return callback(geo.dataTable);
          } else {
            return console.info("requestCartoUpload recieved no callback");
          }
        };
        if (!isNull(cartoMap)) {
          console.info("Creating map");
          return cartodb.createLayer(cartoMap, dataVisUrl).addTo(cartoMap).done(function(layer) {
            console.info("Map created");
            layer.setInteraction(true);
            layer.on("featureOver", defaultMapMouseOverBehaviour);
            return parentCallback();
          });
        } else {
          return geo.init(function() {
            var center, options;
            console.info("Post init");
            center = getMapCenter(geo.boundingBox);
            options = {
              cartodb_logo: false,
              https: true,
              mobile_layout: true,
              gmaps_base_type: "hybrid",
              center_lat: center.lat,
              center_lon: center.lng,
              zoom: getMapZoom(geo.boundingBox)
            };
            createMap(dataVisUrl, void 0, options, function() {
              console.info("createMap callback successful");
              return parentCallback();
            });
            return false;
          });
        }
      }).error(function(result, status) {
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
        } catch (_error) {}
      });
    } else {
      console.error("Unable to authenticate session. Please log in.");
      return stopLoadError("Sorry, your session has expired. Please log in and try again.");
    }
  }).error(function(result, status) {
    console.error("Couldn't communicate with server!", result, status);
    console.warn("" + uri.urlString + adminParams.apiTarget + "?" + args);
    stopLoadError("There was a problem communicating with the server. Please try again in a bit. (E-001)");
    return $("#upload-data").removeAttr("disabled");
  });
  return false;
};

sortPoints = function(pointArray, asObj) {
  var coordPoint, l, len, pointFunc, sortedPoints;
  if (asObj == null) {
    asObj = true;
  }

  /*
   * Take an array of points and return a Google Maps compatible array
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
      pointFunc = new Object();
      pointFunc.lat = function() {
        return coordPoint.lat;
      };
      pointFunc.lng = function() {
        return coordPoint.lng;
      };
      sortedPoints.push(pointFunc);
    }
  }
  delete window.upper;
  return sortedPoints;
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
  this.x = (lng + 180) * 360;
  this.y = (lat + 90) * 180;
  this.lat = lat;
  this.lng = lng;
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
    return "(" + this.x + ", " + this.y + ")";
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
    if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) != null) {
      return new google.maps.LatLng(this.lat, this.lng);
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
  var boundingBox, coordinates, eastMost, l, lat, len, lng, northMost, southMost, westMost;
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
    lat = coordinates[0];
    lng = coordinates[1];
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
  return boundingBox;
};

geo.reverseGeocode = function(lat, lng, boundingBox, callback) {
  var geocoder, ll, request;
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
  } catch (_error) {
    e = _error;
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
    var east, googleBounds, l, len, locality, mustContain, north, south, tooEast, tooNorth, tooSouth, tooWest, validView, view, west;
    if (status === google.maps.GeocoderStatus.OK) {
      console.info("Google said:", result);
      mustContain = geo.getBoundingRectangle(boundingBox);
      validView = null;
      for (l = 0, len = result.length; l < len; l++) {
        view = result[l];
        validView = view;
        googleBounds = view.geometry.bounds;
        north = googleBounds.R.j;
        south = googleBounds.R.R;
        east = googleBounds.j.R;
        west = googleBounds.j.j;
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


/*
 * Minimum Convex Hull
 * view-source:http://www.geocodezip.com/v3_map-markers_ConvexHull.asp
 */

getConvexHull = function(googleMapsMarkersArray) {
  var l, len, marker, points;
  points = new Array();
  for (l = 0, len = googleMapsMarkersArray.length; l < len; l++) {
    marker = googleMapsMarkersArray[l];
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
  var hullPoints, l, len, point, realHull, temp;
  hullPoints = new Array();
  chainHull_2D(points, points.length, hullPoints);
  realHull = new Array();
  for (l = 0, len = hullPoints.length; l < len; l++) {
    point = hullPoints[l];
    temp = {
      lat: point.lat(),
      lng: point.lng()
    };
    realHull.push(temp);
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
    fillColor: "#ff7800",
    fillOpacity: 0.35,
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

     function sortPointX(a,b) { return a.lng() - b.lng(); }
     function sortPointY(a,b) { return a.lat() - b.lat(); }

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

$(function() {});

//# sourceMappingURL=maps/c.js.map
