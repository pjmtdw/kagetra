class MainApp < Sinatra::Base
  namespace '/api/event' do
    def event_info(ev,user)
      today = Date.today
      r = ev.select_attr(:name,:date,:deadline,:created_at,:id)
      r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
      r[:participant_count] = ev.choice(positive: true).user.count
      r[:choices] = ev.choice(order:[:index.asc]).map{|x|x.select_attr(:positive,:name,:id)}
      t = ev.choice.choice_of_user.first(user:user)
      r[:choice] = t && t.event_choice.id
      r
    end
    get '/item/:id' do
      user = get_user
      ev = Event.first(id:params[:id].to_i)
      r = event_info(ev,user)
      if params[:mode] == "detail"
        r.merge!(ev.select_attr(:description))
        r[:participant] = ev.choice(positive:true).each_with_object({}){|c,obj|
          obj[c.id] = c.user.map{|u|
            u.name
          }
        }
      end
      r
    end
    get '/list' do
      user = get_user
      (Event.all(:date.gte => Date.today) + Event.all(date: nil)).map{|ev|
        event_info(ev,user)
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
