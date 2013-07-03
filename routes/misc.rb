class MainApp < Sinatra::Base
  get '/' do
    shared = MyConf.first(name: "shared_password")
    halt 403, "Shared Password Unavailable." unless shared
    shared_salt = shared.value["salt"]

    per = get_permanent
    (login_uid,login_uname) =
      if per.nil? then nil 
      else 
        uid = per["uid"]
        [uid,User.get(uid.to_i).name]
      end
    haml :login, locals: {
      shared_salt: shared_salt,
      login_uid: login_uid,
      login_uname: login_uname,
    }
  end
  get '/robots.txt' do
    content_type 'text/plain'
    "User-agent: *\nDisallow: /"
  end
  get '/top' do
    user = get_user
    dph = MyConf.first(name:"daily_album_photo")
    p dph.value
    daily_photo = if dph then dph.value end
    haml :top, locals:
      {
        user: user,
        daily_photo: daily_photo
      }
  end
  get '/relogin' do
    delete_permanent
    redirect '/'
  end
end
