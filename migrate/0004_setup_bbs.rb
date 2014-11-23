require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:bbs_threads,[:base,:thread],comment:"掲示板のスレッド") do
      String :title, size:48, null:false
      TrueClass :public, null:false, default:false, comment: "外部公開されているか"
    end

    create_table_custom(:bbs_items,[:base,:env,[:comment,:bbs_threads]],comment:"掲示板の書き込み") do
      TrueClass :is_first, null:false, default:false, index: true, comment: "スレッドにおける最初の書き込み"
    end
  end
end
