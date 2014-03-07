var jlpkgApp = angular.module('jlpkgApp', ['ui.bootstrap']);

 
jlpkgApp.controller('jlpkgCtrl', function ($scope, $http) {

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
      $scope.stable[i].showtestlog = false;
    }
  });

  $scope.humanStatus = function(status){
    if (status == "full_pass") {
      return "Tests pass.";
    } else if (status == "full_fail") {
      return "Tests fail.";
    } else if (status == "using_pass") {
      return "No tests, package loads.";
    } else if (status == "using_fail") {
      return "No tests, package doesn't load.";
    } else {
      return "Package was untestable due to binary dependency.";
    }
  };

  // Filtering
  $scope.jlVer = "0.2";
  $scope.testShow = {"full_pass":true,"full_fail":true,
                     "using_pass":true,"using_fail":false,
                     "not_possible":true};
  $scope.searchName = "";
  $scope.searchAuthor = "";
});


jlpkgApp.filter('pkgFilter', function() {
    return function(items, jlVer, testShow, searchName, searchAuthor) {
      var filtered = [];
      angular.forEach(items, function(item) {
        if( jlVer == item.jlver && 
            testShow[item.status] &&
            item.name.indexOf(searchName) != -1 &&
            item.owner.indexOf(searchAuthor) != -1) {
          filtered.push(item);
        }
      });
      return filtered;
    };
});