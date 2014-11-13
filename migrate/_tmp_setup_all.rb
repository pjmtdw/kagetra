require_relative './helper'
Sequel.migration do
  change do
#    
#    create_table_custom(:my_confs,[:base]) do
#      String :name, size:64
#      String :value, text:true
#      
#      index [:name], name::unique_my_confs_name, unique:true
#    end
#    
#    create_table_custom(:wiki_attached_files,[:base]) do
#      TrueClass :deleted, default:false
#      String :path, size:255
#      String :orig_name, size:128
#      String :description, text:true
#      Integer :size, null:false
#      Bignum :owner_id, null:false
#      Bignum :wiki_item_id, null:false
#      
#      
#      index [:owner_id], name::index_wiki_attached_files_owner
#      index [:wiki_item_id], name::index_wiki_attached_files_wiki_item
#    end
#    
#    create_table_custom(:wiki_comments,[:base,:env,[:comment,:wiki_items]]) do
#    end
#    
#    create_table_custom(:wiki_item_logs,[:base]) do
#      Integer :revision, null:false
#      String :patch, text:true, null:false
#      Integer :wiki_item_id, null:false
#      Bignum :user_id
#      
#      
#      index [:user_id], name::index_wiki_item_logs_user
#      index [:revision, :wiki_item_id], name::unique_wiki_item_logs_u1, unique:true
#    end
#    
#    create_table_custom(:wiki_items,[:base,:thread]) do
#      TrueClass :deleted, default:false
#      String :title, size:72, null:false
#      TrueClass :public, default:false
#      String :body, text:true, null:false
#      Integer :revision, default:0
#      Bignum :owner_id
#      Integer :attached_count, default:0
#      
#      
#      index [:owner_id], name::index_wiki_items_owner
#      index [:title], name::unique_wiki_items_title, unique:true
#    end
  end
end
