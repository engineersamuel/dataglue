define(['base64'], function(base64) {

    var encoded = base64.encode('Hello World!');
    console.log("Encoded: " + encoded);

    var decoded = base64.encode(encoded);
    console.log("Decoded: " + decoded);

    return ['$scope', function($scope) {

        // You can access the scope of the controller from here
        $scope.welcomeMessage = 'This is the myctrl2.js controller!';
        $scope.testMessage = 'This is a test message!';

        // because this has happened asynchroneusly we've missed
        // Angular's initial call to $apply after the controller has been loaded
        // hence we need to explicityly call it at the end of our Controller constructor
        $scope.$apply();
    }];
});