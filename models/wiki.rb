class WikiItem
  include ThreadBase
  many_to_one :owner, class:'User', required: false
  one_to_many, :attacheds, class:'WikiAttachedFile'
  one_to_many, :item_logs, class:'WikiItemLog'
  one_to_many, :comments, class:'WikiComment', key: :thread_id
 
  # TODO
  #validates_with_block :title do
  #  if self.title.include?("/")
  #    [false, "You cannot use '/' in title"]
  #  else
  #    true
  #  end
  #end


  # each_revisions_until を使うにはこの関数を実装しておく必要がある
  def patch_syms
    {
      cur_body: :body,
      last_rev: :revision,
      logs: :item_logs
    }
  end

end
class WikiItemLog
  one_to_many :wiki_item
  many_to_one :user
end

class WikiAttachedFile
  many_to_one :owner, class:'User'
  many_to_one :wiki_item
  def update_attached_count
    wi = self.wiki_item
    wi.update(attached_count:wi.attacheds.count)
  end
  # TODO
  # after :create, :update_attached_count
  # after :destroy, :update_attached_count
end

class WikiComment
  include CommentBase
  many_to_one :thread, class:'WikiItem'
end
