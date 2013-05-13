class MainApp < Sinatra::Base
  helpers Kagetra::Helpers
  enable :sessions
  get '/user/initials' do
    content_type :json
    User.all.map{|x|x.furigana[0]}.uniq.sort.map{|x|
      [x.unpack("U*")[0],x]
    }.to_json
  end
  get '/user/list/:initial' do
    content_type :json
    word = [params[:initial].to_i].pack("U*")
    User.all(:order => [:furigana.asc], :furigana.like => "#{word}%").map{|x|
      [x.id,x.name]
    }.to_json

  end
  post '/user/auth' do
    content_type :json
    res = if params[:password] == "dummy" then
      u = User.first(:id => params[:user_id])
      u.update_token!
      session[:user_id] = params[:user_id]
      session[:user_token] = u.token
      "OK"
    else
      "FAIL"
    end
    {:result => res}.to_json
  end
  get '/top' do
    if not session.has_key?(:count) then
      session[:count] = 0
    else
      session[:count] += 1
    end
    count = session[:count]
    user = get_user
    haml :top, :locals => {:count => count, :page_title => "counter", :user => user}
  end
  get '/' do
    haml :index
  end
end
