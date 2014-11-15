module PatchedItem
  # the included module have to implement `patch_syms` method
  def self.included(base)
    base.class_eval do
      def each_revisions_until(limit,&block)
        Enumerator.new{|enu|
          cur = self.send(patch_syms[:cur_body]).to_s
          last_rev = self.send(patch_syms[:last_rev])
          revs = last_rev.downto(last_rev-limit+1).to_a
          logs = self.send(patch_syms[:logs]).where(revision:revs).order(Sequel.desc(:revision))
          enu.yield ({text:cur})
          logs.each{|lg|
            p = lg.patch
            ps = G_DIMAPA.patch_fromText(p)
            (cur,_) = G_DIMAPA.patch_apply(ps,cur)
            enu.yield ({text:cur, log:lg})
          }
        }.each(&block)
      end
      def each_diff_htmls_until(limit,offset=0,&block)
        Enumerator.new{|enu|
          arr = each_revisions_until(limit+offset).to_a[offset..-1]
          if arr.nil?.! and arr.length >= 2 then
            arr[0...-1].zip(arr[1..-1]).each{|cur,prev|
              ctxt = cur[:text].escape_html
              ptxt = prev[:text].escape_html
              next if ctxt == ptxt
              diffs = G_DIMAPA.diff_main(ptxt,ctxt)
              html = G_DIMAPA.diff_prettyHtml(diffs)
              enu.yield ({html:html,log:prev[:log]} )
            }
          end
        }.each(&block)
      end
    end
  end
end

module UserEnv
  def self.included(base)
    def set_env(req)
      addr = req.ip
      agent = req.user_agent
      host =
        begin
          Resolv.getname(addr)
        rescue Resolv::ResolvError => e
          nil
        end
      # TODO: DRY way to get the length of property ?
      self.remote_host = if host then host[0...72] end
      self.remote_addr = if addr then addr[0...48] end
      self.user_agent = if agent then agent[0...255] end
    end
  end
end
#
module CommentBase
  # このモジュールをincludeするクラスは many_to_one :thread を持たなければならない
  # TODO: include時に many_to_one :thread の引数を指定できない？
  def self.included(base)
    base.class_eval do
      many_to_one :user
      original_commentbase_before_save = instance_method(:before_save)
      original_commentbase_after_create = instance_method(:after_create)
      original_commentbase_after_destroy = instance_method(:after_destroy)
      define_method (:before_save){
        if self.user and self.user_name.to_s.empty? then
          self.user_name = self.user.name
        end
        if self.user and self.user_name != self.user.name then
          self.real_name = self.user.name
        end
        original_commentbase_before_save.bind(self).()
      }
      define_method(:after_create){
        # コメント数の更新
        th = self.thread
        th.update(comment_count: th.comments.count,
                  last_comment_user_id: self.user.id,
                  last_comment_date: self.created_at)
        original_commentbase_after_create.bind(self).()
      }
      define_method(:after_destroy){
        th = self.thread
        th.update(comment_count: th.comments.count)
        original_commentbase_after_destroy.bind(self).()
      }
      def is_new(user)
        user.nil?.! and
        (self.user_id.nil? or self.user_id != user.id) and
        user.show_new_from.nil?.! and
        self.created_at >= user.show_new_from
      end
      def editable(user)
        user.nil?.! and (user.admin || (self.user_id && self.user_id == user.id))
      end
      def show(user,public_mode)
        r = self.select_attr(:id,:body,:user_name).merge(
          {
            date: self.created_at.strftime("%Y-%m-%d %H:%M"),
            is_new: self.is_new(user),
            editable: self.editable(user)
          })
        if not public_mode then
          r[:real_name] = self.real_name if self.real_name
        end
        r
      end
    end
  end
end

module ThreadBase
  # このモジュールをincludeするクラスは one_to_many :comments を持たなければならない
  # TODO: include時に one_to_many :comments の引数を指定できない？
  def self.included(base)
    base.class_eval do
      def self.new_threads(user,cond=nil)
        search_from = [user.show_new_from||Time.now,Time.now-G_NEWLY_DAYS_MAX*86400].max
        c0 = Sequel.expr{last_comment_date >= search_from}
        if cond then
          c0 = c0 & Sequel.expr(cond)
        end
        c1 = Sequel.expr(last_comment_user_id:nil)
        c2 = Sequel.~(last_comment_user_id:user.id)

        self.where(c0 & (c1 | c2)).order(Sequel.desc(:last_comment_date))
      end
      def has_new_comment(user)
        return false if user.nil?
        if self.last_comment_date.nil?.! then
          if user.show_new_from.nil?.! then
            if self.last_comment_date > user.show_new_from and
              (self.last_comment_user_id.nil? or self.last_comment_user_id != user.id) then
                return true
            end
          end
        end
        false
      end
    end
  end
end

class MyConf < Sequel::Model(:my_confs)
  plugin :serialization, :json, :value
end
