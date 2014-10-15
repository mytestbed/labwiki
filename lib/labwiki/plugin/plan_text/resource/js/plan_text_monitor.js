
define(['theme/labwiki/js/labwiki', 'plugin/plan_text/js/scrollspy2'], function (lw, scrollspy) {

  var plan_text_monitor = function(content, wid) {
    var toolbar_buttons = {};
    var text_el = $('#' + wid);
    var controller = lw.plan_controller;

    controller.on_drop_handler = function(draggable, target, col_controller) {
      // TODO: Why was this code here?
      // var delegate = target.attr('delegate');
      // if (delegate != 'plan') return true;

      return on_drop(draggable, target);
    };

    function on_drop(draggable, target) {

      var embedder = draggable.data('embedder');
      if (! embedder) return true;

      var eid =  'e' + Math.round((Math.random() * 10E12));
      var line_no = parseInt(target.attr('line_no'));
      // TODO: This is broken, find a better solution to keep track of inserted order
      var seq_no = target.parent().find('.figure').length + 1;
      var em_f = '<div class="figure" id="' + eid + '"></div>'
                 + '<p class="drop-target ui-droppable" delegate="plan" line_no="'
                 + line_no + '" seq_no="' + seq_no + '"> </p>';
      $(em_f).insertAfter(target);

      var e_el = $('#' + eid);
      embedder(e_el);
      controller.init_drag_n_drop();

      var content_f = draggable.data('content');
      if (content_f) {
        // TODO: I'm not sure if this isn't broken?
        var widget = draggable.data('content')();
        var opts = {
              action: 'insert_widget',
              line_no: line_no,
              seq_no: seq_no,
              widget: widget,
              col: 'plan',
              plugin: 'wiki'
            };
        controller.request_action(opts, 'POST', function(reply) {
          // TODO: Deal with errors
          var i = 0;
        });
      }
      return false; // handled
    };

    var pc = controller;
    var b = toolbar_buttons;
    b.share = pc.add_toolbar_button({name: 'share', awsome: 'share-square-o', tooltip: 'Share Page', active: true},
      function(ctxt) {
        var opts = {
          action: 'share',
          col: 'plan',
          plugin: 'wiki',
          url: content.url
        };
        LW.plan_controller.request_action(opts, 'POST', function(reply) {
          var i = 0;
        });
        return false;
      });

    //**** TOC *****/
    var toc_tb_attr = {name: 'toc', awsome: 'th-list', caret: true, active: true};

    var scroll_el = text_el.parents('.panel-body');
    var sections = text_el.find('section');

    var sp = scrollspy(scroll_el, sections, function(section) {
      var li = section.data('plan_text.toc');
      toc_tb_attr.label = li.text();
      b.toc.configure(toc_tb_attr);
      //console.log("section: " + li.text());
    });

    var toc = $('<ul class="dropdown-menu" role="menu" style="position: absolute; ">');
    //toc.attr('id', wid + '_toc');
    var toc_prefix = wid + '_toc_';
    _.each(sections.toArray(), function(s, i) {
      var section = $(s);
      var h = section.find('h1');
      if (h.length == 0) h = section.find('h2');
      var li = $('<li>');
      var a = $('<a href="#">').text(h.text());
      if (i == 0) { toc_tb_attr.label = h.text(); }
      li.append(a);
      toc.append(li);
      section.data('plan_text.toc', li);
        // li.hover(function() {
          // sp.scrollTo(section, 0);
        // });
      li.click(function() {
        sp.scrollTo(section, 0);
        toc.hide();
      });
    });
    $('#col_content_plan').append(toc); // append it to a parent which doesn't crop it

    b.toc = pc.add_toolbar_button(toc_tb_attr,
      function(ctxt) {
        var ct = ctxt.button.parent('.widget-title-toolbar-container');
        var tb_top = ct.offset().top;
        var k_top = $('#k-slider').offset().top;
        var h = ct.height();
        var top = tb_top - k_top + h;
        var left = ctxt.button.offset().left;
        //$('#foo').css({top: top, left: left}).toggle();
        toc.css({top: top, left: left}).toggle();
        return false;
      });

    // Drop target for graphs
    text_el.find('p.content').each(function() {
      var p = $(this);
      var line_no = parseInt(p.attr('line_no'));
      var drop_zone = $('<p class="drop-target ui-droppable" delegate="plan" line_no="'
                          + line_no + '" seq_no="0"> </p>');
      drop_zone.insertAfter(p);
      drop_zone.droppable({
        drop: function(event, ui) {
          on_drop(ui.draggable, $(this));
        },
        // over: function(event, ui) {
          // console.log('over');
          // var i = 0;
        // },
        // out: function(event, ui) {
          // console.log('out');
          // var i = 0;
        // },
        accept: ".ui-draggable"
      });

      text_el.find('img').click(function(a, b, c) {
        var img = $(this);
        var caption = img.attr('alt') || ' ';
        LW.show_modal(caption, img.clone());
        return false;
      });
    });
    controller.init_drag_n_drop();
  };

  return plan_text_monitor;
});
