# Labwiki

## Overview

Visit http://labwiki.mytestbed.net for more information on this project.

## Installation

Labwiki is currently still under constant devlopment and it is therfore best to fetch the latest version
from Github.

    git clone https://github.com/mytestbed/labwiki.git
    cd labwiki
    bundle install --path vendor
    rake post-install

If that fails you may need to install some required libraries. On a 'naked' Ubuntu system, we usually install the following:

    sudo apt-get install libpq-dev

## Try the simple example

First set LABWIKI_TOP to wherever you installed them, respectively.

    export LABWIKI_TOP=...whereever.you.installed.labwiki

Then create a temporary git repo and populate it with some test data.

    mkdir -p ~/tmp/lw_repo
    git init ~/tmp/lw_repo
    cp -r $LABWIKI_TOP/test/repo ~/tmp/lw_repo
    pushd ~/tmp/lw_repo
    git add .
    git commit -m 'initial'

Finally start LabWiki.

    cd $LABWIKI_TOP
    bin/labwiki --lw-config etc/labwiki/local-test.yaml --lw-no-login start

The 'local-test.yaml' will ultimately need to be replace with a path to a file describing the local setup. A sample
of such a file can be found in 'etc/labwiki/norbit.yaml'.

This will start a web server at port 4000. Point your browser there and you should see somthing like:

![Screenshot of starting page](https://raw.github.com/mytestbed/labwiki/master/doc/screenshot.png "Screenshot")

For additional options start the server with -h.

The introductory video at http://labwiki.mytestbed.net should provide you with some hints on how to proceed. Obviously,
more (any) documentation would be even better.

## Installing additional Plugins

Labwiki's functionality is primarily defined by it's external plugins. To install a new plugin, such as the OMF Experiment plugin do the
following:

    $LABWIKI_TOP/install_plugin https://github.com/mytestbed/labwiki_experiment_plugin.git


## Configuration

All the site specific configurations are captured in a YAML file which is provided at startup through
the '--lw-config' flag.

The structure of this file is as following:

    labwiki:
      repositories:
        default:
          type: git
          top_dir: ~/tmp/foo
      plugins:
        experiment:
          plugin_dir: labwiki_experiment_plugin
          job_service:
            host: localhost
            port: 8003

Currently, there are two sub sections defined under the top 'labwiki' node.

The 'repositories' is currently just a placeholder and will get flashed out or even removed
when we add full multi-user support. Currently it expects the path to a single git repository
with the hard-coded label 'foo'. See the 'try the simple example' section above for instructions.

The 'plugins' node holds additional configuration options for each of the plugins. The above
example declares options for the 'experiment' plugin. Please change '__LABWIKI_TOP__' to an absolute path
for your installation. The 'test/omf_exec/omf_exec-norbit.sh' is included, but will very likely not work
in your environemnt, but could be a template for something which may work.


