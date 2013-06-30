# -*- coding: utf-8 -*-

# 掲示板のスレッド
class BbsThread
  include ModelBase
  include ThreadBase
  property :deleted,       ParanoidBoolean, lazy: false # 自動的に付けられる削除済みフラグ
  property :title,         TrimString, length: 48, required: true
  property :public,        Boolean, default: false  # 公開されているか
  belongs_to :first_item, 'BbsItem', required: false # スレッドの最初の書き込み
  has n, :comments, 'BbsItem', child_key: [:thread_id] 
end

# 掲示板の書き込み
class BbsItem
  include ModelBase
  include CommentBase
  belongs_to :thread, 'BbsThread'
  before :save do
    if self.thread.public and self.user and self.user.bbs_public_name.to_s.empty?.! then
      self.user_name = self.user.bbs_public_name
    end
  end
  after :create do
    th = self.thread
    if th.first_item.nil? then
      th.update(first_item: self)
    end
  end
end

