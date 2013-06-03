class MainApp < Sinatra::Base
  get '/top' do
    user = get_user
    haml :top, locals: {user: user}
  end
end
