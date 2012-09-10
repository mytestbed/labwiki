
L.provide('LW.plugin.experiment.experiment_monitor', ['#jquery.ui'], function () {

  LW.plugin.experiment = {};
  
  LW.plugin.experiment.experiment_monitor = function(exp_name) {
    var current_event = null;
    var graphs = {};
    
    function ctxt() {};
    
    OHUB.bind('data_source.log_' + exp_name + '.changed', function(update) {
      var events = update.events;
      var l = events.length;
      if (l < 1 || current_event == events[l - 1]) return;
      
      var html = ""
      _.each(events.reverse(), function(e) {
        var ts = e[0].toFixed(1);
        var severity = e[1];
        var message = e[3];
        html = html + '<tr><td>'
          + ts 
          + '</td><td>' + severity
          + '</td><td>' + message
          + '</td></tr>'
          ;          
      });
      $('table.experiment-log').html(html)
    });
    
    OHUB.bind('data_source.graph_' + exp_name + '.changed', function(update) {
      _.each(update.events, function(e) {
        var id = e[0];
        if (graphs[id]) return;
        
        var opts = JSON.parse(e[1]);
        var type = opts.type;
        
        // Create the datasources
        _.each(opts.data_sources, function(dsh) {
          var ds = OML.data_sources.register(dsh.stream, null, dsh.schema, []);
          if (dsh.update_interval) {
            ds.is_dynamic(dsh.update_interval)
          }
        });
        
        // Create a div to embed the graph in
        opts.base_el = '#w' + id;
        var caption = 'Caption Missing';
        var cap_h = '<div class="experiment-graph-caption">'
                  //+ '<a href="#" id="d' + id + '" class="ui-draggable">_</a>'
                  //+ '<div id="d' + id + '"><img src="/plugin/experiment/img/graph_drag.png"></img></div>'
                  + '<img src="/plugin/experiment/img/graph_drag.png" id="d' + id + '"></img>'
                  + '<span class="experiment-graph-caption-figure">Figure:</span>'
                  + '<span class="experiment-graph-caption-text">' + caption + '</span>'
                  + '</div'
                  ;
        $('div.experiment-graphs')
          .append('<div class="oml_' + type + '" id="w' + id + '"></div>')
          .append(cap_h)
          ;
        // Make Caption draggable
        var del = $('#d' + id);
        //var del = Y('#d' + id);        
        del.data('controller', this);
        //del.data('controller', this);
        del.draggable({
          appendTo: "body",
          helper: "clone",
          stack: 'body',
          zIndex: 9999
        });
        
        L.require('#OML.' + type, 'graph/' + type + '.js', function() {
          graphs[id] = new OML[type](opts);
        });
                
      })
    });
    
    var sections = $('.widget_body h3 a.toggle');
    sections.click(function(ev) {
      var a = $(this)
      a.toggleClass('toggle-closed');
      var p = a.parent().next();
      p.slideToggle(400);
      return false;
    });
    
    return ctxt;
  };
  
 })
