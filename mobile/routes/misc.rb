# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  def self.mobile_comment_routes(namespace,prev_url)
    get "/mobile/#{namespace}/comment/list/:id" do
      @info = call_api(:get,"/api/#{namespace}/comment/list/#{params[:id]}")
      @namesp = namespace
      @prev_url = prev_url
      mobile_haml :comment
    end
    post "/mobile/#{namespace}/comment/item" do
      res = call_api(:post,"/api/#{namespace}/comment/item",params)
      mobile_haml <<-HEREDOC
書き込みました
%a(href='#{namespace}/comment/list/#{params["thread_id"]}') [戻る]
      HEREDOC
    end
  end
  def mobile_haml(sym)
    haml sym, views:"mobile/views", format: :xhtml
  end
  def call_api(method,path,params={},content_type=:json)
    base = {
      "REQUEST_METHOD" => method.to_s.upcase,
      "PATH_INFO" => path,
    }
    case method
    when :get
      base["QUERY_STRING"] = build_query(params)
    when :post
      if content_type == :json
        base["CONTENT_TYPE"] = "application/json"
        base["rack.input"] = StringIO.new(params.to_json)
      else
        base["rack.input"] = StringIO.new(build_query(params))
      end
    end
    res = call env.merge(base)
    if res[0] == 200
      JSON.parse(res[2][0])
    else
      halt res[0], res[2][0]
    end
  end
  namespace '/mobile' do
    get '/top' do
      @newly = call_api(:get,"/api/user/newly_message")
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
                   User.get(params[:uid]).furigana
                 else
                   params[:furigana]
                 end
      if furigana.empty? then
        @message = "ユーザ名が空白です"
      elsif params[:password].empty? then
        @message = "パスワードが空白です"
      else
        users = User.all(:furigana.like => "#{furigana}%")
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
