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

      # When no dataSet defined allow at least setting the name and description
      $scope.dataSetName = undefined
      $scope.dataSetDescription = undefined

      # Optional query for NoSQL/Mongo for restricting what docs are selected for the fields introspection
      $scope.restrictionQuery = undefined

      # If the _id param exists in the url go ahead and load the cached data
      if $routeParams['_id']?
        dbService.cacheGet $routeParams['_id'], (data) ->
          console.debug "Read cached dataSet: #{JSON.stringify(data)}"
          $scope.dataSetName = data.name
          $scope.dataSetDescription = data.description
      # Otherwise reset the dataSet
      else
        dbService.resetDataSet()

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
        dbService.getSchemas $scope.connection.name, (data) -> $scope.schemas = data

      $scope.select_schema = (schema) ->
        $scope.schema = schema
        $scope.tables = []
        #$scope.fields = []
        dbService.getTables $scope.connection.name, $scope.schema, (data) -> $scope.tables = data

      $scope.addDataSet = () ->

        # Set the name and description
        if $scope.dataSetName then dbService.dataSet.name = $scope.dataSetName
        if $scope.dataSetDescription then dbService.dataSet.description = $scope.dataSetDescription

        $scope.fields = []
        dbService.getFields $scope.connection.name, $scope.schema, $scope.table, $scope.restrictionQuery, (data) ->
          dbService.fields = data
          $scope.fields = data

          # Add the connection/schema/table combination to a hash to reference later
          key = [$scope.connection.name, $scope.schema, $scope.table].join('\u2980')

          #if not _.has(dbService.dataSet.dbReferences, key)
          # I did have it as setting a has as in key: obj, but moving to an array
          dbService.dataSet.dbReferences.push
            key: key,
            connection: $scope.connection.name,
            schema: $scope.schema,
            table: $scope.table,
            fields: $scope.fields,
            cache: true, # Default to cache each dbReference
            limit: 1000,
            restrictionQuery: $scope.restrictionQuery  # Primarily used for NoSQL dbs to establish the appropriate fields from a chosen doc format

          # Now save the cache the dataSet object in the backend mongo instance for bookmarkable datasets
          dbService.cacheUpsert (data) ->
            $location.path "/Graph/#{data['_id']}"

      $scope.select_table = (table) ->
        $scope.table = table
        $('#graph_options_modal').modal()

        # I was adding the new dataset if one already existed but I should always pop up options.
        ## If an _id already exists, we are adding to the dataset, so just do so
        #if dbService.dataSet._id?
        #  $scope.addDataSet()
        ## Otherwise this is a new dataset so popup a modal to at least set the Name/Description
        #else
        #  $('#graph_options_modal').modal()

      # because this has happened asynchroneusly we've missed
      # Angular's initial call to $apply after the controller has been loaded
      # hence we need to explicityly call it at the end of our Controller constructor
      $scope.$apply()
  ]
