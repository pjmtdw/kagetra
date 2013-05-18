class MainApp < Sinatra::Base
  enable :sessions
  configure :development do
    register Sinatra::Reloader
  end
  register Sinatra::Namespace

  get '/' do
    shared_salt = MyConf.first(:name => "shared_password").value["salt"]
    haml :index, :locals => {:shared_salt => shared_salt}
  end
end
