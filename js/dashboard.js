var adminApiTarget, apiTarget, createChart, createOverflowMenu, getRandomDataColor, getServerChart;

apiTarget = uri.urlString + "/api.php";

adminApiTarget = uri.urlString + "/admin-api.php";

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

createChart = function(chartSelector, chartData, isSimpleData, appendTo) {
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
      responsive: true
    };
  }
  if (!$(chartSelector).exists()) {
    newId = chartSelector.slice(0, 1) === "#" ? chartSelector.slice(1) : "dataChart-" + ($("canvas").length);
    html = "<canvas id=\"" + newId + "\" class=\"chart dynamic-chart\">\n</canvas>";
    $(appendTo).append(html);
  }
  chartCtx = $(chartSelector);
  chart = new Chart(chartCtx, chartData);
  console.info("Chart created with", chartData);
  return chart;
};

getRandomDataColor = function() {
  var colorString, colors;
  colorString = "rgba(" + (randomInt(0, 255)) + "," + (randomInt(0, 255)) + "," + (randomInt(0, 255));
  colors = {
    border: colorString + ",1)",
    background: colorString + ",0.2"
  };
  return colors;
};

getServerChart = function() {
  var args;
  args = "action=chart";
  $.post(apiTarget, args, "json").done(function(result) {
    var chartData, chartDataJs, chartObj, colors, data, datasets, i, j, len, ref;
    if (result.status === false) {
      console.error("Server had a problem fetching chart data - " + result.human_error);
      console.warn(result);
      return false;
    }
    chartData = result.data;
    datasets = Object.toArray(chartData.datasets);
    i = 0;
    for (j = 0, len = datasets.length; j < len; j++) {
      data = datasets[j];
      data.data = Object.toArray(data.data);
      if (data.borderWidth == null) {
        data.borderWidth = 1;
      }
      if (data.backgroundColor == null) {
        colors = getRandomDataColor();
        data.borderColor = colors.border;
        data.backgroundColor = colors.background;
      }
      datasets[i] = data;
      ++i;
    }
    chartDataJs = {
      labels: Object.toArray(chartData.labels),
      datasets: datasets
    };
    chartObj = {
      data: chartDataJs,
      type: (ref = chartData.type) != null ? ref : "bar"
    };
    createChart("#chart-" + (datasets[0].label.replace(" ", "-")), chartObj);
    return false;
  }).fail(function(result, status) {
    return false;
  });
  return false;
};

$(function() {
  console.log("Loaded dashboard");
  createChart("#sample", {});
  return false;
});

//# sourceMappingURL=maps/dashboard.js.map
