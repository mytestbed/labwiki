require 'base64'
require 'json'
require 'labwiki/rack/abstract_handler'
require 'labwiki/labwiki_widget'
require 'omf-web/content/repository'
require 'labwiki/plugins/experiment/redis_helper'

module LabWiki
  class SearchHandler < AbstractHandler
    include LabWiki::Plugin::Experiment::RedisHelper

    def on_request(req)
      debug "Search params: #{req.params.inspect}"

      opts = {:max => 10}
      if (col = req.params['col']) == 'plan'
        opts[:mime_type] = 'text/markup'
      end
      opts[:repo_iterator] = OMF::Web::SessionStore[col.to_sym, :repos]
      unless (pat = req.params['pat'])
        raise OMF::Web::Rack::MissingArgumentException.new "Missing parameter 'pat'"
      end
      if col == 'execute'# && OMF::Web::SessionStore[:exps, :omf]
        debug "SEARCHING>>>>>>>>>>>>>>>>> old exps #{pat} #{ns(:experiments, OMF::Web::SessionStore[:id, :user])} "
        res = []
        #OMF::Web::SessionStore[:exps, :omf].find_all do |v|
        cursor = 0
        loop do
          cursor, keys = redis.sscan(ns(:experiments, OMF::Web::SessionStore[:id, :user] || 'unknown'), cursor, match: "*#{pat}*")
          keys.each { |v|  res << { label: "task:#{v}", omf_exp_id: v, mime_type: 'exp/task' } }
          break if cursor == "0" || res.size > opts[:max]
        end
      else
        fs = OMF::Web::ContentRepository.find_files(pat, opts)
        res = fs.collect do |f|
          f[:label] = url = f.delete(:url)
          f[:content] = Base64.encode64("#{f[:mime_type]}::#{url}").gsub("\n", '')
          f
        end
      end

      [res.to_json, 'application/json']
    end

  end # class
end # module
