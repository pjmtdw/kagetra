#!/bin/bash

# you should do following commands to create index of name
#   create extension pg_trgm;
#   create index planet_osm_polygon_name_index on planet_osm_polygon using gist (name gist_trgm_ops);
#   create index planet_osm_point_name_index on planet_osm_point using gist (name gist_trgm_ops);
# or use pg_bigm if possible: http://pgbigm.sourceforge.jp/

DATA_VER="12.0a" # open http://nlftp.mlit.go.jp/isj/ and check the latest version
TARGET="data"
TABLE_NAME="japan_address"
COMMIT_BLOCK=2000

export PGUSER='postgres'
export PGDATABASE='osm'
export PGPASSWORD='postgres'

function download(){
  mkdir -p "$TARGET"
  for i in {01..47}; do
    fn="$i"000-"$DATA_VER".zip
    if ! [ -e "$TARGET"/"$fn" ]; then
      wget http://nlftp.mlit.go.jp/isj/dls/data/"$DATA_VER"/"$fn" -O "$TARGET"/"$fn"
      sleep 20 # take care of server to avoid BAN
    fi
    unzip -L -j -d "$TARGET" "$TARGET"/"$fn" '*.csv'
  done
}

function create_table(){
  echo "create table $TABLE_NAME ( id bigserial primary key, prefecture char(4), city varchar(16), oaza_chocho varchar(24), \
    number_major varchar(8), number_minor varchar(8), way geometry(Point,900913));"
  echo "create index ${TABLE_NAME}_point_index on $TABLE_NAME using gist(way);"
  echo "alter table planet_osm_point add column ${TABLE_NAME}_id bigint references ${TABLE_NAME} (id) on delete set null;"
  echo "alter table planet_osm_polygon add column ${TABLE_NAME}_id bigint references ${TABLE_NAME} (id) on delete set null;"
}

function insert_data(){
  COUNTER=1
  pre="insert into $TABLE_NAME (prefecture, city, oaza_chocho, number_major, way) values"
  for f in "$TARGET"/*.csv; do
    while IFS=',' read a b c d _ _ _ lat lng _; do
      if [ "$COUNTER" -eq 1 ];then
        echo -n "$pre"
      fi
      geo="ST_Transform(ST_GeometryFromText('POINT($lng $lat)',4326),900913)"
      if [ "$COUNTER" -ne 1 ];then
        echo -n ","
      fi
      echo -n "('$a','$b','$c','$d',$geo)"  
      if ((COUNTER++ % COMMIT_BLOCK == 0)); then
        echo ";"
        COUNTER=1
      fi
    done < <(nkf -w "$f" | tail -n +2 | tr -d '"')
  done
  if [ "$COUNTER" -ne 1 ];then
    echo ";"
  fi
}

function update_id(){
  typ="$1" # must be 'point' or 'polygon'
  max_id=$(echo "select max(osm_id) from planet_osm_${typ}" | psql -tA)
  min_id=$(echo "select min(osm_id) from planet_osm_${typ}" | psql -tA)
  increment=$(( (max_id - min_id) / 1000 ))
  for ((distance=1000;;distance*=2)) do
    for ((i=min_id; i<max_id; i+=increment)); do
      echo "update planet_osm_${typ} p set ${TABLE_NAME}_id = (select id from $TABLE_NAME a where ST_DWithin(a.way,p.way,$distance) order by ST_Distance(a.way,p.way) asc limit 1) \
        where name is not null and ${TABLE_NAME}_id is null and osm_id >= $i and osm_id < $((i+increment));"
    done | psql -tA
    rest=$(echo "select count(*) from planet_osm_${typ} where name is not null and ${TABLE_NAME}_id is null" | psql -tA)
    echo "distance=$distance done, rest=$rest"
    if [ "$rest" -eq 0 ];then
      break
    fi
  done
}

function drop_table(){
  echo "alter table planet_osm_point drop column ${TABLE_NAME}_id;"
  echo "alter table planet_osm_polygon drop column ${TABLE_NAME}_id;"
  echo "drop table $TABLE_NAME;"
}

case "$1" in
d)
  download;;
ct)
  create_table | psql;;
id)
  insert_data | psql;;
uia)
  update_id 'point';;
uib)
  update_id 'polygon';;
dt)
  drop_table | psql;;
*)
  echo "USAGE: $0 [d|ct|id|uia|uib|dt]"
  echo "  d .. download GIS data from MLIT"
  echo "  ct .. create table ${TABLE_NAME}, add column to planet_osm_{point,polygon}"
  echo "  id .. insert GIS data to ${TABLE_NAME}"
  echo "  uia .. update ${TABLE_NAME}_id of planet_osm_point"
  echo "  uib .. update ${TABLE_NAME}_id of planet_osm_polygon"
  echo "  dt .. drop table and columns"
esac

