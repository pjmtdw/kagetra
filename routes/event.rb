class MainApp < Sinatra::Base
  namespace '/api/event' do
    get '/list' do
      user = get_user
      today = Date.today
      (Event.all(:date.gte => Date.today) + Event.all(date: nil)).map{|x|
        r = x.select_attr(:name,:date,:deadline,:created_at,:id)
        r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
        r[:participant] = x.choice(positive: true).user.count
        r[:choices] = x.choice(order:[:index.asc]).map{|y|y.select_attr(:positive,:name,:id)}
        t = x.choice.choice_of_user.first(user:user)
        r[:choice] = t && t.event_choice.id
        r
      }
    end
    post '/choose/:eid/:cid' do
      begin
        user = get_user
        event = Event.first(id:params[:eid].to_i)
        event.choice.first(id:params[:cid].to_i).choice_of_user.create(user:user)
      rescue DataMapper::SaveFailureError => e
        p e.resource.errors
      end
    end
  end
end
