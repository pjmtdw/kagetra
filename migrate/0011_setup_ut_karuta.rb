require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:ut_karuta_form,[:base]) do
      String :name, size:64
      String :mail, size:128
      String :body, text:true
      Integer :flag, null:false, default:0, comment:"返信済みなら1"
    end
  end
end
