
class MainApp < Sinatra::Base
  namespace '/api/user_conf', auth: :user do
    get '/etc' do
      {bbs_public_name:@user.bbs_public_name}
    end
    post '/etc' do
      @user.update(bbs_public_name:@json["bbs_public_name"])
    end
  end
end
