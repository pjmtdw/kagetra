class MainApp < Sinatra::Base
  def filter_public(splat)
    path = "/" + splat
    halt(403,"this page is not public") unless G_TOP_BAR_ROUTE.any?{|x|
      next unless x[:public]
      r = x[:route]
      [r,"/api"+r].any?{|z| path.start_with?(z)}
    }
    @public_mode = true
    call env.merge("PATH_INFO" => path)
  end

  # only get and post is allowed in /public/
  get '/public/*' do |splat|
    filter_public(splat)
  end
  post '/public/*' do |splat|
    filter_public(splat)
  end
  before do
    return if @public_mode
    path = request.path_info
    return if ["/public/","/api/user/auth/"].any?{|s|path.start_with?(s)} or path == "/"
    @user = get_user
    if @user.nil? then
      halt 403, "login required"
    end
  end
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
  get '/' do
    shared = MyConf.first(name: "shared_password")
    halt 403, "Shared Password Unavailable." unless shared
    shared_salt = shared.value["salt"]

    uid = get_permanent("uid")
    (login_uid,login_uname) =
      if uid.nil? then nil 
      else 
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
    dph = MyConf.first(name:"daily_album_photo")
    p dph.value
    daily_photo = if dph then dph.value end
    haml :top, locals:
      {
        daily_photo: daily_photo
      }
  end
  get '/relogin' do
    delete_permanent("uid")
    redirect '/'
  end
end
