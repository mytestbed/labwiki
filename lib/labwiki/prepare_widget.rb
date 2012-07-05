
require 'labwiki/column_widget'
require 'labwiki/theme/col_content_renderer'

module LabWiki    
  
  # Responsible for the prepare column
  # Only shows code editors
  #
  class PrepareWidget < ColumnWidget
    
    def on_get(req)
      margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
      e = {:type => :code, :height => 800, :content => {:url => 'sample2.md'}, :margin => margin}
      @embedded_widget = OMF::Web::Widget.create_widget(e)
      r = OMF::Web::Theme::ColumnContentRenderer.new(self, @name)
      [r.to_html, "text/html"]
    end
    
  end
end
