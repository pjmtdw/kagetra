# -*- coding: utf-8 -*-
class User
  include ModelBase
  property :guest,         Boolean, default: false # 行事や大会にしか登録していないユーザ
  property :name,          String, length: 24, required: true
  property :furigana,      String, length: 36, required: true
  property :furigana_row,  Integer, index: true # 振り仮名の最初の一文字が五十音順のどの行か
  property :password_hash, String, length: 44
  property :password_salt, String, length: 32
  property :token,         String, length: 32
  property :admin,         Boolean, default: false
  #has n, :attr, "UserAttributeValue", through: :user_attribute
  
  has n, :event_user_choices

  before :save do
    self.furigana_row = Kagetra::Utils.gojuon_row_num(self.furigana)
  end
  def update_token!
    self.update(token: SecureRandom.base64(24))
  end
end

# TODO: unique constraint that one user can have one attribute per key
# どのユーザがどのユーザ属性を持っているか
class UserAttribute
  include ModelBase
  property :user_id, Integer, unique_index: :u1, required: true
  belongs_to :user
  property :user_attribute_key_id, Integer, unique_index: :u1, required: true
  belongs_to :user_attribute_key
  property :user_attribute_value_id, Integer, unique_index: :u1, required: true
  belongs_to :user_attribute_value
end
  

# ユーザ属性の名前
class UserAttributeKey
  include ModelBase
  property :name, String, length: 36, required:true
  property :index, Integer, required: true # 順番
end

# ユーザ属性の値
class UserAttributeValue
  include ModelBase
  property :user_attribute_key_id, Integer, unique_index: :u1, required: true
  belongs_to :user_attribute_key
  property :value, String, length: 48, unique_index: :u1, required: true
  property :index, Integer, required: true
end
