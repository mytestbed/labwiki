
require 'labwiki/plugin'
require 'labwiki/plugins/experiment/experiment_widget'
require 'labwiki/plugins/experiment/experiment_renderer'

LabWiki::Plugin.register :experiment, {
  :widgets => [
    {
      :context => :execute,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text/ruby') ? 500 : nil
      end,
      :widget_class => LabWiki::ExperimentWidget
    }
  ],
  :renderers => {
    :experiment_renderer => OMF::Web::Theme::ExperimentRenderer
  }
} 

