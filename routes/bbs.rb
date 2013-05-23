class MainApp < Sinatra::Base
  get '/bbs' do
    haml :bbs
  end
end
