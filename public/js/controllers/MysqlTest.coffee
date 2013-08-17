define [], () ->
  ['$scope', '$http', ($scope, $http) ->
    # You can access the scope of the controller from here
    $scope.welcomeMessage = 'Testing Mysql!'
    $scope.results = []

    $http.get('/kcsdw').success (data) ->
      $scope.results = data

    # because this has happened asynchroneusly we've missed
    # Angular's initial call to $apply after the controller has been loaded
    # hence we need to explicityly call it at the end of our Controller constructor
    $scope.$apply();
  ]
