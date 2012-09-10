
require 'rack/file'

module LabWiki
  
  # Rack::Resource serves resource files provided by the various plugins. 
  #
  # Each plugin is assumed to have a 'resource' directory under which the
  # requested resources are to be found. 
  #
  # Handlers can detect if bodies are a Rack::File, and use mechanisms
  # like sendfile on the +path+.
  #
  class PluginResourceHandler < ::Rack::File
    def initialize(cache_control = nil)
      super nil, cache_control
    end
    
    def _call(env)
      @path_info = ::Rack::Utils.unescape(env["PATH_INFO"])
      parts = @path_info.split SEPS
      #puts ">>> PARTS: #{parts}"

      return fail(403, "Forbidden")  if parts.include? ".."

      if (plugin_name = parts.shift).empty?
        plugin_name = parts.shift # the first element is empty, not sure if always
      end

      root = PluginManager.resource_directory_for(plugin_name)
      @path = F.join(root, *parts)
      #puts ">>>> CHECKING #{@path}"
      available = begin
        F.file?(@path) && F.readable?(@path)
      rescue SystemCallError
        false
      end

      if available
        return serving(env)
      end
      fail(404, "File not found: #{@path_info}")
    end # _call
    
  end # class
end # module



