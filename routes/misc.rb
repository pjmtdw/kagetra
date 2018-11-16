# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  def filter_public(splat)
    path = "/" + splat
    # TODO: G_TOP_BAR_PUBLIC の wiki のページが増えるとここが非効率的になる
    # board_message は /public/api/board_message/ からもアクセスされるのでこっちにも入れておく
    halt_wrap 403, "this page is not public" unless G_TOP_BAR_PUBLIC.any?{|x|
      r = x[:route].sub(/#.*/,"")
      rs = ["/"+r,"/api/"+r]
      if r == "schedule" then
        rs += ["/api/event/item/"] # 予定表の「情報」ボタンも公開可能にする
      end
      rs.any?{|z| path.start_with?(z)}
    } or path.start_with?("/api/board_message/")
    @public_mode = true
    call env.merge("PATH_INFO" => path)
  end

  set(:private){|value|
    condition{
      if value and @public_mode
        halt_wrap 403, "this page is private"
      end
    }
  }

  # /public/ では GET と POST しか許可しない ( PUT や DELETE はできない )
  get '/public/' do
    redirect '/'
  end
  get '/public/*' do |splat|
    filter_public(splat)
  end
  post '/public/*' do |splat|
    filter_public(splat)
  end
  before do
    return if @public_mode
    # pathの末尾の/は無視
    path = request.path_info
    path.chop! if path[-1] == '/'
    # 以下のURLはログインしなくてもアクセスできる
    allowed_prefix = ["/public/", "/api/user/auth/", "/api/board_message/", "/api/ut_karuta/form", "/js/", "/img/", "/css/"]
    allowed = ["", "/robots.txt", "/select_other_uid", "/mobile", "/api/initials"]
    return if allowed_prefix.any?{ |s| path.start_with?(s) } or allowed.include?(path)

    @user = if settings.development? and ENV.has_key?("KAGETRA_USER_ID")
            then User.first(id: ENV["KAGETRA_USER_ID"])
            else get_user
            end
    if @user.nil? then
      if path.start_with?("/api/") then
        halt_wrap 403, "login required"
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

    def getBoardMessageName(mode)
      halt 403, "invalid board message mode." unless ["user","shared"].include?(mode)
      "board_message_" + mode
    end

    get '/board_message/:mode' do
      name = getBoardMessageName(params[:mode])
      cnf = MyConf.first(name:name)
      if cnf.nil? then {message:""} else cnf.value end
    end
    post '/board_message/:mode' do
      with_update{
        name = getBoardMessageName(params[:mode])
        MyConf.update_or_create({name: name},{value: {message:@json['message']}})
      }
    end
    get '/initials' do
      Kagetra::Utils.gojuon_row_names
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
      title: 'ログイン',
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
    haml :top, locals: {
      title: 'トップ',
    }
  end
  get '/select_other_uid' do
    delete_permanent("uid")
    redirect '/'
  end
  get '/etc' do
    redirect '/top'
  end
  get '/img/bg.jpg' do
    expires :today
    filename = "%02d"%Date.today.month + '.jpg'
    send_file("./public/img/bg/#{filename}")
  end
  get '/img/bg_rev.jpg' do
    expires :today
    filename = "%02d"%Date.today.month + '_rev.jpg'
    send_file("./public/img/bg/#{filename}")
  end
end
