# -*- coding: utf-8 -*-
module MiscHelpers
  def get_user
    User.first(id: session[:user_id], token: session[:user_token])
  end
end
