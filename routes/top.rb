class MainApp < Sinatra::Base
  get '/top' do
    if not session.has_key?(:count) then
      session[:count] = 0
    else
      session[:count] += 1
    end
    count = session[:count]
    user = get_user
    haml :top, locals: {count: count, user: user}
  end
end
