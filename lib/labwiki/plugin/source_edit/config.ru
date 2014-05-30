require 'omf-web/content/irods_repository'


# These should go to a separate controller/handler file.
map "/plugin/source_edit/create_script" do
  handler = lambda do |env|
    req = ::Rack::Request.new(env)
    file_ext = req.params['file_ext'].downcase
    file_name = "#{req.params['file_name']}.#{file_ext}"

    sub_folder, mime_type = case file_ext
                            when 'oedl' then ['oedl', 'text/ruby']
                            when 'md' then ['wiki', 'text/markup']
                            end

    repo = (OMF::Web::SessionStore[:prepare, :repos] || []).first
    return [500, {}, "Could not find any available repo to write"] if repo.nil?

    begin
      path = "#{sub_folder}/#{file_name}"
      url = repo.get_url_for_path(path)
      repo.write(url, "", "Adding new script #{file_name}")
    rescue => e
      e_msg = "Failed to create #{file_name}. #{e.message}"
      OMF::Base::Loggable.logger('repository').error e_msg
      return [500, {}, e_msg]
    end
    [200, {'Content-Type' => 'application/json'}, { url: url, mime_type: mime_type }.to_json]
  end
  run handler
end

