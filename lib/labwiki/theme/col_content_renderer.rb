


module OMF::Web::Theme
  class ColumnContentRenderer < Erector::Widget
    
    MIMETYPE2ICON = {
      'text' => "/resource/vendor/mono_icons/linedpaper32.png",
      'text/html' => "/resource/vendor/mono_icons/linedpaper32.png",
      "text/something" => "/resource/vendor/mono_icons/linedpaperpencil32.png",
    }
    
    def initialize(widget, col_name)
      @widget = widget
      @col_name = col_name
    end
        
    def content
      div :id => "col_content_#{@col_name}" do 
        if ! @widget.empty?
          render_title
          render_body
        end
      end
    end
    
    def render_title()
      div :class => "block block-nav widget-title-block" do
        div :class => "drop-target" do
          div :class => "summary" do
            if img_src = MIMETYPE2ICON[@widget.embedded_widget.mime_type]
              div :class => 'widget-title-icon' do
                img :src => img_src 
              end
            end
            div :class => "label" do
              text  @widget.embedded_widget.title
            end
            div :class => "info" do
            end
          end
        end
      end
    end
     
    def render_body
      div :class => "panel-body", :style => "height: 376px; " do
        div :class => "block block-content widget_container" do
          if widget = @widget.embedded_widget
            div :class => "widget_body widget_body_#{widget.widget_type}" do
              rawtext widget.content().to_html 
            end
          end 
        end
      end
    end
  end # class 
end # OMF::Web::Theme
