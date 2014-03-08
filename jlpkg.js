var jlpkgApp = angular.module('jlpkgApp', ['ui.bootstrap','once']);

 
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
      $scope.stable[i].l_owner = url_split[url_split.length-2].toLowerCase();
      $scope.stable[i].l_name = $scope.stable[i].name.toLowerCase();
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
                     "using_pass":true,"using_fail":true,
                     "not_possible":true};
  $scope.searchName = "";
  $scope.searchAuthor = "";

  $scope.isVisible = function(item) {
    var lowerName   = $scope.searchName.toLowerCase();
    var lowerAuthor = $scope.searchAuthor.toLowerCase();
    return ($scope.jlVer == item.jlver && 
            $scope.testShow[item.status] &&
            item.l_name.indexOf(lowerName)    != -1 &&
            item.l_owner.indexOf(lowerAuthor) != -1);
  };

  $scope.filterMsg = function() {
    var sN = $scope.searchName;
    var sA = $scope.searchAuthor;
    if (sN == "" && sA == "") {
      return "";
    } else if (sN != "" && sA == "") {
      return "('" + sN + "')";
    } else if (sN == "" && sA != "") {
      return "('" + sA + "')";
    } else {
      return "('" + sN + "', '" + sA + "')";
    }
  };

  $scope.countPkgs = function() {
    var count = 0;
    var people = {};
    
    angular.forEach($scope.stable, function(item) {
      if ($scope.isVisible(item)) {
        count += 1;
        people[item.owner] = true;
      }
    });

    var people_count = 0;
    angular.forEach(people, function(item) {
      people_count += 1;
    });

    return count + ' packages from ' + people_count + ' people and organizations.';
  };

});