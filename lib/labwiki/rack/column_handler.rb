
require 'labwiki/rack/abstract_handler'
require 'omf-web/rack/rack_exceptions'
require 'omf-web/content/content_proxy'

module LabWiki
      
  # Handle the request to send a new column
  #
  class ColumnHandler < AbstractHandler
    
    def on_request(req)
      unless col = req.params['col']
        raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'col'"
      end
      
      unless action = req.params['action']
        raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'action'"
      end
      
      main_w = get_lw_widget(req)
      main_w.dispatch_to_column(col.to_sym, action.to_sym, OMF::Web.deep_symbolize_keys(req.params), req)

      # action = "on_#{action}".to_sym
      # unless col_w.respond_to? action
        # raise OMF::Web::Rack::MissingArgumentException.new "Unknown action '#{action}' for column '#{col}'"
      # end
#       
      # unless col_w = main_w.get_column_widget(col)
        # raise OMF::Web::Rack::MissingArgumentException.new "Can't find column widget for '#{col}"
      # end
#       
#       
      # debug "Calling '#{action} on '#{col_w.class}' widget"
      # col_w.send(action, OMF::Web.deep_symbolize_keys(req.params), req)
    end
  end # ContentHandler
  
end # OMF:Web


      
        
