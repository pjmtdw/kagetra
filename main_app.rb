class MainApp < Sinatra::Base
  enable :sessions
  helpers Kagetra::Helpers
  configure :development do
    register Sinatra::Reloader
  end
  register Sinatra::Namespace

  namespace '/user' do
    before do
      content_type :json
    end
    get '/list/:initial' do
      row = params[:initial].to_i
      User.all(:order => [:furigana.asc], :furigana_row => row).map{|x|
        [x.id,x.name]
      }.to_json

    end
    post '/auth' do
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
