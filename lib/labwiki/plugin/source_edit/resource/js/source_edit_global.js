LW.prepare_controller.add_tool('Edit',
  '<div class="alert-create-script" style="display: none; margin: 7px 0 7px 7px; padding: 5px;"></div>\
   <form class="form-inline" id="new_script_form_prepare" style="padding: 5px; font-size: 100%;">\
     <input name="file_name" placeholder="File name" style="margin-right: 5px; height: 30px;" type="text" value="">\
     <select name="file_ext" style="margin-right: 5px; width: 60px;">\
       <option value="oedl">OEDL</option>\
       <option value="md">Wiki</option>\
     </select>\
     <button class="btn btn-primary btn-sm" type="submit">Create</button>\
   </form>'
);

$('#new_script_form_prepare').submit(function(event) {
  $.post("/plugin/source_edit/create_script", $(this).serialize(), function(data) {
    var url = data.url;
    var mime_type = data.mime_type;
    $(".alert-create-script").html(url + ' created.').addClass("alert-success").removeClass("alert-danger");
    var opts = {
      action: 'get_content',
      col: 'prepare',
      plugin: 'source_edit',
      mime_type: mime_type,
      url: url
    };
    LW.prepare_controller.refresh_content(opts, 'POST');
  }).fail(function(data) {
    $(".alert-create-script").html(data.responseText).addClass("alert-danger").removeClass("alert-success");
  }).always(function(data) {
    $(".alert-create-script").show();
  });
  return false;
});
