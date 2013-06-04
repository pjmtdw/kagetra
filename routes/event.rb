class MainApp < Sinatra::Base
  namespace '/api/event' do
    get '/list' do
      today = Date.today
      (Event.all(:date.gte => Date.today) + Event.all(date: nil)).map{|x|
        r = x.select_attr(:name,:date,:deadline,:created_at)
        r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
        r
      }
    end
  end
end
