DataMapper::Model.raise_on_save_failure = G_DB_RAISE_SAVE_FAILURE

if CONF_DB_DEBUG then
  DataMapper::Logger.new(STDOUT, :debug)
end

DataMapper.setup(:default, CONF_DB_PATH)
require_relative 'misc'
require_relative 'user'
require_relative 'bbs'
require_relative 'schedule'
require_relative 'event'
require_relative 'result'
require_relative 'addrbook'
require_relative 'album'
require_relative 'wiki'

DataMapper.finalize
DataMapper.auto_upgrade!
