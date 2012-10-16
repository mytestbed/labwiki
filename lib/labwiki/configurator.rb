

module LabWiki    
  
  # Holds the local configuration information.
  #
  class Configurator < OMF::Common::LObject
    
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
      debug "Configuration for '#{key_path}' is '#{v}'"
      v
    end
  end
end

