# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/result_list' do
    get '/year/:year' do
      minyear = Event.aggregate(:date.min,kind:[:contest]).year
      year = params[:year].to_i
      sday = Date.new(year,1,1)
      eday = Date.new(year+1,1,1)
      list = Event.all(:date.gte => sday, :date.lt => eday, done: true, kind:[:contest], order:[:date.desc]).map{|x|
        result_summary(x)
      }
      {list:list,minyear:minyear,maxyear:Date.today.year,curyear:year}
    end
  end
  get '/result_list' do
    haml :result_list
  end
end
