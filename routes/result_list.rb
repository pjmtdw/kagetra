# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  PROMOTION_MAX_DAY = 365
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
    get '/promotion' do
      event_ids = Event.all(:date.gte => Date.today - PROMOTION_MAX_DAY, fields:[:id]).map{|x|x.id}
      list = ContestResultCache.all(event_id:event_ids,:prizes.not=>[]).map{|x|
        x.prizes.select{|y|
          y["type"] == "person" and y["promotion"] == "rank_up"
        }.map{|y|
          u = User.get(y["user_id"])
          attr_values = if u.nil? then [] else u.attrs.value.map{|x|x[:id]} end 
          y.select_attr("class_name","name","prize","user_id").merge({event:x.event.select_attr(:name,:date),attr_values:attr_values})
        }
      }.flatten.sort_by{|x|
        x[:event][:date]
      }.reverse
      attrs = UserAttributeKey.all(name:G_PROMOTION_ATTRS,order:[:index.asc]).map{|x|
        [x.name,x.values.map{|y|[y.value,y.id]}]
      }
      {list:list,attrs:attrs}
    end
  end
  get '/result_list' do
    haml :result_list
  end
  get '/result_promotion' do
    haml :result_promotion
  end
end
