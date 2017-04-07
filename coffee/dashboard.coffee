apiTarget = "#{uri.urlString}api.php"
adminApiTarget = "#{uri.urlString}admin-api.php"

window._adp = new Object()

try
  do createOverflowMenu = ->
    ###
    # Create the overflow menu lazily
    ###
    checkLoggedIn (result) ->
      accountSettings = if result.status then """    <paper-item data-href="#{uri.urlString}admin" class="click">
        <iron-icon icon="icons:settings-applications"></iron-icon>
        Account Settings
      </paper-item>
      <paper-item data-href="#{uri.urlString}admin-login.php?q=logout" class="click">
        <span class="glyphicon glyphicon-log-out"></span>
        Log Out
      </paper-item>
      """ else ""
      menu = """
    <paper-menu-button id="header-overflow-menu" vertical-align="bottom" horizontal-offset="-15" horizontal-align="right" vertical-offset="30">
      <paper-icon-button icon="icons:more-vert" class="dropdown-trigger"></paper-icon-button>
      <paper-menu class="dropdown-content">
        #{accountSettings}
        <paper-item data-href="#{uri.urlString}/dashboard.php" class="click">
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
        <paper-item data-href="#{uri.urlString}about.php" class="click">
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
    console.log "Creating new canvas"
    newId = if chartSelector.slice(0,1) is "#" then chartSelector.slice(1) else "dataChart-#{$("canvas").length}"
    canvas = document.createElement "canvas"
    canvas.setAttribute "class","chart dynamic-chart col-xs-12"
    canvas.setAttribute "id", newId
    try
      _adp.newCanvas = canvas
    document.querySelector(appendTo).appendChild canvas
  else
    console.log "Canvas already exists:", chartSelector
  ## Handle the chart
  # http://www.chartjs.org/docs/
  chartCtx = $(chartSelector)
  if isNull chartCtx
    try
      console.log "trying again to make context"
      chartCtx = $(canvas)
  chart = new Chart chartCtx, chartData
  console.info "Chart created with", chartData
  if typeof callback is "function"
    callback()
  chart


getRandomDataColor = ->
  colorString = "rgba(#{randomInt(0,255)},#{randomInt(0,255)},#{randomInt(0,255)}"
  # Translucent
  colors =
    border: "#{colorString},1)"
    background: "#{colorString},0.2)"
  colors



getServerChart = (chartType = "location", chartParams) ->
  # Get the chart
  startLoad()
  args = "action=chart&bin=#{chartType}"
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
    console.debug "Fetched chart", result
    chartData = result.data
    datasets = Object.toArray chartData.datasets
    i = 0
    for data in datasets
      data.data = Object.toArray data.data
      console.log "examine data", data
      data.borderWidth ?= 1
      unless data.backgroundColor?
        data.borderColor = new Array()
        data.backgroundColor = new Array()
        s = 0
        for dataItem in data.data
          try
            console.log "Dataset #{i}: examine dataitem", chartData.labels[s], dataItem
          catch
            console.log "Dataset #{i}-e: examine dataitem", dataItem
          if data.stack is "PosNeg"
            if data.label.toLowerCase().search("positive") isnt -1
              colors =
                border: "rgba(220,30,25,1)"
                background: "rgba(220,30,25,0.2)"
            if data.label.toLowerCase().search("negative") isnt -1
              colors =
                border: "rgba(25,70,220,1)"
                background: "rgba(25,70,220,0.2)"
          else if data.stack is "totals"
            if data.label.toLowerCase().search("total") isnt -1
              colors =
                border: "rgba(25,200,90,1)"
                background: "rgba(25,200,90,0.2)"              
          else
            colors = getRandomDataColor()
          data.borderColor.push colors.border
          data.backgroundColor.push colors.background
          ++s
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
                console.debug "Using pointset", pointSet
                title = pointSet.title
                project = pointSet.project_id
                builder =
                  points: []
                  title: title
                  project: project
                builtPoints = 0
                console.log "Looking at project ##{project}, '#{title}'"
                for point in Object.toArray pointSet.points
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
                waitTime = 1000 / 12.5
                localityFromMapBuilder builder, (locality, cbBuilder) ->
                  kprime++
                  try
                    views = cbBuilder.views ? geo.geocoderViews
                    for view in views
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
                  console.log "Final locality '#{country}' for #{cbBuilder.title}"
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
      unless isNull chartData.stacking
        chartObj.options =
          scales:
            xAxes: [
              stacked: chartData.stacking.x
              ]
            yAxes: [
              stacked: chartData.stacking.y
              ]
      try
        uString = chartDataJs.labels.join "," + JSON.stringify chartDataJs.datasets
      catch
        try
          uString = chartDataJs.labels.join ","
        catch
          uString = "BAD_STRINGIFY"
      uid = md5 uString
      chartSelector = "#dataChart-#{datasets[0].label.replace(/ /g,"-")}-#{uid}"
      console.log "Creating chart with", chartSelector, chartObj
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
  chartType = chartOptions.bin ? "location"
  delete chartOptions.bin
  console.info "Going to generate a new chart with the following options", chartOptions
  getServerChart chartType, chartOptions
  chartOptions



dropdownSortEvents = ->
  $("paper-dropdown-menu#binned-by paper-listbox").on "iron-select", ->
    item = $(this).selectedItem
    allowedSortKey = $(item).trim().text().toLowerCase()
    for item in $("paper-dropdown-menu#sort-by paper-listbox paper-item")
      # Check each item in the li st
      allowedBins = $(item).attr("data-bins").split ","
      if allowedSortKey in allowedBins
        # They're allowed to be selected
        try
          p$(item).disabled = false
        $(item).removeAttr "disabled"
      else
        # Disallowed
        try
          p$(item).disabled = true
        $(item).attr "hidden", "hidden"
    false
  console.log "Dropdown sort events bound"
  false



$ ->
  console.log "Loaded dashboard"
  getServerChart()
  $("#generate-chart").click ->
    renderNewChart.debounce 50
  $(".chart-param paper-listbox").on "iron-select", ->
    renderNewChart.debounce 50
  delayPolymerBind "paper-dropdown-menu#binned-by", ->
    dropdownSortEvents()
  false
