#!/bin/bash

#OMF_HOME=$HOME/omf_6
OMF_HOME=$HOME/nicta/omf
CWD=$(dirname $0)
OML_PATH=bob

[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
rvm use ruby-1.9.3@omf

exec ruby -I $OMF_HOME/omf_common/lib -I $OMF_HOME/omf_ec/lib $OMF_HOME/omf_ec/bin/omf_ec \
  --uri xmpp://srv.mytestbed.net --log_config $CWD/etc/ec_6_log.rb exec --oml_uri $OML_PATH $*
