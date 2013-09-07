
class MainApp < Sinatra::Base
  namespace '/api/user_conf' do
    get '/etc' do
      {bbs_public_name:@user.bbs_public_name}
    end
    post '/etc' do
      @user.update(bbs_public_name:@json["bbs_public_name"])
    end
  end
  get '/user_conf' do
    haml :user_conf
  end
end
