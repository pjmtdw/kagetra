class MainApp < Sinatra::Base
  helpers Sinatra::ContentFor
  enable :sessions, :logging
  # ENV['RACK_SESSION_SECRET'] is set by unicorn.rb
  set :session_secret, 
    ((if defined?(CONF_SESSION_SECRET) then CONF_SESSION_SECRET end) or ENV["RACK_SESSION_SECRET"] or SecureRandom.base64(48)) 
  
  # for Internet Explorer 8, 9 (and maybe also 10?) protection session hijacking refuses the session.
  # https://github.com/rkh/rack-protection/issues/11
  set :protection, except: :session_hijacking
  

 def logger
    env['mainapp.logger'] || env['rack.logger']
  end

  set :show_exceptions, :after_handler
  error do
    err = request.env['sinatra.error']
    logger.warn err.message
    logger.puts err.backtrace[0...12].join("\t\n")
    if settings.development?
      pass # fallback to default error page
    else
      halt response.status
    end
  end


  configure :development do
    register Sinatra::Reloader

    get %r{/(.+)\.js$} do |m|
      content_type "application/javascript"
      js = if m.start_with?("foundation") then
        "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/js/foundation/#{m}.js"
      else
        "views/#{m}.js"
      end
      pass if not File.exist?(js) # pass to Rack::Coffee
      send_file(js)
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
