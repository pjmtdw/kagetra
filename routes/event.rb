class MainApp < Sinatra::Base
  namespace '/api/event' do
    get '/list' do
      (Event.all(:date.gte => Date.today) + Event.all(date: nil)).map{|x|
        x.select_attr(:name,:date,:deadline,:created_at)
      }
    end
  end
end
