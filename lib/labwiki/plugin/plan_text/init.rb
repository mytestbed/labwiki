
module LabWiki::Plugin
  module PlanText; end
end

require 'labwiki/plugin/plan_text/plan_text_widget'
require 'labwiki/plugin/plan_text/text_renderer'

LabWiki::PluginManager.register :plan_text, {
  :version => LabWiki.version,
  :widgets => [
    {
      :name => 'wiki',
      :context => :plan,
      :priority => lambda do |opts|
        # FIXME missing :mime_type from opts
        #(opts[:mime_type].start_with? 'text') ? 500 : nil
        500
      end,
      :widget_class => LabWiki::Plugin::PlanText::PlanTextWidget,
      :search => lambda do |pat, opts, wopts|
        opts[:mime_type] = 'text/markup'
        OMF::Web::ContentRepository.find_files(pat, opts)
      end
    }
  ],
  :renderers => {
    :text_renderer => OMF::Web::Theme::TextRenderer
  },
  :resources => File.dirname(__FILE__) + '/resource' # should find a more portable solution
}

# Register a callback to fix potentially fix embedded widgets
require 'omf-web/widget/text/maruku'
OMF::Web::Widget::Text::Maruku::WidgetElement.on_pre_create do |wdescr|
  LabWiki::Plugin::PlanText::PlanTextWidget.on_pre_create_embedded_widget(wdescr)
end

