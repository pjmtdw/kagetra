# -*- coding: utf-8 -*-

class BbsThread < Sequel::Model(:bbs_threads)
  include ThreadBase
  one_to_many :comments, class:'BbsItem', key: :thread_id
end

class BbsItem < Sequel::Model(:bbs_items)
  include CommentBase
  many_to_one :thread, class:'BbsThread'
  # include した CommentBase の中で各model hookをmonkey patchingしてるのでオリジナルを呼べるようにしておく
  original_bbsitem_before_save = instance_method(:before_save)
  original_bbsitem_after_crate = instance_method(:after_create)
  define_method(:before_save){
    if self.user_name.to_s.empty? and self.thread.public and self.user and self.user.bbs_public_name.to_s.empty?.! then
      self.user_name = self.user.bbs_public_name
    end
    original_bbsitem_before_save.bind(self).()
    super
  }
  define_method(:after_create){
    th = self.thread
    if th.first_item.nil? then
      th.update(first_item: self)
    end
    original_bbsitem_after_crate.bind(self).()
    super
  }
end

