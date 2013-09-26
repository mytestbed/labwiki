
module LabWiki::Plugin::Experiment
        
  # This class kicks off and monitors a single experiment
  # on behalf of an ExperimentWidget
  #
  class ExperimentMonitor < OMF::Base::LObject
    
    def initialize()
      script = '~/src/omf_labwiki/test/repo/oidl/tutorial/using-properties.rb'
      ec = LabWiki::Plugin::Experiment::RunExpController.new(:test, script, @opts[:properties]) do |etype, msg|
        on_exp_output ec, etype, msg
      end
    end
  end
end

