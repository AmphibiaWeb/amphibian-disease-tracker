
/*
 * Web worker compatriot to
 *
 * global-search.coffee
 *
 *
 */
var byteCount, dateMonthToString, deEscape, decode64, delay, downloadCSVFile, encode64, generateCSVFromResults, getLocation, getPrettySpecies, getSampleSummaryDialog, goTo, isArray, isBlank, isBool, isEmpty, isJson, isNull, isNumber, jsonTo64, locationData, openLink, openTab, post64, prepURI, randomInt, randomString, roundNumber, roundNumberSigfig, toFloat, toInt, toObject, validateAWebTaxon,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

self.addEventListener("message", function(e) {
  var data, jResultsList, options, response, tableMap;
  switch (e.data.action) {
    case "summary-dialog":
      jResultsList = e.data.resultsList;
      tableMap = e.data.tableToProjectMap;
      return getSampleSummaryDialog(jResultsList, tableMap, e.data.windowWidth);
    case "csv":
      data = e.data.data;
      options = e.data.options;
      response = downloadCSVFile(data, options);
      console.info("CSV file successfully generated");
      self.postMessage(response);
      return self.close();
  }
});

getPrettySpecies = function(rowData) {
  var genus, pretty, ref, ref1, species, ssp;
  genus = rowData.genus;
  species = (ref = rowData.specificEpithet) != null ? ref : rowData.specificepithet;
  ssp = (ref1 = rowData.infraspecificEpithet) != null ? ref1 : rowData.infraspecificEpithet;
  pretty = genus;
  if (!isNull(species)) {
    pretty += " " + species;
    if (!isNull(ssp)) {
      pretty += " " + ssp;
    }
  }
  return pretty;
};

