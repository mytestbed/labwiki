require 'omf-web/content/irods_repository'


# These should go to a separate controller/handler file.
map "/plugin/source_edit/create_script" do
  handler = lambda do |env|
    req = ::Rack::Request.new(env)
    file_ext = req.params['file_ext'].downcase
    file_name = "#{req.params['file_name']}.#{file_ext}"
    sub_folder = case file_ext
                 when 'oedl'
                   'oedl'
                 when 'md'
                   'wiki'
                 end
    repo = (LabWiki::Configurator[:repositories] || {}).first
    if repo.class == Array
      repo = OMF::Web::ContentRepository.find_repo_for("#{repo[1][:type]}:#{repo[0]}")
    end
    repo ||= (OMF::Web::SessionStore[:prepare, :repos] || []).first

    begin
      path = "#{sub_folder}/#{file_name}"
      repo.write(repo.get_url_for_path(path), "", "Adding new script #{file_name}")
    rescue => e
      e_msg = "Failed to create #{file_name}. #{e.message}"
      OMF::Base::Loggable.logger('repository').error e_msg
      return [500, {}, e_msg]
    end
    [200, {}, "#{file_name} created"]
  end
  run handler
end

