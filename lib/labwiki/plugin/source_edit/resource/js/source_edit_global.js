LW.prepare_controller.add_tool('Edit',
  '<div class="form-group">\
     <input class="form-control" name="file_name" placeholder="File name" type="text" value="" required>\
   </div>\
   <div class="form-group">\
     <select class="form-control" name="file_ext">\
       <option value="oedl">OEDL</option>\
       <option value="md">Wiki</option>\
       <option value="r">R</option>\
     </select>\
   </div>\
   <button class="btn" type="submit">Create</button>',
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

define([], function() {
  LW.prepare_controller.add_tool('Edit',
    '<div class="form-group">\
       <input class="form-control" name="file" placeholder="File name" type="file" value="" required>\
     </div>\
     <button class="btn" type="submit">Upload</button>',
    function (form, status_cbk) {
      var formData = new FormData(form[0]);
      $.ajax({
        url: '/plugin/source_edit/upload',
        type: 'POST',
        xhr: function () {  // Custom XMLHttpRequest
          var myXhr = $.ajaxSettings.xhr();
          if (myXhr.upload) { // Check if upload property exists
            myXhr.upload.addEventListener('progress', onProgress, false);
          }
          return myXhr;
        },
        //Ajax events
        //beforeSend: beforeSendHandler,
        success: onComplete,
        error: onError,
        complete: function () {
          LW.prepare_controller.close_tool_list();
        },
        // Form data
        data: formData,
        //Options to tell jQuery not to process data or worry about content-type.
        cache: false,
        contentType: false,
        processData: false
      });
    }
  );

  function onComplete(reply, textStatus) {
    LW.prepare_controller.show_alert("info", "Successfully uploaded '" + reply.url + "'.");
  }

  function onError(xhr, textStatus, errorThrown) {
    LW.prepare_controller.show_alert("error", xhr.responseText);
  }

  function onProgress(e) {
    if (e.lengthComputable) {
      var attr = {value: e.loaded, max: e.total};
      //$('progress').attr(attr);
    }
  }

});

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
