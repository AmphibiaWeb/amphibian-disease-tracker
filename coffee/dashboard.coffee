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


createChart = (chartSelector, chartData, isSimpleData = false, appendTo = "main", callback) ->
  unless typeof chartData is "object"
    console.error "Can't create a chart without a data object"
    return false
  if typeof isSimpleData is "function" and isNull callback
    callback = isSimpleData
    isSimpleData = false
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
      scales:
        yAxes: [{
          ticks:
            beginAtZero: true
          }]

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
  if typeof callback is "function"
    callback()
  chart


getRandomDataColor = ->
  colorString = "rgba(#{randomInt(0,255)},#{randomInt(0,255)},#{randomInt(0,255)}"
  colors =
    border: "#{colorString},1)"
    background: "#{colorString},0.2)"
  colors


wait = (ms) ->
  start = new Date().getTime()
  console.log "Will wait #{ms}ms after #{start}"
  end = start
  while end < start + ms
    end = new Date().getTime()
    if window.endWait is true
      end = start + ms + 1
  console.log "Waiting #{ms}ms"
  end


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
    switch result.use_preprocessor
      when "geocoder"
        console.log "Got results", result
        preprocessorFn = (callback) ->
          # Check the bounds of each and use localityFromMapBuilder to
          # check the bounds
          console.log "Starting geocoder preprocessor", datasets
          builtPoints = 0
          labels = new Array()
          dataBin = new Array()
          dataKeyMap = new Object()
          i = 0
          waitFinished = false
          for datablob in datasets
            data = datablob.data
            console.log "Data blob", data
            unless waitFinished
              finished = false
              currentDataset = i
              k = 0
              kprime = 0
            j = 0
            for pointSet in data
              ++j
              unless isNull pointSet.points
                # The data should be an array of coordinates
                builder =
                  points: []
                builtPoints = 0
                console.debug "Using pointset", pointSet
                title = pointSet.title
                project = pointSet.project_id
                for point in Object.toArray pointSet.points
                  console.log "Looking at project ##{project}, '#{title}'"
                  try
                    tempPoint = canonicalizePoint point
                    builder.points.push tempPoint
                    builtPoints++
                if builtPoints is 0
                  console.log "Skipping project ##{project} = '#{title}' with no points"
                  continue
                # Get the country
                k++
                # Google Maps query limit:
                # https://developers.google.com/maps/documentation/geocoding/usage-limits
                #
                # 50 requests per second, client + server
                waitTime = 1000 / 25
                wait waitTime
                localityFromMapBuilder builder, (locality) ->
                  kprime++
                  try
                    for view in geo.geocoderViews
                      unless "country" in view.types
                        continue
                      country = view.formatted_address
                  catch
                    # Bad point, skip the rest of it
                    country = "Multiple Countries"
                    # console.warn "Skipping bad builder", builder
                    # return false
                  if isNull country
                    country = locality
                  console.log "Final locality '#{country}'"
                  # Bin to countries
                  unless country in labels
                    labels.push country
                    dataKeyMap[country] = dataBin.length
                    dataBin.push 1
                  else
                    binKey = dataKeyMap[country]
                    dataBin[binKey]++
                  if kprime is k
                    # Reconstruct the dataset data
                    datablob.data = dataBin
                    datasets[currentDataset] = datablob
                    kprime = 0
                    k = 0
                    waitFinished = false
                    if i is datasets.length
                      # Reconstruct the labels
                      chartData.labels = labels
                      # Finally call back
                      callback()
              if j is data.length
                finished = true
                waitFinished = true
            ++i
      else
        preprocessorFn = (callback) ->
          callback()
    preprocessorFn ->
      chartDataJs =
        labels: Object.toArray chartData.labels
        datasets: datasets
      chartObj =
        data: chartDataJs
        type: chartData.type ? "bar"
      chartSelector = "#chart-#{datasets[0].label.replace(" ","-")}"
      createChart chartSelector, chartObj, ->
        unless isNull result.full_description
          $("#chart-#{datasets[0].label.replace(" ","-")}").before "<h3 class='col-xs-12 text-center chart-title'>#{result.full_description}</h3>"
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
      chartOptions[key] = p$(option).selectedItemLabel.toLowerCase().replace(" ", "-")
  # Remove the old one
  $(".chart.dynamic-chart").remove()
  $(".chart-title").remove()
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
