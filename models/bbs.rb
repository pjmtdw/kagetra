class BbsThread
  include DataMapper::Resource
  property :id,            Serial
  property :created_at,    DateTime
  property :updated_at,    DateTime
  property :title,         Text

  belongs_to :user
  has n, :bbs_items
end

class BbsItem
  include DataMapper::Resource
  property :id,            Serial
  property :created_at,    DateTime
  property :updated_at,    DateTime
  property :body,          Text

  belongs_to :user
  belongs_to :bbs_thread
end
