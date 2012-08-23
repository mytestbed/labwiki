

require 'omf-web/theme/abstract_page'
require 'labwiki/theme/column_renderer'

module OMF::Web::Theme
  class Page < OMF::Web::Theme::AbstractPage
    
    depends_on :css, '/resource/theme/bright/css/reset-fonts-grids.css'
    depends_on :css, "/resource/theme/bright/css/bright.css"
    depends_on :css, "/resource/theme/labwiki/css/kaiten.css"
    depends_on :css, "/resource/theme/labwiki/css/labwiki.css"    
    
    depends_on :js, "/resource/vendor/jquery-ui/js/jquery-ui.min.js"
    depends_on :js, "/resource/vendor/jquery-ui/js/jquery.ui.autocomplete.js"        

    
    depends_on :js, "/resource/theme/labwiki/js/column_controller.js"        
    depends_on :js, "/resource/theme/labwiki/js/content_selector_widget.js"            
    depends_on :js, "/resource/theme/labwiki/js/execute_col_controller.js"            
    depends_on :js, "/resource/theme/labwiki/js/labwiki.js"        
   

       
    def initialize(widget, opts)
      super
      @title = "LabWiki"
      index = -1
      @col_renderers = [:plan, :prepare, :execute].map do |name|
        index += 1
        ColumnRenderer.new(name.to_s.capitalize, @widget.column_widget(name), name, index)
      end
      # @plan_renderer = ColumnRenderer.new('Plan', @widget.column_widget(:plan), :plan, 0)
      # @prepare_renderer = ColumnRenderer.new('Prepare', @widget.column_widget(:prepare), :prepare, 1)
      # @execute_renderer = ColumnRenderer.new('Execute', @widget.column_widget(:execute)t, :execute, 2)

    end
 
    def content
      
      # <meta name="apple-mobile-web-app-capable" content="yes">
      # <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
      # <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      # #<link rel="icon" type="image/png" href="file://localhost/Users/max/Downloads/v1.2.2%202/images/kaiten-boxed-favicon.png" sizes="16x16">
      # <link rel="stylesheet" type="text/css" href="./dom_files/kaiten.min.css">
    
      javascript %{
        if (typeof(LW) == "undefined") LW = {};
        LW.session_id = '#{Thread.current["sessionID"]}';
      }    
      div :id => "container", :style => "position: relative; height: 100%;" do
        div :id => "k-window" do
          div :id => "k-topbar" do
          end
          div :id => "k-slider", :style => "height: 500px;" do
            @col_renderers.each do |renderer|
              rawtext renderer.to_html
            end
            # rawtext @plan_renderer.to_html
            # rawtext @prepare_renderer.to_html
            # rawtext @execute_renderer.to_html
          end
        end
      end
    end
    
  end # class Page
end # OMF::Web::Theme
