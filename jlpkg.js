var jlpkgApp = angular.module('jlpkgApp', []);

 
jlpkgApp.controller('jlpkgCtrl', function ($scope, $http) {

  $scope.test = 5;

  $scope.stable_url = "all.json";

  $http.get($scope.stable_url).then(function(response){
    $scope.stable = response.data;
    // for (pkg in $scope.stable) {
    //   url_split = $scope.stable[pkg].url.split('/');
    //   $scope.stable[pkg].owner = url_split[url_split.length-2];
    // }
    for (var i = 0; i < $scope.stable.length; i++) {
      url_split = $scope.stable[i].url.split('/');
      $scope.stable[i].owner = url_split[url_split.length-2];
    }
  });

  $scope.humanStatus = function(status){
    if (status == "full_pass") {
      return "Tests Pass";
    } else if (status == "full_fail") {
      return "Tests Fail";
    } else if (status == "using_pass") {
      return "Can Load";
    } else if (status == "using_fail") {
      return "Can't Load";
    } else {
      return "Unknown";
    }
  };

});