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
  unless isArray resultsList
    resultsList = Object.toArray resultsList
  if resultsList.length is 0
    console.warn "There were no results in the result list"
    return false
  console.log "Generating dialog from", resultsList
  projectTableRows = new Array()
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
          outputData.push row
        rowSet = altRows
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
  # Create the pretty table
  summaryTableRows = new Object()
  for species, diseases of dataSummary.data
    for disease, data of diseases
      unless summaryTableRows[disease]?
        summaryTableRows[disease] = new Array()
      prevalence = data.prevalence * 100
      prevalence = roundNumberSigfig prevalence, 2
      summaryTableRows[disease].push """
      <tr>
        <td>#{species}</td>
        <td>#{data.samples}</td>
        <td>#{data.positive}</td>
        <td>#{data.negative}</td>
        <td>#{prevalence}%</td>
      </tr>
      """
  summaryTable = ""
  for disease, tableRows of summaryTableRows
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
          #{tableRows.join("\n")}
        </table>
      </div>
    </div>
    """
  if isNull summaryTable
    summaryTable = "<h3>Sorry, we were unable to generate a summary table</h3>"
  # Create the whole thing
  html = """
  <paper-dialog id="modal-sql-details-list" modal always-on-top auto-fit-on-attach>
    <h2>Project Result List</h2>
    <paper-dialog-scrollable>
      #{summaryTable}
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
    summaryRows: summaryTableRows
  self.postMessage message
  self.close()
