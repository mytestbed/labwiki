require 'labwiki/authentication/warden_lw_persona'

module LabWiki
  class Authentication
    class Persona < Authentication
      register_type :persona

      def initialize(opts)
        super
      end

      def configure_warden(manager)
        super
      end

      def parse_user(user)
        OMF::Web::SessionStore[:id, :user] = user
        OMF::Web::SessionStore[:name, :user] = user.split("@").first
        OMF::Web::SessionStore[:data, :user] = user
      end

      def login_content
        Erector.inline do
          script src: "https://login.persona.org/include.js"
          p do
            2.times { br }
            img :src => "/resource/login/img/persona-logo-wordmark.png", :alt => "Login"
            3.times { br }
            a id: 'signin', :class => "btn btn-lg btn-default" do
              text "Login with your gmail address"
            end
          end

          javascript <<-JS
            // Copied from mozilla site
            var signinLink = document.getElementById('signin');
            if (signinLink) {
              signinLink.onclick = function() { navigator.id.request(); };
            }

            navigator.id.watch({
              onlogin: function(assertion) {
                $.ajax({
                  type: 'POST',
                  url: '/',
                  data: {assertion: assertion},
                  success: function(res, status, xhr) { window.location.reload(); },
                  error: function(xhr, status, err) { alert("Persona Login failure: " + err); }
                });
              }
            });
          JS
        end
      end
    end
  end
end
