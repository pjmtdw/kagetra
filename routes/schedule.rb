class MainApp < Sinatra::Base
  namespace '/api/schedule' do
    post '/copy/:id', private:true do
      item = ScheduleItem.get(params[:id].to_i)
      params[:list].each{|d|
        date = Date.parse(d)
        ScheduleItem.create(item.attributes.merge(
          id:nil,
          created_at:nil,
          updated_at:nil,
          owner:@user,
          date:date))
      }

    end
    post '/update_holiday', private:true do
      @json.each{|day,obj|
        ScheduleDateInfo.first_or_create(date:Date.parse(day)).update(
          names:obj["names"],
          holiday: obj["holiday"]
        )
      }
    end
    def update_or_create(id, user, json)
      date = if id.nil? then
        Date.new(json["year"],json["mon"],json["day"])
      end
      emph = if id.nil? then
               []
             else
               ScheduleItem.get(id).emphasis
             end
      [:name,:place,:start_at,:end_at].each{|s|
        key = "emph_#{s}"
        if json.has_key?(key) then
          if json[key] then
            emph << s
          else
            emph.reject!{|x|x==s}
          end
        end
      }
      json["emphasis"] = emph.compact
      ScheduleItem.update_or_create(
        {id: id},
        {
          owner: user,
          emphasis: emph,
      }.merge(if date then {date: date} else {} end).merge(json.select_attr("name","place","description","start_at","end_at"))
      )
    end
    def make_detail_item(x)
      r = x.select_attr(:id,:start_at,:end_at,:name,:place,:description,:public)
      x.emphasis.each{|e|
        r["emph_#{e}".to_sym] = "on"
      }
      r
    end
    get '/detail/item/:id' do
      make_detail_item(ScheduleItem.get(params[:id]))
    end
    post '/detail/item',private:true do
      dm_response{
        update_or_create(nil, @user, @json)
      }
    end
    put '/detail/item/:id' do
      dm_response{
        update_or_create(params[:id], @user, @json)
      }
    end
    delete '/detail/item/:id' do
      dm_response{
        ScheduleItem.get(params[:id].to_i).destroy
      }
    end
    get '/detail/:year-:mon-:day' do
      (year,mon,day) = [:year,:mon,:day].map{|x|params[x].to_i}
      date = Date.new(year,mon,day)
      cond = if @public_mode then {public:true} else {} end
      cond[:order] = [:start_at.asc,:end_at.asc]
      list = ScheduleItem.all(cond.merge({date:date})).map{|x|
        make_detail_item(x)
      }
      events = Event.all(cond.merge({date:date})).map{|x|
        x.select_attr(:id,:name,:place,:comment_count,:start_at,:end_at)
      }
      info = ScheduleDateInfo.first(date:date)
      day_infos = if info then info.select_attr(:names,:holiday) end
      {year: year, mon: mon, day: day, list: list, events: events, day_infos: day_infos}
    end
    def make_info(x)
      return unless x
      base = x.select_attr(:names)
      base[:is_holiday] = true if x.holiday
      base
    end
    def make_item(x)
      return unless x
      base = x.select_attr(:id,:kind,:name,:place,:start_at,:end_at,:public,:description)
      base[:emphasis] = x.emphasis if x.emphasis.empty?.!
      base
    end
    def make_event(x)
      return unless x
      x.select_attr(:name,:public)
    end
    get '/get/:year-:mon-:day' do
      (year,mon,day) = [:year,:mon,:day].map{|x|params[x].to_i}
      date = Date.new(year,mon,day)
      {
        year: year,
        mon: mon,
        day: day,
        info: make_info(ScheduleDateInfo.first(date:date)),
        item: ScheduleItem.all(date:date,order:[:start_at.asc,:end_at.asc]).map{|x|make_item(x)}
      }
    end

    SCHEDULE_PANEL_DAYS = 3
    get '/panel',private:true do
      today = Date.today
      cond = {:date.gte => today, :date.lt => today + SCHEDULE_PANEL_DAYS}
      order = {order:[:start_at.asc,:end_at.asc]}
      arr = (0...SCHEDULE_PANEL_DAYS).map{|i|
        d = today + i
        {year: d.year, mon: d.mon, day: d.day}
      }
      [
        [ScheduleDateInfo,:info,:make_info,Hash,{}],
        [ScheduleItem,:item,:make_item,Array,order],
        [Event,:event,:make_event,Array,order]
      ].each{|klass,sym,func,obj,acond|
        klass.all(cond.merge(acond)).each{|x|
          p = arr[x.date-today]
          p[sym] ||= obj.new
          if obj == Array then 
            p[sym] <<= send(func,x)
          else
            p[sym] = send(func,x)
          end
        }
      }
      arr
    end
    get '/cal/:year-:mon' do
      year = params[:year].to_i
      mon = params[:mon].to_i
      fday = Date.new(year,mon,1)
      lday = fday.next_month
      month_day = (lday - fday).to_i
      before_day = fday.cwday % 7
      after_day = 7 - lday.cwday
      today = Date.today.day

      cbase = if @public_mode then {public:true} else {} end
      cbase[:order] = [:start_at.asc,:end_at.asc]

      (day_infos,items,events) = [
        [ScheduleDateInfo,:info,:make_info,Hash,{}],
        [ScheduleItem,:item,:make_item,Array,cbase],
        [Event,:event,:make_event,Array,cbase]
      ].map{|klass,sym,func,obj,cond|
        klass.all_month(:date,year,mon,cond)
        .each_with_object(if obj == Array then Hash.new{[]} else {} end){|x,h|
          if obj == Array then
            h[x.date.day] <<= send(func,x)
          else
            h[x.date.day] = send(func,x)
          end
        }
      }
      {
        year: year,
        mon: mon,
        today: today,
        month_day: month_day,
        before_day: before_day,
        after_day: after_day,
        day_infos: day_infos,
        items: items,
        events: events
      }
    end
    SCHEDULE_EVENT_DONE_PER_PAGE = 40
    get '/ev_done',private:true do
      page = if params[:page].to_s.empty?.! then params[:page].to_i else 1 end
      chunks = Event.all(:kind.not=>:contest,done:true,order:[:updated_at.desc,:id.desc]).chunks(SCHEDULE_EVENT_DONE_PER_PAGE)
      pages = chunks.size
      list = chunks[page-1].map{|x|
        x.select_attr(:id,:name,:place,:comment_count,:start_at,:end_at,:date).merge({has_new_comment:x.has_new_comment(@user)})
      }
      {
        list:list,
        pages: pages,
        cur_page: page
      }
    end
  end
  get '/schedule' do
    haml :schedule
  end
end
