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
        attrs.select{|k,v|
          symbols.include?(k) and v.nil?.!
        }
      end
    end
  end
end

module CommentBase
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property
      
      property :deleted, p::ParanoidBoolean
      property :body, p::Text, required: true # 内容
      property :user_name, p::String, length: 24, allow_nil: false # 書き込んだ人の名前
      property :remote_host, p::String, length: 72, lazy: true 
      property :remote_addr, p::String, length: 48, lazy: true
      property :user_agent, p::String, length: 256, lazy: true
      belongs_to :user, required: false # 内部的なユーザID

      before :save do
        if self.user_name.to_s.empty? and self.user then
          self.user_name = self.user.name
        end
      end
      # TODO: trim remote_host, remote_addr, user_agent if it is too long
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

class Test
  include ModelBase
  belongs_to :user
  belongs_to :my_conf
  validates_uniqueness_of :my_conf_id, scope: [:user_id]
end
