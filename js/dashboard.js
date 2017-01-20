var createChart;

createChart = function(chartSelector, chartData, isSimpleData, appendTo) {
  var chart, chartCtx, html, newId;
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
  if (chartData.data == null) {
    chartData.data = [1, 2, 3, 4, 5];
  }
  if (chartData.type == null) {
    chartData.type = "bar";
  }
  if (chartData.labels == null) {
    chartData.labels = ["Label1", "Label2", "Label3", "Label4", "Label5"];
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
  return chart = new Chart(chartCtx, chartData);
};

$(function() {
  console.log("Loaded dashboard");
  createChart("#sample", {});
  return false;
});

//# sourceMappingURL=maps/dashboard.js.map
