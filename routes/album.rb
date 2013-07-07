# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/album' do
    get '/year/:year' do
      year = if params[:year] == "_else_" then nil else params[:year] end
      groups = AlbumGroup.all(year:year, dummy:false).map{|x|x.select_attr(:id,:name,:start_at,:item_count).merge({type:"group"})}
      items = AlbumGroup.all(year:year, dummy:true).items.map{|x|x.select_attr(:id,:name,:date).merge({type:"item"})}

      {list:groups+items} 
    end
    get '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      r = group.select_attr(:name,:year)
      r[:items] = group.items.map{|x|
        x.select_attr(:id,:name).merge({
          thumb: x.thumb
        })
      }
      r
    end
    get '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      r = item.select_attr(:id,:name,:place,:date,:comment)
      r.merge!(item.photo.select_attr(:width,:height))
      group = item.group
      if group.dummy
        r[:group_year] = group.year
      else
        r[:group_id] = group.id
      end
      r[:tags] = item.tags.map{|x|x.select_attr(:id,:name,:coord_x,:coord_y,:radius)}
      r
    end
    put '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      dm_response{
        AlbumItem.transaction{
          if @json.has_key?("tag_edit_log")
            @json["tag_edit_log"].each{|k,v|
              (cmd,obj) = v
              case cmd
              when "update_or_create"
                if k.to_i < 0 then
                  obj.delete("id")
                  obj["album_item_id"] = item.id
                  AlbumTag.create(obj)
                else
                  AlbumTag.update(obj)
                end
              when "destroy"
                if k.to_i >= 0 then
                  t = AlbumTag.get(k.to_i)
                  if t.nil?.! then
                    t.destroy()
                  end
                end
              end
            }
            @json.delete("tag_edit_log")
          end
          item.update(@json)
        }
      }
    end
    get '/years' do
      {list: AlbumGroup.aggregate(:item_count.sum, fields:[:year], unique: true, order: [:year.desc])}
    end
  end
  get '/album' do
    haml :album
  end
  namespace '/static/album' do
    get '/thumb/:id' do
      p = AlbumItem.get(params[:id].to_i).thumb
      send_file(File.join(CONF_HAGAKURE_BASE,"album",p.path))

    end
    get '/photo/:id' do
      p = AlbumItem.get(params[:id].to_i).photo
      send_file(File.join(CONF_HAGAKURE_BASE,"album",p.path))
    end
  end
end
