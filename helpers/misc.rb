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

  def get_permanent(key)
    data = get_permanent_all
    if data then data[key] end
  end

  def get_permanent_all
    str = request.cookies[G_PERMANENT_COOKIE_NAME]
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
    response.set_cookie(G_PERMANENT_COOKIE_NAME,
                        value: str,
                        path: "/",
                        expires: (Date.today + 90).to_time)
  end

  def delete_permanent(key)
    data = get_permanent_all
    data.delete(key)
    if data.empty?
      response.delete_cookie(G_PERMANENT_COOKIE_NAME)
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
    MyConf.update_or_create({name:DAILY_ALBUM_PHOTO_KEY},{value:{id:a.id,thumb:t.select_attr(:id,:width,:height)}})
  end

  def update_event_done_flag
    Event.all(:date.lte => Date.today, done:false).update(done: true)
  end

  # 古いログイン履歴を削除
  def clean_login_log
    day_from = Date.today - G_LOGIN_LOG_DAYS
    UserLoginLog.all(:created_at.lt => day_from).destroy
  end
  DAILY_JOB_KEY = "daily_job"
  DAILY_ALBUM_PHOTO_KEY = "daily_album_photo"
  def exec_daily_job
    Kagetra::Utils.single_exec{
      today = Date.today.to_s
      conf = MyConf.first(name:DAILY_JOB_KEY)
      return if (conf.nil?.! and conf.value["date"] == today)
      MyConf.transaction{
        # put daily tasks here
        choose_daily_album_photo
        clean_login_log
        update_event_done_flag

        MyConf.update_or_create({name:DAILY_JOB_KEY},{value:{date:today}})
      }
    }
  end

  def update_login_ranking(year,month)
    UserLoginMonthly.calc_rank(year,month).each{|x|
      u = UserLoginMonthly.first(user_id:x[:user_id],year_month:UserLoginMonthly.year_month(year,month))
      u.update(rank:x[:rank]) if u.nil?.!
    }
  end

  MONTHLY_JOB_KEY = "monthly_job"

  def exec_monthly_job
    Kagetra::Utils.single_exec{
      today = Date.today
      yearmon = "#{today.year}-#{today.month}"
      conf = MyConf.first(name:MONTHLY_JOB_KEY)
      return if (conf.nil?.! and conf.value["yearmon"] == yearmon)
      MyConf.transaction{
        # put monthly tasks here
        (pyear,pmonth) = Kagetra::Utils.inc_month(today.year,today.month,-1)
        update_login_ranking(pyear,pmonth)

        MyConf.update_or_create({name:MONTHLY_JOB_KEY},{value:{yearmon:yearmon}})
      }
    }
  end

  # wiki とアルバムコメントの共通部分
  def make_comment_log_patch(item,json,s_body,s_revision)
    new_body = json[s_body]
    if new_body.to_s.empty?.! then
      prev_body = if item then item.send(s_body.to_sym).to_s else "" end
      if item
        if json[s_revision].nil? then raise Exception.new("no '#{s_revision}' found: #{json.inspect}") end
        # check for conflict
        if item.send(s_revision.to_sym) != json[s_revision]
          # if conflict then merge
          r_body = item.send(("get_revision_"+s_body).to_sym,json[s_revision])
          patches = G_DIMAPA.patch_make(r_body,new_body)
          (new_body,_) = G_DIMAPA.patch_apply(patches,prev_body)
        end
        rev = (item.send(s_revision)||0) + 1
      else
        rev = 1
      end
      updates = {s_body => new_body, s_revision => rev}
      patches = G_DIMAPA.patch_make(new_body,prev_body)
      patch = G_DIMAPA.patch_toText(patches)
      updates_patch = {revision:rev,patch:patch}
      [updates,updates_patch]
    end
  end
end
