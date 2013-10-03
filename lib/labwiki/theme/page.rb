

require 'omf-web/theme/abstract_page'
require 'labwiki/theme/column_renderer'

module OMF::Web::Theme
  class Page < OMF::Web::Theme::AbstractPage

    depends_on :css, "/resource/vendor/bootstrap/css/bootstrap.css"
    depends_on :css, '/resource/theme/bright/css/reset-fonts-grids.css'
    depends_on :css, "/resource/theme/bright/css/bright.css"
    depends_on :css, "/resource/theme/labwiki/css/kaiten.css"
    depends_on :css, "/resource/theme/labwiki/css/labwiki.css"

    # depends_on :js, '/resource/vendor/jquery/jquery.periodicalupdater.js'
    # depends_on :js, "/resource/vendor/jquery-ui/js/jquery-ui.min.js"
    #depends_on :js, "/resource/vendor/jquery-ui/js/jquery.ui.autocomplete.js"

    depends_on :js, "/resource/theme/labwiki/js/column_controller.js"
    depends_on :js, "/resource/theme/labwiki/js/content_selector_widget.js"
    #depends_on :js, "/resource/theme/labwiki/js/execute_col_controller.js"
    depends_on :js, "/resource/theme/labwiki/js/labwiki.js"



    def initialize(widget, opts)
      super
      @title = "LabWiki"
      index = -1

      @col_renderers = [:plan, :prepare, :execute].map do |name|
        index += 1
        ColumnRenderer.new(name.to_s.capitalize, @widget.column_widget(name), name, index)
      end
    end

    def content
      javascript %{
        if (typeof(LW) == "undefined") LW = {};
        if (typeof(LW.plugin) == "undefined") LW.plugin = {};

        LW.session_id = OML.session_id = '#{OMF::Web::SessionStore.session_id}';

        L.provide('jquery', ['/resource/vendor/jquery/jquery.js']);
        L.provide('jquery.periodicalupdater', ['/resource/vendor/jquery/jquery.periodicalupdater.js']);
        L.provide('jquery.ui', ['/resource/vendor/jquery-ui/js/jquery-ui.min.js']);
        X = null;
        /*
        $(document).ready(function() {
          X = $;
        });
        */
      }
      div :id => "container", :style => "position: relative; height: 100%;" do
        div :id => "k-window" do
          div :id => "k-topbar" do
            span :class => 'brand' do
              text "LabWiki"
            end
            span :class => 'brand', :style=> "font-size: 110%; line-height: 29px;" do
              text "by NICTA"
            end
            ul :class => 'secondary-nav' do
              #if OMF::Web::SessionStore[:exps, :gimi].nil?
              #  li :style => "padding-top: 6px; margin-right: 10px;" do
              #    span :class => 'label label-warning' do
              #      text "You don't have any projects or experiments associated, certain features might not function properly."
              #    end
              #  end
              #end
              li do
                div class: 'dropdown' do
                  a :class => 'dropdown-toggle', :'data-toggle' => 'dropdown', :href => '#' do
                    text 'Experiment Context'
                  end
                end
              end
              li do
                a :href => '#', :class => 'user' do
                  i :class => "icon-user icon-white"
                  text OMF::Web::SessionStore[:id, :user] || 'Unknown'
                end
              end
              li do
                a :href => '/logout', :class => 'logout' do
                  i :class => "icon-off icon-white"
                  text 'Log out'
                end
              end
            end
          end
          div :id => "k-slider", :style => "height: 500px;" do
            @col_renderers.each do |renderer|
              rawtext renderer.to_html
            end
          end
        end
      end
    end

  end # class Page
end # OMF::Web::Theme
