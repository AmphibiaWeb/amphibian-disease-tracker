var adminApiTarget, apiTarget, createChart, createOverflowMenu, getRandomDataColor, getServerChart, renderNewChart,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

apiTarget = uri.urlString + "api.php";

adminApiTarget = uri.urlString + "admin-api.php";

window._adp = new Object();

try {
  (createOverflowMenu = function() {

    /*
     * Create the overflow menu lazily
     */
    checkLoggedIn(function(result) {
      var accountSettings, menu;
      accountSettings = result.status ? "    <paper-item data-href=\"https://amphibiandisease.org/admin\" class=\"click\">\n  <iron-icon icon=\"icons:settings-applications\"></iron-icon>\n  Account Settings\n</paper-item>\n<paper-item data-href=\"https://amphibiandisease.org/admin-login.php?q=logout\" class=\"click\">\n  <span class=\"glyphicon glyphicon-log-out\"></span>\n  Log Out\n</paper-item>" : "";
      menu = "<paper-menu-button id=\"header-overflow-menu\" vertical-align=\"bottom\" horizontal-offset=\"-15\" horizontal-align=\"right\" vertical-offset=\"30\">\n  <paper-icon-button icon=\"icons:more-vert\" class=\"dropdown-trigger\"></paper-icon-button>\n  <paper-menu class=\"dropdown-content\">\n    " + accountSettings + "\n    <paper-item disabled data-href=\"https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/176\" class=\"click\">\n      Summary Dashboard\n    </paper-item>\n    <paper-item data-href=\"https://amphibian-disease-tracker.readthedocs.org\" class=\"click\">\n      <iron-icon icon=\"icons:chrome-reader-mode\"></iron-icon>\n      Documentation\n    </paper-item>\n    <paper-item data-href=\"https://github.com/AmphibiaWeb/amphibian-disease-tracker\" class=\"click\">\n      <iron-icon icon=\"glyphicon-social:github\"></iron-icon>\n      Github\n    </paper-item>\n    <paper-item data-href=\"https://amphibiandisease.org/about.php\" class=\"click\">\n      About / Legal\n    </paper-item>\n  </paper-menu>\n</paper-menu-button>";
      $("#header-overflow-menu").remove();
      $("header#header-bar .logo-container + p").append(menu);
      if (!isNull(accountSettings)) {
        $("header#header-bar paper-icon-button[icon='icons:settings-applications']").remove();
      }
      return bindClicks();
    });
    return false;
  })();
} catch (undefined) {}

createChart = function(chartSelector, chartData, isSimpleData, appendTo, callback) {
  var chart, chartCtx, html, newId, origChartData, sampleBarData, sampleData, sampleDatasets;
  if (isSimpleData == null) {
    isSimpleData = false;
  }
  if (appendTo == null) {
    appendTo = "main";
  }
  if (typeof chartData !== "object") {
    console.error("Can't create a chart without a data object");
    return false;
  }
  if (typeof isSimpleData === "function" && isNull(callback)) {
    callback = isSimpleData;
    isSimpleData = false;
  }

  /*
   * Sample build
   */
  sampleBarData = {
    label: "Sample Data",
    data: [65, 59, 80, 81, 56, 55, 40],
    borderWidth: 1,
    borderColor: ['rgba(255,99,132,1)', 'rgba(54, 162, 235, 1)', 'rgba(255, 206, 86, 1)', 'rgba(75, 192, 192, 1)', 'rgba(153, 102, 255, 1)', 'rgba(255, 159, 64, 1)'],
    backgroundColor: ['rgba(255, 99, 132, 0.2)', 'rgba(54, 162, 235, 0.2)', 'rgba(255, 206, 86, 0.2)', 'rgba(75, 192, 192, 0.2)', 'rgba(153, 102, 255, 0.2)', 'rgba(255, 159, 64, 0.2)']
  };
  sampleDatasets = [sampleBarData];
  sampleData = {
    labels: ["January", "February", "March", "April", "May", "June", "July"],
    datasets: sampleDatasets
  };

  /*
   * Sample bits for a sample bar graph
   */
  if (isNull(chartData.data)) {
    origChartData = chartData;
    console.warn("No data for chart, will use sample data", origChartData);
  }
  if (chartData.data == null) {
    chartData.data = sampleData;
  }
  if (chartData.type == null) {
    chartData.type = "bar";
  }
  if (typeof chartData.options !== "object") {
    chartData.options = {
      responsive: true,
      scales: {
        yAxes: [
          {
            ticks: {
              beginAtZero: true
            }
          }
        ]
      }
    };
  }
  if (!$(chartSelector).exists()) {
    newId = chartSelector.slice(0, 1) === "#" ? chartSelector.slice(1) : "dataChart-" + ($("canvas").length);
    html = "<canvas id=\"" + newId + "\" class=\"chart dynamic-chart col-xs-12\">\n</canvas>";
    $(appendTo).append(html);
  }
  chartCtx = $(chartSelector);
  chart = new Chart(chartCtx, chartData);
  console.info("Chart created with", chartData);
  if (typeof callback === "function") {
    callback();
  }
  return chart;
};

