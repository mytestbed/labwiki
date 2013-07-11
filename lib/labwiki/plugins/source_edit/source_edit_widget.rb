require 'labwiki/column_widget'
require 'omf-web/content/repository'

module LabWiki::Plugin::SourceEdit

  # Maintains the context for a particular editing session on a file.
  #
  class SourceEditWidget < LabWiki::ColumnWidget

    def initialize(column, config_opts, unused)
      unless column == :prepare
        raise "Should only be used in ':prepare' column"
      end
      super column, :type => :source_edit
    end


    def on_get_content(params, req)
      debug "on_get_content: '#{params.inspect}'"

      @mime_type = (params[:mime_type] || 'text')#.gsub('text', 'code')
      @content_url = params[:url]
      content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(@content_url, params)
      _get_content_widget(content_proxy)
    end

    def on_get_plugin(params, req)
      opts = params[:params]
      debug "on_get_plugin: '#{opts.inspect}'"
      @content_url = opts[:url]
      content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(@content_url, opts)
      @mime_type = content_proxy.mime_type
      _get_content_widget(content_proxy)
    end


    def content_renderer()
      @code_widget.content()
    end

    def _get_content_widget(content_proxy)
      if @code_widget
        @code_widget.content_proxy = content_proxy
      else
        margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
        e = {:type => :code, :height => 800, :content => content_proxy, :margin => margin}
        @code_widget = OMF::Web::Widget.create_widget(e)
      end

    end
    # def title
      # @title
    # end



  end # class

end # module