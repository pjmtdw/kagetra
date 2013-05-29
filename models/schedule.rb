class ScheduleDateInfo
  include ModelBase
  property :names, Json, default: []
  property :holiday, Boolean, default: false
  property :date, Date, unique: true, required: true
end

class ScheduleItem
  include ModelBase
  property :type, Enum[:compa, :train, :etc], default: :etc
  property :public, Boolean, default: true
  property :notify, Boolean, default: false
  property :emphasis, Flag[:start, :end, :place]
  property :title, String, length: 48, required: true
  property :date, Date, index: true, required: true
  property :start_at, HourMin
  property :end_at, HourMin
  property :place, String, length: 48
  property :description, Text
  
  belongs_to :user

  before :save do
    self.notify = true if (self.emphasis and self.emphasis.empty?.!)
  end
end
