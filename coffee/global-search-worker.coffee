###
# Web worker compatriot to
#
# global-search.coffee
#
#
###

self.addEventListener "message", (e) ->
  switch e.data.action
    when "summary-dialog"
      jResultsList = e.data.resultsList
      tableMap = e.data.tableToProjectMap
      getSampleSummaryDialog jResultsList, tableMap, e.data.windowWidth
    when "csv"
      data = e.data.data
      options = e.data.options
      response = downloadCSVFile data, options
      console.info "CSV file successfully generated"
      self.postMessage response
      self.close()

getPrettySpecies = (rowData) ->
  genus = rowData.genus
  species = rowData.specificEpithet ? rowData.specificepithet
  ssp = rowData.infraspecificEpithet ? rowData.infraspecificEpithet
  pretty = genus
  unless isNull species
    pretty += " #{species}"
    unless isNull ssp
      pretty += " #{ssp}"
  pretty

getSampleSummaryDialog = (resultsList, tableToProjectMap, windowWidth) ->
  ###
  # Show a SQL-query like dataset in a modal dialog
  #
  # TODO migrate this to a Web Worker
  # http://www.html5rocks.com/en/tutorials/workers/basics/
  #
  # See
  # https://github.com/AmphibiaWeb/amphibian-disease-tracker/issues/146
  #
  # @param array resultList -> array of Carto responses. Data expected
  #   in "rows" field
  # @param object tableToProjectMap -> Map the table name onto project id
  ###
  startTime = Date.now()
  unless isArray resultsList
    resultsList = Object.toArray resultsList
  if resultsList.length is 0
    console.warn "There were no results in the result list"
    return false
  console.log "Generating dialog from list of length #{resultsList.length}", resultsList
  projectTableRows = new Array()
  projectRawData = new Array()
  outputData = new Array()
  i = 0
  unhelpfulCols = [
    "cartodb_id"
    "the_geom"
    "the_geom_webmercator"
    "id"
    ]
  dataSummary =
    species: []
    diseases: []
    data: {}
  for projectResults in resultsList
    ++i
    dataWidthMax = windowWidth * .5
    dataWidthMin = windowWidth * .3
    try
      rowSet = projectResults.rows
      try
        # Clean up the provided view
        altRows = new Object()
        sortRows = new Object()
        for n, row of projectResults.rows
          # Remove the useless-to-people cols
          for col in unhelpfulCols
            delete row[col]
          altRows[n] = row
          # Add a few others for the CSV download
          row.carto_table = projectResults.table
          row.project_id = projectResults.project_id
          species = getPrettySpecies row
          unless species in dataSummary.species
            dataSummary.species.push species
          d = row.diseasetested
          unless d in dataSummary.diseases
            dataSummary.diseases.push d
          if isNull dataSummary.data[species]
            dataSummary.data[species] = {}
          if isNull dataSummary.data[species][d]
            dataSummary.data[species][d] =
              samples: 0
              positive: 0
              negative: 0
              no_confidence: 0
              prevalence: 0
          if row.diseasedetected.toBool()
            dataSummary.data[species][d].positive++
          else
            if row.diseasedetected.toLowerCase() is "no_confidence"
              dataSummary.data[species][d].no_confidence++
            else
              dataSummary.data[species][d].negative++
          dataSummary.data[species][d].samples++
          prevalence = dataSummary.data[species][d].positive / dataSummary.data[species][d].samples
          dataSummary.data[species][d].prevalence = prevalence
          sortRows[species] = row
          #outputData.push row
        rowSet = altRows
        Object.doOnSortedKeys sortRows, (rowData) ->
          outputData.push rowData
      catch
        # Make sure we have the dat for the CSV download
        for n, row of projectResults.rows
          row.carto_table = projectResults.table
          row.project_id = projectResults.project_id
          outputData.push row
      data = JSON.stringify rowSet
      if isNull data
        console.warn "Got bad data for row ##{i}!", projectResults, projectResults.rows, data
        continue
      data = """#{data}"""
    catch
      data = "Invalid data from server"
    table =
    project = tableToProjectMap[projectResults.table]
    row = """
    <tr>
      <td colspan="4" class="code-box-container"><pre readonly class="code-box language-json" style="max-width:#{dataWidthMax}px;min-width:#{dataWidthMin}px">#{data}</pre></td>
      <td class="text-center"><paper-icon-button data-toggle="tooltip" raised class="click" data-href="https://amphibiandisease.org/project.php?id=#{project.id}" icon="icons:arrow-forward" title="#{project.name}"></paper-icon-button></td>
    </tr>
    """
    projectTableRows.push row
    projectRawData.push data
  # Create the pretty table
  summaryTableRows = new Object()
  summaryTableRowsSortable = new Object()
  summaryDataObj = new Array()
  for species, diseases of dataSummary.data
    for disease, data of diseases
      unless summaryTableRows[disease]?
        summaryTableRows[disease] = new Array()
        summaryTableRowsSortable[disease] = new Object()
      prevalence = data.prevalence * 100
      prevalence = roundNumberSigfig prevalence, 2
      summaryRow = """
      <tr>
        <td>#{species}</td>
        <td>#{data.samples}</td>
        <td>#{data.positive}</td>
        <td>#{data.negative}</td>
        <td>#{prevalence}%</td>
      </tr>
      """
      summaryRowData =
        genus: species.split(" ")[0]
        species: species.split(" ")[1]
        fullScientificName: species
        disease: disease
        samples: data.samples
        positive: data.positive
        negative: data.negative
        prevalence: "#{prevalence}%"
      summaryDataObj.push summaryRowData
      summaryTableRows[disease].push summaryRow
      summaryTableRowsSortable[disease][species] = summaryRow 
  summaryTable = ""
  # for disease, tableRows of summaryTableRows
  for disease, tableRows of summaryTableRowsSortable
    try
      if typeof tableRows is "object"
        tableRowsSimple = new Array()
        Object.doOnSortedKeys tableRows, (row) ->
          tableRowsSimple.push row
      else
        console.warn "Warning: table rows aren't an object"
        tableRowsSimple = tableRows
    catch e
      console.error "Can't sort rows: #{e.message}"
      console.warn e.stack
      tableRowsSimple = summaryTableRows[disease]
    summaryTable += """
    <div class="row">
      <div class="col-xs-12">
        <h3>#{disease}</h3>
        <table class="table table-striped">
          <tr>
            <th>Species</th>
            <th>Samples</th>
            <th>Disease Positive</th>
            <th>Disease Negative</th>
            <th>Disease Prevalence</th>
          </tr>
          #{tableRowsSimple.join("\n")}
        </table>
      </div>
    </div>
    """
  if isNull summaryTable
    summaryTable = "<h3><em>Sorry, we were unable to generate a summary table</em></h3>"
  # Create the whole thing
  rawDataHtml = """
      <div class="row">
        <div class="col-xs-12">
          <h3>Raw Data</h3>
          <table class="table table-striped">
            <tr>
              <th colspan="4">Query Data</th>
              <th>Visit Project</th>
            </tr>
            #{projectTableRows.join("\n")}
          </table>
        </div>
      </div>
  """
  html = """
  <paper-dialog id="modal-sql-details-list" modal always-on-top auto-fit-on-attach>
    <h2>Project Result List</h2>
    <paper-dialog-scrollable>
      #{summaryTable}

    </paper-dialog-scrollable>
    <div class="buttons">
      <paper-button id="generate-download">Create Download</paper-button>
      <paper-button dialog-dismiss>Close</paper-button>
    </div>
  </paper-dialog>
  """
  message =
    html: html
    outputData: outputData
    data: dataSummary
    summaryRowData: summaryDataObj
    summaryRows: summaryTableRows
    providedList: resultsList
    providedMap: tableToProjectMap
    providedWidth: windowWidth
    rawProjectData: projectRawData
    rawDataHtml: rawDataHtml
  elapsed = Date.now() - startTime
  console.info "Worker saved #{elapsed}ms from the main thread"
  self.postMessage message
  self.close()
