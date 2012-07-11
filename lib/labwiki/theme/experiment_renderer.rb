

module OMF::Web::Theme
  class ExperimentRenderer < Erector::Widget
    include OMF::Common::Loggable
    extend OMF::Common::Loggable    
         
    def initialize(widget, exp_descr, wopts)
      @widget = widget
      @exp_descr = exp_descr
      @wopts = wopts
    end
        
    def content
      div :class => "experiment-description" do 
        h1 'EXPERIMENT'
        ul do
          li do
            label :class => "desc", :for => "Field1" do
              text 'Name'
              span "*", :class => "req"
            end
            div do
              input :name => "Field1", :type => "text", :class => "field text fn",
                  :value => "", :size => "8", :tabindex => "1", :onkeyup => "handleInput(this);",
                  :onchange => "handleInput(this);"
              label "More info", :for => "Field1"
            end
          end
        end
      end
    end
    
    
  end # class
end # module