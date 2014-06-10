
require 'omf-web/content/repository'

module LabWiki

  # Holds the local configuration information.
  #
  class Configurator < OMF::Base::LObject
    @@configuration = nil
    @@session_start_monitors = []
    @@session_close_monitors = []
    @@cfg_dir = nil # Directory main configuration file is located

    # Load a YAML config file from 'fname' and make it available
    # through self[key].
    #
    # fname - name of YAML file to load from
    #
    def self.load_from(fname)
      info "Loading config from '#{fname}'"
      @@configuration = OMF::Web.deep_symbolize_keys(YAML::load(File.open(fname)))
      OMF::Web::ContentRepository.reference_dir = @@cfg_dir = File.dirname(fname)

      # Include other config files if required
      if pattern = LabWiki::Configurator[:include]
        Dir.glob(File.join(@@cfg_dir, pattern)).each do |f|
          f = File.expand_path(f)
          debug "Loading additional config from #{f}"
          cfg = OMF::Web.deep_symbolize_keys(YAML::load(File.open(f)))

          merger = proc do |key, v1, v2|
            if Hash === v1 && Hash === v2
              v1.merge(v2, &merger)
            elsif Array === v1 && Array === v2
              v1.concat(v2)
            else
              v2
            end
          end
          #@@configuration = @@configuration.merge(cfg, &merger)
          @@configuration.merge!(cfg, &merger)
        end
      end
      debug "Config: '#{@@configuration.inspect}'"
    end

    def self.configured?()
      @@configuration != nil
    end

    # Called once at startup
    #
    def self.init()
      _init_session_configuration
      LabWiki::PluginManager.init
    end

    # Called for every new session
    #
    def self.start_session(user_info)
      #puts "NEW SESSION>>> #{user_info}"


      @@session_start_monitors.each do |block|
        block.call(user_info)
      end

      (self['session/repositories'] || []).each do |ropts|
        opts = ropts.dup

        unless name = opts.delete(:name)
          raise "Missing 'name' declaration in config file's 'session/repositories' - #{opts}"
        end
        repo = OMF::Web::ContentRepository.create(name.to_sym, opts)
        (OMF::Web::SessionStore[:plan, :repos] ||= []) << repo
        (OMF::Web::SessionStore[:prepare, :repos] ||= []) << repo
        (OMF::Web::SessionStore[:execute, :repos] ||= []) << repo
      end
    end

    def self.close_session(user_info = nil)
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

    # Read the content of a file referenced as value to 'key_path'.
    # Returns nil if key_path is not defined, otherwise it throws
    # exception if file name is given, but file can't be read.
    #
    def self.read_file(key_path)
      unless fn = self[key_path]
        return nil
      end
      unless fn.start_with? '/'
        fn = File.join(@@cfg_dir, fn)
      end
      path = File.expand_path(fn)
      unless File.readable? path
        raise "Can't read file '#{path}"
      end
      File.read(path)
    end

  end
end

