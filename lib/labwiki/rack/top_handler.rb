
require 'labwiki/rack/abstract_handler'
require 'labwiki/labwiki_widget'

module LabWiki     
  class TopHandler < AbstractHandler
    

    # def call(env)
      # begin 
        # req = ::Rack::Request.new(env)      
        # body, headers = render_page(req)
        # if headers.kind_of? String
          # headers = {"Content-Type" => headers}
        # end
        # [200, headers, [body]] # required for ruby > 1.9.2 
      # rescue OMF::Web::Rack::RedirectException => rex
        # return [301, {'Location' => rex.redirect_url, "Content-Type" => ""}, ['Try again!']]
      # rescue 
      # end
    # end
    
    def on_request(req)
      opts = @opts.dup
      opts[:prefix] = req.script_name
      opts[:request] = req
      opts[:path] = req.path_info

      widget = get_lw_widget(req, false)
      OMF::Web::Theme.require 'page'
      page = OMF::Web::Theme::Page.new(widget, opts)
      [page.to_html, 'text/html']
    end

  end # class
end # module
