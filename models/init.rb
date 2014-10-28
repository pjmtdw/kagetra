
DB = Sequel.mysql2(
  host: CONF_DB_HOST,
  username: CONF_DB_USERNAME,
  password: CONF_DB_PASSWORD,
  database: CONF_DB_DATABASE
)
Sequel::Model.plugin :touch
Sequel::Model.plugin :string_stripper
require_relative 'sequel_plugins/input_transformer_custom'

module Sequel
  class Dataset
    def find_or_create(vals,id_column)
      # association から取得した Dataset にはどの column で結合したかの情報が失われているので
      # id_column を explicit に与える必要がある
      # TODO: id_column を与えなくても良いようにできない？ Dataset にはどの column で where するかの情報があるので可能なはず．
      raise Exception.new("#{id_column} not found in #{model}") unless columns.include?(id_column)
      first(vals) || model.create(vals.merge(id_column => model_object.pk))
    end
  end
end

Event = nil # TODO
EventComment = nil # TODO
WikiItem = nil # TODO
WikiComment = nil # TODO
require_relative 'misc'
require_relative 'user'
#require_relative 'bbs'
#require_relative 'schedule'
#require_relative 'event'
#require_relative 'result'
#require_relative 'addrbook'
#require_relative 'album'
#require_relative 'wiki'

