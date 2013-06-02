# -*- coding: utf-8 -*-
module MiscHelpers
  def get_user
    user = User.first(id: session[:user_id], token: session[:user_token]) || User.new(name:"guest")
  end
end
