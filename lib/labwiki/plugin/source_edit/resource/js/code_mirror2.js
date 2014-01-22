//L.provide('OML.code_mirror2', ["graph/js/code_mirror", "#OML.code_mirror"], function () {
define(["graph/code_mirror"], function (code_mirror) {

  var code_mirror2 = code_mirror.extend({

    _update_widget_height: function(opts) {
      // Don't do anything
    },

    resize: function() {
      // Don't do anything
    },

  });

  return code_mirror2;
});

