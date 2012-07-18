

/*
 * Implements functions specific to the EXECUTE column
 */
LW.execute_col_controller = LW.column_controller.extend({
  
  /*
   * Start an experiment from a form 
   */
  start_experiment: function(form_el, fopts) {
    
    function get_value(name, def_value) {
      var e = form_el.find('td.' + name).children();
      var v = e.val();
      if (v == "") v = e.text();
      if (v == "") v = def_value;
      return v;     
    }
    
    var opts = {
      action: 'start_experiment',
      col: this._name
    };

    opts.name = get_value('propName', fopts.name);
    opts.script = fopts.script; //get_value('propScript', fopts.script);
    
    //var pv = opts.properties = {};
    opts.properties = _.map(fopts.properties, function(prop, index) {
      var val = get_value('prop' + index, prop['default']);  
      return {name: prop.name, value: val, comment: prop.comment};
    });

    this.refresh_content(opts, 'POST');
  },
  
  /* 
   * Create a new experiment
   */
  on_new_button: function() {
    $.ajax({
      url: '_column',
      data: {
        create: 'experiment', 
        col: this._name,
        sid: LW.session_id
      },
      type: 'GET'
    }).done(function(data) { 
      $('#col_content_execute').replaceWith(data);
      var i = 0;
    });
  },


})

