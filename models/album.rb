# -* coding: utf-8 -*-

class AlbumGroup < Sequel::Model(:album_groups)
  many_to_one :owner, class:'User'
  one_through_one :event, join_table: :album_group_events
  one_to_many :items, class:'AlbumItem', key: :group_id
  def before_save
    if not self.dummy then
      self.year = if self.start_at.nil? then nil else start_at.year end
    end
    super
  end
  def update_count
    # item_countのupdateは本当はAlbumItemのcreate/destroy時だけでいいけど
    # update時にも毎回更新する
    # TODO: これはDataMapperを使ってたころの名残りなので create/destroy時だけで良いと思ったら該当部分を削除すること
    dc = self.items_dataset.where(daily_choose:true).count
    hc = self.items_dataset.where(Sequel.~(comment:nil)).count
    ic = self.items_dataset.count
    tc = self.items_dataset.where{tag_count > 0}.count
    self.update!(daily_choose_count:dc,has_comment_count:hc,item_count:ic,has_tag_count:tc)
  end
end

class AlbumItem < Sequel::Model(:album_items)
  include PatchedItem
  many_to_one :owner, class:'User'
  plugin :serialization, :hourmin, :hourmin
  many_to_one :group, class:'AlbumGroup'

  one_to_one :photo, class:'AlbumPhoto'
  one_to_one :thumb, class:'AlbumThumbnail'
  one_to_many :tags, class:'AlbumTag'
  one_to_many :comment_logs, class:'AlbumCommentLog' # コメントの編集履歴

  # 順方向の関連写真
  many_to_many :right_relations, class:'AlbumItem', join_table: :album_relations, left_key: :source_id, right_key: :target_id
  # 逆方向の関連写真
  many_to_many :left_relations, class:'AlbumItem', join_table: :album_relations, left_key: :target_id, right_key: :source_id


  def validate
    super
    error.add(:rotate,"must be one of 0,90,180,270") unless [0,90,180,270].include?(self.rotate.to_i)
  end

  def before_create
    if self.group_index.nil? then
      ag = self.group
      self.group_index = ag.items_dataset.count
    end
    super
  end

  def id_with_thumb
    self.select_attr(:id,:rotate).merge({thumb:self.thumb.select_attr(:id,:width,:height)})
  end

  # 本来 tag_count や tag_names の更新は AlbumTag の :create, :destroy, :save Hookで行うべきだが
  # そうすると AlbumTag を例えば100個更新すると100回 AlbumItem が更新されるので凄く遅くなる．
  # したがって AlbumTag の更新をした後はこの関数を呼ぶという規約にする
  # TODO: 規約に頼らずHookとか使って上記のことを強制する方法
  def do_after_tag_updated
    tag_names = self.tags.map{|x|x.name}.to_json
    self.update!(tag_count:self.tags_dataset.count,tag_names:tag_names)
    self.group.update_count
  end
  def after_save
    super
    self.group.update_count
  end

  # 順方向と逆方向の両方の関連写真
  def relations
    self.right_relations + self.left_relations
  end

  # each_revisions_until を使うにはこの関数を実装しておく必要がある
  def patch_syms
    {
      cur_body: :comment,
      last_rev: :comment_revision,
      logs: :comment_logs_dataset
    }
  end
end

class AlbumRelation < Sequel::Model(:album_relations)
  many_to_one :source, class:'AlbumItem'
  many_to_one :target, class:'AlbumItem'
  # (source,target) と (target,source) はどちらかしか存在できない
  def after_save
    super
    r = self.class.first(source:self.target, target:self.source)
    if r.nil?.! then r.destroy end
  end
end

class AlbumPhoto < Sequel::Model(:album_photos)
  many_to_one :album_item, class:'AlbumItem'
end
class AlbumThumbnail < Sequel::Model(:album_thumbnails)
  many_to_one :album_item, class:'AlbumItem'
end

class AlbumCommentLog < Sequel::Model(:album_comment_logs)
  many_to_one :album_item
  many_to_one :user
  def after_save
    super
    self.album_item.update!(comment_updated_at:self.created_at)
  end
end

class AlbumTag < Sequel::Model(:album_tags)
  many_to_one :album_item
end

# アルバムと大会の関連
class AlbumGroupEvent < Sequel::Model(:album_group_events)
  many_to_one :album_group
  many_to_one :event
end
