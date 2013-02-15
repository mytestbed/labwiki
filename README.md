# Labwiki

## Overview

Visit http://labwiki.mytestbed.net for more information on this project.

## Installation

Labwiki is built on top of [OMF Web](https://github.com/mytestbed/omf_web) and currently requires the latest
master of OMF Web. It is therefore best to first 
[install OMF Web](https://github.com/mytestbed/omf_web/blob/master/README.md). After that, proceed as following:

    git clone https://github.com/mytestbed/labwiki.git
    cd labwiki
    bundle
    rake install

## Try the simple example

First set OMF_WEB_TOP and LABWIKI_TOP to wherever you installed them, respectively.

    export OMF_WEB_TOP=...whereever.you.installed.omf.web
    export LABWIKI_TOP=...whereever.you.installed.labwiki
    
Then create a temporary git repo and populate it with some test data.

    git init /tmp/foo
    cp -r $LABWIKI_TOP/test/repo /tmp/foo
    cd /tmp/foo
    git add .
    git commit -m 'initial'
    
Finally start LabWiki.

    cd $LABWIKI_TOP
    ruby1.9 -I lib -I $OMF_WEB_TOP/lib lib/labwiki.rb --lw-config __your_config_file__.yaml start
    
The '__your_config_file__.yaml' needs to be replace with a path to a file describing the local setup. A sample 
of such a file can be found in 'test/config/norbit.yaml'. Please create your own one as this one will very likely 
NOT work in yoru environment.
    
This will start a web server at port 4000. Point your browser there and you should see somthing like:

![Screenshot of starting page](https://raw.github.com/mytestbed/labwiki/master/doc/screenshot.png "Screenshot")

For additional options start the server with -h.

The introductory video at http://labwiki.mytestbed.net should provide you with some hints on how to proceed. Obviously, 
more (any) documentation would be even better.

## Configuration

All the site specific configurations are captured in a YAML file which is provided at startup through
the '--lw-config' flag.

The structure of this file is as following:

    labwiki:
      repositories:
        foo: /tmp/foo
      plugins:
        experiment:
          ec_runner: __LABWIKI_TOP__/test/omf_exec/omf_exec-norbit.sh
          oml:
            host: norbit.npc.nicta.com.au
            user: oml2

Currently, there are two sub sections defined under the top 'labwiki' node.

The 'repositories' is currently just a placeholder and will get flashed out or even removed
when we add full multi-user support. Currently it expects the path to a single git repository 
with the hard-coded label 'foo'. See the 'try the simple example' section above for instructions.

The 'plugins' node holds additional configuration options for each of the plugins. The above
example declares options for the 'experiment' plugin. Please change '__LABWIKI_TOP__' to an absolute path
for your installation. The 'test/omf_exec/omf_exec-norbit.sh' is included, but will very likely not work
in your environemnt, but could be a template for something which may work.

 
