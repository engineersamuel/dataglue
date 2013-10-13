define ['jquery', 'underscore', 'moment', 'dbLogic'], ($, _, moment, dbLogic) ->
  [
    '$scope',
    '$rootScope',
    '$location',
    '$routeParams',
    '$timeout',
    'dbService',
    ($scope, $rootScope, $location, $routeParams, $timeout, dbService) ->

      # Bind LoDash to _ in the scope for {{}} view expressions
      $scope._ = _

      # If the _id param exists in the url go ahead and load the cached data
      $scope._id = $routeParams['_id']
      if $routeParams['_id']?
        dbService.cacheGet $routeParams['_id'], (data) ->
          dbService.dataSet = data
          $scope.dataSet = dbService.dataSet
          $rootScope.$broadcast('dataSetLoaded')
      # Otherwise the dataset is from the service itself, this should not/rarely be encountered.
      else
        # Now make sure the current scope dataSet mirrors the service one
        $scope.dataSet = dbService.dataSet
        $rootScope.$broadcast('dataSetLoaded')

      # Returns true if there is an aggregation, group by, or where set on the field
      $scope.removeDbReference = (idx) ->
        $scope.dataSet.dbReferences.splice idx, 1
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          $rootScope.$broadcast('dataSetLoaded')

      # Copy/duplicate the database reference
      $scope.copyDbReference = (idx) ->
        console.debug "Copying dbReference at idx: #{idx}"
        dbRefToCopy = $scope.dataSet.dbReferences[idx]
        # This says to insert at index idx, 0 means don't remove anything, and dbRefToCopy is what element to add
        $scope.dataSet.dbReferences.splice idx, 0, dbRefToCopy
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          $rootScope.$broadcast('dataSetLoaded')

      # Sync in the graphTypes from the service
      $scope.graphTypes = dbService.graphTypes

      # Sync in the limits from the service
      $scope.limits = dbService.limits

      # Sync up the whereConds
      $scope.whereConds = dbService.whereConds
      $scope.rangeConds = dbService.rangeConds
      $scope.beginRangeConds = dbService.beginRangeConds
      $scope.endRangeConds = dbService.endRangeConds
      $scope.booleanConds = dbService.booleanConds
      $scope.booleanOptions = dbService.booleanOptions

      # Returns true if there is an aggregation, group by, or where set on the field
      $scope.optionsSetOnField = (dbRefIdx, fieldIdx) ->
        field = $scope.dataSet.dbReferences[dbRefIdx].fields[fieldIdx]
        if field.groupBy? and field.groupBy not in [undefined, ''] then return true
        if field.aggregation? and field.aggregation not in [undefined, ''] then return true
        if field.cond? and field.condValue not in [undefined, ''] then return true
        if field.beginCond? and field.beginValue not in [undefined, ''] then return true
        if field.endCond? and field.endValue not in [undefined, ''] then return true
        return false

      # Returns true if there is a group by set on the field
      $scope.groupBySetOnField = (selectedField) ->
        if selectedField? and selectedField.groupBy? and selectedField.groupBy not in [undefined, ''] then return true else return false

      # Returns true if there is an aggregation  set on the field
      $scope.aggregationSetOnField = (selectedField) ->
        if selectedField? and selectedField.aggregation? and selectedField.aggregation not in [undefined, ''] then return true else return false

      # Returns true if there is a where condition set on the field
      $scope.whereSetOnField = (selectedField) ->
        if selectedField? and selectedField.beginValue? and selectedField.beginValue not in [undefined, ''] then return true
        if selectedField? and selectedField.endValue? and selectedField.endValue not in [undefined, ''] then return true
        return false

      # Returns the short display of the option set on a field
      $scope.fieldOptionDisplay = (selectedDbReference, fieldIdx) ->
        field = selectedDbReference?.fields[fieldIdx]
        theHtml = []
        if field?.groupBy? and field.groupBy not in [undefined, ''] then theHtml.push "Group by #{field.groupBy}"
        if field?.aggregation? and field.aggregation not in [undefined, ''] then theHtml.push "Aggregate by #{field.aggregation}"
        if field?.cond? and field.condValue not in [undefined, ''] then theHtml.push "Field #{field.cond} #{field.condValue}"
        if field?.beginCond? and field.beginValue not in [undefined, ''] then theHtml.push "Field #{field.cond} #{field.condValue}"
        if field?.endCond? and field.endValue not in [undefined, ''] then theHtml.push "Field #{field.cond} #{field.condValue}"
#        if field?.beginValue? and field.beginValue not in [undefined, ''] then theHtml.push "Date > #{moment(field.beginValue).format('YYYY-MM-DD')}"
#        if field?.endValue? and field.endValue not in [undefined, ''] then theHtml.push "Date <= #{moment(field.endValue).format('YYYY-MM-DD')}"
#        console.log JSON.stringify(field)
        if theHtml.length is 0
          return 'Field being used.'
        else
          return theHtml.join(' | ')

      # Clear All other fields except the specified field index where the varName is say aggregation or groupBy, ect..
      $scope.resetOtherFields = (dbRefIdx, fieldIdx, varName) ->
        console.debug "Clearing #{varName} from dbRef: #{dbRefIdx}, except field: #{fieldIdx}"

        field = $scope.dataSet.dbReferences[dbRefIdx].fields[fieldIdx]
        if varName is 'groupBy'
          groupByValue = field['groupBy']

          # If the groupBy field value is mutliplex then clear all other multiplexes
          if groupByValue is 'multiplex'
            _.each $scope.dataSet.dbReferences[dbRefIdx].fields, (field, idx) ->
              # As long as the field index isn't the current index, reset the variable on the field
              if fieldIdx isnt idx and field['groupBy'] is 'multiplex'
                delete field[varName]

          # If the groupBy field value isn't multiplex then clear all others except multiplex
          else
            _.each $scope.dataSet.dbReferences[dbRefIdx].fields, (field, idx) ->
              # As long as the field index isn't the current index, reset the variable on the field
              if fieldIdx isnt idx and field['groupBy'] isnt 'multiplex'
                delete field[varName]

        # If not groupBy, where I have to handle multiplex and non-multiplex, just remove all other fields
        else
          _.each $scope.dataSet.dbReferences[dbRefIdx].fields, (field, idx) ->
            # As long as the field index isn't the current index, reset the variable on the field
            if fieldIdx isnt idx
              delete field[varName]

      # find the field index of the selected field
#      getSelectedFieldIndex = () ->
#        fieldIndex = _.findIndex $scope.dataSet.dbReferences[$scope.dbRefIndex].fields, (item) ->
#          if item['COLUMN_NAME']? then item['COLUMN_NAME'] is $scope.selectedFieldName else item is $scope.selectedFieldName
#        return fieldIndex

      # Set the field name assuming the model variable name == the scope variable name
#      updateFields = (variableNames) ->
#        console.debug "Updating fields for dbRefIndex: #{$scope.dbRefIndex}"
#        fieldIndex = getSelectedFieldIndex()
#          # Set each designated field name to the scope field name
#        _.each variableNames, (variableName) ->
#          console.debug "Updating variable: #{variableName} on field #{$scope.dataSet.dbReferences[$scope.dbRefIndex].fields[fieldIndex].COLUMN_NAME} for dbRefIndex: #{$scope.dbRefIndex}"
#          $scope.dataSet.dbReferences[$scope.dbRefIndex].fields[fieldIndex][variableName] = $scope[variableName]

      ##################################################################################################################
      # Handle the conversion of the dataSet to a d3DataSet
      ##################################################################################################################
      $scope.$on 'dataSetLoaded', () ->
        dbService.queryDataSet (data) ->
          dbLogic.processDataSet $scope.dataSet, data, (err, d3Data) ->
            $scope.d3DataSet = d3Data

      ##################################################################################################################
      # Aggregation radio options
      ##################################################################################################################
      $scope.aggregationOptions = [
        {name: 'aggregation', value: undefined, label: 'No Selection', dataTypes: ['*']},
        {name: 'aggregation', value: 'count', label: 'Count', tooltip: "COUNT(field)", dataTypes: dbService.countAggregationDataTypes},
        {name: 'aggregation', value: 'distinctCount', label: 'Distinct Count', tooltip: "COUNT(DISTINCT field)", dataTypes: dbService.countAggregationDataTypes},
        {name: 'aggregation', value: 'sum', label: 'Sum', tooltip: "SUM(field)", dataTypes: dbService.sumAggregationDataTypes},
        {name: 'aggregation', value: 'avg', label: 'Avg', tooltip: "AVG(field)", dataTypes: dbService.avgAggregationDataTypes}
      ]

      ##################################################################################################################
      # Group By radio options
      ##################################################################################################################
      # The filter of group by options will happen dynamically based on the DATA_TYPE of the field in relation to what
      # dataTypes are set on the groupBy option itself.
      $scope.filterByFieldDataType = (opt) -> _.contains(opt.dataTypes, $scope.selectedField?.DATA_TYPE) or _.contains(opt.dataTypes, '*')
      $scope.groupByOptions = [
        {name: 'groupBy', value: undefined, label: 'No Selection', dataTypes: ['*']},
        {name: 'groupBy', value: 'multiplex', label: 'Multiplex', tooltip: 'Multiplexes the x-axis over this field.', dataTypes: ['*']},
#        {name: 'groupBy', value: 'multiplex', label: 'Multiplex', tooltip: 'Multiplexes the x-axis over this field.', dataTypes: dbService.multiplexGroupByTypes},
#        {name: 'groupBy', value: 'field', label: 'Field Itself', tooltip: 'Adds this field as the primary x axis group', dataTypes: dbService.fieldGroupByTypes},
        {name: 'groupBy', value: 'field', label: 'Field Itself', tooltip: 'Adds this field as the primary x axis group', dataTypes: ['*']},
#        {name: 'groupBy', value: 'quarter', label: 'Quarter'},
        {name: 'groupBy', value: 'year', label: 'Year', tooltip: "Groups on DATE_FORMAT(field, '%Y')", dataTypes: dbService.dateGroupByTypes},
        {name: 'groupBy', value: 'month', label: 'Month', tooltip: "Groups on DATE_FORMAT(field, '%Y-%m')", dataTypes: dbService.dateGroupByTypes},
        {name: 'groupBy', value: 'day', label: 'Day', tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d')", dataTypes: dbService.dateGroupByTypes},
        {name: 'groupBy', value: 'hour', label: 'Hour', tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d %H')", dataTypes: dbService.dateGroupByTypes},
        {name: 'groupBy', value: 'minute', label: 'Minute', tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d %H:%M')", dataTypes: dbService.dateGroupByTypes},
        {name: 'groupBy', value: 'second', label: 'Second', tooltip: "Groups on DATE_FORMAT(field, '%Y-%m-%d %H:%M:%S')", dataTypes: dbService.dateGroupByTypes},
      ]

      ##################################################################################################################
      # Modal vars and functions
      ##################################################################################################################
      $scope.selectedReference = undefined
      $scope.selectedField = undefined
      $scope.selectedFieldName = undefined
      $scope.dbRefIndex = undefined
      $scope.fieldIndex = undefined

      $scope.openModalForReference = (dbRefIndex, r) ->
        $scope.dbRefIndex = dbRefIndex
        $scope.selectedReference = r
        $('#dbReferenceModal').modal()

      $scope.openModalForField = (dbRefIndex, r, fieldIndex, f) ->
        $scope.dbRefIndex = dbRefIndex
        $scope.fieldIndex = fieldIndex
        $scope.selectedReference = r
        $scope.selectedField = f
        $scope.selectedFieldName = if f['COLUMN_NAME']? then f['COLUMN_NAME'] else f

        $('#graph_field_modal').modal()

      # Modal for the graph options
      $scope.openModalForOptions = () ->
        $('#graph_options_modal').modal()

      # Update the dataset and by default re-graph the data
      $scope.updateDataSet = (graph=true) ->
        $('#graph_field_modal').modal('hide')
        #variablesToUpdate = ['aggregation', 'groupBy', 'beginValue', 'endValue']
        #updateFields(variablesToUpdate)
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          if graph then $rootScope.$broadcast('dataSetLoaded')

      $scope.deleteDataSet = () ->
        $('#graph_options_modal').modal('hide')
        $timeout ( ->
          dbService.cacheDelete $scope.dataSet._id, () -> $location.path "/AddData/"
        ), 1000

      # Initialize the meta data to a hash of undefined vars
      $scope.updateMetaData = (graph=true) ->
        console.log "Updating graph options with graph name: #{$scope.dataSet.name}"
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          if graph then $rootScope.$broadcast('dataSetLoaded')
      ##################################################################################################################

      ##################################################################################################################
      # Where clause begin/end datepicker
      ##################################################################################################################
      $scope.beginValueOpened = false
      $scope.endValueOpened = false
      $scope.dateOptions =
        'year-format': "'yyyy'",
        'starting-day': 1
      $scope.today = () -> $scope.dt = new Date()
      $scope.clearBeginDate = () -> $scope.beginValue = undefined
      $scope.clearEndDate = () -> $scope.endValue = undefined
      $scope.openBeginDate = () -> $timeout () -> $scope.beginValueOpened = true
      $scope.openEndDate = () -> $timeout () -> $scope.endValueOpened = true
      ##################################################################################################################

      $scope.testGraph = () ->
        dbService.queryDb $scope.connection, $scope.schema, $scope.table, $scope.fields, (data) ->
          console.log data
        console.log "Test graph #{JSON.stringify($scope.fields)}"

      $scope.$apply()
  ]

