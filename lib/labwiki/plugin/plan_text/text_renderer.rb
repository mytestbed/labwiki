
require 'omf-web/theme/bright/widget_chrome'

module OMF::Web::Theme

  # Override some of the functionality of the text renderer defined in OMF::Web
  class TextRenderer < Erector::Widget
    include OMF::Base::Loggable

    def initialize(text_widget, content, opts)
      super opts
      @opts = opts
      @widget = text_widget
      @content = content
      puts "CONTENT>>>> #{opts.inspect}"
      @content_descriptor = opts[:content].content_descriptor
    end

    def content
      link :href => '/resource/plugin/plan_text/css/plan_text.css', :rel => "stylesheet", :type => "text/css"
      wid = "w#{@widget.object_id}"
      div :class => "text plan_text", :id => wid do
        rawtext @content.to_html(:img_url_resolver => lambda() {|url| fix_image_url(url)})
      end
      javascript %{
        require(['plugin/plan_text/js/plan_text_monitor'], function(plan_text_monitor) {
          var r_#{object_id} = plan_text_monitor(#{@content_descriptor.to_json}, '#{wid}');
        })
      }
    end

    def title_info
      {
        img_src: '/resource/vendor/mono_icons/article32.png',
        title: @widget.title,
        sub_title:  @content_descriptor[:url] #@widget.content_url
      }
    end

    # Return image url which can be resolved within labwiki
    def fix_image_url(url)
      if (url.start_with? 'http')
        return url # external reference
      end
      cp = @opts[:content].create_proxy_for_url(url)
      debug "Resolving #{url} to #{cp.content_url}"
      cp.content_url
    end
  end

end # OMF::Web::Theme
