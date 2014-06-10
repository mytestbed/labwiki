

module LabWiki::Plugin::PlanText

  # Maintains the context for a MarkDown formatted text column.
  #
  class AbstractPublishProxy < OMF::Base::LObject

    @@instance = nil

    def self.instance
      unless @@instance
        # Create instance
        unless opts = LabWiki::Configurator["plugins/plan_text/publish"]
          raise "No publisher defined in config file"
        end
        debug "Initialising publisher - #{opts}"
        if require_file = opts.delete(:require)
          require(require_file)
        end
        if class_name = opts.delete(:class)
          begin
            provider_class = class_name.split('::').inject(Object) {|c,n| c.const_get(n) }
          rescue Exception
          end
        else
          raise "Missing 'class' declaration for publisher - #{opts}"
        end
        unless provider_class
          raise "Missing provider class for publisher - #{class_name}"
        end
        @@instance = provider_class.new(opts)
      end
      @@instance
    end

    def self.active?
      begin
        instance
        return true
      rescue
        return false
      end
    end

    def publish(content_proxy, opts)
	raise Exception.new("Missing implementation")
      #_to_html(content_proxy, true, opts)
    end

    def _to_html(cp, store_locally, opts)
      # TODO: The following is very dodgy and needs to be done right
      public_repo = cp.repository
      post_name = (opts[:url].split('/')[-1]).split('.')[0]
      dir_name = "/public/#{post_name}/"
      #puts ">>> DIR_NAME: #{dir_name}"
      ####

      require 'omf-web/widget/text/maruku'
      url2local = {}
      m = OMF::Web::Widget::Text::Maruku.format_content_proxy(cp)
      doc = m.to_html_tree(:img_url_resolver => lambda() do |u|
        unless iu = url2local[u]
          ext = u.split('.')[-1]
          iu = url2local[u] = "img#{url2local.length}.#{ext}"
        end
        #puts "IMAGE>>> #{u} => #{iu}"
        iu
      end)
      #puts "RES>>> #{doc.class}\n#{doc}"
      url2local.each do |url, local|
        img = cp.create_proxy_for_url(url)
        img_url = public_repo.get_url_for_path(dir_name + local)
        public_repo.write(img_url, img.content, "Adding/updating image '#{local}' for public post '#{post_name}'")
      end

      if store_locally
        meta = {
          title: opts[:title] || 'Unknown',
          updated: Time.now.iso8601
        }
        meta_url = public_repo.get_url_for_path(dir_name + 'meta.json')
        debug "Posting '#{meta_url}'"
        public_repo.write(meta_url, meta.to_json, "Adding/updating public post '#{post_name}'")

        page_url = public_repo.get_url_for_path(dir_name + 'page.xml')
        public_repo.write(page_url, doc.to_s, "Adding/updating public post '#{post_name}'")
      end

      doc
    end

    def initialize(opts)
      @opts = opts
    end

  end
end
