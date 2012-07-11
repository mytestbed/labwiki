
LW.controllers = [ 
  LW.plan_controller = new LW.column_controller({name: 'plan', col_index: 0}),
  LW.prepare_controller = new LW.column_controller({name: 'prepare', col_index: 1}),
  LW.execute_controller = new LW.execute_col_controller({name: 'execute', col_index: 2})
];



LW.layout = function(window) {
  
  function layout() {
    var width = window.width();
    
    var topbar_height = 32;
    var height = window.height() - topbar_height;
    $('#k-slider').height(height);    

    // To be safe, let's first check how many cols the controllers span
    var cols = _.reduce(LW.controllers, function(sum, c) { return sum + c.col_span; }, 0);
    var col_width = (width / cols);
    _.reduce(LW.controllers, function(left, controller) {
      var w = col_width * controller.col_span;
      controller.resize(left, w);
      return left + w;
    }, 0);
  }
  return layout;
}($(window));


LW.resize = function(window) {
  var last_width = -1;
  
  function resize() {
    var width = window.width();
    if (last_width == width) return;
    last_width = width;
    LW.layout();
  }
  return resize;
}($(window));

OHUB.bind('window.resize', LW.resize);      



$(function() {
  // Fix layout
  LW.resize();
  
  console.log('hi');
  
  
  // /* Support dragging of column title icons onto other column header */
  // $('.widget-title-icon').draggable({
    // appendTo: "body",
    // helper: "clone",
    // stack: 'body',
    // zIndex: 9999
  // });
  // $('.widget-title-block .drop-target').droppable({
    // activeClass: "ui-state-default",
    // hoverClass: "ui-state-hover ui-drop-hover",
    // drop: function(event, ui) {
      // console.log(ui);
    // }
  // });
  
});

