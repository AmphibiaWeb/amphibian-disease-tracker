(function() {
  var activityIndicatorOff, activityIndicatorOn, addAlternateEmail, animateLoad, apiUri, base, base1, beginChangePassword, bsAlert, byteCount, checkMatchPassword, checkPasswordLive, delay, doAsyncCreate, doAsyncLogin, doEmailCheck, doRemoveAccountAction, doTOTPRemove, doTOTPSubmit, evalRequirements, finishChangePassword, finishPasswordResetHandler, giveAltVerificationOptions, isBlank, isBool, isEmpty, isJson, isNull, isNumber, lightboxImages, loadJS, makeTOTP, mapNewWindows, noSubmit, overlayOff, overlayOn, popupSecret, removeAccount, resetPassword, root, roundNumber, saveTOTP, showAdvancedOptions, showInstructions, stopLoad, stopLoadError, toFloat, toInt, toastStatusMessage, toggleNewUserSubmit, verifyEmail, verifyPhone,
    slice = [].slice,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  isBool = function(str) {
    return str === true || str === false;
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

  function toObject(arr) {
    var rv = {};
    for (var i = 0; i < arr.length; ++i)
        if (arr[i] !== undefined) rv[i] = arr[i];
    return rv;
};

  String.prototype.toBool = function() {
    return this.toString() === 'true';
  };

  Boolean.prototype.toBool = function() {
    return this.toString() === 'true';
  };

  Object.size = function(obj) {
    var key, size;
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

  jQuery.fn.exists = function() {
    return jQuery(this).length > 0;
  };

  jQuery.fn.isVisible = function() {
    return jQuery(this).css("display") !== "none";
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

  window.debounce_timer = null;

  ({
    debounce: function(func, threshold, execAsap) {
      if (threshold == null) {
        threshold = 300;
      }
      if (execAsap == null) {
        execAsap = false;
      }
      return function() {
        var args, delayed, obj;
        args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        obj = this;
        delayed = function() {
          if (!execAsap) {
            return func.apply(obj, args);
          }
        };
        if (window.debounce_timer != null) {
          clearTimeout(window.debounce_timer);
        } else if (execAsap) {
          func.apply(obj, args);
        }
        return window.debounce_timer = setTimeout(delayed, threshold);
      };
    }
  });

  Function.prototype.debounce = function() {
    var args, delayed, e, execAsap, func, threshold, timeout;
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
    return window.debounce_timer = setTimeout(delayed, threshold);
  };

  loadJS = function(src, callback, doCallbackOnError) {
    var e, errorFunction, onLoadFunction, s;
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
     * @param bool|func doCallbackOnError Should the callback be executed if
     *                                    loading the script produces an error?
     *                                    If function, do it.
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
              return console.error("Postload callback error - " + e.message);
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
          if (typeof callback === "function" && doCallbackOnError === true) {
            try {
              callback();
            } catch (_error) {
              e = _error;
              console.error("Post error callback error - " + e.message);
              console.warn(e.stack);
            }
          }
        }
        if (typeof doCallbackOnError === "function") {
          try {
            return doCallbackOnError();
          } catch (_error) {
            e = _error;
            return console.error("Couldn't run post-error function - " + e.message);
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

  mapNewWindows = function() {
    return $(".newwindow").each(function() {
      var curHref, openInNewWindow;
      curHref = $(this).attr("href");
      openInNewWindow = function(url) {
        if (url == null) {
          return false;
        }
        window.open(url);
        return false;
      };
      $(this).click(function() {
        return openInNewWindow(curHref);
      });
      return $(this).keypress(function() {
        return openInNewWindow(curHref);
      });
    });
  };

  if ((typeof _metaStatus !== "undefined" && _metaStatus !== null ? _metaStatus.isLoading : void 0) == null) {
    if (typeof _metaStatus === "undefined" || _metaStatus === null) {
      window._metaStatus = new Object();
    }
    _metaStatus.isLoading = false;
  }

  animateLoad = function(elId, iteration) {
    var e, ref, selector;
    if (elId == null) {
      elId = "loader";
    }
    if (iteration == null) {
      iteration = 0;
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

    /*
     * This is there for Edge, which sometimes leaves an element
     * We declare this early because Polymer tries to be smart and not
     * actually activate when it's hidden. Thus, this is a prerequisite
     * to actually re-showing it once hidden.
     */
    $(selector).removeAttr("hidden");
    if (((ref = window._metaStatus) != null ? ref.isLoading : void 0) == null) {
      if (window._metaStatus == null) {
        window._metaStatus = new Object();
      }
      window._metaStatus.isLoading = false;
    }
    try {
      if (window._metaStatus.isLoading) {
        if (iteration < 100) {
          iteration++;
          delay(100, function() {
            return animateLoad(elId, iteration);
          });
          return false;
        } else {
          console.warn("Loader timed out waiting for load completion");
          return false;
        }
      }
      if (!$(selector).exists()) {
        $("body").append("<paper-spinner id=\"" + elId + "\" active></paper-spinner");
      } else {
        $(selector).attr("active", true);
      }
      window._metaStatus.isLoading = true;
      return false;
    } catch (_error) {
      e = _error;
      return console.warn('Could not animate loader', e.message);
    }
  };

  stopLoad = function(elId, fadeOut, iteration) {
    var e, endLoad, selector;
    if (elId == null) {
      elId = "loader";
    }
    if (fadeOut == null) {
      fadeOut = 1000;
    }
    if (iteration == null) {
      iteration = 0;
    }
    if (elId.slice(0, 1) === "#") {
      selector = elId;
      elId = elId.slice(1);
    } else {
      selector = "#" + elId;
    }
    try {
      if (!_metaStatus.isLoading) {
        if (iteration < 100) {
          iteration++;
          delay(100, function() {
            return stopLoad(elId, fadeOut, iteration);
          });
          return false;
        } else {
          return false;
        }
      }
      if ($(selector).exists()) {
        $(selector).addClass("good");
        (endLoad = function() {
          return delay(fadeOut, function() {
            $(selector).removeClass("good").attr("active", false).removeAttr("active");
            return delay(1, function() {
              var aliases, ref;
              $(selector).prop("hidden", true);

              /*
               * Now, the slower part.
               * Edge does weirdness with active being toggled off, but
               * everyone else should have hidden removed so animateLoad()
               * behaves well. So, we check our browser sniffing.
               */
              if ((typeof Browsers !== "undefined" && Browsers !== null ? Browsers.browser : void 0) != null) {
                aliases = ["Spartan", "Project Spartan", "Edge", "Microsoft Edge", "MS Edge"];
                if ((ref = Browsers.browser.browser.name, indexOf.call(aliases, ref) >= 0) || Browsers.browser.engine.name === "EdgeHTML") {
                  $(selector).remove();
                  return _metaStatus.isLoading = false;
                } else {
                  $(selector).removeAttr("hidden");
                  return delay(50, function() {
                    return _metaStatus.isLoading = false;
                  });
                }
              } else {
                $(selector).removeAttr("hidden");
                return delay(50, function() {
                  return _metaStatus.isLoading = false;
                });
              }
            });
          });
        })();
      }
      return false;
    } catch (_error) {
      e = _error;
      return console.warn('Could not stop load animation', e.message);
    }
  };

  stopLoadError = function(message, elId, fadeOut, iteration) {
    var e, endLoad, selector;
    if (elId == null) {
      elId = "loader";
    }
    if (fadeOut == null) {
      fadeOut = 7500;
    }
    if (elId.slice(0, 1) === "#") {
      selector = elId;
      elId = elId.slice(1);
    } else {
      selector = "#" + elId;
    }
    try {
      if (!_metaStatus.isLoading) {
        if (iteration < 100) {
          iteration++;
          delay(100, function() {
            return stopLoadError(message, elId, fadeOut, iteration);
          });
          return false;
        } else {
          return false;
        }
      }
      if ($(selector).exists()) {
        $(selector).addClass("bad");
        try {
          if (message != null) {
            toastStatusMessage(message, "", fadeOut);
          }
        } catch (_error) {}
        (endLoad = function() {
          return delay(fadeOut, function() {
            $(selector).removeClass("bad").prop("active", false).removeAttr("active");
            return delay(1, function() {
              var aliases, ref;
              $(selector).prop("hidden", true);

              /*
               * Now, the slower part.
               * Edge does weirdness with active being toggled off, but
               * everyone else should have hidden removed so animateLoad()
               * behaves well. So, we check our browser sniffing.
               */
              if ((typeof Browsers !== "undefined" && Browsers !== null ? Browsers.browser : void 0) != null) {
                aliases = ["Spartan", "Project Spartan", "Edge", "Microsoft Edge", "MS Edge"];
                if ((ref = Browsers.browser.browser.name, indexOf.call(aliases, ref) >= 0) || Browsers.browser.engine.name === "EdgeHTML") {
                  $(selector).remove();
                  return _metaStatus.isLoading = false;
                } else {
                  $(selector).removeAttr("hidden");
                  return delay(50, function() {
                    return _metaStatus.isLoading = false;
                  });
                }
              } else {
                $(selector).removeAttr("hidden");
                return delay(50, function() {
                  return _metaStatus.isLoading = false;
                });
              }
            });
          });
        })();
      }
      return false;
    } catch (_error) {
      e = _error;
      return console.warn('Could not stop load error animation', e.message);
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

  if (typeof toastStatusMessage === "undefined" || toastStatusMessage === null) {
    toastStatusMessage = bsAlert;
  }

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
    return loadJS(window.totpParams.relative + "bower_components/imagelightbox/dist/imagelightbox.min.js", function() {
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
        var e, imgUrl, tagHtml;
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

  $(function() {
    var base, base1, e;
    try {
      lightboxImages();
    } catch (_error) {
      e = _error;
      console.warn("Couldn't lightbox images! " + e.message);
      console.warn(e.stack);
    }
    try {
      if (typeof picturefill === "function") {
        window.picturefill();
      }
    } catch (_error) {
      e = _error;
      console.warn("Could not execute picturefill.");
    }
    mapNewWindows();
    try {
      if ((base = window.totpParams).tfaLock == null) {
        base.tfaLock = false;
      }
      if (window.latejs == null) {
        window.latejs = new Object();
      }
      if ((base1 = window.latejs).done == null) {
        base1.done = false;
      }
      if (window.latejs.done !== true && window.totpParams.tfaLock !== true) {
        if (typeof lateJS === "function") {
          lateJS();
        }
      }
    } catch (_error) {
      e = _error;
      console.warn("There was an error calling lateJS(). If you haven't set that up, you can safely ignore this.");
    }
    try {
      if (typeof loadLast === "function") {
        return loadLast();
      }
    } catch (_error) {
      e = _error;
      return console.warn("There was an error calling loadLast(). This may result in unexpected behaviour.");
    }
  });

  if (typeof apiUri !== "object") {
    apiUri = new Object();
  }

  try {
    apiUri.o = $.url();
  } catch (_error) {
    if ((typeof uri !== "undefined" && uri !== null ? uri.o : void 0) != null) {
      apiUri.o = uri.o;
    } else {
      console.warn("The PURL library may be improperly loaded!");
    }
  }

  apiUri.urlString = window.location.origin + "/" + totpParams.subdirectory;

  apiUri.query = apiUri.o.attr("fragment");

  apiUri.targetApi = "async_login_handler.php";

  apiUri.apiTarget = apiUri.urlString + apiUri.targetApi;

  if (typeof window.passwords !== 'object') {
    window.passwords = new Object();
  }

  window.passwords.goodbg = "#cae682";

  window.passwords.badbg = "#e5786d";

  if ((base = window.passwords).minLength == null) {
    base.minLength = 8;
  }

  if ((base1 = window.passwords).overrideLength == null) {
    base1.overrideLength = 20;
  }

  if (typeof window.totpParams !== 'object') {
    window.totpParams = new Object();
  }

  window.totpParams.popClass = "pop-panel";

  if (window.totpParams.home == null) {
    window.totpParams.home = apiUri.o.attr('protocol') + '://' + apiUri.o.attr('host') + '/';
  }

  if (window.totpParams.relative == null) {
    window.totpParams.relative = "";
  }

  if (window.totpParams.subdirectory == null) {
    window.totpParams.subdirectory = "";
  }

  window.totpParams.mainStylesheetPath = window.totpParams.relative + "css/otp_styles.css";

  window.totpParams.popStylesheetPath = window.totpParams.relative + "css/otp_panels.css";

  window.totpParams.combinedStylesheetPath = window.totpParams.relative + "css/otp.min.css";

  delete url;

  checkPasswordLive = function(selector, firstPasswordSelector, secondPasswordSelector, requirementsSelector) {
    var pass, re;
    if (selector == null) {
      selector = "#createUser_submit";
    }
    if (firstPasswordSelector == null) {
      firstPasswordSelector = "#password";
    }
    if (secondPasswordSelector == null) {
      secondPasswordSelector = "#password2";
    }
    if (requirementsSelector == null) {
      requirementsSelector = "#password_security";
    }

    /*
     *
     */
    pass = $(firstPasswordSelector).val();
    re = new RegExp("^(?:(?=^.{" + window.passwords.minLength + ",}$)((?=.*\\d)|(?=.*\\W+))(?![.\\n])(?=.*[A-Z])(?=.*[a-z]).*$)$");
    if (pass.length > window.passwords.overrideLength || pass.match(re)) {
      $(firstPasswordSelector).css("background", window.passwords.goodbg).parent().parent().removeClass("has-error").addClass("has-success");
      $("#feedback-status-1").replaceWith("<span id='feedback-status-1' class='glyphicon glyphicon-ok form-control-feedback' aria-hidden='true'></span>");
      window.passwords.basepwgood = true;
    } else {
      $(firstPasswordSelector).css("background", window.passwords.badbg).parent().parent().removeClass("has-success").addClass("has-error");
      $("#feedback-status-1").replaceWith("<span id='feedback-status-1' class='glyphicon glyphicon-remove form-control-feedback' aria-hidden='true'></span>");
      window.passwords.basepwgood = false;
    }
    evalRequirements(requirementsSelector, firstPasswordSelector);
    if (!isNull($(secondPasswordSelector).val())) {
      checkMatchPassword(selector, firstPasswordSelector, secondPasswordSelector);
      toggleNewUserSubmit(selector);
    }
    return false;
  };

  checkMatchPassword = function(selector, firstPasswordSelector, secondPasswordSelector) {
    if (selector == null) {
      selector = "#createUser_submit";
    }
    if (firstPasswordSelector == null) {
      firstPasswordSelector = "#password";
    }
    if (secondPasswordSelector == null) {
      secondPasswordSelector = "#password2";
    }
    if ($(firstPasswordSelector).val() === $(secondPasswordSelector).val()) {
      $(secondPasswordSelector).css('background', window.passwords.goodbg).parent().parent().removeClass("has-error").addClass("has-success");
      $("#feedback-status-2").replaceWith("<span id='feedback-status-2' class='glyphicon glyphicon-ok form-control-feedback' aria-hidden='true'></span>");
      window.passwords.passmatch = true;
    } else {
      $(secondPasswordSelector).css('background', window.passwords.badbg).parent().parent().removeClass("has-success").addClass("has-error");
      $("#feedback-status-2").replaceWith("<span id='feedback-status-2' class='glyphicon glyphicon-remove form-control-feedback' aria-hidden='true'></span>");
      window.passwords.passmatch = false;
    }
    toggleNewUserSubmit(selector);
    return false;
  };

  toggleNewUserSubmit = function(selector) {
    var dbool, e;
    if (selector == null) {
      selector = "#createUser_submit";
    }
    try {
      dbool = !(window.passwords.passmatch && window.passwords.basepwgood);
      return $(selector).attr("disabled", dbool);
    } catch (_error) {
      e = _error;
      window.passwords.passmatch = false;
      return window.passwords.basepwgood = false;
    }
  };

  evalRequirements = function(selector, passwordSelector) {
    var green_channel, html, moz_css, new_end, notice, pass, pstrength, red_channel, webkit_css;
    if (selector == null) {
      selector = "#password_security";
    }
    if (passwordSelector == null) {
      passwordSelector = "#password";
    }
    if (!$("#strength-meter").exists()) {
      html = "<h4>Password Requirements</h4><div id='strength-meter'><div id='strength-requirements'><p style='float:left;margin-top:2em;font-weight:700;'>Character Classes:</p><div id='strength-alpha'><p class='label'>a</p><div class='strength-eval'></div></div><div id='strength-alphacap'><p class='label'>A</p><div class='strength-eval'></div></div><div id='strength-numspecial'><p class='label'>1/!</p><div class='strength-eval'></div></div></div><div id='strength-bar'><label for='password-strength'>Strength: </label><progress id='password-strength' max='5'></progress><p>Time to crack: <span id='crack-time'></span></p></div></div>";
      notice = "<br/><br/><p>We require a password of at least " + window.passwords.minLength + " characters with at least one upper case letter, at least one lower case letter, and at least one digit or special character.</p><p>You can also use <a href='http://imgs.xkcd.com/comics/password_strength.png' class='lightboximage'>any long password</a> of at least " + window.passwords.overrideLength + " characters, with no security requirements.</p>";
      $(selector).html(html + notice).removeClass('invisible');
      lightboxImages();
      $("#helpText").removeClass("invisible");
    }
    pass = $(passwordSelector).val();
    pstrength = zxcvbn(pass);
    green_channel = (toInt(pstrength.score) + 1) * 51;
    red_channel = 255 - toInt(Math.pow(pstrength.score, 2) * 16);
    if (red_channel < 0) {
      red_channel = 0;
    }
    new_end = "rgb(" + red_channel + "," + green_channel + ",0)";
    webkit_css = "\nprogress[value]::-webkit-progress-value { background: -webkit-linear-gradient(left,rgb(255,0,30)," + new_end + "), -webkit-linear-gradient(top,rgba(255, 255, 255, .5), rgba(0, 0, 0, .5)); }";
    moz_css = "\nprogress::-moz-progress-bar { background: -moz-linear-gradient(left,rgb(255,0,30)," + new_end + "), -moz-linear-gradient(top,rgba(255, 255, 255, .5), rgba(0, 0, 0, .5)); }";
    if (!$("#dynamic").exists()) {
      $("<style type='text/css' id='dynamic' />").appendTo("head");
    }
    $("#dynamic").text(webkit_css + moz_css);
    $(".strength-eval").css("background", window.passwords.badbg);
    if (pass.length >= window.passwords.overrideLength) {
      $(".strength-eval").css("background", window.passwords.goodbg);
    } else {
      if (pass.match(/^(?:((?=.*\d)|(?=.*\W+)).*$)$/)) {
        $("#strength-numspecial .strength-eval").css("background", window.passwords.goodbg);
      }
      if (pass.match(/^(?=.*[a-z]).*$/)) {
        $("#strength-alpha .strength-eval").css("background", window.passwords.goodbg);
      }
      if (pass.match(/^(?=.*[A-Z]).*$/)) {
        $("#strength-alphacap .strength-eval").css("background", window.passwords.goodbg);
      }
    }
    $("#password-strength").attr("value", pstrength.score + 1);
    return $("#crack-time").text(pstrength.crack_time_display);
  };

  doEmailCheck = function() {};

  doTOTPSubmit = function(home) {
    var ajaxLanding, apiUrlString, args, code, ip, pass, totp, url, user;
    if (home == null) {
      home = window.totpParams.home;
    }
    noSubmit();
    animateLoad();
    $("#verify_totp_button").prop("disabled", true);
    code = $("#totp_code").val();
    user = $("#username").val();
    pass = $("#password").val();
    ip = $("#remote").val();
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    args = "action=verifytotp&code=" + code + "&user=" + user + "&password=" + pass + "&remote=" + ip;
    totp = $.post(apiUrlString, args, 'json');
    totp.done(function(result) {
      var e, i;
      if (result.status === true) {
        try {
          $("#totp_message").text("Correct!").removeClass("alert-danger").addClass("alert alert-success");
          i = 0;
          return $.each(result["cookies"].raw_cookie, function(key, val) {
            var e;
            try {
              $.cookie(key, val, result["cookies"].expires);
            } catch (_error) {
              e = _error;
              console.error("Couldn't set cookies", result["cookies"].raw_cookie);
            }
            i++;
            if (i === Object.size(result["cookies"].raw_cookie)) {
              if (home == null) {
                home = url.attr('protocol') + '://' + url.attr('host') + '/';
              }
              stopLoad();
              return delay(500, function() {
                return window.location.href = home;
              });
            }
          });
        } catch (_error) {
          e = _error;
          return console.error("Unexpected error while validating", e.message);
        }
      } else {
        $("#totp_message").text(result.human_error).addClass("alert alert-danger");
        $("#totp_code").val("");
        $("#totp_code").focus();
        stopLoadError();
        return console.error("Invalid code error", result.error, result);
      }
    });
    totp.fail(function(result, status) {
      $("#totp_message").text("Failed to contact server. Please try again.").addClass("alert alert-danger");
      console.error("AJAX failure", apiUrlString + "?" + args, result, status);
      return stopLoadError();
    });
    totp.always(function() {
      return $("#verify_totp_button").prop("disabled", false);
    });
    return false;
  };

  doTOTPRemove = function() {
    var ajaxLanding, apiUrlString, args, code, pass, remove_totp, url, user;
    noSubmit();
    animateLoad();
    user = $("#username").val();
    pass = encodeURIComponent($("#password").val());
    code = $("#code").val();
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    args = "action=removetotp&code=" + code + "&username=" + user + "&password=" + pass + "&base64=true";
    remove_totp = $.post(apiUrlString, args, 'json');
    remove_totp.done(function(result) {
      if (result.status !== true) {
        $("#totp_message").text(result.human_error).addClass("error");
        console.error(result.error);
        console.warn(apiUrlString + "?" + args);
        console.warn(result);
        stopLoadError();
        return false;
      }
      $("#totp_message").removeClass('error').addClass('good').text("Two-factor authentication removed for " + result.username + ".");
      $("#totp_remove").remove();
      console.log(apiUrlString + "?" + args);
      console.log(result);
      stopLoad();
      return false;
    });
    return remove_totp.fail(function(result, status) {
      $("#totp_message").text("Failed to contact server. Please try again.").addClass("error");
      console.error("AJAX failure", apiUrlString + "?" + args, result, status);
      return stopLoadError();
    });
  };

  makeTOTP = function() {
    var ajaxLanding, apiUrlString, args, hash, key, password, totp, url, user;
    noSubmit();
    animateLoad();
    user = $("#username").val();
    password = $("#password").val();
    hash = $("#hash").val();
    key = $("#secret").val();
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    args = "action=maketotp&password=" + password + "&user=" + user;
    totp = $.post(apiUrlString, args, 'json');
    totp.done(function(result) {
      var barcodeDiv, html, raw, show_alt, show_secret_id, svg;
      if (result.status === true) {
        $("#totp_message").html("To continue, scan this barcode with your smartphone authenticator application. <small><button id='alt_totp_help' class='alert-link btn btn-link'>Don't have the app?</button></small>").removeClass("error alert-danger alert-warning alert-success").addClass("alert-info");
        console.log(result);
        svg = result.svg;
        raw = result.raw;
        show_secret_id = "show_secret";
        show_alt = "showAltBarcode";
        barcodeDiv = "secretBarcode";
        html = "<form id='totp_verify' onsubmit='event.preventDefault();' class='col-xs-12 clearfix'> <p class='text-muted text-center center-block'>If you're unable to scan the barcode below, <button href='#' id='" + show_secret_id + "' class='btn btn-link'>click here to manually input your key.</button></p> <div id='" + barcodeDiv + "' class='text-center center-block'> " + result.svg + " <p class='text-muted text-center center-block'>Don't see the barcode? <a href='#' id='" + show_alt + "' role='button' class='btn btn-link'>Click here</a></p> </div> <p >Once you've scanned the QR code above with your mobile app, enter the code generated by your app in the field below to verify your setup.</p> <fieldset class='form-inline'> <legend>Confirmation</legend> <div class='form-group'> <label for='code' class='sr-only'>Current Code:</label> <input type='number' pattern='[0-9]{6}' size='6' maxlength='6' id='code' name='code' placeholder='Code' class='form-control'/> </div> <input type='hidden' id='username' name='username' value='" + user + "'/> <input type='hidden' id='hash' name='hash' value='" + hash + "'/> <input type='hidden' id='secret' name='secret' value='" + key + "'/> <button id='verify_totp_button' class='totpbutton btn btn-primary'>Verify</button> </fieldset> </form>";
        $("#totp_start").remove();
        $("#totp_message").after(html);
        $("#alt_totp_help").click(function() {
          return showInstructions();
        });
        $("#" + show_secret_id).click(function() {
          return popupSecret(result.human_secret);
        });
        $("#" + show_alt).click(function() {
          var altImg;
          altImg = "<img src='" + result.raw + "' alt='TOTP barcode'/>";
          $("#" + barcodeDiv).html(altImg);
          return $("#" + show_alt).unbind().text("Still don't see it? Click here again to open the image in a new tab.").click(function() {
            openTab(result.url);
            return $("#" + show_alt).remove();
          });
        });
        $("#verify_totp_button").click(function() {
          noSubmit();
          return saveTOTP(key, hash);
        });
        $("#totp_verify").submit(function() {
          noSubmit();
          return saveTOTP(key, hash);
        });
        return stopLoad();
      } else {
        console.error("Couldn't generate TOTP code", apiUrlString + "?" + args);
        console.warn(result);
        $("#totp_message").text("There was an error generating your code. " + result.message).addClass("error");
        return stopLoadError();
      }
    });
    totp.fail(function(result, status) {
      $("#totp_message").text("Failed to contact server. Please try again.").addClass("error");
      console.error("AJAX failure", apiUrlString + "?" + args, result, status);
      return stopLoadError();
    });
    return false;
  };

  saveTOTP = function(key, hash) {
    var ajaxLanding, apiUrlString, args, code, totp, url, user;
    noSubmit();
    animateLoad();
    code = $("#code").val();
    hash = $("#hash").val();
    key = $("#secret").val();
    user = $("#username").val();
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    args = "action=savetotp&secret=" + key + "&user=" + user + "&hash=" + hash + "&code=" + code;
    totp = $.post(apiUrlString, args, 'json');
    totp.done(function(result) {
      var html;
      if (result.status === true) {
        html = "<h1>Done!</h1><h2>Write down and save this backup code. Without it, you cannot disable two-factor authentication if you lose your device.</h2><pre id='backup_code'>" + result.backup + "</pre><br/><button id='to_home'>Home &#187;</a>";
        $("#totp_add").html(html);
        $("#to_home").click(function() {
          return window.location.href = window.totpParams.home;
        });
        return stopLoad();
      } else {
        html = "<p class='error' id='temp_error'>" + result.human_error + "</p>";
        if (!$("#temp_error").exists()) {
          $("#verify_totp_button").after(html);
        } else {
          $("#temp_error").html(html);
        }
        console.error(result.error);
        return stopLoadError();
      }
    });
    return totp.fail(function(result, status) {
      $("#totp_message").text("Failed to contact server. Please try again.");
      console.error("AJAX failure", result, status);
      return stopLoadError();
    });
  };

  popupSecret = function(secret) {
    var html;
    $("<link/>", {
      rel: "stylesheet",
      type: "text/css",
      media: "screen",
      href: window.totpParams.popStylesheetPath
    }).appendTo("head");
    html = "<div id='cover_wrapper'><div id='secret_id_panel' class='" + window.totpParams.popClass + " cover_content'><p class='close-popup'>X</p><h2>" + secret + "</h2></div></div>";
    $("article").after(html);
    $("article").addClass("blur");
    return $(".close-popup").click(function() {
      $("#cover_wrapper").remove();
      return $("article").removeClass("blur");
    });
  };

  giveAltVerificationOptions = function() {
    var ajaxLanding, apiUrlString, args, messages, pane_id, pane_messages, remove_id, sms, sms_id, url, user;
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    user = $("#username").val();
    args = "action=cansms&user=" + user;
    remove_id = "remove_totp_link";
    sms_id = "send_totp_sms";
    pane_id = "alt_auth_pane";
    pane_messages = "alt_auth_messages";
    if ($("#" + pane_id).exists()) {
      $("#" + pane_id).toggle("fast");
      return false;
    }
    messages = new Object();
    messages.remove = "<a href='#' id='" + remove_id + "' role='button' class='btn btn-default'>Remove two-factor authentication</a>";
    sms = $.get(apiUrlString, args, 'json');
    sms.done(function(result) {
      var html, pop_content;
      if (result[0] === true) {
        messages.sms = "<a href='#' id='" + sms_id + "' role='button' class='btn btn-default'>Send SMS</a>";
      } else {
        console.warn("Couldn't get a valid result", result, apiUrlString + "?" + args);
      }
      pop_content = "";
      $.each(messages, function(k, v) {
        return pop_content += v;
      });
      html = "<div id='" + pane_id + "'><p>" + pop_content + "</p><p id='" + pane_messages + "'></p></div>";
      $("#totp_submit").after(html);
      return $("#" + sms_id).click(function() {
        var sms_totp;
        args = "action=sendtotptext&user=" + user;
        sms_totp = $.get(apiUrlString, args, 'json');
        console.log("Sending message ...", apiUrlString + "?" + args);
        sms_totp.done(function(result) {
          if (result.status === true) {
            $("#" + pane_id).remove();
            return $("#totp_message").text(result.message);
          } else {
            $("#" + pane_messages).addClass("error").text(result.human_error);
            return console.error(result.error);
          }
        });
        return sms_totp.fail(function(result, status) {
          console.error("AJAX failure trying to send TOTP text", apiUrlString + "?" + args);
          return console.error("Returns:", result, status);
        });
      });
    });
    sms.fail(function(result, status) {
      return console.error("Could not check SMS-ability", result, status);
    });
    return sms.always(function() {
      return $("#" + remove_id).click(function() {
        var html;
        html = "\n  <p id='totp_message' class='error'>Are you sure you want to disable two-factor authentication?</p>\n  <form id='totp_remove' onsubmit='event.preventDefault();'>\n    <fieldset>\n      <legend>Remove Two-Factor Authentication</legend>\n      <input type='email' value='" + user + "' readonly='readonly' id='username' name='username'/><br/>\n      <input type='password' id='password' name='password' placeholder='Password'/><br/>\n      <input type='text' id='code' name='code' placeholder='Authenticator Code or Backup Code' size='32' maxlength='32' autocomplete='off'/><br/>\n      <button id='remove_totp_button' class='totpbutton btn btn-danger'>Remove Two-Factor Authentication</button>\n    </fieldset>\n  </form>\n";
        $("#totp_prompt").html(html).attr("id", "totp_remove_section");
        $("#totp_remove").submit(function() {
          return doTOTPRemove();
        });
        return $("#remove_totp_button").click(function() {
          return doTOTPRemove();
        });
      });
    });
  };

  verifyPhone = function() {
    var ajaxLanding, apiUrlString, args, auth, url, user, verifyPhoneAjax;
    noSubmit();
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    auth = $("#phone_auth").val() != null ? $("#phone_auth").val() : null;
    user = $("#username").val();
    args = "action=verifyphone&username=" + user + "&auth=" + auth;
    verifyPhoneAjax = $.get(apiUrlString, args, 'json');
    verifyPhoneAjax.done(function(result) {
      var message, setClass;
      if (result.status === false) {
        if (!$("#phone_verify_message").exists()) {
          $("#phone").before("<p id='phone_verify_message'></p>");
        }
        if (result.is_good === true) {
          $("#verify_phone_button").remove();
          message = "You've already verified your phone number, thanks!";
          setClass = "good";
        } else {
          message = result.human_error;
          setClass = "error";
          console.error(result.error);
        }
        $("#phone_verify_message").text(message).addClass(setClass);
        if (result.fatal === true) {
          $("#verify_phone_button").attr("disabled", true);
          $("#verify_phone").unbind('submit').attr("onsubmit", "");
        }
        return false;
      }
      if (result.status === true) {
        if (!$("#phone_auth").exists()) {
          $("#username").after("<br/><input type='text' length='8' name='phone_auth' id='phone_auth' placeholder='Authorization Code'/>");
        }
        if (!$("#phone_verify_message").exists()) {
          $("#phone").before("<p id='phone_verify_message'></p>");
        }
        $("#phone_verify_message").text(result.message);
        if (result.is_good !== true) {
          return $("#verify_phone_button").text("Confirm");
        } else {
          $("#phone_auth").remove();
          $("#verify_later").remove();
          return $("#verify_phone_button").html("Continue &#187; ").unbind('click').click(function() {
            return window.location.href = window.totpParams.home;
          });
        }
      } else {
        console.warn("Unexpected condition encountered verifying the phone number", apiUrlString);
        console.log(result);
        return false;
      }
    });
    return verifyPhoneAjax.fail(function(result, status) {
      console.error("AJAX failure trying to send phone verification text", apiUrlString + "?" + args);
      return console.error("Returns:", result, status);
    });
  };

  showInstructions = function(path) {
    if (path == null) {
      path = "help/instructions_pop.html";
    }
    $("<link/>", {
      rel: "stylesheet",
      type: "text/css",
      media: "screen",
      href: window.totpParams.popStylesheetPath
    }).appendTo("head");
    return $.get("" + window.totpParams.relative + path).done(function(html) {
      var assetPath;
      $("#login_block").after(html);
      $("#login_block").addClass("blur");
      assetPath = window.totpParams.relative + "assets/";
      $(".android").html("<img src='" + assetPath + "playstore.png' alt='Google Play Store'/>");
      $(".ios").html("<img src='" + assetPath + "appstore.png' alt='iOS App Store'/>");
      $(".wp8").html("<img src='" + assetPath + "wpstore.png' alt='Windows Phone Store'/>");
      $(".large_totp_icon").each(function() {
        var newSource;
        newSource = assetPath + $(this).attr("src");
        return $(this).attr("src", newSource);
      });
      $(".app_link_container a").addClass("newwindow");
      mapNewWindows();
      return $(".close-popup").click(function() {
        $("#login_block").removeClass("blur");
        return $("#cover_wrapper").remove();
      });
    }).fail(function(result, status) {
      return console.error("Failed to load instructions @ " + path, result, status);
    });
  };

  showAdvancedOptions = function(domain, has2fa) {
    var advancedListId, html, optionsHtml, twoFactorClass, twoFactorPhrase;
    advancedListId = "advanced_options_list";
    if ($("#" + advancedListId).exists()) {
      $("#" + advancedListId).toggle("fast");
      return true;
    }
    html = "<ul id='" + advancedListId + "' class='advanced-account-options'>";
    twoFactorPhrase = has2fa ? "Configure" : "Add";
    twoFactorClass = has2fa ? "btn-warning" : "btn-success";
    optionsHtml = ["<li><button id='changePassword' class='btn btn-info change-password'>Change Password</button></li>", "<li><a href='?2fa=t' role='button' class='btn " + twoFactorClass + " configure-tfa btn-success'>" + twoFactorPhrase + " Two-Factor Authentication</a></li>", "<li><button id='removeAccount' role='button' class='btn btn-danger remove-account'>Remove Account</button></li>"];
    html += optionsHtml.join("\n\t");
    html += "</ul>";
    $("#settings_list").after(html);
    $("#removeAccount").click(function() {
      return removeAccount(this, domain + "_user", has2fa);
    });
    return $("#changePassword").click(function() {
      return beginChangePassword();
    });
  };

  removeAccount = function(caller, cookie_key, has2fa) {
    var html, removal_button, section_id, tfaBlock, username;
    if (has2fa == null) {
      has2fa = true;
    }
    username = $.cookie(cookie_key);
    removal_button = "remove_acct_button";
    section_id = "remove_account_section";
    tfaBlock = has2fa ? "\n      <input type='text' id='code' name='code' placeholder='Authenticator Code or Backup Code' size='32' maxlength='32' autocomplete='off'/><br/>" : "";
    html = "<section id='" + section_id + "'>\n  <p id='remove_message' class='error'>Are you sure you want to remove your account?</p>\n  <form id='account_remove' onsubmit='event.preventDefault();'>\n    <fieldset>\n      <legend>Remove My Account</legend>\n      <input type='email' value='" + username + "' readonly='readonly' id='username' name='username'/><br/>\n      <input type='password' id='password' name='password' placeholder='Password'/><br/>" + tfaBlock + "\n      <button id='" + removal_button + "' class='totpbutton btn btn-danger'>Remove My Account Permanantly</button> <button onclick=\"window.location.href=totpParams.home\" class='btn btn-primary'>Back to Safety</button>\n    </fieldset>\n  </form>\n</section>";
    if ($("#login_block").exists()) {
      $("#login_block").replaceWith(html);
    } else {
      $(caller).after(html);
    }
    $("#" + removal_button).click(function() {
      return doRemoveAccountAction();
    });
    return $("#account_remove").submit(function() {
      return doRemoveAccountAction();
    });
  };

  doRemoveAccountAction = function() {
    var ajaxLanding, apiUrlString, args, code, password, url, username;
    animateLoad();
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    username = $("#username").val();
    password = $("#password").val();
    code = $("#code").exists() ? $("#code").val() : false;
    args = "action=removeaccount&username=" + username + "&password=" + password + "&code=" + code;
    return $.post(apiUrlString, args, 'json').done(function(result) {
      if (result.status === true) {
        $("#remove_message").text("Your account has been successfully deleted.");
        $.each($.cookie(), function(k, v) {
          return $.removeCookie(k, {
            path: '/'
          });
        });
        delay(3000, function() {
          return window.location.href = window.totpParams.home;
        });
        return stopLoad();
      } else {
        $("#remove_message").text("There was an error removing your account. Please try again.");
        console.error("Got an error-result: ", result.error);
        console.warn(apiUrlString + "?" + args, result);
        return stopLoadError();
      }
    }).fail(function(result, status) {
      $("#remove_message").text(result.error).addClass("error");
      $("totp_code").val("");
      console.error("Ajax Failure", apiUrlString + "?" + args, result, status);
      return stopLoadError();
    });
  };

  noSubmit = function() {
    event.preventDefault();
    return event.returnValue = false;
  };

  doAsyncLogin = function(uri, respectRelativePath) {
    var apiUrlString, args, pass64, password, username;
    if (uri == null) {
      uri = apiUri.targetApi;
    }
    if (respectRelativePath == null) {
      respectRelativePath = true;
    }
    noSubmit();
    if (respectRelativePath) {
      apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + uri;
    } else {
      apiUrlString = uri;
    }
    username = $("#username").val();
    password = $("#password").val();
    pass64 = Base64.encodeURI(password);
    args = "action=dologin&username=" + username + "&password=" + pass64 + "&b64=true";
    return false;
  };

  doAsyncCreate = function() {
    var recaptchaResponse, recaptchaTest;
    recaptchaResponse = grecaptcha.getResponse();
    recaptchaTest = typeof recaptchaResponse === "object" ? recaptchaResponse.success !== true : isNull(recaptchaResponse);
    if (recaptchaTest) {
      $("#createUser_submit").before("<p id='createUser_fail' class='alert bg-danger'>Sorry, your CAPTCHA was incorrect. Please try again.</p>");
      grecaptcha.reset();
      return false;
    }
    $("#createUser_fail").remove();
    console.info("Successfully called back the recaptcha response", recaptchaResponse);
    if (typeof recaptchaResponse === "string") {
      $("#g-recaptcha-response").val(recaptchaResponse);
    }
    return true;
  };

  resetPassword = function() {

    /*
     * Reset the user password
     */
    var ajaxLanding, apiUrlString, args, checkButton, multiOptionBinding, pane_messages, resetFormSubmit, url;
    $("#password").remove();
    $("label[for='password']").remove();
    $("#reset-password-icon").remove();
    $(".alert").remove();
    $("#form_create_new_account").remove();
    $(".tooltip").remove();
    pane_messages = "reset-user-messages";
    if (!$("#" + pane_messages).exists()) {
      $("#login").before("<div id='" + pane_messages + "'></div>");
    }
    $("#" + pane_messages).removeClass("alert-danger alert-info").addClass("alert alert-warning").text("Once your password has been reset, your old password will be invalid.");
    url = apiUri.o;
    ajaxLanding = apiUri.targetApi;
    apiUrlString = url.attr('protocol') + '://' + url.attr('host') + '/' + window.totpParams.subdirectory + ajaxLanding;
    checkButton = "<button class=\"btn btn-warning\" id=\"check-login\">Start Reset</button>";
    $("#login_button").replaceWith(checkButton);
    args = "action=startpasswordreset";
    multiOptionBinding = function(pargs) {
      if (pargs == null) {
        pargs = args;
      }
      $(".reset-pass-button").unbind().click(function() {
        var method, totpValue;
        totpValue = $("#totp").val();
        if (totpValue != null) {
          pargs += "&totp=" + totpValue;
        }
        method = $(this).attr("data-method");
        resetFormSubmit(pargs, method);
        return false;
      });
      return false;
    };
    resetFormSubmit = function(args, method) {
      var user;
      user = $("#username").val();
      if (args == null) {
        args = "action=startpasswordreset&username=" + user;
      }
      animateLoad();
      return $.get(apiUrlString, args, "json").done(function(result) {
        var altEntryButton, doManualEntry, html, ref, sms_id, text, text_html, usedSms;
        if (result.status === false) {
          if (isNull(result.human_error)) {
            result.human_error = void 0;
          }
          console.log("Got requested action " + result.action, result);
          console.log("Requested", apiUrlString + "?" + args);
          $("#username").prop("disabled", true);
          switch (result.action) {
            case "GET_TOTP":
              usedSms = false;
              html = "<legend>Two-Factor Authentication</legend>\n<p><code>" + user + "</code> has two-factor authentication enabled.</p>\n<div id='start-reset-process' class=\"totp\">\n  <div class=\"form-group\">\n    <label for=\"totp\">Authentication Code:</label>\n    <input type=\"number\" class=\"form-control\" id=\"totp\" name=\"totp\"/>\n  </div>\n</div>\n<button class='reset-pass-button btn btn-danger' data-method='email'>\n  Verify By Email\n</button>";
              if (result.canSMS) {
                sms_id = "reset-user-sms-totp";
                text_html = "<button class='btn btn-primary' id='" + sms_id + "'>Text Code</button>";
                $("#start-reset-process").after(text_html);
                $("#" + sms_id).click(function() {
                  var smsArgs, sms_totp;
                  animateLoad();
                  smsArgs = "action=sendtotptext&user=" + user;
                  sms_totp = $.get(apiUrlString, smsArgs, 'json');
                  console.log("Sending message ...", apiUrlString + "?" + args);
                  sms_totp.done(function(result) {
                    var newButton;
                    if (result.status === true) {
                      $("#" + pane_messages).text("Your code has been sent to your registered number.").removeClass("alert-warning alert-danger").addClass("alert-info");
                      usedSms = true;
                      newButton = "<button class=\"reset-pass-button btn btn-danger\" data-method=\"email\">\n  Verify by SMS\n</button>";
                      $("#" + sms_id).replaceWith(newButton);
                      return multiOptionBinding(args);
                    } else {
                      $("#" + pane_messages).addClass("alert-danger").text(result.human_error);
                      return console.error(result.error);
                    }
                  });
                  sms_totp.fail(function(result, status) {
                    $("#" + pane_messages).addClass("alert-danger").text("There was a problem sending your text. Please try again.");
                    console.error("AJAX failure trying to send TOTP text", apiUrlString + "?" + args);
                    return console.error("Returns:", result, status);
                  });
                  return sms_totp.always(function() {
                    return stopLoad();
                  });
                });
              }
              $("#login").replaceWith(html).unbind().submit(function() {
                noSubmit();
                return doTotpSubmission();
              });
              multiOptionBinding(args);
              return false;
            case "NEED_METHOD":
              html = "<p>Resetting password for <code>" + user + "</code></p>";
              if (result.canSMS && usedSms !== true) {
                html = "<button class='reset-pass-button btn btn-danger' data-method='sms'>Verify by SMS</button>";
                false;
              }
              html += "<button class='reset-pass-button btn btn-danger' data-method='email'>\n  Verify by Email\n</button>";
              $("#login").replaceWith(html);
              multiOptionBinding(args);
              return false;
            case "BAD_USER":
              $("#" + pane_messages).addClass("alert-danger").text("Sorry, that user doesn't exist.");
              $("#username").prop("disabled", false).val("");
              return false;
            default:
              text = (ref = result.human_error) != null ? ref : "There was a problem resetting your password. Please try again";
              $("#" + pane_messages).addClass("alert-danger").removeClass("alert-info alert-warning").text(text);
              console.error("Illegal state!");
              console.warn(result);
              return false;
          }
        } else {
          console.log("Got a good result.");
          console.log(result);
          $(".form-group").remove();
          doManualEntry = function() {
            var altEntry;
            altEntry = "<legend>Verify Reset</legend>\n<div class=\"form-group\">\n  <label for=\"verify\">Verification Token:</label>\n  <input type=\"text\" class=\"form-control\" id=\"verify\" name=\"verify\" />\n</div>\n<div class=\"form-group\">\n  <label for=\"key\">Key:</label>\n  <input type=\"text\" class=\"form-control\" id=\"key\" name=\"key\" />\n</div>\n<input type=\"hidden\" id=\"username\" name=\"username\" value=\"" + user + "\" />\n<button class=\"btn btn-success\" id=\"verify-now\">Verify Now</button>";
            $("#login").html(altEntry).unbind().submit(function() {
              noSubmit();
              return finishPasswordResetHandler();
            });
            return $("#verify-now").click(function() {
              return finishPasswordResetHandler();
            });
          };
          if (method === "email" || (method == null)) {
            $("#" + pane_messages).removeClass("alert-warning alert-danger").addClass("alert-info").text("Check your email for your reset link. Once you've clicked that, your password will be reset.");
            altEntryButton = "<button class='btn btn-default' id='manual-input'>Manually Input Verification</button>";
            $("#check-login").replaceWith(altEntryButton);
            $("#manual-input").click(function() {
              return doManualEntry();
            });
          }
          if (method === "sms") {
            doManualEntry();
          }
        }
        stopLoad();
        return false;
      }).fail(function(result, status) {
        stopLoadError();
        $("#" + pane_messages).removeClass("alert-info alert-warning").addClass("alert-danger").text("We couldn't process the password reset. Please try again.");
        return false;
      });
    };
    $("#login").unbind().submit(function() {
      noSubmit();
      return resetFormSubmit();
    });
    return $("#check-login").unbind().click(function() {
      noSubmit();
      return resetFormSubmit();
    });
  };

  finishPasswordResetHandler = function() {

    /*
     * Read the URL params, then do the async call
     *
     *
     */
    var args, html, key, username, verify;
    verify = "";
    key = "";
    if ($("input#verify").exists()) {
      verify = $("input#verify").val().trim();
      key = $("input#key").val().trim();
      username = $("input#username").val();
    } else {
      verify = window.resetParams.verify;
      key = window.resetParams.key;
      username = window.resetParams.user;
      if (isNull(verify)) {
        verify = apiUri.o.param("verify");
        key = apiUri.o.param("key");
        username = apiUri.o.param("user");
      }
      html = "<h1>Password Reset Confirmation</h1>\n<div id='login'></div>";
      $("body").append(html);
    }
    if (isNull(verify) || isNull(key)) {
      if ($(".alert").exists()) {
        $(".alert").remove();
      }
      html = "<div class=\"alert alert-danger\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>Yikes!</strong> We need both the verification token and key to continue resetting your password.\n</div>";
      $("#login").before(html);
      $(".alert").alert();
      return false;
    }
    args = "action=finishpasswordreset&key=" + key + "&verify=" + verify + "&username=" + username;
    $.post(apiUri.apiTarget, args, "json").done(function(result) {
      if (result.verification_data == null) {
        result.verification_data = true;
      }
      if (!(result.status && result.verification_data)) {
        if ($(".alert").exists()) {
          $(".alert").remove();
        }
        if (result.error === "Invalid credentials - Invalid reset tokens") {
          result.human_error += "<br/><br/>Remember, your reset link is only good for <strong>one</strong> reset. If you've already used that link, you'll need to generate another";
        }
        html = "<div class=\"alert alert-danger\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>There was a problem resetting your password.</strong> " + result.human_error + " We suggest <a href=\"" + apiUri.urlString + "\" class=\"alert-link\">going back</a> and trying again.\n</div>";
        $("#login").before(html);
        $(".alert").alert();
        console.error("Problem resetting password! Server said " + result.error);
        console.warn(result);
        return false;
      }
      html = "<div class=\"alert alert-success\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>Your password has been successfully reset</strong> Your new password is <input type=\"text\" value=\"" + result.new_password + "\" class=\"form-control form-inline code\" readonly />. Write this down! You will NOT be able to generate or see this password again.<br/><br/>When you're done, <a href=\"" + apiUri.urlString + "\" class=\"alert-link\">return to the login page</a> and log in with your new password.\n</div>";
      $("#login").replaceWith(html);
      $(".alert").alert();
      return false;
    }).fail(function(result) {
      html = "<div class=\"alert alert-danger\">\n  <button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-label=\"Close\"><span aria-hidden=\"true\">&times;</span></button>\n  <strong>Yikes!</strong> We had a problem checking the server. Try again later.\n</div>";
      $("#login").before(html);
      $(".alert").alert();
      console.error("Couldn't communicate with server! Tried to contact", apiUri.apiTarget + "?" + args);
      return false;
    }).always(function() {
      return $(".do-refresh-page").click(function() {
        return document.location.reload(true);
      });
    });
    return false;
  };

  beginChangePassword = function() {
    var changePasswordForm, checkFirstPassword, cookie, username;
    cookie = window.totpParams.domain + "_user";
    username = $.cookie(cookie);
    changePasswordForm = "<form class='change-password-form form-horizontal'>\n  <fieldset>\n    <legend>Change Password</legend>\n    <div class=\"form-group\">\n      <label for=\"old-password\" class=\"col-sm-2 control-label\">Old Password</label>\n      <div class=\"col-sm-4\">\n        <input type=\"password\" class=\"form-control old-password\" id=\"old-password\" placeholder=\"Old Password\" required=\"required\"/>\n      </div>\n    </div>\n    <div class=\"new-password-group\">\n      <div class=\"form-group\">\n        <label for=\"new-password\" class=\"col-sm-2 control-label\">New Password</label>\n        <div class=\"col-sm-4 has-feedback\">\n          <input type=\"password\" class=\"form-control new-password\" id=\"new-password\" placeholder=\"New Password\" required=\"required\"/>\n          <span id=\"feedback-status-1\"></span>\n        </div>\n      </div>\n      <div class=\"form-group\">\n        <label for=\"new-password-confirm\" class=\"col-sm-2 control-label\">Confirm New Password</label>\n        <div class=\"col-sm-4 has-feedback\">\n          <input type=\"password\" class=\"form-control new-password\" id=\"new-password-confirm\" placeholder=\"Confirm New Password\" required=\"required\"/>\n          <span id=\"feedback-status-2\"></span>\n        </div>\n      </div>\n    </div>\n    <div id=\"password_security\" class=\"pull-right col-sm-5 password-reqs hidden-xs\"></div>\n    <button id=\"do-change-password\" class=\"btn btn-primary col-sm-offset-2\" disabled>Change Password for<br/> " + username + "</button>\n  </fieldset>\n</form>";
    $("#account_settings").after(changePasswordForm);
    loadJS(window.totpParams.relative + "js/zxcvbn/zxcvbn.min.js");
    checkFirstPassword = function() {
      var e;
      try {
        return checkPasswordLive("#do-change-password", "#new-password", "#new-password-confirm");
      } catch (_error) {
        e = _error;
        console.error("Couldn't check password requirements! " + e.message);
        return console.warn(e.stack);
      }
    };
    $("#new-password").keyup(function() {
      return checkFirstPassword();
    }).change(function() {
      return checkFirstPassword();
    });
    $("#new-password-confirm").change(function() {
      return checkMatchPassword("#do-change-password", "#new-password", "#new-password-confirm");
    }).keyup(function() {
      return checkMatchPassword("#do-change-password", "#new-password", "#new-password-confirm");
    });
    $(".change-password-form input").blur(function() {
      return checkFirstPassword();
    });
    $("#do-change-password").click(function() {
      var args;
      $(this).prop("disabled", true);
      args = "action=changepassword&old_password=" + (encodeURIComponent($("#old-password").val())) + "&new_password=" + (encodeURIComponent($("#new-password").val())) + "&username=" + (encodeURIComponent(username));
      return $.post(apiUri.apiTarget, args, "json").done(function(result) {
        var errorHtml, successHtml;
        if (result.status === false || result.action !== "changepassword") {
          if (result.action !== "changepassword") {
            result.error = "mismatched mode result";
            result.human_error = "The server gave a nonsensical response. Your original password is still valid.";
          }
          if (result.human_error == null) {
            result.human_error = "The server had an unexpected error";
          }
          errorHtml = "<div class=\"alert alert-danger center-block fade in\" role=\"alert\">\n  <strong>Couldn't update password</strong> " + result.human_error + "\n</div>";
          $("#do-change-password").before(errorHtml);
          $("#do-change-password").prop("disabled", false);
          console.error("Couldn't update password! Server said " + result.error);
          console.warn(result);
          return false;
        }
        successHtml = "<div class=\"alert alert-success center-block fade in\" role=\"alert\">\n  <strong>Password Changed</strong> Your password has been successfully updated. <a class=\"alert-link\" id=\"refresh-page\" style=\"cursor:pointer\">Click here to refresh now</a> - you may have to log back in, using your new password.\n</div>";
        $(".change-password-form").replaceWith(successHtml);
        $("#refresh-page").click(function() {
          return document.location.reload(true);
        });
        return false;
      }).fail(function(result, status) {
        var errorHtml;
        errorHtml = "<div class=\"alert alert-danger center-block fade in\" role=\"alert\">\n  <strong>Couldn't update password</strong> There was a problem communicating with the server. Please try again later.\n</div>";
        $("#do-change-password").replaceWith(errorHtml);
        console.error("AJAX failure to change password!");
        return console.warn("Got", result, status);
      });
    });
    return false;
  };

  finishChangePassword = function() {
    return false;
  };

  verifyEmail = function(caller) {
    var args, isAlternate, user, validateEmailCode;
    isAlternate = $(caller).attr("data-alternate").toBool();
    user = $(caller).atter("data-user");
    args = "action=verifyemail&user=" + (encodeURIComponent(user)) + "&alternate=" + isAlternate;
    validateEmailCode = function() {
      var code;
      code = $("#verify-email-code").val().trim();
      args += "&token=" + code;
      $.post(apiUri.apiTarget, args, "json").done(function(result) {
        var html;
        if (result.is_good === true) {
          if (result.status === false) {
            stopLoad();
            toastStatusMessage("You're already verified");
          } else {
            toastStatusMessage("Verification successful");
          }
          $("#verify-email-filler").remove();
          html = "<span class='glyphicon glyphicon-check text-success' data-toggle='tooltip' title='Verified Email'></span>";
          if (result.meets_restriction_criteria) {
            html += "<span class='glyphicon glyphicon-star' data-toggle='tooltip' title='Unrestricted User'></span>";
          }
          $(caller).append(html);
        } else {
          stopLoadError(result.human_error);
        }
        return false;
      }).fail(function(result, status) {
        stopLoadError("Sorry, we couldn't verify your email at this time");
        return false;
      });
      return false;
    };
    try {
      startLoad();
    } catch (_error) {}
    $.post(apiUri.apiTarget, args, "json").done(function(result) {
      var html;
      if (result.is_good === true) {
        if (result.status === false) {
          stopLoad();
          toastStatusMessage("You're already verified");
        } else {
          false;
        }
      } else {
        if (result.status) {
          html = "<div id='verify-email-filler' class='form'>\n  <p>We've sent you an email. Please click the link in the email, or paste the code provided into the box below.</p>\n  <label for='verify-email-code' class='sr-only'>Validation Code:</label>\n  <input class='form-control' type='text' length='32' placeholder='Verification Code' id='verify-email-code' name='verify-email-code'/>\n  <button class='btn btn-primary' id='validate-email-code'>Validate Code</button>\n</div>";
          $(caller).after(html);
          $("#validate-email-code").click(function() {
            return validateEmailCode();
          });
        } else {
          console.error(result.error);
          try {
            stopLoadError(result.human_error);
          } catch (_error) {
            try {
              toastStatusMessage(result.human_error);
            } catch (_error) {}
          }
        }
      }
      return false;
    }).fail(function(result, status) {
      stopLoadError("Sorry, we couldn't verify your email at this time");
      return false;
    });
    return false;
  };

  addAlternateEmail = function() {
    return false;
  };

  $(function() {
    var bootstrapCSS, e, needStylesheetImport, selector;
    needStylesheetImport = true;
    $("link[rel='stylesheet']").each(function() {
      if ($(this).attr("href").search("bootstrap.min.css" !== -1)) {
        needStylesheetImport = false;
        return false;
      }
    });
    if (needStylesheetImport) {
      bootstrapCSS = "<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\" />";
      $("head").append(bootstrapCSS);
    }
    if (window.passwords.submitSelector == null) {
      selector = "#createUser_submit";
    } else {
      selector = window.passwords.submitSelector;
    }
    if ($("#password.create").exists()) {
      loadJS(window.totpParams.relative + "js/zxcvbn/zxcvbn.min.js");
      $("#password.create").keyup(function() {
        return checkPasswordLive();
      }).change(function() {
        return checkPasswordLive();
      });
      $("#password2").change(function() {
        return checkMatchPassword();
      }).keyup(function() {
        return checkMatchPassword();
      });
      $("input").addClass("form-control").parent().addClass("form-inline").blur(function() {
        return checkPasswordLive();
      });
      $("#password").after("<span id='feedback-status-1'></span>").parent().removeClass("form-inline").parent().addClass("has-feedback").parent().addClass("form-horizontal");
      $("#password2").after("<span id='feedback-status-2'></span>").parent().removeClass("form-inline").parent().addClass("has-feedback").parent().addClass("form-horizontal");
    }
    $("#totp_submit").submit(function() {
      return doTOTPSubmit();
    });
    $("#verify_totp_button").click(function() {
      return doTOTPSubmit();
    });
    $("#totp_start").submit(function() {
      return makeTOTP();
    });
    $("#add_totp_button").click(function() {
      return makeTOTP();
    });
    $("#totp_remove").submit(function() {
      return doTOTPRemove();
    });
    $("#remove_totp_button").click(function() {
      return doTOTPRemove();
    });
    $("#alternate_verification_prompt").click(function() {
      giveAltVerificationOptions();
      return false;
    });
    $("#verify_phone").submit(function() {
      return verifyPhone();
    });
    $("#verify_phone_button").click(function() {
      return verifyPhone();
    });
    $("#verify_later").click(function() {
      return window.location.href = window.totpParams.home;
    });
    $("#totp_help").click(function() {
      return showInstructions();
    });
    $("#showAdvancedOptions").click(function() {
      var domain, has2fa;
      domain = $(this).attr('data-domain');
      has2fa = $(this).attr("data-user-tfa") === 'true' ? true : false;
      return showAdvancedOptions(domain, has2fa);
    });
    $(".do-password-reset").click(function() {
      resetPassword();
      return false;
    });
    $(".verify-email").click(function() {
      var parent;
      parent = $(this).parent();
      verifyEmail(parent);
      return false;
    });
    $("#add-alternate").click(function() {
      addAlternateEmail();
      return false;
    });
    try {
      loadJS("https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js", function() {
        var e;
        try {
          if (apiUri.o.param("showhelp") != null) {
            showInstructions();
          }
        } catch (_error) {
          e = _error;
          delay(300, function() {
            if (apiUri.o.param("showhelp") != null) {
              return showInstructions();
            }
          });
        }
        $(".do-password-reset").unbind();
        try {
          $("#reset-password-icon").tooltip();
        } catch (_error) {
          e = _error;
          console.warn("Couldn't tooltip the forgotten password icon!");
        }
        $(".do-password-reset").click(function() {
          resetPassword();
          return false;
        });
        try {
          return $(".alert").alert();
        } catch (_error) {
          e = _error;
          return console.warn("Couldn't bind alert!");
        }
      });
    } catch (_error) {
      e = _error;
      console.log("Couldn't tooltip icon!");
    }
    try {
      if (apiUri.o.param("showhelp") != null) {
        showInstructions();
      }
    } catch (_error) {
      e = _error;
      delay(300, function() {
        if (apiUri.o.param("showhelp") != null) {
          return showInstructions();
        }
      });
    }
    try {
      if (window.checkPasswordReset === true) {
        finishPasswordResetHandler();
      }
    } catch (_error) {
      e = _error;
      console.error("Couldn't check password reset state! " + e.message);
    }
    $("#next.continue").click(function() {
      return window.location.href = window.totpParams.home;
    });
    return $("<link/>", {
      rel: "stylesheet",
      type: "text/css",
      media: "screen",
      href: window.totpParams.combinedStylesheetPath
    }).appendTo("head");
  });

}).call(this);

//# sourceMappingURL=maps/c.js.map
