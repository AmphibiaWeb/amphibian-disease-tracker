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
  if _adp.chart?.chart?
    # Get rid of any current ones
    _adp.chart.chart.destroy()
  chartCtx = $(chartSelector)
  if isNull chartCtx
    try
      console.log "trying again to make context"
      chartCtx = $(canvas)
  chart = new Chart chartCtx, chartData
  _adp.chart =
    chart: chart
    ctx: chartCtx
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
          # try
          #   console.log "Dataset #{i}: examine dataitem", chartData.labels[s], dataItem
          # catch
          #   console.log "Dataset #{i}-e: examine dataitem", dataItem
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
              scaleLabel:
                label: result.axes.x
                display: true
              stacked: chartData.stacking.x
              ]
            yAxes: [
              scaleLabel:
                label: result.axes.y
                display: true
              stacked: chartData.stacking.y
              ]
      else
        try
          chartObj.options?.scales?.xAxes?[0]?.scaleLabel =
            label: result.axes.x
            display: true
          chartObj.options?.scales?.yAxes?[0]?.scaleLabel =
            label: result.axes.y
            display: true
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
        if chartType is "species"
          fetchUpdatesFor = new Object()
          # Put a descriptor
          collapseHtml = ""
          for bin in chartDataJs.labels
            targetId = md5 "#{bin}-#{Date.now()}"
            collapseHtml += """
            <div class="col-xs-12 col-md-6 col-lg-4">
              <button type="button" class="btn btn-default collapse-trigger" data-target="##{targetId}" id="#{targetId}-button-trigger">
              #{bin}
              </button>
              <iron-collapse id="#{targetId}" data-bin="#{chartParams.sort}" data-taxon="#{bin}">
                <div class="collapse-content alert">
                  Binned data for #{bin}. Should populate this asynchronously ....
                </div>
              </iron-collapse>
            </div>
            """
            # Store what needs the update fetched
            fetchUpdatesFor[targetId] = bin
          if chartParams.sort is "species"
            measurement = "species"
            measurementSingle = measurement
          else
            measurement = "genera"
            measurementSingle = "genus"
          html = """
          <section id="post-species-summary" class="col-xs-12">
            <p>
              These data are generated from over #{result.rows} #{measurement}. AND MORE SUMMARY BLAHDEYBLAH. Per #{measurementSingle} summary links, etc.
            </p>
            <div class="row">
              <h3 class="capitalize">#{measurementSingle} Summaries</h3>
              #{collapseHtml}
            </div>
          </section>
          """
          try
            $("#post-species-summary").remove()
          $(chartSelector).after html
          try
            bindCollapsors()
            _adp.fetchUpdatesFor = fetchUpdatesFor
            delay 250, ->
              fetchMiniTaxonBlurbs()
          # Click events on the chart
          _adp.chart.ctx.click (e) ->
            dataset = _adp.chart.chart.getDatasetAtEvent e
            element = _adp.chart.chart.getElementAtEvent e
            console.debug "Dataset", dataset
            console.debug "Element", element
            elIndex = element[0]._index
            data = dataset[elIndex]
            console.debug "Specific data:", data
            taxon = data._model.label
            console.debug "Taxon clicked:", taxon
            color = getRandomDataColor()
            buttonSelector = "button[data-taxon='#{taxon}']"
            console.debug "Selector", buttonSelector, $(buttonSelector).exists()
            $(buttonSelector).get(0).scrollIntoView()
      stopLoad()
    false
  .fail (result, status) ->
    console.error "AJAX error", result, status
    stopLoadError "There was a problem communicating with the server"
    false
  false



