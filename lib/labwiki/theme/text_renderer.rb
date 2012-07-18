
require 'omf-web/theme/bright/widget_chrome'

module OMF::Web::Theme
  
  class TextRenderer < Erector::Widget
    
    def initialize(text_widget, content, opts)
      super opts
      @widget = text_widget
      @content = content
    end
    
    def content
      wid = "w#{@widget.object_id}"
      div :class => "text", :id => wid do
        rawtext @content.to_html
        render_content_observer(wid)
      end
      
    end
    
    def render_content_observer(div_id)
      javascript(%{
        OHUB.bind("content.changed.#{@widget.content_id}", function(evt) {
          // Need a way to find the associated column controller
          // Maybe walking up the DOM tree to look for some element whose
          // id contains the column name - convoluted, but passing the col name
          // through to the rendere is most likely even harder.
          var p = $('\##{div_id}').parents();
          $.each(p, function(index, value) { 
            console.log(index + ': ' + value); 
          });
        });
      })
    end

      
  end 

end # OMF::Web::Theme
