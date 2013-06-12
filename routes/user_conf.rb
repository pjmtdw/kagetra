
class MainApp < Sinatra::Base
  namespace '/api/user_conf' do
    get '/etc' do
      user = get_user
      {bbs_public_name:user.bbs_public_name}
    end
    post '/etc' do
      user = get_user
      user.update(bbs_public_name:@json["bbs_public_name"])
    end
  end
  get '/user_conf' do
    user = get_user
    cur_salt = user.password_salt
    new_salt = Kagetra::Utils.gen_salt
    haml :user_conf, locals:{user: user, cur_salt: cur_salt, new_salt: new_salt}
  end
end
