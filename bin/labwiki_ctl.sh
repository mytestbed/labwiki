#!/bin/sh

PORT=80

SBIN_DIR="$( cd "$( dirname "$0" )" && pwd )"
TOP_DIR=$SBIN_DIR/..

cd $TOP_DIR
ruby -rubygems -I lib labwiki.rb -e production -p $PORT -l /tmp/labwiki.log -P /tmp/labwiki.pid -d $*