# -* coding: utf-8 -*-

# アルバムのグループ
class AlbumGroup
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  property :name, String, length: 72
  property :place, String, length: 128 # 場所
  property :comment, Text
  belongs_to :owner, 'User', required: false

  property :start_at, Date # 開始日
  property :end_at, Date # 終了日

  property :dummy, Boolean, index: true, default: false # どのグループにも属していない写真のための擬似的なグループ
  property :year, Integer, index: true # 年ごとの集計のためにキャッシュする

  property :priority, Float # 所属写真の今日の一枚の選ばれやすさの重み付き合計
  property :no_comment_count, Integer # コメントの入っていない写真の数
  property :no_tag_count, Integer # タグの入っていない写真の数
  property :item_count, Integer # 毎回aggregateするのは遅いのでキャッシュ
  has n, :items, 'AlbumItem', child_key: [:group_id]
  before :save do
    if not self.dummy then
      self.year = if self.start_at.nil? then nil else start_at.year end
    end
  end
end

# アルバムの各写真の情報
class AlbumItem
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  property :name, String, length: 72
  property :place, String, length: 128 # 場所
  belongs_to :owner, 'User', required: false
  property :comment, Text
  property :comment_revision, Integer

  property :date , Date # 撮影日
  property :hourmin , HourMin # 撮影時刻
  property :daily_choose, Boolean, default: true # 今日の一枚として選ばれるかどうか
  property :group_id, Integer, unique_index: :u1, required: true
  belongs_to :group, 'AlbumGroup'
  property :group_index, Integer, unique_index: :u1, allow_nil: false # グループの中での表示順
  property :rotate, Integer # 回転 (右向き, 度数法)

  has 1, :photo, 'AlbumPhoto'
  has 1, :thumb, 'AlbumThumbnail'
  has n, :tags, 'AlbumTag'

  has n, :album_relations, child_key: [:source_id]
  has n, :relations, self, through: :album_relations, via: :target
  has n, :comment_logs, 'AlbumCommentLog' # コメントの編集履歴
  before :create do
    if self.group_index.nil? then
      ag = self.group
      self.group_index = ag.items.count
    end
  end
  after :create do
    ag = self.group
    ag.update(item_count: ag.items.count)
  end
end

# 関連写真
class AlbumRelation
  include ModelBase
  # TODO: (source, target) と (target, sorce) を同じものとみなす
  property :source_id, Integer, unique_index: :u1, required: true, index: true
  belongs_to :source, 'AlbumItem', key: true
  property :target_id, Integer, unique_index: :u1, required: true, index: true
  belongs_to :target, 'AlbumItem', key: true
end

# サムネイルと写真両方に共通する情報
module AlbumBase
  def self.included(base)
    base.class_eval do
      include DataMapper::Resource
      p = DataMapper::Property
      property :path, p::FilePath, required: true, unique: true
      property :width, p::Integer
      property :height, p::Integer
      belongs_to :album_item, key: true
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
  property :album_item_id, Integer, unique_index: :u1, required: true
  belongs_to :album_item
  property :revision, Integer, unique_index: :u1, required: true # パッチの古い順(パッチを当てるときはcreated_atは信用しない)
  property :patch, Text, required: true # 逆向きのdiff ( $ diff new old )
  belongs_to :user, required: false # 編集者
end

# タグ
class AlbumTag
  include ModelBase
  property :name, String, required: true
  property :coord_x, Integer # 写真の中のX座標
  property :coord_y, Integer # 写真の中のY座標
  property :radius, Integer # 円の半径
end
