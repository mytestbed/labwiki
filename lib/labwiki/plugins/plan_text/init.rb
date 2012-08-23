
require 'labwiki/plugin'
require 'labwiki/plugins/plan_text/plan_text_widget'
require 'labwiki/plugins/plan_text/text_renderer'

LabWiki::Plugin.register :plan_text, {
  :widgets => [
    {
      :context => :plan,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text') ? 500 : nil
      end,
      :widget_class => LabWiki::PlanTextWidget
    }
  ],
  :renderers => {
    :text_renderer => OMF::Web::Theme::TextRenderer
  }
} 

