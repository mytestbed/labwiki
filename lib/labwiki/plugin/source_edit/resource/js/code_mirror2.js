//L.provide('OML.code_mirror2', ["graph/js/code_mirror", "#OML.code_mirror"], function () {
define(["graph/code_mirror", 'theme/labwiki/js/labwiki'], function (code_mirror, LW) {

  var code_mirror2 = code_mirror.extend({

    initialize: function(opts) {
      var self = this;

      var pc = LW.prepare_controller;
      var b = this.buttons = {};
      b.save = pc.add_toolbar_button({name: 'save', awsome: 'floppy-o', tooltip: 'Save', active: false}, function(ev) {
        self.on_save_pressed();
        return false;
      });
      b.undo = pc.add_toolbar_button({name: 'undo', awsome: 'undo', tooltip: 'Undo', active: false}, function(ev) {
        self.on_undo_pressed();
        return false;
      });
      b.redo = pc.add_toolbar_button({name: 'redo', awsome: 'repeat', tooltip: 'Redo', active: false}, function(ev) {
        self.on_redo_pressed();
        return false;
      });

      code_mirror2.__super__.initialize.call(this, opts);

    },

    on_changed: function(editor, change) {
      if (editor == undefined) return;

      var o = this.opts;
      var h = editor.historySize();

      this.buttons.save(h.undo > 0);
      this.buttons.undo(h.undo > 0);
      this.buttons.redo(h.redo > 0);
    },


    _update_widget_height: function(opts) {
      // Don't do anything
    },

    resize: function() {
      // Don't do anything
    },

  });

  return code_mirror2;
});

