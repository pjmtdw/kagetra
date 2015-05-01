require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:map_bookmarks,[:base]) do
      String :title, size:72, null:false
      String :description, text:true
      Float :lat, null:false, comment: "緯度"
      Float :lng, null:false, comment: "経度"
      Integer :zoom, null:false, comment: "拡大レベル"
      String :markers, text:true, comment: "マーカーのJSONデータ"
      foreign_key :user_id, :users, null:false, on_delete: :set_null
    end
    alter_table(:events) do
      add_foreign_key :map_bookmark_id, :map_bookmarks, on_delete: :set_null
    end
  end
end
