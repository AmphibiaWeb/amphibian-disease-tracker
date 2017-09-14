var adminApiTarget, apiTarget, createChart, createOverflowMenu, dashboardDisclaimer, dropdownSortEvents, fetchMiniTaxonBlurb, fetchMiniTaxonBlurbs, getRandomDataColor, getServerChart, popShowRangeMap, renderNewChart,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

apiTarget = uri.urlString + "api.php";

adminApiTarget = uri.urlString + "admin-api.php";

window._adp = {
  taxonCharts: new Object()
};

try {
  (createOverflowMenu = function() {

    /*
     * Create the overflow menu lazily
     */
    checkLoggedIn(function(result) {
      var accountSettings, menu;
      accountSettings = result.status ? "    <paper-item data-href=\"" + uri.urlString + "admin\" class=\"click\">\n  <iron-icon icon=\"icons:settings-applications\"></iron-icon>\n  Account Settings\n</paper-item>\n<paper-item data-href=\"" + uri.urlString + "admin-login.php?q=logout\" class=\"click\">\n  <span class=\"glyphicon glyphicon-log-out\"></span>\n  Log Out\n</paper-item>" : "";
      menu = "<paper-menu-button id=\"header-overflow-menu\" vertical-align=\"bottom\" horizontal-offset=\"-15\" horizontal-align=\"right\" vertical-offset=\"30\">\n  <paper-icon-button icon=\"icons:more-vert\" class=\"dropdown-trigger\"></paper-icon-button>\n  <paper-menu class=\"dropdown-content\">\n    " + accountSettings + "\n    <paper-item data-href=\"https://amphibian-disease-tracker.readthedocs.org\" class=\"click\">\n      <iron-icon icon=\"icons:chrome-reader-mode\"></iron-icon>\n      Documentation\n    </paper-item>\n    <paper-item data-href=\"https://github.com/AmphibiaWeb/amphibian-disease-tracker\" class=\"click\">\n      <iron-icon icon=\"glyphicon-social:github\"></iron-icon>\n      Github\n    </paper-item>\n    <paper-item data-href=\"" + uri.urlString + "about.php\" class=\"click\">\n      About / Legal\n    </paper-item>\n  </paper-menu>\n</paper-menu-button>";
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
  var canvas, chart, chartCtx, newId, origChartData, ref, ref1, sampleBarData, sampleData, sampleDatasets;
  if (isSimpleData == null) {
    isSimpleData = false;
  }
  if (appendTo == null) {
    appendTo = "#charts";
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
    console.log("Creating new canvas");
    newId = chartSelector.slice(0, 1) === "#" ? chartSelector.slice(1) : "dataChart-" + ($("canvas").length);
    canvas = document.createElement("canvas");
    canvas.setAttribute("class", "chart dynamic-chart col-xs-12");
    canvas.setAttribute("id", newId);
    try {
      _adp.newCanvas = canvas;
    } catch (undefined) {}
    document.querySelector(appendTo).appendChild(canvas);
  } else {
    console.log("Canvas already exists:", chartSelector);
  }
  if (((ref = _adp.chart) != null ? ref.chart : void 0) != null) {
    _adp.chart.chart.destroy();
  }
  chartCtx = $(chartSelector);
  if (isNull(chartCtx)) {
    try {
      console.log("trying again to make context");
      chartCtx = $(canvas);
    } catch (undefined) {}
  }
  try {
    if (typeof ((ref1 = chartData.options) != null ? ref1.customCallbacks : void 0) !== "object") {
      chartData.options.customCallbacks = {};
    }
  } catch (undefined) {}
  chart = new Chart(chartCtx, chartData);
  _adp.chart = {
    chart: chart,
    ctx: chartCtx
  };
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
  var args, cp, requestKey, requestValue, tested;
  if (chartType == null) {
    chartType = "location";
  }
  startLoad();
  try {
    $("#post-species-summary").remove();
  } catch (undefined) {}
  args = "action=chart&bin=" + chartType;
  if (typeof chartParams === "object") {
    cp = new Array();
    for (requestKey in chartParams) {
      requestValue = chartParams[requestKey];
      cp.push(requestKey + "=" + requestValue);
    }
    args += "&" + (cp.join("&"));
  }
  try {
    if ($("#diseasetested-select").exists()) {
      tested = p$("#diseasetested-select").selectedItem.name;
      if (!isNull(tested)) {
        args += "&disease=" + tested;
      }
    }
  } catch (undefined) {}
  console.debug("Fetching chart with", apiTarget + "?" + args);
  $.post(apiTarget, args, "json").done(function(result) {
    var chartData, colors, data, dataItem, datasets, i, l, len, len1, m, preprocessorFn, ref, s;
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
      console.log("examine data", data);
      if (data.borderWidth == null) {
        data.borderWidth = 1;
      }
      if (data.backgroundColor == null) {
        data.borderColor = new Array();
        data.backgroundColor = new Array();
        s = 0;
        ref = data.data;
        for (m = 0, len1 = ref.length; m < len1; m++) {
          dataItem = ref[m];
          if (data.stack === "PosNeg") {
            if (data.label.toLowerCase().search("positive") !== -1) {
              colors = {
                border: "rgba(220,30,25,1)",
                background: "rgba(220,30,25,0.2)"
              };
            }
            if (data.label.toLowerCase().search("negative") !== -1) {
              colors = {
                border: "rgba(25,70,220,1)",
                background: "rgba(25,70,220,0.2)"
              };
            }
          } else if (data.stack === "totals") {
            if (data.label.toLowerCase().search("total") !== -1) {
              colors = {
                border: "rgba(25,200,90,1)",
                background: "rgba(25,200,90,0.2)"
              };
            }
          } else {
            colors = getRandomDataColor();
          }
          data.borderColor.push(colors.border);
          data.backgroundColor.push(colors.background);
          ++s;
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
      var chartDataJs, chartObj, chartSelector, e, error, error1, error2, error3, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, tooltipPostLabel, uString, uid;
      chartDataJs = {
        labels: Object.toArray(chartData.labels),
        datasets: datasets
      };
      chartObj = {
        data: chartDataJs,
        type: (ref1 = chartData.type) != null ? ref1 : "bar"
      };
      if (!isNull(chartData.stacking)) {
        chartObj.options = {
          scales: {
            xAxes: [
              {
                scaleLabel: {
                  labelString: result.axes.x,
                  display: true
                },
                stacked: chartData.stacking.x
              }
            ],
            yAxes: [
              {
                scaleLabel: {
                  labelString: result.axes.y,
                  display: true
                },
                stacked: chartData.stacking.y
              }
            ]
          }
        };
        if (result.title != null) {
          chartObj.options.title = {
            display: true,
            text: result.title
          };
        }
      } else {
        try {
          if (chartObj.options == null) {
            chartObj.options = {
              scales: {
                xAxes: [
                  {
                    scaleLabel: {}
                  }
                ],
                yAxes: [
                  {
                    scaleLabel: {}
                  }
                ]
              }
            };
          }
          if (result.title != null) {
            chartObj.options.title = {
              display: true,
              text: result.title
            };
          }
          if ((ref2 = chartObj.options) != null) {
            if ((ref3 = ref2.scales) != null) {
              if ((ref4 = ref3.xAxes) != null) {
                if ((ref5 = ref4[0]) != null) {
                  ref5.scaleLabel = {
                    labelString: result.axes.x,
                    display: true
                  };
                }
              }
            }
          }
          if ((ref6 = chartObj.options) != null) {
            if ((ref7 = ref6.scales) != null) {
              if ((ref8 = ref7.yAxes) != null) {
                if ((ref9 = ref8[0]) != null) {
                  ref9.scaleLabel = {
                    labelString: result.axes.y,
                    display: true
                  };
                }
              }
            }
          }
        } catch (error) {
          e = error;
          console.warn("Couldn't set up redundant options - " + e.message);
          console.warn(e.stack);
        }
      }
      try {
        tooltipPostLabel = function(tooltipItems, data) {

          /*
           * Custom tooltip appends after
           *
           * https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/254
           *
           * Modified as per
           * https://stackoverflow.com/a/37552782/1877527
           *
           * Updates raw text ONLY
           * See http://www.chartjs.org/docs/latest/configuration/tooltip.html#tooltip-callbacks
           */
          switch (chartType) {
            case "species":
              return "Click to view the taxon data";
            default:
              return "Click to view the taxon breakdown";
          }
        };
        chartObj.options.tooltips = {
          callbacks: {
            afterLabel: tooltipPostLabel
          }
        };
      } catch (error1) {
        e = error1;
        console.error("Couldn't custom label tooltips! " + e.message);
        console.warn(e.stack);
      }
      try {
        uString = chartDataJs.labels.join("," + JSON.stringify(chartDataJs.datasets));
      } catch (error2) {
        try {
          uString = chartDataJs.labels.join(",");
        } catch (error3) {
          uString = "BAD_STRINGIFY";
        }
      }
      uid = md5(uString);
      chartSelector = "#dataChart-" + (datasets[0].label.replace(/ /g, "-")) + "-" + uid;
      console.log("Creating chart with", chartSelector, chartObj);
      createChart(chartSelector, chartObj, function() {
        var bin, collapseHtml, dataUri, fetchUpdatesFor, html, len2, measurement, measurementSingle, n, ref10, summaryTitle, targetId;
        if (!isNull(result.full_description)) {
          $("#chart-" + (datasets[0].label.replace(" ", "-"))).before("<h3 class='col-xs-12 text-center chart-title'>" + result.full_description + "</h3>");
        }
        if (chartType === "species") {
          fetchUpdatesFor = new Object();
          collapseHtml = "";
          ref10 = chartDataJs.labels;
          for (n = 0, len2 = ref10.length; n < len2; n++) {
            bin = ref10[n];
            if (isNull(bin)) {
              continue;
            }
            targetId = md5(bin + "-" + (Date.now()));
            collapseHtml += "<div class=\"col-xs-12 col-md-6 col-lg-4\">\n  <button type=\"button\" class=\"btn btn-default collapse-trigger\" data-target=\"#" + targetId + "\" id=\"" + targetId + "-button-trigger\" data-taxon=\"" + bin + "\">\n  " + bin + "\n  </button>\n  <iron-collapse id=\"" + targetId + "\" data-bin=\"" + chartParams.sort + "\" data-taxon=\"" + bin + "\" class=\"taxon-collapse\">\n    <div class=\"collapse-content alert\">\n      Binned data for " + bin + ". Should populate this asynchronously ....\n    </div>\n  </iron-collapse>\n</div>";
            fetchUpdatesFor[targetId] = bin;
          }
          if (chartParams.sort === "species") {
            measurement = "species";
            measurementSingle = measurement;
            summaryTitle = measurementSingle + " Summaries";
          } else {
            measurement = "genera";
            measurementSingle = "genus";
            summaryTitle = "Species Summaries by Genus";
          }
          dataUri = _adp.chart.chart.toBase64Image();
          html = "<section id=\"post-species-summary\" class=\"col-xs-12\" style=\"margin-top:2rem;\">\n  <div class=\"row\">\n    <a href=\"" + dataUri + "\" class=\"btn btn-primary pull-right col-xs-8 col-sm-4 col-md-3 col-lg-2\" id=\"download-main-chart\" download disabled>\n      <iron-icon icon=\"icons:cloud-download\"></iron-icon>\n      Download Chart\n    </a>\n  </div>\n  <p hidden>\n    These data are generated from over " + result.rows + " " + measurement + ". AND MORE SUMMARY BLAHDEYBLAH. Per " + measurementSingle + " summary links, etc.\n  </p>\n  <div class=\"row\">\n    <h3 class=\"capitalize col-xs-12\">" + summaryTitle + " <small class=\"text-muted\">Ordered as the above chart</small></h3>\n    <p class=\"col-xs-12 text-muted\">Click on a taxon to toggle charts and more data for that taxon</p>\n    " + collapseHtml + "\n  </div>\n</section>";
          try {
            $("#post-species-summary").remove();
          } catch (undefined) {}
          $(chartSelector).after(html);
          delay(750, function() {
            dataUri = _adp.chart.chart.toBase64Image();
            return $("#download-main-chart").attr("href", dataUri).removeAttr("disabled");
          });
          try {
            bindCollapsors();
            _adp.fetchUpdatesFor = fetchUpdatesFor;
            delay(250, function() {
              return fetchMiniTaxonBlurbs();
            });
          } catch (undefined) {}
          return _adp.chart.ctx.click(function(e) {
            var buttonSelector, color, dataset, elIndex, element, taxon;
            dataset = _adp.chart.chart.getDatasetAtEvent(e);
            element = _adp.chart.chart.getElementAtEvent(e);
            console.debug("Dataset", dataset);
            console.debug("Element", element);
            elIndex = element[0]._index;
            data = dataset[elIndex];
            console.debug("Specific data:", data);
            taxon = data._model.label;
            console.debug("Taxon clicked:", taxon);
            color = getRandomDataColor();
            buttonSelector = "button[data-taxon='" + taxon + "']";
            console.debug("Selector test", buttonSelector, $(buttonSelector).exists());
            $(".success-glow").removeClass("success-glow");
            return $(buttonSelector).addClass("success-glow").get(0).scrollIntoView(false);
          });
        } else if (chartType === "location") {
          return _adp.chart.ctx.click(function(e) {
            var country, dataset, elIndex, element;
            dataset = _adp.chart.chart.getDatasetAtEvent(e);
            element = _adp.chart.chart.getElementAtEvent(e);
            console.debug("Dataset", dataset);
            console.debug("Element", element);
            elIndex = element[0]._index;
            data = dataset[elIndex];
            console.debug("Specific data:", data);
            country = data._model.label;
            console.debug("country clicked:", country);
            args = {
              async: true,
              action: "country_taxon",
              country: country
            };
            $.get("dashboard.php", buildQuery(args, "json")).done(function(result) {
              var chartCtx, labels, negSamples, posSamples, ref11, taxon, taxonData;
              console.debug("Got country result", result);
              if (result.status) {
                console.log("Should build out new chart here");
                chartObj = {
                  type: "bar",
                  options: {
                    responsive: true,
                    title: {
                      display: true,
                      text: "Taxa in " + country
                    },
                    scales: {
                      xAxes: [
                        {
                          scaleLabel: {
                            labelString: "Taxa",
                            display: true
                          }
                        }
                      ],
                      yAxes: [
                        {
                          scaleLabel: {
                            labelString: "Sample Count",
                            display: true
                          },
                          stacked: true
                        }
                      ]
                    }
                  }
                };
                posSamples = {
                  label: "Positive Samples",
                  data: [],
                  borderColor: "rgba(220,30,25,1)",
                  backgroundColor: "rgba(220,30,25,0.3)",
                  borderWidth: 1,
                  stack: "pnSamples"
                };
                negSamples = {
                  label: "Negative Samples",
                  data: [],
                  borderColor: "rgba(25,70,220,1)",
                  backgroundColor: "rgba(25,70,220,0.3)",
                  borderWidth: 1,
                  stack: "pnSamples"
                };
                labels = new Array();
                ref11 = result.data;
                for (taxon in ref11) {
                  taxonData = ref11[taxon];
                  negSamples.data.push(toInt(taxonData["false"]));
                  posSamples.data.push(toInt(taxonData["true"]));
                  labels.push(taxon);
                }
                chartData = {
                  labels: labels,
                  datasets: [posSamples, negSamples]
                };
                chartObj.data = chartData;
                console.log("Using chart data", chartObj);
                uid = JSON.stringify(chartData);
                chartSelector = "#locale-zoom-chart";
                chartCtx = $(chartSelector);
                $(chartSelector).attr("data-uid", uid);
                if (_adp.zoomChart != null) {
                  _adp.zoomChart.destroy();
                }
                _adp.zoomChart = new Chart(chartCtx, chartObj);
              }
              return false;
            });
            return false;
          });
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

dashboardDisclaimer = function(appendAfterSelector) {
  var appendInfoButton, hasAppendedInfo, id;
  if (appendAfterSelector == null) {
    appendAfterSelector = "main > h2 .badge";
  }

  /*
   * Insert a disclaimer
   */
  hasAppendedInfo = false;
  id = "dashboard-disclaimer-popover";
  (appendInfoButton = function(callback, appendAfter) {
    var infoHtml;
    if (!hasAppendedInfo) {
      if (!$(appendAfter).exists()) {
        console.error("Invalid element to append disclaimer info to!");
        return false;
      }
      if (!$("#" + id).exists()) {
        infoHtml = "<paper-icon-button icon=\"icons:info\" data-placement=\"right\" title=\"Please wait...\" id=\"" + id + "\">\n</paper-icon-button>";
        $(appendAfter).after(infoHtml);
        $("#" + id).tooltip();
      }
      hasAppendedInfo = true;
    }
    if (typeof callback === "function") {
      $("#" + id).removeAttr("data-toggle").tooltip("destroy");
      delay(100, (function(_this) {
        return function() {
          return callback("#" + id);
        };
      })(this));
    }
    return false;
  })(void 0, appendAfterSelector);
  checkLoggedIn(function(result) {
    var contentHtml;
    console.debug("CLI callback");
    if (result.status === true) {
      contentHtml = "Data aggregated here are only for publicly available data sets, and those you have permissions to view. There may be samples in the disease repository for which the Principal Investigator(s) has marked as Private, and you lack permissions to view. These are never available in the Dashboard.\n<br/><br/>\nIf you wish to view the data as a member of the public, please either log out or view this page in a \"Private Browsing\" or \"Incognito\" mode.";
    } else {
      contentHtml = "Data aggregated here are only for publicly available data sets. There may be samples in the disease repository for which the Principal Investigator(s) has marked as Private. These are never available in the Dashboard.";
    }
    appendInfoButton(function(selector) {
      if (selector == null) {
        selector = id;
      }
      console.debug("AIB callback for '" + selector + "'", $(selector));
      $(selector).tooltip("destroy").attr("data-toggle", "popover").attr("title", "Data Disclaimer").attr("data-trigger", "focus").attr("role", "button").attr("tabindex", "0").popover({
        content: contentHtml,
        html: true
      });
      console.debug("popover bound");
      return false;
    });
    _adp.appendInfoButton = appendInfoButton;
    console.log(contentHtml);
    return false;
  });
  return false;
};

fetchMiniTaxonBlurbs = function(reference) {
  var collapseSelector, error, ref, selector, taxon, taxonArr, taxonObj;
  if (reference == null) {
    reference = _adp.fetchUpdatesFor;
  }

  /*
   * Called when clicking a taxon / taxon group to fetch the data async
   */
  console.debug("Binding / setting up taxa updates for", reference);
  _adp.collapseOpener = function(collapse) {
    var elapsed;
    if (collapse.opened) {
      elapsed = Date.now() - _adp.lastOpened;
      if (elapsed < 1000) {
        return false;
      }
      collapse.hide();
    } else {
      _adp.lastOpened = Date.now();
      collapse.show();
    }
    return false;
  };
  for (collapseSelector in reference) {
    taxon = reference[collapseSelector];
    selector = "#" + collapseSelector + " .collapse-content";
    try {
      taxonArr = taxon.split(" ");
    } catch (error) {
      continue;
    }
    taxonObj = {
      genus: taxonArr[0],
      species: (ref = taxonArr[1]) != null ? ref : ""
    };
    $("button#" + collapseSelector + "-button-trigger").attr("data-taxon", taxon).click(function() {
      var collapse, hasData, html, ref1, ref2;
      taxon = $(this).attr("data-taxon");
      taxonArr = taxon.split(" ");
      taxonObj = {
        genus: taxonArr[0],
        species: (ref1 = taxonArr[1]) != null ? ref1 : ""
      };
      selector = $(this).parent().find(".collapse-content");
      hasData = (ref2 = $(this).attr("data-has-data")) != null ? ref2 : false;
      if (!hasData.toBool()) {
        $(this).attr("data-has-data", "true");
        html = "<paper-spinner active></paper-spinner> Fetching Data...";
        $(selector).html(html);
        fetchMiniTaxonBlurb(taxonObj, selector);
      } else {
        console.debug("Already has data");
      }
      collapse = $(this).parent().find("iron-collapse").get(0);
      return delay(250, (function(_this) {
        return function() {
          console.debug("is opened?", collapse.opened);
          if (collapse.opened) {
            $("#post-species-summary").addClass("has-open-collapse");
            return $(_this).parent().addClass("is-open");
          } else {
            $("#post-species-summary").removeClass("has-open-collapse");
            return $(".is-open").removeClass("is-open");
          }
        };
      })(this));
    });
  }
  return false;
};

fetchMiniTaxonBlurb = function(taxonResult, targetSelector, isGenus) {
  var args, k, v;
  if (isGenus == null) {
    isGenus = false;
  }
  args = ["action=taxon"];
  for (k in taxonResult) {
    v = taxonResult[k];
    args.push(k + "=" + (encodeURIComponent(v)));
  }
  $.get("api.php", args.join("&"), "json").done(function(result) {
    var blurb, canvas, canvasContainerId, canvasId, chartCfg, chartContainer, chartCtx, containerHtml, countries, countryHtml, data, disease, diseaseData, e, error, error1, extraClasses, fatalData, html, i, idTaxon, iterator, l, len, len1, len2, len3, linkHtml, m, n, name, nameHtml, nameString, names, noSp, o, pieChart, postAppend, project, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, retResult, saveState, taxonData, taxonFormatted, taxonId, taxonString, testingData, title, tooltip;
    console.log("Got result", result);
    if (result.status !== true) {
      html = "<div class=\"alert alert-danger\">\n  <p>\n    <strong>Error:</strong> Couldn't fetch taxon data\n  </p>\n</div>";
      $(targetSelector).html(html);
      return false;
    }
    $(targetSelector).html("");
    if (result.isGenusLookup) {
      iterator = new Array();
      ref = Object.toArray(result.taxa);
      for (l = 0, len = ref.length; l < len; l++) {
        retResult = ref[l];
        iterator.push(retResult.data);
      }
    } else {
      iterator = [result];
    }
    postAppend = new Array();
    for (m = 0, len1 = iterator.length; m < len1; m++) {
      taxonData = iterator[m];
      try {
        console.log("Doing blurb for", JSON.stringify(taxonData.taxon));
        try {
          if (typeof taxonData.amphibiaweb.data.common_name !== "object") {
            throw {
              message: "NOT_OBJECT"
            };
          }
          names = Object.toArray(taxonData.amphibiaweb.data.common_name);
          nameString = "";
          i = 0;
          for (n = 0, len2 = names.length; n < len2; n++) {
            name = names[n];
            ++i;
            if (name === taxonData.iucn.data.main_common_name) {
              name = "<strong>" + (name.trim()) + "</strong>";
            }
            nameString += name.trim();
            if (names.length !== i) {
              nameString += ", ";
            }
          }
        } catch (error) {
          e = error;
          if (typeof taxonData.amphibiaweb.data.common_name === "string") {
            nameString = taxonData.amphibiaweb.data.common_name;
          } else {
            nameString = (ref1 = (ref2 = taxonData.iucn) != null ? (ref3 = ref2.data) != null ? ref3.main_common_name : void 0 : void 0) != null ? ref1 : "";
            console.warn("Couldn't create common name string! " + e.message);
            console.warn(e.stack);
            console.debug(taxonData.amphibiaweb.data);
          }
        }
        if (!isNull(nameString)) {
          nameHtml = "<p>\n  <strong>Names:</strong> " + nameString + "\n</p>";
        } else {
          nameHtml = "";
        }
        countries = Object.toArray(taxonData.adp.countries);
        countryHtml = "<p>Sampled in the following countries:</p>\n<ul class=\"country-list\">\n  <li>" + (countries.join("</li><li>")) + "</li>\n</ul>";
        linkHtml = "<div class='clade-project-summary'>\n  <p>Represented in <strong>" + taxonData.adp.project_count + "</strong> projects with <strong>" + taxonData.adp.samples + "</strong> samples:</p>";
        ref4 = taxonData.adp.projects;
        for (project in ref4) {
          title = ref4[project];
          tooltip = title;
          if (noDefaultRender !== true) {
            if (title.length > 30) {
              title = title.slice(0, 27) + "...";
            }
          }
          linkHtml += "<a class=\"btn btn-primary newwindow project-button-link\" href=\"" + uri.urlString + "/project.php?id=" + project + "\" data-toggle=\"tooltip\" title=\"" + tooltip + "\">\n  " + title + "\n</a>";
        }
        linkHtml += "</div>";
        if (taxonData.adp.samples === 0) {
          linkHtml = "<p>There are no samples of this taxon in our database.</p>";
          countryHtml = "";
        }
        if (result.isGenusLookup || noDefaultRender === true) {
          taxonFormatted = "<span class=\"sciname\">\n  <span class=\"genus\">" + taxonData.taxon.genus + "</span>\n  <span class=\"species\">" + taxonData.taxon.species + "</span>\n</span>";
          taxonId = "<p style='display:inline-block'>\n  <strong>Taxon:</strong> " + taxonFormatted + "\n</p>";
        } else {
          taxonId = "";
        }
        idTaxon = encode64(JSON.stringify(taxonData.taxon));
        idTaxon = idTaxon.replace(/[^\w0-9]/img, "");
        console.log("Appended blurb for idTaxon", idTaxon);
        console.debug("Taxon data:", taxonData, (ref5 = taxonData.amphibiaweb) != null ? ref5.map : void 0);
        blurb = "<div class='blurb-info' id=\"taxon-blurb-" + idTaxon + "\">\n  " + taxonId + "\n  <div style='display:inline-block'>\n    <paper-icon-button\n      icon=\"maps:satellite\"\n      onclick=\"popShowRangeMap(this)\"\n      data-genus=\"" + taxonData.taxon.genus + "\"\n      data-kml=\"" + ((ref6 = taxonData.amphibiaweb) != null ? (ref7 = ref6.map) != null ? ref7.shapefile : void 0 : void 0) + "\"\n      data-species=\"" + taxonData.taxon.species + "\"\n      data-toggle=\"tooltip\"\n      title=\"View Range Map\"\n      data-placement=\"right\">\n    </paper-icon-button>\n  </div>\n  <p>\n    <strong>IUCN Status:</strong> " + taxonData.iucn.category + "\n  </p>\n  " + nameHtml + "\n  " + countryHtml + "\n  <div class=\"charts-container row\">\n  </div>\n  " + linkHtml + "\n  <div class=\"aweb-link-species click\" data-href=\"http://amphibiaweb.org/cgi/amphib_query?rel-genus=equals&rel-species=equals&where-genus=" + (taxonData.taxon.genus.toTitleCase()) + "&where-species=" + taxonData.taxon.species + "\" data-newtab=\"true\">\n    <span class=\"sciname\">\n      " + (taxonData.taxon.genus.toTitleCase()) + " " + taxonData.taxon.species + "\n    </span> on AmphibiaWeb\n    <iron-icon icon=\"icons:open-in-new\"></iron-icon>\n  </div>\n</div>";
        try {
          if (taxonData.taxon.species.search(/sp\./) !== -1) {
            saveState = {
              blurb: blurb,
              taxonData: taxonData,
              idTaxon: idTaxon,
              targetSelector: targetSelector
            };
            postAppend.push(saveState);
            continue;
          }
        } catch (undefined) {}
        $(targetSelector).append(blurb);
        bindClicks();
        formatScientificNames(".aweb-link-species .sciname");
        if (taxonData.adp.samples === 0) {
          stopLoad();
          delay(1000, function() {
            return stopLoad();
          });
        }
        diseaseData = taxonData.adp.disease_data;
        for (disease in diseaseData) {
          data = diseaseData[disease];
          if (data.detected.no_confidence !== data.detected.total) {
            testingData = {
              labels: [disease + " detected", disease + " not detected", disease + " inconclusive data"],
              datasets: [
                {
                  data: [data.detected["true"], data.detected["false"], data.detected.no_confidence],
                  backgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"],
                  hoverBackgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"]
                }
              ]
            };
            chartCfg = {
              type: "pie",
              data: testingData
            };
            canvas = document.createElement("canvas");
            canvas.setAttribute("class", "chart dynamic-pie-chart");
            canvasId = idTaxon + "-" + disease + "-testdata";
            canvas.setAttribute("id", canvasId);
            canvasContainerId = canvasId + "-container";
            chartContainer = $(targetSelector).find("#taxon-blurb-" + idTaxon).find(".charts-container").get(0);
            extraClasses = window.noDefaultRender === true ? "col-xs-6 col-md-4 col-lg-3 " : "";
            containerHtml = "<div id=\"" + canvasContainerId + "\" class=\"" + extraClasses + "taxon-chart\">\n</div>";
            $(chartContainer).append(containerHtml);
            $("#" + canvasContainerId).get(0).appendChild(canvas);
            chartCtx = $("#" + canvasId);
            pieChart = new Chart(chartCtx, chartCfg);
            _adp.taxonCharts[canvasId] = pieChart;
            stopLoad();
          }
          if (data.fatal.unknown !== data.fatal.total) {
            fatalData = {
              labels: [disease + " fatal", disease + " not fatal", disease + " unknown fatality"],
              datasets: [
                {
                  data: [data.fatal["true"], data.fatal["false"], data.fatal.unknown],
                  backgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"],
                  hoverBackgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"]
                }
              ]
            };
            chartCfg = {
              type: "pie",
              data: fatalData
            };
            canvas = document.createElement("canvas");
            canvas.setAttribute("class", "chart dynamic-pie-chart");
            canvasId = idTaxon + "-" + disease + "-fataldata";
            canvas.setAttribute("id", canvasId);
            canvasContainerId = canvasId + "-container";
            chartContainer = $(targetSelector).find(".charts-container").get(0);
            containerHtml = "<div id=\"" + canvasContainerId + "\" class=\"col-xs-6\">\n</div>";
            $(chartContainer).append(containerHtml);
            $("#" + canvasContainerId).get(0).appendChild(canvas);
            chartCtx = $("#" + canvasId);
            pieChart = new Chart(chartCtx, chartCfg);
            _adp.taxonCharts[canvasId] = pieChart;
            stopLoad();
          }
        }
      } catch (error1) {
        e = error1;
        try {
          taxonString = "";
          taxonString = "for\n  <span class=\"sciname\">\n    <span class=\"genus\">" + taxonData.taxon.genus + "</span>\n    <span class=\"species\">" + taxonData.taxon.species + "</span>\n  </span>";
        } catch (undefined) {}
        html = "<div class=\"alert alert-danger\">\n  <p>\n    <strong>Error:</strong> Couldn't fetch taxon data " + taxonString + "\n  </p>\n</div>";
        $(targetSelector).append(html);
        console.error("Couldn't get taxon data -- " + e.message, taxonData);
        console.warn(e.stack);
        stopLoadError();
      }
    }
    if (postAppend.length > 0) {
      console.log("Have " + postAppend.length + " unidentified species");
      for (o = 0, len3 = postAppend.length; o < len3; o++) {
        noSp = postAppend[o];
        try {
          targetSelector = noSp.targetSelector;
          idTaxon = noSp.idTaxon;
          taxonData = noSp.taxonData;
          blurb = noSp.blurb;
          $(targetSelector).append(blurb);
          diseaseData = taxonData.adp.disease_data;
          for (disease in diseaseData) {
            data = diseaseData[disease];
            if (data.detected.no_confidence !== data.detected.total) {
              testingData = {
                labels: [disease + " detected", disease + " not detected", disease + " inconclusive data"],
                datasets: [
                  {
                    data: [data.detected["true"], data.detected["false"], data.detected.no_confidence],
                    backgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"],
                    hoverBackgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"]
                  }
                ]
              };
              chartCfg = {
                type: "pie",
                data: testingData
              };
              canvas = document.createElement("canvas");
              canvas.setAttribute("class", "chart dynamic-pie-chart");
              canvasId = idTaxon + "-" + disease + "-testdata";
              canvas.setAttribute("id", canvasId);
              canvasContainerId = canvasId + "-container";
              chartContainer = $(targetSelector).find("#taxon-blurb-" + idTaxon).find(".charts-container").get(0);
              containerHtml = "<div id=\"" + canvasContainerId + "\" class=\"col-xs-6\">\n</div>";
              $(chartContainer).append(containerHtml);
              $("#" + canvasContainerId).get(0).appendChild(canvas);
              chartCtx = $("#" + canvasId);
              pieChart = new Chart(chartCtx, chartCfg);
              _adp.taxonCharts[canvasId] = pieChart;
              stopLoad();
            }
            if (data.fatal.unknown !== data.fatal.total) {
              fatalData = {
                labels: [disease + " fatal", disease + " not fatal", disease + " unknown fatality"],
                datasets: [
                  {
                    data: [data.fatal["true"], data.fatal["false"], data.fatal.unknown],
                    backgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"],
                    hoverBackgroundColor: ["#FF6384", "#36A2EB", "#FFCE56"]
                  }
                ]
              };
              chartCfg = {
                type: "pie",
                data: fatalData
              };
              canvas = document.createElement("canvas");
              canvas.setAttribute("class", "chart dynamic-pie-chart");
              canvasId = idTaxon + "-" + disease + "-fataldata";
              canvas.setAttribute("id", canvasId);
              canvasContainerId = canvasId + "-container";
              chartContainer = $(targetSelector).find(".charts-container").get(0);
              containerHtml = "<div id=\"" + canvasContainerId + "\" class=\"col-xs-6\">\n</div>";
              $(chartContainer).append(containerHtml);
              $("#" + canvasContainerId).get(0).appendChild(canvas);
              chartCtx = $("#" + canvasId);
              pieChart = new Chart(chartCtx, chartCfg);
              _adp.taxonCharts[canvasId] = pieChart;
              stopLoad();
            }
          }
        } catch (undefined) {}
      }
      stopLoad();
      delay(1000, function() {
        console.debug("Doing 1s delayed stopLoad");
        return stopLoad();
      });
    }
    return false;
  }).error(function(result, status) {
    var html;
    html = "<div class=\"alert alert-danger\">\n  <p>\n    <strong>Error:</strong> Server error fetching taxon data ()\n  </p>\n</div>";
    $(targetSelector).html(html);
    console.error("Couldn't fetch taxon data from server");
    console.warn(result, status);
    stopLoadError();
    return false;
  });
  return false;
};

renderNewChart = function() {
  var chartOptions, chartType, dv, error, key, l, len, option, ref, ref1;
  try {
    if (_adp.zoomChart != null) {
      _adp.zoomChart.destroy();
    }
  } catch (undefined) {}
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
      dv = $(p$(option).selectedItem).attr("data-value");
      if (isNull(dv)) {
        dv = p$(option).selectedItemLabel.toLowerCase().replace(" ", "-");
      }
      chartOptions[key] = dv;
    }
  }
  $(".chart.dynamic-chart").remove();
  $(".chart-title").remove();
  chartType = (ref1 = chartOptions.bin) != null ? ref1 : "location";
  delete chartOptions.bin;
  console.info("Going to generate a new chart with the following options", chartOptions);
  getServerChart(chartType, chartOptions);
  return chartOptions;
};

dropdownSortEvents = function() {
  var doSortDisables;
  if ((typeof _adp !== "undefined" && _adp !== null ? _adp.hasBoundSortDisables : void 0) !== true) {
    $("paper-dropdown-menu#binned-by paper-listbox").on("iron-select", function() {
      return doSortDisables.debounce(50, null, null, this);
    });
    $("paper-dropdown-menu#binned-by paper-listbox > paper-item").click(function() {
      return doSortDisables.debounce(50, null, null, $(this).parents("paper-listbox"));
    });
    _adp.hasBoundSortDisabled = true;
  }
  doSortDisables = function(el) {
    var allowedBins, allowedBinsText, allowedSortKey, binItem, hasFoundKey, item, keyToSelect, kv, l, len, ref, ref1;
    binItem = p$(el).selectedItem;
    console.log("Firing doSortDisables", binItem, el);
    kv = $(binItem).attr("data-value");
    if (isNull(kv)) {
      kv = $(binItem).text().trim().toLowerCase();
    }
    allowedSortKey = kv;
    keyToSelect = 0;
    hasFoundKey = false;
    ref = $("paper-dropdown-menu#sort-by paper-listbox paper-item");
    for (l = 0, len = ref.length; l < len; l++) {
      item = ref[l];
      allowedBinsText = (ref1 = $(item).attr("data-bins")) != null ? ref1 : "";
      allowedBins = allowedBinsText.split(",");
      console.log("Searching allowed bins for '" + allowedSortKey + "'", allowedBins, item);
      if (indexOf.call(allowedBins, allowedSortKey) >= 0) {
        try {
          p$(item).disabled = false;
        } catch (undefined) {}
        $(item).removeAttr("disabled");
        hasFoundKey = true;
      } else {
        try {
          p$(item).disabled = true;
        } catch (undefined) {}
        $(item).attr("disabled", "disabled");
      }
      if (!hasFoundKey) {
        keyToSelect++;
      }
    }
    p$("paper-dropdown-menu#sort-by paper-listbox").selected = keyToSelect;
    return false;
  };
  console.log("Dropdown sort events bound");
  return false;
};

popShowRangeMap = function(taxon, kml) {

  /*
   *
   */
  var args, el, endpoint, genus, html, species;
  if (typeof taxon !== "object") {
    return false;
  }
  el = taxon;
  if (isNull(taxon.genus) || isNull(taxon.species)) {
    try {
      genus = $(taxon).attr("data-genus");
      species = $(taxon).attr("data-species");
      if (isNull(kml)) {
        kml = $(taxon).attr("data-kml");
      }
      taxon = {
        genus: genus,
        species: species
      };
    } catch (undefined) {}
  }
  if (isNull(taxon.genus) || isNull(taxon.species)) {
    toastStatusMessage("Unable to show range map");
    return false;
  }
  if (isNull(kml)) {
    try {
      kml = $(el).attr("data-kml");
    } catch (undefined) {}
    if (isNull(kml)) {
      console.warn("Unable to read KML attr and none passed");
    }
  }
  endpoint = "https://mol.org/species/map/";
  args = {
    embed: "true"
  };
  html = "<paper-dialog modal id=\"species-range-map\" class=\"pop-map dashboard-map\" data-taxon-genus=\"" + taxon.genus + "\" data-taxon-species=\"" + taxon.species + "\">\n  <h2>Range map for <span class=\"genus\">" + taxon.genus + "</span> <span class=\"species\">" + taxon.species + "</span></h2>\n  <paper-dialog-scrollable>\n    <!-- <iframe class=\"mol-embed\" src=\"" + endpoint + (taxon.genus.toTitleCase()) + "_" + taxon.species + "?" + (buildQuery(args)) + "\"></iframe> -->\n  <google-map\n    api-key=\"" + gMapsApiKey + "\"\n    kml=\"" + kml + "\"\n    map-type=\"hybrid\">\n    </google-map>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
  $("#species-range-map").remove();
  $("body").append(html);
  $("#species-range-map").on("iron-overlay-opened", function() {
    var h;
    console.debug("Opened");
    h = $(this).find("paper-dialog-scrollable").height();
    $(this).find("paper-dialog-scrollable > div#scrollable").css("max-height", h + "px").css("height", h + "px");
    console.debug($(this).width(), $(this).height(), h);
    return false;
  });
  p$("#species-range-map").open();
  return true;
};

$(function() {
  var error;
  console.log("Loaded dashboard");
  try {
    if (isNull(window.noDefaultRender)) {
      window.noDefaultRender = false;
    }
  } catch (error) {
    window.noDefaultRender = false;
  }
  console.debug("NDR state", window.noDefaultRender);
  if (window.noDefaultRender !== true) {
    getServerChart();
  }
  $("#generate-chart").click(function() {
    renderNewChart.debounce(50);
    return false;
  });
  $(".tab-area-container .nav-tabs a").click(function(e) {
    e.preventDefault();
    console.debug("Clicked a tab", this);
    $(this).tab("show");
    return false;
  });
  delayPolymerBind("paper-dropdown-menu#binned-by", function() {
    $(".chart-param paper-listbox").on("iron-select", function() {
      console.log("Firing iron-select event", this);
      return renderNewChart.debounce(50);
    });
    $(".chart-param paper-listbox paper-item").on("click", function() {
      console.log("Firing click event on paper-item", this);
      return renderNewChart.debounce(50);
    });
    $("#diseasetested-select").on("selected-item-changed", function() {
      console.log("Firing selection change");
      return renderNewChart.debounce(50);
    });
    dropdownSortEvents();
    return dashboardDisclaimer();
  });
  $.get(apiTarget, "action=higher_taxa", "json");
  return false;
});

//# sourceMappingURL=maps/dashboard.js.map
