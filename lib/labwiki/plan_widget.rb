
require 'labwiki/column_widget'
require 'labwiki/theme/col_content_renderer'

module LabWiki    
  
  # Responsible for the PLAN column
  # Only shows formated text 
  #
  class PlanWidget < ColumnWidget
    
    def on_get(opts, req)
      super
      path = opts[:path]  
      content_proxy = OMF::Web::ContentRepository[{}].load(:path => path)
      #puts "CONTENT>>>> #{content_proxy.content}"
      if @embedded_widget
        @embedded_widget.content_proxy = content_proxy
      else
        margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
        e = {:type => :text, :height => 800, :content => content_proxy, :margin => margin}
        @embedded_widget = OMF::Web::Widget.create_widget(e)
      end
      r = OMF::Web::Theme::ColumnContentRenderer.new(self, @embedded_widget, @name)
      [r.to_html, "text/html"]
    end
    
  end
end
