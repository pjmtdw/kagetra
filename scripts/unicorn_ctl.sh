#!/usr/bin/env bash
if [ $# -eq 0 ];then
  echo "USAGE: $0 [start|stop]"
  exit
fi

PIDFILE="deploy/pid/unicorn.pid"
cd "$(dirname $(readlink -f "$0"))"/..

case "$1" in
start)
  if [ -e "$PIDFILE" ];then
    echo "$PIDFILE found. maybe unicorn is already running"
    exit
  fi
  bundle exec unicorn -E production -c deploy/unicorn.rb -D && echo "unicorn started"
  ;;
stop)
  if ! [ -e "$PIDFILE" ];then
    echo "$PIDFILE not found. maybe unicorn is not running"
    exit
  fi
  pid=$(cat "$PIDFILE")
  echo "killing pid=$pid"
  kill $pid
  ;;
esac
