# -* coding: utf-8 -*-

# アルバムのグループ
class AlbumGroup
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  property :name, TrimString, length: 72
  property :place, TrimString, length: 128 # 場所
  property :comment, TrimText
  belongs_to :owner, 'User', required: false

  property :start_at, Date # 開始日
  property :end_at, Date # 終了日

  property :dummy, Boolean, index: true, default: false # どのグループにも属していない写真のための擬似的なグループ
  property :year, Integer, index: true # 年ごとの集計のためにキャッシュする

  property :daily_choose_count, Integer, default: 0 # 所属写真の今日の一枚の選ばれる数
  property :has_comment_count, Integer, default: 0 # コメントの入っている写真の数
  property :has_tag_count, Integer, default: 0 # タグの入っている写真の数
  property :item_count, Integer, default: 0 # 毎回aggregateするのは遅いのでキャッシュ
  has n, :items, 'AlbumItem', child_key: [:group_id]
  before :save do
    if not self.dummy then
      self.year = if self.start_at.nil? then nil else start_at.year end
    end
  end
  def update_count
    # item_countのupdateは本当はAlbumItemのcreate時だけでいいけど
    # ParanoidBooleanとの都合上update(deleted:true)みたいなことしないといけないので
    # update時にも毎回更新する
    dc = self.items(daily_choose:true).count
    hc = self.items(:comment.not => nil).count
    ic = self.items.count
    tc = self.items(:tag_count.gt => 0).count
    self.update!(daily_choose_count:dc,has_comment_count:hc,item_count:ic,has_tag_count:tc)
  end
end

# アルバムの各写真の情報
class AlbumItem
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  property :name, TrimString, length: 72
  property :place, TrimString, length: 128 # 場所
  belongs_to :owner, 'User', required: false
  property :comment, TrimText
  property :comment_revision, Integer, default: 0, index: true
  property :comment_updated_at, DateTime, index: true

  property :date , Date # 撮影日
  property :hourmin , HourMin # 撮影時刻
  property :daily_choose, Boolean, default: true # 今日の一枚として選ばれるかどうか
  property :group_id, Integer,  required: true, index: true
  belongs_to :group, 'AlbumGroup'
  property :group_index, Integer, allow_nil: false # グループの中での表示順
  property :rotate, Integer, default:0 # 回転 (右向き, 0,90,180,270のどれか)
  property :orig_filename, String, length: 128, lazy: true # アップロードされた元のファイル名

  property :tag_count, Integer, default: 0

  has 1, :photo, 'AlbumPhoto'
  has 1, :thumb, 'AlbumThumbnail'
  has n, :tags, 'AlbumTag'

  property :tag_names, Text # タグ名の入った配列をJSON化したもの(like検索用なので型JsonじゃなくてText)

  # 順方向の関連写真
  has n, :album_relations_r, 'AlbumRelation', child_key: [:source_id]
  has n, :relations_r, self, through: :album_relations_r, via: :target
  # 逆方向の関連写真
  has n, :album_relations_l, 'AlbumRelation', child_key: [:target_id]
  has n, :relations_l, self, through: :album_relations_l, via: :source

  has n, :comment_logs, 'AlbumCommentLog' # コメントの編集履歴


  validates_with_block(:rotate){
    if not [0,90,180,270].include?(self.rotate.to_i) then
      [false, "rotate must be one of 0,90,180,270 not #{self.rotate}"]
    else
      true
    end
  }

  before :create do
    if self.group_index.nil? then
      ag = self.group
      self.group_index = ag.items.count
    end
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
    self.update!(tag_count:self.tags.count,tag_names:tag_names)
    self.group.update_count
  end
  after :save do
    self.group.update_count
  end

  # 順方向と逆方向の両方の関連写真
  def relations
    self.relations_r + self.relations_l
  end

  # each_revisions_until を使うにはこの関数を実装しておく必要がある
  def patch_syms
    {
      cur_body: :comment,
      last_rev: :comment_revision,
      logs: :comment_logs
    }
  end
end

# 関連写真
class AlbumRelation
  include ModelBase
  property :source_id, Integer, unique_index: :u1, required: true, index: true
  belongs_to :source, 'AlbumItem'
  property :target_id, Integer, unique_index: :u1, required: true, index: true
  belongs_to :target, 'AlbumItem'
  # (source,target) と (target,source) はどちらかしか存在できない
  after :save do
    r = self.class.first(source:self.target, target:self.source)
    if r.nil?.! then r.destroy end
  end
end

# サムネイルと写真両方に共通する情報
module AlbumBase
  def self.included(base)
    base.class_eval do
      p = DataMapper::Property
      property :path, p::FilePath, required: true, unique: true
      property :width, p::Integer
      property :height, p::Integer
      property :format, p::String
      belongs_to :album_item, unique: true
    end
  end
end

# 実際の写真
class AlbumPhoto
  include ModelBase
  include AlbumBase
end
# サムネイル
class AlbumThumbnail
  include ModelBase
  include AlbumBase
end

# コメントの編集履歴(created_atが編集日時)
class AlbumCommentLog
  include ModelBase
  include PatchBase
  property :album_item_id, Integer, unique_index: :u1, required: true
  belongs_to :album_item
  after :save do
    self.album_item.update!(comment_updated_at:self.created_at)
  end
end

# タグ
class AlbumTag
  include ModelBase
  property :name, TrimString, required: true, index: true, remove_whitespace: true
  property :coord_x, Integer # 写真の中のX座標
  property :coord_y, Integer # 写真の中のY座標
  property :radius, Integer # 円の半径
  belongs_to :album_item
end
