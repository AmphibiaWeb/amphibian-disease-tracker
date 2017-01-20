var createChart;

createChart = function(chartSelector, chartData, isSimpleData, appendTo) {
  var chart, chartCtx, html, newId, sampleBarData, sampleDatasets;
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

  /*
   * Sample bits for a sample bar graph
   */
  if (chartData.labels == null) {
    chartData.labels = ["January", "February", "March", "April", "May", "June", "July"];
  }
  if (chartData.data == null) {
    chartData.data = sampleDatasets;
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

$(function() {
  console.log("Loaded dashboard");
  createChart("#sample", {});
  return false;
});

//# sourceMappingURL=maps/dashboard.js.map
