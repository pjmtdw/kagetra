# -*- coding: utf-8 -*-
# 地図
class MainApp < Sinatra::Base
  get '/map' do
    haml :map
  end
end
