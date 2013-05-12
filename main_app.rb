require 'sinatra'
class MainApp < Sinatra::Base
  enable :sessions
  get '/' do
    if not session.has_key?(:count) then
      session[:count] = 0
    else
      session[:count] += 1
    end
    count = session[:count]
    haml :index, :locals => {:count => count}
  end
end
