DataMapper::Model.raise_on_save_failure = true

if CONF_DB_DEBUG then
  DataMapper::Logger.new(STDOUT, :debug)
end

DataMapper.setup(:default, CONF_DB_PATH)
require_relative 'misc'
require_relative 'user'
require_relative 'bbs'

DataMapper.finalize
DataMapper.auto_upgrade!
