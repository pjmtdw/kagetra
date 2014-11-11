require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:users, [:base]) do
      String :name, size:24, null:false
      String :furigana, size:36, null:false
      Integer :furigana_row, null:false, index:true, comment:"振り仮名の最初の一文字が五十音順のどの行か"
      String :password_hash, size:44, null:false
      String :password_salt, size:32, null:false
      String :token, size:32, comment:"認証用トークン"
      DateTime :token_expire 
      TrueClass :admin, default:false, comment:"管理者かどうか"
      TrueClass :loginable, default:true, comment:"ログインできるかどうか"
      Integer :permission, comment:"最下位ビットが1なら副管理者"
      String :bbs_public_name, size:24, comment:"掲示板の公開スレッドに書き込むときの名前"
      DateTime :show_new_from, comment:"掲示板やコメントなどの新着メッセージはこれ以降の日時のものを表示"
    end
    create_table_custom(:user_attribute_keys, [:base], comment:"ユーザ属性の名前(性別,級位など)") do
      String :name, size:36, null:false
      Integer :index, null:false, comment:"順序付け"
    end
    
    create_table_custom(:user_attribute_values, [:base], comment:"ユーザ属性の値(性別なら男または女,級位ならA級やB級など)") do
      foreign_key :attr_key_id, :user_attribute_keys, null:false
      String :value, size:48, null:false
      Integer :index, null:false, comment:"順序付け"
      TrueClass :default, default:false, comment:"既定値かどうか"
    end
    
    create_table_custom(:user_attributes, [:base],comment:"どのユーザがどの属性を持っているか") do
      foreign_key :user_id, :users, null:false
      foreign_key :value_id, :user_attribute_values, null:false
    end
    
    create_table_custom(:user_login_latests,[:base,:env],comment:"最後のログイン(updated_atが実際のログインの日時)") do
      foreign_key :user_id, :users, null:false
    end
    
    create_table_custom(:user_login_logs,[:base,:env],comment:"直近数日間のログイン履歴(created_atがログインの日時)") do
      foreign_key :user_id, :users, null:false
      TrueClass :counted, default:true, comment:"ログイン数を増やしたかどうか"
    end
    
    create_table_custom(:user_login_monthlies,[:base],comment:"ユーザが月に何回ログインしたか") do
      foreign_key :user_id, :users, null:false
      String :year_month, size:8, null:false, index:true
      Integer :count, default:0
      Integer :rank, comment:"その月における順位"

      index [:user_id, :year_month], name: :unique_user_login_monthlies_u1, unique:true
    end 
  end
end