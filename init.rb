# -*- coding: utf-8 -*-
# License of this software is described in LICENSE file.
require './conf'
require 'bundler'
require 'mysql2'
require 'sequel'
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
require 'digest'
require 'nkf'
require 'redcarpet'
require './libs/diff_match_patch-ruby/diff_match_patch.rb'
require 'RMagick'
require 'zip'

require 'nokogiri'

require 'spreadsheet'

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
