DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/data.db")

require_relative 'user'
require_relative 'bbs'
require_relative 'misc'

DataMapper.finalize
DataMapper.auto_upgrade!