getSampleSummaryDialog = function(resultsList, tableToProjectMap, windowWidth) {

  /*
   * Show a SQL-query like dataset in a modal dialog
   *
   * TODO migrate this to a Web Worker
   * http://www.html5rocks.com/en/tutorials/workers/basics/
   *
   * See
   * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/146
   *
   * @param array resultList -> array of Carto responses. Data expected
   *   in "rows" field
   * @param object tableToProjectMap -> Map the table name onto project id
   */
  var altRows, col, d, data, dataSummary, dataWidthMax, dataWidthMin, disease, diseases, e, elapsed, error1, error2, error3, html, i, j, l, len, len1, message, n, outputData, prevalence, project, projectRawData, projectResults, projectTableRows, rawDataHtml, ref, ref1, ref2, row, rowSet, sortRows, species, startTime, summaryDataObj, summaryRow, summaryRowData, summaryTable, summaryTableRows, summaryTableRowsSortable, table, tableRows, tableRowsSimple, unhelpfulCols;
  startTime = Date.now();
  if (!isArray(resultsList)) {
    resultsList = Object.toArray(resultsList);
  }
  if (resultsList.length === 0) {
    console.warn("There were no results in the result list");
    return false;
  }
  console.log("Generating dialog from list of length " + resultsList.length, resultsList);
  projectTableRows = new Array();
  projectRawData = new Array();
  outputData = new Array();
  i = 0;
  unhelpfulCols = ["cartodb_id", "the_geom", "the_geom_webmercator", "id"];
  dataSummary = {
    species: [],
    diseases: [],
    data: {}
  };
  for (j = 0, len = resultsList.length; j < len; j++) {
    projectResults = resultsList[j];
    ++i;
    dataWidthMax = windowWidth * .5;
    dataWidthMin = windowWidth * .3;
    try {
      rowSet = projectResults.rows;
      try {
        altRows = new Object();
        sortRows = new Object();
        ref = projectResults.rows;
        for (n in ref) {
          row = ref[n];
          for (l = 0, len1 = unhelpfulCols.length; l < len1; l++) {
            col = unhelpfulCols[l];
            delete row[col];
          }
          altRows[n] = row;
          row.carto_table = projectResults.table;
          row.project_id = projectResults.project_id;
          species = getPrettySpecies(row);
          if (indexOf.call(dataSummary.species, species) < 0) {
            dataSummary.species.push(species);
          }
          d = row.diseasetested;
          if (indexOf.call(dataSummary.diseases, d) < 0) {
            dataSummary.diseases.push(d);
          }
          if (isNull(dataSummary.data[species])) {
            dataSummary.data[species] = {};
          }
          if (isNull(dataSummary.data[species][d])) {
            dataSummary.data[species][d] = {
              samples: 0,
              positive: 0,
              negative: 0,
              no_confidence: 0,
              prevalence: 0
            };
          }
          if (row.diseasedetected.toBool()) {
            dataSummary.data[species][d].positive++;
          } else {
            if (row.diseasedetected.toLowerCase() === "no_confidence") {
              dataSummary.data[species][d].no_confidence++;
            } else {
              dataSummary.data[species][d].negative++;
            }
          }
          dataSummary.data[species][d].samples++;
          prevalence = dataSummary.data[species][d].positive / dataSummary.data[species][d].samples;
          dataSummary.data[species][d].prevalence = prevalence;
          sortRows[species] = row;
        }
        rowSet = altRows;
        Object.doOnSortedKeys(sortRows, function(rowData) {
          return outputData.push(rowData);
        });
      } catch (error1) {
        ref1 = projectResults.rows;
        for (n in ref1) {
          row = ref1[n];
          row.carto_table = projectResults.table;
          row.project_id = projectResults.project_id;
          outputData.push(row);
        }
      }
      data = JSON.stringify(rowSet);
      if (isNull(data)) {
        console.warn("Got bad data for row #" + i + "!", projectResults, projectResults.rows, data);
        continue;
      }
      data = "" + data;
    } catch (error2) {
      data = "Invalid data from server";
    }
    table = project = tableToProjectMap[projectResults.table];
    row = "<tr>\n  <td colspan=\"4\" class=\"code-box-container\"><pre readonly class=\"code-box language-json\" style=\"max-width:" + dataWidthMax + "px;min-width:" + dataWidthMin + "px\">" + data + "</pre></td>\n  <td class=\"text-center\"><paper-icon-button data-toggle=\"tooltip\" raised class=\"click\" data-href=\"https://amphibiandisease.org/project.php?id=" + project.id + "\" icon=\"icons:arrow-forward\" title=\"" + project.name + "\"></paper-icon-button></td>\n</tr>";
    projectTableRows.push(row);
    projectRawData.push(data);
  }
  summaryTableRows = new Object();
  summaryTableRowsSortable = new Object();
  summaryDataObj = new Array();
  ref2 = dataSummary.data;
  for (species in ref2) {
    diseases = ref2[species];
    for (disease in diseases) {
      data = diseases[disease];
      if (summaryTableRows[disease] == null) {
        summaryTableRows[disease] = new Array();
        summaryTableRowsSortable[disease] = new Object();
      }
      prevalence = data.prevalence * 100;
      prevalence = roundNumberSigfig(prevalence, 2);
      summaryRow = "<tr>\n  <td>" + species + "</td>\n  <td>" + data.samples + "</td>\n  <td>" + data.positive + "</td>\n  <td>" + data.negative + "</td>\n  <td>" + prevalence + "%</td>\n</tr>";
      summaryRowData = {
        genus: species.split(" ")[0],
        species: species.split(" ")[1],
        fullScientificName: species,
        disease: disease,
        samples: data.samples,
        positive: data.positive,
        negative: data.negative,
        prevalence: prevalence + "%"
      };
      summaryDataObj.push(summaryRowData);
      summaryTableRows[disease].push(summaryRow);
      summaryTableRowsSortable[disease][species] = summaryRow;
    }
  }
  summaryTable = "";
  for (disease in summaryTableRowsSortable) {
    tableRows = summaryTableRowsSortable[disease];
    try {
      if (typeof tableRows === "object") {
        tableRowsSimple = new Array();
        Object.doOnSortedKeys(tableRows, function(row) {
          return tableRowsSimple.push(row);
        });
      } else {
        console.warn("Warning: table rows aren't an object");
        tableRowsSimple = tableRows;
      }
    } catch (error3) {
      e = error3;
      console.error("Can't sort rows: " + e.message);
      console.warn(e.stack);
      tableRowsSimple = summaryTableRows[disease];
    }
    summaryTable += "<div class=\"row\">\n  <div class=\"col-xs-12\">\n    <h3>" + disease + "</h3>\n    <table class=\"table table-striped\">\n      <tr>\n        <th>Species</th>\n        <th>Samples</th>\n        <th>Disease Positive</th>\n        <th>Disease Negative</th>\n        <th>Disease Prevalence</th>\n      </tr>\n      " + (tableRowsSimple.join("\n")) + "\n    </table>\n  </div>\n</div>";
  }
  if (isNull(summaryTable)) {
    summaryTable = "<h3><em>Sorry, we were unable to generate a summary table</em></h3>";
  }
  rawDataHtml = "<div class=\"row\">\n  <div class=\"col-xs-12\">\n    <h3>Raw Data</h3>\n    <table class=\"table table-striped\">\n      <tr>\n        <th colspan=\"4\">Query Data</th>\n        <th>Visit Project</th>\n      </tr>\n      " + (projectTableRows.join("\n")) + "\n    </table>\n  </div>\n</div>";
  html = "<paper-dialog id=\"modal-sql-details-list\" modal always-on-top auto-fit-on-attach>\n  <h2>Project Result List</h2>\n  <paper-dialog-scrollable>\n    " + summaryTable + "\n\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button id=\"generate-download\">Create Download</paper-button>\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
  message = {
    html: html,
    outputData: outputData,
    data: dataSummary,
    summaryRowData: summaryDataObj,
    summaryRows: summaryTableRows,
    providedList: resultsList,
    providedMap: tableToProjectMap,
    providedWidth: windowWidth,
    rawProjectData: projectRawData,
    rawDataHtml: rawDataHtml
  };
  elapsed = Date.now() - startTime;
  console.info("Worker saved " + elapsed + "ms from the main thread");
  self.postMessage(message);
  return self.close();
};


