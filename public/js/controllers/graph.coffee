define ['jquery', 'underscore', 'moment'], ($, _, moment) ->
  [
    '$scope',
    '$location',
    '$routeParams',
    '$timeout',
    'dbService',
    ($scope, $location, $routeParams, $timeout, dbService) ->

      # If the _id param exists in the url go ahead and load the cached data
      $scope._id = $routeParams['_id']
      if $routeParams['_id']?
        dbService.cacheGet $routeParams['_id'], (data) ->
          dbService.dataSet = data
          $scope.dataSet = dbService.dataSet
      # Otherwise the dataset is from the service itself, this should not/rarely be encountered.
      else
        # Now make sure the current scope dataSet mirrors the service one
        $scope.dataSet = dbService.dataSet

      getSelectedFieldIndex = () ->
        # find the field index of the selected field
        fieldIndex = _.findIndex dbService.dataSet.dbReferences[$scope.selectedReference.key].fields, (item) ->
          if item['COLUMN_NAME']? then item['COLUMN_NAME'] is $scope.selectedFieldName else item is $scope.selectedFieldName
        return fieldIndex

      # Set the field name assuming the model variable name == the scope variable name
      $scope.updateField = (variableNames) ->
        fieldIndex = getSelectedFieldIndex()

          # Set each designated field name to the scope field name
        _.each variableNames, (variableName) ->
          dbService.dataSet.dbReferences[$scope.selectedReference.key].fields[fieldIndex][variableName] = $scope[variableName]

        # Finally update the service reference to the dataSet
        $scope.dataSet = dbService.dataSet

      ##################################################################################################################
      # Handle the conversion of the dataSet to a d3DataSet
      ##################################################################################################################
      $scope.d3DataSet = undefined
      $scope.$watch 'dataSet', () ->
        # Look through each reference in the dataset, and the fields, look for what to group on.  First use case
        # Will be grouping on day

        tmp = {}
        # First if there is not working set of data fetch it from the backend.
        dbData = dbService.queryDataSet (data) ->
          console.log "dataSet: #{data.length} rows"
          # Loop through each dataset
          _.each _.keys(data), (key) ->
            console.log "Looping on key: #{key}"

            tmp[key] = {
              rawValues: undefined
            }
            # Make sure the d3 key is in the hash
            if not tmp[key]['d3']?
              tmp[key]['d3'] = {}

            # Discover any group bys and group by
            _.each dbService.dataSet.dbReferences[key].fields, (field) ->
              console.log "Looping on field: #{JSON.stringify(field)}"

              # Make sure the field is in the hash
              if not tmp[key]['field']?
                tmp[key]['field'] = field

              ################################################
              # Grouping by must always come first
              ################################################
              if field['groupBy']? and field['groupBy'] isnt ""
                groupedRows = undefined
                console.log "Grouping by #{field.groupBy}"
                if field.groupBy is 'year'
                  groupedRows = _.groupBy data[key], (row) ->
                    fieldValue = row[field['COLUMN_NAME']]
                    return moment(fieldValue).format('YYYY')
                else if field['groupBy'] is 'month'
                  groupedRows = _.groupBy data[key], (row) ->
                    fieldValue = row[field['COLUMN_NAME']]
                    return moment(fieldValue).format('YYYY-MM')
                else if field['groupBy'] is 'day'
                  groupedRows = _.groupBy data[key], (row) ->
                    fieldValue = row[field['COLUMN_NAME']]
                    return moment(fieldValue).format('YYYY-MM-DD')

                tmp[key].rawValues = groupedRows

            # Discover aggregations and aggregate
            _.each dbService.dataSet.dbReferences[key].fields, (field) ->
              console.log "Looping on field: #{JSON.stringify(field)}"
              ################################################
              # Then other aggregate operations
              ################################################
              if field['aggregation']? and field['aggregation'] isnt ""
                if field['aggregation'] is 'count'
                  console.log "Aggregating by #{field['aggregation']} on field: #{JSON.stringify(field)}"

                  # If not tmp[key] we have a problem
                  if not tmp[key]?
                    console.error "No tmp[#{key}] found, tmp: #{JSON.stringify(tmp)}"

                  # If not rawValues we have a problem
                  else if not tmp[key].rawValues?
                    console.error "No rawValues found for key: #{key}, tmp[key]: #{JSON.stringify(tmp[key])}"

                  # If there is a group by iterate each group and execute the counts
                  else if not _.isArray(tmp[key].rawValues)
                    # Get a list of the groups
                    _.each _.keys(tmp[key].rawValues), (group) ->
                      # Each group contains an array of database records
                      # The count will result in { field: <number>} which may be desirable later, for now
                      # This assumes the length of the array in each group is the count which is not always
                      # Going to be correct
                      # TODO
                      theCount = _.countBy(tmp[key].rawValues[group], (row) -> return if _.has(row, field['COLUMN_NAME']) then field['COLUMN_NAME'] else undefined)

                      # Since right now I am only concerned with 1d counts, grab the field only
                      theCount = theCount[field['COLUMN_NAME']]

                      console.log "The count of group: #{group} is #{theCount}"

                      # Make sure the hash exists on the d3 group
                      if not tmp[key]['d3'][group]?
                        tmp[key]['d3'][group] = {}

                      # Set the count, which is determined by the field obj
                      tmp[key]['d3'][group]['count'] = theCount

                  # Otherwise we are dealing with an array of values not grouped
                  else if _.isArray tmp.rawValues
                    console.warn "Not yet Implemented!"

          example = [
            {
              "key":"Stream0",
              "values":[
                {"x":0,"y":0.21822935637400104},
                {"x":1,"y":0.9060637492616568},
                {"x":2,"y":4.546998750065884}
              ]
            }
            {
              "key":"Stream1",
              "values":[
                {"x":0,"y":0.12126328994207859},
                {"x":1,"y":0.13279333392038253},
                {"x":2,"y":0.5631966101277897}
              ]
            },
          ]
#Object {kcsdw⦀kcsdw_jjaggars⦀omniture_processed_files: Object}
#  kcsdw⦀kcsdw_jjaggars⦀omniture_processed_files: Object
#    d3: Object
#      2013-07-28: Object
#        count: 173
#      2013-07-29: Object
#        count: 67

          tmpD3DataSet = []
          _.each _.keys(tmp), (dbReference) ->
            stack = {
              key: tmp[dbReference]['field']['COLUMN_NAME']
              values: []
            }
            _.each _.keys(tmp[dbReference]['d3']), (groupedKey) ->
              stack['values'].push
                x: groupedKey
                y: tmp[dbReference]['d3'][groupedKey]['count']
                f: tmp[dbReference]['field']

            # Push the stack onto the d3 dataset
            tmpD3DataSet.push stack


          $scope.d3DataSet = tmpD3DataSet
          console.log tmp
          console.log $scope.d3DataSet

      ##################################################################################################################
      # Aggregation radio options
      ##################################################################################################################
      $scope.aggregation = undefined
      $scope.aggregationOptions = [
        {name: 'aggregation', value: undefined, label: 'No Selection'},
        {name: 'aggregation', value: 'count', label: 'Count'},
        {name: 'aggregation', value: 'distinctCount', label: 'Distinct Count'},
        {name: 'aggregation', value: 'sum', label: 'Sum'},
        {name: 'aggregation', value: 'avg', label: 'Avg'},
        {name: 'aggregation', value: 'median', label: 'Median'},
      ]

      ##################################################################################################################
      # Group By radio options
      ##################################################################################################################
      $scope.groupBy = undefined
      $scope.groupByOptions = [
        {name: 'groupFieldBy', value: undefined, label: 'No Selection'},
        {name: 'groupFieldBy', value: 'field', label: 'Field Itself'},
        {name: 'groupFieldBy', value: 'year', label: 'Year'},
        {name: 'groupFieldBy', value: 'quarter', label: 'Quarter'},
        {name: 'groupFieldBy', value: 'month', label: 'Month'},
        {name: 'groupFieldBy', value: 'day', label: 'Day'},
      ]

      ##################################################################################################################
      # Modal vars and functions
      ##################################################################################################################
      $scope.selectedReference = undefined
      $scope.selectedField = undefined
      $scope.selectedFieldName = undefined
      $scope.openModalForField = (r, f) ->
        $scope.selectedReference = r
        $scope.selectedField = f
        $scope.selectedFieldName = if f['COLUMN_NAME']? then f['COLUMN_NAME'] else f

        # Set all of the options here for each field.
        $scope.aggregation = f['aggregation']
        $scope.groupBy = f['groupBy']
        $scope.beginDate = f['beginDate']
        $scope.endDate = f['endDate']

        $('#graph_field_modal').modal()

      # This assumes that the dbService.dataSet is the latest one and the local scope is kept updated
      $scope.updateDataSet = () ->
        variablesToUpdate = ['aggregation', 'groupBy', 'beginDate', 'endDate']
        $scope.updateField(variablesToUpdate)
        dbService.cacheUpsert () -> undefined
      ##################################################################################################################

      ##################################################################################################################
      # Where clause begin/end datepicker
      ##################################################################################################################
      $scope.beginDate = undefined
      $scope.endDate = undefined
      $scope.beginDateOpened = false
      $scope.endDateOpened = false
      $scope.dateOptions =
        'year-format': "'yyyy'",
        'starting-day': 1
      $scope.today = () -> $scope.dt = new Date()
      $scope.clearBeginDate = () -> $scope.beginDate = undefined
      $scope.clearEndDate = () -> $scope.endDate = undefined
      $scope.openBeginDate = () -> $timeout () -> $scope.beginDateOpened = true
      $scope.openEndDate = () -> $timeout () -> $scope.endDateOpened = true
      ##################################################################################################################

      $scope.testGraph = () ->
        dbService.queryDb $scope.connection, $scope.schema, $scope.table, $scope.fields, (data) ->
          console.log data
        console.log "Test graph #{JSON.stringify($scope.fields)}"


      $scope.$apply();
  ]

