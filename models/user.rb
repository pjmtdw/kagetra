# -*- coding: utf-8 -*-
#class User
#  include ModelBase
#  property :deleted,       ParanoidBoolean, lazy: false # 自動的に付けられる削除済みフラグ
#  property :name,          TrimString, length: 24, required: true, lazy: true, remove_whitespace: true
#  property :furigana,      TrimString, length: 36, required: true, lazy: true
#  property :furigana_row,  Integer, index: true, allow_nil: false, lazy:true # 振り仮名の最初の一文字が五十音順のどの行か
#  property :password_hash, TrimString, length: 44, lazy: true
#  property :password_salt, TrimString, length: 32, lazy: true
#  property :token,         TrimString, length: 32, lazy: true # 認証用トークン
#  property :token_expire, DateTime # 認証用トークンの有効期限
#  property :admin,          Boolean, default: false # 管理者
#  property :loginable,      Boolean, default: true # ログインできるか
#  property :permission, Flag[:sub_admin]
#  property :bbs_public_name, TrimString, length: 24, lazy: true # 掲示板に書き込むときの名前(公開スレッド)
#  property :show_new_from, DateTime # 掲示板, コメントなどの新着メッセージはこれ以降の日時のものを表示
#
#  has n, :attrs, 'UserAttribute'
#
#  has n, :event_user_choices
#
#  has 1, :login_latest, 'UserLoginLatest'
#  has n, :login_logs, 'UserLoginLog'
#  has n, :login_monthlies, 'UserLoginMonthly'
#
#  after :create do
#    UserAttributeValue.all(default:true).each{|v|
#      self.attrs.create(value:v)
#    }
#  end
#
#  before :save do
#    self.furigana_row = Kagetra::Utils.gojuon_row_num(self.furigana)
#  end
#
#  def sub_admin
#    self.permission.include?(:sub_admin)
#  end
#
#  MIN_LOGIN_SPAN = 30 # これだけの分数経過したらログイン数を増やす
#  # ログイン処理
#  def update_login(request)
#    User.transaction{
#      latest = self.login_latest
#      is_first_login = false
#      if latest.nil? then
#        is_first_login = true
#        latest = UserLoginLatest.create(user:self)
#      end
#      now = DateTime.now
#      counted = false
#      if is_first_login or (now - latest.updated_at)*1440 >= MIN_LOGIN_SPAN then
#        monthly = self.login_monthlies.first_or_new(year_month:UserLoginMonthly.year_month(now.year,now.month))
#        monthly.count += 1
#        monthly.save
#        self.show_new_from = if is_first_login then nil else latest.updated_at end
#        latest.set_env(request)
#        latest.touch
#        latest.save
#        counted = true
#      end
#      if self.token_expire.nil? or DateTime.now > self.token_expire
#        self.change_token!
#      end
#      self.save
#      log = self.login_logs.new(counted: counted)
#      log.set_env(request)
#      log.save
#
#    }
#  end
#  def change_token!
#    self.token = SecureRandom.base64(24)
#    self.token_expire = DateTime.now + (G_TOKEN_EXPIRE_HOURS/24.0)
#  end
#  # 今月のログイン数
#  def log_mon_count
#    dt = Date.today
#    monthly = self.login_monthlies.first(year_month:UserLoginMonthly.year_month(dt.year,dt.month))
#    if monthly then
#      monthly.count
#    else
#      0
#    end
#  end
#  def last_login_str
#    pre = self.show_new_from
#    last_count = self.login_latest.updated_at
#    r1 = if pre.nil? then
#      "初ログイン<br/>#{CONF_FIRST_LOGIN_MESSAGE}<br/>"
#    else
#      days = (last_count-pre).to_f
#      if days < 2/24.0
#        "#{(days*1440).to_i}分前"
#      elsif days < 2.0
#        "#{(days*24).to_i}時間前"
#      else
#        "#{days.to_i}日前"
#      end
#    end
#    r2 = (1440*(DateTime.now-last_count).to_f).to_i
#    r3 = (r2 >= MIN_LOGIN_SPAN)
#    [r1,r2,r3]
#  end
#end

class User < Sequel::Model(:users)
end

# 最後のログイン(updated_atが実際のログインの日時)
#class UserLoginLatest
#  include ModelBase
#  include UserEnv
#  property :user_id, Integer, unique: true, required: true
#  belongs_to :user
#end
#
## 直近数日間のログイン履歴(created_atがログインの日時)
#class UserLoginLog
#  include ModelBase
#  include UserEnv
#  belongs_to :user
#  property :counted, Boolean, default:true # ログイン数としてカウントされたか
#end
#
## ユーザが月に何回ログインしたか
#class UserLoginMonthly
#  include ModelBase
#  property :user_id, Integer, unique_index: :u1, required: true
#  belongs_to :user
#  property :year_month, String, unique_index: :u1, required: true, index: true, length: 8 # YYYY-MM
#  property :count, Integer, default: 0
#  property :rank, Integer
#  def self.year_month(year,month)
#    "%d-%02d" % [year,month]
#  end
#  def self.calc_rank(year,month)
#    year_month = self.year_month(year,month)
#    rank = nil
#    prev = nil
#    self.all(year_month:year_month,order:[:count.desc]).to_enum.with_index(1).map{|x,index|
#      if prev != x.count then
#        rank = index
#        prev = x.count
#      end
#      x.select_attr(:user_id,:count).merge({rank:rank})
#    }
#  end
#end
#
## どのユーザがどの属性を持っているか
#class UserAttribute
#  include ModelBase
#  belongs_to :user
#  belongs_to :value, 'UserAttributeValue'
#  before :save do
#    #一人のユーザは各属性keyにつき一つの属性valueしか持てない
#    values = self.value.attr_key.values
#    self.user.attrs(value: values).destroy!
#  end
#end
#
#
## ユーザ属性の名前
#class UserAttributeKey
#  include ModelBase
#  property :name, TrimString, length: 36, required:true
#  property :index, Integer, required: true # 順番
#  has n, :values, 'UserAttributeValue', child_key: [:attr_key_id]
#end
#
## ユーザ属性の値
#class UserAttributeValue
#  include ModelBase
#  property :attr_key_id, Integer, required: true
#  belongs_to :attr_key, 'UserAttributeKey'
#  property :value, TrimString, length: 48, required: true
#  property :index, Integer, required: true
#  property :default, Boolean, default: false # ユーザ作成時のデフォルトの値
#  # デフォルトは必ず一つ必要
#  before :create do
#    if self.attr_key.values(default:true).count == 0 then
#      self.default = true
#    end
#  end
#  # デフォルトが二つあってはいけない
#  after :save do
#    if self.default then
#      self.attr_key.values(default:true,:id.not => self.id).update!(default:false)
#    end
#  end
#  # 少なくとも一つはデフォルトがなくてはならない
#  before :destroy do
#    if self.default then
#      self.attr_key.values(:id.not => self.id).first.update(default:true)
#    end
#  end
#end
