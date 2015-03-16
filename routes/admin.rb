# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/admin' do
    before do
      halt 403 unless @user.admin
    end
    get '/list' do
      user_attrs = Hash[
        UserAttribute.all
        .group_by(&:user_id).map{|xs|[xs[0],xs[1].map(&:value_id)]}]
      attr_values = Hash[UserAttributeValue.map{|x| [x.id, x.select_attr(:index,:value,:default).merge({key_id:x.attr_key_id})]}]
      key_names = UserAttributeKey.order(Sequel.asc(:index)).map{|x|[x.id,x.name]}
      
      key_values = Hash[UserAttributeKey.map{|x|[x.id,x.attr_values_dataset.map(&:id)]}]

      values_indexes = UserAttributeValue.join(UserAttributeKey,id: :attr_key_id).select(:user_attribute_keys__index,:user_attribute_values__id).to_hash(:id,:index)

      login_latests = Hash[UserLoginLatest.map{|x|
        [x.user_id,x.updated_at.to_date]
      }]
      fields = [:id,:name,:furigana,:admin,:loginable,:permission]
      list = User.order(Sequel.asc(:furigana)).map{|u|
        r = u.select_attr(*fields)
        r[:login_latest] = login_latests[u.id]
        a = user_attrs[u.id].sort_by{|x|values_indexes[x]} if user_attrs[u.id]
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
      with_update{
          is_add = (@json["mode"] == "add")
          sym = @json["type"].to_sym
          users = User.where(id: @json["uids"])
          case @json["type"]
          when "admin","loginable" then
            change_admin_or_loginable(is_add,sym,users)
          else
            change_permission(is_add,sym,users)
          end
      }
      {}
    end

    post '/change_attr' do
      users = User.where(id: @json["uids"])
      with_update{
        # UserAttribute.after_save の中で一つの属性valueしか持たないことを保証してくれてるからcreateするだけでいい
        # TODO: updateするとかじゃなくてcreateするだけで良いというのは仕様上分かりにくいのでどうにかする
        users.map{|u|UserAttribute.create(user:u,value_id:@json["value"].to_i)}
      }
      {}
    end
    post '/apply_edit' do
      with_update{
        @json.each{|x|
          u = User[x["uid"].to_i]
          case x["type"]
          when "attr"
            UserAttribute.create(user:u,value_id:x["new_val"].to_i)
          when "furigana"
            u.update(furigana:x["new_val"])
          when "name"
            u.update(name:x["new_val"])
          end
        }
      }
    end

    post '/update_attr' do
      with_update{
        created_keys = []
        @json["list"].to_enum.with_index(1){|x,index|
          k = nil
          if x["key_id"] == "new" then
            next if x["deleted"]
            if not x["list"].empty? then
              k = UserAttributeKey.create(name:x["name"],index:index)
              created_keys << k
            end
          else
            k = UserAttributeKey[x["key_id"]]
            if x["deleted"] then
              k.destroy
              next
            end
          end
          next if k.nil?
          k.update(index:index)
          x["list"].each_with_index{|y,i|
            if y["value_id"] == "new" then
              next if y["deleted"]
              c = UserAttributeValue.create(attr_key:k,value:y["value"],index:i,default:y["default"])
            elsif y["deleted"] then
              next if y["default"]
              default_id = k.attr_values_dataset.where(default:true).first.id
              # 削除する属性を持つユーザの値はデフォルト値に変更する
              UserAttribute.where(value_id:y["value_id"]).each{|x|
                x.update!(value_id:default_id)
              }
              k.attr_values_dataset[y["value_id"]].destroy
            else
              k.attr_values_dataset[y["value_id"]].update(index:i,default:y["default"])
            end
          }
        }
        created_keys.each{|k|
          d = k.attr_values_dataset.first(default:true)
          User.each{|u|
            UserAttribute.create(user:u,value:d)
          }
        }
      }
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
    get '/attrs' do
      list = UserAttributeKey.order(Sequel.asc(:index)).where{index >= 1}.map{|x|
        x.select_attr(:id,:name).merge({
          values: x.attr_values_dataset.order(Sequel.asc(:index)).map{|v|
            v.select_attr(:id,:value,:default)
          }
        })
      }
      {list:list}
    end
  end
  get '/admin', auth: :admin do
    @new_salt = Kagetra::Utils.gen_salt
    haml :admin
  end
  get '/admin_config',auth: :admin do
    @cur_shared_salt = MyConf.first(name: "shared_password").value["salt"]
    @new_shared_salt = Kagetra::Utils.gen_salt
    haml :admin_config
  end
  get '/admin_attr',auth: :admin do
    haml :admin_attr
  end
end
