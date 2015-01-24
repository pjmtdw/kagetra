# 葉隠のrootディレクトリ
CONF_HAGAKURE_BASE = '/home/hiroshima/hagakure'

# 共通パスワードと名簿暗号化用パスワード
# 注意: 暗号化/復号はクライアント側で行われるのでサーバ側に格納しておく必要はない．
#       従ってサーバのデータ流出の際でも復号されないように
#       葉隠データ取り込み後は必ず削除すること
CONF_SHARED_PASSWORD = "momiji"

# MeiboDownloaderによって作られたCSV
CONF_MEIBO_CSV = "/path/to/hagakure/meibo.csv"
CONF_MEIBO_HTML = "/path/to/hagakure/meibo.html"

# 結婚などの理由で途中で名前が変わったユーザの一覧
CONF_USERNAME_CHANGED = {
  '佐藤太郎' => '鈴木太郎',
  '高橋次郎' => '高橋次郎'
}
