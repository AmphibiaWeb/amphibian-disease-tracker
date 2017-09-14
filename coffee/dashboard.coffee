apiTarget = "#{uri.urlString}api.php"
adminApiTarget = "#{uri.urlString}admin-api.php"

window._adp =
  taxonCharts: new Object()

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


createChart = (chartSelector, chartData, isSimpleData = false, appendTo = "#charts", callback) ->
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
  try
    unless typeof chartData.options?.customCallbacks is "object"
      chartData.options.customCallbacks = {}
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
  try
    $("#post-species-summary").remove()
  args = "action=chart&bin=#{chartType}"
  if typeof chartParams is "object"
    cp = new Array()
    for requestKey, requestValue of chartParams
      cp.push "#{requestKey}=#{requestValue}"
    args += "&#{cp.join "&"}"
  try
    if $("#diseasetested-select").exists()
      tested = p$("#diseasetested-select").selectedItem.name
      unless isNull tested
        args += "&disease=" + tested
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
                labelString: result.axes.x
                display: true
              stacked: chartData.stacking.x
              ]
            yAxes: [
              scaleLabel:
                labelString: result.axes.y
                display: true
              stacked: chartData.stacking.y
              ]
        if result.title?
          chartObj.options.title =
            display: true
            text: result.title
      else
        try
          unless chartObj.options?
            chartObj.options =
              scales:
                xAxes: [
                  scaleLabel: {}
                  ]
                yAxes: [
                  scaleLabel: {}
                  ]
          if result.title?
            chartObj.options.title =
              display: true
              text: result.title
          chartObj.options?.scales?.xAxes?[0]?.scaleLabel =
            labelString: result.axes.x
            display: true
          chartObj.options?.scales?.yAxes?[0]?.scaleLabel =
            labelString: result.axes.y
            display: true
        catch e
          console.warn "Couldn't set up redundant options - #{e.message}"
          console.warn e.stack
      try
        tooltipPostLabel = (tooltipItems, data) ->
          ###
          # Custom tooltip appends after
          #
          # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/254
          #
          # Modified as per
          # https://stackoverflow.com/a/37552782/1877527
          #
          # Updates raw text ONLY
          # See http://www.chartjs.org/docs/latest/configuration/tooltip.html#tooltip-callbacks
          ###
          switch chartType
            when "species"
              return "Click to view the taxon data"
            else
              return "Click to view the taxon breakdown"
        chartObj.options.tooltips =
          callbacks:
            afterLabel: tooltipPostLabel
      catch e
        console.error "Couldn't custom label tooltips! #{e.message}"
        console.warn e.stack
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
            if isNull bin
              continue
            targetId = md5 "#{bin}-#{Date.now()}"
            collapseHtml += """
            <div class="col-xs-12 col-md-6 col-lg-4">
              <button type="button" class="btn btn-default collapse-trigger" data-target="##{targetId}" id="#{targetId}-button-trigger" data-taxon="#{bin}">
              #{bin}
              </button>
              <iron-collapse id="#{targetId}" data-bin="#{chartParams.sort}" data-taxon="#{bin}" class="taxon-collapse">
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
            summaryTitle = "#{measurementSingle} Summaries"
          else
            measurement = "genera"
            measurementSingle = "genus"
            summaryTitle = "Species Summaries by Genus"
          dataUri = _adp.chart.chart.toBase64Image()
          html = """
          <section id="post-species-summary" class="col-xs-12" style="margin-top:2rem;">
            <div class="row">
              <a href="#{dataUri}" class="btn btn-primary pull-right col-xs-8 col-sm-4 col-md-3 col-lg-2" id="download-main-chart" download disabled>
                <iron-icon icon="icons:cloud-download"></iron-icon>
                Download Chart
              </a>
            </div>
            <p hidden>
              These data are generated from over #{result.rows} #{measurement}. AND MORE SUMMARY BLAHDEYBLAH. Per #{measurementSingle} summary links, etc.
            </p>
            <div class="row">
              <h3 class="capitalize col-xs-12">#{summaryTitle} <small class="text-muted">Ordered as the above chart</small></h3>
              <p class="col-xs-12 text-muted">Click on a taxon to toggle charts and more data for that taxon</p>
              #{collapseHtml}
            </div>
          </section>
          """
          try
            $("#post-species-summary").remove()
          $(chartSelector).after html
          delay 750, ->
            dataUri = _adp.chart.chart.toBase64Image()
            $("#download-main-chart")
            .attr "href", dataUri
            .removeAttr "disabled"
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
            console.debug "Selector test", buttonSelector, $(buttonSelector).exists()
            $(".success-glow").removeClass "success-glow"
            $(buttonSelector)
            .addClass "success-glow"
            .get(0).scrollIntoView(false)
        else if chartType is "location"
          # See events from
          # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/232
          # Click events on the chart
          _adp.chart.ctx.click (e) ->
            dataset = _adp.chart.chart.getDatasetAtEvent e
            element = _adp.chart.chart.getElementAtEvent e
            console.debug "Dataset", dataset
            console.debug "Element", element
            elIndex = element[0]._index
            data = dataset[elIndex]
            console.debug "Specific data:", data
            country = data._model.label
            console.debug "country clicked:", country
            # Now we'd like to get a copy of of the country's taxon results
            args =
              async: true
              action: "country_taxon"
              country: country
            $.get "dashboard.php", buildQuery args, "json"
            .done (result) ->
              console.debug "Got country result", result
              if result.status
                console.log "Should build out new chart here"
                # Create main object frame
                chartObj =
                  type: "bar"
                  options:
                    responsive: true
                    title:
                      display: true
                      text: "Taxa in #{country}"
                    scales:
                      xAxes: [
                        scaleLabel:
                          labelString: "Taxa"
                          display: true
                        ]
                      yAxes: [
                        scaleLabel:
                          labelString: "Sample Count"
                          display: true
                        stacked: true
                        ]
                # Create placeholder objects all colorized etc
                posSamples =
                  label: "Positive Samples"
                  data: []
                  borderColor: "rgba(220,30,25,1)"
                  backgroundColor: "rgba(220,30,25,0.3)"
                  borderWidth: 1
                  stack: "pnSamples"
                negSamples =
                  label: "Negative Samples"
                  data: []
                  borderColor: "rgba(25,70,220,1)"
                  backgroundColor: "rgba(25,70,220,0.3)"
                  borderWidth: 1
                  stack: "pnSamples"
                # Build the datasets
                labels = new Array()
                for taxon, taxonData of result.data
                  negSamples.data.push toInt taxonData.false
                  posSamples.data.push toInt taxonData.true
                  labels.push taxon
                # Finish the object
                chartData =
                  labels: labels
                  datasets: [
                    posSamples
                    negSamples
                    ]
                chartObj.data = chartData
                # try
                #   chartObj.options.tooltips =
                #     callbacks:
                #       label: customBarTooltip2
                # catch e
                #   console.error "Couldn't custom label tooltips! #{e.message}"
                #   console.warn e.stack
                console.log "Using chart data", chartObj
                uid = JSON.stringify chartData
                chartSelector = "#locale-zoom-chart"
                chartCtx = $(chartSelector)
                $(chartSelector).attr "data-uid", uid
                # Append a new chart
                if _adp.zoomChart?
                  _adp.zoomChart.destroy()
                _adp.zoomChart = new Chart chartCtx, chartObj
              false
            return false
      stopLoad()
    false
  .fail (result, status) ->
    console.error "AJAX error", result, status
    stopLoadError "There was a problem communicating with the server"
    false
  false


dashboardDisclaimer = (appendAfterSelector = "main > h2 .badge")->
  ###
  # Insert a disclaimer
  ###
  hasAppendedInfo = false
  id = "dashboard-disclaimer-popover"
  do appendInfoButton = (callback = undefined, appendAfter = appendAfterSelector) ->
    unless hasAppendedInfo
      unless $(appendAfter).exists()
        console.error "Invalid element to append disclaimer info to!"
        return false
      unless $("##{id}").exists()
        infoHtml = """
        <paper-icon-button icon="icons:info" data-placement="right" title="Please wait..." id="#{id}">
        </paper-icon-button>
        """
        $(appendAfter).after infoHtml
        $("##{id}").tooltip()
      hasAppendedInfo = true
    if typeof callback is "function"
      # Remove the placeholder tooltip
      $("##{id}")
      .removeAttr "data-toggle"
      .tooltip "destroy"
      delay 100, =>
        callback("##{id}")
    false
  checkLoggedIn (result) ->
    console.debug "CLI callback"
    if result.status is true
      # Logged in
      contentHtml = """
      Data aggregated here are only for publicly available data sets, and those you have permissions to view. There may be samples in the disease repository for which the Principal Investigator(s) has marked as Private, and you lack permissions to view. These are never available in the Dashboard.
      <br/><br/>
      If you wish to view the data as a member of the public, please either log out or view this page in a "Private Browsing" or "Incognito" mode.
      """
    else
      contentHtml = """
      Data aggregated here are only for publicly available data sets. There may be samples in the disease repository for which the Principal Investigator(s) has marked as Private. These are never available in the Dashboard.
      """
    appendInfoButton (selector = id) ->
      console.debug "AIB callback for '#{selector}'", $(selector)
      $(selector)
      .tooltip "destroy"
      .attr "data-toggle", "popover"
      .attr "title", "Data Disclaimer"
      .attr "data-trigger", "focus"
      .attr "role", "button"
      .attr "tabindex", "0"
      .popover {content: contentHtml, html: true}
      console.debug "popover bound"
      false
    _adp.appendInfoButton = appendInfoButton
    console.log contentHtml
    false
  false



fetchMiniTaxonBlurbs = (reference = _adp.fetchUpdatesFor) ->
  ###
  # Called when clicking a taxon / taxon group to fetch the data async
  ###
  console.debug "Binding / setting up taxa updates for", reference
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
    try
      taxonArr = taxon.split " "
    catch
      continue
    taxonObj =
      genus: taxonArr[0]
      species: taxonArr[1] ? ""
    $("button##{collapseSelector}-button-trigger")
    .attr "data-taxon", taxon
    .click ->
      taxon = $(this).attr "data-taxon"
      taxonArr = taxon.split " "
      taxonObj =
        genus: taxonArr[0]
        species: taxonArr[1] ? ""
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
      delay 250, =>
        console.debug "is opened?", collapse.opened
        if collapse.opened
          $("#post-species-summary").addClass "has-open-collapse"
          $(this).parent().addClass "is-open"
        else
          $("#post-species-summary").removeClass "has-open-collapse"
          $(".is-open").removeClass "is-open"
  false




fetchMiniTaxonBlurb = (taxonResult, targetSelector, isGenus = false) ->
  args = [
    "action=taxon"
    ]
  for k, v of taxonResult
    args.push "#{k}=#{encodeURIComponent v}"
  $.get "api.php", args.join("&"), "json"
  .done (result) ->
    console.log "Got result", result
    if result.status isnt true
      html = """
      <div class="alert alert-danger">
        <p>
          <strong>Error:</strong> Couldn't fetch taxon data
        </p>
      </div>
      """
      $(targetSelector).html html
      return false
    $(targetSelector).html ""
    if result.isGenusLookup
      iterator = new Array()
      for retResult in Object.toArray result.taxa
        iterator.push retResult.data
    else
      iterator = [result]
    # Check each taxon
    postAppend = new Array()
    for taxonData in iterator
      try
        console.log "Doing blurb for", JSON.stringify taxonData.taxon
        try
          if typeof taxonData.amphibiaweb.data.common_name isnt "object"
            throw {message:"NOT_OBJECT"}
          names = Object.toArray taxonData.amphibiaweb.data.common_name
          nameString = ""
          i = 0
          for name in names
            ++i
            if name is taxonData.iucn.data.main_common_name
              name = "<strong>#{name.trim()}</strong>"
            nameString += name.trim()
            if names.length isnt i
              nameString += ", "
        catch e
          if typeof taxonData.amphibiaweb.data.common_name is "string"
            nameString = taxonData.amphibiaweb.data.common_name
          else
            nameString = taxonData.iucn?.data?.main_common_name ? ""
            console.warn "Couldn't create common name string! #{e.message}"
            console.warn e.stack
            console.debug taxonData.amphibiaweb.data
        unless isNull nameString
          nameHtml = """
          <p>
            <strong>Names:</strong> #{nameString}
          </p>
          """
        else
          nameHtml = ""
        countries = Object.toArray taxonData.adp.countries
        countryHtml = """
        <p>Sampled in the following countries:</p>
        <ul class="country-list">
          <li>#{countries.join("</li><li>")}</li>
        </ul>
        """
        linkHtml = """
        <div class='clade-project-summary'>
          <p>Represented in <strong>#{taxonData.adp.project_count}</strong> projects with <strong>#{taxonData.adp.samples}</strong> samples:</p>
        """
        for project, title of taxonData.adp.projects
          tooltip = title
          unless noDefaultRender is true
            if title.length > 30
              title = title.slice(0,27) + "..."
          linkHtml += """
          <a class="btn btn-primary newwindow project-button-link" href="#{uri.urlString}/project.php?id=#{project}" data-toggle="tooltip" title="#{tooltip}">
            #{title}
          </a>
          """
        linkHtml += "</div>"
        if taxonData.adp.samples is 0
          linkHtml = "<p>There are no samples of this taxon in our database.</p>"
          countryHtml = ""
        if result.isGenusLookup or noDefaultRender is true
          taxonFormatted = """
            <span class="sciname">
              <span class="genus">#{taxonData.taxon.genus}</span>
              <span class="species">#{taxonData.taxon.species}</span>
            </span>
          """
          taxonId = """
          <p style='display:inline-block'>
            <strong>Taxon:</strong> #{taxonFormatted}
          </p>
          """
        else
          taxonId = ""
        # Create taxon blurb
        idTaxon = encode64 JSON.stringify taxonData.taxon
        idTaxon = idTaxon.replace /[^\w0-9]/img, ""
        console.log "Appended blurb for idTaxon", idTaxon
        console.debug "Taxon data:", taxonData, taxonData.amphibiaweb?.map
        blurb = """
        <div class='blurb-info' id="taxon-blurb-#{idTaxon}">
          #{taxonId}
          <div style='display:inline-block'>
            <paper-icon-button
              icon="maps:satellite"
              onclick="popShowRangeMap(this)"
              data-genus="#{taxonData.taxon.genus}"
              data-kml="#{taxonData.amphibiaweb?.map?.shapefile}"
              data-species="#{taxonData.taxon.species}"
              data-toggle="tooltip"
              title="View Range Map"
              data-placement="right">
            </paper-icon-button>
          </div>
          <p>
            <strong>IUCN Status:</strong> #{taxonData.iucn.category}
          </p>
          #{nameHtml}
          #{countryHtml}
          <div class="charts-container row">
          </div>
          #{linkHtml}
          <div class="aweb-link-species click" data-href="http://amphibiaweb.org/cgi/amphib_query?rel-genus=equals&rel-species=equals&where-genus=#{taxonData.taxon.genus.toTitleCase()}&where-species=#{taxonData.taxon.species}" data-newtab="true">
            <span class="sciname">
              #{taxonData.taxon.genus.toTitleCase()} #{taxonData.taxon.species}
            </span> on AmphibiaWeb
            <iron-icon icon="icons:open-in-new"></iron-icon>
          </div>
        </div>
        """
        try
          if taxonData.taxon.species.search(/sp\./) isnt -1
            saveState = {blurb, taxonData, idTaxon, targetSelector}
            postAppend.push saveState
            continue
        $(targetSelector).append blurb
        bindClicks()
        formatScientificNames(".aweb-link-species .sciname")
        if taxonData.adp.samples is 0
          stopLoad()
          delay 1000, ->
            stopLoad()
        # Create the pie charts
        diseaseData = taxonData.adp.disease_data
        for disease, data of diseaseData
          unless data.detected.no_confidence is data.detected.total
            testingData =
              labels: [
                "#{disease} detected"
                "#{disease} not detected"
                "#{disease} inconclusive data"
                ]
              datasets: [
                data: [data.detected.true, data.detected.false, data.detected.no_confidence]
                backgroundColor: [
                  "#FF6384"
                  "#36A2EB"
                  "#FFCE56"
                  ]
                hoverBackgroundColor: [
                  "#FF6384"
                  "#36A2EB"
                  "#FFCE56"
                  ]
                ]
            chartCfg =
              type: "pie"
              data: testingData
            # Create a canvas for this
            canvas = document.createElement "canvas"
            canvas.setAttribute "class","chart dynamic-pie-chart"
            canvasId = "#{idTaxon}-#{disease}-testdata"
            canvas.setAttribute "id", canvasId
            canvasContainerId = "#{canvasId}-container"
            chartContainer = $(targetSelector).find("#taxon-blurb-#{idTaxon}").find(".charts-container").get(0)
            extraClasses = if window.noDefaultRender is true then "col-xs-6 col-md-4 col-lg-3 " else ""
            containerHtml = """
            <div id="#{canvasContainerId}" class="#{extraClasses}taxon-chart">
            </div>
            """
            $(chartContainer).append containerHtml
            $("##{canvasContainerId}").get(0).appendChild canvas
            chartCtx = $("##{canvasId}")
            pieChart = new Chart chartCtx, chartCfg
            _adp.taxonCharts[canvasId] = pieChart
            stopLoad()
          # Fatality!
          unless data.fatal.unknown is data.fatal.total
            fatalData =
              labels: [
                "#{disease} fatal"
                "#{disease} not fatal"
                "#{disease} unknown fatality"
                ]
              datasets: [
                data: [data.fatal.true, data.fatal.false, data.fatal.unknown]
                backgroundColor: [
                  "#FF6384"
                  "#36A2EB"
                  "#FFCE56"
                  ]
                hoverBackgroundColor: [
                  "#FF6384"
                  "#36A2EB"
                  "#FFCE56"
                  ]
                ]
            chartCfg =
              type: "pie"
              data: fatalData
            # Create a canvas for this
            canvas = document.createElement "canvas"
            canvas.setAttribute "class","chart dynamic-pie-chart"
            canvasId = "#{idTaxon}-#{disease}-fataldata"
            canvas.setAttribute "id", canvasId
            canvasContainerId = "#{canvasId}-container"
            chartContainer = $(targetSelector).find(".charts-container").get(0)
            containerHtml = """
            <div id="#{canvasContainerId}" class="col-xs-6">
            </div>
            """
            $(chartContainer).append containerHtml
            $("##{canvasContainerId}").get(0).appendChild canvas
            chartCtx = $("##{canvasId}")
            pieChart = new Chart chartCtx, chartCfg
            _adp.taxonCharts[canvasId] = pieChart
            stopLoad()
      catch e
        try
          taxonString = ""
          taxonString = """
          for
            <span class="sciname">
              <span class="genus">#{taxonData.taxon.genus}</span>
              <span class="species">#{taxonData.taxon.species}</span>
            </span>
          """
        html = """
        <div class="alert alert-danger">
          <p>
            <strong>Error:</strong> Couldn't fetch taxon data #{taxonString}
          </p>
        </div>
        """
        $(targetSelector).append html
        console.error "Couldn't get taxon data -- #{e.message}", taxonData
        console.warn e.stack
        stopLoadError()
      # End iterator for taxa
    # See if we have any "Foo sp." that need to be stuck at the end
    # See
    # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/238#issue-231413546
    if postAppend.length > 0
      console.log "Have #{postAppend.length} unidentified species"
      for noSp in postAppend
        try # Nonfatal on each iteration
          # Re-establish the variables
          targetSelector = noSp.targetSelector
          idTaxon = noSp.idTaxon
          taxonData = noSp.taxonData
          blurb = noSp.blurb
          # Re-run the end of what happened before
          $(targetSelector).append blurb
          # Create the pie charts
          diseaseData = taxonData.adp.disease_data
          for disease, data of diseaseData
            unless data.detected.no_confidence is data.detected.total
              testingData =
                labels: [
                  "#{disease} detected"
                  "#{disease} not detected"
                  "#{disease} inconclusive data"
                  ]
                datasets: [
                  data: [data.detected.true, data.detected.false, data.detected.no_confidence]
                  backgroundColor: [
                    "#FF6384"
                    "#36A2EB"
                    "#FFCE56"
                    ]
                  hoverBackgroundColor: [
                    "#FF6384"
                    "#36A2EB"
                    "#FFCE56"
                    ]
                  ]
              chartCfg =
                type: "pie"
                data: testingData
              # Create a canvas for this
              canvas = document.createElement "canvas"
              canvas.setAttribute "class","chart dynamic-pie-chart"
              canvasId = "#{idTaxon}-#{disease}-testdata"
              canvas.setAttribute "id", canvasId
              canvasContainerId = "#{canvasId}-container"
              chartContainer = $(targetSelector).find("#taxon-blurb-#{idTaxon}").find(".charts-container").get(0)
              containerHtml = """
              <div id="#{canvasContainerId}" class="col-xs-6">
              </div>
              """
              $(chartContainer).append containerHtml
              $("##{canvasContainerId}").get(0).appendChild canvas
              chartCtx = $("##{canvasId}")
              pieChart = new Chart chartCtx, chartCfg
              _adp.taxonCharts[canvasId] = pieChart
              stopLoad()
            # Fatality!
            unless data.fatal.unknown is data.fatal.total
              fatalData =
                labels: [
                  "#{disease} fatal"
                  "#{disease} not fatal"
                  "#{disease} unknown fatality"
                  ]
                datasets: [
                  data: [data.fatal.true, data.fatal.false, data.fatal.unknown]
                  backgroundColor: [
                    "#FF6384"
                    "#36A2EB"
                    "#FFCE56"
                    ]
                  hoverBackgroundColor: [
                    "#FF6384"
                    "#36A2EB"
                    "#FFCE56"
                    ]
                  ]
              chartCfg =
                type: "pie"
                data: fatalData
              # Create a canvas for this
              canvas = document.createElement "canvas"
              canvas.setAttribute "class","chart dynamic-pie-chart"
              canvasId = "#{idTaxon}-#{disease}-fataldata"
              canvas.setAttribute "id", canvasId
              canvasContainerId = "#{canvasId}-container"
              chartContainer = $(targetSelector).find(".charts-container").get(0)
              containerHtml = """
              <div id="#{canvasContainerId}" class="col-xs-6">
              </div>
              """
              $(chartContainer).append containerHtml
              $("##{canvasContainerId}").get(0).appendChild canvas
              chartCtx = $("##{canvasId}")
              pieChart = new Chart chartCtx, chartCfg
              _adp.taxonCharts[canvasId] = pieChart
              stopLoad()
        # End postAppend loop
      # End postAppend check
      stopLoad()
      delay 1000, ->
        console.debug "Doing 1s delayed stopLoad"
        stopLoad()
    false
  .error (result, status) ->
    html = """
      <div class="alert alert-danger">
        <p>
          <strong>Error:</strong> Server error fetching taxon data ()
        </p>
      </div>
    """
    $(targetSelector).html html
    console.error "Couldn't fetch taxon data from server"
    console.warn result, status
    stopLoadError()
    false
  false






renderNewChart = ->
  # Parse the request
  try
    if _adp.zoomChart?
      _adp.zoomChart.destroy()
  chartOptions = new Object()
  for option in $(".chart-param")
    key = $(option).attr("data-key").replace(" ", "-")
    try
      if p$(option).checked?
        chartOptions[key] = p$(option).checked
      else
        throw "Not Toggle"
    catch
      dv = $(p$(option).selectedItem).attr "data-value"
      if isNull dv
        dv = p$(option).selectedItemLabel.toLowerCase().replace(" ", "-")
      chartOptions[key] = dv
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
    kv = $(binItem).attr "data-value"
    if isNull kv
      kv = $(binItem).text().trim().toLowerCase()
    allowedSortKey = kv
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


popShowRangeMap = (taxon, kml) ->
  ###
  #
  ###
  unless typeof taxon is "object"
    return false
  el = taxon
  if isNull(taxon.genus) or isNull(taxon.species)
    try
      genus = $(taxon).attr "data-genus"
      species = $(taxon).attr "data-species"
      if isNull kml
        kml = $(taxon).attr "data-kml"
      taxon = {genus, species}
  if isNull(taxon.genus) or isNull(taxon.species)
    toastStatusMessage "Unable to show range map"
    return false
  if isNull kml
    try
      kml = $(el).attr "data-kml"
    if isNull kml
      console.warn "Unable to read KML attr and none passed"
  endpoint = "https://mol.org/species/map/"
  args =
    embed: "true"
  html = """
  <paper-dialog modal id="species-range-map" class="pop-map dashboard-map" data-taxon-genus="#{taxon.genus}" data-taxon-species="#{taxon.species}">
    <h2>Range map for <span class="genus">#{taxon.genus}</span> <span class="species">#{taxon.species}</span></h2>
    <paper-dialog-scrollable>
      <!-- <iframe class="mol-embed" src="#{endpoint}#{taxon.genus.toTitleCase()}_#{taxon.species}?#{buildQuery args}"></iframe> -->
    <google-map
      api-key="#{gMapsApiKey}"
      kml="#{kml}"
      map-type="hybrid">
      </google-map>
    </paper-dialog-scrollable>
    <div class="buttons">
      <paper-button dialog-dismiss>Close</paper-button>
    </div>
  </paper-dialog>
  """
  $("#species-range-map").remove()
  $("body").append html
  $("#species-range-map").on "iron-overlay-opened", ->
    console.debug "Opened"
    h = $(this).find("paper-dialog-scrollable").height()
    $(this).find("paper-dialog-scrollable > div#scrollable")
    .css "max-height", "#{h}px"
    .css "height", "#{h}px"
    console.debug $(this).width(), $(this).height(), h
    false
  p$("#species-range-map").open()
  true


$ ->
  console.log "Loaded dashboard"
  try
    if isNull window.noDefaultRender
      window.noDefaultRender = false
  catch
    window.noDefaultRender = false
  console.debug "NDR state", window.noDefaultRender
  unless window.noDefaultRender is true
    getServerChart()
  $("#generate-chart").click ->
    renderNewChart.debounce 50
    false
  $(".tab-area-container .nav-tabs a").click (e) ->
    e.preventDefault()
    console.debug "Clicked a tab", this
    $(this).tab "show"
    false
  delayPolymerBind "paper-dropdown-menu#binned-by", ->
    $(".chart-param paper-listbox")
    .on "iron-select", ->
      console.log "Firing iron-select event", this
      renderNewChart.debounce 50
    $(".chart-param paper-listbox paper-item")
    .on "click", ->
      console.log "Firing click event on paper-item", this
      renderNewChart.debounce 50
    $("#diseasetested-select").on "selected-item-changed", ->
      console.log "Firing selection change"
      renderNewChart.debounce 50
    dropdownSortEvents()
    dashboardDisclaimer()
  # Ping the higher taxa update
  $.get apiTarget, "action=higher_taxa", "json"
  false
