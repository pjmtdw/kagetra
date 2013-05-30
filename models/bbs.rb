# -*- coding: utf-8 -*-

# 掲示板のスレッド
class BbsThread
  include ModelBase
  property :title,         String, length: 48, required: true
  property :public,        Boolean, default: false  # 公開されているか
  property :deleted,       ParanoidBoolean # 削除済み
  belongs_to :first_item, 'BbsItem', required: false # スレッドの最初の書き込み
  has n, :bbs_item
end

# 掲示板の書き込み
class BbsItem
  include ModelBase
  property :deleted, ParanoidBoolean
  property :body,  Text, required: true # 内容
  property :user_name,  String, length: 24, required: true # 書き込んだ人の名前
  property :user_host,  Text
  belongs_to :user, required: false # 内部的なユーザID
  belongs_to :bbs_thread
end
