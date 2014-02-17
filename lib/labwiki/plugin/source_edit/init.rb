
module LabWiki::Plugin
  module SourceEdit; end
end

require 'labwiki/plugin/source_edit/source_edit_widget'
require 'labwiki/plugin/source_edit/code_renderer'

LabWiki::PluginManager.register :source_edit, {
  :widgets => [
    {
      :name => 'source_edit',
      :context => :prepare,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text') ? 100 : nil
      end,
      :widget_class => LabWiki::Plugin::SourceEdit::SourceEditWidget,
      :search => lambda do |pat, opts, wopts|
        # TODO The next line should be commented out when upgradign to newest omf_web
#        opts[:mime_type] ||= 'text/*'
        OMF::Web::ContentRepository.find_files(pat, opts, wopts)
      end
    }
  ],
  :renderers => {
    :code_renderer => OMF::Web::Theme::CodeRenderer
  },
  :resources => File.join(File.dirname(__FILE__), '/resource'),
  :config_ru => File.join(File.dirname(__FILE__), 'config.ru')
}

