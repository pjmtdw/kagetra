# -*- coding: utf-8 -*-
module MiscHelpers
  def time_for(value)
    now = Time.now
    case value
    when :today then Time.local now.year, now.mon, now.day, 23, 59, 59
    else super
    end
  end

  def get_user
    User.first(id: session[:user_id], token: session[:user_token])
  end

  def addrbook_check_password_js
    # 名簿パスワードが正しいかどうか確認するJavaScriptを埋め込む
    enc = MyConf.first(name: "addrbook_confirm_enc").value["text"]
    str = G_ADDRBOOK_CONFIRM_STR
    <<-HEREDOC
    function g_addrbook_check_password(pass){
      return ('#{str}'== CryptoJS.AES.decrypt('#{enc}',pass).toString(CryptoJS.enc.Latin1))
    }
    HEREDOC
  end

  def addrbook_check_password(pass)
    enc = MyConf.first(name: "addrbook_confirm_enc").value["text"]
    str = G_ADDRBOOK_CONFIRM_STR
    str == Kagetra::Utils.openssl_dec(enc,pass)
  end

  def error_response(message)
    status 400
    {error_message: message}
  end

  def halt_wrap(status_code, message)
    halt status_code, { error_message: message }
  end

  def with_update
    begin
      DB.transaction{
        yield
      }
    rescue Exception => e
      logger.warn e.message
      $stderr.puts e.message

      bt = e.backtrace.join("\n")
      logger.puts bt
      $stderr.puts bt
      error_response(e.message)
    end
  end

  # Cookie
  def get_permanent(key)
    data = get_permanent_all
    if data then data[key] end
  end

  def get_permanent_cookie_name
    # 共通パスワードが変わったら共通パスワード入力画面に強制的に飛ばすために別のCookie Keyにする
    # 16文字で十分衝突確率は低いはず
    G_PERMANENT_COOKIE_NAME + "." + MyConf.first(name:"shared_password").value["hash"].delete("^a-zA-Z0-9")[0...16]
  end

  def get_permanent_all
    str = request.cookies[get_permanent_cookie_name]
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
    response.set_cookie(get_permanent_cookie_name,
                        value: str,
                        path: "/",
                        expires: (Date.today + 90).to_time)
  end

  def delete_permanent(key)
    data = get_permanent_all
    data.delete(key)
    if data.empty?
      response.delete_cookie(get_permanent_cookie_name)
    else
      set_permanent_all(data)
    end
  end

  # 今日の一枚を選択
  def choose_daily_album_photo
    # sqrtの重み付け
    # 以下の方法はメモリを多少多めに利用するが
    # AlbumGroupの数は多くても数千，重みの最大は精々10程度で平均3ぐらいなので多分大丈夫
    ag = AlbumGroup.where{ daily_choose_count > 0}.map{|x|
      w = Math.sqrt(x.daily_choose_count).to_i
      [x] * w
    }.flatten.sample
    return if ag.nil?
    item = ag.items.to_a.sample
    MyConf.update_or_create({name:DAILY_ALBUM_PHOTO_KEY},{value:item.id_with_thumb})
  end

  def update_event_done_flag
    events = Event.where(done:false).where{ date <= Date.today }
    events.where(kind: Event.kind__contest).each{|ev|
      # ContestUser と ContestClass を作る
      value2klass = {}
      ev.aggregate_attr.attr_values.each{|v|
        next if ev.forbidden_attrs.include?(v.id)
        value2klass[v.id] = ContestClass.create(event_id:ev.id,class_name:v.value,index:v.index)
      }
      ev.choices_dataset.where(positive: true).each{|c|
        c.user_choices.each{|uc|
          av = uc.attr_value
          next if av.nil?
          klass = value2klass[av.id]
          next if klass.nil?
          ContestUser.create(event_id:ev.id,contest_class_id:klass.id,user:uc.user,name:uc.user_name)
        }
      }
    }
    events.each{|x|x.update(done: true)}
  end


  def invalidate_expired_token
    User.where{ token_expire < Time.now}.each{|x|x.update(token:nil,token_expire:nil)}
  end

  # 古いログイン履歴を削除
  def clean_login_log
    day_from = Date.today - G_LOGIN_LOG_DAYS
    UserLoginLog.where{ created_at < day_from}.destroy
  end
  DAILY_JOB_KEY = "daily_job"
  DAILY_ALBUM_PHOTO_KEY = "daily_album_photo"
  def exec_daily_job
    Kagetra::Utils.single_exec{
      today = Date.today.to_s
      conf = MyConf.first(name:DAILY_JOB_KEY)
      return if (conf.nil?.! and conf.value["date"] == today)
      DB.transaction{
        # put daily tasks here
        choose_daily_album_photo
        clean_login_log
        update_event_done_flag
        invalidate_expired_token

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
      DB.transaction{
        # put monthly tasks here
        (pyear,pmonth) = Kagetra::Utils.inc_month(today.year,today.month,-1)
        update_login_ranking(pyear,pmonth)

        MyConf.update_or_create({name:MONTHLY_JOB_KEY},{value:{yearmon:yearmon}})
      }
    }
  end

  # wiki とアルバムコメントの共通部分
  def make_comment_log_patch(item,json,s_body,s_revision)
    return unless json.has_key?(s_body)
    new_body = json[s_body].to_s.strip
    prev_body = if item then item.send(s_body.to_sym).to_s else "" end
    if item
      if json[s_revision].nil? then raise Exception.new("no '#{s_revision}' found: #{json.inspect}") end
      # check for conflict
      cur_rev = item.send(s_revision.to_sym)
      if cur_rev != json[s_revision]
        # if conflict then merge
        r_body = item.each_revisions_until(cur_rev-json[s_revision]).to_a[-1][:text]
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
    if not patch.to_s.empty? then
      updates_patch = {revision:rev,patch:patch}
      [updates,updates_patch]
    else
      [nil,nil]
    end
  end
  # 編集距離
  # copied from http://rosettacode.org/wiki/Levenshtein_distance#Ruby
  def levenshtein_distance(str1, str2)
    str1 = str1.to_s
    str2 = str2.to_s
    n = str1.length
    m = str2.length
    max = n/2
    return m if 0 == n
    return n if 0 == m
    return n if (n - m).abs > max
    d = (0..m).to_a
    x = nil
    str1.each_char.with_index do |char1,i|
      e = i+1

      str2.each_char.with_index do |char2,j|
        cost = (char1 == char2) ? 0 : 1
        x = [ d[j+1] + 1, # insertion
              e + 1,      # deletion
              d[j] + cost # substitution
            ].min
        d[j] = e
        e = x
      end

      d[m] = x
    end
    x
  end

  def haml_wrap(title='', top_bar=true, **args)
    haml '', locals: args.merge(title:title,top_bar:top_bar)
  end
end
