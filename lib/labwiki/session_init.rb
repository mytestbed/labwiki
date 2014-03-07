require 'grit'
require 'httparty'
require 'omf-web/content/git_repository'
require 'omf-web/session_store'
require 'labwiki/plugin_manager'

class SessionInit < OMF::Base::LObject
  def initialize(app, opts = {})
    @app = app
  end

  def call(env)
    req = ::Rack::Request.new(env)

    unless req.path =~ /^\/resource/ # Do not care about resource files
      req.session['sid'] ||= "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"
      Thread.current["sessionID"] = req.session['sid'] # needed for Session Store

      # No login hack, set a default user called user1
      if OMF::Web::Runner.instance.options[:no_login_required] && !env['warden'].authenticated?
        identity_url = "https://localhost?id=user1"
        u_data = 'user1'
        $users[identity_url] = u_data
        env['warden'].set_user identity_url
      end

      if env['warden'].authenticated?
        user = $users[env['warden'].user]

        if user.nil?
          req.session['sid'] = nil # necessary?
          req.session.clear
          if req.xhr?
            return [401, {}, ['Session lost, re-authenticate.']]
          else
            return [302, {'Location' => '/', "Content-Type" => ""}, ['Session lost, re-authenticate.']]
          end
        end

        update_user(user)
        # We need to fresh this every time user logged in
        update_geni_projects_slices(user) if LabWiki::Configurator[:gimi]

        unless OMF::Web::SessionStore[:initialised, :session]
          if LabWiki::Configurator[:gimi]
            init_git_repository(OMF::Web::SessionStore[:id, :user]) if LabWiki::Configurator[:gimi][:git]
            init_irods_repository(OMF::Web::SessionStore[:id, :irods_user]) if LabWiki::Configurator[:gimi][:irods]
          end
          LabWiki::PluginManager.init_session()
          LabWiki::LWWidget.init_session()
          OMF::Web::SessionStore[:initialised, :session] = true
        end
      end
    end
    @app.call(env)
  end

  private

  def update_user(user)
    if user.kind_of? Hash
      pretty_name = user['http://geni.net/user/prettyname'].first
      urn = user['http://geni.net/user/urn'].first
      irods_user = user['http://geni.net/irods/username'].first
      irods_zone = user['http://geni.net/irods/zone'].first
      OMF::Web::SessionStore[:urn, :user] = urn
      OMF::Web::SessionStore[:name, :user] = pretty_name
      OMF::Web::SessionStore[:id, :user] = urn && urn.split('|').last
      OMF::Web::SessionStore[:id, :irods_user] = irods_user
      OMF::Web::SessionStore[:id, :irods_zone] = irods_zone
    elsif user.kind_of? String
      OMF::Web::SessionStore[:urn, :user] = user
      OMF::Web::SessionStore[:name, :user] = user
      OMF::Web::SessionStore[:id, :user] = user
    end
  end

  def update_geni_projects_slices(user)
    if user.kind_of?(Hash) &&
      (geni_projects = user['http://geni.net/projects']) &&
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
    elsif LabWiki::Configurator[:gimi] && LabWiki::Configurator[:gimi][:mocking]
      OMF::Web::SessionStore[:projects, :geni_portal] = [
        { uuid: '1111-111111',
          name: 'p1',
          slices: [
            { uuid: '2222-2222222', name: 'bob_slice' },
            { uuid: '3333-3333333', name: 'alice_slice' }
          ]
        },
        { uuid: '1111-111112',
          name: 'p2',
          slices: [
            { uuid: '2222-2222223', name: 'p2_bob_slice' },
            { uuid: '3333-3333334', name: 'p2_alice_slice' }
          ]
        }
      ]
    else
      OMF::Web::SessionStore[:projects, :geni_portal] = []
    end

    # We can create a default experiment for each project
    if LabWiki::Configurator[:gimi] && LabWiki::Configurator[:gimi][:ges]
      OMF::Web::SessionStore[:projects, :geni_portal].each do |p|
        proj = find_or_create("projects", p[:name], { irods_user: OMF::Web::SessionStore[:id, :irods_user] })
      end
    end
  end

  def init_irods_repository(id)
    irods_home = LabWiki::Configurator[:gimi][:irods][:home]
    id = 'user1' if LabWiki::Configurator[:gimi][:mocking]
    script_folder = "#{irods_home}/#{id}/#{LabWiki::Configurator[:gimi][:irods][:script_folder]}"
    opts = { type: :irods, top_dir: script_folder }
    repo = OMF::Web::ContentRepository.register_repo(id, opts)
    repo ||= OMF::Web::ContentRepository.find_repo_for("irods:#{id}")

    if (sample_repo_path = LabWiki::Configurator[:gimi][:irods][:sample_repo])
      cmd = "iput -r #{sample_repo_path}/* #{script_folder} 2>&1"
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
    git_path = File.expand_path("#{LabWiki::Configurator[:gimi][:git][:repos_dir]}/#{id}/")
    repos_dir_path = File.expand_path(LabWiki::Configurator[:gimi][:git][:repos_dir])
    sample_path = File.expand_path(LabWiki::Configurator[:gimi][:git][:sample_repo])

    begin
      unless File.exist?("#{git_path}.git")
        FileUtils.mkdir_p(git_path)
        Dir.chdir(repos_dir_path) do
          system "git clone #{sample_path} #{id}"
        end
      end

      opts = { type: :git, top_dir: git_path }
      OMF::Web::ContentRepository.register_repo(id, opts)

      repo = OMF::Web::ContentRepository.find_repo_for("git:#{id}")
      # Set the repos to search for content for each column
      OMF::Web::SessionStore[:plan, :repos] = [repo]
      OMF::Web::SessionStore[:prepare, :repos] = [repo]
      OMF::Web::SessionStore[:execute, :repos] = [repo]
    rescue => e
      error e.message
    end
  end

  def find_or_create(res_path, res_id, additional_data = {})
    ges_url = LabWiki::Configurator[:gimi][:ges]
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

