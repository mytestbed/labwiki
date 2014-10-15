require 'omf_base/lobject'

module LabWiki

  # Implements functionality common across all rack handler
  #
  class AbstractHandler < OMF::Base::LObject

    def initialize(opts = {})
      @opts = opts
    end

    def call(env)
      begin
        req = ::Rack::Request.new(env)
        res = on_request(req)
        if res.length == 3 # proper reply?
          return res
        end
        body, headers = res
        if headers.kind_of? String
          headers = {"Content-Type" => headers}
        end
        [200, headers, [body]] # required for ruby > 1.9.2
      rescue OMF::Web::Rack::RedirectException => rex
        return [307, {'Location' => rex.redirect_url, "Content-Type" => ""}, ['Try again!']]
      rescue OMF::Web::Rack::UnknownResourceException => rex
        warn rex
        return rex.reply
      rescue OMF::Web::Rack::MissingArgumentException => mex
        warn mex
        return mex.reply
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
