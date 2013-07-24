
class MainApp < Sinatra::Base
  namespace '/api/user' do
    # /auth 以下はログインなしでも見られるように名前空間を分ける
    # TODO: 直接APIを叩かれるとユーザ一覧が取得できてしまう．共通パスワードを入れたユーザのみがユーザ一覧を見られるようにする
    namespace '/auth' do
      post '/shared' do
        hash = MyConf.first(name: "shared_password").value["hash"]
        Kagetra::Utils.check_password(params,hash)
      end
      get '/list/:initial' do
        row = params[:initial].to_i
        {list: User.all(order: [:furigana.asc], furigana_row: row, loginable: true).map{|x|
          [x.id,x.name]
        }}
      end
      post '/user' do
        uid = params[:user_id]
        user = User.first(id: uid)
        hash = user.password_hash 
        res = Kagetra::Utils.check_password(params,hash)
        if res[:result] == "OK" then
          user.update_login(request)
          exec_daily_job
          exec_monthly_job
          session[:user_id] = uid
          session[:user_token] = user.token
          set_permanent("uid",uid)
        end
        res
      end
      get '/salt/:id' do
        {salt: User.first(id: params[:id]).password_salt}
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
      up = {password_hash: params[:hash], password_salt: params[:salt]}
      if params[:uids]
        User.all(id:params[:uids].map{|x|x.to_i}).update(up)
      else
        @user.update(up)
      end
      {result:"OK"}
    end
    post '/change_shared_password' do
      up = {hash: params[:hash], salt: params[:salt]}
      MyConf.first(name: "shared_password").update(value: up)
      {result:"OK"}
    end

    get '/newly_message' do
      new_events = Event.new_events(@user).map{|x|x.select_attr(:name,:id)}
      participants = Event.new_participants(@user)
      {
        last_login: @user.last_login_str,
        log_mon: @user.log_mon_count,
        wiki: WikiItem.new_threads(@user).map{|x|x.select_attr(:title,:id)},
        event_comment: Event.new_threads(@user,{done:false}).map{|x|x.select_attr(:name,:id)},
        result_comment: Event.new_threads(@user,{done:true,kind: :contest}).map{|x|x.select_attr(:name,:id)},
        ev_done_comment: Event.new_threads(@user,{done:true,:kind.not=>:contest}).map{|x|x.select_attr(:name,:id)},
        bbs: BbsThread.new_threads(@user).map{|x|x.select_attr(:title,:id)},
        new_events: new_events,
        participants: participants
      }
    end
    delete '/delete_users' do
      User.all(id:@json["uids"].map{|x|x.to_i}).update!(deleted:true)
    end
    post '/create_users' do
      User.transaction{
        @json["list"].each{|x|
          u = User.create(name:x["name"],furigana:x["furigana"])
          # 同名のユーザがあったらuser_idを関連付ける
          EventUserChoice.all(user_name:u.name,user_id:nil).update(user_id:u.id)
          ContestUser.all(name:u.name,user_id:nil).update(user_id:u.id)
          x.each{|k,v|
            next unless k.start_with?("attr_")
            u.attrs.create(value_id:v)
          }
        }
      }
    end
  end
  get '/user/logout' do
    @user.change_token!
    @user.save

    session.clear
    redirect '/'
  end
end
