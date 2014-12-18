require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:map_bookmarks,[:base]) do
      String :title, size:72, null:false
      String :description, text:true
      Float :lat, null:false
      Float :lng, null:false
      Integer :zoom, null:false
      String :markers, text:true
      foreign_key :user_id, :users, null:false, on_delete: :cascade
    end
    
  end
end
