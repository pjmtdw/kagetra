module ModelBase
  def self.included(base)
    base.class_eval do
      include DataMapper::Resource
      p = DataMapper::Property
      property :id, p::Serial
      # Automatically set/updated by dm-timestamps
      property :created_at, p::DateTime, index: true, lazy: true
      property :updated_at, p::DateTime, index: true, lazy: true

      def self.all_month(prop,year,month)
        from = Date.new(year,month,1)
        to = from >> 1
        all(prop.gte => from, prop.lt => to)
      end

      def select_attr(*symbols)
        attrs = self.attributes
        symbols.each{|s|
          raise Exception.new("'#{s}' is not a property of '#{self.class}'") unless attrs.has_key?(s)
        }
        attrs.select_attr(*symbols)
      end
    end
  end
end

module UserEnv
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property
      property :remote_host, p::String, length: 72, lazy: true 
      property :remote_addr, p::String, length: 48, lazy: true
      property :user_agent, p::String, length: 255, lazy: true
    end
    def set_env(req)
      # TODO: DRY way to get the length of property ?
      host = req.env["REMOTE_HOST"]
      addr = req.ip
      agent = req.user_agent
      self.remote_host = host[0...72] if host
      self.remote_addr = addr[0...48] if addr
      self.user_agent = agent[0...255] if agent
    end
  end
end

module CommentBase
  # このモジュールをincludeするクラスは belongs_to :thread を持たなければならない
  # TODO: include時に belongs_to :thread の引数を指定できない？
  def self.included(base)
    base.class_eval do
      include UserEnv
      p = DataMapper::Property 
      # ParanoidBooleanにはバグがあって lazy: true にしてしまうと関連モデルを直接取得したときの belong_to が nil になる
      # https://github.com/datamapper/dm-types/issues/52
      property :deleted, p::ParanoidBoolean, lazy: false
      property :body, p::Text, required: true # 内容
      property :user_name, p::String, length: 24, allow_nil: false # 書き込んだ人の名前
      belongs_to :user, required: false # 内部的なユーザID

      before :save do
        if self.user_name.to_s.empty? and self.user then
          self.user_name = self.user.name
        end
      end
      after :create do
        # コメント数の更新
        th = self.thread
        th.update(comment_count: th.comments.count,
                  last_comment_user: self.user,
                  last_comment_date: self.created_at)
      end
      def is_new(user)
        (self.user.nil? or self.user.id != user.id) and 
        user.show_new_from.nil?.! and
        self.created_at >= user.show_new_from
      end
    end
  end
end

module ThreadBase
  # このモジュールをincludeするクラスは has n, :comments を持たなければならない
  # TODO: include時に has n, :comments の引数を指定できない？
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property 
      belongs_to :last_comment_user, 'User', required: false # スレッドに最後に書き込んだユーザ
      property :last_comment_date, p::DateTime, index: true # スレッドに最後に書き込んだ日時
      property :comment_count, Integer, default: 0 # コメント数 (毎回aggregateするのは遅いのでキャッシュ)
    end
    def self.new_threads(user)
      search_from = user.show_new_from
      c0 = self.all(
        :last_comment_date.gte => user.show_new_from,
        order: [:last_comment_date.desc])
      c1 = self.all(:last_comment_user_id => nil)
      c2 = self.all(:last_comment_user_id.not => user.id)
      c0 & (c1 | c2)
    end
  end
end

module DataMapper
  class Property
    class HourMin < DataMapper::Property::String
      def custom?
        true
      end
      def load(value)
        case value
        when ::String
          ::Kagetra::HourMin.parse(value)
        when ::NilClass,::Kagetra::HourMin
          value
        else
          raise Exception.new("invalid class: #{value.class.name}")
        end
      end
      def dump(value)
        case value
        when ::NilClass,::String
          value
        when ::Kagetra::HourMin
          value.to_s
        else
          raise Exception.new("invalid class: #{value.class.name}")
        end
      end
      def typecast(value)
        load(value)
      end
    end
  end
end

class MyConf
  include ModelBase
  property :name,  String, length: 64, unique: true
  property :value, Json
end

