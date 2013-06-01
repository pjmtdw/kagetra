class MainApp < Sinatra::Base
  namespace '/api/schedule' do
    post '/update_holiday' do
      @json.each{|day,obj|
        ScheduleDateInfo.first_or_create(date:Date.parse(day)).update(
          names:obj["names"],
          holiday: obj["holiday"]
        )
      }
    end
    post '/detail/update' do
      date = Date.new(@json["year"],@json["mon"],@json["day"])
      Kagetra::Utils.dm_debug{
        ScheduleItem.create(user: get_user,date: date, title: @json["title"])
      }
    end
    put '/detail/update/:id' do
      # todo update others
      ScheduleItem.first(id:params[:id]).update(
        title: @json["title"]
      )
    end
    get '/detail/:year/:mon/:day' do
      year = params[:year].to_i
      mon = params[:mon].to_i
      day = params[:day].to_i
      
      list = ScheduleItem.all(date:Date.new(year,mon,day)).map{|x|
        {
         id: x.id,
         title: x.title,
         start_at: x.start_at,
         end_at: x.end_at,
         place: x.place,
         description: x.description
        }
      }
      {
        year:year,
        mon:mon,
        day:day,
        list: list
      }
    end
    def make_info(x)
      return unless x
      base = {
        names: x.names
      }
      base[:is_holiday] = true if x.holiday
      base
    end
    def make_item(x)
      return unless x
      base = {
        kind: x.kind,
        title: x.title,
        place: x.place
      }
      base[:start_at] = x.start_at if x.start_at
      base[:end_at] = x.end_at if x.end_at
      base[:emphasis] = x.emphasis if x.emphasis.empty?.!
      base
    end
    get '/get/:year/:mon/:day' do
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
    get '/cal/:year/:mon' do
      year = params[:year].to_i
      mon = params[:mon].to_i
      fday = Date.new(year,mon,1)
      lday = fday >> 1
      month_day = (lday - fday).to_i
      before_day = fday.cwday % 7
      after_day = 7 - lday.cwday
      today = Date.today.day
      day_infos = ScheduleDateInfo
        .all_month(:date,year,mon)
        .each_with_object({}){|x,h|
          h[x.date.day] = make_info(x)
        }
      items = ScheduleItem.all_month(:date,year,mon)
        .each_with_object(Hash.new{[]}){|x,h|
          h[x.date.day] <<= make_item(x)
        }
      {
        year: year,
        mon: mon,
        today: today,
        month_day: month_day,
        before_day: before_day,
        after_day: after_day,
        day_infos: day_infos,
        items: items
      }
    end
  end
  get '/schedule' do
    haml :schedule
  end
end
