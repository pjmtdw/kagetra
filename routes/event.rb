# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/event' do
    get '/item/contest' do
      # 大会を新規作成するときのデフォルトの値
      {
        public:true,
        team_size: 1,
        official: true,
        choices:[
          {name: "出場する", positive: true, id: -1},
          {name: "出場しない", positive: false, id: -1}],
        owners_str: @user.name,
        all_attrs: get_all_attrs,
        all_event_groups: get_all_event_groups,
        aggregate_attr_id: UserAttributeKey.first(name:CONF_CONTEST_DEFAULT_AGGREGATE_ATTR).id,
        forbidden_attrs: CONF_CONTEST_DEFAULT_FORBIDDEN_ATTRS.map{|k,v|UserAttributeKey.where(name:k).first.attr_values_dataset.where(value:v).map(&:id)}.flatten
      }
    end
    get '/item/party' do
      # 行事を新規作成するときのデフォルトの値
      {
        public:true,
        choices:[
          {name: "参加する", positive: true, id: -1},
          {name: "参加しない", positive: false, id: -1}],
        owners_str: @user.name,
        all_attrs: get_all_attrs,
        aggregate_attr_id: UserAttributeKey.first(name:CONF_PARTY_DEFAULT_AGGREGATE_ATTR).id
      }
    end

    def get_all_attrs
      UserAttributeKey.order(Sequel.asc(:index)).map{|x|[[x.id,x.name],x.attr_values.map{|y|[y.id,y.value]}]}
    end
    def get_all_event_groups
      EventGroup.order(Sequel.asc(:name)).map{|x|x.select_attr(:id,:name)}
    end

    def event_info(ev,user,opts = {})
      today = Date.today
      is_owner = ev.owners.map(&:id).include?(@user.id) 
      r = ev.to_deserialized_hash.select_attr(:place,:name,:date,:kind,:official,:deadline,:created_at,:id,:participant_count,:comment_count,:team_size,:event_group_id,:public,:last_comment_date)
      r[:has_new_comment] = ev.has_new_comment(user)
      r[:deadline_day] = (r[:deadline]-today).to_i if r[:deadline]
      if r[:deadline_day] and r[:deadline_day].between?(0,G_DEADLINE_ALERT) then
        r[:deadline_alert] = true
      end
      if is_owner and r[:deadline_day] and r[:deadline_day] < 0 and not ev.register_done then
        r[:deadline_after] = true
      end
      r[:choices] = ev.choices_dataset.order(Sequel.asc(:index)).map{|x|x.values.select_attr(:positive,:name,:id)}
      r[:editable] = @user.admin || is_owner || (ev.done and ev.kind == :contest and @user.permission.include?(:sub_admin))
      r[:choice] = if opts.has_key?(:user_choices) then opts[:user_choices][ev.id]
                   else
                     t = EventChoice.first(event:ev,user_choices:user.event_user_choices)
                     t && t.id
                   end
      opts[:user_attr_values] ||= UserAttributeValue.where(user_attributes:user.attrs_dataset).map(&:id)
      forbidden = (ev.forbidden_attrs & opts[:user_attr_values]).empty?.!
      r[:forbidden] = true if forbidden
      if opts[:detail]
        r.merge!(ev.select_attr(:description,:formal_name,:start_at, :end_at, :done))
        r.merge!(get_participant(ev,opts[:edit])) unless opts[:no_participant]
        if opts[:edit]
          r[:all_attrs] = get_all_attrs
          r[:owners_str] = ev.owners.map(&:name).join(" , ")
          r[:all_event_groups] = get_all_event_groups
          r.merge!(ev.select_attr(:forbidden_attrs,:hide_choice,:register_done,:aggregate_attr_id))
        end
      end
      r
    end
    def get_participant(ev,edit_mode)
      participant_names = {}
      attr_query = UserAttributeValue.where(attr_key:ev.aggregate_attr).where(Sequel.~(id:ev.forbidden_attrs)).all
      # TODO: all で実際に取得して二回も attr_query.map を呼んでるのは美しくない
      participant_attrs = attr_query.map{|x|[x.id,x.value]}
      attr_value_index = attr_query.map{|x|[x.id,x.index]}.to_h
      sort_and_map = ->(h){
        h.sort_by{|k,v|attr_value_index[k] || 9999} # 後から参加不能属性が追加された場合参加不能属性の人でも参加している可能性はある
        .map{|k,v|
          [k,v.map(&:id)]}}
      add_participant_names = ->(ucs,hide_result){
        if hide_result and not edit_mode then return end
        participant_names.merge!(Hash[ucs.map{|u|[u.id,u.user_name]}])
      }
      cond = if edit_mode then {} else {positive:true} end
      choices = ev.choices_dataset.where(cond)
      res = if ev.hide_choice and not edit_mode then
              res = Hash.new{[]}
              choices.each{|c|
                ucs = c.user_choices
                add_participant_names.call(ucs,c.hide_result)
                ucs.each{|uc|
                  res[uc.attr_value_id] <<= uc
                }
              }
              {-1 => sort_and_map.call(res)}
            else
              choices.to_a.each_with_object({}){|c,obj|
                ucs = c.user_choices
                add_participant_names.call(ucs,c.hide_result)
                obj[c.id] = sort_and_map.call(
                  ucs.group_by{|x|x.attr_value_id}
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
      ev = Event[params[:id].to_i]
      return {} if ev.nil?
      opts = Hash[[:detail,:edit,:no_participant].map{|x|[x,params[x]=="true"]}]
      event_info(ev,@user,opts)
    end
    delete '/item/:id' do
      with_update{
        Event[params[:id].to_i].destroy
      }
    end

    def update_or_create_item(update_mode)
      # get時に付加したmodelにない情報なので削除する．TODO: 不要な情報なのでクライアント側で削除する
      @json.delete("all_attrs")
      @json.delete("all_event_groups")

      with_update{
        choices = if @json.has_key?("choices") then
          @json.delete("choices")
        end
        owners_update = nil
        if @json.has_key?("owners_str") then
          owners_update = @json["owners_str"].to_s.split(/\s*,\s*/).map{|s|
            u = User.first(name:s)
            if u.nil? then
              raise Exception.new("invalid owner name: #{s}")
            end
            u.id
          }
          @json.delete("owners_str")
        end
        if @json.has_key?("forbidden_attrs")
          # 一つしかない場合は Array じゃなくて String で送られてくる
          @json["forbidden_attrs"] = [@json["forbidden_attrs"]].flatten.map(&:to_i)
        end
        updata = @json.except("id")
        if update_mode
          ev = Event[params[:id]]
          if updata.empty?.! then
            ev.update(updata)
          end
        else
          ev = Event.create(updata)
          end
        if owners_update then
          cur = ev.owners.map(&:id)
          (owners_update-cur).each{|uid|
            EventOwner.create(user_id:uid,event_id:ev.id)
          }
          (cur-owners_update).each{|uid|
            EventOwner.where(user_id:uid,event_id:ev.id).destroy
          }
        end
        if choices.nil?.! then
          choice_ids = ev.choices.map(&:id)
          choices.each_with_index{|o,i|
            cond = o.select_attr("name","positive").merge({index:i})
            if o["id"] < 0 then
              EventChoice.create(cond.merge(event:ev))
            else
              ev.choices_dataset.where(id:o["id"]).each{|x|x.update(cond)}
              choice_ids.delete(o["id"])
            end
          }
          if choice_ids.empty?.! then
            ev.choices_dataset.where(id:choice_ids).destroy
          end
        end
        event_info(ev,@user)
      }
    end

    put '/item/:id' do
      update_or_create_item(true)
    end
    post '/item' do
      update_or_create_item(false)
    end
    get '/list' do
      events = Event.where(done:false)
      if events.empty?
        # BackboneのCollectionのsyncをtriggerするために空ではない配列を返す
        [{name:"(大会／行事はありません)",choices:[],editable:false,comment_count:0,participant_count:0,id:-1,public:false}]
      else
        # 各eventごとに取得するのは遅いのでまとめて取得しておく
        user_choices = EventChoice.where(event:events,user_choices:@user.event_user_choices_dataset).to_hash(:event_id,:id)
        user_attr_values = UserAttributeValue.where(user_attributes:@user.attrs_dataset).map(&:id)

        events.map{|ev|
          event_info(ev,@user,{user_choices:user_choices,user_attr_values:user_attr_values})
        }
      end
    end
    put '/choose/:cid' do
      with_update{
        c = EventChoice.first(id:params[:cid])
        EventUserChoice.create(user:@user,event_choice:c)
        {
          count: c.event(true).participant_count, # デフォルトではキャッシュされてるので .event(true) とすることでキャッシュ無効化
          event_name:c.event.name,
          choice:c.name
        }
      }
    end
    put '/participants/:id' do
      with_update{
        # TODO: ev が使われていない
        #       event_choice_id がちゃんとそのEventに属しているか念のためにチェック
        ev = Event[params[:id].to_i]
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
    end
    get '/group_list/:id' do
      EventGroup[params[:id].to_i].events_dataset.order(Sequel.desc(:date)).limit(10).map{|x|
        x.select_attr(:id,:name,:date)
      }
    end
    post '/group/new' do
      with_update{
        name = params[:name]
        EventGroup.create(name:name).select_attr(:id,:name)
      }
    end
    put '/group/:id' do
      with_update{
        EventGroup[params[:id].to_i].update(@json.except("id"))
      }
    end
    get '/deadline_alert' do
      uav = @user.attrs.value.map(&:id)
      today = Date.today
      Event.where { (deadline >= today) & (deadline < today+G_DEADLINE_ALERT)}.map{|ev|
        next if (ev.forbidden_attrs & uav).empty?.!
        next if EventUserChoice.first(user_id:@user.id,EventUserChoice.event_choice.event_id => ev.id).nil?.!
        ev.select_attr(:id,:name).merge(deadline_day:(ev.deadline-today).to_i)}.compact
    end
  end
  comment_routes("/api/event",Event,EventComment,true)
  get '/event_catalog' do
    haml :event_catalog
  end
  get '/api/event_catalog/list' do
    query = Event.where(done:false).order(Sequel.asc(:date),Sequel.asc(:id))
    if @public_mode then
      query = query.where(public:true)
    end
    {list:query.map{|x|x.select_attr(:id,:name,:official,:kind,:description,:deadline,:date,:start_at,:end_at,:place,:public)}}
  end
end
