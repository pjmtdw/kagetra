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
require 'diff_match_patch'
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
require 'tempfile'

require './app'
require './routes/init'
require './helpers/init'
require './models/init'
require './utils'

G_ADDRBOOK_CONFIRM_STR = 'kagetra_addrbook' # 名簿でパスワードが正しいかの確認用

G_ADDRBOOK_KEYS = ['名前','ふりがな','E-Mail','生年月日','所属','出身高校','電話番号','郵便番号1','住所1','郵便番号2','住所2','メモ1','メモ2']

G_DEADLINE_ALERT = 7 # 締切が迫っていますを表示する日数

G_EVENT_KINDS = {party:"コンパ/合宿/アフター等",etc:"アンケート/購入/その他"}

G_TEAM_SIZES = {"1"=>"個人戦","3"=>"三人団体戦","5"=>"五人団体戦"}

G_BACKTRACE_LENGTH = 16 # ログに表示するbacktraceの最大行数

G_LOGIN_LOG_DAYS = 10 # ログイン履歴を残す日数

# public は外部公開されているかどうか
G_TOP_BAR_ROUTE = [
  {route:"top",      name:"TOP",      public: false},
  {route:"bbs",      name:"掲示板",   public: true },
  {route:"result",   name:"大会結果", public: false},
  {route:"schedule", name:"予定表",   public: true },
  {route:"wiki",     name:"Wiki",     public: true },
  {route:"album",    name:"アルバム", public: false},
  {route:"addrbook", name:"名簿",     public: false},
]

G_STORAGE_DIR = "./storage"

G_DIMAPA = DiffMatchPatch.new
