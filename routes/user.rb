
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
      p params[:id]
      {salt: User.first(id: params[:id]).password_salt}
    end
    post '/auth_shared' do
      hash = MyConf.first(name: "shared_password").value["hash"]
      # TODO: msg must be something hard to be counterfeited
      #   e.g. random string generated and stored to server, ip address
      msg = params[:msg]
      trial_hash = params[:hash]
      correct_hash = Kagetra::Utils.hmac_password(hash,msg)
      res = if trial_hash == correct_hash then "OK" else "FAIL" end
      {result: res}
    end
  end
  get '/user/logout' do
    get_user.update_token!
    session.clear
    redirect '/'
  end
end
