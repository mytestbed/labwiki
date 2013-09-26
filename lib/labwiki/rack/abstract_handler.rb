require 'omf_base/lobject'

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
        return [307, {'Location' => rex.redirect_url, "Content-Type" => ""}, ['Try again!']]
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
      unless widget = OMF::Web::SessionStore[:lw_widget, :rack]
        widget = OMF::Web::SessionStore[:lw_widget, :rack] = LabWiki::LWWidget.new
      end
      return widget
    end
  end # class
end # module
