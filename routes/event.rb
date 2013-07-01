# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/event' do
    def event_info(ev,user,user_choices=nil,user_attr_values=nil)
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
      user_attr_values ||= user.attrs.value.map{|v|v.id}
      forbidden = (ev.forbidden_attrs & user_attr_values).empty?.!
      r[:forbidden] = true if forbidden
      r
    end
    def get_participant(ev,edit_mode)
      participant_names = {}
      participant_attrs = ev.aggregate_attr.values.map{|x|[x.id,x.value]}
      sort_and_map = ->(h){
        h.sort_by{|k,v|k.index}
        .map{|k,v|
          {k.id => v.map{|x|x.id}}}}
      add_participant_names = ->(ucs,hide_result){
        if hide_result and not edit mode then return end
        participant_names.merge!(Hash[ucs.map{|u|[u.id,u.user_name]}])
      }
      cond = if edit_mode then {} else {positive:true} end
      choices = ev.choices(cond)
      res = if ev.hide_choice and not edit_mode then
              res = Hash.new{[]}
              choices.each{|c|
                ucs = c.user_choices
                add_participant_names.call(ucs,c.hide_result)
                ucs.each{|uc|
                  res[uc.attr_value] <<= uc
                }
              }
              {-1 => sort_and_map.call(res)}
            else
              choices.each_with_object({}){|c,obj|
                ucs = c.user_choices
                add_participant_names.call(ucs,c.hide_result)
                obj[c.id] = sort_and_map.call(
                  ucs.group_by{|x|x.attr_value}
                )
              }
            end
      {
        participant: res,
        participant_names: participant_names,
        participant_attrs: participant_attrs
      }
    end
    get '/item/:id' do
      user = get_user
      ev = Event.first(id:params[:id].to_i)
      r = event_info(ev,user)
      if params[:detail] == "true"
        r.merge!(ev.select_attr(:description,:formal_name,:start_at, :end_at))
        r.merge!(get_participant(ev,params[:edit] == "true"))
        if params[:edit] == "true"
          r[:all_attrs] = UserAttributeKey.all(order:[:index.asc]).map{|x|[x.name,x.values.map{|y|[y.id,y.value]}]}
          r[:forbidden_attrs] = ev.forbidden_attrs
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
      user_attr_values = user.attrs.value.map{|v|v.id}

      events.map{|ev|
        event_info(ev,user,user_choices,user_attr_values)
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
