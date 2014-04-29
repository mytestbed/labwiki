# Labwiki

## Overview

Visit http://labwiki.mytestbed.net for more information on this project.

## Installation

Labwiki is currently still under constant devlopment and it is therfore best to fetch the latest version
from Github.

    git clone https://github.com/mytestbed/labwiki.git
    cd labwiki
    export LABWIKI_TOP=`pwd`
    bundle install --path vendor
    rake post-install

If that fails you may need to install some required libraries. On a 'naked' Ubuntu system, we usually install the following:

    sudo apt-get install libpq-dev

## Getting Started

Most of Labwiki's functionality is provided by it's plugins. The core only includes plugins to view wiki pages
and edit code. See the section on plugins further down for more information on how to install and configure them.

But first, let's see if the core is working.

    $LABWIKI_TOP/bin/labwiki --lw-config etc/labwiki/labwiki.yaml --lw-no-login start

This will start a web server at port 4000. Point your browser there and you should see somthing like:

![Screenshot of starting page](https://raw.github.com/mytestbed/labwiki/master/doc/screenshot.png "Screenshot")

For additional options start the server with -h.

While there is little functionality in the core, you can display the raw markup text of the wiki page in the left column
by dragging the icon in the title block into the middle column. After dropping the icon, a code editor should appear. Please
note the 'Read-only' label in the title block. As it is read from a read-only repository, editing is blocked.

This [introductory video](http://labwiki.mytestbed.net) should provide you with some hints on the capabilities
of LabWiki provided through it's plugin system.

## Installing additional Plugins

Labwiki's functionality is primarily defined by it's external plugins. To install a new plugin, such as the OMF Experiment plugin do the
following:

    $LABWIKI_TOP/install_plugin https://github.com/mytestbed/labwiki_experiment_plugin.git

## Configuration

All the site specific configurations are captured in a YAML file which is provided at startup through
the '--lw-config' flag.

The structure of this file is as following:

    labwiki:
      session:
        repositories:
          - name: system
            type: file
            read_only: true
            top_dir: ../../system_repo
        default_plugins: # Show these plugins the first time a user logs in
          - column: plan
            plugin: 'wiki'
            action: "on_get_content"
            url: 'system:wiki/quickstart/quickstart.md'

      plugins:
        experiment:
          plugin_dir: labwiki_experiment_plugin
          job_service:
            host: localhost
            port: 8002


Currently, there are two sub sections defined under the top 'labwiki' node.

The 'session' section describes what should happen at the start of a session. In the above example, each
session is associated with a single, read-only repository from where assets are being fetched. LabWiki, through
'omf_web' supports multiple repository types, such as 'file', 'git', or 'irods'.

The above session section also defines what is going to be shown to the first time user (currently
it is shown on every login). In this particular case, a 'wiki' plugin is initialised for the 'plan' column showing
this README file.

The 'plugins' node holds additional configuration options for each of the plugins. The above
example defines the configuration options of the 'experiment' plugin. Check the documentation of each particular plugin
you use for how to configure it.
