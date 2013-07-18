module ModelBase
  def self.included(base)
    base.class_eval do
      include DataMapper::Resource
      p = DataMapper::Property
      property :id, p::Serial
      # Automatically set/updated by dm-timestamps
      property :created_at, p::DateTime, index: true, lazy: true
      property :updated_at, p::DateTime, index: true, lazy: true

      def self.all_month(prop,year,month)
        from = Date.new(year,month,1)
        to = from >> 1
        all(prop.gte => from, prop.lt => to)
      end

      def select_attr(*symbols)
        Hash[symbols.map{|s|
          [s,self.send(s)]
        }]
      end

      # for wiki and album comment
      # the included module have to implement `patch_syms` method
      def each_revisions_until(limit,&block)
        Enumerator.new{|enu|
          cur = self.send(patch_syms[:cur_body])
          last_rev = self.send(patch_syms[:last_rev])
          revs = last_rev.downto(last_rev-limit+1)
          logs = self.send(patch_syms[:logs]).all(revision:revs,order:[:revision.desc])
          enu.yield ({text:cur})
          logs.compact.each{|lg|
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

      def get_diffs_common(rev,s_cur_body,s_last_revision,s_logs)
      end
    end
  end
end

module UserEnv
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property
      property :remote_host, p::TrimString, length: 72, lazy: true 
      property :remote_addr, p::TrimString, length: 48, lazy: true
      property :user_agent, p::TrimString, length: 255, lazy: true
    end
    def set_env(req)
      # TODO: DRY way to get the length of property ?
      host = req.env["REMOTE_HOST"]
      addr = req.ip
      agent = req.user_agent
      self.remote_host = host[0...72] if host
      self.remote_addr = addr[0...48] if addr
      self.user_agent = agent[0...255] if agent
    end
  end
end

module CommentBase
  # このモジュールをincludeするクラスは belongs_to :thread を持たなければならない
  # TODO: include時に belongs_to :thread の引数を指定できない？
  def self.included(base)
    base.class_eval do
      include UserEnv
      p = DataMapper::Property 
      # ParanoidBooleanにはバグがあって lazy: true にしてしまうと関連モデルを直接取得したときの belong_to が nil になる
      # https://github.com/datamapper/dm-types/issues/52
      property :deleted, p::ParanoidBoolean, lazy: false
      property :body, p::TrimText, required: true # 内容
      property :user_name, p::TrimString, length: 24, allow_nil: false # 書き込んだ人の名前
      belongs_to :user, required: false # 内部的なユーザID

      before :save do
        if self.user_name.to_s.empty? and self.user then
          self.user_name = self.user.name
        end
      end
      after :create do
        # コメント数の更新
        th = self.thread
        th.update(comment_count: th.comments.count,
                  last_comment_user: self.user,
                  last_comment_date: self.created_at)
      end
      def is_new(user)
        user.nil?.! and
        (self.user_id.nil? or self.user_id != user.id) and 
        user.show_new_from.nil?.! and
        self.created_at >= user.show_new_from
      end
      def editable(user)
        user.nil?.! and (user.admin || (self.user_id && self.user_id == user.id))
      end
    end
  end
end

module PatchBase
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property 
      property :revision, p::Integer, unique_index: :u1, required: true
      property :patch, p::Text, required: true # 逆向きのdiff ( $ diff new old )
      belongs_to :user, required: false # 編集者
    end
  end
end

module ThreadBase
  # このモジュールをincludeするクラスは has n, :comments を持たなければならない
  # TODO: include時に has n, :comments の引数を指定できない？
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property 
      belongs_to :last_comment_user, 'User', required: false # スレッドに最後に書き込んだユーザ
      property :last_comment_date, p::DateTime, index: true # スレッドに最後に書き込んだ日時
      property :comment_count, Integer, default: 0 # コメント数 (毎回aggregateするのは遅いのでキャッシュ)
      def self.new_threads(user,cond={})
        search_from = [user.show_new_from,DateTime.now-G_NEWLY_DAYS_MAX].max
        c0 = self.all(
          cond.merge({:last_comment_date.gte => search_from}))
        c1 = self.all(:last_comment_user_id => nil)
        c2 = self.all(:last_comment_user_id.not => user.id)
        (c0 & (c1 | c2)).all(order: [:last_comment_date.desc])
      end
    end
  end
end

module DataMapper
  module Model
    # copied from http://blog.tquadrado.com/2010/datamapper-update_or_create/
    # update_or_create method: finds and updates, or creates;
    #   -upon create, returns the object
    #   -upon update, returns the object (by default, returned True)
    # @param[Hash] Conditions hash for the search query.
    # @param[Hash] Attributes hash with the property value for the update or creation of a new row.
    # @param[Boolean] Merger is a boolean that determines if the conditions are merged with the attributes upon create.
    #   If true, merges conditions to attributes and passes the merge to the create method;
    #   If false, only attributes are passed into the create method
    # @return[Object] DataMapper object 
    def update_or_create(conditions = {}, attributes = {}, merger = true)
      if (row = first(conditions))
        row.update(attributes)
        row
      else
        create(merger ? (conditions.merge(attributes)) : attributes )
      end
    end
  end
  class Property
    class HourMin < DataMapper::Property::String
      def custom?
        true
      end
      def load(value)
        case value
        when ::String
          ::Kagetra::HourMin.parse(value)
        when ::NilClass,::Kagetra::HourMin
          value
        else
          raise Exception.new("invalid class: #{value.class.name}")
        end
      end
      def dump(value)
        case value
        when ::NilClass,::String
          value
        when ::Kagetra::HourMin
          value.to_s
        else
          raise Exception.new("invalid class: #{value.class.name}")
        end
      end
      def typecast(value)
        load(value)
      end
    end
  end
  class Property
    class TrimString < DataMapper::Property::String
      accept_options :remove_whitespace
      remove_whitespace(false)
      def initialize(model, name, options = {})
        super
        @remove_whitespace = options.fetch(:remove_whitespace,false) 
      end
      def custom?
        true
      end
      def dump(value)
        return nil if value.nil?
        r = value.to_s.strip
        if @remove_whitespace then
          r.gsub!(/\s+/,"")
        end
        if r.empty? then nil else r end
      end
    end
    class TrimText < DataMapper::Property::Text
      def custom?
        true
      end
      def dump(value)
        return nil if value.nil?
        r = value.to_s.strip
        if r.empty? then nil else r end
      end
    end
  end
end

class MyConf
  include ModelBase
  property :name, TrimString, length: 64, unique: true
  property :value, Json
end
