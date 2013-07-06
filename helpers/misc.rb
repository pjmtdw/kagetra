# -*- coding: utf-8 -*-
module MiscHelpers
  def get_user
    User.first(id: session[:user_id], token: session[:user_token])
  end

  def dm_response
    begin
      yield
    rescue DataMapper::SaveFailureError => e
      msg = e.resource.errors.full_messages().join("\n")
      logger.warn msg
      $stderr.puts msg

      bt = e.backtrace.join("\n")
      logger.puts bt
      $stderr.puts bt
      {_error_: msg}
    rescue Exception => e
      logger.warn e.message
      $stderr.puts e.message

      bt = e.backtrace.join("\n")
      logger.puts bt
      $stderr.puts bt
      {_error_: e.message }
    end
  end

  PERMANENT_COOKIE_NAME="kagetra.permanent"
  def get_permanent(key)
    data = get_permanent_all
    if data then data[key] end
  end

  def get_permanent_all
    str = request.cookies[PERMANENT_COOKIE_NAME]
    if str.to_s.empty? then
      {}
    else
      return JSON.parse(Base64.strict_decode64(str))
    end
  end

  def set_permanent(key,value)
    data = get_permanent_all
    data.merge!(key => value)
    set_permanent_all(data)
  end

  def set_permanent_all(data)
    str = Base64.strict_encode64(data.to_json)
    response.set_cookie(PERMANENT_COOKIE_NAME,
                        value: str,
                        path: "/",
                        expires: (Date.today + 90).to_time)
  end

  def delete_permanent(key)
    data = get_permanent_all
    data.delete(key)
    if data.empty?
      response.delete_cookie(PERMANENT_COOKIE_NAME)
    else
      set_permanent_all(data)
    end
  end
  # 今日の一枚を選択
  def choose_daily_album_photo
    # sqrtの重み付け
    # 以下の方法はメモリを多少多めに利用するが
    # AlbumGroupの数は多くても数千，重みの最大は精々10程度で平均3ぐらいなので多分大丈夫
    ag = AlbumGroup.all(:daily_choose_count.gt => 0).map{|ag|
      w = Math.sqrt(ag.daily_choose_count).to_i
      [ag] * w
    }.flatten.sample
    a = ag.items.to_a.sample
    t = a.thumb
    MyConf.update_or_create({name:DAILY_ALBUM_PHOTO_KEY},{value:{id:a.id,width:t.width,height:t.height}})
  end

  # 古いログイン履歴を削除
  def clean_login_log
    day_from = Date.today - G_LOGIN_LOG_DAYS
    UserLoginLog.all(:created_at.lt => day_from).destroy
  end
  DAILY_JOB_KEY_PREFIX = "daily_job_"
  DAILY_ALBUM_PHOTO_KEY = "daily_album_photo"
  def exec_daily_job
    Kagetra::Utils.single_exec{
      key = DAILY_JOB_KEY_PREFIX + Date.today.to_s
      conf = MyConf.first(name:key)
      return if conf.nil?.!
      MyConf.transaction{
        # put daily tasks here
        choose_daily_album_photo
        clean_login_log

        MyConf.all(:name.like => DAILY_JOB_KEY_PREFIX + "%", :name.not => key).destroy
        MyConf.create(name:key,value:{done:"true"})
      }
    }
  end
end
