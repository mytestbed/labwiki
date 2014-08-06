
var i = 0;
require.config({
    //By default load any module IDs from js/lib
    baseUrl: '/resource',
    //except, if the module ID starts with "app",
    //load it from the js/app directory. paths
    //config is relative to the baseUrl, and
    //never includes a ".js" extension since
    //the paths config could be for a directory.
    paths: {
        omf: 'js',
        vendor: 'vendor',
        graph: 'graph/js',
        graph_css: 'graph/css'
    },
    // shim: {
      // 'vendor/jquery/jquery': {
          // //deps: ['jquery'],
          // exports: 'jQuery'
      // },
    // },
    map: {
      '*': {
        'css': 'vendor/require-css/css'
      }
    },
    waitSeconds: 30
});
//OML.require_dependency('vendor/jquery/jquery', { exports: 'jQuery' });

require(['css!graph_css/graph'], function(css) {});

define(['theme/labwiki/js/column_controller'], function (column_controller) {
  if (typeof(LW) == "undefined") LW = {};
  if (typeof(LW.plugin) == "undefined") LW.plugin = {};


  LW.controllers = [
    LW.plan_controller = new column_controller({name: 'plan', col_index: 0}),
    LW.prepare_controller = new column_controller({name: 'prepare', col_index: 1}),
    //LW.execute_controller = new LW.execute_col_controller({name: 'execute', col_index: 2})
    LW.execute_controller = new column_controller({name: 'execute', col_index: 2})
  ];

  function resize_modal() {
    var height = $('#k-slider').height();
    var fd = $('#fullscreen_modal .modal-content');
    var hc = height - 20;
    fd.css('height', '' + hc + 'px');

    var fd_h = fd.find('.modal-header');
    var h = fd_h[0].scrollHeight;
    if (h > 0) {
      var fd_b = fd.find('.modal-body');
      fd_b.css('height', '' + hc - h - 5 + 'px');
    }
  }

  LW.layout = function(window) {

    function layout() {
      var width = window.width();

      var topbar_height = 32;
      var height = window.height() - topbar_height;
      $('#k-slider').height(height);

      // To be safe, let's first check how many cols the controllers span
      var cols = _.reduce(LW.controllers, function(sum, c) { return sum + c.col_span; }, 0);
      var col_width = (width / cols);
      _.reduce(LW.controllers, function(left, controller) {
        var w = col_width * controller.col_span;
        controller.resize(left, w, height);
        return left + w;
      }, 0);
      OHUB.trigger('layout.resize', {});
      resize_modal();
    }
    return layout;
  }($(window));

  LW.show_modal = function(title, content, on_show) {
    var fm = $('#fullscreen_modal');
    var th = fm.find('.modal-title');
    th.text(title);

    var fb = fm.find('.modal-body');
    fb.empty();
    fb.append(content);
    if (on_show) {
      fm.on('shown.bs.modal', function() {
        resize_modal();
        on_show();
      });
    }
    fm.modal({});
  };



  LW.resize = function(window) {
    var last_width = -1;
    var last_height = -1;


    function resize() {
      var width = window.width();
      var height = window.height();
      if (last_width == width && last_height == height) return;
      last_width = width;
      last_height = height;
      LW.layout();
    }
    return resize;
  }($(window));

  OHUB.bind('window.resize', LW.resize);

  //LW.plugin = {}


  $(function() {
    // Init controller now that everything is loaded
    OHUB.trigger('page.loaded', {});

    // Fix layout
    LW.resize();

    console.log('hi');

    window.onbeforeunload = function() { return "You unsaved work will be lost."; };
  });

  return LW;
});
