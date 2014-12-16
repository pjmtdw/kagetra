#!/usr/bin/env bash
# register this script to cron if you want to do pg_dump periodically
# example: 0 3 * * 1 /path/to/kagetra/scripts/with_rbenv.sh ./periodic_dbdump.sh
SIZE_LIMIT="1024" # in megabytes
ROOTDIR="$(dirname $(readlink -f $0))/../"
cd "$ROOTDIR"

if ! [ "$CONF_DUMP_DIR" ];then
  echo "CONF_DUMP_DIR is empty. check conf.rb"
  exit 1
fi

DUMPDIR="${ROOTDIR}/${CONF_DUMP_DIR}"
mkdir -p "$DUMPDIR"
DUMPFILE=$(date +'pgdump_%F_%H%M%S')

PGPASSWORD="$CONF_DB_PASSWORD"  pg_dump \
  --username="$CONF_DB_USERNAME" \
  --host="$CONF_DB_HOST" \
  --port="$CONF_DB_PORT" \
  --dbname="$CONF_DB_DATABASE" \
  -Fc \
  -f "$DUMPDIR"/"$DUMPFILE"

while [ "$(du -sm "$DUMPDIR" | cut -f 1)" -gt $SIZE_LIMIT ];do
  fn=$(ls -tr "$DUMPDIR"/pgdump_* | head -n 1)
  [ "$fn" ] || break
  rm "$fn" || break
done
