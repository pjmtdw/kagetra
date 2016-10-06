# -* coding: utf-8 -*-

class UtKarutaForm < Sequel::Model(:ut_karuta_form)
  serialize_attributes Kagetra::serialize_enum([:notyet,:done,:ignore]), :status
  def self.has_new_item(user)
    search_from = user.show_new_from || Time.now
    DB.select(self.where{created_at >= search_from}.exists).first[:exists]
  end
  def update_status(user_name,status)
    self.update(status: status,
                status_change_user: user_name,
                status_change_at: Time.now)
  end
end
