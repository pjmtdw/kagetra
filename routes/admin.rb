# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/admin' do
    get '/list' do
      # UserAttribute.all.map{|x|[x.user_id,x.value_id]} が遅いので手動でクエリする
      # TODO: 上記が遅い原因を探り, 手動クエリを使わない方法を見つける
      user_attrs = Hash[repository(:default).adapter
        .select('SELECT user_id, value_id FROM user_attributes')
        .group_by{|x| x[:user_id]}.map{|xs|[xs[0],xs[1].map{|x|x[:value_id]}]}]
      attr_values = Hash[UserAttributeValue.all
        .map{|x| [x.id, {index:x.index, value:x.value}]}]
      key_names = UserAttributeKey.all.map{|x|[x.id,x.name]}
      key_values = Hash[UserAttributeKey.all.map{|x|[x.id,x.values.map{|v|v.id}]}]

      list = User.all.map{|u|
        r = u.select_attr(:id,:name,:furigana)
        l = u.login_latest
        r[:login_latest] = l.updated_at.to_date if l
        a = user_attrs[u.id]
        r[:attrs] = a if a
        r
      }
      {
        key_names: key_names,
        attr_values: attr_values,
        key_values: key_values,
        list: list
      }
    end
    post '/permission' do
      is_add = (json["mode"] == "add")
      sym = json["type"].to_sym
      users = User.all(id: json["uids"])
      case @json["type"]
      when "admin","loginable" then
        change_admin_or_loginable(is_add,sym,users)
      else
        change_permission(is_add,sym,users)
      end
    end

    def change_admin_or_loginable(is_add,sym,users)
      users.update(sym => is_add)
    end

    def change_permission(is_add,sym,users)
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
