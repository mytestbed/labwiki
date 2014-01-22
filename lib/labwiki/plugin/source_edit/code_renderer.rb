
require 'omf-web/theme/bright/code_renderer'

module OMF::Web::Theme

  # Override some of the functionality of the code renderer defined in OMF::Web
  class CodeRenderer
    def render_widget_creation(base_id, opts)
      link :href => "/resource/plugin/source_edit/css/codemirror.css",
          :media => "all", :rel => "stylesheet", :type => "text/css"

      javascript(%{
        require(['plugin/source_edit/js/code_mirror2'], function(code_mirror2) {
          OML.widgets.#{base_id} = new code_mirror2(#{opts.to_json});
        });
      })
    end

  end

end