fetchMiniTaxonBlurbs = (reference = _adp.fetchUpdatesFor) ->
  console.debug "Fetching taxa updates for", reference
  _adp.collapseOpener = (collapse) ->    
    if collapse.opened
      elapsed = Date.now() - _adp.lastOpened
      if elapsed < 1000
        return false
      collapse.hide()
    else
      _adp.lastOpened = Date.now()
      collapse.show()
    #collapse.show()
    #collapse.toggle.debounce(50)
    false
  for collapseSelector, taxon of reference
    selector = "##{collapseSelector} .collapse-content"
    taxonArr = taxon.split " "
    taxonObj =
      genus: taxonArr[0]
      species: taxonArr[1]
    $("button##{collapseSelector}-button-trigger")
    .attr "data-taxon", taxon
    .click ->
      taxon = $(this).attr "data-taxon"
      taxonArr = taxon.split " "
      taxonObj =
        genus: taxonArr[0]
        species: taxonArr[1]
      selector = $(this).parent().find ".collapse-content"
      hasData = $(this).attr("data-has-data") ? false
      unless hasData.toBool()
        $(this).attr "data-has-data", "true"
        html = """
        <paper-spinner active></paper-spinner> Fetching Data...
        """
        $(selector).html html
        fetchMiniTaxonBlurb taxonObj, selector
      else
        console.debug "Already has data"
      collapse = $(this).parent().find("iron-collapse").get(0)
      console.debug "is opened?", collapse.opened
      #_adp.collapseOpener.debounce 300, null, null, collapse
  false


fetchMiniTaxonBlurb = (taxonResult, targetSelector) ->
  args = [
    "action=taxon"
    ]
  for k, v of taxonResult
    args.push "#{k}=#{encodeURIComponent v}"
  $.get "api.php", args.join("&"), "json"
  .done (result) ->
    console.log "Got result", result
    try
      if typeof result.amphibiaweb.data.common_name isnt "object"
        throw {message:"NOT_OBJECT"}
      names = Object.toArray result.amphibiaweb.data.common_name
      nameString = ""
      i = 0
      for name in names
        ++i
        if name is result.iucn.data.main_common_name
          name = "<strong>#{name.trim()}</strong>"
        nameString += name.trim()
        if names.length isnt i
          nameString += ", "
    catch e
      if typeof result.amphibiaweb.data.common_name is "string"
        nameString = result.amphibiaweb.data.common_name
      else
        nameString = result.iucn?.data?.main_common_name ? ""
        console.warn "Couldn't create common name string! #{e.message}"
        console.warn e.stack
        console.debug result.amphibiaweb.data
    unless isNull nameString
      nameHtml = """
      <p>
        <strong>Names:</strong> #{nameString}
      </p>
      """
    else
      nameHtml = ""
    blurb = """
    <div class='blurb-info'>
      <p>
        <strong>IUCN Status:</strong> #{result.iucn.category}
      </p>
      #{nameHtml}
    </div>
    """
    $(targetSelector).html blurb
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
  unless _adp?.hasBoundSortDisables is true
    $("paper-dropdown-menu#binned-by paper-listbox")
    .on "iron-select", ->
      doSortDisables.debounce 50, null, null, this
    $("paper-dropdown-menu#binned-by paper-listbox > paper-item")
    .click ->
      doSortDisables.debounce 50, null, null, $(this).parents("paper-listbox")
    _adp.hasBoundSortDisabled = true
  doSortDisables = (el) ->
    binItem = p$(el).selectedItem
    console.log "Firing doSortDisables", binItem, el
    allowedSortKey = $(binItem).text().trim().toLowerCase()
    keyToSelect = 0
    hasFoundKey = false
    for item in $("paper-dropdown-menu#sort-by paper-listbox paper-item")
      # Check each item in the li st
      allowedBinsText = $(item).attr("data-bins") ? ""
      allowedBins = allowedBinsText.split ","
      console.log "Searching allowed bins for '#{allowedSortKey}'", allowedBins, item
      if allowedSortKey in allowedBins
        # They're allowed to be selected
        try
          p$(item).disabled = false
        $(item).removeAttr "disabled"
        hasFoundKey = true
      else
        # Disallowed
        try
          p$(item).disabled = true
        $(item).attr "disabled", "disabled"
      unless hasFoundKey
        keyToSelect++
    p$("paper-dropdown-menu#sort-by paper-listbox").selected = keyToSelect
    false
  console.log "Dropdown sort events bound"
  false



$ ->
  console.log "Loaded dashboard"
  getServerChart()
  $("#generate-chart").click ->
    renderNewChart.debounce 50
  delayPolymerBind "paper-dropdown-menu#binned-by", ->
    $(".chart-param paper-listbox")
    .on "iron-select", ->
      console.log "Firing iron-select event", this
      renderNewChart.debounce 50
    $(".chart-param paper-listbox paper-item")
    .on "click", ->
      console.log "Firing click event on paper-item", this
      renderNewChart.debounce 50
    dropdownSortEvents()
  false
