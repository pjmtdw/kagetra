class MainApp < Sinatra::Base
  helpers Sinatra::ContentFor
  enable :sessions
  set :session_secret, (ENV["RACK_SESSION_SECRET"] || SecureRandom.hex(64)) # RACK_SESSION_SECRET is set by unicorn.rb

  configure :development do
    register Sinatra::Reloader
    get %r{/(.+)\.js$} do |m|
      content_type "application/javascript"
      js = "views/#{m}.js"
      pass if not File.exist?(js) # pass to Rack::Coffee
      File.read(js)
    end
  end
  register Sinatra::Namespace

  namespace '/api' do
    before do
      content_type :json
    end
    after do
      response.body = response.body.to_json
    end
  end
  get '/' do
    shared_salt = MyConf.first(name: "shared_password").value["salt"]
    haml :index, locals: {shared_salt: shared_salt}
  end
end
