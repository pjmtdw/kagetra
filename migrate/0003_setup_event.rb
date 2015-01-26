require_relative './helper'
Sequel.migration do
  change do
    
    create_table_custom(:event_groups,[:base],comment:"大会/行事のグループ") do
      String :name, size:60, null:false, unique:true
      String :description, text:true
    end

    create_table_custom(:events,[:base,:thread],comment:"大会/行事") do
      String :name, size:48, null:false, comment:"名称"
      String :formal_name, size:96, comment:"正式名称"
      TrueClass :official, null:false, default:true, comment:"公認大会かどうか"
      Integer :kind, index:true, null:false, comment:"1:大会,2:コンパ/合宿/アフター,3:アンケート/購入"
      Integer :team_size, null:false, default:1, comment:"1:個人戦,3:三人団体戦,5:五人団体戦"
      String :description, text:true, comment:"備考"
      Date :deadline, comment:"締切日"
      Date :date, index:true, comment:"開催日時"
      String :start_at, size:5, comment:"開始時刻(HH:MM)"
      String :end_at, size:5, comment:"終了時刻(HH:MM)"
      String :place, size:255, comment:"場所"
      TrueClass :done, null:false, default:false, index:true, comment:"終わった大会/行事"
      TrueClass :public, null:false, default:true, index:true, comment:"公開されているか"
      TrueClass :register_done, null:false, default:false, comment:"登録者確認済み(締切を過ぎてからN日経過のメッセージを表示しない)"
      Integer :participant_count, null:false, default:0, comment:"参加者数(毎回aggregateするのは遅いのでキャッシュ)"
      String :forbidden_attrs, text:true, comment:"登録不可属性(user_attribute_values.idのリスト,json形式)"
      TrueClass :hide_choice, null:false, default:false, comment:"ユーザがどれを選択したかを管理者以外には分からなくする"
      Integer :attached_count, null:false, default:0, comment:"添付ファイルの数"
      foreign_key :event_group_id, :event_groups, on_delete: :set_null
      foreign_key :aggregate_attr_id, :user_attribute_keys, null:false, comment:"集計属性" 
    end
    
    create_table_custom(:event_choices,[:base],comment:"大会/行事の選択肢") do
      String :name, size:24, null:false
      TrueClass :positive, null:false, comment:"「参加する」「はい」などの前向きな回答"
      TrueClass :hide_result, null:false, default:false, comment:"回答した人の一覧を表示しない"
      Integer :index, null:false, comment:"順序"
      foreign_key :event_id, :events, null:false, on_delete: :cascade
    end
    
    create_table_custom(:event_comments,[:base,:env,[:comment,:events]], comment:"大会/行事のコメント") do
    end
 
    create_table_custom(:event_user_choices,[:base],comment:"どのユーザがどの選択肢を選んだか") do
      String :user_name, size:24, null:false, comment:"後で改名する人やUserにない人を登録できるように用意しておく"
      TrueClass :cancel, null:false, default:false, comment:"登録取り消しフラグ"
      foreign_key :attr_value_id, :user_attribute_values, null:false
      foreign_key :event_choice_id, :event_choices, null:false, on_delete: :cascade
      foreign_key :user_id, :users, on_delete: :set_null, comment:"usersにない人でも登録できるようにNULLを許可する"
    end

    create_table_custom(:event_owners,[:base],comment:"大会行事を編集する権限のある人") do
      foreign_key :user_id, :users, null:false, on_delete: :cascade
      foreign_key :event_id, :events, null:false, on_delete: :cascade
      index [:user_id,:event_id], unique:true
    end
    create_table_custom(:event_attached_files,[:base,[:attached,:events]],comment:"Wikiの添付ファイル") do
    end
  end
end
