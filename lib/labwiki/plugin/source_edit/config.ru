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
      # TODO: This should NOT be necessary as it should be INSIDE the IRodsContentRepository
      if repo.class == OMF::Web::IRodsContentRepository
        # iRods needs full path...
        path = "#{LabWiki::Configurator[:gimi][:irods][:home]}/#{OMF::Web::SessionStore[:id, :user]}/#{LabWiki::Configurator[:gimi][:irods][:script_folder]}/#{sub_folder}/#{file_name}"
      else
        path = "repo/#{sub_folder}/#{file_name}"
      end

      repo.write(path, "", "Adding new script #{file_name}")
    rescue => e
      if e.class == RuntimeError && e.message =~ /Cannot write to file/
        repo.write("#{sub_folder}/#{file_name}", "", "Adding new script #{file_name}")
      else
        puts ">>> Write new files error: #{e.message}"
      end
    end
    [200, {}, "#{file_name} created"]
  end
  run handler
end

