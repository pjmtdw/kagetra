# -*- coding: utf-8 -*-
# 大会/行事
class Event < Sequel::Model(:events)
  include ThreadBase
  serialize_attributes Kagetra::serialize_enum([:contest, :party, :etc]), :kind
  plugin :serialization, :hourmin, :start_at, :end_at
  plugin :serialization, :json, :forbidden_attrs

  many_to_one :event_group
  many_to_one :aggregate_attr, class:'UserAttributeKey'

  one_to_one :result_cache, class:'ContestResultCache'

  many_to_many :album_groups, class:'AlbumGroup', join_table: :album_group_events
  many_to_many :owners, class:'User', right_key: :user_id, join_table: :event_owners

  one_to_many :choices, class:'EventChoice'
  one_to_many :result_classes, class:'ContestClass'
  one_to_many :result_users, class:'ContestUser'
  one_to_many :comments, class:'EventComment', key: :thread_id
  
  # serialized されたカラムを where 検索するのに必要
  def self.kind_contest
    self.serialization_map[:kind].call(:contest)
  end
  def validate
    super
    error.add(:date,"cannot be null for contest") if self.kind == :contest and self.date.nil?
    error.add(:forbidden_attrs,"is invalid") unless self.forbidden_attrs.all?{|o| o.is_a?(Integer) and UserAttributeValue[o] }
  end
  def self.new_events(user)
    search_from = [user.show_new_from||Time.now,Time.now-G_NEWLY_DAYS_MAX*86400].max
    self.where(done:false).where{created_at >= search_from}.order(Sequel.desc(:created_at))
  end
  def self.my_events(user)
    evs = self.where(done:false)
    if user.admin
      evs
    else
      evs.where(owners:user)
    end
  end
  def self.new_participants(user)
    search_from = [user.show_new_from||Time.now,Time.now-G_NEWLY_DAYS_MAX*86400].max
    self.my_events(user).map{|ev|
      all = EventUserChoice.where(event_choice:ev.choices_dataset.where(positive:true)).where{created_at >= search_from}.all
      res = [ev.id,ev.name,all.map(&:user_name)]
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
  many_to_many :users, class:'User', right_key: :user_id, join_table: :event_user_choices
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
          self.attr_value = ev.aggregate_attr.attr_values_dataset.first(id:user.attrs.map(&:value_id))
        end
        # 一つの行事を複数選択することはできない
        ucs = EventUserChoice.where(user:self.user,event_choice:ev.choices)
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
          count = EventUserChoice.where(event_choice:ev.choices_dataset.where(positive: true)).count
          ev.update(participant_count:count)
        end
      }
    }
  }
end

# 大会/行事のコメント
class EventComment < Sequel::Model(:event_comments)
  include CommentBase
  many_to_one :thread, class:'Event'
end

# 大会/行事の所有者
class EventOwner < Sequel::Model(:event_owners)
  many_to_one :user
  many_to_one :event
end
