# -*- coding: utf-8 -*-
module MiscHelpers
  def get_user
    user = User.first(id: session[:user_id], token: session[:user_token])
    if user.nil? then
      halt 403,'Login Required.'
    end
    user
  end
end
