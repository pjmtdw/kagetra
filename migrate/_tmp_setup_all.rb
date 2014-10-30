require_relative './helper'
Sequel.migration do
  change do

#    create_table_custom(:album_comment_logs,[:base]) do
#      Integer :revision, null:false
#      String :patch, text:true, null:false
#      Integer :album_item_id, null:false
#      Bignum :user_id
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
#      
#      index [:user_id], name::index_album_comment_logs_user
#      index [:revision, :album_item_id], name::unique_album_comment_logs_u1, unique:true
#    end
#    
#    create_table_custom(:album_group_events,[:base]) do
#      Bignum :event_id, null:false
#      Bignum :album_group_id, null:false
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_group_id), 0)
#      
#      index [:album_group_id], name::index_album_group_events_album_group
#      index [:event_id], name::index_album_group_events_event
#      index [:album_group_id], name::unique_album_group_events_album_group_id, unique:true
#    end
#    
#    create_table_custom(:album_groups,[:base]) do
#      TrueClass :deleted, default:false
#      String :name, size:72
#      String :place, size:128
#      String :comment, text:true
#      Date :start_at
#      Date :end_at
#      TrueClass :dummy, default:false
#      Integer :year
#      Integer :daily_choose_count, default:0
#      Integer :has_comment_count, default:0
#      Integer :has_tag_count, default:0
#      Integer :item_count, default:0
#      Bignum :owner_id
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
#      
#      index [:dummy], name::index_album_groups_dummy
#      index [:owner_id], name::index_album_groups_owner
#      index [:year], name::index_album_groups_year
#    end
#    
#    create_table_custom(:album_items,[:base]) do
#      TrueClass :deleted, default:false
#      String :name, size:72
#      String :place, size:128
#      String :comment, text:true
#      Integer :comment_revision, default:0
#      DateTime :comment_updated_at
#      Date :date
#      String :hourmin, size:50
#      TrueClass :daily_choose, default:true
#      Integer :group_id, null:false
#      Integer :group_index, null:false
#      Integer :rotate
#      String :orig_filename, size:128
#      Integer :tag_count, default:0
#      String :tag_names, text:true
#      Bignum :owner_id
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
#      
#      index [:comment_revision], name::index_album_items_comment_revision
#      index [:comment_updated_at], name::index_album_items_comment_updated_at
#      index [:group_id], name::index_album_items_group_id
#      index [:owner_id], name::index_album_items_owner
#    end
#    
#    create_table_custom(:album_photos,[:base]) do
#      String :path, size:255, null:false
#      Integer :width
#      Integer :height
#      String :format, size:50
#      Bignum :album_item_id, null:false
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
#      
#      index [:album_item_id], name::index_album_photos_album_item
#      index [:album_item_id], name::unique_album_photos_album_item_id, unique:true
#      index [:path], name::unique_album_photos_path, unique:true
#    end
#    
#    create_table_custom(:album_relations,[:base]) do
#      Integer :source_id, null:false
#      Integer :target_id, null:false
#      
#      index [:source_id], name::index_album_relations_source_id
#      index [:target_id], name::index_album_relations_target_id
#      index [:source_id, :target_id], name::unique_album_relations_u1, unique:true
#    end
#    
    
    create_table_custom(:addr_books, [:base] do
      foreign_key :user_id, :users, null:false, unique:true
      foreign_key :album_item_id, :album_items, on_delete: :set_null
      String :text, text:true
    end
    
#    create_table_custom(:album_tags,[:base]) do
#      String :name, size:50, null:false
#      Integer :coord_x
#      Integer :coord_y
#      Integer :radius
#      Bignum :album_item_id, null:false
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
#      
#      index [:album_item_id], name::index_album_tags_album_item
#      index [:name], name::index_album_tags_name
#    end
#    
#    create_table_custom(:album_thumbnails,[:base]) do
#      String :path, size:255, null:false
#      Integer :width
#      Integer :height
#      String :format, size:50
#      Bignum :album_item_id, null:false
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
#      
#      index [:album_item_id], name::index_album_thumbnails_album_item
#      index [:album_item_id], name::unique_album_thumbnails_album_item_id, unique:true
#      index [:path], name::unique_album_thumbnails_path, unique:true
#    end
#    
#    create_table_custom(:bbs_items,[:base,:env]) do
#      TrueClass :deleted, default:false
#      String :body, text:true, null:false
#      String :user_name, size:24, null:false
#      String :real_name, size:24
#      Bignum :thread_id, null:false
#      Bignum :user_id
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:thread_id), 0)
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
#      
#      index [:thread_id], name::index_bbs_items_thread
#      index [:user_id], name::index_bbs_items_user
#    end
#    
#    create_table_custom(:bbs_threads,[:base,:thread]) do
#      TrueClass :deleted, default:false
#      String :title, size:48, null:false
#      TrueClass :public, default:false
#      Bignum :first_item_id
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:first_item_id), 0)
#      
#      index [:first_item_id], name::index_bbs_threads_first_item
#    end
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
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:contest_prize_id), 0)
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:contest_user_id), 0)
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
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
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
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
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:contest_class_id), 0)
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
#    create_table_custom(:schedule_date_infos,[:base]) do
#      Date :date, null:false
#      String :names, text:true
#      TrueClass :holiday, default:false
#      
#      index [:date], name::unique_schedule_date_infos_date, unique:true
#    end
#    
#    create_table_custom(:schedule_items,[:base]) do
#      Date :date, null:false
#      TrueClass :kind
#      TrueClass :public, default:true
#      Integer :emphasis
#      String :name, size:48, null:false
#      String :start_at, size:50
#      String :end_at, size:50
#      String :place, size:48
#      String :description, text:true
#      Bignum :owner_id, null:false
#      
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
#      
#      index [:date], name::index_schedule_items_date
#      index [:owner_id], name::index_schedule_items_owner
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
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:wiki_item_id), 0)
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
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
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
#      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
#      
#      index [:owner_id], name::index_wiki_items_owner
#      index [:title], name::unique_wiki_items_title, unique:true
#    end
  end
end
