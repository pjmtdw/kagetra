class MainApp < Sinatra::Base
  helpers Sinatra::ContentFor
  enable :sessions
  enable :logging, :dump_errors, :raise_errors
  # ENV['RACK_SESSION_SECRET'] is set by unicorn.rb
  set :session_secret, 
    ((if defined?(CONF_SESSION_SECRET) then CONF_SESSION_SECRET end) or ENV["RACK_SESSION_SECRET"] or SecureRandom.base64(48)) 
  
  # for Internet Explorer 8, 9 (and maybe also 10?) protection session hijacking refuses the session.
  # https://github.com/rkh/rack-protection/issues/11
  set :protection, except: :session_hijacking

  configure :development do
    register Sinatra::Reloader
    get %r{/(.+)\.js$} do |m|
      content_type "application/javascript"
      js = "views/#{m}.js"
      pass if not File.exist?(js) # pass to Rack::Coffee
      send_file(js)
    end
    $stdout.reopen("./deploy/log/develop.log","w")
    $stdout.sync = true
    $stderr.reopen($stdout)
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
