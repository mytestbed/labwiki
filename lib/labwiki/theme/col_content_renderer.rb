


module OMF::Web::Theme
  class ColumnContentRenderer < Erector::Widget
    include OMF::Common::Loggable
    extend OMF::Common::Loggable    
    
    MIMETYPE2ICON = {
      'text' => "/resource/vendor/mono_icons/linedpaper32.png",
      'text/html' => "/resource/vendor/mono_icons/linedpaper32.png",
      "text/something" => "/resource/vendor/mono_icons/linedpaperpencil32.png",
      "code" => "/resource/vendor/mono_icons/linedpaperpencil32.png",    
      'experiment' => "/resource/vendor/mono_icons/experiment32.png"
    }
    
    def initialize(widget, embedded_widget, col_name)
      @widget = widget
      @embedded_widget = embedded_widget
      @col_name = col_name
    end
        
    def content
      div :id => "col_content_#{@col_name}" do 
        if @embedded_widget
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
            mime_type = @embedded_widget.mime_type
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
              debug "Couldn't find icon for mime-type '#{@widget.mime_type}'"
            end
            div :class => "label" do
              text  @embedded_widget.title
            end
            div :class => "info" do
            end
          end
        end
      end
    end
     
    def render_body
      div :class => "panel-body", :style => "height: 200px; " do
        div :class => "block block-content widget_container" do
          if widget = @embedded_widget
            div :class => "widget_body widget_body_#{widget.widget_type}" do
              rawtext widget.content().to_html 
            end
          end 
        end
      end
    end
  end # class 
end # OMF::Web::Theme
