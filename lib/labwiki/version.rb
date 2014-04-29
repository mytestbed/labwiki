
module LabWiki
  VERSION = [0, 15, 'pre']

  def self.version
    version = VERSION.join('.')
    if File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '/../../.git'))
      git_tag  = `git describe --tags 2> /dev/null`.chomp
      unless git_tag.empty?
        version += '-' + git_tag.gsub(/-/, '.').gsub(/^v/, '')
      end
    end
    version
  end

  def self.plugin_version(version, init_path = nil)
    version = version.join('.') if version.is_a? Array
    if (init_path)
      git_dir = File.absolute_path(File.join(File.dirname(init_path), '../../../../.git'))
      if File.exist? git_dir
        git_tag  = `git --git-dir #{git_dir} describe --tags 2> /dev/null`.chomp
        unless git_tag.empty?
          version += '-' + git_tag.gsub(/-/, '.').gsub(/^v/, '')
        end
      end
    end
    version
  end


end
