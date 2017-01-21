apiTarget = "#{uri.urlString}api.php"
adminApiTarget = "#{uri.urlString}admin-api.php"

window._adp = new Object()

try
  do createOverflowMenu = ->
    ###
    # Create the overflow menu lazily
    ###
    checkLoggedIn (result) ->
      accountSettings = if result.status then """    <paper-item data-href="https://amphibiandisease.org/admin" class="click">
        <iron-icon icon="icons:settings-applications"></iron-icon>
        Account Settings
      </paper-item>
      <paper-item data-href="https://amphibiandisease.org/admin-login.php?q=logout" class="click">
        <span class="glyphicon glyphicon-log-out"></span>
        Log Out
      </paper-item>
      """ else ""
      menu = """
    <paper-menu-button id="header-overflow-menu" vertical-align="bottom" horizontal-offset="-15" horizontal-align="right" vertical-offset="30">
      <paper-icon-button icon="icons:more-vert" class="dropdown-trigger"></paper-icon-button>
      <paper-menu class="dropdown-content">
        #{accountSettings}
        <paper-item disabled data-href="https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/176" class="click">
          Summary Dashboard
        </paper-item>
        <paper-item data-href="https://amphibian-disease-tracker.readthedocs.org" class="click">
          <iron-icon icon="icons:chrome-reader-mode"></iron-icon>
          Documentation
        </paper-item>
        <paper-item data-href="https://github.com/AmphibiaWeb/amphibian-disease-tracker" class="click">
          <iron-icon icon="glyphicon-social:github"></iron-icon>
          Github
        </paper-item>
        <paper-item data-href="https://amphibiandisease.org/about.php" class="click">
          About / Legal
        </paper-item>
      </paper-menu>
    </paper-menu-button>
      """
      $("#header-overflow-menu").remove()
      $("header#header-bar .logo-container + p").append menu
      unless isNull accountSettings
        $("header#header-bar paper-icon-button[icon='icons:settings-applications']").remove()
      bindClicks()
    false


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
  # The actual data object
  sampleData =
    labels: ["January", "February", "March", "April", "May", "June", "July"]
    datasets: sampleDatasets
  ###
  # Sample bits for a sample bar graph
  ###
  if isNull chartData.data
    origChartData = chartData
    console.warn "No data for chart, will use sample data", origChartData
  chartData.data ?= sampleData
  chartData.type ?= "bar"
  unless typeof chartData.options is "object"
    chartData.options =
      responsive: true

  unless $(chartSelector).exists()
    newId = if chartSelector.slice(0,1) is "#" then chartSelector.slice(1) else "dataChart-#{$("canvas").length}"
    html = """
    <canvas id="#{newId}" class="chart dynamic-chart col-xs-12">
    </canvas>
    """
    $(appendTo).append html
  ## Handle the chart
  # http://www.chartjs.org/docs/
  chartCtx = $(chartSelector)
  chart = new Chart chartCtx, chartData
  console.info "Chart created with", chartData
  chart


getRandomDataColor = ->
  colorString = "rgba(#{randomInt(0,255)},#{randomInt(0,255)},#{randomInt(0,255)}"
  colors =
    border: "#{colorString},1)"
    background: "#{colorString},0.2)"
  colors


getServerChart = (chartType = "infection", chartParams) ->
  # Get the chart
  startLoad()
  args = "action=chart&sort=#{chartType}"
  if typeof chartParams is "object"
    cp = new Array()
    for requestKey, requestValue of chartParams
      cp.push "#{requestKey}=#{requestValue}"
    args += "&#{cp.join "&"}"
  console.debug "Fetching chart with", "#{apiTarget}?#{args}"
  $.post apiTarget, args, "json"
  .done (result) ->
    if result.status is false
      console.error "Server had a problem fetching chart data - #{result.human_error}"
      console.warn result
      stopLoadError result.human_error
      return false
    chartData = result.data
    datasets = Object.toArray chartData.datasets
    i = 0
    for data in datasets
      data.data = Object.toArray data.data
      data.borderWidth ?= 1
      unless data.backgroundColor?
        data.borderColor = new Array()
        data.backgroundColor = new Array()
        for dataItem in data.data
          colors = getRandomDataColor()
          data.borderColor.push colors.border
          data.backgroundColor.push colors.background
      datasets[i] = data
      ++i
    chartDataJs =
      labels: Object.toArray chartData.labels
      datasets: datasets
    chartObj =
      data: chartDataJs
      type: chartData.type ? "bar"
    createChart "#chart-#{datasets[0].label.replace(" ","-")}", chartObj
    stopLoad()
    false
  .fail (result, status) ->
    console.error "AJAX error", result, status
    stopLoadError "There was a problem communicating with the server"
    false
  false


renderNewChart = ->
  # Parse the request
  chartOptions = new Object()
  for option in $(".chart-param")
    key = $(option).attr("data-key").replace(" ", "-")
    try
      if p$(option).checked?
        chartOptions[key] = p$(option).checked
      else
        throw "Not Toggle"
    catch
      chartOptions[key] = p$(option).selectedItemLabel.toLowerCase()
  # Remove the old one
  $(".chart.dynamic-chart").remove()
  # Get the new one
  chartType = chartOptions.sort ? "infection"
  delete chartOptions.sort
  console.info "Going to generate a new chart with the following options", chartOptions
  getServerChart chartType, chartOptions
  chartOptions



$ ->
  console.log "Loaded dashboard"
  getServerChart()
  $("#generate-chart").click ->
    renderNewChart.debounce 50
  false
