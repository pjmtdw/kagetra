
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
        {list: User.all(order: [:furigana.asc], furigana_row: row).map{|x|
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
  end
  get '/user/logout' do
    @user.change_token!
    @user.save

    session.clear
    redirect '/'
  end
end
