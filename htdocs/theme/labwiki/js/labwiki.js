
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

define(['theme/labwiki/js/column_controller', 'omf/data_source_repo'], function (column_controller, ds_repo) {
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
    fm.off('shown.bs.modal');
    if (content) {
      fb.append(content);
    }
    if (on_show) {
      fm.on('shown.bs.modal', function() {
        resize_modal();
        on_show(fb);
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

  // Look for discarded widgets and cleanup unused data sources
  CLEANER_INTERVAL = 5000
  setInterval(function() {
    var TIMEOUT = 10000;
    var body = $("body");
    var ts = Date.now();
    _.each(OML.widgets, function(widget, id) {
      if (body.find("#" + id).length > 0) {
        // apparently still in use
        if ((typeof widget.ping) == "function") {
          widget.ping(ts);
        }
      } else {
        delete OML.widgets[id];
      }
    });
    // Now check for old repos
    ds_repo.each(function(ds, name) {
      var dts = ds.ping();
      if (!dts) {
        // not sure when we would come through here?
        ds.ping(dts);
        return;
      }
      if ((ts - dts) > 2 * CLEANER_INTERVAL) {
        // Looks like nobody is needing this data source anymore
        ds_repo.deregister(name);
      }
    })
  }, CLEANER_INTERVAL);

  $(function() {
    // Init controller now that everything is loaded
    OHUB.trigger('page.loaded', {});

    // Fix layout
    LW.resize();

    //console.log('hi');

    window.onbeforeunload = function() { return "Your unsaved work will be lost."; };
  });

  return LW;
});
