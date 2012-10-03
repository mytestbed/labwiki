
require 'omf-web/theme/bright/widget_chrome'

module OMF::Web::Theme
  
  # Override some of the functionality of the text renderer defined in OMF::Web
  class TextRenderer < Erector::Widget
    
    def initialize(text_widget, content, opts)
      super opts
      @widget = text_widget
      @content = content
      @content_descriptor = opts[:content].content_descriptor
    end
    
    def content
      link :href => '/plugin/plan_text/css/plan_text.css', :rel => "stylesheet", :type => "text/css"
      wid = "w#{@widget.object_id}"
      div :class => "text plan_text", :id => wid do
        rawtext @content.to_html
      end
      javascript %{
        L.require('#LW.plugin.plan_text.plan_text_monitor', '/plugin/plan_text/js/plan_text_monitor.js', function() {
          var r_#{object_id} = LW.plugin.plan_text.plan_text_monitor(#{@content_descriptor.to_json});
        })
      }
    end
          
  end 

end # OMF::Web::Theme
