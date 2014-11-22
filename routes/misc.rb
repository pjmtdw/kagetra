# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  def filter_public(splat)
    path = "/" + splat
    # TODO: G_TOP_BAR_PUBLIC の wiki のページが増えるとここが非効率的になる
    halt(403,"this page is not public") unless G_TOP_BAR_PUBLIC.any?{|x|
      r = x[:route].sub(/#.*/,"")
      ["/"+r,"/api/"+r].any?{|z| path.start_with?(z)}
    } or path.start_with?("/haml/")
    @public_mode = true
    call env.merge("PATH_INFO" => path)
  end

  set(:private){|value|
    condition{
      if value and @public_mode
        halt 403,"this page is private"
      end
    }
  }

  # /public/ では GET と POST しか許可しない ( PUT や DELETE はできない )
  get '/public/*' do |splat|
    filter_public(splat)
  end
  post '/public/*' do |splat|
    filter_public(splat)
  end
  before do
    return if @public_mode
    path = request.path_info
    # 以下のURLはログインしなくてもアクセスできる
    return if ["/public/","/api/user/auth/","/js/","/img/","/css/"].any?{|s|path.start_with?(s)} or ["/","/robots.txt","/select_other_uid","/mobile/"].include?(path)
    @user = get_user
    if @user.nil? then
      if path.start_with?("/api/") then
        halt 403, "login required"
      elsif path.start_with?("/mobile/") then
        redirect '/mobile/'
      else
        redirect '/'
      end
    end
  end
  namespace '/api' do
    before do
      content_type :json
      cache_control :no_cache
      if request.content_type then
        ctype = request.content_type.split(";")[0].downcase
        if ["json","javascript"].any?{|x|ctype.include?(x)} then
          @json = JSON.parse(request.body.read)
        end
      end
    end
    after do
      r = response.body.to_json
      if @public_mode then
        # Eメールアドレス収集ボットに対処
        r.gsub!(Kagetra::Utils::EMAIL_ADDRESS_REGEX){
          $1 + " あっと " + $2.gsub("."," どっと ")
        }
      end
      response.body = r
    end
  end
  get '/' do
    shared = MyConf.first(name: "shared_password")
    halt 403, "Shared Password Unavailable." unless shared
    shared_salt = shared.value["salt"]

    uid = get_permanent("uid")
    user = User[uid.to_i]
    (login_uid,login_uname) =
      if uid.nil? or user.nil? then nil
      else
        [uid,user.name]
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
    @daily_photo = if dph then dph.value end
    haml :top
  end
  get '/select_other_uid' do
    delete_permanent("uid")
    redirect '/'
  end
  get '/etc' do
    redirect '/top'
  end
  get '/haml/:prefix' do
    # ブラウザ側にキャッシュさせる
    # 注意: キャッシュさせるhamlファイルに@userなどの動的な情報が含まれないようにすること
    last_modified File.mtime(File.join(settings.views,params[:prefix]+".haml"))
    haml params[:prefix].to_sym, layout: nil
  end
end
