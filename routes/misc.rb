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
    # pathの末尾の/は無視
    path = request.path_info
    path.chop! if path[-1] == '/'
    # 以下のURLはログインしなくてもアクセスできる
    allowed_prefix = ["/public/", "/api/user/auth/", "/api/board_message/", "/js/", "/img/", "/css/"]
    allowed = ["", "/robots.txt", "/select_other_uid", "/mobile", "/api/initials"]
    return if allowed_prefix.any?{ |s| path.start_with?(s) } or allowed.include?(path)

    @user = if settings.development? and ENV.has_key?("KAGETRA_USER_ID")
            then User.first(id: ENV["KAGETRA_USER_ID"])
            else get_user
            end
    if @user.nil? and path.start_with?("/api/") then
      halt_wrap 403, "ログインが必要です"
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
  not_found do
    if request.path_info.start_with?("/api/") then
      halt_wrap 404, "not found"
    else
      send_file("./static/index.html")
    end
  end
  get '/img/*' do |splat|
    send_file("./static/img/#{splat}")
  end
end
