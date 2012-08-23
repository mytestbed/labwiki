

module OMF::Web::Theme
  class ExperimentRenderer < Erector::Widget
    include OMF::Common::Loggable
    extend OMF::Common::Loggable    
         
    def initialize(widget, wopts)
      @widget = widget
      @wopts = wopts
      @tab_index = 30
    end
        
    def content
      div :class => "experiment-description" do 
        @widget.new? ? render_start_form : render_properties
      end
    end
    
    
    def render_start_form
      fid = "f#{self.object_id}"
      properties = @wopts[:properties]
      form :id => fid, :class => 'start-form' do
        if properties
          table :style => 'width: auto' do
            render_field -1, :name => 'Name', :size => 24, :default => @wopts[:name]
            render_field_static :name => 'Script', :value => @wopts[:url]
            properties.each_with_index do |prop, i|
              render_field(i, prop)
            end
            tr :class => "buttons" do 
              td :colspan => 3 do
                input :type => "hidden", :name => "name1",  :id => "id1", :value => "value1"
                input :id => "id_startExperiment", :name => "name_startExperient", :class => "submit button-text", 
                  :type => "submit", :value => "Start Experiment"
                  #:onmousedown => "doSubmitEvents();"
              end
            end              
          end
        end
      end
      javascript %{
        $("\##{fid}").submit(function(event) {
          event.preventDefault();
          LW.execute_controller.start_experiment($(this), #{@wopts.to_json});
        });
      }
    end
    
    def render_field(index, prop)
      # {:default=>"node2", :comment=>"ID of a node", :name=>"res2", :size => 16}
      comment = prop[:comment]
      name = prop[:name]
      fname = "prop" + (index >= 0 ? index.to_s : name)
      tr :class => fname do
        td name + ':', :class => "desc"
        td :class => "input #{fname}", :colspan => (comment ? 1 : 2) do
          input :name => fname, :type => "text", :class => "field text fn",
              :placeholder => prop[:default] || "", :size => prop[:size] || 16, :tabindex => (@tab_index += 1) 
              #:onkeyup => "handleInput(this);", :onchange => "handleInput(this);"
        end
        if comment
          td :class => "comment" do
            text comment
          end
        end
      end
    end
    
    def render_field_static(prop)
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
        if comment
          td :class => "comment" do
            text comment
          end
        end
      end
    end
    
    
    def render_properties
      properties = @wopts[:properties]
      #puts ">>>> #{properties}"
      div :class => 'experiment-status' do
        if properties
          table :class => 'experiment-status', :style => 'width: auto'  do
            render_field_static :name => 'Name', :value => @wopts[:name]
            render_field_static :name => 'Script', :value => @wopts[:url]
            properties.each_with_index do |prop, i|
              prop[:index] = i
              render_field_static(prop)
            end
          end
        end
      end
    end

    
  end # class
end # module