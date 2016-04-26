require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/theme'
require 'omf_oml/table'

module LabWiki
  module Plugin; end # Put all plugins under this module

  class PluginManager < OMF::Base::LObject
    @@plugins = {}
    @@widgets_for_col = { plan: [], prepare: [], execute: []}

    def self.init
      info "Initializing Plugins"
      require 'labwiki/plugin/source_edit/init'
      require 'labwiki/plugin/plan_text/init'

      (LabWiki::Configurator[:plugins] || []).each do |name, opts|
        debug "Initialize plugin '#{name}' - #{opts}"
        next if @@plugins[name] # must be a built-in one

        if plugin_dir = opts.delete(:plugin_dir)
          unless plugin_dir.start_with? '/'
            plugin_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../plugins', plugin_dir))
          end
          lib_dir = File.join(plugin_dir, 'lib')
          unless File.readable? lib_dir
            error "Can't find lib directory '#{lib_dir}' for plugin '#{name}'"
            next
          end
          $: << lib_dir
          require "labwiki/plugin/#{name}/init"
        else
          fatal "Missing 'plugin_dir' for plugin '#{name}'"
          exit(-1)
        end
      end

    end

    def self.extend_config_ru(binding)
      #puts "POST>>>> #{binding}"
      @@plugins.each do |name, opts|
        if config_ru = opts[:config_ru]
          if File.readable? config_ru
            eval(IO.read(config_ru), binding)
          else
            error "Can't read '#{config_ru}' for plugin '#{name}'"
          end
        end
      end
    end

    #
    # description:
    #  - widget
    #  - renderer
    #
    def self.register name, description
      info "Loading plugin '#{name}' - V#{description[:version] || '??'}"
      name = name.to_sym
      if @@plugins[name]
        warn "Plugin '#{name}' is already registered. Overiding previous settings"
      end
      description[:name] = name
      @@plugins[name] = description
      (description[:widgets] || {}).each do |wdescr|
        # :context => :execute,
        # :priority => lambda(),
        # :widget_class => Class
        unless wdescr[:name]
          warn "Missing widget name, default to 'name' -- #{wdescr}"
          wdescr[:name] = name
        end
        wdescr[:config_name] ||= wdescr[:name] || name
        wdescr[:plugin_name] = name
        if ctxt = @@widgets_for_col[wdescr[:context]]
          ctxt << wdescr
        else
          warn "Ignoring widget '#{name} for unknown context '#{wdescr[:context]}'"
        end
      end

      # Register provided renderers
      (description[:renderers] || {}).each do |renderer_name, renderer_class|
        OMF::Web::Theme.register_renderer renderer_name, renderer_class, 'labwiki/theme'
      end
    end

    # Return an array containing all the javascript
    # init files the plugins have registers to be loaded
    # into the global context
    #
    def self.get_global_js
      @@plugins.map do |name, opts|
        if gjs = opts[:global_js]
          "plugin/#{name}/#{gjs.split('.')[0]}"
        end
      end.compact
    end

    def self.create_widget(column, params)
      debug "Attempting to creating widget for column '#{column}' from '#{params}'"

      # It can specify :widget or let it search based on mime_type
      if wname = params[:widget]
        wdescr = widgets_for_column(column).find do |wd|
          #debug "creating widget '#{wname}' - #{wd[:name] == wname} - #{wd}"
          wd[:name] == wname
        end
      else
        widget = @@widgets_for_col[column.to_sym].reduce(:priority => 0, :wdescr => {}) do |best, wdescr|
          if wdescr[:priority] && priority = wdescr[:priority].call(params)
            if priority > best[:priority]
              best = {:priority => priority, :wdescr => wdescr}
            end
          end
          best
          #mime_type.match(wdescr[:mime_type]) != nil
        end
        wdescr = widget[:wdescr]
      end
      unless wdescr
        raise "Can't find plugin for '#{column}' from '#{params}'"
      end
      unless widget_class = wdescr[:widget_class]
        raise "No execute widget available for '#{params.inspect}'"
      end
      options = Configurator["plugins/#{wdescr[:config_name]}"]
      debug "Creating widget for '#{column}' from '#{widget_class}' (#{options})"
      widget = widget_class.new(column, options, params)
      widget
    end

    def self.widgets_for_column(column)
      @@widgets_for_col[column.to_sym]
    end

    def self.resource_directory_for(plugin_name)
      unless p = @@plugins[plugin_name.to_sym]
        warn "Requesting resource directory for unknown plugin '#{plugin_name}'"
        return nil
      end
      unless rd = p[:resources]
        warn "No resource directory defined for plugin '#{plugin_name}'"
        return nil
      end
      rd
    end

    def self.init_session()
      @@plugins.each do |name, plugin_descr|
        if block = plugin_descr[:on_session_init]
          _safe_call(block)
        end
      end

      unless OMF::Web::SessionStore[:content_choices, :plugin_mgr]
        n = "content_choices_#{OMF::Web::SessionStore.session_id}"
        t = OMF::OML::OmlTable.new n, [:name, :description]
        OMF::Web::DataSourceProxy.register_datasource t
        OMF::Web::SessionStore[:content_choices, :plugin_mgr] = t
        OMF::Web::SessionStore[:content_choices_ds_name, :plugin_mgr] = n
      end
    end

    # Return OML table to be used to pus content choices to browser
    #
    # Schema: [:name, :description]
    #
    def self.content_choice_table
      OMF::Web::SessionStore[:content_choices, :plugin_mgr]
    end

    # FIXME should have arguments? or not?
    def self.close_session(user_info = nil)
      @@plugins.each do |name, plugin_descr|
        if block = plugin_descr[:on_session_close]
          _safe_call(block)
        end
      end
    end

    # Called when session got authorised
    # Note: Authorisation tokens are stored in session store
    #
    def self.authorised()
      @@plugins.each do |name, plugin_descr|
        #puts ">>>>> #{plugin_descr.keys}"
        if block = plugin_descr[:on_authorised]
          _safe_call(block)
        end
      end
    end

    def self._safe_call(block)
      begin
        block.call
      rescue => ex
        error ex
        debug "#{ex}\n\t#{ex.backtrace.join("\n\t")}"
      end
    end



  end # class
end # module

