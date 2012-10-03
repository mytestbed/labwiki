
L.provide('LW.plugin.plan_text.plan_text_monitor', ['#LW.init'], function () {

  LW.plugin.plan_text = {};
  
  LW.plugin.plan_text.plan_text_monitor = function(content) {
        
    // Not sure what this is good for :)
    OHUB.bind('column.content.showing', function(evt) {
      if (evt.column != 'plan') return;
      
      $("a[href^='lw:']").each(function() { 
        var a = $(this);
        var href = a.attr("href");
        //a.attr('lw:ref', href);
        a.removeAttr("href");
        a.data('content', {
          url: href.substring(3),
          mime_type: 'text'
        });
        a.draggable({
          appendTo: "body",
          helper: "clone",
          stack: 'body',
          zIndex: 9999
        });
        
      });

      
      // Fix the links which are internal
      // var links = evt.selector.find('a');
      // links.each(function(index) {
//            
        // var a = $(this);
        // var href = a.attr("href");
        // if (href = href.match(/^lw:/)) {
          // a.attr("href", '#');
        // }
        // var i = 0;
      // });
    });
    
    LW.plan_controller.on_drop_handler = function(draggable, target, col_controller) {
      var delegate = target.attr('delegate');
      if (delegate != 'plan') return true;
      
      var embedder = draggable.data('embedder');
      var eid =  'e' + Math.round((Math.random() * 10E12));
      var line_no = parseInt(target.attr('line_no'));
      var em_h = '<div class="figure" id="' + eid + '"></div>'
      $(em_h).insertBefore(target);
        
      var e_el = $('#' + eid);
      embedder(e_el);
      
      // TODO: Report to backend that new content has been added

      return false; // handled
    }
  };
  
})
