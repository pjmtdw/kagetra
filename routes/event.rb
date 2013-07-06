# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/event' do
    get '/item/contest' do
      {
        team_size: 1,
        official: true,
        choices:[
          {name: "出場する", positive: true, id: -1},
          {name: "出場しない", positive: false, id: -1}],
        owners_str: @user.name,
        all_attrs: get_all_attrs
      }
    end
    get '/item/party' do
      {
        choices:[
          {name: "参加する", positive: true, id: -1},
          {name: "参加しない", positive: false, id: -1}],
        owners_str: @user.name,
        all_attrs: get_all_attrs
      }
    end

    def get_all_attrs
      UserAttributeKey.all(order:[:index.asc]).map{|x|[[x.id,x.name],x.values.map{|y|[y.id,y.value]}]}
    end

    def event_info(ev,user,opts = {})
      today = Date.today
      r = ev.select_attr(:place,:name,:date,:kind,:official,:deadline,:created_at,:id,:participant_count,:comment_count,:team_size)
      if ev.last_comment_date.nil?.! then
        r[:latest_comment_date] = ev.last_comment_date
        if user.show_new_from.nil?.! then
          if ev.last_comment_date > user.show_new_from and
            (ev.last_comment_user.nil? or ev.last_comment_user_id != user.id) then
            r[:has_new_comment] = true
          end
        end
      end
      r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
      if r[:deadline_day] and r[:deadline_day].between?(0,G_DEADLINE_ALERT) then
        r[:deadline_alert] = true
      end
      r[:choices] = ev.choices(order:[:index.asc]).map{|x|x.select_attr(:positive,:name,:id)}
      r[:editable] = @user.admin || ev.owners.include?(@user.id)
      r[:choice] = if opts.has_key?(:user_choices) then opts[:user_choices][ev.id] 
                   else
                     t = user.event_user_choices.event_choices.first(event:ev)
                     t && t.id
                   end
      opts[:user_attr_values] ||= user.attrs.value.map{|v|v.id}
      forbidden = (ev.forbidden_attrs & opts[:user_attr_values]).empty?.!
      r[:forbidden] = true if forbidden
      if opts[:detail] 
        r.merge!(ev.select_attr(:description,:formal_name,:start_at, :end_at))
        r.merge!(get_participant(ev,opts[:edit]))
        if opts[:edit]
          r[:all_attrs] = get_all_attrs
          r[:owners_str] = ev.owners.map{|u|User.get(u).name}.join(" , ")
          r.merge!(ev.select_attr(:forbidden_attrs,:hide_choice,:aggregate_attr_id))
        end
      end
      r
    end
    def get_participant(ev,edit_mode)
      participant_names = {}
      participant_attrs = ev.aggregate_attr.values(:id.not => ev.forbidden_attrs).map{|x|[x.id,x.value]}
      sort_and_map = ->(h){
        h.sort_by{|k,v|k.index}
        .map{|k,v|
          [k.id,v.map{|x|x.id}]}}
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
      ev = Event.get(params[:id].to_i)
      event_info(ev,@user,{detail:params[:detail]=="true",edit:params[:edit]=="true"})
    end
    delete '/item/:id' do
      # 関連する物を削除しないとdestroyできないが，全部削除はしたくないので deleted フラグを付けるだけにする
      Event.get(params[:id].to_i).update!(deleted:true)
    end

    def update_or_create_item
      @json.delete("all_attrs") # get時に付加したmodelにない情報なので削除する．TODO: 不要な情報なのでクライアント側で削除する
      dm_response{
        Event.transaction{
          @json["hide_choice"] = @json["hide_choice"].to_s.empty?.!
          choices = if @json.has_key?("choices") then
            @json.delete("choices")
          end
          if @json.has_key?("owners_str") then
            owners = @json["owners_str"].split(/\s*,\s*/).map{|s|
              u = User.first(name:s)
              if u.nil? then
                raise Exception.new("invalid owner name: #{s}")
              end
              u.id
            }
            @json.delete("owners_str")
            @json["owners"] = owners
          end
          if @json.has_key?("forbidden_attrs")
            # 一つしかない場合は Array じゃなくて String で送られてくる
            @json["forbidden_attrs"] = [@json["forbidden_attrs"]].flatten.map{|x|x.to_i}
          end
          ev = Event.update_or_create({id:params[:id]},@json)
          if choices.nil?.! then
            choice_ids = ev.choices.map{|c|c.id}
            choices.each_with_index{|o,i|
              cond = o.select_attr("name","positive").merge({index:i})
              if o["id"] < 0 then
                ev.choices.create(cond)
              else
                ev.choices.get(o["id"]).update(cond)
                choice_ids.delete(o["id"])
              end
            }
            if choice_ids.empty?.! then
              ev.choices.all(id:choice_ids).destroy
            end
          end
          event_info(ev,@user)
        }
      }
    end

    put '/item/:id' do
      update_or_create_item
    end
    post '/item' do
      update_or_create_item
    end
    get '/list' do
      events = (Event.all(:date.gte => Date.today) + Event.all(date: nil))

      # 各eventごとに取得するのは遅いのでまとめて取得しておく
      user_choices = @user.event_user_choices.event_choice(event:events).to_enum.with_object({}){|x,h|h[x.event_id]=x.id}
      user_attr_values = @user.attrs.value.map{|v|v.id}

      events.map{|ev|
        event_info(ev,@user,{user_choices:user_choices,user_attr_values:user_attr_values})
      }
    end
    put '/choose/:cid' do
      Kagetra::Utils.dm_debug{
        c = EventChoice.first(id:params[:cid].to_i)
        c.user_choices.create(user:@user)
        {count: c.event.participant_count}
      }
    end
    put '/participants/:id' do
      dm_response{
        # TODO: ev が使われていない
        #       event_choice_id がちゃんとそのEventに属しているか念のためにチェック
        ev = Event.get(params[:id].to_i)
        EventUserChoice.transaction{
          @json["log"].each{|name,v|
            (cmd,attr,choice) = v
            case cmd
            when "add" then
              EventUserChoice.create(
                event_choice_id:choice,
                user_name:name,
                user: User.first(name:name),
                attr_value_id:attr)
            when "delete" then
              c = EventUserChoice.first(
                event_choice_id:choice,
                user_name:name,
                attr_value_id:attr)
              if c then c.destroy end
            end
          }
        }
      }
    end
  end
  comment_routes("/api/event",Event,EventComment)
end
