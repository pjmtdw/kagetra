# -*- coding: utf-8 -*-
# 大会/行事
class Event < Sequel::Model(:events)
  include ThreadBase
  serialize_attributes Kagetra::serialize_enum([:contest, :party, :etc]), :kind
  plugin :serialization, :hourmin, :start_at, :end_at
  plugin :serialization, :json, :owners, :forbidden_attrs

  many_to_one :event_group
  many_to_one :aggregate_attr, class:'UserAttributeKey'

  one_to_one :result_cache, class:'ContestResultCache'

  many_to_many :album_groups, class:'AlbumGroup', join_table: :album_group_event

  one_to_many :choices, class:'EventChoice'
  one_to_many :result_classes, class:'ContestClass'
  one_to_many :result_users, class:'ContestUser'
  one_to_many :comments, class:'EventComment', key: :thread_id
  def validate
    super
    error.add(:date,"cannot be null for contest") if self.kind == :contest and self.date.nil?
    error.add(:owners,"is invalid") unless self.owners.all?{|o| o.is_a?(Integer) and User.get(o) }
    error.add(:forbidden_attrs,"is invalid") unless self.forbidden_attrs.all?{|o| o.is_a?(Integer) and UserAttributeValue.get(o) }
  end
  def self.new_events(user)
    search_from = [user.show_new_from||DateTime.now,DateTime.now-G_NEWLY_DAYS_MAX].max
    self.all(done:false,:created_at.gte => search_from,order: [:created_at.desc])
  end
  def self.my_events(user)
    evs = self.all(done:false)
    if user.admin
      return evs
    end
    evs.select{|x|x.owners.include?(user.id)}
  end
  def self.new_participants(user)
    search_from = [user.show_new_from||DateTime.now,DateTime.now-G_NEWLY_DAYS_MAX].max
    self.my_events(user).map{|ev|
      all = ev.choices(positive: true).user_choices.all(:created_at.gte => search_from)
      res = [ev.id,ev.name,all.map{|x|x.user_name}]
      if all.empty? then nil else res end
    }.compact
  end
  def create_result_cache
    if self.result_cache.nil? then
      self.result_cache = ContestResultCache.new
      self.save
    end
  end
  def update_cache_prizes
    self.create_result_cache
    self.result_cache.update_prizes
  end
  def update_cache_winlose
    self.create_result_cache
    self.result_cache.update_winlose
  end
end

# 行事のグループ
class EventGroup < Sequel::Model(:event_groups)
  one_to_many :events
end

# 行事の選択肢
class EventChoice < Sequel::Model(:event_choices)
  many_to_one :event
  # 注意: EventUserChoiceにはuserがnilのものも存在するので user_choices.count と users.count は一致しない
  one_to_many :user_choices, class:'EventUserChoice'
  # TODO
  # one_to_many :users, through: :user_choices , via: :user
end

# どのユーザがどの選択肢を選んだか
class EventUserChoice < Sequel::Model(:event_user_choices)
  many_to_one :event_choice
  many_to_one :user
  many_to_one :attr_value, class:'UserAttributeValue'

  def before_save
    super
    if self.user then
      self.user_name = self.user.name
      self.event_choice.event.tap{|ev|
        if self.attr_value.nil? then
          self.attr_value = self.user.attrs.values.first(attr_key: ev.aggregate_attr)
        end
        # 一つの行事を複数選択することはできない
        ucs = ev.choices.user_choices(user:self.user)
        if ucs.empty?.! and ucs.first.event_choice.positive then
          self.cancel = true
        end
        ucs.destroy
      }
    end
  end
  ["save","destroy"].each{|sym|
    define_method(("after_"+sym).to_sym){
      self.event_choice.event.tap{|ev|
        if ev then
          # 参加者数の更新
          ev.update(participant_count:ev.choices(positive: true).user_choices.count)
        end
      }
    }
  }
end

# 大会/行事のコメント
class EventComment < Sequel::Model(:event_comments)
  #include CommentBase
  many_to_one :thread, class:'Event'
end
