
OML.show_widget = function(opts) {
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
};
   
LW = {};
 
LW.register_content_search = function(el_prefix, opts) {
  $('#' + el_prefix + '_hi a').hover(
    function() {$(this).addClass('ui-state-hover');},
    function() {$(this).removeClass('ui-state-hover');}       
  );
  $('#' + el_prefix + '_hi a').click(function() {
    $('#' + el_prefix + '_si').autocomplete("close");
    $('#' + el_prefix + '_hi ul').hide();
    var url = $(this).attr('lw:url');
    LW.load_content(url, opts);
    // TODO: Call the content loader
    // Close autocomplete and oneself
    return false;
  });
  
  $('#' + el_prefix + '_si').autocomplete({
    source: '_search?sid=' + opts.sid + '&col=' + opts.col,
    appendTo: $('#' + el_prefix + '_sl'),
    autoFocus: true,
    minLength: 0,
    open: function() {
      var w = $('#' + el_prefix + '_si').autocomplete("widget");
      w.css('left', '0px');
      w.css('top', '0px');
      var i = 0;
    },
    close: function() {
      //$('this').element.val(''); // clear search box
      // TODO: This is a bit of a hack and leads to the menu blinking
      // as the search box is getting back focus when the menu is clicked on.
      $('#' + el_prefix + '_si').blur();               
      $('#' + el_prefix + '_hi ul').hide();
    },
    select: function(event, ui) {
      //$('#' + el_prefix + '_si').autocomplete("close");
      //$('.summary').focus();
      LW.load_content(ui.item.value, opts);
      return false;
    }
  });

  $('#' + el_prefix + '_si').focus(function () {
    //console.log('FOCUS');
    $('#' + el_prefix + '_hi ul').show();
    $('#' + el_prefix + '_si').autocomplete("search");
    //return true;
  });
}

LW.load_content = function(selected, opts) {
  console.log([selected, opts]);
  opts['id'] = selected.id;
  $.ajax({
    url: '_column',
    data: opts,
    type: 'GET'
  }).done(function(data) { 
    $('#col_content_' + opts.col).replaceWith(data);
    var i = 0;
  });
  
}

LW.content_history_for_pos = function(pos) {
  return LW.__content_history[pos] || [];
}

LW.__content_history = [[],[], []];

$(function() {
  console.log('hi');
  
  LW.plan_controller = new LW.column_controller('plan');
  LW.prepare_controller = new LW.column_controller('prepare');
  LW.execute_controller = new LW.column_controller('execute');
  
  /* Support dragging of column title icons onto other column header */
  $('.widget-title-icon').draggable({
    appendTo: "body",
    helper: "clone",
    stack: 'body',
    zIndex: 9999
  });
  $('.widget-title-block .drop-target').droppable({
    activeClass: "ui-state-default",
    hoverClass: "ui-state-hover ui-drop-hover",
    drop: function(event, ui) {
      console.log(ui);
    }
  });
  
});
