# -*- coding: utf-8 -*-

class BbsThread < Sequel::Model(:bbs_threads)
  include ThreadBase
  one_to_many :comments, class: 'BbsItem', key: :thread_id
end

class BbsItem < Sequel::Model(:bbs_items)
  include CommentBase
  include UserEnv
  many_to_one :thread, class:'BbsThread'
  many_to_one :user, class:'User'
  def before_save
    if self.user_name.to_s.empty? and self.thread.public and self.user and self.user.bbs_public_name.to_s.empty?.! then
      self.user_name = self.user.bbs_public_name
    end
    super
  end
end
