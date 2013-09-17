define ['jquery', 'underscore', 'moment', 'dbLogic'], ($, _, moment, dbLogic) ->
  [
    '$scope',
    '$rootScope',
    '$location',
    '$routeParams',
    '$timeout',
    'dbService',
    ($scope, $rootScope, $location, $routeParams, $timeout, dbService) ->

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
        $scope.dataSet.dbReferences.splice idx 1
        # dbService.dataSet.dbReferences.splice idx, 1
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          $rootScope.$broadcast('dataSetLoaded')


      # Returns true if there is an aggregation, group by, or where set on the field
      $scope.optionsSetOnField = (field) ->
        if field.groupBy? and field.groupBy not in [undefined, ''] then return true
        if field.aggregation? and field.aggregation not in [undefined, ''] then return true
        if field.beginDate? and field.beginDate not in [undefined, ''] then return true
        if field.endDate? and field.endDate not in [undefined, ''] then return true
        return false

      # find the field index of the selected field
      getSelectedFieldIndex = () ->
        fieldIndex = _.findIndex $scope.dataSet.dbReferences[$scope.dbRefIndex].fields, (item) ->
          if item['COLUMN_NAME']? then item['COLUMN_NAME'] is $scope.selectedFieldName else item is $scope.selectedFieldName
        return fieldIndex

      # Set the field name assuming the model variable name == the scope variable name
      updateFields = (variableNames) ->
        fieldIndex = getSelectedFieldIndex()
          # Set each designated field name to the scope field name
        _.each variableNames, (variableName) ->
          $scope.dataSet.dbReferences[$scope.dbRefIndex].fields[fieldIndex][variableName] = $scope[variableName]

      ##################################################################################################################
      # Handle the conversion of the dataSet to a d3DataSet
      ##################################################################################################################
      $scope.$on 'dataSetLoaded', () ->
        dbService.queryDataSet (data) ->
          dbLogic.processDataSet $scope.dataSet, data, (err, d3Data) ->
            $scope.d3DataSet = d3Data

      # TODO, create various events so I only fetch the data when necessary and re-process
      $scope.$on 'dataSetFieldChange', () -> dbLogic.processDataSet $scope.dataSet
      $scope.$on 'dataSetFieldChange', () -> dbLogic.processDataSet $scope.dataSet

      ##################################################################################################################
      # Aggregation radio options
      ##################################################################################################################
      $scope.aggregation = undefined
      $scope.aggregationOptions = [
        {name: 'aggregation', value: undefined, label: 'No Selection'},
        {name: 'aggregation', value: 'count', label: 'Count'},
        {name: 'aggregation', value: 'distinctCount', label: 'Distinct Count'},
        {name: 'aggregation', value: 'sum', label: 'Sum'},
        {name: 'aggregation', value: 'avg', label: 'Avg'}
      ]

      ##################################################################################################################
      # Group By radio options
      ##################################################################################################################
      $scope.groupBy = undefined
      $scope.groupByOptions = [
        {name: 'groupFieldBy', value: undefined, label: 'No Selection'},
        {name: 'groupFieldBy', value: 'field', label: 'Field Itself'},
        {name: 'groupFieldBy', value: 'year', label: 'Year'},
#        {name: 'groupFieldBy', value: 'quarter', label: 'Quarter'},
        {name: 'groupFieldBy', value: 'month', label: 'Month'},
        {name: 'groupFieldBy', value: 'day', label: 'Day'},
        {name: 'groupFieldBy', value: 'hour', label: 'Hour'},
      ]

      ##################################################################################################################
      # Modal vars and functions
      ##################################################################################################################
      $scope.selectedReference = undefined
      $scope.selectedField = undefined
      $scope.selectedFieldName = undefined
      $scope.openModalForField = (dbRefIndex, r, f) ->
        $scope.dbRefIndex = dbRefIndex
        $scope.selectedReference = r
        $scope.selectedField = f
        $scope.selectedFieldName = if f['COLUMN_NAME']? then f['COLUMN_NAME'] else f

        # Set all of the options here for each field.
        $scope.aggregation = f['aggregation']
        $scope.groupBy = f['groupBy']
        $scope.beginDate = f['beginDate']
        $scope.endDate = f['endDate']

        $('#graph_field_modal').modal()

      # Modal for the graph options
      $scope.openModalForOptions = () ->
        $('#graph_options_modal').modal()

      # Update the dataset and by default re-graph the data
      $scope.updateDataSet = (graph=true) ->
        variablesToUpdate = ['aggregation', 'groupBy', 'beginDate', 'endDate']
        updateFields(variablesToUpdate)
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          if graph then $rootScope.$broadcast('dataSetLoaded')

      $scope.deleteDataSet = () ->
        $('#graph_options_modal').modal('hide')
        $timeout ( ->
          dbService.cacheDelete $scope.dataSet._id, () -> $location.path "/AddData/"
        ), 1000

      # Initialize the meta data to a hash of undefined vars
      $scope.updateMetaData = () ->
        console.log "Updating graph options with graph name: #{$scope.dataSet.name}"
        dbService.dataSet = $scope.dataSet
        dbService.cacheUpsert () ->
          console.log "dataSet upserted, setting the scope to dbService.dataSet"
          $rootScope.$broadcast('dataSetLoaded')
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

      $scope.$apply()
  ]

