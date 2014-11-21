# -*- coding: utf-8 -*-

class ScheduleDateInfo < Sequel::Model(:schedule_date_infos)
  plugin :serialization, :json, :names
  # MySQL では TEXT なカラムには DEFAULT を指定できないので Sequel の defaults_setter プラグインに頼る
  default_values[:names] = "[]"
end

class ScheduleItem < Sequel::Model(:schedule_items)
  serialize_attributes Kagetra::serialize_enum([:practice,:party,:etc]), :kind
  serialize_attributes Kagetra::serialize_flag([:name, :start_at, :end_at, :place]), :emphasis
  plugin :serialization, :hourmin, :start_at, :end_at
  many_to_one :owner, class:'User'
end
