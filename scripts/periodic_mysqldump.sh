#!/usr/bin/env bash
# register this script to cron if you want to do mysqldump periodically
# example: 0 3 * * 1 /path/to/kagetra/scripts/with_rbenv.sh ./periodic_mysqldump.sh
SIZE_LIMIT="1024" # in megabytes
ROOTDIR="$(dirname $(readlink -f $0))/../"
cd "$ROOTDIR"
source <(ruby -e 'require "./conf";require "./inits/utils"; Kagetra::Utils.conf_export_to_bash')

DUMPDIR="${ROOTDIR}/${CONF_DUMP_DIR}"

mkdir -p "$DUMPDIR"
prefix=$(date +'dump_%F_%H%M%S')
mysqldump -u "$CONF_DB_USERNAME" --password="$CONF_DB_PASSWORD" --host="$CONF_DB_HOST" --port="$CONF_DB_PORT" "$CONF_DB_DATABASE" |\
 gzip > "$DUMPDIR"/"$prefix".gz 

while [ "$(du -sm "$DUMPDIR" | cut -f 1)" -gt $SIZE_LIMIT ];do
  fn=$(ls -tr "$DUMPDIR"/dump_*.gz | head -n 1)
  [ "$fn" ] || break
  rm "$fn" || break
done
