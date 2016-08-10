
/*
 * Web worker compatriot to
 *
 * global-search.coffee
 *
 *
 */
var getSampleSummaryDialog,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

importScripts("c.min.js", "https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js");

self.addEventListener("message", function(e) {
  var jResultsList, tableMap;
  switch (e.data.action) {
    case "summary-dialog":
      jResultsList = e.data.resultsList;
      tableMap = e.data.tableToProjectMap;
      return getSampleSummaryDialog(jResultsList, tableMap);
  }
});

getSampleSummaryDialog = function(resultsList, tableToProjectMap) {

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
  var altRows, col, d, data, dataWidthMax, dataWidthMin, disease, diseases, error, error1, html, i, j, k, len, len1, message, n, outputData, prevalence, project, projectResults, projectTableRows, ref, ref1, ref2, row, rowSet, species, summaryTable, table, tableRows, unhelpfulCols;
  if (!isArray(resultsList)) {
    resultsList = Object.toArray(resultsList);
  }
  if (resultsList.length === 0) {
    console.warn("There were no results in the result list");
    return false;
  }
  console.log("Generating dialog from", resultsList);
  projectTableRows = new Array();
  outputData = new Array();
  i = 0;
  unhelpfulCols = ["cartodb_id", "the_geom", "the_geom_webmercator", "id"];
  window.dataSummary = {
    species: [],
    diseases: [],
    data: {}
  };
  for (j = 0, len = resultsList.length; j < len; j++) {
    projectResults = resultsList[j];
    ++i;
    dataWidthMax = $(window).width() * .5;
    dataWidthMin = $(window).width() * .3;
    try {
      rowSet = projectResults.rows;
      try {
        altRows = new Object();
        ref = projectResults.rows;
        for (n in ref) {
          row = ref[n];
          for (k = 0, len1 = unhelpfulCols.length; k < len1; k++) {
            col = unhelpfulCols[k];
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
          outputData.push(row);
        }
        rowSet = altRows;
      } catch (error) {
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
    } catch (error1) {
      data = "Invalid data from server";
    }
    table = project = tableToProjectMap[projectResults.table];
    row = "<tr>\n  <td colspan=\"4\" class=\"code-box-container\"><pre readonly class=\"code-box language-json\" style=\"max-width:" + dataWidthMax + "px;min-width:" + dataWidthMin + "px\">" + data + "</pre></td>\n  <td class=\"text-center\"><paper-icon-button data-toggle=\"tooltip\" raised class=\"click\" data-href=\"https://amphibiandisease.org/project.php?id=" + project.id + "\" icon=\"icons:arrow-forward\" title=\"" + project.name + "\"></paper-icon-button></td>\n</tr>";
    projectTableRows.push(row);
  }
  window.summaryTableRows = new Object();
  ref2 = dataSummary.data;
  for (species in ref2) {
    diseases = ref2[species];
    for (disease in diseases) {
      data = diseases[disease];
      if (summaryTableRows[disease] == null) {
        summaryTableRows[disease] = new Array();
      }
      prevalence = data.prevalence * 100;
      prevalence = roundNumberSigfig(prevalence, 2);
      summaryTableRows[disease].push("<tr>\n  <td>" + species + "</td>\n  <td>" + data.samples + "</td>\n  <td>" + data.positive + "</td>\n  <td>" + data.negative + "</td>\n  <td>" + prevalence + "%</td>\n</tr>");
    }
  }
  summaryTable = "";
  for (disease in summaryTableRows) {
    tableRows = summaryTableRows[disease];
    summaryTable += "<div class=\"row\">\n  <div class=\"col-xs-12\">\n    <h3>" + disease + "</h3>\n    <table class=\"table table-striped\">\n      <tr>\n        <th>Species</th>\n        <th>Samples</th>\n        <th>Disease Positive</th>\n        <th>Disease Negative</th>\n        <th>Disease Prevalence</th>\n      </tr>\n      " + (tableRows.join("\n")) + "\n    </table>\n  </div>\n</div>";
  }
  html = "<paper-dialog id=\"modal-sql-details-list\" modal always-on-top auto-fit-on-attach>\n  <h2>Project Result List</h2>\n  <paper-dialog-scrollable>\n    " + summaryTable + "\n    <div class=\"row\">\n      <div class=\"col-xs-12\">\n        <h3>Raw Data</h3>\n        <table class=\"table table-striped\">\n          <tr>\n            <th colspan=\"4\">Query Data</th>\n            <th>Visit Project</th>\n          </tr>\n          " + (projectTableRows.join("\n")) + "\n        </table>\n      </div>\n    </div>\n  </paper-dialog-scrollable>\n  <div class=\"buttons\">\n    <paper-button id=\"generate-download\">Create Download</paper-button>\n    <paper-button dialog-dismiss>Close</paper-button>\n  </div>\n</paper-dialog>";
  message = {
    html: html,
    outputData: outputData
  };
  self.postMessage(message);
  return self.close();
};

//# sourceMappingURL=maps/global-search-worker.js.map
