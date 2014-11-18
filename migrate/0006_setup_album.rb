require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:album_groups,[:base],comment:"行事や大会単位でアルバムをまとめるためのもの") do
      String :name, size:72
      String :place, size:128
      String :comment, text:true
      Date :start_at, comment:"開始日"
      Date :end_at, comment:"終了日"
      TrueClass :dummy, index:true, default:false, comment:"どのグループにも属していない写真のための擬似的なグループ"
      Integer :year, index:true, comment:"年ごとの集計のためにキャッシュする"
      Integer :daily_choose_count, default:0, comment: "含まれる写真のうち今日の一枚の対象になっている数"
      Integer :has_comment_count, default:0, comment: "コメントの入っている写真の数"
      Integer :has_tag_count, default:0, comment: "タグの入っている写真の数"
      Integer :item_count, default:0, comment:"含まれる写真数，毎回aggregateするのは遅いのでキャッッシュ"
      foreign_key :owner_id, :users, on_delete: :set_null
    end

    create_table_custom(:album_group_events,[:base],comment:"大会結果とアルバムの関連付け") do
      foreign_key :album_group_id, :album_groups, unique:true, null:false, on_delete: :cascade
      foreign_key :event_id, :events, null:false, on_delete: :cascade
      index [:album_group_id], name: :unique_album_group_events_album_group_id, unique:true
    end

    create_table_custom(:album_items,[:base],comment:"アルバムの各写真の情報") do
      String :name, size:72
      String :place, size:128
      String :comment, text:true
      Integer :comment_revision,index:true, default:0
      DateTime :comment_updated_at, index:true
      Date :date, comment:"撮影日"
      String :hourmin, size:50, comment:"撮影時刻"
      TrueClass :daily_choose, default:true, comment:"今日の一枚として選ばれるかどうか"
      Integer :group_index, null:false, comment:"グループの中での表示順"
      Integer :rotate, comment:"回転(右向き．0,90,180,270のどれか)"
      String :orig_filename, size:128, comment:"アップロードされた元のファイル名"
      Integer :tag_count, default:0, comment:"写真にタグが何個付いているか"
      String :tag_names, text:true, comment:"タグ名の入った配列をJSON化したもの"
      
      foreign_key :owner_id, :users, on_delete: :set_null
      foreign_key :group_id, :album_groups, null:false, on_delete: :cascade
    end

    create_table_custom(:album_relations,[:base],comment:"アルバムの各写真同士の関連付け") do
      foreign_key :source_id, :album_items, null:false, on_delete: :cascade
      foreign_key :target_id, :album_items, null:false, on_delete: :cascade

      index [:source_id, :target_id], name: :unique_album_relations_u1, unique:true
    end

    create_table_custom(:album_comment_logs,[:base,[:patch,:album_items,:album_item_id]],comment:"アルバムのコメントの変更履歴(created_atが編集日時)") do
    end
    
    create_table_custom(:album_tags,[:base],comment:"写真の特定の位置にタグ付けできる") do
      String :name, size:50, null:false, index: true
      Integer :coord_x, comment:"X座標"
      Integer :coord_y, comment:"Y座標"
      Integer :radius, comment:"円の半径"
      foreign_key :album_item_id, :album_items, null:false, on_delete: :cascade  
    end

    create_table_custom(:album_photos,[:base,:image]) do
    end 
    
    create_table_custom(:album_thumbnails,[:base,:image]) do
    end 
  end
end
    
