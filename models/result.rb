# -*- coding: utf-8 -*-

# 個人戦, 団体戦共通

# 大会の各級の情報
class ContestClass
  include ModelBase
  property :event_id, Integer, unique_index: [:u1,:u2], required: true
  belongs_to :event
  property :class_name, String, length: 16, unique_index: :u1 # 級の名前
  property :class_rank, Enum[:a,:b,:c,:d,:e,:f,:g] # 実際の級のランク
  property :index, Integer, unique_index: :u2 # 順番
  property :num_person, Integer # その級の参加人数(個人戦)
  property :round_name, Json # 順位決定戦の名前(個人戦), {"4":"順決勝","5":"決勝"} のような形式
  has n, :single_user_classes, 'ContestSingleUserClass'
  has n, :single_users,'User',through: :single_user_classes,via: :user # 参加者(個人戦)
  has n, :single_games,'ContestSingleGame' # 試合結果(個人戦)
  has n, :prizes, 'ContestPrize'
  has n, :teams, 'ContestTeam' # 参加チーム(団体戦)
end

# 個人賞/入賞
class ContestPrize
  include ModelBase
  property :contest_class_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_class
  property :user_id, Integer, unique_index: :u1, required: true
  belongs_to :user
  property :prize, String, length: 32 # 入賞
  property :promotion, Enum[:rank_up, :dash] # 昇級, ダッシュ
  property :point, Integer # A級のポイント
  property :point_local, Integer # 会内ポイント
  property :rank, Integer # 順位
end

# 試合結果(個人戦, 団体戦共通)
class ContestGame
  include ModelBase
  property :type, Discriminator # Single Table Inheritance between ContestTeamGame and ContestSingleGame
  belongs_to :user
  property :user_name, String, length: 24 # 大会出場時の名前 (後に改名する人がいるために残しておく)
  property :result, Enum[:now,:win,:lose,:default_win] # 勝敗 => 対戦中, 勝ち, 負け, 不戦勝,
  property :score_str, String, length: 8 # 枚数(文字) "棄" とか "3+1" とかあるので文字列として用意しておく
  property :score_int, Integer # 枚数(数字)
  property :opponent_name, String, length: 24 # 対戦相手の名前
  property :opponent_belongs, String, length: 36 # 対戦相手の所属, 個人戦のみ使用 (ただし団体戦の大会でも対戦相手の所属がバラバラなものもあるので用意しておく))
  property :comment, Text # コメント
end

# 誰がどの級に出場したか(個人戦)
class ContestSingleUserClass
  include ModelBase
  property :user_id, Integer, unique_index: :u1, required: true
  property :contest_class_id, Integer, unique_index: :u1, required: true
  belongs_to :user
  belongs_to :contest_class
end

# 試合結果(個人戦)
class ContestSingleGame < ContestGame
  # These properties are actually 'required: true'. However, it corresponds to SQL constraint 'NOT NULL'
  # As for single table inheritance, other classes which inherits this base class cannot create instance if we set 'required: true'.
  # Thus we use 'validates_presence_of' instead
  belongs_to :contest_class, required: false
  property :round, Integer
  # TODO: how to create UNIQUE INDEX (user_id, contest_class_id, round) ?
  # we use unique verification instead
  validates_uniqueness_of :user_id, scope: [:contest_class_id,:round]
  validates_presence_of :contest_class_id
  validates_presence_of :round
end

# 誰がどのチームの何将か(団体戦)
class ContestTeamMember
  include ModelBase
  property :user_id, Integer, unique_index: :u1, required: true
  belongs_to :user
  property :contest_team_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_team
  property :order_num, Integer, unique_index: :u1, required: true # 将順
end

# どのチームがどの級に出場しているか(団体戦)
class ContestTeam
  include ModelBase
  property :contest_class_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_class
  property :name, String, length: 48, unique_index: :u1, required: true # チーム名
  property :prize, String, length: 24 # チーム入賞
  property :rank, Integer # 順位
  property :promotion, Enum[:rank_up,:rank_down] # 昇級, 陥落
  has n, :members, 'ContestTeamMember'
  has n, :opponents, 'ContestTeamOpponent'
end

# 各チームが何回戦にどのチームと対戦したか(団体戦)
class ContestTeamOpponent
  include ModelBase
  property :contest_team_id, Integer, unique_index: :u1, required: true
  belongs_to :contest_team
  property :name, String, length: 48 # 対戦相手のチーム名
  property :round, Integer, unique_index: :u1, required: true
  property :round_name, String, length: 36
  property :comment, Text
  property :kind, Enum[:team, :single] # 団体戦, 個人戦
  has n, :games, 'ContestTeamGame'
end

# 試合結果(団体戦)
class ContestTeamGame < ContestGame
  belongs_to :contest_team_opponent, required: false
  property :opponent_order, Integer # 将順
  # TODO: how to create UNIQUE INDEX (user_id, contest_team_opponent_id) ?
  # we use unique verification instead
  validates_uniqueness_of :user_id, scope: [:contest_team_opponent_id]
  validates_presence_of :contest_team_opponent_id
end
