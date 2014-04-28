

module LabWiki

  # Holds the local configuration information.
  #
  class Configurator < OMF::Base::LObject
    @@configuration = nil
    @@session_start_monitors = []
    @@session_close_monitors = []

    # Load a YAML config file from 'fname' and make it available
    # through self[key].
    #
    # fname - name of YAML file to load from
    #
    def self.load_from(fname)
      info "Loading config from '#{fname}'"
      @@configuration = OMF::Web.deep_symbolize_keys(YAML::load(File.open(fname)))
      debug "Config: '#{@@configuration.inspect}'"
    end

    def self.configured?()
      @@configuration != nil
    end

    # Process the configuration parameter for settings specific to the OMF::Web
    # library. Current settings include: repository.
    #
    # def self.init_omf_web
      # #require 'omf-web/content/git_repository'
      # (self[:repositories] || []).each do |name, opts|
        # info "Registering repo '#{name}' -> #{opts}"
        # #File.expand_path(path), true
        # OMF::Web::ContentRepository.register_repo(name, opts)
      # end
      # (self[:plugins] || []).each do |name, opts|
        # if init = opts[:init]
          # info "Initialising plugin '#{name}'"
          # require init
        # end
      # end
    # end

    # Called once at startup
    #
    def self.init()
      _init_session_configuration
      LabWiki::PluginManager.init
    end

    # Called for every new session
    #
    def self.start_session(user_info)
      puts "NEW SESSION>>> #{user_info}"
      @@session_start_monitors.each do |block|
        block.call(user_info)
      end
    end

    def self.close_session(user_info)
      @@session_close_monitors.each do |block|
        block.call()
      end
    end

    def self.on_session_start(&block)
      @@session_start_monitors << block
    end

    def self.on_session_close(&block)
      @@session_close_monitors << block
    end

    def self._init_session_configuration
      si = self[:session]
      return unless si

      if (req = si[:require])
        begin
          require(req)
        rescue Exception => ex
          error "Loading session require '#{req}' - #{ex}"
          abort
        end
      end
    end

    def self.on_user_login(user)

    end

    # Return configuration value for 'key'. Key can be of the form 'a/b/c' which
    # returns config[:a][:b][:c].
    #
    # key - name or path to config option
    #
    def self.[](key_path)
      kp = "labwiki/#{key_path}"
      v = kp.split('/').reduce(@@configuration) do | config, key |
        break nil unless config.is_a?(Hash)
        config[key.to_sym];
      end
      #debug "Configuration for '#{key_path}' is '#{v}'"
      v
    end
  end
end