getRandomDataColor = function() {
  var colorString, colors;
  colorString = "rgba(" + (randomInt(0, 255)) + "," + (randomInt(0, 255)) + "," + (randomInt(0, 255));
  colors = {
    border: colorString + ",1)",
    background: colorString + ",0.2)"
  };
  return colors;
};

getServerChart = function(chartType, chartParams) {
  var args, cp, requestKey, requestValue;
  if (chartType == null) {
    chartType = "infection";
  }
  startLoad();
  args = "action=chart&sort=" + chartType;
  if (typeof chartParams === "object") {
    cp = new Array();
    for (requestKey in chartParams) {
      requestValue = chartParams[requestKey];
      cp.push(requestKey + "=" + requestValue);
    }
    args += "&" + (cp.join("&"));
  }
  console.debug("Fetching chart with", apiTarget + "?" + args);
  $.post(apiTarget, args, "json").done(function(result) {
    var chartData, colors, data, dataItem, datasets, i, l, len, len1, m, preprocessorFn, ref;
    if (result.status === false) {
      console.error("Server had a problem fetching chart data - " + result.human_error);
      console.warn(result);
      stopLoadError(result.human_error);
      return false;
    }
    console.debug("Fetched chart", result);
    chartData = result.data;
    datasets = Object.toArray(chartData.datasets);
    i = 0;
    for (l = 0, len = datasets.length; l < len; l++) {
      data = datasets[l];
      data.data = Object.toArray(data.data);
      if (data.borderWidth == null) {
        data.borderWidth = 1;
      }
      if (data.backgroundColor == null) {
        data.borderColor = new Array();
        data.backgroundColor = new Array();
        ref = data.data;
        for (m = 0, len1 = ref.length; m < len1; m++) {
          dataItem = ref[m];
          colors = getRandomDataColor();
          data.borderColor.push(colors.border);
          data.backgroundColor.push(colors.background);
        }
      }
      datasets[i] = data;
      ++i;
    }
    switch (result.use_preprocessor) {
      case "geocoder":
        console.log("Got results", result);
        preprocessorFn = function(callback) {
          var builder, builtPoints, currentDataset, dataBin, dataKeyMap, datablob, finished, j, k, kprime, labels, len2, len3, len4, n, o, p, point, pointSet, project, ref1, results, tempPoint, title, waitFinished, waitTime;
          console.log("Starting geocoder preprocessor", datasets);
          builtPoints = 0;
          labels = new Array();
          dataBin = new Array();
          dataKeyMap = new Object();
          i = 0;
          waitFinished = false;
          results = [];
          for (n = 0, len2 = datasets.length; n < len2; n++) {
            datablob = datasets[n];
            data = datablob.data;
            console.log("Data blob", data);
            if (!waitFinished) {
              finished = false;
              currentDataset = i;
              k = 0;
              kprime = 0;
            }
            j = 0;
            for (o = 0, len3 = data.length; o < len3; o++) {
              pointSet = data[o];
              ++j;
              if (!isNull(pointSet.points)) {
                console.debug("Using pointset", pointSet);
                title = pointSet.title;
                project = pointSet.project_id;
                builder = {
                  points: [],
                  title: title,
                  project: project
                };
                builtPoints = 0;
                console.log("Looking at project #" + project + ", '" + title + "'");
                ref1 = Object.toArray(pointSet.points);
                for (p = 0, len4 = ref1.length; p < len4; p++) {
                  point = ref1[p];
                  try {
                    tempPoint = canonicalizePoint(point);
                    builder.points.push(tempPoint);
                    builtPoints++;
                  } catch (undefined) {}
                }
                if (builtPoints === 0) {
                  console.log("Skipping project #" + project + " = '" + title + "' with no points");
                  continue;
                }
                k++;
                waitTime = 1000 / 12.5;
                localityFromMapBuilder(builder, function(locality, cbBuilder) {
                  var binKey, country, error, len5, q, ref2, view, views;
                  kprime++;
                  try {
                    views = (ref2 = cbBuilder.views) != null ? ref2 : geo.geocoderViews;
                    for (q = 0, len5 = views.length; q < len5; q++) {
                      view = views[q];
                      if (indexOf.call(view.types, "country") < 0) {
                        continue;
                      }
                      country = view.formatted_address;
                    }
                  } catch (error) {
                    country = "Multiple Countries";
                  }
                  if (isNull(country)) {
                    country = locality;
                  }
                  console.log("Final locality '" + country + "' for " + cbBuilder.title);
                  if (indexOf.call(labels, country) < 0) {
                    labels.push(country);
                    dataKeyMap[country] = dataBin.length;
                    dataBin.push(1);
                  } else {
                    binKey = dataKeyMap[country];
                    dataBin[binKey]++;
                  }
                  if (kprime === k) {
                    datablob.data = dataBin;
                    datasets[currentDataset] = datablob;
                    kprime = 0;
                    k = 0;
                    waitFinished = false;
                    if (i === datasets.length) {
                      chartData.labels = labels;
                      return callback();
                    }
                  }
                });
              }
              if (j === data.length) {
                finished = true;
                waitFinished = true;
              }
            }
            results.push(++i);
          }
          return results;
        };
        break;
      default:
        preprocessorFn = function(callback) {
          return callback();
        };
    }
    preprocessorFn(function() {
      var chartDataJs, chartObj, chartSelector, ref1;
      chartDataJs = {
        labels: Object.toArray(chartData.labels),
        datasets: datasets
      };
      chartObj = {
        data: chartDataJs,
        type: (ref1 = chartData.type) != null ? ref1 : "bar"
      };
      chartSelector = "#chart-" + (datasets[0].label.replace(" ", "-"));
      createChart(chartSelector, chartObj, function() {
        if (!isNull(result.full_description)) {
          return $("#chart-" + (datasets[0].label.replace(" ", "-"))).before("<h3 class='col-xs-12 text-center chart-title'>" + result.full_description + "</h3>");
        }
      });
      return stopLoad();
    });
    return false;
  }).fail(function(result, status) {
    console.error("AJAX error", result, status);
    stopLoadError("There was a problem communicating with the server");
    return false;
  });
  return false;
};

renderNewChart = function() {
  var chartOptions, chartType, error, key, l, len, option, ref, ref1;
  chartOptions = new Object();
  ref = $(".chart-param");
  for (l = 0, len = ref.length; l < len; l++) {
    option = ref[l];
    key = $(option).attr("data-key").replace(" ", "-");
    try {
      if (p$(option).checked != null) {
        chartOptions[key] = p$(option).checked;
      } else {
        throw "Not Toggle";
      }
    } catch (error) {
      chartOptions[key] = p$(option).selectedItemLabel.toLowerCase().replace(" ", "-");
    }
  }
  $(".chart.dynamic-chart").remove();
  $(".chart-title").remove();
  chartType = (ref1 = chartOptions.sort) != null ? ref1 : "infection";
  delete chartOptions.sort;
  console.info("Going to generate a new chart with the following options", chartOptions);
  getServerChart(chartType, chartOptions);
  return chartOptions;
};

$(function() {
  console.log("Loaded dashboard");
  getServerChart();
  $("#generate-chart").click(function() {
    return renderNewChart.debounce(50);
  });
  return false;
});

//# sourceMappingURL=maps/dashboard.js.map
