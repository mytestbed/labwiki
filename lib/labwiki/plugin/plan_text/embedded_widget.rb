module LabWiki::Plugin::PlanText

  # Maintains the context for a MarkDown formatted text column.
  #
  class EmbeddedWidget
    # Check for data sources and create them if they don't exist yet
    def self.on_pre_create_embedded_widget(wdescr)

      unless wdescr.is_a? Hash
        warn "Malformed widget description - #{wdescr} "
        # TODO: Should raise some error to be propagated to client
        return {}
      end

      if wdescr[:mime_type] == 'data/graph'
        wdescr[:type] = "data/#{wdescr.delete(:graph_type)}"

        if dss = wdescr[:data_sources]
          dss.each do |ds|
            #puts ">>>>>>>> FIX DS #{ds}"
            if data_url = ds[:data_url]
              puts ">>>>> RESOLVE #{data_url}"
            end
            #ds[:id] = ds[:stream] = ds[:name] = 'foo'
          end
        end
      end
      #puts ">>>>>>>> FIX WIDGET - #{wdescr}"
      wdescr
    end

    def self.create(wdescr)
      #puts ">>>>>>>> CREATE WIDGET - #{wdescr}"
      self.new(wdescr)
    end

    def initialize(opts)
      @opts = opts
      @data_sources = []
      extract_datasources(opts)
      # if (content_descr = opts[:content])
        # opts[:content_proxy] = OMF::Web::ContentRepository.create_content_proxy_for(content_descr, opts)
      # end
    end

    def extract_datasources(opts)
      opts.each do |k, v|
        case k
          when :data_source
            register_datasource(nil, v)
          when :data_sources
            v.each {|n, ds| register_datasource(n, ds)}
          else
            if v.is_a? Hash
              extract_datasources(v)
            elsif v.is_a? Array
              v.each do |e|
                extract_datasources(e) if e.is_a? Hash
              end
            end
        end
      end
    end

    def register_datasource(name, ds_descr)
      #puts ">>>>DATA_SOURCE: #{ds_descr}"
      unless OMF::Web::DataSourceProxy.validate_ds_description(ds_descr)
        raise "Unknown data source requested for data widget - #{ds_descr}"
      end
      @data_sources << ds_descr
    end

    def title
      @opts[:title] || 'No Title'
    end

    def content()
      EmbeddedRenderer.new(@opts)
    end

    def collect_data_sources(ds_set)
      @data_sources.each do |ds|
        #ds_set.add(ds[:stream])
        ds_set.add(ds)
      end
      ds_set
    end
  end

  class EmbeddedRenderer < Erector::Widget

    def initialize(opts)
      super opts
      @opts = opts
    end

    def content()
      base_id = "lwe#{self.object_id}"
      div :id => base_id, :class => "omf_data_widget_container" do
        javascript(%{
          (OML.widget_proto.#{base_id} = function(id) {
            var inner_el = id + "_i";
            $("#" + id).append("<div id='" + inner_el + "' class='omf_embedded_widget omf_data_widget' />")
            var opts = #{@opts.to_json};
            //var base_el = "#" + inner_el;
            require(['plugin/plan_text/js/plan_text_embedded'], function(Embedded) {
              OML.widgets[id] = Embedded(inner_el, opts);
            });
          })('#{base_id}');
        })
      end

    end

  end
end
