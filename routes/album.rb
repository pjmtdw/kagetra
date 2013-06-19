# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/album' do
    get '/year/:year' do
      year = params[:year]
      {list: AlbumGroup.all(year:year, order: [:start_at.desc]).map{|x|x.select_attr(:name,:start_at)}}
    end
    get '/years' do
      {list: AlbumGroup.all(fields:[:year], unique: true, order: [:year.desc]).map{|x|x.year}}
    end
  end
  get '/album' do
    user = get_user
    haml :album,{locals: {user: user}}
  end
end
