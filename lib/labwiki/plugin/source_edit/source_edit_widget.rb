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
      @content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(@content_url, params)
    end

    def on_get_plugin(params, req)
      opts = params[:params]
      debug "on_get_plugin: '#{opts.inspect}'"
      @content_url = opts[:url]
      @content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(@content_url, opts)
      @mime_type = @content_proxy.mime_type
    end


    def content_renderer()
      OMF::Web::Theme.require 'code_renderer2'
      mode = @mime_type.split('/')[-1]
      OMF::Web::Theme::CodeRenderer2.new(self, @content_proxy.content, mode, @opts)
    end

    def title
      @content_proxy.name.split('/')[-1]
    end

    def sub_title
      @content_proxy.name
    end

    def mime_type
      @mime_type
    end

    def content_url
      @content_url
    end

    def update_url
      @content_proxy.content_url
    end

    def content_id
      @content_proxy.content_id
    end

  end # class

end # module
