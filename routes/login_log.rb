class MainApp < Sinatra::Base 
  namespace '/api/login_log' do
  end
  get '/login_log' do
    user = get_user
    haml :login_log,{locals: {user: user}}
  end
end
