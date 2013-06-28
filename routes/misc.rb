class MainApp < Sinatra::Base
  get '/' do
    shared = MyConf.first(name: "shared_password")
    halt 403, "Shared Password Unavailable." unless shared
    shared_salt = shared.value["salt"]
    haml :index, locals: {shared_salt: shared_salt}
  end
  get '/robots.txt' do
    content_type 'text/plain'
    "User-agent: *\nDisallow: /"
  end
  get '/top' do
    user = get_user
    haml :top, locals: {user: user}
  end
end
