module Sequel
  module Plugins
    module Serialization
      module ClassMethods
        # serializedされたカラムをwhere検索するのに必要
        # serialized_attr_accessor :kind__contest,:promotion__rank_up しておくと
        # Klass.kind__contest, Klass.promotion__rank_up でシリアライズされたデータが取得できる
        def serialized_attr_accessor(*syms)
          syms.each{|x|
            (k,c) = x.to_s.split("__")
            define_singleton_method(x){
              self.serialization_map[k.to_sym].call(c.to_sym)
            }
          }
        end
        # update や create に渡せるようにデシリアライズする
        # 深さ1までなので注意
        def make_deserialized_data(data)
          data.map{|k,v|
            s = k.to_sym
            f = self.deserialization_map[s]
            [s, if f then f.call(v) else v end]
          }.to_h
        end
      end
      module InstanceMethods
        # 普通の Model#to_hash はデシリアライズしないので自分で実装
        # ついでに引数でフィルタリングできるようにする
        def select_attr(*args)
          self.to_deserialized_hash(*args)
        end
        def to_deserialized_hash(*args)
          args = args.map{|x|x.to_sym}
          self.class.serialized_columns.each{|c|
            # デシリアライズする 
            self.send(c)
          }
          # 一度デシリアライズしたものは deserialized_values に格納される
          h = self.to_hash.merge(self.deserialized_values)
          if args.empty?
            h
          else
            h.select{|x|args.include?(x)}
          end
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
    raise Exception.new("#{enums.inspect} is #{enums.class}, it should be Array") unless enums.is_a?(Array)
    serializer = lambda{|x|
      if not x.nil? then
        if x.is_a?(String) then x = x.to_sym end
        raise Exception.new("#{x.inspect} is #{x.class}, it should be Symbol") unless x.is_a?(Symbol)
        enums.index(x) + 1
      end
    }
    deserializer = lambda{|x|
      if not x.nil? then
        raise Exception.new("#{x.inspect} is #{x.class}, it should be Numeric") unless x.is_a?(Numeric)
        enums[x-1]
      end
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
    raise Exception.new("#{flags.inspect} is #{flags.class}, it should be Array") unless flags.is_a?(Array)
    serializer = lambda{|x|
      if not x.nil? then
        raise Exception.new("#{x.inspect} is #{x.class}, it should be Array") unless x.is_a?(Array)
        x.inject(0){|sum,y|
          sum + (1 << flags.index(y))
        }
      end
    }
    deserializer = lambda{|x|
      if not x.nil? then
        raise Exception.new("#{x.inspect} is #{x.class}, it should be Numeric") unless x.is_a?(Numeric)
        flags.each_with_index.map{|y,i|
          (x & (1 << i) != 0) ? y : nil
        }.compact
      end
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
      if not x.nil? then
        if x.is_a?(String) then
          x = Kagetra::HourMin.parse(x)
        end
        raise Exception.new("#{x.inspect} is #{x.class}, it should be HourMin") unless x.is_a?(Kagetra::HourMin)
        x.to_s
      end
    }
    deserializer = lambda{|x|
      if not x.nil? then
        raise Exception.new("#{x.inspect} is #{x.class}, it should be String") unless x.is_a?(String)
        Kagetra::HourMin.parse(x)
      end
    }
    [serializer,deserializer]
  end
end
