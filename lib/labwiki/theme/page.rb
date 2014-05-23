

require 'omf-web/theme/abstract_page'
require 'labwiki/theme/column_renderer'
require 'labwiki/plugin_manager'

module OMF::Web::Theme
  class Page < OMF::Web::Theme::AbstractPage

    depends_on :css, "/resource/vendor/bootstrap/css/bootstrap.css"
    depends_on :css, "/resource/vendor/font-awesome/css/font-awesome.min.css"
    depends_on :css, "/resource/vendor/smartmenus/addons/bootstrap/jquery.smartmenus.bootstrap.css"
    depends_on :css, '/resource/theme/bright/css/reset-fonts-grids.css'
    depends_on :css, "/resource/theme/bright/css/bright.css"
    depends_on :css, "/resource/theme/labwiki/css/kaiten.css"
    depends_on :css, "/resource/theme/labwiki/css/labwiki.css"

    # depends_on :js, '/resource/vendor/jquery/jquery.periodicalupdater.js'
    # depends_on :js, "/resource/vendor/jquery-ui/js/jquery-ui.min.js"
    #depends_on :js, "/resource/vendor/jquery-ui/js/jquery.ui.autocomplete.js"

    #depends_on :js, "/resource/theme/labwiki/js/column_controller.js"
    #depends_on :js, "/resource/theme/labwiki/js/content_selector_widget.js"
    #depends_on :js, "/resource/theme/labwiki/js/execute_col_controller.js"
    #depends_on :js, "/resource/theme/labwiki/js/labwiki.js"

    # Pretend experiment context doesn't exist for a moment
    #depends_on :js, "/resource/theme/labwiki/js/exp_context.js"

    depends_on :js, "/resource/vendor/bootstrap/js/bootstrap.js"
    depends_on :js, '/resource/vendor/jquery/jquery.js'
    depends_on :js, '/resource/vendor/jquery/jquery.periodicalupdater.js'
    depends_on :js, '/resource/vendor/jquery-ui/js/jquery-ui.min.js'
    depends_on :js, '/resource/vendor/jquery.ui.touch-punch.min.js'
    depends_on :js, '/resource/vendor/smartmenus/jquery.smartmenus.js'
    depends_on :js, '/resource/vendor/smartmenus/addons/bootstrap/jquery.smartmenus.bootstrap.js'
    depends_on :js, '/resource/vendor/d3/d3.js'

    def initialize(widget, opts)
      super
      @title = "LabWiki"
      index = -1

      @col_renderers = [:plan, :prepare, :execute].map do |name|
        index += 1
        ColumnRenderer.new(name.to_s.capitalize, @widget.column_widget(name), name, index)
      end
    end

    def render_additional_headers
      "\n<meta http-equiv='content-type' content='text/html;charset=UTF8' />\n"
    end

    def content
      gjsa = LabWiki::PluginManager.get_global_js().map do |js|
        "require(['#{js}'], function() {});"
      end
      javascript %{
        require(['theme/labwiki/js/labwiki'], function() {
          LW.session_id = OML.session_id = '#{OMF::Web::SessionStore.session_id}';
          #{gjsa.join("\n")}
        });
      }
      div :id => "container", :style => "position: relative; height: 100%;" do
        div :id => "k-window" do
          div :id => "k-topbar" do
            span "LabWiki", :class => 'brand'
            ul class: 'nav navbar-nav' do
              li do
                a id: 'about-menu-a', class: 'nav-menu', href: "#" do
                  text 'by NICTA'
                end
                ul id: 'about-menu-ul', class: "dropdown-menu" do
                  li do
                    div id: 'about-menu-div' do
                      p %{
                        Some gushing words about the good people at NICTA who
                        brought this wonderful tool to the world.
                      }
                    end
                  end
                end
              end
            end

            unless LabWiki::Configurator[:stable]
              if LabWiki::Configurator[:stable_instance_location]
                span :class => 'label label-warning', :style => "font-size: 110%; line-height: 29px; margin-left: 10px;" do
                  text "This is NOT the stable instance. You could visit "
                  a :href => LabWiki::Configurator[:stable_instance_location] do
                    text "the stable instance here."
                  end
                end
              end
            end

            ul class: 'nav navbar-nav navbar-right' do
              li do
                a id: 'tools-menu-a', class: 'nav-menu', href: "#" do
                  i :class => "glyphicon glyphicon-cog icon-white"
                  text 'Tools'
                end
                ul id: 'tools-menu-ul', class: "dropdown-menu" do
                  li 'GIMI', class: "dropdown-header"
                  if (authorisation_info = LabWiki::Configurator[:session][:authorisation])
                    li do
                      #a "Add experiment context", href: "#"
                      a "Authorise", href: "#{authorisation_info[:url]}?id=labwiki&backto=#{authorisation_info[:callback_url]}"
                    end
                  end
                end
              end

              li class: 'last-nav-link' do
                a id: 'user-menu-a', class: 'nav-menu', href: "#" do
                  i :class => "glyphicon glyphicon-user icon-white"
                  #text (OMF::Web::SessionStore[:name, :user] || 'Unknown').capitalize
                  text OMF::Web::SessionStore[:name, :user] || 'Unknown'
                end
                ul id: 'user-menu-ul', class: 'nav-menu', class: "dropdown-menu" do
                  li do
                    a id: 'user-menu-logout-a', class: 'nav-menu-item', href: "#" do
                      i :class => "glyphicon glyphicon-off icon-white"
                      text "Logout"
                    end
                  end
                end
              end

              # li do
                # a :class => "dropdown-toggle", :id => "topbar-tools-menu-toggle", 'data-toggle' => "dropdown" do
                  # i :class => "tools"
                  # text 'Tools'
                  # span class: "caret"
                # end
                # #ul :id => "topbar-tools-menu", :class => "dropdown-menu", :role => "menu", 'aria-labelledby' => "topbar-tools-menu-toggle" do
                # ul :id => "topbar-tools-menu", :class => "dropdown-menu" do
                  # li :class => 'dropdown-header', :role => "presentation" do
                    # text "GIMI"
                  # end
                  # li role: "presentation" do
                    # a 'Action', role: "menuitem", tabindex: "-1", href: "#"
                  # end
                  # li :class => 'divider', :role => "presentation"
                  # li role: "presentation" do
                    # a 'Action', role: "menuitem", tabindex: "-1", href: "#"
                  # end
                # end
              # end
