require 'omf-web/session_store'
require 'labwiki/plugin_manager'
require 'labwiki/core_ext/object'

# Class handling all the GIMI specific 'stuff'. Should most likely
# migrate into a separate plugin
#
class LabWiki::Gimi < OMF::Base::LObject
  include Singleton

  # Register with Configurator
  #
  LabWiki::Configurator.on_session_start do |user_info|
    self.instance.on_session_start(user_info)
  end

  LabWiki::Configurator.on_session_close do |user_info|
    self.instance.on_session_close
  end


  def initialize()
    @opts = LabWiki::Configurator['session/gimi']
    debug "GIMI options: #{@opts}"
  end

  def on_session_start(user_info)
    return unless @opts
  end

  def on_session_close
    #TODO What to do?
  end

  def update_geni_projects_slices(user)
    if (geni_projects = user['http://geni.net/projects']) &&
       (geni_slices = user['http://geni.net/slices'])
      projects = geni_projects.map do |p|
        uuid, name = *(p.split('|'))
        { uuid: uuid, name: name, slices: []}
      end

      geni_slices.each do |s|
        uuid, project_uuid, name = *s.split('|')
        if (p = projects.find { |v| v[:uuid] == project_uuid })
          p[:slices] << { uuid: uuid, name: name }
        end
      end
      OMF::Web::SessionStore[:projects, :geni_portal] = projects
    else
      OMF::Web::SessionStore[:projects, :geni_portal] = []
    end

    # We can create a default experiment for each project
    if @opts[:ges]
      OMF::Web::SessionStore[:projects, :geni_portal].each do |p|
        proj = find_or_create("projects", p[:name], { irods_user: OMF::Web::SessionStore[:id, :irods_user] })
      end
    end
  end

  def find_or_create(res_path, res_id, additional_data = {})
    ges_url = @opts[:ges]
    obj = HTTParty.get("#{ges_url}/#{res_path}/#{res_id}")

    if obj['uuid'].nil?
      debug "Create a new #{res_path}"
      obj = HTTParty.post("#{ges_url}/#{res_path}", body: { name: res_id }.merge(additional_data))
    else
      debug "Found existing #{res_path} #{obj['name']}"
      # FIXME this hack appends irods user to projects
      if res_path =~ /projects/
        users = obj['irods_user'].split('|')
        current_irods_user = OMF::Web::SessionStore[:id, :irods_user]
        unless users.include? current_irods_user
          new_irods_user = "#{obj['irods_user']}|#{current_irods_user}"
          info "Need to write this #{new_irods_user}"
          HTTParty.post("#{ges_url}/#{res_path}/#{res_id}", body: { irods_user: new_irods_user })
        end
      end
    end

    obj
  end

end

