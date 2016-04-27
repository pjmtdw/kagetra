# -* coding: utf-8 -*-

class UtKarutaForm < Sequel::Model(:ut_karuta_form)
  def self.has_new_item(user)
    search_from = user.show_new_from || Time.now
    DB.select(self.where{created_at >= search_from}.exists).first[:exists]
  end
end
