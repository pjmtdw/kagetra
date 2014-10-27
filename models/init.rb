
DB = Sequel.mysql2(
  host: CONF_DB_HOST,
  username: CONF_DB_USERNAME,
  password: CONF_DB_PASSWORD,
  database: CONF_DB_DATABASE
)

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

