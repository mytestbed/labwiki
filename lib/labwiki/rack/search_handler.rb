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
      col = req.params['col']
      opts[:repo_iterator] = OMF::Web::SessionStore[col.to_sym, :repos]
      unless (pat = req.params['pat'])
        raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'pat'"
      end

      #puts "Plugins>> #{PluginManager.plugins_for_column(col)}"
      res = PluginManager.plugins_for_column(col).map do |plugin|
        next unless sproc = plugin[:search]
        name = plugin[:name]
        cl = (sproc.call(pat, opts) || [])
        #puts "CL: >> #{cl}"
        cl.map do |f|
          f[:plugin] = name
          url = f.delete(:url)
          f[:label] ||= url
          f[:content] = Base64.encode64("#{f[:mime_type]}::#{url}").gsub("\n", '')
          f
        end
      end.flatten.compact
      # if col == 'execute' && OMF::Web::SessionStore[:exps, :omf]
        # res = []
        # OMF::Web::SessionStore[:exps, :omf].find_all do |v|
          # v[:id] =~ /#{pat}/
        # end.each { |v| res << { label: "task:#{v[:id]}", omf_exp_id: v[:id] } }
      # else
        # fs = OMF::Web::ContentRepository.find_files(pat, opts)
        # res = fs.collect do |f|
          # f[:label] = url = f.delete(:url)
          # f[:content] = Base64.encode64("#{f[:mime_type]}::#{url}").gsub("\n", '')
          # f
        # end
      # end
      [res.to_json, 'application/json']
    end

  end # class
end # module
