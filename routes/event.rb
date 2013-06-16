# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/event' do
    def event_info(ev,user,user_choices=nil)
      today = Date.today
      r = ev.select_attr(:name,:date,:deadline,:created_at,:id,:participant_count,:comment_count)
      if ev.latest_comment.nil?.! then
        comment_date = ev.latest_comment.created_at
        r[:latest_comment_date] = comment_date
        if user.show_new_from.nil?.! then
          r[:has_new_comment] = true if comment_date > user.show_new_from and ev.latest_comment.user.id != user.id
        end
      end
      r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
      r[:choices] = ev.choices(order:[:index.asc]).map{|x|x.select_attr(:positive,:name,:id)}
      r[:choice] = if user_choices then user_choices[ev.id] 
                   else
                     t = user.event_user_choices.event_choices.first(event:ev)
                     t && t.id
                   end
      r
    end
    get '/item/:id' do
      user = get_user
      ev = Event.first(id:params[:id].to_i)
      r = event_info(ev,user)
      if params[:mode] == "detail"
        r.merge!({description: Kagetra::Utils.escape_html_br(ev.description)})
        r[:participant] = ev.choices(positive:true).each_with_object({}){|c,obj|
          obj[c.id] = c.user_choices.group_by{|x|x.attr_value}
          .sort_by{|k,v|k.index}.map{|k,v| {k.value => v.map{|x|x.user_name}}}}
      end
      r
    end
    get '/list' do
      user = get_user
      events = (Event.all(:date.gte => Date.today) + Event.all(date: nil))

      # 各eventごとに取得するのは遅いのでまとめて取得しておく
      user_choices = user.event_user_choices.event_choice(event:events).to_enum.with_object({}){|x,h|h[x.event_id]=x.id}

      events.map{|ev|
        event_info(ev,user,user_choices)
      }
    end
    post '/choose/:eid/:cid' do
      begin
        user = get_user
        evt = Event.first(id:params[:eid].to_i)
        evt.choices.first(id:params[:cid].to_i).user_choices.create(user:user)
        {count: evt.participant_count}
      rescue DataMapper::SaveFailureError => e
        p e.resource.errors
      end
    end
    get '/comment/list/:id' do
      user = get_user
      evt = Event.first(id:params[:id].to_i)
      list = evt.comments(order: [:created_at.desc]).map{|x|
        r = x.select_attr(:user_name)
          .merge({
            date: x.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            body: Kagetra::Utils.escape_html_br(x.body)
          })
        if x.user.id != user.id and 
          user.show_new_from.nil?.! and
          x.created_at >= user.show_new_from then
          r[:is_new] = true
        end
        r
      }
      {
        event_name: evt.name,
        list: list
      }
    end
    post '/comment/item' do
      begin
        user = get_user
        evt = Event.first(id:params[:event_id].to_i)
        c = evt.comments.create(user:user,body:params[:body])
      rescue DataMapper::SaveFailureError => e
        p e.resource.errors
      end
    end
  end
end
