# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  ALBUM_SEARCH_PER_PAGE = 50
  namespace '/api/album' do
    get '/year/:year' do
      year = if params[:year] == "_else_" then nil else params[:year] end
      groups = AlbumGroup.all(year:year, dummy:false).map{|x|x.select_attr(:id,:name,:start_at,:item_count).merge({type:"group"})}
      items = AlbumGroup.all(year:year, dummy:true).items.map{|x|x.select_attr(:id,:name,:date).merge({type:"item"})}

      {list:groups+items} 
    end
    get '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      r = group.select_attr(:name,:year,:place,:comment,:start_at,:end_at)
      tags = {}
      r[:items] = group.items(order:[:group_index.asc]).map{|x|
        if x.tag_names then
          JSON.parse(x.tag_names).each{|t|
            tags[t] ||= []
            tags[t] << x.id
          }
        end
        x.select_attr(:id,:name).merge({
          thumb: x.thumb.select_attr(:id,:width,:height)
        })
      }
      r[:tags] = tags.sort_by{|k,v|v.size}.reverse
      r[:deletable] = @user.admin or group.owner_id == @user.id
      r
    end
    delete '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      if group.nil?.! then
        AlbumItem.transaction{
          group.update!(deleted:true)
        }
      end
    end
    put '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      dm_response{
        AlbumGroup.transaction{
          @json["item_order"].each_with_index{|item,i|
            AlbumItem.get(item).update(group_index:i)
          }
          @json.delete("item_order")
          group.update(@json)
        }
      }
    end
    get '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      r = item.select_attr(:id,:name,:place,:date,:comment,:daily_choose,:comment_revision)
      r.merge!({photo:item.photo.select_attr(:id,:width,:height)})
      r[:group] = item.group.select_attr(:dummy,:year,:id,:name)
      r[:tags] = item.tags.map{|x|x.select_attr(:id,:name,:coord_x,:coord_y,:radius)}
      r[:relations] = item.relations.map{|x| x.select_attr(:id).merge({thumb:x.thumb.select_attr(:id,:width,:height)})}
      r[:deletable] = @user.admin or item.owner_id == @user.id
      r
    end
    put '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      dm_response{
        AlbumItem.transaction{
          if @json.has_key?("daily_choose") then
            @json["daily_choose"] = @json["daily_choose"].nil?.!
          end
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
          item.do_after_tag_updated
          (updates,updates_patch) = make_comment_log_patch(item,@json,"comment","comment_revision")
          if updates then @json.merge!(updates) end
          item.update(@json)
          if updates_patch
            item.comment_logs.create(updates_patch.merge({user:@user}))
          end
        }
      }
    end
    delete '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      if item.nil?.! then
        AlbumItem.transaction{
          ag = item.group
          item.update!(deleted:true)
          ag.update_count
        }
      end
    end
    get '/years' do
      aggr = AlbumGroup.aggregate(:item_count.sum, fields:[:year], unique: true, order: [:year.desc])
      total = aggr.map{|x|x[1]}.sum
      {list: aggr,total: total}
    end
    post '/search' do
      cond = {}
      qs = params[:qs]
      page = if params[:page] then params[:page].to_i else 1 end
      if /(?:^|\s)([0-9\-]+)(?:$|\s)/ =~ qs then
        qs = $` + " " + $'
        mt = $1
        (year_s,year_e) = nil
        if mt.end_with?("-") then
          year_s = mt.gsub("-","").to_i
        elsif mt.start_with?("-") then
          year_e = mt.gsub("-","").to_i
        elsif mt.include?("-") then
          (year_s,year_e) = mt.split("-")
        else
          (year_s,year_e) = [mt.to_i]*2
        end
        cond[:date.gte] = Date.new(year_s.to_i,1,1) unless year_s.nil?
        cond[:date.lt] = Date.new(year_e.to_i+1,1,1) unless year_e.nil?
      end
      qx = AlbumItem.all(id:-1) # 存在しないクエリ
      ss = qs.strip.split(/\s+/).map{|x| "%#{x}%" }
      [:name,:place,:comment,:tag_names].each{|sym|
        q = AlbumItem.all(cond)
        ss.each{|x|
          q &= AlbumItem.all(sym.like => x)
        }
        qx |= q
      }
      chunks = qx.all(order:[:date.desc]).chunks(ALBUM_SEARCH_PER_PAGE)
      list = chunks[page-1].map{|x|
        {id:x.id,thumb:x.thumb.select_attr(:id,:width,:height)}
      }
      {
        list: list,
        pages: chunks.size,
        cur_page: page
      }
    end
  end
  get '/album' do
    haml :album
  end
  namespace '/static/album' do
    get '/thumb/:id' do
      p = AlbumThumbnail.get(params[:id].to_i)
      send_file(File.join(CONF_HAGAKURE_BASE,"album",p.path))
    end
    get '/photo/:id' do
      p = AlbumPhoto.get(params[:id].to_i)
      send_file(File.join(CONF_HAGAKURE_BASE,"album",p.path))
    end
  end
end
