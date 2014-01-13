require 'labwiki/column_widget'
require 'labwiki/plugins/experiment/run_exp_controller'
require 'labwiki/plugins/experiment/experiment'
require 'labwiki/plugins/experiment/redis_helper'
require 'active_support/core_ext'

module LabWiki::Plugin::Experiment

  # Maintains the context for a particular experiment in this user context.
  #
  class ExperimentWidget < LabWiki::ColumnWidget
    include LabWiki::Plugin::Experiment::RedisHelper

    attr_reader :name

    def initialize(column, config_opts, unused)
      unless column == :execute
        raise "Should only be used in 'execute' column"
      end
      super column, :type => :experiment
      @experiment = nil

      @config_opts = config_opts
      OMF::Web::SessionStore[self.widget_id, :widgets] = self # Let's stick around a bit
    end

    def on_get_content(params, req)
      debug "on_get_content: '#{params.inspect}'"

      if (omf_exp_id = params[:omf_exp_id])
        #if (exp_hash = OMF::Web::SessionStore[:exps, :omf] && OMF::Web::SessionStore[:exps, :omf].find { |v| v[:id] == omf_exp_id })
          # LW instance still has such instance
        #  @experiment = exp_hash[:instance]
        #else
        @experiment = LabWiki::Plugin::Experiment::Experiment.new(nil, @config_opts)
        @experiment.recreate_experiment(omf_exp_id)
      else
        @experiment = LabWiki::Plugin::Experiment::Experiment.new(nil, @config_opts)
      end

      if (url = params[:url])
        @experiment.script = url
      end
      @title = "NEW"
    end

    def on_start_experiment(params, req)
      debug "START EXPERIMENT>>> #{params.inspect}"
      irods = {}
      irods[:path] = params[:irods_path]
      irods[:exp_name] = params[:gimi_exp]
      irods[:path] ||= "/tempZone/home/rods/user1"
      slice = params[:slice]
      @experiment.start_experiment((params[:properties] || {}).values, slice, params[:name], irods)
    end

    def on_stop_experiment(params, req)
      @experiment.stop_experiment
    end

    def new?
      @experiment ? (@experiment.state == :new) : false
    end

    def content_renderer()
      debug "content_renderer: #{@opts.inspect}"
      if new?
        OMF::Web::Theme.require 'experiment_setup_renderer'
        ExperimentSetupRenderer.new(self, @experiment)
      else
        OMF::Web::Theme.require 'experiment_running_renderer'
        ExperimentRunningRenderer.new(self, @experiment)
      end
    end

    def mime_type
      'experiment'
    end

    def title
      @experiment ? (@experiment.name || 'NEW') : 'No Experiment'
    end

  end # class

end # module
