class BbsThread
  include ModelBase
  property :title,         String, length: 48
  property :public,        Boolean, default: false
  property :deleted,       Boolean, default: false
  belongs_to :first_item, 'BbsItem', required: false
  has n, :bbs_item
end

class BbsItem
  include ModelBase
  property :deleted, Boolean, default: false
  property :body,  Text
  property :user_name,  String, length: 24
  property :user_host,  Text
  belongs_to :user, required: false
  belongs_to :bbs_thread
end
