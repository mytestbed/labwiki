
module LabWiki::Plugin
  module SourceEdit; end
end

require 'labwiki/plugin/source_edit/source_edit_widget'
require 'labwiki/plugin/source_edit/code_renderer'
require 'labwiki/plugin/source_edit/code_renderer2'

LabWiki::PluginManager.register :source_edit, {
  :version => LabWiki.version,
  :widgets => [
    {
      :name => 'source_edit',
      :context => :prepare,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text') ? 100 : nil
      end,
      :widget_class => LabWiki::Plugin::SourceEdit::SourceEditWidget,
      :search => lambda do |pat, opts, wopts, &cbk|
        OMF::Web::ContentRepository.find_files(pat, opts, &cbk)
      end
    }
  ],
  :renderers => {
    :code_renderer2 => OMF::Web::Theme::CodeRenderer2
  },
  :resources => File.join(File.dirname(__FILE__), '/resource'),
  :config_ru => File.join(File.dirname(__FILE__), 'config.ru'),
  :global_js => 'js/source_edit_global.js'
}

