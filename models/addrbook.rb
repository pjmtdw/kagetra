# -*- coding: utf-8 -*-

# 名簿
class AddrBook
  include ModelBase
  property :deleted, ParanoidBoolean, lazy: false
  property :text, TrimText # 暗号化+Base64されたテキスト，平文はJSON形式 {"項目1":"値1","項目2":"値2"}
  property :user_id, Integer, unique: true, required: true
  belongs_to :user
  belongs_to :album_item, required: false
end
