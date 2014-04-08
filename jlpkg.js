// Initialize globals
window.searchName = '';
window.searchAuthor = '';
window.juliaVersion = '0.2';
window.testStatus = {"full_pass"   :true, "full_fail" :true,
                     "using_pass"  :true, "using_fail":true,
                     "not_possible":true};
window.license = {"MIT"  :true, "BSD"  :true,
                  "GPLv2":true, "GPLv3":true,
                  "Other":true};

///////////////////////////////////////////////////////////////////////////////
// Filtering function
function updateFilter() {
  var lowerSearchName = window.searchName.toLowerCase();
  var visibleCount = 0;
  $('.pkglisting').each(function(){
     var pkg    = $(this).data('pkg');  // pre-lowered
     var ver    = $(this).data('ver');
     var status = $(this).data('status');

     if (ver == window.juliaVersion &&
         window.testStatus[status] &&
         pkg.indexOf(lowerSearchName) != -1) {
      $(this).show();
      visibleCount += 1;
     } else {
        $(this).hide();
     }
  });

  var lowerName   = $scope.searchName.toLowerCase();
    var lowerAuthor = $scope.searchAuthor.toLowerCase();
    var licstatus = false;
    licstatus = licstatus || (item.license == "MIT" && $scope.licenseShow["MIT"])
    licstatus = licstatus || (item.license == "BSD" && $scope.licenseShow["BSD"])
    licstatus = licstatus || (item.license == "GPL v2" && $scope.licenseShow["GPLv2"])
    licstatus = licstatus || (item.license == "GPL v3" && $scope.licenseShow["GPLv3"])
    licstatus = licstatus || (item.license != "MIT" && item.license != "BSD" &&
                              item.license != "GPL v2" && item.license != "GPL v3" &&
                              $scope.licenseShow["Other"])
    return (
            $scope.testShow[item.status] &&
            item.l_name.indexOf(lowerName)    != -1 &&
            item.l_owner.indexOf(lowerAuthor) != -1 &&
            licstatus);


  $("#pkgcount").text(visibleCount);
}

///////////////////////////////////////////////////////////////////////////////
// Filter controls

// Package name
$('#searchName').change( function () {
  window.searchName = $(this).val();
  updateFilter();
}).keyup( function () { $(this).change(); });

$('#clearName').click( function() { 
  window.searchName = '';
  updateFilter();
  $('#searchName').val('').focus();
});


// Package author
$('#searchAuthor').change( function () {
  window.searchAuthor = $(this).val();
  updateFilter();
}).keyup( function () { $(this).change(); });

$('#clearAuthor').click( function() { 
  window.searchAuthor = '';
  updateFilter();
  $('#searchAuthor').val('').focus();
});


// Julia version
$('#juliaVersion .btn').click( function() { 
  window.juliaVersion = $(this).data('jlver');
  $('#juliaVersion .btn').removeClass('active');
  $(this).addClass("active");
  updateFilter();
});


// Test status
$('#testStatus .btn').click( function() { 
  window.testStatus[$(this).attr('id')] = !window.testStatus[$(this).attr('id')];
  $('#testStatus .btn').removeClass('active');
  $('#testStatus i').removeClass('glyphicon-ok glyphicon-remove');
  for (var key in window.testStatus) {
    if (window.testStatus[key]) {
      $('#' + key).addClass('active');
      $('#' + key + ' i').addClass('glyphicon-ok');
    } else {
      $('#' + key).blur();
      $('#' + key + ' i').addClass('glyphicon-remove');
    }
  }
  updateFilter();
});


// License
$('#license .btn').click( function() { 
  window.license[$(this).attr('id')] = !window.license[$(this).attr('id')];
  $('#license .btn').removeClass('active');
  $('#license i').removeClass('glyphicon-ok glyphicon-remove');
  for (var key in window.license) {
    if (window.license[key]) {
      $('#' + key).addClass('active');
      $('#' + key + ' i').addClass('glyphicon-ok');
    } else {
      $('#' + key).blur();
      $('#' + key + ' i').addClass('glyphicon-remove');
    }
  }
  updateFilter();
});


///////////////////////////////////////////////////////////////////////////////
// Package toggles (+ AJAX loading of logs)
$('.showlog').click( function() {
  var pkg = $(this).data('pkg');
  var ver = $(this).data('ver');
  var logbox = $('#'+pkg+'_log');
  var loglink = $('#'+pkg+'_loglink');
  
  if (loglink.text() == 'Show log') {
    loglink.text('Hide log');
  } else {
    loglink.text('Show log');
  }

  logbox.toggle();
  if (logbox.html() == '') {
    // Haven't loaded yet
    $.get('logs/' + pkg + '_' + ver + '.log', function(data) {
      logbox.html(data);
    });
  }
});
$('.showhist').click( function() {
  var pkg = $(this).data('pkg');
  $('#'+pkg+'_hist').toggle();
  if ($('#'+pkg+'_histlink').text() == 'Show history') {
    $('#'+pkg+'_histlink').text('Hide history');
  } else {
    $('#'+pkg+'_histlink').text('Show history');
  }
});


// Initial hiding
updateFilter();