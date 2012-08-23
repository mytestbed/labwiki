require 'omf_common/lobject'


module LabWiki     
  class Plugin < OMF::Common::LObject
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
      @@plugins[name] = description
      (description[:widgets] || {}).each do |wdescr|
        # :context => :execute,
        # :priority => lambda(),
        # :widget_class => Class
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
      widget = @@plugins[column.to_sym].reduce(:priority => 0, :klass => nil) do |best, wdescr|
        if priority = wdescr[:priority].call(params)
          if priority > best[:priority]
            best = {:priority => priority, :klass => wdescr[:widget_class]}
          end
        end
        best
        #mime_type.match(wdescr[:mime_type]) != nil
      end
      unless widget_class = widget[:klass]
        raise "No execute widget available for '#{params.inspect}'"
      end
      debug "Creating widget for '#{column}' from '#{widget_class}'"      
      widget = widget_class.new(column, params)
      widget
    end
    
    
    # def self.create_execute_widget(params)
      # mime_type = params[:mime_type]
      # wdescr = @@plugins[:execute].find do |wdescr|
        # mime_type.match(wdescr[:mime_type]) != nil
      # end
      # unless wdescr
        # throw "No execute widget available for '#{params[:mime_type]}'"
      # end
      # widget_class = wdescr[:widget_class]
      # widget = widget_class.create_for(params)
    # end
  end # class
end # module

