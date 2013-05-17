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
    after do
      response.body = response.body.to_json
    end
    get '/list/:initial' do
      row = params[:initial].to_i
      {:list => User.all(:order => [:furigana.asc], :furigana_row => row).map{|x|
        [x.id,x.name]
      }}
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
      {:result => res}
    end
    post '/auth_shared' do
      hash = MyConf.first(:name => "shared_password").value["hash"]
      rand = params[:rand]
      trial_hash = params[:hash]
      correct_hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), hash, rand)).gsub("\n","")
      res = if trial_hash == correct_hash then
              "OK"
            else
              "FAIL"
            end
      {:result => res}
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
    shared_salt = MyConf.first(:name => "shared_password").value["salt"]
    haml :index, :locals => {:shared_salt => shared_salt}
  end
end
