# -*- coding: utf-8 -*-
# 行事
class Event
  include ModelBase
  property :deleted, ParanoidBoolean
  property :done, Boolean, index: true # 過去の大会かどうか
  property :name, String, length: 48, required: true # 名称
  property :formal_name, String, length: 96 # 正式名称
  property :official, Boolean, default: true # 公認大会
  property :type, Enum[:contest, :practice, :party, :etc], default: :etc # 大会, 練習, コンパ, その他
  property :num_teams, Integer, default: 1 # 1 => 個人戦, 3 => 3人団体戦, 5 => 5人団体戦
  property :desciprtion, Text # 備考
  property :deadline, Date # 締切
  property :date, Date # 日時 
  property :start_at, HourMin #開始時刻
  property :end_at, HourMin #終了時刻
  property :place, String, length: 96 # 場所
  belongs_to :event_group
  # belongs_to :aggregate_attr 'UserAttributeKey' # 集計属性
  # has n, :owner, 'User' # 管理者
  property :show_choice, Boolean, default: true # ユーザがどれを選択したか表示する
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
  property :name, String, length: 24, required:true
  property :positive, Boolean, required: true # 参加する, はい などの前向きな回答
  property :show_result, Boolean, default: true # 回答した人の一覧を表示する
  property :index, Integer, required: true # 順番
  belongs_to :event
  has n, :user, through: :event_choice_user
end

# どのユーザがどの選択肢を選んだか
class EventChoiceUser
  include ModelBase
  belongs_to :event_choice
  # we cannot set :unique_index => <index_name> directly to belongs_to
  # this creates UNIQUE INDEX `unique_<table_name>_u1` ON `<table_name>` (`user_id`,`event_id`)
  property :user_id, Integer, unique_index: :u1, required: true
  property :event_id, Integer, unique_index: :u1, required: true
  belongs_to :user
  belongs_to :event
end

