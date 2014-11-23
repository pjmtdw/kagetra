# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/user' do
    def login_jobs(user)
      uid = user.id
      user.update_login(request)
      exec_daily_job
      exec_monthly_job
      session[:user_id] = uid
      session[:user_token] = user.token
      set_permanent("uid",uid)
    end
    # /auth 以下はログインなしでも見られるように名前空間を分ける
    # TODO: 直接APIを叩かれるとユーザ一覧が取得できてしまう．共通パスワードを入れたユーザのみがユーザ一覧を見られるようにする
    namespace '/auth' do
      post '/shared' do
        hash = MyConf.first(name: "shared_password").value["hash"]
        Kagetra::Utils.check_password(params,hash)
      end
      get '/list/:initial' do
        row = params[:initial].to_i
        {list: User.where(furigana_row: row, loginable: true).order(Sequel.asc(:furigana)).map{|x|
          [x.id,x.name]
        }}
      end
      # この認証方法はDBのpassword_hashが分かればパスワードを知らなくても誰でもログインできてしまう．
      # しかしそもそも攻撃者がDBを見られる時点であんまし認証とか意味ないので許容する
      # TODO: ちゃんとした認証方法に変える
      post '/user' do
        user = User[params[:user_id].to_i]
        if user.loginable then
          hash = user.password_hash
          Kagetra::Utils.check_password(params,hash).tap{|res|
            if res[:result] == "OK" then
              login_jobs(user)
            end
          }
        else
          {result: "NOT_LOGINABLE"}
        end
      end
      get '/salt/:id' do
        {salt: User[params[:id]].password_salt}
      end
    end
    get '/mysalt' do
      {
        salt_cur: @user.password_salt,
        salt_new: Kagetra::Utils.gen_salt
      }
    end
    get '/shared_salt' do
      {
        salt_cur: MyConf.first(name: "shared_password").value["salt"],
        salt_new: Kagetra::Utils.gen_salt
      }
    end
    post '/confirm_password' do
      hash = @user.password_hash
      Kagetra::Utils.check_password(params,hash)
    end
    post '/change_password' do
      with_update{
        up = {password_hash: params[:hash], password_salt: params[:salt]}
        if params[:uids]
          # TODO: 本当はユーザごとに salt を変えないといけない
          User.where(id:params[:uids].map(&:to_i)).each{|x|x.update(up)}
        else
          @user.update(up)
        end
        {result:"OK"}
      }
    end
    post '/change_shared_password' do
      with_update{
        up = {hash: params[:hash], salt: params[:salt]}
        MyConf.first(name: "shared_password").update(value: up)
        {result:"OK"}
      }
    end

    get '/newly_message' do
      new_events = Event.new_events(@user).map{|x|x.select_attr(:name,:id)}
      participants = Event.new_participants(@user)
      {
        last_login: @user.last_login_str,
        log_mon: @user.log_mon_count,
        wiki: WikiItem.new_threads(@user).map{|x|x.select_attr(:title,:id)},
        event_comment: Event.new_threads(@user,{done:false}).map{|x|x.select_attr(:name,:id)},
        result_comment: Event.new_threads(@user,{done:true,kind:Event.kind__contest}).map{|x|x.select_attr(:name,:id)},
        ev_done_comment: Event.new_threads(@user,Sequel.expr(done:true) & Sequel.~(kind:Event.kind__contest)).map{|x|x.select_attr(:name,:id)},
        bbs: BbsThread.new_threads(@user).each_page(BBS_THREADS_PER_PAGE).with_index(1).to_a.map{|xs,i|xs.map{|x|x.select_attr(:title,:id).merge(page:i)}}.flatten,
        new_events: new_events,
        participants: participants
      }
    end
    delete '/delete_users' do
      User.where(id:@json["uids"].map(&:to_i)).each(&:destroy)
    end
    post '/create_users' do
      with_update{
        shared = MyConf.first(name: "shared_password").value
        hash = shared["hash"]
        salt = shared["salt"]
        @json["list"].each{|x|
          u = User.create(name:x["name"],furigana:x["furigana"],password_hash:hash,password_salt:salt)
          # 同名のユーザがあったらuser_idを関連付ける
          EventUserChoice.where(user_name:u.name,user_id:nil).each{|x|x.update(user_id:u.id)}
          ContestUser.where(name:u.name,user_id:nil).each{|x|x.update(user_id:u.id)}
          x.each{|k,v|
            next unless k.start_with?("attr_")
            UserAttribute.create(user:u,value:UserAttributeValue[v.to_i])
          }
        }
      }
    end
    post '/change_attr/:promotion_event/:user_id' do
      with_update{
        u = User[params[:user_id].to_i]
        @json["values"].each{|v|
          new_value = UserAttributeValue[v.to_i]
          key = new_value.attr_key
          cur_value = u.attrs_dataset.first(value_id:key.attr_values.map(&:id)).value
          UserAttribute.create(user:u,value_id:v.to_i)
          EventUserChoice.where(event_choice:Event.where(done:false).map(&:choices).flatten,user:u,attr_value:cur_value).each{|choice|
            ev_choice = choice.event_choice
            ev = ev_choice.event
            promotion_event = Event[params[:promotion_event].to_i]
            if ev.forbidden_attrs.include?(v.to_i) then
              choice.destroy
              if ev_choice.positive then
                EventComment.create(thread:ev,user_name:"ロビタ",body:"#{u.name}さんが#{promotion_event.name}で昇級して参加不能属性になったので登録を取り消しました。")
              end
            else
              EventUserChoice.create(user:u,event_choice:ev_choice)
              if ev_choice.positive then
                EventComment.create(thread:ev,user_name:"ロビタ",body:"#{u.name}さんが#{promotion_event.name}で昇級したので#{cur_value.value}から#{new_value.value}に登録変更しました。")
              end
            end
          }
        }
      }
    end
    post '/relogin' do
      login_jobs(@user)
    end
  end
  get '/user/logout' do
    session.clear
    redirect '/'
  end
end
