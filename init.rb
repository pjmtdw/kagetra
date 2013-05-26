# -*- coding: utf-8 -*-
require './conf'
require 'bundler'

require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/content_for'
if development? then
  require 'sass/plugin/rack'
  require 'sinatra/reloader'
end
require 'haml'

require 'json'
require 'base64'

require 'data_mapper'
require 'dm-chunked_query'

case CONF_DB_PATH
when /^sqlite3:/
  require 'dm-sqlite-adapter'
when /^mysql:/
  require 'dm-mysql-adapter'
end

require 'openssl'
require 'securerandom'

require './app'
require './routes/init'
require './helpers/init'
require './models/init'
require './utils'
