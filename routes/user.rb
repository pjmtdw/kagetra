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
    namespace '/auth' do
      before do
        @user = if settings.development? and ENV.has_key?("KAGETRA_USER_ID")
                then User.first(id: ENV["KAGETRA_USER_ID"])
                else get_user
                end
      end
      get '/init' do
        shared = MyConf.first(name: "shared_password")
        halt 403, "Shared Password Unavailable." unless shared
        uid = get_permanent("uid")

        user = User[uid.to_i]
        (login_uid,login_uname) =
          if uid.nil? or user.nil? then
            nil
          else
            [uid,user.name]
          end
        {
          shared: session[:shared],
          login_uid: login_uid,
          login_uname: login_uname,
          user: (@user and {
            name: @user.name
          }),
        }
      end
      post '/shared' do
        if not request.cookies.has_key?(G_SESSION_COOKIE_NAME) then
          # ブラウザがセッションを受け付けてない場合はCOOKIE_BLOCKEDを返す
          # 最初に/にアクセスしたときにSinatraが{"session_id"=>"...","csrf"=>"..."}みたいなセッションをデフォルトで作るので
          # このAPIが呼ばれた時点で既にセッションは存在していてCookieとして送られてくるはず．
          # 既にセッションが存在している時にブラウザの設定変更で「これ以降のCookieの受付をブロック」みたいなことをされるとお手上げだが，
          # そのようなケースは稀で，セッションのCookieはブラウザを閉じると消えるので妥協する．
          halt_wrap 401, "クッキーを有効にしてください"
        end
        shared = MyConf.first(name: "shared_password")
        if @json['password'] and Kagetra::Utils.hash_password(@json['password'], shared.value["salt"])[:hash] == shared.value["hash"]
          session[:shared] = true # 共通パスワード認証成功
          200
        else
          halt 401, { updated_at: shared.updated_at }
        end
      end
      get '/search' do
        # 共通パスワードを入れていない場合401
        if not session[:shared] and not session[:user_id]
          halt 401
        end
        query1 = "#{params['q']}%"
        users1 = User.select(:id, :name)
                     .where(Sequel.like(:name, query1) | Sequel.like(:furigana, query1))
                     .where(loginable: true)
                     .order(Sequel.asc(:furigana))
                     .map{|u| { id: u.id, name: u.name }}
        query2 = "%#{params['q']}%"
        users2 = User.select(:id, :name)
                     .where((Sequel.like(:name, query2) | Sequel.like(:furigana, query2)) & ~(Sequel.like(:name, query1) | Sequel.like(:furigana, query1)))
                     .where(loginable: true)
                     .order(Sequel.asc(:furigana))
                     .map{|u| { id: u.id, name: u.name }}
        users1 + users2
      end
      post '/user' do
        if not request.cookies.has_key?(G_SESSION_COOKIE_NAME) then
          halt_wrap 401, "クッキーを有効にしてください"
        end
        user = User[@json['id'].to_i]
        if user.loginable then
          if @json['password'] and Kagetra::Utils.hash_password(@json['password'], user.password_salt)[:hash] == user.password_hash
            login_jobs(user)
            return 200, { user: { name: user.name } }
          else
            halt_wrap 401, 'ログインに失敗しました'
          end
        else
          halt_wrap 401, "ログイン権限がありません"
        end
      end
    end
    get '/logout' do
      session.clear
    end
    post '/confirm_password' do
      hash = @user.password_hash
      Kagetra::Utils.check_password(@json['msg'], @json['hash'], hash)
    end
    post '/change_password' do
      with_update{
        up = {password_hash: @json['hash'], password_salt: @json['salt']}
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
      today_contests = Event.today_contests.map{|x|x.select_attr(:name,:id)}
      participants = Event.new_participants(@user)
      {
        last_login: @user.last_login_data,
        log_mon: @user.log_mon_count,
        wiki: WikiItem.new_threads(@user).map{|x|x.select_attr(:title,:id)},
        event_comment: Event.new_threads(@user,{done:false}).map{|x|x.select_attr(:name,:id)},
        result_comment: Event.new_threads(@user,{done:true,kind:Event.kind__contest}).map{|x|x.select_attr(:name,:id)},
        ev_done_comment: Event.new_threads(@user,Sequel.expr(done:true) & Sequel.~(kind:Event.kind__contest)).map{|x|x.select_attr(:name,:id)},
        bbs: BbsThread.new_threads(@user).each_page(BBS_THREADS_PER_PAGE).with_index(1).to_a.map{|xs,i|xs.map{|x|x.select_attr(:title,:id).merge(page:i)}}.flatten,
        new_events: new_events,
        today_contests: today_contests,
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
      # TODO: これがないとstatus codeがおかしくなる
      200
    end
    post '/relogin' do
      login_jobs(@user)
    end
  end
end
