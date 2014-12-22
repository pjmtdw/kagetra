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
    get '/bookmark/:id' do
      bmk = MapBookmark[params[:id]]
      bmk.select_attr(:title,:lat,:lng,:zoom,:markers)
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
  end
  get '/map' do
    haml :map
  end
end
