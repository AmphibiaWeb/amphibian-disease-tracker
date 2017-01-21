apiTarget = "#{uri.urlString}/api.php"
adminApiTarget = "#{uri.urlString}/admin-api.php"

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
  chartData.data ?= sampleData
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


getServerChart = ->
  # Get the chart
  args = "action=chart"
  $.post apiTarget, args, "json"
  .done (result) ->
    if result.status is false
      console.error "Server had a problem fetching chart data - #{result.human_error}"
      console.warn result
      return false
    chartData = result.data
    datasets = Object.toArray chartData.datasets
    i = 0
    for data in datasets
      data.data = Object.toArray data.data
      datasets[i] = data
      ++i
    chartDataJs =
      labels: Object.toArray chartData.labels
      datasets: datasets
    createChart "#chart-#{datasets[0].label.replace(" ","-")}", chartDataJs
    false
  .fail (result, status) ->
    false
  false


$ ->
  console.log "Loaded dashboard"
  createChart("#sample", {})
  false
