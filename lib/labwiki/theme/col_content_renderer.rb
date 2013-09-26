


module OMF::Web::Theme
  class ColumnContentRenderer < Erector::Widget
    include OMF::Base::Loggable
    extend OMF::Base::Loggable

    MIMETYPE2ICON = {
      'text' => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      'text/html' => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      "text/something" => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      "code" => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      'experiment' => "/resource/vendor/mono_icons/experiment32.png"
    }

    def initialize(widget, col_name)
      @widget = widget
      @col_name = col_name
    end

    def content
      div :id => "col_content_#{@col_name}" do
        if @widget
          render_title
          render_body
        else
          div :class => "drop-target", :style => 'height: 400px'
        end
      end
    end

    def render_title()
      div :class => "block block-nav widget-title-block" do
        div :class => "drop-target" do
          div :class => "summary" do
            mime_type = @widget.mime_type
            unless img_src = MIMETYPE2ICON[mime_type]
              # try default
              mime_type = mime_type.split('/')[0]
              img_src = MIMETYPE2ICON[mime_type]
            end
            if img_src
              div :class => 'widget-title-icon' do
                img :src => img_src
              end
            else
              debug "Couldn't find icon for mime-type '#{mime_type}'"
            end
            div :class => "label" do
              text  @widget.title
            end
            div :class => "info" do
            end
          end
          div :class => 'widget-title-toolbar-container'
        end
      end
    end

    def render_body
      div :class => "panel-body", :style => "height: 200px; " do
        div :class => "block block-content widget_container" do
          if widget = @widget
            div :class => "widget_body widget_body_#{widget.widget_type}" do
              rawtext widget.content_renderer().to_html
            end
          end
        end
      end
    end
  end # class
end # OMF::Web::Theme
