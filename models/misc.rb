module ModelBase
  def self.included(base)
    base.class_eval do
      include DataMapper::Resource
      property :id,            DataMapper::Property::Serial
      # Automatically set/updated by dm-timestamps
      property :created_at, DataMapper::Property::DateTime, index: true
      property :updated_at, DataMapper::Property::DateTime, index: true
      
      def self.all_month(prop,year,month)
        from = Date.new(year,month,1)
        to = from >> 1
        all(prop.gte => from, prop.lt => to)
      end
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
          raise Exception.new("invalid type: #{value.class.name}")
        end
      end
      def dump(value)
        case value
        when ::NilClass,::String
          value
        when ::Kagetra::HourMin
          value.to_s
        else
          raise Exception.new("invalid type: #{value.class.name}")
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
  property :id,    Serial
  property :name,  String, length: 64, unique: true
  property :value, Json
end

