
require 'labwiki/rack/abstract_handler'
require 'omf-web/rack/rack_exceptions'
require 'omf-web/content/content_proxy'

module LabWiki

  # Handle the request to send a new column
  #
  class ColumnHandler < AbstractHandler

    def on_request(req)
      unless body = req.body #req.POST
        return [400, {"Content-Type" => 'text/json'}, 'Missing body']
      end
      if body.is_a? Hash
        params = req.params
      else
        (body = body.string) if body.is_a? StringIO
        unless req.content_type == 'application/json'
          warn "Received request with unknown content type '#{req.content_type}'"
          return [400, {"Content-Type" => 'text/json'}, 'Unknown content type']
        end
        params = JSON.parse(body)
        puts "BODY>>>> #{params.inspect} --- #{body}"
      end
      puts "REQREST PARAMS> #{params}"

      unless col = params['col']
        raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'col'"
      end

      unless action = params['action']
        raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'action'"
      end

      main_w = get_lw_widget(req)
      main_w.dispatch_to_column(col.to_sym, action.to_sym, OMF::Web.deep_symbolize_keys(params), req)
    end
  end # ContentHandler

end # OMF:Web




