
module LabWiki::Plugin
  module PlanText; end
end

require 'labwiki/plugin/plan_text/plan_text_widget'
require 'labwiki/plugin/plan_text/text_renderer'

LabWiki::PluginManager.register :plan_text, {
  :widgets => [
    {
      :name => 'wiki',
      :context => :plan,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text') ? 500 : nil
      end,
      :widget_class => LabWiki::Plugin::PlanText::PlanTextWidget,
      :search => lambda do |pat, opts|
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

