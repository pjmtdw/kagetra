
DB = Sequel.mysql2(
  host: CONF_DB_HOST,
  username: CONF_DB_USERNAME,
  password: CONF_DB_PASSWORD,
  database: CONF_DB_DATABASE
)

if CONF_DB_DEBUG then
  DB.loggers << Logger.new($stdout)
  DB.sql_log_level = :debug
end

DB.extension(:graph_each)
DB.extension(:pagination)
Sequel::Model.plugin :touch
Sequel::Model.plugin :timestamps, update_on_create:true
Sequel::Model.plugin :string_stripper
Sequel::Model.plugin :serialization_modification_detection # 自動的に :serialization も読み込む
Sequel::Model.plugin :update_or_create
Sequel::Model.plugin :validation_helpers
require_relative 'sequel_helpers/input_transformer_custom'
require_relative 'sequel_helpers/serializers'
Sequel::Plugins::Serialization.register_format(:hourmin,*Kagetra::serialize_hourmin)

module Sequel
  class Dataset
    def find_or_create(vals,id_column)
      # Sequel::Model には find_or_create があるけど Dataset の方にはないので自分で定義
      # association から取得した Dataset にはどの column で結合したかの情報が失われているので
      # id_column を explicit に与える必要がある
      # TODO: id_column を与えなくても良いようにできない？ Dataset にはどの column で where するかの情報があるので可能なはず．
      raise Exception.new("#{id_column} not found in #{model}") unless columns.include?(id_column)
      first(vals) || model.create(vals.merge(id_column => model_object.pk))
    end
  end
end

require_relative 'misc'
require_relative 'user'
require_relative 'event'
require_relative 'bbs'
require_relative 'schedule'
require_relative 'album'
require_relative 'addrbook'
require_relative 'result'
require_relative 'wiki'
