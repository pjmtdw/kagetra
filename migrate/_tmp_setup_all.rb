require_relative './helper'
Sequel.migration do
  change do
#    
#    create_table_custom(:contest_classes,[:base]) do
#      Integer :event_id, null:false
#      String :class_name, size:16, null:false
#      TrueClass :class_rank
#      Integer :index
#      Integer :num_person
#      String :round_name, text:true
#      
#      index [:event_id, :class_name], name::unique_contest_classes_u1, unique:true
#    end
#    
#    create_table_custom(:contest_games,[:base]) do
#      Integer :event_id, null:false
#      TrueClass :type
#      Integer :contest_user_id, null:false
#      TrueClass :result, null:false
#      String :score_str, size:8
#      Integer :score_int
#      String :opponent_name, size:24
#      String :opponent_belongs, size:36
#      String :comment, text:true
#      Integer :contest_class_id
#      Integer :round
#      Integer :contest_team_opponent_id
#      Integer :opponent_order
#      
#      index [:contest_class_id], name::index_contest_games_contest_class_id
#      index [:contest_team_opponent_id], name::index_contest_games_contest_team_opponent_id
#      index [:event_id], name::index_contest_games_event_id
#      index [:opponent_name], name::index_contest_games_opponent_name
#      index [:score_int], name::index_contest_games_score_int
#      index [:type], name::index_contest_games_type
#      index [:contest_user_id, :contest_class_id, :round], name::unique_contest_games_u1, unique:true
#    end
#    
#    create_table_custom(:contest_prizes,[:base]) do
#      Integer :contest_class_id, null:false
#      Integer :contest_user_id, null:false
#      String :prize, size:32, null:false
#      TrueClass :promotion
#      Integer :point, default:0
#      Integer :point_local, default:0
#      Integer :rank
#      
#      index [:contest_class_id, :contest_user_id], name::unique_contest_prizes_u1, unique:true
#    end
#    
#    create_table_custom(:contest_promotion_caches,[:base]) do
#      String :prize, size:32, null:false
#      String :class_name, size:16, null:false
#      String :user_name, size:24, null:false
#      Date :event_date, null:false
#      String :event_name, size:48, null:false
#      Date :debut_date, null:false
#      Integer :contests, null:false
#      TrueClass :promotion, null:false
#      TrueClass :class_rank, null:false
#      Integer :a_champ_count
#      Bignum :contest_prize_id, null:false
#      Bignum :contest_user_id, null:false
#      Bignum :event_id, null:false
#      
#      
#      index [:contest_prize_id], name::index_contest_promotion_caches_contest_prize
#      index [:contest_user_id], name::index_contest_promotion_caches_contest_user
#      index [:event_id], name::index_contest_promotion_caches_event
#      index [:contest_prize_id], name::unique_contest_promotion_caches_contest_prize_id, unique:true
#      index [:contest_user_id], name::unique_contest_promotion_caches_contest_user_id, unique:true
#    end
#    
#    create_table_custom(:contest_result_caches,[:base]) do
#      Integer :win, default:0
#      Integer :lose, default:0
#      String :prizes, text:true
#      Bignum :event_id, null:false
#      
#      
#      index [:event_id], name::index_contest_result_caches_event
#    end
#    
#    create_table_custom(:contest_team_members,[:base]) do
#      Integer :contest_user_id, null:false
#      Integer :contest_team_id, null:false
#      Integer :order_num, null:false
#      
#      index [:contest_user_id, :contest_team_id], name::unique_contest_team_members_u1, unique:true
#    end
#    
#    create_table_custom(:contest_team_opponents,[:base]) do
#      Integer :contest_team_id, null:false
#      String :name, size:48
#      Integer :round, null:false
#      String :round_name, size:36
#      TrueClass :kind, null:false
#      
#      index [:contest_team_id, :round], name::unique_contest_team_opponents_u1, unique:true
#    end
#    
#    create_table_custom(:contest_teams,[:base]) do
#      Integer :contest_class_id, null:false
#      String :name, size:48, null:false
#      String :prize, size:24
#      Integer :rank
#      TrueClass :promotion
#      
#      index [:contest_class_id, :name], name::unique_contest_teams_u1, unique:true
#    end
#    
#    create_table_custom(:contest_users,[:base]) do
#      String :name, size:24, null:false
#      Integer :user_id
#      Integer :event_id, null:false
#      Integer :win, default:0
#      Integer :lose, default:0
#      Integer :point, default:0
#      Integer :point_local, default:0
#      TrueClass :class_rank
#      Bignum :contest_class_id, null:false
#      
#      
#      index [:contest_class_id], name::index_contest_users_contest_class
#      index [:name], name::index_contest_users_name
#      index [:user_id, :event_id], name::unique_contest_users_u1, unique:true
#    end
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
