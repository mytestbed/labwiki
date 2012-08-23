
require 'labwiki/plugin'
require 'labwiki/plugins/source_edit/source_edit_widget'
require 'labwiki/plugins/source_edit/code_renderer'

LabWiki::Plugin.register :source_edit, {
  :widgets => [
    {
      :context => :prepare,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text') ? 500 : nil
      end,
      :widget_class => LabWiki::SourceEditWidget
    }
  ],
  :renderers => {
    :code_renderer => OMF::Web::Theme::CodeRenderer
  }
} 

