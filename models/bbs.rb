# -*- coding: utf-8 -*-

# 掲示板のスレッド
class BbsThread
  include ModelBase
  property :deleted,       ParanoidBoolean # 自動的に付けられる削除済みフラグ
  property :title,         String, length: 48, required: true
  property :public,        Boolean, default: false  # 公開されているか
  belongs_to :first_item, 'BbsItem', required: false # スレッドの最初の書き込み
  has n, :items, 'BbsItem'
end

# 掲示板の書き込み
class BbsItem
  include ModelBase
  include CommentBase
  belongs_to :bbs_thread
end
