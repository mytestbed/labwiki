

define([], function () {

  // Helper to build a simple form in a column
  //
  // Definition:
  /***
  {
    rows: [
      {
        id: 'foo',
        label: 'Foo',
        type: 'text',
        size: 16, // size of text field
        value: 'xxx',  // preset
        def_value: '???', // default value
        editable: true, // User can change (default: true)
        info: 'Good luck!'
      }, ...
    ]
  }
  ***/
  //
  var form_builder = function(container, opts) {
    var on_change_callback = null;
    var row_finisher_callback = null;

    var my = function(form_decl) {
      var table = $('<table />').attr('class', "lw-form").attr("style", "width: auto");

      var c = [];
      _.each(form_decl.rows, function(r, idx) {
        var row = build_row(r, idx);
        if (row) row.appendTo(table);
      });
      container.empty().append(table);
    };

    my.on_change = function(callback) {
      on_change_callback = callback;
    };

    my.on_row_built = function(callback) {
      row_finisher_callback = callback;
    };

    function build_row(rdecl, idx) {
      var r = $('<tr />');
      r.attr('class', 'field_' + rdecl.id + ' row_' + idx);

      $('<td />').attr('class', 'row_label').text(rdecl.label || 'Unknown').appendTo(r);
      var vc = null;
      switch (rdecl.type || 'text') {
        case 'text':
        case 'int':
          vc = $('<input />');
          vc.blur(function() {
            if (on_change_callback) {
              var val = vc.val();
              on_change_callback(val, rdecl);
            }
          });
          vc.attr('name', rdecl.id);
          vc.attr('type', 'text');
          vc.attr('class', "field text fn");
          vc.attr('size',  rdecl.size || 16);
          if (rdecl.value) {
            vc.attr('value', rdecl.value);
          } else if (rdecl.def_value) {
            vc.attr('placeholder', rdecl.def_value);
          }
          break;

        case 'boolean':
          vc = $('<input />');
          vc.change(function() {
            if (on_change_callback) {
              var checked = vc.is(':checked');
              on_change_callback(checked, rdecl);
            }
          });
          vc.attr('name', rdecl.id);
          vc.attr('type', 'checkbox');
          vc.attr('class', "field boolean fn");
          if (rdecl.value == true) {
            vc.attr('checked', 'checked');
          }
          break;
      };
      if (vc) {
        $('<td />').attr('class', 'row_value').append(vc).appendTo(r);
      }

      if (rdecl.info) {
        $('<td />').attr('class', 'row_info').text(rdecl.info).appendTo(r);
      }

      if (row_finisher_callback) row_finisher_callback(rdecl, r, idx);
      return r;
    }

    //==== INIT ====

    return my;
  };

  return form_builder;
});
