require 'labwiki/column_widget'
require 'omf-web/content/repository'
require 'labwiki/plugin/plan_text/abstract_publish_proxy'

module LabWiki::Plugin::PlanText

  # Maintains the context for a MarkDown formatted text column.
  #
  class PlanTextWidget < LabWiki::ColumnWidget

    # Check for data sources and create them if they don't exist yet
    def self.on_pre_create_embedded_widget(wdescr)
      if dss = wdescr[:data_sources]
        dss.each do |name, ds|
          #puts ">>>>>>>> FIX DS(#{name})- #{ds}"
          #ds[:id] = ds[:stream] = ds[:name] = 'foo'
        end
      end
      #puts ">>>>>>>> FIX WIDGET - #{wdescr}"
      wdescr
    end

    def initialize(column, config_opts, unused)
      unless column == :plan
        raise "Should only be used in ':plan' column"
      end
      super column, :type => :plan
    end


    def on_get_content(params, req)
      debug "on_get_content: '#{params.inspect}'"

      @mime_type = (params[:mime_type] || 'text')
      @content_url = params[:url]

      #

      @content_proxy ||= OMF::Web::ContentRepository.create_content_proxy_for(@content_url, params)
      _get_text_widget(@content_proxy)
    end

    def on_insert_widget(params, req)
      debug "INSERT WIDGET - p: #{params}"
      nil
    end

    def on_share(params, req)
      debug "SHARE - p: #{params} - #@content_proxy - #@content_url - #{OMF::Web::SessionStore[:plan, :repos]}"
      if (url = params[:url]) != @content_url || @content_proxy.nil?
        cp = OMF::Web::ContentRepository.create_content_proxy_for(url, params)
      else
        cp = @content_proxy
      end

      params[:title] ||= self.title
      AbstractPublishProxy.instance.publish(cp, params)

      # # TODO: The following is very dodgy and needs to be done right
      # public_repo = cp.repository
      # post_name = (params[:url].split('/')[-1]).split('.')[0]
      # dir_name = "/public/#{post_name}/"
      # #puts ">>> DIR_NAME: #{dir_name}"
      # ####
#
      # require 'omf-web/widget/text/maruku'
      # url2local = {}
      # m = OMF::Web::Widget::Text::Maruku.format_content_proxy(cp)
      # doc = m.to_html_tree(:img_url_resolver => lambda() do |u|
        # unless iu = url2local[u]
          # ext = u.split('.')[-1]
          # iu = url2local[u] = "img#{url2local.length}.#{ext}"
        # end
        # #puts "IMAGE>>> #{u} => #{iu}"
        # iu
      # end)
      # #puts "RES>>> #{doc.class}\n#{doc}"
      # meta = {
        # title: self.title,
        # updated: Time.now.iso8601
      # }
      # meta_url = public_repo.get_url_for_path(dir_name + 'meta.json')
      # debug "Posting '#{meta_url}'"
      # public_repo.write(meta_url, meta.to_json, "Adding/updating public post '#{post_name}'")
#
      # page_url = public_repo.get_url_for_path(dir_name + 'page.xml')
      # public_repo.write(page_url, doc.to_s, "Adding/updating public post '#{post_name}'")
      # url2local.each do |url, local|
        # img = cp.create_proxy_for_url(url)
        # img_url = public_repo.get_url_for_path(dir_name + local)
        # public_repo.write(img_url, img.content, "Adding/updating image '#{local}' for public post '#{post_name}'")
      # end
      nil
    end

    # def on_get_plugin(params, req)
      # opts = params[:params]
      # debug "on_get_plugin: '#{opts.inspect}'"
      # @content_url = opts[:url]
      # @content_proxy ||= OMF::Web::ContentRepository.create_content_proxy_for(@content_url, opts)
      # @mime_type = @content_proxy.mime_type
      # _get_text_widget(@content_proxy)
    # end


    def content_renderer()
      @text_widget.content()
    end

    def title
      @text_widget.title
    end

    def sub_title
      @content_url || ''
    end

    def _get_text_widget(content_proxy)
      if @text_widget
        @text_widget.content_proxy = content_proxy
      else
        margin = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
        e = {:type => :text, :height => 800, :content => content_proxy, :margin => margin}
        @text_widget = OMF::Web::Widget.create_widget(e)
      end
    end
  end # class

end # module
