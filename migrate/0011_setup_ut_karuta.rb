require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:ut_karuta_form,[:base]) do
      String :name, size:64
      String :mail, size:128
      String :body, text:true
      Integer :status, null:false, default:1, comment:"未返信なら1,返信済みなら2,無視するなら3"
      String :status_change_user, size:24
      DateTime :status_change_at
    end
  end
end
