# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  def mobile_event_symbol(kind,official)
    case kind
    when "contest"
      if official then "★" else "<font color='green'>■</font>" end
    when "party"
      "<font color='#FF6666'>●</font>"
    when "etc"
      "<font color='#187CB4'>◆</font>"
    end
  end
  def mobile_emphasis(item,key)
    s = (item[key]||"").escape_html
    if (item["emphasis"] || []).include?(key) then
      s = "<b>#{s}</b>"
    end
    s
  end
  def mobile_paren_private(item,s)
    if not item["public"] then
      s = "(#{s})"
    end
    s
  end
  def self.mobile_comment_routes(namespace)
    get "/mobile/#{namespace}/comment/list/:from/:id" do
      qs = if params.has_key?("page") then {page:params[:page]} else {} end
      @info = call_api(:get,"/api/#{namespace}/comment/list/#{params[:id]}",qs)
      @namesp = namespace
      @prev_url = params[:from].to_s.gsub(".","/")
      mobile_haml :comment
    end
    post "/mobile/#{namespace}/comment/:from/item" do
      res = call_api(:post,"/api/#{namespace}/comment/item",params)
      mobile_haml <<-HEREDOC
書き込みました
%a(href='#{G_MOBILE_BASE}/#{namespace}/comment/list/#{params[:from]}/#{params[:thread_id]}') [戻る]
      HEREDOC
    end
  end
  def mobile_haml(sym,rest={})
    haml sym, rest.merge(views:"mobile/views", format: :html4)
  end
  def call_api(method,path,params={},content_type=:json)
    base = {
      "REQUEST_METHOD" => method.to_s.upcase,
      "PATH_INFO" => path,
    }
    case method
    when :get
      base["QUERY_STRING"] = build_query(params)
    when :post,:put
      if content_type == :json
        base["CONTENT_TYPE"] = "application/json"
        base["rack.input"] = StringIO.new(params.to_json)
      else
        base["rack.input"] = StringIO.new(build_query(params))
      end
    end
    res = call env.merge(base)
    if res[0] == 200
      begin
        JSON.parse(res[2][0])
      rescue JSON::ParserError => e
        puts "#{method.inspect} #{path.inspect} #{params.inspect} => #{res[2][0].inspect}"
        raise e
      end
    else
      halt res[0], res[2][0]
    end
  end
  namespace '/mobile' do
    get '/top' do
      @newly = call_api(:get,"/api/user/newly_message")
      @panel = call_api(:get,"/api/schedule/panel")
      @deadline = call_api(:get,"/api/event/deadline_alert")
      mobile_haml :top
    end
    get '/' do
      if params[:reset] then
        delete_permanent("uid")
      else
        @uid = get_permanent("uid")
      end
      mobile_haml :login
    end
    post '/' do
      furigana = if params[:uid] then
                   @uid = params[:uid]
                   User[params[:uid]].furigana
                 else
                   params[:furigana]
                 end
      if furigana.empty? then
        @message = "ユーザ名が空白です"
      elsif params[:password].empty? then
        @message = "パスワードが空白です"
      else
        users = User.where(Sequel.like(:furigana,"#{furigana}%"))
        count = users.count
        if count == 0
          @message = "該当するユーザはいません"
        elsif count >= 2
          @message = "該当するユーザが複数います"
        else
          u = users.first
          check = u.password_hash == Kagetra::Utils.hash_password(params[:password],u.password_salt)[:hash]
          if not check
            @message = "パスワードが違います"
          end
        end
      end
      if @message
        mobile_haml :login
      else
        u.update_login(request)
        session[:user_id] = u.id
        session[:user_token] = u.token
        set_permanent("uid",u.id)
        redirect '/mobile/top'
      end
    end
  end
end
