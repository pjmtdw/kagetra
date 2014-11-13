require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:wiki_items,[:base,:thread]) do
      String :title, size:72, null:false, unique: true
      TrueClass :public, default:false, comment:"外部公開されているか"
      String :body, text:true, null:false
      Integer :revision, default:0
      Integer :attached_count, default:0, comment:"添付ファイルの数"
      foreign_key :owner_id, :users, on_delete: :set_null
    end
    create_table_custom(:wiki_attached_files,[:base],comment:"Wikiの添付ファイル") do
      String :path, size:255
      String :orig_name, size:128, comment:"元のファイル名"
      String :description, text:true
      Integer :size, null:false
      foreign_key :owner_id, :users, on_delele: :set_null
      foreign_key :wiki_item_id, :wiki_items, null:false, on_delete: :cascade
    end
    
    create_table_custom(:wiki_comments,[:base,:env,[:comment,:wiki_items]]) do
    end
    
    create_table_custom(:wiki_item_logs,[:base,[:patch,:wiki_items,:wiki_item_id]]) do
    end
    
  end
end
