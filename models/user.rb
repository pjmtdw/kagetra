# -*- coding: utf-8 -*-

class User < Sequel::Model(:users)
  plugin :input_transformer_custom
  add_input_transformer_custom(:name){|v|v.gsub(/\s+/,"")}

  one_to_many :attrs, class:'UserAttribute'

  one_to_one :login_latest, class:'UserLoginLatest'
  one_to_many :login_monthlies, class:'UserLoginMonthly'
  one_to_many :login_logs, class:'UserLoginLog'
  
  one_to_many :event_user_choices
  one_to_one :addr_book, class:'AddrBook'

  serialize_attributes Kagetra::serialize_flag([:sub_admin]), :permission


  MIN_LOGIN_SPAN = 30 # これだけの分数経過したらログイン数を増やす
  # ログイン処理
  def update_login(request)
    DB.transaction{
      latest = self.login_latest
      is_first_login = false
      if latest.nil? then
        is_first_login = true
        latest = UserLoginLatest.new(user:self)
      end
      now = Time.now
      counted = false
      if is_first_login or (now - latest.updated_at) >= MIN_LOGIN_SPAN*60 then
        monthly = self.login_monthlies_dataset.find_or_create({year_month:UserLoginMonthly.year_month(now.year,now.month)},:user_id)
        monthly.count += 1
        monthly.save
        self.show_new_from = if is_first_login then nil else latest.updated_at end
        latest.set_env(request)
        latest.touch
        latest.save
        counted = true
      end
      if self.token_expire.nil? or Time.now > self.token_expire
        self.change_token!
      end
      self.save
      log = self.add_login_log(counted: counted)
      log.set_env(request)
      log.save
    }
  end
  def change_token!
    self.token = SecureRandom.base64(24)
    self.token_expire = Time.now + (G_TOKEN_EXPIRE_HOURS/24.0)
  end
  # 今月のログイン数
  def log_mon_count
    dt = Date.today
    monthly = self.login_monthlies_dataset.first(year_month:UserLoginMonthly.year_month(dt.year,dt.month))
    if monthly then
      monthly.count
    else
      0
    end
  end
  def after_create
    UserAttributeValue.all(default:true).each{|v|
      self.attrs.create(value:v)
    }
  end
  def before_save
    self.furigana_row = Kagetra::Utils.gojuon_row_num(self.furigana)
  end

  def sub_admin
    self.permission.include?(:sub_admin)
  end

  def last_login_str
    pre = self.show_new_from
    last_count = self.login_latest.updated_at
    r1 = if pre.nil? then
      "初ログイン<br/>#{CONF_FIRST_LOGIN_MESSAGE}<br/>"
    else
      days = ((last_count-pre)/86400.0).to_f
      if days < 2/24.0
        "#{(days*1440).to_i}分前"
      elsif days < 2.0
        "#{(days*24).to_i}時間前"
      else
        "#{days.to_i}日前"
      end
    end
    r2 = ((Time.now-last_count).to_f/60.0).to_i
    r3 = (r2 >= MIN_LOGIN_SPAN)
    [r1,r2,r3]
  end
end

class UserLoginLatest < Sequel::Model(:user_login_latests)
  include UserEnv
  many_to_one :user
end

class UserLoginLog < Sequel::Model(:user_login_logs)
  include UserEnv
  many_to_one :user
end

class UserLoginMonthly < Sequel::Model(:user_login_monthlies)
  many_to_one :user
  def self.year_month(year,month)
    "%d-%02d" % [year,month]
  end
  def self.calc_rank(year,month)
    year_month = self.year_month(year,month)
    rank = nil
    prev = nil
    self.where(year_month:year_month).order(Sequel.desc(:count)).to_enum.with_index(1).map{|x,index|
      if prev != x.count then
        rank = index
        prev = x.count
      end
      x.select_attr(:user_id,:count).merge({rank:rank})
    }
  end
end

class UserAttribute < Sequel::Model(:user_attributes)
  many_to_one :user
  many_to_one :value, class:'UserAttributeValue'
  def after_save
    #一人のユーザは各属性keyにつき一つの属性valueしか持たないことを保証する
    values = self.value.attr_key.attr_values
    self.user.attrs_dataset.where(value: values).where(Sequel.~(id:self.id)).destroy
  end
end


class UserAttributeKey < Sequel::Model(:user_attribute_keys)
  one_to_many :attr_values, class:'UserAttributeValue', key: :attr_key_id
end

class UserAttributeValue < Sequel::Model(:user_attribute_values)
  many_to_one :attr_key, class:'UserAttributeKey', key: :attr_key_id
  one_to_many :user_attributes, key: :value_id
  # デフォルトは必ず一つ必要
  def before_create
    if self.attr_key.attr_values_dataset.where(default:true).count == 0 then
      self.default = true
    end
  end
  # デフォルトが二つあってはいけない
  def after_save
    if self.default then
      self.attr_key.attr_values_dataset.where(default:true).where(Sequel.~(id:self.id)).update!(default:false)
    end
  end
  # 少なくとも一つはデフォルトがなくてはならない
  def before_destroy
    if self.default then
      self.attr_key.attr_values_dataset.where(Sequel.~(id:self.id)).first.update(default:true)
    end
  end
end
