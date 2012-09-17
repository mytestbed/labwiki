require 'labwiki/column_widget'
require 'omf-web/content/repository'

module LabWiki::Plugin::PlanText    
      
  # Maintains the context for a MarkDown formatted text column.
  #
  class PlanTextWidget < LabWiki::ColumnWidget
    
    def initialize(column, unused)
      unless column == :plan
        raise "Should only be used in ':plan' column"
      end
      super column, :type => :plan
    end
    

    def on_get_content(params, req)
      debug "on_get_content: '#{params.inspect}'"
      
      @mime_type = (params[:mime_type] || 'text')
      @content_url = params[:url]
      content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(@content_url, params)
      if @text_widget
        @text_widget.content_proxy = content_proxy
      else
        margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
        e = {:type => :text, :height => 800, :content => content_proxy, :margin => margin}
        @text_widget = OMF::Web::Widget.create_widget(e)
      end
    end

    def content_renderer()
      @text_widget.content()
    end
    
    def title
      @text_widget.title
    end    
    
  end # class

end # module