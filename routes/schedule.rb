class MainApp < Sinatra::Base
  namespace '/api/schedule' do
    post '/copy/:id' do
      user = get_user
      item = ScheduleItem.get(params[:id].to_i)
      params[:list].each{|d|
        date = Date.parse(d)
        ScheduleItem.create(item.attributes.merge(
          id:nil,
          created_at:nil,
          updated_at:nil,
          owner:user,
          date:date))
      }

    end
    post '/update_holiday' do
      @json.each{|day,obj|
        ScheduleDateInfo.first_or_create(date:Date.parse(day)).update(
          names:obj["names"],
          holiday: obj["holiday"]
        )
      }
    end
    def update_or_create(id, user, json)
      date = if not id then
        Date.new(json["year"],json["mon"],json["day"])
      end
      emph = ["name","place","start_at","end_at"].map{|s|
        if json["emph_"+s].to_s.empty?.! then
          s.to_sym
        end
      }.compact
      Kagetra::Utils.dm_debug{
        ScheduleItem.update_or_create(
          {id: id},
          {
            owner: user,
            name: json["name"],
            place: json["place"],
            emphasis: emph,
            description: json["description"],
            start_at: json["start_at"],
            end_at: json["end_at"]
          }.merge(if date then {date: date} else {} end)
        )
      }
    end
    def make_detail_item(x)
      r = x.select_attr(:id,:start_at,:end_at,:name,:place,:description)
      x.emphasis.each{|e|
        r["emph_#{e}".to_sym] = "on"
      }
      r
    end
    get '/detail/item/:id' do
      make_detail_item(ScheduleItem.get(params[:id]))
    end
    post '/detail/item' do
      user = get_user
      update_or_create(nil, user, @json)
    end
    put '/detail/item/:id' do
      user = get_user
      update_or_create(params[:id], user, @json)
    end
    delete '/detail/item/:id' do
      Kagetra::Utils.dm_debug{
        ScheduleItem.get(params[:id].to_i).destroy
      }
    end
    get '/detail/:year-:mon-:day' do
      (year,mon,day) = [:year,:mon,:day].map{|x|params[x].to_i}
      date = Date.new(year,mon,day)
      list = ScheduleItem.all(date:date).map{|x|
        make_detail_item(x)
      }
      events = Event.all(date:date).map{|x|
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
      base = x.select_attr(:id,:kind,:name,:place,:start_at,:end_at)
      base[:emphasis] = x.emphasis if x.emphasis.empty?.!
      base
    end
    def make_event(x)
      return unless x
      x.select_attr(:name)
    end
    get '/get/:year-:mon-:day' do
      (year,mon,day) = [:year,:mon,:day].map{|x|params[x].to_i}
      date = Date.new(year,mon,day)
      {
        year: year,
        mon: mon,
        day: day,
        info: make_info(ScheduleDateInfo.first(date:date)),
        item: ScheduleItem.all(date:date).map{|x|make_item(x)}
      }
    end
    get '/panel' do
      PANEL_DAYS = 3
      today = Date.today
      cond = {:date.gte => today, :date.lt => today + PANEL_DAYS}
      arr = (0...PANEL_DAYS).map{|i|
        d = today + i
        {year: d.year, mon: d.mon, day: d.day}
      }
      [
        [ScheduleDateInfo,:info,:make_info,Hash],
        [ScheduleItem,:item,:make_item,Array],
        [Event,:event,:make_event,Array]
      ].each{|klass,sym,func,obj|
        klass.all(cond).each{|x|
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
      lday = fday >> 1
      month_day = (lday - fday).to_i
      before_day = fday.cwday % 7
      after_day = 7 - lday.cwday
      today = Date.today.day

      (day_infos,items,events) = [
        [ScheduleDateInfo,:info,:make_info,Hash],
        [ScheduleItem,:item,:make_item,Array],
        [Event,:event,:make_event,Array]
      ].map{|klass,sym,func,obj|
        klass.all_month(:date,year,mon)
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
  end
  get '/schedule' do
    user = get_user
    haml :schedule, locals:{user: user}
  end
end
