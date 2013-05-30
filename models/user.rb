# -*- coding: utf-8 -*-
class User
  include ModelBase
  property :name,          Text
  property :furigana,      Text
  property :furigana_row,  Integer, index: true # 振り仮名の最初の一文字が五十音順のどの行か
  property :password_hash, String, length: 44
  property :password_salt, String, length: 32
  property :token,         String, length: 32
  property :admin,         Boolean, default: false

  before :save do
    self.furigana_row = Kagetra::Utils.gojuon_row_num(self.furigana)
  end

  def update_token!
    self.update!(token: SecureRandom.base64(24))
  end
  def admin?
    self.admin
  end
end

