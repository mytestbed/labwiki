L.provide('OML.code_mirror2', ["graph/code_mirror", "#OML.code_mirror"], function () {

  OML.code_mirror2 = OML.code_mirror.extend({
    
    _update_widget_height: function(opts) {
      // Don't do anything
      // var s_el = $(opts.base_el + " .CodeMirror-scroll");
      // s_el.css('height', 'auto');      
    },

    resize: function() {
      // if (!this.code_mirror) return;
//       
      // var o = this.opts;
      // var b = $(o.base_el);
      // var p = $(o.base_el).parents('.panel-body');
      // var height = p.height();
      // var width = p.width();
      // if (height && width) {
        // this.code_mirror.setSize(width, height);
      // }
    },
    
  })
})
