
require 'labwiki/plugins/experiment/renderer/experiment_common_renderer'

module LabWiki::Plugin::Experiment

  class ExperimentRunningRenderer < ExperimentCommonRenderer

    def render_content
      render_toolbar
      render_properties
      render_logging
      render_graphs

      javascript %{
        L.require('#LW.plugin.experiment.experiment_monitor', '/plugin/experiment/js/experiment_monitor.js', function() {
          #{@experiment.datasource_renderer};
          var r_#{object_id} = LW.plugin.experiment.experiment_monitor('#{@experiment.name}');
        })
      }

    end

    def render_toolbar
      div :class => 'widget-toolbar' do
        button "Stop Experiment", :class => 'btn-stop-experiment btn btn-danger'
        button("Dump", id: 'btn-dump', class: 'btn-dump btn btn-inverse')
      end
    end

    def render_properties
      properties = @experiment.properties
      #puts ">>>> #{properties}"
      render_header "Experiment Properties"
      div :class => 'experiment-status' do
        if properties
          table :class => 'experiment-status table table-bordered', :style => 'width: auto'  do
            render_field_static :name => 'Name', :value => @experiment.name
            render_field_static :name => 'Script', :value => @experiment.url
            if @experiment.slice
              render_field_static :name => 'Slice', :value => @experiment.slice
            end
            properties.each_with_index do |prop, i|
              prop[:index] = i
              render_field_static(prop, false)
            end
          end
        end
      end
    end

    def render_logging
      render_header  "Logging"
      div :class => 'experiment-log' do
        table :class => 'experiment-log table table-bordered'
        #div :class => 'experiment-log-latest'
      end
    end

    def render_graphs
      render_header  "Graphs"
      div :class => 'experiment-graphs' do
      end
    end

    def render_header(header_text)
      h3 do
        a :class => 'toggle', :href => '#'
        text header_text
      end
    end

  end # class
end # module
