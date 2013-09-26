

module LabWiki::Plugin::Experiment

  class ExperimentCommonRenderer < Erector::Widget
    include OMF::Base::Loggable
    extend OMF::Base::Loggable

    def initialize(widget, experiment)
      @widget = widget
      @experiment = experiment
      #@wopts = wopts
      @tab_index = 30
    end

    def content
      link :href => '/plugin/experiment/css/experiment.css', :rel => "stylesheet", :type => "text/css"
      @data_id = "e#{object_id}"
      div :class => "experiment-description", :id => @data_id do
        render_content
      end
      javascript %{
        L.require('#LW.plugin.experiment.controller', '/plugin/experiment/js/experiment_controller.js', function() {
          $("\##{@data_id}").data('ec', LW.plugin.experiment.controller(#{@content_descriptor.to_json}));
        })
      }
    end

    def render_field(index, prop)
      # {:default=>"node2", :comment=>"ID of a node", :name=>"res2", :size => 16}
      comment = prop[:comment]
      name = prop[:name]
      type = prop[:type] || :text

      fname = "prop" + (index >= 0 ? index.to_s : name)
      tr :class => fname do
        td name + ':', :class => "desc" unless type.to_sym == :hidden
        td :class => "input #{fname}", :colspan => (comment ? 1 : 2) do
          case type.to_sym
          when :text
            input :name => fname, :type => "text", :class => "field text fn",
              :value => prop[:default] || "", :size => prop[:size] || 16, :tabindex => (@tab_index += 1)
              #:onkeyup => "handleInput(this);", :onchange => "handleInput(this);"
          when :hidden
            input :name => fname, :type => "hidden", :value => prop[:default] || "", :tabindex => (@tab_index += 1)
          when :select
            select(name: fname) do
              prop[:options] && prop[:options].each do |opt|
                option(value: opt) { text opt }
              end
            end
          end
        end
        if comment
          td :class => "comment" do
            text comment
          end
        end
      end
    end

    def render_field_static(prop, with_comment = true)
      # {:default=>"node2", :comment=>"ID of a node", :name=>"res2", :size => 16}
      comment = prop[:comment]
      name = prop[:name]
      index = prop[:index]
      fname = "prop" + (index ? index.to_s : name)
      tr :class => fname do
        td name + ':', :class => "desc"
        td :class => "input #{fname}", :colspan => (comment ? 1 : 2) do
          span prop[:value]
        end
        if with_comment && comment
          td :class => "comment" do
            text comment
          end
        end
      end
    end


  end # class
end # module
