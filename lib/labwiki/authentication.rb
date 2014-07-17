require 'warden'
require 'erector'
require 'labwiki/rack/login_handler'

TRUST_REFERRER = "portal.geni.net"

module LabWiki
  class Authentication < OMF::Base::LObject
    @@types = {}

    attr_reader :type, :users

    def self.register_type(type_name)
      @@types[type_name.to_s] = self
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

    def self.login_content
      @@instance.login_content
    end

    def self.configure_warden(manager)
      @@instance.configure_warden(manager)
    end

    def self.openid?
      @@instance.type == 'openid'
    end

    def self.none?
      @@instance.type == 'none'
    end

    def initialize(opts)
      @type = opts.delete(:type)

      Warden::Manager.after_set_user do |user, auth, opts|
        parse_user(user) unless OMF::Web::SessionStore[:initialised, :session]
      end
    end

    def configure_warden(manager)
      manager.failure_app = LabWiki::LoginHandler.new
    end

    # Parse warden user information into omf web session store
    def parse_user(user)
    end

    # To display in login page
    def login_content
    end
  end
end
