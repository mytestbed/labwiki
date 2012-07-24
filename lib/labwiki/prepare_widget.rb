
require 'omf-web/content/repository'
require 'labwiki/column_widget'
require 'labwiki/theme/col_content_renderer'

module LabWiki    
  
  # Responsible for the prepare column
  # Only shows code editors
  #
  class PrepareWidget < ColumnWidget

    def mime_type
      # Replace leading 'text' with 'code
      super.gsub('text', 'code') 
    end

    def on_get_content(params, req)
      p = parse_req_params(params, req)
      debug "on_get_content '#{p.inspect}'"
      
      if p[:mime_type].start_with? 'text'
        on_get_code(p, params, req)
      else
        raise "Don't know what to do with mime-type '#{mime_type}'"
      end
    end
      
    def on_get_code(content_descr, opts, req)
      content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(content_descr, opts)
      if @code_widget
        @code_widget.content_proxy = content_proxy
      else
        margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
        e = {:type => :code, :height => 800, :content => content_proxy, :margin => margin}
        @code_widget = OMF::Web::Widget.create_widget(e)
      end
      @embedded_widget = @code_widget
      r = OMF::Web::Theme::ColumnContentRenderer.new(self, @code_widget, @name)
      #puts r.to_html
      [r.to_html, "text/html"]
    end
    
  end
end
