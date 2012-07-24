require 'base64'
require 'json'
require 'labwiki/rack/abstract_handler'
require 'labwiki/labwiki_widget'
require 'omf-web/content/repository'

module LabWiki     
  class SearchHandler < AbstractHandler
        
    def on_request(req)
      debug "Search params: #{req.params.inspect}"

      opts = {:max => 10}
      if (req.params['col'] == 'plan') 
        opts[:mime_type] = 'text/markup'
      end
      fs = OMF::Web::ContentRepository.find_files(req.params['term'], opts)
      res = fs.collect do |f|
        path = f.delete(:path)
        f[:content] = Base64.encode64("#{f[:mime_type]}::#{path}").gsub("\n", '')
        {:label => path, :value => f}
      end
      [res.to_json, 'application/json']
    end

  end # class
end # module