/*
 * Core helpers/imports for web workers
 */

locationData = new Object();

locationData.params = {
  enableHighAccuracy: true
};

locationData.last = void 0;

isBool = function(str, strict) {
  var e, error1;
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
  } catch (error1) {
    e = error1;
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
  var e, error1;
  try {
    if (isEmpty(str) || isBlank(str) || (str == null)) {
      if (!(str === false || str === 0)) {
        return true;
      }
    }
  } catch (error1) {
    e = error1;
    return false;
  }
  return false;
};

isJson = function(str) {
  var error1;
  if (typeof str === 'object' && !isArray(str)) {
    return true;
  }
  try {
    JSON.parse(str);
    return true;
  } catch (error1) {
    return false;
  }
  return false;
};

isArray = function(arr) {
  var error1, shadow;
  try {
    shadow = arr.slice(0);
    shadow.push("foo");
    return true;
  } catch (error1) {
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
  var e, error1, res;
  try {
    res = _.find(this, function(val) {
      return _.isEqual(obj, val);
    });
    return typeof res === "object";
  } catch (error1) {
    e = error1;
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
  var e, error1, key, size;
  if (typeof obj !== "object") {
    try {
      return obj.length;
    } catch (error1) {
      e = error1;
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
  var data, j, key, len, results, sortedKeys;
  sortedKeys = Object.keys(obj).sort();
  results = [];
  for (j = 0, len = sortedKeys.length; j < len; j++) {
    key = sortedKeys[j];
    data = obj[key];
    results.push(fn(data));
  }
  return results;
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
  var e, error1;
  try {
    return Base64.encode(string);
  } catch (error1) {
    e = error1;
    console.warn("Bad encode string provided");
    return string;
  }
};

decode64 = function(string) {
  var e, error1;
  try {
    return Base64.decode(string);
  } catch (error1) {
    e = error1;
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

String.prototype.toTitleCase = function() {
  var j, l, len, len1, lower, lowerRegEx, lowers, str, upper, upperRegEx, uppers;
  str = this.replace(/([^\W_]+[^\s-]*) */g, function(txt) {
    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
  });
  lowers = ["A", "An", "The", "And", "But", "Or", "For", "Nor", "As", "At", "By", "For", "From", "In", "Into", "Near", "Of", "On", "Onto", "To", "With"];
  for (j = 0, len = lowers.length; j < len; j++) {
    lower = lowers[j];
    lowerRegEx = new RegExp("\\s" + lower + "\\s", "g");
    str = str.replace(lowerRegEx, function(txt) {
      return txt.toLowerCase();
    });
  }
  uppers = ["Id", "Tv"];
  for (l = 0, len1 = uppers.length; l < len1; l++) {
    upper = uppers[l];
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

openLink = function(url) {
  if (url == null) {
    return false;
  }
  open(url);
  return false;
};

openTab = function(url) {
  return openLink(url);
};

goTo = function(url) {
  if (url == null) {
    return false;
  }
  location.href = url;
  return false;
};

dateMonthToString = function(month) {
  var conversionObj, error1, rv;
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
  } catch (error1) {
    rv = month;
  }
  return rv;
};

prepURI = function(string) {
  string = encodeURIComponent(string);
  return string.replace(/%20/g, "+");
};

locationData = new Object();

locationData.params = {
  enableHighAccuracy: true
};

locationData.last = void 0;

getLocation = function(callback) {
  var geoFail, geoSuccess, geoTimeout, retryTimeout;
  if (callback == null) {
    callback = void 0;
  }
  retryTimeout = 1500;
  geoSuccess = function(pos) {
    var elapsed, last;
    clearTimeout(geoTimeout);
    locationData.lat = pos.coords.latitude;
    locationData.lng = pos.coords.longitude;
    locationData.acc = pos.coords.accuracy;
    last = locationData.last;
    locationData.last = Date.now();
    elapsed = locationData.last - last;
    if (elapsed < retryTimeout) {
      return false;
    }
    console.info("Successfully set location");
    if (typeof callback === "function") {
      callback(locationData);
    }
    return false;
  };
  geoFail = function(error) {
    var locationError;
    clearTimeout(geoTimeout);
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
    navigator.geolocation.getCurrentPosition(geoSuccess, geoFail, locationData.params);
    return geoTimeout = delay(1500, function() {
      return getLocation(callback);
    });
  } else {
    console.warn("This browser doesn't support geolocation!");
    if (callback != null) {
      return callback(false);
    }
  }
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
  var c, col, e, elapsed, error1, file, header, headerPlaceholder, headerStr, html, id, j, jsonObject, k, len, parser, response, selector, startTime, textAsset;
  startTime = Date.now();
  textAsset = "";
  if (isJson(data) && typeof data === "string") {
    console.info("Parsing as JSON string");
    try {
      jsonObject = JSON.parse(data);
    } catch (error1) {
      e = error1;
      console.error("COuldn't parse json! " + e.message);
      console.warn(e.stack);
      console.info(data);
      throw "error";
    }
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
    var col, dataVal, error2, escapedKey, handleValue, j, key, len, results, row, tmpRow, tmpRowString, value;
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
            tempValue = providedValue.replace(/,/g, '\,');
            tempValue = tempValue.replace(/"/g, '""');
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
          for (j = 0, len = headerPlaceholder.length; j < len; j++) {
            col = headerPlaceholder[j];
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
  for (j = 0, len = headerPlaceholder.length; j < len; j++) {
    col = headerPlaceholder[j];
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
    c = randomInt(0, 9999);
    id = (selector.slice(1)) + "-download-button-" + c;
    html = "<a id=\"" + id + "\" class=\"" + options.classes + "\" href=\"" + file + "\" download=\"" + options.downloadFile + "\">\n  " + options.iconHtml + "\n  " + options.buttonText + "\n</a>";
  } else {
    html = "";
  }
  response = {
    file: file,
    options: options,
    html: html
  };
  elapsed = Date.now() - startTime;
  console.debug("CSV Worker saved " + elapsed + "ms from main thread");
  return response;
};

generateCSVFromResults = function(resultArray, caller, selector) {
  var error1, options, response;
  if (selector == null) {
    selector = "#modal-sql-details-list";
  }
  console.info("Worker CSV: Given", resultArray);
  options = {
    objectAsValues: true,
    downloadFile: "adp-global-search-result-data_" + (Date.now()) + ".csv"
  };
  try {
    response = downloadCSVFile(resultArray, options);
  } catch (error1) {
    console.error("Sorry, there was a problem with this dataset and we can't do that right now.");
    response = {
      file: "",
      options: options,
      html: ""
    };
  }
  return response;
};

validateAWebTaxon = function(taxonObj, callback) {
  var args, doCallback, validationMeta;
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
  if ((typeof validationMeta !== "undefined" && validationMeta !== null ? validationMeta.validatedTaxons : void 0) == null) {
    if (typeof validationMeta !== "object") {
      validationMeta = new Object();
    }
    validationMeta.validatedTaxons = new Array();
  }
  doCallback = function(validatedTaxon) {
    if (typeof callback === "function") {
      callback(validatedTaxon);
    }
    return false;
  };
  if (validationMeta.validatedTaxons.containsObject(taxonObj)) {
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
      validationMeta.validatedTaxons.push(taxonObj);
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
    console.warn("Warning: Couldn't validate " + prettyTaxon + " with AmphibiaWeb with worker");
    return console.warn(api.php + "?" + args);
  });
  return false;
};

//# sourceMappingURL=maps/global-search-worker.js.map
