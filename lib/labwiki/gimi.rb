

require 'omf-web/session_store'
require 'labwiki/plugin_manager'

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

    init_user(user_info)
    init_repo(user_info)
  end

  def on_session_close
    #TODO What to do?
  end

  def init_user(user)
    pretty_name = (user['http://geni.net/user/prettyname'] || ['Unknown']).first
    OMF::Web::SessionStore[:name, :user] = pretty_name

    if urn_a = user['http://geni.net/user/urn']
      urn = urn_a.first
      OMF::Web::SessionStore[:urn, :user] = urn.gsub '|', '+'
      OMF::Web::SessionStore[:id, :user] = urn && urn.split('|').last
    end
    if iu_a = user['http://geni.net/irods/username']
      irods_user = iu_a.first
      OMF::Web::SessionStore[:id, :irods_user] = irods_user
    end
    if iz_a = user['http://geni.net/irods/zone']
      irods_zone = iz_a.first
      OMF::Web::SessionStore[:id, :irods_zone] = irods_zone
    end
  end

  def init_repo(user_info)
    init_git_repository(OMF::Web::SessionStore[:id, :user]) if @opts[:git]
    init_irods_repository(OMF::Web::SessionStore[:id, :irods_user]) if @opts[:irods]
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

  def init_irods_repository(id)
    irods_home = @opts[:irods][:home]
    id = 'user1' if @opts[:mocking]
    script_folder = "#{irods_home}/#{id}/#{@opts[:irods][:script_folder]}"
    opts = { type: :irods, top_dir: script_folder }
    repo = OMF::Web::ContentRepository.register_repo(id, opts)
    repo ||= OMF::Web::ContentRepository.find_repo_for("irods:#{id}")

    if (sample_repo_path = @opts[:irods][:sample_repo])
      cmd = "iput -fr #{sample_repo_path}/* #{script_folder} 2>&1"
      cmd_out = `#{cmd}`
      unless $?.success?
        error "iRods command failed: '#{cmd}'"
        error cmd_out
      end
    end

    OMF::Web::SessionStore[:plan, :repos] = [repo]
    OMF::Web::SessionStore[:prepare, :repos] = [repo]
    OMF::Web::SessionStore[:execute, :repos] = [repo]
  end

  def init_git_repository(id)
    git_path = File.expand_path("#{@opts[:git][:repos_dir]}/#{id}/")
    repos_dir_path = File.expand_path(@opts[:git][:repos_dir])
    sample_path = File.expand_path(@opts[:git][:sample_repo]) if @opts[:git][:sample_repo]

    begin
      unless File.exist?("#{git_path}.git")
        FileUtils.mkdir_p(git_path)
        Dir.chdir(repos_dir_path) do
          if sample_path
            system "git clone #{sample_path} #{id}"
          else
            system "git init #{id}"
          end
        end
      end

      opts = { name: id.to_sym, type: :git, top_dir: git_path, read_only: false }

      my_repo = OMF::Web::ContentRepository.create(opts.delete(:name), opts)

      # Set the repos to search for content for each column
      (OMF::Web::SessionStore[:plan, :repos] ||= []) << my_repo
      (OMF::Web::SessionStore[:prepare, :repos] ||= []) << my_repo
      (OMF::Web::SessionStore[:execute, :repos] ||= []) << my_repo
    rescue => e
      error e.message
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

