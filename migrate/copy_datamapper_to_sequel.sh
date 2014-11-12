#!/bin/bash
DB_FROM="test"
DB_TO="test2"
DB_USER="root"
DB_PASSWORD="hogefuga"
function m(){
  mysql -NB -p${DB_PASSWORD} -u ${DB_USER}
}
function c(){
  m <<< "SHOW COLUMNS FROM $DB_TO.$1" | cut -f 1 | grep -v "^${2}$" | sed -e 's/\(.*\)/`\1`/' | tr '\n' ',' | sed -e 's/,$//'
}
function p(){
  if [ "$2" ];then
    local t="$2"
  else
    local t="$(c $1)"
  fi
  echo "INSERT INTO $DB_TO.$1 SELECT $t FROM $DB_FROM.$1;"
}
function d(){
  # delete rows which does not match constraint
  local t1="$DB_FROM.$1"
  local t2="$DB_TO.$2"
  echo "DELETE FROM $t1 WHERE id IN (SELECT id FROM (SELECT $t1.id FROM $t1 LEFT JOIN $t2 ON $t1.$3 = $t2.id WHERE $t2.id IS NULL) AS delete_task);"
}
function x(){
  local t1="$DB_FROM.$1"
  echo "DELETE FROM $t1 WHERE deleted = 1;"
}

exec 1> >(tee >(m) >&2)
echo 'BEGIN;'
x addr_books
x album_groups
x album_items
x bbs_threads
x event_comments
x events
x users
x wiki_attached_files
x wiki_comments
x wiki_items
p my_confs
p users
p user_attribute_keys
p user_attribute_values
d user_attributes users user_id
p user_attributes
d user_login_latests users user_id
p user_login_latests 
p user_login_logs
d user_login_monthlies users user_id
p user_login_monthlies
p event_groups
p events
d event_choices events event_id
p event_choices
p event_comments
d event_user_choices event_choices event_choice_id
p event_user_choices
p bbs_threads
d bbs_items bbs_threads thread_id
p bbs_items "$(c bbs_items is_first),0 as is_first"
p schedule_date_infos
p schedule_items
p album_groups
p album_group_events
d album_items album_groups group_id
p album_items
d album_relations album_items target_id
p album_relations
d album_comment_logs album_items album_item_id
p album_comment_logs
d album_tags album_items album_item_id
p album_tags
p album_photos
p album_thumbnails
echo "UPDATE ${DB_TO}.bbs_items SET is_first = 1 WHERE id in (SELECT first_item_id FROM ${DB_FROM}.bbs_threads);"
echo 'COMMIT;'
# wait for mysql to finish
MYSQL_PID=$(lsof -d 1 | grep '^[m]ysql' | awk '{print $2}')
while kill -0 $MYSQL_PID &>/dev/null; do
  sleep 1
done
