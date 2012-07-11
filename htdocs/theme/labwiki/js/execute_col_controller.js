

/*
 * Implements functions specific to the EXECUTE column
 */
LW.execute_col_controller = LW.column_controller.extend({
  
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

