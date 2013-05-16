# -*- coding: utf-8 -*-
module Kagetra
  module Helpers
    def get_user
      User.first(:id => session[:user_id], :token => session[:user_token])
    end
  end
end
