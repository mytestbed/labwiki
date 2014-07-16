require 'labwiki/rack/abstract_handler'

module LabWiki
  class LoginHandler < AbstractHandler
    def on_request(req)
      opts = @opts.dup
      opts[:prefix] = req.script_name
      opts[:request] = req
      opts[:path] = req.path_info

      OMF::Web::Theme.require 'login'
      page = OMF::Web::Theme::Login.new(nil, opts)
      [page.to_html, 'text/html']
    end
  end
end
