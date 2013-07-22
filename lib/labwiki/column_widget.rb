
require 'omf_common/lobject'
require 'omf-web/widget'
require 'labwiki/theme/col_content_renderer'

module LabWiki

  # Responsible for the content to be shown in a particular column
  class ColumnWidget < OMF::Common::LObject

    def initialize(col, opts)
      @column = col
      @opts = opts
    end

    def widget_type
      @opts[:type] || :unknown
    end

    def title
      @title || content_url
    end

    def content_url
      @content_url || @opts[:url] || :unknown
    end

    def mime_type
      @mime_type || 'unknown'
    end

    def content_descriptor
      {:mime_type => mime_type, :url => content_url}
    end

    def collect_data_sources(ds_set)
      ds_set
    end

    # Should most likely get implemented by the specific widget
    def on_get_content(params, req)
      @content_opts = params

      debug "on_get_content: '#{params.inspect}'"
      self
    end

    def on_get_plugin(params, req)
      @content_opts = params

      debug "on_get_plugin: '#{params.inspect}'"
      self
    end

  end
end
