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
  local t1="$DB_FROM.$1"
  local t2="$DB_TO.$2"
  echo "DELETE FROM $t1 WHERE id IN (SELECT id FROM (SELECT $t1.id FROM $t1 LEFT JOIN $t2 ON $t1.$3 = $t2.id WHERE $t2.id IS NULL) AS delete_task);"
}
echo 'BEGIN;'
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
p event_choices
p event_comments
p event_user_choices
p bbs_threads
p bbs_items "$(c bbs_items is_first),0 as is_first"
echo "UPDATE ${DB_TO}.bbs_items SET is_first = 1 WHERE id in (SELECT first_item_id FROM ${DB_FROM}.bbs_threads);"
echo 'COMMIT;'
