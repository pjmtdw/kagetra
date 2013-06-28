# -*- coding: utf-8 -*-
# 大会/行事
class Event
  include ModelBase
  include ThreadBase
  property :deleted, ParanoidBoolean, lazy: false
  property :name, String, length: 48, required: true # 名称
  property :formal_name, String, length: 96, lazy:true # 正式名称
  property :official, Boolean, default: true # 公認大会
  property :kind, Enum[:contest, :practice, :party, :etc], default: :etc # 大会, 練習, コンパ, その他
  property :team_size, Integer, default: 1 # 1 => 個人戦, 3 => 3人団体戦, 5 => 5人団体戦
  property :description, Text # 備考
  property :deadline, Date # 締切
  property :date, Date # 日時 
  property :start_at, HourMin #開始時刻
  property :end_at, HourMin #終了時刻
  property :place, String, length: 255, lazy: true # 場所

  property :participant_count, Integer, default: 0 # 参加者数 (毎回aggregateするのは遅いのでキャッシュ)

  belongs_to :event_group, required: false
  belongs_to :aggregate_attr, 'UserAttributeKey' # 集計属性

  property :owners, Json, default: [] # 管理者一覧( User.id の配列 )
  property :forbidden_attrs, Json, default: [] # 登録不可属性 ( UserAttributeValue.id の配列 )
  property :show_choice, Boolean, default: true # ユーザがどれを選択したか表示する
  has n, :choices, 'EventChoice'
  has n, :result_classes, 'ContestClass' # 大会結果の各級の情報
  has n, :result_users, 'ContestUser' # 大会結果の出場者
  has n, :comments, 'EventComment', child_key: [:thread_id] # コメント
  # TODO: validate owners and forbidden_attrs is array of integer
end

# 行事のグループ
class EventGroup
  include ModelBase
  property :name, String, length: 60, required: true
  property :description, Text
  has n, :events
end

# 行事の選択肢
class EventChoice
  include ModelBase
  property :name, String, length: 24, required: false
  property :positive, Boolean, required: true # 参加する, はい などの前向きな回答
  property :show_result, Boolean, default: true # 回答した人の一覧を表示する
  property :index, Integer, required: true # 順番
  belongs_to :event
  # 注意: EventUserChiceにはuserがnilのものも存在するので user_choices.count と users.count は一致しない
  has n, :user_choices,'EventUserChoice'
  has n, :users, through: :user_choices , via: :user
end

# どのユーザがどの選択肢を選んだか
class EventUserChoice
  include ModelBase
  belongs_to :event_choice
  property :user_name, String, length: 24, allow_nil: false # 後に改名する人やUserにない人を登録できるようにするため用意しておく
  belongs_to :user, required: false # Userにない人を登録できるようにするため required: false にしておく
  property :attr_value_id, Integer, allow_nil: false
  belongs_to :attr_value, 'UserAttributeValue'

  before :save do
    if self.user then
      self.user_name = self.user.name
      self.event_choice.event.tap{|ev|
        self.attr_value = self.user.attrs.values.first(attr_key: ev.aggregate_attr)
        # 一つの行事を複数選択することはできない
        ev.choices.user_choices(user:self.user).destroy
      }
    end
  end
  after :save do
    self.event_choice.event.tap{|ev|
      if ev then
        # 参加者数の更新
        ev.update(participant_count:ev.choices(positive: true).user_choices.count)
      end
    }
  end
end

# 大会/行事のコメント
class EventComment
  include ModelBase
  include CommentBase
  belongs_to :thread, 'Event'
end
