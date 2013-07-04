class MainApp < Sinatra::Base 
  namespace '/api/login_log' do
  end
  get '/login_log' do
    haml :login_log
  end
end
