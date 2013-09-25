define ['jquery', 'underscore'], ($, _) ->
  [
    '$scope',
    '$location',
    '$routeParams',
    'dbService'
    ($scope, $location, $routeParams, dbService) ->

      # TODO I think next I need some databaseSelectionService to hold the connection/schema/table then take me to another
      # Page.  That or I could treat this controller as such and smooth scroll down to the next id in the html?

      # You can access the scope of the controller from here
      $scope.welcomeMessage = 'Add Data'

      # Sometimes the modal background doesn't remove when Deleting a dataSet
      #$('body').removeClass('modal-open')
      #$('.modal-backdrop').remove()

      # If the _id param exists in the url go ahead and load the cached data
      if $routeParams['_id']?
        dbService.cacheGet $routeParams['_id'], (data) ->
          console.log "Read cached dataSet: #{JSON.stringify(data._id)}"
      # Otherwise reset the dataSet
      else
        dbService.resetDataSet()

      # When no dataSet defined allow at least setting the name and description
      $scope.dataSetName = undefined
      $scope.dataSetDescription = undefined

      # Hold the paths here
      $scope.connection = undefined
      $scope.schema = undefined
      $scope.table = undefined

      # Hold the results here
      $scope.connections = undefined
      $scope.schemas = undefined
      $scope.tables = undefined
      # $scope.fields = undefined

      if not $scope.connection
        # When database reference selected
        dbService.getConnections '/db/info', (data) -> $scope.connections = data

      $scope.select_connection = (connection) ->
        $scope.connection = connection
        $scope.schemas = []
        $scope.tables = []
        #$scope.fields = []
        dbService.getSchemas $scope.connection, (data) -> $scope.schemas = data

      $scope.select_schema = (schema) ->
        $scope.schema = schema
        $scope.tables = []
        #$scope.fields = []
        dbService.getTables $scope.connection, $scope.schema, (data) -> $scope.tables = data

      $scope.addDataSet = () ->

        # Set the name and description
        if $scope.dataSetName then dbService.dataSet.name = $scope.dataSetName
        if $scope.dataSetDescription then dbService.dataSet.description = $scope.dataSetDescription

        $scope.fields = []
        dbService.getFields $scope.connection, $scope.schema, $scope.table, (data) ->
          dbService.fields = data
          $scope.fields = data

          # Add the connection/schema/table combination to a hash to reference later
          key = [$scope.connection, $scope.schema, $scope.table].join('\u2980')
          #if not _.has(dbService.dataSet.dbReferences, key)
          # I did have it as setting a has as in key: obj, but moving to an array
          dbService.dataSet.dbReferences.push
            key: key,
            connection: $scope.connection,
            schema: $scope.schema,
            table: $scope.table,
            fields: $scope.fields,
            limit: 1000

          # Now save the cache the dataSet object in the backend mongo instance for bookmarkable datasets
          dbService.cacheUpsert (data) ->
            $location.path "/Graph/#{data['_id']}"

      $scope.select_table = (table) ->
        $scope.table = table
        # If an _id already exists, we are adding to the dataset, so just do so
        if dbService.dataSet._id?
          $scope.addDataSet()
        # Otherwise this is a new dataset so popup a modal to at least set the Name/Description
        else
          $('#graph_options_modal').modal()

      # because this has happened asynchroneusly we've missed
      # Angular's initial call to $apply after the controller has been loaded
      # hence we need to explicityly call it at the end of our Controller constructor
      $scope.$apply()
  ]
