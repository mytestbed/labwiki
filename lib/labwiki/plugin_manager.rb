require 'omf_common/lobject'


module LabWiki 
  module Plugin; end # Put all plugins under this module
      
  class PluginManager < OMF::Common::LObject
    @@plugins = {}

    def self.init
      info "INITIALIZING PLUGINS"
      require 'labwiki/plugins/experiment/init'
      require 'labwiki/plugins/source_edit/init'      
      require 'labwiki/plugins/plan_text/init'            
    end
    
    #
    # description:
    #  - widget
    #  - renderer
    #
    def self.register name, description
      info "Loading plugin '#{name}'"
      name = name.to_sym
      if @@plugins[name]
        warn "P{lugin '#{name}' is already registered. Overiding previous settings"
      end
      description[:name] = name
      @@plugins[name] = description
      (description[:widgets] || {}).each do |wdescr|
        # :context => :execute,
        # :priority => lambda(),
        # :widget_class => Class
        wdescr[:config_name] ||= name
        ctxt = (@@plugins[wdescr[:context]] ||= [])
        ctxt << wdescr
      end
        
      # Register provided renderers
      (description[:renderers] || {}).each do |renderer_name, renderer_class|
        OMF::Web::Theme.register_renderer renderer_name, renderer_class, 'labwiki/theme'
      end 
    end
    
    def self.create_widget(column, params)
      debug "Creating widget for '#{column}' from '#{params.inspect}'"
      widget = @@plugins[column.to_sym].reduce(:priority => 0, :wdescr => {}) do |best, wdescr|
        if priority = wdescr[:priority].call(params)
          if priority > best[:priority]
            best = {:priority => priority, :wdescr => wdescr}
          end
        end
        best
        #mime_type.match(wdescr[:mime_type]) != nil
      end
      unless widget_class = widget[:wdescr][:widget_class]
        raise "No execute widget available for '#{params.inspect}'"
      end
      options = Configurator["plugins/#{widget[:wdescr][:config_name]}"]
      debug "Creating widget for '#{column}' from '#{widget_class}' (#{options})"      
      widget = widget_class.new(column, options, params)
      widget
    end
    
    def self.resource_directory_for(plugin_name)
      @@plugins[plugin_name.to_sym][:resources]
    end
    
  end # class
end # module

