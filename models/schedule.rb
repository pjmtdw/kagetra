# -*- coding: utf-8 -*-

class ScheduleDateInfo < Sequel::Model(:schedule_date_infos)
  plugin :serialization, :json, :names
  set_default_values_custom :names, "[]"
end

class ScheduleItem < Sequel::Model(:schedule_items)
  serialize_attributes Kagetra::serialize_enum([:practice,:party,:etc]), :kind
  serialize_attributes Kagetra::serialize_flag([:name, :start_at, :end_at, :place]), :emphasis
  plugin :serialization, :hourmin, :start_at, :end_at
  many_to_one :owner, class:'User'
end
