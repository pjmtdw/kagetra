Sequel.migration do
  change do
    create_table(:addr_books, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      TrueClass :deleted, :default=>false
      String :text, :text=>true
      Integer :user_id, :null=>false
      Bignum :album_item_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
      
      index [:created_at], :name=>:index_addr_books_created_at
      index [:updated_at], :name=>:index_addr_books_updated_at
      index [:user_id], :name=>:unique_addr_books_user_id, :unique=>true
    end
    
    create_table(:album_comment_logs, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :revision, :null=>false
      String :patch, :text=>true, :null=>false
      Integer :album_item_id, :null=>false
      Bignum :user_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      
      index [:created_at], :name=>:index_album_comment_logs_created_at
      index [:updated_at], :name=>:index_album_comment_logs_updated_at
      index [:user_id], :name=>:index_album_comment_logs_user
      index [:revision, :album_item_id], :name=>:unique_album_comment_logs_u1, :unique=>true
    end
    
    create_table(:album_group_events, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Bignum :event_id, :null=>false
      Bignum :album_group_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_group_id), 0)
      
      index [:album_group_id], :name=>:index_album_group_events_album_group
      index [:created_at], :name=>:index_album_group_events_created_at
      index [:event_id], :name=>:index_album_group_events_event
      index [:updated_at], :name=>:index_album_group_events_updated_at
      index [:album_group_id], :name=>:unique_album_group_events_album_group_id, :unique=>true
    end
    
    create_table(:album_groups, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      TrueClass :deleted, :default=>false
      String :name, :size=>72
      String :place, :size=>128
      String :comment, :text=>true
      Date :start_at
      Date :end_at
      TrueClass :dummy, :default=>false
      Integer :year
      Integer :daily_choose_count, :default=>0
      Integer :has_comment_count, :default=>0
      Integer :has_tag_count, :default=>0
      Integer :item_count, :default=>0
      Bignum :owner_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
      
      index [:created_at], :name=>:index_album_groups_created_at
      index [:dummy], :name=>:index_album_groups_dummy
      index [:owner_id], :name=>:index_album_groups_owner
      index [:updated_at], :name=>:index_album_groups_updated_at
      index [:year], :name=>:index_album_groups_year
    end
    
    create_table(:album_items, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      TrueClass :deleted, :default=>false
      String :name, :size=>72
      String :place, :size=>128
      String :comment, :text=>true
      Integer :comment_revision, :default=>0
      DateTime :comment_updated_at
      Date :date
      String :hourmin, :size=>50
      TrueClass :daily_choose, :default=>true
      Integer :group_id, :null=>false
      Integer :group_index, :null=>false
      Integer :rotate
      String :orig_filename, :size=>128
      Integer :tag_count, :default=>0
      String :tag_names, :text=>true
      Bignum :owner_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
      
      index [:comment_revision], :name=>:index_album_items_comment_revision
      index [:comment_updated_at], :name=>:index_album_items_comment_updated_at
      index [:created_at], :name=>:index_album_items_created_at
      index [:group_id], :name=>:index_album_items_group_id
      index [:owner_id], :name=>:index_album_items_owner
      index [:updated_at], :name=>:index_album_items_updated_at
    end
    
    create_table(:album_photos, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :path, :size=>255, :null=>false
      Integer :width
      Integer :height
      String :format, :size=>50
      Bignum :album_item_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
      
      index [:album_item_id], :name=>:index_album_photos_album_item
      index [:created_at], :name=>:index_album_photos_created_at
      index [:updated_at], :name=>:index_album_photos_updated_at
      index [:album_item_id], :name=>:unique_album_photos_album_item_id, :unique=>true
      index [:path], :name=>:unique_album_photos_path, :unique=>true
    end
    
    create_table(:album_relations, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :source_id, :null=>false
      Integer :target_id, :null=>false
      
      index [:created_at], :name=>:index_album_relations_created_at
      index [:source_id], :name=>:index_album_relations_source_id
      index [:target_id], :name=>:index_album_relations_target_id
      index [:updated_at], :name=>:index_album_relations_updated_at
      index [:source_id, :target_id], :name=>:unique_album_relations_u1, :unique=>true
    end
    
    create_table(:album_tags, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>50, :null=>false
      Integer :coord_x
      Integer :coord_y
      Integer :radius
      Bignum :album_item_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
      
      index [:album_item_id], :name=>:index_album_tags_album_item
      index [:created_at], :name=>:index_album_tags_created_at
      index [:name], :name=>:index_album_tags_name
      index [:updated_at], :name=>:index_album_tags_updated_at
    end
    
    create_table(:album_thumbnails, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :path, :size=>255, :null=>false
      Integer :width
      Integer :height
      String :format, :size=>50
      Bignum :album_item_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:album_item_id), 0)
      
      index [:album_item_id], :name=>:index_album_thumbnails_album_item
      index [:created_at], :name=>:index_album_thumbnails_created_at
      index [:updated_at], :name=>:index_album_thumbnails_updated_at
      index [:album_item_id], :name=>:unique_album_thumbnails_album_item_id, :unique=>true
      index [:path], :name=>:unique_album_thumbnails_path, :unique=>true
    end
    
    create_table(:bbs_items, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :remote_host, :size=>72
      String :remote_addr, :size=>48
      String :user_agent, :size=>255
      TrueClass :deleted, :default=>false
      String :body, :text=>true, :null=>false
      String :user_name, :size=>24, :null=>false
      String :real_name, :size=>24
      Bignum :thread_id, :null=>false
      Bignum :user_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:thread_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      
      index [:created_at], :name=>:index_bbs_items_created_at
      index [:thread_id], :name=>:index_bbs_items_thread
      index [:updated_at], :name=>:index_bbs_items_updated_at
      index [:user_id], :name=>:index_bbs_items_user
    end
    
    create_table(:bbs_threads, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      DateTime :last_comment_date
      Integer :comment_count, :default=>0
      TrueClass :deleted, :default=>false
      String :title, :size=>48, :null=>false
      TrueClass :public, :default=>false
      Bignum :last_comment_user_id
      Bignum :first_item_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:last_comment_user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:first_item_id), 0)
      
      index [:created_at], :name=>:index_bbs_threads_created_at
      index [:first_item_id], :name=>:index_bbs_threads_first_item
      index [:last_comment_date], :name=>:index_bbs_threads_last_comment_date
      index [:last_comment_user_id], :name=>:index_bbs_threads_last_comment_user
      index [:updated_at], :name=>:index_bbs_threads_updated_at
    end
    
    create_table(:contest_classes, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :event_id, :null=>false
      String :class_name, :size=>16, :null=>false
      TrueClass :class_rank
      Integer :index
      Integer :num_person
      String :round_name, :text=>true
      
      index [:created_at], :name=>:index_contest_classes_created_at
      index [:updated_at], :name=>:index_contest_classes_updated_at
      index [:event_id, :class_name], :name=>:unique_contest_classes_u1, :unique=>true
    end
    
    create_table(:contest_games, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :event_id, :null=>false
      TrueClass :type
      Integer :contest_user_id, :null=>false
      TrueClass :result, :null=>false
      String :score_str, :size=>8
      Integer :score_int
      String :opponent_name, :size=>24
      String :opponent_belongs, :size=>36
      String :comment, :text=>true
      Integer :contest_class_id
      Integer :round
      Integer :contest_team_opponent_id
      Integer :opponent_order
      
      index [:contest_class_id], :name=>:index_contest_games_contest_class_id
      index [:contest_team_opponent_id], :name=>:index_contest_games_contest_team_opponent_id
      index [:created_at], :name=>:index_contest_games_created_at
      index [:event_id], :name=>:index_contest_games_event_id
      index [:opponent_name], :name=>:index_contest_games_opponent_name
      index [:score_int], :name=>:index_contest_games_score_int
      index [:type], :name=>:index_contest_games_type
      index [:updated_at], :name=>:index_contest_games_updated_at
      index [:contest_user_id, :contest_class_id, :round], :name=>:unique_contest_games_u1, :unique=>true
    end
    
    create_table(:contest_prizes, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :contest_class_id, :null=>false
      Integer :contest_user_id, :null=>false
      String :prize, :size=>32, :null=>false
      TrueClass :promotion
      Integer :point, :default=>0
      Integer :point_local, :default=>0
      Integer :rank
      
      index [:created_at], :name=>:index_contest_prizes_created_at
      index [:updated_at], :name=>:index_contest_prizes_updated_at
      index [:contest_class_id, :contest_user_id], :name=>:unique_contest_prizes_u1, :unique=>true
    end
    
    create_table(:contest_promotion_caches, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :prize, :size=>32, :null=>false
      String :class_name, :size=>16, :null=>false
      String :user_name, :size=>24, :null=>false
      Date :event_date, :null=>false
      String :event_name, :size=>48, :null=>false
      Date :debut_date, :null=>false
      Integer :contests, :null=>false
      TrueClass :promotion, :null=>false
      TrueClass :class_rank, :null=>false
      Integer :a_champ_count
      Bignum :contest_prize_id, :null=>false
      Bignum :contest_user_id, :null=>false
      Bignum :event_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:contest_prize_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:contest_user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
      
      index [:contest_prize_id], :name=>:index_contest_promotion_caches_contest_prize
      index [:contest_user_id], :name=>:index_contest_promotion_caches_contest_user
      index [:created_at], :name=>:index_contest_promotion_caches_created_at
      index [:event_id], :name=>:index_contest_promotion_caches_event
      index [:updated_at], :name=>:index_contest_promotion_caches_updated_at
      index [:contest_prize_id], :name=>:unique_contest_promotion_caches_contest_prize_id, :unique=>true
      index [:contest_user_id], :name=>:unique_contest_promotion_caches_contest_user_id, :unique=>true
    end
    
    create_table(:contest_result_caches, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :win, :default=>0
      Integer :lose, :default=>0
      String :prizes, :text=>true
      Bignum :event_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
      
      index [:created_at], :name=>:index_contest_result_caches_created_at
      index [:event_id], :name=>:index_contest_result_caches_event
      index [:updated_at], :name=>:index_contest_result_caches_updated_at
    end
    
    create_table(:contest_team_members, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :contest_user_id, :null=>false
      Integer :contest_team_id, :null=>false
      Integer :order_num, :null=>false
      
      index [:created_at], :name=>:index_contest_team_members_created_at
      index [:updated_at], :name=>:index_contest_team_members_updated_at
      index [:contest_user_id, :contest_team_id], :name=>:unique_contest_team_members_u1, :unique=>true
    end
    
    create_table(:contest_team_opponents, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :contest_team_id, :null=>false
      String :name, :size=>48
      Integer :round, :null=>false
      String :round_name, :size=>36
      TrueClass :kind, :null=>false
      
      index [:created_at], :name=>:index_contest_team_opponents_created_at
      index [:updated_at], :name=>:index_contest_team_opponents_updated_at
      index [:contest_team_id, :round], :name=>:unique_contest_team_opponents_u1, :unique=>true
    end
    
    create_table(:contest_teams, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :contest_class_id, :null=>false
      String :name, :size=>48, :null=>false
      String :prize, :size=>24
      Integer :rank
      TrueClass :promotion
      
      index [:created_at], :name=>:index_contest_teams_created_at
      index [:updated_at], :name=>:index_contest_teams_updated_at
      index [:contest_class_id, :name], :name=>:unique_contest_teams_u1, :unique=>true
    end
    
    create_table(:contest_users, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>24, :null=>false
      Integer :user_id
      Integer :event_id, :null=>false
      Integer :win, :default=>0
      Integer :lose, :default=>0
      Integer :point, :default=>0
      Integer :point_local, :default=>0
      TrueClass :class_rank
      Bignum :contest_class_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:contest_class_id), 0)
      
      index [:contest_class_id], :name=>:index_contest_users_contest_class
      index [:created_at], :name=>:index_contest_users_created_at
      index [:name], :name=>:index_contest_users_name
      index [:updated_at], :name=>:index_contest_users_updated_at
      index [:user_id, :event_id], :name=>:unique_contest_users_u1, :unique=>true
    end
    
    create_table(:event_choices, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>24, :null=>false
      TrueClass :positive, :null=>false
      TrueClass :hide_result, :default=>false
      Integer :index, :null=>false
      Bignum :event_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_id), 0)
      
      index [:created_at], :name=>:index_event_choices_created_at
      index [:event_id], :name=>:index_event_choices_event
      index [:updated_at], :name=>:index_event_choices_updated_at
    end
    
    create_table(:event_comments, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :remote_host, :size=>72
      String :remote_addr, :size=>48
      String :user_agent, :size=>255
      TrueClass :deleted, :default=>false
      String :body, :text=>true, :null=>false
      String :user_name, :size=>24, :null=>false
      String :real_name, :size=>24
      Bignum :user_id
      Bignum :thread_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:thread_id), 0)
      
      index [:created_at], :name=>:index_event_comments_created_at
      index [:thread_id], :name=>:index_event_comments_thread
      index [:updated_at], :name=>:index_event_comments_updated_at
      index [:user_id], :name=>:index_event_comments_user
    end
    
    create_table(:event_groups, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>60, :null=>false
      String :description, :text=>true
      
      index [:created_at], :name=>:index_event_groups_created_at
      index [:updated_at], :name=>:index_event_groups_updated_at
      index [:name], :name=>:unique_event_groups_name, :unique=>true
    end
    
    create_table(:event_user_choices, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :user_name, :size=>24, :null=>false
      Integer :attr_value_id, :null=>false
      TrueClass :cancel, :default=>false
      Bignum :event_choice_id, :null=>false
      Bignum :user_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_choice_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      
      index [:created_at], :name=>:index_event_user_choices_created_at
      index [:event_choice_id], :name=>:index_event_user_choices_event_choice
      index [:updated_at], :name=>:index_event_user_choices_updated_at
      index [:user_id], :name=>:index_event_user_choices_user
    end
    
    create_table(:events, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      DateTime :last_comment_date
      Integer :comment_count, :default=>0
      TrueClass :deleted, :default=>false
      String :name, :size=>48, :null=>false
      String :formal_name, :size=>96
      TrueClass :official, :default=>true
      TrueClass :kind
      Integer :team_size, :default=>1
      String :description, :text=>true
      Date :deadline
      Date :date
      String :start_at, :size=>50
      String :end_at, :size=>50
      String :place, :size=>255
      TrueClass :done, :default=>false
      TrueClass :public, :default=>true
      Integer :participant_count, :default=>0
      Integer :contest_user_count, :default=>0
      String :owners, :text=>true
      String :forbidden_attrs, :text=>true
      TrueClass :hide_choice, :default=>false
      Bignum :last_comment_user_id
      Bignum :event_group_id
      Bignum :aggregate_attr_id, :null=>false
      TrueClass :register_done, :default=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:last_comment_user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:event_group_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:aggregate_attr_id), 0)
      
      index [:aggregate_attr_id], :name=>:index_events_aggregate_attr
      index [:created_at], :name=>:index_events_created_at
      index [:date], :name=>:index_events_date
      index [:done], :name=>:index_events_done
      index [:event_group_id], :name=>:index_events_event_group
      index [:kind], :name=>:index_events_kind
      index [:last_comment_date], :name=>:index_events_last_comment_date
      index [:last_comment_user_id], :name=>:index_events_last_comment_user
      index [:public], :name=>:index_events_public
      index [:updated_at], :name=>:index_events_updated_at
    end
    
    create_table(:my_confs, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>64
      String :value, :text=>true
      
      index [:created_at], :name=>:index_my_confs_created_at
      index [:updated_at], :name=>:index_my_confs_updated_at
      index [:name], :name=>:unique_my_confs_name, :unique=>true
    end
    
    create_table(:schedule_date_infos, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Date :date, :null=>false
      String :names, :text=>true
      TrueClass :holiday, :default=>false
      
      index [:created_at], :name=>:index_schedule_date_infos_created_at
      index [:updated_at], :name=>:index_schedule_date_infos_updated_at
      index [:date], :name=>:unique_schedule_date_infos_date, :unique=>true
    end
    
    create_table(:schedule_items, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Date :date, :null=>false
      TrueClass :kind
      TrueClass :public, :default=>true
      Integer :emphasis
      String :name, :size=>48, :null=>false
      String :start_at, :size=>50
      String :end_at, :size=>50
      String :place, :size=>48
      String :description, :text=>true
      Bignum :owner_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
      
      index [:created_at], :name=>:index_schedule_items_created_at
      index [:date], :name=>:index_schedule_items_date
      index [:owner_id], :name=>:index_schedule_items_owner
      index [:updated_at], :name=>:index_schedule_items_updated_at
    end
    
    create_table(:user_attribute_keys, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>36, :null=>false
      Integer :index, :null=>false
      
      index [:created_at], :name=>:index_user_attribute_keys_created_at
      index [:updated_at], :name=>:index_user_attribute_keys_updated_at
    end
    
    create_table(:user_attribute_values, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :attr_key_id, :null=>false
      String :value, :size=>48, :null=>false
      Integer :index, :null=>false
      TrueClass :default, :default=>false
      
      index [:created_at], :name=>:index_user_attribute_values_created_at
      index [:updated_at], :name=>:index_user_attribute_values_updated_at
    end
    
    create_table(:user_attributes, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Bignum :user_id, :null=>false
      Bignum :value_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:value_id), 0)
      
      index [:created_at], :name=>:index_user_attributes_created_at
      index [:updated_at], :name=>:index_user_attributes_updated_at
      index [:user_id], :name=>:index_user_attributes_user
      index [:value_id], :name=>:index_user_attributes_value
    end
    
    create_table(:user_login_latests, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :remote_host, :size=>72
      String :remote_addr, :size=>48
      String :user_agent, :size=>255
      Integer :user_id, :null=>false
      
      index [:created_at], :name=>:index_user_login_latests_created_at
      index [:updated_at], :name=>:index_user_login_latests_updated_at
      index [:user_id], :name=>:unique_user_login_latests_user_id, :unique=>true
    end
    
    create_table(:user_login_logs, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :remote_host, :size=>72
      String :remote_addr, :size=>48
      String :user_agent, :size=>255
      Bignum :user_id, :null=>false
      TrueClass :counted, :default=>true
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      
      index [:created_at], :name=>:index_user_login_logs_created_at
      index [:updated_at], :name=>:index_user_login_logs_updated_at
      index [:user_id], :name=>:index_user_login_logs_user
    end
    
    create_table(:user_login_monthlies, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :user_id, :null=>false
      String :year_month, :size=>8, :null=>false
      Integer :count, :default=>0
      Integer :rank
      
      index [:created_at], :name=>:index_user_login_monthlies_created_at
      index [:updated_at], :name=>:index_user_login_monthlies_updated_at
      index [:year_month], :name=>:index_user_login_monthlies_year_month
      index [:user_id, :year_month], :name=>:unique_user_login_monthlies_u1, :unique=>true
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      TrueClass :deleted, :default=>false
      String :name, :size=>24, :null=>false
      String :furigana, :size=>36, :null=>false
      Integer :furigana_row, :null=>false
      String :password_hash, :size=>44
      String :password_salt, :size=>32
      String :token, :size=>32
      TrueClass :admin, :default=>false
      TrueClass :loginable, :default=>true
      Integer :permission
      String :bbs_public_name, :size=>24
      DateTime :show_new_from
      DateTime :token_expire
      
      index [:created_at], :name=>:index_users_created_at
      index [:furigana_row], :name=>:index_users_furigana_row
      index [:updated_at], :name=>:index_users_updated_at
    end
    
    create_table(:wiki_attached_files, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      TrueClass :deleted, :default=>false
      String :path, :size=>255
      String :orig_name, :size=>128
      String :description, :text=>true
      Integer :size, :null=>false
      Bignum :owner_id, :null=>false
      Bignum :wiki_item_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:wiki_item_id), 0)
      
      index [:created_at], :name=>:index_wiki_attached_files_created_at
      index [:owner_id], :name=>:index_wiki_attached_files_owner
      index [:updated_at], :name=>:index_wiki_attached_files_updated_at
      index [:wiki_item_id], :name=>:index_wiki_attached_files_wiki_item
    end
    
    create_table(:wiki_comments, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      String :remote_host, :size=>72
      String :remote_addr, :size=>48
      String :user_agent, :size=>255
      TrueClass :deleted, :default=>false
      String :body, :text=>true, :null=>false
      String :user_name, :size=>24, :null=>false
      String :real_name, :size=>24
      Bignum :user_id
      Bignum :thread_id, :null=>false
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:thread_id), 0)
      
      index [:created_at], :name=>:index_wiki_comments_created_at
      index [:thread_id], :name=>:index_wiki_comments_thread
      index [:updated_at], :name=>:index_wiki_comments_updated_at
      index [:user_id], :name=>:index_wiki_comments_user
    end
    
    create_table(:wiki_item_logs, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      Integer :revision, :null=>false
      String :patch, :text=>true, :null=>false
      Integer :wiki_item_id, :null=>false
      Bignum :user_id
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:user_id), 0)
      
      index [:created_at], :name=>:index_wiki_item_logs_created_at
      index [:updated_at], :name=>:index_wiki_item_logs_updated_at
      index [:user_id], :name=>:index_wiki_item_logs_user
      index [:revision, :wiki_item_id], :name=>:unique_wiki_item_logs_u1, :unique=>true
    end
    
    create_table(:wiki_items, :ignore_index_errors=>true) do
      primary_key :id, :type=>Bignum
      DateTime :created_at
      DateTime :updated_at
      DateTime :last_comment_date
      Integer :comment_count, :default=>0
      TrueClass :deleted, :default=>false
      String :title, :size=>72, :null=>false
      TrueClass :public, :default=>false
      String :body, :text=>true, :null=>false
      Integer :revision, :default=>0
      Bignum :last_comment_user_id
      Bignum :owner_id
      Integer :attached_count, :default=>0
      
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:last_comment_user_id), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:owner_id), 0)
      
      index [:created_at], :name=>:index_wiki_items_created_at
      index [:last_comment_date], :name=>:index_wiki_items_last_comment_date
      index [:last_comment_user_id], :name=>:index_wiki_items_last_comment_user
      index [:owner_id], :name=>:index_wiki_items_owner
      index [:updated_at], :name=>:index_wiki_items_updated_at
      index [:title], :name=>:unique_wiki_items_title, :unique=>true
    end
  end
end
