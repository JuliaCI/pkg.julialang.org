var jlpkgApp = angular.module('jlpkgApp', []);

 
jlpkgApp.controller('jlpkgCtrl', function ($scope, $http) {

  $scope.test = 5;

  $scope.stable_url = "all.json";

  $http.get($scope.stable_url).then(function(response){
    $scope.stable = response.data;
    for (pkg in $scope.stable) {
      url_split = $scope.stable[pkg].url.split('/');
      $scope.stable[pkg].owner = url_split[url_split.length-2];
    }
  });

});