# -*- coding: utf-8 -*-

G_ADDRBOOK_CONFIRM_STR = 'kagetra_addrbook' # 名簿でパスワードが正しいかの確認用

G_ADDRBOOK_KEYS = ['名前','ふりがな','E-Mail','生年月日','所属','出身高校','電話番号','郵便番号1','住所1','郵便番号2','住所2','メモ1','メモ2']

G_DEADLINE_ALERT = 7 # 締切が迫っていますを表示する日数

G_EVENT_KINDS = {party:"コンパ/合宿/アフター等",etc:"アンケート/購入/その他"}

G_TEAM_SIZES = {"1"=>"個人戦","3"=>"三人団体戦","5"=>"五人団体戦"}

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

G_DIMAPA = DiffPatchMatch.new

G_CONTEST_DEFAULT_AGGREGATE_ATTR = "級" # 大会のデフォルトの集計属性
G_CONTEST_DEFAULT_FORBIDDEN_ATTRS = {"全日協" => ["×"]} # 大会のデフォルトの参加不能属性
G_PARTY_DEFAULT_AGGREGATE_ATTR = "学年" # 大会以外の行事のデフォルトの集計属性


G_SESSION_COOKIE_NAME = "kagetra.session" # ブラウザが閉じられると消える
G_PERMANENT_COOKIE_NAME = "kagetra.permanent" # 3ヶ月保存される

G_NEWLY_DAYS_MAX = 60 # 新着コメントとして表示される最大の日数
