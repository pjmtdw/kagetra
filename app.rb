class MainApp < Sinatra::Base
  helpers Sinatra::ContentFor
  enable :sessions
  # ENV['RACK_SESSION_SECRET'] is set by unicorn.rb
  set :session_secret, 
    ((if defined?(CONF_SESSION_SECRET) then CONF_SESSION_SECRET end) or ENV["RACK_SESSION_SECRET"] or SecureRandom.base64(48)) 

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
      if request.content_type == "application/json" then
        @json = JSON.parse(request.body.read)
      end
    end
    after do
      response.body = response.body.to_json
    end
  end
end
