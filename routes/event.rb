class MainApp < Sinatra::Base
  namespace '/api/event' do
    def event_info(ev,user)
      today = Date.today
      r = ev.select_attr(:name,:date,:deadline,:created_at,:id)
      r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
      r[:participant_count] = ev.choices(positive: true).users.count
      r[:comment_count] = ev.comments.count
      r[:choices] = ev.choices(order:[:index.asc]).map{|x|x.select_attr(:positive,:name,:id)}
      t = ev.choices.user_choices.first(user:user)
      r[:choice] = t && t.event_choice.id
      r
    end
    get '/item/:id' do
      user = get_user
      ev = Event.first(id:params[:id].to_i)
      r = event_info(ev,user)
      if params[:mode] == "detail"
        r.merge!({description: Kagetra::Utils.escape_html_br(ev.description)})
        r[:participant] = ev.choices(positive:true).each_with_object({}){|c,obj|
          obj[c.id] = c.users.map{|u|
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
        event.choices.first(id:params[:cid].to_i).user_choices.create(user:user)
      rescue DataMapper::SaveFailureError => e
        p e.resource.errors
      end
    end
    get '/comment/list/:id' do
      evt = Event.first(id:params[:id].to_i)
      evt.comments(order: [:created_at.desc]).map{|x|
        x.select_attr(:user_name)
          .merge({
            date: x.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            body: Kagetra::Utils.escape_html_br(x.body)
          })
      }
    end
    post '/comment/item' do
      begin
        user = get_user
        evt = Event.first(id:params[:event_id].to_i)
        # TODO: automatically set user_name from user in model's :save hook
        c = evt.comments.create(user:user,body:params[:body],user_name:user.name)
      rescue DataMapper::SaveFailureError => e
        p e.resource.errors
      end
    end
  end
end
