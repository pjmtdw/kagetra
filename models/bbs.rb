class BbsThread
  include ModelBase
  property :title,         String, length: 48, required: true
  property :public,        Boolean, default: false
  property :deleted,       ParanoidBoolean
  belongs_to :first_item, 'BbsItem', required: false
  has n, :bbs_item
end

class BbsItem
  include ModelBase
  property :deleted, ParanoidBoolean
  property :body,  Text, required: true
  property :user_name,  String, length: 24, required: true
  property :user_host,  Text
  belongs_to :user, required: false
  belongs_to :bbs_thread
end
