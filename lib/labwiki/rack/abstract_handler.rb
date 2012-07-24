require 'omf_common/lobject'

module LabWiki  
  
  # Implements functionality common across all rack handler
  #   
  class AbstractHandler < OMF::Common::LObject
   
    def initialize(opts = {})
      @opts = opts
    end
    
    def call(env)
      begin 
        req = ::Rack::Request.new(env)      
        body, headers = on_request(req)
        if headers.kind_of? String
          headers = {"Content-Type" => headers}
        end
        [200, headers, [body]] # required for ruby > 1.9.2 
      rescue OMF::Web::Rack::RedirectException => rex
        return [301, {'Location' => rex.redirect_url, "Content-Type" => ""}, ['Try again!']]
      rescue OMF::Web::Rack::MissingArgumentException => mex
        warn mex
        return [412, {"Content-Type" => 'text'}, [mex.to_s]]
      rescue Exception => ex
        error ex
        debug ex.to_s + "\n\t" + ex.backtrace.join("\n\t")
        return [500, {"Content-Type" => 'text'}, [ex.to_s]]
      end
    end
    
    
    def get_lw_widget(req, requires_session_id = true)
      sessionID = req.params['sid']
      if sessionID.nil? || sessionID.empty?
        if requires_session_id
          raise OMF::Web::Rack::MissingArgumentException.new "Missing session id"
        end

        sessionID = "s#{(rand * 10000000).to_i}"
        # Ensure we have a proper sid on the browser
        raise OMF::Web::Rack::RedirectException.new "/labwiki?sid=#{sessionID}"
        #return [301, {'Location' => "/labwiki?sid=#{sessionID}", "Content-Type" => ""}, ['Try again!']]
      end
      Thread.current["sessionID"] = sessionID
      
      unless widget = OMF::Web::SessionStore[:lw_widget, :rack]
        widget = OMF::Web::SessionStore[:lw_widget, :rack] = LabWiki::LWWidget.new
      end
      return widget
    end
  end # class
end # module