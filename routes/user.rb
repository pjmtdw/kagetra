
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
      hash = User.first(id: uid).password_hash
      msg = params[:msg]
      trial_hash = params[:hash]
      correct_hash = Kagetra::Utils.hmac_password(hash,msg)
      res = if trial_hash == correct_hash then
        u = User.first(id: uid)
        u.update_token!
        session[:user_id] = uid
        session[:user_token] = u.token
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
    get_user.update_token!
    session.clear
    redirect '/'
  end
end
