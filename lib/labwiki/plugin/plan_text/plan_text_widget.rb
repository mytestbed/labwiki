require 'labwiki/column_widget'
require 'omf-web/content/repository'
require 'labwiki/plugin/plan_text/abstract_publish_proxy'

module LabWiki::Plugin::PlanText

  # Maintains the context for a MarkDown formatted text column.
  #
  class PlanTextWidget < LabWiki::ColumnWidget

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
            puts ">>>>>>>> FIX DS #{ds}"
            if data_url = ds[:data_url]
              puts ">>>>> RESOLVE #{data_url}"
            end
            #ds[:id] = ds[:stream] = ds[:name] = 'foo'
          end
        end
      end
      puts ">>>>>>>> FIX WIDGET - #{wdescr}"
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
      return unless @content_proxy # TODO: Should return some error message

      # Line numbers are relative to original content
      unless @content
        c = @content_proxy.read
        @content = c.split("\n")
        @header_lines = OMF::Web::Widget::Text::Maruku.count_header_lines(c)
      end
      #puts "CONTENT: #{@content.inspect}"
      line_no = params[:line_no] + @header_lines
      line_idx = line_no - 1 # Line_no starts at 1
      line = @content[line_idx]
      unless line.is_a? Array
        @content[line_idx] = line = [line]
      end
      w = params[:widget]
      if dss = w.delete(:data_sources)
        w[:data_sources] = dss.map do |ds|
          {name: ds[:name], data_url: ds[:data_url]}
        end
      end
      gd = {widget: w}.to_yaml(line_width: -1, indentation: 2)
      if gd.start_with? "---\n"
        gd = gd[4 .. -1]
      end
      line << "{{{\n#{gd}\n}}}"
      #puts "LINE: #{line}"

      # Now save it
      s = @content.map do |l|
        l.is_a?(Array) ? l.join("\n") : l
      end.join("\n")
      puts "WRITE: #{s}"
      @content_proxy.write(s, "Added widget")
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
      message = ""
      begin
        AbstractPublishProxy.instance.publish(cp, params)
      rescue LabWiki::Plugin::PlanText::AccessDeniedError => e
        message = "#{e.inspect}"
      rescue LabWiki::Plugin::PlanText::NoConnectionToCMSError => e
        message = "#{e.inspect}"
      rescue LabWiki::Plugin::PlanText::InvalidUrlError => e
        message = "#{e.inspect}"
      rescue Exception => e
        message = "TODO: Rescue Exception -> #{e.inspect}"
      end

      debug "error-message: #{message}" unless message == ""
      gui_log(:error, message)

      # # TODO: Pop up with message


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
      OMF::Web::SessionStore[:contentHandler, :repos] = lambda() do |url|
        ps = url.split(':')
        repo = nil
        case ps.length
          when 1
            # Read from first repo
            repo = OMF::Web::SessionStore[:plan, :repos][0]
          when 2
            repo = OMF::Web::SessionStore[:plan, :repos].find do |r|
              #puts ">>>>>>> #{r.inspect} -- #{r.exist? url}"
              r.exist?(url)
            end
        end
        if repo
          {content: repo.read(url), mime_type: repo.mime_type_for_file(url) }
        else
          raise "Can't find repo containing '#{url}'."
        end
      end
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
