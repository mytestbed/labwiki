require 'omf_common/lobject'
require 'labwiki/labwiki_widget'

module LabWiki     
  class LWRack < OMF::Common::LObject
    

    def initialize(opts = {})
      @opts = opts
    end
    
    def call(env)
      req = ::Rack::Request.new(env)
      sessionID = req.params['sid']
      if sessionID.nil? || sessionID.empty?
        sessionID = "s#{(rand * 10000000).to_i}"
        # Ensure we have a proper sid on the browser
        return [301, {'Location' => "/labwiki?sid=#{sessionID}", "Content-Type" => ""}, ['Try again!']]
      end
      Thread.current["sessionID"] = sessionID
      
      body, headers = render_page(req)
      if headers.kind_of? String
        headers = {"Content-Type" => headers}
      end
      [200, headers, [body]] # required for ruby > 1.9.2 
    end
    
    def render_page(req)
      opts = @opts.dup
      opts[:prefix] = req.script_name
      opts[:request] = req
      opts[:path] = req.path_info

      widget = LabWiki::LWWidget[req]
      OMF::Web::Theme.require 'page'
      page = OMF::Web::Theme::Page.new(widget, opts)
      [page.to_html, 'text/html']
    end

  end # class
end # module
