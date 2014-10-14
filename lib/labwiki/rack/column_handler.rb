
require 'labwiki/rack/abstract_handler'
require 'omf-web/rack/rack_exceptions'
require 'omf-web/content/content_proxy'

module LabWiki

  # Handle the request to send a new column
  #
  class ColumnHandler < AbstractHandler

    def on_request(req)
      case req.request_method
      when 'POST'
        return on_post(req)
      when 'GET'
        return on_get(req)
      else
        return [400, {}, "Cannot handle '#{req.request_method}'"]
      end
    end

    def on_post(req)
      unless body = req.body #req.POST
        return [400, {"Content-Type" => 'text/json'}, 'Missing body']
      end
      if body.is_a? Hash
        params = req.params
      else
        (body = body.string) if body.is_a? StringIO
        unless req.content_type.start_with? 'application/json'
          warn "Received request with unknown content type '#{req.content_type}'"
          return [400, {"Content-Type" => 'text/json'}, 'Unknown content type']
        end
        #puts "BODY>>>> #{body}"
        params = JSON.parse(body)
      end
      #puts "REQUEST PARAMS> #{params}"
      process(req, params)
    end

    def on_get(req)
      params = {}
      req.params.each {|k, v| params[k.to_s] = v}
      #puts "ON_GET>>>> #{params.inspect}"
      process(req, req.params || {})
    end

    def process(req, params)
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




