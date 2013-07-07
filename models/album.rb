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
  property :name, TrimString, length: 72
  property :place, TrimString, length: 128 # 場所
  belongs_to :owner, 'User', required: false
  property :comment, TrimText
  property :comment_revision, Integer

  property :date , Date # 撮影日
  property :hourmin , HourMin # 撮影時刻
  property :daily_choose, Boolean, default: true # 今日の一枚として選ばれるかどうか
  property :group_id, Integer, unique_index: :u1, required: true
  belongs_to :group, 'AlbumGroup'
  property :group_index, Integer, unique_index: :u1, allow_nil: false # グループの中での表示順
  property :rotate, Integer # 回転 (右向き, 度数法)
  property :orig_filename, String, length: 128 # アップロードされた元のファイル名

  property :tag_count, Integer, default: 0

  has 1, :photo, 'AlbumPhoto'
  has 1, :thumb, 'AlbumThumbnail'
  has n, :tags, 'AlbumTag'

  # 順方向の関連写真
  has n, :album_relations_r, 'AlbumRelation', child_key: [:source_id]
  has n, :relations_r, self, through: :album_relations_r, via: :target
  # 逆方向の関連写真
  has n, :album_relations_l, 'AlbumRelation', child_key: [:target_id]
  has n, :relations_l, self, through: :album_relations_l, via: :source

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
  after :save do
    ag = self.group
    c = ag.items(daily_choose:true).count
    hc = ag.items(:comment.not => nil).count
    ag.update(daily_choose_count:c,has_comment_count:hc)
  end

  # 順方向と逆方向の両方の関連写真
  def relations
    self.relations_r + self.relations_l
  end

end

# 関連写真
class AlbumRelation
  include ModelBase
  property :source_id, Integer, unique_index: :u1, required: true, index: true
  belongs_to :source, 'AlbumItem', key: true
  property :target_id, Integer, unique_index: :u1, required: true, index: true
  belongs_to :target, 'AlbumItem', key: true
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
  property :name, TrimString, required: true, index: true
  property :coord_x, Integer # 写真の中のX座標
  property :coord_y, Integer # 写真の中のY座標
  property :radius, Integer # 円の半径
  belongs_to :album_item
  [:create,:destroy].each{|sym|
    after sym do
      AlbumItem.transaction{
        item = self.album_item
        item.update(tag_count:item.tags.count)
        ag = item.group
        ag.update(has_tag_count:ag.items(:tag_count.gt => 0).count)
      }
    end
  }
end
