
require 'omf_common/lobject'
require 'omf-web/rack/rack_exceptions'
require 'omf-web/content/content_proxy'

module LabWiki
      
  # Handle the request to send a new column
  #
  class ColumnHandler < OMF::Common::LObject
    
    def call(env)
      req = ::Rack::Request.new(env)
      begin
        unless main_w = LabWiki::LWWidget[req]
          raise MissingArgumentException.new "Can't find session widget"
        end
        unless col = req.params['col']
          raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'col'"
        end
        unless col_w = main_w.get_column_widget(col)
          raise OMF::Web::Rack::MissingArgumentException.new "Can't find column widget for '#{col}"
        end
        method = "on_#{req.request_method().downcase}"
        body, headers = col_w.send(method.to_sym, req)
      rescue OMF::Web::Rack::MissingArgumentException => mex
        debug mex
        return [412, {"Content-Type" => 'text'}, [mex.to_s]]
      rescue Exception => ex
        error ex
        debug ex.to_s + "\n\t" + ex.backtrace.join("\n\t")
        return [500, {"Content-Type" => 'text'}, [ex.to_s]]
      end
      
      if headers.kind_of? String
        headers = {"Content-Type" => headers}
      end
      [200, headers, [body]] 
    end
  end # ContentHandler
  
end # OMF:Web


      
        
