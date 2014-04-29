
#require 'coderay'
require 'omf-web/theme/abstract_page'

module OMF::Web::Theme

  class CodeRenderer2 < Erector::Widget

    #depends_on :css, "/resource/css/coderay.css"

    # This maps the content's mime type to a different mode  supported
    # CodeMirror
    #
    MODE_MAPPER = {
      :markup => :markdown
    }

    def initialize(widget, content, mode, opts)
      super opts
      @widget = widget
      @content = content
      @mode = MODE_MAPPER[mode.to_sym] || mode
      @opts = opts
    end

    def content()

      base_id = "cm#{self.object_id}"
      edit_id = base_id + '_e'
      mode = @mode

      opts = @opts.dup
      opts.delete :id
      opts.delete :layout
      opts.delete :top_level
      opts.delete :priority
      opts.merge!(
        :base_el => "#" + base_id,
        :edit_el => '#' + edit_id,
        :content => @content.to_s,
        :mode => mode,
        :save_url => @widget.update_url,
        :read_only => @widget.read_only?
      )

      div :id => base_id, :class => "codemirror_widget" do
        ['codemirror', 'util/dialog'].each do |f|
          link :href => "/resource/vendor/codemirror/lib/#{f}.css",
            :media => "all", :rel => "stylesheet", :type => "text/css"
        end

        ['codemirror', 'util/dialog', 'util/searchcursor', 'util/search', 'util/loadmode'].each do |f|
          script :src => "/resource/vendor/codemirror/lib/#{f}.js"
        end

        # Div where the text should go
        div :id => edit_id, :class => "codemirror_edit" #, :style => 'height:100%'

        render_widget_creation(base_id, opts)
      end
    end

    def render_widget_creation(base_id, opts)
      link :href => "/resource/plugin/source_edit/css/codemirror.css",
          :media => "all", :rel => "stylesheet", :type => "text/css"

      javascript(%{
        require(['plugin/source_edit/js/code_mirror2'], function(code_mirror2) {
          OML.widgets.#{base_id} = new code_mirror2(#{opts.to_json});
        });
      })
    end

    def title_info
      url = @widget.content_url
      ti = {
        mime_type: @widget.mime_type,
        title: url.split('/')[-1],
        sub_title:  url,
        read_only: @widget.read_only?
      }
      if @widget.read_only?
        ti[:title_badge] = {text: 'Read-only', severity: 'warning'}
      end
      ti
    end


  end

end
