
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
        user.update_login(request)
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
      up = {password_hash: params[:hash], password_salt: params[:salt]}
      if params[:uids]
        User.all(id:params[:uids].map{|x|x.to_i}).update(up)
      else
        user = get_user
        user.update(up)
      end
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
