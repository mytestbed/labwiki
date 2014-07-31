module OMF::Web::Theme
  class Login < OMF::Web::Theme::AbstractPage

    depends_on :css, "/resource/vendor/bootstrap/css/bootstrap.css"
    depends_on :css, "/resource/vendor/font-awesome/css/font-awesome.min.css"
    depends_on :js, "/resource/vendor/bootstrap/js/bootstrap.js"
    depends_on :css, "/resource/theme/labwiki/css/login.css"

    def initialize(widget, opts)
      super
      @page_title = "Login : LabWiki"
    end

    def content
      navbar

      about

      div :class => "container" do
        div :class => "row" do
          div :class => "col-lg-8 col-lg-offset-2 content" do
            div :class => "login_content" do
              rawtext LabWiki::Authentication.login_content
            end
            logos
          end
        end

        div :class => "row" do
          div :class => "col-lg-8 col-lg-offset-2 footer" do
            p "Copyright #{Time.now.year} NICTA."

            p "Version: #{LabWiki.version}"
          end
        end
      end
    end

    def navbar
      div :class => "navbar navbar-inverse", :role => "navigation" do
        div :class => "container-fluid" do
          div :class => "navbar-header" do
            a(href: "#", :class => "navbar-brand") do
              text "LabWiki"
            end
          end

          div :class => "pull-right" do
            ul :class => "nav navbar-nav navbar-right" do
              li do
                a href: "#aboutModal", "data-toggle" => "modal" do
                  text "About"
                end
              end
            end
          end
        end
      end
    end

    def about
      div :id => "aboutModal", :class => "modal fade", :tabindex => "-1", :role => "dialog", "aria-labelledby" => "myModalLabel", "aria-hidden" => "true" do
        div :class => "modal-dialog" do
          div :class => "modal-content" do
            div :class => "modal-header" do
              button :type => "btn", :class => "close", "data-dismiss" => "modal", "aria-hidden" => "true" do
                text "x"
              end
              h3 'About'
            end
            div :class => "modal-body" do
              p do
                text "Labwiki is a web-based workspace for experimenters. It strives to support the entire investigative life-cycle from planning to preparation to execution to analysis."
              end

              p do
                text "It is still under active development and more details can (should) be found on LabWiki's"
                a :href => "http://labwiki.mytestbed.net"do
                  text "web site"
                end
              end
            end
            div :class => "modal-footer" do
              button :class => "btn btn-default", "data-dismiss" => "modal", "aria-hidden" => "true" do
                text "Close"
              end
            end
          end
        end
      end
    end

    def logos
      hr
      div :class => "col-lg-3 logo" do
        a :href => "http://www.nicta.com.au", :target => "blank" do
          img :src => "/resource/login/img/Logo-Nicta-S.jpg", :alt => "NICTA"
        end
      end
      div :class => "col-lg-3 logo" do
        a :href => "http://gimi.ecs.umass.edu", :target => "blank" do
          img :src => "/resource/login/img/logo-gimi.png", :alt => "GIMI"
        end
      end
      div :class => "col-lg-3 logo" do
        a :href => "http://www.fed4fire.eu", :target => "blank" do
          img :src => "/resource/login/img/fed4fire-logo_small.jpg", :alt => "Fed4Fire"
        end
      end
      div :class => "col-lg-3 logo" do
        a :href => "http://www.ict-openlab.eu", :target => "blank" do
          img :src => "/resource/login/img/openlab_logo_square_small.png", :alt => "Openlab"
        end
      end
    end
  end

end
