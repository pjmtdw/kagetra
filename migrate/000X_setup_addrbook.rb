require_relative './helper'
Sequel.migration do
  change do
    create_table_custom(:addr_books, [:base], comment: "名簿") do
      foreign_key :user_id, :users, null:false, unique:true
      foreign_key :album_item_id, :album_items, on_delete: :set_null
      String :text, text:true, comment: '暗号化+Base64されたテキスト，平文はJSON形式 {"項目1":"値1","項目2":"値2"}'
    end
  end
end
