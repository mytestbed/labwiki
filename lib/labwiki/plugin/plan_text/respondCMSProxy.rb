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
			@name = "TEST" #opts[:title]
			#@name = OMF::Web::SessionStore[:name, :user] if opts[:title] == nil 
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

			print "#{OMF::Web::SessionStore[:id, :user]}"
			print "\n#{OMF::Web::SessionStore[:name, :user]}"
			return 

			print "\n\n\n"	
			
			@cookie = login if @cookie == "-1"

			EventMachine.synchrony do	
				
				debug "\n\n ---- ADD PAGE ---- \n"
	
				addPageUrl = "#{@respond}page/add/"
				addPageParams = {
					:pageTypeUniqId => "-1",
					:name => "#{@name}",
					:friendlyId => "#{@name.downcase.tr('^A-Za-z0-9', '')}",
					:description => "" # "Author: #{OMF::Web::SessionStore[:id, :user]}"
				}
				#optional parameters
				# addPageParams[:PageTypeId] =>
				# addPageParams[:Layout] =>
				# addPageParams[:Stylesheet] =>
				# addPageParams[:categories] =>
	
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
	
	
				debug "\n\n ---- UPDATE PAGE ---- \n"
	
				updatePageUrl = "#{@respond}page/#{pageID}"
				debug "URL: #{updatePageUrl}"
				updatePageParams = {
					:keywords => "TEST",
					:callout => "",
					:rss => "",
					:layout => "",
					:stylesheet => "",
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
			url2local = {}
			m = OMF::Web::Widget::Text::Maruku.format_content_proxy(cp)
			docI = m.to_html_tree(:img_url_resolver => lambda() do |u|
				#print "\n #{u} \n"
				unless iu = url2local[u]
					ext = u.split('.')[-1]
					iu = url2local[u] = "img#{url2local.length}.#{ext}"
				end
				#puts "IMAGE>>> #{u} => #{iu}"e
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
				newDoc.gsub! key, "#{imgUrl}#{key}"
			end

			c = 0
			url2local.each do |key, value|
				print "\n #{c} \n"
				path = "#{public_repo.top_dir}/wiki/#{post_name}/"
				sendFile("#{path}#{key}")
				c=c+1
			end
		

			#print "\n\n #{newDoc} \n\n"
			return newDoc

		end


		def sendFile(path)
			boundary = "------------------AaB03x"
			url = "#{@respond}file/post/"
	
			uri = URI.parse(url)
			
			post_body = []
			post_body << "--#{boundary}\n"
			post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{File.basename(path)}\"\n"
			post_body << "Content-Type: image/jpeg\n"
			post_body << "\n"
			post_body << File.read(path)
			post_body << "\n--#{boundary}--\n"
			
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Post.new(uri.request_uri)
			request.body = post_body.join

			#print "\n\n#{post_body.join}\n\n"

			request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
			request["cookie"] = "#{@cookie}"
			response = http.request(request)
			print "\n\n #{response.body} \n\n"
		end

		def sendFile2(path)

				@cookie = login

				url = "#{@respond}file/post/"
				
				uri = URI.parse(url)

				data = File.read("#{path}")  

				print "\nname: #{File.basename(path)}\n"

				http = Net::HTTP.new(uri.host, uri.port)
				request = Net::HTTP::Post.new(uri.request_uri)
				request.body = data
				request["content-type"] = 'image/jpeg'
				request["cookie"] = '#{@cookie}'
				request["content-disposition"] = 'form-data; name=\"file\"; filename=\"#{File.basename(path)}\"'
				
				#print "\n\nbody: #{request.inspect}\n\n"
				#request.header.each_header {|key,value| print "\n#{key} = #{value}\n" }


				response = http.request(request)
				print "\n\n Response: #{response.body} \n\n"
				print "#{response.code}"

				

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
	
