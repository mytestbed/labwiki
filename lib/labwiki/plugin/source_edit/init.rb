
module LabWiki::Plugin
  module SourceEdit; end
end

require 'labwiki/plugins/source_edit/source_edit_widget'
require 'labwiki/plugins/source_edit/code_renderer'

LabWiki::PluginManager.register :source_edit, {
  :widgets => [
    {
      :name => 'source_edit',
      :context => :prepare,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text') ? 100 : nil
      end,
      :widget_class => LabWiki::Plugin::SourceEdit::SourceEditWidget
    }
  ],
  :renderers => {
    :code_renderer => OMF::Web::Theme::CodeRenderer
  }
}

