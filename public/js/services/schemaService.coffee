# This doesn't work
define [], () ->
  [
    '$http',
    '$resource',
    'notificationService',
    ($http, $resource, notificationService) ->
      return {
        get: (ref, callback) ->
          $http.get('/db/info/' + ref)
          .success( (data) -> callback(data) )
          .error( (data, status, headers, config) ->
            notificationService.notify
              title: 'Request Error'
              text: 'There was a ' + status + ' accessing ' + config.url
              type: 'error'
              icon: false
          )
      }
  ]
