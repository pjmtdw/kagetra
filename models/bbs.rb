# -*- coding: utf-8 -*-

class BbsThread < Sequel::Model(:bbs_threads)
  include ThreadBase
  one_to_many :comments, class:'BbsItem', key: :thread_id
  many_to_one :last_comment_user, class: 'User'

end

class BbsItem < Sequel::Model(:bbs_items)
  include CommentBase
  include UserEnv
  many_to_one :thread, class:'BbsThread'
  many_to_one :user, class:'User'
  # include した CommentBase の中で各model hookをmonkey patchingしてるのでオリジナルを呼べるようにしておく
  original_bbsitem_before_save = instance_method(:before_save)
  define_method(:before_save){
    if self.user_name.to_s.empty? and self.thread.public and self.user and self.user.bbs_public_name.to_s.empty?.! then
      self.user_name = self.user.bbs_public_name
    end
    original_bbsitem_before_save.bind(self).()
    super()
  }
end

