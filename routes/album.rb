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
      r = item.select_attr(:id,:name)
      group = item.group
      if group.dummy
        r[:group_year] = group.year
      else
        r[:group_id] = group.id
      end
      r
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
