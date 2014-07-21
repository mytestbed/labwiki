LW.prepare_controller.add_tool('Edit',
  '<div class="form-group">\
     <input class="form-control" name="file_name" placeholder="File name" type="text" value="" required>\
   </div>\
   <div class="form-group">\
     <select class="form-control" name="file_ext">\
       <option value="oedl">OEDL</option>\
       <option value="md">Wiki</option>\
     </select>\
   </div>\
   <button class="btn btn-success" type="submit">Create</button>',
  function(form, status_cbk) {
    var params = form.serialize();
    $.post("/plugin/source_edit/create_script", params, function(data) {
      var url = data.url;
      var mime_type = data.mime_type;
      //$(".alert-create-script").html(url + ' created.').addClass("alert-success").removeClass("alert-danger");
      status_cbk('success', url + ' created.');
      var opts = {
        action: 'get_content',
        col: 'prepare',
        plugin: 'source_edit',
        mime_type: mime_type,
        url: url
      };
      LW.prepare_controller.refresh_content(opts, 'POST');
    }).fail(function(data) {
      //$(".alert-create-script").html(data.responseText).addClass("alert-danger").removeClass("alert-success");
      status_cbk('danger', data.responseText);
    }).always(function(data) {
      // $(".alert-create-script").show();
      // $("div.tools-list").delay(2000).hide(0);
      LW.prepare_controller.close_tool_list();
    });
    return false;
  }
);

// LW.prepare_controller.add_tool('Edit',
  // '<div class="alert-create-script alert" style="display: none;"></div>\
   // <form class="form-inline" role="form" id="new_script_form_prepare">\
     // <div class="form-group">\
       // <input class="form-control" name="file_name" placeholder="File name" type="text" value="" required>\
     // </div>\
     // <div class="form-group">\
       // <select class="form-control" name="file_ext">\
         // <option value="oedl">OEDL</option>\
         // <option value="md">Wiki</option>\
       // </select>\
     // </div>\
     // <button class="btn btn-success" type="submit">Create</button>\
   // </form>'
// );
//
// $('#new_script_form_prepare').submit(function(event) {
  // $.post("/plugin/source_edit/create_script", $(this).serialize(), function(data) {
    // var url = data.url;
    // var mime_type = data.mime_type;
    // $(".alert-create-script").html(url + ' created.').addClass("alert-success").removeClass("alert-danger");
    // var opts = {
      // action: 'get_content',
      // col: 'prepare',
      // plugin: 'source_edit',
      // mime_type: mime_type,
      // url: url
    // };
    // LW.prepare_controller.refresh_content(opts, 'POST');
  // }).fail(function(data) {
    // $(".alert-create-script").html(data.responseText).addClass("alert-danger").removeClass("alert-success");
  // }).always(function(data) {
    // $(".alert-create-script").show();
    // $("div.tools-list").delay(2000).hide(0);
  // });
  // return false;
// });
