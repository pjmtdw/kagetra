# -*- coding: utf-8 -*-

# 予定表の祝日の情報
class ScheduleDateInfo
  include ModelBase
  property :date, Date, unique: true, required: true
  property :names, Json, default: []
  property :holiday, Boolean, default: false # 休日かどうか
end

module ScheduleItemBase
  def self.included(base)
    base.class_eval do
      include ModelBase
      p = DataMapper::Property
      property :kind, p::Enum[:practice, :party, :etc], default: :etc #練習, コンパ, その他
      property :public, p::Boolean, default: true # 公開されているか
      property :emphasis, p::Flag[:title, :start_at, :end_at, :place, :description]  # 強調表示 => タイトル, 開始時刻, 終了時刻, 場所, コメント
      property :title, p::String, length: 48, required: true
      property :start_at, p::HourMin # 開始時刻
      property :end_at, p::HourMin # 終了時刻
      property :place, p::String, length: 48 # 場所
      property :description, p::Text # 説明
    end
  end
end

# 予定表のアイテム
class ScheduleItem
  include ScheduleItemBase
  property :date, Date, index: true, required: true # 日付
  belongs_to :user
end

# 毎週の予定
class ScheduleWeekly
  include ScheduleItemBase
  property :weekday, Integer # 0=日曜日, 1=月曜日, 2=火曜日, ...
end
