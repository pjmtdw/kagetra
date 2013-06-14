# -*- coding: utf-8 -*-
class User
  include ModelBase
  property :name,          String, length: 24, required: true, lazy: true
  property :furigana,      String, length: 36, required: true, lazy: true
  property :furigana_row,  Integer, index: true, allow_nil: false, lazy:true # 振り仮名の最初の一文字が五十音順のどの行か
  property :password_hash, String, length: 44, lazy: true
  property :password_salt, String, length: 32, lazy: true
  property :token,         String, length: 32, lazy: true # 認証用トークン
  property :admin,         Boolean, default: false
  property :bbs_public_name, String, length: 24, lazy: true

  has n, :attrs, 'UserAttribute'
  
  has n, :event_user_choices

  before :save do
    self.furigana_row = Kagetra::Utils.gojuon_row_num(self.furigana)
  end
  def update_token!
    self.update(token: SecureRandom.base64(24))
  end
end

class UserAttribute
  include ModelBase
  belongs_to :user
  belongs_to :value, 'UserAttributeValue'
  before :save do
    #一人のユーザは各属性keyにつき一つの属性valueしか持てない
    values = self.value.attr_key.values
    self.user.attrs(value: values).destroy
  end
end
  

# ユーザ属性の名前
class UserAttributeKey
  include ModelBase
  property :name, String, length: 36, required:true
  property :index, Integer, required: true, unique: true # 順番
  has n, :values, 'UserAttributeValue', child_key: [:attr_key_id]
end

# ユーザ属性の値
class UserAttributeValue
  include ModelBase
  property :attr_key_id, Integer, unique_index: :u1, required: true
  belongs_to :attr_key, 'UserAttributeKey'
  property :value, String, length: 48, required: true
  property :index, Integer, unique_index: :u1, required: true
end
