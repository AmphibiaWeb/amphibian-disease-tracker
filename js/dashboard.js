var adminApiTarget, apiTarget, createChart, createOverflowMenu, dropdownSortEvents, fetchMiniTaxonBlurb, fetchMiniTaxonBlurbs, getRandomDataColor, getServerChart, renderNewChart,
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
      menu = "<paper-menu-button id=\"header-overflow-menu\" vertical-align=\"bottom\" horizontal-offset=\"-15\" horizontal-align=\"right\" vertical-offset=\"30\">\n  <paper-icon-button icon=\"icons:more-vert\" class=\"dropdown-trigger\"></paper-icon-button>\n  <paper-menu class=\"dropdown-content\">\n    " + accountSettings + "\n    <paper-item data-href=\"" + uri.urlString + "/dashboard.php\" class=\"click\">\n      Data Dashboard\n    </paper-item>\n    <paper-item data-href=\"https://amphibian-disease-tracker.readthedocs.org\" class=\"click\">\n      <iron-icon icon=\"icons:chrome-reader-mode\"></iron-icon>\n      Documentation\n    </paper-item>\n    <paper-item data-href=\"https://github.com/AmphibiaWeb/amphibian-disease-tracker\" class=\"click\">\n      <iron-icon icon=\"glyphicon-social:github\"></iron-icon>\n      Github\n    </paper-item>\n    <paper-item data-href=\"" + uri.urlString + "about.php\" class=\"click\">\n      About / Legal\n    </paper-item>\n  </paper-menu>\n</paper-menu-button>";
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
  var canvas, chart, chartCtx, newId, origChartData, ref, sampleBarData, sampleData, sampleDatasets;
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
  var args, cp, requestKey, requestValue;
  if (chartType == null) {
    chartType = "location";
  }
  startLoad();
  args = "action=chart&bin=" + chartType;
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
      var chartDataJs, chartObj, chartSelector, e, error, error1, error2, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, uString, uid;
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
        uString = chartDataJs.labels.join("," + JSON.stringify(chartDataJs.datasets));
      } catch (error1) {
        try {
          uString = chartDataJs.labels.join(",");
        } catch (error2) {
          uString = "BAD_STRINGIFY";
        }
      }
      uid = md5(uString);
      chartSelector = "#dataChart-" + (datasets[0].label.replace(/ /g, "-")) + "-" + uid;
      console.log("Creating chart with", chartSelector, chartObj);
      createChart(chartSelector, chartObj, function() {
        var bin, collapseHtml, dataUri, fetchUpdatesFor, html, len2, measurement, measurementSingle, n, ref10, targetId;
        if (!isNull(result.full_description)) {
          $("#chart-" + (datasets[0].label.replace(" ", "-"))).before("<h3 class='col-xs-12 text-center chart-title'>" + result.full_description + "</h3>");
        }
        if (chartType === "species") {
          fetchUpdatesFor = new Object();
          collapseHtml = "";
          ref10 = chartDataJs.labels;
          for (n = 0, len2 = ref10.length; n < len2; n++) {
            bin = ref10[n];
            targetId = md5(bin + "-" + (Date.now()));
            collapseHtml += "<div class=\"col-xs-12 col-md-6 col-lg-4\">\n  <button type=\"button\" class=\"btn btn-default collapse-trigger\" data-target=\"#" + targetId + "\" id=\"" + targetId + "-button-trigger\">\n  " + bin + "\n  </button>\n  <iron-collapse id=\"" + targetId + "\" data-bin=\"" + chartParams.sort + "\" data-taxon=\"" + bin + "\">\n    <div class=\"collapse-content alert\">\n      Binned data for " + bin + ". Should populate this asynchronously ....\n    </div>\n  </iron-collapse>\n</div>";
            fetchUpdatesFor[targetId] = bin;
          }
          if (chartParams.sort === "species") {
            measurement = "species";
            measurementSingle = measurement;
          } else {
            measurement = "genera";
            measurementSingle = "genus";
          }
          dataUri = _adp.chart.chart.toBase64Image();
          html = "<section id=\"post-species-summary\" class=\"col-xs-12\" style=\"margin-top:2rem;\">\n  <div class=\"row\">\n    <a href=\"" + dataUri + "\" class=\"btn btn-primary pull-right col-xs-8 col-sm-4 col-md-3 col-lg-2\" id=\"download-main-chart\" download>\n      <iron-icon icon=\"icons:cloud-download\"></iron-icon>\n      Download Chart\n    </a>\n  </div>\n  <p>\n    These data are generated from over " + result.rows + " " + measurement + ". AND MORE SUMMARY BLAHDEYBLAH. Per " + measurementSingle + " summary links, etc.\n  </p>\n  <div class=\"row\">\n    <h3 class=\"capitalize\">" + measurementSingle + " Summaries</h3>\n    " + collapseHtml + "\n  </div>\n</section>";
          try {
            $("#post-species-summary").remove();
          } catch (undefined) {}
          $(chartSelector).after(html);
          delay(300, function() {
            dataUri = _adp.chart.chart.toBase64Image();
            return $("#download-main-chart").attr("href", dataUri);
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
            console.debug("Selector", buttonSelector, $(buttonSelector).exists());
            $(".success-glow").removeClass("success-glow");
            return $(buttonSelector).addClass("success-glow").get(0).scrollIntoView(false);
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

fetchMiniTaxonBlurbs = function(reference) {
  var collapseSelector, selector, taxon, taxonArr, taxonObj;
  if (reference == null) {
    reference = _adp.fetchUpdatesFor;
  }
  console.debug("Fetching taxa updates for", reference);
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
    taxonArr = taxon.split(" ");
    taxonObj = {
      genus: taxonArr[0],
      species: taxonArr[1]
    };
    $("button#" + collapseSelector + "-button-trigger").attr("data-taxon", taxon).click(function() {
      var collapse, hasData, html, ref;
      taxon = $(this).attr("data-taxon");
      taxonArr = taxon.split(" ");
      taxonObj = {
        genus: taxonArr[0],
        species: taxonArr[1]
      };
      selector = $(this).parent().find(".collapse-content");
      hasData = (ref = $(this).attr("data-has-data")) != null ? ref : false;
      if (!hasData.toBool()) {
        $(this).attr("data-has-data", "true");
        html = "<paper-spinner active></paper-spinner> Fetching Data...";
        $(selector).html(html);
        fetchMiniTaxonBlurb(taxonObj, selector);
      } else {
        console.debug("Already has data");
      }
      collapse = $(this).parent().find("iron-collapse").get(0);
      return console.debug("is opened?", collapse.opened);
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
    var blurb, canvas, canvasContainerId, canvasId, chartCfg, chartContainer, chartCtx, containerHtml, countries, countryHtml, data, disease, diseaseData, e, error, fatalData, i, idTaxon, l, len, linkHtml, name, nameHtml, nameString, names, pieChart, project, ref, ref1, ref2, ref3, testingData, title, tooltip;
    console.log("Got result", result);
    try {
      if (typeof result.amphibiaweb.data.common_name !== "object") {
        throw {
          message: "NOT_OBJECT"
        };
      }
      names = Object.toArray(result.amphibiaweb.data.common_name);
      nameString = "";
      i = 0;
      for (l = 0, len = names.length; l < len; l++) {
        name = names[l];
        ++i;
        if (name === result.iucn.data.main_common_name) {
          name = "<strong>" + (name.trim()) + "</strong>";
        }
        nameString += name.trim();
        if (names.length !== i) {
          nameString += ", ";
        }
      }
    } catch (error) {
      e = error;
      if (typeof result.amphibiaweb.data.common_name === "string") {
        nameString = result.amphibiaweb.data.common_name;
      } else {
        nameString = (ref = (ref1 = result.iucn) != null ? (ref2 = ref1.data) != null ? ref2.main_common_name : void 0 : void 0) != null ? ref : "";
        console.warn("Couldn't create common name string! " + e.message);
        console.warn(e.stack);
        console.debug(result.amphibiaweb.data);
      }
    }
    if (!isNull(nameString)) {
      nameHtml = "<p>\n  <strong>Names:</strong> " + nameString + "\n</p>";
    } else {
      nameHtml = "";
    }
    countries = Object.toArray(result.adp.countries);
    countryHtml = "<ul class=\"country-list\">\n  <li>" + (countries.join("</li><li>")) + "</li>\n</ul>";
    linkHtml = "<div class='clade-project-summary'>\n  <p>Represented in <strong>" + result.adp.project_count + "</strong> projects with <strong>" + result.adp.samples + "</strong> samples</p>";
    ref3 = result.adp.projects;
    for (project in ref3) {
      title = ref3[project];
      tooltip = title;
      if (title.length > 30) {
        title = title.slice(0, 27) + "...";
      }
      linkHtml += "<a class=\"btn btn-primary newwindow project-button-link\" href=\"" + uri.urlString + "/project.php?id=" + project + "\" data-toggle=\"tooltip\" title=\"" + tooltip + "\">\n  " + title + "\n</a>";
    }
    linkHtml += "</div>";
    blurb = "<div class='blurb-info'>\n  <p>\n    <strong>IUCN Status:</strong> " + result.iucn.category + "\n  </p>\n  " + nameHtml + "\n  <p>Sampled in the following countries:</p>\n  " + countryHtml + "\n  " + linkHtml + "\n  <div class=\"charts-container row\">\n  </div>\n</div>";
    $(targetSelector).html(blurb);
    idTaxon = encode64(JSON.stringify(taxonResult));
    idTaxon = idTaxon.replace(/[^\w0-9]/img, "");
    diseaseData = result.adp.disease_data;
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
        chartContainer = $(targetSelector).find(".charts-container").get(0);
        containerHtml = "<div id=\"" + canvasContainerId + "\" class=\"col-xs-6\">\n</div>";
        $(chartContainer).append(containerHtml);
        $("#" + canvasContainerId).get(0).appendChild(canvas);
        chartCtx = $("#" + canvasId);
        pieChart = new Chart(chartCtx, chartCfg);
        _adp.taxonCharts[canvasId] = pieChart;
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
      }
    }
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
    var allowedBins, allowedBinsText, allowedSortKey, binItem, hasFoundKey, item, keyToSelect, l, len, ref, ref1;
    binItem = p$(el).selectedItem;
    console.log("Firing doSortDisables", binItem, el);
    allowedSortKey = $(binItem).text().trim().toLowerCase();
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

$(function() {
  console.log("Loaded dashboard");
  getServerChart();
  $("#generate-chart").click(function() {
    return renderNewChart.debounce(50);
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
    return dropdownSortEvents();
  });
  return false;
});

//# sourceMappingURL=maps/dashboard.js.map
