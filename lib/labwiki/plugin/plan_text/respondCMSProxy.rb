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
		@name = "TITEL" # opts[:title]
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
			else if "#{e.class} == "NoMethodError"
				raise InvalidUrlError.new("Url is invalid. Check Url in config-file!")
			else
				raise e.new("TODO: Rescue Exception -> #{e.insepect}")
		end

		return cookie
	end

	def publish(content_proxy, opts)
		login
	end

	def publish2(content_proxy, opts)
		#doc = _to_html(content_proxy, true, opts)
		doc = "<HTML><HEAD><TITLE>A Small Hello</TITLE></HEAD><BODY><H1>Hi</H1><P>hello world.</P></BODY></HTML>"
                @cookie = login if @cookie == "-1"
		EventMachine.synchrony do
			head = {"Cookie" => "#{@cookie}"} 

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

			http = EventMachine::HttpRequest.new(addPageUrl).post :body => addPageParams, :timeout => 10, :head => head
			print "EM-RESPONSE: #{http.response} \n"
			print "EM-RESPONSE-HEADER: #{http.response_header} \n"
			print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n" 
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
			http = EventMachine::HttpRequest.new(updatePageUrl).post :body => updatePageParams, :timeout => 10, :head => head                        
			print "EM-RESPONSE: #{http.response} \n"
			print "EM-RESPONSE-HEADER: #{http.response_header} \n"
			print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n" 

			debug "\n\n ---- SAVE PAGE ---- \n"

			#savePage
			savePageUrl = "#{@respond}page/content/#{pageID}"
			savePageParams = {
				:content => doc,
				:status => "publish"
			#	:image =>
			}
			http = EventMachine::HttpRequest.new(savePageUrl).post :body => savePageParams, :timeout => 10, :head => head
			print "EM-RESPONSE: #{http.response} \n"
			print "EM-RESPONSE-HEADER: #{http.response_header} \n"
			print "EM-RESPONSE-HEADER-STATUS: #{http.response_header.status} \n" 
		end
	end












      def loginUser(email, password)
            url = 'http://10.129.128.41/respond/api/user/login/'
            options = {
              'email' => email,
              'password' => password
            }
            resp = sendRequest(url, options)
      end


      def addPage(pageTypeUniqId, pageTypeId, layout, stylesheet, name, friendlyId, description, categories)
            url = 'http://10.129.128.41/respond/api/page/add/'
            options = {
              # 'pageTypeUniqId' => pageTypeUniqId,
              # 'PageTypeId' => pageTypeId,
               #'Layout' => layout,
              # 'Stylesheet' => stylesheet,
               'name' => name,
               'friendlyId' => friendlyId,
               'description' => description
              # 'categories' => categories
            }
            resp = sendRequest(url, options)
      end

      def sendHelloWorld(url)
              options = {"content" => "<html><body><h1>Hello, World!<h1></body></html>"}
               resp = sendRequest(url, options)
      end

end

end

class AccessDeniedError < StandardError
# if credentials are wrong -> check config file
end

class NoConnectionToCMSError < StandardError
#if server can't be accessed
end

class InvalidUlError < StandardError
end


