

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

    depends_on :js, "/resource/vendor/bootstrap/js/bootstrap.js"
    depends_on :js, '/resource/vendor/jquery-ui/js/jquery-ui.js'
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

            ul class: 'nav navbar-nav navbar-right' do
              li do
                a id: 'tools-menu-a', class: 'nav-menu', href: "#" do
                  i :class => "glyphicon glyphicon-cog icon-white"
                  text 'Tools'
                end
                ul id: 'tools-menu-ul', class: "dropdown-menu" do
                  li 'GIMI', class: "dropdown-header"
                  if (authorisation_info = LabWiki::Configurator[:session][:authorisation])
                    authorisation_info[:certificate] = LabWiki::Configurator.read_file('session/authorisation/cert_file')
                    li do
                      form method: "post", action: authorisation_info[:url], id: "authorise" do
                        input name: "tool_id", value: "Labwiki", type: "hidden"
                        input name: "backto", value: authorisation_info[:callback_url], type: "hidden"
                        input name: "tool_cert", value: authorisation_info[:certificate], type: "hidden"
                      end
                      a "Authorise", href: "#", onclick: "$('form#authorise').submit();"
                    end
                  end
                end
              end

              li class: 'last-nav-link' do
                a id: 'user-menu-a', class: 'nav-menu', href: "#" do
                  i :class => "glyphicon glyphicon-user icon-white"
                  text OMF::Web::SessionStore[:name, :user] || 'Unknown'
                end
                ul id: 'user-menu-ul', class: 'nav-menu', class: "dropdown-menu" do
                  li do
                    a id: 'user-menu-logout-a', class: 'nav-menu-item', href: "/logout" do
                      i :class => "glyphicon glyphicon-off icon-white"
                      text "Logout"
                    end
                  end
                end
              end
            end
          end

          div :id => "k-slider" do
            @col_renderers.each do |renderer|
              rawtext renderer.to_html
            end
          end
        end
      end

      full_screen_modal
    end

    def full_screen_modal
      div class: "modal fade", id: "fullscreen_modal", tabindex: "-1", role: "dialog", 'aria-labelledby' => "myModalLabel", 'aria-hidden' => "true" do
        div class: "modal-dialog" do
          div class: "modal-content" do
            div class: "modal-header" do
              button type: "button", class: "close", 'data-dismiss' => "modal" do
                span class: "glyphicon glyphicon-remove"
                span 'Close', class: "sr-only"
             end
             h2 "XXX", class: "modal-title"
            end
            div class: "modal-body" do
              text '....'
            end
            # div class: "modal-footer" do
              # button 'Close', type: "button", class: "btn btn-default", 'data-dismiss' => "modal"
              # button 'Save changes', type: "button", class: "btn btn-primary"
            # end
          end
        end
      end

    end

  end # class Page
end # OMF::Web::Theme
