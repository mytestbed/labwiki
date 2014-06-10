# Publish - Plugin

## Overview

With this plugin the results of experiments can be published.
What you need to use it:
1. CMS of your choice
2. Implementation of a class that communicates with your CMS

## CMS - Proxy

As mentioned before, you need to implement your own class that publishes to the CMS of your choice.
This class inherits from the abstract class abstract_publish_proxy.rb (lib/labwiki/plan_text/)

## Configuration

To specify of which class the abstract class has to initialize an instance from,
the user has to specify the class in the config file. Example:

	plugin:
	  plan_text:
	      publish:
	        require: 'labwiki/plugin/plan_text/respondCMSProxy'
         	class: 'LabWiki::Plugin::PlanText::RespondCMSProxy'

## RespondCMS

If you want to use the RespondCMS (respondcms.com) there is already a class provided that sends the data to the RespondCMS.
To use this class, you only have to specify some information in an extra config file (lib/labwiki/plan_text/respond.yaml):

	config:
	    respond: 'http://server.url/respond/api/'
	    email: 'test@email.com'
	    password: 'test'
	    sitename: 'testsite'

