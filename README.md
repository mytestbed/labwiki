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
    ruby1.9 -I lib -I $OMF_WEB_TOP/lib -rubygems lib/labwiki.rb start
    
This will start a web server at port 4000. Point your browser there and you should see somthing like:

![Screenshot of starting page](https://raw.github.com/mytestbed/labwiki/master/doc/screenshot.png "Screenshot")

For additional options start the server with -h.

The introductory video at http://labwiki.mytestbed.net should provide you with some hints on how to proceed. Obviously, 
more (any) documentation would be even better.

