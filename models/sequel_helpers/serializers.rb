module Sequel
  module Plugins
    module Serialization
      module InstanceMethods
        # 普通の Model#to_hash はデシリアライズしないので自分で実装
        def to_deserialized_hash
          self.class.serialized_columns.each{|c|
            # デシリアライズする 
            self.send(c)
          }
          # 一度デシリアライズしたものは deserialized_values に格納される
          self.to_hash.merge(self.deserialized_values)
        end
      end
    end
  end
end
module Kagetra
  # DataMapper の Enum 相当．sequel/plugins/serializationに渡す
  # 使い方:
  #   require 'sequel/plugins/serialization'
  #   class Hoge < Sequel::Model
  #     serialize_attributes Kagetra::serialize_enum([:apple,:banana,:orange]), :fruits
  #   end
  def self.serialize_enum(enums)
    raise Exception.new("#{enums} is not an array") unless enums.is_a?(Array)
    serializer = lambda{|x|
      raise Exception.new("#{x} is not a symbol") unless x.is_a?(Symbol)
      enums.index(x) + 1
    }
    deserializer = lambda{|x|
      raise Exception.new("#{x} is not a numeric") unless x.is_a?(Numeric)
      enums[x-1]
    }
    [serializer,deserializer]
  end
  # DataMapper の Flag 相当．sequel/plugins/serializationに渡す
  # 使い方:
  #   require 'sequel/plugins/serialization'
  #   class Hoge < Sequel::Model
  #     serialize_attributes Kagetra::serialize_flag([:is_women,:is_japanese,:is_married]), :person, 
  #   end
  def self.serialize_flag(flags)
    raise Exception.new("#{flags} is not an array") unless flags.is_a?(Array)
    serializer = lambda{|x|
      raise Exception.new("#{x} is not an array") unless x.is_a?(Array)
      x.inject(0){|sum,y|
        sum + (1 << flags.index(y))
      }
    }
    deserializer = lambda{|x|
      raise Exception.new("#{x} is not a numeric") unless x.is_a?(Numeric)
      flags.each_with_index.map{|y,i|
        (x & (1 << i) != 0) ? y : nil
      }.compact
    }
    [serializer,deserializer]
  end
  # HourMinのシリアライザ
  # 使い方:
  #   require 'sequel/plugins/serialization'
  #   Sequel::Plugins::Serialization.register_format(:hourmin,*Kagetra::serialize_hourmin)
  #   class Hoge < Sequel::Model
  #     plugin :serialization, :hourmin, :start_at
  #   end
  def self.serialize_hourmin
    serializer = lambda{|x|
      raise Exception.new("#{x} is not HourMin") unless x.is_a?(Kagetra::HourMin)
      x.to_s
    }
    deserializer = lambda{|x|
      raise Exception.new("#{x} is not a string") unless x.is_a?(String)
      Kagetra::HourMin.parse(x)
    }
    [serializer,deserializer]
  end
end
