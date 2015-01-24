
DB = Sequel.postgres(
  CONF_DB_DATABASE,
  host: CONF_DB_HOST,
  port: CONF_DB_PORT,
  user: CONF_DB_USERNAME,
  password: CONF_DB_PASSWORD,
  pool_timeout: 10,
  sslmode: "disable"
)

DB_OSM = if CONF_DB_OSM_DATABASE then
  Sequel.postgres(
    CONF_DB_OSM_DATABASE,
    host: CONF_DB_HOST,
    port: CONF_DB_PORT,
    user: CONF_DB_USERNAME,
    password: CONF_DB_PASSWORD,
    sslmode: "disable"
  )
 end

if CONF_DB_DEBUG then
  DB.loggers << Logger.new($stdout)
  DB.sql_log_level = :debug
  DB_OSM.loggers << Logger.new($stdout)
  DB_OSM.sql_log_level = :debug
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
require_relative 'sequel_helpers/defaults_setter_custom'
require_relative 'sequel_helpers/serializers'
Sequel::Model.plugin :defaults_setter_custom
Sequel::Model.plugin :input_transformer_custom

Sequel::Plugins::Serialization.register_format(:hourmin,*Kagetra::serialize_hourmin)

module Sequel
  module SQL
    class Function
      # SQLのSUM()はデフォルトでは0を返してくれない
      def coalesce_0
        Sequel.function(:coalesce,self,0)
      end
    end
  end
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
  module Plugins
    module SerializationModificationDetection
      module InstanceMethods
        def before_save
          # オリジナルの SerializationModificationDetection は initialize_set の中でしか serialize_deserialized_values を呼んでいない
          # これだと before_save hook の中で self.hoge = "fuga" とかした場合に hoge が Serialized value の場合変更を detect できない
          serialize_deserialized_values
          super
        end
      end
    end
    module  UpdateOrCreate
      module ClassMethods
        # オリジナルの update_or_create は 更新するものがないときは nil を返す
        # lib/sequel/plugins/update_or_create.rb 参照
        def update_or_create_custom(attrs, set_attrs=nil, &block)
          find_or_new(attrs, set_attrs, &block).tap(&:save_changes)
        end
      end
    end
    # timestamps プラグインは自動的に updated_at を更新するが，更新したくない時もあるので
    # update! メソッドを用意する
    # sequel/lib/sequel/plugins/timestamp.rb 参照
    module Timestamps
      module ClassMethods
        attr_accessor :timpstamp_preserve
      end
      module InstanceMethods
        # timestamps の before_update を上書きする
        def before_update
          if not @timestamp_preserve then
            set_update_timestamp
          end
          super
        end
        # これを使うとtimestampを更新しないupdateできる
        def update!(hash)
          orig = @timestamp_preserve
          @timestamp_preserve = true
          r = update(hash)
          @timestamp_preserve = orig
          r
        end
      end
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
require_relative 'map'
