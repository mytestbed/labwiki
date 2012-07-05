
require 'omf_common/lobject'
require 'omf-web/widget'
require 'labwiki/theme/col_content_renderer'

module LabWiki    
  
  # Responsible for the content to be shown in a particular column 
  class ColumnWidget < OMF::Common::LObject
    
    attr_reader :embedded_widget, :name

    def initialize(name)
      @name = name
    end
    
    def empty?
      @embedded_widget.nil?
    end
    
    def on_get(req)
      margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
      t = {:type => :text, :content => {:url => 'sample2.md'}, :margin => margin}      
      @embedded_widget = OMF::Web::Widget.create_widget(t)
      r = OMF::Web::Theme::ColumnContentRenderer.new(self, @name)
      [r.to_html, "text/html"]
    end
    
    def collect_data_sources(ds_set)
      if @embedded_widget
        @embedded_widget.collect_data_sources(ds_set)
      end
      ds_set
    end
  end
end
