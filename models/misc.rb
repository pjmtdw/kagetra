class MyConf
  include DataMapper::Resource
  property :id,    Serial
  property :name,  Text, :unique => true
  property :value, Json
end

