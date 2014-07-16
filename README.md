# Labwiki

## Overview

Visit http://labwiki.mytestbed.net for more information on this project.

## Installation

Labwiki is currently still under constant devlopement and it is therefore best to fetch the latest version from Github.

    git clone https://github.com/mytestbed/labwiki.git
    cd labwiki
    export LABWIKI_TOP=`pwd`

    bundle install --path vendor

    rake post-install

If that fails you may need to install some required libraries. On a 'naked' Ubuntu system, we usually install the following:

    sudo apt-get install libpq-dev
    sudo apt-get install libicu-dev

If there are any additional issues, please also refer to the README for 'omf_web'.

## Getting Started

Most of Labwiki's functionality is provided by it's plugins. The core only includes plugins to view wiki pages
and edit code. See the section on plugins further down for more information on how to install and configure them.

But first, let's see if the core is working.

    $LABWIKI_TOP/bin/labwiki --lw-config etc/labwiki/first_test.yaml --lw-no-login start

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

If you need to install a sepcific version other than latest master, provide optional branch/tag name

    $LABWIKI_TOP/install_plugin https://github.com/mytestbed/labwiki_experiment_plugin.git some_other_branch_or_tag

## Upgrade & Redeployment

You probably noticed that we run everything from the source, so for re-deployment, simply go to each relative repository directory, update the repo by:

    cd <code repository>

Assuming that you have some local changes in the repository directory

    git stash

Assuming your origin is set to official LabWiki reposoitory

    git fetch origin

Assuming that you are in master branch and try to merge with master branch

    git merge origin/master

This will bring your previous local changes back

    git stash pop

Then re-run whatever you need to run.

_Because we run everything from the source, PLEASE report the git commit id whenever you need to report issues_

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
            top_dir: ../../system_repo # This is relative to config file location
        default_plugins: # Show these plugins the first time a user logs in
          - column: plan
            plugin: 'wiki'
            action: "on_get_content"
            url: 'system:wiki/quickstart/quickstart.md'

      plugins:
        experiment:
          plugin_dir: labwiki_experiment_plugin
          # Require job service setup & running
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

### Multi-user & Authentication

LabWiki will start without authentication by default, if multi-user is required, simply add a simple 'authentication' section to your config file:

    labwiki:
      session:
        authentication:
          type: openid
          provider: google


LabWiki has built in support for openid, with choice of providers: google or geni

#### Separate repository per user

A common multi-user set up for LabWiki would be to let each authenticated user having an empty repository for their own use, while all the users would share a single common repository where some default content and scripts locate. This can be achieved by specifying repository name dynamically using authenticated user's id.

For example:

https://github.com/mytestbed/labwiki/blob/master/etc/labwiki/multi_repos.yml

#### Customise additional authentication strategies

TBD
