
createChart = (chartSelector, chartData, isSimpleData = false, appendTo = "main") ->
  unless typeof chartData is "object"
    console.error "Can't create a chart without a data object"
    return false
  ###
  # Sample build
  ###
  # How a dataset is constructed
  sampleBarData =
    label: "Sample Data"
    data: [65, 59, 80, 81, 56, 55, 40]
    borderWidth: 1
    borderColor: [
      'rgba(255,99,132,1)',
      'rgba(54, 162, 235, 1)'
      'rgba(255, 206, 86, 1)'
      'rgba(75, 192, 192, 1)'
      'rgba(153, 102, 255, 1)'
      'rgba(255, 159, 64, 1)'
      ]
    backgroundColor: [
      'rgba(255, 99, 132, 0.2)'
      'rgba(54, 162, 235, 0.2)'
      'rgba(255, 206, 86, 0.2)'
      'rgba(75, 192, 192, 0.2)'
      'rgba(153, 102, 255, 0.2)'
      'rgba(255, 159, 64, 0.2)'
      ]
  # The data should be an array of datasets
  sampleDatasets = [
    sampleBarData
    ]
  ###
  # Sample bits for a sample bar graph
  ###
  chartData.labels ?= ["January", "February", "March", "April", "May", "June", "July"]
  chartData.data ?= sampleDatasets
  chartData.type ?= "bar"
  unless typeof chartData.options is "object"
    chartData.options =
      responsive: true

  unless $(chartSelector).exists()
    newId = if chartSelector.slice(0,1) is "#" then chartSelector.slice(1) else "dataChart-#{$("canvas").length}"
    html = """
    <canvas id="#{newId}" class="chart dynamic-chart">
    </canvas>
    """
    $(appendTo).append html
  ## Handle the chart
  # http://www.chartjs.org/docs/
  chartCtx = $(chartSelector)
  chart = new Chart chartCtx, chartData
  console.info "Chart created with", chartData
  chart


$ ->
  console.log "Loaded dashboard"
  createChart("#sample", {})
  false
