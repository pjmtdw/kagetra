# -*- coding: utf-8 -*-

G_APP_NAME = "景虎"

G_DIMAPA = DiffPatchMatch.new

G_MOBILE_BASE = "/mobile"

G_DB_RAISE_SAVE_FAILURE = true # DataMapperがsave失敗したときにErrorをraiseする

G_STORAGE_DIR = "./storage" # Wikiの添付ファイルとアルバムの写真が置かれるディレクトリ

G_WEEKDAY_JA = ['日','月','火','水','木','金','土']

G_ADDRBOOK_CONFIRM_STR = 'kagetra_addrbook' # 名簿でパスワードが正しいかの確認用

# 一つのサーバで複数のkagetraを起動する場合はこの辺を変更すること
G_SESSION_COOKIE_NAME = "kagetra.session" # ブラウザが閉じられると消える
G_PERMANENT_COOKIE_NAME = "kagetra.permanent" # 3ヶ月保存される

G_NEWLY_DAYS_MAX = 75 # 新着コメントとして表示される最大の日数
G_DEADLINE_ALERT = 7 # 締切が迫っていますを表示する日数
G_LOGIN_LOG_DAYS = 10 # ログイン履歴を残す日数
G_TOKEN_EXPIRE_HOURS = 24 # ユーザの認証用トークンを更新する時間間隔

G_EVENT_KINDS = {party:"コンパ/合宿/アフター等",etc:"アンケート/購入/その他"}

G_TEAM_SIZES = {"1"=>"個人戦","3"=>"三人団体戦","5"=>"五人団体戦"}

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

G_SINGLE_POINT = [1,2,4,8,16,32,64] # 個人戦でもらえるA級ポイント
G_SINGLE_POINT_LOCAL = [1,2,4,8,16,32,64,128,256] # 個人戦でもらえる会内ポイント
G_TEAM_POINT_LOCAL = [10,20,30,40,50] # 団体戦でもらえる会内ポイント

