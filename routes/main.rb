# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  set(:auth) do |role|
    condition do
      case role
      when :user
        return true unless @user.nil?
      when :sub_admin
        return true if not @user.nil? and @user.sub_admin
      when :admin
        return true if not @user.nil? and @user.admin
      end
      if request.path.start_with?('/api')
        halt_wrap 403, '権限がありません'
      else
        halt 403
      end
    end
  end

  # ゲストユーザーはPUTとDELETE禁止
  class << self
    def put(path, opts = {}, &block)
      opts[:auth] = :user if opts[:auth].nil?
      super(path, opts, &block)
    end
    def delete(path, opts = {}, &block)
      opts[:auth] = :user if opts[:auth].nil?
      super(path, opts, &block)
    end
  end

  before do
    @user = get_user
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
  not_found do
    if request.path_info.start_with?("/api/") then
      halt_wrap 404, "not found"
    else
      send_file("./static/index.html")
    end
  end
end