#
              # li do
                # a :href => '#new-exp-modal', :role => 'button', :"data-toggle" => "modal" do
                  # i :class => "icon-asterisk icon-white"
                  # text "Add experiment context"
                # end
              # end
              # li do
                # a :href => '#', :class => 'user' do
                  # i :class => "glyphicon glyphicon-user icon-white"
                  # text (OMF::Web::SessionStore[:name, :user] || 'Unknown').capitalize
                # end
              # end
              # li do
                # a :href => '/logout', :class => 'logout' do
                  # i :class => "glyphicon glyphicon-off icon-white"
                  # text "Log out"
                # end
              # end
            end
          end

          div :id => "k-slider" do
            @col_renderers.each do |renderer|
              rawtext renderer.to_html
            end
          end
        end
      end

      div id: "new-exp-modal", class: "modal fade" do
        div class: "modal-dialog" do
          div class: "modal-content" do

            div class: "modal-header" do
              button :type => "button", :class => "close", :"data-dismiss" => "modal", :"aria-hidden" => "true" do
                rawtext '&times;'
              end
              h3 "New experiment context", style: "font-size: 20px;"
            end

            div class: "modal-body" do
              form class: "form-horizontal", role: "form" do
                div class: "form-group" do
                  label "Project", class: "col-sm-3 control-label"
                  div class: "col-sm-9" do
                    select id: "project", class: "form-control" do
                      if OMF::Web::SessionStore[:projects, :geni_portal]
                        OMF::Web::SessionStore[:projects, :geni_portal].each do |p|
                          option p[:name], value: p[:name]
                        end
                      end
                    end
                  end
                end

                div class: "form-group" do
                  label class: "col-sm-3 control-label" do
                    text "Name"
                  end
                  div class: "col-sm-9" do
                    input id: "exp-name", type: "text", class: "form-control"
                    input id: "irods-user-name", type: "hidden", value: OMF::Web::SessionStore[:id, :user]
                  end
                end
              end
            end

            div class: "modal-footer" do
              a "Close", :href => "#", :class => "btn btn-default", :"data-dismiss" => "modal"
              a "Save", :href => "#", :id => "save-exp", :class => "btn btn-primary", :"data-dismiss" => "modal"
            end
          end
        end
      end
    end

  end # class Page
end # OMF::Web::Theme
