require 'grit'
require 'omf-web/content/git_repository'
require 'omf-web/session_store'

class SessionInit < OMF::Common::LObject
  def initialize(app, opts = {})
    @app = app
  end

  def call(env)
    req = ::Rack::Request.new(env)
    req.session['sid'] ||= "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"
    Thread.current["sessionID"] = req.session['sid'] # needed for Session Store
    if env['warden'].authenticated?
      user = env['warden'].user
      id = user.split('=').last
      OMF::Web::SessionStore[:email, :user] = user
      OMF::Web::SessionStore[:name, :user] = user
      OMF::Web::SessionStore[:id, :user] = id
      init_git_repository(id)
    end
    @app.call(env)
  end

  private

  def init_git_repository(id)
    git_path = "#{LabWiki::Configurator[:repos_dir]}/#{id}/"
    sample_path = LabWiki::Configurator[:sample_repo_dir]

    begin
      unless File.exist?("#{git_path}.git")
        FileUtils.mkdir_p(git_path)
        Dir.chdir(LabWiki::Configurator[:repos_dir]) do
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
end

