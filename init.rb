# -*- coding: utf-8 -*-
# License of this software is described in LICENSE file.
require './conf'
require 'bundler'

require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/content_for'
if development? then
  require 'sass/plugin/rack'
  require 'sinatra/reloader'
end
require 'logger'
require 'haml'

require 'json'
require 'base64'
require 'nkf'
require 'redcarpet'
require './libs/diff_match_patch-ruby/diff_match_patch.rb'
require 'RMagick'
require 'zip/zip' # RubyZip

require 'nokogiri'

require 'data_mapper'
require 'dm-chunked_query'
require 'spreadsheet'

case CONF_DB_PATH
when /^sqlite3:/
  require 'dm-sqlite-adapter'
when /^mysql:/
  require 'dm-mysql-adapter'
end

require 'openssl'
require 'securerandom'
require 'tempfile'
require 'resolv'

require './const'
require './models/init'
require './app'
require './helpers/init'
require './routes/init'
require './utils'

require './mobile/init'
