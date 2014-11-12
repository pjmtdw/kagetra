require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:schedule_date_infos,[:base],comment:"予定表の祝日の情報") do
      Date :date, null:false, unique:true
      String :names, text:true
      TrueClass :holiday, default:false, comment:"休日かどうか"
    end
    
    create_table_custom(:schedule_items,[:base],comment:"予定表のアイテム") do
      Date :date, null:false, index:true
      Integer :kind, default:3, null:false, comment:"種類=>1:練習,2:コンパ,3:その他"
      Integer :emphasis, default:0, null:false, comment:"強調表示:下位bitからそれぞれname,start_at,end_at,place"
      TrueClass :public, default:true, comment:"公開されているか"
      String :name, size:48, null:false
      String :start_at, size:5, comment:"開始時刻(HH:MM)"
      String :end_at, size:5, comment:"終了時刻(HH:MM)"
      String :place, size:48, comment:"場所"
      String :description, text:true
      foreign_key :owner_id, :users, on_delete: :set_null, comment:"所有者"
    end    
  end
end
