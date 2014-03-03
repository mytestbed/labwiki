


module OMF::Web::Theme
  class ColumnContentRenderer < Erector::Widget
    include OMF::Base::Loggable
    extend OMF::Base::Loggable

    MIMETYPE2ICON = {
      'text' => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      'text/html' => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      "text/something" => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      "code" => "/resource/vendor/mono_icons/linedpaperpencil32.png"
      #'experiment' => "/resource/vendor/mono_icons/experiment32.png"
    }

    def initialize(widget, col_name)
      @widget = widget
      @col_name = col_name
      @content_renderer = widget.content_renderer() if widget
    end

    def content
      div :id => "col_content_#{@col_name}" do
        if @widget
          render_title2
          render_body
        else
          div :class => "drop-target", :style => 'height: 400px'
        end
      end
    end

    def render_title()
      div :class => "block block-nav widget-title-block" do
        div :class => "drop-target" do
          ti = title_info
          sopts = {:class => 'summary'}
          if (p = ti[:widget_id])
            sopts[:id] = p + "_widget_summary"
          end
          div sopts do
            if ti[:img_src]
              div :class => 'widget-title-icon' do
                img :src => ti[:img_src]
              end
            else
              debug "Couldn't find icon for mime-type '#{mime_type}'"
            end
            div :class => "label title" do
              text  ti[:title] || 'Unknown'
            end
            div :class => "info sub_title" do
              if st = ti[:sub_title]
                text st
              end
            end
          end
          div :class => 'widget-title-toolbar-container'
        end
      end
    end

    def render_title2()
      div :class => "block block-nav widget-title-block" do
        div :class => "drop-target" do
          ti = title_info
          id_prefix = ti[:widget_id] || "wx#{object_id}"
          div :class => 'col-summary' do
            # The nested divs are used to vertically center the icon.
            # Thanks to http://blog.themeforest.net/tutorials/vertical-centering-with-css/
            div :class => "wrapper" do
              div :class => "cell" do
                div :class => "summary-icon" do
                  if ti[:img_src]
                    div :class => 'widget-title-icon' do
                      img :src => ti[:img_src], :id => id_prefix + "_widget_icon"
                    end
                  else
                    debug "Couldn't find icon for mime-type '#{mime_type}'"
                  end
                end
              end
              div :class => 'cell' do
                div :class => "title-block" do
                  div :class => "title", :id => id_prefix + "_widget_title" do
                    text  ti[:title] || 'Unknown'
                  end
                  div :class => "sub_title", :id => id_prefix + "_widget_sub_title" do
                    if st = ti[:sub_title]
                      text st
                    end
                  end
                end
              end
            end
          end
          div :class => 'widget-title-toolbar-container'
        end
      end
    end

    def title_info
      if @content_renderer.respond_to? :title_info
        return @content_renderer.title_info
      end

      mime_type = @widget.mime_type
      unless img_src = MIMETYPE2ICON[mime_type]
        # try default
        mime_type = mime_type.split('/')[0]
        img_src = MIMETYPE2ICON[mime_type]
      end
      {
        img_src: img_src,
        title: @widget.title,
        sub_title: @widget.sub_title
      }

    end

    def render_body
      div :class => "panel-body", :style => "height: 200px; " do
        div :class => "block block-content widget_container" do
          if widget = @widget
            div :class => "widget_body widget_body_#{widget.widget_type}" do
              rawtext @content_renderer.to_html
            end
          end
        end
      end
    end
  end # class
end # OMF::Web::Theme
