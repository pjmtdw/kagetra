# -*- coding: utf-8 -*-
# 地図
class MainApp < Sinatra::Base
  namespace '/api/map' do
    get '/bookmark/list' do
      list = MapBookmark.order(Sequel.desc(:updated_at)).limit(20).map{|x|
        x.select_attr(:id,:title)
      }
      {list:list}
    end
    post '/bookmark/complement' do
      list = MapBookmark
        .where(Sequel.like(:title,"%#{params[:q]}%"))
        .order(Sequel.desc(:updated_at)).limit(20).map{|x|
        {id:x.id, text: x.title}
      }
      {results:list}
    end
    get '/bookmark/:id' do
      bmk = MapBookmark[params[:id]]
      bmk.select_attr(:title,:lat,:lng,:zoom,:markers)
    end

    delete '/bookmark/:id' do
      with_update{
        MapBookmark[params[:id]].destroy
      }
    end

    put '/bookmark/:id' do
      with_update{
        item = MapBookmark[params[:id]]
        @json.delete("id")
        item.update(@json)
      }
    end
    post '/bookmark' do
      with_update{
        m = MapBookmark.create(@json.merge(user_id:@user.id))
        m.select_attr(:id);
      }
    end
    post '/search' do
      halt(501,'CONF_DB_OSM_DATABASE is empty!') if DB_OSM.nil?
      LIMIT = 10
      lat = params[:lat]
      lng = params[:lng]
      order = "ST_Distance(way,ST_Transform(ST_GeometryFromText('POINT(#{lng} #{lat})',4326),900913))"
      queries = {}
      queries[:polygon] = "SELECT ST_AsGeoJSON(ST_Transform(ST_Centroid(way),4326)) AS json, name FROM planet_osm_polygon"
      queries[:point] = "SELECT ST_AsGeoJSON(ST_Transform(way,4326)) AS json, name FROM planet_osm_point"
      wheres = params[:q].split(/\s+/).map{|x| "name LIKE '%#{x}%'"}.join(" AND ")
      queries.keys.each{|k|
        queries[k] += " WHERE #{wheres} ORDER BY #{order} ASC LIMIT #{LIMIT}"
      }
      lst = queries.values.map{|v|
        DB_OSM.fetch(v).map{|x|
          j = JSON.parse(x[:json])
          coord = j["coordinates"]
          {
            latlng: {lat: coord[1], lng: coord[0]},
            text: x[:name]
          }
        }
      }.flatten
      { results: lst }
    end
  end
  get '/map' do
    haml :map
  end
end
