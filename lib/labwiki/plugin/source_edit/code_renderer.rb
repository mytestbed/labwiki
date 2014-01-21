
require 'omf-web/theme/bright/code_renderer'

module OMF::Web::Theme

  # Override some of the functionality of the code renderer defined in OMF::Web
  class CodeRenderer     
    def render_widget_creation(base_id, opts)
      link :href => "/resource/theme/labwiki/css/codemirror.css", 
          :media => "all", :rel => "stylesheet", :type => "text/css"
      
      javascript(%{
        L.require('#OML.code_mirror2', '/resource/theme/labwiki/js/code_mirror2.js', function() {
          OML.widgets.#{base_id} = new OML.code_mirror2(#{opts.to_json});
        });
      })
    end
    
  end
  
end
