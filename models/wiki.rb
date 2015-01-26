class WikiItem < Sequel::Model(:wiki_items)
  include ThreadBase
  include PatchedItem
  many_to_one :owner, class:'User', required: false
  one_to_many :attacheds, class:'WikiAttachedFile', key: :thread_id
  one_to_many :item_logs, class:'WikiItemLog'
  one_to_many :comments, class:'WikiComment', key: :thread_id
 
  def validate
    super
    error.add(:title,"must not include / ") if self.title.include?("/")
  end

  # each_revisions_until を使うにはこの関数を実装しておく必要がある
  def patch_syms
    {
      cur_body: :body,
      last_rev: :revision,
      logs: :item_logs_dataset
    }
  end

end
class WikiItemLog < Sequel::Model(:wiki_item_logs)
  many_to_one :wiki_item
  many_to_one :user
end

class WikiAttachedFile < Sequel::Model(:wiki_attached_files)
  include AttachedBase
  many_to_one :owner, class:'User'
  many_to_one :thread, class:'WikiItem'
end

class WikiComment < Sequel::Model(:wiki_comments)
  include CommentBase
  include UserEnv
  many_to_one :thread, class:'WikiItem'
end
