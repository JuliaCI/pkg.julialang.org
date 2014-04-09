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
  var lowerSearchAuthor = window.searchAuthor.toLowerCase();
  var visibleCount = 0;
  $('.pkglisting').each(function(){
     var pkg    = $(this).data('pkg');    // pre-lowered
     var owner  = $(this).data('owner');  // pre-lowered
     var ver    = $(this).data('ver');
     var status = $(this).data('status');
     var lic    = $(this).data('lic');

     if (
         pkg.indexOf(lowerSearchName) != -1 &&
         owner.indexOf(lowerSearchAuthor) != -1 &&
         ver == window.juliaVersion &&
         window.testStatus[status] &&
         window.license[licenseSumary(lic)]
         ) {
      $(this).show();
      visibleCount += 1;
     } else {
        $(this).hide();
     }
  });

  $("#pkgcount").text(visibleCount);
}

function licenseSumary(license) {
  if (license == "MIT") return "MIT";
  if (license == "BSD") return "BSD";
  if (license == "GPL v2") return "GPLv2";
  if (license == "GPL v3") return "GPLv3";
  return "Other";
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
  var vers = (''+ver).substr(2,1);
  var logbox = $('#'+pkg+vers+'_log');
  var loglink = $('#'+pkg+vers+'_loglink');
  
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
  var ver = $(this).data('ver');
  var vers = (''+ver).substr(2,1);
  console.log('#'+pkg+vers+'_hist')
  $('#'+pkg+vers+'_hist').toggle();
  if ($('#'+pkg+vers+'_histlink').text() == 'Show history') {
    $('#'+pkg+vers+'_histlink').text('Hide history');
  } else {
    $('#'+pkg+vers+'_histlink').text('Show history');
  }
});


// Initial hiding
var spl = window.location.search.substr(1).split('&');
for (var i = 0; i < spl.length; i++) {
  var subspl = spl[i].split('=');
  if (subspl.length != 2) continue;
  var lhs = subspl[0];
  var rhs = subspl[1];
  if (rhs[rhs.length-1] == '/') {
    rhs = rhs.substr(0,rhs.length-1);
  }
  rhs = decodeURIComponent(rhs);
  if (lhs == 'pkg') {
    window.searchName = rhs;
    $('#searchName').val(rhs);
  }
  if (lhs == 'ver') {
    window.juliaVersion = rhs;
    $('#juliaVersion .btn').removeClass('active');
    if (rhs == '0.2') {
      $('#releaseButton').addClass('active');
    } else {
      $('#nightlyButton').addClass('active');
    }
  }
}
updateFilter();