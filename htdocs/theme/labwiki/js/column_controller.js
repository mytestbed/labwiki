
//if (typeof(LW) == "undefined") LW = {};

//L.provide('LW.column_controller', ['#LW.content_selector_widget', '#jquery.ui'], function () {
define(["theme/labwiki/js/content_selector_widget"], function (ContentSelectorWidget) {

  /*
   * The UI is divided into multiple columns whose content may dynamically
   * change during a session. This object coordinates the behavior the columns
   * and maintains its state.
   */
  var column_controller = Backbone.Model.extend({
    defaults: {
      left: 0,
      width: 0,
      panel_height: 0
    },

    /********* EXTENSION POINTS *********/

    set_search_list_formatter: function(plugin_name, formatter_f) {
      this._content_selector.set_search_list_formatter(plugin_name, formatter_f);
    },

    // type: success, info, warning, danger
    show_alert: function(type, msg, hide_after) {
      if (type == 'error') type = 'danger';
      var self = this;
      var ad = $('<div class="alert alert-' + type + ' fade in" role="alert">'
                 + '<button type="button" class="close" data-dismiss="alert">'
                 + '<span aria-hidden="true">×</span><span class="sr-only">Close</span></button>'
                 + msg + '</div>');
      var ap = this.top_el.find('.col-alerts');
      ap.prepend(ad);
      if (hide_after || type == 'success' || type == 'info') {
        if (!hide_after) hide_after = 5000; // default
        ad.delay(hide_after).fadeOut().promise().done(function() {
          ad.remove();
          self.check_size();
        });
      }
      ap.show();
      self.check_size();
    },

    add_tool: function(name, html_frag, callback) {
      var self = this;
      var id = this._name + '_tool_form_' + (this.tool_count += 1);
      var hf = '<form class="form-inline" role="form" id="' + id + '" method="POST">'
              + html_frag + '</form>';
      this._content_selector.add_tool(name, hf);
      var form = $('#' + id);
      form.submit(function(event) {
        callback(form, function(status, msg) {
          self.show_alert(status, msg);
          switch (status) {
          case 'success':
            self.close_tool_list();
            break;
          }
        });
        return false;
      });
      return form;
    },

    close_tool_list: function() {
      var self = this;
      $("div.tools-list").hide(0).promise().done(function() {
        self.check_size();
      });
    },

    add_toolbar_element: function(el) {
      var tc = this.top_el.find('.widget-title-toolbar-container');
      tc.show().append(el);
    },

    add_toolbar_button: function(opts, callback) {
      var b = $('<button type="button" class="toolbar toolbar-' + (opts.name || 'unknown') + '" />');
      this.add_toolbar_element(b);
      // Return a function to interact with the button in the future
      var ctxt = {
        button: b
      };
      ctxt.configure = function(opts) {
        b.empty();
        if (opts.awsome) {
          b.append('<i class="fa fa-' + opts.awsome + '" />');
        } else if (opts.glyph) {
          b.append('<span class="glyphicon glyphicon-' + opts.glyph + '" />');
        }
        if (opts.label) {
          b.append('<span class="label">' + opts.label + '</span>');
        }
        if (opts.caret) {
          b.append('<span class="caret"></span>');
        }
      };
      ctxt.enable = function(enable) {
        if (enable || enable == undefined) {
          b.tooltip('enable');
          b.removeClass('toolbar-button-disabled');
        } else {
          b.tooltip('disable');
          b.addClass('toolbar-button-disabled');
        }
        var i = 0;
      };
      ctxt.tooltip = function(text) {
        b.tooltip({title: text});
      };

      if (callback) { b.click(function(evt) { return callback(ctxt, evt); }); };
      b.tooltip({container: 'body', title: opts.tooltip, placement: 'bottom', delay: { show: 500, hide: 0 }});
      ctxt.configure(opts);
      ctxt.enable(opts.active != false);

      return ctxt;
    },

    add_toolbar_separator: function() {
      var s = $('<div class="toolbar toolbar-separator">|</div>');
      this.add_toolbar_element(s);

      // var b = this.top_el.find('.widget-title-toolbar-container button:last');
      // b.addClass('toolbar-with-separator');
    },

    initialize: function(opts) {
      this._opts = opts;
      var name = this._name = opts.name;
      this._content_selector = new ContentSelectorWidget(this, {});
      //this._content_history = [];
      this.content_descriptor = {};
      // allow content specific monitors to take a first stab at handling dropped content
      this.on_drop_handler = null;

      this.top_el = $("#kp" + opts.col_index);
      this.col_span = 1;

      this.tool_count = 0; // enumerate tools added

      var self = this;
      // OHUB.bind('layout.resize', function(e) {
        // self.init_content_panel();
      // });
      OHUB.bind('page.loaded', function(e) {
        self.fix_toolbar();
      });

    },

    resize: function(left, width, height) {
      this.set({left: left, width: width, height: height});
      var cd = $("#kp" + this._opts.col_index);
      cd.css({
          "left"    : left + 'px',
          "display" : width > 0 ? 'block' : 'none'
      });
      cd.width(width);
      this.init_content_panel(); // fix panel height
    },

    load_content: function(selected) {
      //console.log(selected);
      //this.displayed_content = selected;
      var self = this;
      var opts = {
        action: (selected.action || 'get_content'),
        //blob: selected.blob,  // use this one if we care about a specific version
        col: this._name,
        descriptor: selected
      };
      if (selected.name) opts.name = selected.name;
      if (selected.content) opts.content = selected.content;
      if (selected.url) opts.url = selected.url;
      if (selected.mime_type) opts.mime_type = selected.mime_type;
      if (selected.widget) opts.widget = selected.widget;

      this.refresh_content(opts, 'POST');
    },

    refresh_content: function(opts, type, status_cbk) {
      //opts['id'] = selected.id;
      var self = this;
      opts.sid = LW.session_id;
      $.ajax({
        type: (type != undefined) ? type : 'POST',
        url: '_column',
        data: JSON.stringify(opts),
        contentType: "application/json"
      }).done(function(data) {
        self.on_drop_handler = null; // remove drop handler as it may be related to old content
        var content_div = $('#col_content_' + opts.col);
        try {
          content_div.replaceWith(data.html);
        } catch(err) {
          // TODO: Find a better way of conveying problem
          var s = printStackTrace({e: err});
          console.log(s);
          self.show_alert('danger', s.slice(0, 2).join("\n"));
        }
        if (status_cbk) status_cbk('success', 'OK');
        delete data['html'];
        self.content_descriptor = data;
        self.fix_toolbar();
        self.init_drag_n_drop();
        self.init_content_panel();
        OHUB.trigger('column.content.showing', {column: self._name, content: data, selector: content_div});
      }).fail(function(jqXHR, textStatus, errorThrown) {
        self._report_ajax_fail(jqXHR, '_column', opts, status_cbk);
      });

    },

    _report_ajax_fail: function(jqXHR, url, opts, status_cbk) {
      var self = this;
      var type = 'danger';
      var msg = jqXHR.responseText || jqXHR.statusText;
      switch (jqXHR.status) {
        case 500:
          msg = "Server Error: " + jqXHR.responseText;
          break;

      }
      console.log('Ajax failed: ' + msg);
      switch (typeof(status_cbk)) {
      case 'function':
        status_cbk(type, msg);
        break;
      case 'undefined':
        self.show_alert(type, msg);
        break;
      }
    },

    request_action: function(opts, type, callback, status_cbk) {
      //opts['id'] = selected.id;
      var self = this;
      opts.sid = LW.session_id;
      opts.no_render = true;
      var type = (type != undefined) ? type : 'POST';
      var req = {
        url: '_column',
        type: type
      };
      if (type != 'GET') {
        req.data = JSON.stringify(opts);
        req.contentType = "application/json"
      } else {
        req.data = opts;
      }
      $.ajax(req).done(function(data) {
        try {
          if (callback) callback(data.action_reply);
          if (status_cbk) status_cbk('success', 'OK');
        } catch(err) {
          // TODO: Find a better way of conveying problem
          if (status_cbk) status_cbk('error', err);
          var s = printStackTrace({e: err});
          console.log(s);
          self.show_alert('danger', s.slice(0, 2).join("\n"));
        }
      }).fail(function(jqXHR, textStatus, errorThrown) {
        self._report_ajax_fail(jqXHR, '_column', opts, status_cbk);
      });
    },

    on_drop: function(e, target) {
      var content_descriptor = e.data('content');
      var delegate = target.attr('delegate');
      if (content_descriptor.url) {
        var o = {
          url: content_descriptor.url,
          mime_type: content_descriptor.mime_type,
          action: 'get_widget'
        };
        this.load_content(o);
      } else {
        this.refresh_content(content_descriptor, 'POST');
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
      //OHUB.trigger('column.content.showing', {column: this._name, content: opts, selector: $('#col_content_' + opts.col)});

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
        f($(this), self.right_column_controller());
      });
      $(prefix + '_maximize_left_buttom').click(function() {
        f($(this), self.left_column_controller());
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
          var e = ui.draggable;
          //var propagate = null;
          if (self.on_drop_handler) {
            propagate = self.on_drop_handler(e, $(this), self);
          } else {
            propagate = true;
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

      var enter = 0;
      targets.on('dragover', function(e) {
        e.preventDefault();
        e.stopPropagation();
      });
      targets.on('dragenter', function(e) {
        e.preventDefault();
        e.stopPropagation();
        if ((enter += 1) == 1) {
          targets.addClass("ui-state-hover ui-drop-hover");
        }
      });
      targets.on('dragleave', function(e) {
        e.preventDefault();
        e.stopPropagation();
        if ((enter -= 1) == 0) {
          targets.removeClass("ui-state-hover ui-drop-hover");
        }
      });
      targets.on('drop', function(e) {
        if (e.originalEvent.dataTransfer){
          if (e.originalEvent.dataTransfer.files.length) {
            e.preventDefault();
            e.stopPropagation();
            /*UPLOAD FILES HERE*/
            if (self.on_drop_handler) {
              propagate = self.on_drop_handler(e, $(this), self);
            }
            if (propagate) {
              self.on_drop(e, $(this));
            }

            //this.upload(e.originalEvent.dataTransfer.files);
          }
        }
        enter = 0;
        targets.removeClass("ui-state-hover ui-drop-hover");
      });
    },

    check_size: function() {
      var opts = this._opts;
  //    $('#col_content_' + opts.col)
      var col = $('#col_content_' + opts.name);
      var panel = col.find('.panel-body');
      var position = panel.offset();
      if (position) {
        var win_height = $(window).height();
        var panel_height = win_height - position.top;
        panel.height(panel_height);
        this.set({panel_height: panel_height});
        OHUB.trigger('column.' + this._name + '.resize', {
           left: this.get('left'), top: position.top,
           width: this.get('width'), panel_height: panel_height,
           position: position
        });

        //OHUB.trigger('column.' + this._name + '.panel.height', {height: panel_height});
      }
    },

    init_content_panel: function() {
      this.check_size();
      var opts = this._opts;
  //    $('#col_content_' + opts.col)
      var col = $('#col_content_' + opts.name);
      var panel = col.find('.panel-body');
      var position = panel.offset();

      // fix links in content panel
      panel.find('.widget_body a').each(function() {
        var el = $(this);
        var href = el.attr('xhref');
        if (href != undefined) {
          href = href.trim();
          if (href.slice(0, 3) == 'lw:') {
            el.removeAttr('href');
            // Link syntax shall be lw:prepare:system:oedl:bob.oedl

            var a = href.slice(3).split(':');
            var col = a[0];
            var url = a.slice(1);
            var controller = LW[col + '_controller'];

            var mime_type = '';
            switch (url.slice(-1)[0].split('.').slice(-1)[0]) {
              case 'rb':
              case 'oedl':
                mime_type = 'text/ruby';
                break;
              case 'md':
              case 'mkd':
                mime_type = 'text/markup';
                break;
              case 'experiment':
              case 'exp':
                mime_type = 'plugin/experiment';
                break;
            }

            if (controller != undefined && url != undefined) {
              var cmd = {
                action: 'get_widget',
                url: url.join(':'),
                col: col,
                mime_type: mime_type
              }

              // Making the link draggable as well
              el.data('content', cmd);
              el.draggable({
                appendTo: "body",
                helper: "clone",
                stack: 'body',
                zIndex: 9999
              });

              el.click(function() {
                controller.refresh_content(cmd, 'POST');
                return false;
              });
            } else {
              // Should insert an error statement into 'el'
            }
          }
          var i = 0;
        }
      });
    },

    // Check if the content panel includes a 'toolbar'. If yes, move it to
    // the widget widget title so it remains visible when scrolling the content
    //
    fix_toolbar: function() {
      // var col = $('#col_content_' + this._opts.name);
      // var panel = col.find('.panel-body');
      // var toolbar = panel.find('.widget-toolbar').detach();
      // var c = col.find('.widget-title-toolbar-container');
      // c.empty(); // remove potential previous toolbar
      // if (toolbar.length > 0) {
        // toolbar.appendTo(c);
      // }
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
      this.col_span = this.col_span > 1 ? this.col_span - 1 : 0;
    },

    increment_col_span: function() {
      this.col_span = this.col_span < (LW.controllers.length - 1) ? this.col_span + 1 : this.col_span;
    }

  });

  return column_controller;
});
