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
require 'RMagick'

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

G_ADDRBOOK_CONFIRM_STR = 'kagetra_addrbook' # 名簿でパスワードが正しいかの確認用

G_ADDRBOOK_KEYS = ['名前','ふりがな','E-Mail','生年月日','所属','出身高校','電話番号','郵便番号1','住所1','郵便番号2','住所2','メモ1','メモ2']

G_DEADLINE_ALERT = 7 # 締切が迫っていますを表示する日数

G_EVENT_KINDS = {party:"コンパ/アフター等",etc:"アンケート/その他"}

G_TEAM_SIZES = {"1"=>"個人戦","3"=>"三人団体戦","5"=>"五人団体戦"}
