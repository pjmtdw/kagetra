# -*- coding: utf-8 -*-

# 大会出場者(後に改名する人がいる可能性があるのと，Userにない人を追加できるようにするため)
class ContestUser
  include ModelBase
  property :name, TrimString, length: 24, required: true
  property :user_id, Integer, unique_index: :u1, required: false
  belongs_to :user
  property :event_id, Integer, unique_index: :u1, required: true
  belongs_to :event
  has 1, :prize, 'ContestPrize'
  has n, :games, 'ContestGame'
end

# 大会の各級の情報
class ContestClass
  include ModelBase
  property :event_id, Integer, unique_index: [:u1,:u2], required: true
  belongs_to :event
  property :class_name, TrimString, length: 16, required: true, unique_index: :u1 # 級の名前
  property :class_rank, Enum[:a,:b,:c,:d,:e,:f,:g] # 実際の級のランク
  property :index, Integer, unique_index: :u2 # 順番
  property :num_person, Integer # その級の参加人数(個人戦)
  property :round_name, Json, default: {} # 順位決定戦の名前(個人戦), {"4":"順決勝","5":"決勝"} のような形式
  has n, :single_user_classes, 'ContestSingleUserClass'
  has n, :single_users,'ContestUser',through: :single_user_classes,via: :contest_user # 参加者(個人戦)
  has n, :single_games,'ContestGame' # 試合結果(個人戦)
  has n, :prizes, 'ContestPrize'
  has n, :teams, 'ContestTeam' # 参加チーム(団体戦)
end

# 個人賞/入賞
class ContestPrize
  include ModelBase
  property :contest_class_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_class
  property :contest_user_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_user
  property :prize, TrimString, length: 32, required: true # 実際の名前 (優勝, 全勝賞など)
  property :promotion, Enum[:rank_up, :dash] # 昇級, ダッシュ
  property :point, Integer # A級のポイント
  property :point_local, Integer # 会内ポイント
  property :rank, Integer # 順位(1=優勝, 2=準優勝, 3=三位, 4=四位, ...)
end


# 試合結果(個人戦, 団体戦共通)
class ContestGame
  include ModelBase
  # Discriminator を使った Single Table Inheritance は子クラスにインデックスを作れないし
  # 親クラスと子クラスの間のunique_indexを作れないので自分で切り変える
  property :type, Enum[:single,:team] , index: true # 個人戦, 団体戦
  # belongs_to does not support unique_index so we do this ugly hack.
  property :contest_user_id, Integer, unique_index: [:u1,:u2], required: true
  belongs_to :contest_user
  property :result, Enum[:now,:win,:lose,:default_win], required: true # 勝敗 => 対戦中, 勝ち, 負け, 不戦勝,
  property :score_str, TrimString, length: 8 # 枚数(文字) "棄" とか "3+1" とかあるので文字列として用意しておく
  property :score_int, Integer, index: true # 枚数(数字)
  property :opponent_name, TrimString, length: 24 # 対戦相手の名前
  property :opponent_belongs, TrimString, length: 36 # 対戦相手の所属, 個人戦のみ使用 (ただし団体戦の大会でも対戦相手の所属がバラバラな場合はここに書く))
  property :comment, TrimText # コメント

  is_single = ->(x){ x.type == :single }
  is_team = ->(x){ x.type == :team }
 
  # 個人戦用
  property :contest_class_id, Integer, unique_index: :u1, index: true
  belongs_to :contest_class
  property :round, Integer, unique_index: :u1

  # required:true の代わりに条件付きvalidationする(required:trueだとDBにNOT NULLを付けてしまう)
  validates_presence_of :contest_class_id, if: is_single
  validates_presence_of :round, if: is_single
  validates_absence_of :contest_team_opponent_id, if: is_single
  validates_absence_of :opponent_order, if: is_single

  # 団体戦用
  property :contest_team_opponent_id, Integer, unique_index: :u2, index: true
  belongs_to :contest_team_opponent
  property :opponent_order, Integer, unique_index: :u2 # 将順

  validates_presence_of :contest_team_opponent_id, if: is_team
  validates_absence_of :contest_class_id, if: is_team
  validates_absence_of :round, if: is_team

end

# 誰がどの級に出場したか(個人戦)
class ContestSingleUserClass
  include ModelBase
  # belongs_to does not support unique_index so we do this ugly hack.
  property :contest_user_id, Integer, unique_index: :u1, required: true
  property :contest_class_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_user
  belongs_to :contest_class
end

# 誰がどのチームの何将か(団体戦)
class ContestTeamMember
  include ModelBase
  # belongs_to does not support unique_index so we do this ugly hack.
  property :contest_user_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_user
  property :contest_team_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_team
  property :order_num, Integer, unique_index: :u1, required: true # 将順
end

# どのチームがどの級に出場しているか(団体戦)
class ContestTeam
  include ModelBase
  # belongs_to does not support unique_index so we do this ugly hack.
  property :contest_class_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_class
  property :name, TrimString, length: 48, unique_index: :u1, required: true # チーム名
  property :prize, TrimString, length: 24 # チーム入賞
  property :rank, Integer # チーム入賞から推定した順位
  property :promotion, Enum[:rank_up,:rank_down] # 昇級, 陥落
  has n, :members, 'ContestTeamMember'
  has n, :opponents, 'ContestTeamOpponent'
end

# 各チームが何回戦にどのチームと対戦したか(団体戦)
class ContestTeamOpponent
  include ModelBase
  property :contest_team_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_team
  property :name, TrimString, length: 48 # 対戦相手のチーム名
  property :round, Integer, unique_index: :u1, required: true # n回戦
  property :round_name, TrimString, length: 36 # 決勝, 順位決定戦など
  property :comment, TrimText
  property :kind, Enum[:team, :single] # 団体戦, 個人戦 (大会としては団体戦だけど各自が別々のチーム相手に対戦)
  has n, :games, 'ContestGame' # 試合結果(団体戦)
end
