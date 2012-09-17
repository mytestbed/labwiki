
if (typeof(LW) == "undefined") LW = {};

L.provide('LW.column_controller', ['#LW.content_selector_widget', '#jquery.ui'], function () {
  
  /*
   * The UI is divided into multiple columns whose content may dynamically
   * change during a session. This object coordinates the behavior the columns
   * and maintains its state.
   */
  LW.column_controller = Backbone.Model.extend({
    
    initialize: function(opts) {
      this._opts = opts;
      var name = this._name = opts.name;
      this._content_selector = new LW.content_selector_widget(this, {});
      //this._content_history = []; 
      this.content_descriptor = {};
      // allow content specific monitors to take a first stab at handling dropped content
      this.on_drop_handler = null;
      
      
      this.col_span = 1;
      
      var self = this;
      // OHUB.bind('layout.resize', function(e) {
        // self.init_content_panel();
      // });
      OHUB.bind('page.loaded', function(e) {
        self.fix_toolbar();
      });
      
    },  
    
    resize: function(left, width) {
      var cd = $("#kp" + this._opts.col_index);
      cd.css({
          "left"    : left+'px',
          "display" : width > 0 ? 'block' : 'none'
      });
      cd.width(width);
      this.init_content_panel(); // fix panel height
    },
    
    load_content: function(selected) {
      console.log(selected);
      //this.displayed_content = selected;
      var self = this;
      var opts = {
        action: 'get_content',
        //blob: selected.blob,  // use this one if we care about a specific version
        col: this._name
      };
      if (selected.content) opts.content = selected.content;
      if (selected.url) opts.url = selected.url;
      if (selected.mime_type) opts.mime_type = selected.mime_type;

      this.refresh_content(opts, 'GET');
    },
    
    refresh_content: function(opts, type) {
      //opts['id'] = selected.id;
      var self = this;
      opts.sid = LW.session_id;
      $.ajax({
        url: '_column',
        data: opts,
        type: type
      }).done(function(data) { 
        self.on_drop_handler = null; // remove drop handler as it may be related to old content
        try {
          $('#col_content_' + opts.col).replaceWith(data.html);
        } catch(err) {
          // TODO: Find a better way of conveying problem
          var s = printStackTrace({e: err});
          console.log(s);            
        }
        delete data['html'];
        self.content_descriptor = data;
        OHUB.trigger('column.content.showing', {column: self._name, content: data});         
        self.fix_toolbar();
        self.init_content_panel();
        self.init_drag_n_drop();
      });
      
    },
    
    on_drop: function(e, target) {
      var content_descriptor = e.data('content');
      var delegate = target.attr('delegate');
      if (content_descriptor.url) {
        var o = {
          url: content_descriptor.url,
          mime_type: content_descriptor.mime_type
        }
        this.load_content(o);
      }
    },
    
    /* 
     * Called when the ADD button beside the column's top search box
     */
    on_new_button: function() {
      
    },
    
    
    show_widget: function(opts) {
      var prefix = opts.inner_class;
      var index = opts.index;
      var widget_id = opts.widget_id;
      
      $('.' + prefix).hide();
      $('#' + prefix + '_' + index).show();
      
      var current = $('#' + prefix + '_l_' + index);
      current.addClass('current');
      current.siblings().removeClass('current');
      
      // May be a bit overkill, but this should shake out the widgets hidden so far
      OHUB.trigger('window.resize', {}); 
      
      
      //var widget = OML.widgets[widget_id];
      //if (widget) widget.resize().update();
        
      return false;
    },
     
    /*
     * Put the final touches on the column DOM, such as button bindings
     */
    init: function(el_prefix, opts) {
      this.init_titlebar();
      this._content_selector.init(el_prefix, opts);
      this.init_drag_n_drop();
      this.init_content_panel();
      
      var o = opts;
      if (o.mime_type) this.content_descriptor.mime_type = o.mime_type;
      if (o.url) this.content_descriptor.url = o.url;
      this._opts.sid = o.sid;
    },
    
    init_titlebar: function() {
      
      var prefix = '#kp' + this._opts.col_index;
      
      // Columns resize. 
      // Current functionality flips back and forth between col_span 1 and 2.
      
      // Only show resize if there is a neighbor to that side
      if (this.right_column_controller()) $(prefix + '_maximize_right_buttom').show();
      if (this.left_column_controller()) $(prefix + '_maximize_left_buttom').show();
          
      var self = this;
      var f = function(button_el, neighbor_controller) {
        if (button_el.hasClass('k-active')) {
          // minimize
          self.decrement_col_span();        
          neighbor_controller.increment_col_span();
        } else {
          self.increment_col_span();        
          neighbor_controller.decrement_col_span();
        }
        // Swap button image
        $(prefix + ' button.maximize').toggleClass('k-active');
        LW.layout();
      };
      
      $(prefix + '_maximize_right_buttom').click(function() {
        f($(this), self.right_column_controller())
      });
      $(prefix + '_maximize_left_buttom').click(function() {
        f($(this), self.left_column_controller())
      });
    },
     
  
    init_drag_n_drop: function() {
      var self = this;
      var prefix = '#kp' + this._opts.col_index;
      var del = $(prefix + ' .widget-title-icon');
      del.data('content', this.content_descriptor);
      del.draggable({
        appendTo: "body",
        helper: "clone",
        stack: 'body',
        zIndex: 9999
      });
      var targets = $(prefix + ' .drop-target');
      $(prefix + ' .drop-target').droppable({
        activeClass: "ui-state-default",
        hoverClass: "ui-state-hover ui-drop-hover",
        drop: function(event, ui) {
          var propagate = true;
          var e = ui.draggable;
          if (self.on_drop_handler) {
            propagate = self.on_drop_handler(e, $(this), self);
          } 
          if (propagate) {
            self.on_drop(e, $(this));
          }
        },
        accept: function(candidate) {
          console.log("drop accept? : " + candidate);
          return true;
        }
      });
    },
    
    init_content_panel: function() {
      var opts = this._opts;
  //    $('#col_content_' + opts.col)
      var col = $('#col_content_' + opts.name);
      var panel = col.find('.panel-body');
      var position = panel.offset();
      if (position) {
        var win_height = $(window).height();
        var panel_height = win_height - position.top;
        panel.height(panel_height);
      } 
    },
    
    // Check if the content panel includes a 'toolbar'. If yes, move it to
    // the widget widget title so it remains visible when scrolling the content
    //
    fix_toolbar: function() {
      var col = $('#col_content_' + this._opts.name);
      var panel = col.find('.panel-body');
      var toolbar = panel.find('.widget-toolbar').detach();
      var c = col.find('.widget-title-toolbar-container');
      c.empty(); // remove potential previous toolbar
      if (toolbar.length > 0) {
        toolbar.appendTo(c);
      }
    },
  
    content_history_for_pos: function(pos) {
      return LW.__content_history[pos] || [];
    },
    
    /* Return the controller of the column to our right, may be null */
    right_column_controller: function() {
      return LW.controllers[this._opts.col_index + 1];
    },
  
    /* Return the controller of the column to our left, may be null */
    left_column_controller: function() {
      return LW.controllers[this._opts.col_index - 1];
    },
    
    decrement_col_span: function() {
      this.col_span = this.col_span > 1 ? this.col_span - 1 : 0
    },
  
    increment_col_span: function() {
      this.col_span = this.col_span < (LW.controllers.length - 1) ? this.col_span + 1 : this.col_span;
    },
  
  });
})