require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:contest_classes,[:base],comment:"大会の各級の情報") do
      String :class_name, size:16, null:false, comment:"級の名前"
      Integer :class_rank, comment:"級のランク（団体戦や非公認大会ならNULL，その他は1=>A級,2=>B級,3=>C級,4=>D級...）"
      Integer :index, null:false, comment:"順番"
      Integer :num_person, comment:"その級の他会の人も含む出場人数(個人戦のみ)"
      String :round_name, text:true, comment:'順位決定戦の名前(個人戦のみ)，{"4":"準決勝","5":"決勝"}のような形式'
      foreign_key :event_id, :events, null:false, on_delete: :cascade

      index [:event_id, :class_name], name: :unique_contest_classes_u1, unique:true
    end

    create_table_custom(:contest_users,[:base], comment:"大会出場者の情報") do
      String :name, size:24, null:false, index:true, comment:"後に改名する人や,usersに入ってない人のため"
      foreign_key :user_id, :users, on_delete: :set_null, comment:"usersテーブルから削除されたりした人のためにnullも許容"
      foreign_key :event_id, :events, null:false, on_delete: :cascade
      foreign_key :contest_class_id, :contest_classes, null:false, on_delete: :cascade
      Integer :win, default:0, comment:"この大会の勝ち数(aggregateするのは遅いのでキャッシュ)"
      Integer :lose, default:0, comment:"この大会の負け数(aggregateするのは遅いのでキャッシュ)"
      Integer :point, default:0, comment:"A級のポイント(aggregateするのは遅いのでキャッシュ)"
      Integer :point_local, default:0, comment:"会内ポイント(aggregateするのは遅いのでキャッシュ)"
      Integer :class_rank, comment:"contest_classesのclass_rankのキャッシュ"
      
      index [:user_id, :event_id], name: :unique_contest_users_u1, unique:true
    end
    
    create_table_custom(:contest_teams,[:base],comment:"どのチームがどの級に出場しているか(団体戦)") do
      foreign_key :contest_class_id, :contest_classes, null:false, on_delete: :cascade
      String :name, size:48, null:false, comment:"チーム名"
      String :prize, size:24, comment:"チーム入賞"
      Integer :rank, comment:"チーム入賞から推定した順位"
      Integer :promotion, comment:"1:昇級,2:陥落"
      
      index [:contest_class_id, :name], name: :unique_contest_teams_u1, unique:true
    end

    create_table_custom(:contest_team_members,[:base],comment:"誰がどのチームの何将か(団体戦)") do
      foreign_key :contest_user_id, :contest_users, null:false, on_delete: :cascade
      foreign_key :contest_team_id, :contest_teams, null:false, on_delete: :cascade
      Integer :order_num, null:false, comment:"将順"
      index [:contest_user_id, :contest_team_id], name: :unique_contest_team_members_u1, unique:true
    end
    
    create_table_custom(:contest_team_opponents,[:base],comment:"各チームが何回戦にどのチームと対戦したか") do
      foreign_key :contest_team_id, :contest_teams, null:false, on_delete: :cascade
      String :name, size:48, comment:"対戦相手のチーム名"
      Integer :round, null:false, comment:"回戦"
      String :round_name, size:36, comment:"決勝，順位決定戦など"
      Integer :kind, null:false, comment:"1:団体戦,2:個人戦(大会形式は団体戦だけど相手の所属がバラバラ)"
      
      index [:contest_team_id, :round], name: :unique_contest_team_opponents_u1, unique:true
    end
    
    
    create_table_custom(:contest_games,[:base],comment:"大会の試合結果") do
      String :type, size:8, null:false, comment:"single:個人戦, team:団体戦"
      foreign_key :event_id, :events, null:false, on_delete: :cascade
      foreign_key :contest_user_id, :contest_users, null:false, on_delete: :cascade
      Integer :result, null:false, comment:"勝敗 => 1:対戦中,2:勝ち,3:負け,4:不戦勝"
      String :score_str, size:8, comment:"枚数(文字),'棄'とか'3+1'とかあるので文字列を用意しておく"
      Integer :score_int, index:true, comment:"score_strをintとしてparseしたもの"
      String :comment, text:true

      String :opponent_name, index:true, size:24, comment:"対戦相手の名前"
      String :opponent_belongs, size:36, comment:"対戦相手の所属，基本的には個人戦のみ使用するが団体戦でも対戦相手の所属がバラバラな場合はここに書く"

      # 個人戦用
      foreign_key :contest_class_id, :contest_classes, comment:"個人戦用"
      Integer :round, comment:"個人戦用:回戦" 

      # 団体戦用
      foreign_key :contest_team_opponent_id, :contest_team_opponents, comment:"団体戦用"
      Integer :opponent_order, comment:"団体戦用:相手の将順"
      
      
      # > According to the ANSI standards SQL:92, SQL:1999, and SQL:2003, a UNIQUE constraint should disallow duplicate non-NULL values, but allow multiple NULL values
      # とのこと．ただし Microsoft の SQL Server は ANSI満たしてないらしい．
      # https://connect.microsoft.com/SQLServer/feedback/details/299229/change-unique-constraint-to-allow-multiple-null-values
      # ゆえに MySQL とかでは :type の種類に関わらず下記の unique index で大丈夫なはず
      index [:contest_user_id, :contest_class_id, :round], name: :unique_contest_games_u1, unique:true
      index [:event_id, :contest_user_id, :contest_class_id, :round], name: :unique_contest_games_u2, unique:true
      index [:event_id, :contest_user_id, :contest_team_opponent_id], name: :unique_contest_games_u3, unique:true
    end
    
    create_table_custom(:contest_prizes,[:base]) do
      foreign_key :contest_class_id, :contest_classes, null:false, on_delete: :cascade
      foreign_key :contest_user_id, :contest_users, null:false, on_delete: :cascade
      String :prize, size:32, null:false, comment:"実際の名前（優勝，全勝賞など）"
      Integer :promotion, comment:"1:昇級,2:ダッシュ,3:A級優勝"
      Integer :point, default:0, comment:"A級のポイント"
      Integer :point_local, default:0, comment: "会内ポイント"
      Integer :rank, comment:"順位=>1:優勝,2:準優勝,3:三位,..."
      
      index [:contest_class_id, :contest_user_id], name: :unique_contest_prizes_u1, unique:true
    end
    
    create_table_custom(:contest_promotion_caches,[:base],comment:"昇級ランキング用キャッシュ") do
      String :prize, size:32, null:false, comment:"contest_prizes.prizeのキャッシュ"
      String :class_name, size:16, null:false, comment:"contest_classes.class_nameのキャッシュ"
      String :user_name, size:24, null:false, comment:"contest_users.nameのキャッシュ"
      Date :event_date, null:false, comment:"events.dateのキャッシュ"
      String :event_name, size:48, null:false
      Date :debut_date, null:false, comment:"初出場大会もしくは前回昇級してから次の大会の日付"
      Integer :contests, null:false, comment:"昇級した級の大会出場数"
      Integer :promotion, null:false, comment:"contest_prizes.promotionのキャッシュ"
      Integer :class_rank, null:false, comment:"contest_classes.class_rankのキャッシュ"
      Integer :a_champ_count, comment:"何回目のA級優勝か"
      foreign_key :contest_prize_id, :contest_prizes, null:false, unique:true, on_delete: :cascade
      foreign_key :contest_user_id, :contest_users, null:false, unique:true, on_delete: :cascade
      foreign_key :event_id, :events, null:false, comment:"昇級した大会", on_delete: :cascade
    end
    
    create_table_custom(:contest_result_caches,[:base],comment:"毎回aggregateするのは遅いのでキャッシュ") do
      foreign_key :event_id, :events, null:false, on_delete: :cascade
      Integer :win, default:0, comment: "勝ち数の合計"
      Integer :lose, default:0, comment: "負け数の合計"
      String :prizes, text:true, comment: "入賞情報(JSON)" 
    end
     
  end
end
