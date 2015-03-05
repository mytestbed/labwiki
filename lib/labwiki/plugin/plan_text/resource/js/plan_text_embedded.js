
define([], function () {
  return function(wid, opts) {

    var layout2yui = {
      '50:50': {c: "yui-g", cnt: 2, s: [0.5, 0.5]},
      '33:33:33': {c: 'yui-gb', cnt: 3, s: [0.33, 0.33, 0.33]},
      '66:33': {c: "yui-gc", cnt: 2, s: [0.66, 0.33]},
      '33:66': {c: "yui-gd", cnt: 2, s: [0.33, 0.66]},
      '75:25': {c: "yui-ge", cnt: 2, s: [0.75, 0.25]},
      '25:75': {c: "yui-gf", cnt: 2, s: [0.25, 0.75]}
    };
    var widgets = [];

    var self = {};

    self.resize = function() {
      widgets.forEach(function(wID) {
        var widget = OML.widgets[wID];
        if (widget) {
          widget.resize();
        }
      })
    }

    function createColumn(colDef, colsEl, colIdx) {
      var colEl = $("<div class='yui-u" + (colIdx == 0 ? ' first' : '') + "'/>");
      colsEl.append(colEl);
      colDef.forEach(function (wdgt, wIdx) {
        var type = wdgt.type;
        if (!type) {
          raise("Missing type for widget '" + wdgt + "'.");
        }
        ts = type.split("/");
        if (ts[0] != "data") {
          raise("Only supporting data widgets and not '" + type + "'.");
        }
        var wType = ts[1];
        var wID = wid + "_" + colIdx + "_" + wIdx;
        var wd = $("<div id='" + wID + "' class='omf_data_widget_container'/>");
        colEl.append(wd);
        // adjust width according to split
        var width = wdgt.width;
        if (! width) width = 1.0;
        if (width < 10) {
          wdgt.width = yui.s[colIdx] * width;
        }
        (OML.widget_proto[wID] = function (id) {
          var inner_el = id + "_i";
          $("#" + id).append("<div id='" + inner_el + "' class='omf_data_widget oml_" + wType + "' />");
          wdgt.base_el = "#" + inner_el;
          require(['graph/' + wType], function (Graph) {
            OML.widgets[id] = new Graph(wdgt);
          });
        })(wID);
        widgets.push(wID);
      });
    }

    //* INIT
    var outer_el = $("#" + wid);
    var layout = opts.layout;
    if (layout == null) {
      raise("Missing layout declaration");
    }
    var yui = layout2yui[layout];
    if (yui == null) {
      raise("Unknown layout '" + layout + "'.");
    }

    var cols_el = $("<div class='" + yui.c + "'/>");
    outer_el.append(cols_el);
    opts.cols.forEach(function(colDef, i) {
      if (colDef.col) colDef = colDef.col;
      createColumn(colDef, cols_el, i);
    })

    return self;
  }
});
