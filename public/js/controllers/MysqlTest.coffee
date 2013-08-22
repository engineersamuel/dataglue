define ['base64'], (base64) ->
  ['$scope', '$http', ($scope, $http) ->
    # You can access the scope of the controller from here
    $scope.welcomeMessage = 'Testing Mysql!'
    $scope.results = []

    # TODO handle the base64 in the service and not here
    $http.post('/db/query', {ref: 'kcsdw', b64_sql: base64.encode('SELECT * FROM sfdc_users limit 50')}).success (data) ->
      $scope.results = data

    # because this has happened asynchroneusly we've missed
    # Angular's initial call to $apply after the controller has been loaded
    # hence we need to explicityly call it at the end of our Controller constructor
    $scope.$apply()
  ]
