# -*- coding: utf-8 -*-

# 予定表の祝日の情報
class ScheduleDateInfo
  include ModelBase
  property :date, Date, unique: true, required: true
  property :names, Json, default: []
  property :holiday, Boolean, default: false # 休日かどうか
end

# 予定表のアイテム
class ScheduleItem
  include ModelBase
  property :type, Enum[:practice, :party, :etc], default: :etc #練習, コンパ, その他
  property :public, Boolean, default: true # 公開されているか
  property :notify, Boolean, default: false # 期日が迫ったときに通知するか
  property :emphasis, Flag[:start, :end, :place]  # 強調表示 => 開始時刻, 終了時刻, 場所
  property :title, String, length: 48, required: true
  property :date, Date, index: true, required: true # 日時
  property :start_at, HourMin # 開始時刻
  property :end_at, HourMin # 終了時刻
  property :place, String, length: 48 # 場所
  property :description, Text # 説明

  belongs_to :user

  before :save do
    self.notify = true if (self.emphasis and self.emphasis.empty?.!)
  end
end
