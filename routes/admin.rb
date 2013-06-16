# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  THREADS_PER_PAGE = 10
  namespace '/api/admin' do
    get '/list' do
      User.all.map{|x|
        x.select_attr(:id,:name,:furigana)
      }
    end
    post '/permission' do
      case @json["type"]
      when "admin","loginable" then
        change_admin_or_loginable(@json)
      else
        change_permission(@json)
      end
    end

    def change_admin_or_loginable(json)
      v = (json["mode"] == "add")
      sym = json["type"].to_sym
      users = User.all(id: json["uids"]).update(sym => v)
    end
    def change_permission(json)
      is_add = (json["mode"] == "add")
      sym = json["type"].to_sym
      users = User.all(id: json["uids"])
      users.each{|u|
        np = if is_add then
          u.permission + [sym]
        else
          u.permission.reject{|x|x==sym}
        end
        u.update(permission: np)
      }
    end
  end
  get '/admin' do
    user = get_user
    haml :admin,{locals: {user: user}}
  end
end
