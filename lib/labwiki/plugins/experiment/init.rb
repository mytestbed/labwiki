
module LabWiki::Plugin
  module Experiment; end
end

require 'labwiki/plugins/experiment/experiment_widget'
require 'labwiki/plugins/experiment/renderer/experiment_setup_renderer'
require 'labwiki/plugins/experiment/renderer/experiment_running_renderer'

LabWiki::PluginManager.register :experiment, {
  :search => lambda do ||
  end,
  :selector => lambda do ||
  end,
  :widgets => [
    {
      :name => 'experiment',
      :context => :execute,
      :priority => lambda do |opts|
        (opts[:mime_type].start_with? 'text/ruby') ? 500 : nil
      end,
      :widget_class => LabWiki::Plugin::Experiment::ExperimentWidget
    }
  ],
  :renderers => {
    :experiment_setup_renderer => LabWiki::Plugin::Experiment::ExperimentSetupRenderer,
    :experiment_running_renderer => LabWiki::Plugin::Experiment::ExperimentRunningRenderer
  },
#  :resources => File.dirname(__FILE__) + File.SEPARATOR + 'resource'
  :resources => File.dirname(__FILE__) + '/resource' # should find a more portable solution
}

