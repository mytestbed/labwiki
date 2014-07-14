

require 'labwiki/theme/col_content_renderer'

module OMF::Web::Theme
  class ColumnRenderer < Erector::Widget


    def initialize(title, widget, col_name, position)
      @title = title
      @widget = widget
      @col_name = col_name
      @position = position
      @content_renderer = ColumnContentRenderer.new(widget, col_name)
    end

    def content
      title = @title
      #widget = @widget
      pos = @position
      width = 400
      style = "overflow-y: hidden; left: #{width * pos}px; width: #{width}px; display: block; "
      div :class => "k-panel k-focus", :id => "kp#{pos}", :style => style do
        render_panel_titlebar(title)
        render_panel_selector_bar
        rawtext @content_renderer.to_html()
        div :class => "mask", :style => "display: none; " do
          div :class => "loader"
        end
      end
      opts = {:sid => OMF::Web::SessionStore.session_id, :col => @col_name}
      if @widget
        opts.merge!(@widget.content_descriptor)
        # if cd = @widget.content_url
          # opts[:content] = cd
        # end
      end
      javascript %{
        require(['theme/labwiki/js/labwiki'], function(lw) {
          lw.#{@col_name}_controller.init('lw#{object_id}', #{opts.to_json});
        });
      }

    end

    def render_panel_titlebar(title)
      prefix = "kp#{@position}_"
      div :class => "titlebar" do
        table do
          tbody do
            tr do
              td :class => "left" do
                button :id => prefix + 'maximize_left_buttom', :class => "tool maximize", :title => "Resize", :style => "display:none"
                #button :class => "tool reload", :title => "Reload"
              end
              td :class => "center" do
                div :class => "title" do
                  text title
                end
              end
              td :class => "right" do
                button :id => prefix + 'maximize_right_buttom', :class => "tool maximize", :title => "Resize", :style => "display:none"
                #button :class => "tool newtab", :title => "Open this panel in a new tab"
              end
            end
          end
        end
      end

    end

    def render_panel_selector_bar
      div :id => "lw#{object_id}_search", :class => "block-nav content-selection" do
        table do
          tr do
            td :class => 'action-buttons', :style => 'display: none; width: 32px' do
              button :class => "tool-button" do
                span :class => "glyphicon glyphicon-cog"
              end
            end
            td do
              form :id => "lw#{object_id}_csf", :class => "quicksearch k-active", :onsubmit => "return false;" do
                div :class => "container rounded-corners" do
                  button :class => "head search"
                  input :id => "lw#{object_id}_si", :class => "input", :type => "text", :value => "" do
                    button :class => "tail reset"
                  end
                  button :class => "tail reset"
                end
              end
            end
          end
        end
        div :class => "suggestion-list selection-list", :style => 'display: none;' do
          ul :class => 'suggestion-list selection-list ui-menu'
        end
        div :class => "tools-list selection-list", :style => 'display: none;' do
          ul :class => 'tools-list selection-list ui-menu'
        end
      end

    end

  end # class
end # OMF::Web::Theme
