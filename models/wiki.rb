class WikiItem
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  property :title, TrimString, length: 64, required: true, index: true
  property :public, Boolean, default: false # 外部公開されているか
  property :body, TrimText, required: true
  property :revision, Integer
end
class WikiItemLog
  include ModelBase
  property :wiki_item_id, Integer, unique_index: :u1, required: true
  belongs_to :wiki_item
  property :revision, Integer, unique_index: :u1, required: true # パッチの古い順(パッチを当てるときはcreated_atは信用しない)
  property :patch, Text # 逆向きのdiff ( $ diff new old )
  belongs_to :user, required: false # 編集者
end

# 添付ファイル
class WikiAttachedFile
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  belongs_to :owner, 'User'
  belongs_to :wiki_item
  property :path, FilePath
  property :orig_name, TrimString, length: 128 # 元の名前
  property :description, TrimText # 説明
  property :size, Integer, required: true
end