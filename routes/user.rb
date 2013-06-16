
class MainApp < Sinatra::Base
  namespace '/api/user' do
    get '/list/:initial' do
      row = params[:initial].to_i
      {list: User.all(order: [:furigana.asc], furigana_row: row).map{|x|
        [x.id,x.name]
      }}
    end
    post '/auth_user' do
      uid = params[:user_id]
      user = User.first(id: uid)
      hash = user.password_hash
      msg = params[:msg]
      trial_hash = params[:hash]
      correct_hash = Kagetra::Utils.hmac_password(hash,msg)
      res = if trial_hash == correct_hash then
        User.transaction{
          latest = UserLoginLatest.first_or_new(user: user)

          user.change_token!
          user.show_new_from = latest.updated_at
          user.save

          latest.set_env(request)
          latest.touch
          latest.save

          log = user.login_log.new
          log.set_env(request)
          log.save

          dt = Date.today
          monthly = user.login_monthly.first_or_new(year:dt.year,month:dt.month)
          monthly.count += 1
          monthly.save
        }
        session[:user_id] = uid
        session[:user_token] = user.token
        "OK"
      else
        "FAIL"
      end
      {result: res}
    end
    get '/auth_salt/:id' do
      {salt: User.first(id: params[:id]).password_salt}
    end

    def check_password(params,hash)
      # TODO: msg must be something hard to be counterfeited
      #   e.g. random string generated and stored to server, ip address
      msg = params[:msg]
      trial_hash = params[:hash]
      correct_hash = Kagetra::Utils.hmac_password(hash,msg)
      res = if trial_hash == correct_hash then "OK" else "FAIL" end
      {result: res}
    end

    post '/auth_shared' do
      hash = MyConf.first(name: "shared_password").value["hash"]
      check_password(params,hash)
    end
    post '/confirm_password' do
      user = get_user
      hash = user.password_hash
      check_password(params,hash) 
    end
    post '/change_password' do
      user = get_user
      hash = params[:hash]
      salt = params[:salt]
      user.update(password_hash:hash, password_salt: salt)
      {result:"OK"}
    end
  end
  get '/user/logout' do
    user = get_user
    user.change_token!
    user.save

    session.clear
    redirect '/'
  end
end
