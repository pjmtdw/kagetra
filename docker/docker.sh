#!/bin/bash
function usage() {
  cat <<EOF
USAGE:
  $(basename $0) COMMAND [<options>]

COMMANDS:
  build [-d]
  run [-d] [-p port]
  exec
EOF
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

readonly ROOT_PATH=$(cd $(dirname $0)/.. && pwd)
# Parse
COMMAND=$1
PORT=7777
FLAG_D=false
shift
for OPT in $@; do
  case $OPT in
  -d)
    FLAG_D=true
    shift
    ;;
  -p)
    if [ -z $2 ]; then
      usage
    fi
    PORT=$2
    shift 2
    ;;
  *)
    usage
    ;;
  esac
done

case $COMMAND in
build)
  if $FLAG_D; then
    docker build -t kgtr-dev -f $ROOT_PATH/docker/dev.Dockerfile $ROOT_PATH/docker
  else
    docker build -t kgtr-img -f $ROOT_PATH/docker/Dockerfile $ROOT_PATH/docker
  fi
  ;;
run)
  if $FLAG_D; then
    docker run --name kgtr -p $PORT:1530 -v $ROOT_PATH:/home/kagetra/kagetra:cached -it kgtr-dev
  else
    docker run --name kgtr -p $PORT:1530 -it kgtr-img
  fi
  ;;
exec)
  if ! docker ps --format "{{.Names}}" | grep -e "^kgtr$"; then
    docker start kgtr
  fi
  docker exec -u kagetra -it kgtr bash
  ;;
*)
  usage
  ;;
esac
