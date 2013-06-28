class MainApp < Sinatra::Base 
  namespace '/api/login_log' do
  end
  get '/login_log' do
    user = get_user
    logger.warn "HOGE"
    raise Exception.new("FUGA")
    haml :login_log,{locals: {user: user}}
  end
end
