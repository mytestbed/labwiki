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
			doc = to_html(content_proxy, true, opts)

			#doc = "<div id=\"block-1\" class=\"block row\" data-nested=\"not-nested\"><div class=\"col col-md-12\"><h1 id=\"hypothesis_wiresless_links_are_bandwidth_constraints\">Hypothesis: Wiresless Links are bandwidth Constraints</h1><p class=\"content\" delegate=\"plan\" line_no=\"3\">We want to test the hypothesis that wireless links are bandwidth constraints.</p></div></div>"
			#doc = "<div id=\"block-1\" class=\"block row\" data-nested=\"not-nested\"><div class=\"col col-md-12\"><h1 id=\"h1-1399522248\">TEST</h1><p id=\"p-1399522248\">test test test</p><div id=\"imagecontainer1\" class=\"o-image\"><img id=\"image1\" src=\"sites/testsite/files/Sydney_565x215_tcm253-811043.jpg\"></div><pre id=\"1399523715\" class=\"prettyprint linenums pre-scrollable\">def main {\nputs \"Hello\"\n}</pre></div></div>"
			
			@cookie = login if @cookie == "-1"
			EventMachine.synchrony do
			 	@cookie = "12345"
	
				debug "\n\n ---- ADD PAGE ---- \n"
	
				#add Page 
				addPageUrl = "#{@respond}page/add/"
				addPageParams = {
					:pageTypeUniqId => "-1",
					:name => "#{@name}",
					:friendlyId => "#{@name.downcase.tr('^A-Za-z0-9', '')}",
					:description => ""
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
	
				#update Page
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
	
				#savePage
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

				print "\n\n GET PAGE CONTENT \n\n"
				

				getPageUrl = "#{@respond}page/content/536b03a94a9ee"

				head = {"Cookie" => "#{@cookie}"} 
					http = EventMachine::HttpRequest.new(getPageUrl).get :timeout => 10, :head => head
					print "EM-RESPONSE: #{http.response} \n"
					print "EM-RESPONSE-HEADER: #{http.response_header} \n"
					print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n" 
				
				print "\n\n #{doc} \n\n"
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
			doc = m.to_html_tree(:img_url_resolver => lambda() do |u|
				#print "\n #{u} \n"
				unless iu = url2local[u]
					ext = u.split('.')[-1]
					iu = url2local[u] = "img#{url2local.length}.#{ext}"
				end
				#puts "IMAGE>>> #{u} => #{iu}"
				iu
			end)

			doc.root.attributes["class"] = "col col-md-12"

			outerPart1 = "<div id=\"block-1\" class=\"block row\" data-nested=\"not-nested\">"
			outerPart2 = "</div>"

			return "#{outerPart1}#{doc}#{outerPart2}"
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
	
