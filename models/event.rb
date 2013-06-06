# -*- coding: utf-8 -*-
# 行事
class Event
  include ModelBase
  property :deleted, ParanoidBoolean
  property :name, String, length: 48, required: true # 名称
  property :formal_name, String, length: 96 # 正式名称
  property :official, Boolean, default: true # 公認大会
  property :kind, Enum[:contest, :practice, :party, :etc], default: :etc # 大会, 練習, コンパ, その他
  property :num_teams, Integer, default: 1 # 1 => 個人戦, 3 => 3人団体戦, 5 => 5人団体戦
  property :description, Text # 備考
  property :deadline, Date # 締切
  property :date, Date # 日時 
  property :start_at, HourMin #開始時刻
  property :end_at, HourMin #終了時刻
  property :place, String, length: 256 # 場所
  belongs_to :event_group, required: false
  belongs_to :aggregate_attr, 'UserAttributeKey', required: false # 集計属性
  # TODO: through: DataMapper::Resource で自動的に作られるテーブルには created_at, updated_atがない
  has n, :owners, 'User' , through: DataMapper::Resource # 管理者
  has n, :forbidden_attrs, 'UserAttributeValue', through: DataMapper::Resource # 登録不可属性
  property :show_choice, Boolean, default: true # ユーザがどれを選択したか表示する
  has n, :choices, 'EventChoice'
  has n, :result_classes, 'ContestClass' # 大会結果の各級の情報
end

# 行事のグループ
class EventGroup
  include ModelBase
  property :name, String, length: 60, required: true
  property :description, Text
end

# 行事の選択肢
class EventChoice
  include ModelBase
  property :name, String, length: 24, required: false
  property :positive, Boolean, required: true # 参加する, はい などの前向きな回答
  property :show_result, Boolean, default: true # 回答した人の一覧を表示する
  property :index, Integer, required: true # 順番
  belongs_to :event
  has n, :user_choices,'EventUserChoice'
  has n, :users, through: :user_choices , via: :user
end

# どのユーザがどの選択肢を選んだか
class EventUserChoice
  include ModelBase
  belongs_to :event_choice
  belongs_to :user

  # 一つの行事を複数選択することはできない
  before :save do
    self.event_choice.event.tap{|x|
      x.choices.user_choices(user:self.user).destroy if x
    }
  end
end

