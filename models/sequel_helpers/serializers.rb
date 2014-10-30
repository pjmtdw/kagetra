module Kagetra
  # DataMapper の Enum 相当．sequel/plugins/serializationに渡す
  # 使い方:
  #   require 'sequel/plugins/serialization'
  #   class Hoge < Sequel::Model
  #     serialize_attributes Kagetra::serialize_enum([:apple,:banana,:orange]), :fruits
  #   end
  def self.serialize_enum(enums)
    raise Exception("#{enums} is not an array") unless enums.is_a?(Array)
    serializer = lambda{|x|
      raise Exception("#{x} is not a symbol") unless x.is_a?(Symbol)
      enums.index(x) + 1
    }
    deserializer = lambda{|x|
      raise Exception("#{x} is not a numeric") unless x.is_a?(Numeric)
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
    raise Exception("#{flags} is not an array") unless flags.is_a?(Array)
    serializer = lambda{|x|
      raise Exception("#{x} is not an array") unless x.is_a?(Array)
      x.inject(0){|sum,y|
        sum + (1 << flags.index(y))
      }
    }
    deserializer = lambda{|x|
      raise Exception("#{x} is not a numeric") unless x.is_a?(Numeric)
      flags.each_with_index.map{|y,i|
        (x & (1 << i) != 0) ? y : nil
      }.compact
    }
    [serializer,deserializer]
  end
end
