require 'warden'

#LOGIN_PAGE = LabWiki::Configurator["session/authentication/page"] || "/resource/login/google_openid.html"
LOGIN_PAGE = "/resource/login/google_openid.html"

TRUST_REFERRER = "portal.geni.net"

module LabWiki
  class Authentication < OMF::Base::LObject
    @@types = {}

    attr_reader :type

    def self.register_type(type_name)
      @@types[type_name.to_s] = self
      puts @@types
    end

    def self.setup(opts)
      # No authentication :none as default
      opts ||= { type: "none" }
      require "labwiki/authentication/#{opts[:type]}"
      @@instance ||= @@types[opts[:type]].new(opts)
    end

    def self.type
      @@instance.type.to_sym
    end

    # TODO use define_method
    def self.openid?
      @@instance.type == 'openid'
    end

    def self.none?
      @@instance.type == 'none'
    end

    def initialize(opts)
      @type = opts.delete(:type)
      @users = {}

      Warden::Manager.after_set_user do |user, auth, opts|
        parse_user(user)
      end
    end

    def parse_user(user)
    end

    module Failure
      def self.call(env)
        #[401, {'Location' => '/labwiki', "Content-Type" => ""}, [
        #  "<p>Authentication failed. #{env['warden'].message}<p>
        # <a href='/labwiki/logout'>Try again</a>
        #  "
        #]]
        [302, {'Location' => "/resource/login/google_openid.html", "Content-Type" => ""}, ['Redirect to login']]
      end
    end
  end
end
