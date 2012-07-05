require 'omf_common/lobject'
require 'labwiki/labwiki_widget'
require 'omf-web/content/repository'

module LabWiki     
  class SearchHandler < OMF::Common::LObject
        
    def call(env)
      req = ::Rack::Request.new(env)
      puts ">>>> #{req.params.inspect}"
      
      sessionID = req.params['sid']
      if sessionID.nil? || sessionID.empty?
        # should not happen under normal conditions
        raise 'missing sid'
        return [400, {}, []]
      end
      Thread.current["sessionID"] = sessionID

      body, headers = render_response(req)
      if headers.kind_of? String
        headers = {"Content-Type" => headers}
      end
      puts ">>> #{body}"
      [200, headers, [body]] # required for ruby > 1.9.2 
    end
    
    def render_response(req)
      fs = OMF::Web::ContentRepository[{}].find_files(req.params['term'])
      if req.params['col'] == 'plan'
        # only allow markup documents to be displayed in the first col
        fs = fs.select { |f| f[:mime_type] == 'text/markup' }
      end
      res = fs[0, 10].collect do |f|
        path = f.delete(:path)
        f[:content] = :id => Base64.encode64(long_name).gsub("\n", ''), 
        {:label => path, :value => f}
      end
      [res.to_json, 'application/json']
    end

  end # class
end # module
