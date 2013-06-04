class MainApp < Sinatra::Base
  get '/' do
    shared_salt = MyConf.first(name: "shared_password").value["salt"]
    haml :index, locals: {shared_salt: shared_salt}
  end
  get '/top' do
    user = get_user
    haml :top, locals: {user: user}
  end
end
