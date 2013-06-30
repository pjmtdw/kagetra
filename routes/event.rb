# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/event' do
    def event_info(ev,user,user_choices=nil)
      today = Date.today
      r = ev.select_attr(:name,:date,:kind,:official,:deadline,:created_at,:id,:participant_count,:comment_count,:team_size)
      if ev.last_comment_date.nil?.! then
        r[:latest_comment_date] = ev.last_comment_date
        if user.show_new_from.nil?.! then
          r[:has_new_comment] = true if ev.last_comment_date > user.show_new_from and
            (ev.last_comment_user.nil? or ev.last_comment_user != user.id)
        end
      end
      r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
      if r[:deadline_day] and r[:deadline_day].between?(0,G_DEADLINE_ALERT) then
        r[:deadline_alert] = true
      end
      r[:choices] = ev.choices(order:[:index.asc]).map{|x|x.select_attr(:positive,:name,:id)}
      r[:choice] = if user_choices then user_choices[ev.id] 
                   else
                     t = user.event_user_choices.event_choices.first(event:ev)
                     t && t.id
                   end
      forbidden = (ev.forbidden_attrs & user.attrs.value.map{|v|v.id}).empty?.!
      r[:forbidden] = true if forbidden
      r
    end
    get '/item/:id' do
      user = get_user
      ev = Event.first(id:params[:id].to_i)
      r = event_info(ev,user)
      if params[:detail] == "true"
        r.merge!(ev.select_attr(:description,:formal_name,:start_at, :end_at))
        sort_and_map = ->(h){
          h.sort_by{|k,v|k.index}
          .map{|k,v|{k.value => v.map{|x|x[:user_name]}}}
        }
        filter_user_choices = ->(uc,hide_result){
          uc.map{|x|
            {
              attr_value: x.attr_value,
              user_name: if hide_result then "@" else x.user_name end
            }
          }
        }
        choices = ev.choices(positive:true)
        r[:participant] = 
          if ev.hide_choice then
            res = Hash.new{[]}
            choices.each{|c|
              filter_user_choices.call(c.user_choices,c.hide_result).each{|uc|
                res[uc[:attr_value]] <<= uc
              }
            }
            {-1 => sort_and_map.call(res)}
          else
            choices.each_with_object({}){|c,obj|
              obj[c.id] = sort_and_map.call(filter_user_choices.call(c.user_choices,c.hide_result).group_by{|x|x[:attr_value]})
            }
          end
      end
      r
    end
    put '/item/:id' do
      user = get_user
      dm_response{
        ev.update(@json)
        event_info(ev,user)
      }
    end
    post '/item' do
      user = get_user
      dm_response{
        ev = Event.create(@json.merge({owners:[user],aggregate_attr:UserAttributeKey.first()}))
        event_info(ev,user)
      }
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
    put '/choose/:cid' do
      Kagetra::Utils.dm_debug{
        user = get_user
        c = EventChoice.first(id:params[:cid].to_i)
        c.user_choices.create(user:user)
        {count: c.event.participant_count}
      }
    end
    get '/comment/list/:id' do
      user = get_user
      evt = Event.first(id:params[:id].to_i)
      list = evt.comments(order: [:created_at.desc]).map{|x|
        r = x.select_attr(:id,:user_name,:body)
          .merge({
            date: x.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          })
        r[:is_new] = x.is_new(user)
        r
      }
      {
        event_name: evt.name,
        list: list
      }
    end
    post '/comment/item' do
      dm_response{
        user = get_user
        evt = Event.get(@json["event_id"].to_i)
        c = evt.comments.create(user:user,body:@json["body"])
      }
    end
    put '/comment/item/:id' do
      dm_response{
        user = get_user
        EventComment.get(params[:id].to_i).update(body:@json["body"])
      }
    end
    delete '/comment/item/:id' do
      Kagetra::Utils.dm_debug{
        EventComment.get(params[:id]).destroy()
      }
    end
  end
end
