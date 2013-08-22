define [], () ->
  ['$scope', '$http', 'sharedProperties', 'connectionService', 'notificationService', ($scope, $http, sharedProperties, connectionService, notificationService) ->
    # You can access the scope of the controller from here
    $scope.welcomeMessage = 'Add Data'
#    $scope.scopedAppVersion = version

#    notificationService.notify
#      title: 'Regular Notice',
#      text: 'Check me out! I\'m a notice.'

    # Hold the paths here
    $scope.ref = undefined
    $scope.schema = undefined
    $scope.table = undefined


    # Hold the results here
    $scope.connections = []
    $scope.databases = []
    $scope.collections = []
    $scope.fields = []

    if not $scope.ref
      # When database reference selected
      connectionService.get '/db/info', (data) -> $scope.connections = data
#      $http.get('/db/info/', {}).success (data) ->
#        $scope.connections = data

    # because this has happened asynchroneusly we've missed
    # Angular's initial call to $apply after the controller has been loaded
    # hence we need to explicityly call it at the end of our Controller constructor
    $scope.$apply();
  ]
