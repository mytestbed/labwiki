require 'net/http'
require 'uri'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'eventmachine'
require 'em-http-request'
require 'json'
require 'labwiki/plugin/plan_text/abstract_publish_proxy'
	
module LabWiki::Plugin::PlanText
	
	class RespondCMSProxy < AbstractPublishProxy
	
		def initialize(opts)
			super
			@respond = opts[:respond]
			@email = opts[:email]
			@password = opts[:password]
			@sitename = opts[:sitename]
	                @cookie = "-1"
		end
	
		def login
			begin
				url = "#{@respond}user/login/"
				debug "LOGIN-URL #{url}"
				params = {:email => "#{@email}", :password => "#{@password}" }
				uri = URI(url)
		        	response = Net::HTTP.post_form(uri, params)
				debug response.body
				debug response.code
				cookie = response["set-cookie"]
		
				if "#{response.body}" == "Access denied" && "#{response.code}" == "401"
					raise AccessDeniedError.new("")
				end
	
			rescue AccessDeniedError 
				raise AccessDeniedError.new("Access denied. Check Email and Password in Config-File!")		
			rescue Exception => e
				debug "Class: #{e.class} --- Message: #{e.inspect}"
				if "#{e.class}" == "Errno::EHOSTUNREACH"
					raise NoConnectionToCMSError.new("Server not reached. Check Server and Url in Configfile") 
				else if "#{e.class}" == "NoMethodError"
					raise InvalidUrlError.new("Url is invalid. Check Url in config-file!")
				else
					raise e.new("TODO: Rescue Exception -> #{e.insepect}")
				end
				end
			end
			return cookie
	
		end

	
		def publish(content_proxy, opts)

			#time = Time.new
			#date = time.strftime("%Y-%m-%d %H:%M:%S")
			title = "#{(opts[:url].split('/')[-1]).split('.')[0]}"
			author = "AUTHOR" #OMF::Web::SessionStore[:name, :user]
			#@name = "#{title} by #{author} #{date}" 
			@name = "#{title} by #{author}"

			print "\n\n id: #{OMF::Web::SessionStore[:id, :user]}"
			print "\n name: #{OMF::Web::SessionStore[:name, :user]}"

			print "\n\n\n"	
			
			@cookie = login if @cookie == "-1"

			EventMachine.synchrony do

				pages = get_pages

				unless get_pages.keys.include? @name 	
				
				debug "\n\n ---- ADD PAGE ---- \n"
	
				addPageUrl = "#{@respond}page/add/"
				addPageParams = {
					:pageTypeUniqId => "-1",
					:name => "#{@name}",
					:friendlyId => "#{@name.downcase.tr('^A-Za-z0-9', '')}",
					:description => "" 
				}
				#optional parameters
				# addPageParams[:categories] =
	
				tried = 0
				begin
					head = {"Cookie" => "#{@cookie}"} 
					http = EventMachine::HttpRequest.new(addPageUrl).post :body => addPageParams, :timeout => 10, :head => head
					print "EM-RESPONSE: #{http.response} \n"
					print "EM-RESPONSE-HEADER: #{http.response_header} \n"
					print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n"
			
					if "#{http.response_header.status}" == "401"
						tried = tried + 1
						raise AccessDeniedError.new("")
					end 
				
 				rescue AccessDeniedError => e
					print "EXCEPTION: #{e.inspect}"
					if tried == 1
					@cookie = login
					print "RETRY\n"
					retry
					end
					raise AccessDeniedError.new("AddPage: Login not possible") if tried == 2
				rescue Exception => ex
					raise Exception.new("TODO: handle Exception: #{ex.inspect}")
				end
					
				json_response = JSON.parse(http.response)
				pageID = json_response["PageUniqId"]			
				debug "ID: #{pageID}"

			
=begin
	
				debug "\n\n ---- UPDATE PAGE ---- \n"
	
				updatePageUrl = "#{@respond}page/#{pageID}"
				debug "URL: #{updatePageUrl}"
				updatePageParams = {
					:keywords => "TEST",
					:callout => "",
					:rss => "",
					:layout => "content",
					:stylesheet => "content",
					:beginDate => "",
					:endDate => "",
					:timeZone => "",
					:location => "",
					:latitude => "",
					:longitude => ""
				}
				updatePageParams = updatePageParams.merge(addPageParams)



				tried = 0
				begin
					head = {"Cookie" => "#{@cookie}"} 
					http = EventMachine::HttpRequest.new(updatePageUrl).post :body => updatePageParams, :timeout => 10, :head => head                        
					print "EM-RESPONSE: #{http.response} \n"
					print "EM-RESPONSE-HEADER: #{http.response_header} \n"
					print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n" 
					
					if "#{http.response_header.status}" == "401"
						tried = tried + 1
						raise AccessDeniedError.new("")
					end
	
				rescue AccessDeniedError => e
					print "EXCEPTION: #{e.inspect}"
					if tried == 1
					@cookie = login
					print "RETRY\n"
					retry
					end
					raise AccessDeniedError.new("UpdatePage: Login not possible") if tried == 2
				rescue Exception => ex
					raise Exception.new("TODO: handle Exception: #{ex.inspect}")
				end
