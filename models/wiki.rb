class WikiItem
  include ModelBase
  include ThreadBase
  property :deleted, ParanoidBoolean, lazy: false
  property :title, TrimString, length: 64, required: true, unique: true
  property :public, Boolean, default: false # 外部公開されているか
  property :body, TrimText, required: true
  property :revision, Integer, default: 0
  belongs_to :owner, 'User', required: false
  has n, :attacheds, 'WikiAttachedFile'
  has n, :item_logs, 'WikiItemLog'
  has n, :comments, 'WikiComment', child_key: [:thread_id] # コメント

  # get_revision_of を使うにはこの関数を実装しておく必要がある
  def patch_syms
    {
      cur_body: :body,
      last_rev: :revision,
      logs: :item_logs
    }
  end

end
class WikiItemLog
  include ModelBase
  include PatchBase
  property :wiki_item_id, Integer, unique_index: :u1, required: true
  belongs_to :wiki_item
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

# Wikiコメント
class WikiComment
  include ModelBase
  include CommentBase
  belongs_to :thread, 'WikiItem'
end
