
createChart = (chartSelector, chartData, isSimpleData = false, appendTo = "main") ->
  unless typeof chartData is "object"
    console.error "Can't create a chart without a data object"
  chartData.data ?= [1,2,3,4,5]
  chartData.type ?= "bar"
  chartData.labels ?= ["Label1", "Label2", "Label3", "Label4", "Label5"]
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



$ ->
  console.log "Loaded dashboard"
  createChart("#sample")
  false
