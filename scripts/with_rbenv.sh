#!/bin/bash
# use this when executing in cron job
if ! [ "$PATH" ];then
  # some crons does not set PATH?
  PATH="/bin:/usr/bin"
fi
if ! [ "$HOME" ];then
  # some crons does not set HOME?
  echo '$HOME is empty!'
  exit 1
fi
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
ROOTDIR="$(dirname $(readlink -f $0))"
cd $ROOTDIR
"$@"
