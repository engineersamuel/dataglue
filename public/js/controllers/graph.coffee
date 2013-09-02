define ['jquery', 'underscore'], ($, _) ->
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
      $scope.d3DataSet = []
      $scope.$watch 'dataSet', () ->
        # Look through each reference in the dataset, and the fields, look for what to group on.  First use case
        # Will be grouping on day

        # First if there is not working set of data fetch it from the backend.
        # TODO fetching each time now, in the future cach it
        dbData = dbService.queryDataSet (data) ->
          console.log "dataSet: #{JSON.stringify(data)}"
#        service.queryDb = function(ref, schema, table, fields, callback) {


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
        {name: 'groupFieldBy', value: 'field', label: 'Field itself'},
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

