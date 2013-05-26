module ModelBase
  def self.included(base)
    base.class_eval do
      include DataMapper::Resource
      property :id,            DataMapper::Property::Serial
      # Automatically set/updated by dm-timestamps
      property :created_at, DataMapper::Property::DateTime, index: true
      property :updated_at, DataMapper::Property::DateTime, index: true
    end
  end
end
class MyConf
  include ModelBase
  property :id,    Serial
  property :name,  String, length: 64, unique: true
  property :value, Json
end

