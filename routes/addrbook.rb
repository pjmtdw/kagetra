# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base 
  namespace '/api/addrbook' do
    get '/item/:uid' do
      AddrBook.first(user_id:params[:uid]).select_attr(:text)
    end
  end
  get '/addrbook' do
    user = get_user
    haml :addrbook,{locals: {user: user}}
  end
end
