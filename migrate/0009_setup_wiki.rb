require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:wiki_items,[:base,:thread]) do
      String :title, size:72, null:false, unique: true
      TrueClass :public, null:false, default:false, comment:"外部公開されているか"
      String :body, text:true, null:false
      Integer :revision, null:false, default:0
      Integer :attached_count, null:false, default:0, comment:"添付ファイルの数"
      foreign_key :owner_id, :users, on_delete: :set_null
    end
    create_table_custom(:wiki_attached_files,[:base,[:attached,:wiki_items]],comment:"Wikiの添付ファイル") do
    end
    
    create_table_custom(:wiki_comments,[:base,:env,[:comment,:wiki_items]]) do
    end
    
    create_table_custom(:wiki_item_logs,[:base,[:patch,:wiki_items,:wiki_item_id]]) do
    end
    
  end
end