=end

				#end
				else
					pageID = pages[@name]
					print "\n\n>>>>>>>>>>>only save<<<<<<<<<<<< \n\n"
				end
				debug "\n\n ---- SAVE PAGE ---- \n"

				doc = to_html(content_proxy, true, opts)
	
				savePageUrl = "#{@respond}page/content/#{pageID}"
				savePageParams = {
					:content => doc,
					:status => "publish"
				#	:image =>
				}

				tried = 0
				begin 
					head = {"Cookie" => "#{@cookie}"} 
					http = EventMachine::HttpRequest.new(savePageUrl).post :body => savePageParams, :timeout => 10, :head => head
					print "EM-RESPONSE: #{http.response} \n"
					print "EM-RESPONSE-HEADER: #{http.response_header} \n"
					print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n" 

					if "#{http.response_header.status}" == "401"
						tried = tried + 1
						raise AccessDeniedError.new("")
					end
	
				rescue AccessDeniedError => e
					print "EXCEPTION: #{e.inspect}"
					if tried == 1
					@cookie = login
					print "RETRY\n"
					retry
					end
					raise AccessDeniedError.new("SavePage: Login not possible") if tried == 2
				rescue Exception => ex
					raise Exception.new("TODO: handle Exception: #{ex.inspect}")
				end

			end
		end

		def to_html(cp, store_locally, opts)
			# TODO: The following is very dodgy and needs to be done right
			public_repo = cp.repository
			post_name = (opts[:url].split('/')[-1]).split('.')[0]
			dir_name = "/public/#{post_name}/"
			#puts ">>> DIR_NAME: #{dir_name}"
			####

			require 'omf-web/widget/text/maruku'
			require 'securerandom'
			uuid = SecureRandom.uuid
			path = "#{public_repo.top_dir}/wiki/#{post_name}/"
			url2local = {}
			m = OMF::Web::Widget::Text::Maruku.format_content_proxy(cp)
			docI = m.to_html_tree(:img_url_resolver => lambda() do |u|
				#print "\n #{u} \n"
				unless iu = url2local[u]
					ext = u.split('.')[-1]
					iu = url2local[u] = "#{get_checksum("#{path}#{u}")}.#{ext}"
				end
				#puts "IMAGE>>> #{u} => #{iu}"
				iu
			end)

			doc = m.to_html_tree(suppress_section: true)
			print "\n\n doc true: \n\n #{doc}"

			doc.root.attributes["class"] = "col col-md-12"

			outerPart1 = "<div id=\"block-1\" class=\"block row\" data-nested=\"not-nested\">"
			outerPart2 = "</div>"

			newDoc ="#{outerPart1}#{doc}#{outerPart2}"

			imgUrl = "sites/#{@sitename}/files/"

			url2local.each do |key, value|
				newDoc.gsub! key, "#{imgUrl}#{value}"
				print "\n"
				print value
			end
			print "\n"


			images = get_images
			c = 0
			url2local.each do |key, value|
				print "\n #{c} \n"
				sendFile("#{path}#{key}", value) unless images.include? value
				c=c+1
			end
		
			return newDoc

		end

		def get_images
			print "\n\n --- GET_IMAGES --- \n\n"
				url = "#{@respond}image/list/all/"
				uri = URI(url)

				http = Net::HTTP.new(uri.host, uri.port)
				req = Net::HTTP::Get.new(uri.path)
				req["cookie"] = "#{@cookie}"
				response = http.request(req)
				images = []
				parsed = JSON.parse(response.body)	
				parsed.each do |image|
					filename = image["filename"]
					images << filename
				end
				return images
		end

		def get_pages
			url = "#{@respond}page/list/all/"
			uri = URI(url)

			http = Net::HTTP.new(uri.host, uri.port)
			req = Net::HTTP::Get.new(uri.path)
			req["cookie"] = "#{@cookie}"
			response = http.request(req)
			parsed = JSON.parse(response.body)
			pages = {}
			parsed.each do |id, details|
				pageTitle = details["Name"]
				pages[pageTitle] = id	
			end
			return pages
		end

		def get_checksum(path)

			require 'digest/md5'
			digest = Digest::MD5.hexdigest(File.read(path))
			return digest
		end


		def sendFile(path, filename)
			boundary = "------------------AaB03x"
			url = "#{@respond}file/post/"
	
			uri = URI.parse(url)
			
			post_body = []
			post_body << "--#{boundary}\n"
			post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\n"
			post_body << "Content-Type: image/jpeg\n"
			post_body << "\n"
			post_body << File.read(path)
			post_body << "\n--#{boundary}--\n"
			
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Post.new(uri.request_uri)
			request.body = post_body.join

			request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
			request["cookie"] = "#{@cookie}"
			response = http.request(request)
			print "\n\n #{response.body} \n\n"
		end

	end
	
	
	class AccessDeniedError < StandardError
	# if credentials are wrong -> check config file
	end
	
	class NoConnectionToCMSError < StandardError
	#if server can't be accessed
	end
	
	class InvalidUrlError < StandardError
	end

end
	
