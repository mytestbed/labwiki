
require 'omf_common/lobject'
require 'omf-web/widget'
require 'labwiki/column_widget'
require 'labwiki/prepare_widget'

module LabWiki     
  class LWWidget < OMF::Common::LObject
    @@instance = nil
    
    def self.[](opts)
      @@instance ||= self.new
    end
    
    attr_reader :plan_widget, :prepare_widget, :execute_widget
    
    def initialize()
      @widgets = {}
      @plan_widget = @widgets[:plan] = ColumnWidget.new(:plan)
      @prepare_widget = @widgets[:prepare] = PrepareWidget.new(:prepare)
      @execute_widget = @widgets[:execute] = ColumnWidget.new(:execute)

      # margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
      # e = {:type => :code, :height => 800, :content => {:url => 'sample2.md'}, :margin => margin}
      # t = {:type => :text, :content => {:url => 'sample2.md'}, :margin => margin}      
      # @plan_widget = OMF::Web::Widget.create_widget(t)
      # @prepare_widget = OMF::Web::Widget.create_widget(e)
      # @execute_widget = OMF::Web::Widget.create_widget(t)
    end
    
    def get_column_widget(pos)
      @widgets[pos.to_sym]
    end
    
    def collect_data_sources(ds_set)
      @plan_widget.collect_data_sources(ds_set)
      @prepare_widget.collect_data_sources(ds_set)
      @execute_widget.collect_data_sources(ds_set)
      ds_set
    end
  end
end
